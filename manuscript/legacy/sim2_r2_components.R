#!/usr/bin/env Rscript
# Supplement Simulation 2 with R^2 and L^2, preserving the original predictions.
#
# First check (default): Rscript sim2_r2_components.R --repeats=1:3
# Complete/resume:        Rscript sim2_r2_components.R --repeats=1:100
# Optional: --code-dir=/path/to/TimeMetric --output-dir=/path/to/new/results
#
# Original R files, CSVs, and figures are read only. Outputs and checkpoints are
# written beside this script, in sim2_r2_update, unless --output-dir is supplied.
# Point-version measures are deliberately excluded.

main <- function() {
  argv <- commandArgs(trailingOnly = TRUE)
  option <- function(name, default) {
    prefix <- paste0("--", name, "=")
    value <- argv[startsWith(argv, prefix)]
    if (length(value) > 1L) stop("Repeated option: ", name)
    if (length(value)) substring(value, nchar(prefix) + 1L) else default
  }
  known <- c("--repeats=", "--code-dir=", "--output-dir=")
  for (arg in argv) {
    if (!any(vapply(known, function(k) startsWith(arg, k), logical(1)))) {
      stop("Unknown option: ", arg)
    }
  }
  repeat_text <- option("repeats", "1:3")
  if (!grepl("^[0-9]+(:[0-9]+)?(,[0-9]+(:[0-9]+)?)*$", repeat_text)) {
    stop("Use --repeats=1:3, --repeats=1:100, or --repeats=1,2,3.")
  }
  repeats <- sort(unique(unlist(lapply(strsplit(repeat_text, ",")[[1]], function(x) {
    ends <- as.integer(strsplit(x, ":")[[1]])
    if (length(ends) == 1L) ends else seq.int(ends[1], ends[2])
  }))))
  if (anyNA(repeats) || any(!repeats %in% 1:100)) stop("Repeats must be in 1:100.")
  file_arg <- grep("^--file=", commandArgs(), value = TRUE)
  if (length(file_arg) != 1L) stop("Run this script with Rscript.")
  script_path <- sub("^--file=", "", file_arg)
  # Some R launchers encode spaces as ~+~ in --file. Decode only when the
  # literal path is absent and the decoded file exists; fail on a real bad path.
  if (!file.exists(script_path)) {
    decoded <- gsub("~+~", " ", script_path, fixed = TRUE)
    if (file.exists(decoded)) script_path <- decoded
  }
  script_dir <- dirname(normalizePath(script_path, mustWork = TRUE))
  code_dir <- normalizePath(option("code-dir", paste0(
    "/Users/zianzhuang/Dropbox/zza/UCLA/research/Dr. Li's GSR/",
    "PA measure new/TimeMetric/TimeMetric")), mustWork = TRUE)
  out_dir <- option("output-dir", file.path(script_dir, "sim2_r2_update"))
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  out_dir <- normalizePath(out_dir)
  prediction_dir <- file.path(out_dir, "predictions")
  dir.create(prediction_dir, showWarnings = FALSE)
  if (!requireNamespace("TimeMetric", quietly = TRUE) ||
      !requireNamespace("survival", quietly = TRUE)) {
    stop("TimeMetric and survival must be installed.")
  }
  # The original Rmd calls the installed package. Check that its relevant
  # functions still match the attached source before using those same calls.
  ns <- asNamespace("TimeMetric")
  function_files <- c(
    sim_cox_weibull_censored = "pam.sim_data.R",
    pam.coxph_restricted = "pam.coxph_restricted.R",
    pam.surverg_restricted = "pam.surverg_restricted.R",
    pam.r2_metrics = "pam.r2_metrics.R",
    integrate_survival = "pam.predicted_survial_eval.R",
    predictSurvProb2survreg = "pam.predictSurvProb2survreg.R"
  )
  for (name in names(function_files)) {
    e <- new.env(parent = ns)
    sys.source(file.path(code_dir, "R", function_files[[name]]), envir = e)
    installed <- get(name, envir = ns, inherits = FALSE)
    if (!identical(formals(installed), formals(e[[name]])) ||
        !identical(deparse(body(installed)), deparse(body(e[[name]])))) {
      stop("Installed/source function mismatch: ", name,
           ". Resolve the version difference before reproducing results.")
    }
  }
  tm <- function(name) get(name, envir = ns, inherits = FALSE)
  baseline_path <- file.path(code_dir, "paper.sim2_table.csv")
  nonlinear_path <- file.path(code_dir, "paper.sim2_extra_table.csv")
  original <- read.csv(baseline_path, check.names = FALSE)
  model_names <- c("Cox", "Cox.reduce", "Ln", "Ln.fix")
  metrics <- c("R_square", "L_square", "Pseudo_R_square")
  if (!all(c("Metric", "index", model_names) %in% names(original))) {
    stop("Unexpected baseline CSV columns.")
  }
  watched <- unique(c(file.path(code_dir, "R", unname(function_files)),
                      file.path(code_dir, "paper.code.Rmd"), baseline_path,
                      nonlinear_path))
  fingerprint <- list(
    files = tools::md5sum(watched),
    R = R.version.string, RNG = RNGkind(),
    TimeMetric = as.character(utils::packageVersion("TimeMetric")),
    survival = as.character(utils::packageVersion("survival")),
    train_seed = 1234L, train_n = 10000L, test_n = 3000L,
    v = 1, beta = c(1, -1), tau = 10e10
  )
  manifest <- file.path(out_dir, "configuration.rds")
  if (file.exists(manifest)) {
    if (!identical(readRDS(manifest), fingerprint)) {
      stop("Inputs or R/package versions changed. Use a new --output-dir.")
    }
  } else {
    if (length(list.files(prediction_dir)) || file.exists(file.path(out_dir, "models.rds"))) {
      stop("Unidentified checkpoints exist; use a new --output-dir.")
    }
    saveRDS(fingerprint, manifest)
  }
  capture.output(sessionInfo(), file = file.path(out_dir, "sessionInfo.txt"))
  model_file <- file.path(out_dir, "models.rds")
  if (file.exists(model_file)) {
    fits <- readRDS(model_file)
    message("Reusing the four training models.")
  } else {
    message("Fitting four models once, using the original n=10000 and seed=1234.")
    train <- tm("sim_cox_weibull_censored")(
      n = 10000, pi_c = 0, v = 1, beta = c(1, -1), seed = 1234)
    # Formula environments resolve Surv without attaching any packages.
    Surv <- survival::Surv
    fits <- list(
      Cox = survival::coxph(Surv(time, status) ~ ., data = train, x = TRUE, y = TRUE),
      Cox.reduce = survival::coxph(Surv(time, status) ~ x2, data = train, x = TRUE, y = TRUE),
      Ln = survival::survreg(Surv(time, status) ~ ., data = train,
                            dist = "lognormal", x = TRUE, y = TRUE),
      Ln.fix = survival::survreg(Surv(time, status) ~ ., data = train, scale = 2,
                                dist = "lognormal", x = TRUE, y = TRUE)
    )
    # Avoid serializing this main() frame through the fitted formulas.
    formula_env <- new.env(parent = asNamespace("survival"))
    formula_env$Surv <- survival::Surv
    for (name in model_names) {
      attr(fits[[name]]$terms, ".Environment") <- formula_env
      if (!is.null(fits[[name]]$formula)) environment(fits[[name]]$formula) <- formula_env
    }
    saveRDS(fits, model_file)
    rm(train)
  }
  calculate <- function(p) {
    # Match the ordering in pam.predicted_survial_eval(), then call the
    # original component calculator, preserving its four-decimal rounding.
    o <- order(p$times)
    z <- tm("pam.r2_metrics")(predicted_data = p$pred[o],
                              survival_time = p$times[o], status = p$status[o],
                              tau = 10e10)
    values <- c(R_square = z$R_squared, L_square = z$L_squared,
                Pseudo_R_square = z$Pseudo_R_squared)
    if (length(values) != 3L || any(!is.finite(values))) {
      stop("Invalid component result.")
    }
    values
  }
  collect_results <- function() {
    files <- list.files(prediction_dir, pattern = "^repeat_[0-9]{3}\\.rds$", full.names = TRUE)
    if (!length(files)) return(NULL)
    do.call(rbind, lapply(files, function(path) {
      record <- readRDS(path)
      row <- data.frame(Metric = metrics, stringsAsFactors = FALSE)
      for (name in model_names) row[[name]] <- calculate(record$predictions[[name]])[metrics]
      row$index <- record$index
      row
    }))
  }
  compare <- function(results) {
    pseudo <- results[results$Metric == "Pseudo_R_square", ]
    do.call(rbind, lapply(seq_len(nrow(pseudo)), function(i) {
      idx <- pseudo$index[i]
      ref <- original[original$Metric == "Pseudo_R_square" & original$index == idx, ]
      if (nrow(ref) != 1L) stop("Missing or duplicate reference for repeat ", idx)
      fresh <- as.numeric(pseudo[i, model_names])
      saved <- as.numeric(ref[1, model_names])
      data.frame(index = idx, Model = model_names, original_2dp = saved,
                 recomputed_4dp = fresh, recomputed_2dp = round(fresh, 2),
                 difference_4dp = fresh - saved,
                 match_saved_precision = abs(round(fresh, 2) - saved) < 1e-10)
    }))
  }
  for (idx in repeats) {
    checkpoint <- file.path(prediction_dir, sprintf("repeat_%03d.rds", idx))
    if (file.exists(checkpoint)) {
      message("Repeat ", idx, ": reusing saved prediction means.")
      next
    }
    started <- proc.time()[["elapsed"]]
    test <- tm("sim_cox_weibull_censored")(
      n = 3000, pi_c = 0, v = 1, beta = c(1, -1), seed = idx)
    predictions <- setNames(vector("list", length(model_names)), model_names)
    for (name in model_names) {
      fit <- fits[[name]]
      # The original script supplies Cox covariate names to both AFT fits;
      # survreg coefficients also contain an intercept, which is not a column.
      covs <- names(fits[[if (name == "Cox.reduce") "Cox.reduce" else "Cox"]]$coefficients)
      fun <- if (inherits(fit, "coxph")) "pam.coxph_restricted" else "pam.surverg_restricted"
      p <- tm(fun)(model = fit, covs = covs, new_data = test, tau = 10e10)
      predictions[[name]] <- p[c("times", "status", "pred")]
      calculate(predictions[[name]])
      rm(p)
      invisible(gc())
    }
    saveRDS(list(index = idx, predictions = predictions), checkpoint)
    message(sprintf("Repeat %d: four predictions saved (%.1f seconds).",
                    idx, proc.time()[["elapsed"]] - started))
    # Refresh summaries after every completed repeat; reruns never append duplicates.
    results <- collect_results()
    utils::write.csv(results, file.path(out_dir, "sim2_linear_r2_components.csv"), row.names = FALSE)
    utils::write.csv(compare(results), file.path(out_dir, "sim2_linear_precision_check.csv"), row.names = FALSE)
  }
  results <- collect_results()
  checks <- compare(results)
  utils::write.csv(results, file.path(out_dir, "sim2_linear_r2_components.csv"), row.names = FALSE)
  utils::write.csv(checks, file.path(out_dir, "sim2_linear_precision_check.csv"), row.names = FALSE)
  print(checks[checks$index %in% repeats, ], row.names = FALSE)
  if (!all(checks$match_saved_precision)) {
    stop("Some pseudo-R^2 values differ at the original two-decimal precision. See the comparison CSV.")
  }
  message("PASS: all ", nrow(checks), " saved-precision comparisons match.")
  if (!all(1:100 %in% results$index)) {
    message("Only ", length(unique(results$index)),
            " of 100 repeats are available. Final figures are not produced yet.")
    return(invisible(results))
  }
  if (!requireNamespace("ggplot2", quietly = TRUE) || !requireNamespace("patchwork", quietly = TRUE)) {
    stop("Results are saved. Install ggplot2 and patchwork to produce the figures.")
  }
  # Draw the existing scalar metrics alongside a component panel. Each plotted
  # quantity is averaged over repeats separately: mean(R*L), not mean(R)*mean(L).
  make_figure <- function(table, models, labels, path) {
    required <- c(metrics, "Brier Score", "Harrell’s C", "Time Dependent Auc")
    if (!all(required %in% table$Metric)) stop("Incomplete plotting table: ", path)
    means <- do.call(rbind, lapply(required, function(metric) {
      rows <- table[table$Metric == metric, , drop = FALSE]
      if (nrow(rows) != 100L || anyDuplicated(rows$index)) {
        stop("Expected 100 unique repeats for ", metric)
      }
      values <- vapply(models, function(m) {
        if (any(!is.finite(rows[[m]]))) stop("Non-finite value in ", metric, "/", m)
        mean(rows[[m]])
      }, numeric(1))
      data.frame(Metric = metric, Model = models, Value = values)
    }))
    means$Model <- factor(means$Model, levels = models, labels = labels)
    bar_width <- if (length(models) == 4L) 0.7 else 0.5
    headroom <- if (length(models) == 4L) 0.15 else 0.2
    common_theme <- ggplot2::theme_bw() + ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 30, hjust = 1, size = 9),
      axis.title.y = ggplot2::element_text(size = 9),
      plot.title = ggplot2::element_text(hjust = 0.5, face = "bold", size = 11),
      legend.position = "none")
    bars <- means[means$Metric == "Pseudo_R_square", ]
    points <- means[means$Metric %in% c("R_square", "L_square"), ]
    points$Component <- factor(points$Metric, levels = c("R_square", "L_square"),
                               labels = c("R²", "L²"))
    first <- ggplot2::ggplot(bars, ggplot2::aes(x = Model, y = Value)) +
      ggplot2::geom_col(width = bar_width) +
      ggplot2::geom_point(data = points, ggplot2::aes(shape = Component),
                          size = 2.5, color = "black", show.legend = FALSE) +
      ggplot2::scale_shape_manual(values = c(16, 1), guide = "none") +
      ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0, headroom))) +
      ggplot2::labs(x = NULL, y = "Mean Value", title = "Pseudo-R²") + common_theme
    others <- Map(function(metric, title) {
      ggplot2::ggplot(means[means$Metric == metric, ], ggplot2::aes(x = Model, y = Value)) +
        ggplot2::geom_col(width = bar_width) +
        ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0, headroom))) +
        ggplot2::labs(x = NULL, y = "Mean Value", title = title) + common_theme
    }, c("Brier Score", "Harrell’s C", "Time Dependent Auc"), c("Brier score", "C-index", "AUC"))
    combined <- patchwork::wrap_plots(c(list(first), others), ncol = 2)
    figure_width <- if (length(models) == 4L) 10 else 8
    ggplot2::ggsave(path, combined, width = figure_width,
                    height = figure_width * 3.5 / 5.5)
  }
  keep <- original[!original$Metric %in% metrics, ]
  linear <- rbind(keep, results[, names(keep)])
  make_figure(linear, model_names, c("Cox", "Cox (Reduced)", "Ln", "Ln (Scale = 2)"),
              file.path(out_dir, "paper.fig5.components.pdf"))
  nonlinear <- read.csv(nonlinear_path, check.names = FALSE)
  make_figure(nonlinear, c("RF", "Cox", "Ln"), c("RF", "Cox", "Ln"),
              file.path(out_dir, "paper.fig5.2.components.pdf"))
  message("Both component figures saved in ", out_dir)
  invisible(results)
}

main()

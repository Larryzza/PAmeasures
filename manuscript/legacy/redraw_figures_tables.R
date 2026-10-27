#!/usr/bin/env Rscript
# Rebuild the tutorial's simulation figures and real-data performance tables.
# Rscript redraw_figures_tables.R
# RStudio: source("/absolute/path/redraw_figures_tables.R"); redraw_timemetric()
# Optional CLI: --section=all|simulations|real --code-dir=... --component-dir=...
#               --output-dir=...
# No original sources, results, figures, or manuscript files are overwritten.

.timemetric_redraw_dir <- local({
  from_source <- tryCatch(sys.frame(1)$ofile, error = function(e) NULL)
  arg <- grep("^--file=", commandArgs(), value = TRUE)
  path <- if (!is.null(from_source)) from_source else if (length(arg)) sub("^--file=", "", arg[1]) else NULL
  if (!is.null(path) && !file.exists(path)) {
    decoded <- gsub("~+~", " ", path, fixed = TRUE)
    if (file.exists(decoded)) path <- decoded
  }
  if (is.null(path)) getwd() else dirname(normalizePath(path, mustWork = TRUE))
})

redraw_timemetric <- function(
    section = c("all", "simulations", "real"),
    code_dir = "/Users/zianzhuang/Dropbox/zza/UCLA/research/Dr. Li's GSR/PA measure new/TimeMetric/TimeMetric",
    component_dir = file.path(.timemetric_redraw_dir, "sim2_r2_update"),
    output_dir = file.path(.timemetric_redraw_dir, "updated_figures_tables")) {
  section <- match.arg(section)
  code_dir <- normalizePath(code_dir, mustWork = TRUE)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  output_dir <- normalizePath(output_dir)
  for (sub in c("figures", "tables", "plot_data", "checks")) {
    dir.create(file.path(output_dir, sub), showWarnings = FALSE)
  }
  require_packages <- function(packages) {
    missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
    if (length(missing)) stop("Missing packages: ", paste(missing, collapse = ", "))
  }
  require_packages(c("TimeMetric", "survival"))
  tm <- function(name) get(name, envir = asNamespace("TimeMetric"), inherits = FALSE)
  # Record source fingerprints; compare them after the run to check preservation.
  originals <- c(list.files(code_dir, pattern = "\\.(csv|pdf|Rmd)$", full.names = TRUE),
                 list.files(file.path(code_dir, "R"), pattern = "\\.R$", full.names = TRUE))
  before <- tools::md5sum(originals)
  on.exit({
    after <- tools::md5sum(originals)
    utils::write.csv(data.frame(file = names(before), before = unname(before),
                               after = unname(after), unchanged = unname(before == after)),
                     file.path(output_dir, "checks", "original_files_unchanged.csv"), row.names = FALSE)
    capture.output(sessionInfo(), file = file.path(output_dir, "checks", paste0("sessionInfo_", section, ".txt")))
  }, add = TRUE)
  capture.output(sessionInfo(), file = file.path(output_dir, "checks", "sessionInfo.txt"))
  # Exact identifiers expected by the current package; the two-phase API spells
  # its scalar summary "Pesudo_R". No removed or point-version metrics are asked for.
  right_metrics <- c("R_square", "L_square", "Pseudo_R_square", "Harrell’s C",
                     "Uno’s C", "Brier Score", "Time Dependent Auc")
  cr_metrics <- c("R_square", "L_square", "Pseudo_R_square", "C_index",
                  "Brier Score", "Time Dependent Auc")
  weighted_metrics <- c("R_square", "L_square", "Pesudo_R", "Harrell’s C",
                        "Uno’s C", "Brier Score", "Time Dependent Auc")
  status_file <- file.path(output_dir, "checks", "run_status.csv")
  status <- if (file.exists(status_file)) utils::read.csv(status_file) else
    data.frame(Output = character(), Status = character())
  record_status <- function(output, state) {
    status <<- status[status$Output != output, , drop = FALSE]
    status <<- rbind(status, data.frame(Output = output, Status = state))
    utils::write.csv(status, file.path(output_dir, "checks", "run_status.csv"), row.names = FALSE)
  }
  read_result <- function(name) utils::read.csv(file.path(code_dir, name), check.names = FALSE)
  complete <- function(table, metrics, models = "value", groups = character()) {
    if (!all(c("Metric", "index", models, groups) %in% names(table))) stop("Missing result columns.")
    selected <- table[table$Metric %in% metrics, , drop = FALSE]
    if (!all(metrics %in% selected$Metric)) stop("Missing requested metrics.")
    key <- interaction(selected[c("Metric", groups)], drop = TRUE)
    for (rows in split(seq_len(nrow(selected)), key)) {
      cell <- selected[rows, , drop = FALSE]
      if (length(rows) != 100L || anyDuplicated(cell$index)) stop("Expected 100 unique repeats per setting.")
      for (m in models) if (any(!is.finite(cell[[m]]))) stop("Non-finite plotted value: ", m)
    }
    invisible(TRUE)
  }
  metric_label <- function(metric) switch(metric,
    Pseudo_R_square = expression("Pseudo-" * R^2),
    R_square = expression(R^2), L_square = expression(L^2),
    "Brier Score" = "Brier score", "Harrell’s C" = "Harrell's C",
    "Uno’s C" = "Uno's C", "Time Dependent Auc" = "AUC", metric)
  save_plot <- function(plot, name, width, height) {
    ggplot2::ggsave(file.path(output_dir, "figures", name), plot,
                    width = width, height = height, device = "pdf")
    record_status(name, "created")
  }
  # Export CSVs and directly usable booktabs tabulars, without changing main.new.tex.
  export_table <- function(table, name, title, model_labels) {
    table$Metric[table$Metric == "Pesudo_R"] <- "Pseudo_R_square"
    if (any(table$Metric %in% c("R_E", "R_sh")) || any(grepl("point", table$Metric))) {
      stop("Unexpected retired or point-version metric in table ", name)
    }
    wanted <- c("R_square", "L_square", "Pseudo_R_square", "Harrell’s C", "Uno’s C",
                "C_index", "Brier Score", "Time Dependent Auc")
    wanted <- wanted[wanted %in% table$Metric]
    if (!all(c("R_square", "L_square", "Pseudo_R_square") %in% wanted)) stop("Missing components in ", name)
    table <- table[match(wanted, table$Metric), , drop = FALSE]
    models <- names(table)[-1]
    if (length(models) != length(model_labels)) stop("Incorrect table model labels.")
    for (m in models) {
      table[[m]] <- as.numeric(table[[m]])
      if (any(!is.finite(table[[m]]))) stop("Invalid table values: ", name, "/", m)
    }
    utils::write.csv(table, file.path(output_dir, "tables", paste0(name, ".csv")), row.names = FALSE)
    labels <- c(R_square = "$R^2$", L_square = "$L^2$", Pseudo_R_square = "Pseudo-$R^2$",
                "Harrell’s C" = "Harrell's C-index", "Uno’s C" = "Uno's C-index",
                C_index = "C-index", "Brier Score" = "Brier score", "Time Dependent Auc" = "Time-dependent AUC")
    lines <- vapply(seq_len(nrow(table)), function(i) {
      paste0(paste(c(labels[[table$Metric[i]]], sprintf("%.2f", as.numeric(table[i, models]))),
                   collapse = " & "), " \\\\")
    }, character(1))
    tex <- c(paste0("% ", title), "% Requires booktabs. Values are displayed to two decimal places.",
             paste0("\\begin{tabular}{l", paste(rep("c", length(models)), collapse = ""), "}"),
             "\\toprule", paste0(paste(c("Metric", model_labels), collapse = " & "), " \\\\") ,
             "\\midrule", lines, "\\bottomrule", "\\end{tabular}")
    writeLines(tex, file.path(output_dir, "tables", paste0(name, ".tex")))
    markdown <- c(paste0("# ", title), "", paste(c("Metric", model_labels), collapse = " | "),
                  paste(rep("---", length(models) + 1), collapse = " | "),
                  vapply(seq_len(nrow(table)), function(i) {
                    paste(c(table$Metric[i], sprintf("%.2f", as.numeric(table[i, models]))), collapse = " | ")
                  }, character(1)))
    writeLines(markdown, file.path(output_dir, "tables", paste0(name, ".md")))
    record_status(name, "created")
    table
  }
  if (section %in% c("all", "simulations")) {
    require_packages(c("ggplot2", "patchwork"))
    scalar_metrics <- c("Pseudo_R_square", "Brier Score", "Harrell’s C", "Time Dependent Auc")
    message("Drawing Simulation 1 from existing results.")
    sim1 <- read_result("paper.sim1_table.csv")
    grid <- expand.grid(v = 1 / c(0.5, 1, 1.5, 2), beta = c(0.5, 0.7, 1, 1.5), repeat_id = 1:100)
    grid$index <- seq_len(nrow(grid))
    sim1 <- merge(sim1[sim1$Metric %in% scalar_metrics, ], grid, by = "index", sort = FALSE)
    complete(sim1, scalar_metrics, groups = c("v", "beta"))
    means <- stats::aggregate(value ~ Metric + v + beta, sim1, mean)
    means$value <- round(means$value, 3)
    utils::write.csv(means, file.path(output_dir, "plot_data", "simulation1_means.csv"), row.names = FALSE)
    row_header <- function(expr_label, hjust) {
      ggplot2::ggplot() + ggplot2::theme_void() + ggplot2::annotate(
        "text", x = 0, y = 1, label = expr_label, parse = TRUE,
        hjust = hjust, vjust = 1, fontface = "bold", size = 4.2) +
        ggplot2::coord_cartesian(xlim = c(0, 1), ylim = c(0, 1), clip = "off") +
        ggplot2::theme(plot.margin = ggplot2::margin(t = 2, r = 0, b = 4, l = 20))
    }
    groups <- lapply(c("beta", "inv_v"), function(variable) {
      plots <- lapply(scalar_metrics, function(metric) {
        d <- means[means$Metric == metric, ]
        d <- if (variable == "beta") d[d$v == 1, ] else d[d$beta == 1, ]
        d$x <- if (variable == "beta") d$beta else 1 / d$v
        d$x <- factor(d$x, levels = sort(unique(d$x)))
        limits <- range(means$value[means$Metric == metric])
        ggplot2::ggplot(d, ggplot2::aes(x, value)) + ggplot2::geom_col(width = 0.7) +
          ggplot2::theme_bw() +
          ggplot2::labs(x = if (variable == "beta") expression(beta) else "1/v",
                        y = if (metric == "Harrell’s C") "C-index" else metric_label(metric)) +
          ggplot2::coord_cartesian(ylim = limits) +
          ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0.1, 0.17))) +
          ggplot2::scale_x_discrete(drop = FALSE) + ggplot2::theme(
            axis.title.x = ggplot2::element_text(size = 9),
            axis.title.y = ggplot2::element_text(size = 9))
      })
      header <- if (variable == "beta") {
        row_header("bold('(a) Vary the effect size through ') * beta", hjust = 0.3)
      } else {
        row_header("bold('(b) Vary the variance of event times through ') * 1/v", hjust = 0.203)
      }
      patchwork::wrap_plots(header, patchwork::wrap_plots(plots, nrow = 2),
                            ncol = 1, heights = c(0.08, 1))
    })
    save_plot(patchwork::wrap_plots(groups, ncol = 1), "paper.fig4.updated.pdf", 7, 7)

    component_figure <- function(table, models, labels, name, width, height, bar_width, headroom) {
      needed <- c("R_square", "L_square", scalar_metrics)
      complete(table, needed, models)
      means <- do.call(rbind, lapply(needed, function(metric) {
        d <- table[table$Metric == metric, , drop = FALSE]
        data.frame(Metric = metric, Model = models,
                   Value = vapply(models, function(m) mean(d[[m]]), numeric(1)))
      }))
      # Preserve the tutorial's original model order and plot design.
      means$Model <- factor(means$Model, levels = models, labels = labels)
      utils::write.csv(means, file.path(output_dir, "plot_data", sub("\\.pdf$", ".csv", name)), row.names = FALSE)
      dots <- means[means$Metric %in% c("R_square", "L_square"), ]
      dots$Component <- factor(dots$Metric, levels = c("R_square", "L_square"))
      original_theme <- ggplot2::theme_bw() + ggplot2::theme(
        plot.title = ggplot2::element_text(hjust = 0.5, face = "bold", size = 11),
        axis.text.x = ggplot2::element_text(angle = 30, hjust = 1, size = 9),
        axis.title.y = ggplot2::element_text(size = 9), legend.position = "none")
      plots <- list(ggplot2::ggplot(means[means$Metric == "Pseudo_R_square", ],
                                    ggplot2::aes(Model, Value)) +
        ggplot2::geom_col(width = bar_width) +
        ggplot2::geom_point(data = dots, ggplot2::aes(shape = Component), size = 2.5,
                            color = "black", show.legend = FALSE) +
        ggplot2::scale_shape_manual(values = c(16, 1), guide = "none") +
        ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0, headroom))) +
        ggplot2::labs(x = NULL, y = "Mean Value", title = "Pseudo-R²") + original_theme)
      for (metric in scalar_metrics[-1]) {
        plots[[length(plots) + 1L]] <- ggplot2::ggplot(means[means$Metric == metric, ],
                                                      ggplot2::aes(Model, Value)) +
          ggplot2::geom_col(width = bar_width) +
          ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0, headroom))) +
          ggplot2::labs(x = NULL, y = "Mean Value",
                        title = if (metric == "Harrell’s C") "C-index" else metric_label(metric)) + original_theme
      }
      plot <- patchwork::wrap_plots(plots, nrow = 2) + patchwork::plot_annotation(
        theme = ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5, size = 12, face = "bold")))
      save_plot(plot, name, width, height)
    }
    message("Drawing nonlinear Simulation 2 from existing component results.")
    component_figure(read_result("paper.sim2_extra_table.csv"), c("RF", "Cox", "Ln"),
                     c("RF", "Cox", "Ln"), "paper.fig5.2.updated.pdf", 8, 8 * 3.5 / 5.5, 0.5, 0.2)
    original <- read_result("paper.sim2_table.csv")
    component_file <- file.path(component_dir, "sim2_linear_r2_components.csv")
    components <- if (file.exists(component_file)) utils::read.csv(component_file, check.names = FALSE) else NULL
    ready <- !is.null(components) && all(c("Metric", "index") %in% names(components)) &&
      all(vapply(c("R_square", "L_square", "Pseudo_R_square"), function(metric) {
        d <- components[components$Metric == metric, ]
        nrow(d) == 100L && !anyDuplicated(d$index) && setequal(d$index, 1:100)
      }, logical(1)))
    if (ready) {
      models <- c("Cox", "Cox.reduce", "Ln", "Ln.fix")
      complete(components, c("R_square", "L_square", "Pseudo_R_square"), models)
      fresh <- components[components$Metric == "Pseudo_R_square", ]
      old <- original[original$Metric == "Pseudo_R_square", ]
      old <- old[match(fresh$index, old$index), ]
      checks <- do.call(rbind, lapply(models, function(m) data.frame(
        index = fresh$index, Model = m, original = old[[m]], recomputed = fresh[[m]],
        match_saved_precision = abs(round(fresh[[m]], 2) - old[[m]]) < 1e-10)))
      utils::write.csv(checks, file.path(output_dir, "checks", "simulation2_linear_precision.csv"), row.names = FALSE)
      if (anyNA(checks$match_saved_precision) || !all(checks$match_saved_precision)) {
        stop("Linear Simulation 2 does not match original saved precision; see checks.")
      }
      keep <- original[!original$Metric %in% c("R_square", "L_square", "Pseudo_R_square"), ]
      combined <- rbind(keep, components[, names(keep)])
      component_figure(combined, models, c("Cox", "Cox (Reduced)", "Ln", "Ln (Scale = 2)"),
                       "paper.fig5.updated.pdf", 10, 10 * 3.5 / 5.5, 0.7, 0.15)
    } else {
      n <- if (is.null(components)) 0L else length(unique(components$index))
      message("Linear Simulation 2: waiting for 100 component repeats (currently ", n, ").")
      record_status("paper.fig5.updated.pdf", paste0("waiting: ", n, "/100 component repeats"))
    }

    message("Drawing Simulation 3 from existing results.")
    sim3 <- read_result("paper.sim3_table.csv")
    box_metrics <- c("Pseudo_R_square", "Brier Score", "Harrell’s C", "Uno’s C", "Time Dependent Auc")
    sim3 <- sim3[sim3$Metric %in% box_metrics, ]
    complete(sim3, box_metrics, groups = c("n", "censore", "quantile"))
    ref <- stats::aggregate(value ~ Metric + quantile, sim3[sim3$n == 3000 & sim3$censore == 0, ], mean)
    names(ref)[names(ref) == "value"] <- "reference"
    ref$reference <- round(ref$reference, 3) # Preserve the original reference calculation.
    sim3 <- merge(sim3, ref, by = c("Metric", "quantile"), sort = FALSE)
    sim3$error <- sim3$value - sim3$reference
    sim3$quantile <- factor(sim3$quantile, levels = c(90, 50))
    utils::write.csv(sim3, file.path(output_dir, "plot_data", "simulation3_errors.csv"), row.names = FALSE)
    censoring_levels <- sort(unique(sim3$censore))
    rows <- lapply(seq_along(censoring_levels), function(row_index) {
      censoring <- censoring_levels[row_index]
      row_label <- paste0("(", letters[row_index], ") censoring ", round(100 * censoring), "%")
      label_plot <- ggplot2::ggplot() + ggplot2::annotate(
        "text", x = 0, y = 1, label = row_label, hjust = -0.2, vjust = -1.5,
        fontface = "bold", size = 4.8) + ggplot2::xlim(0, 1) + ggplot2::ylim(0, 1) +
        ggplot2::coord_cartesian(clip = "off") + ggplot2::theme_void(base_size = 12) +
        ggplot2::theme(plot.margin = ggplot2::margin(t = 22, r = 16, b = 4, l = 14))
      plots <- lapply(box_metrics, function(metric) {
        d <- sim3[sim3$Metric == metric & sim3$censore == censoring, ]
        limits <- range(sim3$error[sim3$Metric == metric])
        ggplot2::ggplot(d, ggplot2::aes(factor(n), error, fill = quantile)) +
          ggplot2::geom_hline(yintercept = 0, linetype = "dashed") +
          ggplot2::geom_boxplot(outlier.shape = NA, width = 0.6,
                               color = "black",
                               position = ggplot2::position_dodge(width = 0.75)) +
          ggplot2::scale_fill_manual(values = c("90" = "grey70", "50" = "white"),
                                     labels = c("90%", "50%"), name = "Quantile") +
          ggplot2::scale_y_continuous(limits = limits, expand = ggplot2::expansion(mult = c(0.05, 0.05))) +
          ggplot2::labs(x = NULL, y = metric_label(metric)) + ggplot2::theme_bw(base_size = 12) +
          ggplot2::theme(panel.grid.minor = ggplot2::element_blank(),
                         plot.margin = ggplot2::margin(6, 6, 6, 6))
      })
      patchwork::wrap_plots(c(list(label_plot), plots), ncol = length(box_metrics) + 1,
                            widths = c(0.1, rep(1, length(box_metrics))))
    })
    big_figure <- (Reduce(`/`, rows) + patchwork::plot_layout(heights = rep(1, length(rows)))) &
      ggplot2::theme(legend.position = "none")
    x_label <- ggplot2::ggplot() + ggplot2::annotate("text", x = 0.5, y = 0.5, label = "Sample size", size = 5) +
      ggplot2::theme_void()
    plot <- patchwork::wrap_plots(big_figure, x_label, ncol = 1, heights = c(1, 0.05))
    save_plot(plot, "paper.fig6.updated.pdf", 13, 6)
  }

  if (section %in% c("all", "real")) {
    require_packages(c("dplyr", "cmprsk", "riskCommunicator", "pec", "expint"))
    # Match the original Rmd: this package version calls concordancefit()
    # without importing it, so survival must be on the search path.
    suppressPackageStartupMessages(library("survival", character.only = TRUE))
    # Needed by original package helpers and model formulas, without attaching packages.
    Surv <- survival::Surv
    metadata <- list()
    message("Recomputing the PBC table with explicitly selected components.")
    set.seed(1234567)
    e <- new.env(); utils::data("pbc", package = "survival", envir = e)
    df <- e$pbc |>
      dplyr::filter(!is.na(trt)) |>
      dplyr::mutate(log_albumin = log(albumin), log_bili = log(bili), log_protime = log(protime),
                    status = ifelse(status == 2, 1, 0)) |>
      dplyr::select(time, status, age, log_albumin, log_bili, log_protime, edema)
    covs <- names(df)[-c(1:2)]; reduced_covs <- covs[c(1, 5)]
    idx <- sample(seq_len(nrow(df)), round(2/3 * nrow(df)))
    train <- df[idx, ]; test <- df[-idx, ]
    full <- survival::coxph(Surv(time, status) ~ ., data = train, x = TRUE, y = TRUE)
    reduced <- survival::coxph(Surv(time, status) ~ ., data = train[, c(1:2, 3, 7)], x = TRUE, y = TRUE)
    aft <- survival::survreg(Surv(time, status) ~ ., data = train, dist = "weibull", x = TRUE, y = TRUE)
    mods <- list(
      Cox = tm("pam.coxph_restricted")(full, covs, new_data = test),
      Cox.Reduce = tm("pam.coxph_restricted")(reduced, reduced_covs, new_data = test),
      Weibull.AFT = tm("pam.surverg_restricted")(aft, covs, new_data = test))
    pbc_table <- tm("pam.summary")(mods, metrics = right_metrics, tau = 10e10, digits = 4)
    export_table(pbc_table, "pbc_metrics", "PBC: death prediction", c("Cox", "Cox (Reduced)", "Weibull AFT"))
    metadata[["PBC"]] <- data.frame(Dataset = "PBC", Train_n = nrow(train), Test_n = nrow(test),
                                    Requested_probability_horizon = median(test$time),
                                    Probability_horizon = sort(test$time)[which.min(abs(sort(test$time) - median(test$time)))],
                                    Time_horizon = 10e10)
    rm(mods, full, reduced, aft); invisible(gc())

    message("Recomputing the Framingham table with explicitly selected components.")
    set.seed(1234567)
    e <- new.env(); utils::data("framingham", package = "riskCommunicator", envir = e)
    framingham <- e$framingham
    df_ref <- framingham |> dplyr::filter(PERIOD == 1) |>
      dplyr::select(DEATH, TIMEDTH, HYPERTEN, TIMEHYP, RANDID, SEX:educ, RANDID, TIME) |>
      dplyr::group_by(RANDID) |>
      dplyr::mutate(time = min(TIMEDTH, TIMEHYP), status = ifelse(time == TIMEDTH, DEATH * 2, HYPERTEN)) |>
      dplyr::select(time, status, dplyr::everything()) |>
      dplyr::filter(time != 0) |> dplyr::ungroup() |>
      dplyr::select(time, status, RANDID) |> stats::na.omit()
    df <- df_ref |>
      dplyr::left_join(framingham |> dplyr::select(RANDID, TIME, PERIOD, SEX:educ, -BPMEDS), by = "RANDID") |>
      stats::na.omit() |> dplyr::filter(time > TIME) |> dplyr::group_by(RANDID) |>
      dplyr::slice(dplyr::n()) |> dplyr::ungroup() |> dplyr::mutate(time = time - TIME) |>
      dplyr::select(-c(RANDID, TIME, PERIOD))
    covs <- names(df)[-c(1:2)]; reduced_covs <- covs[c(1:3, 5)]
    idx <- sample(seq_len(nrow(df)), round(2/3 * nrow(df)))
    train <- df[idx, ]; test <- df[-idx, ]
    train_reduced <- train[, c("time", "status", reduced_covs)]
    test_reduced <- test[, c("time", "status", reduced_covs)]
    fg1 <- cmprsk::crr(train$time, train$status, train[, covs, drop = FALSE])
    fg2 <- cmprsk::crr(train$time, train$status, train_reduced[, reduced_covs, drop = FALSE])
    aft1 <- survival::survreg(Surv(time, status == 1) ~ ., data = train, x = TRUE, dist = "weibull")
    aft2 <- survival::survreg(Surv(time, status == 2) ~ ., data = train, x = TRUE, dist = "weibull")
    aft3 <- survival::survreg(Surv(time, status == 1) ~ ., data = train, scale = 5, x = TRUE, dist = "weibull")
    aft4 <- survival::survreg(Surv(time, status == 2) ~ ., data = train, scale = 5, x = TRUE, dist = "weibull")
    mods <- list(
      FG = tm("pam.predict_cr")(fg_model = fg1, newdata = test, covs = covs, tau = 5475),
      FG.Reduced = tm("pam.predict_cr")(fg_model = fg2, newdata = test_reduced, covs = reduced_covs, tau = 5475),
      CSH.AFT = tm("pam.predict_cr")(model1 = aft1, model2 = aft2, newdata = test, covs = covs, tau = 5475),
      CSH.AFT.FIX = tm("pam.predict_cr")(model1 = aft3, model2 = aft4, newdata = test, covs = covs, tau = 5475))
    fhs_table <- tm("pam.summary_cr")(mods, metrics = cr_metrics, event_type = 1, tau = 5475, t_star = 5475, digits = 4)
    # Verify that explicitly requesting the components leaves the legacy scalar
    # results unchanged. This does not assume the manuscript's old table is current.
    legacy <- tm("pam.summary_cr")(mods, event_type = 1, tau = 5475, t_star = 5475)
    retained <- intersect(fhs_table$Metric, legacy$Metric)
    legacy_check <- do.call(rbind, lapply(names(mods), function(m) data.frame(
      Metric = retained, Model = m,
      original_default = legacy[[m]][match(retained, legacy$Metric)],
      explicit_metrics = round(fhs_table[[m]][match(retained, fhs_table$Metric)], 2))))
    legacy_check$match <- abs(legacy_check$original_default - legacy_check$explicit_metrics) < 1e-10
    utils::write.csv(legacy_check, file.path(output_dir, "checks", "framingham_default_metric_check.csv"), row.names = FALSE)
    if (!all(legacy_check$match)) stop("Framingham retained metrics changed when requesting components.")
    export_table(fhs_table, "framingham_metrics", "Framingham: hypertension, with death as a competing event",
                 c("Fine--Gray", "Fine--Gray (Reduced)", "CSH-AFT", "CSH-AFT (scale = 5)"))
    metadata[["Framingham"]] <- data.frame(Dataset = "Framingham", Train_n = nrow(train), Test_n = nrow(test),
                                           Requested_probability_horizon = 5475,
                                           Probability_horizon = 5475, Time_horizon = 5475)
    rm(mods, fg1, fg2, aft1, aft2, aft3, aft4); invisible(gc())

    message("Recomputing the GBSG2 case-cohort table with explicitly selected components.")
    set.seed(2025)
    e <- new.env(); utils::data("GBSG2", package = "pec", envir = e)
    df <- e$GBSG2 |> dplyr::mutate(status = cens, id = dplyr::row_number()) |>
      dplyr::filter(time != 0) |> dplyr::select(time, status, id, horTh:estrec) |> stats::na.omit()
    covs <- names(df)[-c(1:3)]
    idx <- sample(seq_len(nrow(df)), round(2/3 * nrow(df)))
    train <- df[idx, ]; test <- df[-idx, ]
    subcohort <- sample(train$id, round(nrow(train) * 0.10))
    subtest <- sample(test$id, round(nrow(test) * 0.10))
    km <- survival::survfit(Surv(time, 1 - status) ~ 1, data = train)
    cc_train <- train |> dplyr::mutate(subco = id %in% subcohort, case = status == 1)
    cc_train$weights <- tm("cc_weights")(time = cc_train$time, status = cc_train$status, subcohort = cc_train$subco)
    cc_train <- cc_train |> dplyr::filter(subco | status == 1)
    train_weights <- cc_train$weights
    cc_train <- cc_train |> dplyr::select(time, status, dplyr::all_of(covs))
    random_train <- train |> dplyr::filter(id %in% sample(train$id, nrow(cc_train))) |>
      dplyr::select(time, status, dplyr::all_of(covs))
    cc_test <- test |> dplyr::mutate(subco = id %in% subtest, case = status == 1)
    cc_test$weights <- tm("cc_weights")(time = cc_test$time, status = cc_test$status, subcohort = cc_test$subco)
    cc_test <- cc_test |> dplyr::filter(subco | status == 1)
    test_weights <- cc_test$weights
    cc_test <- cc_test |> dplyr::select(time, status, dplyr::all_of(covs))
    fit1 <- survival::coxph(Surv(time, status) ~ ., data = cc_train, weights = train_weights, x = TRUE, y = TRUE)
    fit2 <- survival::coxph(Surv(time, status) ~ ., data = random_train, x = TRUE, y = TRUE)
    mods <- list(Cox.cc = tm("pam.coxph_restricted")(fit1, covs, new_data = cc_test),
                 Cox.random = tm("pam.coxph_restricted")(fit2, covs, new_data = cc_test))
    # Preserve the original case-weight input and sampling scheme. This step
    # changes the requested metrics, not the package's weighting implementation.
    gbsg_table <- tm("pam.sample_design")(models = mods, km_cens = km, case_weights = test_weights,
                                          metrics = weighted_metrics, tau = 10e10, digits = 4)
    export_table(gbsg_table, "gbsg2_metrics", "GBSG2: recurrence-free survival under a case-cohort design",
                 c("Cox (Case--cohort)", "Cox (Random sample)"))
    metadata[["GBSG2"]] <- data.frame(Dataset = "GBSG2", Train_n = nrow(cc_train), Test_n = nrow(cc_test),
                                      Requested_probability_horizon = median(cc_test$time),
                                      Probability_horizon = sort(cc_test$time)[max(which(sort(cc_test$time) <= median(cc_test$time)))],
                                      Time_horizon = 10e10)
    utils::write.csv(do.call(rbind, metadata), file.path(output_dir, "tables", "analysis_settings.csv"), row.names = FALSE)
  }
  message("Outputs saved in ", output_dir)
  invisible(status)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  known <- c("section", "code-dir", "component-dir", "output-dir")
  options <- list()
  for (arg in args) {
    pieces <- regmatches(arg, regexec("^--([^=]+)=(.*)$", arg))[[1]]
    if (length(pieces) != 3L || !pieces[2] %in% known) stop("Unknown argument: ", arg)
    options[[gsub("-", "_", pieces[2])]] <- pieces[3]
  }
  do.call(redraw_timemetric, options)
}

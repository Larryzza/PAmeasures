#!/usr/bin/env Rscript
# Redraw saved results and refresh every figure used by main.new.tex.
# RStudio: source("manuscript/update_all_figures.R"); update_all_figures(manuscript_dir = "/path/to/manuscript")

.pameasures_figure_home <- local({
  sourced <- Filter(Negate(is.null), lapply(sys.frames(), function(x) x$ofile))
  candidate <- if (length(sourced)) tail(sourced, 1L)[[1L]] else {
    arg <- grep("^--file=", commandArgs(), value = TRUE)
    if (!length(arg)) stop("Source this file or run it with Rscript.")
    sub("^--file=", "", arg[1L])
  }
  if (!file.exists(candidate)) candidate <- gsub("~+~", " ", candidate, fixed = TRUE)
  dirname(normalizePath(candidate, mustWork = TRUE))
})

update_all_figures <- function(manuscript_dir = NULL,
    sim_output = file.path(.pameasures_figure_home, "..", "results",
                           "simulations", "ici_crn"),
    real_output = NULL) {
  code_root <- normalizePath(file.path(.pameasures_figure_home, ".."),
                             mustWork = TRUE)
  if (is.null(manuscript_dir))
    stop("Set manuscript_dir to the folder containing main.new.tex.")
  manuscript_dir <- normalizePath(manuscript_dir, mustWork = TRUE)
  sim_output <- normalizePath(sim_output, mustWork = TRUE)
  if (!file.exists(file.path(manuscript_dir, "main.new.tex")))
    stop("The manuscript directory must contain main.new.tex: ", manuscript_dir)
  helper <- new.env(parent = globalenv())
  sys.source(file.path(code_root, "analysis", "common.R"), envir = helper)
  sys.source(file.path(code_root, "figures", "original_format.R"), envir = helper)
  if (is.null(real_output)) real_output <- helper$paper_current_real_run(code_root)
  real_output <- normalizePath(real_output, mustWork = TRUE)

  # Read the same saved predictions used by the current manuscript figures.
  active <- utils::read.csv(file.path(real_output, "framingham", "active_horizon.csv"))
  fit <- file.path(real_output, "framingham", "framingham_visit3_10y.rds")
  if (nrow(active) != 1L || active$Horizon_years != 12 ||
      !identical(active$Fit_source_md5, unname(tools::md5sum(fit))))
    stop("The saved FHS 12-year selection is missing or out of date.")
  fhs <- active$Source_predictions
  if (!startsWith(fhs, "/")) fhs <- file.path(real_output, fhs)
  inputs <- c(pbc = file.path(real_output, "pbc", "pbc_comparison.rds"),
              framingham = fhs, gbsg = file.path(real_output, "gbsg", "gbsg2.rds"))
  sim_files <- c("completion.csv", "tables/metrics_raw.csv", "tables/sim3_errors.csv",
                 "tables/calibration_diagnostics.csv")
  required <- c(inputs, file.path(sim_output, sim_files))
  if (any(!file.exists(required)))
    stop("Missing saved results: ", paste(required[!file.exists(required)], collapse = ", "))
  completion <- utils::read.csv(file.path(sim_output, "completion.csv"))
  parts <- c("sim1", "sim2_linear", "sim2_nonlinear", "sim3")
  if (!setequal(completion$part, parts) || any(completion$mode != "full"))
    stop("All four full simulation parts are required; smoke results cannot be published.")
  source_hashes <- tools::md5sum(required)

  # All drawing happens in a temporary directory. Saved runs are read-only.
  stage <- tempfile("pameasures_figures_")
  dir.create(file.path(stage, "simulation", "tables"), recursive = TRUE)
  dir.create(file.path(stage, "ready"))
  on.exit(unlink(stage, recursive = TRUE), add = TRUE)
  if (!all(file.copy(file.path(sim_output, sim_files),
                     file.path(stage, "simulation", sim_files))))
    stop("Could not stage simulation tables.")
  old_libs <- .libPaths()
  on.exit(.libPaths(old_libs), add = TRUE)
  helper$paper_load(code_root)
  message("Drawing Figures 1-3 from saved real-data predictions...")
  sizes <- list(pbc = c(9, 3.5), framingham = c(9, 7), gbsg = c(9, 4))
  real_stems <- c(pbc = "paper.fig1", framingham = "paper.fig2", gbsg = "paper.fig3")
  for (dataset in names(inputs)) {
    result <- readRDS(inputs[[dataset]])
    predictions <- if (dataset == "pbc") result$after else result$predictions
    tau <- if (dataset == "framingham") result$settings$tau else NULL
    plot <- helper$paper_original_real_plot(dataset, predictions, tau)
    helper$paper_original_save(plot, file.path(stage, "ready"), real_stems[[dataset]],
                               sizes[[dataset]][1], sizes[[dataset]][2])
  }
  message("Drawing Figures 4, 5(a), 5(b), and 6 from saved simulation tables...")
  helper$paper_original_simulations(code_root, file.path(stage, "simulation"))
  sim_stems <- paste0("paper.fig", c("4", "5", "5.2", "6"), ".updated")
  sim_names <- as.vector(outer(sim_stems, c("pdf", "png"), paste, sep = "."))
  generated <- file.path(stage, "simulation", "figures", sim_names)
  if (any(!file.exists(generated)))
    stop("Not all four final simulation figures passed the replication checks. Nothing was replaced.")
  if (!all(file.copy(generated, file.path(stage, "ready", sim_names))))
    stop("Could not stage final simulation figures.")
  partial_file <- "paper.fig6.partial_repetitions.csv"
  if (!file.copy(file.path(stage, "simulation", "figures", partial_file),
                 file.path(stage, "ready", partial_file))) stop("Missing Figure 6 finite counts.")
  partial <- utils::read.csv(file.path(stage, "ready", partial_file))
  if (nrow(partial)) {
    message("Figure 6 has unestimable ICI repetitions; retain the finite-count exception in its caption:")
    print(partial, row.names = FALSE)
  }
  if (!identical(source_hashes, tools::md5sum(required)))
    stop("Saved source results changed during drawing. Nothing was replaced; rerun after computation finishes.")

  stems <- c(unname(real_stems), sim_stems)
  files <- as.vector(outer(stems, c("pdf", "png"), paste, sep = "."))
  if (any(file.info(file.path(stage, "ready", files))$size <= 0))
    stop("An output figure is empty.")
  runs <- c(rep(real_output, 3), rep(sim_output, 4))
  source_inputs <- c(unname(inputs),
    rep(file.path(sim_output, "tables", "metrics_raw.csv"), 3),
    file.path(sim_output, "tables", "sim3_errors.csv"))
  manifest <- data.frame(File = files, Source_run = rep(runs, 2),
    Source_input = rep(source_inputs, 2),
    Source_input_MD5 = rep(unname(tools::md5sum(source_inputs)), 2),
    MD5 = unname(tools::md5sum(file.path(stage, "ready", files))),
    Updated_at = format(Sys.time(), tz = "America/Los_Angeles", usetz = TRUE))
  utils::write.csv(manifest, file.path(stage, "ready", "figure_update_manifest.csv"),
                   row.names = FALSE)

  # Preserve existing files before replacing the complete set.
  files <- c(files, partial_file, "figure_update_manifest.csv")
  target <- file.path(manuscript_dir, files)
  existed <- file.exists(target)
  backup <- tempfile(paste0("figure_refresh_",
    format(Sys.time(), "%Y-%m-%d_%H%M%S", tz = "America/Los_Angeles"), "_"),
    tmpdir = file.path(manuscript_dir, "review_notes"))
  dir.create(backup, recursive = TRUE)
  if (any(existed) && !all(file.copy(target[existed], backup)))
    stop("Could not back up existing figures. Nothing was replaced.")
  committed <- FALSE
  on.exit(if (!committed) {
    file.copy(file.path(backup, files[existed]), target[existed], overwrite = TRUE)
    unlink(target[!existed])
  }, add = TRUE)
  if (!all(file.copy(file.path(stage, "ready", files), target, overwrite = TRUE)))
    stop("Figure replacement failed; restoring previous files.")
  if (!identical(unname(tools::md5sum(target)),
                 unname(tools::md5sum(file.path(stage, "ready", files)))))
    stop("Figure verification failed; restoring previous files.")
  committed <- TRUE
  message("Updated all 7 manuscript figures (PDF + PNG): ", manuscript_dir,
          "\nPrevious files: ", backup)
  invisible(manifest)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--help" %in% args) {
    cat("Usage: Rscript --vanilla manuscript/update_all_figures.R --manuscript-dir=PATH",
        "[--sim-output=PATH] [--real-output=PATH]\n",
        "Required: --manuscript-dir. Defaults: simulation results/simulations/ici_crn; real-data published manifest.\n",
        "Redraws saved results only. Existing figures are backed up before replacement.\n")
  } else {
    options <- list()
    for (arg in args) {
      if (!grepl("^--(manuscript-dir|sim-output|real-output)=.+$", arg))
        stop("Unknown argument: ", arg, ". Use --help.")
      key <- gsub("-", "_", sub("^--([^=]+)=.*$", "\\1", arg))
      options[[key]] <- sub("^--[^=]+=", "", arg)
    }
    do.call(update_all_figures, options)
  }
}

#!/usr/bin/env Rscript
# One entry for all paper analyses. Sourcing defines run_all() without running it.
.pa_run_root <- local({
  files <- Filter(Negate(is.null), lapply(sys.frames(), function(x) x$ofile))
  script <- if (length(files)) tail(files, 1L)[[1L]] else
    sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1L])
  if (!file.exists(script)) script <- gsub("~+~", " ", script, fixed = TRUE)
  normalizePath(file.path(dirname(script), ".."), mustWork = TRUE)
})

run_all <- function(mode = "check", output = file.path(.pa_run_root, "results",
                                                      "reruns", "pa_full")) {
  mode <- match.arg(mode, c("check", "full"))
  if (length(output) != 1L || is.na(output) || !nzchar(output))
    stop("Supply a nonempty output directory.")
  root <- .pa_run_root
  output <- normalizePath(output, mustWork = FALSE)
  description <- read.dcf(file.path(root, "DESCRIPTION"))
  imports <- trimws(strsplit(description[1L, "Imports"], ",")[[1L]])
  imports <- sub("[[:space:]]*\\(.*\\)$", "", imports)
  required <- unique(c(imports, "pkgload", "cmprsk", "randomForestSRC",
                       "riskCommunicator"))
  available <- vapply(required, requireNamespace, logical(1), quietly = TRUE)
  if (any(!available)) stop("Missing R packages: ",
    paste(required[!available], collapse = ", "),
    ". Install them or set R_LIBS to their library directory, then retry.")
  helper <- new.env(parent = globalenv())
  sys.source(file.path(root, "analysis", "common.R"), envir = helper)
  helper$paper_load(root)
  cat("Preflight passed: local PAmeasures and dependencies.\n",
      "Real data: PBC, Framingham (examination 3, 12 years), GBSG2.\n",
      "Simulations: sim1, sim2_linear, sim2_nonlinear, sim3; 100 repetitions per cell; ICI included.\n",
      "Output: ", output, "\n", sep = "")
  if (mode == "check") {
    cat("Check only. Use --mode=full to start computation.\n")
    return(invisible(output))
  }
  # Child processes use the same libraries, including an RStudio .libPaths().
  previous <- Sys.getenv("R_LIBS", unset = NA_character_)
  on.exit(if (is.na(previous)) Sys.unsetenv("R_LIBS") else
    Sys.setenv(R_LIBS = previous), add = TRUE)
  Sys.setenv(R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep))
  dir.create(output, recursive = TRUE, showWarnings = FALSE)
  steps <- list(
    real_data = c("run_real_data.R",
      paste0("--output=", file.path(output, "real_data")),
      paste0("--paper-output=", file.path(output, "paper"))),
    simulations = c("run_simulations.R", "--mode=full",
      paste0("--output=", file.path(output, "simulations"))))
  status <- data.frame(Step = character(), Exit_code = integer())
  for (name in names(steps)) {
    args <- steps[[name]]
    message("Starting ", name, "...")
    code <- system2(file.path(R.home("bin"), "Rscript"),
      c("--vanilla", shQuote(file.path(root, "figures", args[1L])),
        vapply(args[-1L], shQuote, character(1))))
    status <- rbind(status, data.frame(Step = name, Exit_code = as.integer(code)))
    utils::write.csv(status, file.path(output, "run_all_status.csv"), row.names = FALSE)
  }
  print(status, row.names = FALSE)
  if (any(status$Exit_code != 0L))
    stop("Some analyses are incomplete. Inspect run_all_status.csv and the individual run logs/status tables. ",
         "Reusing this output resumes simulation checkpoints; real-data models are refitted.")
  cat("All analyses completed. Results: ", output, "\n", sep = "")
  invisible(output)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if ("--help" %in% args) {
    cat("Usage: Rscript --vanilla figures/run_all.R [--mode=check|full] [--output=PATH]\n",
        "Default: check only; output results/reruns/pa_full within this checkout.\n",
        "Full: refit all real-data analyses, then run/resume all full simulations and export figures/tables.\n",
        "Existing global paper exports and manuscript files are not updated.\n")
  } else {
    options <- list()
    for (arg in args) {
      if (!grepl("^--(mode|output)=.+$", arg)) stop("Unknown argument: ", arg, ". Use --help.")
      key <- sub("^--([^=]+)=.*$", "\\1", arg)
      options[[key]] <- sub("^--[^=]+=", "", arg)
    }
    do.call(run_all, options)
  }
}

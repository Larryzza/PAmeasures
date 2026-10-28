#!/usr/bin/env Rscript
arg <- grep("^--file=", commandArgs(), value = TRUE)
script <- sub("^--file=", "", arg[1])
if (!file.exists(script)) script <- gsub("~+~", " ", script, fixed = TRUE)
source(file.path(dirname(normalizePath(script)), "common.R"))
root <- paper_root(script)
out <- file.path(root, "results", "pbc")
args <- commandArgs(trailingOnly = TRUE)
if (length(args)) {
  if (length(args) != 1 || !startsWith(args, "--output=")) stop("Use --output=/path.")
  out <- sub("^--output=", "", args)
}
paper_load(root)
paper_manifest(root, out, list(seed = 1234567L, analysis = "PBC right-censored survival example"))

set.seed(1234567)
e <- new.env(); utils::data("pbc", package = "survival", envir = e)
df <- e$pbc[!is.na(e$pbc$trt), ]
df$log_albumin <- log(df$albumin); df$log_bili <- log(df$bili)
df$log_protime <- log(df$protime); df$status <- as.integer(df$status == 2)
covs <- c("age", "log_albumin", "log_bili", "log_protime", "edema")
df <- df[, c("time", "status", covs)]
idx <- sample(seq_len(nrow(df)), round(2/3 * nrow(df)))
train <- df[idx, ]; test <- df[-idx, ]
fits <- list(
  Cox = survival::coxph(survival::Surv(time, status) ~ ., train, x = TRUE, y = TRUE),
  Cox.Reduce = survival::coxph(survival::Surv(time, status) ~ age + edema, train, x = TRUE, y = TRUE),
  Weibull.AFT = survival::survreg(survival::Surv(time, status) ~ ., train,
                                 dist = "weibull", x = TRUE, y = TRUE))
predictions <- list(
  Cox = pa_predict_coxph(fits$Cox, covs, new_data = test),
  Cox.Reduce = pa_predict_coxph(fits$Cox.Reduce, c("age", "edema"), new_data = test),
  Weibull.AFT = pa_predict_survreg(fits$Weibull.AFT, covs, new_data = test))
metrics <- pa_summarize(predictions, metrics = paper_cohort_metrics, tau = 10e10, digits = 4)
stopifnot(all(is.finite(as.matrix(metrics[, -1]))))
utils::write.csv(metrics, file.path(out, "metrics.csv"), row.names = FALSE)
paper_write_md(metrics, file.path(out, "metrics.md"))
saveRDS(list(train = train, test = test, models = fits,
             predictions = predictions, metrics = metrics), file.path(out, "pbc.rds"))
settings <- paper_support(fits$Cox, test, 10e10)
settings$probability_time_requested <- median(test$time)
settings$probability_time_used <- sort(test$time)[PAmeasures:::pa_nearest_time_index(sort(test$time), median(test$time))]
settings$calibration_time <- median(test$time)
settings$calibration_prediction_time <- max(test$time[test$time <= settings$calibration_time])
settings$calibration_method <- "pmcalibration restricted cubic spline; five knots"
utils::write.csv(settings, file.path(out, "analysis_settings.csv"), row.names = FALSE)

plot_data <- do.call(rbind, lapply(names(predictions), function(m) {
  p <- predictions[[m]]
  data.frame(Model = m, Observed = p$times, Status = p$status, Predicted = p$pred)
}))
utils::write.csv(plot_data, file.path(out, "plot_data.csv"), row.names = FALSE)
writeLines(c("PBC: right-censored survival example with Cox, reduced Cox and Weibull AFT models.",
  paste(nrow(train), "training and", nrow(test), "test participants; seed 1234567."),
  "Predictions and metrics use the current PAmeasures implementation.",
  "Use analysis_settings.csv to inspect the integration endpoint and probability horizon."),
  file.path(out, "README.txt"))
print(metrics)
cat("PBC PASS. Results:", out, "\n")

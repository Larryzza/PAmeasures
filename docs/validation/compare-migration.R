args <- commandArgs(trailingOnly = TRUE)
root <- normalizePath(if (length(args)) args[1] else getwd())
original <- normalizePath(if (length(args) >= 2L) args[2] else file.path(root, "..", "TimeMetric-paper"))
suppressPackageStartupMessages(pkgload::load_all(original, quiet = TRUE))
suppressPackageStartupMessages(pkgload::load_all(root, quiet = TRUE))
fn <- function(package, name) {
  if (package == "TimeMetric") name <- sub("^pa_", "tm_", name)
  getExportedValue(package, name)
}

# Reuse identical fitted-model inputs so formula environments do not differ
# merely because models were refitted in separate evaluation frames.
fixture <- fn("TimeMetric", "pa_sim_cox_weibull")(n = 200, pi_c = .3, v = 2,
  beta = c(.5, -.5), seed = 1001)[, c("time", "status", "x1", "x2")]
fixture <- fixture[order(fixture$time), ]
shared_cox <- survival::coxph(survival::Surv(time, status) ~ x1 + x2,
  data = fixture, x = TRUE, y = TRUE)
shared_aft <- survival::survreg(survival::Surv(time, status) ~ x1 + x2,
  data = fixture, dist = "weibull", x = TRUE, y = TRUE)

evaluate <- function(package) {
  f <- function(name) fn(package, name)
  d <- f("pa_sim_cox_weibull")(n = 200, pi_c = .3, v = 2,
    beta = c(.5, -.5), seed = 1001)[, c("time", "status", "x1", "x2")]
  d <- d[order(d$time), ]
  cox <- shared_cox
  aft <- shared_aft
  covs <- c("x1", "x2")
  pc <- f("pa_predict_coxph")(cox, covs, new_data = d)
  pa <- f("pa_predict_survreg")(aft, covs, new_data = d)
  summary <- f("pa_summarize")(list(cox = pc, aft = pa), metrics = "all")
  t_star <- median(d$time)
  prob <- 1 - pc$surv_prob[, max(which(sort(d$time) <= t_star))]
  calibration <- f("pa_calibration")(prob, d$time, d$status, t_star)
  set.seed(2001)
  cc <- f("pa_case_cohort_weights")(d$time, d$status,
    subcohort = rbinom(nrow(d), 1, .4))
  ncc <- f("pa_nested_case_control_weights")(d$time, d$status, m = 2)
  km <- survival::survfit(survival::Surv(time, 1 - status) ~ 1, data = d)
  two_phase <- f("pa_evaluate_two_phase")(pc, km_cens_fit = km,
    case_weights = cc)
  weighted_calibration <- f("pa_calibration")(prob, d$time, d$status,
    t_star, case_weights = cc)
  cr <- f("pa_simulate_fine_gray")(n = 200, v = 2,
    beta1 = c(.5, -.5), beta2 = c(-.3, .3), censor = .3, seed = 1003)
  cr$time <- cr$obs.times
  cr$status <- cr$obs.event
  m1 <- survival::coxph(survival::Surv(time, status == 1) ~ X1 + X2,
    data = cr, x = TRUE, y = TRUE)
  m2 <- survival::coxph(survival::Surv(time, status == 2) ~ X1 + X2,
    data = cr, x = TRUE, y = TRUE)
  pcr <- f("pa_predict_cif")(model1 = m1, model2 = m2,
    newdata = cr, covs = c("X1", "X2"), event.type = 1, tau = max(cr$time))
  competing <- f("pa_summarize_cr")(list(cox = pcr), metrics = "all")
  horizon <- median(cr$time)
  cif <- pcr$cif_pred[max(which(pcr$cif_pred[, 1] <= horizon)), -1]
  cr_calibration <- f("pa_calibration_cr")(as.numeric(cif), cr$time,
    cr$status, t_star = horizon, event_type = 1)
  list(data = d, cox_prediction = pc, aft_prediction = pa,
    cohort_summary = summary, calibration = calibration,
    cc_weights = cc, ncc_weights = ncc, two_phase = two_phase,
    weighted_calibration = weighted_calibration,
    competing_risk_prediction = pcr, competing_risk_summary = competing,
    competing_risk_calibration = cr_calibration)
}

before <- evaluate("TimeMetric")
after <- evaluate("PAmeasures")
same <- vapply(names(before), function(name) identical(before[[name]], after[[name]]), logical(1))
print(same)
for (name in names(same)[!same]) {
  cat("Comparison details:", name, "\n")
  print(all.equal(before[[name]], after[[name]]))
  print(vapply(names(before[[name]]), function(field) identical(before[[name]][[field]], after[[name]][[field]]), logical(1)))
}
saveRDS(list(before = before, after = after, identical = same),
  file.path(Sys.getenv("PAMEASURES_VALIDATION_DIR", unset = tempdir()), "numerical-equivalence.rds"))
stopifnot(all(same))
cat("All 12 result groups are exactly identical before and after migration.\n")

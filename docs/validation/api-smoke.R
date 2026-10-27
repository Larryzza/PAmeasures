# Run from the repository root: Rscript docs/validation/api-smoke.R
# Exercises all 20 primary exports and pam.nlm. This is a runtime/shape smoke test;
# scientific-audit.R and the reference-comparison unit tests check estimators.
pkgload::load_all(".", quiet = TRUE)
dir.create("docs/validation/results", recursive = TRUE, showWarnings = FALSE)
nlm <- pa_nlm(c(1, 2, 4, 5), 1:4)
stopifnot(isTRUE(all.equal(unlist(nlm), c(R.squared = .98, L.squared = .1))))
stopifnot(identical(pam.nlm(c(1, 2, 4, 5), 1:4),
                    list(R.squared = "0.9800", L.squared = "0.1000")))
grDevices::pdf(NULL)

d <- pa_sim_cox_weibull(240, pi_c = 0.3, v = 2,
                         beta = c(0.5, -0.5), seed = 6201)
d <- d[, c("time", "status", "x1", "x2")]
train <- d[1:160, ]
test <- d[161:240, ]
covs <- c("x1", "x2")
horizon <- unname(stats::quantile(train$time, 0.6))
cox <- survival::coxph(survival::Surv(time, status) ~ x1 + x2,
                       train, x = TRUE, y = TRUE)
aft <- survival::survreg(survival::Surv(time, status) ~ x1 + x2,
                         train, dist = "weibull", x = TRUE, y = TRUE)
pred <- pa_predict_coxph(cox, covs, tau = horizon, new_data = test)
pred_aft <- pa_predict_survreg(aft, covs, tau = horizon, new_data = test)
right <- pa_summarize(list(Cox = pred, Weibull = pred_aft),
                      t_star = horizon, tau = horizon, metrics = "all", digits = 4)
stopifnot(nrow(right) == 13L, all(is.finite(as.matrix(right[, -1]))))
direct <- pa_survival_eval(model = cox, event_time = pred$times,
  predicted_probability = pred$surv_prob, pred_mean_survival = pred$pred,
  status = pred$status, covariates = covs, metrics = "harrell_c", tau = horizon)
stopifnot(identical(direct$Value, right$Cox[right$Metric == "harrell_c"]))
fitted <- pa_fit_and_eval(train, covs, models = "all", predicted_data = test,
                          metrics = c("brier_score", "harrell_c"), t_star = horizon)
stopifnot(nrow(fitted) == 4L, all(is.finite(as.matrix(fitted[, -1]))))
probability <- 1 - pred$surv_prob[, max(which(sort(pred$times) <= horizon))]
cal <- pa_calibration(probability, pred$times, pred$status, horizon)
stopifnot(all(is.finite(cal$metrics)))
print(pa_plot_pred(pred))
print(pa_plot_summary(list(Cox = pred, Weibull = pred_aft),
                       invert_linear = c(FALSE, TRUE)))

cr <- pa_simulate_fine_gray(220, v = 2, beta1 = c(0.5, -0.5),
                            beta2 = c(-0.3, 0.3), censor = 0.3, seed = 6202)
cr$time <- cr$obs.times
cr$status <- cr$obs.event
cr_train <- cr[1:150, ]
cr_test <- cr[151:220, ]
m1 <- survival::coxph(survival::Surv(time, status == 1) ~ X1 + X2,
                      cr_train, x = TRUE, y = TRUE)
m2 <- survival::coxph(survival::Surv(time, status == 2) ~ X1 + X2,
                      cr_train, x = TRUE, y = TRUE)
cp <- pa_predict_cif(model1 = m1, model2 = m2, newdata = cr_test,
                     covs = c("X1", "X2"), event.type = 1)
competing <- pa_summarize_cr(list(CSH = cp), event_type = 1, metrics = "all")
stopifnot(nrow(competing) == 12L, all(is.finite(competing$CSH)))
cr_horizon <- median(cp$times)
cif <- as.numeric(cp$cif_pred[max(which(cp$cif_pred[, 1] <= cr_horizon)), -1])
cr_cal <- pa_calibration_cr(cif, cp$times, cp$status, cr_horizon)
stopifnot(all(is.finite(cr_cal$metrics)))
auc <- pa_survival_eval_cr(cp$cif_pred[, -1, drop = FALSE], cp$times,
                           cp$cif_pred[, 1], cp$status, metrics = "td_auc")
stopifnot(is.finite(auc$Value))
if (requireNamespace("cmprsk", quietly = TRUE)) {
  fg <- cmprsk::crr(cr_train$time, cr_train$status,
                    as.matrix(cr_train[, c("X1", "X2")]))
  fp <- pa_predict_cif(fg_model = fg, newdata = cr_test, covs = c("X1", "X2"))
  stopifnot(all(is.finite(pa_summarize_cr(list(FG = fp))$FG)))
}

# Compute weights from the FULL cohort, then retain sampled subjects and
# apply exactly the same ordering to subjects and their weights.
set.seed(6203)
subcohort <- sample(seq_len(nrow(test)), round(0.4 * nrow(test)))
in_subcohort <- seq_len(nrow(test)) %in% subcohort
w <- pa_case_cohort_weights(test$time, test$status, in_subcohort)
keep <- which(in_subcohort | test$status == 1)
keep <- keep[order(test$time[keep])]
cc_pred <- pa_predict_coxph(cox, covs, new_data = test[keep, ], tau = horizon)
km <- survival::survfit(survival::Surv(time, 1 - status) ~ 1, train)
two_phase <- pa_evaluate_two_phase(cc_pred, km_cens_fit = km,
  case_weights = w[keep], t_star = horizon, tau = horizon, metrics = "all")
wide <- pa_sample_design(list(CC = cc_pred), case_weights = w[keep], km_cens = km,
                         t_star = horizon, tau = horizon, metrics = "all")
stopifnot(nrow(two_phase) == 10L, nrow(wide) == 10L,
           all(is.finite(two_phase$Value)))
stopifnot(identical(pa_nested_case_control_weights(c(1, 2, 3),
                                                   c(1, 0, 0), m = 1), c(1, 2, 2)))
stopifnot(length(pa_metric_names()) == 14L)
utils::write.csv(right, "docs/validation/results/example-survival.csv", row.names = FALSE)
utils::write.csv(competing, "docs/validation/results/example-competing-risks.csv", row.names = FALSE)
utils::write.csv(wide, "docs/validation/results/example-case-cohort.csv", row.names = FALSE)
grDevices::dev.off()
cat("All 20 primary exports and pam.nlm exercised successfully.\n")

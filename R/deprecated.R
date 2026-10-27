#' Deprecated function names
#'
#' @description
#' These aliases preserve the pre-0.2 TimeMetric script interfaces, including
#' two misspellings (`survial` for `survival`, `surverg` for `survreg`).
#' The current primary interfaces retain their `tm_` prefix in PAmeasures.
#' These aliases do not recreate the original PAmeasures 0.1.0 interfaces.
#'
#' Each old name below still works and forwards to its replacement, emitting a
#' deprecation warning that names the new function. They exist so that existing
#' analysis scripts -- including `paper.code.Rmd` and the reproduction code for
#' Zhuang et al. (2025) -- keep running unchanged.
#'
#' @param ... Passed unchanged to the replacement function.
#'
#' @return Whatever the replacement function returns.
#'
#' @name PAmeasures-deprecated
NULL

#' @rdname PAmeasures-deprecated
#' @details `pam.predicted_survial_eval()` is deprecated; use [tm_survival_eval()].
#' @export
pam.predicted_survial_eval <- function(...) {
  .Deprecated("tm_survival_eval", package = "PAmeasures")
  tm_survival_eval(...)
}

#' @rdname PAmeasures-deprecated
#' @details `pam.predicted_survial_eval_cr()` is deprecated; use [tm_survival_eval_cr()].
#' @export
pam.predicted_survial_eval_cr <- function(...) {
  .Deprecated("tm_survival_eval_cr", package = "PAmeasures")
  tm_survival_eval_cr(...)
}

#' @rdname PAmeasures-deprecated
#' @details `pam.survival_eval()` is deprecated; use [tm_fit_and_eval()].
#' @export
pam.survival_eval <- function(...) {
  .Deprecated("tm_fit_and_eval", package = "PAmeasures")
  tm_fit_and_eval(...)
}

#' @rdname PAmeasures-deprecated
#' @details `pam.coxph_restricted()` is deprecated; use [tm_predict_coxph()].
#' @export
pam.coxph_restricted <- function(...) {
  .Deprecated("tm_predict_coxph", package = "PAmeasures")
  tm_predict_coxph(...)
}

#' @rdname PAmeasures-deprecated
#' @details `pam.surverg_restricted()` is deprecated; use [tm_predict_survreg()].
#' @export
pam.surverg_restricted <- function(...) {
  .Deprecated("tm_predict_survreg", package = "PAmeasures")
  tm_predict_survreg(...)
}

#' @rdname PAmeasures-deprecated
#' @details `pam.predict_cr()` is deprecated; use [tm_predict_cif()].
#' @export
pam.predict_cr <- function(...) {
  .Deprecated("tm_predict_cif", package = "PAmeasures")
  tm_predict_cif(...)
}

#' @rdname PAmeasures-deprecated
#' @details `pam.summary()` is deprecated; use [tm_summarize()].
#' @export
pam.summary <- function(...) {
  .Deprecated("tm_summarize", package = "PAmeasures")
  tm_summarize(...)
}

#' @rdname PAmeasures-deprecated
#' @details `pam.summary_cr()` is deprecated; use [tm_summarize_cr()].
#' @export
pam.summary_cr <- function(...) {
  .Deprecated("tm_summarize_cr", package = "PAmeasures")
  tm_summarize_cr(...)
}

#' @rdname PAmeasures-deprecated
#' @details `pam.sample_design()` is deprecated; use [tm_sample_design()].
#' @export
pam.sample_design <- function(...) {
  .Deprecated("tm_sample_design", package = "PAmeasures")
  tm_sample_design(...)
}

#' @rdname PAmeasures-deprecated
#' @details `cc_weights()` is deprecated; use [tm_case_cohort_weights()].
#' @export
cc_weights <- function(...) {
  .Deprecated("tm_case_cohort_weights", package = "PAmeasures")
  tm_case_cohort_weights(...)
}

#' @rdname PAmeasures-deprecated
#' @details `ncc_weights()` is deprecated; use [tm_nested_case_control_weights()].
#' @export
ncc_weights <- function(...) {
  .Deprecated("tm_nested_case_control_weights", package = "PAmeasures")
  tm_nested_case_control_weights(...)
}

#' @rdname PAmeasures-deprecated
#' @details `plot_pred()` is deprecated; use [tm_plot_pred()].
#' @export
plot_pred <- function(...) {
  .Deprecated("tm_plot_pred", package = "PAmeasures")
  tm_plot_pred(...)
}

#' @rdname PAmeasures-deprecated
#' @details `summary_pred_plot()` is deprecated; use [tm_plot_summary()].
#' @export
summary_pred_plot <- function(...) {
  .Deprecated("tm_plot_summary", package = "PAmeasures")
  tm_plot_summary(...)
}

#' @rdname PAmeasures-deprecated
#' @details `sim_cox_weibull_censored()` is deprecated; use [tm_sim_cox_weibull()].
#' @export
sim_cox_weibull_censored <- function(...) {
  .Deprecated("tm_sim_cox_weibull", package = "PAmeasures")
  tm_sim_cox_weibull(...)
}

#' @rdname PAmeasures-deprecated
#' @details `simulateTwoCauseFineGrayModel()` is deprecated; use [tm_simulate_fine_gray()].
#' @export
simulateTwoCauseFineGrayModel <- function(...) {
  .Deprecated("tm_simulate_fine_gray", package = "PAmeasures")
  tm_simulate_fine_gray(...)
}

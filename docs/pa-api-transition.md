# PAmeasures pa_ API transition

Development version: 2.0.0.9002. Date: 2026-10-26 (America/Los_Angeles).

The primary API contains twenty `pa_` functions. `pam.nlm()` is the only
supported historical public name. All original `tm_` exports and the fifteen
older TimeMetric script aliases are removed from the new package namespace.
The original TimeMetric repository is unchanged.

## Function-name mapping

| Previous name | Current name |
|---|---|
| `tm_survival_eval` | `pa_survival_eval` |
| `tm_survival_eval_cr` | `pa_survival_eval_cr` |
| `tm_evaluate_two_phase` | `pa_evaluate_two_phase` |
| `tm_fit_and_eval` | `pa_fit_and_eval` |
| `tm_metric_names` | `pa_metric_names` |
| `tm_predict_coxph` | `pa_predict_coxph` |
| `tm_predict_survreg` | `pa_predict_survreg` |
| `tm_predict_cif` | `pa_predict_cif` |
| `tm_summarize` | `pa_summarize` |
| `tm_summarize_cr` | `pa_summarize_cr` |
| `tm_sample_design` | `pa_sample_design` |
| `tm_case_cohort_weights` | `pa_case_cohort_weights` |
| `tm_nested_case_control_weights` | `pa_nested_case_control_weights` |
| `tm_plot_pred` | `pa_plot_pred` |
| `tm_plot_summary` | `pa_plot_summary` |
| `tm_sim_cox_weibull` | `pa_sim_cox_weibull` |
| `tm_simulate_fine_gray` | `pa_simulate_fine_gray` |
| `tm_calibration` | `pa_calibration` |
| `tm_calibration_cr` | `pa_calibration_cr` |

The survival function arguments, metric identifiers and computations remain
the same. Update function references in external scripts as shown above.
Saved-result source fingerprints change; use fresh output directories for
new simulations rather than mixing old and new checkpoints.

The old aliases `pam.predicted_survial_eval`, `pam.predicted_survial_eval_cr`,
`pam.survival_eval`, `pam.coxph_restricted`, `pam.surverg_restricted`,
`pam.predict_cr`, `pam.summary`, `pam.summary_cr`, `pam.sample_design`,
`cc_weights`, `ncc_weights`, `plot_pred`, `summary_pred_plot`,
`sim_cox_weibull_censored` and `simulateTwoCauseFineGrayModel` are not available.
Their corresponding current evaluation, prediction, weighting, plotting and
simulation functions appear in the table above.

## Continuous outcomes

`pa_nlm(y, y.predict)` accepts paired observed and predicted continuous values
from any regression model. It returns an unrounded numeric list with
`R.squared` and `L.squared`, retaining the definitions of PAmeasures 0.1.0.
Its affine correction does not fit the original prediction model.

`pam.nlm(y, y.predict)` calls the same implementation and formats each result
to four decimal places as a character. The historical Moore's Law example
and ordinary defined results are checked against the archived 0.1.0 function.
This alias is supported without a deprecation warning.

Both entry points reject unequal lengths, nonnumeric vectors, missing or
infinite values and fewer than two pairs. Constant predictions use the mean
response as the correction. Constant responses yield undefined R-squared;
zero original prediction error yields undefined L-squared. Undefined measures
are NA with a warning while other defined measures remain available. This
replaces incidental historical NaN/Inf behavior at undefined denominators.
Inputs that overflow or underflow in squared deviations require rescaling.

## Scope and evidence

The other historical CRAN interfaces `pam.censor()`, `pam.coxph()` and
`pam.survreg()` are not restored as public function names. Their related
survival capabilities are accessed through the current API. The `moore`
dataset remains available.

The baseline before this step is tagged `before-pa-api-2026-10-26`, pointing to
5a791aacef9d378e632bc49d256c0b0e8409c625. The prior migration report describes
that earlier state; current validation is in
`validation/pa-api-2026-10-26.md`. Historical audit reports and archived
manuscript helpers keep their original names and results.

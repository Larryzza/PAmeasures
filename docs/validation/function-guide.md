# PAmeasures function and usage guide

Updated 2026-10-26 for development version 2.0.0.9002.

The package exports **20 primary pa_ functions** and **one supported historical
entry, pam.nlm**. The survival evaluators recognize 14 canonical metric names,
with different supported subsets by setting. Internal helpers are not public
interfaces. See [the API transition guide](../pa-api-transition.md) for the
previous names and [the current validation record](pa-api-2026-10-26.md).

## Installation and development

```r
remotes::install_github("Larryzza/PAmeasures")
library(PAmeasures)
# From a local checkout:
pkgload::load_all(".")
testthat::test_local()
```

The repository is initially private: GitHub installation requires authorized
credentials. An SSH clone can instead be installed with
`remotes::install_local("/path/to/PAmeasures")`. R >= 4.1.0 is declared.

## Current public functions

| Function | Inputs and purpose | Result |
|---|---|---|
| `pa_nlm()` | Observed `y` and paired `y.predict` for continuous outcomes from any regression model | Unrounded numeric `R.squared` / `L.squared` list |
| `pa_survival_eval()` | Follow-up, binary status, survival probabilities; optional fitted model and mean-time predictions | Right-censored `Metric` / `Value` table |
| `pa_survival_eval_cr()` | Follow-up, cause codes, target-cause CIF, its grid and event type | Competing-risk `Metric` / `Value` table |
| `pa_evaluate_two_phase()` | Prediction object, aligned positive sampling weights and a censoring fit where required | Two-phase `Metric` / `Value` table |
| `pa_fit_and_eval()` | Training data, covariates and optional independent prediction data | One row per selected model |
| `pa_metric_names()` | No arguments | Canonical metric identifiers |
| `pa_predict_coxph()` | Fitted Cox model, covariate names, optional new data and horizon | Survival prediction list |
| `pa_predict_survreg()` | Fitted parametric survival model, covariates, optional new data and horizon | Survival prediction list |
| `pa_predict_cif()` | Cause-specific model pair, Fine-Gray fit, or competing-risk forest | CIF prediction list |
| `pa_summarize()` | Named right-censored prediction list and metric/horizon settings | One column per model, one row per metric |
| `pa_summarize_cr()` | Named competing-risk prediction list | Competing-risk comparison table |
| `pa_sample_design()` | Named prediction list and aligned sampling weights | Two-phase comparison table |
| `pa_case_cohort_weights()` | Full-cohort follow-up, status and subcohort membership | Sampling weights in input order |
| `pa_nested_case_control_weights()` | Full-cohort follow-up/status, controls per case `m`, optional strata | Inverse-selection weights in input order |
| `pa_plot_pred()` | Prediction object | Prediction plot |
| `pa_plot_summary()` | Named prediction objects | Model-comparison plots |
| `pa_sim_cox_weibull()` | Sample size, Weibull model and censoring parameters, optional seed | Simulated right-censored data |
| `pa_simulate_fine_gray()` | Two-cause simulation settings and optional seed | Simulated competing-risk data |
| `pa_calibration()` | Predicted event probabilities, follow-up, status and a horizon; optional sampling weights | ICI/E50/E90 and calibrated curve |
| `pa_calibration_cr()` | Target-cause CIF, follow-up, cause codes and a horizon | Unweighted competing-risk ICI/E50/E90 and curve |
| `pam.nlm()` | Same paired continuous-outcome inputs as `pa_nlm()` | Historical four-decimal character `R.squared` / `L.squared` list |

See each function's installed help page for its argument names and defaults.

## Continuous outcomes

```r
pa_nlm(c(1, 2, 4, 5), c(1, 2, 3, 4))
pam.nlm(c(1, 2, 4, 5), c(1, 2, 3, 4))
```

The affine-corrected prediction explains R-squared variation; L-squared is the
ratio of corrected to original squared error. The new numeric interface does
not round before returning. Missing values and unequal lengths are rejected.
A constant response makes R-squared undefined; zero original error makes
L-squared undefined. The affected value is NA with a warning. Constant
predictions use an intercept-only correction. See `?pa_nlm` for details.

## Survival metrics and data alignment

`pa_metric_names()` includes `pseudo_r2`, `pseudo_r2_point`, `r_square`,
`l_square`, `r2_point`, `l2_point`, `harrell_c`, `uno_c`, `c_index`,
`brier_score`, `td_auc`, `ici`, `e50` and `e90`. Availability depends on the
setting. Competing risks use `c_index`; ordinary right-censoring uses
`harrell_c` and `uno_c`. ICI is included by default; E50/E90 are opt-in or
included by `metrics = "all"`. Calibration confidence intervals and
sampling-adjusted competing-risk calibration are not implemented.

Survival prediction matrices are subjects by time points. CIF matrices returned
by `pa_predict_cif()` have times in the first column and one subject per other
column; the direct evaluator takes the grid separately. Preserve subject and
prediction order, and reorder sampling weights together with subjects.

Calculate two-phase weights on the full cohort, subset to actual sampled
subjects, and align weights with prediction order. NCC `m` means controls per
case. The weighting function computes inclusion probabilities; it does not
draw controls or infer membership of an external sample.

Cox/AFT prediction lists retain fitted models and outcome information. Use
held-out predictions for performance assessment where appropriate. A prediction
function's integration horizon and an evaluator's point horizon are distinct;
choose them explicitly in scientific analyses.

## Optional backends and examples

`cmprsk` and `randomForestSRC` are optional prediction backends. Required
calibration backends include `pmcalibration`, `Hmisc` and `prodlim`.
The [executable API example](api-smoke.R) exercises all twenty primary
functions and `pam.nlm()` on simulated data. Original historical names and
method audits remain in dated records; they are not current API examples.

# PAmeasures

<!-- badges: start -->
[![R-CMD-check](https://github.com/Larryzza/PAmeasures/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/Larryzza/PAmeasures/actions/workflows/R-CMD-check.yaml)
[![test-coverage](https://github.com/Larryzza/PAmeasures/actions/workflows/test-coverage.yaml/badge.svg)](https://github.com/Larryzza/PAmeasures/actions/workflows/test-coverage.yaml)
[![License: GPL-3](https://img.shields.io/badge/License-GPL--3-blue.svg)](https://www.r-project.org/Licenses/GPL-3)
<!-- badges: end -->

`PAmeasures` evaluates prediction accuracy for continuous outcomes and
predictive performance across right-censored survival data, competing risks,
and two-phase sampling designs (case-cohort and nested case-control).

**PAmeasures 2.0.0** is available on
[CRAN](https://CRAN.R-project.org/package=PAmeasures).
It provides a consistent `pa_` interface for prediction and evaluation.

It separates **prediction** from **evaluation**: the evaluation functions take
predicted survival probabilities or cumulative incidence functions from any
source, so a model fitted outside the package can be assessed with the same
metrics as one fitted by it.

## Installation

Install the released version from CRAN:

```r
install.packages("PAmeasures")
```

If a binary is not yet available for your Windows or macOS R version, install
from source with `install.packages("PAmeasures", type = "source")`.

For the development version from GitHub:

```r
# install.packages("remotes")
remotes::install_github("Larryzza/PAmeasures")
```

## Quick start

For observed and predicted continuous outcomes from any regression model:

```r
library(PAmeasures)
y <- c(1, 2, 4, 5)
prediction <- c(1, 2, 3, 4)
pa_nlm(y, prediction)   # unrounded numeric R.squared and L.squared
pam.nlm(y, prediction)  # historical four-decimal character format
```

These functions use affine correction of the supplied predictions, retaining
the original PAmeasures R-squared and L-squared definitions. Undefined
denominators produce a warning and an NA for the affected measure; see
`?pa_nlm` for constant predictions, perfect predictions and input requirements.

For right-censored survival predictions:

```r
library(PAmeasures)

# simulate right-censored data and fit a model
d   <- pa_sim_cox_weibull(n = 200, pi_c = 0.3, v = 2,
                          beta = c(0.5, -0.5), seed = 1001)
d   <- d[, c("time", "status", "x1", "x2")]
fit <- survival::coxph(survival::Surv(time, status) ~ x1 + x2,
                       data = d, x = TRUE, y = TRUE)

# predicted survival probabilities over the observed time grid
pred <- pa_predict_coxph(model = fit, covs = c("x1", "x2"), new_data = d)

# evaluate
pa_summarize(list(cox = pred))
#>            Metric  cox
#> 1       pseudo_r2 0.24
#> 2 pseudo_r2_point 0.16
#> 3       harrell_c 0.66
#> 4           uno_c 0.66
#> 5     brier_score 0.21
#> 6          td_auc 0.74
#> 7             ici 0.03
```

## Metrics

`pa_metric_names()` returns the canonical identifiers used by the evaluation
interfaces and emitted in the `Metric` column; each setting supports a subset:

| Name | Measure |
|---|---|
| `pseudo_r2`, `pseudo_r2_point` | Pseudo *R²*, integrated and point-in-time (Li & Wang 2019; Zhuang et al. 2025) |
| `r_square`, `l_square`, `r2_point`, `l2_point` | Explained-variation components |
| `harrell_c`, `uno_c` | Concordance indices (Harrell et al. 1982; Uno et al. 2011) |
| `c_index` | Concordance for competing risks |
| `brier_score` | Brier score (Brier 1950; Graf et al. 1999) |
| `td_auc` | Time-dependent AUC (Heagerty, Lumley & Pepe 2000) |
| `ici`, `e50`, `e90` | Mean, median, and 90th percentile absolute calibration error at a specified time |

Not every metric applies to every setting: competing risks use `c_index` rather
than the concordance indices defined for right-censored data. Calibration is
available for ordinary right-censored and competing-risks cohorts, and for
right-censored two-phase sampling designs. Default evaluation and comparison tables
include `ici`; request `metrics = c("ici", "e50", "e90")` for all three, or
`metrics = "all"` for these alongside the other supported metrics.

## Calibration at a specified time

The calibration functions accept predicted event probabilities from any source,
without the original fitted model. `t_star` is a single evaluation horizon in
the same units as follow-up; repeat the call for multiple horizons. ICI averages
calibration error across subjects, not across follow-up time.

```r
# Ordinary right-censoring: p = 1 - S(t_star) for each subject.
t_star <- 1
p <- 1 - as.numeric(pec::predictSurvProb(fit, newdata = d, times = t_star))
cal <- pa_calibration(p, d$time, d$status, t_star)
cal$metrics                   # ici, e50, e90, without display rounding
head(cal$curve)               # predicted and calibrated, in subject order

# Add all three to a model comparison table.
pa_summarize(list(cox = pred), t_star = t_star,
             metrics = c("ici", "e50", "e90"), digits = 4)
```

For competing risks, supply the target-cause CIF and retain all other event
types in `status` (0 denotes censoring):

```r
# A runnable example with known exponential cause-specific hazards.
set.seed(29)
rate1 <- exp(.5 * d$x1 - .5 * d$x2)
target <- stats::rexp(nrow(d), rate1)
competing <- stats::rexp(nrow(d), .4)
censor <- stats::rexp(nrow(d), .3)
cr_time <- pmin(target, competing, censor)
cr_status <- ifelse(censor < pmin(target, competing), 0L,
                    ifelse(target <= competing, 1L, 2L))
t_star <- 1
p_cif <- rate1 / (rate1 + .4) * (1 - exp(-(rate1 + .4) * t_star))
cal_cr <- pa_calibration_cr(p_cif, cr_time, cr_status,
                            t_star = t_star, event_type = 1)
cal_cr$metrics
```

Right-censored curves use `pmcalibration::pmcalibration()` with restricted cubic
splines (default five knots, controlled by `nk`). Competing-risks curves use
`prodlim::prodlim()` and its nearest-neighborhood Aalen--Johansen estimator,
controlled by `bandwidth`. Both summarize errors with
`pmcalibration::cal_metrics()`, exposing only ICI (`Eavg` in the backend), E50,
and E90. This competing-risks curve estimator differs from Fine-Gray spline
calibration. Constant right-censored predictions use marginal Kaplan--Meier
risk; small or few-valued samples use simpler calibration as documented in
`?pa_calibration`.

The matrix evaluators interpret supplied probability grids as right-continuous
steps and use the last grid value at or before `t_star` for calibration.
`pa_calibration()` and `pa_calibration_cr()` accept probabilities already
evaluated exactly at the requested time. Exact 0/1 probabilities are retained;
the right-censored backend moves them slightly inward for fitting only and
warns. A failed curve fit warns and produces missing calibration values in the
evaluation table without dropping the other metrics.

Use held-out or out-of-fold predictions where possible. Calibration assumes
the respective estimator's censoring conditions; the competing-risks
`censoring`/`censor_covariates` arguments for generalized R-squared do not change
the calibration estimator.

For a right-censored case-cohort or NCC validation sample, provide the positive
inverse-inclusion weights for the sampled subjects in prediction order:

```r
cal_w <- pa_calibration(p, event_time, status, t_star,
                        case_weights = sampling_weights)
cal_w$metrics
# Calibration-only evaluation needs no separate censoring fit or mean times.
pa_sample_design(list(external = prediction), case_weights = sampling_weights,
                 metrics = "ici", t_star = t_star)
```

The weighted implementation fits its own Cox calibration model, using the same
complementary log-log risk transformation and spline-knot rule as the ordinary
backend. Both coefficients and baseline cumulative hazard use sampling weights;
ICI then averages absolute errors with those weights. Constant risks use weighted
Kaplan-Meier. E50/E90 use normalized weighted order-statistic interpolation.
`calibration_args = list(nk = 3)` controls the two-phase curve. Weights must
represent inclusion under the actual sampling mechanism, rather than combined
sampling/censoring weights or risk-set weights from a different estimator.
This assumes an appropriate calibration Cox model and conditionally independent
censoring given its predictor. No sampling-adjusted competing-risks calibration
or design-based confidence intervals are implemented.

## Functions

**Continuous outcomes:** `pa_nlm(y, y.predict)` returns numeric R-squared and
L-squared. `pam.nlm()` is the sole supported historical function-name exception.

**Evaluation** — take predictions, return a `Metric`/`Value` table:

| Function | Setting |
|---|---|
| `pa_survival_eval()` | Right-censored |
| `pa_survival_eval_cr()` | Competing risks |
| `pa_evaluate_two_phase()` | Case-cohort and nested case-control |
| `pa_fit_and_eval()` | Fits several models from raw data, then evaluates |
| `pa_calibration()`, `pa_calibration_cr()` | Direct probability inputs; return calibration metrics and curve |

**Prediction** — produce the input the evaluators expect:

| Function | Model |
|---|---|
| `pa_predict_coxph()` | Cox proportional hazards |
| `pa_predict_survreg()` | Parametric AFT |
| `pa_predict_cif()` | Cumulative incidence for competing risks |

**Summaries and weights:**

| Function | Purpose |
|---|---|
| `pa_summarize()`, `pa_summarize_cr()` | One column per model, rows as metrics |
| `pa_sample_design()` | Summary for two-phase designs |
| `pa_case_cohort_weights()` | Prentice-style case-cohort weights |
| `pa_nested_case_control_weights()` | Nested case-control weights |

**Plotting and simulation:** `pa_plot_pred()`, `pa_plot_summary()`,
`pa_sim_cox_weibull()`, `pa_simulate_fine_gray()`.

## Two-phase designs

Case-cohort and nested case-control evaluation weights each subject by the
inverse of its sampling probability:

```r
set.seed(2001)
in_subcohort <- rbinom(nrow(d), 1, 0.4) == 1
w <- pa_case_cohort_weights(d$time, d$status, subcohort = in_subcohort)
keep <- which(in_subcohort | d$status == 1)
keep <- keep[order(d$time[keep])]
cc_pred <- pa_predict_coxph(fit, covs = c("x1", "x2"), new_data = d[keep, ])
km <- survival::survfit(survival::Surv(d$time, 1 - d$status) ~ 1)
pa_evaluate_two_phase(pred_results = cc_pred, km_cens_fit = km,
                       case_weights = w[keep])
```

`pa_nested_case_control_weights(time, status, m = 2)` computes inverse-selection
weights for two controls per case. Supply matching strata via `strata` when
needed, subset to the subjects actually sampled, and align weights with the
prediction order.

## Optional backends

`pa_predict_cif()` accepts alternative model types through suggested packages:

* `cmprsk` for a Fine-Gray fit, via the `fg_model` argument
* `randomForestSRC` for a survival forest, via the `cr_model` argument

Both are optional; the function reports which package to install if one is
needed and absent.

## Compatibility

Current functions use the `pa_` prefix. For continuous outcomes, `pam.nlm()`
is also supported for compatibility with earlier PAmeasures releases.
See the [API transition guide](https://github.com/Larryzza/PAmeasures/blob/main/docs/pa-api-transition.md)
for earlier function names and their current equivalents.

## Citation

To cite the package in a publication, run:

```r
citation("PAmeasures")
```

The package DOI is
[10.32614/CRAN.package.PAmeasures](https://doi.org/10.32614/CRAN.package.PAmeasures).
Include the package version used in your analysis.

## Reproducing the paper analyses

Scripts for the simulations and three real-data examples in the accompanying
tutorial are included in this repository.

To reproduce these analyses, clone the GitHub repository and follow the
[paper reproduction guide](https://github.com/Larryzza/PAmeasures/blob/main/docs/reproduce-paper.md),
which describes data requirements, additional dependencies, and commands for
running the analyses and generating figures and tables.

These scripts are separate from the package's standard prediction and
evaluation workflow. Full reproduction requires additional dependencies and
substantial computation; saved analysis results are not included in the
repository.

## Contributors

Developed by **Li's Lab** (UCLA): Tong Zhu, Zian Zhuang, Wen Su, Xiaowu Dai and
Gang Li.

The original PAmeasures 0.1.0 was authored by Xiaoyan Wang and Gang Li; their
contributions are retained in the package authorship and provenance records.
The survival prediction and evaluation framework was initially developed
under the name TimeMetric and subsequently integrated into PAmeasures 2.0.0.

## License

PAmeasures is distributed under GPL-3. Historical TimeMetric MIT notices are
preserved in `LICENSE.md` and `inst/licenses/TimeMetric-MIT.txt`; see
`inst/COPYRIGHTS` for the source lineage.

## References

Brier, G. W. (1950). *Monthly Weather Review* 78(1), 1–3.
Graf, E., Schmoor, C., Sauerbrei, W. & Schumacher, M. (1999). *Statistics in Medicine* 18(17–18), 2529–2545.
Harrell, F. E., Califf, R. M., Pryor, D. B., Lee, K. L. & Rosati, R. A. (1982). *JAMA* 247(18), 2543–2546.
Heagerty, P. J., Lumley, T. & Pepe, M. S. (2000). *Biometrics* 56(2), 337–344.
Li, G. & Wang, X. (2019). *JASA* 114(528), 1815–1825.
Uno, H., Cai, T., Pencina, M. J., D'Agostino, R. B. & Wei, L. J. (2011). *Statistics in Medicine* 30(10), 1105–1117.
Zhuang, Z., Su, W., Kawaguchi, E. & Li, G. (2025). arXiv:2507.15040.

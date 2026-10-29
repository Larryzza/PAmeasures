#' PAmeasures: Prediction Accuracy for Continuous and Survival Outcomes
#'
#' Prediction accuracy for continuous outcomes and performance metrics for
#' survival models with right-censoring,
#' competing risks, and two-phase designs such as nested case-control and
#' case-cohort studies.
#'
#' All primary interfaces use the \code{pa_} prefix. \code{\link{pa_nlm}()} assesses continuous
#' outcomes; \code{\link{pam.nlm}()} retains the historical four-decimal character format.
#'
#' @section Optional backends:
#' Two prediction backends are optional and declared in \code{Suggests} rather than
#' \code{Imports}, because each serves a single branch of \code{\link{pa_predict_cif}()}:
#'
#' * \code{randomForestSRC} supplies the \code{cr_model} argument (an \code{rfsrc} fit).
#' * \code{cmprsk} supplies the \code{fg_model} argument (a Fine-Gray \code{crr} fit).
#'
#' Both branches check availability with \code{requireNamespace()} and raise an
#' informative error naming the package to install.
#'
#' @keywords internal
#' @name PAmeasures-package
#' @aliases PAmeasures
#'
#' @importFrom survival Surv survfit concordancefit
#' @importFrom stats median na.omit pnorm predict uniroot sd runif rnorm
#' @importFrom stats quantile complete.cases reshape
#' @importFrom stats lm as.formula rbinom rweibull
#' @importFrom utils head
"_PACKAGE"

# Non-standard evaluation: these are column names referenced inside dplyr verbs
# and ggplot2 aes() mappings, not undefined globals. Declaring them silences
# "no visible binding for global variable" from R CMD check.
utils::globalVariables(c(
  ".", ".pred", "pred", "surv_obj", "weight_time", "x_var", "times", "status"
))

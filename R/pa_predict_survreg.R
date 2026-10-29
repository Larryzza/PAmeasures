#' @title Prediction Accuracy Measures for Parametric Survival Regression Models
#'
#' @description
#' Returns subject-specific survival probabilities and a time summary from a
#' fitted model when \code{predict = TRUE}. With \code{predict = FALSE}, returns
#' R-squared, L-squared and pseudo-R-squared instead. R-squared measures explained
#' variation after affine correction. L-squared is the corrected prediction
#' error divided by the original prediction error; it is not the fraction of
#' error removed by correction. Pseudo-R-squared is their product.
#'
#' @param model An object of class \code{survreg} fitted with distribution
#'   \code{"exponential"}, \code{"weibull"}, or \code{"lognormal"}. Fit with
#'   \code{x = TRUE} and \code{y = TRUE} to store the design and response.
#' @param covs A vector of covariate names to be used for prediction when new_data is provided.
#' @param tau (Optional) A restriction time for computing restricted survival time. If provided, the function evaluates predictions up to this time point. Default is 10e10.
#' @param new_data (Optional) A new dataset for evaluating the model. If NULL, the function uses the training data stored in model.
#' @param predict (Optional) A logical value indicating whether to return individual predictions. Default is TRUE. 
#' @details With \code{predict = FALSE}, R-squared metrics return missing values
#'   with a warning if censoring weights cannot be normalized, for example
#'   when the training censoring survival is zero at an observed evaluation
#'   event. Individual predictions remain available with \code{predict = TRUE}.
#' @return
#' With \code{predict = TRUE}, a single prediction list containing:
#' \itemize{
#'   \item \code{model} -- the fitted survival model object.
#'   \item \code{times} -- numeric vector of observed follow-up times for the evaluation dataset.
#'   \item \code{status} -- event indicators (1 = event, 0 = censored).
#'   \item \code{surv_prob} -- an \eqn{n \times K} matrix of predicted
#'         subject-specific survival probabilities on a common time grid.
#'   \item \code{pred} -- model-based restricted mean survival time
#'     \eqn{E[\min(T, \tau) \mid X]}, calculated analytically up to
#'     \code{tau}; it is not the median survival time.
#'   \item \code{linear.pred} -- the model's linear predictor, aligned with
#'     the returned subjects.
#'   \item \code{covs} -- character vector of covariate names used for prediction.
#'   \item \code{new_data} -- dataset on which the predictions were computed.
#' }
#' Subjects are sorted by observed follow-up time. The columns of
#' \code{surv_prob} correspond to the sorted follow-up times, including ties.
#' With \code{predict = FALSE}, the result is a list of formatted character
#' scalars named \code{R.squared}, \code{L.squared}, and \code{Psuedo.R}.
#' The last spelling is retained for compatibility.

#' 
#' @examples
#' data(pbc, package = "survival")
#' pbc <- pbc[!is.na(pbc$trt), ]
#' pbc$log_albumin <- log(pbc$albumin)
#' pbc$log_bili    <- log(pbc$bili)
#' pbc$log_protime <- log(pbc$protime)
#' pbc$status <- ifelse(pbc$status == 2, 1, 0)
#' covs <- c("age", "log_albumin", "log_bili", "log_protime", "edema")
#' df <- pbc[, c("time", "status", covs)]
#' df <- df[stats::complete.cases(df), ]
#'
#' set.seed(2025)
#' idx <- sample(seq_len(nrow(df)), round(2 / 3 * nrow(df)))
#' train_data <- df[idx, ]
#' test_data  <- df[-idx, ]
#'
#' m.wei <- survival::survreg(survival::Surv(time, status) ~ .,
#'                            data = train_data, dist = "weibull",
#'                            x = TRUE, y = TRUE)
#' wei_pred <- pa_predict_survreg(model = m.wei, covs = covs,
#'                                    new_data = test_data)
#' str(wei_pred$pred)
#'
#' @export

pa_predict_survreg <- function(model, covs, tau = 10e10,  new_data = NULL, predict = TRUE)
{
  
  # Check inputs
  if (!inherits(model, "survreg")) {
    stop("model must be an object of class 'survreg'.")
  }
  if (is.null(model$x) || is.null(model$y)) {
    stop("model must include x = TRUE and y = TRUE.")
  }
  
  if(is.null(new_data)){
    x.matrix.unsorted <- model$x
    y.unsorted <- model$y[, 1]
    censor.unsorted <- model$y[, 2]
    y.order.new <- NULL
    if(is.null(tau)) tau <- max(model$y[, 1])
  } else {
    if (!all(covs %in% colnames(new_data))) {
      stop("All covariates must be present in new_data.")
    }
    time_var = "time"
    status_var = "status"
    if (any(!c(time_var, status_var) %in% colnames(new_data))) {
      stop("new_data require time and status columns")
    }
    y.unsorted <- model$y[, 1]
    censor.unsorted <- model$y[, 2]
    x.matrix.unsorted <- new_data[, covs, drop = FALSE]
    y.unsorted.new <- new_data[[time_var]]
    censor.unsorted.new <- new_data[[status_var]]
    y.order.new <- order(y.unsorted.new)
    if(is.null(tau)) tau <- max(new_data[[time_var]])
  }
  
    
  
  nsize <- length(y.unsorted)
  y.order <- order(y.unsorted)
  y <- y.unsorted[y.order]
  delta <- censor.unsorted[y.order]
  p <- dim(as.matrix(x.matrix.unsorted))[2]
  
  if (!is.null(y.order.new)) {
    y.order <- y.order.new
  }
  
  x.matrix <- x.matrix.unsorted[y.order, , drop = FALSE]
  
  
  nsize <- length(y)
  fit.km.censoring <- survfit(Surv(y, 1 - delta) ~ 1)
  
  if (!is.null(y.order.new)){
    y <- y.unsorted.new[y.order]
    delta <- censor.unsorted.new[y.order]
  } 
  
  km.censoring.minus <- pa_censoring_left_limit(fit.km.censoring, y)
  
  ratio.km <- delta/km.censoring.minus
  ratio.km[is.nan(ratio.km)] <- 0
  weight.km <- ratio.km/(sum(ratio.km))
  
  if (model$dist %in% c("exponential", "weibull")) {
    if(is.null(new_data)){
      temp.pred <- predict(model, type = "response")[y.order]
    }else{
      temp.pred <- predict(model, newdata = as.data.frame(x.matrix), type = "response")
    }
    
    gtau <- (tau/temp.pred)^(1/model$scale)
    # E[min(T, tau)] = E[T I(T <= tau)] + tau P(T > tau).
    t.predicted <- temp.pred * gamma(1 + model$scale) *
      stats::pgamma(gtau, shape = 1 + model$scale) + tau * exp(-gtau)
  } else if (model$dist == "lognormal") {
    if(is.null(new_data)){
      temp.pred <- predict(model, type = "response")[y.order]
    }else{
      temp.pred <- predict(model, newdata = as.data.frame(x.matrix), type = "response")
    }
    gtau <- (log(tau)-log(temp.pred))/model$scale
    t.predicted <- temp.pred * exp((model$scale)^2/2) *
      pnorm(gtau - model$scale) + tau * pnorm(gtau, lower.tail = FALSE)
  }
  
  y.original <- y
  delta.original <- delta
  if (!is.null(tau)) {
    delta <- ifelse(y <= tau, delta, 1)
    y <- pmin(y, tau)
    y.input <- ifelse(tau > y, y, tau)
  }
  
  if (predict) {
    time_points <- y.original
    
    pre_sp <- predictSurvProb2survreg(model, as.data.frame(x.matrix), time_points)
    t.predicted2 <- integrate_survival(pre_sp, y, delta, tau)
    return(list(pred = t.predicted, #t.predicted2,
                times = y.original,
                status = delta.original,
                surv_prob = pre_sp,
                model = model,
                new_data = new_data,
                linear.pred = predict(model, 
                                      newdata = as.data.frame(x.matrix), 
                                      type = "lp"),
                covs = covs))
  }
  
  if (any(!is.finite(weight.km)) || !any(weight.km > 0)) {
    warning("R-squared metrics require positive censoring survival at observed ",
            "evaluation events and at least one observed event.", call. = FALSE)
    return(list(R.squared = NA_character_, L.squared = NA_character_,
                Psuedo.R = NA_character_))
  }
  wls.fitted <- tryCatch(lm(y ~ t.predicted, weights = weight.km), 
                         error = function(e) {
                           warning("Error in WLS fitting: ", conditionMessage(e), call. = FALSE)
                           return(c(NA, NA))
                         })
  calibrate.fitted <- tryCatch(predict(wls.fitted), error = function(e) {
    return(c(NA, NA))
  })
  
  num.rho2 <- sum(weight.km * (calibrate.fitted - sum(weight.km * y))^2)
  denom.rho2 <- sum(weight.km * (y - sum(weight.km * y))^2)
  R2 <- round(num.rho2/denom.rho2, digits = 4)
  num.L2 <- sum(weight.km * (y - calibrate.fitted)^2)
  denom.L2 <- sum(weight.km * (y - t.predicted)^2)
  L2 <- round(num.L2/denom.L2, digits = 4)
  SR <- round(R2 * L2, digits = 4)
  
  return(list(R.squared = format(R2, nsmall = 4), 
              L.squared = format(L2, nsmall = 4), 
              Psuedo.R = format(SR, nsmall = 4)))
}

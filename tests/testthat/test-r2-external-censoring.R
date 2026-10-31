test_that("external full-cohort KM reproduces ordinary R-squared", {
  y <- c(1, 2, 3, 4, 5, 6)
  d <- c(1, 0, 1, 0, 1, 0)
  p <- c(2, 4, 2.5, 6, 4, 7)
  km <- survival::survfit(survival::Surv(y, 1 - d) ~ 1)
  expect_equal(pam.r2_metrics(p, y, d, km_cens_fit = km),
               pam.r2_metrics(p, y, d))
})

test_that("phase-one censoring fit corrects outcome-dependent evaluation", {
  y <- c(1, 2, 3, 4, 5, 6)
  d <- c(1, 0, 1, 0, 1, 0)
  p <- c(2, 4, 2.5, 6, 4, 7)
  km <- survival::survfit(survival::Surv(y, 1 - d) ~ 1)
  keep <- c(1, 3, 4, 5)
  z <- pam.r2_metrics(p[keep], y[keep], d[keep],
                     case_weight = c(1, 1, 3, 1), km_cens_fit = km)
  # At the three observed events, the phase-one left limits are 1, 4/5, 8/15.
  event_y <- c(1, 3, 5)
  event_p <- c(2, 2.5, 4)
  w <- 1 / c(1, 4/5, 8/15)
  fit <- stats::lm(event_y ~ event_p, weights = w)
  expected_r <- round(summary(fit)$r.squared, 4)
  expected_l <- round(sum(w * residuals(fit)^2) /
                        sum(w * (event_y - event_p)^2), 4)
  expect_equal(z$R_squared, expected_r)
  expect_equal(z$L_squared, expected_l)
  expect_false(isTRUE(all.equal(z, pam.r2_metrics(
    p[keep], y[keep], d[keep], case_weight = c(1, 1, 3, 1)))))
})

test_that("original and restricted phase-one KM agree at restricted left limits", {
  y <- c(1, 2, 3, 4, 5, 6)
  d <- c(1, 0, 1, 0, 1, 0)
  p <- c(2, 3, 2.5, 3, 3.2, 3.4)
  tau <- 3.5
  km <- survival::survfit(survival::Surv(y, 1 - d) ~ 1)
  restricted <- restricted_data_gen(y, d, tau)
  km_tau <- survival::survfit(survival::Surv(time, 1 - status) ~ 1,
                              data = restricted)
  expect_equal(pam.r2_metrics(p, y, d, tau = tau, km_cens_fit = km),
               pam.r2_metrics(p, y, d, tau = tau, km_cens_fit = km_tau))
})

test_that("zero censoring support cannot silently discard contributing events", {
  km <- survival::survfit(survival::Surv(c(1, 2), c(1, 1)) ~ 1)
  expect_error(pam.r2_metrics(c(1, 2, 3), c(1, 2, 3), c(1, 1, 1),
                              km_cens_fit = km), "positive and finite")
})


test_that("two-phase public interfaces use the supplied phase-one censoring fit", {
  y <- c(1, 2, 3, 4, 5, 6)
  d <- c(1, 0, 1, 0, 1, 0)
  keep <- c(1, 3, 4, 5)
  p <- c(2, 2.5, 6, 4)
  w <- c(1, 1, 3, 1)
  km <- survival::survfit(survival::Surv(y, 1 - d) ~ 1)
  pred <- list(times = y[keep], status = d[keep], pred = p,
               surv_prob = matrix(0.5, 4, 4))
  expected <- pam.r2_metrics(p, y[keep], d[keep], case_weight = w,
                             km_cens_fit = km)
  metrics <- c("r_square", "l_square", "pseudo_r2")
  direct <- pa_evaluate_two_phase(pred, km_cens_fit = km, case_weights = w,
                                  metrics = metrics)
  wide <- pa_sample_design(list(Cox = pred), case_weights = w,
                            km_cens = km, metrics = metrics)
  expected_values <- round(unlist(expected, use.names = FALSE), 2)
  expect_equal(direct$Value[match(metrics, direct$Metric)], expected_values)
  expect_equal(wide$Cox[match(metrics, wide$Metric)], expected_values)
})

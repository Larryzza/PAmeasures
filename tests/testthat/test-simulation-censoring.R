cr_censoring_sample <- function(censor, ...) {
  pa_simulate_fine_gray(n = 2000, v = 1, beta1 = c(.5, -.2),
                       beta2 = c(-.3, .4), censor = censor, seed = 2025, ...)
}

test_that("Fine-Gray simulator attains distinct target censoring proportions", {
  targets <- c(.1, .3, .7)
  observed <- vapply(targets, function(target) {
    d <- cr_censoring_sample(target)
    expect_true(all(is.finite(d$obs.times)))
    expect_true(all(d$obs.times > 0))
    mean(d$obs.event == 0)
  }, numeric(1))
  expect_equal(observed, targets, tolerance = 1/2000)
})

test_that("explicit log-censoring shifts control censoring", {
  early <- cr_censoring_sample(.3, mu.c.time = -20)
  late <- cr_censoring_sample(.3, mu.c.time = 20)
  latent <- cr_censoring_sample(0)
  expect_true(all(early$obs.event == 0))
  expect_identical(late$obs.event, latent$obs.event)
  # The censored branch returns exp(log(T)); allow its round-trip error.
  expect_equal(late$obs.times, latent$obs.times, tolerance = 1e-14)
  expect_true(all(early$obs.times <= late$obs.times))
})

test_that("reported censoring parameters reproduce the generated sample", {
  summary <- cr_censoring_sample(.3, report.mu_and_sd = TRUE)
  generated <- cr_censoring_sample(.3)
  explicit <- cr_censoring_sample(.3, sd.time = summary$sd.time,
                                 mu.c.time = summary$mu.c.time)
  expect_equal(explicit, generated)
  expect_equal(as.numeric(summary[1, -(1:2)]),
               unname(stats::quantile(generated$obs.times, c(.1,.3,.5,.7,.9))))
})

test_that("target censoring also works with covariate-dependent censoring", {
  d <- cr_censoring_sample(.3, independent_c = FALSE)
  expect_equal(mean(d$obs.event == 0), .3, tolerance = 1/2000)
})

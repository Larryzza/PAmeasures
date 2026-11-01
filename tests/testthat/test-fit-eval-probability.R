probability_models <- function(train) {
  formula <- survival::Surv(time, status) ~ x1 + x2
  fits <- list(coxph = survival::coxph(formula, train, x = TRUE, y = TRUE))
  for (m in c("exp", "lognormal", "weibull")) {
    fits[[m]] <- survival::survreg(formula, train, x = TRUE, y = TRUE,
      dist = if (m == "exp") "exponential" else m)
  }
  fits
}

probability_prediction <- function(fit, test) {
  if (inherits(fit, "coxph")) {
    pa_predict_coxph(fit, c("x1", "x2"), new_data = test)
  } else {
    pa_predict_survreg(fit, c("x1", "x2"), new_data = test)
  }
}

probability_baseline <- function() {
  readRDS(testthat::test_path("fixtures", "fit-eval-probability-baseline.rds"))
}

test_that("summary retains its pre-change probability-metric baseline", {
  b <- probability_baseline()
  fits <- probability_models(b$train)
  for (m in names(fits)) {
    p <- probability_prediction(fits[[m]], b$test)
    for (i in 1:2) {
      t <- list(NULL, b$t_star)[[i]]
      result <- pa_summarize(setNames(list(p), m),
        metrics = c("brier_score", "td_auc"), t_star = t, digits = 4)
      expect_equal(result, b$summary[[m]][[i]], tolerance = 1e-12)
    }
  }
})

test_that("fit-and-evaluate preserves all other metrics and return layout", {
  b <- probability_baseline()
  for (i in 1:2) {
    result <- pa_fit_and_eval(b$train, c("x1", "x2"), models = "all",
      predicted_data = b$test, metrics = "all", t_star = list(NULL, b$t_star)[[i]])
    expect_identical(names(result), c("Model", "pseudo_r2", "r_square",
      "l_square", "harrell_c", "uno_c", "brier_score", "td_auc",
      "ici", "e50", "e90"))
    expect_equal(result[, names(b$other[[i]])], b$other[[i]], tolerance = 1e-12)
  }
})

test_that("probability metrics agree across all four models, censoring and ties", {
  b <- probability_baseline()
  fits <- probability_models(b$train)
  metrics <- c("brier_score", "td_auc")
  for (censor in c(0, 0.3)) {
    d <- pa_sim_cox_weibull(80, censor, 2, c(0.5, -0.5), seed = 4003)
    d <- d[, c("time", "status", "x1", "x2")]
    # Repeated covariates create genuine tied prediction scores for every model.
    d$x1 <- round(d$x1)
    d$x2 <- round(d$x2)
    d$time <- pmax(0.1, round(d$time, 1))
    d <- d[rev(seq_len(nrow(d))), ]
    grid <- sort(unique(d$time))
    k <- length(grid) %/% 2
    off_grid <- 0.35 * grid[k] + 0.65 * grid[k + 1]
    expect_false(off_grid %in% grid)
    for (m in names(fits)) {
      p <- probability_prediction(fits[[m]], d)
      ix <- PAmeasures:::pa_nearest_time_index(p$times, stats::median(p$times))
      expect_gt(anyDuplicated(p$surv_prob[, ix]), 0)
      for (t in list(NULL, off_grid)) {
        reference <- pa_summarize(setNames(list(p), m), metrics = metrics,
                                  t_star = t, digits = 2)
        result <- pa_fit_and_eval(b$train, c("x1", "x2"), models = m,
          predicted_data = d, metrics = metrics, t_star = t)
        expect_identical(names(result), c("Model", metrics))
        expect_equal(unlist(result[1, metrics], use.names = FALSE),
                     reference[[m]][match(metrics, reference$Metric)])
        reordered <- pa_fit_and_eval(b$train, c("x1", "x2"), models = m,
          predicted_data = d[order(d$time), ], metrics = metrics, t_star = t)
        expect_equal(result, reordered)
      }
    }
  }
})

test_that("each probability metric can be requested alone", {
  b <- probability_baseline()
  both <- pa_fit_and_eval(b$train, c("x1", "x2"), models = "all",
    predicted_data = b$test, metrics = c("brier_score", "td_auc"))
  for (metric in c("brier_score", "td_auc")) {
    single <- pa_fit_and_eval(b$train, c("x1", "x2"), models = "all",
      predicted_data = b$test, metrics = metric)
    expect_equal(single, both[, c("Model", metric)])
  }
})

test_that("PBC Cox predictions match survfit without using held-out labels", {
  withr::local_seed(1234567)
  e <- new.env()
  utils::data("pbc", package = "survival", envir = e)
  d <- e$pbc[!is.na(e$pbc$trt), ]
  d$log_albumin <- log(d$albumin)
  d$log_bili <- log(d$bili)
  d$log_protime <- log(d$protime)
  d$status <- as.integer(d$status == 2)
  covs <- c("age", "log_albumin", "log_bili", "log_protime", "edema")
  d <- d[, c("time", "status", covs)]
  idx <- sample(seq_len(nrow(d)), round(2/3 * nrow(d)))
  train <- d[idx, ]
  test <- d[-idx, ]
  for (cv in list(covs, c("age", "edema"))) {
    formula <- stats::reformulate(cv, response = "survival::Surv(time, status)")
    fit <- survival::coxph(formula, train, x = TRUE, y = TRUE)
    p <- pa_predict_coxph(fit, cv, new_data = test)
    ordered <- test[order(test$time), ]
    ref <- survival::survfit(fit, newdata = ordered, se.fit = FALSE)
    expected <- t(summary(ref, times = ordered$time, extend = TRUE)$surv)
    expect_equal(unname(p$surv_prob), unname(expected), tolerance = 1e-12)
    changed <- test
    changed$status <- 1L - changed$status
    perturbed <- pa_predict_coxph(fit, cv, new_data = changed)
    expect_identical(p$surv_prob, perturbed$surv_prob)
    expect_identical(p$pred, perturbed$pred)
  }
})

test_that("PBC figure consumers read current and historical saved predictions", {
  root <- skip_without_source_tree()
  path <- file.path(root, "figures", "original_format.R")
  skip_if_not(file.exists(path), "figure helpers are excluded from installed builds")
  helper <- new.env(parent = globalenv())
  sys.source(path, envir = helper)
  out <- tempfile("pbc_fit_")
  dir.create(file.path(out, "pbc"), recursive = TRUE)
  on.exit(unlink(out, recursive = TRUE), add = TRUE)
  expect_error(helper$paper_pbc_fit(out), "Missing PBC predictions")
  old <- file.path(out, "pbc", "pbc_comparison.rds")
  current <- file.path(out, "pbc", "pbc.rds")
  predictions <- list(Cox = list(pred = 1))
  saveRDS(list(after = predictions), old)
  expect_identical(helper$paper_pbc_fit(out), normalizePath(old))
  expect_identical(helper$paper_real_predictions(readRDS(old)), predictions)
  saveRDS(list(predictions = predictions), current)
  expect_identical(helper$paper_pbc_fit(out), normalizePath(current))
  expect_identical(helper$paper_real_predictions(readRDS(current)), predictions)
  expect_error(helper$paper_real_predictions(list()), "no predictions")
})

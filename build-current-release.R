stopifnot(getRversion() == "4.6.1")
expected <- strsplit(readLines("SHA256SUMS"), "  ", fixed = TRUE)[[1L]][1L]
stopifnot(identical(unname(as.character(tools::sha256sum("PAmeasures_2.0.0.tar.gz"))), expected))
root <- getwd()
dir.create("build-stage", showWarnings = FALSE)
dir.create("submission", showWarnings = FALSE)
untar("PAmeasures_2.0.0.tar.gz", exdir = "build-stage")
# Apply only the reviewed README correction and the installed-test guard.
stopifnot(file.copy("resubmission/README.md", "build-stage/PAmeasures/README.md", overwrite = TRUE))
stopifnot(file.copy("resubmission/test-paper-fhs-fit-path.R",
                   "build-stage/PAmeasures/tests/testthat/test-paper-fhs-fit-path.R", overwrite = TRUE))
writeLines(R.version.string, "submission/R-build-version.txt")
setwd("build-stage")
output <- system2(file.path(R.home("bin"), "R"), c("CMD", "build", "PAmeasures"),
                  stdout = TRUE, stderr = TRUE)
setwd(root)
writeLines(output, "submission/R-build.log")
cat(output, sep = "\n")
status <- attr(output, "status")
if (!is.null(status) && status != 0L) {
  message <- gsub("%", "%25", paste(tail(output, 12L), collapse = " | "), fixed = TRUE)
  cat("::error title=R release build::", message, "\n", sep = "")
  stop("R CMD build failed")
}
stopifnot(file.copy("build-stage/PAmeasures_2.0.0.tar.gz", "submission/PAmeasures_2.0.0.tar.gz"))

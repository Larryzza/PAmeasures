cat(R.version.string, "\n")
print(Sys.which(c("pdflatex", "makeindex", "pandoc", "tidy")))
stopifnot(nzchar(Sys.which("pandoc")), nzchar(Sys.which("tidy")),
          requireNamespace("V8", quietly = TRUE))
result <- rcmdcheck::rcmdcheck(
  path = "submission/PAmeasures_2.0.0.tar.gz",
  args = c("--as-cran", "--run-donttest"),
  check_dir = "check", error_on = "never", quiet = FALSE)
summary <- list(R = R.version.string, platform = R.version$platform,
  source_sha256 = as.character(tools::sha256sum("submission/PAmeasures_2.0.0.tar.gz")),
  errors = result$errors, warnings = result$warnings, notes = result$notes)
stopifnot(identical(unname(summary$source_sha256), Sys.getenv("SOURCE_SHA256")))
jsonlite::write_json(summary, "check-summary.json", pretty = TRUE, auto_unbox = TRUE)
public_summary <- list(R = summary$R, platform = summary$platform,
  source_sha256 = summary$source_sha256, errors = length(summary$errors),
  warnings = length(summary$warnings), notes = length(summary$notes))
cat("::notice title=Source tarball check summary::",
    jsonlite::toJSON(public_summary, auto_unbox = TRUE), "\n", sep = "")
for (kind in c("errors", "warnings", "notes")) {
  values <- summary[[kind]]
  for (value in values) {
    value <- gsub("%", "%25", value, fixed = TRUE)
    value <- gsub("\r", "%0D", value, fixed = TRUE)
    value <- gsub("\n", "%0A", value, fixed = TRUE)
    cat("::notice title=R CMD check ", kind, "::", value, "\n", sep = "")
  }
}
stopifnot(length(result$errors) == 0L, length(result$warnings) == 0L)

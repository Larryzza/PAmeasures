cat(R.version.string, "\n")
print(Sys.which(c("pdflatex", "makeindex", "pandoc", "tidy")))
stopifnot(nzchar(Sys.which("pandoc")), nzchar(Sys.which("tidy")),
          requireNamespace("V8", quietly = TRUE), requireNamespace("xml2", quietly = TRUE))
stopifnot(tolower(Sys.getenv("_R_CHECK_CRAN_INCOMING_CHECK_FILE_URIS_")) == "true")
# Check links in the extracted submission archive, rather than the full repository.
check_readme_file_uris <- function(dir) {
  dir <- normalizePath(dir)
  wd <- getwd(); setwd(dir); on.exit(setwd(wd))
  db <- get("url_db_from_package_README_md", asNamespace("tools"))(dir)
  stopifnot(nrow(db) > 0L)
  parts <- get("parse_URI_reference", asNamespace("tools"))(db$URL)
  local <- which(parts[, "scheme"] %in% c("", "file"))
  missing <- local[!file.exists(file.path(dir, dirname(db$Parent[local]), parts[local, "path"]))]
  if (length(missing)) stop("Invalid README file URIs: ", paste(db$URL[missing], collapse = ", "))
  cat("::notice title=README URI preflight::", nrow(db),
      " links parsed; 0 invalid file URIs; CRAN file-URI check enabled.\n", sep = "")
}
check_readme_file_uris("PAmeasures")
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

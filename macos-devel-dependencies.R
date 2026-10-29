# Install released dependencies from source and retain each compiler transcript.
options(warn = 1, Ncpus = 2L, timeout = 300)
d <- read.dcf("PAmeasures/DESCRIPTION")
fields <- intersect(c("Depends", "Imports", "LinkingTo", "Suggests"), colnames(d))
required <- trimws(unlist(strsplit(paste(d[1L, fields], collapse = ","), ",")))
required <- unique(sub("[[:space:]]*[(].*$", "", required))
required <- unique(c(setdiff(required[nzchar(required)], "R"),
                     "rcmdcheck", "tinytex", "jsonlite", "V8", "xml2"))
dir.create("dependency-install-logs", showWarnings = FALSE)
available <- vapply(required, requireNamespace, logical(1), quietly = TRUE)
writeLines(paste(required, available), "dependency-status-before.txt")
missing <- required[!available]
if (length(missing)) {
  message("Installing released sources: ", paste(missing, collapse = ", "))
  install.packages(missing, repos = "https://cloud.r-project.org", type = "source",
                   Ncpus = 2L, keep_outputs = "dependency-install-logs")
}
namespace_errors <- character()
available <- vapply(required, function(package) {
  tryCatch({loadNamespace(package); TRUE}, error = function(e) {
    namespace_errors <<- c(namespace_errors,
      paste0(package, ": ", conditionMessage(e)))
    FALSE
  })
}, logical(1))
writeLines(paste(required, available), "dependency-status-after.txt")
writeLines(namespace_errors, "dependency-namespace-errors.txt")
capture.output(sessionInfo(), file = "dependency-sessionInfo.txt")
if (any(!available)) stop("Unavailable dependencies: ",
                         paste(required[!available], collapse = ", "))

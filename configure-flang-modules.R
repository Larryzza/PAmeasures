# R-admin C.3.2.1 documents the intrinsic-module path for this R macOS toolchain.
modules <- "/opt/R/flang-23/lib/clang/23/finclude/flang/arm64-apple-darwin22.6.0"
stopifnot(file.exists(file.path(modules, "iso_fortran_env.mod")))
flags <- system2(file.path(R.home("bin"), "R"), c("CMD", "config", "FCFLAGS"),
                 stdout = TRUE, stderr = TRUE)
status <- attr(flags, "status")
if (!is.null(status) && status != 0L) stop("Cannot read R Fortran flags")
original <- Sys.getenv("R_MAKEVARS_USER", path.expand("~/.R/Makevars"))
previous <- if (file.exists(original)) readLines(original, warn = FALSE) else character()
makevars <- file.path(Sys.getenv("RUNNER_TEMP"), "flang-module-Makevars")
configuration <- c(previous, paste("FCFLAGS =", paste(flags, collapse = " "),
                                   "-fintrinsic-modules-path", modules))
writeLines(configuration, makevars)
writeLines(configuration, "flang-module-config.txt")
cat("R_MAKEVARS_USER=", makevars, "\n", file = Sys.getenv("GITHUB_ENV"),
    append = TRUE, sep = "")

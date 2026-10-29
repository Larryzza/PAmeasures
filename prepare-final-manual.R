root <- file.path(Sys.getenv("RUNNER_TEMP"), "TinyTeX")
tinytex::install_tinytex(dir = root, add_path = FALSE, extra_packages = NULL)
bins <- unique(c(file.path(root, "bin", "windows"),
                 list.dirs(file.path(root, "bin"), recursive = FALSE)))
bins <- bins[dir.exists(bins)]
Sys.setenv(PATH = paste(c(bins, Sys.getenv("PATH")), collapse = .Platform$path.sep))
writeLines(bins, Sys.getenv("GITHUB_PATH"), useBytes = TRUE)
tinytex::tlmgr_install(c("inconsolata", "helvetic", "times", "courier",
                        "ec", "cm-super", "ae", "texinfo", "makeindex"))
stopifnot(nzchar(Sys.which("pdflatex")), nzchar(Sys.which("makeindex")))
writeLines("\\indexentry{PAmeasures}{1}", "index-smoke.idx")
status <- system2(Sys.which("makeindex"), "index-smoke.idx",
                  stdout = "index-smoke.stdout", stderr = "index-smoke.stderr")
stopifnot(status == 0L, file.exists("index-smoke.ind"))

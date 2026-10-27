# Manuscript figure refresh

The package analysis and plotting entry points remain in `analysis/` and
`figures/`. This directory carries the additional figure-refresh driver from
the original outer manuscript directory.

From the repository root:

```sh
Rscript --vanilla manuscript/update_all_figures.R \
  --manuscript-dir=/path/to/manuscript \
  --sim-output=/path/to/completed/results/simulations/ici_crn \
  --real-output=/path/to/completed/real-data-run
```

The manuscript directory must contain `main.new.tex`. Saved results are local
inputs and are not distributed in Git. Relative input paths are relative to
the working directory. If omitted, simulation results are read from this
checkout's `results/simulations/ici_crn`; the real-data run is selected through
this checkout's `results/real_data/paper/source_manifest.csv`.

In RStudio, source the driver and supply the paths explicitly:

```r
source("manuscript/update_all_figures.R")
update_all_figures(
  manuscript_dir = "/path/to/manuscript",
  sim_output = "/path/to/completed/results/simulations/ici_crn",
  real_output = "/path/to/completed/real-data-run"
)
```

The driver loads PAmeasures from this checkout and redraws all seven figures
from saved results. It checks inputs, stages the complete figure set, backs up
existing manuscript figures and then replaces them. It does not rerun
simulations or fit prediction models. Passing an existing manuscript directory
will update its figure files; use a copied manuscript directory to review.

All package dependencies plus `pkgload` must be available in the R session.
No machine-specific temporary library is added by the migrated driver.

## Earlier helpers

`legacy/` preserves unchanged copies of `redraw_figures_tables.R`,
`sim2_r2_components.R` and their README. They reference historical TimeMetric
sources and results, including files absent from this checkout. They are
provenance material, not supported PAmeasures entry points. Use the current
driver above or `figures/` for new work.

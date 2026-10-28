# Reproducing the paper analyses

This guide covers the tutorial's simulations and three real-data examples.
To evaluate your own predictions, start with the package examples in the
[README](https://github.com/Larryzza/PAmeasures#quick-start).
The analysis scripts are provided in the GitHub repository, separately from
the installed CRAN package. Saved results are not distributed in Git.

## 1. Obtain the code and dependencies

Clone the repository with Git, then run the analysis commands from its root:

```sh
git clone https://github.com/Larryzza/PAmeasures.git
cd PAmeasures
```

Alternatively, download and extract the repository ZIP from GitHub, then
set the working directory to the extracted repository root. The standard
paper workflow does not require Git history. Record the code revision or
release used when reporting results.

Use R >= 4.1.0 and install the package and additional analysis dependencies:

```r
install.packages(c("PAmeasures", "pkgload", "cmprsk",
                   "randomForestSRC", "riskCommunicator"))
```

Installing PAmeasures also installs its required dependencies. The scripts
load the package code from this clone using `pkgload`, so the calculations
use the checked-out source. If working with a development revision, check
`DESCRIPTION` for any additional or updated dependencies. Individual
dependencies may require a newer R version or compilation tools.

The real-data scripts load datasets from these R packages; no separate
clinical data files need to be supplied for these examples:

| Example | Data source | Setting |
|---|---|---|
| PBC | `survival::pbc` | Right-censored survival |
| Framingham | `framingham` in `riskCommunicator` | Competing risks; examination 3 as time zero, 12-year horizon |
| GBSG2 | `pec::GBSG2` | Case-cohort sampling example |

## 2. Check the setup and run the analyses

First run the preflight check. It checks dependencies, loads the local
package, and does not fit models:

```sh
Rscript --vanilla figures/run_all.R
```

Then run all three real-data analyses and all four simulation parts
(Simulation 1, the linear and nonlinear parts of Simulation 2, and
Simulation 3; 100 repetitions per simulation cell):

```sh
Rscript --vanilla figures/run_all.R --mode=full --output=results/reruns/paper_run
```

This is a substantial computation, rather than a quick package example.
Runtime depends on the machine and available resources. Keep the saved
models and checkpoints if you want to resume simulations.

In RStudio, set the working directory to the repository root and use:

```r
source("figures/run_all.R")
run_all() # preflight only
run_all(mode = "full", output = "results/reruns/paper_run")
```

If dependencies are installed in a custom library, add it to `.libPaths()`
before calling `run_all()` in RStudio, or set `R_LIBS` before launching
`Rscript`. The unified runner passes its library paths to the child sessions.

## 3. Locate and check the results

Under `results/reruns/paper_run/`, the runner writes:

| Location | Contents |
|---|---|
| `real_data/` | Real-data fits, predictions, metrics and diagnostics |
| `paper/` | Real-data manuscript figures and tables, with their source manifest |
| `simulations/` | Simulation models, checkpoints, metric tables and figures |
| `run_all_status.csv` | Exit codes for the real-data and simulation steps |

The runner attempts both steps even if one fails. Check `run_all_status.csv`
and the individual status and diagnostic files before treating a run as
complete. A generated figure alone does not establish completion.

Simulation 3 can produce a figure while returning a nonzero status when ICI
cannot be estimated in some repetitions. See the
[simulation guide](simulation-ici.md) for diagnostics and finite-count files.

Repeating the full command resumes unchanged simulation checkpoints; the
real-data models are fitted again. Use a new output directory after changing
source code, settings or dependency versions, or when starting an independent
run. Outputs from different computation versions must not be mixed.

## 4. Optional: render a report of completed results

Install `rmarkdown` and `knitr`, and ensure Pandoc is available. From R at the
repository root, render the saved figures and tables with explicit paths:

```r
install.packages(c("rmarkdown", "knitr"))
rmarkdown::render(
  "paper.code.Rmd",
  output_dir = "results/report",
  params = list(
    simulation_output = "results/reruns/paper_run/simulations",
    real_paper_output = "results/reruns/paper_run/paper"
  )
)
```

Rendering does not fit models or run simulations. The report requires all
four full simulation parts with complete finite metrics and all three
real-data exports. It rejects incomplete runs, including runs with missing
ICI repetitions, even when a simulation figure is available.

For simulation-only runs, repetition selection, or redrawing saved simulation
figures, see the [simulation guide](simulation-ici.md).

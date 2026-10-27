# Updated TimeMetric figures and tables

For the current manuscript including ICI, use `update_all_figures.R` instead.
It refreshes all seven figures beside `main.new.tex`; see
[README_update_all_figures.md](README_update_all_figures.md).
The workflow below is retained for the earlier results.

`redraw_figures_tables.R` reads the original results and creates outputs under
`updated_figures_tables/`. It does not edit the original R package, Rmd, CSVs,
figures, or manuscript.

## Run from RStudio

```r
source("/Users/zianzhuang/Dropbox/zza/UCLA/research/Dr. Li's GSR/TimeMetric__SIM_/redraw_figures_tables.R")
redraw_timemetric()
```

To run only one part:

```r
redraw_timemetric(section = "simulations")
redraw_timemetric(section = "real")
```

## Run from a terminal

```bash
Rscript "/Users/zianzhuang/Dropbox/zza/UCLA/research/Dr. Li's GSR/TimeMetric__SIM_/redraw_figures_tables.R"
```

Optional arguments: `--section=simulations`, `--section=real`,
`--code-dir=/path/to/TimeMetric`, `--component-dir=/path/to/sim2_r2_update`,
and `--output-dir=/path/to/new/outputs`.

## Simulation figures

- `figures/paper.fig4.updated.pdf`: Simulation 1, with the retired metric removed.
- `figures/paper.fig5.updated.pdf`: linear Simulation 2, with pseudo-R-squared
  bars, R-squared filled dots, and L-squared open circles.
- `figures/paper.fig5.2.updated.pdf`: nonlinear Simulation 2, using the same
  component display for RF, Cox, and Ln, all from the existing result CSV.
- `figures/paper.fig6.updated.pdf`: Simulation 3, with the retired metric removed.

There are no numerical annotations on the bars, component legends, or explanatory
sentences inside the figures; describe the bars and points in the manuscript
captions. Original title wording, bold headings, model order, figure dimensions,
axis-label sizes and angles, bar widths, and the `(a)`/`(b)`/`(c)` censoring labels
are retained from `paper.code.Rmd`. Figure 5 uses 10 by 6.36 inches and Figure 5.2
uses 8 by 5.09 inches, both keeping the original Figure 5.2 aspect ratio. Figure
5.2's larger canvas reduces the relative text size at a fixed publication width.
Only the requested retired-metric removal,
component dots, and removal of bar-value labels change the display.
All three quantities are averaged separately over repetitions; the scalar bar
is the mean of the per-repetition products, not the product of the component means.

The linear Simulation 2 figure requires all 100 component repetitions from
`sim2_r2_components.R`. Until then, the script skips that figure and records
the pending status in `checks/run_status.csv`. It never presents three repetitions
as a completed 100-repetition analysis. Before drawing the completed figure,
all 400 scalar results are checked against the original two-decimal CSV.

## Real-data tables

The script repeats the original data processing, seeds, splits, model fits,
prediction routines, and evaluation horizons from `paper.code.Rmd`. It requests
explicit metric lists from `pam.summary()`, `pam.summary_cr()`, and
`pam.sample_design()`, adding the two components and excluding the removed metrics
and all point-version R-squared measures.

For PBC, Framingham, and GBSG2, it exports:

- `tables/*_metrics.csv`: numeric results.
- `tables/*_metrics.tex`: booktabs tabulars, displayed to two decimal places.
- `tables/*_metrics.md`: readable tables.
- `tables/analysis_settings.csv`: analysis sample sizes, requested probability
  horizons, and the grid times actually used for probability evaluation.

The current package internally rounds the GBSG2 weighted R-squared components
to two decimal places even when the outer `digits` argument is four. Those
values are retained, rather than suggesting additional precision.

These are regenerated analyses using the currently installed package and data.
Old manuscript values and captions should be checked before replacing them.
In particular, the current original Framingham Rmd block also differs from the
manuscript's old table: its pseudo-R-squared values round to 0.21, 0.12, 0.21,
and 0.17. Explicitly requesting the components gives the same retained scalar
metrics; `checks/framingham_default_metric_check.csv` verifies this.
The cause was subsequently traced to the random seed: rerunning the original
Framingham block with seed 2025 reproduces all 16 retained values in the old
manuscript table, whereas the current Rmd uses seed 1234567. The script continues
to follow the current Rmd and does not silently switch seeds.

The PBC default requests the test-set median (1829 days in the current run),
then evaluates at the nearest observed grid time (1827 days). The manuscript
caption previously stated 2182 days. The revised caption states the nearest-time
rule and reports 1829 days as the test-set median, using only one number.
`analysis_settings.csv` records the requested and actual evaluation times;
the underlying evaluation calculation has not changed.
With seed 2025, the PBC test-set median is 2181.5 days (2182 when rounded),
confirming that this caption corresponds to a different split.

The three existing real-data figure drawing streams were reproduced exactly:
PBC and FHS use seed 1234567, and GBSG2 uses seed 2025. The revised FHS table in
`main.new.tex` therefore follows seed 1234567 and includes the two components;
Figure 2 is retained. The FHS prose now reflects the current last-available-visit
selection and the reduced model's `DIABP` covariate (diastolic blood pressure).

Both the `pec` and `TH.data` GBSG2 help pages define `time` as recurrence-free
survival time and `cens` as the event indicator (0 censored, 1 event). The Figure 3
and case-cohort table captions in `main.new.tex` use recurrence-free survival.
The figure data and sampling settings have not changed, so no new real-data
plotting routine is needed for these caption corrections.

## Paths containing spaces

Some R launchers represent spaces in the `--file` argument as `~+~`. Both scripts
now decode that representation before locating their output directory and require
the resolved script file to exist. The completed 100-repeat results from the
accidentally encoded directory have been copied to the normal `sim2_r2_update/`
directory; all 400 precision comparisons passed. The misplaced copy was preserved,
and the previous three-repeat directory was backed up as
`sim2_r2_update_first3_backup/`.

The two RStudio lines above belong in the R Console. At a shell prompt such as
`username@computer folder %`, use the terminal `Rscript` command instead. If the
shell shows `function>`, press Ctrl+C to cancel the incomplete shell expression.

## Scope and checks

The existing real-data scatterplots (Figures 1--3) have no retired metric panels
and are not regenerated by this script. The script does not change the package's
prediction, censoring adjustment, or case-weight implementation. Thus the new
tables preserve the existing analysis pipeline; this task is not a comprehensive
validation of those methods.

The `checks/` folder records R/package versions, output status, source-file
preservation, and the available precision comparisons. To adopt the new output,
review it first, then update the manuscript figure paths and table contents.

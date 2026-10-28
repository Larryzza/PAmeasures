# Running the paper simulations

For repository setup, dependencies, and the combined simulation and real-data
workflow, see the [paper reproduction guide](reproduce-paper.md).
Run the following commands from the repository root.

## Run simulations separately

Print the job plan without fitting models or evaluating predictions:

```sh
Rscript --vanilla figures/run_simulations.R --mode=plan
```

Run all four simulation parts with 100 repetitions per cell:

```sh
Rscript --vanilla figures/run_simulations.R --mode=full --output=results/simulations/paper_run
```

The simulations use right-censored data and include ICI evaluated with
`pa_calibration()` using a five-knot Cox spline calibration curve at each
job's specified horizon. The paper's competing-risk and sampling-design
examples are covered by the real-data scripts rather than these simulations.

To run selected parts or repetitions, append selectors to the full command:

```sh
Rscript --vanilla figures/run_simulations.R --mode=full --output=results/simulations/selected_run --part=sim2_linear,sim2_nonlinear --repeats=1:10
```

A selected subset is useful for exploring the workflow, but does not replace
the full paper run. Keep subsets in a separate output directory. Repeat the
same command to resume unchanged checkpoints; use a new output directory
when source code, settings or dependency versions change.

## Outputs and completion

The simulation output directory contains:

- `tables/metrics_raw.csv` and `tables/metrics_summary.csv`: individual and
  aggregated metric values, including ICI.
- `tables/calibration_diagnostics.csv`: evaluation horizons, calibration
  methods, warnings and errors for each job and model.
- `tables/sim3_references.csv`, `sim3_errors.csv` and `sim3_accuracy.csv`:
  Simulation 3 reference and error summaries. The reference is the mean from
  the larger uncensored test samples; it is not assumed to be zero.
- `run_status.csv` and `completion.csv`: run status and completion records.
- Saved models, resumable checkpoints, and figures in `figures/`.

Calibration failures retain the other metrics and record a missing ICI with
a warning. Such jobs are incomplete and are retried when the run resumes.
Check status and diagnostic files before using results as final paper output.

In Simulation 3, ICI is not estimable when no test subject is followed to the
requested horizon (`at_risk = 0` in the calibration diagnostics). If these are
the only missing values, Figure 6 can still be generated using the finite
repetitions. The affected cells and counts are recorded in
`figures/paper.fig6.partial_repetitions.csv`; report these counts when using
that figure. The computation still returns a nonzero status, and the HTML
report rejects incomplete results. A figure's existence does not mean every
repetition succeeded.

Other incomplete simulation parts can receive preview figures under
`figures/original_format_preview/`, with replication counts. These are not
complete paper results.

## Redraw completed simulation figures

The simulation runner generates figures automatically. To redraw saved
results without fitting models or rerunning simulations:

```sh
Rscript --vanilla figures/redraw_original.R --section=simulations --sim-output=results/simulations/paper_run
```

For report rendering after a combined run, follow the
[paper reproduction guide](reproduce-paper.md#4-optional-render-a-report-of-completed-results).

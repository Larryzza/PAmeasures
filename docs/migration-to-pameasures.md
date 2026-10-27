# PAmeasures development migration

Date: 2026-10-26 (America/Los_Angeles)
Target: PAmeasures 2.0.0
Development snapshot: 2.0.0.9000
Repository: https://github.com/Larryzza/PAmeasures (initially private)

## Baselines and provenance

* TimeMetric `paper` commit:
  `f9fd19f73d7abefc8cb1c54c415ce99c1fd96ba0`.
* The imported commit history is retained. Tag
  `timemetric-paper-baseline-2026-10-26` identifies the unmodified starting
  point. Only this branch's ancestry is imported into the new main branch.
* The local TimeMetric-paper checkout is unchanged. Its upstream repository
  is https://github.com/toz015/TimeMetric.
* Original PAmeasures source:
  https://cran.r-project.org/src/contrib/Archive/PAmeasures/PAmeasures_0.1.0.tar.gz.
  Historical DESCRIPTION, NAMESPACE and archive SHA-256 are recorded under
  `docs/provenance/`. This migration does not restore its old API.

## Scope of this first step

The package name, active namespace references, package-level help, citation,
repository URLs, installation examples and test bootstrap now use PAmeasures.
The current `tm_` functions, arguments and return structures remain in place.
No estimator, seed, test expectation or numerical fixture is intentionally
changed. Historical TimeMetric NEWS and audit evidence retain their original
names and versions.

While the repository is private, `remotes::install_github()` requires GitHub
credentials with repository access. Alternatively, clone using an authorized
SSH key and run `remotes::install_local("/path/to/PAmeasures")` locally.

The package is distributed under GPL-3 with the original TimeMetric MIT
notices preserved. Xiaoyan Wang's original authorship is retained. The current
TimeMetric maintainer is carried forward provisionally; the GitHub owner is
Larryzza, and this does not assert that CRAN has approved a maintainer change.

## Function coverage decisions

PAmeasures 0.1.0's public functions were `pam.nlm()`, `pam.censor()`,
`pam.coxph()` and `pam.survreg()`, plus the `moore` dataset. The current package
focuses on survival prediction evaluation; it retains `moore` and the
survival-related implementations, but does not export those four historical
interfaces. In particular, the nonlinear-regression `pam.nlm()` interface is
not included. Full feature equivalence with 0.1.0 is not claimed.

The deprecated aliases in `R/deprecated.R` preserve earlier TimeMetric script
entry points. They are not a PAmeasures 0.1.0 compatibility layer.

## Manuscript and results

`analysis/`, `figures/`, `paper.code.Rmd` and the working JOSS draft are retained.
`manuscript/update_all_figures.R` is adapted from the outer manuscript directory
and takes an explicit manuscript path. Earlier helpers are preserved verbatim
under `manuscript/legacy/` for provenance; they need historical inputs.

Generated results, saved clinical predictions and the outer manuscript itself
are not uploaded. Existing outputs remain in the original local checkout.
Source/version fingerprints differ after renaming, so simulation resumption
requires a new output directory; do not mix migrated and old checkpoints.
No full simulations or clinical analyses are rerun as part of this rename.

## Validation

Validation results for this migration are recorded in
`docs/validation/pameasures-migration-2026-10-26.md`.

## Pending release decisions

* Confirm withdrawal/status of the separate TimeMetric CRAN submission.
* Complete the PAmeasures maintainer handover and choose the monitored email;
  update Authors@R when that decision is made.
* Finalize the intended feature scope and any future function-prefix changes.
* Review the inherited JOSS draft: update the metric-availability table,
  remove historical claims for retired metrics, and finalize AI usage
  disclosure and publication authorship with the human authors.
* Verify current R release/devel across Linux, macOS and Windows using CI.
* Finalize release metadata and cran-comments.md before CRAN submission.
* Decide when to make the repository public and how to document continuity
  with the prior public project for JOSS.

No CRAN submission, maintainer change or public release is performed by this
initial migration.

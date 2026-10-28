# PAmeasures development migration

Date: 2026-10-26 (America/Los_Angeles)
Package version: PAmeasures 2.0.0
Initial snapshot: 2.0.0.9000
Last development snapshot: 2.0.0.9002
Repository: https://github.com/Larryzza/PAmeasures (initially private)

The current public API uses `pa_`, with `pam.nlm()` retained for historical
continuous-outcome calls. See [the API transition guide](pa-api-transition.md)
for current names and compatibility rules. The initial migration validation
report describes the earlier 2.0.0.9000 state. Historical validation reports
retain the versions they checked; they are not checks of the 2.0.0 release
tarball.

Historical commit IDs in older reports refer to the pre-cleanup history or
the original TimeMetric repository. Local baseline tags have been rewritten
to exclude R workspaces; the old-to-new mapping is in
`docs/provenance/workspace-history-map-2026-10-26.tsv`.

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
The original migration retained `tm_`; the subsequent API step renames those
functions to `pa_` while retaining their arguments, computations and return
structures. It also restores continuous-outcome assessment with `pa_nlm()`.
No estimator, seed, test expectation or numerical fixture is intentionally
changed. Historical TimeMetric NEWS and audit evidence retain their original
names and versions.

While the repository is private, `remotes::install_github()` requires GitHub
credentials with repository access. Alternatively, clone using an authorized
SSH key and run `remotes::install_local("/path/to/PAmeasures")` locally.

The package is distributed under GPL-3 with the original TimeMetric MIT
notices preserved. Xiaoyan Wang's original authorship is retained.

## Function coverage decisions

PAmeasures 0.1.0's public functions were `pam.nlm()`, `pam.censor()`,
`pam.coxph()` and `pam.survreg()`, plus the `moore` dataset. The current package
retains `moore`, restores `pam.nlm()` alongside numeric `pa_nlm()`, and exposes
survival capabilities through the `pa_` interfaces. The other three historical
function names are not exported. Full API compatibility with 0.1.0 is not
claimed. Earlier TimeMetric script aliases have been removed; `pam.nlm()` is
the sole supported historical public name.

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

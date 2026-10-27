# PAmeasures initial migration validation

Date: 2026-10-26 (America/Los_Angeles)
Package: PAmeasures 2.0.0.9000
Baseline: TimeMetric paper commit f9fd19f73d7abefc8cb1c54c415ce99c1fd96ba0
Environment: R 4.5.0, aarch64-apple-darwin20, macOS 26.6.2

## Results

| Check | Result |
|---|---|
| Source test suite | 195 tests, 930 assertions; 0 failed assertions, errors, test warnings or skips |
| Saved-result manuscript integration | 1 test, 17 assertions; 0 failures, errors, test warnings or skips |
| Required-dependency installed-package smoke | All six default two-phase metrics finite, including ICI in [0, 1] |
| Numerical equivalence | All 12 result groups exactly identical to the starting TimeMetric source |
| Computation source preservation | All 23 computational R files byte-identical |
| Data and numerical reference preservation | moore data, metric fixtures and all existing snapshots byte-identical |
| Package build | Successful; approximately 138 KB source tarball |
| Installation | Successful; package and namespace load/unload checks pass |
| R CMD check | 0 errors, 0 warnings, 2 NOTEs |
| Entry points | Simulation plan, figure-driver help, R syntax and workflow YAML parsing pass |
| Original checkout | Still on paper at the baseline, with no local changes |

Raw evidence is in [pameasures-migration-2026-10-26/](pameasures-migration-2026-10-26/).
The local testthat installation prints a startup warning because it was built
under R 4.5.2 while the local interpreter is 4.5.0; this is separate from the
zero test warnings reported above.

## Package check conditions

The tested command was:

```sh
_R_CHECK_CRAN_INCOMING_REMOTE_=false \
  R CMD check --as-cran --no-manual --run-donttest PAmeasures_2.0.0.9000.tar.gz
```

The two NOTEs concern the intentional development version component `9000`
and inability to verify the current time through the external time service.
The package installation, examples, installed-package tests and documentation
checks pass. The PDF manual was not compiled because LaTeX is unavailable.
Remote CRAN incoming checks were disabled for this private development
repository; this is not evidence of CRAN submission approval or URL acceptance.

Dependencies were installed only into `/tmp/pameasures-migration-lib`, leaving
the user's system R library unchanged. R release/devel checks on other
platforms still need to be confirmed by the copied GitHub workflows.

Validated source tarball SHA-256:

```text
278d8c52ee6dd3f76053e80a881eacba33af977d3774ac52e05f22cf21c36285
```

The artifact is local at
`/tmp/pameasures-migration-validation/PAmeasures_2.0.0.9000.tar.gz`; it is not
committed to Git. Documentation and migration evidence under `docs/` are
excluded from the package tarball.

## Numerical comparison

The two package namespaces were loaded from their respective source trees.
With identical seeds, data and fitted-model inputs, exact `identical()`
comparisons pass for simulated data, Cox predictions, AFT predictions,
cohort summaries, ordinary calibration, case-cohort weights, NCC weights,
two-phase evaluation, weighted calibration, competing-risk predictions,
competing-risk summaries and competing-risk calibration. No tolerance changes
or reference-value updates were made.

To reproduce with both checkouts available:

```sh
Rscript --vanilla docs/validation/compare-migration.R \
  /path/to/PAmeasures /path/to/TimeMetric-paper
```

The original PAmeasures 0.1.0 interfaces were not part of this compatibility
comparison. No full manuscript simulations or clinical analyses were rerun.

## Repository checks

The main branch preserves the TimeMetric paper ancestry and a baseline tag.
The package namespace exports the same 34 functions as the starting package
under the PAmeasures package identity. Active tests, analysis and plotting
references use PAmeasures. Historical audit logs and archived manuscript
helpers retain their original TimeMetric references intentionally.

Generated results and clinical inputs are not added. The package tarball
excludes analysis, figures, manuscript, results and audit directories, and
includes GPL-3 text, historical MIT notices and source copyright records.
The copied coverage workflow saves a report and uploads to Codecov only when
the new repository has a CODECOV_TOKEN configured.

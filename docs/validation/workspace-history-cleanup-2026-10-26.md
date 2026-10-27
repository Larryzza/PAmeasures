# Workspace history cleanup verification

Date: 2026-10-26 (America/Los_Angeles).
Package version: PAmeasures 2.0.0.9002, unchanged.

## Historical rewrite

* The complete pre-cleanup repository was bundled outside the public source,
  verified with `git bundle verify`, restored and checked with `git fsck`.
* All 153 existing commits were retained. Author/committer names, email
  addresses, dates, commit messages and parent relationships under the
  mapping were compared individually and preserved. 148 commit IDs changed.
* Nine `.RData` workspace blobs and ten `.Rhistory` command-history blobs,
  including a conflicted copy, were removed across all refs.
* Every old/new commit tree was compared. All historical files other than
  the three session-file paths are byte-identical.
* The latest source tree was exactly identical before follow-up reference
  and documentation updates. Statistical implementation and numerical
  reference files were not changed.
* Both baseline tags are retained with cleaned ancestry. The commit mapping
  is recorded in `../provenance/workspace-history-map-2026-10-26.tsv`.

## Current-source validation

| Check | Result |
|---|---|
| Full source suite | 200 tests, 944 assertions; zero failed assertions, errors, test warnings or skips |
| Saved-result manuscript integration | 17 assertions pass |
| Historical Cox source reference | Resolves the rewritten baseline and loads successfully |
| Matched NCC comparison | Historical/current comparison and expected weights pass |
| Numerical comparison with original TimeMetric | All twelve result groups exactly identical |
| Simulation plan and figure-refresh help | Pass; no full simulations rerun |
| Repository-hygiene guard | Rejects original history and accepts cleaned history |
| Workflow syntax | Parses successfully |
| Credential pattern scan | No private-key blocks, GitHub-token patterns or AWS access-key-ID patterns found in reachable blobs |

The pattern scan is limited to those credential types and is not a guarantee
that all possible secrets are absent. No data values or credentials were
printed or copied into these public validation records.

The testthat installation emits its existing startup warning about having
been built under R 4.5.2 while the interpreter is R 4.5.0; the reported test
warnings remain zero. Prior full R package checks are recorded in
`pa-api-2026-10-26.md`. This operation changes Git history, analysis provenance
references, documentation and repository checks; the package version and
statistical functions remain unchanged.

Raw evidence is in
`workspace-history-cleanup-2026-10-26/`. No R session snapshots, private Git
backup bundles, raw datasets or fitted clinical models are included there.

## Publication boundary

The repository remains private. Removed files are absent from advertised
branch/tag ancestry. Server-side caches, old commit URLs, earlier Actions
artifacts and other people's clones are separate from that guarantee.
See `../workspace-history-cleanup.md` for GitHub Support and re-cloning notes.
The original TimeMetric-paper checkout and the upstream TimeMetric repository
are not rewritten.

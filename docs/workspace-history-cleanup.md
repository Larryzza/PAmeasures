# R workspace history cleanup

Date: 2026-10-26 (America/Los_Angeles).

Nine historical `.RData` blobs were found in the PAmeasures Git ancestry.
They contained saved R sessions, including datasets, fitted models, predictions
and functions. They were absent from the current source tree but still
downloadable through historical commits. These sessions are not part of the
distributed package or intended public reproducibility materials.

## Changes

All branches and tags were rewritten to exclude R session files: `.RData`,
`.Rhistory`, and a conflicted copy of `.Rhistory`. Nine workspace versions
and ten command-history versions were removed. All 153 existing commits were retained, including empty commits after
removal, preserving author/committer identities, timestamps, messages and
parent relationships under the old-to-new mapping. 148 commit IDs changed.
The first changed original commit was
`7bd1648c69327a4e596e20dc7e965b0d97e49993`.

Every rewritten commit was compared against its original tree: the only
removed paths were those three R session paths. All other historical file contents are unchanged.
Before the follow-up documentation/ref updates, the latest source tree was
exactly identical to the original tree.

The current analysis scripts now reference the rewritten historical comparison
commit. The local baseline tags retain their names. The complete mapping is
in `provenance/workspace-history-map-2026-10-26.tsv`; old IDs in archived
reports and references to upstream TimeMetric remain historical evidence.
The original TimeMetric repository and local TimeMetric-paper checkout were
not modified.

`.gitignore` continues excluding R session files. A new repository-hygiene
workflow checks all reachable history with a complete checkout, and rejects
R workspaces or command-history files. Legitimate package data such as
`data/moore.rda` and the numerical test fixtures are retained.

## Recovery and other clones

A complete private Git bundle, current-source archive, original refs, commit
mapping and checksums were saved outside this repository and tested for
restoration. They intentionally retain the old workspaces and must never be
published or pushed. Their location is recorded in the cleanup handoff.

Anyone with a PAmeasures clone from before the rewrite should make a new clone.
Do not merge or push the previous history: that would restore the removed
sessions. Transfer any uncommitted work as reviewed file patches. The local
TimeMetric-paper repository is a separate source project; do not merge its
complete history back into this cleaned repository.

## GitHub storage and visibility

History rewriting removes the sessions from advertised branch/tag ancestry.
It does not guarantee immediate physical deletion from GitHub storage,
cached commit URLs, prior Actions runs, artifacts, forks or other clones.
GitHub documents further cleanup through Support for sensitive data; Support
does not remove non-sensitive data on request.

The repository remains private during this operation. If the historical data
must be inaccessible even through old commit URLs, resolve cached-object
removal with GitHub Support before changing visibility. A clean clone cannot
establish server-side cache deletion. No support ticket or external message
was sent by this cleanup.

Reference:
https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository

Current verification results are in
`validation/workspace-history-cleanup-2026-10-26.md`.

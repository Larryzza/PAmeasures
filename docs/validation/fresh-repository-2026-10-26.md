# Fresh GitHub repository verification

Date: 2026-10-26 (America/Los_Angeles).
Repository: Larryzza/PAmeasures.

After the first repository's history was cleaned, its server still returned
the old main commit through an authenticated metadata-only fetch. A newly
created empty repository at the same owner/name was therefore used to receive
only the already-cleaned local history.

## Checks performed

* The replacement repository advertised no refs before upload.
* The cleaned main branch and two cleaned baseline tags were uploaded without
  force-pushing.
* A fresh mirror was downloaded from the new repository and passed `git fsck`.
* The verified code snapshot was
  `bcbcd79c36d3ebd5d2256e647cf2f675148d8199`, with 154 commits at that point.
* All three advertised refs matched the intended local refs.
* No R workspace or command-history paths remained in reachable history.
* None of the nineteen removed session objects existed in the fresh mirror's
  object database.
* Metadata-only fetches of the old main
  `e850f173ef00706f4adaed0db9e33986330d444f` and the first changed original
  commit `7bd1648c69327a4e596e20dc7e965b0d97e49993` were rejected by the new
  GitHub endpoint as unavailable. These were explicit object-unavailability
  errors, not authentication or network failures.

Machine-readable results are in
`fresh-repository-2026-10-26.json`. This documentation is recorded in a
subsequent commit; no package functions or numerical references changed.
The prior 200-test, 944-assertion package validation remains applicable to
the unchanged code snapshot.

## Visibility and scope

The replacement repository remained private during verification. No visibility
setting was changed by the upload. Based on these checks, the new repository
can be published as the PAmeasures 2.0 development line; it is not a CRAN release.

Any earlier GitHub repository retained as a backup must remain private. This
verification does not erase its server-side objects or caches, other people's
clones, or the upstream TimeMetric repository. The previous Support request
draft concerns that earlier repository identity, not this fresh repository.

The normal local PAmeasures path and origin URL remain unchanged. Private
recovery bundles stay outside the Git repository and must never be pushed.

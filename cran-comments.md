## Submission

This is a new submission. It has not been submitted yet: the version is still
0.0.0.9000 and must be set to a release number first.

## R CMD check results

Local, macOS 26.6.1, R 4.4.2, `R CMD check --as-cran`: 0 errors, 0 warnings,
3 notes.

* New submission. Version contains large components (0.0.0.9000).
  Expected for an unreleased development version.
* Problems with news in 'NEWS.md': No news entries found.
  The top heading is "(development version)", which R does not parse as a
  version. It will carry the version number at release.
* Unable to verify current time. A local network issue, not from the package.

## Test environments

* GitHub Actions (R CMD check workflow): macOS, Windows and Ubuntu on R
  release; Ubuntu on R devel and R oldrel-1.
* win-builder, R-devel and R-release: uploaded 2026-11-22, results pending
  (emailed to the maintainer).
* macOS builder: not run. The service returned HTTP 502 on 2026-11-22.
* R-hub: not run yet. Its workflow starts only from the default branch.

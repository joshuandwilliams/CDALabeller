## Submission

This is a new submission.

## R CMD check results

Local, macOS 26.6.1, R 4.4.2, `R CMD check --as-cran`: 0 errors, 0 warnings,
3 notes.

* New submission.
* Unable to verify current time. A local network issue, not from the package.
* HTML version of manual: "<main> is not recognized". The local HTML Tidy is
  Apple's 2006 build, which predates HTML5. R-hub reported no notes on any
  platform.

## win-builder notes

* New submission.

  Possibly misspelled words in DESCRIPTION: Agroinfiltration,
  agroinfiltration, CDA, CDAs.
  These are spelled correctly. Agroinfiltration is the method of infiltrating
  plant leaves with Agrobacterium. A CDA is a cell death area, the region of a
  leaf that the app labels, and CDAs is its plural.

* Found the following hidden files and directories: .git

  The uploaded tarball contains no .git file or directory. Listing it with
  `tar tzf CDALabeller_0.1.0.tar.gz` shows no entry containing "git". The binary
  that win-builder built records the same Packaged time as that tarball, so it
  was the file checked. A local `R CMD check --as-cran` of the same tarball,
  and R-hub's checks of the GitHub source, did not report this note.

## Test environments

* GitHub Actions (R CMD check workflow): macOS, Windows and Ubuntu on R
  release; Ubuntu on R devel and R oldrel-1. All passed.
* R-hub, R-devel on linux, windows, macos and macos-arm64 (run 2026-11-23):
  Status OK on all four.
* win-builder, R-devel (2026-11-17 r90926 ucrt) and R-release (4.6.2): 0 errors,
  0 warnings, 2 notes on both. See "win-builder notes" above.

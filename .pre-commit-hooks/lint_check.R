#!/usr/bin/env Rscript
# Lints the given R/Rmd files with lintr (using .lintr config) and fails on any lint.
args <- commandArgs(trailingOnly = TRUE)
n <- 0L
for (path in args) {
  lints <- lintr::lint(path)
  if (length(lints) > 0) {
    print(lints)
    n <- n + length(lints)
  }
}
if (n > 0) {
  message(sprintf("lintr: %d lint(s)", n))
  quit(status = 1)
}

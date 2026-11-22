
# CDALabeller <img src="man/figures/logo.png" align="right" height="120" alt="" />

<!-- badges: start -->

[![R CMD
check](https://github.com/joshuandwilliams/CDALabeller/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/joshuandwilliams/CDALabeller/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/joshuandwilliams/CDALabeller/graph/badge.svg)](https://app.codecov.io/gh/joshuandwilliams/CDALabeller)
[![lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
![R](https://img.shields.io/badge/R-%3E=4.0.0-1e90ff?logo=r)
![Shiny](https://img.shields.io/badge/built%20with-Shiny-00B2E1?logo=shiny)

<!-- badges: end -->

CDALabeller is an app for labelling cell death areas (CDAs) in
photographs of agroinfiltrated leaves. You draw a square around each
area and note its treatment. You also give it a score from 0 (no cell
death) to 6 (strong cell death). The app then saves your squares as a
CSV file. That file can be read by
[AutoCDAScorer](https://github.com/joshuandwilliams/AutoCDAScorer),
which scores cell death areas automatically.

## Installation

CDALabeller needs R 4.0.0 or later. Install it from GitHub with `pak`:

``` r
install.packages("pak")
pak::pak("joshuandwilliams/CDALabeller")
```

`pak` does not build the package’s guide (its vignette). To include the
guide, install with `remotes` instead:

``` r
install.packages("remotes")
remotes::install_github("joshuandwilliams/CDALabeller", build_vignettes = TRUE)
```

## Running the app

``` r
CDALabeller::run_app()
```

The app opens in your web browser. In Positron, it opens in the Viewer
pane instead. Closing the app’s tab stops the app, and any boxes you
have not downloaded are lost.

## What the app does

- **Upload.** Upload one or more TIFF images. Each file can be up to 200
  MB.
- **Draw.** Click and drag to draw a box around a cell death area. Each
  box is made square, so every area is cropped to the same shape.
- **Record.** Enter a treatment and a score for each box. A score key
  below the image shows example areas for each score.
- **Review.** Move between images with Previous and Next. Undo removes
  the last box you drew.
- **Download.** Save the boxes for all images as one CSV file.
- **Trace.** Each row records who drew the box and when they drew it. It
  also records the exact image file and the version of CDALabeller used.

## Guide

The guide explains each step and every column of the CSV file:

``` r
vignette("CDALabeller", package = "CDALabeller")
```

## Citing CDALabeller

``` r
citation("CDALabeller")
```

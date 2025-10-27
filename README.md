
# CDALabeller

<!-- badges: start -->

[![R CMD
check](https://github.com/%5BYOUR_USERNAME%5D/%5BYOUR_REPO%5D/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/%5BYOUR_USERNAME%5D/%5BYOUR_REPO%5D/actions/workflows/R-CMD-check.yaml)
[![codecov](https://codecov.io/gh/%5BYOUR_USERNAME%5D/%5BYOUR_REPO%5D/graph/badge.svg)](https://codecov.io/gh/%5BYOUR_USERNAME%5D/%5BYOUR_REPO%5D)
[![lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
![R](https://img.shields.io/badge/R-%3E=3.5.0-1e90ff?logo=r)
![Shiny](https://img.shields.io/badge/built%20with-Shiny-00B2E1?logo=shiny)

<!-- badges: end -->

The goal of `CDALabeller` is to provide a simple, interactive tool for
drawing bounding boxes and annotating cell death areas (CDAs) in
agroinfiltration images.

## Installation

You can install the development version of `CDALabeller` from
[GitHub](https://github.com/joshuandwilliams/CDALabeller) with:

``` r
install.packages("devtools")
devtools::install_github("joshuandwilliams/CDALabeller")
```

## Example

To run the application:

``` r
library(CDALabeller)
CDALabeller::run_app()
```

This will launch the Shiny application in your web browser.

## Features

- **Image Upload:** Upload one or more TIF/TIFF images for annotation.
- **Drawing:** Click and drag to draw bounding boxes. Boxes are
  automatically converted to squares to ensure uniform area selection.
- **Annotation:** Add “Treatment” and “Score” metadata to each box you
  draw.
- **Navigation:** Easily move between “Next” and “Previous” images in
  your uploaded set.
- **Undo:** Remove the last-drawn box with the “Undo Last Box” button.
- **Export:** Download all annotations for all processed images as a
  single, tidy CSV file. This file can is compatible with
  [AutoCDAScorer](https://github.com/joshuandwilliams/AutoCDAScorer)

library(testthat)
library(shiny)
library(magrittr)
library(magick)

source(testthat::test_path("../../R/server_utils.R"))

test_that("placeholder test", {
  expect_equal(1 + 1, 2)
})

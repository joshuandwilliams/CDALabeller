# Feeds a CDALabeller export into AutoCDAScorer::crop_and_load_images(), the
# function that reads it for scoring. Needs AutoCDAScorer, which is not on CRAN
# and pulls in keras3 and EBImage, so this runs in its own workflow
# (.github/workflows/integration.yaml) rather than in R CMD check. Run locally
# from the package root with testthat::test_dir("tests/integration").

testthat::skip_if_not_installed("AutoCDAScorer")

# A 600 x 400 grey image with a red square at (10, 20)-(110, 120) and a blue
# square in the bottom-right corner, (520, 320)-(600, 400). The export boxes
# those squares exactly, so each crop must be a single colour.
images_dir <- withr::local_tempdir()
img <- magick::image_blank(600, 400, "grey")
img <- magick::image_composite(img, magick::image_blank(100, 100, "red"), offset = "+10+20")
img <- magick::image_composite(img, magick::image_blank(80, 80, "blue"), offset = "+520+320")
magick::image_write(img, file.path(images_dir, "squares.tif"), format = "tiff")

files <- data.frame(name = "squares.tif", md5 = unname(tools::md5sum(file.path(images_dir, "squares.tif"))))
boxes <- list(squares.tif = list(
  list(x1 = 10, y1 = 20, x2 = 110, y2 = 120, treatment = "T1", score = "2"),
  list(x1 = 520, y1 = 320, x2 = 600, y2 = 400, treatment = "T2", score = "5")
))
export <- CDALabeller:::format_annotations(boxes, files, annotator = "test")

# A crop shifted by even one pixel would include grey, which has all three
# channels non-zero.
expect_crops_match_squares <- function(result) {
  testthat::expect_equal(dim(result$images), c(2, 64, 64, 3))
  red <- result$images[1, , , ]
  blue <- result$images[2, , , ]
  testthat::expect_true(min(red[, , 1]) > 0 && max(red[, , 2:3]) == 0)
  testthat::expect_true(min(blue[, , 3]) > 0 && max(blue[, , 1:2]) == 0)
}

testthat::test_that("AutoCDAScorer crops an export with full image paths", {
  csv <- withr::local_tempfile(fileext = ".csv")
  export$img <- file.path(images_dir, export$img)
  utils::write.csv(export, csv, row.names = FALSE)

  result <- AutoCDAScorer::crop_and_load_images(csv, image_size = 64)

  expect_crops_match_squares(result)
  testthat::expect_equal(result$filenames, c("squares_1.tif", "squares_2.tif"))
})

testthat::test_that("AutoCDAScorer crops an export as saved, run from the image folder", {
  csv <- withr::local_tempfile(fileext = ".csv")
  utils::write.csv(export, csv, row.names = FALSE)
  withr::local_dir(images_dir)

  expect_crops_match_squares(AutoCDAScorer::crop_and_load_images(csv, image_size = 64))
})

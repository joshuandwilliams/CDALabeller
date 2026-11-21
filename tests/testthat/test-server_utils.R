library(shiny)

#' Fixture images in the data frame format `shiny::fileInput` returns.
#' Two landscape (600 x 400) then two portrait (400 x 600) images.
fixture_upload <- function() {
  paths <- list.files(test_path("fixtures", "images"), full.names = TRUE)
  data.frame(name = basename(paths), size = file.size(paths), type = "image/tiff", datapath = paths)
}

test_that("uploading images stores them and processes the first", {
  upload_df <- fixture_upload()

  testServer(app_server, expr = {
    session$setInputs(image_upload = upload_df)

    expect_equal(image_files(), upload_df)
    expect_equal(current_index(), 1)
    info <- processed_image_info()
    expect_equal(c(info$original_width, info$original_height), c(600, 400))
  })
})

test_that("navigation moves between images and stays in range", {
  testServer(app_server, expr = {
    session$setInputs(image_upload = fixture_upload())

    session$setInputs(prev_image = 1)
    expect_equal(current_index(), 1)

    for (i in 1:5) session$setInputs(next_image = i)
    expect_equal(current_index(), 4)
    info <- processed_image_info()
    expect_equal(c(info$original_width, info$original_height), c(400, 600))
  })
})

test_that("process_image writes a downscaled JPEG and keeps original dimensions", {
  path <- tempfile(fileext = ".tif")
  magick::image_write(magick::image_blank(2400, 1600, "white"), path, format = "tiff")
  withr::defer(unlink(path))

  info <- process_image(path)
  out <- magick::image_info(magick::image_read(info$path))

  expect_equal(out$format, "JPEG")
  expect_equal(c(out$width, out$height), c(1200, 800))
  expect_equal(c(info$original_width, info$original_height), c(2400, 1600))
})

test_that("annotations are formatted with empty fields as NA", {
  boxes <- list(
    a.tif = list(
      list(x1 = 1, y1 = 2, x2 = 3, y2 = 4, treatment = "T1", score = "2"),
      list(x1 = 5, y1 = 6, x2 = 7, y2 = 8, treatment = "")
    ),
    b.tif = list()
  )

  df <- format_annotations_for_download(boxes)

  expect_equal(names(df), c("img", "x1", "y1", "x2", "y2", "treatment", "score"))
  expect_equal(df$img, c("a.tif", "a.tif"))
  expect_equal(df$treatment, c("T1", NA))
  expect_equal(df$score, c("2", NA))
  expect_null(format_annotations_for_download(list()))
})

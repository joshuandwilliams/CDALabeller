library(shiny)

#' Fixture images in the data frame format `shiny::fileInput` returns.
#' Two landscape (600 x 400) then two portrait (400 x 600) images.
fixture_upload <- function() {
  paths <- list.files(test_path("fixtures", "images"), full.names = TRUE)
  data.frame(name = basename(paths), size = file.size(paths), type = "image/tiff", datapath = paths)
}

test_that("uploading images stores them with checksums and processes the first", {
  upload_df <- fixture_upload()

  testServer(app_server, expr = {
    session$setInputs(image_upload = upload_df)

    expect_equal(image_files()[names(upload_df)], upload_df)
    expect_equal(image_files()$md5, unname(tools::md5sum(upload_df$datapath)))
    expect_equal(current_index(), 1)
    info <- processed_image_info()
    expect_equal(c(info$original_width, info$original_height), c(600, 400))
    img <- output$output_image
    expect_equal(img[c("data-filename", "data-width", "data-height")], list(
      `data-filename` = "_DSC0024.tif", `data-width` = 600, `data-height` = 400
    ))
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

    session$setInputs(prev_image = 2)
    expect_equal(current_index(), 3)
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

# Replaces shiny::showNotification() with a recorder; returns the messages shown.
local_notifications <- function(env = parent.frame()) {
  shown <- new.env()
  shown$messages <- character()
  local_mocked_bindings(
    showNotification = function(ui, ...) shown$messages <- c(shown$messages, ui),
    .package = "shiny", .env = env
  )
  shown
}

test_that("uploads with duplicate file names are rejected", {
  shown <- local_notifications()
  upload_df <- fixture_upload()[c(1, 2), ]
  upload_df$name <- c("same.tif", "same.tif")

  testServer(app_server, expr = {
    session$setInputs(image_upload = upload_df)
    expect_null(image_files())
  })
  expect_match(shown$messages, "same.tif")
})

test_that("an invalid score triggers a warning, a valid one does not", {
  shown <- local_notifications()
  testServer(app_server, expr = {
    session$setInputs(image_upload = fixture_upload())
    box <- list(x1 = 1, y1 = 1, x2 = 5, y2 = 5, score = "3")
    session$setInputs(bbox_coords = list(filename = "_DSC0024.tif", boxes = list(box)))
    expect_length(shown$messages, 0)

    box$score <- "9"
    session$setInputs(bbox_coords = list(filename = "_DSC0024.tif", boxes = list(box)))
    expect_match(shown$messages, "from 0 to 6")
  })
})

test_that("parse_score accepts numbers from 0 to 6 and gives NA otherwise", {
  expect_equal(vapply(c("0", "2.5", "6"), parse_score, numeric(1), USE.NAMES = FALSE), c(0, 2.5, 6))
  for (x in list("", "6.1", "-1", ".", "abc", NULL)) expect_identical(parse_score(x), NA_real_)
})

test_that("annotations are formatted to the export schema", {
  boxes <- list(
    a.tif = list(
      list(x1 = 1, y1 = 2, x2 = 3, y2 = 4, treatment = "T1", score = "2", created_at = "2026-01-01T00:00:00.000Z"),
      list(x1 = 5, y1 = 6, x2 = 7, y2 = 8, treatment = "", score = "9")
    ),
    b.tif = list()
  )
  files <- data.frame(name = c("a.tif", "b.tif"), md5 = c("aaa", "bbb"))

  df <- format_annotations(boxes, files)

  expect_equal(names(df), annotation_columns)
  expect_equal(df$img, c("a.tif", "a.tif"))
  expect_equal(df$x1, c(1L, 5L))
  expect_equal(df$treatment, c("T1", NA))
  expect_equal(df$score, c(2, NA))
  expect_equal(df$created_at, c("2026-01-01T00:00:00.000Z", NA))
  expect_equal(df$img_md5, c("aaa", "aaa"))
  expect_equal(df$labeller_version, rep(as.character(utils::packageVersion("CDALabeller")), 2))
})

test_that("with no boxes the export has the schema columns and no rows", {
  for (boxes in list(list(), list(a.tif = list()))) {
    df <- format_annotations(boxes, data.frame(name = "a.tif", md5 = "aaa"))
    expect_equal(names(df), annotation_columns)
    expect_equal(nrow(df), 0)
  }
})

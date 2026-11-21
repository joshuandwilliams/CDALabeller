test_that("annotations are autosaved after every change", {
  withr::local_options(CDALabeller.autosave_dir = withr::local_tempdir())
  paths <- list.files(test_path("fixtures", "images"), full.names = TRUE)
  upload_df <- data.frame(name = basename(paths), size = file.size(paths), type = "image/tiff", datapath = paths)

  shiny::testServer(app_server, expr = {
    session$setInputs(image_upload = upload_df, annotator_input = "JW")
    expect_false(file.exists(autosave_path))

    box <- list(x1 = 10, y1 = 10, x2 = 50, y2 = 50, score = "2")
    session$setInputs(bbox_coords = list(filename = upload_df$name[1], boxes = list(box)))
    saved <- utils::read.csv(autosave_path)
    expect_equal(names(saved), annotation_columns)
    expect_equal(saved$x2, 50)
    expect_equal(saved$annotator, "JW")

    session$setInputs(bbox_coords = list(filename = upload_df$name[1], boxes = list(box, box)))
    expect_equal(nrow(utils::read.csv(autosave_path)), 2)
  })
})

test_that("the autosave directory follows run_app(), then the option", {
  withr::local_options(CDALabeller.autosave_dir = "from-option")
  expect_equal(autosave_dir(), "from-option")
})

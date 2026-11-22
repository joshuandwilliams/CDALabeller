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

# Writes an empty file and sets its modification time to `days_old` days ago.
touch_file <- function(path, days_old) {
  file.create(path)
  Sys.setFileTime(path, Sys.time() - days_old * 24 * 3600)
}

test_that("prune_autosaves deletes only old files named like autosaves", {
  dir <- withr::local_tempdir()
  touch_file(file.path(dir, "autosave_20260101_120000.csv"), 40)
  touch_file(file.path(dir, "autosave_20260301_120000.csv"), 10)
  touch_file(file.path(dir, "my_notes.csv"), 400)
  touch_file(file.path(dir, "autosave_backup.csv"), 400)

  deleted <- prune_autosaves(dir, keep_days = 30)

  expect_equal(basename(deleted), "autosave_20260101_120000.csv")
  expect_setequal(
    list.files(dir),
    c("autosave_20260301_120000.csv", "my_notes.csv", "autosave_backup.csv")
  )
  expect_length(prune_autosaves(dir, keep_days = Inf), 0)
})

test_that("old autosaves are pruned when a session starts", {
  dir <- withr::local_tempdir()
  withr::local_options(CDALabeller.autosave_dir = dir, CDALabeller.autosave_keep_days = 5)
  touch_file(file.path(dir, "autosave_20260101_120000.csv"), 6)
  touch_file(file.path(dir, "autosave_20260102_120000.csv"), 4)

  shiny::testServer(app_server, expr = NULL)

  expect_equal(list.files(dir), "autosave_20260102_120000.csv")
})

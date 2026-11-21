# End-to-end tests in headless Chrome. They need shinytest2 and a Chrome install,
# so they are skipped on CRAN and where Chrome is missing.
skip_on_cran()
skip_if_not_installed("shinytest2")
skip_if(is.null(tryCatch(chromote::find_chrome(), error = function(e) NULL)), "Chrome not found")

# Starts the app with one blank 2400 x 1600 image. The window is wide enough for
# the image to display at 1200 x 800, so one canvas pixel is two image pixels.
start_app <- function(env = parent.frame()) {
  path <- withr::local_tempfile(fileext = ".tif", .local_envir = env)
  magick::image_write(magick::image_blank(2400, 1600, "grey"), path, format = "tiff")
  # run_app(autosave_dir =) does not reach AppDriver's child process, so the
  # autosave directory is set through an R option there instead.
  autosave <- withr::local_tempdir(.local_envir = env)
  app <- shinytest2::AppDriver$new(
    run_app(),
    width = 1800, height = 1400, load_timeout = 30000,
    options = list(CDALabeller.autosave_dir = autosave)
  )
  withr::defer(app$stop(), envir = env)
  app$upload_file(image_upload = path)
  # Reading and scaling the image can take several seconds on CI runners
  app$wait_for_js("window.document.getElementById('myCanvas').style.visibility === 'visible'", timeout = 30000)
  # The path is only rendered once the control panel is shown after upload,
  # because Shiny suspends hidden outputs.
  stopifnot(startsWith(app$wait_for_value(output = "autosave_path"), autosave))
  app
}

# Drags on the canvas from (x1, y1) to (x2, y2), in canvas pixels.
drag <- function(app, x1, y1, x2, y2) {
  app$run_js(sprintf(
    "const c = document.getElementById('myCanvas');
     const r = c.getBoundingClientRect();
     const fire = (type, x, y) => c.dispatchEvent(new MouseEvent(type, {
       clientX: r.left + c.clientLeft + x, clientY: r.top + c.clientTop + y, bubbles: true
     }));
     fire('mousedown', %d, %d); fire('mousemove', %d, %d); fire('mouseup', %d, %d);",
    x1, y1, x2, y2, x2, y2
  ))
}

test_that("the canvas drawing surface sits exactly on the image", {
  app <- start_app()
  geometry <- app$get_js(
    "(() => {
       const i = document.querySelector('#output_image img').getBoundingClientRect();
       const c = document.getElementById('myCanvas');
       const r = c.getBoundingClientRect();
       return [r.left + c.clientLeft - i.left, r.top + c.clientTop - i.top,
               c.width - i.width, c.height - i.height];
     })()"
  )
  expect_equal(unlist(geometry), c(0, 0, 0, 0))
})

test_that("a drawn box is stored squared, in original-image pixels", {
  app <- start_app()
  drag(app, 100, 100, 200, 180)

  # Canvas (100, 100)-(200, 180) is image (200, 200)-(400, 360); squaring
  # widens the 160 px side to 200 px about its centre.
  box <- app$get_value(input = "bbox_coords")$boxes[[1]]
  expect_equal(unlist(box[c("x1", "y1", "x2", "y2")]), c(x1 = 200, y1 = 180, x2 = 400, y2 = 380))
})

test_that("a click without a drag records no box", {
  app <- start_app()
  drag(app, 50, 50, 50, 50)
  expect_null(app$get_value(input = "bbox_coords"))
})

test_that("the downloaded CSV holds the drawn box and its annotations", {
  app <- start_app()
  app$set_inputs(annotator_input = "JW")
  drag(app, 100, 100, 200, 180)
  app$run_js(
    "for (const [id, value] of [['treatment_input', 'T1'], ['score_input', '3']]) {
       const el = document.getElementById(id);
       el.value = value;
       el.dispatchEvent(new Event('input', {bubbles: true}));
     }"
  )
  app$wait_for_idle()

  csv <- utils::read.csv(app$get_download("download_data"))
  expect_equal(names(csv), annotation_columns)
  expect_equal(nrow(csv), 1)
  expect_equal(unlist(csv[1, c("x1", "y1", "x2", "y2")]), c(x1 = 200, y1 = 180, x2 = 400, y2 = 380))
  expect_equal(csv$treatment, "T1")
  expect_equal(csv$score, 3)
  expect_equal(csv$annotator, "JW")
  expect_match(csv$created_at, "^\\d{4}-\\d{2}-\\d{2}T")
  expect_match(csv$img_md5, "^[0-9a-f]{32}$")
})

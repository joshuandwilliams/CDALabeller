test_that("the upload limit is raised while the app runs and restored after", {
  withr::local_options(shiny.maxRequestSize = NULL)
  on_stop <- NULL
  local_mocked_bindings(onStop = function(fun, ...) on_stop <<- fun, .package = "shiny")
  started <- FALSE

  set_upload_limit(function() started <<- TRUE)

  expect_equal(getOption("shiny.maxRequestSize"), 200 * 1024^2)
  expect_true(started)
  on_stop()
  expect_null(getOption("shiny.maxRequestSize"))
})

test_that("run_app() raises the upload limit only when the app starts", {
  withr::local_options(shiny.maxRequestSize = NULL)
  app <- run_app()
  expect_s3_class(app, "shiny.appobj")
  expect_null(getOption("shiny.maxRequestSize"))
})

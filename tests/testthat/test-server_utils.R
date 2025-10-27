library(shiny)
library(magick)
library(withr)

#' Create a mock image_files data frame
#'
#' This helper creates dummy image files in a temporary directory
#' and returns a data frame in the same format as a shiny::fileInput.
#' It also registers a cleanup handler to delete the files.
#'
#' @param n Number of mock image files to create.
#' @param env The environment to register the cleanup handler in.
#'   This should be left as the default.
#' @return A data frame with columns: name, size, type, datapath
create_mock_image_files <- function(n = 2, env = parent.frame()) {
  paths <- replicate(n, tempfile(fileext = ".tif"))
  names <- basename(paths)

  for (path in paths) {
    magick::image_write(magick::image_blank(100, 100, "white"), path, format = "tiff")
  }

  # Create the data frame structure shiny::fileInput returns
  df <- data.frame(
    name = paste0("image_", 1:n, ".tif"),
    size = rep(100, n),
    type = rep("image/tiff", n),
    datapath = paths,
    stringsAsFactors = FALSE
  )

  # Clean up the files when the test environment closes
  withr::defer(unlink(df$datapath[file.exists(df$datapath)]), envir = env)

  return(df)
}

test_that("handle_image_upload correctly resets state and sends messages", {
  new_upload_df <- create_mock_image_files(3)

  testServer(app_server, expr = {
    current_index(5)
    all_boxes(list(image1 = "some data"))

    session$setInputs(image_upload = new_upload_df)

    expect_equal(image_files(), new_upload_df)
    expect_equal(current_index(), 1)
    expect_equal(all_boxes(), list())
  })
})

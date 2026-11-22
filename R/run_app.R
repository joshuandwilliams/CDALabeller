#' Start the CDALabeller app
#'
#' Opens the app in your web browser, or in the Viewer pane in Positron. While
#' the app runs, each uploaded image can be up to 200 MB. Closing the app's tab
#' stops the app. Download your boxes before closing it.
#'
#' @param ... Options passed to the app through golem
#'   (see `?golem::get_golem_options`). CDALabeller does not use any yet.
#' @inheritParams shiny::shinyApp
#'
#' @return A Shiny app object. Printing it starts the app, which is what
#'   happens when you call `run_app()` at the console.
#'
#' @examples
#' if (interactive()) {
#'   run_app()
#' }
#'
#' @export
run_app <- function(
    onStart = NULL,
    options = list(),
    enableBookmarking = NULL,
    uiPattern = "/",
    ...) {
  golem::with_golem_options(
    app = shiny::shinyApp(
      ui = app_ui,
      server = app_server,
      onStart = function() set_upload_limit(onStart),
      options = options,
      enableBookmarking = enableBookmarking,
      uiPattern = uiPattern
    ),
    golem_opts = list(...)
  )
}

#' Largest upload Shiny accepts while the app runs: 200 MB, enough for
#' full-size camera TIFFs (about 62 MB each). Shiny's default is 5 MB.
#' @noRd
max_upload_bytes <- 200 * 1024^2

#' Raise Shiny's upload limit for as long as the app runs.
#'
#' Called as the app's `onStart`. Shiny reads `shiny.maxRequestSize` at each
#' upload, so setting it here is enough. The previous value is restored when
#' the app stops, which leaves the user's options as they were.
#'
#' @param onStart The `onStart` function passed to [run_app()], or `NULL`.
#' @noRd
set_upload_limit <- function(onStart = NULL) {
  old <- options(shiny.maxRequestSize = max_upload_bytes)
  shiny::onStop(function() options(old))
  if (!is.null(onStart)) onStart()
}

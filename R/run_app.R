#' Run the Shiny Application
#'
#' @param ... arguments to pass to golem_opts.
#' See `?golem::get_golem_options` for more details.
#' @inheritParams shiny::shinyApp
#'
#' @return A Shiny app object. Printing it, as happens when `run_app()` is
#'   called at the console, starts the app.
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
#' upload, so setting it here is enough; the previous value is restored when
#' the app stops, so the user's options are left as they were.
#'
#' @param onStart The `onStart` function passed to [run_app()], or `NULL`.
#' @noRd
set_upload_limit <- function(onStart = NULL) {
  old <- options(shiny.maxRequestSize = max_upload_bytes)
  shiny::onStop(function() options(old))
  if (!is.null(onStart)) onStart()
}

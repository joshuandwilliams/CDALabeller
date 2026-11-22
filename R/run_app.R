#' Run the Shiny Application
#'
#' @param ... Settings passed to the app as golem options
#'   (see `?golem::get_golem_options`):
#'   * `autosave_dir`: directory for autosaved annotations. The default is
#'     `tools::R_user_dir("CDALabeller", "data")`.
#'   * `autosave_keep_days`: autosaves in that directory older than this many
#'     days are deleted when the app starts. The default is 30; `Inf` keeps
#'     them all.
#'
#'   Each can instead be set with an R option, e.g.
#'   `options(CDALabeller.autosave_keep_days = 90)`.
#' @inheritParams shiny::shinyApp
#'
#' @return A Shiny app object. Printing it, as happens when `run_app()` is
#'   called at the console, starts the app.
#'
#' @examples
#' if (interactive()) {
#'   run_app()
#'   run_app(autosave_dir = "~/cda-annotations", autosave_keep_days = 90)
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
      onStart = onStart,
      options = options,
      enableBookmarking = enableBookmarking,
      uiPattern = uiPattern
    ),
    golem_opts = list(...)
  )
}

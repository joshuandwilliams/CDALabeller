#' Directory for autosaved annotations.
#'
#' Uses, in order: the `autosave_dir` argument of [run_app()], the
#' `CDALabeller.autosave_dir` option, then `tools::R_user_dir("CDALabeller", "data")`.
#'
#' @return A directory path. It is created when the first autosave is written.
#' @noRd
autosave_dir <- function() {
  dir <- golem::get_golem_options("autosave_dir")
  if (is.null(dir)) {
    dir <- getOption("CDALabeller.autosave_dir", tools::R_user_dir("CDALabeller", "data"))
  }
  dir
}

#' Autosave annotations after every change.
#'
#' Rewrites one CSV per session, named by the session's start time, whenever the
#' boxes or the annotator change, so closing the browser or a crash loses no
#' work. The file has the same columns as the download.
#'
#' @param path Path of this session's autosave CSV.
#' @param all_boxes A `reactiveVal` containing the list of all annotations.
#' @param image_files A `reactiveVal` holding the uploaded image file data.
#' @param annotator A reactive returning the annotator's name.
#'
#' @noRd
setup_autosave <- function(path, all_boxes, image_files, annotator) {
  shiny::observe({
    boxes <- all_boxes()
    shiny::req(length(boxes) > 0)
    dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
    utils::write.csv(format_annotations(boxes, image_files(), annotator()), path, row.names = FALSE)
  })
}

#' Read an app setting.
#'
#' Uses, in order: the argument of that name passed to [run_app()], the
#' `CDALabeller.<name>` option, then `default`.
#'
#' @param name Setting name, e.g. `"autosave_dir"`.
#' @param default Value used when neither is set.
#' @noRd
app_setting <- function(name, default) {
  value <- golem::get_golem_options(name)
  if (is.null(value)) value <- getOption(paste0("CDALabeller.", name), default)
  value
}

#' Directory for autosaved annotations.
#'
#' @return A directory path, by default `tools::R_user_dir("CDALabeller", "data")`.
#'   It is created when the first autosave is written.
#' @noRd
autosave_dir <- function() {
  app_setting("autosave_dir", tools::R_user_dir("CDALabeller", "data"))
}

#' Delete old autosave files.
#'
#' Removes files named like CDALabeller's autosaves
#' (`autosave_YYYYMMDD_HHMMSS.csv`) that were last modified more than
#' `keep_days` days ago. Other files in `dir` are never touched. Keeps the
#' default autosave directory, under `tools::R_user_dir()`, from growing without
#' bound, as CRAN policy requires.
#'
#' @param dir Autosave directory.
#' @param keep_days Age in days beyond which autosaves are deleted. `Inf` keeps
#'   all of them.
#' @return The paths deleted, invisibly.
#' @noRd
prune_autosaves <- function(dir, keep_days) {
  files <- list.files(dir, pattern = "^autosave_[0-9]{8}_[0-9]{6}\\.csv$", full.names = TRUE)
  age_days <- as.numeric(difftime(Sys.time(), file.mtime(files), units = "days"))
  old <- files[age_days > keep_days]
  unlink(old)
  invisible(old)
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

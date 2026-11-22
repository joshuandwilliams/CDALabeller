#' Handle image upload.
#'
#' Stores the uploaded files, with each file's MD5 checksum for provenance, and
#' swaps the upload step for the annotation UI. The upload step is hidden
#' afterwards, so images are uploaded once per session. Files with duplicate
#' names are rejected, because annotations are keyed by file name.
#'
#' @param input The Shiny input object from the server function.
#' @param image_files A `reactiveVal` to store the uploaded image file data.
#'
#' @noRd
handle_image_upload <- function(input, image_files) {
  shiny::observeEvent(input$image_upload, {
    files <- input$image_upload
    duplicated_names <- unique(files$name[duplicated(files$name)])
    if (length(duplicated_names) > 0) {
      shiny::showNotification(
        paste0(
          "These file names appear more than once: ", paste(duplicated_names, collapse = ", "),
          ". Rename them and upload again."
        ),
        type = "error", duration = NULL
      )
      return()
    }

    shinyjs::hide(selector = ".step1-container")
    shinyjs::show(selector = "#step2-title")
    shinyjs::show(selector = "#image-container")
    shinyjs::show(selector = ".control-panel")
    if (nrow(files) > 1) {
      shinyjs::show(selector = ".image-nav")
    }
    files$md5 <- unname(tools::md5sum(files$datapath))
    image_files(files)
  })
}

#' Process and resize an image for app display
#'
#' Reads an image, scales it to fit within max dimensions while preserving
#' aspect ratio, and writes it to a temporary JPEG.
#'
#' @param filepath The path to the source image file.
#' @param max_width,max_height The maximum output dimensions in pixels.
#'
#' @return A list containing the path to the processed JPEG (`path`), and the
#'   original image's dimensions (`original_width`, `original_height`).
#'
#' @noRd
process_image <- function(filepath, max_width = 1200, max_height = 1200) {
  img <- magick::image_read(filepath)
  info <- magick::image_info(img)
  img <- magick::image_scale(img, paste0(max_width, "x", max_height, ">"))
  out_path <- tempfile(fileext = ".jpg")
  magick::image_write(img, path = out_path, format = "jpeg", quality = 85)
  list(path = out_path, original_width = info$width, original_height = info$height)
}

#' Handle image navigation events.
#'
#' Moves the current index on 'next' and 'previous', keeping it within the
#' number of uploaded images.
#'
#' @param input The Shiny input object from the server function.
#' @param image_files A `reactiveVal` holding the uploaded image file data.
#' @param current_index A `reactiveVal` for the index of the current image.
#'
#' @noRd
handle_image_navigation <- function(input, image_files, current_index) {
  shiny::observeEvent(input$next_image, {
    shiny::req(image_files())
    if (current_index() < nrow(image_files())) current_index(current_index() + 1)
  })
  shiny::observeEvent(input$prev_image, {
    if (current_index() > 1) current_index(current_index() - 1)
  })
}

#' Handle visibility of navigation buttons.
#'
#' Hides 'Previous' on the first image and 'Next' on the last. The class uses
#' `visibility: hidden`, so the buttons keep their space and the counter stays
#' centred.
#'
#' @param image_files A `reactiveVal` holding the uploaded image file data.
#' @param current_index A `reactiveVal` for the index of the current image.
#'
#' @noRd
handle_nav_button_visibility <- function(image_files, current_index) {
  shiny::observe({
    shiny::req(image_files())
    idx <- current_index()
    shinyjs::toggleClass("prev_image", "hidden-by-visibility", condition = idx <= 1)
    shinyjs::toggleClass("next_image", "hidden-by-visibility", condition = idx >= nrow(image_files()))
  })
}

#' Update annotations from client-side data.
#'
#' Stores the boxes sent by the client (`input$bbox_coords`) under their
#' image filename in `all_boxes`. Warns if a score is not valid; such scores
#' are exported as `NA` (see `parse_score()`).
#'
#' @param input The Shiny input object from the server function.
#' @param all_boxes A `reactiveVal` to store all bounding box annotations.
#'
#' @noRd
update_annotations <- function(input, all_boxes) {
  shiny::observeEvent(input$bbox_coords, {
    new_boxes <- input$bbox_coords$boxes
    scores <- vapply(new_boxes, function(b) if (is.null(b$score)) "" else as.character(b$score), character(1))
    if (any(scores != "" & is.na(vapply(scores, parse_score, numeric(1))))) {
      shiny::showNotification(
        paste0("Scores must be numbers from 0 to ", max_score, ". Invalid scores are exported as NA."),
        type = "warning", id = "invalid-score"
      )
    }
    boxes <- all_boxes()
    boxes[[input$bbox_coords$filename]] <- new_boxes
    all_boxes(boxes)
  })
}

#' Render the main output image.
#'
#' The `img` element carries the image's file name and original dimensions as
#' `data-` attributes. The client reads them from the element it is drawing
#' over, so the canvas scale always matches the image on screen.
#'
#' @param processed_image_info A reactive expression that returns the processed
#'   image's path and original dimensions.
#' @param image_files A `reactiveVal` holding the uploaded image file data.
#' @param current_index A `reactiveVal` for the index of the current image.
#'
#' @return A `renderImage` object.
#'
#' @noRd
render_output_image <- function(processed_image_info, image_files, current_index) {
  shiny::renderImage(
    {
      info <- processed_image_info()
      list(
        src = info$path,
        contentType = "image/jpeg",
        alt = paste("Image", current_index()),
        `data-filename` = image_files()$name[current_index()],
        `data-width` = info$original_width,
        `data-height` = info$original_height
      )
    },
    deleteFile = TRUE
  )
}

#' Render the image counter text, e.g. "Image 3 of 5 - my_image.tif".
#'
#' @param image_files A `reactiveVal` holding the uploaded image file data.
#' @param current_index A `reactiveVal` for the index of the current image.
#'
#' @return A `renderText` object.
#'
#' @noRd
render_image_counter <- function(image_files, current_index) {
  shiny::renderText({
    files <- shiny::req(image_files())
    idx <- current_index()
    paste0("Image ", idx, " of ", nrow(files), " - ", files$name[idx])
  })
}

#' Highest cell death severity score on the scoring key.
#' @noRd
max_score <- 6

#' Columns of the exported CSV, in order.
#'
#' AutoCDAScorer requires `img`, `x1`, `x2`, `y1` and `y2`
#' (`load_cdascorer_dataframe()`) and ignores the rest.
#' @noRd
annotation_columns <- c(
  "img", "x1", "y1", "x2", "y2", "treatment", "score",
  "annotator", "created_at", "img_md5", "labeller_version"
)

#' Parse a score entered in the app.
#'
#' @param x A score as text, as sent by the client.
#' @return The score as a number, or `NA` if it is empty, not a number, or
#'   outside 0 to `max_score`.
#' @noRd
parse_score <- function(x) {
  score <- suppressWarnings(as.numeric(x))
  if (length(score) != 1 || is.na(score) || score < 0 || score > max_score) NA_real_ else score
}

#' Format annotations as the export data frame.
#'
#' @param boxes_list A named list where each name is an image filename and each
#'   value is a list of bounding box annotations for that image.
#' @param image_files The uploaded image data frame, with an `md5` column.
#' @param annotator The annotator's name, as entered in the app.
#'
#' @return A data frame with the columns in `annotation_columns`, one row per
#'   box. It has zero rows if there are no boxes.
#'
#' @noRd
format_annotations <- function(boxes_list, image_files, annotator) {
  text_or_na <- function(x) if (is.null(x) || x == "") NA_character_ else x
  rows <- lapply(names(boxes_list), function(image_name) {
    boxes <- boxes_list[[image_name]]
    if (length(boxes) == 0) {
      return(NULL)
    }
    data.frame(
      img = image_name,
      x1 = vapply(boxes, function(b) as.integer(b$x1), integer(1)),
      y1 = vapply(boxes, function(b) as.integer(b$y1), integer(1)),
      x2 = vapply(boxes, function(b) as.integer(b$x2), integer(1)),
      y2 = vapply(boxes, function(b) as.integer(b$y2), integer(1)),
      treatment = vapply(boxes, function(b) text_or_na(b$treatment), character(1)),
      score = vapply(boxes, function(b) parse_score(b$score), numeric(1)),
      created_at = vapply(boxes, function(b) text_or_na(b$created_at), character(1)),
      img_md5 = image_files$md5[match(image_name, image_files$name)]
    )
  })
  df <- do.call(rbind, rows)
  if (is.null(df)) {
    empty <- data.frame(matrix(nrow = 0, ncol = length(annotation_columns)))
    names(empty) <- annotation_columns
    return(empty)
  }
  df$annotator <- text_or_na(annotator)
  df$labeller_version <- as.character(utils::packageVersion("CDALabeller"))
  df[, annotation_columns]
}

#' Set up the download handler for annotations.
#'
#' @param all_boxes A `reactiveVal` containing the list of all annotations.
#' @param image_files A `reactiveVal` holding the uploaded image file data.
#' @param annotator A reactive returning the annotator's name.
#'
#' @return A `downloadHandler` object writing a timestamped CSV. With no boxes,
#'   the CSV has only the header row.
#'
#' @noRd
setup_download_handler <- function(all_boxes, image_files, annotator) {
  shiny::downloadHandler(
    filename = function() {
      paste0("bounding_boxes_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv")
    },
    content = function(file) {
      df <- format_annotations(all_boxes(), image_files(), annotator())
      utils::write.csv(df, file, row.names = FALSE)
    }
  )
}

#' Handle image upload.
#'
#' Stores the uploaded files and swaps the upload step for the annotation UI.
#' The upload step is hidden afterwards, so images are uploaded once per session.
#'
#' @param input The Shiny input object from the server function.
#' @param image_files A `reactiveVal` to store the uploaded image file data.
#'
#' @importFrom shiny observeEvent
#' @noRd
handle_image_upload <- function(input, image_files) {
  observeEvent(input$image_upload, {
    shinyjs::hide(selector = ".step1-container")
    shinyjs::show(selector = "#step2-title")
    shinyjs::show(selector = "#image-container")
    shinyjs::show(selector = ".control-panel")
    if (nrow(input$image_upload) > 1) {
      shinyjs::show(selector = ".image-nav")
    }
    image_files(input$image_upload)
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
#' @importFrom magick image_info image_read image_scale image_write
#' @noRd
process_image <- function(filepath, max_width = 1200, max_height = 1200) {
  img <- image_read(filepath)
  info <- image_info(img)
  img <- image_scale(img, paste0(max_width, "x", max_height, ">"))
  out_path <- tempfile(fileext = ".jpg")
  image_write(img, path = out_path, format = "jpeg", quality = 85)
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
#' @importFrom shiny observeEvent req
#' @noRd
handle_image_navigation <- function(input, image_files, current_index) {
  observeEvent(input$next_image, {
    req(image_files())
    if (current_index() < nrow(image_files())) current_index(current_index() + 1)
  })
  observeEvent(input$prev_image, {
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
#' @importFrom shiny observe req
#' @noRd
handle_nav_button_visibility <- function(image_files, current_index) {
  observe({
    req(image_files())
    idx <- current_index()
    shinyjs::toggleClass("prev_image", "hidden-by-visibility", condition = idx <= 1)
    shinyjs::toggleClass("next_image", "hidden-by-visibility", condition = idx >= nrow(image_files()))
  })
}

#' Update annotations from client-side data.
#'
#' Stores the boxes sent by the client (`input$bbox_coords`) under their
#' image filename in `all_boxes`.
#'
#' @param input The Shiny input object from the server function.
#' @param all_boxes A `reactiveVal` to store all bounding box annotations.
#'
#' @importFrom shiny observeEvent
#' @noRd
update_annotations <- function(input, all_boxes) {
  observeEvent(input$bbox_coords, {
    boxes <- all_boxes()
    boxes[[input$bbox_coords$filename]] <- input$bbox_coords$boxes
    all_boxes(boxes)
  })
}

#' Render the main output image.
#'
#' @param processed_image_info A reactive expression that returns a list
#'   containing the path to the processed image.
#' @param current_index A `reactiveVal` holding the index of the current image,
#'   used for the alt text.
#'
#' @return A `renderImage` object.
#'
#' @importFrom shiny renderImage
#' @noRd
render_output_image <- function(processed_image_info, current_index) {
  renderImage({
    list(
      src = processed_image_info()$path,
      contentType = "image/jpeg",
      alt = paste("Image", current_index())
    )
  }, deleteFile = TRUE)
}

#' Render the image counter text, e.g. "Image 3 of 5 - my_image.tif".
#'
#' @param image_files A `reactiveVal` holding the uploaded image file data.
#' @param current_index A `reactiveVal` for the index of the current image.
#'
#' @return A `renderText` object.
#'
#' @importFrom shiny renderText req
#' @noRd
render_image_counter <- function(image_files, current_index) {
  renderText({
    files <- req(image_files())
    idx <- current_index()
    paste0("Image ", idx, " of ", nrow(files), " - ", files$name[idx])
  })
}

#' Format a list of annotations into a data frame.
#'
#' Converts the nested list of bounding boxes, grouped by image name, into a
#' single data frame for CSV export. Empty treatment or score values become `NA`.
#'
#' @param boxes_list A named list where each name is an image filename and each
#'   value is a list of bounding box annotations for that image.
#'
#' @return A data frame with all annotations, or `NULL` if there are none.
#'
#' @noRd
format_annotations_for_download <- function(boxes_list) {
  na_if_empty <- function(x) if (is.null(x) || x == "") NA else x

  do.call(rbind, lapply(names(boxes_list), function(image_name) {
    boxes <- boxes_list[[image_name]]
    if (length(boxes) == 0) return(NULL)
    data.frame(
      img = image_name,
      x1 = sapply(boxes, `[[`, "x1"),
      y1 = sapply(boxes, `[[`, "y1"),
      x2 = sapply(boxes, `[[`, "x2"),
      y2 = sapply(boxes, `[[`, "y2"),
      treatment = sapply(boxes, function(b) na_if_empty(b$treatment)),
      score = sapply(boxes, function(b) na_if_empty(b$score))
    )
  }))
}

#' Set up the download handler for annotations.
#'
#' @param all_boxes A `reactiveVal` containing the list of all annotations.
#'
#' @return A `downloadHandler` object writing a timestamped CSV.
#'
#' @importFrom shiny downloadHandler
#' @importFrom utils write.csv
#' @noRd
setup_download_handler <- function(all_boxes) {
  downloadHandler(
    filename = function() {
      paste0("bounding_boxes_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv")
    },
    content = function(file) {
      annotations_df <- format_annotations_for_download(all_boxes())
      if (!is.null(annotations_df)) {
        write.csv(annotations_df, file, row.names = FALSE)
      }
    }
  )
}

#' Notify client about a new processed image.
#'
#' Sends the image's original filename and dimensions so the client can map
#' canvas coordinates back to original-image pixels.
#'
#' @param session The Shiny session object from the server function.
#' @param processed_image_info A reactive expression that returns metadata for
#'   the currently processed image.
#' @param image_files A `reactiveVal` holding the uploaded image file data.
#' @param current_index A `reactiveVal` for the index of the current image.
#'
#' @importFrom shiny observeEvent
#' @noRd
notify_client_of_new_image <- function(session, processed_image_info, image_files, current_index) {
  observeEvent(processed_image_info(), {
    info <- processed_image_info()
    session$sendCustomMessage("image_loaded", list(
      filename = image_files()$name[current_index()],
      width = info$original_width,
      height = info$original_height
    ))
  })
}

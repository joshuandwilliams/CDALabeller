#' Handle the startup modal for field selection.
#'
#' Shows a modal dialog on application startup to allow the user to select
#' which data fields to collect. It sets up an observer to handle the
#' user's confirmation and updates the application state accordingly.
#'
#' @param input The Shiny input object from the server function.
#' @param session The Shiny session object from the server function.
#' @param data_fields A `reactiveVal` used to store the user-selected fields.
#'
#' @importFrom shiny showModal modalDialog p checkboxGroupInput actionButton
#' @importFrom shiny observeEvent req removeModal
#' @noRd
handle_startup_modal <- function(input, session, data_fields) {
  showModal(modalDialog(
    title = "Select Data to Collect",
    p("Choose the data fields you want to record for each bounding box."),
    checkboxGroupInput("field_selection", "Fields:",
                       choices = c("treatment", "score"),
                       selected = "treatment"),
    footer = actionButton("confirm_fields", "Start Labelling")
  ))

  observeEvent(input$confirm_fields, {
    req(input$field_selection)
    selected_fields <- input$field_selection
    data_fields(selected_fields)
    session$sendCustomMessage("configure_fields", as.list(selected_fields))
    removeModal()
  })
}

#' Handle new image uploads and reset application state.
#'
#' Sets up an observer for the file input. When new images are uploaded, it
#' sends a message to clear the client-side state (e.g., existing canvases)
#' and resets the server-side reactive values for the file list, current image
#' index, and stored annotations.
#'
#' @param input The Shiny input object from the server function.
#' @param session The Shiny session object from the server function.
#' @param image_files A `reactiveVal` to store the uploaded image file data.
#' @param current_index A `reactiveVal` to store the index of the currently
#'   viewed image.
#' @param all_boxes A `reactiveVal` to store all bounding box annotations.
#'
#' @importFrom shiny observeEvent req
#' @noRd
handle_image_upload <- function(input, session, image_files, current_index, all_boxes) {
  observeEvent(input$image_upload, {
    req(input$image_upload)
    session$sendCustomMessage("clear_client_state", list())

    image_files(input$image_upload)
    current_index(1)
    all_boxes(list())
  })
}

#' Process and resize an image for app display
#'
#' Reads an image from a path, resizes it to fit within max dimensions
#' while preserving aspect ratio, converts it to JPEG, and saves it to a
#' temporary file.
#'
#' @param filepath The path to the source image file.
#' @param max_width The maximum width of the output image in pixels.
#' @param max_height The maximum height of the output image in pixels.
#'
#' @return A list containing the path to the processed JPEG (`path`), and the
#'   original image's dimensions (`original_width`, `original_height`).
#'
#' @importFrom magick image_convert image_info image_read image_scale image_write
#' @noRd
process_image <- function(filepath, max_width = 1200, max_height = 1200) {
  img <- image_read(filepath)
  info <- image_info(img)
  img <- image_scale(img, paste0(max_width, "x", max_height, ">")) # Resize while preserving aspect ratio
  img <- image_convert(img, format = "jpeg") # Convert to JPEG
  out_path <- tempfile(fileext = ".jpg")
  image_write(img, path = out_path, format = "jpeg", quality = 85) # Save to temp file
  return(list(path = out_path, original_width = info$width, original_height = info$height))
}

#' Handle image navigation events.
#'
#' Sets up observers for the 'next' and 'previous' image buttons to update the
#' current image index, ensuring the index stays within the bounds of the
#' number of uploaded images.
#'
#' @param input The Shiny input object from the server function.
#' @param image_files A `reactiveVal` holding the uploaded image file data.
#' @param current_index A `reactiveVal` for the index of the current image.
#'
#' @importFrom shiny observeEvent req
#' @noRd
handle_image_navigation <- function(input, image_files, current_index) {
  # Next image button
  observeEvent(input$next_image, {
    req(image_files())
    idx <- current_index()
    # Use nrow() to get the correct number of uploaded files
    if (idx < nrow(image_files())) {
      current_index(idx + 1)
    }
  })

  # Previous image button
  observeEvent(input$prev_image, {
    req(image_files())
    idx <- current_index()
    if (idx > 1) {
      current_index(idx - 1)
    }
  })
}

#' Handle the undo bounding box event.
#'
#' Sets up an observer for the 'undo' button. When clicked, it sends a
#' custom message to the client-side JavaScript to remove the last drawn
#' bounding box for the current image.
#'
#' @param input The Shiny input object from the server function.
#' @param session The Shiny session object from the server function.
#' @param image_files A `reactiveVal` holding the uploaded image file data.
#' @param current_index A `reactiveVal` for the index of the current image.
#'
#' @importFrom shiny observeEvent
#' @noRd
handle_undo <- function(input, session, image_files, current_index) {
  observeEvent(input$undo_box, {
    # Assuming image_files() is a data frame like object from fileInput
    current_file_path <- image_files()$datapath[current_index()]
    session$sendCustomMessage("undo_last_box", list(filename = base::basename(current_file_path)))
  })
}

#' Update annotations from client-side data.
#'
#' Sets up an observer that listens for incoming bounding box data from the
#' client (`input$bbox_coords`). When data is received, it updates the main
#' `all_boxes` reactive list with the new annotations for the corresponding
#' filename.
#'
#' @param input The Shiny input object from the server function.
#' @param all_boxes A `reactiveVal` to store all bounding box annotations.
#'
#' @importFrom shiny observeEvent
#' @noRd
update_annotations <- function(input, all_boxes) {
  observeEvent(input$bbox_coords, {
    if (!is.null(input$bbox_coords)) {
      filename <- input$bbox_coords$filename
      boxes <- input$bbox_coords$boxes
      current_boxes <- all_boxes()
      current_boxes[[filename]] <- boxes
      all_boxes(current_boxes)
    }
  })
}

#' Render the main output image.
#'
#' Creates a `renderImage` object that displays the currently selected and
#' processed image. The function depends on reactive information about the
#' current image.
#'
#' @param processed_image_info A reactive expression that returns a list
#'   containing the path to the processed image.
#' @param current_index A `reactiveVal` holding the index of the current image,
#'   used for the alt text.
#'
#' @return A `renderImage` object.
#'
#' @importFrom shiny renderImage req
#' @noRd
render_output_image <- function(processed_image_info, current_index) {
  renderImage({
    req(processed_image_info())
    list(
      src = processed_image_info()$path,
      contentType = "image/jpeg",
      alt = paste("Image", current_index())
    )
  }, deleteFile = TRUE)
}

#' Render the image counter text.
#'
#' Creates a `renderText` object that displays the current image count and
#' filename (e.g., "Image 3 of 5 – my_image.jpg").
#'
#' @param image_files A `reactiveVal` holding the uploaded image file data.
#' @param current_index A `reactiveVal` for the index of the current image.
#'
#' @return A `renderText` object.
#'
#' @importFrom shiny renderText
#' @noRd
render_image_counter <- function(image_files, current_index) {
  renderText({
    files <- image_files()
    idx <- current_index()
    if (is.null(files) || length(files) == 0) {
      return("No images loaded")
    }
    fname <- files$name[idx]
    base::paste0("Image ", idx, " of ", length(files), " – ", fname)
  })
}

#' Render dynamic UI inputs for annotation data.
#'
#' Creates a `renderUI` object that generates input fields (e.g., for
#' 'treatment' or 'score') based on the fields the user selected at startup.
#'
#' @param data_fields A `reactiveVal` containing the user-selected field names.
#' @param image_files A `reactiveVal` used with `req()` to ensure inputs only
#'   appear after images are loaded.
#'
#' @return A `renderUI` object.
#'
#' @importFrom shiny renderUI req textInput tagList
#' @noRd
render_dynamic_inputs <- function(data_fields, image_files) {
  renderUI({
    fields <- data_fields()
    req(fields, image_files())

    inputs <- list()
    if ("treatment" %in% fields) {
      inputs <- c(inputs, list(textInput("treatment_input", "Treatment:", placeholder = "Enter treatment for the last box")))
    }
    if ("score" %in% fields) {
      inputs <- c(inputs, list(textInput("score_input", "Score:", placeholder = "Enter score for the last box")))
    }
    tagList(inputs)
  })
}

#' Format a list of annotations into a data frame.
#'
#' Converts the nested list of bounding boxes, grouped by image name, into a
#' single, tidy data frame suitable for export to CSV.
#'
#' @param boxes_list A named list where each name is an image filename and each
#'   value is a list of bounding box annotations for that image.
#'
#' @return A data frame with all annotations, or `NULL` if the input is empty.
#'
#' @noRd
format_annotations_for_download <- function(boxes_list) {
  if (is.null(boxes_list) || length(boxes_list) == 0) {
    return(NULL)
  }

  # Convert list of boxes to dataframe
  all_boxes_df <- do.call(rbind, lapply(names(boxes_list), function(image_name) {
    boxes <- boxes_list[[image_name]]
    if (is.null(boxes) || length(boxes) == 0) return(NULL)

    df <- data.frame(
      image = image_name,
      x1 = sapply(boxes, function(b) b$x1),
      y1 = sapply(boxes, function(b) b$y1),
      x2 = sapply(boxes, function(b) b$x2),
      y2 = sapply(boxes, function(b) b$y2),
      stringsAsFactors = FALSE
    )

    # Dynamically add columns if they exist in the data
    if (!is.null(boxes[[1]]$treatment)) {
      df$treatment <- sapply(boxes, function(b) ifelse(is.null(b$treatment), NA, b$treatment))
    }
    if (!is.null(boxes[[1]]$score)) {
      df$score <- sapply(boxes, function(b) ifelse(is.null(b$score), NA, b$score))
    }
    df
  }))

  if (is.null(all_boxes_df) || nrow(all_boxes_df) == 0) {
    return(NULL)
  }
  all_boxes_df
}

#' Set up the download handler for annotations.
#'
#' Creates the `downloadHandler` object for the download button. It generates
#' a timestamped filename and uses the `format_annotations_for_download`
#' function to prepare the data before writing it to a CSV file.
#'
#' @param all_boxes A `reactiveVal` containing the list of all annotations.
#'
#' @return A `downloadHandler` object.
#'
#' @importFrom shiny downloadHandler
#' @importFrom utils write.csv
#' @noRd
setup_download_handler <- function(all_boxes) {
  downloadHandler(
    filename = function() {
      timestamp <- base::format(base::Sys.time(), "%Y%m%d_%H%M%S")
      base::paste0("bounding_boxes_", timestamp, ".csv")
    },
    content = function(file) {
      # Use the pure function to get the data frame
      annotations_df <- format_annotations_for_download(all_boxes())

      if (!is.null(annotations_df)) {
        utils::write.csv(annotations_df, file, row.names = FALSE)
      }
    }
  )
}

#' Notify client about a new processed image.
#'
#' Sets up an observer that triggers whenever the `processed_image_info`
#' reactive changes. It sends a custom message to the client-side with the
#' new image's original filename and dimensions, allowing JavaScript to
#' correctly scale the annotation canvas.
#'
#' @param session The Shiny session object from the server function.
#' @param processed_image_info A reactive expression that returns metadata for
#'   the currently processed image.
#' @param image_files A `reactiveVal` holding the uploaded image file data, used
#'   to get the original filename.
#' @param current_index A `reactiveVal` for the index of the current image.
#'
#' @importFrom shiny observeEvent req
#' @noRd
notify_client_of_new_image <- function(session, processed_image_info, image_files, current_index) {
  observeEvent(processed_image_info(), {
    files <- image_files()
    idx <- current_index()
    p_info <- processed_image_info()
    req(p_info, files, idx) # Ensure all reactives are ready

    original_filename <- files$name[idx]

    session$sendCustomMessage("image_loaded", list(
      filename = original_filename,
      width = p_info$original_width,
      height = p_info$original_height
    ))
  })
}

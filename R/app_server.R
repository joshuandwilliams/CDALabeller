options("shiny.maxRequestSize" = 200 * 1024^2) # Uploads up to 200MB

#' The application server-side logic
#'
#' @param input,output,session Internal parameters for `{shiny}`.
#'
#' @importFrom magick image_convert image_info image_read image_scale image_write
#' @importFrom shiny observeEvent reactive reactiveVal req renderImage renderText showNotification stopApp
#' @importFrom shinyFiles parseDirPath shinyDirChoose
#' @importFrom utils write.csv
#' @noRd
app_server <- function(input, output, session) {
  session$onSessionEnded(stopApp)

  process_image <- function(filepath, max_width = 1200, max_height = 1200) {
    base::cat("Processing image...\n")

    img <- image_read(filepath)
    base::cat("Original image size:", image_info(img)$width, "x", image_info(img)$height, "\n")

    # Resize while preserving aspect ratio
    img <- image_scale(img, paste0(max_width, "x", max_height, ">"))

    base::cat("Resized image size:", image_info(img)$width, "x", image_info(img)$height, "\n")

    # Convert to JPEG
    img <- image_convert(img, format = "jpeg")

    # Save to temporary file
    out_path <- base::tempfile(fileext = ".jpg")
    image_write(img, path = out_path, format = "jpeg", quality = 85)

    base::cat("Saved processed image to:", out_path, "\n")
    return(out_path)
  }

  image_files <- reactiveVal(NULL)
  current_index <- reactiveVal(1)

  # Store all bounding boxes for all images
  all_boxes <- reactiveVal(list())

  observeEvent(input$image_upload, {
    # Require that files have been uploaded to proceed
    req(input$image_upload)

    # Optional: Log the number of files uploaded to the R console
    base::cat("User uploaded", nrow(input$image_upload), "images\n")

    # The 'input$image_upload' is a dataframe containing file information.
    # We store the entire dataframe, which includes 'name' for display
    # and 'datapath' for the temporary server-side file path.
    image_files(input$image_upload)

    # Reset the index to the first image
    current_index(1)

    # Clear any previously stored bounding boxes
    all_boxes(list())
  })

  processed_path <- reactive({
    files <- image_files()
    idx <- current_index()
    req(files, idx)

    # Use the 'datapath' column for the server-side temporary path
    filepath <- files$datapath[idx]
    process_image(filepath)
  })

  output$output_image <- renderImage({
    req(processed_path())

    list(
      src = processed_path(),
      contentType = "image/jpeg",
      alt = paste("Image", current_index())
    )
  }, deleteFile = TRUE)

  output$image_counter <- renderText({
    files <- image_files()
    idx <- current_index()
    if (is.null(files) || length(files) == 0) {
      return("No images loaded")
    }
    fname <- files$name[idx]
    base::paste0("Image ", idx, " of ", length(files), " – ", fname)
  })

  observeEvent(processed_path(), {
    files <- image_files()
    idx <- current_index()

    original_filename <- files$name[idx]

    session$sendCustomMessage("image_loaded", list(
      filename = original_filename
    ))
  })

  observeEvent(input$bbox_coords, {
    base::cat("Received Bounding Box Coordinates from JS\n")

    if (!is.null(input$bbox_coords)) {
      filename <- input$bbox_coords$filename
      boxes <- input$bbox_coords$boxes

      base::cat("Filename:", filename, "\n")
      base::cat("Number of boxes:", length(boxes), "\n")

      current_boxes <- all_boxes()
      current_boxes[[filename]] <- boxes
      all_boxes(current_boxes)
    }
  })

  observeEvent(input$next_image, {
    req(image_files())
    idx <- current_index()
    if (idx < length(image_files())) {
      current_index(idx + 1)
    }
  })

  observeEvent(input$prev_image, {
    req(image_files())
    idx <- current_index()
    if (idx > 1) {
      current_index(idx - 1)
    }
  })

  observeEvent(input$undo_box, {
    session$sendCustomMessage("undo_last_box", list(filename = base::basename(image_files()[current_index()])))
  })

  output$download_data <- downloadHandler(
    filename = function() {
      # This function determines the name of the file the user will download.
      timestamp <- base::format(base::Sys.time(), "%Y%m%d_%H%M%S")
      base::paste0("bounding_boxes_", timestamp, ".csv")
    },
    content = function(file) {
      # This function generates the content of the file.
      # 'file' is a temporary file path on the server provided by Shiny.

      boxes_list <- all_boxes()

      # Stop if there is no data to save.
      if (is.null(boxes_list) || length(boxes_list) == 0) {
        return(NULL)
      }

      # Use your existing logic to convert the list of boxes into a single data frame.
      all_boxes_df <- base::do.call(base::rbind, base::lapply(base::names(boxes_list), function(image_name) {
        boxes <- boxes_list[[image_name]]
        if (is.null(boxes) || length(boxes) == 0) return(NULL)

        base::data.frame(
          image = image_name,
          x1 = base::sapply(boxes, function(b) b$x1),
          y1 = base::sapply(boxes, function(b) b$y1),
          x2 = base::sapply(boxes, function(b) b$x2),
          y2 = base::sapply(boxes, function(b) b$y2),
          stringsAsFactors = FALSE
        )
      }))

      # Another check to ensure the final dataframe is not empty.
      if (is.null(all_boxes_df) || nrow(all_boxes_df) == 0) {
        return(NULL)
      }

      # Write the data frame to the temporary file path provided by Shiny.
      # This file is then sent to the user's browser for download.
      utils::write.csv(all_boxes_df, file, row.names = FALSE)
    }
  )
}

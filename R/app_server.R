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

  shinyDirChoose(input, "user_folder", roots = c(home = "~"))

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

  observeEvent(input$user_folder, {
    folder_path <- parseDirPath(roots = c(home = "~"), selection = input$user_folder)

    if (is.null(folder_path) || length(folder_path) == 0 || is.na(folder_path) || folder_path == "") {
      return(NULL)
    }

    base::cat("User selected folder:", folder_path, "\n")

    tiffs <- base::list.files(
      path = folder_path,
      pattern = "\\.(tif|tiff)$",
      ignore.case = TRUE,
      full.names = TRUE
    )

    if (length(tiffs) == 0) {
      base::cat("No TIFF images found in folder.\n")
    } else {
      base::cat("Found", length(tiffs), "images\n")
    }

    image_files(tiffs)
    current_index(1)
    all_boxes(list()) # Reset boxes when new folder is selected
  })

  processed_path <- reactive({
    files <- image_files()
    idx <- current_index()
    req(files, idx)

    filepath <- files[idx]
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
    fname <- base::basename(files[idx])
    base::paste0("Image ", idx, " of ", length(files), " – ", fname)
  })

  observeEvent(processed_path(), {
    files <- image_files()
    idx <- current_index()

    original_filename <- base::basename(files[idx])

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

  observeEvent(input$save_boxes, {
    folder_path <- parseDirPath(roots = c(home = "~"), selection = input$user_folder)

    if (is.null(folder_path) || length(folder_path) == 0 || folder_path == "") {
      showNotification("Please select a folder first!", type = "error")
      return()
    }

    timestamp <- base::format(base::Sys.time(), "%Y%m%d_%H%M%S")
    csv_filename <- base::paste0("bounding_boxes_", timestamp, ".csv")
    csv_path <- base::file.path(folder_path, csv_filename)

    boxes_list <- all_boxes()

    if (is.null(boxes_list) || length(boxes_list) == 0) {
      showNotification("No boxes to save!", type = "error")
      return()
    }

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

    if (is.null(all_boxes_df) || nrow(all_boxes_df) == 0) {
      showNotification("No boxes to save!", type = "error")
      return()
    }

    tryCatch({
      write.csv(all_boxes_df, csv_path, row.names = FALSE)
      showNotification(base::paste("Saved", nrow(all_boxes_df), "boxes to", base::basename(csv_path)), type = "message", duration = 5)
      base::cat("Successfully saved", nrow(all_boxes_df), "boxes to", csv_path, "\n")
    }, error = function(e) {
      showNotification(base::paste("Error saving file:", e$message), type = "error", duration = 10)
      base::cat("Error saving CSV:", e$message, "\n")
    })
  })
}

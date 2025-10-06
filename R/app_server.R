source("R/server_utils.R")
options("shiny.maxRequestSize" = 200 * 1024^2) # Uploads up to 200MB

#' The application server-side logic.
#'
#' @param input,output,session Internal parameters for `{shiny}`.
#'
#' @importFrom shiny observeEvent reactive reactiveVal req renderImage renderText stopApp
#' @importFrom utils write.csv
#' @noRd
app_server <- function(input, output, session) {

  session$onSessionEnded(stopApp)

  image_files <- reactiveVal(NULL)
  current_index <- reactiveVal(1)
  all_boxes <- reactiveVal(list())


  # Event: User uploads images using fileInput()
  observeEvent(input$image_upload, {
    req(input$image_upload)
    session$sendCustomMessage("clear_client_state", list())

    image_files(input$image_upload) # input$image_upload contains 'name' for display and 'datapath' for temp server-side filepath

    current_index(1)
    all_boxes(list())
  })


  # Reactive Object: Current image metadata
  processed_image_info <- reactive({
    files <- image_files()
    idx <- current_index()
    req(files, idx)
    filepath <- files$datapath[idx]
    process_image(filepath)
  })


  # Output: Send image to UI. Re-runs each time the user clicks "Next" or "Previous"
  output$output_image <- renderImage({
    req(processed_image_info())
    list(
      src = processed_image_info()$path,
      contentType = "image/jpeg",
      alt = paste("Image", current_index())
    )
  }, deleteFile = TRUE)


  # Output: Send text to UI e.g. "Image 3 of 4 - image_3.tif"
  output$image_counter <- renderText({
    files <- image_files()
    idx <- current_index()
    if (is.null(files) || length(files) == 0) {
      return("No images loaded")
    }
    fname <- files$name[idx]
    base::paste0("Image ", idx, " of ", length(files), " – ", fname)
  })


  # Event: Tell JavaScript when a new image has been processed
  observeEvent(processed_image_info(), {
    files <- image_files()
    idx <- current_index()
    p_info <- processed_image_info()
    req(p_info)

    original_filename <- files$name[idx]

    session$sendCustomMessage("image_loaded", list(
      filename = original_filename,
      width = p_info$original_width,
      height = p_info$original_height
    ))
  })


  # Event: Update all_boxes() with current annotations
  observeEvent(input$bbox_coords, {
    if (!is.null(input$bbox_coords)) {
      filename <- input$bbox_coords$filename
      boxes <- input$bbox_coords$boxes
      current_boxes <- all_boxes()
      current_boxes[[filename]] <- boxes
      all_boxes(current_boxes)
    }
  })


  # Event: Next image button
  observeEvent(input$next_image, {
    req(image_files())
    idx <- current_index()
    if (idx < length(image_files())) {
      current_index(idx + 1)
    }
  })


  # Event: Prev image button
  observeEvent(input$prev_image, {
    req(image_files())
    idx <- current_index()
    if (idx > 1) {
      current_index(idx - 1)
    }
  })


  # Event: Tell JavaScript to undo last box
  observeEvent(input$undo_box, {
    session$sendCustomMessage("undo_last_box", list(filename = base::basename(image_files()[current_index()])))
  })


  # Output: Save annotation data to CSV (browser download)
  output$download_data <- downloadHandler(

    filename = function() {
      timestamp <- base::format(base::Sys.time(), "%Y%m%d_%H%M%S")
      base::paste0("bounding_boxes_", timestamp, ".csv")
    },

    content = function(file) {
      boxes_list <- all_boxes()
      if (is.null(boxes_list) || length(boxes_list) == 0) {
        return(NULL)
      }

      # Convert list of boxes to dataframe
      all_boxes_df <- do.call(rbind, lapply(names(boxes_list), function(image_name) {
        boxes <- boxes_list[[image_name]]

        if (is.null(boxes) || length(boxes) == 0) return(NULL)

        data.frame(
          image = image_name,
          x1 = sapply(boxes, function(b) b$x1),
          y1 = sapply(boxes, function(b) b$y1),
          x2 = sapply(boxes, function(b) b$x2),
          y2 = sapply(boxes, function(b) b$y2),
          treatment = sapply(boxes, function(b) ifelse(is.null(b$treatment), NA, b$treatment)),
          stringsAsFactors = FALSE
        )
      }))

      # Ensure the final dataframe is not empty.
      if (is.null(all_boxes_df) || nrow(all_boxes_df) == 0) {
        return(NULL)
      }

      # Write the data frame to the temporary file path provided by Shiny.
      # This file is then sent to the user's browser for download.
      utils::write.csv(all_boxes_df, file, row.names = FALSE)
    }
  )
}

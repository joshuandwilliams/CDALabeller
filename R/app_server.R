source("R/server_utils.R")

#' The application server-side logic.
#'
#' @param input,output,session Internal parameters for \{shiny\}.
#'
#' @importFrom shiny reactive reactiveVal req stopApp
#' @export
app_server <- function(input, output, session) {

  # 1. Session Management
  # ============================================================================
  session$onSessionEnded(stopApp)


  # 2. Application State Initialization
  # ============================================================================
  # Reactive values to hold the core state of the application.
  data_fields   <- reactiveVal(c("treatment", "score"))     # Fields to collect
  image_files   <- reactiveVal(NULL)      # Data frame of uploaded image files
  current_index <- reactiveVal(1)         # Index of the current image
  all_boxes     <- reactiveVal(list())    # List storing all annotations

  # Hide main app UI elements on startup. They will be shown after image upload.
  # This hides the "Step 2" title using its new ID
  shinyjs::hide(selector = "#step2-title")
  shinyjs::hide(selector = "#image-container")
  shinyjs::hide(selector = ".image-nav")
  shinyjs::hide(selector = ".control-panel")

  # 3. Core Reactive Logic
  # ============================================================================
  # This reactive triggers whenever the current_index or image_files change.
  # It processes the current image and makes its data available to outputs.
  processed_image_info <- reactive({
    files <- image_files()
    idx <- current_index()
    req(files, idx)
    filepath <- files$datapath[idx]
    process_image(filepath)
  })


  # 4. Event Handlers & Observers
  # ============================================================================
  # These functions set up observers that react to user inputs and state changes.

  # Handle new image uploads and reset the application state.
  handle_image_upload(input, session, image_files, current_index, all_boxes)

  # Handle navigation between images (next/previous buttons).
  handle_image_navigation(input, image_files, current_index)

  # Conditionally show/hide navigation buttons based on index.
  handle_nav_button_visibility(image_files, current_index)

  # Handle the undo button press.
  handle_undo(input, session, image_files, current_index)

  # Update annotations when new data is received from the client.
  update_annotations(input, all_boxes)

  # Notify the client when a new image is processed and ready.
  notify_client_of_new_image(session, processed_image_info, image_files, current_index)


  # 5. UI Outputs
  # ============================================================================
  # These functions create the render expressions that update the user interface.

  # Render the main image display.
  output$output_image <- render_output_image(processed_image_info, current_index)

  # Render the text counter (e.g., "Image 1 of 5").
  output$image_counter <- render_image_counter(image_files, current_index)

  # Render the dynamic input fields for annotation data.
  output$dynamic_inputs <- render_dynamic_inputs(data_fields, image_files)

  # Set up the download button for exporting annotations.
  output$download_data <- setup_download_handler(all_boxes)
}

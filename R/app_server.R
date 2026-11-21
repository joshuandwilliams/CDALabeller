#' The application server-side logic.
#'
#' @param input,output,session Internal parameters for \{shiny\}.
#'
#' @export
app_server <- function(input, output, session) {
  session$onSessionEnded(shiny::stopApp)

  image_files <- shiny::reactiveVal(NULL) # Data frame of uploaded image files
  current_index <- shiny::reactiveVal(1) # Index of the current image
  all_boxes <- shiny::reactiveVal(list()) # Annotations, keyed by image filename

  # Hidden until images are uploaded
  shinyjs::hide(selector = "#step2-title")
  shinyjs::hide(selector = "#image-container")
  shinyjs::hide(selector = ".image-nav")
  shinyjs::hide(selector = ".control-panel")

  processed_image_info <- shiny::reactive({
    shiny::req(image_files())
    process_image(image_files()$datapath[current_index()])
  })

  handle_image_upload(input, image_files)
  handle_image_navigation(input, image_files, current_index)
  handle_nav_button_visibility(image_files, current_index)
  update_annotations(input, all_boxes)
  notify_client_of_new_image(session, processed_image_info, image_files, current_index)

  output$output_image <- render_output_image(processed_image_info, current_index)
  output$image_counter <- render_image_counter(image_files, current_index)
  output$download_data <- setup_download_handler(all_boxes)
}

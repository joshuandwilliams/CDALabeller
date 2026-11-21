#' The application User-Interface
#'
#' @param request Internal parameter for \{shiny\}.
#'
#' @importFrom shiny tagList fluidPage h2 tags imageOutput fluidRow column actionButton textOutput span fileInput textInput downloadButton
#' @export
app_ui <- function(request) {
  tagList(
    golem_add_external_resources(),
    shinyjs::useShinyjs(),
    fluidPage(
      tags$div(
        class = "title-container",
        h2("CDALabeller"),
        tags$p("Draw bounding box annotations around cell death areas")
      ),

      fluidRow(
        class = "main-container",

        # Left column: upload, image and navigation
        column(
          width = 9,
          tags$div(
            class = "step1-container",
            tags$h4("Upload Your Agroinfiltration Images"),
            fileInput(
              "image_upload",
              label = NULL,
              multiple = TRUE,
              accept = c(".tif", ".tiff"),
              placeholder = "No files selected"
            )
          ),

          tags$h4(id = "step2-title", "Step 1: Draw a Bounding Box (Click and Drag)"),
          tags$div(
            id = "image-container",
            imageOutput("output_image", height = "auto"),
            tags$canvas(id = "myCanvas")
          ),
          tags$div(
            class = "image-nav",
            actionButton("prev_image", "Previous"),
            textOutput("image_counter", container = span),
            actionButton("next_image", "Next")
          )
        ),

        # Right column: annotation fields and export
        column(
          width = 3,
          class = "control-panel",
          tags$h4("Step 2: Record Treatment / Score"),
          textInput("treatment_input", "Treatment:", placeholder = "e.g. Treatment A"),
          textInput("score_input", "Score:", placeholder = "e.g. 0-6"),
          tags$hr(),
          actionButton("undoButton", "Undo Last Box"),
          tags$hr(),
          tags$div(
            id = "download-box",
            downloadButton("download_data", "Download Your Boxes")
          )
        )
      )
    )
  )
}

#' Add external Resources to the Application
#'
#' @importFrom golem add_resource_path favicon
#' @importFrom shiny tags
#' @noRd
golem_add_external_resources <- function() {
  add_resource_path("www", app_sys("app/www"))
  tags$head(
    favicon(),
    tags$title("CDALabeller"),
    tags$link(rel = "stylesheet", type = "text/css", href = "www/styles.css"),
    tags$script(type = "module", src = "www/script.js")
  )
}

#' The application User-Interface
#'
#' @param request Internal parameter for \{shiny\}.
#'
#' @importFrom shiny tagList fluidPage h2 tags imageOutput fluidRow column actionButton textOutput span fileInput uiOutput downloadButton
#' @importFrom shinyFiles shinyDirButton
#' @importFrom shinyjs useShinyjs
#' @export
app_ui <- function(request) {
  tagList(
    golem_add_external_resources(),
    shinyjs::useShinyjs(),
    fluidPage(
      # Page Header
      tags$div(
        class = "title-container",
        h2("CDALabeller"),
        tags$p("Draw bounding box annotations around cell death areas")
      ),

      # Main two-column layout
      fluidRow(
        class = "main-container",

        # Left Column: Image and Navigation
        column(
          width = 9,
          tags$div(
            class = "step1-container",
            tags$h4("Upload Your Agroinfiltration Images"),
            fileInput(
              "image_upload",
              label = NULL, # Label is provided by the h4
              multiple = TRUE,
              accept = c(".tif", ".tiff"),
              buttonLabel = "Browse...",
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

        # Right Column: Controls and Data Entry
        column(
          width = 3,
          class = "control-panel",
          tags$h4("Step 2: Record Treatment / Score"),
          uiOutput("dynamic_inputs"),
          tags$hr(),

          actionButton("undoButton", "Undo Last Box"),
          tags$hr(),

          tags$div(
            id = "download-box",
            tags$h4("Download your Annotations"),
            # Updated button label
            downloadButton("download_data", "Download Your Boxes")
          ),

          tags$hr()
        )
      )
    )
  )
}

#' Add external Resources to the Application
#'
#' This function is internally used to add external
#' resources inside the Shiny application.
#'
#' @importFrom golem add_resource_path favicon bundle_resources
#' @importFrom shiny tags
#' @noRd
golem_add_external_resources <- function() {
  add_resource_path("www", app_sys("app/www"))
  tags$head(
    favicon(),
    tags$title("CDALabeller"),  # This sets the tab name
    tags$link(rel = "stylesheet", type = "text/css", href = "www/styles.css"),
    tags$script(type = "module", src = "www/script.js")
  )
}

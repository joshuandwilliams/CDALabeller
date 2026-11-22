#' The app's user interface
#'
#' Builds the page that [run_app()] shows. You do not normally need to call this
#' yourself.
#'
#' @param request Used internally by Shiny.
#'
#' @return A [shiny::tagList()] holding the app's user interface.
#'
#' @export
app_ui <- function(request) {
  shiny::tagList(
    golem_add_external_resources(),
    shinyjs::useShinyjs(),
    shiny::fluidPage(
      shiny::tags$div(
        class = "title-container",
        shiny::h2("CDALabeller"),
        shiny::tags$p("Draw bounding box annotations around cell death areas.")
      ),
      shiny::fluidRow(
        class = "main-container",

        # Left column: upload, image and navigation
        shiny::column(
          width = 9,
          shiny::tags$div(
            class = "step1-container",
            shiny::tags$h4("Upload Your Agroinfiltration Images"),
            shiny::fileInput(
              "image_upload",
              label = NULL,
              multiple = TRUE,
              accept = c(".tif", ".tiff"),
              placeholder = "No files selected"
            )
          ),
          shiny::tags$h4(id = "step2-title", "Step 1: Draw a Bounding Box (Click and Drag)"),
          shiny::tags$div(
            id = "image-container",
            shiny::imageOutput("output_image", height = "auto"),
            shiny::tags$canvas(id = "myCanvas")
          ),
          # Below the drawing area, so it cannot be drawn on. Its width is set
          # to the image's in canvasUtils.js, which centres the key on the image.
          shiny::tags$div(
            id = "score-key-row",
            shiny::tags$img(
              id = "score-key", src = "www/lesion_score_key.jpg",
              alt = "Cell death severity scoring key, 0 to 6"
            )
          ),
          shiny::tags$div(
            class = "image-nav",
            shiny::actionButton("prev_image", "Previous"),
            shiny::textOutput("image_counter", container = shiny::span),
            shiny::actionButton("next_image", "Next")
          )
        ),

        # Right column: annotation fields and export
        shiny::column(
          width = 3,
          class = "control-panel",
          shiny::tags$h4("Step 2: Record Treatment / Severity Score"),
          shiny::textInput("treatment_input", "Treatment:", placeholder = "e.g. Treatment A"),
          shiny::textInput("score_input", "Severity score:", placeholder = "0 to 6"),
          shiny::tags$hr(),
          shiny::actionButton("undoButton", "Undo Last Box"),
          shiny::tags$hr(),
          shiny::downloadButton("download_data", "Download Your Boxes")
        )
      )
    )
  )
}

#' Add external Resources to the Application
#'
#' @noRd
golem_add_external_resources <- function() {
  golem::add_resource_path("www", app_sys("app/www"))
  shiny::tags$head(
    golem::favicon(),
    shiny::tags$title("CDALabeller"),
    shiny::tags$link(rel = "stylesheet", type = "text/css", href = "www/styles.css"),
    shiny::tags$script(type = "module", src = "www/script.js")
  )
}

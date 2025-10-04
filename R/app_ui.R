#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'
#' @importFrom shiny tagList fluidPage h2 tags imageOutput fluidRow column actionButton textOutput span
#' @importFrom shinyFiles shinyDirButton
#' @noRd
app_ui <- function(request) {
  tagList(
    golem_add_external_resources(),
    fluidPage(
      h2("Cell Death Area Labeller"),

      fileInput(
        "image_upload",
        "Choose TIFF images",
        multiple = TRUE,
        accept = c(".tif", ".tiff")
      ),

      tags$div(
        id = "image-container",
        imageOutput("output_image", height = "auto"),
        tags$canvas(id = "myCanvas")
      ),

      fluidRow(
        column(4, actionButton("prev_image", "Previous")),
        column(4, textOutput("image_counter", container = span)),
        column(4, actionButton("next_image", "Next"))
      ),

      fluidRow(
        column(6, actionButton("undoButton", "Undo Last Box")),
        column(6, downloadButton("download_data", "Download Boxes as CSV"))
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
    bundle_resources(
      path = app_sys("app/www"),
      app_title = "CDALabeller"
    ),
    tags$link(rel = "stylesheet", type = "text/css", href = "www/styles.css"),
    tags$script(src = "www/script.js")
  )
}

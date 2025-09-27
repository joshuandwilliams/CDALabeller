#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'
#' @import shiny
#' @noRd
app_server <- function(input, output, session) {
  observeEvent(input$js_message, {
    output$server_response <- renderText({
      paste("Message from JS:", input$js_message)
    })
  })
}

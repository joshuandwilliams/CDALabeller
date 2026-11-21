# Regenerates documentation, reloads the package and runs the app on a random port.
golem::detach_all_attached()
golem::document_and_reload()
shiny::runApp(run_app(), port = httpuv::randomPort(), launch.browser = TRUE)

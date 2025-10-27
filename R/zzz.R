.onLoad <- function(libname, pkgname) {
  options("shiny.maxRequestSize" = 200 * 1024^2)
}

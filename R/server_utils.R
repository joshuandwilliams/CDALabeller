#' Process and resize an image for app display
#'
#' Reads an image from a path, resizes it to fit within max dimensions
#' while preserving aspect ratio, converts it to JPEG, and saves it to a
#' temporary file.
#'
#' @param filepath The path to the source image file.
#' @param max_width The maximum width of the output image in pixels.
#' @param max_height The maximum height of the output image in pixels.
#'
#' @return A list containing the path to the processed JPEG (`path`), and the
#'   original image's dimensions (`original_width`, `original_height`).
#'
#' @importFrom magick image_convert image_info image_read image_scale image_write
#' @noRd

process_image <- function(filepath, max_width = 1200, max_height = 1200) {
  img <- image_read(filepath)
  info <- image_info(img)
  img <- image_scale(img, paste0(max_width, "x", max_height, ">")) # Resize while preserving aspect ratio
  img <- image_convert(img, format = "jpeg") # Convert to JPEG
  out_path <- tempfile(fileext = ".jpg")
  image_write(img, path = out_path, format = "jpeg", quality = 85) # Save to temp file
  return(list(path = out_path, original_width = info$width, original_height = info$height))
}

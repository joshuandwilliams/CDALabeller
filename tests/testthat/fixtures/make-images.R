# Recreates the downscaled test images from the full-size originals (5568 x 3712).
# The originals are in the uv-agroinfiltration-dataset repository, under data/raw_images_rotated.
# Run from the package root: Rscript tests/testthat/fixtures/make-images.R <originals_dir>
src <- commandArgs(TRUE)[1]
for (f in c("_DSC0024.tif", "_DSC0025-AVRPib.tif", "_DSC2689.tif", "_DSC2690.tif")) {
  img <- magick::image_scale(magick::image_read(file.path(src, f)), "600x600")
  img <- magick::image_strip(img)
  magick::image_write(img, file.path("tests/testthat/fixtures/images", f), format = "tiff", compression = "JPEG")
}

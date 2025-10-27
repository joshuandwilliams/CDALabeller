library(shinytest2)
shinytest2::load_app_env()
library(waldo)

test_that("{shinytest2} recording: core-workflow", {
  app <- AppDriver$new(variant = platform_variant(), name = "core-workflow", height = 1367,
      width = 2259)

  # Initialise
  app$expect_values()
  app$expect_screenshot()

  # Upload images, load first image
  test_files <- c(
    "_DSC0024.tif",
    "_DSC0025-AVRPib.tif",
    "_DSC2689.tif",
    "_DSC2690.tif"
  )
  upload_paths <- file.path("test-images", test_files)
  app$upload_file(image_upload = upload_paths)
  app$expect_values()

  # --- Draw first box and details ---
  app$run_js(
    "
    appState.currentImage = '_DSC0024.tif';
    appState.originalImageWidth = 4000;
    appState.originalImageHeight = 6000;
    const box1 = {x1: 782, y1: 803, x2: 1037, y2: 1058, treatment: 'Treatment1', score: '0.5'};
    appState.drawnBoxesPerImage[appState.currentImage] = [box1];
    redraw();
    "
  )

  box1_list <- list(
    list(x1 = 782, y1 = 803, x2 = 1037, y2 = 1058, treatment = "Treatment1", score = "0.5")
  )
  app$set_inputs(
    bbox_coords = list(
      filename = "_DSC0024.tif",
      boxes = box1_list
    ),
    allow_no_input_binding_ = TRUE
  )
  app$set_inputs(treatment_input = "Treatment1")
  app$set_inputs(score_input = "0.5")
  app$expect_values()
  app$expect_screenshot()

  # --- Draw second box and details ---
  app$run_js(
    "
    const box2 = {x1: 617, y1: 1021, x2: 886, y2: 1290, treatment: 'Treatment2', score: '0.8'};
    appState.drawnBoxesPerImage[appState.currentImage].push(box2);
    redraw();
    "
  )

  box_list_2 <- list(
    list(x1 = 782, y1 = 803, x2 = 1037, y2 = 1058, treatment = "Treatment1", score = "0.5"),
    list(x1 = 617, y1 = 1021, x2 = 886, y2 = 1290, treatment = "Treatment2", score = "0.8")
  )

  # Set 'input$bbox_coords' as the full nested list
  app$set_inputs(
    bbox_coords = list(
      filename = "_DSC0024.tif",
      boxes = box_list_2
    ),
    allow_no_input_binding_ = TRUE
  )
  app$set_inputs(treatment_input = "Treatment2")
  app$set_inputs(score_input = "0.8")
  app$expect_values()
  app$expect_screenshot()

  # Undo last box
  app$click("undoButton")
  app$expect_values()
  app$expect_screenshot()

  # Next image
  app$click("next_image")
  app$expect_values()

  # Download data
  app$expect_download("download_data")
})

import appState from './state.js';
import { ensureCanvasSize, syncInputsToLastBox } from './canvasUtils.js';

/**
 * Sends the current annotations for the active image to the Shiny server.
 */
export function sendAnnotationsToShiny() {
  if (!appState.currentImage) return;

  Shiny.setInputValue("bbox_coords", {
    filename: appState.currentImage,
    boxes: appState.drawnBoxesPerImage[appState.currentImage] || []
  });
}

/**
 * Sets up the custom message handlers that listen for events from the
 * Shiny server.
 */
export function setupShinyListeners() {
  Shiny.addCustomMessageHandler("image_loaded", function(message) {
    appState.currentImage = message.filename;
    appState.originalImageWidth = message.width;
    appState.originalImageHeight = message.height;
    setTimeout(ensureCanvasSize, 100);
    syncInputsToLastBox();
  });
}

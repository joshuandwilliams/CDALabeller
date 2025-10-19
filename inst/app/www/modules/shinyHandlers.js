import appState from './state.js';
import { ensureCanvasSize } from './canvasUtils.js';

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
 * Sets up all the custom message handlers that listen for events from the
 * Shiny server.
 */
export function setupShinyListeners() {
  Shiny.addCustomMessageHandler("image_loaded", function(message) {
    appState.currentImage = message.filename;
    appState.originalImageWidth = message.width;
    appState.originalImageHeight = message.height;
    setTimeout(ensureCanvasSize, 100);

    // Function to update input states based on the newly loaded image's data
    function updateInputStates() {
      const boxes = appState.drawnBoxesPerImage[appState.currentImage];
      const hasBoxes = boxes && boxes.length > 0;
      let allInputsFound = true;

      appState.requiredFields.forEach(field => {
        const inputEl = document.getElementById(field + '_input');
        if (inputEl) {
          inputEl.disabled = false; // Always enable inputs
          if (hasBoxes) {
            const lastBox = boxes.slice(-1)[0];
            inputEl.value = lastBox[field] || "";
          } else {
            inputEl.value = "";
          }
        } else {
          allInputsFound = false;
        }
      });
      // Retry if dynamic inputs haven't been rendered by Shiny yet
      if (!allInputsFound && appState.requiredFields.length > 0) {
        setTimeout(updateInputStates, 50);
      }
    }
    updateInputStates();
  });

  Shiny.addCustomMessageHandler("clear_client_state", function(message) {
    appState.drawnBoxesPerImage = {};
  });
}

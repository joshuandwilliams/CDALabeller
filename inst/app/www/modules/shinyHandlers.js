import appState from './state.js';

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

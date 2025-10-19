/**
 * A centralized object to hold the application's shared state. This avoids
 * using global variables and provides a single source of truth.
 */
const appState = {
  // DOM element references
  canvas: null,
  ctx: null,

  // Annotation data
  drawnBoxesPerImage: {}, // All boxes, keyed by image filename
  currentImage: null, // The filename of the currently displayed image

  // Image properties
  originalImageWidth: 0,
  originalImageHeight: 0,

  // Configuration from R/Shiny
  requiredFields: ["treatment", "score"],

  // Drawing state
  isDrawing: false,
  isReady: false, // Flag to indicate if the canvas is ready for interaction
  startX: 0,
  startY: 0,
};

export default appState;

import appState from './state.js';

/**
 * Redraws the canvas. This function clears the canvas and then draws all the
 * bounding boxes stored in the state for the current image.
 */
export function redraw() {
  const image = document.querySelector("#output_image img");
  if (!image || !appState.canvas) return;

  if (image.naturalWidth === 0 || image.naturalHeight === 0) {
    return;
  }

  const displayWidth = image.offsetWidth;
  const displayHeight = image.offsetHeight;

  appState.canvas.width = displayWidth;
  appState.canvas.height = displayHeight;
  appState.ctx = appState.canvas.getContext('2d');
  appState.ctx.clearRect(0, 0, appState.canvas.width, appState.canvas.height);

  appState.ctx.strokeStyle = "red";
  appState.ctx.lineWidth = 2;

  if (appState.currentImage && appState.drawnBoxesPerImage[appState.currentImage]) {
    appState.drawnBoxesPerImage[appState.currentImage].forEach(box => {
      const pixelX = (box.x1 / appState.originalImageWidth) * appState.canvas.width;
      const pixelY = (box.y1 / appState.originalImageHeight) * appState.canvas.height;
      const pixelWidth = ((box.x2 - box.x1) / appState.originalImageWidth) * appState.canvas.width;
      const pixelHeight = ((box.y2 - box.y1) / appState.originalImageHeight) * appState.canvas.height;
      appState.ctx.strokeRect(pixelX, pixelY, pixelWidth, pixelHeight);
    });
  }
}

/**
 * Converts a rectangular box into a square, expanding from its center.
 * It includes boundary checks to ensure the square does not go outside
 * the original image dimensions.
 * @param {object} box - The box to be squared {x1, y1, x2, y2}.
 * @param {number} imgWidth - The original width of the image.
 * @param {number} imgHeight - The original height of the image.
 * @returns {object} The new, squared box coordinates.
 */
export function makeSquare(box, imgWidth, imgHeight) {
  let { x1, y1, x2, y2 } = box;
  const hlen = x2 - x1;
  const vlen = y2 - y1;
  if (hlen === vlen) return box;

  const diff = Math.abs(hlen - vlen);
  const halfDiff = diff / 2;

  if (hlen > vlen) {
    y1 -= halfDiff;
    y2 += halfDiff;
  } else {
    x1 -= halfDiff;
    x2 += halfDiff;
  }

  if (x1 < 0) { const shift = -x1; x1 += shift; x2 += shift; }
  if (x2 > imgWidth) { const shift = x2 - imgWidth; x1 -= shift; x2 -= shift; }
  if (y1 < 0) { const shift = -y1; y1 += shift; y2 += shift; }
  if (y2 > imgHeight) { const shift = y2 - imgHeight; y1 -= shift; y2 -= shift; }

  return { x1: Math.round(x1), y1: Math.round(y1), x2: Math.round(x2), y2: Math.round(y2) };
}

/**
 * Ensures the canvas element is correctly sized to match the displayed image.
 * This is crucial for responsive behavior and accurate coordinate mapping. It
 * also manages the visibility and interactivity of the canvas.
 */
export function ensureCanvasSize() {
  const image = document.querySelector("#output_image img");
  if (!image || !appState.canvas) return;

  const checkImageSize = () => {
    if (image.offsetWidth > 0 && image.offsetHeight > 0) {
      appState.canvas.width = image.offsetWidth;
      appState.canvas.height = image.offsetHeight;
      redraw();
      appState.isReady = true;
      appState.canvas.style.visibility = "visible";
      appState.canvas.style.pointerEvents = "auto";
    } else {
      setTimeout(checkImageSize, 10);
    }
  };

  appState.canvas.style.pointerEvents = "none";
  appState.canvas.style.visibility = "hidden";
  appState.isReady = false;

  if (image.complete && image.offsetWidth > 0) {
    checkImageSize();
  } else {
    image.onload = checkImageSize;
    setTimeout(checkImageSize, 50);
  }
}

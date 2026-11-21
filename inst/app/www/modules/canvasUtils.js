import appState from './state.js';

/**
 * Resizes the canvas to the displayed image, which also clears it, then draws
 * the current image's boxes. The last box is white and thick, the rest blue.
 */
export function redraw() {
  const image = document.querySelector("#output_image img");
  if (!image || !appState.canvas || image.naturalWidth === 0) return;

  appState.canvas.width = image.offsetWidth;
  appState.canvas.height = image.offsetHeight;

  const boxes = appState.drawnBoxesPerImage[appState.currentImage] || [];
  boxes.forEach((box, index) => {
    const isLast = index === boxes.length - 1;
    appState.ctx.strokeStyle = isLast ? "white" : "blue";
    appState.ctx.lineWidth = isLast ? 4 : 2;

    const scaleX = appState.canvas.width / appState.originalImageWidth;
    const scaleY = appState.canvas.height / appState.originalImageHeight;
    appState.ctx.strokeRect(box.x1 * scaleX, box.y1 * scaleY, (box.x2 - box.x1) * scaleX, (box.y2 - box.y1) * scaleY);
  });
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

  const halfDiff = Math.abs(hlen - vlen) / 2;

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
 * Sizes the canvas and the score key to the displayed image once it has
 * rendered, then enables drawing.
 */
export function ensureCanvasSize() {
  const image = document.querySelector("#output_image img");
  if (!image || !appState.canvas) return;

  const checkImageSize = () => {
    if (image.offsetWidth > 0 && image.offsetHeight > 0) {
      document.getElementById("score-key").style.width = image.offsetWidth + "px";
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

/**
 * Fills the treatment and score inputs with the current image's last box,
 * or clears them if it has no boxes.
 */
export function syncInputsToLastBox() {
  const boxes = appState.drawnBoxesPerImage[appState.currentImage] || [];
  const lastBox = boxes[boxes.length - 1];
  appState.requiredFields.forEach(field => {
    document.getElementById(field + '_input').value = (lastBox && lastBox[field]) || "";
  });
}

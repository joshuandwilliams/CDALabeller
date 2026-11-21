import appState from './state.js';
import { isValidScore } from './annotationUtils.js';

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
 * or clears them if it has no boxes, and updates the score's error state.
 */
export function syncInputsToLastBox() {
  const boxes = appState.drawnBoxesPerImage[appState.currentImage] || [];
  const lastBox = boxes[boxes.length - 1];
  appState.requiredFields.forEach(field => {
    document.getElementById(field + '_input').value = (lastBox && lastBox[field]) || "";
  });
  const scoreInput = document.getElementById('score_input');
  scoreInput.closest('.form-group').classList.toggle('has-error', !isValidScore(scoreInput.value));
}

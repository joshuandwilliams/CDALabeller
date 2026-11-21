import appState from './state.js';
import { redraw, ensureCanvasSize, syncInputsToLastBox } from './canvasUtils.js';
import { canvasToImageBox, makeSquare, isBoxTooLarge, isEmptyBox, sanitizeScore, isValidScore } from './annotationUtils.js';
import { sendAnnotationsToShiny } from './shinyHandlers.js';

/**
 * Sets up all DOM event listeners for the application: canvas drawing, undo,
 * window resizing, and the treatment/score inputs.
 */
export function setupEventListeners() {
  // Live drawing of the new box
  function draw(e) {
    if (!appState.isDrawing) return;
    redraw();
    const currentX = Math.max(0, Math.min(e.offsetX, appState.canvas.width));
    const currentY = Math.max(0, Math.min(e.offsetY, appState.canvas.height));
    appState.ctx.strokeStyle = "blue";
    appState.ctx.lineWidth = 4;
    appState.ctx.strokeRect(appState.startX, appState.startY, currentX - appState.startX, currentY - appState.startY);
  }

  // Finalize a box on mouse up, in original-image pixels
  function handleMouseUp(e) {
    if (!appState.isReady || !appState.isDrawing) return;
    appState.isDrawing = false;
    const imgWidth = appState.originalImageWidth;
    const imgHeight = appState.originalImageHeight;
    const newBox = canvasToImageBox(
      { x: appState.startX, y: appState.startY },
      { x: e.offsetX, y: e.offsetY },
      { width: appState.canvas.width, height: appState.canvas.height },
      { width: imgWidth, height: imgHeight }
    );

    if (isEmptyBox(newBox)) {
      redraw();
      return;
    }
    if (isBoxTooLarge(newBox, imgWidth, imgHeight)) {
      alert(`The box you drew is too large. The maximum size for any side is ${Math.min(imgWidth, imgHeight)} pixels (the shortest side of this image).`);
      redraw();
      return;
    }

    const boxes = appState.drawnBoxesPerImage[appState.currentImage] ??= [];
    boxes.push(makeSquare(newBox, imgWidth, imgHeight));
    redraw();
    syncInputsToLastBox();
    document.getElementById(appState.requiredFields[0] + '_input').focus();
    sendAnnotationsToShiny();
  }

  appState.canvas.addEventListener('mousedown', (e) => {
    if (!appState.isReady) return;
    appState.isDrawing = true;
    appState.startX = e.offsetX;
    appState.startY = e.offsetY;
  });
  appState.canvas.addEventListener('mousemove', draw);
  appState.canvas.addEventListener('mouseup', handleMouseUp);
  appState.canvas.addEventListener('mouseleave', () => {
    if (appState.isDrawing) {
      appState.isDrawing = false;
      redraw();
    }
  });

  window.addEventListener('resize', () => { setTimeout(ensureCanvasSize, 100); });

  document.getElementById("undoButton").addEventListener("click", () => {
    const boxes = appState.drawnBoxesPerImage[appState.currentImage];
    if (!boxes || boxes.length === 0) return;
    boxes.pop();
    syncInputsToLastBox();
    redraw();
    sendAnnotationsToShiny();
  });

  // Copy input values onto the last box. Scores outside 0-6 are flagged as errors.
  function updateLastBoxField(field, value) {
    const boxes = appState.drawnBoxesPerImage[appState.currentImage];
    if (boxes && boxes.length > 0) {
      boxes[boxes.length - 1][field] = value;
      sendAnnotationsToShiny();
    }
  }
  document.addEventListener('input', function(e) {
    if (e.target.id === 'treatment_input') {
      updateLastBoxField('treatment', e.target.value);
    } else if (e.target.id === 'score_input') {
      e.target.value = sanitizeScore(e.target.value);
      e.target.closest('.form-group').classList.toggle('has-error', !isValidScore(e.target.value));
      updateLastBoxField('score', e.target.value);
    }
  });
}

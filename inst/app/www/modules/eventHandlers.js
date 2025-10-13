import appState from './state.js';
import { redraw, makeSquare, ensureCanvasSize } from './canvasUtils.js';
import { sendAnnotationsToShiny } from './shinyHandlers.js';

/**
 * Sets up all DOM event listeners for the application, including canvas drawing,
 * button clicks, and dynamic input handling.
 */
export function setupEventListeners() {
  // Live drawing of the new box
  function draw(e) {
    if (!appState.isDrawing) return;
    redraw(); // Redraw existing boxes first
    const currentX = Math.max(0, Math.min(e.offsetX, appState.canvas.width));
    const currentY = Math.max(0, Math.min(e.offsetY, appState.canvas.height));
    appState.ctx.strokeStyle = "red";
    appState.ctx.lineWidth = 2;
    appState.ctx.strokeRect(appState.startX, appState.startY, currentX - appState.startX, currentY - appState.startY);
  }

  // Finalize a box on mouse up
  function handleMouseUp(e) {
    if (!appState.isReady || !appState.isDrawing) return;
    appState.isDrawing = false;
    const endX = e.offsetX;
    const endY = e.offsetY;

    let newBox = {
      x1: Math.round((Math.min(appState.startX, endX) / appState.canvas.width) * appState.originalImageWidth),
      y1: Math.round((Math.min(appState.startY, endY) / appState.canvas.height) * appState.originalImageHeight),
      x2: Math.round((Math.max(appState.startX, endX) / appState.canvas.width) * appState.originalImageWidth),
      y2: Math.round((Math.max(appState.startY, endY) / appState.canvas.height) * appState.originalImageHeight),
    };

    appState.requiredFields.forEach(field => { newBox[field] = ""; });
    const squaredBox = makeSquare(newBox, appState.originalImageWidth, appState.originalImageHeight);

    if (!appState.drawnBoxesPerImage[appState.currentImage]) {
      appState.drawnBoxesPerImage[appState.currentImage] = [];
    }
    appState.drawnBoxesPerImage[appState.currentImage].push(squaredBox);
    redraw();

    appState.requiredFields.forEach((field, index) => {
      const inputEl = document.getElementById(field + '_input');
      if (inputEl) {
        inputEl.disabled = false;
        inputEl.value = "";
        if (index === 0) { inputEl.focus(); }
      }
    });
    sendAnnotationsToShiny();
  }

  // Validation and start drawing on mouse down
  appState.canvas.addEventListener('mousedown', (e) => {
    if (!appState.isReady) return;
    const boxes = appState.drawnBoxesPerImage[appState.currentImage];
    if (boxes && boxes.length > 0) {
      const lastBox = boxes.slice(-1)[0];
      const firstEmptyField = appState.requiredFields.find(field => !lastBox[field] || lastBox[field].toString().trim() === "");
      if (firstEmptyField) {
        const inputToFocus = document.getElementById(firstEmptyField + '_input');
        if (inputToFocus) {
          inputToFocus.style.transition = 'background-color 0.1s';
          inputToFocus.style.backgroundColor = '#ffdddd';
          setTimeout(() => { inputToFocus.style.backgroundColor = ''; }, 500);
          inputToFocus.focus();
        }
        return;
      }
    }
    appState.isDrawing = true;
    appState.startX = e.offsetX;
    appState.startY = e.offsetY;
  });

  // Attach other canvas listeners
  appState.canvas.addEventListener('mousemove', draw);
  appState.canvas.addEventListener('mouseup', handleMouseUp);
  appState.canvas.addEventListener('mouseleave', () => {
    if (appState.isDrawing) {
      appState.isDrawing = false;
      redraw();
    }
  });

  // Handle window resizing
  window.addEventListener('resize', () => { setTimeout(ensureCanvasSize, 100); });

  // Handle undo button
  function undoLastBox() {
    const boxes = appState.drawnBoxesPerImage[appState.currentImage];
    if (boxes && boxes.length > 0) {
      boxes.pop();
      const newLastBox = boxes.length > 0 ? boxes.slice(-1)[0] : null;
      appState.requiredFields.forEach(field => {
        const inputEl = document.getElementById(field + '_input');
        if (inputEl) {
          inputEl.value = newLastBox ? (newLastBox[field] || "") : "";
          inputEl.disabled = !newLastBox;
        }
      });
      redraw();
      sendAnnotationsToShiny();
    }
  }
  document.getElementById("undoButton").addEventListener("click", undoLastBox);

  // Handle dynamic text inputs
  function updateLastBoxField(field, value) {
    const boxes = appState.drawnBoxesPerImage[appState.currentImage];
    if (boxes && boxes.length > 0) {
      boxes.slice(-1)[0][field] = value;
      sendAnnotationsToShiny();
    }
  }
  document.addEventListener('input', function(e) {
    if (e.target.id === 'treatment_input') {
      updateLastBoxField('treatment', e.target.value);
    } else if (e.target.id === 'score_input') {
      const sanitizedValue = e.target.value.replace(/[^0-9.]/g, '').replace(/(\..*)\./g, '$1');
      e.target.value = sanitizedValue;
      updateLastBoxField('score', sanitizedValue);
    }
  });
}

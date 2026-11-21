/**
 * Pure functions for box geometry and score input. They have no DOM or state
 * dependencies, so they are unit tested directly (tests/js).
 */

/** Highest score on the lesion score key. */
export const MAX_SCORE = 6;

/**
 * Converts a drag between two canvas points into a box in original-image pixels.
 * @param {{x: number, y: number}} start - Drag start, in canvas pixels.
 * @param {{x: number, y: number}} end - Drag end, in canvas pixels.
 * @param {{width: number, height: number}} canvas - Displayed canvas size.
 * @param {{width: number, height: number}} image - Original image size.
 * @returns {{x1: number, y1: number, x2: number, y2: number}} Integer box with x1 <= x2, y1 <= y2.
 */
export function canvasToImageBox(start, end, canvas, image) {
  const scaleX = image.width / canvas.width;
  const scaleY = image.height / canvas.height;
  return {
    x1: Math.round(Math.min(start.x, end.x) * scaleX),
    y1: Math.round(Math.min(start.y, end.y) * scaleY),
    x2: Math.round(Math.max(start.x, end.x) * scaleX),
    y2: Math.round(Math.max(start.y, end.y) * scaleY),
  };
}

/**
 * Converts a rectangular box into a square, expanding the shorter side about
 * the centre, then shifting the square back inside the image if needed.
 * The caller must ensure the longer side fits in the image (see isBoxTooLarge).
 * @param {{x1: number, y1: number, x2: number, y2: number}} box - Box in image pixels.
 * @param {number} imgWidth - The original width of the image.
 * @param {number} imgHeight - The original height of the image.
 * @returns {{x1: number, y1: number, x2: number, y2: number}} The squared box.
 */
export function makeSquare(box, imgWidth, imgHeight) {
  let { x1, y1, x2, y2 } = box;
  const hlen = x2 - x1;
  const vlen = y2 - y1;
  if (hlen === vlen) return { x1, y1, x2, y2 };

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
 * A box is too large to square if either side exceeds the image's shortest side.
 * @param {{x1: number, y1: number, x2: number, y2: number}} box - Box in image pixels.
 * @param {number} imgWidth - The original width of the image.
 * @param {number} imgHeight - The original height of the image.
 * @returns {boolean}
 */
export function isBoxTooLarge(box, imgWidth, imgHeight) {
  const shortestSide = Math.min(imgWidth, imgHeight);
  return box.x2 - box.x1 > shortestSide || box.y2 - box.y1 > shortestSide;
}

/**
 * A click without a drag gives a box with no width and no height.
 * @param {{x1: number, y1: number, x2: number, y2: number}} box - Box in image pixels.
 * @returns {boolean}
 */
export function isEmptyBox(box) {
  return box.x2 === box.x1 && box.y2 === box.y1;
}

/**
 * Keeps only digits and the first decimal point.
 * @param {string} value - Raw input text.
 * @returns {string}
 */
export function sanitizeScore(value) {
  return value.replace(/[^0-9.]/g, '').replace(/(\..*)\./g, '$1');
}

/**
 * An empty score is allowed (it is exported as NA). Otherwise it must be a
 * number from 0 to MAX_SCORE.
 * @param {string} value - Sanitized score text.
 * @returns {boolean}
 */
export function isValidScore(value) {
  if (value === '') return true;
  const score = Number(value);
  return Number.isFinite(score) && score >= 0 && score <= MAX_SCORE;
}

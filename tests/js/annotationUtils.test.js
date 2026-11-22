import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  canvasToImageBox, makeSquare, isBoxTooLarge, isEmptyBox, sanitizeScore, isValidScore,
} from '../../inst/app/www/modules/annotationUtils.js';

const canvas = { width: 1200, height: 800 };
const image = { width: 2400, height: 1600 };

test('canvasToImageBox scales canvas pixels to image pixels', () => {
  assert.deepEqual(
    canvasToImageBox({ x: 100, y: 100 }, { x: 200, y: 180 }, canvas, image),
    { x1: 200, y1: 200, x2: 400, y2: 360 },
  );
});

test('canvasToImageBox orders corners whatever the drag direction', () => {
  assert.deepEqual(
    canvasToImageBox({ x: 200, y: 180 }, { x: 100, y: 100 }, canvas, image),
    { x1: 200, y1: 200, x2: 400, y2: 360 },
  );
});

test('canvasToImageBox rounds to whole pixels', () => {
  // Scale 10/3: 1 -> 3.33 -> 3, 2 -> 6.67 -> 7
  assert.deepEqual(
    canvasToImageBox({ x: 1, y: 1 }, { x: 2, y: 2 }, { width: 3, height: 3 }, { width: 10, height: 10 }),
    { x1: 3, y1: 3, x2: 7, y2: 7 },
  );
});

test('makeSquare expands the shorter side about the centre', () => {
  assert.deepEqual(makeSquare({ x1: 200, y1: 200, x2: 400, y2: 360 }, 2400, 1600), { x1: 200, y1: 180, x2: 400, y2: 380 });
  assert.deepEqual(makeSquare({ x1: 10, y1: 0, x2: 20, y2: 30 }, 100, 100), { x1: 0, y1: 0, x2: 30, y2: 30 });
});

test('makeSquare shifts the square back inside the image', () => {
  assert.deepEqual(makeSquare({ x1: 0, y1: 0, x2: 10, y2: 30 }, 100, 100), { x1: 0, y1: 0, x2: 30, y2: 30 });
  assert.deepEqual(makeSquare({ x1: 95, y1: 0, x2: 100, y2: 20 }, 100, 100), { x1: 80, y1: 0, x2: 100, y2: 20 });
});

test('makeSquare keeps the side exact when the difference is odd', () => {
  assert.deepEqual(makeSquare({ x1: 0, y1: 10, x2: 101, y2: 110 }, 200, 200), { x1: 0, y1: 10, x2: 101, y2: 111 });
});

test('makeSquare output is square, inside the image and contains the input (random boxes)', () => {
  // Deterministic LCG so failures are reproducible
  let seed = 42;
  const rand = (n) => { seed = (seed * 1664525 + 1013904223) % 2 ** 32; return Math.floor((seed / 2 ** 32) * n); };
  for (let i = 0; i < 5000; i++) {
    const w = 1 + rand(3000);
    const h = 1 + rand(3000);
    const side = Math.min(w, h);
    const x1 = rand(w);
    const y1 = rand(h);
    const box = { x1, y1, x2: Math.min(w, x1 + rand(side + 1)), y2: Math.min(h, y1 + rand(side + 1)) };
    if (isBoxTooLarge(box, w, h)) continue;
    const sq = makeSquare(box, w, h);
    const msg = JSON.stringify({ box, w, h, sq });
    assert.equal(sq.x2 - sq.x1, sq.y2 - sq.y1, msg);
    assert.ok(sq.x1 >= 0 && sq.y1 >= 0 && sq.x2 <= w && sq.y2 <= h, msg);
    assert.ok(sq.x1 <= box.x1 && sq.y1 <= box.y1 && sq.x2 >= box.x2 && sq.y2 >= box.y2, msg);
  }
});

test('isBoxTooLarge compares each side with the shortest image side', () => {
  assert.equal(isBoxTooLarge({ x1: 0, y1: 0, x2: 1600, y2: 10 }, 2400, 1600), false);
  assert.equal(isBoxTooLarge({ x1: 0, y1: 0, x2: 1601, y2: 10 }, 2400, 1600), true);
});

test('isEmptyBox is true only when both sides are zero', () => {
  assert.equal(isEmptyBox({ x1: 5, y1: 5, x2: 5, y2: 5 }), true);
  assert.equal(isEmptyBox({ x1: 5, y1: 5, x2: 9, y2: 5 }), false);
});

test('sanitizeScore keeps digits and the first decimal point', () => {
  assert.equal(sanitizeScore('3a.5.1'), '3.51');
  assert.equal(sanitizeScore('-2'), '2');
  assert.equal(sanitizeScore(''), '');
});

test('isValidScore accepts empty or 0 to 6', () => {
  for (const v of ['', '0', '2.5', '6']) assert.equal(isValidScore(v), true, v);
  for (const v of ['6.1', '7', '.']) assert.equal(isValidScore(v), false, v);
});

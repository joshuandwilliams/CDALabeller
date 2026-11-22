import appState from './modules/state.js';
import { watchImage } from './modules/canvasUtils.js';
import { setupEventListeners } from './modules/eventHandlers.js';

document.addEventListener('DOMContentLoaded', () => {
  appState.canvas = document.getElementById('myCanvas');
  appState.ctx = appState.canvas.getContext('2d');
  watchImage();
  setupEventListeners();
});

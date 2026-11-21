import appState from './modules/state.js';
import { setupShinyListeners } from './modules/shinyHandlers.js';
import { setupEventListeners } from './modules/eventHandlers.js';

document.addEventListener('DOMContentLoaded', () => {
  appState.canvas = document.getElementById('myCanvas');
  appState.ctx = appState.canvas.getContext('2d');
  setupShinyListeners();
  setupEventListeners();
});

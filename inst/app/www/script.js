// Import all modules
import appState from './modules/state.js';
import { setupShinyListeners } from './modules/shinyHandlers.js';
import { setupEventListeners } from './modules/eventHandlers.js';

/**
 * Main application entry point. This script orchestrates the setup of the
 * annotation tool by initializing state and attaching all necessary listeners.
 */
document.addEventListener('DOMContentLoaded', () => {
  // 1. Initialize references to DOM elements in the shared state
  appState.canvas = document.getElementById('myCanvas');
  appState.ctx = appState.canvas.getContext('2d');

  // 2. Set up listeners for communication from the R/Shiny server
  setupShinyListeners();

  // 3. Set up listeners for user interaction with the DOM (canvas, buttons, etc.)
  setupEventListeners();

  console.log("Annotation tool initialized.");
});

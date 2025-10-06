// Global variables: Declare shared variables but don't assign DOM elements yet.
var canvas = null;
var ctx = null;
var drawnBoxesPerImage = {}; // Object to store boxes for each image: { "image1.tif": [{box1}, {box2}], ... }
var currentImage = null; // Track which image is currently displayed
var originalImageWidth = 0;
var originalImageHeight = 0;

// Global functions: Redraw is global so the Shiny handler and drawing functions can all call it.
function redraw() {
  const image = document.querySelector("#output_image img");
  if (!image || !canvas) return;

  // Wait for image to have actual dimensions
  if (image.naturalWidth === 0 || image.naturalHeight === 0) {
    console.log("Image not yet loaded, waiting...");
    return;
  }

  const displayWidth = image.offsetWidth;
  const displayHeight = image.offsetHeight;

  // Match canvas dimensions to the image's current displayed size
  canvas.width = displayWidth;
  canvas.height = displayHeight;

  ctx = canvas.getContext('2d');
  ctx.clearRect(0, 0, canvas.width, canvas.height); // Clear everything

  // Redraw all stored boxes for CURRENT image only
  ctx.strokeStyle = "red";
  ctx.lineWidth = 2;

  if (currentImage && drawnBoxesPerImage[currentImage]) {
    drawnBoxesPerImage[currentImage].forEach(box => {
      // Convert absolute integer coordinates back to relative display coordinates
      const pixelX = (box.x1 / originalImageWidth) * canvas.width;
      const pixelY = (box.y1 / originalImageHeight) * canvas.height;
      const pixelWidth = ((box.x2 - box.x1) / originalImageWidth) * canvas.width;
      const pixelHeight = ((box.y2 - box.y1) / originalImageHeight) * canvas.height;
      ctx.strokeRect(pixelX, pixelY, pixelWidth, pixelHeight);
    });
  } else {
  }
}

function makeSquare(box, imgWidth, imgHeight) {
  let { x1, y1, x2, y2 } = box;

  const hlen = x2 - x1;
  const vlen = y2 - y1;

  if (hlen === vlen) return box;

  const diff = Math.abs(hlen - vlen);
  const halfDiff = diff / 2;

  if (hlen > vlen) { // Box is wider than it is tall
    y1 -= halfDiff;
    y2 += halfDiff;
  } else { // Box is taller than it is wide
    x1 -= halfDiff;
    x2 += halfDiff;
  }

  // Boundary checks to shift box if it goes out of bounds
  if (x1 < 0) {
    const shift = -x1;
    x1 += shift;
    x2 += shift;
  }
  if (x2 > imgWidth) {
    const shift = x2 - imgWidth;
    x1 -= shift;
    x2 -= shift;
  }
  if (y1 < 0) {
    const shift = -y1;
    y1 += shift;
    y2 += shift;
  }
  if (y2 > imgHeight) {
    const shift = y2 - imgHeight;
    y1 -= shift;
    y2 -= shift;
  }

  // Final rounding to ensure integer coordinates
  return {
    x1: Math.round(x1),
    y1: Math.round(y1),
    x2: Math.round(x2),
    y2: Math.round(y2)
  };
}

// Function to ensure canvas is properly sized when image loads
var isReady = false;

function ensureCanvasSize() {
  const image = document.querySelector("#output_image img");
  if (!image || !canvas) {
    console.log("Image or canvas not found in ensureCanvasSize");
    return;
  }

  // Use a more robust approach to wait for the image to be fully rendered
  const checkImageSize = () => {
    if (image.offsetWidth > 0 && image.offsetHeight > 0) {
      console.log("Image ready with dimensions:", image.offsetWidth, "x", image.offsetHeight);
      canvas.width = image.offsetWidth;
      canvas.height = image.offsetHeight;
      redraw();
      isReady = true;
      canvas.style.visibility = "visible";
      canvas.style.pointerEvents = "auto";
    } else {
      // If image still doesn't have size, wait a bit more
      console.log("Image size still 0, retrying...");
      setTimeout(checkImageSize, 10);
    }
  };

  // Initially disable interaction until image loads
  canvas.style.pointerEvents = "none";
  canvas.style.visibility = "hidden";
  isReady = false;

  if (image.complete && image.offsetWidth > 0) {
    // Image is already loaded and has dimensions
    console.log("Image already complete with dimensions");
    canvas.width = image.offsetWidth;
    canvas.height = image.offsetHeight;
    redraw();
    isReady = true;
    canvas.style.visibility = "visible";
    canvas.style.pointerEvents = "auto";
  } else {
    // Wait for image to load and have dimensions
    console.log("Waiting for image to load...");
    image.onload = checkImageSize;
    // Also try after a short delay in case onload already fired
    setTimeout(checkImageSize, 50);
  }
}

// Page initialisation and event listeners
var listenersAttached = false; // Flag to prevent duplicate listeners

document.addEventListener('DOMContentLoaded', function() {
  console.log("DOM ready. Setting up basic interactivity");

  canvas = document.getElementById('myCanvas');
  ctx = canvas.getContext('2d');

  // Only attach listeners once
  if (!listenersAttached) {
    /* Canvas Drawing Logic */
    let isDrawing = false;
    let startX = 0;
    let startY = 0;

    function draw(e) {
      if (!isDrawing) return;
      redraw(); // Redraw permanent boxes

      // Draw the new 'live' box
      const currentX = Math.max(0, Math.min(e.offsetX, canvas.width));
      const currentY = Math.max(0, Math.min(e.offsetY, canvas.height));
      const width = currentX - startX;
      const height = currentY - startY;
      ctx.strokeStyle = "red";
      ctx.lineWidth = 2;
      ctx.strokeRect(startX, startY, width, height);
    }

    function handleMouseUp(e) {
      if (!isReady) return;
      if (!isDrawing) return;
      isDrawing = false;

      const endX = e.offsetX;
      const endY = e.offsetY;

      // Create box with absolute integer coordinates relative to original image size
      let newBox = {
        x1: Math.round((Math.min(startX, endX) / canvas.width) * originalImageWidth),
        y1: Math.round((Math.min(startY, endY) / canvas.height) * originalImageHeight),
        x2: Math.round((Math.max(startX, endX) / canvas.width) * originalImageWidth),
        y2: Math.round((Math.max(startY, endY) / canvas.height) * originalImageHeight),
        treatment: "" // Initialize with empty treatment
      };

      // Convert the new box to a square
      const squaredBox = makeSquare(newBox, originalImageWidth, originalImageHeight);

      // Initialize array for this image if it doesn't exist
      if (!drawnBoxesPerImage[currentImage]) {
        drawnBoxesPerImage[currentImage] = [];
      }

      // Add the new SQUARED box to the current image's array
      drawnBoxesPerImage[currentImage].push(squaredBox);

      console.log("Box added. Total boxes for", currentImage, ":", drawnBoxesPerImage[currentImage].length);

      redraw();

      // Enable, clear, and focus the treatment input for the new box
      const treatmentInput = document.getElementById('treatment_input');
      treatmentInput.disabled = false;
      treatmentInput.value = "";
      treatmentInput.focus();

      // Send the box data back to R with filename and all boxes for this image
      Shiny.setInputValue("bbox_coords", {
        filename: currentImage,
        boxes: drawnBoxesPerImage[currentImage]
      });
    }

    /* Event Listeners for Drawing */
    /* Event Listeners for Drawing */
    canvas.addEventListener('mousedown', (e) => {
      if (!isReady) return;

      // Check if the last box needs a treatment before allowing a new one
      if (currentImage && drawnBoxesPerImage[currentImage] && drawnBoxesPerImage[currentImage].length > 0) {
        const lastBox = drawnBoxesPerImage[currentImage].slice(-1)[0];
        if (!lastBox.treatment || lastBox.treatment.trim() === "") {
          const treatmentInput = document.getElementById('treatment_input');
          // Flash the input box to alert the user and focus it
          treatmentInput.style.transition = 'background-color 0.1s';
          treatmentInput.style.backgroundColor = '#ffdddd';
          setTimeout(() => {
            treatmentInput.style.backgroundColor = '';
          }, 500);
          treatmentInput.focus();
          return; // Block drawing
        }
      }

      isDrawing = true;
      startX = e.offsetX;
      startY = e.offsetY;
    });

    canvas.addEventListener('mousemove', (e) => {
      if (!isReady) return;
      draw(e);
    });

    canvas.addEventListener('mouseup', handleMouseUp);

    canvas.addEventListener('mouseleave', () => {
      if (isDrawing) {
        isDrawing = false;
        redraw();
        console.log("Drawing cancelled: mouse left canvas.");
      }
    });

    // Handle window resize to keep canvas sized correctly
    window.addEventListener('resize', () => {
      setTimeout(ensureCanvasSize, 100);
    });

    listenersAttached = true;
    console.log("Event listeners attached");

    function undoLastBox() {
      const treatmentInput = document.getElementById('treatment_input');
      if (currentImage && drawnBoxesPerImage[currentImage] && drawnBoxesPerImage[currentImage].length > 0) {
        drawnBoxesPerImage[currentImage].pop(); // Remove the last box

        const boxes = drawnBoxesPerImage[currentImage];
        const newLastBox = boxes && boxes.length > 0 ? boxes.slice(-1)[0] : null;

        // Update the treatment input to reflect the new state
        if (newLastBox) {
          treatmentInput.value = newLastBox.treatment;
        } else {
          treatmentInput.value = "";
          treatmentInput.disabled = true; // Disable if no boxes are left
        }

        redraw();
        Shiny.setInputValue("bbox_coords", {
          filename: currentImage,
          boxes: drawnBoxesPerImage[currentImage]
        });
      }
    }

    document.getElementById("undoButton").addEventListener("click", undoLastBox);

    const treatmentInput = document.getElementById('treatment_input');
    treatmentInput.disabled = true; // Disable the input on page load

    treatmentInput.addEventListener('input', () => {
      if (currentImage && drawnBoxesPerImage[currentImage] && drawnBoxesPerImage[currentImage].length > 0) {
        const lastBox = drawnBoxesPerImage[currentImage].slice(-1)[0];
        lastBox.treatment = treatmentInput.value;

        // Resend data to R on every keystroke to keep it in sync
        Shiny.setInputValue("bbox_coords", {
          filename: currentImage,
          boxes: drawnBoxesPerImage[currentImage]
        });
      }
    });
  }
});

// Shiny message handler - called when R loads a new image
Shiny.addCustomMessageHandler("image_loaded", function(message) {
  console.log("Message received from R - Image loaded:", message.filename);

  // Update the current image filename and original dimensions
  currentImage = message.filename;
  originalImageWidth = message.width;
  originalImageHeight = message.height;

  // Set the state of the treatment input based on the new image's data
  const treatmentInput = document.getElementById('treatment_input');
  const boxes = drawnBoxesPerImage[currentImage];
  const lastBox = boxes && boxes.length > 0 ? boxes.slice(-1)[0] : null;

  if (lastBox) {
    treatmentInput.disabled = false;
    treatmentInput.value = lastBox.treatment;
  } else {
    treatmentInput.disabled = true;
    treatmentInput.value = "";
  }

  // Ensure canvas is properly sized and boxes are redrawn for this image
  setTimeout(ensureCanvasSize, 100);
});

// Shiny message handler - called when a new file upload starts
Shiny.addCustomMessageHandler("clear_client_state", function(message) {
  console.log("New file upload detected. Clearing client-side box data.");
  drawnBoxesPerImage = {};
});

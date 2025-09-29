// Global variables: Declare shared variables but don't assign DOM elements yet.
var canvas = null;
var ctx = null;
var drawnBoxesPerImage = {}; // Object to store boxes for each image: { "image1.tif": [{box1}, {box2}], ... }
var currentImage = null; // Track which image is currently displayed

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
      // Convert relative coordinates back to absolute pixel values
      const pixelX = box.x1 * canvas.width;
      const pixelY = box.y1 * canvas.height;
      const pixelWidth = (box.x2 - box.x1) * canvas.width;
      const pixelHeight = (box.y2 - box.y1) * canvas.height;
      ctx.strokeRect(pixelX, pixelY, pixelWidth, pixelHeight);
    });
  } else {
  }
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

      // Create box with normalized coordinates (0-1 range)
      const newBox = {
        x1: Math.min(startX, endX) / canvas.width,
        y1: Math.min(startY, endY) / canvas.height,
        x2: Math.max(startX, endX) / canvas.width,
        y2: Math.max(startY, endY) / canvas.height
      };

      // Initialize array for this image if it doesn't exist
      if (!drawnBoxesPerImage[currentImage]) {
        drawnBoxesPerImage[currentImage] = [];
      }

      // Add the new box to the current image's array
      drawnBoxesPerImage[currentImage].push(newBox);

      console.log("Box added. Total boxes for", currentImage, ":", drawnBoxesPerImage[currentImage].length);

      redraw();

      // Send the box data back to R with filename and all boxes for this image
      Shiny.setInputValue("bbox_coords", {
        filename: currentImage,
        boxes: drawnBoxesPerImage[currentImage]
      });
    }

    /* Event Listeners for Drawing */
    canvas.addEventListener('mousedown', (e) => {
      if (!isReady) return;
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
      if (currentImage && drawnBoxesPerImage[currentImage] && drawnBoxesPerImage[currentImage].length > 0) {
        drawnBoxesPerImage[currentImage].pop();
        redraw();
        Shiny.setInputValue("bbox_coords", {
          filename: currentImage,
          boxes: drawnBoxesPerImage[currentImage]
        });
      }
    }

    document.getElementById("undoButton").addEventListener("click", undoLastBox);
  }
});

// Shiny message handler - called when R loads a new image
Shiny.addCustomMessageHandler("image_loaded", function(message) {
  console.log("Message received from R - Image loaded:", message.filename);

  // Update the current image filename
  currentImage = message.filename;

  // Ensure canvas is properly sized and boxes are redrawn for this image
  setTimeout(ensureCanvasSize, 100);
});

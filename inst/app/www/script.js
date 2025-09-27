document.addEventListener("DOMContentLoaded", function() {
  document.getElementById("my_button").addEventListener("click", function() {
    const message = "Hello from JavaScript at " + new Date().toLocaleTimeString();
    Shiny.setInputValue("js_message", message);
  });
});

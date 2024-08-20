import Router from "./src/router.js";

window.addEventListener("DOMContentLoaded", async function initRouter() {
  console.log("DOM is ready");
  await Router.init();
});

document.addEventListener(
  "focus",
  function (event) {
    if (
      event.target.tagName === "INPUT" ||
      event.target.tagName === "TEXTAREA" ||
      event.target.tagName === "SELECT"
    ) {
      event.target.scrollIntoView({ behavior: "smooth", block: "center" });
    }
  },
  true
);

import CreateForm from "./flow.js";

var Router = {
  init: async function init_() {
    document.querySelectorAll("a").forEach((a) => {
      a.addEventListener("click", function overrideNavlinks(event) {
        event.preventDefault();
        var href = event.target.getAttribute("href");
        Router.go(href);
      });
    });

    window.addEventListener("popstate", (event) => {
      Router.go(event.state.route, false);
      return;
    });
    var route = location.pathname + location.search;
    await Router.go(route);
  },
  go: async function go_(route, addToHistory = true) {
    console.log("Navigating to", route);

    if (addToHistory) {
      history.pushState({ route }, "", route);
    }
    var pageElement;

    // In case the browser started the login somewhere else with the Kratos server
    var flowId = new URL(location.href).searchParams.get("flow");

    switch (true) {
      case route.startsWith("/login"):
        pageElement = await CreateForm(flowId, "login");
        break;
      case route.startsWith("/register"):
        pageElement = await CreateForm(flowId, "registration");
        break;
      case route.startsWith("/verify"):
        pageElement = await CreateForm(flowId, "verification");
        break;
      case route.startsWith("/recovery"):
        pageElement = await CreateForm(flowId, "recovery");
        break;
      case route.startsWith("/settings"):
        pageElement = await CreateForm(flowId, "settings");
        break;
      default:
        pageElement = document.createElement("h1");
        pageElement.textContent = `Default Implementation for Page ${route}`;
    }
    if (pageElement) {
      var app = document.getElementById("app");

      app.innerHTML = "";
      app.appendChild(pageElement);
    }

    window.scrollX = 0;
  },
};

export default Router;

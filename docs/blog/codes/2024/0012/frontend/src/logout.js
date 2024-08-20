import { initFlow } from "./utils.js";

async function createForm() {
  var flowInfo;

  var extraHeaders = {
    accept: "application/json",
  };

  flowInfo = await initFlow("logout", extraHeaders);

  var flowJson = await flowInfo.json();

  await fetch(flowJson.logout_url, { credentials: "include" });

  window.location.href = "/login";
}

export default createForm;

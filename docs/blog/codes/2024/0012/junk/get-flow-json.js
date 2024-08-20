import { initFlow } from "./utils.js";


async function createForm(flowName) {
  var flowInfo, flowJson;

  var headers = {
    accept: "application/json",
  };

  flowInfo = await initFlow(flowName, headers);
  flowJson = await flowInfo.json();

  // build the HTML form from the json and return it

  return "TODO";
}

export default createForm;

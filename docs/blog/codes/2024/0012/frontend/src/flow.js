import { initFlow, getFlowInfo, createFlowForm } from "./utils.js";


async function createForm(flowId, flowName) {
  var flowInfo, flowJson;

  var headers = {
    accept: "application/json",
  };

  if (flowId) {
    flowInfo = await getFlowInfo(flowId);
  } else {
    flowInfo = await initFlow(flowName, headers);
  }

  flowJson = await flowInfo.json();

  var form = createFlowForm(flowJson);

  return form;
}

export default createForm;

import { kratosHost } from "./config.js";

var fetchOptions = {
  credentials: "include",
};

export async function initFlow(flow, extraHeaders = {}) {
  return await fetch(`${kratosHost}/self-service/${flow}/browser`, {
    ...fetchOptions,
    headers: {
      ...extraHeaders,
    },
  });
}

export function createFlowForm(flowJson, submitLabel = "Submit") {
  var form = document.createElement("form");

  form.action = flowJson.ui.action;
  form.method = flowJson.ui.method;

  var autofocus = false;

  var passwordField, passwordLabel;

  flowJson.ui.nodes.forEach(function parseNode(node) {
    if (node.type == "input") {
      var attr = node.attributes;
      var isSubmit = attr.type == "submit";
      var isPassword = attr.type == "password";
      var input = document.createElement("input");
      var label = document.createElement("label");

      if (isSubmit) {
        input = document.createElement("button");
      }

      if (node.meta && node.meta.label && node.meta.label.text) {
        label.innerText = node.meta.label.text;
      }
      input.type = attr.type;
      input.name = attr.name;
      input.value = attr.value || "";

      if (isSubmit) {
        input.classList.add("button");
        var span = document.createElement("span");
        span.innerText = submitLabel;
        input.appendChild(span);
      }
      if (attr.required) {
        input.required = true;
        if (attr.type != "hidden") {
          var required = document.createElement("span");
          required.innerText = " *";
          required.className = "required";
          label.appendChild(required);
        }
      }
      if (attr.disabled) {
        input.disabled = true;
      }
      if (!isSubmit && !isPassword) {
        form.appendChild(label);
      }

      if (!autofocus && input.type != "hidden") {
        input.autofocus = true;
        autofocus = true;
      }

      if (!isPassword) {
        form.appendChild(input);
      } else {
        passwordField = input;
        passwordLabel = label;
      }
    }
  });

  if (passwordField) {
    form[form.length - 1].insertAdjacentElement("beforebegin", passwordLabel);
    form[form.length - 1].insertAdjacentElement("beforebegin", passwordField);
  }

  return form;
}

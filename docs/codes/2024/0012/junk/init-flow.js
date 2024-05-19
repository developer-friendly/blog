import { kratosHost } from "./config.js";

var fetchOptions = {
  credentials: "include",
};


export async function initFlow(flow, extraHeaders = {}) {
  return await fetch(
    `${kratosHost}/self-service/${flow}/browser`,
    {
      ...fetchOptions,
      headers: {
        ...extraHeaders,
      },
    }
  );
}

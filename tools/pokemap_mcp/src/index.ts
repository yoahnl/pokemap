import { serveStdio } from "@modelcontextprotocol/server/stdio";

import { createCompatibilityServer } from "./compatibility_server.js";

const handle = serveStdio(createCompatibilityServer, {
  legacy: "serve",
  onerror: (error) => {
    console.error(`[pokemap-mcp] ${error.message}`);
  },
});

let closing = false;

async function close(): Promise<void> {
  if (closing) {
    return;
  }
  closing = true;
  await handle.close();
}

process.once("SIGINT", () => {
  void close();
});
process.once("SIGTERM", () => {
  void close();
});

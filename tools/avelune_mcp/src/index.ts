import { serveStdio } from "@modelcontextprotocol/server/stdio";

import { HttpAveluneApiClient } from "./api_client.js";
import { parseConfig, AveluneMcpConfigError } from "./config.js";
import { AveluneController } from "./controller.js";
import { createAveluneMcpServer } from "./server.js";
import { readControlSession } from "./session.js";

try {
  start(parseConfig(process.argv.slice(2)));
} catch (error) {
  const message =
    error instanceof AveluneMcpConfigError
      ? error.message
      : "Unable to initialize Avelune MCP configuration.";
  console.error(`[avelune-mcp] ${message}`);
  process.exitCode = 64;
}

function start(config: ReturnType<typeof parseConfig>): void {
  const readSession = () => readControlSession(config.sessionFile);
  const controller = new AveluneController({
    api: new HttpAveluneApiClient(readSession),
    allowedRoots: config.allowedRoots,
  });
  const handle = serveStdio(() => createAveluneMcpServer(controller), {
    legacy: "serve",
    onerror: (error) => console.error(`[avelune-mcp] ${error.message}`),
  });
  let closing = false;
  async function close(): Promise<void> {
    if (closing) return;
    closing = true;
    await handle.close();
  }
  process.once("SIGINT", () => void close());
  process.once("SIGTERM", () => void close());
  process.stdin.once("end", () => void close());
}

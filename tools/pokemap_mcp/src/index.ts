import { serveStdio } from "@modelcontextprotocol/server/stdio";

import { LocalAuthoringClient } from "./authoring_client.js";
import { MemoryArtifactReader } from "./artifacts.js";
import {
  parseConfig,
  PokeMapMcpConfigError,
  type PokeMapMcpConfig,
} from "./config.js";
import { createPokeMapMcpServer } from "./server.js";

try {
  start(parseConfig(process.argv.slice(2)));
} catch (error) {
  const message =
    error instanceof PokeMapMcpConfigError
      ? error.message
      : "Unable to initialize PokeMap MCP configuration.";
  console.error(`[pokemap-mcp] ${message}`);
  process.exitCode = 64;
}

function start(config: PokeMapMcpConfig): void {
  const authoring = new LocalAuthoringClient({
    allowedRoots: config.allowedRoots,
    authoringPackageRoot: config.authoringPackageRoot,
    dartExecutable: config.dartExecutable,
  });
  const artifacts = new MemoryArtifactReader();
  const handle = serveStdio(
    () => createPokeMapMcpServer({ authoring, artifacts }),
    {
      legacy: "serve",
      onerror: (error) => {
        console.error(`[pokemap-mcp] ${error.message}`);
      },
    },
  );

  let closing = false;
  async function close(): Promise<void> {
    if (closing) {
      return;
    }
    closing = true;
    await handle.close();
    await authoring.close();
  }

  process.once("SIGINT", () => {
    void close();
  });
  process.once("SIGTERM", () => {
    void close();
  });
  process.stdin.once("end", () => {
    void close();
  });
}

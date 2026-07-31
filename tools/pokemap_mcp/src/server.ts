import { McpServer } from "@modelcontextprotocol/server";

import type { AuthoringGateway } from "./authoring_client.js";
import type { ArtifactReader } from "./artifacts.js";
import {
  MCP_SERVER_NAME,
  MCP_SERVER_VERSION,
  SUPPORTED_PROTOCOL_VERSIONS,
} from "./protocol.js";
import { registerReadOnlyResources } from "./resources/read_only.js";
import { registerReadOnlyTools } from "./tools/read_only.js";

export interface PokeMapMcpServerDependencies {
  authoring: AuthoringGateway;
  artifacts: ArtifactReader;
}

export function createPokeMapMcpServer(
  dependencies: PokeMapMcpServerDependencies,
): McpServer {
  const server = new McpServer(
    { name: MCP_SERVER_NAME, version: MCP_SERVER_VERSION },
    {
      supportedProtocolVersions: [...SUPPORTED_PROTOCOL_VERSIONS],
      instructions:
        "This PokeMap server is read-only. Open only configured roots, keep opaque handles, follow nextCursor, and never invent resource URIs.",
    },
  );
  registerReadOnlyTools(server, dependencies.authoring, dependencies.artifacts);
  registerReadOnlyResources(server, dependencies.authoring);
  return server;
}

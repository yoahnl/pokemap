import { McpServer } from "@modelcontextprotocol/server";

import type { AuthoringGateway } from "./authoring_client.js";
import type { ArtifactReader } from "./artifacts.js";
import type { RuntimeGateway } from "./runtime_gateway.js";
import {
  MCP_SERVER_NAME,
  MCP_SERVER_VERSION,
  SUPPORTED_PROTOCOL_VERSIONS,
} from "./protocol.js";
import { registerReadOnlyResources } from "./resources/read_only.js";
import { registerReadOnlyTools } from "./tools/read_only.js";
import { registerMutationTools } from "./tools/mutations.js";
import { registerRuntimeTools } from "./tools/runtime.js";

export interface PokeMapMcpServerDependencies {
  authoring: AuthoringGateway;
  artifacts: ArtifactReader;
  runtime?: RuntimeGateway;
}

export function createPokeMapMcpServer(
  dependencies: PokeMapMcpServerDependencies,
): McpServer {
  const server = new McpServer(
    { name: MCP_SERVER_NAME, version: MCP_SERVER_VERSION },
    {
      supportedProtocolVersions: [...SUPPORTED_PROTOCOL_VERSIONS],
      instructions:
        "Open only configured roots, plan before apply, keep opaque handles, use exact confirmations, follow nextCursor, and never invent artifact or resource URIs.",
    },
  );
  registerReadOnlyTools(server, dependencies.authoring, dependencies.artifacts);
  registerMutationTools(server, dependencies.authoring);
  if (dependencies.runtime) {
    registerRuntimeTools(server, dependencies.runtime);
  }
  registerReadOnlyResources(server, dependencies.authoring);
  return server;
}

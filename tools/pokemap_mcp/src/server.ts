import { McpServer } from "@modelcontextprotocol/server";

import type {
  AuthoringGateway,
  ProjectRootResolver,
} from "./authoring_client.js";
import type { ArtifactReader } from "./artifacts.js";
import type { RuntimeGateway } from "./runtime_gateway.js";
import {
  MCP_SERVER_NAME,
  MCP_SERVER_VERSION,
  SUPPORTED_PROTOCOL_VERSIONS,
} from "./protocol.js";
import {
  guardArtifactReader,
  guardAuthoringGateway,
  guardRuntimeGateway,
  PokeMapRequestGuard,
} from "./request_guard.js";
import { registerReadOnlyResources } from "./resources/read_only.js";
import { registerReadOnlyTools } from "./tools/read_only.js";
import { registerMutationTools } from "./tools/mutations.js";
import { registerGameExportTool } from "./tools/game_export.js";
import { registerRuntimeTools } from "./tools/runtime.js";

export interface PokeMapMcpServerDependencies {
  authoring: AuthoringGateway;
  artifacts: ArtifactReader;
  projectRoots?: ProjectRootResolver;
  runtime?: RuntimeGateway;
  guard?: PokeMapRequestGuard;
}

export function createPokeMapMcpServer(
  dependencies: PokeMapMcpServerDependencies,
): McpServer {
  const guard = dependencies.guard ?? new PokeMapRequestGuard();
  const authoring = guardAuthoringGateway(dependencies.authoring, guard);
  const artifacts = guardArtifactReader(dependencies.artifacts, guard);
  const runtime = dependencies.runtime
    ? guardRuntimeGateway(dependencies.runtime, guard)
    : undefined;
  const server = new McpServer(
    { name: MCP_SERVER_NAME, version: MCP_SERVER_VERSION },
    {
      supportedProtocolVersions: [...SUPPORTED_PROTOCOL_VERSIONS],
      instructions:
        "Open only configured roots, plan before apply, keep opaque handles, use exact confirmations, follow nextCursor, and never invent artifact or resource URIs.",
    },
  );
  registerReadOnlyTools(server, authoring, artifacts);
  registerMutationTools(server, authoring);
  registerGameExportTool(server, authoring, dependencies.projectRoots);
  if (runtime) {
    registerRuntimeTools(server, runtime);
  }
  registerReadOnlyResources(server, authoring);
  return server;
}

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
import { registerProjectCreationTools } from "./tools/project_creation.js";
import { registerNativeProjectCreationTools } from "./tools/native_project_creation.js";
import { registerResourcePackTool } from "./tools/resource_packs.js";
import { registerProjectionTool } from "./tools/projections.js";
import { registerRuntimeTools } from "./tools/runtime.js";
import { registerMapEditorTools } from "./tools/map_editor.js";
import { registerVisualSettingsTools } from "./tools/visual_settings.js";
import { registerMapAtmosphereTools } from "./tools/map_atmosphere.js";
import { registerMapExteriorDecorationTools } from "./tools/map_exterior_decoration.js";
import { registerCharacterContactShadowTools } from "./tools/character_contact_shadows.js";
import { registerMapCheckTool } from "./tools/map_check.js";
import { registerMapEditTool } from "./tools/map_edit.js";

export interface PokeMapMcpServerDependencies {
  protocolVersions?: readonly string[];
  profile?: "full" | "map-builder";
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
      supportedProtocolVersions: [...dependencies.protocolVersions??SUPPORTED_PROTOCOL_VERSIONS],
      instructions:
        "Open only configured roots, plan before apply, keep opaque handles, use exact confirmations, follow nextCursor, and never invent artifact or resource URIs.",
    },
  );
  const compact = dependencies.profile === "map-builder";
  registerReadOnlyTools(server, authoring, artifacts, compact);
  registerMutationTools(server, authoring, compact);
  registerMapCheckTool(server, authoring, runtime);
  registerMapEditTool(server, authoring);
  if (!compact) {
  registerCharacterContactShadowTools(server, authoring);
  registerMapAtmosphereTools(server, authoring);
  registerMapExteriorDecorationTools(server, authoring);
  registerVisualSettingsTools(server, authoring);
  registerMapEditorTools(server, authoring);
  registerGameExportTool(server, authoring, dependencies.projectRoots);
  registerProjectCreationTools(server, authoring);
  registerNativeProjectCreationTools(server, authoring);
  registerResourcePackTool(server, authoring);
  registerProjectionTool(server, authoring);
  }
  if (runtime) {
    registerRuntimeTools(server, runtime, compact);
  }
  registerReadOnlyResources(server, authoring);
  return server;
}

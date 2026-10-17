import {
  type McpServer,
  ResourceTemplate,
  type Variables,
} from "@modelcontextprotocol/server";

import type { AuthoringGateway, JsonRecord } from "../authoring_client.js";

export function registerReadOnlyResources(
  server: McpServer,
  authoring: AuthoringGateway,
): void {
  server.registerResource(
    "pokemap-resource-pack",
    new ResourceTemplate("pokemap://project/{projectHandle}/resource-pack/{resourceKind}/{handle}", { list: undefined }),
    projectMetadata("Avelune resource pack", "Opaque bounded session-owned pack state."),
    async (uri, variables) => {
      const kind = variable(variables, "resourceKind");
      if (!["resourcePackJob", "resourcePackInspection", "resourcePackEntry",
        "resourcePackSelection", "resourcePackPreview"].includes(kind)) {
        throw new Error("Unsupported temporary pack resource kind.");
      }
      const result = await authoring.request("query", {
        projectHandle: variable(variables, "projectHandle"),
        request: query(kind, "get", [variable(variables, "handle")]),
      });
      const response = jsonResource(uri, result.data);
      if (Buffer.byteLength(JSON.stringify({ jsonrpc: "2.0", id: "x".repeat(128), result: response }), "utf8") > 256 * 1024) {
        throw new Error("The pack resource exceeds its bounded response budget.");
      }
      return response;
    },
  );

  server.registerResource(
    "pokemap-project",
    new ResourceTemplate("pokemap://project/{projectHandle}", {
      list: undefined,
    }),
    projectMetadata("PokeMap project", "Detailed immutable project snapshot."),
    async (uri, variables) =>
      queryResource(uri, authoring, {
        projectHandle: variable(variables, "projectHandle"),
        request: query("project", "get", ["project"]),
      }),
  );

  server.registerResource(
    "pokemap-catalog",
    new ResourceTemplate(
      "pokemap://project/{projectHandle}/catalog/{resourceKind}",
      { list: undefined },
    ),
    projectMetadata(
      "PokeMap catalog",
      "A bounded first page of one canonical project resource catalog.",
    ),
    async (uri, variables) =>
      queryResource(uri, authoring, {
        projectHandle: variable(variables, "projectHandle"),
        request: query(variable(variables, "resourceKind"), "list"),
      }),
  );

  server.registerResource(
    "pokemap-diagnostics",
    new ResourceTemplate(
      "pokemap://project/{projectHandle}/diagnostics",
      { list: undefined },
    ),
    projectMetadata(
      "PokeMap diagnostics",
      "Structural, reference, and optional capability certification results for one snapshot.",
    ),
    async (uri, variables) => {
      const result = await authoring.request("validate", {
        projectHandle: variable(variables, "projectHandle"),
      });
      return jsonResource(uri, result.data);
    },
  );

  server.registerResource(
    "pokemap-map",
    new ResourceTemplate(
      "pokemap://project/{projectHandle}/map/{mapId}",
      { list: undefined },
    ),
    projectMetadata("PokeMap map", "Detailed immutable map snapshot."),
    async (uri, variables) =>
      queryResource(uri, authoring, {
        projectHandle: variable(variables, "projectHandle"),
        request: query(
          "map",
          "get",
          [variable(variables, "mapId")],
          "summary",
        ),
      }),
  );
}

function projectMetadata(title: string, description: string) {
  return {
    title,
    description,
    mimeType: "application/json",
  };
}

function query(
  resourceKind: string,
  operation: "list" | "get",
  ids: string[] = [],
  view: "summary" | "detail" = "detail",
): JsonRecord {
  return {
    resourceKind,
    operation,
    view,
    ids,
    fieldMask: [],
    filters: {},
    sort: [],
    pageSize: 200,
  };
}

async function queryResource(
  uri: URL,
  authoring: AuthoringGateway,
  args: JsonRecord,
) {
  const result = await authoring.request("query", args);
  return jsonResource(uri, result.data);
}

function jsonResource(uri: URL, data: JsonRecord) {
  return {
    contents: [
      {
        uri: uri.href,
        mimeType: "application/json",
        text: JSON.stringify(data),
      },
    ],
  };
}

function variable(variables: Variables, name: string): string {
  const value = variables[name];
  if (typeof value !== "string" || value.length === 0) {
    throw new Error(`Missing resource variable: ${name}`);
  }
  return value;
}

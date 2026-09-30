import { isAbsolute } from "node:path";

import type { McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";

import type { AuthoringGateway } from "../authoring_client.js";
import { authoringResult, toolEnvelopeSchema } from "./result.js";

const requestSchema = z.object({
  name: z.string().min(1),
  folderName: z.string().min(1),
  parentPath: z.string().min(1).refine(isAbsolute, "parentPath must be absolute"),
  template: z.enum(["empty", "playable"]).optional(),
  tileSize: z.union([z.literal(16), z.literal(32), z.literal(48)]).optional(),
  mapWidth: z.number().int().min(3).max(256).optional(),
  mapHeight: z.number().int().min(3).max(256).optional(),
}).strict();

export function registerProjectCreationTools(
  server: McpServer,
  authoring: AuthoringGateway,
): void {
  server.registerTool("pokemap_project_create_preview", {
    title: "Preview a new Avelune project",
    description: "Preview a new empty or playable project under a configured parent root. Writes nothing; returns an opaque confirmation bound to this exact request and destination.",
    inputSchema: z.object({ request: requestSchema }).strict(),
    outputSchema: toolEnvelopeSchema,
    annotations: {
      readOnlyHint: true,
      destructiveHint: false,
      idempotentHint: false,
      openWorldHint: false,
    },
  }, async ({ request }) => authoringResult(() =>
    authoring.request("project_create_preview", { request })));

  server.registerTool("pokemap_project_create", {
    title: "Create the previewed Avelune project",
    description: "Create the exact confirmed new project. Refuses existing destinations; uses journaled promotion, not atomic multi-file visibility. Bootstrap cannot be undone. A timeout requires inspection before retrying.",
    inputSchema: z.object({
      request: requestSchema,
      confirmation: z.string().min(8).max(256),
    }).strict(),
    outputSchema: toolEnvelopeSchema,
    annotations: {
      readOnlyHint: false,
      destructiveHint: false,
      idempotentHint: false,
      openWorldHint: false,
    },
  }, async ({ request, confirmation }) => authoringResult(() =>
    authoring.request("project_create", { request, confirmation })));
}

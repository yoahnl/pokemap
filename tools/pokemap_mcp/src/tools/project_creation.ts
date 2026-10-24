import { isAbsolute } from "node:path";

import type { McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";

import type { AuthoringGateway } from "../authoring_client.js";
import { authoringResult, toolEnvelopeSchema } from "./result.js";

const requestSchema = z.object({
  name: z.string().min(1),
  folderName: z.string().min(1),
  parentPath: z.string().min(1).refine(isAbsolute, "parentPath must be absolute"),
  template: z.enum(["empty", "playable", "catalogue"]).optional(),
  templateId: z.string().min(1).optional(),
  dimension: z.enum(["twoD", "threeD"]).optional(),
  spatialCamera: z.object({
    mode: z.literal("fixed"),
    pitchDegrees: z.number().finite().gt(0).lt(90),
    yawDegrees: z.number().finite(),
    fieldOfViewDegrees: z.number().finite().gt(1).lt(120),
    projection: z.enum(["perspective", "orthographic"]).optional(),
    orthographicHeight: z.number().finite().gt(0).lte(10000).optional(),
    distance: z.number().finite().gt(0).max(10000),
  }).strict().optional(),
  tileSize: z.union([z.literal(16), z.literal(32), z.literal(48)]).optional(),
  mapWidth: z.number().int().min(3).max(256).optional(),
  mapHeight: z.number().int().min(3).max(256).optional(),
  mapInstanceRetentionPolicy: z.object({
    schemaVersion: z.literal(1),
    viewportWidthTiles: z.number().int().min(1).max(2147483647),
    viewportHeightTiles: z.number().int().min(1).max(2147483647),
    marginTiles: z.number().int().min(0).max(2147483647),
    clampViewportToMapIds: z.array(z.string().min(1).refine((value) => value.trim() === value))
      .refine((values) => new Set(values).size === values.length),
  }).strict().optional(),
}).strict();

export function registerProjectCreationTools(
  server: McpServer,
  authoring: AuthoringGateway,
): void {
  server.registerTool("pokemap_project_templates", {
    title: "List verified project templates",
    description: "List the explicitly configured project template catalogue, including immutable source revisions, checksums and geometry. Does not download or create a project.",
    inputSchema: z.object({}).strict(),
    outputSchema: toolEnvelopeSchema,
    annotations: {
      readOnlyHint: true,
      destructiveHint: false,
      idempotentHint: true,
      openWorldHint: false,
    },
  }, async () => authoringResult(() => authoring.request("project_templates", {})));

  server.registerTool("pokemap_project_create_preview", {
    title: "Preview a new Avelune project",
    description: "Preview a new exclusively 2D or 3D project under a configured parent root. 3D uses the empty template with an initial spatial map and fixed camera; 2D also supports playable or an explicitly selected catalogue templateId. Writes nothing; returns confirmation bound to the exact request, source descriptor and destination.",
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
      openWorldHint: true,
    },
  }, async ({ request, confirmation }) => authoringResult(() =>
    authoring.request("project_create", { request, confirmation })));
}

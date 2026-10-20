import { isAbsolute } from "node:path";

import type { McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";

import type { AuthoringGateway } from "../authoring_client.js";
import { authoringResult, toolEnvelopeSchema } from "./result.js";

const handle = z.string().min(8).max(256);
const fingerprint = z.string().min(8).max(256);
const source = z.object({
  descriptorPath: z.string().min(1).refine(isAbsolute, "descriptorPath must be absolute"),
  sha256: z.string().regex(/^[0-9a-f]{64}$/),
  byteLength: z.number().int().min(1).max(500 * 1024 * 1024),
}).strict();

export function registerNativeProjectCreationTools(
  server: McpServer,
  authoring: AuthoringGateway,
): void {
  server.registerTool("pokemap_project_native_prepare", {
    title: "Prepare an attested native project",
    description: "Read a typed native descriptor and exact witnessed blobs under configured roots, validate the complete native project and return a sealed session handle. No destination is written. Handles cannot be restored across worker processes; prepare again from the same attested source.",
    inputSchema: z.object({ source }).strict(),
    outputSchema: toolEnvelopeSchema,
    annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: false, openWorldHint: false },
  }, async (args) => authoringResult(() => authoring.request("project_native_prepare", args)));
  server.registerTool("pokemap_project_native_plan", {
    title: "Plan the prepared native project destination",
    description: "Recheck all source witnesses and plan an exclusively new destination under configured roots. Returns the exact inventory fingerprint and an opaque plan; writes nothing.",
    inputSchema: z.object({
      preparedHandle: handle,
      expectedInventoryFingerprint: fingerprint,
      parentPath: z.string().min(1).refine(isAbsolute, "parentPath must be absolute"),
      folderName: z.string().min(1).max(128),
    }).strict(),
    outputSchema: toolEnvelopeSchema,
    annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: false, openWorldHint: false },
  }, async (args) => authoringResult(() => authoring.request("project_native_plan", args)));
  server.registerTool("pokemap_project_native_publish", {
    title: "Publish the exact prepared native project",
    description: "Recheck source witnesses before first publication and publish the exact sealed plan through canonical native creation. Replaying the same plan verifies the completed output inventory and returns the same canonical receipt without rewriting. Refuses changed inputs before publication and changed completed outputs. Failures retain any reserved destination for inspection; retry only the identical sealed plan after a timeout.",
    inputSchema: z.object({ planHandle: handle, expectedInventoryFingerprint: fingerprint }).strict(),
    outputSchema: toolEnvelopeSchema,
    annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false },
  }, async (args) => authoringResult(() => authoring.request("project_native_publish", args)));
  server.registerTool("pokemap_project_native_release", {
    title: "Release a native creation session handle",
    description: "Release a prepared project and its plans from this worker session without touching source or published project files.",
    inputSchema: z.object({ preparedHandle: handle }).strict(),
    outputSchema: toolEnvelopeSchema,
    annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false },
  }, async (args) => authoringResult(() => authoring.request("project_native_release", args)));
}

import type { McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";

import type { AuthoringGateway, AuthoringWorkerSuccess } from "../authoring_client.js";
import { PokeMapToolError } from "../tool_error.js";
import { failureEnvelope, mutationAnnotations, successEnvelope, toolEnvelopeSchema } from "./result.js";

const handle = z.string().min(1).max(128);
const revision = z.string().regex(/^sha256:[0-9a-f]{64}$/);
const filter = z.object({
  kind: z.enum(["tileset", "element", "model3d", "character", "environmentPreset",
    "smartTilePreset", "smartTilePattern", "borderBlueprint"]).optional(),
  search: z.string().min(1).max(256).optional(),
  selected: z.boolean().optional(),
  context: z.enum(["all", "interior", "exterior", "both", "unspecified"]).optional(),
  familyId: z.string().min(1).max(512).optional(),
}).strict();
const ref = z.object({
  kind: z.enum(["tileset", "element", "model3d", "character", "environmentPreset",
    "smartTilePreset", "smartTilePattern", "borderBlueprint"]),
  id: z.string().min(1).max(512),
}).strict();
const selection = { selectionHandle: handle, revision };
const page = { cursor: handle.optional(), limit: z.number().int().min(1).max(200).optional() };
const metadata = z.object({
  id: z.string().min(1).max(256), version: z.string().min(1).max(128),
  name: z.string().min(1).max(256), description: z.string().max(4096),
  universeId: z.string().min(1).max(256),
  authors: z.array(z.string().min(1).max(128)).min(1).max(200),
  provenance: z.string().min(1).max(4096),
}).strict();
export const resourcePackToolSchema = z.discriminatedUnion("verb", [
  z.object({ projectHandle: handle, verb: z.literal("stage"), input: z.object({ sourcePath: z.string().min(1).max(4096) }).strict() }).strict(),
  z.object({ projectHandle: handle, verb: z.literal("stage_license"), input: z.object({ sourcePath: z.string().min(1).max(4096) }).strict() }).strict(),
  z.object({ projectHandle: handle, verb: z.literal("inspect"), input: z.object({ archiveHandle: handle }).strict() }).strict(),
  z.object({ projectHandle: handle, verb: z.literal("diagnose"), input: z.union([
    z.object({ expectedRevision: revision }).strict(),
    z.object({ expectedRevision: revision, ...selection }).strict(),
  ]) }).strict(),
  z.object({ projectHandle: handle, verb: z.literal("entries"), input: z.object({
    inspectionHandle: handle.optional(), selectionHandle: handle.optional(), section: z.enum(["resources", "families", "authors", "sources"]).optional(), filter: filter.optional(), ...page,
  }).strict().refine((value) => Boolean(value.inspectionHandle) !== Boolean(value.selectionHandle), "Choose one scoped owner.") }).strict(),
  z.object({ projectHandle: handle, verb: z.literal("selection.create"), input: z.discriminatedUnion("mode", [
    z.object({ mode: z.literal("archive"), inspectionHandle: handle }).strict(),
    z.object({ mode: z.literal("native") }).strict(),
  ]) }).strict(),
  z.object({ projectHandle: handle, verb: z.literal("selection.patch"), input: z.object({
    ...selection, add: z.array(ref).max(200).optional(), remove: z.array(ref).max(200).optional(),
  }).strict().refine((value) => (value.add?.length ?? 0) + (value.remove?.length ?? 0) <= 200) }).strict(),
  z.object({ projectHandle: handle, verb: z.literal("selection.select_filtered"), input: z.object({ ...selection, filter }).strict() }).strict(),
  z.object({ projectHandle: handle, verb: z.literal("prepare"), input: z.union([
    z.object({ ...selection, expectedRevision: revision, conflictPolicy: z.enum(["preserveProject", "importCopy"]).optional() }).strict(),
    z.object({ ...selection, expectedRevision: revision, metadata, author: z.string().min(1).max(128), sourceUrl: z.string().max(4096).optional(), licenseHandles: z.array(handle).max(200).optional() }).strict(),
  ]) }).strict(),
  z.object({ projectHandle: handle, verb: z.literal("preview"), input: z.object({ previewHandle: handle, ...page }).strict() }).strict(),
  z.object({ projectHandle: handle, verb: z.literal("start_apply"), input: z.object({
    planId: handle, operationId: handle, confirmationToken: z.string().min(1).max(4096).optional(),
  }).strict() }).strict(),
  z.object({ projectHandle: handle, verb: z.literal("start_history"), input: z.object({
    operation: z.enum(["undo", "redo", "revert"]), entryId: handle, operationId: handle,
    expectedRevision: revision, expectedHeadEntryId: handle.optional(),
  }).strict() }).strict(),
  z.object({ projectHandle: handle, verb: z.literal("start_recovery"), input: z.object({ operationId: handle }).strict() }).strict(),
  z.object({ projectHandle: handle, verb: z.literal("recovery_status"), input: z.object({}).strict() }).strict(),
  z.object({ projectHandle: handle, verb: z.literal("export"), input: z.object({ preparedExportHandle: handle, acknowledgeOrganizationRemoval: z.boolean().optional() }).strict() }).strict(),
  z.object({ projectHandle: handle, verb: z.literal("get"), input: z.object({ jobId: handle }).strict() }).strict(),
  z.object({ projectHandle: handle, verb: z.literal("events"), input: z.object({
    jobId: handle, afterSequence: z.number().int().min(0).optional(), cursor: handle.optional(),
  }).strict() }).strict(),
  z.object({ projectHandle: handle, verb: z.literal("read_payload"), input: z.object({
    payloadRef: handle, offset: z.number().int().min(0), length: z.number().int().min(1).max(128 * 1024),
  }).strict() }).strict(),
  z.object({ projectHandle: handle, verb: z.literal("cancel"), input: z.object({ jobId: handle }).strict() }).strict(),
  z.object({ projectHandle: handle, verb: z.literal("release"), input: z.object({ handle }).strict() }).strict(),
]);

export function registerResourcePackTool(server: McpServer, authoring: AuthoringGateway): void {
  server.registerTool("pokemap_resource_pack", {
    title: "Transfer native Avelune resource packs",
    description: "Runs bounded session-owned pack jobs. Diagnose saved project and optional selection volumes without staging media or preparing a mutation. Stage only from configured source roots; inspect, select, prepare, then plan resource_pack.import before start_apply. Stage UTF-8 licences, prepare a native selection, then inspect its prepared preview and export only its immutable preparedExportHandle. Native entry sections describe the captured project inventory; preview credits describe only reached origins/documents. Acknowledge organization removal only on export when the preparation requires it.",
    inputSchema: resourcePackToolSchema,
    outputSchema: toolEnvelopeSchema,
    annotations: mutationAnnotations,
  }, async ({ projectHandle, verb, input }) =>
    resourcePackResult(() => authoring.request("resource_pack", { projectHandle, verb, input })));
}

export async function resourcePackResult(operation: () => Promise<AuthoringWorkerSuccess>) {
  try {
    const result = await operation();
    const response = {
      content: [{ type: "text" as const, text: "Scoped resource pack response." }],
      structuredContent: successEnvelope(result.data, result.artifacts),
    };
    if (Buffer.byteLength(JSON.stringify({ jsonrpc: "2.0", id: "x".repeat(128), result: response }), "utf8") > 256 * 1024) {
      throw new PokeMapToolError("resource_limit", "The resource pack envelope exceeds its bounded response budget.");
    }
    return response;
  } catch (error) {
    return failureEnvelope(error);
  }
}

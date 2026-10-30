import type { McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";
import type { AuthoringGateway } from "../authoring_client.js";
import { authoringResult, mutationAnnotations, toolEnvelopeSchema } from "./result.js";

const policy = z.enum(["refuse", "report"]);

export const mapEditSchema = z.object({
  projectHandle: z.string().min(1),
  operationId: z.string().regex(/^[A-Za-z0-9][A-Za-z0-9._-]{0,119}$/),
  mapId: z.string().min(1),
  seed: z.number().int().min(0).max(2147483647).default(0),
  operations: z.array(z.object({
    actionId: z.string().min(1),
    actionVersion: z.number().int().positive(),
    parameters: z.record(z.string(), z.unknown()),
  }).strict()).min(1).max(64),
  guards: z.object({
    groundGaps: policy.optional(),
    borderObjectOverlaps: policy.optional(),
    staleBorders: z.enum(["rematerialize", "refuse", "report"]).optional(),
    newBorderErrors: policy.optional(),
    newBorderWarnings: policy.optional(),
  }).strict().default({}),
  dryRun: z.boolean().default(false),
}).strict();

export function registerMapEditTool(server: McpServer, authoring: AuthoringGateway): void {
  server.registerTool("pokemap_map_edit", {
    title: "Edit one map atomically",
    description: 'Projects 1–64 canonical map operations, checks final guards and persists one transaction. Create operationId before calling; retain it with identical content after a lost response. Use a new identity for a new intention, including after undo. dryRun reserves nothing. Defaults refuse new exposed gaps, worsening overlaps and errors; rematerialize affected Borders. Warnings remain reported. Discover operation schemas using pokemap_describe. Example: {"projectHandle":"<handle>","operationId":"paint-1","mapId":"field","operations":[{"actionId":"smart_tile.cell.paint","actionVersion":1,"parameters":{"layerId":"ground","materialId":"grass","cells":[{"x":2,"y":3}]}}],"dryRun":true}.',
    inputSchema: mapEditSchema,
    outputSchema: toolEnvelopeSchema,
    annotations: mutationAnnotations,
  }, async request => authoringResult(() => authoring.request("map_edit", request)));
}

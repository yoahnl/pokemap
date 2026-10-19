import type { McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";

import type { AuthoringGateway, JsonRecord } from "../authoring_client.js";
import { PokeMapToolError } from "../tool_error.js";
import { failureEnvelope, readOnlyAnnotations, successEnvelope, toolEnvelopeSchema } from "./result.js";

const handle = z.string().min(1).max(128);
export const projectionToolSchema = z.discriminatedUnion("operation", [
  z.object({
    operation: z.literal("receipt"),
    projectHandle: handle,
    receiptId: handle,
  }).strict(),
  z.object({
    operation: z.literal("diff"),
    projectHandle: handle,
    diffRef: handle,
    cursor: handle.optional(),
    limit: z.number().int().min(1).max(200).optional(),
  }).strict(),
  z.object({
    operation: z.literal("payload"),
    projectHandle: handle,
    payloadRef: handle,
    offset: z.number().int().min(0),
    byteLength: z.number().int().min(1).max(131072).optional(),
  }).strict(),
]);

export function registerProjectionTool(server: McpServer, authoring: AuthoringGateway): void {
  server.registerTool("pokemap_projection", {
    title: "Read immutable authoring result projections",
    description: "Read a committed receipt by receiptId, an ordered diff page by diffRef (limit 1..200, default 200), or a raw payload chunk by payloadRef (offset >= 0; byteLength 1..131072, default 131072). Requires an active project session and project.read permission. Follow nextCursor and nextOffset; expired plans remain readable while their projection session is active. After reopening, reload the receipt to obtain fresh session-owned references. Successful responses including the actual RPC identifier stay within 256 KiB. Identifiers consuming the success envelope budget are refused before reading.",
    inputSchema: projectionToolSchema,
    outputSchema: toolEnvelopeSchema,
    annotations: readOnlyAnnotations,
  }, async (input, ctx) => projectionResult(authoring, input, ctx.mcpReq.id));
}

async function projectionResult(authoring: AuthoringGateway, input: JsonRecord, id: string | number) {
  try {
    const emptyResponse = {
      content: [{ type: "text" as const, text: "Scoped authoring projection response." }],
      structuredContent: successEnvelope({}, []),
    };
    if (!projectionFits(emptyResponse, id)) {
      throw new PokeMapToolError("resource_limit", "The RPC identifier leaves no room for a projection success envelope.");
    }
    let args = input;
    while (true) {
      const result = await authoring.request("projection", args);
      const response = {
        ...emptyResponse,
        structuredContent: successEnvelope(result.data, result.artifacts),
      };
      if (projectionFits(response, id)) {
        return response;
      }
      const rows = result.data.entries;
      if (input.operation !== "diff" || !Array.isArray(rows) || rows.length <= 1 || rows.length > Number(args.limit ?? 200)) {
        throw new PokeMapToolError("resource_limit", "The projection envelope exceeds its bounded response budget.");
      }
      args = { ...input, limit: Math.floor(rows.length / 2) };
    }
  } catch (error) {
    return failureEnvelope(error);
  }
}

function projectionFits(response: unknown, id: string | number): boolean {
  return Buffer.byteLength(JSON.stringify({ jsonrpc: "2.0", id, result: response }), "utf8") + 1 <= 256 * 1024;
}

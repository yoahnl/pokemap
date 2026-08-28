import { z } from "zod";

import { AveluneMcpError } from "./controller.js";

const dataSchema = z.record(z.string(), z.unknown());
const errorSchema = z.object({
  code: z.string(),
  message: z.string(),
  retryable: z.boolean(),
  details: dataSchema,
});

export const toolEnvelopeSchema = z.object({
  ok: z.boolean(),
  data: dataSchema,
  error: errorSchema.optional(),
});

export const readOnlyAnnotations = {
  readOnlyHint: true,
  destructiveHint: false,
  idempotentHint: true,
  openWorldHint: false,
} as const;

export const controlAnnotations = {
  readOnlyHint: false,
  destructiveHint: false,
  idempotentHint: false,
  openWorldHint: false,
} as const;

export async function toolResult(
  operation: () => Promise<Record<string, unknown>>,
) {
  try {
    const data = await operation();
    return {
      content: [{ type: "text" as const, text: JSON.stringify(data) }],
      structuredContent: { ok: true, data },
    };
  } catch (error) {
    const failure =
      error instanceof AveluneMcpError
        ? {
            code: error.code,
            message: error.message,
            retryable: error.retryable,
            details: error.details,
          }
        : {
            code: "mcp.internal",
            message: "The Avelune MCP request failed unexpectedly.",
            retryable: false,
            details: {},
          };
    return {
      isError: true,
      content: [
        { type: "text" as const, text: `${failure.code}: ${failure.message}` },
      ],
      structuredContent: { ok: false, data: {}, error: failure },
    };
  }
}

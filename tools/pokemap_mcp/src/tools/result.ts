import { z } from "zod";

import {
  AuthoringClientError,
  type AuthoringWorkerSuccess,
  type JsonRecord,
} from "../authoring_client.js";
import { ArtifactReadError } from "../artifacts.js";
import { PokeMapToolError } from "../tool_error.js";

const jsonRecordSchema = z.record(z.string(), z.unknown());
const artifactReferenceSchema = z.record(z.string(), z.unknown());
const errorSchema = z.object({
  code: z.string(),
  domainCode: z.string().optional(),
  message: z.string(),
  retryable: z.boolean(),
  remediation: z.array(z.string()),
  details: jsonRecordSchema,
});

export const toolEnvelopeSchema = z.object({
  ok: z.boolean(),
  data: jsonRecordSchema,
  artifacts: z.array(artifactReferenceSchema),
  error: errorSchema.optional(),
});

export const readOnlyAnnotations = {
  readOnlyHint: true,
  destructiveHint: false,
  idempotentHint: true,
  openWorldHint: false,
} as const;

export const mutationAnnotations = {
  readOnlyHint: false,
  destructiveHint: true,
  idempotentHint: true,
  openWorldHint: false,
} as const;

export async function authoringResult(
  operation: () => Promise<AuthoringWorkerSuccess>,
) {
  try {
    const result = await operation();
    return operationSuccess(result.data, result.artifacts);
  } catch (error) {
    return failureEnvelope(error);
  }
}

export async function toolResult(
  operation: () => Promise<{ data: JsonRecord; artifacts?: JsonRecord[] }>,
) {
  try {
    const result = await operation();
    return operationSuccess(result.data, result.artifacts ?? []);
  } catch (error) {
    return failureEnvelope(error);
  }
}

export function successEnvelope(
  data: JsonRecord,
  artifacts: JsonRecord[],
): JsonRecord {
  return { ok: true, data, artifacts };
}

export function failureEnvelope(error: unknown) {
  const failure = normalizeError(error);
  return {
    isError: true,
    content: [
      {
        type: "text" as const,
        text: `${failure.code}: ${failure.message}`,
      },
    ],
    structuredContent: {
      ok: false,
      data: {},
      artifacts: [],
      error: failure,
    },
  };
}

function operationSuccess(data: JsonRecord, artifacts: JsonRecord[]) {
  return {
    content: [{ type: "text" as const, text: JSON.stringify(data) }],
    structuredContent: successEnvelope(data, artifacts),
  };
}

function normalizeError(error: unknown) {
  if (error instanceof AuthoringClientError) {
    return {
      code: error.code,
      ...(error.domainCode ? { domainCode: error.domainCode } : {}),
      message: error.message,
      retryable: error.retryable,
      remediation: [...error.remediation],
      details: error.details,
    };
  }
  if (error instanceof ArtifactReadError || error instanceof PokeMapToolError) {
    return {
      code: error.code,
      message: error.message,
      retryable:
        error instanceof PokeMapToolError ? error.retryable : false,
      remediation:
        error instanceof PokeMapToolError ? [...error.remediation] : [],
      details: error instanceof PokeMapToolError ? error.details : {},
    };
  }
  return {
    code: "mcp.internal",
    message: "The PokeMap MCP request failed unexpectedly.",
    retryable: false,
    remediation: [],
    details: {},
  };
}

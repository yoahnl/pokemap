import { type McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";

import {
  AuthoringClientError,
  type AuthoringGateway,
  type AuthoringWorkerSuccess,
  type JsonRecord,
} from "../authoring_client.js";
import {
  ArtifactReadError,
  type ArtifactReader,
  type ReadArtifact,
} from "../artifacts.js";

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
const toolEnvelopeSchema = z.object({
  ok: z.boolean(),
  data: jsonRecordSchema,
  artifacts: z.array(artifactReferenceSchema),
  error: errorSchema.optional(),
});

const readOnlyAnnotations = {
  readOnlyHint: true,
  destructiveHint: false,
  idempotentHint: true,
  openWorldHint: false,
} as const;

export function registerReadOnlyTools(
  server: McpServer,
  authoring: AuthoringGateway,
  artifacts: ArtifactReader,
): void {
  registerArtifactTool(server, artifacts);

  server.registerTool(
    "pokemap_describe",
    {
      title: "Describe PokeMap authoring",
      description:
        "Lists canonical resource kinds, query operations, action contracts, and validation capabilities.",
      inputSchema: z.object({}).strict(),
      outputSchema: toolEnvelopeSchema,
      annotations: readOnlyAnnotations,
    },
    async () => authoringResult(() => authoring.request("describe")),
  );

  server.registerTool(
    "pokemap_query",
    {
      title: "Query a PokeMap snapshot",
      description:
        "Runs a deterministic, cursor-aware query against an explicit project handle.",
      inputSchema: z
        .object({
          projectHandle: z.string().min(1),
          resourceKind: z.string().regex(/^[a-z][A-Za-z0-9_]*$/),
          operation: z.enum(["list", "get", "batch_get", "search", "summary"]),
          view: z.enum(["summary", "detail"]).default("summary"),
          ids: z.array(z.string().min(1)).default([]),
          searchTerm: z.string().min(1).optional(),
          fieldMask: z.array(z.string().min(1)).default([]),
          filters: jsonRecordSchema.default({}),
          sort: z
            .array(
              z
                .object({
                  field: z.string().min(1),
                  descending: z.boolean().default(false),
                })
                .strict(),
            )
            .default([]),
          pageSize: z.number().int().min(1).max(200).default(50),
          cursor: z.string().min(1).optional(),
          extensions: jsonRecordSchema.optional(),
        })
        .strict(),
      outputSchema: toolEnvelopeSchema,
      annotations: readOnlyAnnotations,
    },
    async ({ projectHandle, ...request }) =>
      authoringResult(() =>
        authoring.request("query", { projectHandle, request }),
      ),
  );

  server.registerTool(
    "pokemap_validate",
    {
      title: "Validate a PokeMap project",
      description:
        "Checks references and explicit capability truth on an immutable snapshot.",
      inputSchema: z
        .object({
          projectHandle: z.string().min(1),
          capabilityTruth: z
            .object({
              records: z.array(jsonRecordSchema),
              requiredCapabilityIds: z.array(z.string().min(1)),
            })
            .strict()
            .optional(),
        })
        .strict(),
      outputSchema: toolEnvelopeSchema,
      annotations: readOnlyAnnotations,
    },
    async ({ projectHandle, capabilityTruth }) =>
      authoringResult(() =>
        authoring.request("validate", {
          projectHandle,
          ...(capabilityTruth ? { capabilityTruth } : {}),
        }),
      ),
  );

  server.registerTool(
    "pokemap_workspace",
    {
      title: "Manage a read-only PokeMap workspace",
      description:
        "Opens an allowed project or closes an explicit opaque workspace handle. It never writes project files.",
      inputSchema: z.discriminatedUnion("operation", [
        z
          .object({
            operation: z.literal("open"),
            projectRoot: z.string().min(1),
          })
          .strict(),
        z
          .object({
            operation: z.literal("close"),
            workspaceHandle: z.string().min(1),
          })
          .strict(),
      ]),
      outputSchema: toolEnvelopeSchema,
      annotations: readOnlyAnnotations,
    },
    async (input) =>
      input.operation === "open"
        ? authoringResult(() =>
            authoring.request("open", { projectRoot: input.projectRoot }),
          )
        : authoringResult(() =>
            authoring.request("close", {
              workspaceHandle: input.workspaceHandle,
            }),
          ),
  );
}

function registerArtifactTool(
  server: McpServer,
  artifacts: ArtifactReader,
): void {
  server.registerTool(
    "pokemap_artifact",
    {
      title: "Read a PokeMap artifact",
      description:
        "Reads bytes already registered under an opaque artifact:// handle. Filesystem and arbitrary HTTPS reads are forbidden.",
      inputSchema: z
        .object({
          uri: z.string().regex(/^artifact:\/\//),
        })
        .strict(),
      outputSchema: toolEnvelopeSchema,
      annotations: readOnlyAnnotations,
    },
    async ({ uri }) => {
      try {
        const artifact = await artifacts.read(uri);
        const data = artifactData(artifact);
        return {
          content: [
            {
              type: "resource" as const,
              resource: artifact.text === undefined
                ? {
                    uri: artifact.uri,
                    mimeType: artifact.mediaType,
                    blob: artifact.blob ?? "",
                  }
                : {
                    uri: artifact.uri,
                    mimeType: artifact.mediaType,
                    text: artifact.text,
                  },
            },
          ],
          structuredContent: successEnvelope(data, []),
        };
      } catch (error) {
        return failureEnvelope(error);
      }
    },
  );
}

async function authoringResult(
  operation: () => Promise<AuthoringWorkerSuccess>,
) {
  try {
    const result = await operation();
    const structuredContent = successEnvelope(result.data, result.artifacts);
    return {
      content: [{ type: "text" as const, text: JSON.stringify(result.data) }],
      structuredContent,
    };
  } catch (error) {
    return failureEnvelope(error);
  }
}

function artifactData(artifact: ReadArtifact): JsonRecord {
  return {
    uri: artifact.uri,
    mediaType: artifact.mediaType,
    ...(artifact.text === undefined ? {} : { text: artifact.text }),
    ...(artifact.blob === undefined ? {} : { blob: artifact.blob }),
  };
}

function successEnvelope(
  data: JsonRecord,
  artifacts: JsonRecord[],
): JsonRecord {
  return { ok: true, data, artifacts };
}

function failureEnvelope(error: unknown) {
  const failure = normalizeError(error);
  const structuredContent = {
    ok: false,
    data: {},
    artifacts: [],
    error: failure,
  };
  return {
    isError: true,
    content: [
      {
        type: "text" as const,
        text: `${failure.code}: ${failure.message}`,
      },
    ],
    structuredContent,
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
  if (error instanceof ArtifactReadError) {
    return {
      code: error.code,
      message: error.message,
      retryable: false,
      remediation: [],
      details: {},
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

import { type McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";

import {
  type AuthoringGateway,
  type JsonRecord,
} from "../authoring_client.js";
import {
  type ArtifactReader,
  type ReadArtifact,
} from "../artifacts.js";
import {
  authoringResult,
  failureEnvelope,
  readOnlyAnnotations,
  successEnvelope,
  toolEnvelopeSchema,
} from "./result.js";

const jsonRecordSchema = z.record(z.string(), z.unknown());

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
        .strict()
        .superRefine((input, context) => {
          if (input.operation === "get" && input.ids.length !== 1) {
            context.addIssue({
              code: "custom",
              path: ["ids"],
              message: "get requires exactly one ID",
            });
          }
          if (input.operation === "batch_get" && input.ids.length === 0) {
            context.addIssue({
              code: "custom",
              path: ["ids"],
              message: "batch_get requires at least one ID",
            });
          }
          if (input.operation === "search" && !input.searchTerm) {
            context.addIssue({
              code: "custom",
              path: ["searchTerm"],
              message: "search requires a search term",
            });
          }
          if (
            (input.operation === "list" || input.operation === "summary") &&
            input.ids.length > 0
          ) {
            context.addIssue({
              code: "custom",
              path: ["ids"],
              message: `${input.operation} does not accept IDs`,
            });
          }
        }),
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
        "Separately checks project structure, references, and optional capability certification on an immutable snapshot.",
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

function artifactData(artifact: ReadArtifact): JsonRecord {
  return {
    uri: artifact.uri,
    mediaType: artifact.mediaType,
    ...(artifact.text === undefined ? {} : { text: artifact.text }),
    ...(artifact.blob === undefined ? {} : { blob: artifact.blob }),
  };
}

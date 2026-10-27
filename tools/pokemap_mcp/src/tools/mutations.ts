import { type McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";

import type { AuthoringGateway } from "../authoring_client.js";
import { PokeMapToolError } from "../tool_error.js";
import {
  authoringResult,
  mutationAnnotations,
  readOnlyAnnotations,
  toolEnvelopeSchema,
} from "./result.js";

const jsonRecordSchema = z.record(z.string(), z.unknown());
const revisionSchema = z.string().regex(/^sha256:[0-9a-f]{64}$/);

export function registerMutationTools(
  server: McpServer,
  authoring: AuthoringGateway,
): void {
  server.registerTool(
    "pokemap_workshop",
    {
      title: "Read or prepare scoped workshop authoring",
      description: "Reads only the documents needed by a catalog action. Explicit preparation admits an older or copied catalog and prepares its editing indexes and retained history; preparation may inspect the whole catalog and belongs before local edits. Use returned snapshotRevision and planExtensions with pokemap_plan. Use preparation scope=mapCreation for only the map identity/path ownership index of an already admitted catalog; it reads map metadata, without maps, assets or retained history. Preparation scope=assetImport indexes only model and tileset definition positions for append-only imports. Preparation scope=nativeResources indexes only Smart Tile, Border and Environment definition positions. Preparation scope=metadataContext explicitly attests canonical catalog metadata for the current generation and its prepared local undo window, including required historical index conversions; it preserves HEAD, receipts and navigable entries and never expires or collects data. It returns contextVersion and metadataRevision. Set includeDocuments=false when only planning metadata is needed to omit project and map documents.",
      inputSchema: z.discriminatedUnion("operation", [
        z.object({ operation: z.literal("read"), projectHandle: z.string().min(1),
          actionId: z.string().min(1), parameters: jsonRecordSchema.default({}),
          readDependencies: z.record(z.string(), z.string()).optional(),
          includeDocuments: z.boolean().default(true), }).strict(),
        z.object({ operation: z.literal("prepare"), projectHandle: z.string().min(1), scope: z.enum(["mapCreation", "assetImport", "nativeResources", "metadataContext"]).optional() }).strict(),
      ]),
      outputSchema: toolEnvelopeSchema,
      annotations: mutationAnnotations,
    },
    async (input) => authoringResult(() => input.operation === "prepare"
      ? authoring.request("workshop_prepare", { projectHandle: input.projectHandle, ...(input.scope ? { scope: input.scope } : {}) })
      : authoring.request("workshop_snapshot", { projectHandle: input.projectHandle,
          actionId: input.actionId, parameters: input.parameters, includeDocuments: input.includeDocuments,
          ...(input.readDependencies ? {readDependencies: input.readDependencies} : {}) })),
  );

  server.registerTool(
    "pokemap_project_bootstrap",
    {
      title: "Inspect or repair a PokeMap project bootstrap",
      description:
        "Inspects a project before opening it and can transactionally add the canonical Pokemon ruleset after exact confirmation.",
      inputSchema: z.discriminatedUnion("operation", [
        z
          .object({
            operation: z.literal("inspect"),
            projectRoot: z.string().min(1),
          })
          .strict(),
        z
          .object({
            operation: z.literal("repair_ruleset"),
            projectRoot: z.string().min(1),
            expectedRevision: revisionSchema,
            confirmation: z.literal("REPAIR POKEMON RULESET"),
          })
          .strict(),
      ]),
      outputSchema: toolEnvelopeSchema,
      annotations: mutationAnnotations,
    },
    async (input) =>
      input.operation === "inspect"
        ? authoringResult(() =>
            authoring.request("project_bootstrap_inspect", {
              projectRoot: input.projectRoot,
            }),
          )
        : authoringResult(() =>
            authoring.request("project_bootstrap_repair", {
              projectRoot: input.projectRoot,
              expectedRevision: input.expectedRevision,
              confirmation: input.confirmation,
            }),
          ),
  );

  server.registerTool(
    "pokemap_artifact_stage",
    {
      title: "Stage a local PokeMap artifact",
      description:
        "Securely stages a file from an allowed root and returns an opaque handle for canonical asset mutations.",
      inputSchema: z
        .object({
          sourcePath: z.string().min(1),
          declaredMediaType: z
            .string()
            .regex(/^[a-z0-9][a-z0-9!#$&^_.+-]*\/[a-z0-9][a-z0-9!#$&^_.+-]*$/i)
            .optional(),
        })
        .strict(),
      outputSchema: toolEnvelopeSchema,
      annotations: {
        ...mutationAnnotations,
        destructiveHint: false,
      },
    },
    async ({ sourcePath, declaredMediaType }) =>
      authoringResult(() =>
        authoring.request("stage_artifact", {
          sourcePath,
          ...(declaredMediaType ? { declaredMediaType } : {}),
        }),
      ),
  );

  server.registerTool(
    "pokemap_plan",
    {
      title: "Plan a PokeMap mutation",
      description:
        "Builds a revision-bound preview and planned receipt without writing project files.",
      inputSchema: z
        .object({
          projectHandle: z.string().min(1),
          request: z
            .object({
              requestId: z.string().min(1),
              actionId: z.string().min(1),
              actionVersion: z.number().int().positive(),
              workspaceHandle: z.string().min(1),
              parameters: jsonRecordSchema,
              expectedRevision: revisionSchema.optional(),
              idempotencyKey: z.string().min(1),
              dryRun: z.boolean().default(false),
              extensions: jsonRecordSchema.optional(),
            })
            .strict(),
        })
        .strict(),
      outputSchema: toolEnvelopeSchema,
      annotations: {
        ...mutationAnnotations,
        destructiveHint: false,
      },
    },
    async ({ projectHandle, request }) =>
      authoringResult(() =>
        authoring.request("plan", { projectHandle, request }),
      ),
  );

  server.registerTool(
    "pokemap_apply",
    {
      title: "Confirm or apply a PokeMap mutation",
      description:
        "Issues a plan-bound confirmation or applies a frozen plan with an explicit operation id.",
      inputSchema: z.discriminatedUnion("operation", [
        z
          .object({
            operation: z.literal("confirm"),
            projectHandle: z.string().min(1),
            planId: z.string().min(1),
          })
          .strict(),
        z
          .object({
            operation: z.literal("apply"),
            projectHandle: z.string().min(1),
            planId: z.string().min(1),
            operationId: z.string().min(1),
            confirmationToken: z.string().min(1).optional(),
          })
          .strict(),
      ]),
      outputSchema: toolEnvelopeSchema,
      annotations: mutationAnnotations,
    },
    async (input) =>
      input.operation === "confirm"
        ? authoringResult(() =>
            authoring.request("confirm", {
              projectHandle: input.projectHandle,
              planId: input.planId,
            }),
          )
        : authoringResult(() =>
            authoring.request("apply", {
              projectHandle: input.projectHandle,
              planId: input.planId,
              operationId: input.operationId,
              ...(input.confirmationToken
                ? { confirmationToken: input.confirmationToken }
                : {}),
            }),
          ),
  );

  server.registerTool(
    "pokemap_history",
    {
      title: "Inspect, undo, redo or maintain PokeMap history",
      description:
        "Lists committed receipts, requests a revision-safe undo or redo, or explicitly maintains managed project undo history. Maintenance previews by default; applying requires the exact preview fingerprint and current revision. Review expiredEntryIds and any legacyBarrierEntryId before applying: older independent undo may limit the safe retained sequence. Defaults: 50 user operations and 200 MiB logical undo data. Pending recovery and live readers remain protected. Maintenance may inspect retained data and never runs as part of a save.",
      inputSchema: z.discriminatedUnion("operation", [
        z
          .object({
            operation: z.literal("list"),
            projectHandle: z.string().min(1),
            limit: z.number().int().min(1).max(100).default(20),
            cursor: z.string().min(1).optional(),
          })
          .strict(),
        z
          .object({
            operation: z.enum(["undo", "redo"]),
            projectHandle: z.string().min(1),
            entryId: z.string().min(1),
            idempotencyKey: z.string().min(1),
          })
          .strict(),
        z.object({
          operation: z.literal("maintain"),
          projectHandle: z.string().min(1),
          expectedRevision: revisionSchema,
          apply: z.boolean().default(false),
          expectedFingerprint: z.string().min(1).optional(),
          maxOperations: z.number().int().min(1).max(50).default(50),
          maxBytes: z.number().int().min(1).max(200 * 1024 * 1024).default(200 * 1024 * 1024),
        }).strict().refine(input => !input.apply || input.expectedFingerprint !== undefined, {
          message: "Applying maintenance requires the exact preview fingerprint.",
          path: ["expectedFingerprint"],
        }),
      ]),
      outputSchema: toolEnvelopeSchema,
      annotations: mutationAnnotations,
    },
    async (input) => {
      if (input.operation === "maintain") {
        return authoringResult(() => authoring.request("history_maintenance", {
          projectHandle: input.projectHandle,
          expectedRevision: input.expectedRevision,
          apply: input.apply,
          ...(input.expectedFingerprint ? { expectedFingerprint: input.expectedFingerprint } : {}),
          maxOperations: input.maxOperations,
          maxBytes: input.maxBytes,
        }));
      }
      return input.operation === "list"
        ? authoringResult(() =>
            authoring.request("history", {
              projectHandle: input.projectHandle,
              limit: input.limit,
              ...(input.cursor ? { cursor: input.cursor } : {}),
            }),
          )
        : authoringResult(() =>
            authoring.request(input.operation, {
              projectHandle: input.projectHandle,
              entryId: input.entryId,
              idempotencyKey: input.idempotencyKey,
            }),
          );
    },
  );

  server.registerTool(
    "pokemap_recovery_discard",
    {
      title: "Discard an incomplete PokeMap preparation",
      description: "Discards only an uncommitted incomplete transaction preparation. Never resumes, promotes or reconstructs project data. Requires recovery permission and records an audit event.",
      inputSchema: z.object({
        projectHandle: z.string().min(1),
        operationId: z.string().min(1),
      }).strict(),
      outputSchema: toolEnvelopeSchema,
      annotations: mutationAnnotations,
    },
    async (input) => authoringResult(() => authoring.request("discard_preparation", input)),
  );

  server.registerTool(
    "pokemap_recovery_status",
    {
      title: "Inspect a PokeMap operation",
      description: "Reports committed, recoverable and finalized state without applying or resuming an operation.",
      inputSchema: z.object({
        projectHandle: z.string().min(1),
        operationId: z.string().min(1),
      }).strict(),
      outputSchema: toolEnvelopeSchema,
      annotations: readOnlyAnnotations,
    },
    async (input) => authoringResult(() => authoring.request("recovery_status", input)),
  );

  server.registerTool(
    "pokemap_recovery",
    {
      title: "Recover a PokeMap transaction",
      description:
        "Resumes one recoverable transaction only after an exact human-readable confirmation phrase.",
      inputSchema: z
        .object({
          projectHandle: z.string().min(1),
          operationId: z.string().min(1),
          confirmation: z.string().min(1),
        })
        .strict(),
      outputSchema: toolEnvelopeSchema,
      annotations: mutationAnnotations,
    },
    async ({ projectHandle, operationId, confirmation }) => {
      const expected = `RECOVER ${operationId}`;
      if (confirmation !== expected) {
        return authoringResult(() =>
          Promise.reject(
            new PokeMapToolError(
              "confirmation.required",
              "Recovery requires the exact confirmation phrase.",
              false,
              [`Retry with confirmation exactly equal to \"${expected}\".`],
              { expectedConfirmation: expected },
            ),
          ),
        );
      }
      return authoringResult(() =>
        authoring.request("recover", { projectHandle, operationId }),
      );
    },
  );
}

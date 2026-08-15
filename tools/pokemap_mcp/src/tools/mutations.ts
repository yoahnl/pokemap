import { type McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";

import type { AuthoringGateway } from "../authoring_client.js";
import { PokeMapToolError } from "../tool_error.js";
import {
  authoringResult,
  mutationAnnotations,
  toolEnvelopeSchema,
} from "./result.js";

const jsonRecordSchema = z.record(z.string(), z.unknown());
const revisionSchema = z.string().regex(/^sha256:[0-9a-f]{64}$/);

export function registerMutationTools(
  server: McpServer,
  authoring: AuthoringGateway,
): void {
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
      title: "Inspect or undo PokeMap history",
      description:
        "Lists committed receipts with stable pagination or requests a revision-safe undo.",
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
            operation: z.literal("undo"),
            projectHandle: z.string().min(1),
            entryId: z.string().min(1),
            idempotencyKey: z.string().min(1),
          })
          .strict(),
      ]),
      outputSchema: toolEnvelopeSchema,
      annotations: mutationAnnotations,
    },
    async (input) =>
      input.operation === "list"
        ? authoringResult(() =>
            authoring.request("history", {
              projectHandle: input.projectHandle,
              limit: input.limit,
              ...(input.cursor ? { cursor: input.cursor } : {}),
            }),
          )
        : authoringResult(() =>
            authoring.request("undo", {
              projectHandle: input.projectHandle,
              entryId: input.entryId,
              idempotencyKey: input.idempotencyKey,
            }),
          ),
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

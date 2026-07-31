import { type McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";

import type { RuntimeGateway } from "../runtime_gateway.js";
import {
  mutationAnnotations,
  readOnlyAnnotations,
  toolEnvelopeSchema,
  toolResult,
} from "./result.js";

export function registerRuntimeTools(
  server: McpServer,
  runtime: RuntimeGateway,
): void {
  server.registerTool(
    "pokemap_render",
    {
      title: "Render a PokeMap snapshot",
      description:
        "Renders an explicit map or region at its current revision and returns an opaque image artifact handle.",
      inputSchema: z
        .object({
          projectHandle: z.string().min(1),
          mapId: z.string().min(1),
          region: z
            .object({
              x: z.number().int().nonnegative(),
              y: z.number().int().nonnegative(),
              width: z.number().int().positive(),
              height: z.number().int().positive(),
            })
            .strict()
            .optional(),
          layerIds: z.array(z.string().min(1)).default([]),
          overlays: z
            .array(z.enum(["collision", "zones", "warps", "entities"]))
            .default([]),
          cellPixelSize: z.number().int().min(1).max(64).default(8),
        })
        .strict(),
      outputSchema: toolEnvelopeSchema,
      annotations: readOnlyAnnotations,
    },
    async (request) =>
      toolResult(() =>
        runtime.render({
          projectHandle: request.projectHandle,
          mapId: request.mapId,
          ...(request.region ? { region: request.region } : {}),
          layerIds: request.layerIds,
          overlays: request.overlays,
          cellPixelSize: request.cellPixelSize,
        }),
      ),
  );

  server.registerTool(
    "pokemap_playtest",
    {
      title: "Start a sandboxed PokeMap playtest",
      description:
        "Starts a bounded evaluation job for a scenario bound to the opened project. Poll it with pokemap_job.",
      inputSchema: z
        .object({
          projectHandle: z.string().min(1),
          scenarioId: z.string().min(1),
          target: z.enum(["headless", "interactive"]).default("headless"),
          policy: z.enum(["probe", "certify"]).optional(),
        })
        .strict(),
      outputSchema: toolEnvelopeSchema,
      annotations: {
        ...mutationAnnotations,
        destructiveHint: false,
      },
    },
    async (request) =>
      toolResult(() =>
        runtime.startPlaytest({
          projectHandle: request.projectHandle,
          scenarioId: request.scenarioId,
          target: request.target,
          ...(request.policy ? { policy: request.policy } : {}),
        }),
      ),
  );

  server.registerTool(
    "pokemap_job",
    {
      title: "Manage a PokeMap runtime job",
      description:
        "Gets state, reads ordered events, cancels, or retries a playtest job. Terminal jobs expose receipt and artifact links.",
      inputSchema: z.discriminatedUnion("operation", [
        z
          .object({
            operation: z.literal("get"),
            jobId: z.string().min(1),
          })
          .strict(),
        z
          .object({
            operation: z.literal("events"),
            jobId: z.string().min(1),
            afterSequence: z.number().int().nonnegative().default(0),
          })
          .strict(),
        z
          .object({
            operation: z.literal("cancel"),
            jobId: z.string().min(1),
          })
          .strict(),
        z
          .object({
            operation: z.literal("retry"),
            jobId: z.string().min(1),
          })
          .strict(),
      ]),
      outputSchema: toolEnvelopeSchema,
      annotations: mutationAnnotations,
    },
    async (input) =>
      toolResult(() => {
        switch (input.operation) {
          case "get":
            return runtime.getJob(input.jobId);
          case "events":
            return runtime.jobEvents(input.jobId, input.afterSequence);
          case "cancel":
            return runtime.cancelJob(input.jobId);
          case "retry":
            return runtime.retryJob(input.jobId);
        }
      }),
  );
}

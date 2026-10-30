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
  compact = false,
): void {
  if (!compact) server.registerTool(
    "pokemap_render",
    {
      title: "Render a PokeMap snapshot",
      description:
        "Renders an explicit map or region at its current authored revision, including authored NPC sprites and placed-element occlusion, and returns an opaque image artifact handle.",
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
    "pokemap_render_3d",
    {
      title: "Render a PokeMap 3D map",
      description:
        "Renders a 3D map at its current authored revision through the native Metal renderer (terrain, Border faces, GLB models, lighting) and returns an opaque PNG artifact handle. Use it to see Border reliefs, joints and holes that pokemap_render cannot show. view game uses the player camera, top looks straight down and orbit gives an oblique overview; center pans to world cells and magnification zooms in every view. macOS only; a small floating window appears while rendering; the first call may build the host and load the map for one to two minutes.",
      inputSchema: z
        .object({
          projectHandle: z.string().min(1),
          mapId: z.string().min(1),
          center: z.object({ x: z.number(), z: z.number() }).strict().optional(),
          magnification: z.number().min(0.5).max(8).default(2),
          view: z.enum(["game", "top", "orbit"]).default("game"),
          minuteOfDay: z.number().min(0).max(1439).default(720),
        })
        .strict(),
      outputSchema: toolEnvelopeSchema,
      annotations: readOnlyAnnotations,
    },
    async (request) =>
      toolResult(() =>
        runtime.render3d({
          projectHandle: request.projectHandle,
          mapId: request.mapId,
          ...(request.center ? { center: request.center } : {}),
          magnification: request.magnification,
          view: request.view,
          minuteOfDay: request.minuteOfDay,
        }),
      ),
  );

  server.registerTool(
    "pokemap_render_3d_scan",
    {
      title: "Scan a PokeMap 3D map for holes",
      description:
        "Loads a 3D map once in the native renderer, frames every cluster of cells whose ground nothing proves and every placed object crossing Border modules (the spatialMapIntegrity report), then, with grid (default), tiles the whole painted area in player views. It measures where the background shows through the map: holeRatio counts background patches the scene encloses (missing ground, unbridged height steps, slits between modules); backgroundRatio also counts the map's outer void and sky. Returns a PNG artifact for every targeted view and for each grid view with a hole; look at each overlap view, since crossing geometry is not a hole. macOS only; about one second per view after loading.",
      inputSchema: z
        .object({
          projectHandle: z.string().min(1),
          mapId: z.string().min(1),
          maxViews: z.number().int().min(1).max(32).default(12),
          magnification: z.number().min(2).max(8).default(4),
          grid: z.boolean().default(true),
        })
        .strict(),
      outputSchema: toolEnvelopeSchema,
      annotations: readOnlyAnnotations,
    },
    async (request) =>
      toolResult(() =>
        runtime.scan3d({
          projectHandle: request.projectHandle,
          mapId: request.mapId,
          maxViews: request.maxViews,
          magnification: request.magnification,
          grid: request.grid,
        }),
      ),
  );

  if (!compact) server.registerTool(
    "pokemap_playtest",
    {
      title: "Start a sandboxed PokeMap playtest",
      description:
        "Starts a bounded evaluation job for a scenario bound to the opened project. Poll it with pokemap_job.",
      inputSchema: z
        .object({
          projectHandle: z.string().min(1),
          scenarioId: z.string().min(1),
          simulationSpeed: z.union([z.literal(1), z.literal(2), z.literal(5), z.literal(10)]).optional(),
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
          ...(request.simulationSpeed ? { simulationSpeed: request.simulationSpeed } : {}),
          target: request.target,
          ...(request.policy ? { policy: request.policy } : {}),
        }),
      ),
  );

  if (!compact) server.registerTool(
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

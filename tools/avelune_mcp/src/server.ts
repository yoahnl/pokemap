import { McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";

import {
  type AveluneController,
  type ControlDescribe,
  type ControlState,
} from "./controller.js";
import {
  controlAnnotations,
  readOnlyAnnotations,
  toolEnvelopeSchema,
  toolResult,
} from "./result.js";

const SUPPORTED_PROTOCOL_VERSIONS = ["2026-07-28", "2025-11-25"] as const;

export function createAveluneMcpServer(controller: AveluneController): McpServer {
  const server = new McpServer(
    { name: "avelune-control", version: "0.1.0" },
    {
      supportedProtocolVersions: [...SUPPORTED_PROTOCOL_VERSIONS],
      instructions:
        "Control only the connected Avelune development session. Install packages only from configured roots and wait for explicit application state instead of inferring success from UI events.",
    },
  );

  server.registerTool(
    "avelune_describe",
    {
      title: "Describe Avelune control",
      description: "Checks the controlled development app and lists its capabilities.",
      inputSchema: z.object({}).strict(),
      outputSchema: toolEnvelopeSchema,
      annotations: readOnlyAnnotations,
    },
    async () => toolResult(async () => asRecord(await controller.describe())),
  );

  server.registerTool(
    "avelune_state",
    {
      title: "Read Avelune state",
      description:
        "Returns the Hub status, active surface, active game, install generation, and installed library.",
      inputSchema: z.object({}).strict(),
      outputSchema: toolEnvelopeSchema,
      annotations: readOnlyAnnotations,
    },
    async () => toolResult(async () => asRecord(await controller.state())),
  );

  server.registerTool(
    "avelune_install",
    {
      title: "Install an Avelune game",
      description:
        "Uploads an allowed .avelunegame package to the controlled app and requires Avelune to prove a completed installation transition.",
      inputSchema: z
        .object({
          packagePath: z.string().min(1),
          timeoutMs: z.number().int().min(100).max(300_000).default(120_000),
        })
        .strict(),
      outputSchema: toolEnvelopeSchema,
      annotations: controlAnnotations,
    },
    async ({ packagePath, timeoutMs }) =>
      toolResult(async () =>
        asRecord(await controller.install(packagePath, timeoutMs)),
      ),
  );

  server.registerTool(
    "avelune_launch",
    {
      title: "Launch an installed Avelune game",
      description:
        "Launches a healthy installed game through the canonical Hub session controller.",
      inputSchema: z.object({ gameId: z.string().min(1) }).strict(),
      outputSchema: toolEnvelopeSchema,
      annotations: controlAnnotations,
    },
    async ({ gameId }) =>
      toolResult(async () => asRecord(await controller.launch(gameId))),
  );

  server.registerTool(
    "avelune_return_to_hub",
    {
      title: "Return Avelune to the Hub",
      description: "Closes the active Player surface and refreshes the Hub.",
      inputSchema: z.object({}).strict(),
      outputSchema: toolEnvelopeSchema,
      annotations: controlAnnotations,
    },
    async () =>
      toolResult(async () => asRecord(await controller.returnToHub())),
  );

  server.registerTool(
    "avelune_wait",
    {
      title: "Wait for an Avelune state",
      description:
        "Polls semantic application state until the Hub, Player, or an installed game is ready.",
      inputSchema: z
        .object({
          condition: z.enum(["hubReady", "playerOpened", "gameInstalled"]),
          gameId: z.string().min(1).optional(),
          timeoutMs: z.number().int().min(100).max(300_000).default(30_000),
        })
        .strict(),
      outputSchema: toolEnvelopeSchema,
      annotations: readOnlyAnnotations,
    },
    async ({ condition, gameId, timeoutMs }) =>
      toolResult(async () =>
        asRecord(await controller.waitFor(condition, gameId, timeoutMs)),
      ),
  );

  return server;
}

function asRecord(value: ControlState | ControlDescribe): Record<string, unknown> {
  return value as unknown as Record<string, unknown>;
}

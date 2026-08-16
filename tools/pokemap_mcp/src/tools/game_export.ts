import { isAbsolute } from "node:path";

import { type McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";

import {
  type AuthoringGateway,
  type ProjectRootResolver,
} from "../authoring_client.js";
import { authoringResult, toolEnvelopeSchema } from "./result.js";

export function registerGameExportTool(
  server: McpServer,
  authoring: AuthoringGateway,
  projectRoots: ProjectRootResolver | undefined,
): void {
  server.registerTool(
    "pokemap_game_export",
    {
      title: "Export an Avelune game package",
      description:
        "Builds, certifies, and writes one .avelunegame file for an opened project into a configured export root.",
      inputSchema: z
        .object({
          projectHandle: z.string().min(1),
          outputPath: z
            .string()
            .min(1)
            .refine(isAbsolute, "outputPath must be absolute"),
        })
        .strict(),
      outputSchema: toolEnvelopeSchema,
      annotations: {
        readOnlyHint: false,
        destructiveHint: false,
        idempotentHint: false,
        openWorldHint: false,
      },
    },
    async ({ projectHandle, outputPath }) =>
      authoringResult(async () => {
        if (!projectRoots) {
          throw new Error("Project-root resolution is unavailable.");
        }
        return authoring.request("game_export", {
          projectRoot: projectRoots.resolveProjectRoot(projectHandle),
          outputPath,
        });
      }),
  );
}

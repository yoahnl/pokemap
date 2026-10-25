import { isAbsolute } from "node:path";
import type { McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";
import type { AuthoringGateway } from "../authoring_client.js";
import { authoringResult, toolEnvelopeSchema } from "./result.js";

export function registerCharacterContactShadowTools(server: McpServer, authoring: AuthoringGateway): void {
  const identity = {
    projectRoot: z.string().min(1).refine(isAbsolute, "projectRoot must be absolute"),
    characterId: z.string().min(1).max(256),
  };
  server.registerTool("pokemap_character_contact_shadow_inspect", {
    title: "Inspect one character contact shadow",
    description: "Read the nullable resource override, effective setting and manifest revision under configured roots without loading unrelated assets or opening a full workspace.",
    inputSchema: z.object(identity).strict(),
    outputSchema: toolEnvelopeSchema,
    annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: false },
  }, async (args) => authoringResult(() => authoring.request("character_contact_shadow_inspect", args)));
  server.registerTool("pokemap_character_contact_shadow_set", {
    title: "Set one character contact shadow",
    description: "Set true or false, or null to inherit the project default, using the exact manifest revision returned by inspect. Uses the canonical scoped transaction and returns a receipt. On an unknown outcome retry the same operationId and identical arguments.",
    inputSchema: z.object({ ...identity, expectedRevision: z.string().min(1).max(256), enabled: z.boolean().nullable(), operationId: z.string().min(1).max(256) }).strict(),
    outputSchema: toolEnvelopeSchema,
    annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false },
  }, async (args) => authoringResult(() => authoring.request("character_contact_shadow_set", args)));
}

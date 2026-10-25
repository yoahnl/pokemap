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
    description: "Read the nullable resource override, effective setting and current document or catalog generation revision under configured roots. For an existing working catalog, this admits its reader in the current worker session before subsequent set calls. Initial admission is separate from save work. Never partitions a project implicitly or loads unrelated assets.",
    inputSchema: z.object(identity).strict(),
    outputSchema: toolEnvelopeSchema,
    annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: false },
  }, async (args) => authoringResult(() => authoring.request("character_contact_shadow_inspect", args)));
  server.registerTool("pokemap_character_contact_shadow_set", {
    title: "Set one character contact shadow",
    description: "Set true or false, or null to inherit the project default, using the exact revision returned by inspect in this server session. An existing working catalog must first be admitted through inspect; its save updates the character definition and required catalog dependencies without rewriting project.json. Never partitions a project implicitly. Uses the canonical scoped transaction and returns a receipt. On an unknown outcome retry the same operationId and identical arguments.",
    inputSchema: z.object({ ...identity, expectedRevision: z.string().min(1).max(256), enabled: z.boolean().nullable(), operationId: z.string().min(1).max(256) }).strict(),
    outputSchema: toolEnvelopeSchema,
    annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false },
  }, async (args) => authoringResult(() => authoring.request("character_contact_shadow_set", args)));
}

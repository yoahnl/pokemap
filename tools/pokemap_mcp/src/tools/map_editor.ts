import { isAbsolute } from "node:path";
import type { McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";
import type { AuthoringGateway } from "../authoring_client.js";
import { authoringResult, toolEnvelopeSchema } from "./result.js";

export function registerMapEditorTools(server: McpServer, authoring: AuthoringGateway): void {
  const identity = {
    projectRoot: z.string().min(1).refine(isAbsolute, "projectRoot must be absolute"),
    mapId: z.string().min(1).max(128),
    mapRelativePath: z.string().min(1).max(1024).optional(),
  };
  const mutation = {
    ...identity,
    expectedRevision: z.string().min(1).max(128),
    operationId: z.string().min(1).max(120),
  };
  const state = z.object({
    lockedElements: z.array(z.string().min(3).max(384)).max(4096).optional(),
    lockedFamilies: z.array(z.enum(["layer", "decor", "model", "entity", "warp", "zone", "trigger", "effect"])).max(8).optional(),
  }).strict();
  server.registerTool("pokemap_map_editor_inspect", {
    title: "Inspect map editor locks",
    description: "Read selection and movement locks for one map. Absent editor documents mean unlocked elements. Returns the exact revision required by set. Reads only the bounded maps/<mapId>.editor.json document and map metadata, without loading the project, map content, assets or history. Locks affect editing in both 2D and 3D and do not change gameplay.",
    inputSchema: z.object(identity).strict(),
    outputSchema: toolEnvelopeSchema,
    annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: false },
  }, async args => authoringResult(() => authoring.request("map_editor_inspect", args)));
  server.registerTool("pokemap_map_editor_set", {
    title: "Save map editor locks",
    description: "Set selection and movement locks through the canonical map.editor.set transaction. Supply the entire current state from inspect with edited lockedElements and lockedFamilies, the exact revision and a unique operationId. Element keys use kind:id with kind layer, decor, model, entity, warp, zone, trigger or effect. lockedFamilies accepts only those canonical kinds and locks every element of that kind. Studio's category groups, such as particles, persist an explicit batch of lockedElements keys rather than a category name. Locked elements remain visible but are excluded from selection and movement in 2D and 3D. Writes only the editor sidecar and scoped transaction/history metadata; never loads or rewrites project content. Retry identical arguments and operationId after an unknown outcome.",
    inputSchema: z.object({ ...mutation, state }).strict(),
    outputSchema: toolEnvelopeSchema,
    annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false },
  }, async args => authoringResult(() => authoring.request("map_editor_set", args)));
  server.registerTool("pokemap_map_editor_undo", {
    title: "Undo map editor locks",
    description: "Restore one current map editor lock receipt. Requires receiptId from set and the current revision from inspect. Preserves concurrent edits and records a scoped undo receipt without replaying project history.",
    inputSchema: z.object({ ...mutation, receiptId: z.string().regex(/^receipt_document_[a-f0-9]{32}$/) }).strict(),
    outputSchema: toolEnvelopeSchema,
    annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false },
  }, async args => authoringResult(() => authoring.request("map_editor_undo", args)));
  server.registerTool("pokemap_map_elements_inspect", {
    title: "Inspect map stacking order",
    description: "Read one map and its exact revision for a scoped stacking order edit. Does not load other maps, the project catalog, assets or accumulated history. The map's layer order and each layer's visualOrder determine stacking; frontFirstIds supplied to reorder begin with the highest element.",
    inputSchema: z.object(identity).strict(),
    outputSchema: toolEnvelopeSchema,
    annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: false },
  }, async args => authoringResult(() => authoring.request("map_elements_inspect", args)));
  server.registerTool("pokemap_map_elements_reorder", {
    title: "Reorder map elements",
    description: "Reorder one map through canonical map.elements.reorder. Supply kind layers with an exact permutation of all map layer ids, or kind decor plus layerId with an exact permutation of that layer's decoration ids. frontFirstIds starts with the element drawn highest. Edits only the affected map and scoped transaction metadata, preserving unknown JSON fields, concurrent revision checks and undo. Applies to composited layers and decorations; physical 3D volume depth remains determined by scene geometry.",
    inputSchema: z.object({ ...mutation, kind: z.enum(["layers", "decor"]), frontFirstIds: z.array(z.string().min(1).max(384)).max(100000), layerId: z.string().min(1).max(384).optional() }).strict(),
    outputSchema: toolEnvelopeSchema,
    annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false },
  }, async args => authoringResult(() => authoring.request("map_elements_reorder", args)));
  server.registerTool("pokemap_map_elements_undo", {
    title: "Undo map stacking order",
    description: "Restore one current map stacking receipt. Supply its receiptId, current exact map revision and a unique operationId. Uses only targeted immutable history and records an undo receipt; rejects concurrent changes.",
    inputSchema: z.object({ ...mutation, receiptId: z.string().regex(/^receipt_document_[a-f0-9]{32}$/) }).strict(),
    outputSchema: toolEnvelopeSchema,
    annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false },
  }, async args => authoringResult(() => authoring.request("map_elements_undo", args)));
}

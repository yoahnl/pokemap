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
    hiddenElements: z.array(z.string().min(3).max(384)).max(4096).optional(),
    hiddenFamilies: z.array(z.enum(["layer", "decor", "model", "entity", "warp", "zone", "trigger", "effect"])).max(8).optional(),
  }).strict();
  server.registerTool("pokemap_map_editor_inspect", {
    title: "Inspect map editor visibility and locks",
    description: "Read editor visibility and selection/movement locks for one map. Absent editor documents mean visible, unlocked elements. Version 1 documents retain their locks and default to visible elements; new documents use version 2. Returns the exact revision required by set. Reads only the bounded maps/<mapId>.editor.json document and map metadata, without loading the project, map content, assets or history. These settings affect editing in both 2D and 3D and do not change gameplay.",
    inputSchema: z.object(identity).strict(),
    outputSchema: toolEnvelopeSchema,
    annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: false },
  }, async args => authoringResult(() => authoring.request("map_editor_inspect", args)));
  server.registerTool("pokemap_map_editor_set", {
    title: "Save map editor visibility and locks",
    description: "Set editor visibility and selection/movement locks through canonical map.editor.set. Supply the entire current state from inspect with edited lockedElements, lockedFamilies, hiddenElements and hiddenFamilies, the exact revision and a unique operationId. Element keys use kind:id with kind layer, decor, model, entity, warp, zone, trigger or effect. Families accept only those canonical kinds and affect every element of that kind. Studio category groups, such as particles, persist explicit element keys rather than category names. Locked elements stay visible unless hidden, and cannot be selected or moved. Hidden elements and hidden layer contents, including paths and borders, are excluded from editor previews and picking in both 2D and 3D. Visibility never changes gameplay or exported map content. Each element-key collection accepts at most 4096 entries; the whole editor document remains limited to 65536 bytes. Writes only the version 2 editor sidecar and scoped transaction/history metadata, preserving legacy locks; never loads or rewrites project content. Retry identical arguments and operationId after an unknown outcome.",
    inputSchema: z.object({ ...mutation, state }).strict(),
    outputSchema: toolEnvelopeSchema,
    annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false },
  }, async args => authoringResult(() => authoring.request("map_editor_set", args)));
  server.registerTool("pokemap_map_editor_undo", {
    title: "Undo map editor visibility and locks",
    description: "Restore the visibility and locks from one current map editor receipt. Requires receiptId from set and the current revision from inspect. Preserves concurrent edits and records a scoped undo receipt without replaying project history.",
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

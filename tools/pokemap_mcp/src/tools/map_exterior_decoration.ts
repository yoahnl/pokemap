import { isAbsolute } from "node:path";
import type { McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";
import type { AuthoringGateway, JsonRecord } from "../authoring_client.js";
import { authoringResult, toolEnvelopeSchema } from "./result.js";

export function registerMapExteriorDecorationTools(server: McpServer, authoring: AuthoringGateway): void {
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
  const sectorId = z.string().regex(/^[a-zA-Z0-9_-]{1,128}$/);
  const content = z.record(z.string(), z.unknown());
  const cell = z.object({x: z.number().int().min(-64).max(320), z: z.number().int().min(-64).max(320)}).strict();
  const cells = z.array(cell).min(1).max(1024);
  const nativeEdit = z.discriminatedUnion("kind", [
    z.object({kind: z.literal("terrain.paint"), sectorId, presetId: z.string().min(1), cells, materialId: z.string().min(1).optional(), erase: z.boolean().optional()}).strict(),
    z.object({kind: z.literal("environment.generate"), sectorId, presetId: z.string().min(1), cells, areaId: sectorId, layerId: sectorId.optional(), seed: z.number().int().min(-2147483648).max(2147483647), erase: z.boolean().optional()}).strict(),
    z.object({kind: z.literal("border.draw"), blueprintId: z.string().min(1), borderId: sectorId, layerId: sectorId.optional(), points: z.array(cell).min(2).max(16384), seed: z.string().regex(/^-?[0-9]+$/), closed: z.boolean().optional()}).strict(),
    z.object({kind: z.literal("border.erase"), borderId: sectorId, cells}).strict(),
  ]);
  const operations = [
    {id: "inspect", title: "Inspect exterior decoration", schema: z.object({...identity, sectorIds: z.array(sectorId).max(256).optional(), borderIds: z.array(sectorId).max(64).optional()}).strict(), readOnly: true},
    {id: "native_catalog", title: "Inspect exterior native catalog revision", schema: z.object(identity).strict(), readOnly: true},
    {id: "references_prepare", title: "Prepare exterior incoming resource references", schema: z.object(mutation).strict(), readOnly: false},
    {id: "native_edit", title: "Edit exterior native Terrain, Path, Border or Environment", schema: z.object({...mutation, expectedCatalogRevision: z.string().min(1).max(128), edit: nativeEdit}).strict(), readOnly: false},
    {id: "sector_batch", title: "Save one exterior brush gesture atomically", schema: z.object({...mutation, sectors: z.array(content).max(256), removeSectorIds: z.array(sectorId).max(256).optional()}).strict(), readOnly: false},
    {id: "configure", title: "Configure exterior decoration", schema: z.object({...mutation, decoration: content.nullable()}).strict(), readOnly: false},
    {id: "sector_set", title: "Save one exterior decoration sector", schema: z.object({...mutation, sector: content}).strict(), readOnly: false},
    {id: "sector_remove", title: "Remove one exterior decoration sector", schema: z.object({...mutation, sectorId}).strict(), readOnly: false},
    {id: "border_set", title: "Save one logical exterior Border", schema: z.object({...mutation, border: content}).strict(), readOnly: false},
    {id: "border_remove", title: "Remove one logical exterior Border", schema: z.object({...mutation, borderId: sectorId}).strict(), readOnly: false},
    {id: "undo", title: "Undo an exterior decoration edit", schema: z.object({...mutation, receiptId: z.string().min(1).max(128)}).strict(), readOnly: false},
  ];
  for (const operation of operations) {
    server.registerTool(`pokemap_map_exterior_decoration_${operation.id}`, {
      title: operation.title,
      description: "Use the canonical bounded exterior-decoration document. Inspect returns the current revision; mutations require that revision and a unique operationId. Native visual sectors remain separate from playable map data. Sector edits touch only affected visual documents and their small index, with dependency admission, revision checks and undo receipts. Native edits use world coordinates; read native_catalog once and pass its catalogRevision as expectedCatalogRevision, preserving it on retries. Use terrain.paint for native Terrain or Path presets, environment.generate for complete reusable vegetation, and border.draw/border.erase for one logical native Border across sectors.",
      inputSchema: operation.schema,
      outputSchema: toolEnvelopeSchema,
      annotations: {readOnlyHint: operation.readOnly, destructiveHint: false, idempotentHint: true, openWorldHint: false},
    }, async (args: JsonRecord) => authoringResult(() => authoring.request(`map_exterior_decoration_${operation.id}`, args)));
  }
}

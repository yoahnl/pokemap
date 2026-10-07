import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { execFile } from "node:child_process";
import { mkdtemp, readFile, realpath, rm } from "node:fs/promises";
import { basename, dirname, join, resolve } from "node:path";
import { tmpdir } from "node:os";
import { promisify } from "node:util";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

const projectRoot = await realpath(resolve(process.argv[2] ?? ""));
const sourcePath = await realpath(resolve(process.argv[3] ?? ""));
const png = await readFile(sourcePath);
assert.equal(basename(sourcePath), "basic.png", "This recipe uses the authored PSDK basic.png quarter cells.");
assert.equal(png.readUInt32BE(16), 256);
assert.equal(png.readUInt32BE(20), 3232);
const mapId = "terrain-qa";
const atlasId = "psdk-ground-transitions";
const temporaryRoot = await mkdtemp(join(tmpdir(), "avelune-psdk-ground-"));
const atlasPath = join(temporaryRoot, "psdk-ground-transitions.png");
await promisify(execFile)("python3", ["-c", `
from PIL import Image
import sys
source = Image.open(sys.argv[1]).convert('RGBA')
atlas = Image.new('RGBA', (512, 96))
for row, (column, tile_row) in enumerate([(0, 0), (5, 9), (0, 2)]):
 for mask in range(16):
  tile = Image.new('RGBA', (32, 32))
  if row == 0:
   tile = source.crop((0, 0, 32, 32))
  else:
   for quarter in range(4):
    east, south = quarter % 2, quarter // 2
    horizontal = 1 if mask & (2 if east else 8) else 2 if east else 0
    vertical = 1 if mask & (4 if south else 1) else 2 if south else 0
    x, y = (column + horizontal) * 32 + east * 16, (tile_row + vertical) * 32 + south * 16
    tile.paste(source.crop((x, y, x + 16, y + 16)), (east * 16, south * 16))
  atlas.paste(tile, (mask * 32, row * 32))
atlas.save(sys.argv[2])
`, sourcePath, atlasPath]);
const transport = new StdioClientTransport({ command: process.execPath,
  args: [resolve("dist/src/index.js"), "--root", projectRoot, "--artifact-root", dirname(sourcePath), "--artifact-root", temporaryRoot],
  cwd: process.cwd(), stderr: "pipe" });
const client = new Client({ name: "avelune-spatial-ground-authoring", version: "1.0.0" });

async function call(name: string, args: JsonRecord = {}): Promise<JsonRecord> {
  const result = await client.callTool({ name, arguments: args });
  const envelope = record(result.structuredContent);
  assert.equal(envelope.ok, true, JSON.stringify(envelope.error));
  return record(envelope.data);
}

const directions = ["northEdge", "eastEdge", "southEdge", "westEdge"];
function signature(mask: number): JsonRecord {
  return Object.fromEntries(directions.map((name, index) => [name, { kind: mask & (1 << index) ? "same" : "different" }]));
}

function preset(id: string, name: string, usage: string,
  materials: { id: string; column: number; row: number }[]): JsonRecord {
  return { id, name, usage, topology: "cardinal_4", templateHint: "free",
    coveragePolicy: "complete", coverageProfile: { mode: "explicit", requiredScenarios:
      materials.flatMap((material) => Array.from({ length: 16 }, (_, mask) => ({
        id: `${material.id}-${mask}`, centerMaterialId: material.id,
        signature: Object.fromEntries(directions.map((direction, index) =>
          [direction, mask & (1 << index) ? material.id : null])) }))) },
    defaultMaterialId: materials[0]!.id, allowedMaterialIds: materials.map((material) => material.id),
    rules: materials.flatMap((material) => Array.from({ length: 16 }, (_, mask) => ({
      id: `${material.id}-${mask}`, centerMatch: { kind: "material", materialId: material.id },
      signature: signature(mask), candidates: [{ id: `quarters-${mask}`,
        parts: [{ source: { kind: "frame", frame: {
          atlasId, column: mask, row: material.id === "psdk-grass" ? 0 : material.id === "psdk-dirt" ? 1 : 2 } }, channel: "ground" }] }] }))),
    tags: ["PSDK", "spatial-ground-qa"], transformPolicy: {} };
}

try {
  await client.connect(transport);
  const catalog = await call("pokemap_describe");
  const actions = (catalog.mutationActions as JsonRecord[]).map((action) => action.id);
  for (const action of ["tileset.import_image", "smart_tile.preset.publish", "smart_tile.cell.paint"]) assert.ok(actions.includes(action));
  const opened = await call("pokemap_workspace", { operation: "open", projectRoot });
  const projectHandle = String(opened.projectHandle), workspaceHandle = String(opened.workspaceHandle);
  async function query(kind: string, id: string): Promise<JsonRecord> {
    return call("pokemap_query", { projectHandle, resourceKind: kind, operation: "get", ids: [id], view: "detail" });
  }
  async function mutate(actionId: string, parameters: JsonRecord): Promise<void> {
    const snapshot = await query("project", "project");
    const id = randomUUID();
    const plan = await call("pokemap_plan", { projectHandle, request: {
      requestId: id, actionId, actionVersion: 1, workspaceHandle, parameters,
      expectedRevision: snapshot.snapshotRevision, idempotencyKey: id } });
    await call("pokemap_apply", { operation: "apply", projectHandle, planId: plan.planId, operationId: id });
  }
  try {
    let project = record(((await query("project", "project")).items as unknown[])[0]);
    assert.equal(record(project.settings).dimension, "threeD");
    if (!(project.maps as JsonRecord[]).some((map) => map.id === mapId)) {
      await mutate("map.create", { mapId, name: "Atelier sols 3D", width: 20, height: 16 });
    }
    if (!(project.tilesets as JsonRecord[]).some((tileset) => tileset.id === "psdk-ground")) {
      const staged = await call("pokemap_artifact_stage", { sourcePath, declaredMediaType: "image/png" });
      await mutate("tileset.import_image", { artifactHandle: staged.artifactHandle,
        tilesetId: "psdk-ground", name: "Sols PSDK", tileWidth: 32, tileHeight: 32 });
    }
    if (!(project.tilesets as JsonRecord[]).some((tileset) => tileset.id === "psdk-ground-transitions")) {
      const staged = await call("pokemap_artifact_stage", { sourcePath: atlasPath, declaredMediaType: "image/png" });
      await mutate("tileset.import_image", { artifactHandle: staged.artifactHandle,
        tilesetId: "psdk-ground-transitions", name: "Raccords PSDK", tileWidth: 32, tileHeight: 32 });
    }
    project = record(((await query("project", "project")).items as unknown[])[0]);
    const smart = record(project.smartTileCatalog ?? {});
    if (!((smart.atlases ?? []) as JsonRecord[]).some((atlas) => atlas.id === atlasId)) {
      await mutate("smart_tile.atlas.upsert", { atlas: { id: atlasId, name: "Sols PSDK · quartiers",
        tilesetId: "psdk-ground-transitions", cellWidth: 32, cellHeight: 32, columns: 16, rows: 3 } });
    }
    for (const [id, name] of [["psdk-grass", "Herbe"], ["psdk-dirt", "Terre"], ["psdk-sand", "Sable"]]) {
      if (!((smart.materials ?? []) as JsonRecord[]).some((material) => material.id === id)) {
        await mutate("smart_tile.material.upsert", { material: { id, name, connectionGroupId: id } });
      }
    }
    project = record(((await query("project", "project")).items as unknown[])[0]);
    const existingPresets = (record(project.smartTileCatalog).presets ?? []) as JsonRecord[];
    for (const value of [
      preset("psdk-grass", "Herbe PSDK", "terrain", [{ id: "psdk-grass", column: 0, row: 0 }]),
      preset("psdk-dirt", "Terre PSDK", "terrain", [{ id: "psdk-dirt", column: 5, row: 9 }]),
      preset("psdk-sand", "Sable PSDK", "terrain", [{ id: "psdk-sand", column: 0, row: 2 }]),
      preset("psdk-paths", "Chemins PSDK · terre et sable", "path", [
        { id: "psdk-dirt", column: 5, row: 9 }, { id: "psdk-sand", column: 0, row: 2 }]),
    ]) {
      const existing = existingPresets.find((entry) => entry.id === value.id);
      if (!existing) {
        await mutate("smart_tile.preset.publish", { preset: value, layer: {
          mapId, layerId: value.id === "psdk-grass" ? "ground" : value.usage === "path" ? "paths" : value.id, name: value.name } });
      } else {
        const candidate = ((existing.rules as JsonRecord[])[0]!.candidates as JsonRecord[])[0]!;
        const part = (candidate.parts as JsonRecord[])[0]!;
        const frame = record(record(part.source).frame);
        if (frame.atlasId !== atlasId) await mutate("smart_tile.preset.publish", { preset: value });
      }
    }
    const map = record(((await query("map", mapId)).items as unknown[])[0]);
    const order = (map.layers as JsonRecord[]).map((layer) => layer.id);
    const operations: JsonRecord[] = [];
    for (const [newIndex, id] of ["paths", "psdk-sand", "psdk-dirt", "ground"].entries()) {
      const oldIndex = order.indexOf(id);
      if (oldIndex === newIndex) continue;
      operations.push({ kind: "layer.reorder", oldIndex, newIndex });
      order.splice(newIndex, 0, ...order.splice(oldIndex, 1));
    }
    if (operations.length) await mutate("map.apply_operations", { mapId, operations });
    const ground = (map.layers as JsonRecord[]).find((layer) => layer.id === "ground")!;
    if ((record(ground.field).semanticCells as number[]).every((cell) => cell === 0)) {
      await mutate("smart_tile.cell.paint", { mapId, layerId: "ground", materialId: "psdk-grass",
        selection: { kind: "rectangle", start: { x: 0, y: 0 }, end: { x: 19, y: 15 } } });
    }
    const dirt = (map.layers as JsonRecord[]).find((layer) => layer.id === "psdk-dirt")!;
    const paths = (map.layers as JsonRecord[]).find((layer) => layer.id === "paths")!;
    if ((record(paths.field).semanticCells as number[]).every((cell) => cell !== 0)) {
      await mutate("smart_tile.cell.erase", { mapId, layerId: "paths",
        selection: { kind: "rectangle", start: { x: 0, y: 0 }, end: { x: 19, y: 15 } } });
    }
    if ((record(dirt.field).semanticCells as number[]).every((cell) => cell === 0)) {
      const cells = [];
      for (let y = 4; y <= 12; y++) for (let x = 3; x <= 5; x++) cells.push({ x, y });
      for (let y = 10; y <= 12; y++) for (let x = 6; x <= 16; x++) cells.push({ x, y });
      await mutate("smart_tile.cell.paint", { mapId, layerId: "psdk-dirt", materialId: "psdk-dirt", cells });
      await mutate("smart_tile.cell.paint", { mapId, layerId: "psdk-sand", materialId: "psdk-sand",
        cells: [{ x: 14, y: 5 }, { x: 15, y: 5 }, { x: 14, y: 6 }, { x: 15, y: 6 }] });
    }
    if ((record(paths.field).semanticCells as number[]).every((cell) => cell === 0)) {
      const cells = [];
      for (let x = 10; x <= 16; x++) cells.push({ x, y: 14 });
      for (let y = 8; y <= 13; y++) cells.push({ x: 16, y });
      await mutate("smart_tile.cell.paint", { mapId, layerId: "paths", materialId: "psdk-dirt", cells });
    }
    if (record(record(map.spatialScene).navigation).spawn && record(record(record(map.spatialScene).navigation).spawn).x !== 4) {
      await mutate("map3d.navigation.configure", { mapId, navigation: {
        spawn: { x: 4, z: 8 }, allowDiagonalMovement: false, ramps: [], blockedAreas: [] } });
    }
    const scene = record(map.spatialScene);
    if (!(scene.instances as unknown[]).length && (project.models3d as JsonRecord[]).some((model) => model.id === "house")) {
      await mutate("map3d.instance.upsert", { mapId, instance: {
        id: "qa-house", modelId: "house", position: { x: 10, y: 0, z: 5 },
        rotationDegrees: 0, scale: 1, animationIndex: null, blocksMovement: true } });
    }
    const validation = await call("pokemap_validate", { projectHandle });
    assert.equal(record(validation.structure).valid, true, JSON.stringify(validation));
    const authored = record(((await query("map", mapId)).items as unknown[])[0]);
    const layers = (authored.layers as JsonRecord[]).map((layer) => ({ id: layer.id,
      paintedCellCount: (record(layer.field).semanticCells as number[]).filter((cell) => cell !== 0).length }));
    console.log(JSON.stringify({ projectRoot, mapId, sourcePath, layers,
      palettes: ["Herbe PSDK", "Terre PSDK", "Sable PSDK", "Chemins PSDK · terre et sable"], validation }));
  } finally {
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
  }
} finally {
  await client.close();
  await transport.close();
  await rm(temporaryRoot, { recursive: true, force: true });
}

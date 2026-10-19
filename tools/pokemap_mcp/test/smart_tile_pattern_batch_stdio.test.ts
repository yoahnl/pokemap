import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import test from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("live MCP imports and paints bounded pattern batches atomically", { timeout: 120000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-pattern-batch-mcp-"));
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"], cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "pattern-batch-proof", version: "1.0.0" });
  async function response(name: string, args: JsonRecord = {}) {
    return client.callTool({ name, arguments: args }, { timeout: 125000 });
  }
  async function call(name: string, args: JsonRecord = {}): Promise<JsonRecord> {
    const result = await response(name, args);
    assert.equal(result.isError, undefined, JSON.stringify(result.structuredContent));
    return record(record(result.structuredContent).data);
  }
  try {
    await client.connect(transport);
    const described = await call("pokemap_describe");
    const descriptor = (described.mutationActions as JsonRecord[]).find(value => value.id === "smart_tile.pattern.upsert_batch");
    assert.ok(descriptor);
    assert.equal(record(descriptor.extensions).maximumPatternCount, 250);
    assert.equal(record(descriptor.extensions).maximumPatternCellCount, 16384);
    const request = { name: "Pattern batch", folderName: "patterns", parentPath: root, template: "empty", dimension: "threeD", mapWidth: 4, mapHeight: 4 };
    const preview = await call("pokemap_project_create_preview", { request });
    const created = await call("pokemap_project_create", { request, confirmation: preview.confirmation });
    const projectRoot = String(created.projectPath);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    const mutate = async (actionId: string, parameters: JsonRecord, id: string) => {
      const current = await call("pokemap_validate", { projectHandle: opened.projectHandle });
      const planned = await call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
        requestId: id, actionId, actionVersion: 1, workspaceHandle: opened.workspaceHandle,
        parameters, expectedRevision: current.snapshotRevision, idempotencyKey: id } });
      assert.equal(planned.applicable, true);
      return { planned, applied: await call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle, planId: planned.planId, operationId: id }) };
    };
    const image = join(root, "ground.png");
    await writeFile(image, Buffer.from("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=", "base64"));
    const staged = await call("pokemap_artifact_stage", { sourcePath: image, declaredMediaType: "image/png" });
    await mutate("tileset.import_image", { artifactHandle: staged.artifactHandle, tilesetId: "ground", name: "Ground", tileWidth: 1, tileHeight: 1 }, "image");
    await mutate("smart_tile.atlas.upsert", { atlas: { id: "atlas", name: "Ground", tilesetId: "ground", cellWidth: 1, cellHeight: 1, columns: 1, rows: 1 } }, "atlas");
    const manifestPath = join(projectRoot, "project.json");
    const manifest = JSON.parse(await readFile(manifestPath, "utf8")) as JsonRecord;
    const map = record((manifest.maps as JsonRecord[])[0]);
    const mapPath = join(projectRoot, String(map.relativePath));
    const mapBefore = await readFile(mapPath);
    const projectBefore = await readFile(manifestPath);
    const patterns = Array.from({ length: 217 }, (_, index) => ({
      id: `unit-${index}`, name: `Reusable ground ${index}`, usage: "terrain", width: 1, height: 1, repeatMode: "tiled",
      cells: [{ x: 0, y: 0, parts: [{ source: { kind: "frame", frame: { atlasId: "atlas", column: 0, row: 0 } } }] }] }));
    const current = await call("pokemap_validate", { projectHandle: opened.projectHandle });
    const rejected = await response("pokemap_plan", { projectHandle: opened.projectHandle, request: {
      requestId: "duplicate", actionId: "smart_tile.pattern.upsert_batch", actionVersion: 1, workspaceHandle: opened.workspaceHandle,
      parameters: { patterns: [patterns[0], patterns[0]] }, expectedRevision: current.snapshotRevision, idempotencyKey: "duplicate" } });
    assert.equal(rejected.isError, true);
    assert.deepEqual(await readFile(manifestPath), projectBefore);
    const { planned, applied } = await mutate("smart_tile.pattern.upsert_batch", { patterns }, "patterns");
    const replay = await call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle, planId: planned.planId, operationId: "patterns" });
    assert.equal(record(applied.receipt).receiptId, record(replay.receipt).receiptId);
    assert.deepEqual(await readFile(mapPath), mapBefore);
    const saved = JSON.parse(await readFile(manifestPath, "utf8")) as JsonRecord;
    assert.equal((record(saved.smartTileCatalog).patterns as JsonRecord[]).length, 217);
    const paintDescriptor = (described.mutationActions as JsonRecord[]).find(value => value.id === "smart_tile.pattern.paint_batch");
    assert.ok(paintDescriptor);
    assert.equal(record(paintDescriptor.extensions).maximumStrokeCount, 250);
    assert.equal(record(paintDescriptor.extensions).maximumTotalCellCount, 65536);
    const basePattern = patterns[0];
    assert.ok(basePattern);
    const baseCell = basePattern.cells[0];
    assert.ok(baseCell);
    await mutate("smart_tile.material.upsert", { material: { id: "grass", name: "Grass", connectionGroupId: "ground" } }, "material");
    await mutate("smart_tile.preset.publish", { preset: {
      id: "ground", name: "Ground", usage: "terrain", topology: "uniform", templateHint: "simple",
      coveragePolicy: "sparse", coverageProfile: { mode: "template" }, transformPolicy: {},
      defaultMaterialId: "grass", allowedMaterialIds: ["grass"], rules: [{
        id: "base", centerMatch: { kind: "material", materialId: "grass" }, signature: {},
        candidates: [{ id: "base", parts: baseCell.parts }],
      }],
    } }, "preset");
    await mutate("smart_tile.layer.create", { mapId: map.id, layerId: "ground", name: "Ground", presetId: "ground" }, "layer");
    const beforePainting = await readFile(mapPath);
    const projectBeforePainting = await readFile(manifestPath);
    const strokes = Array.from({ length: 217 }, (_, index) => ({
      patternId: `unit-${index}`, strokeId: `stroke-${index}`, phaseX: -index, phaseY: index,
      selection: { kind: "stamp", anchor: { x: index % 4, y: Math.floor(index / 4) % 4 } },
    }));
    const paintRevision = await call("pokemap_validate", { projectHandle: opened.projectHandle });
    const invalidPaint = await response("pokemap_plan", { projectHandle: opened.projectHandle, request: {
      requestId: "invalid-paint", actionId: "smart_tile.pattern.paint_batch", actionVersion: 1, workspaceHandle: opened.workspaceHandle,
      parameters: { mapId: map.id, layerId: "ground", strokes: [strokes[0], { ...strokes[1], patternId: "unknown" }] },
      expectedRevision: paintRevision.snapshotRevision, idempotencyKey: "invalid-paint" } });
    assert.equal(invalidPaint.isError, true);
    assert.deepEqual(await readFile(mapPath), beforePainting);
    const paint = await mutate("smart_tile.pattern.paint_batch", { mapId: map.id, layerId: "ground", strokes }, "paint-patterns");
    const paintReplay = await call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle,
      planId: paint.planned.planId, operationId: "paint-patterns" });
    assert.equal(record(paint.applied.receipt).receiptId, record(paintReplay.receipt).receiptId);
    assert.deepEqual(await readFile(manifestPath), projectBeforePainting);
    const painted = JSON.parse(await readFile(mapPath, "utf8")) as JsonRecord;
    assert.equal((record((painted.layers as JsonRecord[])[0]).patternStrokes as JsonRecord[]).length, 217);
    assert.deepEqual(painted.spatialScene, (JSON.parse(beforePainting.toString()) as JsonRecord).spatialScene);
    for (const id of ["smart_tile.layer.set_animation_activation", "smart_tile.layer.set_encounter_behavior", "campaign.encounter_table.upsert"]) {
      assert.ok((described.mutationActions as JsonRecord[]).some(value => value.id === id));
    }
    await mutate("smart_tile.preset.publish", { preset: {
      id: "grass-path", name: "Grass path", usage: "path", topology: "uniform", templateHint: "simple",
      coveragePolicy: "sparse", coverageProfile: { mode: "template" }, transformPolicy: {},
      defaultMaterialId: "grass", allowedMaterialIds: ["grass"], rules: [{
        id: "base", centerMatch: { kind: "material", materialId: "grass" }, signature: {},
        candidates: [{ id: "base", parts: baseCell.parts }],
      }],
    } }, "grass-preset");
    await mutate("smart_tile.layer.create", { mapId: map.id, layerId: "grass-path", name: "Grass path",
      presetId: "grass-path" }, "grass-layer");
    await mutate("campaign.encounter_table.upsert", { value: {
      id: "grass-table", name: "Grass", encounterKind: "walk", chancePerStep: 0.15,
      entries: [{ speciesId: "zubat", minLevel: 2, maxLevel: 4, weight: 1 }],
    } }, "grass-table");
    await mutate("smart_tile.layer.set_animation_activation", { mapId: map.id,
      layerId: "grass-path", activation: "on_enter" }, "grass-on-enter");
    await mutate("smart_tile.cell.paint", { mapId: map.id,
      layerId: "grass-path", materialId: "grass", cells: [{ x: 1, y: 1 }] }, "grass-paint");
    await mutate("smart_tile.layer.set_encounter_behavior", { mapId: map.id, layerId: "grass-path",
      materialId: "grass", priority: 0, encounterTableId: "grass-table", encounterKind: "walk" }, "grass-encounters");
    const configured = JSON.parse(await readFile(mapPath, "utf8")) as JsonRecord;
    const grass = (configured.layers as JsonRecord[]).find(layer => layer.id === "grass-path");
    assert.ok(grass);
    assert.equal(grass.usage, "path");
    assert.equal(grass.animationActivation, "on_enter");
    assert.equal(record(grass.encounterBehavior).materialId, "grass");
    assert.equal(record(record(grass.encounterBehavior).encounter).encounterTableId, "grass-table");
    assert.deepEqual(record(grass.field).semanticCells,
      Array.from({ length: 16 }, (_, index) => index === 5 ? 1 : 0));
    assert.deepEqual(configured.gameplayZones, painted.gameplayZones);
    await mutate("smart_tile.pattern.upsert_batch", { patterns: [{
      id: "grass-contour", name: "Grass contour", usage: "path", width: 2, height: 1, repeatMode: "tiled",
      cells: [{ x: 0, y: 0, parts: baseCell.parts }],
    }] }, "grass-contour");
    await mutate("smart_tile.pattern.paint_batch", { mapId: map.id, layerId: "grass-path", strokes: [{
      patternId: "grass-contour", strokeId: "grass-contour-stroke", materialId: "grass",
      selection: { kind: "stamp", anchor: { x: 2, y: 2 } },
    }] }, "grass-contour-paint");
    let currentGrass = (record(JSON.parse(await readFile(mapPath, "utf8"))).layers as JsonRecord[])
      .find(layer => layer.id === "grass-path");
    assert.ok(currentGrass);
    assert.deepEqual(record(currentGrass.field).semanticCells,
      Array.from({ length: 16 }, (_, index) => [5, 10].includes(index) ? 1 : 0));
    await mutate("smart_tile.pattern.erase", { mapId: map.id, layerId: "grass-path", clearMaterial: true,
      cells: [{ x: 2, y: 2 }] }, "grass-contour-erase");
    await mutate("smart_tile.cell.erase", { mapId: map.id, layerId: "grass-path",
      cells: [{ x: 1, y: 1 }] }, "grass-final-cell-erase");
    currentGrass = (record(JSON.parse(await readFile(mapPath, "utf8"))).layers as JsonRecord[])
      .find(layer => layer.id === "grass-path");
    assert.ok(currentGrass);
    assert.deepEqual(record(currentGrass.field).semanticCells, Array(16).fill(0));
    assert.deepEqual(currentGrass.encounterBehavior, grass.encounterBehavior);
    assert.equal(currentGrass.animationActivation, "on_enter");
    const eraseDescriptor = (described.mutationActions as JsonRecord[])
      .find(action => action.id === "smart_tile.pattern.erase");
    assert.ok(eraseDescriptor);
    assert.equal(record(eraseDescriptor.extensions).optionalClearMaterial, true);
    assert.equal(record(paintDescriptor.extensions).optionalPatternMaterial, true);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
    const reopened = await call("pokemap_workspace", { operation: "open", projectRoot });
    assert.equal((await call("pokemap_validate", { projectHandle: reopened.projectHandle })).valid, true);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: reopened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

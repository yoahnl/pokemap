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

test("live MCP publishes paints reopens and undoes native raster supports", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-raster-height-"));
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--artifact-root", root,
      "--dart", process.env.POKEMAP_TEST_DART ?? "dart"], cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "raster-height-proof", version: "1.0.0" });
  async function call(name: string, args: JsonRecord = {}): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: args });
    assert.equal(result.isError, undefined, JSON.stringify(result.structuredContent ?? result.content));
    return record(record(result.structuredContent).data);
  }
  let workspaceHandle: string | undefined;
  try {
    await client.connect(transport);
    const described = await call("pokemap_describe");
    for (const id of ["smart_tile.preset.publish", "smart_tile.pattern.upsert"]) {
      const action = (described.mutationActions as JsonRecord[]).find(value => value.id === id)!;
      const contract = record(record(action.extensions).rasterSpatialHeight);
      assert.equal(contract.minimumCatalogFormatVersion, 5);
      assert.equal(contract.relativeTo, "resolvedNativeGround");
      assert.equal(contract.preservesNavigation, true);
      assert.equal(contract.terrainSamplingMinimumCatalogFormatVersion, 7);
      assert.equal(contract.whenTerrainSamplingDisabled, "constantWorldHeight");
      const clipping = record(record(action.extensions).rasterSpatialClip);
      assert.equal(clipping.minimumCatalogFormatVersion, 6);
      assert.equal(clipping.preservesTextureDensity, true);
    }
    for (const id of ["smart_tile.cell.paint", "smart_tile.cell.paint_batch", "smart_tile.corner.paint", "smart_tile.pattern.paint", "smart_tile.pattern.paint_batch"]) {
      const action = (described.mutationActions as JsonRecord[]).find(value => value.id === id)!;
      assert.equal(record(action.extensions).materialPalettePolicy, "append_catalog_material_allowed_by_preset");
    }
    const request = { name: "Ground supports", folderName: "supports", parentPath: root,
      template: "empty", dimension: "threeD", mapWidth: 4, mapHeight: 4 };
    const preview = await call("pokemap_project_create_preview", { request });
    const created = await call("pokemap_project_create", { request, confirmation: preview.confirmation });
    const projectRoot = String(created.projectPath);
    let opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    let projectHandle = String(opened.projectHandle), serial = 0;
    workspaceHandle = String(opened.workspaceHandle);
    const manifestPath = join(projectRoot, "project.json");
    const manifest = record(JSON.parse(await readFile(manifestPath, "utf8")));
    const mapEntry = record((manifest.maps as unknown[])[0]);
    const mapId = String(mapEntry.id), mapPath = join(projectRoot, String(mapEntry.relativePath));
    async function mutate(actionId: string, parameters: JsonRecord): Promise<JsonRecord> {
      const current = await call("pokemap_validate", { projectHandle });
      const before = await readFile(mapPath), id = "height-" + serial++;
      const planned = await call("pokemap_plan", { projectHandle, request: { requestId: id,
        actionId, actionVersion: 1, workspaceHandle, parameters, expectedRevision: current.snapshotRevision, idempotencyKey: id } });
      assert.deepEqual(await readFile(mapPath), before);
      const applied = await call("pokemap_apply", { operation: "apply", projectHandle, planId: planned.planId, operationId: id });
      assert.equal(record(applied.receipt).status, "applied");
      return applied;
    }
    const image = join(root, "grass.png");
    await writeFile(image, Buffer.from("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=", "base64"));
    const staged = await call("pokemap_artifact_stage", { sourcePath: image, declaredMediaType: "image/png" });
    await mutate("tileset.import_image", { artifactHandle: staged.artifactHandle, tilesetId: "grass", name: "Grass", tileWidth: 1, tileHeight: 1 });
    await mutate("smart_tile.atlas.upsert", { atlas: { id: "atlas", name: "Grass", tilesetId: "grass", cellWidth: 1, cellHeight: 1, columns: 1, rows: 1 } });
    await mutate("smart_tile.material.upsert", { material: { id: "grass", name: "Grass", connectionGroupId: "grass" } });
    const parts = [0, -1, -2.5].map(spatialHeightOffset => ({
      source: { kind: "frame", frame: { atlasId: "atlas", column: 0, row: 0 } }, spatialHeightOffset,
      ...(spatialHeightOffset === -1 ? { spatialFollowTerrain: false } : {}),
      spatialClip: { left: 0, top: .0625, right: 1, bottom: 1 },
    }));
    await mutate("smart_tile.preset.publish", { preset: { id: "ground", name: "Ground", usage: "terrain",
      topology: "uniform", templateHint: "simple", coveragePolicy: "sparse", coverageProfile: { mode: "template" },
      transformPolicy: {}, defaultMaterialId: "grass", allowedMaterialIds: ["grass"],
      rules: [{ id: "grass", centerMatch: { kind: "material", materialId: "grass" }, candidates: [{ id: "supports", parts }] }],
    } });
    await mutate("smart_tile.pattern.upsert", { pattern: { id: "support", name: "Support", usage: "terrain",
      width: 1, height: 1, cells: [{ x: 0, y: 0, parts }] } });
    await mutate("smart_tile.layer.create", { mapId, layerId: "ground", name: "Ground", presetId: "ground" });
    await mutate("smart_tile.material.upsert", { material: { id: "relief", name: "Relief", connectionGroupId: "grass" } });
    const existing = record(JSON.parse(await readFile(manifestPath, "utf8")));
    const currentPreset = (record(existing.smartTileCatalog).presets as JsonRecord[]).find(value => value.id === "ground")!;
    await mutate("smart_tile.preset.publish", { preset: { ...currentPreset, allowedMaterialIds: ["grass", "relief"],
      rules: [...currentPreset.rules as unknown[], { id: "relief", centerMatch: { kind: "material", materialId: "relief" },
        candidates: [{ id: "relief", parts: [{ source: { kind: "frame", frame: { atlasId: "atlas", column: 0, row: 0 } }, spatialHeightOffset: -.125 }] }] }],
    } });
    const beforePaint = await readFile(mapPath);
    const originalLayer = (record(JSON.parse(beforePaint.toString())).layers as JsonRecord[]).find(value => value.id === "ground")!;
    assert.deepEqual(originalLayer.materialPalette, ["", "grass"]);
    await mutate("smart_tile.cell.paint_batch", { mapId, layerId: "ground", strokes: [
      { materialId: "grass", cells: [{ x: 1, y: 1 }, { x: 2, y: 1 }] },
      { materialId: "relief", cells: [{ x: 2, y: 2 }] },
    ] });
    const saved = await readFile(mapPath);
    const paintedLayer = (record(JSON.parse(saved.toString())).layers as JsonRecord[]).find(value => value.id === "ground")!;
    assert.deepEqual(paintedLayer.materialPalette, ["", "grass", "relief"]);
    assert.deepEqual(record(JSON.parse(saved.toString())).spatialScene, record(JSON.parse(beforePaint.toString())).spatialScene);
    await call("pokemap_workspace", { operation: "close", workspaceHandle }); workspaceHandle = undefined;
    opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    projectHandle = String(opened.projectHandle); workspaceHandle = String(opened.workspaceHandle);
    assert.deepEqual(await readFile(mapPath), saved);
    const loaded = record(JSON.parse(await readFile(manifestPath, "utf8")));
    const catalog = record(loaded.smartTileCatalog);
    assert.equal(catalog.formatVersion, 7);
    const preset = (catalog.presets as JsonRecord[]).find(value => value.id === "ground")!;
    const publishedParts = record((record((preset.rules as unknown[])[0]).candidates as unknown[])[0]).parts as JsonRecord[];
    assert.deepEqual(publishedParts.map(part => part.spatialHeightOffset ?? 0), [0, -1, -2.5]);
    assert.deepEqual(publishedParts.map(part => part.spatialFollowTerrain ?? true), [true, false, true]);
    assert.deepEqual(publishedParts.map(part => record(part.spatialClip).top), [.0625, .0625, .0625]);
    const pattern = (catalog.patterns as JsonRecord[]).find(value => value.id === "support")!;
    assert.deepEqual((record((pattern.cells as unknown[])[0]).parts as JsonRecord[]).map(part => part.spatialHeightOffset ?? 0), [0, -1, -2.5]);
    const history = await call("pokemap_history", { operation: "list", projectHandle, limit: 1 });
    await call("pokemap_history", { operation: "undo", projectHandle,
      entryId: record((history.entries as unknown[])[0]).entryId, idempotencyKey: "undo-height-paint" });
    assert.deepEqual(await readFile(mapPath), beforePaint);
    assert.equal((await call("pokemap_validate", { projectHandle })).valid, true);
  } finally {
    if (workspaceHandle) await call("pokemap_workspace", { operation: "close", workspaceHandle });
    await client.close(); await transport.close(); await rm(root, { recursive: true, force: true });
  }
});

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

test("live MCP paints reactive FRLG grass and preserves its terrain, clip and description after reopen", async () => {
  const root = await mkdtemp(join(tmpdir(), "frlg-tall-grass-mcp-"));
  const transport = new StdioClientTransport({
    command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root,
      "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe",
  });
  const client = new Client({ name: "frlg-grass-proof", version: "1.0.0" });
  async function call(name: string, args: JsonRecord = {}): Promise<JsonRecord> {
    const response = await client.callTool({ name, arguments: args });
    assert.equal(response.isError, undefined, JSON.stringify(response.structuredContent ?? response.content));
    return record(record(response.structuredContent).data);
  }
  try {
    await client.connect(transport);
    const described = await call("pokemap_describe");
    const preset = (described.resourceKinds as JsonRecord[]).find(kind => kind.id === "smartTilePreset");
    const actorOcclusion = record(record(preset?.extensions).actorOcclusion3d);
    assert.equal(actorOcclusion.capability, "map3d.actor-occlusion@1");
    assert.equal(actorOcclusion.channel, "actor_occlusion");
    assert.equal(actorOcclusion.encounters, false);
    assert.match(String(actorOcclusion.geometry), /anchored to the terrain cell; fixed during movement inside that cell/);
    const actions = new Set((described.mutationActions as JsonRecord[]).map(action => action.id));
    for (const id of ["smart_tile.layer.create", "smart_tile.cell.paint", "smart_tile.cell.erase",
      "smart_tile.animation.upsert", "smart_tile.layer.set_animation_activation", "resource.classify"]) {
      assert.ok(actions.has(id), id);
    }
    const request = { name: "FRLG grass proof", folderName: "game", parentPath: root,
      template: "empty", dimension: "twoD", mapWidth: 3, mapHeight: 3 };
    const preview = await call("pokemap_project_create_preview", { request });
    const created = await call("pokemap_project_create", { request, confirmation: preview.confirmation });
    const projectRoot = String(created.projectPath);
    let opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    let projectHandle = String(opened.projectHandle);
    let workspaceHandle = String(opened.workspaceHandle);
    const manifestPath = join(projectRoot, "project.json");
    const mapId = "grass-map";
    let mapPath = manifestPath;
    let sequence = 0;
    async function mutate(actionId: string, parameters: JsonRecord): Promise<void> {
      const validation = await call("pokemap_validate", { projectHandle });
      const before = await readFile(mapPath);
      const id = `grass-${sequence++}`;
      const planned = await call("pokemap_plan", { projectHandle, request: {
        requestId: id, actionId, actionVersion: 1, workspaceHandle, parameters,
        expectedRevision: validation.snapshotRevision, idempotencyKey: id,
      } });
      assert.deepEqual(await readFile(mapPath), before);
      const applied = await call("pokemap_apply", { operation: "apply", projectHandle,
        planId: planned.planId, operationId: `apply-${id}` });
      assert.equal(record(applied.receipt).status, "applied");
    }
    async function map(): Promise<JsonRecord> {
      const result = await call("pokemap_query", { projectHandle, resourceKind: "map",
        operation: "batch_get", ids: [mapId], view: "detail" });
      return record((result.items as unknown[])[0]);
    }
    function layer(current: JsonRecord, id: string): JsonRecord {
      const found = (current.layers as JsonRecord[]).find(candidate => candidate.id === id);
      assert.ok(found, id);
      return found;
    }
    await mutate("map.create", { mapId, name: "Hautes herbes", width: 3, height: 3 });
    const initialManifest = record(JSON.parse(await readFile(manifestPath, "utf8")));
    const mapEntry = (initialManifest.maps as JsonRecord[]).find(entry => entry.id === mapId)!;
    mapPath = join(projectRoot, String(mapEntry.relativePath));
    const imagePath = join(root, "synthetic.png");
    await writeFile(imagePath, Buffer.from(
      "iVBORw0KGgoAAAANSUhEUgAAAAcAAAABCAYAAAASC7TOAAAAHklEQVR4nBXGQQ0AAAgAIaIbxabn/DBEjUrv14rpAPMgEBMjGNwaAAAAAElFTkSuQmCC", "base64"));
    const staged = await call("pokemap_artifact_stage", { sourcePath: imagePath, declaredMediaType: "image/png" });
    await mutate("tileset.import_image", { artifactHandle: staged.artifactHandle,
      tilesetId: "atlas", name: "Synthetic test atlas", tileWidth: 1, tileHeight: 1 });
    await mutate("smart_tile.atlas.upsert", { atlas: { id: "atlas", name: "Atlas",
      tilesetId: "atlas", cellWidth: 1, cellHeight: 1, columns: 7, rows: 1 } });
    for (const id of ["terrain", "grass"]) {
      await mutate("smart_tile.material.upsert", { material: { id, name: id, connectionGroupId: id,
        ...(id === "grass" ? { pathSurfaceKind: "tall_grass" } : {}) } });
    }
    const frames = [1, 2, 3, 4, 0].map((column, index) => ({
      frame: { atlasId: "atlas", column, row: 0, columnSpan: 1, rowSpan: 1 }, durationMs: [167, 166, 167, 167, 166][index],
    }));
    await mutate("smart_tile.animation.upsert", { animation: { id: "entry", name: "Herbe au passage",
      loop: "once", sync: "global", frames } });
    for (const id of ["terrain", "grass"]) {
      await mutate("smart_tile.preset.publish", { preset: { id, name: id,
        usage: id === "grass" ? "path" : "terrain", topology: "uniform", templateHint: "simple",
        coveragePolicy: id === "grass" ? "sparse" : "complete", coverageProfile: { mode: "template" },
        transformPolicy: {}, defaultMaterialId: id, allowedMaterialIds: [id],
        rules: [{ id, centerMatch: { kind: "material", materialId: id }, candidates: [{ id,
          parts: [{ source: { kind: "frame", frame: { atlasId: "atlas", column: id === "grass" ? 5 : 6, row: 0 } } },
            ...(id === "grass" ? [{ source: { kind: "animation", animationId: "entry" }, channel: "actor_occlusion" }] : [])],
        }] }],
      } });
      await mutate("smart_tile.layer.create", { mapId, presetId: id, layerId: id, name: id, insertIndex: 0 });
    }
    const description = "Hautes herbes à dessiner ; animation au passage, terrain conservé.";
    await mutate("resource.classify", { resourceKind: "smartTilePreset", resourceId: "grass",
      familyId: "vegetation", placementContext: "exterior", role: "standard", description });
    const untouched = await map();
    const terrain = layer(untouched, "terrain");
    assert.equal(layer(untouched, "grass").animationActivation, "on_enter");
    assert.equal(layer(untouched, "grass").encounterBehavior, undefined);
    await mutate("smart_tile.cell.paint", { mapId, layerId: "grass", materialId: "grass",
      selection: { kind: "rectangle", start: { x: 0, y: 0 }, end: { x: 1, y: 1 } } });
    assert.deepEqual(record(layer(await map(), "grass").field).semanticCells, [1, 1, 0, 1, 1, 0, 0, 0, 0]);
    await mutate("smart_tile.cell.erase", { mapId, layerId: "grass", cells: [{ x: 0, y: 0 }] });
    await mutate("smart_tile.layer.set_animation_activation", { mapId, layerId: "grass", activation: "always" });
    await mutate("smart_tile.cell.paint", { mapId, layerId: "grass", materialId: "grass", cells: [{ x: 0, y: 0 }] });
    assert.equal(layer(await map(), "grass").animationActivation, "always");
    await mutate("smart_tile.layer.set_animation_activation", { mapId, layerId: "grass", activation: "on_enter" });
    await mutate("smart_tile.cell.erase", { mapId, layerId: "grass", cells: [{ x: 0, y: 0 }] });
    const beforeClose = await readFile(mapPath);
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
    opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    projectHandle = String(opened.projectHandle); workspaceHandle = String(opened.workspaceHandle);
    const reopened = await map();
    assert.deepEqual(await readFile(mapPath), beforeClose);
    assert.deepEqual(layer(reopened, "terrain"), terrain);
    assert.deepEqual(record(layer(reopened, "grass").field).semanticCells, [0, 1, 0, 1, 1, 0, 0, 0, 0]);
    assert.equal(layer(reopened, "grass").animationActivation, "on_enter");
    assert.equal(layer(reopened, "grass").encounterBehavior, undefined);
    const manifest = record(JSON.parse(await readFile(manifestPath, "utf8")));
    const catalog = record(manifest.smartTileCatalog);
    const animation = (catalog.animations as JsonRecord[]).find(candidate => candidate.id === "entry")!;
    assert.deepEqual(animation.frames, frames);
    assert.equal(animation.loop, "once");
    const library = record(manifest.resourceLibraryCatalog);
    const entry = (library.entries as JsonRecord[]).find(candidate => candidate.resourceId === "grass")!;
    assert.equal(entry.description, description);
    assert.equal(entry.placementContext, "exterior");
    assert.equal(record((await call("pokemap_validate", { projectHandle })).structure).valid, true);
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

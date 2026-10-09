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

test("live MCP creates a layer in a catalog that previously exceeded the SDK read buffer", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-layer-catalog-mcp-"));
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "120000"],
    cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "smart-tile-layer-catalog-proof", version: "1.0.0" });
  const transportErrors: string[] = [];
  let stderr = "";
  client.onerror = error => transportErrors.push(String(error));
  transport.stderr?.on("data", chunk => { stderr += String(chunk); });
  let maximumResponseBytes = 0;
  async function call(name: string, args: JsonRecord = {}): Promise<JsonRecord> {
    let result;
    try {
      result = await client.callTool({ name, arguments: args }, { timeout: 125000 });
    } catch (error) {
      throw new Error(`${String(error)}; transport: ${transportErrors.join(" | ")}; stderr: ${stderr}`);
    }
    maximumResponseBytes = Math.max(maximumResponseBytes, Buffer.byteLength(JSON.stringify(result), "utf8"));
    assert.equal(result.isError, undefined, JSON.stringify(result.structuredContent));
    return record(record(result.structuredContent).data);
  }
  try {
    await client.connect(transport);
    const described = await call("pokemap_describe");
    const descriptor = (described.mutationActions as JsonRecord[]).find(value => value.id === "smart_tile.layer.create")!;
    assert.equal(record(descriptor.extensions).diffProjection, "semantic_catalog_binding");
    assert.equal(record(descriptor.extensions).maximumInlineCatalogDiffByteLength, 64 * 1024);
    maximumResponseBytes = 0;
    const request = { name: "Large layer catalog", folderName: "catalog", parentPath: root,
      template: "empty", dimension: "threeD", mapWidth: 4, mapHeight: 4 };
    const preview = await call("pokemap_project_create_preview", { request });
    const created = await call("pokemap_project_create", { request, confirmation: preview.confirmation });
    const projectRoot = String(created.projectPath);
    const initial = await call("pokemap_workspace", { operation: "open", projectRoot });
    const image = join(root, "ground.png");
    await writeFile(image, Buffer.from("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=", "base64"));
    const staged = await call("pokemap_artifact_stage", { sourcePath: image, declaredMediaType: "image/png" });
    const validation = await call("pokemap_validate", { projectHandle: initial.projectHandle });
    const imagePlan = await call("pokemap_plan", { projectHandle: initial.projectHandle, request: {
      requestId: "image", actionId: "tileset.import_image", actionVersion: 1, workspaceHandle: initial.workspaceHandle,
      parameters: { artifactHandle: staged.artifactHandle, tilesetId: "ground-image", name: "Ground", tileWidth: 1, tileHeight: 1 },
      expectedRevision: validation.snapshotRevision, idempotencyKey: "image" } });
    await call("pokemap_apply", { operation: "apply", projectHandle: initial.projectHandle, planId: imagePlan.planId, operationId: "image" });
    await call("pokemap_workspace", { operation: "close", workspaceHandle: initial.workspaceHandle });
    const manifestPath = join(projectRoot, "project.json");
    const manifest = JSON.parse(await readFile(manifestPath, "utf8")) as JsonRecord;
    const map = record((manifest.maps as JsonRecord[])[0]);
    const mapPath = join(projectRoot, String(map.relativePath));
    const ids = Array.from({ length: 10000 }, (_, i) => `material-${i}`);
    const slots = ["northWestCorner", "northEdge", "northEastCorner", "eastEdge", "southEastCorner", "southEdge", "southWestCorner", "westEdge"];
    const preset = { id: "large-preset", name: "Large", usage: "terrain", topology: "uniform", status: "published",
      defaultMaterialId: ids[0], allowedMaterialIds: ids, coveragePolicy: "complete",
      coverageProfile: { mode: "explicit", allowFallback: false, requiredScenarios: ids.map(id => ({ id: `scenario-${id}`, centerMaterialId: id,
        signature: Object.fromEntries(slots.map(slot => [slot, null])) })) }, transformPolicy: {},
      rules: ids.map(id => ({ id: `rule-${id}`, centerMatch: { kind: "material", materialId: id }, signature: Object.fromEntries(slots.map(slot => [slot, { kind: "any" }])),
        candidates: [{ id: `candidate-${id}`, label: "", weight: 1, parts: [{ source: { kind: "frame", frame: { atlasId: "atlas", column: 0, row: 0, columnSpan: 1, rowSpan: 1 } },
          transform: { quarterTurns: 0, flipX: false }, channel: "ground", frameSampling: "full_frame", offsetUnit: "pixel", offsetX: 0, offsetY: 0,
          footprintWidth: 1, footprintHeight: 1, anchorX: 0, anchorY: 0, drawOrder: 0 }] }] })) };
    manifest.smartTileCatalog = { formatVersion: 4, categories: [], atlases: [{ id: "atlas", name: "Atlas", tilesetId: "ground-image", cellWidth: 1, cellHeight: 1, columns: 1, rows: 1 }],
      materials: ids.map(id => ({ id, name: id, connectionGroupId: "ground", categoryId: "", terrainType: null, pathSurfaceKind: null, isEmpty: false, sortOrder: 0, editorColorArgb: null })),
      presets: Array.from({ length: 3 }, (_, i) => {
        const start = i * 3500;
        const allowed = ids.slice(start, start + 3500);
        return { ...preset, id: i === 0 ? preset.id : `${preset.id}-${i}`,
          defaultMaterialId: allowed[0], allowedMaterialIds: allowed,
          coverageProfile: { ...preset.coverageProfile, requiredScenarios: preset.coverageProfile.requiredScenarios.slice(start, start + 3500) },
          rules: preset.rules.slice(start, start + 3500) };
      }), patterns: [], animations: [], drafts: [] };
    await writeFile(manifestPath, JSON.stringify(manifest));
    const before = await readFile(manifestPath);
    const mapBefore = await readFile(mapPath);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    const valid = await call("pokemap_validate", { projectHandle: opened.projectHandle });
    const planned = await call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
      requestId: "layer", actionId: "smart_tile.layer.create", actionVersion: 1, workspaceHandle: opened.workspaceHandle,
      parameters: { mapId: map.id, presetId: preset.id, layerId: "large-terrain", name: "Terrain" }, expectedRevision: valid.snapshotRevision, idempotencyKey: "layer" } });
    assert.ok(Buffer.byteLength(JSON.stringify(planned), "utf8") < 64 * 1024);
    assert.deepEqual(await readFile(manifestPath), before);
    assert.deepEqual(await readFile(mapPath), mapBefore);
    const plan = record(planned.plan);
    assert.deepEqual((record(plan.changeSet).changes as JsonRecord[]).map(change => record(change.resource).kind), ["map"]);
    assert.equal(record(plan.preview).manifestChanged, false);
    const applied = await call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle, planId: planned.planId, operationId: "layer" });
    const replay = await call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle, planId: planned.planId, operationId: "layer" });
    assert.equal(record(applied.receipt).receiptId, record(replay.receipt).receiptId);
    assert.deepEqual(await readFile(manifestPath), before);
    const saved = JSON.parse(await readFile(mapPath, "utf8")) as JsonRecord;
    const layer = (saved.layers as JsonRecord[]).find(item => item.id === "large-terrain")!;
    assert.equal(layer.presetId, preset.id);
    assert.deepEqual((layer.materialPalette as string[]).slice(1), ids.slice(0, 3500));
    assert.ok(maximumResponseBytes < 64 * 1024);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

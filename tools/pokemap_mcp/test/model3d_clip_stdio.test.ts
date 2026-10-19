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

function glb(animated = false): Buffer {
  const document: JsonRecord = { asset: { version: "2.0" }, scene: 0,
    scenes: [{ nodes: [0] }], nodes: [{ mesh: 0 }],
    meshes: [{ primitives: [{ attributes: { POSITION: 0 } }] }],
    buffers: [{ byteLength: animated ? 68 : 36 }],
    bufferViews: [{ buffer: 0, byteLength: 36 }],
    accessors: [{ bufferView: 0, componentType: 5126, count: 3, type: "VEC3" }] };
  if (animated) {
    (document.bufferViews as JsonRecord[]).push({ buffer: 0, byteOffset: 36, byteLength: 8 }, { buffer: 0, byteOffset: 44, byteLength: 24 });
    (document.accessors as JsonRecord[]).push({ bufferView: 1, componentType: 5126, count: 2, type: "SCALAR" },
      { bufferView: 2, componentType: 5126, count: 2, type: "VEC3" });
    document.animations = [{ name: "Motion", samplers: [{ input: 1, output: 2, interpolation: "LINEAR" }],
      channels: [{ sampler: 0, target: { node: 0, path: "translation" } }] }];
  }
  const json = Buffer.from(JSON.stringify(document)), length = Math.ceil(json.length / 4) * 4;
  const binary = Buffer.alloc(animated ? 68 : 36);
  [-.5, 0, -.5, .5, 0, -.5, -.5, 0, .5].forEach((v, i) => binary.writeFloatLE(v, i * 4));
  if (animated) { binary.writeFloatLE(1, 40); binary.writeFloatLE(.5, 56); }
  const bytes = Buffer.alloc(28 + length + binary.length);
  bytes.writeUInt32LE(0x46546c67, 0); bytes.writeUInt32LE(2, 4); bytes.writeUInt32LE(bytes.length, 8);
  bytes.writeUInt32LE(length, 12); bytes.writeUInt32LE(0x4e4f534a, 16);
  bytes.fill(32, 20, 20 + length); json.copy(bytes, 20);
  bytes.writeUInt32LE(binary.length, 20 + length); bytes.writeUInt32LE(0x004e4942, 24 + length);
  binary.copy(bytes, 28 + length);
  return bytes;
}

test("live MCP reopens clipped and fixed-height whole models and rejects animated clipped replacements", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-model-clip-"));
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--artifact-root", root,
      "--dart", process.env.POKEMAP_TEST_DART ?? "dart", "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "static-model-clip-proof", version: "1.0.0" });
  async function call(name: string, args: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const response = await client.callTool({ name, arguments: args });
    assert.equal(response.isError, failure ? true : undefined, JSON.stringify(response.structuredContent ?? response.content));
    const envelope = record(response.structuredContent);
    return record(failure ? envelope.error : envelope.data);
  }
  try {
    await client.connect(transport);
    const described = await call("pokemap_describe");
    const descriptor = (described.mutationActions as JsonRecord[]).find(a => a.id === "smart_tile.pattern.upsert");
    assert.ok(descriptor);
    assert.equal(record(record(descriptor.extensions).model3dSpatialClip).minimumCatalogFormatVersion, 9);
    assert.equal(record(descriptor.extensions).model3dTerrainSample, "unclipped_final_anchor");
    assert.equal(record(record(descriptor.extensions).model3dSpatialClip).terrainSampling, "visible_clip_support_center");
    assert.deepEqual(record(record(descriptor.extensions).model3dSpatialClip).channels, ["ground", "understory", "canopy"]);
    assert.equal(record(record(descriptor.extensions).model3dSpatialClip).boundaryOwnership, "closed_rectangle_preserves_isolated_outer_faces");
    const request = { name: "Static clipping", folderName: "game", parentPath: root,
      template: "empty", dimension: "threeD", mapWidth: 8, mapHeight: 8 };
    const preview = await call("pokemap_project_create_preview", { request });
    const created = await call("pokemap_project_create", { request, confirmation: preview.confirmation });
    const projectRoot = String(created.projectPath), projectPath = join(projectRoot, "project.json");
    let opened = await call("pokemap_workspace", { operation: "open", projectRoot }), serial = 0;
    async function plan(actionId: string, parameters: JsonRecord, failure = false) {
      const validated = await call("pokemap_validate", { projectHandle: opened.projectHandle }), id = "clip-" + serial++;
      return call("pokemap_plan", { projectHandle: opened.projectHandle, request: { requestId: id,
        actionId, actionVersion: 1, workspaceHandle: opened.workspaceHandle, parameters,
        expectedRevision: validated.snapshotRevision, idempotencyKey: id } }, failure);
    }
    async function mutate(actionId: string, parameters: JsonRecord) {
      const planned = await plan(actionId, parameters);
      await call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle,
        planId: planned.planId, operationId: "apply-" + serial++ });
    }
    const sourcePath = join(root, "static.glb"), animatedPath = join(root, "animated.glb");
    await writeFile(sourcePath, glb()); await writeFile(animatedPath, glb(true));
    const staged = await call("pokemap_artifact_stage", { sourcePath, declaredMediaType: "model/gltf-binary" });
    await mutate("model3d.import", { modelId: "unit", name: "Static unit", artifactHandle: staged.artifactHandle });
    await mutate("smart_tile.material.upsert", { material: { id: "clip", name: "Clip", connectionGroupId: "clip" } });
    const clip = { left: 0, top: 0, right: .5, bottom: 1 };
    const part = { source: { kind: "model3d", modelId: "unit", followTerrain: false }, spatialClip: clip, channel: "canopy" };
    await mutate("smart_tile.preset.publish", { preset: { id: "clip", name: "Clip", usage: "path", topology: "uniform",
      templateHint: "simple", coveragePolicy: "sparse", coverageProfile: { mode: "template" },
      transformPolicy: {}, defaultMaterialId: "clip", allowedMaterialIds: ["clip"], rules: [{ id: "unit",
        centerMatch: { kind: "material", materialId: "clip" }, candidates: [{ id: "unit", parts: [part] }] }] } });
    const project = record(JSON.parse(await readFile(projectPath, "utf8")));
    const map = record((project.maps as JsonRecord[])[0]), mapId = String(map.id);
    const mapPath = join(projectRoot, String(map.relativePath));
    await mutate("smart_tile.layer.create", { mapId, layerId: "clipped", name: "Clipped models", presetId: "clip" });
    await mutate("smart_tile.pattern.upsert", { pattern: { id: "half", name: "Half", usage: "path", width: 1, height: 1,
      repeatMode: "stamp", cells: [{ x: 0, y: 0, parts: [part] }] } });
    await mutate("smart_tile.pattern.paint", { mapId, layerId: "clipped", patternId: "half", strokeId: "half",
      selection: { kind: "stamp", anchor: { x: 2, y: 2 } } });
    const fixedPart = { source: { kind: "model3d", modelId: "unit", followTerrain: false, offsetY: -1.125 },
      channel: "canopy", footprintWidth: 3, footprintHeight: 3 };
    await mutate("smart_tile.pattern.upsert", { pattern: { id: "fixed-whole", name: "Fixed whole", usage: "path",
      width: 3, height: 3, repeatMode: "stamp", clippingPolicy: "reject", cells: [{ x: 0, y: 0, parts: [fixedPart] }] } });
    await mutate("smart_tile.pattern.paint", { mapId, layerId: "clipped", patternId: "fixed-whole", strokeId: "fixed-whole",
      selection: { kind: "stamp", anchor: { x: 4, y: 4 } } });
    const saved = await readFile(projectPath), savedMap = await readFile(mapPath);
    const raw = record(JSON.parse(saved.toString()));
    assert.equal(record(raw.smartTileCatalog).formatVersion, 9);
    const pattern = record((record(raw.smartTileCatalog).patterns as JsonRecord[]).find(p => p.id === "half"));
    const cell = record((pattern.cells as JsonRecord[])[0]);
    assert.deepEqual(record((cell.parts as JsonRecord[])[0]).spatialClip, clip);
    assert.equal(record((cell.parts as JsonRecord[])[0]).channel, "canopy");
    const fixedPattern = record((record(raw.smartTileCatalog).patterns as JsonRecord[]).find(p => p.id === "fixed-whole"));
    const fixedCell = record((fixedPattern.cells as JsonRecord[])[0]);
    const fixedSavedPart = record((fixedCell.parts as JsonRecord[])[0]);
    assert.equal(record(fixedSavedPart.source).followTerrain, false);
    assert.equal(record(fixedSavedPart.source).offsetY, -1.125);
    assert.equal(fixedSavedPart.spatialClip, undefined);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
    opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    assert.equal((await call("pokemap_validate", { projectHandle: opened.projectHandle })).valid, true);
    assert.deepEqual(await readFile(projectPath), saved); assert.deepEqual(await readFile(mapPath), savedMap);
    for (const actionId of ["model3d.source.replace", "model3d.source.replace_batch"]) {
      const replacement = await call("pokemap_artifact_stage", { sourcePath: animatedPath, declaredMediaType: "model/gltf-binary" });
      const entry = { modelId: "unit", artifactHandle: replacement.artifactHandle };
      await plan(actionId, actionId.endsWith("_batch") ? { models: [entry] } : entry, true);
      assert.deepEqual(await readFile(projectPath), saved); assert.deepEqual(await readFile(mapPath), savedMap);
      assert.deepEqual(await readFile(join(projectRoot, "assets/models3d/unit.glb")), glb());
    }
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close(); await transport.close(); await rm(root, { recursive: true, force: true });
  }
});

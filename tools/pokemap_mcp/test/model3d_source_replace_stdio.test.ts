import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import test from "node:test";
import { promisify } from "node:util";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

function glb(animated: boolean, animationCount = 1, width = 1): Buffer {
  const binary = Buffer.alloc(animated ? 68 : 36);
  [0, 0, 0, width, 0, 0, 0, 1, 0].forEach((value, index) =>
    binary.writeFloatLE(value, index * 4));
  if (animated) {
    binary.writeFloatLE(2, 40);
    binary.writeFloatLE(1, 56);
  }
  const document = {
    asset: { version: "2.0" }, scene: 0,
    scenes: [{ nodes: [0] }], nodes: [{ mesh: 0 }],
    meshes: [{ primitives: [{ attributes: { POSITION: 0 } }] }],
    buffers: [{ byteLength: binary.length }],
    bufferViews: [{ buffer: 0, byteLength: 36 }, ...(animated ? [
      { buffer: 0, byteOffset: 36, byteLength: 8 },
      { buffer: 0, byteOffset: 44, byteLength: 24 },
    ] : [])],
    accessors: [{ bufferView: 0, componentType: 5126, count: 3,
      type: "VEC3", min: [0, 0, 0], max: [width, 1, 0] }, ...(animated ? [
      { bufferView: 1, componentType: 5126, count: 2, type: "SCALAR" },
      { bufferView: 2, componentType: 5126, count: 2, type: "VEC3" },
    ] : [])],
    ...(animated ? { animations: Array.from({ length: animationCount }, (_, index) => ({
      name: index === 0 ? "Wind" : "Close", samplers: [{ input: 1, output: 2 }],
      channels: [{ sampler: 0, target: { node: 0, path: "translation" } }],
    })) } : {}),
  };
  const json = Buffer.from(JSON.stringify(document));
  const jsonLength = Math.ceil(json.length / 4) * 4;
  const output = Buffer.alloc(28 + jsonLength + binary.length);
  output.writeUInt32LE(0x46546c67, 0);
  output.writeUInt32LE(2, 4);
  output.writeUInt32LE(output.length, 8);
  output.writeUInt32LE(jsonLength, 12);
  output.writeUInt32LE(0x4e4f534a, 16);
  output.fill(32, 20, 20 + jsonLength);
  json.copy(output, 20);
  output.writeUInt32LE(binary.length, 20 + jsonLength);
  output.writeUInt32LE(0x004e4942, 24 + jsonLength);
  binary.copy(output, 28 + jsonLength);
  return output;
}

test("live MCP replaces an inspected model source and restores it without changing identity", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-model-source-mcp-"));
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "model3d-source-transport-proof", version: "1.0.0" });
  async function call(name: string, args: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: args });
    assert.equal(result.isError, failure ? true : undefined, JSON.stringify(result.structuredContent));
    const envelope = record(result.structuredContent);
    return record(failure ? envelope.error : envelope.data);
  }
  try {
    await client.connect(transport);
    const described = await call("pokemap_describe");
    const smartTileDescriptor = (described.mutationActions as JsonRecord[])
      .find((action) => action.id === "smart_tile.pattern.upsert")!;
    const modelSchema = record(record(smartTileDescriptor.extensions).model3dVisualSourceSchema);
    assert.equal(record(record(modelSchema.properties).replacesGround).default, false);
    assert.equal(record(smartTileDescriptor.extensions).model3dGroundReplacement,
      "source_cell_below_or_equal_layer");
    const descriptor = (described.mutationActions as JsonRecord[])
      .find((action) => action.id === "model3d.source.replace")!;
    assert.ok(descriptor);
    assert.ok((descriptor.guarantees as string[]).includes("revision_checked"));
    assert.ok(!(descriptor.guarantees as string[]).includes("atomic"));
    const schema = record(record(descriptor.extensions).inputSchema);
    assert.deepEqual(schema.required, ["modelId", "artifactHandle"]);
    assert.equal(schema.additionalProperties, false);
    const batchDescriptor = (described.mutationActions as JsonRecord[])
      .find((action) => action.id === "model3d.source.replace_batch")!;
    assert.ok(batchDescriptor);
    assert.equal(record(batchDescriptor.extensions).maximumModelCount, 50);
    assert.equal(record(batchDescriptor.extensions).maximumTotalByteLength, 64 << 20);
    assert.deepEqual(record(record(batchDescriptor.extensions).inputSchema).required, ["models"]);
    for (const action of [descriptor, batchDescriptor]) {
      assert.deepEqual(record(action.extensions).sourceReplacementScope, {
        requestExtension: "sourceReplacementScope", values: ["local", "project"],
        catalogDefault: "local",
        localContract: "preserve_static_and_existing_animation_indices_and_durations",
        projectScope: "explicit_full_project_usage_validation",
      });
    }
    const configureDescriptor = (described.mutationActions as JsonRecord[])
      .find((action) => action.id === "model3d.configure")!;
    const configureSchema = record(record(configureDescriptor.extensions).inputSchema);
    const collisionSchema = record(record(configureSchema.properties).collisionBounds);
    assert.deepEqual(collisionSchema.type, ["object", "null"]);
    assert.equal(record(record(configureSchema.properties).blocksMovementByDefault).type, "boolean");
    const modelKind = (described.resourceKinds as JsonRecord[]).find(kind => kind.id === "model3d")!;
    assert.equal(record(record(modelKind.extensions).blocksMovementByDefault).default, true);
    const request = { name: "Model replacement", folderName: "models", parentPath: root,
      template: "empty", dimension: "threeD", mapWidth: 8, mapHeight: 6 };
    const preview = await call("pokemap_project_create_preview", { request });
    const created = await call("pokemap_project_create", { request, confirmation: preview.confirmation });
    const projectRoot = String(created.projectPath);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    const projectHandle = String(opened.projectHandle);
    await call("pokemap_workshop", { operation: "prepare", projectHandle });
    let sequence = 0;
    async function stage(bytes: Buffer): Promise<string> {
      const path = join(root, `candidate-${sequence++}.glb`);
      await writeFile(path, bytes);
      return String((await call("pokemap_artifact_stage", {
        sourcePath: path, declaredMediaType: "model/gltf-binary" })).artifactHandle);
    }
    async function plan(actionId: string, parameters: JsonRecord, failure = false): Promise<JsonRecord> {
      const validation = await call("pokemap_validate", { projectHandle });
      const id = `model-source-${sequence++}`;
      return call("pokemap_plan", { projectHandle, request: {
        requestId: id, actionId, actionVersion: 1,
        workspaceHandle: opened.workspaceHandle, parameters,
        expectedRevision: validation.snapshotRevision, idempotencyKey: id } }, failure);
    }
    async function apply(planned: JsonRecord): Promise<JsonRecord> {
      return call("pokemap_apply", { operation: "apply", projectHandle,
        planId: planned.planId, operationId: `model-source-apply-${sequence++}` });
    }
    const beforeBytes = glb(false);
    const afterBytes = glb(true);
    await apply(await plan("model3d.import", { modelId: "house", name: "Maison",
      artifactHandle: await stage(beforeBytes) }));
    await apply(await plan("model3d.import", { modelId: "tree", name: "Arbre",
      artifactHandle: await stage(afterBytes) }));
    const collisionBounds = { min: { x: .1, y: 0, z: .1 }, max: { x: .4, y: 1, z: .4 } };
    for (const invalid of [null, 0, "false", {}]) {
      await plan("model3d.configure", { modelId: "house", blocksMovementByDefault: invalid }, true);
    }
    await apply(await plan("model3d.configure", { modelId: "house", name: "Maison gardée",
      scale: 2.5, pivot: { x: 1, y: 2, z: -3 }, collisionBounds, blocksMovementByDefault: false }));
    for (const unchanged of [
      { modelId: "tree", blocksMovementByDefault: true },
      { modelId: "house", blocksMovementByDefault: false },
      { modelId: "house", name: "Maison gardée", scale: 2.5,
        pivot: { x: 1, y: 2, z: -3 }, collisionBounds, blocksMovementByDefault: false },
    ]) {
      const noOp = await plan("model3d.configure", unchanged);
      assert.equal(noOp.applicable, false);
      assert.equal(noOp.nonApplicableReason, "no_changes");
      const projected = record(noOp.plan);
      assert.equal(record(projected.preview).noOp, true);
      assert.deepEqual(record(projected.changeSet).changes, []);
    }
    const manifestPath = join(projectRoot, "project.json");
    const initialManifest = record(JSON.parse((await readFile(manifestPath)).toString()));
    const mapId = String(record((initialManifest.maps as JsonRecord[])[0]).id);
    await apply(await plan("smart_tile.material.upsert", { material: {
      id: "grass", name: "Grass", connectionGroupId: "grass",
    } }));
    await apply(await plan("smart_tile.preset.publish", { preset: {
      id: "grass-path", name: "Grass", usage: "path", topology: "uniform",
      templateHint: "simple", coveragePolicy: "complete",
      coverageProfile: { mode: "template" }, transformPolicy: {},
      defaultMaterialId: "grass", allowedMaterialIds: ["grass"],
      rules: [{ id: "grass", centerMatch: { kind: "material", materialId: "grass" },
        candidates: [{ id: "grass", parts: [{ source: {
          kind: "model3d", modelId: "tree", scale: .75, offsetY: .125,
          animationIndex: 0,
        } }] }] }],
    }, layer: { mapId, layerId: "grass", name: "Grass" } }));
    await apply(await plan("smart_tile.cell.paint", {
      mapId, layerId: "grass", materialId: "grass", cells: [{ x: 2, y: 2 }],
    }));
    const savedManifest = record(JSON.parse((await readFile(manifestPath)).toString()));
    const grassPreset = record((record(savedManifest.smartTileCatalog).presets as JsonRecord[])[0]);
    const grassPart = record((record((record((grassPreset.rules as JsonRecord[])[0]).candidates as JsonRecord[])[0]).parts as JsonRecord[])[0]);
    assert.deepEqual(grassPart.source, { modelId: "tree", scale: .75, offsetX: 0, offsetY: .125, offsetZ: 0, animationIndex: 0, followTerrain: true, replacesGround: false, kind: "model3d" });
    const savedMap = record(JSON.parse((await readFile(join(projectRoot, "maps", `${mapId}.json`))).toString()));
    const grassLayer = record((savedMap.layers as JsonRecord[]).find(layer => layer.id === "grass"));
    assert.equal((record(grassLayer.field).semanticCells as number[])[2 * 8 + 2], 1);
    const mapPath = join(projectRoot, "maps", `${mapId}.json`);
    await apply(await plan("smart_tile.pattern.upsert", { pattern: {
      id: "grass-edge", name: "Grass edge", usage: "path", width: 1, height: 1,
      repeatMode: "tiled", cells: [{ x: 0, y: 0, parts: [{ source: {
        kind: "model3d", modelId: "tree", scale: .75, offsetY: .5,
        animationIndex: 0, followTerrain: true, replacesGround: true,
      } }] }],
    } }));
    await apply(await plan("smart_tile.pattern.paint", {
      mapId, layerId: "grass", patternId: "grass-edge", strokeId: "edges",
      selection: { kind: "rectangle", start: { x: 2, y: 2 }, end: { x: 3, y: 2 } },
    }));
    const patternedManifest = record(JSON.parse(await readFile(manifestPath, "utf8")));
    const savedPattern = (record(patternedManifest.smartTileCatalog).patterns as JsonRecord[])
      .find((pattern) => pattern.id === "grass-edge")!;
    const savedPatternPart = record((record((savedPattern.cells as JsonRecord[])[0]).parts as JsonRecord[])[0]);
    assert.equal(record(savedPatternPart.source).replacesGround, true);
    const patternedBytes = await readFile(mapPath);
    for (const actionId of ["smart_tile.cell.erase", "smart_tile.cell.paint",
      "smart_tile.cell.paint_batch"]) {
      const cells = [{ x: 2, y: 2 }];
      await apply(await plan(actionId, { mapId, layerId: "grass",
        ...(actionId === "smart_tile.cell.paint_batch"
          ? { strokes: [{ materialId: "grass", cells }] }
          : { cells, ...(actionId === "smart_tile.cell.paint" ? { materialId: "grass" } : {}) }),
      }));
      const changed = record(JSON.parse(await readFile(mapPath, "utf8")));
      const layer = (changed.layers as JsonRecord[]).find(value => value.id === "grass")!;
      assert.deepEqual(record((layer.patternStrokes as JsonRecord[])[0]).cells, [{ x: 3, y: 2 }]);
      const recent = await call("pokemap_history", { operation: "list", projectHandle, limit: 1 });
      await call("pokemap_history", { operation: "undo", projectHandle,
        entryId: record((recent.entries as JsonRecord[])[0]).entryId,
        idempotencyKey: `undo-pattern-cell-${actionId}` });
      assert.deepEqual(await readFile(mapPath), patternedBytes);
    }
    for (const presetId of ["replacement", "soil"]) {
      await apply(await plan("smart_tile.preset.publish", { preset: {
        id: presetId, name: presetId, usage: "terrain", topology: "uniform",
        templateHint: "simple", coveragePolicy: "sparse",
        coverageProfile: { mode: "template" }, transformPolicy: {},
        defaultMaterialId: "grass", allowedMaterialIds: ["grass"],
        rules: [{ id: "unit",
          centerMatch: { kind: "material", materialId: "grass" },
          candidates: [{ id: "unit", parts: [{ source: {
            kind: "model3d", modelId: "tree", replacesGround: presetId === "replacement",
          } }] }],
        }],
      } }));
      await apply(await plan("smart_tile.layer.create", { mapId,
        layerId: presetId, presetId, name: presetId,
        insertIndex: presetId === "replacement" ? 0 : 1,
      }));
    }
    await apply(await plan("smart_tile.cell.paint", { mapId,
      layerId: "replacement", materialId: "grass", cells: [{ x: 1, y: 1 }],
    }));
    const beforeSoil = record(JSON.parse(await readFile(mapPath, "utf8")));
    const ownedLayer = (beforeSoil.layers as JsonRecord[])
      .find(layer => layer.id === "replacement")!;
    for (const actionId of ["smart_tile.cell.paint", "smart_tile.cell.paint_batch"]) {
      await apply(await plan(actionId, { mapId, layerId: "soil",
        ...(actionId === "smart_tile.cell.paint_batch"
          ? { strokes: [{ materialId: "grass", cells: [{ x: 1, y: 1 }] }] }
          : { materialId: "grass", cells: [{ x: 1, y: 1 }] }),
      }));
      const painted = record(JSON.parse(await readFile(mapPath, "utf8")));
      assert.deepEqual((painted.layers as JsonRecord[])
        .find(layer => layer.id === "replacement"), ownedLayer);
      if (actionId === "smart_tile.cell.paint") await apply(await plan(
        "smart_tile.cell.erase", { mapId, layerId: "soil", cells: [{ x: 1, y: 1 }] }));
    }
    const beforeManifest = await readFile(manifestPath);
    const before = record((record(JSON.parse(beforeManifest.toString())).models3d as JsonRecord[])[0]);
    await plan("model3d.source.replace", { modelId: "unknown", artifactHandle: await stage(afterBytes) }, true);
    await plan("model3d.source.replace", { modelId: "house", artifactHandle: await stage(Buffer.from([0, 1, 2])) }, true);
    assert.deepEqual(await readFile(manifestPath), beforeManifest);
    const planned = await plan("model3d.source.replace", {
      modelId: "house", artifactHandle: await stage(afterBytes) });
    assert.deepEqual(await readFile(manifestPath), beforeManifest);
    const operationId = "replace-model-source";
    const args = { operation: "apply", projectHandle, planId: planned.planId, operationId };
    const applied = await call("pokemap_apply", args);
    const replay = await call("pokemap_apply", args);
    assert.equal(record(applied.receipt).receiptId, record(replay.receipt).receiptId);
    const queried = await call("pokemap_query", { projectHandle,
      resourceKind: "model3d", operation: "get", ids: ["house"], view: "detail" });
    const after = record((queried.items as JsonRecord[])[0]);
    for (const key of ["id", "name", "scale", "pivot", "collisionBounds", "blocksMovementByDefault", "sourceAssetId", "relativePath"]) {
      assert.deepEqual(after[key], before[key], key);
    }
    assert.equal((record(after.inspection).animations as JsonRecord[]).length, 1);
    const sourcePath = join(projectRoot, String(before.relativePath));
    assert.deepEqual(await readFile(sourcePath), afterBytes);
    const history = await call("pokemap_history", { operation: "list", projectHandle, limit: 1 });
    await call("pokemap_history", { operation: "undo", projectHandle,
      entryId: record((history.entries as JsonRecord[])[0]).entryId, idempotencyKey: "undo-model-source" });
    assert.deepEqual(await readFile(sourcePath), beforeBytes);
    const batchBefore = await readFile(manifestPath);
    const batchModels = record(JSON.parse(batchBefore.toString())).models3d as JsonRecord[];
    const batchHandle = await stage(afterBytes);
    await plan("model3d.source.replace_batch", { models: [
      { modelId: "house", artifactHandle: batchHandle },
      { modelId: "house", artifactHandle: batchHandle },
    ] }, true);
    assert.deepEqual(await readFile(manifestPath), batchBefore);
    const handle = await stage(afterBytes);
    const batchPlan = await plan("model3d.source.replace_batch", { models: [
      { modelId: "house", artifactHandle: handle },
      { modelId: "tree", artifactHandle: handle },
    ] });
    const changes = record(record(batchPlan.plan).changeSet).changes as JsonRecord[];
    assert.equal(changes.filter(change => record(change.resource).kind === "project").length, 1);
    assert.equal(changes.filter(change => record(change.resource).kind === "assetCatalog").length, 1);
    const batchApplied = await apply(batchPlan);
    const batchAfter = await call("pokemap_query", { projectHandle,
      resourceKind: "model3d", operation: "batch_get", ids: ["house", "tree"], view: "detail" });
    for (const current of batchAfter.items as JsonRecord[]) {
      const previous = batchModels.find(model => model.id === current.id)!;
      for (const key of ["id", "name", "scale", "pivot", "collisionBounds", "blocksMovementByDefault", "sourceAssetId", "relativePath"]) {
        assert.deepEqual(current[key], previous[key], key);
      }
      assert.equal((record(current.inspection).animations as JsonRecord[]).length, 1);
      assert.deepEqual(await readFile(join(projectRoot, String(current.relativePath))), afterBytes);
    }
    assert.equal(record(batchApplied.receipt).actionId, "model3d.source.replace_batch");
    const batchHistory = await call("pokemap_history", { operation: "list", projectHandle, limit: 1 });
    await call("pokemap_history", { operation: "undo", projectHandle,
      entryId: record((batchHistory.entries as JsonRecord[])[0]).entryId, idempotencyKey: "undo-model-sources" });
    for (const previous of batchModels) {
      assert.deepEqual(await readFile(join(projectRoot, String(previous.relativePath))),
        previous.id === "tree" ? afterBytes : beforeBytes);
    }
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
    const reopened = await call("pokemap_workspace", { operation: "open", projectRoot });
    const restored = await call("pokemap_query", { projectHandle: reopened.projectHandle,
      resourceKind: "model3d", operation: "get", ids: ["house"], view: "detail" });
    assert.equal((record(record((restored.items as JsonRecord[])[0]).inspection).animations as JsonRecord[]).length, 0);
    assert.deepEqual(record((restored.items as JsonRecord[])[0]).collisionBounds, collisionBounds);
    assert.equal(record((restored.items as JsonRecord[])[0]).blocksMovementByDefault, false);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: reopened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

test("live MCP catalog model source replacements use explicit scoped and project contracts", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-model-source-catalog-"));
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "model3d-catalog-source-proof", version: "1.0.0" });
  let workspace: JsonRecord;
  let sequence = 0;
  async function call(name: string, args: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: args });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify(envelope));
    return record(envelope[failure ? "error" : "data"]);
  }
  async function stage(bytes: Buffer): Promise<string> {
    const path = join(root, `candidate-${sequence++}.glb`);
    await writeFile(path, bytes);
    return String((await call("pokemap_artifact_stage", {
      sourcePath: path, declaredMediaType: "model/gltf-binary" })).artifactHandle);
  }
  async function plan(actionId: string, parameters: JsonRecord, options: {
    scoped?: boolean; projectScope?: boolean; failure?: boolean;
  } = {}): Promise<JsonRecord> {
    const current = options.scoped
      ? await call("pokemap_workshop", { operation: "read", projectHandle: workspace.projectHandle,
        actionId, parameters, includeDocuments: false })
      : await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    const id = `catalog-model-source-${sequence++}`;
    return call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
      requestId: id, actionId, actionVersion: 1,
      workspaceHandle: workspace.workspaceHandle, parameters,
      expectedRevision: current.snapshotRevision, idempotencyKey: id,
      extensions: { ...(current.planExtensions ? record(current.planExtensions) : {}),
        ...(options.projectScope ? { sourceReplacementScope: "project" } : {}) },
    } }, options.failure);
  }
  async function apply(planned: JsonRecord): Promise<JsonRecord> {
    return call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle,
      planId: planned.planId, operationId: `catalog-model-source-apply-${sequence++}` });
  }
  try {
    await client.connect(transport);
    const projectRoot = root;
    const originalDoor = glb(true, 2);
    const originalStatic = glb(false);
    await writeFile(join(root, "door.glb"), originalDoor);
    await writeFile(join(root, "static.glb"), originalStatic);
    const packageRoot = resolve("../../packages/map_authoring");
    await promisify(execFile)(process.env.POKEMAP_TEST_DART ?? "dart", [
      `--packages=${join(packageRoot, ".dart_tool/package_config.json")}`,
      join(packageRoot, "test/support/create_model_source_catalog_fixture.dart"), root,
    ], { timeout: 60_000 });
    const manifestPath = join(projectRoot, "project.json");
    const mapId = "room";
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot });
    await call("pokemap_workshop", { operation: "prepare", projectHandle: workspace.projectHandle });
    const descriptor = await readFile(manifestPath);
    const mapPath = join(projectRoot, "maps", `${mapId}.json`);
    const mapBytes = await readFile(mapPath);
    const staticPath = join(projectRoot, "assets/models3d/static.glb");
    const doorPath = join(projectRoot, "assets/models3d/door.glb");
    const firstStatic = glb(false, 1, 2);
    const first = await plan("model3d.source.replace", {
      modelId: "static", artifactHandle: await stage(firstStatic),
    }, { scoped: true });
    const operationId = `catalog-model-source-apply-${sequence++}`;
    const applyArgs = { operation: "apply", projectHandle: workspace.projectHandle,
      planId: first.planId, operationId };
    const applied = await call("pokemap_apply", applyArgs);
    const replay = await call("pokemap_apply", applyArgs);
    assert.equal(record(replay.receipt).receiptId, record(applied.receipt).receiptId);
    assert.deepEqual(await readFile(staticPath), firstStatic);
    assert.deepEqual(await readFile(doorPath), originalDoor);
    assert.deepEqual(await readFile(mapPath), mapBytes);
    assert.deepEqual(await readFile(manifestPath), descriptor);
    const nextDoor = glb(true, 2, 1.25);
    const nextStatic = glb(false, 1, 3);
    await apply(await plan("model3d.source.replace_batch", { models: [
      { modelId: "door", artifactHandle: await stage(nextDoor) },
      { modelId: "static", artifactHandle: await stage(nextStatic) },
    ] }, { scoped: true }));
    assert.deepEqual(await readFile(doorPath), nextDoor);
    assert.deepEqual(await readFile(staticPath), nextStatic);
    assert.deepEqual(await readFile(mapPath), mapBytes);
    const history = await call("pokemap_history", { operation: "list", projectHandle: workspace.projectHandle, limit: 1 });
    await call("pokemap_history", { operation: "undo", projectHandle: workspace.projectHandle,
      entryId: record((history.entries as JsonRecord[])[0]).entryId, idempotencyKey: "undo-catalog-source-batch" });
    assert.deepEqual(await readFile(doorPath), originalDoor);
    assert.deepEqual(await readFile(staticPath), firstStatic);
    assert.deepEqual(await readFile(mapPath), mapBytes);
    for (const actionId of ["model3d.source.replace", "model3d.source.replace_batch"]) {
      const entry = { modelId: "door", artifactHandle: await stage(glb(true)) };
      const parameters = actionId.endsWith("_batch") ? { models: [entry] } : entry;
      const localFailure = await plan(actionId, parameters, { scoped: true, failure: true });
      assert.equal(localFailure.domainCode, "catalog.model_source_usage_proof_required");
      const globalEntry = { modelId: "door", artifactHandle: await stage(glb(true)) };
      const globalFailure = await plan(actionId,
        actionId.endsWith("_batch") ? { models: [globalEntry] } : globalEntry,
        { projectScope: true, failure: true });
      assert.equal(globalFailure.domainCode, "warp.door_clip_invalid");
      assert.deepEqual(await readFile(doorPath), originalDoor);
      assert.deepEqual(await readFile(mapPath), mapBytes);
    }
    const refusedAnimation = await plan("model3d.source.replace", {
      modelId: "static", artifactHandle: await stage(glb(true)),
    }, { scoped: true, failure: true });
    assert.equal(refusedAnimation.domainCode, "catalog.model_source_usage_proof_required");
    assert.deepEqual(await readFile(staticPath), firstStatic);
    await apply(await plan("model3d.source.replace", {
      modelId: "static", artifactHandle: await stage(glb(true)),
    }, { projectScope: true }));
    assert.deepEqual(await readFile(staticPath), glb(true));
    assert.deepEqual(await readFile(mapPath), mapBytes);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot });
    const reopened = await call("pokemap_query", { projectHandle: workspace.projectHandle,
      resourceKind: "model3d", operation: "batch_get", ids: ["door", "static"], view: "detail" });
    const models = reopened.items as JsonRecord[];
    assert.equal((record(models.find(model => model.id === "door")!.inspection).animations as unknown[]).length, 2);
    assert.equal((record(models.find(model => model.id === "static")!.inspection).animations as unknown[]).length, 1);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

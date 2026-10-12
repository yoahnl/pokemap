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

function unitGlb(): Buffer {
  const binary = Buffer.alloc(36);
  [-.2, 0, -.2, .2, 0, -.2, 0, 1, .2].forEach((value, index) =>
    binary.writeFloatLE(value, index * 4));
  const json = Buffer.from(JSON.stringify({
    asset: { version: "2.0" }, scene: 0,
    scenes: [{ nodes: [0] }], nodes: [{ mesh: 0 }],
    meshes: [{ primitives: [{ attributes: { POSITION: 0 } }] }],
    buffers: [{ byteLength: binary.length }],
    bufferViews: [{ buffer: 0, byteLength: binary.length }],
    accessors: [{ bufferView: 0, componentType: 5126, count: 3,
      type: "VEC3", min: [-.2, 0, -.2], max: [.2, 1, .2] }],
  }));
  const length = Math.ceil(json.length / 4) * 4;
  const bytes = Buffer.alloc(28 + length + binary.length);
  bytes.writeUInt32LE(0x46546c67, 0);
  bytes.writeUInt32LE(2, 4);
  bytes.writeUInt32LE(bytes.length, 8);
  bytes.writeUInt32LE(length, 12);
  bytes.writeUInt32LE(0x4e4f534a, 16);
  bytes.fill(32, 20, 20 + length);
  json.copy(bytes, 20);
  bytes.writeUInt32LE(binary.length, 20 + length);
  bytes.writeUInt32LE(0x004e4942, 24 + length);
  binary.copy(bytes, 28 + length);
  return bytes;
}

function borderFeature(map: JsonRecord, featureId: string): JsonRecord {
  const layer = (map.layers as JsonRecord[]).find(value => value.id === "fences");
  assert.ok(layer);
  const feature = (record(layer.content).features as JsonRecord[])
    .find(value => value.id === featureId);
  assert.ok(feature);
  return feature;
}

function instances(map: JsonRecord): JsonRecord[] {
  return record(map.spatialScene).instances as JsonRecord[];
}

function placements(feature: JsonRecord): JsonRecord[] {
  return record(feature.materialization).spatialPlacements as JsonRecord[];
}

test("live MCP Border cell erase splits and rematerializes one owned trace atomically", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-border-stroke-erase-mcp-"));
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root,
      "--dart", process.env.POKEMAP_TEST_DART ?? "dart",
      "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "border-stroke-erase-proof", version: "1.0.0" });
  async function call(name: string, args: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const response = await client.callTool({ name, arguments: args });
    assert.equal(response.isError, failure ? true : undefined,
      JSON.stringify(response.structuredContent));
    const envelope = record(response.structuredContent);
    return record(failure ? envelope.error : envelope.data);
  }
  try {
    await client.connect(transport);
    const catalog = await call("pokemap_describe");
    const descriptor = (catalog.mutationActions as JsonRecord[])
      .find(action => action.id === "border_layer.stroke_erase");
    assert.ok(descriptor, "border_layer.stroke_erase must be discoverable");
    assert.equal(descriptor.version, 1);
    assert.equal(descriptor.inputSchemaId,
      "schema.border_layer.stroke_erase.input.v1");
    const schema = record(record(descriptor.extensions).inputSchema);
    assert.equal(schema.additionalProperties, false);
    assert.deepEqual([...(schema.required as string[])].sort(),
      ["featureId", "layerId", "mapId", "points"]);
    const pointsSchema = record(record(schema.properties).points);
    assert.equal(pointsSchema.type, "array");
    assert.equal(pointsSchema.minItems, 1);
    assert.equal(pointsSchema.maxItems, 4096);
    const pointSchema = record(pointsSchema.items);
    assert.equal(pointSchema.additionalProperties, false);
    assert.deepEqual([...(pointSchema.required as string[])].sort(), ["x", "y"]);
    for (const axis of ["x", "y"]) {
      assert.equal(record(record(pointSchema.properties)[axis]).type, "integer");
    }

    const request = { name: "Editable fences", folderName: "fences", parentPath: root,
      template: "empty", dimension: "threeD", mapWidth: 10, mapHeight: 6 };
    const createPreview = await call("pokemap_project_create_preview", { request });
    const created = await call("pokemap_project_create",
      { request, confirmation: createPreview.confirmation });
    const projectRoot = String(created.projectPath);
    let opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    let projectHandle = String(opened.projectHandle);
    let workspaceHandle = String(opened.workspaceHandle);
    const manifestPath = join(projectRoot, "project.json");
    const manifest = record(JSON.parse(await readFile(manifestPath, "utf8")));
    const mapEntry = (manifest.maps as JsonRecord[])[0];
    assert.ok(mapEntry);
    const mapId = String(mapEntry.id);
    const mapPath = join(projectRoot, String(mapEntry.relativePath));
    let sequence = 0;
    async function plan(actionId: string, parameters: JsonRecord, failure = false): Promise<JsonRecord> {
      const validation = await call("pokemap_validate", { projectHandle });
      const before = await Promise.all([readFile(manifestPath), readFile(mapPath)]);
      const id = `border-stroke-erase-${sequence++}`;
      const planned = await call("pokemap_plan", { projectHandle, request: {
        requestId: id, actionId, actionVersion: 1, workspaceHandle, parameters,
        expectedRevision: validation.snapshotRevision, idempotencyKey: id } }, failure);
      assert.deepEqual(await Promise.all([readFile(manifestPath), readFile(mapPath)]), before);
      return planned;
    }
    async function mutate(actionId: string, parameters: JsonRecord): Promise<JsonRecord> {
      const planned = await plan(actionId, parameters);
      const applied = await call("pokemap_apply", { operation: "apply", projectHandle,
        planId: planned.planId, operationId: `border-stroke-erase-apply-${sequence++}` });
      assert.equal(record(applied.receipt).status, "applied");
      return applied;
    }
    const modelPath = join(root, "fence.glb");
    await writeFile(modelPath, unitGlb());
    const artifact = await call("pokemap_artifact_stage", {
      sourcePath: modelPath, declaredMediaType: "model/gltf-binary" });
    await mutate("model3d.import", { modelId: "fence-unit", name: "Fence",
      artifactHandle: artifact.artifactHandle });
    await mutate("map.apply_operations", { mapId, operations: [
      { kind: "layer.add", layerKind: "border", layerId: "fences", name: "Fences" },
    ] });
    await mutate("border.blueprint.draft.upsert", { record: { id: "fence", draft: {
      baseRevision: 0, definition: { name: "Fence", previewSeed: "17",
        template: "connectedLine", sortOrder: 0,
        primitives: ["lineStraight", "lineCorner", "lineCap"].map(role => ({
          id: role, sourceModelId: "fence-unit", role, weight: 1,
          transforms: { allowFlipX: false, allowedQuarterTurns: [0, 1, 2, 3] },
        })), defaults: { irregularityPermille: 0, detailDensityPermille: 0,
          variationPermille: 1000, maxOverlapPx: 0, gapTolerancePx: 0, depthRows: 1 },
      },
    } } });
    await mutate("border.blueprint.publish", { blueprintId: "fence" });
    const foreignY = -2.7040466528;
    await mutate("map3d.instance.upsert_batch", { mapId, instances: [
      { id: "foreign", modelId: "fence-unit", position: { x: 4.5, y: foreignY, z: 2.5 },
        rotationDegrees: 35, scale: .75, blocksMovement: false },
    ] });
    async function queryForeign(): Promise<JsonRecord> {
      const query = await call("pokemap_query", { projectHandle,
        resourceKind: "map", operation: "get", ids: [mapId], view: "detail" });
      const map = record((query.items as JsonRecord[])[0]);
      const foreign = instances(map).find(value => value.id === "foreign");
      assert.ok(foreign);
      assert.equal(record(foreign.position).y, foreignY);
      return foreign;
    }
    for (const [featureId, row, length] of [["target", 2, 7], ["other", 4, 3]] as const) {
      await mutate("border_layer.feature_create", { mapId, layerId: "fences", featureId,
        blueprintId: "fence", name: featureId, seed: "17", geometry: {
          kind: "stroke", strokes: [{ id: `${featureId}-line`, closed: false,
            points: Array.from({ length }, (_, index) => ({ x: index + 1, y: row })),
          }],
        } });
      await mutate("border_layer.materialize_apply", { mapId, layerId: "fences", featureId });
    }
    const beforeBytes = await readFile(mapPath);
    const beforeManifest = await readFile(manifestPath);
    const before = record(JSON.parse(beforeBytes.toString()));
    const foreignBefore = await queryForeign();
    const targetBefore = borderFeature(before, "target");
    const ownedBefore = new Set(placements(targetBefore).map(value => String(value.instanceId)));
    assert.equal(ownedBefore.size, 7);
    const historyBefore = await call("pokemap_history", { operation: "list", projectHandle, limit: 2 });
    const previousHistoryId = record((historyBefore.entries as JsonRecord[])[0]).entryId;
    const target = { mapId, layerId: "fences", featureId: "target", points: [{ x: 4, y: 2 }] };
    const rejected = await plan("border_layer.stroke_erase", { ...target, featureId: "missing" }, true);
    assert.equal(rejected.code, "validation_failed");
    assert.ok(JSON.stringify(rejected).includes("border.feature_missing"),
      JSON.stringify(rejected));
    assert.deepEqual(await readFile(mapPath), beforeBytes);
    assert.deepEqual(await readFile(manifestPath), beforeManifest);
    assert.deepEqual((await call("pokemap_history", {
      operation: "list", projectHandle, limit: 2 })).entries, historyBefore.entries);
    await mutate("border_layer.stroke_erase", target);
    const erasedBytes = await readFile(mapPath);
    assert.notDeepEqual(erasedBytes, beforeBytes);
    assert.deepEqual(await readFile(manifestPath), beforeManifest);
    const erased = record(JSON.parse(erasedBytes.toString()));
    const targetAfter = borderFeature(erased, "target");
    const strokes = record(targetAfter.geometry).strokes as JsonRecord[];
    assert.equal(strokes.length, 2);
    assert.deepEqual(strokes.map(stroke => stroke.points), [
      [{ x: 1, y: 2 }, { x: 2, y: 2 }, { x: 3, y: 2 }],
      [{ x: 5, y: 2 }, { x: 6, y: 2 }, { x: 7, y: 2 }],
    ]);
    assert.ok(strokes.every(stroke => stroke.closed !== true));
    assert.equal(new Set(strokes.map(stroke => stroke.id)).size, 2);
    const ownedAfter = new Set(placements(targetAfter).map(value => String(value.instanceId)));
    assert.equal(ownedAfter.size, 6);
    assert.equal(instances(erased).length, instances(before).length - 1);
    assert.deepEqual(instances(erased).filter(value => !ownedAfter.has(String(value.id))),
      instances(before).filter(value => !ownedBefore.has(String(value.id))));
    assert.deepEqual(await queryForeign(), foreignBefore);
    assert.deepEqual(borderFeature(erased, "other"), borderFeature(before, "other"));
    assert.equal(instances(erased).filter(value => ownedAfter.has(String(value.id)) &&
      record(value.position).x === 4.5).length, 0);
    for (const x of [1.5, 2.5, 6.5, 7.5]) {
      const original = instances(before).find(value => ownedBefore.has(String(value.id)) &&
        record(value.position).x === x);
      assert.ok(original);
      const retained = instances(erased).find(value => value.id === original.id);
      assert.deepEqual(retained, original);
      assert.deepEqual(placements(targetAfter).find(value => value.instanceId === original.id),
        placements(targetBefore).find(value => value.instanceId === original.id));
    }
    const historyAfter = await call("pokemap_history", { operation: "list", projectHandle, limit: 2 });
    const historyEntries = historyAfter.entries as JsonRecord[];
    assert.equal(historyEntries.length, 2);
    assert.equal(record(historyEntries[1]).entryId, previousHistoryId);
    const eraseHistoryId = record(historyEntries[0]).entryId;
    assert.notEqual(eraseHistoryId, previousHistoryId);
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
    opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    projectHandle = String(opened.projectHandle);
    workspaceHandle = String(opened.workspaceHandle);
    assert.deepEqual(await readFile(mapPath), erasedBytes);
    assert.deepEqual(await readFile(manifestPath), beforeManifest);
    assert.deepEqual(await queryForeign(), foreignBefore);
    await call("pokemap_history", { operation: "undo", projectHandle,
      entryId: eraseHistoryId, idempotencyKey: "undo-border-cell-erase" });
    assert.deepEqual(await readFile(mapPath), beforeBytes);
    assert.deepEqual(await readFile(manifestPath), beforeManifest);
    assert.deepEqual(await queryForeign(), foreignBefore);
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

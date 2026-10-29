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
  const document = { asset: { version: "2.0" }, scene: 0, scenes: [{ nodes: [0] }], nodes: [{ mesh: 0 }],
    buffers: [{ byteLength: 36 }], bufferViews: [{ buffer: 0, byteLength: 36 }],
    accessors: [{ bufferView: 0, componentType: 5126, count: 3, type: "VEC3" }],
    meshes: [{ primitives: [{ attributes: { POSITION: 0 } }] }] };
  const json = Buffer.from(JSON.stringify(document));
  const length = Math.ceil(json.length / 4) * 4;
  const bytes = Buffer.alloc(28 + length + 36);
  bytes.writeUInt32LE(0x46546c67, 0); bytes.writeUInt32LE(2, 4); bytes.writeUInt32LE(bytes.length, 8);
  bytes.writeUInt32LE(length, 12); bytes.writeUInt32LE(0x4e4f534a, 16);
  bytes.fill(32, 20, 20 + length); json.copy(bytes, 20);
  bytes.writeUInt32LE(36, 20 + length); bytes.writeUInt32LE(0x004e4942, 24 + length);
  [-.2, 0, -.2, .2, 0, -.2, 0, 1, .2].forEach((value, i) => bytes.writeFloatLE(value, 28 + length + i * 4));
  return bytes;
}

test("live MCP moves native Border variations and suppression through materialize and reopen", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-border-move-mcp-"));
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--artifact-root", root,
      "--dart", process.env.POKEMAP_TEST_DART ?? "dart", "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "native-border-move-proof", version: "1.0.0" });
  async function call(name: string, args: JsonRecord = {}): Promise<JsonRecord> {
    const response = await client.callTool({ name, arguments: args });
    assert.equal(response.isError, undefined, JSON.stringify(response.structuredContent ?? response.content));
    return record(record(response.structuredContent).data);
  }
  try {
    await client.connect(transport);
    const catalog = await call("pokemap_describe");
    assert.ok((catalog.mutationActions as JsonRecord[]).some(action => action.id === "border_layer.feature_move"));
    const request = { name: "Native Border move", folderName: "game", parentPath: root,
      template: "empty", dimension: "threeD", mapWidth: 8, mapHeight: 8 };
    const preview = await call("pokemap_project_create_preview", { request });
    const created = await call("pokemap_project_create", { request, confirmation: preview.confirmation });
    const projectRoot = String(created.projectPath);
    let opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    let projectHandle = String(opened.projectHandle), workspaceHandle = String(opened.workspaceHandle), serial = 0;
    await call("pokemap_workshop", { operation: "prepare", projectHandle });
    const manifest = record(JSON.parse(await readFile(join(projectRoot, "project.json"), "utf8")));
    const entry = record((manifest.maps as unknown[])[0]), mapId = String(entry.id);
    const mapPath = join(projectRoot, String(entry.relativePath));
    async function mutate(actionId: string, parameters: JsonRecord): Promise<void> {
      const validation = await call("pokemap_validate", { projectHandle });
      const before = await readFile(mapPath), id = "move-" + serial++;
      const planned = await call("pokemap_plan", { projectHandle, request: { requestId: id,
        actionId, actionVersion: 1, workspaceHandle, parameters, expectedRevision: validation.snapshotRevision, idempotencyKey: id } });
      assert.deepEqual(await readFile(mapPath), before);
      const applied = await call("pokemap_apply", { operation: "apply", projectHandle, planId: planned.planId, operationId: "apply-" + id });
      assert.equal(record(applied.receipt).status, "applied");
    }
    const sourcePath = join(root, "unit.glb"); await writeFile(sourcePath, unitGlb());
    const staged = await call("pokemap_artifact_stage", { sourcePath, declaredMediaType: "model/gltf-binary" });
    await mutate("model3d.import", { modelId: "unit", name: "Unit", artifactHandle: staged.artifactHandle });
    const definition = { name: "Fence", previewSeed: "1", template: "connectedLine", straightOnly: false, sortOrder: 0,
      primitives: ["lineCap", "lineStraight", "lineCorner"].map(role => ({ id: role, sourceModelId: "unit", role,
        weight: 1, transforms: { allowFlipX: false, allowedQuarterTurns: [0, 1, 2, 3] } })),
      defaults: { irregularityPermille: 0, detailDensityPermille: 0, variationPermille: 0, maxOverlapPx: 0, gapTolerancePx: 0, depthRows: 1 } };
    await mutate("border.blueprint.draft.upsert", { record: { id: "fence", draft: { baseRevision: 0, definition } } });
    await mutate("border.blueprint.publish", { blueprintId: "fence" });
    await mutate("map.apply_operations", { mapId, operations: [{ kind: "layer.add", layerKind: "border", layerId: "border", name: "Fence" }] });
    const target = { mapId, layerId: "border", featureId: "fence" };
    await mutate("border_layer.feature_create", { ...target, blueprintId: "fence", name: "Fence", seed: "1",
      geometry: { kind: "stroke", strokes: [{ id: "line", closed: false, points: [{ x: 1, y: 1 }, { x: 2, y: 1 }, { x: 3, y: 1 }] }] } });
    await mutate("border_layer.materialize_apply", target);
    const relinkDescriptor = (catalog.mutationActions as JsonRecord[]).find(action => action.id === "border_layer.relink_apply")!;
    const relinkSchema = record(record(relinkDescriptor.extensions).inputSchema);
    assert.ok(record(relinkSchema.properties).reverseStrokes);
    await mutate("border.blueprint.draft.upsert", { record: { id: "replacement", draft: { baseRevision: 0, definition } } });
    await mutate("border.blueprint.publish", { blueprintId: "replacement" });
    const beforeRelink = record(JSON.parse(await readFile(mapPath, "utf8")));
    await mutate("border_layer.relink_apply", { ...target, targetBlueprintId: "replacement", reverseStrokes: true, clearVerticalOffset: true });
    const relinkedMap = record(JSON.parse(await readFile(mapPath, "utf8")));
    const sourceFeature = record((record((beforeRelink.layers as JsonRecord[])[0]!.content).features as JsonRecord[])[0]);
    const relinkedFeature = record((record((relinkedMap.layers as JsonRecord[])[0]!.content).features as JsonRecord[])[0]);
    assert.equal(relinkedFeature.id, sourceFeature.id);
    assert.equal(relinkedFeature.seed, sourceFeature.seed);
    assert.equal(relinkedFeature.blueprintId, "replacement");
    assert.deepEqual(relinkedFeature.keepOutRegions, sourceFeature.keepOutRegions);
    const sourceStroke = record((record(sourceFeature.geometry).strokes as JsonRecord[])[0]);
    const relinkedStroke = record((record(relinkedFeature.geometry).strokes as JsonRecord[])[0]);
    assert.deepEqual(relinkedStroke.points, [...sourceStroke.points as unknown[]].reverse());
    await mutate("border_layer.relink_apply", { ...target, targetBlueprintId: "fence", reverseStrokes: true });
    const base = record(JSON.parse(await readFile(mapPath, "utf8")));
    const featureOf = (map: JsonRecord) => record((record((map.layers as JsonRecord[]).find(layer => layer.id === "border")!.content).features as unknown[])[0]);
    const placements = record(featureOf(base).materialization).spatialPlacements as JsonRecord[];
    const body = placements.find(p => p.primitiveId === "lineStraight")!, cap = placements.find(p => p.primitiveId === "lineCap")!;
    await mutate("border_layer.feature_set_replacement", { ...target, slotKey: body.slotKey, primitiveId: "lineStraight" });
    await mutate("border_layer.feature_set_transform", { ...target, slotKey: body.slotKey, transformOverride: { quarterTurns: 2, flipX: false } });
    await mutate("border_layer.feature_set_suppressed", { ...target, slotKey: cap.slotKey, suppressed: true });
    await mutate("border_layer.materialize_apply", target);
    const before = record(JSON.parse(await readFile(mapPath, "utf8")));
    await mutate("border_layer.feature_move", { ...target, dx: 1, dy: 1 });
    await mutate("border_layer.materialize_apply", target);
    const afterBytes = await readFile(mapPath), after = record(JSON.parse(afterBytes.toString()));
    const oldInstances = record(before.spatialScene).instances as JsonRecord[], instances = record(after.spatialScene).instances as JsonRecord[];
    assert.equal(instances.length, 2);
    for (let i = 0; i < instances.length; i++) {
      assert.equal(instances[i]!.modelId, oldInstances[i]!.modelId);
      assert.equal(instances[i]!.rotationDegrees, oldInstances[i]!.rotationDegrees);
      for (const axis of ["x", "z"]) assert.equal(Number(record(instances[i]!.position)[axis]) - Number(record(oldInstances[i]!.position)[axis]), 1);
    }
    const overrides = featureOf(after).overrides as JsonRecord[];
    assert.equal(overrides.length, 2); assert.ok(overrides.every(o => o.slotKey !== body.slotKey && o.slotKey !== cap.slotKey));
    assert.equal(overrides.find(o => !o.suppressed)!.replacementPrimitiveId, "lineStraight");
    assert.equal(record(overrides.find(o => !o.suppressed)!.transformOverride).quarterTurns, 2);
    const fragmentsTarget = { ...target, featureId: "fragments" };
    await mutate("border_layer.feature_create", { ...fragmentsTarget, blueprintId: "fence", name: "Fragments", seed: "17",
      geometry: { kind: "stroke", strokes: [{ id: "erased-line", closed: false,
        points: Array.from({ length: 7 }, (_, i) => ({ x: i + 1, y: 4 })) }] } });
    await mutate("border_layer.materialize_apply", fragmentsTarget);
    await mutate("border_layer.stroke_erase", { ...fragmentsTarget, points: [{ x: 4, y: 4 }] });
    const fragmentFeatureOf = (map: JsonRecord) => record((record((map.layers as JsonRecord[])
      .find(layer => layer.id === "border")!.content).features as JsonRecord[]).find(f => f.id === "fragments"));
    const erased = record(JSON.parse(await readFile(mapPath, "utf8")));
    const fragmentSlots = record(fragmentFeatureOf(erased).materialization).spatialPlacements as JsonRecord[];
    assert.equal(fragmentSlots.length, 6);
    await mutate("border_layer.feature_set_transform", { ...fragmentsTarget,
      slotKey: fragmentSlots[1]!.slotKey, transformOverride: { quarterTurns: 2, flipX: false } });
    await mutate("border_layer.materialize_apply", fragmentsTarget);
    const corrected = record(JSON.parse(await readFile(mapPath, "utf8")));
    const owned = new Set(fragmentSlots.map(slot => String(slot.instanceId)));
    const beforeFragments = (record(corrected.spatialScene).instances as JsonRecord[])
      .filter(instance => owned.has(String(instance.id)));
    await mutate("border_layer.feature_move", { ...fragmentsTarget, dx: -1, dy: 1 });
    await mutate("border_layer.materialize_apply", fragmentsTarget);
    const savedBytes = await readFile(mapPath), saved = record(JSON.parse(savedBytes.toString()));
    const movedFragmentSlots = record(fragmentFeatureOf(saved).materialization).spatialPlacements as JsonRecord[];
    const movedOwned = new Set(movedFragmentSlots.map(slot => String(slot.instanceId)));
    const afterFragments = (record(saved.spatialScene).instances as JsonRecord[])
      .filter(instance => movedOwned.has(String(instance.id)));
    assert.equal(afterFragments.length, 6);
    for (let i = 0; i < afterFragments.length; i++) {
      assert.equal(afterFragments[i]!.modelId, beforeFragments[i]!.modelId);
      assert.equal(afterFragments[i]!.rotationDegrees, beforeFragments[i]!.rotationDegrees);
      assert.equal(Number(record(afterFragments[i]!.position).x) - Number(record(beforeFragments[i]!.position).x), -1);
      assert.equal(Number(record(afterFragments[i]!.position).z) - Number(record(beforeFragments[i]!.position).z), 1);
    }
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
    opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    projectHandle = String(opened.projectHandle); workspaceHandle = String(opened.workspaceHandle);
    assert.equal((await call("pokemap_validate", { projectHandle })).valid, true);
    assert.deepEqual(await readFile(mapPath), savedBytes);
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
  } finally {
    await client.close(); await transport.close(); await rm(root, { recursive: true, force: true });
  }
});

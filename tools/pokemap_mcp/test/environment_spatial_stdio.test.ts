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

function treeGlb(): Buffer {
  const binary = Buffer.alloc(36);
  [-.2, 0, -.2, .2, 0, -.2, 0, 2, .2].forEach((value, index) =>
    binary.writeFloatLE(value, index * 4));
  const document = {
    asset: { version: "2.0" }, scene: 0,
    scenes: [{ nodes: [0] }], nodes: [{ mesh: 0 }],
    meshes: [{ primitives: [{ attributes: { POSITION: 0 } }] }],
    buffers: [{ byteLength: binary.length }],
    bufferViews: [{ buffer: 0, byteLength: binary.length }],
    accessors: [{ bufferView: 0, componentType: 5126, count: 3,
      type: "VEC3", min: [-.2, 0, -.2], max: [.2, 2, .2] }],
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

function instances(map: JsonRecord): JsonRecord[] {
  return record(map.spatialScene).instances as JsonRecord[];
}

function area(map: JsonRecord): JsonRecord {
  const layer = (map.layers as JsonRecord[]).find(value => value.id === "forest")!;
  const content = record(layer.content);
  assert.equal(content.targetsSpatialTerrain, true);
  return (content.areas as JsonRecord[]).find(value => value.id === "trees")!;
}

test("live MCP spatial Environment generation preserves ownership, transforms and persistence", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-environment-spatial-mcp-"));
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "environment-spatial-transport-proof", version: "1.0.0" });
  async function call(name: string, args: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: args });
    assert.equal(result.isError, failure ? true : undefined, JSON.stringify(result.structuredContent));
    const envelope = record(result.structuredContent);
    return record(failure ? envelope.error : envelope.data);
  }
  try {
    await client.connect(transport);
    const catalog = await call("pokemap_describe");
    const actions = new Map((catalog.mutationActions as JsonRecord[])
      .map(value => [String(value.id), value]));
    const attachment = actions.get("environment.attach_to_spatial_terrain")!;
    assert.ok(attachment);
    assert.deepEqual(record(record(attachment.extensions).inputSchema).required, ["mapId", "layerId"]);
    const add = actions.get("environment.generated_placement_add")!;
    assert.deepEqual(record(add.extensions).visualKinds, ["element", "model3d"]);
    assert.deepEqual(record(record(add.extensions).inputSchema).oneOf,
      [{ required: ["elementId"] }, { required: ["modelId"] }]);
    for (const id of ["environment.preset.upsert", "environment.area_create",
      "environment.mask_paint", "environment.generate_apply", "environment.regenerate_apply",
      "environment.generated_placement_move", "environment.generated_placement_delete"]) {
      assert.ok(actions.has(id), id);
    }
    const request = { name: "Spatial forest", folderName: "forest", parentPath: root,
      template: "empty", dimension: "threeD", mapWidth: 8, mapHeight: 6 };
    const createPreview = await call("pokemap_project_create_preview", { request });
    const created = await call("pokemap_project_create", { request, confirmation: createPreview.confirmation });
    const projectRoot = String(created.projectPath);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    let projectHandle = String(opened.projectHandle), workspaceHandle = String(opened.workspaceHandle);
    const manifestPath = join(projectRoot, "project.json");
    const manifest = record(JSON.parse(await readFile(manifestPath, "utf8")));
    const mapEntry = (manifest.maps as JsonRecord[])[0];
    assert.ok(mapEntry);
    const mapId = String(mapEntry.id), mapPath = join(projectRoot, String(mapEntry.relativePath));
    const target = { mapId, layerId: "forest", areaId: "trees" };
    let sequence = 0;
    async function savedMap(): Promise<JsonRecord> {
      return record(JSON.parse(await readFile(mapPath, "utf8")));
    }
    async function plan(actionId: string, parameters: JsonRecord, failure = false): Promise<JsonRecord> {
      const validation = await call("pokemap_validate", { projectHandle });
      const beforeManifest = await readFile(manifestPath), beforeMap = await readFile(mapPath);
      const id = `spatial-environment-${sequence++}`;
      const planned = await call("pokemap_plan", { projectHandle, request: {
        requestId: id, actionId, actionVersion: 1, workspaceHandle, parameters,
        expectedRevision: validation.snapshotRevision, idempotencyKey: id } }, failure);
      assert.deepEqual(await readFile(manifestPath), beforeManifest);
      assert.deepEqual(await readFile(mapPath), beforeMap);
      return planned;
    }
    async function apply(planned: JsonRecord, failure = false): Promise<JsonRecord> {
      return call("pokemap_apply", { operation: "apply", projectHandle,
        planId: planned.planId, operationId: `spatial-environment-apply-${sequence++}` }, failure);
    }
    async function mutate(actionId: string, parameters: JsonRecord): Promise<void> {
      const applied = await apply(await plan(actionId, parameters));
      assert.equal(record(applied.receipt).status, "applied");
    }
    const modelPath = join(root, "tree.glb");
    await writeFile(modelPath, treeGlb());
    const staged = await call("pokemap_artifact_stage", {
      sourcePath: modelPath, declaredMediaType: "model/gltf-binary" });
    await mutate("model3d.import", { modelId: "tree", name: "Tree", artifactHandle: staged.artifactHandle });
    const preset = { id: "forest", name: "Forest", templateId: "forest",
      palette: [{ modelId: "tree", weight: 1, collisionMode: "forceDisabled", tags: [] }],
      defaultParams: { density: 1, variation: 0, edgeDensity: 1, minSpacingCells: 0 }, sortOrder: 0 };
    await mutate("environment.preset.upsert", { preset });
    await mutate("map.apply_operations", { mapId, operations: [
      { kind: "layer.add", layerKind: "environment", layerId: "forest", name: "Forest" },
    ] });
    await mutate("environment.attach_to_spatial_terrain", { mapId, layerId: "forest" });
    await mutate("environment.area_create", { ...target, name: "Trees", presetId: "forest", seed: 31 });
    await mutate("map3d.terrain.set_levels", { mapId, cells: [{ x: 1, z: 1, level: 2 }] });
    await mutate("environment.mask_paint", { ...target, x: 1, y: 1, width: 4, height: 3 });
    const stalePlan = await plan("environment.generate_apply", target);
    const firstPreview = record(record(record(stalePlan.plan).preview).generation);
    assert.equal(firstPreview.placementCount, 12);
    assert.equal(typeof firstPreview.inputFingerprint, "string");
    assert.equal(typeof firstPreview.fingerprint, "string");
    await mutate("environment.preset.upsert", { preset: { ...preset, name: "Renamed forest" } });
    const beforeStaleApply = await readFile(mapPath);
    const stale = await apply(stalePlan, true);
    assert.equal(stale.code, "revision_conflict");
    assert.deepEqual(await readFile(mapPath), beforeStaleApply);
    const freshPlan = await plan("environment.generate_apply", target);
    const freshPreview = record(record(record(freshPlan.plan).preview).generation);
    assert.deepEqual(freshPreview.placements, firstPreview.placements);
    assert.notEqual(freshPreview.inputFingerprint, firstPreview.inputFingerprint);
    await apply(freshPlan);
    const generated = await savedMap();
    assert.deepEqual(generated.placedElements ?? [], []);
    assert.equal(instances(generated).length, 12);
    const owned = area(generated);
    assert.deepEqual(new Set(owned.generatedPlacementIds as string[]),
      new Set(instances(generated).map(value => String(value.id))));
    assert.deepEqual(owned.manualPlacementIds ?? [], []);
    for (const instance of instances(generated)) {
      assert.equal(instance.modelId, "tree");
      assert.equal(instance.blocksMovement, false);
      const position = record(instance.position);
      assert.equal(position.y, position.x === 1.5 && position.z === 1.5 ? 2 : 0);
    }
    const selected = instances(generated)[0], removed = instances(generated)[1];
    assert.ok(selected && removed);
    const movedId = String(selected.id), deletedId = String(removed.id);
    const previousPosition = record(selected.position);
    await mutate("environment.generated_placement_move", { ...target, placementId: movedId, x: 6, y: 4 });
    const moved = instances(await savedMap()).find(value => value.id === movedId)!;
    assert.deepEqual(moved.position, { x: 6.5, y: 0, z: 4.5 });
    assert.ok((area(await savedMap()).manualPlacementIds as string[]).includes(movedId));
    assert.equal((record(area(await savedMap()).mask).cells as boolean[])[
      Math.floor(Number(previousPosition.z)) * 8 + Math.floor(Number(previousPosition.x))], false);
    const exact = { ...moved, position: { x: 6.3, y: .8, z: 4.7 }, rotationDegrees: 45, scale: 1.2 };
    await mutate("map3d.instance.upsert", { mapId, instance: exact });
    await plan("environment.generated_placement_add", {
      ...target, placementId: "invalid", modelId: "tree", elementId: "decor", x: 5, y: 4 }, true);
    await mutate("environment.generated_placement_add", {
      ...target, placementId: "manual-tree", modelId: "tree", x: 5, y: 4 });
    await mutate("environment.generated_placement_delete", { ...target, placementId: deletedId });
    const deletedMap = await savedMap();
    assert.ok(!instances(deletedMap).some(value => value.id === deletedId));
    assert.ok(!(area(deletedMap).generatedPlacementIds as string[]).includes(deletedId));
    await mutate("map3d.instance.upsert", { mapId, instance: {
      id: "foreign", modelId: "tree", position: { x: 7.5, y: 0, z: 5.5 },
      rotationDegrees: 0, scale: 1, blocksMovement: false,
    } });
    await mutate("environment.mask_paint", { ...target, cells: [{ x: 4, y: 4 }] });
    const beforeRegeneration = await readFile(mapPath);
    await mutate("environment.regenerate_apply", { ...target, x: 0, y: 0, width: 8, height: 6 });
    const regenerated = await savedMap();
    assert.deepEqual(instances(regenerated).find(value => value.id === movedId), exact);
    assert.ok(instances(regenerated).some(value => value.id === "manual-tree"));
    assert.ok(instances(regenerated).some(value => value.id === "foreign"));
    assert.ok(!instances(regenerated).some(value => value.id === deletedId));
    assert.deepEqual(new Set(area(regenerated).manualPlacementIds as string[]), new Set([movedId, "manual-tree"]));
    assert.ok(!(area(regenerated).generatedPlacementIds as string[]).includes("foreign"));
    await call("pokemap_validate", { projectHandle });
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
    const reopened = await call("pokemap_workspace", { operation: "open", projectRoot });
    projectHandle = String(reopened.projectHandle);
    workspaceHandle = String(reopened.workspaceHandle);
    assert.deepEqual(await savedMap(), regenerated);
    const queried = await call("pokemap_query", { projectHandle,
      resourceKind: "map", operation: "get", ids: [mapId], view: "detail" });
    const restored = record((queried.items as JsonRecord[])[0]);
    assert.deepEqual(restored.spatialScene, regenerated.spatialScene);
    assert.deepEqual(restored.layers, regenerated.layers);
    const history = await call("pokemap_history", { operation: "list", projectHandle, limit: 1 });
    await call("pokemap_history", { operation: "undo", projectHandle,
      entryId: record((history.entries as JsonRecord[])[0]).entryId,
      idempotencyKey: "undo-spatial-environment-regeneration" });
    assert.deepEqual(await readFile(mapPath), beforeRegeneration);
    assert.deepEqual(instances(await savedMap()).find(value => value.id === movedId), exact);
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

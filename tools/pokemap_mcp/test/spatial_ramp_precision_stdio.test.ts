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

function animatedUnitGlb(): Buffer {
  const document = {
    asset: { version: "2.0" }, scene: 0, scenes: [{ nodes: [0] }], nodes: [{ mesh: 0 }],
    buffers: [{ byteLength: 68 }],
    bufferViews: [{ buffer: 0, byteLength: 36 },
      { buffer: 0, byteOffset: 36, byteLength: 8 },
      { buffer: 0, byteOffset: 44, byteLength: 24 }],
    accessors: [{ bufferView: 0, componentType: 5126, count: 3, type: "VEC3" },
      { bufferView: 1, componentType: 5126, count: 2, type: "SCALAR" },
      { bufferView: 2, componentType: 5126, count: 2, type: "VEC3" }],
    meshes: [{ primitives: [{ attributes: { POSITION: 0 } }] }],
    animations: [{ name: "unit", samplers: [{ input: 1, output: 2 }],
      channels: [{ sampler: 0, target: { node: 0, path: "translation" } }] }],
  };
  const json = Buffer.from(JSON.stringify(document));
  const length = Math.ceil(json.length / 4) * 4;
  const bytes = Buffer.alloc(28 + length + 68);
  bytes.writeUInt32LE(0x46546c67, 0);
  bytes.writeUInt32LE(2, 4);
  bytes.writeUInt32LE(bytes.length, 8);
  bytes.writeUInt32LE(length, 12);
  bytes.writeUInt32LE(0x4e4f534a, 16);
  bytes.fill(32, 20, 20 + length);
  json.copy(bytes, 20);
  bytes.writeUInt32LE(68, 20 + length);
  bytes.writeUInt32LE(0x004e4942, 24 + length);
  [0, 0, 0, 1, 0, 0, 0, 1, 0].forEach((value, index) =>
    bytes.writeFloatLE(value, 28 + length + index * 4));
  bytes.writeFloatLE(1, 28 + length + 40);
  bytes.writeFloatLE(1, 28 + length + 56);
  return bytes;
}

function eastRampHeight(ramp: JsonRecord, x: number): number {
  const progress = Math.max(0, Math.min(1, (x - Number(ramp.x)) / Number(ramp.width)));
  return (Number(ramp.lowLevel) + (Number(ramp.highLevel) - Number(ramp.lowLevel)) * progress) * .25;
}

test("live MCP keeps source fractional ramp geometry and signed model offsets exact through reopen and undo", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-ramp-precision-mcp-"));
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root,
      "--dart", process.env.POKEMAP_TEST_DART ?? "dart",
      "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "ramp-precision-proof", version: "1.0.0" });
  async function call(name: string, args: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const response = await client.callTool({ name, arguments: args });
    assert.equal(response.isError, failure ? true : undefined,
      JSON.stringify(response.structuredContent ?? response.content));
    const envelope = record(response.structuredContent);
    return record(failure ? envelope.error : envelope.data);
  }
  try {
    await client.connect(transport);
    const catalog = await call("pokemap_describe");
    const descriptor = (catalog.mutationActions as JsonRecord[])
      .find(action => action.id === "map3d.navigation.configure");
    assert.ok(descriptor);
    assert.equal(descriptor.version, 1);
    assert.equal(descriptor.inputSchemaId, "schema.map3d.navigation.configure.input.v1");
    const schema = record(record(descriptor.extensions).inputSchema);
    const navigationSchema = record(record(schema.properties).navigation);
    const rampSchema = record(record(record(navigationSchema.properties).ramps).items);
    for (const field of ["x", "z", "width", "depth"]) {
      assert.equal(record(record(rampSchema.properties)[field]).type, "number");
    }

    const request = { name: "Fractional ramp", folderName: "ramp", parentPath: root,
      template: "empty", dimension: "threeD", mapWidth: 64, mapHeight: 24 };
    const creation = await call("pokemap_project_create_preview", { request });
    const created = await call("pokemap_project_create", {
      request, confirmation: creation.confirmation });
    const projectRoot = String(created.projectPath);
    let opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    let projectHandle = String(opened.projectHandle);
    let workspaceHandle = String(opened.workspaceHandle);
    const manifestPath = join(projectRoot, "project.json");
    const manifest = record(JSON.parse(await readFile(manifestPath, "utf8")));
    const mapEntry = record((manifest.maps as unknown[])[0]);
    const mapId = String(mapEntry.id);
    const mapPath = join(projectRoot, String(mapEntry.relativePath));
    let sequence = 0;
    async function plan(actionId: string, parameters: JsonRecord, failure = false): Promise<JsonRecord> {
      const validation = await call("pokemap_validate", { projectHandle });
      const before = await Promise.all([readFile(manifestPath), readFile(mapPath)]);
      const id = "ramp-precision-" + sequence++;
      const result = await call("pokemap_plan", { projectHandle, request: {
        requestId: id, actionId, actionVersion: 1, workspaceHandle, parameters,
        expectedRevision: validation.snapshotRevision, idempotencyKey: id } }, failure);
      assert.deepEqual(await Promise.all([readFile(manifestPath), readFile(mapPath)]), before);
      return result;
    }
    async function apply(planned: JsonRecord): Promise<void> {
      const applied = await call("pokemap_apply", { operation: "apply", projectHandle,
        planId: planned.planId, operationId: "ramp-precision-apply-" + sequence++ });
      assert.equal(record(applied.receipt).status, "applied");
    }
    async function mutate(actionId: string, parameters: JsonRecord): Promise<void> {
      await apply(await plan(actionId, parameters));
    }
    async function queryMap(): Promise<JsonRecord> {
      const response = await call("pokemap_query", { projectHandle, resourceKind: "map",
        operation: "get", ids: [mapId], view: "detail" });
      const map = record((response.items as unknown[])[0]);
      delete map.resourceKind;
      return map;
    }

    const modelPath = join(root, "unit.glb");
    await writeFile(modelPath, animatedUnitGlb());
    const staged = await call("pokemap_artifact_stage", {
      sourcePath: modelPath, declaredMediaType: "model/gltf-binary" });
    await mutate("model3d.import", { modelId: "unit", name: "Unit",
      artifactHandle: staged.artifactHandle });
    if (record((await queryMap()).spatialScene).levelHeight !== .25) {
      await mutate("map3d.terrain.configure_height", { mapId, levelHeight: .25 });
    }
    const heightLevels = Array.from({ length: 64 * 24 }, (_, index) => {
      const x = index % 64, z = Math.floor(index / 64);
      return x >= 60 ? 23 : z >= 19 && z <= 22 && x >= 7 ? 7 : 3;
    });
    await mutate("map3d.terrain.set_levels", { mapId, cells: heightLevels.map((level, index) => ({
      x: index % 64, z: Math.floor(index / 64), level,
    })) });
    const sourceRamp = { id: "route19-stairs", x: 54.998046875, z: 13.125,
      width: 5.001953125, depth: 1.75, lowLevel: 3, highLevel: 23, direction: "east" };
    const originalRamp = { ...sourceRamp, x: sourceRamp.x + .125, width: sourceRamp.width - .125 };
    const otherRamp = { id: "other", x: 4.25, z: 20.125, width: 2.75,
      depth: 1.5, lowLevel: 3, highLevel: 7, direction: "east" };
    const originalNavigation = { spawn: { x: 1.5, z: 1.5 }, allowDiagonalMovement: true,
      ramps: [originalRamp, otherRamp], blockedAreas: [{ x: 2, z: 4, width: 1, depth: 1 }] };
    await mutate("map3d.navigation.configure", { mapId, navigation: originalNavigation });
    const offsetY = -.375;
    const instanceX = 57.5;
    await mutate("map3d.instance.upsert_batch", { mapId, instances: [
      { id: "supported", modelId: "unit", position: {
        x: instanceX, y: eastRampHeight(originalRamp, instanceX) + offsetY, z: 14 },
      rotationDegrees: 37, scale: .8, animationIndex: 0,
      animationLoop: false, animationSpeed: .75, blocksMovement: false },
      { id: "other-supported", modelId: "unit", position: {
        x: 5.5, y: eastRampHeight(otherRamp, 5.5) + .125, z: 20.5 },
      rotationDegrees: 12, scale: 1.125, blocksMovement: false },
      { id: "outside", modelId: "unit", position: { x: 12.5, y: -2.7040466528, z: 10.5 },
        rotationDegrees: 91, scale: .75, blocksMovement: false },
    ] });
    const beforeBytes = await readFile(mapPath);
    const beforeManifest = await readFile(manifestPath);
    const before = await queryMap();
    assert.deepEqual(before, record(JSON.parse(beforeBytes.toString())));
    const beforeScene = record(before.spatialScene);
    assert.equal(beforeScene.levelHeight, .25);
    assert.deepEqual(beforeScene.heightLevels, heightLevels);
    const previousHistory = await call("pokemap_history", { operation: "list", projectHandle, limit: 2 });
    const navigation = { ...originalNavigation, ramps: [sourceRamp, otherRamp] };
    const invalid = await plan("map3d.navigation.configure", { mapId,
      navigation: { ...navigation, ramps: [{ ...sourceRamp, lowLevel: 0 }, otherRamp] } }, true);
    assert.equal(invalid.code, "validation_failed");
    assert.ok(JSON.stringify(invalid).includes("map3d.parameters_invalid"));
    assert.deepEqual((await call("pokemap_history", {
      operation: "list", projectHandle, limit: 2 })).entries, previousHistory.entries);
    await apply(await plan("map3d.navigation.configure", { mapId, navigation }));
    const afterBytes = await readFile(mapPath);
    const after = await queryMap();
    const expected = structuredClone(before);
    const expectedScene = record(expected.spatialScene);
    expectedScene.navigation = navigation;
    const supported = (expectedScene.instances as JsonRecord[]).find(value => value.id === "supported");
    assert.ok(supported);
    const position = record(supported.position);
    position.y = Number(position.y) +
      (eastRampHeight(sourceRamp, instanceX) - eastRampHeight(originalRamp, instanceX));
    assert.notEqual(position.y, record((beforeScene.instances as JsonRecord[])
      .find(value => value.id === "supported")!.position).y);
    assert.equal(Number(position.y) - eastRampHeight(sourceRamp, instanceX), offsetY);
    assert.deepEqual(after, expected);
    assert.deepEqual(record(JSON.parse(afterBytes.toString())), expected);
    assert.deepEqual(await readFile(manifestPath), beforeManifest);
    const history = await call("pokemap_history", { operation: "list", projectHandle, limit: 2 });
    const entries = history.entries as JsonRecord[];
    assert.equal(entries.length, 2);
    assert.equal(entries[1]!.entryId, (previousHistory.entries as JsonRecord[])[0]!.entryId);
    const mutationEntryId = entries[0]!.entryId;
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
    opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    projectHandle = String(opened.projectHandle);
    workspaceHandle = String(opened.workspaceHandle);
    assert.deepEqual(await queryMap(), expected);
    assert.deepEqual(await readFile(mapPath), afterBytes);
    assert.deepEqual(await readFile(manifestPath), beforeManifest);
    await call("pokemap_history", { operation: "undo", projectHandle,
      entryId: mutationEntryId, idempotencyKey: "undo-source-ramp-precision" });
    assert.deepEqual(await queryMap(), before);
    assert.deepEqual(await readFile(mapPath), beforeBytes);
    assert.deepEqual(await readFile(manifestPath), beforeManifest);
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

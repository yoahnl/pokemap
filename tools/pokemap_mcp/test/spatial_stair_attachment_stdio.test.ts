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

test("live MCP attaches stairs and keeps batch moves deletion reopen and undo atomic", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-attached-stairs-"));
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--artifact-root", root,
      "--dart", process.env.POKEMAP_TEST_DART ?? "dart", "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "attached-stairs-proof", version: "1.0.0" });
  async function call(name: string, args: JsonRecord = {}): Promise<JsonRecord> {
    const response = await client.callTool({ name, arguments: args });
    assert.equal(response.isError, undefined, JSON.stringify(response.structuredContent ?? response.content));
    return record(record(response.structuredContent).data);
  }
  try {
    await client.connect(transport);
    const catalog = await call("pokemap_describe");
    const descriptor = (catalog.mutationActions as JsonRecord[]).find(action => action.id === "model3d.configure");
    assert.ok(descriptor);
    const fields = record(record(record(descriptor.extensions).inputSchema).properties);
    assert.deepEqual(record(fields.rampProfile).type, ["object", "null"]);
    assert.ok((descriptor.resourceKinds as string[]).includes("map"));
    const request = { name: "Attached stairs", folderName: "stairs", parentPath: root,
      template: "empty", dimension: "threeD", mapWidth: 16, mapHeight: 16 };
    const preview = await call("pokemap_project_create_preview", { request });
    const created = await call("pokemap_project_create", { request, confirmation: preview.confirmation });
    const projectRoot = String(created.projectPath);
    let opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    let projectHandle = String(opened.projectHandle), workspaceHandle = String(opened.workspaceHandle);
    const manifest = record(JSON.parse(await readFile(join(projectRoot, "project.json"), "utf8")));
    const mapId = String(record((manifest.maps as unknown[])[0]).id);
    let sequence = 0;
    async function mutate(actionId: string, parameters: JsonRecord): Promise<void> {
      const validation = await call("pokemap_validate", { projectHandle });
      const id = "stairs-" + sequence++;
      const planned = await call("pokemap_plan", { projectHandle, request: {
        requestId: id, actionId, actionVersion: 1, workspaceHandle, parameters,
        expectedRevision: validation.snapshotRevision, idempotencyKey: id } });
      const applied = await call("pokemap_apply", { operation: "apply", projectHandle, planId: planned.planId, operationId: id });
      assert.equal(record(applied.receipt).status, "applied");
    }
    async function scene(): Promise<JsonRecord> {
      const response = await call("pokemap_query", { projectHandle, resourceKind: "map", operation: "get", ids: [mapId], view: "detail" });
      return record(record((response.items as unknown[])[0]).spatialScene);
    }
    const modelPath = join(root, "stairs.glb");
    await writeFile(modelPath, animatedUnitGlb());
    const staged = await call("pokemap_artifact_stage", { sourcePath: modelPath, declaredMediaType: "model/gltf-binary" });
    await mutate("model3d.import", { modelId: "stairs", name: "Stairs", artifactHandle: staged.artifactHandle });
    await mutate("model3d.configure", { modelId: "stairs", rampProfile: { x: 0, z: 0, width: 1, depth: 1, lowHeight: 0, highHeight: 1, direction: "north" } });
    const first = { id: "first", modelId: "stairs", position: { x: 3, y: 0, z: 4 }, rotationDegrees: 0, scale: 1, blocksMovement: true };
    const second = { ...first, id: "second", position: { x: 5, y: 0, z: 4 } };
    await mutate("map3d.instance.upsert_batch", { mapId, instances: [first, second] });
    const placed = await scene();
    assert.equal((record(placed.navigation).ramps as unknown[]).length, 2);
    assert.ok((placed.instances as JsonRecord[]).every(instance => instance.blocksMovement === false));
    await mutate("map3d.instance.upsert_batch", { mapId, instances: [{ ...first, position: second.position }, { ...second, position: first.position }] });
    await mutate("map3d.instance.upsert", { mapId, instance: { ...first, position: { x: 8, y: 0, z: 7 }, rotationDegrees: 90 } });
    const moved = await scene();
    const ramp = (record(moved.navigation).ramps as JsonRecord[]).find(r => r.surfaceInstanceId === "first");
    assert.ok(ramp);
    assert.deepEqual([ramp.x, ramp.z, ramp.width, ramp.depth, ramp.direction], [8, 6, 1, 1, "west"]);
    await mutate("map3d.instance.delete_batch", { mapId, instanceIds: ["first", "second"] });
    assert.deepEqual(record((await scene()).navigation).ramps, []);
    const history = await call("pokemap_history", { operation: "list", projectHandle, limit: 1 });
    await call("pokemap_history", { operation: "undo", projectHandle, entryId: (history.entries as JsonRecord[])[0]!.entryId, idempotencyKey: "undo-stair-delete" });
    assert.deepEqual(await scene(), moved);
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
    opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    projectHandle = String(opened.projectHandle); workspaceHandle = String(opened.workspaceHandle);
    assert.deepEqual(await scene(), moved);
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
  } finally {
    await client.close(); await transport.close(); await rm(root, { recursive: true, force: true });
  }
});

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

function triangleGlb(): Buffer {
  const document = {
    asset: { version: "2.0" }, scene: 0, scenes: [{ nodes: [0] }], nodes: [{ mesh: 0 }],
    buffers: [{ byteLength: 36 }], bufferViews: [{ buffer: 0, byteLength: 36 }],
    accessors: [{ bufferView: 0, componentType: 5126, count: 3, type: "VEC3" }],
    meshes: [{ primitives: [{ attributes: { POSITION: 0 } }] }],
  };
  const json = Buffer.from(JSON.stringify(document));
  const length = Math.ceil(json.length / 4) * 4;
  const bytes = Buffer.alloc(28 + length + 36);
  bytes.writeUInt32LE(0x46546c67, 0);
  bytes.writeUInt32LE(2, 4);
  bytes.writeUInt32LE(bytes.length, 8);
  bytes.writeUInt32LE(length, 12);
  bytes.writeUInt32LE(0x4e4f534a, 16);
  bytes.fill(32, 20, 20 + length);
  json.copy(bytes, 20);
  bytes.writeUInt32LE(36, 20 + length);
  bytes.writeUInt32LE(0x004e4942, 24 + length);
  [0, 0, 0, 1, 0, 0, 0, 1, 0].forEach((value, index) => bytes.writeFloatLE(value, 28 + length + index * 4));
  return bytes;
}

function placement(id: string, x = .5): JsonRecord {
  return { id, modelId: "house", position: { x, y: 0, z: .5 }, rotationDegrees: 90,
    scale: 1.5, animationLoop: false, animationSpeed: .5, blocksMovement: false };
}

test("live MCP validates, persists and rereads one atomic instance batch", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-instance-batch-mcp-"));
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root], cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "instance-batch-transport-proof", version: "1.0.0" });
  async function call(name: string, args: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: args });
    assert.equal(result.isError, failure ? true : undefined, JSON.stringify(result.structuredContent));
    const envelope = record(result.structuredContent);
    return record(failure ? envelope.error : envelope.data);
  }
  try {
    await client.connect(transport);
    const catalog = await call("pokemap_describe");
    const descriptor = (catalog.mutationActions as JsonRecord[]).find((action) => action.id === "map3d.instance.upsert_batch")!;
    assert.equal(descriptor.version, 1);
    assert.ok((descriptor.guarantees as string[]).includes("atomic"));
    assert.equal(record(descriptor.extensions).maximumInstanceCount, 50);
    const request = { name: "Instances", folderName: "instances", parentPath: root,
      template: "empty", dimension: "threeD", mapWidth: 8, mapHeight: 6 };
    const preview = await call("pokemap_project_create_preview", { request });
    const created = await call("pokemap_project_create", { request, confirmation: preview.confirmation });
    const projectRoot = String(created.projectPath);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    const projectHandle = String(opened.projectHandle);
    const workspaceHandle = String(opened.workspaceHandle);
    let sequence = 0;
    async function plan(actionId: string, parameters: JsonRecord, failure = false): Promise<JsonRecord> {
      const revision = (await call("pokemap_validate", { projectHandle })).snapshotRevision;
      const id = `instance-batch-${++sequence}`;
      return call("pokemap_plan", { projectHandle, request: { requestId: id, actionId,
        actionVersion: 1, workspaceHandle, parameters, expectedRevision: revision, idempotencyKey: id } }, failure);
    }
    async function mutate(actionId: string, parameters: JsonRecord): Promise<void> {
      const planned = await plan(actionId, parameters);
      const applied = await call("pokemap_apply", { operation: "apply", projectHandle,
        planId: planned.planId, operationId: `apply-instance-${sequence}` });
      assert.equal(record(applied.receipt).status, "applied");
    }
    const model = join(root, "house.glb");
    await writeFile(model, triangleGlb());
    const staged = await call("pokemap_artifact_stage", { sourcePath: model, declaredMediaType: "model/gltf-binary" });
    await mutate("model3d.import", { modelId: "house", name: "House", artifactHandle: staged.artifactHandle });
    const manifest = JSON.parse(await readFile(join(projectRoot, "project.json"), "utf8")) as JsonRecord;
    const entry = record((manifest.maps as unknown[])[0]);
    const mapId = String(entry.id);
    const mapPath = join(projectRoot, String(entry.relativePath));
    await mutate("map3d.instance.upsert", { mapId, instance: placement("keep") });
    const beforeMap = await readFile(mapPath);
    const beforeProject = await readFile(join(projectRoot, "project.json"));
    const invalid = await plan("map3d.instance.upsert_batch", { mapId,
      instances: [placement("valid"), { ...placement("missing"), modelId: "missing" }] }, true);
    assert.equal(invalid.domainCode, "map3d.instance.model_not_found");
    const duplicate = await plan("map3d.instance.upsert_batch", { mapId,
      instances: [placement("duplicate"), placement("duplicate")] }, true);
    assert.equal(duplicate.domainCode, "map3d.instance.batch_duplicate");
    assert.deepEqual(await readFile(mapPath), beforeMap);
    assert.deepEqual(await readFile(join(projectRoot, "project.json")), beforeProject);
    await mutate("map3d.instance.upsert_batch", { mapId,
      instances: [placement("keep", 1.5), placement("new", 2.5)] });
    assert.deepEqual(await readFile(join(projectRoot, "project.json")), beforeProject);
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
    const reopened = await call("pokemap_workspace", { operation: "open", projectRoot });
    const queried = await call("pokemap_query", { projectHandle: reopened.projectHandle,
      resourceKind: "map", operation: "get", ids: [mapId], view: "detail" });
    const map = record((queried.items as unknown[])[0]);
    const instances = record(map.spatialScene).instances as JsonRecord[];
    assert.deepEqual(instances.map((instance) => instance.id), ["keep", "new"]);
    assert.deepEqual(instances.map((instance) => instance.position),
      [{ x: 1.5, y: 0, z: .5 }, { x: 2.5, y: 0, z: .5 }]);
    assert.ok(instances.every((instance) => instance.rotationDegrees === 90 && instance.scale === 1.5 && instance.blocksMovement === false && instance.animationSpeed === .5));
    assert.equal(map.version, "v9");
    await call("pokemap_workspace", { operation: "close", workspaceHandle: reopened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

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

function glb(animated: boolean): Buffer {
  const binary = Buffer.alloc(animated ? 68 : 36);
  [0, 0, 0, 1, 0, 0, 0, 1, 0].forEach((value, index) =>
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
      type: "VEC3", min: [0, 0, 0], max: [1, 1, 0] }, ...(animated ? [
      { bufferView: 1, componentType: 5126, count: 2, type: "SCALAR" },
      { bufferView: 2, componentType: 5126, count: 2, type: "VEC3" },
    ] : [])],
    ...(animated ? { animations: [{ name: "Wind", samplers: [{ input: 1, output: 2 }],
      channels: [{ sampler: 0, target: { node: 0, path: "translation" } }] }] } : {}),
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
    const request = { name: "Model replacement", folderName: "models", parentPath: root,
      template: "empty", dimension: "threeD", mapWidth: 8, mapHeight: 6 };
    const preview = await call("pokemap_project_create_preview", { request });
    const created = await call("pokemap_project_create", { request, confirmation: preview.confirmation });
    const projectRoot = String(created.projectPath);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    const projectHandle = String(opened.projectHandle);
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
      artifactHandle: await stage(beforeBytes) }));
    await apply(await plan("model3d.configure", { modelId: "house", name: "Maison gardée",
      scale: 2.5, pivot: { x: 1, y: 2, z: -3 } }));
    const manifestPath = join(projectRoot, "project.json");
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
    for (const key of ["id", "name", "scale", "pivot", "sourceAssetId", "relativePath"]) {
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
      for (const key of ["id", "name", "scale", "pivot", "sourceAssetId", "relativePath"]) {
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
      assert.deepEqual(await readFile(join(projectRoot, String(previous.relativePath))), beforeBytes);
    }
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
    const reopened = await call("pokemap_workspace", { operation: "open", projectRoot });
    const restored = await call("pokemap_query", { projectHandle: reopened.projectHandle,
      resourceKind: "model3d", operation: "get", ids: ["house"], view: "detail" });
    assert.equal((record(record((restored.items as JsonRecord[])[0]).inspection).animations as JsonRecord[]).length, 0);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: reopened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

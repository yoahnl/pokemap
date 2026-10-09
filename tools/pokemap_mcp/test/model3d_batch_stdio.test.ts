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

function triangleGlb(external = false): Buffer {
  const document = {
    asset: { version: "2.0" }, scene: 0,
    scenes: [{ nodes: [0] }], nodes: [{ mesh: 0 }],
    meshes: [{ primitives: [{ attributes: { POSITION: 0 } }] }],
    buffers: [{ byteLength: 36, ...(external ? { uri: "outside.bin" } : {}) }],
    bufferViews: [{ buffer: 0, byteLength: 36 }],
    accessors: [{ bufferView: 0, componentType: 5126, count: 3,
      type: "VEC3", min: [0, 0, 0], max: [1, 1, 0] }],
  };
  const json = Buffer.from(JSON.stringify(document));
  const jsonLength = Math.ceil(json.length / 4) * 4;
  const output = Buffer.alloc(28 + jsonLength + 36);
  output.writeUInt32LE(0x46546c67, 0);
  output.writeUInt32LE(2, 4);
  output.writeUInt32LE(output.length, 8);
  output.writeUInt32LE(jsonLength, 12);
  output.writeUInt32LE(0x4e4f534a, 16);
  output.fill(32, 20, 20 + jsonLength);
  json.copy(output, 20);
  output.writeUInt32LE(36, 20 + jsonLength);
  output.writeUInt32LE(0x004e4942, 24 + jsonLength);
  [0, 0, 0, 1, 0, 0, 0, 1, 0].forEach((value, index) =>
    output.writeFloatLE(value, 28 + jsonLength + index * 4));
  return output;
}

test("live MCP imports a bounded recoverable model batch and rejects a trailing invalid GLB", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-model-batch-mcp-"));
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "model3d-batch-transport-proof", version: "1.0.0" });
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
      .find((action) => action.id === "model3d.import_batch")!;
    assert.ok(descriptor);
    assert.equal(descriptor.version, 1);
    const extension = record(descriptor.extensions);
    assert.equal(extension.maximumModelCount, 50);
    assert.equal(extension.maximumTotalByteLength, 64 * 1024 * 1024);
    assert.ok(!(descriptor.guarantees as string[]).includes("atomic"));
    const request = { name: "Model batch", folderName: "models", parentPath: root,
      template: "empty", dimension: "threeD", mapWidth: 8, mapHeight: 6 };
    const preview = await call("pokemap_project_create_preview", { request });
    const created = await call("pokemap_project_create", { request, confirmation: preview.confirmation });
    const projectRoot = String(created.projectPath);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    const projectHandle = String(opened.projectHandle);
    const workspaceHandle = String(opened.workspaceHandle);
    let sequence = 0;
    async function stage(name: string, bytes: Buffer): Promise<string> {
      const path = join(root, `${name}.glb`);
      await writeFile(path, bytes);
      return String((await call("pokemap_artifact_stage", {
        sourcePath: path, declaredMediaType: "model/gltf-binary" })).artifactHandle);
    }
    async function plan(models: JsonRecord[], failure = false): Promise<JsonRecord> {
      const validation = await call("pokemap_validate", { projectHandle });
      const id = `models-${++sequence}`;
      return call("pokemap_plan", { projectHandle, request: {
        requestId: id, actionId: "model3d.import_batch", actionVersion: 1,
        workspaceHandle, parameters: { models }, expectedRevision: validation.snapshotRevision,
        idempotencyKey: id } }, failure);
    }
    const validBytes = triangleGlb();
    const valid = await stage("valid", validBytes);
    const invalid = await stage("invalid", triangleGlb(true));
    const manifestPath = join(projectRoot, "project.json");
    const before = await readFile(manifestPath);
    await plan([{ modelId: "valid", name: "Valid", artifactHandle: valid },
      { modelId: "invalid", name: "Invalid", artifactHandle: invalid }], true);
    assert.deepEqual(await readFile(manifestPath), before);
    const handle = await stage("shared", validBytes);
    const planned = await plan(["house", "tree"].map((modelId) => ({
      modelId, name: modelId, artifactHandle: handle })));
    assert.deepEqual(await readFile(manifestPath), before);
    const operationId = "model-batch-apply";
    const applied = await call("pokemap_apply", { operation: "apply", projectHandle,
      planId: planned.planId, operationId });
    const replay = await call("pokemap_apply", { operation: "apply", projectHandle,
      planId: planned.planId, operationId });
    assert.equal(record(applied.receipt).receiptId, record(replay.receipt).receiptId);
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
    const reopened = await call("pokemap_workspace", { operation: "open", projectRoot });
    const models = await call("pokemap_query", { projectHandle: reopened.projectHandle,
      resourceKind: "model3d", operation: "list", view: "detail" });
    assert.deepEqual((models.items as JsonRecord[]).map((model) => model.id).sort(), ["house", "tree"]);
    for (const id of ["house", "tree"]) {
      assert.deepEqual(await readFile(join(projectRoot, "assets", "models3d", `${id}.glb`)), validBytes);
    }
    await call("pokemap_workspace", { operation: "close", workspaceHandle: reopened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

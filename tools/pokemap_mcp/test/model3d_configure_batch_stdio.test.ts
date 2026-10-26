import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
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
  const document = { asset: { version: "2.0" }, scene: 0,
    scenes: [{ nodes: [0] }], nodes: [{ mesh: 0 }],
    meshes: [{ primitives: [{ attributes: { POSITION: 0 } }] }],
    buffers: [{ byteLength: 36 }], bufferViews: [{ buffer: 0, byteLength: 36 }],
    accessors: [{ bufferView: 0, componentType: 5126, count: 3, type: "VEC3" }] };
  const json = Buffer.from(JSON.stringify(document));
  const length = Math.ceil(json.length / 4) * 4;
  const bytes = Buffer.alloc(28 + length + 36);
  bytes.writeUInt32LE(0x46546c67, 0); bytes.writeUInt32LE(2, 4); bytes.writeUInt32LE(bytes.length, 8);
  bytes.writeUInt32LE(length, 12); bytes.writeUInt32LE(0x4e4f534a, 16);
  bytes.fill(32, 20, 20 + length); json.copy(bytes, 20);
  bytes.writeUInt32LE(36, 20 + length); bytes.writeUInt32LE(0x004e4942, 24 + length);
  [0, 0, 0, 1, 0, 0, 0, 1, 0].forEach((value, i) => bytes.writeFloatLE(value, 28 + length + i * 4));
  return bytes;
}

test("live MCP configures fifty existing models with one recoverable manifest change", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-model-configure-batch-"));
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--artifact-root", root,
      "--dart", process.env.POKEMAP_TEST_DART ?? "dart", "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "configure-batch-proof", version: "1.0.0" });
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
      .find(action => action.id === "model3d.configure_batch");
    assert.ok(descriptor, "configure_batch must be discoverable through the fresh worker");
    assert.equal(record(descriptor.extensions).maximumModelCount, 50);
    assert.equal(record(descriptor.extensions).publicationSemantics, "recoverable_cross_file");
    assert.ok(!(descriptor.guarantees as string[]).includes("atomic"));
    const schema = record(record(descriptor.extensions).inputSchema);
    assert.deepEqual(schema.required, ["models"]);
    const request = { name: "Configuration batch", folderName: "game", parentPath: root,
      template: "empty", dimension: "threeD", mapWidth: 8, mapHeight: 6 };
    const preview = await call("pokemap_project_create_preview", { request });
    const created = await call("pokemap_project_create", { request, confirmation: preview.confirmation });
    const projectRoot = String(created.projectPath), manifestPath = join(projectRoot, "project.json");
    let opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    let projectHandle = String(opened.projectHandle), workspaceHandle = String(opened.workspaceHandle), serial = 0;
    async function plan(actionId: string, parameters: JsonRecord, failure = false) {
      const validation = await call("pokemap_validate", { projectHandle }), id = "configuration-" + serial++;
      return call("pokemap_plan", { projectHandle, request: { requestId: id, actionId,
        actionVersion: 1, workspaceHandle, parameters, expectedRevision: validation.snapshotRevision,
        idempotencyKey: id } }, failure);
    }
    async function apply(planned: JsonRecord, operationId: string) {
      return call("pokemap_apply", { operation: "apply", projectHandle, planId: planned.planId, operationId });
    }
    await call("pokemap_workshop",{operation:"prepare",projectHandle});
    const bytes = triangleGlb(), sourcePath = join(root, "source.glb");
    await writeFile(sourcePath, bytes);
    const staged = await call("pokemap_artifact_stage", { sourcePath, declaredMediaType: "model/gltf-binary" });
    const ids = Array.from({ length: 50 }, (_, index) => "model-" + index);
    await apply(await plan("model3d.import_batch", { models: ids.map(modelId => ({
      modelId, name: modelId, artifactHandle: staged.artifactHandle })) }), "import-models");
    const before = await readFile(manifestPath);
    const sourceCatalogPath = join(projectRoot, "assets", ".pokemap-assets.json");
    const beforeCatalog = await readFile(sourceCatalogPath);
    for (const models of [[], Array.from({ length: 51 }, (_, index) => ({ modelId: "model-" + index })),
      [{ modelId: ids[0], scale: 2 }, { modelId: ids[0], scale: 3 }],
      [{ modelId: ids[0], scale: 2 }, { modelId: ids[1], scale: 0 }],
      [{ modelId: ids[0], relativePath: "elsewhere.glb" }]]) {
      await plan("model3d.configure_batch", { models }, true);
      assert.deepEqual(await readFile(manifestPath), before);
      assert.deepEqual(await readFile(sourceCatalogPath), beforeCatalog);
    }
    const configured = ids.map((modelId, index) => ({ modelId, name: "Configured " + index,
      scale: 1 + index / 100, pivot: { x: index / 8, y: 0, z: -.5 },
      blocksMovementByDefault: false, collisionBounds: null, rampProfile: null }));
    const planned = await plan("model3d.configure_batch", { models: configured });
    const changeSet = record(record(planned.plan).changeSet);
    assert.equal((changeSet.changes as JsonRecord[]).filter(change => record(change.resource).kind === "project").length, 1);
    assert.equal((changeSet.changes as JsonRecord[]).length, 1);
    assert.deepEqual(await readFile(manifestPath), before);
    const applied = await apply(planned, "configure-models");
    const replay = await apply(planned, "configure-models");
    assert.equal(record(applied.receipt).receiptId, record(replay.receipt).receiptId);
    const saved = await readFile(manifestPath);
    const models = record(JSON.parse(saved.toString())).models3d as JsonRecord[];
    const original = record(JSON.parse(before.toString())).models3d as JsonRecord[];
    assert.equal(models.length, 50);
    for (const [index, model] of models.entries()) {
      const expected = configured[index], previous = original[index];
      assert.ok(expected && previous);
      assert.equal(model.id, ids[index]); assert.equal(model.name, expected.name);
      assert.equal(model.scale, expected.scale);
      assert.deepEqual(model.pivot, expected.pivot);
      assert.equal(model.blocksMovementByDefault, false);
      assert.equal(model.sourceAssetId, previous.sourceAssetId);
      assert.equal(model.relativePath, previous.relativePath);
      assert.deepEqual(model.inspection, previous.inspection);
      assert.deepEqual(await readFile(join(projectRoot, String(model.relativePath))), bytes);
    }
    assert.deepEqual(await readFile(sourceCatalogPath), beforeCatalog);
    const noOp = await plan("model3d.configure_batch", { models: configured });
    assert.equal(record(noOp.plan).applicable, false);
    assert.equal(record(noOp.plan).nonApplicableReason, "no_changes");
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
    opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    projectHandle = String(opened.projectHandle); workspaceHandle = String(opened.workspaceHandle);
    assert.equal((await call("pokemap_validate", { projectHandle })).valid, true);
    assert.deepEqual(await readFile(manifestPath), saved);
    const history = await call("pokemap_history", { operation: "list", projectHandle, limit: 1 });
    await call("pokemap_history", { operation: "undo", projectHandle,
      entryId: record((history.entries as JsonRecord[])[0]).entryId, idempotencyKey: "undo-configuration-batch" });
    assert.deepEqual(await readFile(manifestPath), before);
    assert.deepEqual(await readFile(sourceCatalogPath), beforeCatalog);
    const light = {localPosition:{x:0,y:2,z:0}, radius:4, intensity:1.2, colorRgb:0xbddfff, nightOnly:true,
      colorCycle:{colors:[0xbddfff,0xf2c8e5],periodSeconds:12},
      proximity:{mode:"near",enterDistance:3,exitDistance:4,fadeSeconds:.35}};
    const configuredLight = await plan("model3d.configure",{modelId:ids[0],light});
    await apply(configuredLight,"configure-light-behavior");
    const withLight=record(JSON.parse((await readFile(manifestPath)).toString())).models3d as JsonRecord[];
    assert.deepEqual(record(withLight[0]).light,light);
    const beforeInvalid=await readFile(manifestPath);
    await plan("model3d.configure",{modelId:ids[0],light:{...light,proximity:{mode:"near",enterDistance:5,exitDistance:3}}},true);
    assert.deepEqual(await readFile(manifestPath),beforeInvalid);
    assert.deepEqual(await readFile(sourceCatalogPath),beforeCatalog);
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
  } finally {
    await client.close(); await transport.close(); await rm(root, { recursive: true, force: true });
  }
});


test("native catalog light workshop is bounded, discoverable and durable over MCP", { timeout: 90_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "catalog-light-mcp-"));
  const dart = process.env.POKEMAP_TEST_DART ?? "dart";
  const packageRoot = resolve("../../packages/map_authoring");
  await promisify(execFile)(dart, [`--packages=${join(packageRoot, ".dart_tool/package_config.json")}`,
    join(packageRoot, "test/support/create_working_catalog_fixture.dart"), root, "--light-workshop"], { timeout: 60_000 });
  const transport = new StdioClientTransport({command: process.execPath, args: [resolve("dist/src/index.js"),
    "--root", root, "--dart", dart, "--authoring-timeout-ms", "60000"], cwd: process.cwd(), stderr: "pipe"});
  const client = new Client({name: "light-catalog-proof", version: "1"});
  async function call(name: string, input: JsonRecord = {}) {
    const response = record((await client.callTool({name, arguments: input})).structuredContent);
    assert.equal(response.ok, true, JSON.stringify(response)); return record(response.data);
  }
  try {
    const descriptor = await readFile(join(root, "project.json"));
    await client.connect(transport);
    const described = await call("pokemap_describe");
    const action = (described.mutationActions as JsonRecord[]).find(v => v.id === "model3d.configure");
    const schema = record(record(record(action!.extensions).inputSchema).properties);
    assert.ok(record(record(schema.light).properties).colorCycle);
    const opened = await call("pokemap_workspace", {operation: "open", projectRoot: root});
    await call("pokemap_workshop", {operation: "prepare", projectHandle: opened.projectHandle});
    const light = {localPosition: {x: .2, y: 2.1, z: -.1}, radius: 5, intensity: .8, colorRgb: 0xbddfff,
      nightOnly: true, colorCycle: {colors: [0xbddfff,0xf2c8e5], periodSeconds: 8},
      proximity: {mode: "near", enterDistance: 3, exitDistance: 4, fadeSeconds: .35}};
    for (const [index, value] of [light, null, light].entries()) {
      const parameters = {modelId: "lamp", light: value};
      const snapshot = await call("pokemap_workshop", {operation: "read", projectHandle: opened.projectHandle,
        actionId: "model3d.configure", parameters});
      assert.deepEqual(snapshot.maps, []);
      assert.equal((record(snapshot.project).models3d as unknown[]).length, 1);
      assert.deepEqual(record(snapshot.project).tilesets, []);
      const id = `light-${index}`;
      const planned = await call("pokemap_plan", {projectHandle: opened.projectHandle, request: {
        requestId: id, actionId: "model3d.configure", actionVersion: 1, workspaceHandle: opened.workspaceHandle,
        expectedRevision: snapshot.snapshotRevision, idempotencyKey: id, parameters}});
      await call("pokemap_apply", {operation: "apply", projectHandle: opened.projectHandle,
        planId: planned.planId, operationId: id});
      const after = await call("pokemap_workshop", {operation: "read", projectHandle: opened.projectHandle,
        actionId: "model3d.configure", parameters});
      const stored = (record(after.project).models3d as JsonRecord[])[0]!;
      assert.deepEqual(stored.light ?? null, value);
      assert.deepEqual(await readFile(join(root,"project.json")),descriptor);
    }
    await call("pokemap_workspace", {operation: "close", workspaceHandle: opened.workspaceHandle});
  } finally {await client.close();await transport.close();await rm(root,{recursive:true,force:true});}
});

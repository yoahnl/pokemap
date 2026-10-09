import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import test from "node:test";
import { isDeepStrictEqual } from "node:util";
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

test("live MCP bounds batch plans with a large model library and unrelated presets", async () => {
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
    assert.equal(extension.diffProjection, "batch_model_additions");
    assert.equal(extension.maximumInlineModelDiffByteLength, 8 * 1024);
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
    const manifest = JSON.parse((await readFile(manifestPath)).toString()) as JsonRecord;
    const assetCatalogPath = join(projectRoot, "assets", ".pokemap-assets.json");
    const assetCatalog = JSON.parse((await readFile(assetCatalogPath)).toString()) as JsonRecord;
    const templateModel = record((manifest.models3d as JsonRecord[])[0]);
    const templateAsset = (assetCatalog.records as JsonRecord[])
      .find((asset) => asset.id === templateModel.sourceAssetId)!;
    const existingModels = Array.from({ length: 300 }, (_, i) => ({
      ...templateModel, id: `existing-${i}`, name: `Existing ${i}`,
      sourceAssetId: `model3d_existing-${i}`,
      relativePath: `assets/models3d/existing-${i}.glb`,
      inspection: { ...record(templateModel.inspection),
        diagnostics: ["existing inspection ".repeat(512)] },
    }));
    manifest.models3d = [...manifest.models3d as JsonRecord[], ...existingModels];
    assetCatalog.records = [...assetCatalog.records as JsonRecord[],
      ...existingModels.map((model) => ({ ...templateAsset,
        id: model.sourceAssetId, logicalPath: model.relativePath }))];
    manifest.smartTileCatalog = { formatVersion: 4,
      categories: [], atlases: [], materials: [], animations: [], presets: [], patterns: [],
      drafts: [{ id: "unrelated-draft", targetPresetId: "unrelated-preset",
        sourcePresetId: null, name: "Unrelated large preset", categoryId: "",
        usage: "terrain", lastStage: "image", guideId: null, sourceTilesetIds: [],
        atlases: [], primaryAtlasId: null, materials: [], animations: [],
        defaultMaterialId: null, allowedMaterialIds: [], topology: "uniform",
        templateHint: "simple", boundaryPolicy: "empty", coveragePolicy: "complete",
        coverageProfile: { mode: "explicit", allowFallback: false,
          requiredScenarios: Array.from({ length: 5000 }, (_, i) => ({
            id: `unrelated-scenario-${i}`, centerMaterialId: null, signature: {
              northEdge: null, eastEdge: null, southEdge: null, westEdge: null,
              northEastCorner: null, southEastCorner: null,
              southWestCorner: null, northWestCorner: null } })) },
        transformPolicy: { allowHFlip: false, allowVFlip: false,
          allowQuarterTurns: false, preferUntransformed: true },
        rules: [], fallbackRuleId: null, tags: [], sortOrder: 0, seedSalt: 0 }] };
    for (const model of existingModels) {
      await writeFile(join(projectRoot, model.relativePath), validBytes);
    }
    await writeFile(assetCatalogPath, JSON.stringify(assetCatalog));
    await writeFile(manifestPath, JSON.stringify(manifest));
    const largeBefore = await readFile(manifestPath);
    const largeOpened = await call("pokemap_workspace", { operation: "open", projectRoot });
    const largeValidation = await call("pokemap_validate", { projectHandle: largeOpened.projectHandle });
    const largeHandle = await stage("large-shared", validBytes);
    const ids = Array.from({ length: 50 }, (_, i) => `new-${i}`);
    const largePlanned = await call("pokemap_plan", { projectHandle: largeOpened.projectHandle,
      request: { requestId: "large-model-batch", actionId: "model3d.import_batch", actionVersion: 1,
        workspaceHandle: largeOpened.workspaceHandle,
        parameters: { models: ids.map((modelId) => ({
          modelId, name: modelId, artifactHandle: largeHandle })) },
        expectedRevision: largeValidation.snapshotRevision, idempotencyKey: "large-model-batch" } });
    const projectedWire = JSON.stringify(largePlanned);
    assert.ok(Buffer.byteLength(projectedWire) < 512 * 1024);
    assert.ok(!projectedWire.includes("existing inspection"));
    assert.ok(!projectedWire.includes("unrelated-scenario"));
    const modelDiffs = (record(record(record(largePlanned.plan).changeSet).diff).entries as JsonRecord[])
      .filter((entry) => record(entry.resource).kind === "project");
    assert.deepEqual(modelDiffs.map((entry) => entry.path).sort(),
      ids.map((id) => `/models3d/${id}`).sort());
    assert.ok(modelDiffs.every((entry) => entry.operation === "add"));
    assert.deepEqual(await readFile(manifestPath), largeBefore);
    await call("pokemap_apply", { operation: "apply", projectHandle: largeOpened.projectHandle,
      planId: largePlanned.planId, operationId: "large-model-batch-apply" });
    const largeAfter = JSON.parse((await readFile(manifestPath)).toString()) as JsonRecord;
    assert.deepEqual((largeAfter.models3d as JsonRecord[]).slice(0, 302), manifest.models3d);
    assert.ok(isDeepStrictEqual(largeAfter.smartTileCatalog, manifest.smartTileCatalog),
      "Unrelated preset data changed during the batch publication");
    assert.deepEqual((largeAfter.models3d as JsonRecord[]).slice(302).map((model) => model.id), ids);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: largeOpened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

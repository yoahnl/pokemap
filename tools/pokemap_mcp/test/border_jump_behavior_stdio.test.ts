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

function ledgeGlb(): Buffer {
  const binary = Buffer.alloc(36);
  [-.2, 0, -.2, .2, 0, -.2, 0, 1, .2].forEach((value, index) =>
    binary.writeFloatLE(value, index * 4));
  const json = Buffer.from(JSON.stringify({
    asset: { version: "2.0" }, scene: 0,
    scenes: [{ nodes: [0] }], nodes: [{ mesh: 0 }],
    meshes: [{ primitives: [{ attributes: { POSITION: 0 } }] }],
    buffers: [{ byteLength: 36 }], bufferViews: [{ buffer: 0, byteLength: 36 }],
    accessors: [{ bufferView: 0, componentType: 5126, count: 3, type: "VEC3",
      min: [-.2, 0, -.2], max: [.2, 1, .2] }],
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

test("live MCP exposes and preserves the typed Border jump property", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-border-jump-mcp-"));
  const dart = process.env.POKEMAP_TEST_DART;
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root,
      "--authoring-timeout-ms", "60000", ...(dart ? ["--dart", dart] : [])],
    cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "border-jump-data-proof", version: "1.0.0" });
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
    const actions = catalog.mutationActions as JsonRecord[];
    for (const id of ["border.blueprint.draft.upsert", "border.blueprint.publish"]) {
      const extension = record(record(actions.find(action => action.id === id)!.extensions)
        .directedJumpBehavior);
      assert.equal(extension.property, "definition.jumpBehavior");
      assert.equal(extension.owner, "borderBlueprint");
      assert.equal(extension.persistedGameplayZone, false);
      assert.equal(record(extension.schema).additionalProperties, false);
      assert.equal(record(record(record(extension.schema).properties).distanceCells).const, 2);
    }
    const request = { name: "Border jump data", folderName: "jump", parentPath: root,
      template: "empty", dimension: "threeD", mapWidth: 8, mapHeight: 6 };
    const preview = await call("pokemap_project_create_preview", { request });
    const created = await call("pokemap_project_create", { request, confirmation: preview.confirmation });
    const projectRoot = String(created.projectPath);
    let opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    let projectHandle = String(opened.projectHandle), workspaceHandle = String(opened.workspaceHandle);
    const manifestPath = join(projectRoot, "project.json");
    const initial = record(JSON.parse(await readFile(manifestPath, "utf8")));
    const mapPath = join(projectRoot, String((initial.maps as JsonRecord[])[0]!.relativePath));
    const mapBefore = await readFile(mapPath);
    let sequence = 0;
    async function mutate(actionId: string, parameters: JsonRecord, failure = false): Promise<void> {
      const validation = await call("pokemap_validate", { projectHandle });
      const id = `border-jump-${sequence++}`;
      const planned = await call("pokemap_plan", { projectHandle, request: {
        requestId: id, actionId, actionVersion: 1, workspaceHandle, parameters,
        expectedRevision: validation.snapshotRevision, idempotencyKey: id } }, failure);
      if (failure) return;
      const applied = await call("pokemap_apply", { operation: "apply", projectHandle,
        planId: planned.planId, operationId: `border-jump-apply-${sequence++}` });
      assert.equal(record(applied.receipt).status, "applied");
    }
    const modelPath = join(root, "ledge.glb");
    await writeFile(modelPath, ledgeGlb());
    const artifact = await call("pokemap_artifact_stage", {
      sourcePath: modelPath, declaredMediaType: "model/gltf-binary" });
    await mutate("model3d.import", { modelId: "ledge-unit", name: "Ledge",
      artifactHandle: artifact.artifactHandle });
    const jump = { side: "inverted", distanceCells: 2, durationMs: 750, peakHeightPx: 36 };
    const definition = { name: "Jump ledge", previewSeed: "17", template: "connectedLine", sortOrder: 0,
      primitives: ["lineCap", "lineStraight", "lineCorner"].map(role => ({
        id: role, role, sourceModelId: "ledge-unit", weight: 1,
        anchorWorld: { x: 0, y: 0, z: 0 },
        transforms: { allowFlipX: false, allowedQuarterTurns: [0, 1, 2, 3] },
      })), defaults: { irregularityPermille: 0, detailDensityPermille: 0,
        variationPermille: 0, maxOverlapPx: 0, gapTolerancePx: 0, depthRows: 1 },
      jumpBehavior: jump };
    const manifestBeforeInvalid = await readFile(manifestPath);
    await mutate("border.blueprint.draft.upsert", { record: { id: "ledge", draft: {
      baseRevision: 0, definition: { ...definition, jumpBehavior: { ...jump, distanceCells: 3 } } } } }, true);
    assert.deepEqual(await readFile(manifestPath), manifestBeforeInvalid);
    await mutate("border.blueprint.draft.upsert", { record: { id: "ledge",
      draft: { baseRevision: 0, definition } } });
    await mutate("border.blueprint.publish", { blueprintId: "ledge" });
    const published = record(JSON.parse(await readFile(manifestPath, "utf8")));
    assert.equal(record(published.borderCatalog).formatVersion, 6);
    for (const reopening of [false, true]) {
      if (reopening) {
        await call("pokemap_workspace", { operation: "close", workspaceHandle });
        opened = await call("pokemap_workspace", { operation: "open", projectRoot });
        projectHandle = String(opened.projectHandle); workspaceHandle = String(opened.workspaceHandle);
      }
      const query = await call("pokemap_query", { projectHandle, resourceKind: "borderBlueprint",
        operation: "get", ids: ["ledge"], view: "detail" });
      const queried = record((query.items as JsonRecord[])[0]);
      for (const branch of ["draft", "latestPublished"]) {
        assert.deepEqual(record(record(queried[branch]).definition).jumpBehavior, jump);
      }
    }
    assert.deepEqual(await readFile(mapPath), mapBefore);
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

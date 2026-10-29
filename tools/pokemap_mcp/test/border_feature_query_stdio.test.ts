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
  const json = Buffer.from(JSON.stringify(document)), length = Math.ceil(json.length / 4) * 4;
  const bytes = Buffer.alloc(28 + length + 36);
  bytes.writeUInt32LE(0x46546c67, 0); bytes.writeUInt32LE(2, 4); bytes.writeUInt32LE(bytes.length, 8);
  bytes.writeUInt32LE(length, 12); bytes.writeUInt32LE(0x4e4f534a, 16);
  bytes.fill(32, 20, 20 + length); json.copy(bytes, 20);
  bytes.writeUInt32LE(36, 20 + length); bytes.writeUInt32LE(0x004e4942, 24 + length);
  [-.5, 0, 0, .5, 0, 0, .5, 1, 0].forEach((value, i) => bytes.writeFloatLE(value, 28 + length + i * 4));
  return bytes;
}

test("live MCP lists and details Border features with their slot diagnostics", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-border-feature-query-mcp-"));
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--artifact-root", root,
      "--dart", process.env.POKEMAP_TEST_DART ?? "dart", "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "border-feature-query-proof", version: "1.0.0" });
  async function call(name: string, args: JsonRecord = {}): Promise<JsonRecord> {
    const response = await client.callTool({ name, arguments: args });
    assert.equal(response.isError, undefined, JSON.stringify(response.structuredContent ?? response.content));
    return record(record(response.structuredContent).data);
  }
  async function failure(name: string, args: JsonRecord): Promise<string> {
    const response = await client.callTool({ name, arguments: args });
    assert.equal(response.isError, true);
    return JSON.stringify(response.structuredContent ?? response.content);
  }
  try {
    await client.connect(transport);
    const catalog = await call("pokemap_describe");
    const kind = (catalog.resourceKinds as JsonRecord[]).find(entry => entry.id === "borderFeature");
    assert.equal(record(record(kind!.extensions).query).idFormat, "<layerId>/<featureId>");
    const request = { name: "Border feature query", folderName: "game", parentPath: root,
      template: "empty", dimension: "threeD", mapWidth: 24, mapHeight: 12 };
    const preview = await call("pokemap_project_create_preview", { request });
    const created = await call("pokemap_project_create", { request, confirmation: preview.confirmation });
    const projectRoot = String(created.projectPath), projectPath = join(projectRoot, "project.json");
    const legacy = record(JSON.parse(await readFile(projectPath, "utf8")));
    const mapId = String(record((legacy.maps as unknown[])[0]).id);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    const projectHandle = String(opened.projectHandle), workspaceHandle = String(opened.workspaceHandle);
    let serial = 0;
    async function mutate(actionId: string, parameters: JsonRecord): Promise<void> {
      const validation = await call("pokemap_validate", { projectHandle }), id = "query-" + serial++;
      const planned = await call("pokemap_plan", { projectHandle, request: { requestId: id, actionId,
        actionVersion: 1, workspaceHandle, parameters, expectedRevision: validation.snapshotRevision,
        idempotencyKey: id } });
      const applied = await call("pokemap_apply", { operation: "apply", projectHandle,
        planId: planned.planId, operationId: "apply-query-" + serial });
      assert.equal(record(applied.receipt).status, "applied");
    }
    const sourcePath = join(root, "unit.glb"); await writeFile(sourcePath, unitGlb());
    const staged = await call("pokemap_artifact_stage", { sourcePath, declaredMediaType: "model/gltf-binary" });
    await call("pokemap_workshop", { operation: "prepare", projectHandle });
    await mutate("model3d.import", { modelId: "unit", name: "Unit", artifactHandle: staged.artifactHandle });
    const definition = { name: "Directed face", previewSeed: "1", template: "connectedLine",
      straightOnly: true, followContourDirection: true, sortOrder: 0,
      primitives: ["lineStraight", "lineCap"].map(role => ({ id: role, sourceModelId: "unit", role, weight: 1,
        authoredOrientation: "east", anchorWorld: { x: 0, y: 1, z: 0 },
        transforms: { allowFlipX: false, allowedQuarterTurns: [0, 1, 2, 3] } })),
      defaults: { irregularityPermille: 0, detailDensityPermille: 0, variationPermille: 1000,
        maxOverlapPx: 0, gapTolerancePx: 0, depthRows: 1 } };
    await mutate("border.blueprint.draft.upsert", { record: { id: "face", draft: { baseRevision: 0, definition } } });
    await mutate("border.blueprint.publish", { blueprintId: "face" });
    await mutate("map.apply_operations", { mapId, operations: [{ kind: "layer.add", layerKind: "border",
      layerId: "border", name: "Face" }] });
    const target = { mapId, layerId: "border", featureId: "face" };
    await mutate("border_layer.feature_create", { ...target, blueprintId: "face", name: "Face", seed: "3",
      geometry: { kind: "stroke", alignment: "gridEdges", strokes: [{ id: "line", closed: false,
        points: Array.from({ length: 6 }, (_, i) => ({ x: 2 + i, y: 4 })) }] } });
    const unmaterialized = await call("pokemap_query", { projectHandle, resourceKind: "borderFeature",
      operation: "list", filters: { mapId } });
    assert.equal(record((unmaterialized.items as unknown[])[0]).materialization, "missing");
    await mutate("border_layer.materialize_apply", target);

    const listed = await call("pokemap_query", { projectHandle, resourceKind: "borderFeature",
      operation: "list", filters: { mapId } });
    const summary = record((listed.items as unknown[])[0]);
    assert.equal(summary.id, "border/face");
    assert.equal(summary.materialization, "fresh");
    assert.equal(summary.status, "warning");
    assert.equal(summary.slotCount, 6);
    assert.equal(summary.warningCount, 6);
    assert.equal(summary.diagnostics, undefined);

    const detailed = await call("pokemap_query", { projectHandle, resourceKind: "borderFeature",
      operation: "get", ids: ["border/face"], filters: { mapId }, view: "detail" });
    const item = record((detailed.items as unknown[])[0]);
    const slots = item.slots as JsonRecord[], diagnostics = item.diagnostics as JsonRecord[];
    assert.equal(slots.length, 6);
    assert.ok(slots.every(slot => slot.modelId === "unit" && typeof slot.slotKey === "string"
      && ["lineStraight", "lineCap"].includes(String(slot.role))));
    const faces = diagnostics.filter(entry => entry.code === "border.spatial.face_base_mismatch");
    assert.deepEqual(new Set(faces.map(entry => entry.slotKey)), new Set(slots.map(slot => slot.slotKey)));
    assert.equal(record(faces[0]?.parameters).lowerGroundHeight, 0);

    assert.match(await failure("pokemap_query", { projectHandle, resourceKind: "borderFeature",
      operation: "list" }), /query.border_feature_map_required/);
    assert.match(await failure("pokemap_query", { projectHandle, resourceKind: "borderFeature",
      operation: "get", ids: ["face"], filters: { mapId } }), /query.resource_not_found/);
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

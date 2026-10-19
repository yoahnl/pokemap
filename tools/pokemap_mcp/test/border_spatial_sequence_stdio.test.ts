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

test("live MCP publishes cyclic native Borders and preserves phases after erase move and reopen", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-border-sequence-mcp-"));
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--artifact-root", root,
      "--dart", process.env.POKEMAP_TEST_DART ?? "dart", "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "native-border-sequence-proof", version: "1.0.0" });
  async function call(name: string, args: JsonRecord = {}): Promise<JsonRecord> {
    const response = await client.callTool({ name, arguments: args });
    assert.equal(response.isError, undefined, JSON.stringify(response.structuredContent ?? response.content));
    return record(record(response.structuredContent).data);
  }
  try {
    await client.connect(transport);
    const catalog = await call("pokemap_describe");
    const publish = (catalog.mutationActions as JsonRecord[]).find(action => action.id === "border.blueprint.publish");
    assert.equal(record(record(publish!.extensions).spatialSequence).minimumCatalogFormatVersion, 12);
    const request = { name: "Native cyclic border", folderName: "game", parentPath: root,
      template: "empty", dimension: "threeD", mapWidth: 24, mapHeight: 12 };
    const preview = await call("pokemap_project_create_preview", { request });
    const created = await call("pokemap_project_create", { request, confirmation: preview.confirmation });
    const projectRoot = String(created.projectPath), projectPath = join(projectRoot, "project.json");
    let opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    let projectHandle = String(opened.projectHandle), workspaceHandle = String(opened.workspaceHandle), serial = 0;
    const manifest = record(JSON.parse(await readFile(projectPath, "utf8")));
    const entry = record((manifest.maps as unknown[])[0]), mapId = String(entry.id);
    const mapPath = join(projectRoot, String(entry.relativePath));
    async function plan(actionId: string, parameters: JsonRecord) {
      const validation = await call("pokemap_validate", { projectHandle }), id = "sequence-" + serial++;
      return { projectHandle, request: { requestId: id, actionId, actionVersion: 1, workspaceHandle,
        parameters, expectedRevision: validation.snapshotRevision, idempotencyKey: id } };
    }
    async function mutate(actionId: string, parameters: JsonRecord): Promise<void> {
      const beforeMap = await readFile(mapPath), beforeProject = await readFile(projectPath);
      const planned = await call("pokemap_plan", await plan(actionId, parameters));
      assert.deepEqual(await readFile(mapPath), beforeMap);
      assert.deepEqual(await readFile(projectPath), beforeProject);
      const applied = await call("pokemap_apply", { operation: "apply", projectHandle,
        planId: planned.planId, operationId: "apply-sequence-" + serial });
      assert.equal(record(applied.receipt).status, "applied");
    }
    const sourcePath = join(root, "unit.glb"); await writeFile(sourcePath, unitGlb());
    const staged = await call("pokemap_artifact_stage", { sourcePath, declaredMediaType: "model/gltf-binary" });
    await mutate("model3d.import", { modelId: "unit", name: "Unit", artifactHandle: staged.artifactHandle });
    const definition = { name: "Six-step fence", previewSeed: "1", template: "connectedLine",
      straightOnly: true, sequenceLength: 6, sortOrder: 0,
      primitives: Array.from({ length: 6 }, (_, sequenceIndex) => ["body", "start", "end"].map(kind => ({
        id: kind + "-" + sequenceIndex, sourceModelId: "unit", sequenceIndex,
        role: kind === "body" ? "lineStraight" : "lineCap", weight: 1,
        authoredOrientation: kind === "end" ? "west" : "east",
        transforms: { allowFlipX: false, allowedQuarterTurns: [0, 1] } }))).flat(),
      defaults: { irregularityPermille: 0, detailDensityPermille: 0, variationPermille: 1000,
        maxOverlapPx: 0, gapTolerancePx: 0, depthRows: 1 } };
    await mutate("border.blueprint.draft.upsert", { record: { id: "fence", draft: { baseRevision: 0, definition } } });
    await mutate("border.blueprint.publish", { blueprintId: "fence" });
    const savedProject = record(JSON.parse(await readFile(projectPath, "utf8")));
    const borderCatalog = record(savedProject.borderCatalog), blueprint = record((borderCatalog.records as unknown[])[0]);
    assert.equal(borderCatalog.formatVersion, 12);
    for (const field of ["draft", "latestPublished"]) {
      const saved = record(record(blueprint[field]).definition);
      assert.equal(saved.sequenceLength, 6);
      assert.deepEqual((saved.primitives as JsonRecord[]).map(p => p.sequenceIndex ?? 0),
        Array.from({ length: 6 }, (_, phase) => [phase, phase, phase]).flat());
    }
    await mutate("map.apply_operations", { mapId, operations: [{ kind: "layer.add", layerKind: "border", layerId: "border", name: "Fence" }] });
    const target = { mapId, layerId: "border", featureId: "fence" };
    await mutate("border_layer.feature_create", { ...target, blueprintId: "fence", name: "Fence", seed: "31",
      geometry: { kind: "stroke", strokes: [{ id: "line", closed: false,
        points: Array.from({ length: 12 }, (_, i) => ({ x: 12 - i, y: 2 })) }] } });
    await mutate("border_layer.materialize_apply", target);
    const featureOf = (map: JsonRecord) => record((record((map.layers as JsonRecord[])
      .find(layer => layer.id === "border")!.content).features as unknown[])[0]);
    const placements = (map: JsonRecord) => record(featureOf(map).materialization).spatialPlacements as JsonRecord[];
    const original = record(JSON.parse(await readFile(mapPath, "utf8")));
    assert.deepEqual(placements(original).map(p => Number(String(p.primitiveId).split("-").at(-1))),
      Array.from({ length: 12 }, (_, i) => i % 6));
    await mutate("border_layer.stroke_erase", { ...target, points: [{ x: 4, y: 2 }] });
    const erased = record(JSON.parse(await readFile(mapPath, "utf8")));
    const instances = new Map((record(erased.spatialScene).instances as JsonRecord[]).map(i => [i.id, i]));
    const phasesByX = new Map(placements(erased).map(p => [Number(record(instances.get(p.instanceId)!.position).x),
      Number(String(p.primitiveId).split("-").at(-1))]));
    assert.equal(phasesByX.size, 11);
    for (let x = 1; x <= 12; x++) if (x !== 4) assert.equal(phasesByX.get(x + .5), (x - 1) % 6);
    await mutate("border_layer.feature_move", { ...target, dx: 2, dy: 1 });
    await mutate("border_layer.materialize_apply", target);
    const savedBytes = await readFile(mapPath), saved = record(JSON.parse(savedBytes.toString()));
    const movedInstances = new Map((record(saved.spatialScene).instances as JsonRecord[]).map(i => [i.id, i]));
    for (const placement of placements(saved)) {
      const x = Number(record(movedInstances.get(placement.instanceId)!.position).x);
      assert.equal(Number(String(placement.primitiveId).split("-").at(-1)), phasesByX.get(x - 2));
    }
    const beforeRejected = await readFile(projectPath);
    const rejected = await client.callTool({ name: "pokemap_plan",
      arguments: await plan("border_layer.feature_update", { ...target, lineSide: "inverted" }) });
    assert.equal(rejected.isError, true);
    assert.deepEqual(await readFile(mapPath), savedBytes);
    assert.deepEqual(await readFile(projectPath), beforeRejected);
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
    opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    projectHandle = String(opened.projectHandle); workspaceHandle = String(opened.workspaceHandle);
    assert.equal((await call("pokemap_validate", { projectHandle })).valid, true);
    assert.deepEqual(await readFile(mapPath), savedBytes);
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
  } finally {
    await client.close(); await transport.close(); await rm(root, { recursive: true, force: true });
  }
});

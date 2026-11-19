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

function faceGlb(height: number): Buffer {
  const binary = Buffer.alloc(36);
  [-.2, 0, -.2, .2, 0, -.2, 0, height, .2].forEach((value, index) =>
    binary.writeFloatLE(value, index * 4));
  const json = Buffer.from(JSON.stringify({
    asset: { version: "2.0" }, scene: 0, scenes: [{ nodes: [0] }], nodes: [{ mesh: 0 }],
    meshes: [{ primitives: [{ attributes: { POSITION: 0 } }] }],
    buffers: [{ byteLength: 36 }], bufferViews: [{ buffer: 0, byteLength: 36 }],
    accessors: [{ bufferView: 0, componentType: 5126, count: 3, type: "VEC3",
      min: [-.2, 0, -.2], max: [.2, height, .2] }],
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

test("live MCP paints a relief level, traces its cliff and undoes it as one edit", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-relief-paint-mcp-"));
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root,
      "--dart", process.env.POKEMAP_TEST_DART ?? "dart", "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "relief-paint-proof", version: "1.0.0" });
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
      .find(action => action.id === "map3d.terrain.paint_height");
    assert.ok(descriptor);
    assert.ok((descriptor.guarantees as string[]).includes("undoable"));
    const schema = record(record(descriptor.extensions).inputSchema);
    assert.deepEqual(schema.required, ["mapId", "level", "blueprintId"]);
    assert.ok(record(schema.properties).twoLevelBlueprintId);
    const request = { name: "Relief", folderName: "relief", parentPath: root,
      template: "empty", dimension: "threeD", mapWidth: 10, mapHeight: 8 };
    const preview = await call("pokemap_project_create_preview", { request });
    const created = await call("pokemap_project_create", { request, confirmation: preview.confirmation });
    const projectRoot = String(created.projectPath);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    const projectHandle = String(opened.projectHandle);
    const workspaceHandle = String(opened.workspaceHandle);
    const manifestPath = join(projectRoot, "project.json");
    const entry = record((record(JSON.parse(await readFile(manifestPath, "utf8"))).maps as unknown[])[0]);
    const mapId = String(entry.id);
    const mapPath = join(projectRoot, String(entry.relativePath));
    const levelHeight = Number(record(record(JSON.parse(await readFile(mapPath, "utf8"))).spatialScene)
      .levelHeight ?? 1);
    let sequence = 0;
    async function plan(actionId: string, parameters: JsonRecord, failure = false): Promise<JsonRecord> {
      const validation = await call("pokemap_validate", { projectHandle });
      const before = await readFile(mapPath);
      const id = "relief-" + sequence++;
      const planned = await call("pokemap_plan", { projectHandle, request: {
        requestId: id, actionId, actionVersion: 1, workspaceHandle, parameters,
        expectedRevision: validation.snapshotRevision, idempotencyKey: id } }, failure);
      assert.deepEqual(await readFile(mapPath), before);
      return planned;
    }
    async function mutate(actionId: string, parameters: JsonRecord): Promise<JsonRecord> {
      const planned = await plan(actionId, parameters);
      await call("pokemap_apply", { operation: "apply", projectHandle,
        planId: planned.planId, operationId: "relief-apply-" + sequence++ });
      return planned;
    }
    const modelPath = join(root, "face.glb");
    await writeFile(modelPath, faceGlb(levelHeight));
    const artifact = await call("pokemap_artifact_stage", {
      sourcePath: modelPath, declaredMediaType: "model/gltf-binary" });
    await mutate("model3d.import", { modelId: "face", name: "Face", artifactHandle: artifact.artifactHandle });
    await mutate("border.blueprint.draft.upsert", { record: { id: "cliff", draft: { baseRevision: 0,
      definition: {
        name: "Cliff", previewSeed: "17", template: "connectedLine", sortOrder: 0,
        followContourDirection: true,
        primitives: [
          { id: "straight", role: "lineStraight" },
          { id: "cap", role: "lineCap" },
          { id: "right", role: "lineCorner", cornerTurn: "right" },
          { id: "left", role: "lineCorner", cornerTurn: "left" },
        ].map(piece => ({ ...piece, sourceModelId: "face", weight: 1, authoredOrientation: "east",
          anchorWorld: { x: 0, y: levelHeight, z: 0 },
          transforms: { allowFlipX: false, allowedQuarterTurns: [0, 1, 2, 3] } })),
        defaults: { irregularityPermille: 0, detailDensityPermille: 0,
          variationPermille: 0, maxOverlapPx: 0, gapTolerancePx: 0, depthRows: 1 },
      } } } });
    await mutate("border.blueprint.publish", { blueprintId: "cliff" });
    const refused = await plan("map3d.terrain.paint_height", { mapId, level: 1,
      blueprintId: "missing", region: { x: 2, y: 2, width: 4, height: 3 } }, true);
    assert.ok(JSON.stringify(refused).includes("spatial.relief.profile_unavailable"));
    const before = await readFile(mapPath);
    const planned = await mutate("map3d.terrain.paint_height", { mapId, level: 1,
      blueprintId: "cliff", region: { x: 2, y: 2, width: 4, height: 3 } });
    const previewedTraces = record(record(planned.plan).preview).traces as JsonRecord[];
    assert.equal(previewedTraces.length, 1);
    const trace = record(previewedTraces[0]);
    assert.equal(trace.change, "created");
    assert.equal(trace.featureId, "relief-1");
    const painted = record(JSON.parse(await readFile(mapPath, "utf8")));
    const surfaces = record(record(painted.spatialScene).terrainSurfaces).surfaces as JsonRecord[];
    assert.equal(surfaces.length, 1);
    assert.equal(surfaces[0]!.height, levelHeight);
    const layer = (painted.layers as JsonRecord[]).find(value => value.id === "reliefs")!;
    const feature = (record(layer.content).features as JsonRecord[])[0]!;
    assert.equal(feature.id, "relief-1");
    assert.ok((record(feature.materialization).spatialPlacements as unknown[]).length > 0);
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
    const reopened = await call("pokemap_workspace", { operation: "open", projectRoot });
    const map = await call("pokemap_query", { projectHandle: reopened.projectHandle,
      resourceKind: "map", operation: "get", view: "detail", ids: [mapId] });
    const reopenedLayer = (record((map.items as JsonRecord[])[0]).layers as JsonRecord[]).find(value => value.id === "reliefs")!;
    assert.deepEqual(record(reopenedLayer.content).features, record(layer.content).features);
    const history = await call("pokemap_history", { operation: "list", projectHandle: reopened.projectHandle, limit: 1 });
    await call("pokemap_history", { operation: "undo", projectHandle: reopened.projectHandle,
      entryId: record((history.entries as unknown[])[0]).entryId, idempotencyKey: "relief-undo" });
    assert.deepEqual(await readFile(mapPath), before);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: reopened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

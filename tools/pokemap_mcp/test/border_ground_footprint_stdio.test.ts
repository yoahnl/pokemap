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
  const json = Buffer.from(JSON.stringify(document));
  const length = Math.ceil(json.length / 4) * 4;
  const bytes = Buffer.alloc(28 + length + 36);
  bytes.writeUInt32LE(0x46546c67, 0); bytes.writeUInt32LE(2, 4); bytes.writeUInt32LE(bytes.length, 8);
  bytes.writeUInt32LE(length, 12); bytes.writeUInt32LE(0x4e4f534a, 16);
  bytes.fill(32, 20, 20 + length); json.copy(bytes, 20);
  bytes.writeUInt32LE(36, 20 + length); bytes.writeUInt32LE(0x004e4942, 24 + length);
  [-.2, 0, -.2, .2, 0, -.2, 0, 1, .2].forEach((value, i) => bytes.writeFloatLE(value, 28 + length + i * 4));
  return bytes;
}

test("live MCP publishes reusable cliff footprints and preserves them on reopen", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-cliff-ground-mcp-"));
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--artifact-root", root,
      "--dart", process.env.POKEMAP_TEST_DART ?? "dart", "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "cliff-footprint-proof", version: "1.0.0" });
  async function call(name: string, args: JsonRecord = {}): Promise<JsonRecord> {
    const response = await client.callTool({ name, arguments: args });
    assert.equal(response.isError, undefined, JSON.stringify(response.structuredContent ?? response.content));
    return record(record(response.structuredContent).data);
  }
  try {
    await client.connect(transport);
    const catalog = await call("pokemap_describe");
    const contract = (catalog.mutationActions as JsonRecord[]).find(a => a.id === "border.blueprint.draft.upsert")!;
    const contact = record(record(contract.extensions).spatialGroundContact);
    assert.equal(contact.footprintsMinimumCatalogVersion, 8);
    assert.equal(contact.footprintsShape, "unionOfStrictlyConvexPolygons");
    const request = { name: "Cliff footprints", folderName: "game", parentPath: root,
      template: "empty", dimension: "threeD", mapWidth: 8, mapHeight: 8 };
    const preview = await call("pokemap_project_create_preview", { request });
    const created = await call("pokemap_project_create", { request, confirmation: preview.confirmation });
    const projectRoot = String(created.projectPath);
    let opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    let projectHandle = String(opened.projectHandle), workspaceHandle = String(opened.workspaceHandle), serial = 0;
    const manifest = record(JSON.parse(await readFile(join(projectRoot, "project.json"), "utf8")));
    const entry = record((manifest.maps as unknown[])[0]), mapId = String(entry.id);
    const mapPath = join(projectRoot, String(entry.relativePath));
    async function mutate(actionId: string, parameters: JsonRecord): Promise<void> {
      const validation = await call("pokemap_validate", { projectHandle });
      const before = await readFile(mapPath), id = "footprint-" + serial++;
      const planned = await call("pokemap_plan", { projectHandle, request: { requestId: id,
        actionId, actionVersion: 1, workspaceHandle, parameters, expectedRevision: validation.snapshotRevision, idempotencyKey: id } });
      assert.deepEqual(await readFile(mapPath), before);
      const applied = await call("pokemap_apply", { operation: "apply", projectHandle, planId: planned.planId, operationId: "apply-" + id });
      assert.equal(record(applied.receipt).status, "applied");
    }
    const sourcePath = join(root, "unit.glb"); await writeFile(sourcePath, unitGlb());
    const staged = await call("pokemap_artifact_stage", { sourcePath, declaredMediaType: "model/gltf-binary" });
    await mutate("model3d.import", { modelId: "unit", name: "Cliff", artifactHandle: staged.artifactHandle });
    const footprints = [[{ x: -.1, z: -.1 }, { x: .1, z: -.1 }, { x: -.1, z: .1 }]];
    const definition = { name: "Cliff", previewSeed: "1", template: "connectedLine", replacesGround: true, sortOrder: 0,
      primitives: ["lineCap", "lineStraight", "lineCorner"].map(role => ({ id: role, sourceModelId: "unit", role,
        groundFootprints: footprints, weight: 1, transforms: { allowFlipX: false, allowedQuarterTurns: [0, 1, 2, 3] } })),
      defaults: { irregularityPermille: 0, detailDensityPermille: 0, variationPermille: 0, maxOverlapPx: 0, gapTolerancePx: 0, depthRows: 1 } };
    await mutate("border.blueprint.draft.upsert", { record: { id: "cliff", draft: { baseRevision: 0, definition } } });
    await mutate("border.blueprint.publish", { blueprintId: "cliff" });
    await mutate("map.apply_operations", { mapId, operations: [{ kind: "layer.add", layerKind: "border", layerId: "border", name: "Cliff" }] });
    const target = { mapId, layerId: "border", featureId: "cliff" };
    await mutate("border_layer.feature_create", { ...target, blueprintId: "cliff", name: "Cliff", seed: "1",
      geometry: { kind: "stroke", strokes: [{ id: "line", closed: false, points: [{ x: 1, y: 1 }, { x: 2, y: 1 }, { x: 3, y: 1 }] }] } });
    await mutate("border_layer.materialize_apply", target);
    const saved = await readFile(mapPath);
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
    opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    projectHandle = String(opened.projectHandle); workspaceHandle = String(opened.workspaceHandle);
    const queried = await call("pokemap_query", { projectHandle, resourceKind: "borderBlueprint", operation: "get", ids: ["cliff"], view: "detail" });
    const current = record((queried.items as unknown[])[0]);
    const published = record(record(current.latestPublished).definition);
    for (const p of published.primitives as JsonRecord[]) assert.deepEqual(p.groundFootprints, footprints);
    const loadedManifest = record(JSON.parse(await readFile(join(projectRoot, "project.json"), "utf8")));
    assert.equal(record(loadedManifest.borderCatalog).formatVersion, 8);
    assert.deepEqual(await readFile(mapPath), saved);
    assert.equal((record(JSON.parse(saved.toString()).spatialScene).instances as unknown[]).length, 3);
    assert.equal((await call("pokemap_validate", { projectHandle })).valid, true);
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
  } finally {
    await client.close(); await transport.close(); await rm(root, { recursive: true, force: true });
  }
});

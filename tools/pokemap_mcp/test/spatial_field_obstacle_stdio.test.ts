import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import test from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";
import { canonicalPokemonConfig } from "./pokemon_fixture.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("fresh MCP configures a bound spatial obstacle, rejects stale plans, undoes and reopens", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "spatial-field-obstacle-"));
  await mkdir(join(root, "maps"));
  const positions = [-.4, 0, -.4, .4, 0, -.4, 0, 2, .4];
  const gltf = Buffer.from(JSON.stringify({ asset: { version: "2.0" }, scene: 0, scenes: [{ nodes: [0] }], nodes: [{ mesh: 0 }],
    buffers: [{ byteLength: 36 }], bufferViews: [{ buffer: 0, byteLength: 36 }],
    accessors: [{ bufferView: 0, componentType: 5126, count: 3, type: "VEC3", min: [-.4, 0, -.4], max: [.4, 2, .4] }],
    meshes: [{ primitives: [{ attributes: { POSITION: 0 } }] }] }));
  const jsonLength = Math.ceil(gltf.length / 4) * 4;
  const glb = Buffer.alloc(28 + jsonLength + 36);
  glb.writeUInt32LE(0x46546c67, 0); glb.writeUInt32LE(2, 4); glb.writeUInt32LE(glb.length, 8);
  glb.writeUInt32LE(jsonLength, 12); glb.writeUInt32LE(0x4e4f534a, 16);
  glb.fill(32, 20, 20 + jsonLength); gltf.copy(glb, 20);
  glb.writeUInt32LE(36, 20 + jsonLength); glb.writeUInt32LE(0x004e4942, 24 + jsonLength);
  positions.forEach((value, index) => glb.writeFloatLE(value, 28 + jsonLength + index * 4));
  const sourcePath = join(root, "source.glb");
  await writeFile(sourcePath, glb);
  const mapFile = join(root, "maps/route.json");
  const projectFile = join(root, "project.json");
  await writeFile(projectFile, JSON.stringify({ name: "Obstacles", version: "v9", pokemon: canonicalPokemonConfig(), settings: { dimension: "threeD",
    spatialCamera: { mode: "fixed", projection: "perspective", pitchDegrees: 48.7, yawDegrees: 0, fieldOfViewDegrees: 16.2, distance: 42, orthographicHeight: 12 } }, tilesets: [],
    maps: [{ id: "route", name: "Route", relativePath: "maps/route.json" }],
    models3d: [] }));
  await writeFile(mapFile, JSON.stringify({ id: "route", name: "Route", version: "v9", size: { width: 8, height: 8 }, layers: [], entities: [],
    spatialScene: { schemaVersion: 1, width: 8, depth: 8, levelHeight: 1, heightLevels: Array(64).fill(0),
      camera: { mode: "fixed", projection: "perspective", pitchDegrees: 48.7, yawDegrees: 0, fieldOfViewDegrees: 16.2, distance: 42, orthographicHeight: 12 },
      navigation: { spawn: { x: .5, z: .5 }, allowDiagonalMovement: false, ramps: [], blockedAreas: [] }, instances: [] } }));
  const args = [resolve("dist/src/index.js"), "--root", root, "--artifact-root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "spatial-field-test", version: "1.0.0" });
  async function call(name: string, input: JsonRecord, failed = false): Promise<JsonRecord> {
    const envelope = record((await client.callTool({ name, arguments: input })).structuredContent);
    assert.equal(envelope.ok, !failed, JSON.stringify(envelope));
    return record(envelope[failed ? "error" : "data"]);
  }
  try {
    await client.connect(transport);
    const description = await call("pokemap_describe", {});
    const actionId = "map3d.instance.configure_field_obstacle";
    const action = (description.mutationActions as JsonRecord[]).find(value => value.id === actionId);
    assert.ok(action);
    const schema = record(record(action.extensions).inputSchema);
    const obstacleSchema = record(record(schema.properties).fieldObstacle);
    assert.ok((record(record(obstacleSchema.properties).kind).enum as string[]).includes("strengthBoulder"));
    const workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    await call("pokemap_workshop", { operation: "prepare", projectHandle: workspace.projectHandle });
    async function setup(action: string, parameters: JsonRecord) {
      const revision = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
      const id = `setup-${action}`;
      const planned = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
        requestId: id, idempotencyKey: id, workspaceHandle: workspace.workspaceHandle,
        actionId: action, actionVersion: 1, expectedRevision: revision.snapshotRevision, parameters,
      } });
      await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle, planId: planned.planId, operationId: id });
    }
    const staged = await call("pokemap_artifact_stage", { sourcePath, declaredMediaType: "model/gltf-binary" });
    await setup("model3d.import_batch", { models: [{ modelId: "oak", name: "Oak", artifactHandle: staged.artifactHandle }] });
    await setup("map3d.instance.upsert", { mapId: "route", instance: {
      id: "oak-1", modelId: "oak", position: { x: 2.5, y: 0, z: 3.5 }, rotationDegrees: 0, scale: 1, blocksMovement: true } });
    const originalProject = await readFile(projectFile);
    const read = () => call("pokemap_workshop", { operation: "read", projectHandle: workspace.projectHandle,
      actionId, parameters: { mapId: "route", instanceId: "oak-1", fieldObstacle: null }, includeDocuments: false });
    const initial = await read();
    let sequence = 0;
    const plan = (fieldObstacle: unknown, revision: unknown, failed = false) => {
      const id = `spatial-field-${++sequence}`;
      return call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
        requestId: id, idempotencyKey: id, workspaceHandle: workspace.workspaceHandle,
        actionId, actionVersion: 1, expectedRevision: revision,
        extensions: { workshopScope: true },
        parameters: { mapId: "route", instanceId: "oak-1", fieldObstacle },
      } }, failed);
    };
    const obstacle = { kind: "cutTree", resetPolicy: "persistent" };
    const planned = await plan(obstacle, initial.snapshotRevision);
    assert.deepEqual(record(JSON.parse(await readFile(mapFile, "utf8"))).entities, []);
    const applied = await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle,
      planId: planned.planId, operationId: "bind" });
    const saved = record(JSON.parse(await readFile(mapFile, "utf8")));
    const entity = record((saved.entities as unknown[])[0]);
    assert.deepEqual(entity.fieldObstacle, obstacle);
    assert.equal(record((record(saved.spatialScene).instances as unknown[])[0]).entityId, entity.id);
    assert.deepEqual(await readFile(projectFile), originalProject);
    await plan(null, initial.snapshotRevision, true);
    await call("pokemap_history", { operation: "undo", projectHandle: workspace.projectHandle,
      entryId: record(applied.receipt).receiptId, idempotencyKey: "undo-bind" });
    assert.deepEqual(record(JSON.parse(await readFile(mapFile, "utf8"))).entities, []);
    const revision = await read();
    const rock = await plan({ kind: "rockSmashRock", resetPolicy: "mapInstance" }, revision.snapshotRevision);
    await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle, planId: rock.planId, operationId: "rock" });
    const strengthRevision = await read();
    const strength = await plan({ kind: "strengthBoulder", resetPolicy: "persistent" }, strengthRevision.snapshotRevision);
    await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle,
      planId: strength.planId, operationId: "strength" });
    assert.deepEqual(record((record(JSON.parse(await readFile(mapFile, "utf8"))).entities as unknown[])[0]).fieldObstacle,
      { kind: "strengthBoulder", resetPolicy: "persistent" });
    assert.deepEqual(await readFile(projectFile), originalProject);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    const reopened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    assert.deepEqual(record((record(JSON.parse(await readFile(mapFile, "utf8"))).entities as unknown[])[0]).fieldObstacle,
      { kind: "strengthBoulder", resetPolicy: "persistent" });
    await call("pokemap_workspace", { operation: "close", workspaceHandle: reopened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

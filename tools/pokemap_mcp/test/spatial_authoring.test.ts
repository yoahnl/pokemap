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

function triangleGlb(): Buffer {
  const document = {
    asset: { version: "2.0" }, scene: 0, scenes: [{ nodes: [0] }], nodes: [{ mesh: 0 }],
    buffers: [{ byteLength: 36 }], bufferViews: [{ buffer: 0, byteLength: 36 }],
    accessors: [{ bufferView: 0, componentType: 5126, count: 3, type: "VEC3" }],
    meshes: [{ primitives: [{ attributes: { POSITION: 0 } }] }],
  };
  const json = Buffer.from(JSON.stringify(document));
  const length = Math.ceil(json.length / 4) * 4;
  const bytes = Buffer.alloc(28 + length + 36);
  bytes.writeUInt32LE(0x46546c67, 0);
  bytes.writeUInt32LE(2, 4);
  bytes.writeUInt32LE(bytes.length, 8);
  bytes.writeUInt32LE(length, 12);
  bytes.writeUInt32LE(0x4e4f534a, 16);
  bytes.fill(32, 20, 20 + length);
  json.copy(bytes, 20);
  bytes.writeUInt32LE(36, 20 + length);
  bytes.writeUInt32LE(0x004e4942, 24 + length);
  [0, 0, 0, 1, 0, 0, 0, 1, 0].forEach((value, index) => bytes.writeFloatLE(value, 28 + length + index * 4));
  return bytes;
}

test("built MCP server creates a 3D project and persists resource, terrain, instance and camera actions", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-spatial-mcp-"));
  const transport = new StdioClientTransport({
    command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe",
  });
  const client = new Client({ name: "spatial-native-transport-proof", version: "1.0.0" });
  async function call(name: string, args: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: args });
    assert.equal(result.isError, failure ? true : undefined, JSON.stringify(result.structuredContent ?? result.content));
    const envelope = record(result.structuredContent);
    return record(failure ? envelope.error : envelope.data);
  }
  try {
    await client.connect(transport);
    const catalog = await call("pokemap_describe");
    const ids = (catalog.mutationActions as JsonRecord[]).map((item) => item.id);
    for (const id of ["model3d.import", "model3d.configure", "model3d.delete", "map3d.terrain.set_levels", "map3d.terrain.configure_appearance", "map3d.instance.upsert", "map3d.instance.delete", "map3d.camera.configure", "map3d.navigation.configure", "connection.create_bidirectional_apply", "connection.delete_bidirectional_apply"]) assert.ok(ids.includes(id), id);
    const request = { name: "Spatial MCP", folderName: "spatial", parentPath: root, template: "empty", dimension: "threeD", mapWidth: 8, mapHeight: 6 };
    const preview = await call("pokemap_project_create_preview", { request });
    const created = await call("pokemap_project_create", { request, confirmation: preview.confirmation });
    const projectRoot = String(created.projectPath);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    let projectHandle = String(opened.projectHandle), workspaceHandle = String(opened.workspaceHandle);
    let sequence = 0;
    async function mutate(actionId: string, parameters: JsonRecord, destructive = false): Promise<void> {
      const validation = await call("pokemap_validate", { projectHandle });
      const id = `spatial-${++sequence}`;
      const plan = await call("pokemap_plan", { projectHandle, request: {
        requestId: id, actionId, actionVersion: 1, workspaceHandle, parameters,
        expectedRevision: validation.snapshotRevision, idempotencyKey: id, dryRun: false,
      } });
      const confirmation = destructive ? await call("pokemap_apply", { operation: "confirm", projectHandle, planId: plan.planId }) : null;
      const result = await call("pokemap_apply", { operation: "apply", projectHandle, planId: plan.planId, operationId: id,
        ...(confirmation ? { confirmationToken: confirmation.confirmationToken } : {}),
      });
      assert.equal(record(result.receipt).status, "applied");
    }
    const path = join(root, "triangle.glb");
    await writeFile(path, triangleGlb());
    const staged = await call("pokemap_artifact_stage", { sourcePath: path, declaredMediaType: "model/gltf-binary" });
    await mutate("model3d.import", { modelId: "rock", name: "Rock", artifactHandle: staged.artifactHandle });
    await mutate("model3d.configure", { modelId: "rock", scale: 2 });
    const manifest = JSON.parse(await readFile(join(projectRoot, "project.json"), "utf8")) as JsonRecord;
    const mapEntry = record((manifest.maps as unknown[])[0]);
    const mapId = String(mapEntry.id);
    const cliffPath = join(root, "cliff.png");
    await writeFile(cliffPath, Buffer.from("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=", "base64"));
    const cliffArtifact = await call("pokemap_artifact_stage", { sourcePath: cliffPath, declaredMediaType: "image/png" });
    await mutate("tileset.import_image", { artifactHandle: cliffArtifact.artifactHandle, tilesetId: "cliff", name: "Cliff", tileWidth: 1, tileHeight: 1 });
    await mutate("smart_tile.atlas.upsert", { atlas: { id: "cliff", name: "Cliff", tilesetId: "cliff", cellWidth: 1, cellHeight: 1, columns: 1, rows: 1 } });
    const cliffFrame = { atlasId: "cliff", column: 0, row: 0, columnSpan: 1, rowSpan: 1 };
    await mutate("map3d.terrain.configure_appearance", { mapId, cliffFrame });
    await mutate("map3d.terrain.set_levels", { mapId, cells: [{ x: 2, z: 3, level: 2 }] });
    await mutate("map3d.instance.upsert", { mapId, instance: { id: "rock-1", modelId: "rock", position: { x: 2.2, y: 2, z: 3.7 }, rotationDegrees: 90, scale: 1, animationIndex: null, blocksMovement: true } });
    await mutate("map3d.camera.configure", { mapId, camera: { mode: "fixed", pitchDegrees: 60, yawDegrees: 15, fieldOfViewDegrees: 30, distance: 25 } });
    await mutate("map3d.terrain.set_levels", { mapId, cells: [{ x: 4, z: 2, level: 1 }] });
    const navigation = { spawn: { x: 4, z: 4 }, allowDiagonalMovement: false, ramps: [{ id: "stairs", x: 4, z: 3, width: 1, depth: 1, lowLevel: 0, highLevel: 1, direction: "north" }], blockedAreas: [{ x: 0, z: 0, width: 1, depth: 1 }] };
    await mutate("map3d.navigation.configure", { mapId, navigation });
    const map = JSON.parse(await readFile(join(projectRoot, String(mapEntry.relativePath)), "utf8")) as JsonRecord;
    const scene = record(map.spatialScene);
    assert.equal((scene.heightLevels as number[])[3 * 8 + 2], 2);
    assert.equal(record(scene.camera).pitchDegrees, 60);
    assert.deepEqual(scene.navigation, navigation);
    assert.deepEqual(scene.cliffFrame, cliffFrame);
    assert.equal((scene.instances as unknown[]).length, 1);
    assert.deepEqual(record((scene.instances as unknown[])[0]).position, { x: 2.2, y: 2, z: 3.7 });
    assert.deepEqual(map.layers, []);
    await mutate("map.create", { mapId: "second", name: "Second", width: 8, height: 6 });
    await mutate("entity.create", { mapId, entity: { id: "start", kind: "spawn", pos: { x: 4, y: 4 }, size: { width: 1, height: 1 }, blocksMovement: false, spawn: { role: "player_start", facing: "south" } } });
    await mutate("map.apply_operations", { mapId, operations: [{ kind: "layer.add", layerKind: "collision", layerId: "solid", name: "Collisions" }] });
    await mutate("collision_layer.paint", { mapId, layerId: "solid", x: 1, y: 0, width: 2, height: 1 });
    await mutate("warp.create_reciprocal_apply", { mapId, warp: { id: "out", pos: { x: 6, y: 4 }, targetMapId: "second", targetPos: { x: 2, y: 2 } }, reciprocalWarpId: "back" });
    await mutate("connection.create_bidirectional_apply", { mapId, direction: "east", targetMapId: "second", offset: 2 });
    const authored = JSON.parse(await readFile(join(projectRoot, String(mapEntry.relativePath)), "utf8")) as JsonRecord;
    assert.equal(authored.version, "v9");
    assert.equal(record((authored.entities as unknown[])[0]).id, "start");
    assert.deepEqual((record((authored.layers as unknown[])[0]).collisions as boolean[]).slice(1, 3), [true, true]);
    assert.equal(record((authored.warps as unknown[])[0]).targetMapId, "second");
    const finalManifest = JSON.parse(await readFile(join(projectRoot, "project.json"), "utf8")) as JsonRecord;
    const secondEntry = (finalManifest.maps as JsonRecord[]).find((entry) => entry.id === "second")!;
    const second = JSON.parse(await readFile(join(projectRoot, String(secondEntry.relativePath)), "utf8")) as JsonRecord;
    assert.equal(record((second.warps as unknown[])[0]).targetMapId, mapId);
    assert.deepEqual(authored.connections, [{ direction: "east", targetMapId: "second", offset: 2 }]);
    assert.deepEqual(second.connections, [{ direction: "west", targetMapId: mapId, offset: -2 }]);
    await mutate("map3d.instance.delete", { mapId, instanceId: "rock-1" }, true);
    await mutate("model3d.delete", { modelId: "rock" }, true);
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
    const reopened = await call("pokemap_workspace", { operation: "open", projectRoot });
    const queried = await call("pokemap_query", { projectHandle: reopened.projectHandle, resourceKind: "map", operation: "list", view: "detail" });
    for (const item of queried.items as JsonRecord[]) assert.equal((item.connections as unknown[]).length, 1);
    const reopenedMap = (queried.items as JsonRecord[]).find((item) => item.id === mapId)!;
    assert.deepEqual(record(reopenedMap.spatialScene).cliffFrame, cliffFrame);
    projectHandle = String(reopened.projectHandle);
    workspaceHandle = String(reopened.workspaceHandle);
    await mutate("map3d.terrain.configure_appearance", { mapId, cliffFrame: null });
    const cleared = await call("pokemap_query", { projectHandle, resourceKind: "map", operation: "get", ids: [mapId], view: "detail" });
    assert.equal(record(record((cleared.items as unknown[])[0]).spatialScene).cliffFrame, undefined);
    await mutate("connection.delete_bidirectional_apply", { mapId, direction: "east" });
    const disconnected = await call("pokemap_query", { projectHandle: reopened.projectHandle, resourceKind: "map", operation: "list", view: "detail" });
    for (const item of disconnected.items as JsonRecord[]) assert.deepEqual(item.connections, []);
    await call("pokemap_validate", { projectHandle: reopened.projectHandle });
    await call("pokemap_workspace", { operation: "close", workspaceHandle: reopened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

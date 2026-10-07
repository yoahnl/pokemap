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
    args: [resolve("dist/src/index.js"), "--root", root],
    cwd: process.cwd(), stderr: "pipe",
  });
  const client = new Client({ name: "spatial-native-transport-proof", version: "1.0.0" });
  async function call(name: string, args: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: args });
    assert.equal(result.isError, failure ? true : undefined, JSON.stringify(result.structuredContent));
    const envelope = record(result.structuredContent);
    return record(failure ? envelope.error : envelope.data);
  }
  try {
    await client.connect(transport);
    const catalog = await call("pokemap_describe");
    const ids = (catalog.mutationActions as JsonRecord[]).map((item) => item.id);
    for (const id of ["model3d.import", "model3d.configure", "model3d.delete", "map3d.terrain.set_levels", "map3d.instance.upsert", "map3d.instance.delete", "map3d.camera.configure", "map3d.navigation.configure"]) assert.ok(ids.includes(id), id);
    const request = { name: "Spatial MCP", folderName: "spatial", parentPath: root, template: "empty", dimension: "threeD", mapWidth: 8, mapHeight: 6 };
    const preview = await call("pokemap_project_create_preview", { request });
    const created = await call("pokemap_project_create", { request, confirmation: preview.confirmation });
    const projectRoot = String(created.projectPath);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    const projectHandle = String(opened.projectHandle), workspaceHandle = String(opened.workspaceHandle);
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
    await mutate("map3d.terrain.set_levels", { mapId, cells: [{ x: 2, z: 3, level: 2 }] });
    await mutate("map3d.instance.upsert", { mapId, instance: { id: "rock-1", modelId: "rock", position: { x: 2.5, y: 2, z: 3.5 }, rotationDegrees: 90, scale: 1, animationIndex: null, blocksMovement: true } });
    await mutate("map3d.camera.configure", { mapId, camera: { mode: "fixed", pitchDegrees: 60, yawDegrees: 15, fieldOfViewDegrees: 30, distance: 25 } });
    await mutate("map3d.terrain.set_levels", { mapId, cells: [{ x: 4, z: 2, level: 1 }] });
    const navigation = { spawn: { x: 4, z: 4 }, allowDiagonalMovement: false, ramps: [{ id: "stairs", x: 4, z: 3, width: 1, depth: 1, lowLevel: 0, highLevel: 1, direction: "north" }], blockedAreas: [{ x: 0, z: 0, width: 1, depth: 1 }] };
    await mutate("map3d.navigation.configure", { mapId, navigation });
    const map = JSON.parse(await readFile(join(projectRoot, String(mapEntry.relativePath)), "utf8")) as JsonRecord;
    const scene = record(map.spatialScene);
    assert.equal((scene.heightLevels as number[])[3 * 8 + 2], 2);
    assert.equal(record(scene.camera).pitchDegrees, 60);
    assert.deepEqual(scene.navigation, navigation);
    assert.equal((scene.instances as unknown[]).length, 1);
    assert.deepEqual(map.layers, []);
    await mutate("map3d.instance.delete", { mapId, instanceId: "rock-1" }, true);
    await mutate("model3d.delete", { modelId: "rock" }, true);
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
    const reopened = await call("pokemap_workspace", { operation: "open", projectRoot });
    await call("pokemap_validate", { projectHandle: reopened.projectHandle });
    await call("pokemap_workspace", { operation: "close", workspaceHandle: reopened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

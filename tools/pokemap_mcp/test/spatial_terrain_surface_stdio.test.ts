import assert from "node:assert/strict";
import { mkdtemp, readFile, rm } from "node:fs/promises";
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

test("live MCP creates edits reopens and undoes bounded native terrain surfaces", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-terrain-surface-mcp-"));
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root,
      "--dart", process.env.POKEMAP_TEST_DART ?? "dart", "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "terrain-surface-proof", version: "1.0.0" });
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
    for (const id of ["map3d.terrain.surface.upsert_batch", "map3d.terrain.surface.delete_batch"]) {
      const descriptor = (catalog.mutationActions as JsonRecord[]).find(action => action.id === id);
      assert.ok(descriptor);
      assert.equal(descriptor.version, 1);
      assert.equal(record(descriptor.extensions).maximumSurfaceCount, 128);
      assert.ok((descriptor.guarantees as string[]).includes("atomic"));
      const schema = record(record(descriptor.extensions).inputSchema);
      assert.deepEqual(record(schema.properties).reanchorInstances, { type: "boolean", default: true });
    }
    const request = { name: "Terrain", folderName: "terrain", parentPath: root,
      template: "empty", dimension: "threeD", mapWidth: 8, mapHeight: 6 };
    const preview = await call("pokemap_project_create_preview", { request });
    const created = await call("pokemap_project_create", { request, confirmation: preview.confirmation });
    const projectRoot = String(created.projectPath);
    let opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    let projectHandle = String(opened.projectHandle);
    let workspaceHandle = String(opened.workspaceHandle);
    const manifestPath = join(projectRoot, "project.json");
    const manifest = record(JSON.parse(await readFile(manifestPath, "utf8")));
    const entry = record((manifest.maps as unknown[])[0]);
    const mapId = String(entry.id);
    const mapPath = join(projectRoot, String(entry.relativePath));
    const manifestBefore = await readFile(manifestPath);
    let sequence = 0;
    async function plan(actionId: string, parameters: JsonRecord, failure = false): Promise<JsonRecord> {
      const validation = await call("pokemap_validate", { projectHandle });
      const before = await readFile(mapPath);
      const id = "terrain-surface-" + sequence++;
      const planned = await call("pokemap_plan", { projectHandle, request: {
        requestId: id, actionId, actionVersion: 1, workspaceHandle, parameters,
        expectedRevision: validation.snapshotRevision, idempotencyKey: id } }, failure);
      assert.deepEqual(await readFile(mapPath), before);
      assert.ok(JSON.stringify(planned).length < 16384);
      return planned;
    }
    async function mutate(actionId: string, parameters: JsonRecord): Promise<void> {
      const planned = await plan(actionId, parameters);
      await call("pokemap_apply", { operation: "apply", projectHandle,
        planId: planned.planId, operationId: "terrain-surface-apply-" + sequence++ });
    }
    async function scene(): Promise<JsonRecord> {
      const queried = await call("pokemap_query", { projectHandle, resourceKind: "map",
        operation: "get", ids: [mapId], view: "detail" });
      return record(record((queried.items as unknown[])[0]).spatialScene);
    }
    const surface = { id: "hill", x: 1, z: 1, height: 2, gradientX: .25, gradientZ: 0,
      footprints: [[{ x: 0, z: 0 }, { x: 1, z: 0 }, { x: 1, z: 1 }, { x: 0, z: 1 }]] };
    await mutate("map3d.terrain.surface.upsert_batch", { mapId, surfaces: [surface], reanchorInstances: false });
    assert.equal((await scene()).schemaVersion, 2);
    assert.deepEqual(record((await scene()).terrainSurfaces).surfaces, [surface]);
    const createdBytes = await readFile(mapPath);
    const rejected = await plan("map3d.terrain.surface.upsert_batch", {
      mapId, surfaces: [{ ...surface, id: "other" }, { ...surface, id: "outside", x: 99 }],
    }, true);
    assert.ok(JSON.stringify(rejected).includes("map3d.terrain.surface.invalid"));
    assert.deepEqual(await readFile(mapPath), createdBytes);
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
    opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    projectHandle = String(opened.projectHandle);
    workspaceHandle = String(opened.workspaceHandle);
    assert.deepEqual(record((await scene()).terrainSurfaces).surfaces, [surface]);
    await mutate("map3d.terrain.surface.upsert_batch", { mapId, surfaces: [{ ...surface, height: 3 }] });
    const beforeDelete = await readFile(mapPath);
    await mutate("map3d.terrain.surface.delete_batch", { mapId, surfaceIds: ["hill"], reanchorInstances: false });
    assert.equal((await scene()).schemaVersion, 1);
    assert.equal((await scene()).terrainSurfaces, undefined);
    const history = await call("pokemap_history", { operation: "list", projectHandle, limit: 1 });
    const latest = record((history.entries as unknown[])[0]);
    await call("pokemap_history", { operation: "undo", projectHandle,
      entryId: latest.entryId, idempotencyKey: "undo-surface-delete" });
    assert.deepEqual(await readFile(mapPath), beforeDelete);
    assert.deepEqual(await readFile(manifestPath), manifestBefore);
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

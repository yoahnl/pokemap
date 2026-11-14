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

function rectangle(width: number, depth: number): JsonRecord[] {
  return [{ x: 0, z: 0 }, { x: width, z: 0 }, { x: width, z: depth }, { x: 0, z: depth }];
}

test("live MCP slopes a plateau edge with closed flanks and undoes it as one edit", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-slope-mcp-"));
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root,
      "--dart", process.env.POKEMAP_TEST_DART ?? "dart", "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "slope-proof", version: "1.0.0" });
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
    for (const [id, required] of [
      ["map3d.terrain.paint_slope", ["mapId", "from", "to"]],
      ["map3d.terrain.place_stair", ["mapId", "cell", "modelId"]],
    ] as const) {
      const descriptor = (catalog.mutationActions as JsonRecord[]).find(action => action.id === id);
      assert.ok(descriptor, id);
      assert.ok((descriptor.guarantees as string[]).includes("undoable"));
      assert.deepEqual(record(record(descriptor.extensions).inputSchema).required, required);
    }
    const request = { name: "Slope", folderName: "slope", parentPath: root,
      template: "empty", dimension: "threeD", mapWidth: 12, mapHeight: 12 };
    const preview = await call("pokemap_project_create_preview", { request });
    const created = await call("pokemap_project_create", { request, confirmation: preview.confirmation });
    const projectRoot = String(created.projectPath);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    const projectHandle = String(opened.projectHandle);
    const workspaceHandle = String(opened.workspaceHandle);
    const entry = record((record(JSON.parse(await readFile(join(projectRoot, "project.json"), "utf8")))
      .maps as unknown[])[0]);
    const mapId = String(entry.id);
    const mapPath = join(projectRoot, String(entry.relativePath));
    let sequence = 0;
    async function plan(actionId: string, parameters: JsonRecord, failure = false): Promise<JsonRecord> {
      const validation = await call("pokemap_validate", { projectHandle });
      const before = await readFile(mapPath);
      const id = "slope-" + sequence++;
      const planned = await call("pokemap_plan", { projectHandle, request: {
        requestId: id, actionId, actionVersion: 1, workspaceHandle, parameters,
        expectedRevision: validation.snapshotRevision, idempotencyKey: id } }, failure);
      assert.deepEqual(await readFile(mapPath), before);
      return planned;
    }
    async function mutate(actionId: string, parameters: JsonRecord): Promise<JsonRecord> {
      const planned = await plan(actionId, parameters);
      await call("pokemap_apply", { operation: "apply", projectHandle,
        planId: planned.planId, operationId: "slope-apply-" + sequence++ });
      return planned;
    }
    const ambiguous = await plan("map3d.terrain.paint_slope", { mapId,
      from: { x: 4, y: 9 }, to: { x: 6, y: 7 } }, true);
    assert.ok(JSON.stringify(ambiguous).includes("spatial.slope.direction_ambiguous"));
    const missing = await plan("map3d.terrain.place_stair", { mapId,
      cell: { x: 4, y: 5 }, modelId: "missing" }, true);
    assert.ok(JSON.stringify(missing).includes("spatial.stair.model_unavailable"));
    const moundPlan = await plan("map3d.terrain.paint_slope", { mapId,
      from: { x: 4, y: 9 }, to: { x: 4, y: 6 } });
    const mound = record(record(moundPlan.plan).preview);
    assert.equal(mound.direction, "north");
    assert.deepEqual(mound.region, { x: 4, y: 6, width: 1, height: 4 });
    assert.equal(mound.lowerHeight, 0);
    await mutate("map3d.terrain.surface.upsert_batch", { mapId, surfaces: [
      { id: "ground", x: 0, z: 0, height: 1, footprints: [rectangle(12, 12)] },
      { id: "plateau", x: 2, z: 2, height: 2, footprints: [rectangle(6, 4)] },
    ] });
    const before = await readFile(mapPath);
    const planned = await mutate("map3d.terrain.paint_slope", { mapId,
      from: { x: 4, y: 9 }, to: { x: 4, y: 4 } });
    const planPreview = record(record(planned.plan).preview);
    assert.equal(planPreview.direction, "north");
    assert.deepEqual(planPreview.region, { x: 4, y: 6, width: 1, height: 4 });
    const sloped = record(JSON.parse(await readFile(mapPath, "utf8")));
    const surfaces = record(record(sloped.spatialScene).terrainSurfaces).surfaces as JsonRecord[];
    const slope = surfaces.find(surface => surface.id === planPreview.surfaceId)!;
    assert.equal(slope.closedFlanks, true);
    assert.equal(slope.gradientZ, -0.25);
    const history = await call("pokemap_history", { operation: "list", projectHandle, limit: 1 });
    await call("pokemap_history", { operation: "undo", projectHandle,
      entryId: record((history.entries as unknown[])[0]).entryId, idempotencyKey: "slope-undo" });
    assert.deepEqual(await readFile(mapPath), before);
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

import assert from "node:assert/strict";
import { mkdtemp, rm } from "node:fs/promises";
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

test("built MCP selects exact neighbors on a shared 2D edge", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-multi-edge-"));
  const transport = new StdioClientTransport({
    command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe",
  });
  const client = new Client({ name: "multi-edge-transport-proof", version: "1.0.0" });
  async function call(name: string, args: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: args });
    assert.equal(result.isError, failure ? true : undefined, JSON.stringify(result.structuredContent ?? result.content));
    const envelope = record(result.structuredContent);
    return record(failure ? envelope.error : envelope.data);
  }
  let workspaceHandle: string | undefined;
  try {
    await client.connect(transport);
    const description = await call("pokemap_describe");
    const kind = (description.resourceKinds as JsonRecord[]).find((entry) => entry.id === "mapConnection");
    assert.ok(kind);
    assert.deepEqual(record(kind.extensions).identityFields, ["mapId", "direction", "targetMapId"]);
    assert.equal(record(kind.extensions).multipleNeighborsPerEdge, "nonOverlapping2d");
    const request = { name: "Multi edge", folderName: "world", parentPath: root, template: "empty", dimension: "twoD", mapWidth: 8, mapHeight: 8 };
    const preview = await call("pokemap_project_create_preview", { request });
    const created = await call("pokemap_project_create", { request, confirmation: preview.confirmation });
    const projectRoot = String(created.projectPath);
    const sourceMapId = "source";
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    const projectHandle = String(opened.projectHandle);
    workspaceHandle = String(opened.workspaceHandle);
    let sequence = 0;
    async function mutate(actionId: string, parameters: JsonRecord): Promise<void> {
      const validation = await call("pokemap_validate", { projectHandle });
      const id = `multi-edge-${++sequence}`;
      const plan = await call("pokemap_plan", { projectHandle, request: {
        requestId: id, actionId, actionVersion: 1, workspaceHandle, parameters,
        expectedRevision: validation.snapshotRevision, idempotencyKey: id,
      } });
      const applied = await call("pokemap_apply", { operation: "apply", projectHandle, planId: plan.planId, operationId: id });
      assert.equal(record(applied.receipt).status, "applied");
    }
    await mutate("map.create", { mapId: sourceMapId, name: "Source", width: 8, height: 8 });
    for (const mapId of ["first", "second"]) {
      await mutate("map.create", { mapId, name: mapId, width: 4, height: 4 });
    }
    await mutate("connection.create_bidirectional_apply", { mapId: sourceMapId, direction: "east", targetMapId: "first", offset: 0 });
    await mutate("connection.create_bidirectional_apply", { mapId: sourceMapId, direction: "east", targetMapId: "second", offset: 4 });
    const queried = await call("pokemap_query", { projectHandle, resourceKind: "mapConnection", operation: "list", view: "detail" });
    const sourceConnections = (queried.items as JsonRecord[]).filter((entry) => entry.mapId === sourceMapId);
    assert.equal(sourceConnections.length, 2);
    assert.deepEqual(sourceConnections.map((entry) => entry.id).sort(), [`${sourceMapId}:east:first`, `${sourceMapId}:east:second`]);
    const validation = await call("pokemap_validate", { projectHandle });
    const ambiguous = await call("pokemap_plan", { projectHandle, request: {
      requestId: "ambiguous", actionId: "connection.delete", actionVersion: 1, workspaceHandle,
      parameters: { mapId: sourceMapId, direction: "east" }, expectedRevision: validation.snapshotRevision,
      idempotencyKey: "ambiguous",
    } }, true);
    assert.equal(ambiguous.code, "validation_failed");
    await mutate("connection.update_bidirectional_apply", { mapId: sourceMapId, direction: "east", targetMapId: "second", offset: 5 });
    await mutate("connection.delete_bidirectional_apply", { mapId: sourceMapId, direction: "east", targetMapId: "first" });
    const remaining = await call("pokemap_query", { projectHandle, resourceKind: "mapConnection", operation: "list", view: "detail" });
    assert.deepEqual((remaining.items as JsonRecord[]).filter((entry) => entry.mapId === sourceMapId).map((entry) => [entry.targetMapId, entry.offset]), [["second", 5]]);
    const reciprocal = (remaining.items as JsonRecord[]).find((entry) => entry.mapId === "second");
    assert.equal(reciprocal?.targetMapId, sourceMapId);
    assert.equal(reciprocal?.offset, -5);
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
    workspaceHandle = undefined;
  } finally {
    if (workspaceHandle) await call("pokemap_workspace", { operation: "close", workspaceHandle });
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

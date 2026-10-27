import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { mkdir, readFile, rm } from "node:fs/promises";
import { homedir } from "node:os";
import { join, resolve } from "node:path";
import { promisify } from "node:util";
import test from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("scoped map relations cross live MCP and JSONL with two-map undo", { timeout: 120_000 }, async () => {
  const root = join(homedir(), "Library/Caches/AveluneQA/hgss-mauville-maps/api/mcp-relations");
  await mkdir(root, { recursive: true });
  const packageRoot = resolve("../../packages/map_authoring");
  const dart = process.env.POKEMAP_TEST_DART ?? "dart";
  const client = new Client({ name: "scoped-map-relations", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--dart", dart, "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe" });
  async function call(name: string, args: JsonRecord): Promise<JsonRecord> {
    const response = record((await client.callTool({ name, arguments: args })).structuredContent);
    assert.equal(response.ok, true, JSON.stringify(response));
    return record(response.data);
  }
  try {
    await promisify(execFile)(dart, [`--packages=${join(packageRoot, ".dart_tool/package_config.json")}`,
      join(packageRoot, "test/support/create_working_catalog_fixture.dart"), root, "--map-creation"], { timeout: 60_000 });
    await client.connect(transport);
    const described = await call("pokemap_describe", {});
    const actions = ["warp.create", "connection.upsert", "connection.create_bidirectional_apply"];
    for (const action of actions) assert.ok((described.mutationActions as JsonRecord[]).some(entry => entry.id === action));
    let opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    await call("pokemap_workshop", { operation: "prepare", projectHandle: opened.projectHandle });
    await call("pokemap_workshop", { operation: "prepare", projectHandle: opened.projectHandle, scope: "mapCreation" });
    let sequence = 0;
    async function mutate(actionId: string, parameters: JsonRecord): Promise<JsonRecord> {
      const id = `relation-${sequence++}`;
      const scoped = await call("pokemap_workshop", { operation: "read", projectHandle: opened.projectHandle, actionId, parameters });
      const planned = await call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
        requestId: id, actionId, actionVersion: 1, workspaceHandle: opened.workspaceHandle,
        expectedRevision: scoped.snapshotRevision, idempotencyKey: id, parameters, extensions: scoped.planExtensions } });
      const args = { operation: "apply", projectHandle: opened.projectHandle, planId: planned.planId, operationId: id };
      const applied = await call("pokemap_apply", args);
      assert.equal(record((await call("pokemap_apply", args)).receipt).receiptId, record(applied.receipt).receiptId);
      return record(applied.receipt);
    }
    for (const mapId of ["route-30", "route-31", "interior"]) {
      await mutate("map.create", { mapId, name: mapId, width: 32, height: 32, role: "exterior" });
    }
    await mutate("warp.create", { mapId: "route-31", warp: { id: "door", pos: { x: 2, y: 3 },
      targetMapId: "interior", targetPos: { x: 3, y: 2 } } });
    await mutate("connection.upsert", { mapId: "route-30", direction: "east", targetMapId: "route-31", offset: 1 });
    const sourceBefore = await readFile(join(root, "maps/route-31.json"));
    const targetBefore = await readFile(join(root, "maps/interior.json"));
    const receipt = await mutate("connection.create_bidirectional_apply", {
      mapId: "route-31", direction: "north", targetMapId: "interior", offset: 2 });
    const source = record(JSON.parse(await readFile(join(root, "maps/route-31.json"), "utf8")));
    const target = record(JSON.parse(await readFile(join(root, "maps/interior.json"), "utf8")));
    assert.equal((source.warps as JsonRecord[])[0]!.id, "door");
    assert.deepEqual(source.connections, [{ direction: "north", targetMapId: "interior", offset: 2 }]);
    assert.deepEqual(target.connections, [{ direction: "south", targetMapId: "route-31", offset: -2 }]);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
    opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    await call("pokemap_history", { operation: "undo", projectHandle: opened.projectHandle,
      entryId: receipt.receiptId, idempotencyKey: "undo-pair" });
    assert.deepEqual(await readFile(join(root, "maps/route-31.json")), sourceBefore);
    assert.deepEqual(await readFile(join(root, "maps/interior.json")), targetBefore);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close(); await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";
import { canonicalPokemonConfig } from "./pokemon_fixture.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}
const darkness = (opacity: number): JsonRecord => ({ actionKind: "darkness", darkness: { opacity } });
const cascade = (requiresSurf: boolean): JsonRecord => ({ actionKind: "waterfall", waterfall: {
  entry: { x: 0, y: 2 }, path: [{ x: 0, y: 1 }], exit: { x: 0, y: 0 }, direction: "north", requiresSurf,
} });
const zone = (): JsonRecord => ({ id: "dark", name: "Cave darkness", kind: "fieldAction",
  area: { pos: { x: 1, y: 1 }, size: { width: 3, height: 2 } }, fieldAction: darkness(.7) });

test("live MCP discovers native Flash and proves create, set, cancel, undo, revision, lifecycle and cold reopen", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "flash-zone-mcp-"));
  const mapFile = join(root, "maps/cave.json");
  const projectFile = join(root, "project.json");
  await mkdir(join(root, "maps"));
  await writeFile(projectFile, JSON.stringify({ name: "Flash MCP", version: "v8", pokemon: canonicalPokemonConfig(),
    maps: [{ id: "cave", name: "Cave", relativePath: "maps/cave.json" }], tilesets: [] }));
  await writeFile(mapFile, JSON.stringify({ id: "cave", name: "Cave", version: "v8", size: { width: 8, height: 6 }, layers: [] }));
  const projectBefore = await readFile(projectFile);
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const client = new Client({ name: "flash-zone-test", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  let workspace: JsonRecord | undefined;
  let sequence = 0;
  async function call(name: string, input: JsonRecord, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: input });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify({ name, envelope }));
    return record(envelope[failure ? "error" : "data"]);
  }
  async function plan(actionId: string, parameters: JsonRecord, failure = false, revision?: unknown): Promise<JsonRecord> {
    assert.ok(workspace);
    const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    const before = await readFile(mapFile);
    const id = `flash-${++sequence}`;
    const planned = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
      requestId: id, actionId, actionVersion: 1, workspaceHandle: workspace.workspaceHandle,
      expectedRevision: revision ?? validation.snapshotRevision, idempotencyKey: id,
      parameters: { mapId: "cave", ...parameters },
    } }, failure);
    assert.deepEqual(await readFile(mapFile), before);
    return planned;
  }
  async function apply(actionId: string, parameters: JsonRecord): Promise<void> {
    const planned = await plan(actionId, parameters);
    await call("pokemap_apply", { operation: "apply", projectHandle: workspace!.projectHandle, planId: planned.planId, operationId: `flash-${++sequence}` });
  }
  async function zones(): Promise<JsonRecord[]> {
    return record(JSON.parse(await readFile(mapFile, "utf8"))).gameplayZones as JsonRecord[];
  }
  try {
    await client.connect(transport);
    const description = await call("pokemap_describe", {});
    const action = (description.mutationActions as JsonRecord[]).find(entry => entry.id === "gameplay_zone.set_field_action_payload");
    assert.ok(action);
    const contract = record(record(action.extensions).fieldActionZone);
    assert.equal(contract.mapMode, "2d"); assert.equal(contract.lifetime, "byActionKind");
    assert.equal(record(contract.waterfall).lifetime, "traversal");
    assert.equal(record(contract.darkness).lifetime, "mapInstance");
    assert.deepEqual([...(contract.actionKinds as string[])].sort(), ["darkness", "dive", "waterfall", "whirlpool"]); assert.equal(contract.consumesPp, false);
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const initial = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    await apply("gameplay_zone.create", { zone: zone() });
    assert.deepEqual((await zones())[0]!.fieldAction, darkness(.7));
    await plan("gameplay_zone.set_field_action_payload", { zoneId: "dark", payload: darkness(.35) });
    assert.deepEqual((await zones())[0]!.fieldAction, darkness(.7));
    await apply("gameplay_zone.set_field_action_payload", { zoneId: "dark", payload: darkness(.85) });
    assert.deepEqual((await zones())[0]!.fieldAction, darkness(.85));
    const stale = await plan("gameplay_zone.set_field_action_payload", { zoneId: "dark", payload: darkness(.7) }, true, initial.snapshotRevision);
    assert.equal(stale.domainCode, "plan.stale");
    for (const payload of [darkness(1), { ...darkness(.7), extra: true }, { actionKind: "waterfall" }]) {
      const rejected = await plan("gameplay_zone.set_field_action_payload", { zoneId: "dark", payload }, true);
      assert.notEqual(rejected.domainCode, "worker.internal");
    }
    const history = await call("pokemap_history", { operation: "list", projectHandle: workspace.projectHandle, limit: 1 });
    await call("pokemap_history", { operation: "undo", projectHandle: workspace.projectHandle,
      entryId: (history.entries as JsonRecord[])[0]!.entryId, idempotencyKey: "undo-flash" });
    assert.deepEqual((await zones())[0]!.fieldAction, darkness(.7));
    await apply("gameplay_zone.move", { zoneId: "dark", x: 2, y: 1 });
    await apply("gameplay_zone.resize", { zoneId: "dark", width: 4, height: 3 });
    await apply("gameplay_zone.set_priority", { zoneId: "dark", priority: 3 });
    const updated = (await zones())[0]!;
    await apply("gameplay_zone.update", { zoneId: "dark", zone: { ...updated, name: "Dark cave" } });
    await apply("gameplay_zone.clone", { zoneId: "dark", newId: "copy", x: 0, y: 0 });
    await apply("gameplay_zone.clear_payload", { zoneId: "copy" });
    assert.equal((await zones())[1]!.fieldAction, undefined);
    await apply("gameplay_zone.delete", { zoneId: "copy" });
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const reopened = await call("pokemap_query", { projectHandle: workspace.projectHandle, resourceKind: "map", operation: "get", ids: ["cave"], view: "detail" });
    assert.ok(JSON.stringify(reopened).includes('"fieldAction":{"actionKind":"darkness","darkness":{"opacity":0.7}}'));
    assert.equal((await zones())[0]!.name, "Dark cave");
    assert.deepEqual(await readFile(projectFile), projectBefore);
    await apply("gameplay_zone.set_field_action_payload", { zoneId: "dark", payload: cascade(true) });
    await plan("gameplay_zone.set_field_action_payload", { zoneId: "dark", payload: cascade(false) });
    assert.deepEqual((await zones())[0]!.fieldAction, cascade(true));
    await apply("gameplay_zone.set_field_action_payload", { zoneId: "dark", payload: cascade(false) });
    assert.deepEqual((await zones())[0]!.fieldAction, cascade(false));
    const cascadeHistory = await call("pokemap_history", { operation: "list", projectHandle: workspace.projectHandle, limit: 1 });
    await call("pokemap_history", { operation: "undo", projectHandle: workspace.projectHandle,
      entryId: (cascadeHistory.entries as JsonRecord[])[0]!.entryId, idempotencyKey: "undo-cascade" });
    assert.deepEqual((await zones())[0]!.fieldAction, cascade(true));
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const cascadeReopened = await call("pokemap_query", { projectHandle: workspace.projectHandle, resourceKind: "map", operation: "get", ids: ["cave"], view: "detail" });
    assert.ok(JSON.stringify(cascadeReopened).includes('"actionKind":"waterfall"'));
    const receiptPath = process.env.POKEMAP_TEST_FLASH_RECEIPT;
    if (receiptPath) await writeFile(receiptPath, JSON.stringify({ action, live: true, transport: "MCP stdio",
      serverSha256: createHash("sha256").update(await readFile(resolve("dist/src/index.js"))).digest("hex"),
      verified: ["describe", "create", "set", "cancel", "undo", "stale", "strictPayload", "move", "resize", "priority", "update", "clone", "clear", "delete", "coldReopen", "waterfallSet", "waterfallCancel", "waterfallUndo", "waterfallColdReopen"] }, null, 2));
  } finally {
    if (workspace) await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    await client.close(); await transport.close(); await rm(root, { recursive: true, force: true });
  }
});

import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, mkdir, writeFile } from "node:fs/promises";
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

test("map editor locks remain scoped across MCP restart, replay, conflict and undo", { timeout: 150_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "editor-mcp-"));
  const outside = await mkdtemp(join(tmpdir(), "editor-outside-"));
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  async function session(run: (call: (name: string, input?: JsonRecord, fails?: boolean) => Promise<JsonRecord>) => Promise<void>): Promise<void> {
    const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
    let diagnostics = "";
    transport.stderr?.on("data", chunk => { diagnostics += String(chunk); });
    const client = new Client({ name: "editor-lock-test", version: "1" });
    async function call(name: string, input: JsonRecord = {}, fails = false): Promise<JsonRecord> {
      const body = record((await client.callTool({ name, arguments: input })).structuredContent);
      assert.equal(body.ok, !fails, JSON.stringify(body));
      return record(body[fails ? "error" : "data"]);
    }
    try {
      await client.connect(transport);
      const names = (await client.listTools()).tools.map(t => t.name);
      for (const operation of ["inspect", "set", "undo"]) assert.ok(names.includes(`pokemap_map_editor_${operation}`));
      await run(call);
    } catch (error) {
      throw new Error(`${String(error)}; worker diagnostics: ${diagnostics}`, { cause: error });
    } finally {
      await client.close();
      await transport.close();
    }
  }
  try {
    await mkdir(join(root, "maps"));
    const map = join(root, "maps", "bourg.json");
    const project = join(root, "project.json");
    const sidecar = join(root, "maps", "bourg.editor.json");
    await writeFile(map, "undecodable map");
    await writeFile(project, "undecodable project");
    const state = { lockedElements: ["decor:back-particles", "model:tree"], lockedFamilies: ["decor"] };
    let originalRevision: unknown;
    let afterRevision: unknown;
    let receiptId: unknown;
    await session(async call => {
      const catalog = await call("pokemap_describe");
      assert.equal(record(catalog.mapEditorAuthoring).id, "map.editor.set");
      assert.deepEqual(record(catalog.mapEditorAuthoring).resourceKinds, ["mapEditor"]);
      assert.ok((catalog.scopedResourceKinds as JsonRecord[]).some(kind => kind.id === "mapEditor"));
      assert.ok((catalog.scopedMutationActions as JsonRecord[]).some(action => action.id === "map.editor.set"));
      assert.ok((catalog.commands as JsonRecord[]).some(c => c.id === "map_editor_set"));
      const initial = await call("pokemap_map_editor_inspect", { projectRoot: root, mapId: "bourg" });
      assert.deepEqual(initial.state, { lockedElements: [], lockedFamilies: [] });
      originalRevision = initial.revision;
      const input = { projectRoot: root, mapId: "bourg", expectedRevision: initial.revision, state, operationId: "lock-particles" };
      const changed = await call("pokemap_map_editor_set", input);
      assert.deepEqual(changed.afterState, state);
      afterRevision = changed.afterRevision;
      receiptId = record(changed.receipt).receiptId;
      const beforeReplay = await readFile(sidecar);
      const replay = await call("pokemap_map_editor_set", input);
      assert.equal(record(replay.receipt).receiptId, receiptId);
      assert.deepEqual(await readFile(sidecar), beforeReplay);
      await call("pokemap_map_editor_set", { ...input, state: { lockedElements: [], lockedFamilies: [] } }, true);
      await call("pokemap_map_editor_set", { ...input, operationId: "stale-edit" }, true);
      await call("pokemap_map_editor_set", { ...input, expectedRevision: afterRevision, state: { lockedElements: ["invalid:particle"] }, operationId: "invalid-kind" }, true);
    });
    await session(async call => {
      const persisted = await call("pokemap_map_editor_inspect", { projectRoot: root, mapId: "bourg" });
      assert.deepEqual(persisted.state, state);
      assert.equal(persisted.revision, afterRevision);
      const undoInput = { projectRoot: root, mapId: "bourg", receiptId, expectedRevision: afterRevision, operationId: "unlock-particles" };
      const undone = await call("pokemap_map_editor_undo", undoInput);
      assert.deepEqual(undone.afterState, { lockedElements: [], lockedFamilies: [] });
      assert.equal(undone.afterRevision, originalRevision);
      const replay = await call("pokemap_map_editor_undo", undoInput);
      assert.equal(record(replay.receipt).receiptId, record(undone.receipt).receiptId);
      await call("pokemap_map_editor_inspect", { projectRoot: outside, mapId: "bourg" }, true);
      await call("pokemap_map_editor_inspect", { projectRoot: root, mapId: "bourg", mapRelativePath: "../escape.json" }, true);
    });
    assert.equal((await readFile(map)).toString(), "undecodable map");
    assert.equal((await readFile(project)).toString(), "undecodable project");
  } finally {
    await rm(root, { recursive: true, force: true });
    await rm(outside, { recursive: true, force: true });
  }
});

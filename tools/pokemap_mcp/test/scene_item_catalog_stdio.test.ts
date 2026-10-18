import assert from "node:assert/strict";
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

function scene(itemId: string): JsonRecord {
  return {
    id: "items", name: "Inventory references",
    layout: { nodeLayouts: [{ nodeId: "start", x: 0, y: 0 },
      { nodeId: "give", x: 100, y: 0 }, { nodeId: "end", x: 200, y: 0 }], edgeLayouts: [] }, graph: {
      startNodeId: "start", nodes: [
        { id: "start", kind: "start" },
        { id: "give", kind: "action", payload: { consequence: { kind: "giveItem", itemId, quantity: 1 } } },
        { id: "end", kind: "end" },
      ], edges: [
        { id: "enter", fromNodeId: "start", fromPortId: "completed", toNodeId: "give", kind: "default" },
        { id: "leave", fromNodeId: "give", fromPortId: "completed", toNodeId: "end", kind: "actionCompleted" },
      ],
    },
  };
}

test("L18 MCP preserves item catalog diagnostics and publication blockers", { timeout: 180_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "l18-items-mcp-"));
  const file = join(root, "project.json");
  const items = join(root, "data/pokemon/catalogs/items.json");
  await mkdir(join(root, "data/pokemon/catalogs"), { recursive: true });
  await writeFile(file, JSON.stringify({ name: "Item diagnostics", version: "v8",
    pokemon: canonicalPokemonConfig(), maps: [], tilesets: [], scenes: [scene("tonic")] }));
  await writeFile(items, JSON.stringify({ schemaVersion: 1,
    entries: [{ id: "tonic", displayName: "Tonic", pocketId: "medicine" }] }));
  const args = [resolve(process.env.POKEMAP_TEST_MCP_ENTRY ?? "dist/src/index.js"),
    "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  if (process.env.POKEMAP_TEST_AUTHORING_PACKAGE) args.push("--authoring-package", process.env.POKEMAP_TEST_AUTHORING_PACKAGE);
  const client = new Client({ name: "l18-item-diagnostics", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  async function call(name: string, input: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const result = record((await client.callTool({ name, arguments: input })).structuredContent);
    assert.equal(result.ok, !failure, JSON.stringify({ name, result }));
    return record(result[failure ? "error" : "data"]);
  }
  try {
    await client.connect(transport);
    const catalog = await call("pokemap_describe");
    assert.ok((catalog.mutationActions as JsonRecord[]).some(action => action.id === "scene.upsert"));
    assert.ok((catalog.resourceKinds as JsonRecord[]).some(resource => resource.kind === "scene" || resource.id === "scene"));
    const workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const query = () => call("pokemap_query", { projectHandle: workspace.projectHandle,
      resourceKind: "scene", operation: "get", ids: ["items"], view: "detail" });
    const diagnostics = (result: JsonRecord): JsonRecord[] =>
      record((result.items as JsonRecord[])[0]).diagnostics as JsonRecord[];
    assert.equal(diagnostics(await query()).filter(item => item.severity === "error").length, 0);
    const initial = await readFile(file);
    const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    const planned = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
      requestId: "known-item", actionId: "scene.upsert", actionVersion: 1,
      workspaceHandle: workspace.workspaceHandle, expectedRevision: validation.snapshotRevision,
      idempotencyKey: "known-item", parameters: { scene: { ...scene("tonic"), name: "Known item update" } }, dryRun: true,
    } });
    assert.equal(record(record(planned.plan).preview).canPublish, true);
    const rejected = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
      requestId: "unknown-item", actionId: "scene.upsert", actionVersion: 1,
      workspaceHandle: workspace.workspaceHandle, expectedRevision: validation.snapshotRevision,
      idempotencyKey: "unknown-item", parameters: { scene: scene("unknown") }, dryRun: true,
    } }, true);
    assert.equal(rejected.domainCode, "scene.publication_blocked");
    assert.deepEqual(await readFile(file), initial);
    await writeFile(items, JSON.stringify({ schemaVersion: 1, entries: [] }));
    assert.ok(diagnostics(await query()).some(item => item.code === "consequenceUnknownItem" && item.severity === "error"));
    await writeFile(items, "{invalid");
    assert.ok(diagnostics(await query()).some(item => item.code === "project.item_catalog_invalid" && item.severity === "error"));
    await rm(items);
    assert.ok(diagnostics(await query()).some(item => item.code === "project.item_catalog_missing" && item.severity === "error"));
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

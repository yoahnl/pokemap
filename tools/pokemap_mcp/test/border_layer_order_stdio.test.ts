import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";
import { canonicalPokemonConfig } from "./pokemon_fixture.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("first Border layer through live MCP stdio paints in front of ground", async () => {
  const root = await mkdtemp(join(tmpdir(), "uwu6-border-stdio-"));
  const manifestPath = join(root, "project.json");
  const mapPath = join(root, "garden.json");
  const ground = {runtimeType: "tile", id: "ground", name: "Sol", cells: [0]};
  const manifest = {version: "v8", name: "Jardin", pokemon: canonicalPokemonConfig(), tilesets: [], maps: [
    {id: "garden", name: "Jardin", relativePath: "garden.json"},
  ]};
  await writeFile(manifestPath, JSON.stringify(manifest));
  await writeFile(mapPath, JSON.stringify({version: "v8", id: "garden", name: "Jardin",
    size: {width: 1, height: 1}, visualStack: {semanticsVersion: 1}, layers: [ground]}));
  const transport = new StdioClientTransport({command: process.execPath,
    args: ["dist/src/index.js", "--root", root, "--dart", process.env.POKEMAP_TEST_DART ?? "dart"],
    cwd: process.cwd(), stderr: "pipe"});
  const client = new Client({name: "uwu6-border-stdio", version: "1.0.0"});
  async function data(name: string, args: JsonRecord): Promise<JsonRecord> {
    const result = await client.callTool({name, arguments: args});
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, true, JSON.stringify(envelope));
    return record(envelope.data);
  }
  try {
    await client.connect(transport);
    const catalog = await data("pokemap_describe", {});
    assert.ok((catalog.mutationActions as JsonRecord[]).some(a => a.id === "map.apply_operations"));
    const opened = await data("pokemap_workspace", {operation: "open", projectRoot: root});
    const projectHandle = opened.projectHandle;
    const validation = await data("pokemap_validate", {projectHandle});
    const beforeMap = await readFile(mapPath);
    const beforeManifest = await readFile(manifestPath);
    const planned = await data("pokemap_plan", {projectHandle, request: {
      requestId: "first-border", actionId: "map.apply_operations", actionVersion: 1,
      workspaceHandle: opened.workspaceHandle, expectedRevision: validation.snapshotRevision,
      idempotencyKey: "first-border", dryRun: false, parameters: {mapId: "garden", operations: [
        {kind: "layer.add", layerKind: "border", layerId: "border", name: "Bordures"},
      ]}}});
    assert.deepEqual(await readFile(mapPath), beforeMap);
    const result = await data("pokemap_apply", {operation: "apply", projectHandle,
      planId: planned.planId, operationId: "apply-first-border"});
    assert.equal(record(result.receipt).status, "applied");
    await data("pokemap_workspace", {operation: "close", workspaceHandle: opened.workspaceHandle});
    const persisted = record(JSON.parse(await readFile(mapPath, "utf8")));
    const layers = persisted.layers as JsonRecord[];
    assert.equal(layers[0]!.id, "border");
    assert.equal(layers[1]!.id, "ground");
    assert.deepEqual(layers[1]!.cells, ground.cells);
    assert.deepEqual(await readFile(manifestPath), beforeManifest);
  } finally {
    await client.close();
    await rm(root, {recursive: true, force: true});
  }
});

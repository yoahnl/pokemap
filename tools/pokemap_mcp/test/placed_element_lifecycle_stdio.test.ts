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

function rock(id: string, x: number, y: number): JsonRecord {
  return { id, layerId: "decor", elementId: "rock", pos: { x, y }, opacity: 0.5, applyCollision: false,
    properties: { pokemapPlacementOrigin: "authored", note: "garder" } };
}

test("live MCP places, moves, clones and deletes a decor with the canonical refusals", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "decor-lifecycle-mcp-"));
  const manifestFile = join(root, "project.json");
  const alphaFile = join(root, "maps/alpha.json");
  await mkdir(join(root, "maps"));
  await writeFile(manifestFile, JSON.stringify({ name: "Decor MCP", version: "v8",
    pokemon: canonicalPokemonConfig(),
    tilesets: [{ id: "ts", name: "TS", relativePath: "assets/ts.png" }],
    elementCategories: [{ id: "cat", name: "Cat" }],
    elements: [{ id: "rock", name: "Rock", tilesetId: "ts", categoryId: "cat",
      frames: [{ source: { x: 0, y: 0, width: 2, height: 2 } }] }],
    maps: [{ id: "alpha", name: "Alpha", relativePath: "maps/alpha.json" }] }));
  await writeFile(alphaFile, JSON.stringify({ version: "v8", id: "alpha", name: "Alpha",
    size: { width: 6, height: 6 },
    layers: [{ runtimeType: "tile", id: "decor", name: "Decor", cells: new Array(36).fill(0) }] }));
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const client = new Client({ name: "decor-lifecycle-proof", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args,
    cwd: process.cwd(), stderr: "pipe" });
  let workspace: JsonRecord | undefined;
  async function call(name: string, input: JsonRecord, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: input });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify(envelope));
    return record(envelope[failure ? "error" : "data"]);
  }
  try {
    await client.connect(transport);
    const description = await call("pokemap_describe", {});
    for (const id of ["placed_element.place", "placed_element.move", "placed_element.clone", "placed_element.delete"]) {
      assert.ok((description.mutationActions as JsonRecord[]).some((entry) => entry.id === id), id);
    }
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const manifestBefore = await readFile(manifestFile);
    let sequence = 0;
    async function plan(actionId: string, parameters: JsonRecord, failure = false): Promise<JsonRecord> {
      assert.ok(workspace);
      const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
      const before = await readFile(alphaFile);
      const id = `decor-${++sequence}`;
      const result = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
        requestId: id, actionId, actionVersion: 1, workspaceHandle: workspace.workspaceHandle,
        expectedRevision: validation.snapshotRevision, idempotencyKey: id,
        parameters: { mapId: "alpha", ...parameters },
      } }, failure);
      assert.deepEqual(await readFile(alphaFile), before);
      assert.deepEqual(await readFile(manifestFile), manifestBefore);
      return result;
    }
    async function mutate(actionId: string, parameters: JsonRecord): Promise<void> {
      const planned = await plan(actionId, parameters);
      assert.ok(workspace);
      await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle,
        planId: planned.planId, operationId: `apply-${++sequence}` });
    }
    async function refuse(actionId: string, parameters: JsonRecord, code?: string): Promise<void> {
      const failure = await plan(actionId, parameters, true);
      if (code) assert.equal(failure.domainCode, code, JSON.stringify(failure));
    }
    await mutate("placed_element.place", { instance: rock("rock-1", 1, 1) });
    await refuse("placed_element.place", { instance: rock("edge", 5, 5) }, "placed_element.footprint_out_of_bounds");
    await refuse("placed_element.place", { instance: rock("rock-1", 1, 1) }, "placed_element.exists");
    await refuse("placed_element.place", { instance: { ...rock("ghost", 1, 1), elementId: "missing" } },
      "placed_element.element_missing");
    await mutate("placed_element.move", { instanceId: "rock-1", x: 2, y: 1 });
    await refuse("placed_element.move", { instanceId: "nowhere", x: 2, y: 2 }, "placed_element.not_found");
    await mutate("placed_element.clone", { instanceId: "rock-1", newId: "rock-2", x: 3, y: 3 });
    await refuse("placed_element.clone", { instanceId: "rock-1", newId: "rock-2", x: 0, y: 0 }, "placed_element.exists");
    await mutate("placed_element.delete", { instanceId: "rock-1" });
    await refuse("placed_element.delete", { instanceId: "nowhere" });
    const stable = await readFile(alphaFile);
    const saved = record(JSON.parse(stable.toString("utf8")));
    const placed = saved.placedElements as JsonRecord[];
    assert.equal(placed.length, 1);
    const copy = record(placed[0]);
    assert.equal(copy.id, "rock-2");
    assert.deepEqual(copy.pos, { x: 3, y: 3 });
    assert.equal(copy.opacity, 0.5);
    assert.equal(copy.applyCollision, false);
    assert.equal(record(copy.properties).note, "garder");
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const queried = await call("pokemap_query", { projectHandle: workspace.projectHandle,
      resourceKind: "map", operation: "get", ids: ["alpha"], view: "detail" });
    assert.ok(JSON.stringify(queried).includes('"rock-2"'));
    assert.ok(!JSON.stringify(queried).includes('"rock-1"'));
    assert.deepEqual(await readFile(alphaFile), stable);
    assert.deepEqual(await readFile(manifestFile), manifestBefore);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = undefined;
  } finally {
    if (workspace) await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

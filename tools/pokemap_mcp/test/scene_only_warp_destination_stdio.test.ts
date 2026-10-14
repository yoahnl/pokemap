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

test("live MCP creates and moves a passive named Scene arrival without an outgoing target", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "scene-only-mcp-"));
  const manifestFile = join(root, "project.json");
  const alphaFile = join(root, "maps/alpha.json");
  const betaFile = join(root, "maps/beta.json");
  const point = { id: "arrival", pos: { x: 1, y: 1 }, triggerMode: "scene_only" };
  await mkdir(join(root, "maps"));
  await writeFile(manifestFile, JSON.stringify({ name: "Arrival MCP", version: "v8",
    pokemon: canonicalPokemonConfig(), tilesets: [], maps: [
      { id: "alpha", name: "Alpha", relativePath: "maps/alpha.json" },
      { id: "beta", name: "Beta", relativePath: "maps/beta.json" },
    ] }));
  for (const id of ["alpha", "beta"]) {
    await writeFile(join(root, `maps/${id}.json`), JSON.stringify({ version: "v8", id, name: id,
      size: { width: 4, height: 4 }, layers: [], warps: [] }));
  }
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const client = new Client({ name: "scene-only-proof", version: "1.0.0" });
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
    for (const id of ["warp.create", "warp.update"]) {
      const action = (description.mutationActions as JsonRecord[]).find((entry) => entry.id === id);
      assert.ok(action);
      const contract = record(record(action.extensions).warpDestinationContract);
      assert.deepEqual(contract.triggerModeValues, ["on_enter", "on_bump", "scene_only"]);
      assert.deepEqual(contract.activeRequiredFields, ["targetMapId", "targetPos"]);
      assert.equal(record(contract.sceneOnly).automaticTraversal, false);
      assert.equal(contract.sceneOnlyToActiveRequiresExplicitDestination, true);
    }
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const manifestBefore = await readFile(manifestFile);
    const betaBefore = await readFile(betaFile);
    let sequence = 0;
    async function plan(actionId: string, parameters: JsonRecord, failure = false): Promise<JsonRecord> {
      assert.ok(workspace);
      const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
      const before = await readFile(alphaFile);
      const id = `arrival-${++sequence}`;
      const result = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
        requestId: id, actionId, actionVersion: 1, workspaceHandle: workspace.workspaceHandle,
        expectedRevision: validation.snapshotRevision, idempotencyKey: id,
        parameters: { mapId: "alpha", ...parameters },
      } }, failure);
      assert.deepEqual(await readFile(alphaFile), before);
      assert.deepEqual(await readFile(manifestFile), manifestBefore);
      assert.deepEqual(await readFile(betaFile), betaBefore);
      return result;
    }
    async function mutate(actionId: string, parameters: JsonRecord): Promise<void> {
      const planned = await plan(actionId, parameters);
      assert.ok(workspace);
      await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle,
        planId: planned.planId, operationId: `apply-${++sequence}` });
    }
    await mutate("warp.create", { warp: point });
    await mutate("warp.update", { warpId: "arrival", warp: { ...point, pos: { x: 2, y: 1 } } });
    for (const warp of [
      { ...point, id: "bad-map", targetMapId: "beta" },
      { ...point, id: "bad-pos", targetPos: { x: 0, y: 0 } },
      { ...point, id: "null-target", targetPos: null },
      { ...point, id: "unknown", sceneOnly: true },
    ]) await plan("warp.create", { warp }, true);
    await plan("warp.update", { warpId: "arrival", warp: { ...point, triggerMode: "on_enter" } }, true);
    for (const [actionId, parameters] of [
      ["warp.create_reciprocal_apply", { warp: { ...point, id: "clone" } }],
      ["warp.update_pair_apply", { warpId: "arrival", warp: point }],
      ["warp.delete_pair_apply", { warpId: "arrival" }],
    ] as const) await plan(actionId, parameters, true);
    const stable = await readFile(alphaFile);
    const saved = record(JSON.parse(stable.toString("utf8")));
    const arrival = record((saved.warps as JsonRecord[])[0]);
    assert.equal(arrival.triggerMode, "scene_only");
    assert.equal(arrival.targetMapId, "alpha");
    assert.deepEqual(arrival.pos, { x: 2, y: 1 });
    assert.deepEqual(arrival.targetPos, arrival.pos);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const queried = await call("pokemap_query", { projectHandle: workspace.projectHandle,
      resourceKind: "map", operation: "get", ids: ["alpha"], view: "detail" });
    assert.ok(JSON.stringify(queried).includes('"triggerMode":"scene_only"'));
    assert.deepEqual(await readFile(alphaFile), stable);
    assert.deepEqual(await readFile(betaFile), betaBefore);
    assert.deepEqual(await readFile(manifestFile), manifestBefore);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = undefined;
  } finally {
    if (workspace) await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

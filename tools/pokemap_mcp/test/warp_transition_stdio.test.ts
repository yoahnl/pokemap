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

test("live MCP discovers and configures independent native warp screen transitions", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "warp-transition-mcp-"));
  const alphaFile = join(root, "maps/alpha.json");
  const betaFile = join(root, "maps/beta.json");
  const manifestFile = join(root, "project.json");
  const actionId = "warp.transition.configure";
  const first = { id: "first", pos: { x: 1, y: 1 }, targetMapId: "beta", targetPos: { x: 2, y: 1 } };
  const second = { ...first, id: "second", pos: { x: 2, y: 1 } };
  await mkdir(join(root, "maps"));
  await writeFile(manifestFile, JSON.stringify({ name: "Native transition MCP", version: "v8",
    pokemon: canonicalPokemonConfig(), tilesets: [], maps: [
      { id: "alpha", name: "Alpha", relativePath: "maps/alpha.json" },
      { id: "beta", name: "Beta", relativePath: "maps/beta.json" },
    ] }));
  for (const id of ["alpha", "beta"]) await writeFile(join(root, `maps/${id}.json`),
    JSON.stringify({ version: "v8", id, name: id, size: { width: 4, height: 4 }, layers: [], warps: [] }));
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const client = new Client({ name: "native-transition-proof", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  let workspace: JsonRecord | undefined;
  async function call(name: string, input: JsonRecord, failure = false): Promise<JsonRecord> {
    const envelope = record((await client.callTool({ name, arguments: input })).structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify(envelope));
    return record(envelope[failure ? "error" : "data"]);
  }
  try {
    await client.connect(transport);
    const description = await call("pokemap_describe", {});
    const action = (description.mutationActions as JsonRecord[]).find((item) => item.id === actionId);
    assert.ok(action);
    const inputSchema = record(record(action.extensions).inputSchema);
    assert.deepEqual(inputSchema.required, ["mapId", "warpId", "transition"]);
    const transitionSchema = record(record(inputSchema.properties).transition);
    assert.deepEqual(record(record(transitionSchema.properties).type).enum, ["fade", "hgss", "none"]);
    assert.equal(transitionSchema.additionalProperties, false);
    const resource = (description.resourceKinds as JsonRecord[]).find((item) => item.id === "map");
    assert.ok(resource);
    assert.equal(record(record(resource.extensions).warpTransition).configureAction, actionId);
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const manifestBefore = await readFile(manifestFile), betaBefore = await readFile(betaFile);
    let sequence = 0;
    async function plan(action: string, parameters: JsonRecord, failure = false): Promise<JsonRecord> {
      assert.ok(workspace);
      const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
      const before = await readFile(alphaFile), id = `transition-${++sequence}`;
      const result = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
        requestId: id, actionId: action, actionVersion: 1, workspaceHandle: workspace.workspaceHandle,
        expectedRevision: validation.snapshotRevision, idempotencyKey: id,
        parameters: { mapId: "alpha", ...parameters },
      } }, failure);
      assert.deepEqual(await readFile(alphaFile), before);
      return result;
    }
    async function mutate(action: string, parameters: JsonRecord): Promise<void> {
      const planned = await plan(action, parameters);
      assert.ok(workspace);
      await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle,
        planId: planned.planId, operationId: `apply-${++sequence}` });
    }
    await mutate("warp.create", { warp: first });
    await mutate("warp.create", { warp: second });
    for (const transition of [
      { type: "hgss", durationSeconds: .4 },
      { type: "none", durationSeconds: .2 },
      { type: "fade", durationSeconds: .1 },
    ]) {
      await mutate(actionId, { warpId: "first", transition });
      const saved = record(JSON.parse((await readFile(alphaFile)).toString("utf8")));
      const warps = saved.warps as JsonRecord[];
      assert.deepEqual(warps[0]?.transition, transition);
      assert.deepEqual(warps[1]?.transition, { type: "fade", durationSeconds: .2 });
      assert.deepEqual(record(warps[0]).pos, first.pos);
      assert.equal(record(warps[0]).targetMapId, "beta");
    }
    for (const transition of [
      { type: "unknown", durationSeconds: .2 },
      { type: "hgss", durationSeconds: 0 },
      { type: "fade", durationSeconds: 5.1 },
      { type: "none", durationSeconds: -1 },
      { type: "fade", durationSeconds: .2, extra: true },
    ]) await plan(actionId, { warpId: "first", transition }, true);
    await mutate("warp.create", { warp: { id: "passive", pos: { x: 0, y: 0 }, triggerMode: "scene_only" } });
    const passiveError = await plan(actionId, { warpId: "passive", transition: { type: "hgss", durationSeconds: .2 } }, true);
    assert.equal(record(passiveError.details).domainCode, "warp.transition_requires_active_warp");
    const stable = await readFile(alphaFile);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const queried = await call("pokemap_query", { projectHandle: workspace.projectHandle,
      resourceKind: "map", operation: "get", ids: ["alpha"], view: "detail" });
    assert.ok(JSON.stringify(queried).includes('"durationSeconds":0.1'));
    assert.deepEqual(await readFile(alphaFile), stable);
    assert.deepEqual(await readFile(betaFile), betaBefore);
    assert.deepEqual(await readFile(manifestFile), manifestBefore);
    if (process.env.POKEMAP_TRANSITION_RECEIPT) await writeFile(process.env.POKEMAP_TRANSITION_RECEIPT,
      JSON.stringify({ status: "PASS_LIVE_DESCRIBE_PLAN_APPLY_REOPEN_QUERY", action, resource,
        styles: ["hgss", "none", "fade"], invalidPayloadsRejected: 5, passiveArrivalRejected: true, secondWarpUnchanged: true,
        manifestAndTargetMapByteIdentical: true, noScenesOrCinematicsCreated: true }, null, 2));
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = undefined;
  } finally {
    if (workspace) await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

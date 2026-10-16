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
function map(id: string, role: string): JsonRecord {
  return { id, name: id, version: "v8", size: { width: 6, height: 5 }, layers: [], entities: [{ id: `${id}-spawn`, kind: "spawn", pos: { x: 2, y: 2 }, blocksMovement: false, spawn: {} }], gameplayZones: [
    { id: "terrain", kind: "movement", area: { pos: { x: 0, y: 0 }, size: { width: 6, height: 5 } }, movement: { requiredMode: role === "surface" ? "surf" : "dive" } },
    { id: "point", kind: "fieldAction", area: { pos: { x: 2, y: 2 }, size: { width: 1, height: 1 } }, fieldAction: { actionKind: "dive", dive: { role, arrivalSpawnId: `${id}-spawn` } } },
  ] };
}
test("live MCP discovers, plans, links, rejects stale preimages, unlinks and cold reopens native Dive", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "dive-pair-mcp-"));
  await mkdir(join(root, "maps"));
  for (const id of ["sea", "deep"]) await writeFile(join(root, `maps/${id}.json`), JSON.stringify(map(id, id === "sea" ? "surface" : "underwater")));
  const projectFile = join(root, "project.json");
  await writeFile(projectFile, JSON.stringify({ name: "Dive MCP", version: "v8", pokemon: canonicalPokemonConfig(), maps: ["sea", "deep"].map(id => ({ id, name: id, relativePath: `maps/${id}.json` })), tilesets: [] }));
  const projectBefore = await readFile(projectFile);
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const client = new Client({ name: "dive-pair-test", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  let workspace: JsonRecord | undefined;
  let sequence = 0;
  async function call(name: string, input: JsonRecord, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: input });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify({ name, envelope }));
    return record(envelope[failure ? "error" : "data"]);
  }
  async function read(id: string): Promise<JsonRecord> { return record(JSON.parse(await readFile(join(root, `maps/${id}.json`), "utf8"))); }
  function dive(value: JsonRecord): JsonRecord { return record(record((value.gameplayZones as JsonRecord[])[1]!.fieldAction).dive); }
  async function plan(actionId: string, parameters: JsonRecord, failure = false, revision?: unknown): Promise<JsonRecord> {
    const validation = await call("pokemap_validate", { projectHandle: workspace!.projectHandle });
    const before = await Promise.all([readFile(join(root, "maps/sea.json")), readFile(join(root, "maps/deep.json"))]);
    const id = `dive-${++sequence}`;
    const planned = await call("pokemap_plan", { projectHandle: workspace!.projectHandle, request: { requestId: id, actionId, actionVersion: 1, workspaceHandle: workspace!.workspaceHandle, expectedRevision: revision ?? validation.snapshotRevision, idempotencyKey: id, parameters: { mapId: "sea", zoneId: "point", ...parameters } } }, failure);
    assert.deepEqual(await readFile(join(root, "maps/sea.json")), before[0]);
    assert.deepEqual(await readFile(join(root, "maps/deep.json")), before[1]);
    return planned;
  }
  async function apply(plan: JsonRecord): Promise<void> { await call("pokemap_apply", { operation: "apply", projectHandle: workspace!.projectHandle, planId: plan.planId, operationId: `dive-${++sequence}` }); }
  try {
    await client.connect(transport);
    const description = await call("pokemap_describe", {});
    const actions = (description.mutationActions as JsonRecord[]).filter(entry => String(entry.id).startsWith("gameplay_zone.dive."));
    assert.equal(actions.length, 2);
    for (const action of actions) assert.equal(record(action.extensions).multiFileGuarantee, "recoverable");
    const payloadAction = (description.mutationActions as JsonRecord[]).find(entry => entry.id === "gameplay_zone.set_field_action_payload")!;
    assert.ok((record(record(payloadAction.extensions).fieldActionZone).actionKinds as string[]).includes("dive"));
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const initial = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    const params = { targetMapId: "deep", targetZoneId: "point" };
    const cancelled = await plan("gameplay_zone.dive.link_pair_apply", params);
    assert.ok(cancelled.planId);
    assert.equal(dive(await read("sea")).link, undefined);
    assert.equal(dive(await read("deep")).link, undefined);
    await plan("gameplay_zone.dive.link_pair_apply", { targetMapId: "sea", targetZoneId: "point" }, true);
    await apply(await plan("gameplay_zone.dive.link_pair_apply", params));
    assert.deepEqual(dive(await read("sea")).link, { mapId: "deep", zoneId: "point" });
    assert.deepEqual(dive(await read("deep")).link, { mapId: "sea", zoneId: "point" });
    await plan("gameplay_zone.dive.link_pair_apply", params, true);
    const stale = await plan("gameplay_zone.dive.unlink_pair_apply", {}, true, initial.snapshotRevision);
    assert.equal(stale.domainCode, "plan.stale");
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const query = await call("pokemap_query", { projectHandle: workspace.projectHandle, resourceKind: "map", operation: "get", ids: ["deep"], view: "detail" });
    assert.ok(JSON.stringify(query).includes('"actionKind":"dive"'));
    await apply(await plan("gameplay_zone.dive.unlink_pair_apply", {}));
    assert.equal(dive(await read("sea")).link, undefined);
    assert.equal(dive(await read("deep")).link, undefined);
    assert.equal(dive(await read("sea")).arrivalSpawnId, "sea-spawn");
    assert.deepEqual(await readFile(projectFile), projectBefore);
    if (process.env.POKEMAP_TEST_DIVE_RECEIPT) await writeFile(process.env.POKEMAP_TEST_DIVE_RECEIPT, JSON.stringify({ actions, live: true, transport: "MCP stdio", serverSha256: createHash("sha256").update(await readFile(resolve("dist/src/index.js"))).digest("hex"), verified: ["describe", "planNoWrite", "linkPair", "unlinkPair", "rejectSelf", "rejectLinked", "stale", "coldReopen", "exactSpawnRetained"] }, null, 2));
  } finally {
    if (workspace) await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    await client.close(); await transport.close(); await rm(root, { recursive: true, force: true });
  }
});

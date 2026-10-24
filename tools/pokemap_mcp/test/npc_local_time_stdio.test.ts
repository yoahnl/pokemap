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

function predicate(startMinute: number, endMinute: number): JsonRecord {
  return { kind: "localTimeWindow", refId: "", timeWindow: { startMinute, endMinute } };
}

test("MCP discovers and persists NPC presence and battle hours with safe clearing", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "npc-hours-mcp-"));
  const mapFile = join(root, "maps/route.json");
  const projectFile = join(root, "project.json");
  await mkdir(join(root, "maps"));
  await writeFile(projectFile, JSON.stringify({ name: "NPC hours", version: "v8", tilesets: [], pokemon: canonicalPokemonConfig(),
    maps: [{ id: "route", name: "Route", relativePath: "maps/route.json" }],
    trainers: [{ id: "guard", name: "Guard", trainerClass: "Police" }] }));
  await writeFile(mapFile, JSON.stringify({ id: "route", name: "Route", version: "v8",
    size: { width: 8, height: 6 }, layers: [], entities: [
      { id: "guard", kind: "npc", pos: { x: 2, y: 1 }, npc: { displayName: "Guard", trainerId: "guard" } },
    ] }));
  const projectBefore = await readFile(projectFile);
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const client = new Client({ name: "npc-hours-test", version: "1.0.0" });
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
    const id = `hours-${++sequence}`;
    const result = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
      requestId: id, actionId, actionVersion: 1, workspaceHandle: workspace.workspaceHandle,
      expectedRevision: revision ?? validation.snapshotRevision, idempotencyKey: id, parameters,
    } }, failure);
    assert.deepEqual(await readFile(mapFile), before);
    assert.deepEqual(await readFile(projectFile), projectBefore);
    return result;
  }
  async function apply(actionId: string, parameters: JsonRecord): Promise<void> {
    const planned = await plan(actionId, parameters);
    assert.ok(workspace);
    await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle,
      planId: planned.planId, operationId: `apply-hours-${sequence}` });
  }
  async function npc(): Promise<JsonRecord> {
    const map = record(JSON.parse(await readFile(mapFile, "utf8")));
    const entity = (map.entities as JsonRecord[])[0]!;
    assert.deepEqual(entity.pos, { x: 2, y: 1 });
    return record(entity.npc);
  }
  try {
    await client.connect(transport);
    const description = await call("pokemap_describe", {});
    const action = (description.mutationActions as JsonRecord[]).find(entry => entry.id === "npc.set_trainer_battle_rule");
    assert.ok(action);
    assert.deepEqual(record(record(action.extensions).npcLocalTime).windowFields, ["startMinute", "endMinute"]);
    assert.ok((record(record(action.extensions).npcLocalTime).affects as string[]).includes("handoffRecheck"));
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const initial = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    for (const [start, end] of [[240, 1200], [1200, 240], [0, 1440]] as const) {
      const when = predicate(start, end);
      await apply("npc.set_visibility_rule", { mapId: "route", entityId: "guard", visibilityRule: { mode: "visibleWhen", predicate: when } });
      await apply("npc.set_trainer_battle_rule", { mapId: "route", entityId: "guard", trainerBattleWhen: when });
      const saved = await npc();
      assert.deepEqual(record(saved.visibilityRule).predicate, when);
      assert.deepEqual(saved.trainerBattleWhen, when);
      assert.equal(saved.displayName, "Guard");
    }
    for (const when of [predicate(240, 240), predicate(-1, 1200), predicate(1440, 0), predicate(0, 1441),
      { kind: "localTimeWindow", refId: "unexpected", timeWindow: { startMinute: 240, endMinute: 1200 } }]) {
      const rejected = await plan("npc.set_trainer_battle_rule", { mapId: "route", entityId: "guard", trainerBattleWhen: when }, true);
      assert.notEqual(rejected.domainCode, "worker.internal");
    }
    const stale = await plan("npc.set_trainer_battle_rule", { mapId: "route", entityId: "guard", trainerBattleWhen: null }, true, initial.snapshotRevision);
    assert.equal(stale.domainCode, "plan.stale");
    await apply("npc.set_trainer", { mapId: "route", entityId: "guard", trainerId: null });
    assert.equal((await npc()).trainerBattleWhen ?? null, null);
    await apply("npc.set_visibility_rule", { mapId: "route", entityId: "guard", visibilityRule: null });
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const reopened = await call("pokemap_query", { projectHandle: workspace.projectHandle,
      resourceKind: "map", operation: "get", ids: ["route"], view: "detail" });
    assert.ok(JSON.stringify(reopened).includes('"Guard"'));
    assert.equal((await npc()).visibilityRule ?? null, null);
    assert.deepEqual(await readFile(projectFile), projectBefore);
  } finally {
    if (workspace) await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

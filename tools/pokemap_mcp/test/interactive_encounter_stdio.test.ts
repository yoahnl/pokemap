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

test("live MCP discovers native interactive encounters and persists set clear undo query and stale guards", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "cut-obstacle-mcp-"));
  const mapFile = join(root, "maps/route.json");
  const projectFile = join(root, "project.json");
  await mkdir(join(root, "maps"));
  await writeFile(projectFile, JSON.stringify({ name: "Cut MCP", version: "v8", pokemon: canonicalPokemonConfig(),
    maps: [{ id: "route", name: "Route", relativePath: "maps/route.json" }], encounterTables: [{id: "trees", name: "Trees", encounterKind: "headbutt", chancePerStep: 1, entries: [{speciesId: "sproutle", minLevel: 2, maxLevel: 2, weight: 1}]}, {id:"rocks",name:"Rocks",encounterKind:"special",chancePerStep:1,entries:[{speciesId:"sproutle",minLevel:2,maxLevel:2,weight:1}]}],
    tilesets: [{ id: "trees", name: "Trees", relativePath: "trees.png" }],
    elementCategories: [{ id: "props", name: "Props" }],
    elements: [{ id: "tree-visual", name: "Tree", tilesetId: "trees", categoryId: "props",
      frames: [{ source: { x: 0, y: 0, width: 2, height: 1 } }] }] }));
  const entities = [
    { id: "tree", name: "Tree", kind: "custom", pos: { x: 2, y: 1 },
      editorVisual: { elementId: "tree-visual" }, properties: { preserved: "yes" } },
    {id:"rock",kind:"custom",pos:{x:3,y:3},editorVisual:{elementId:"tree-visual"},fieldObstacle:{kind:"rockSmashRock",resetPolicy:"mapInstance"}},
    { id: "wide", kind: "custom", pos: { x: 4, y: 1 }, size: { width: 2, height: 1 }, editorVisual: { elementId: "tree-visual" } },
    { id: "no-visual", kind: "custom", pos: { x: 6, y: 1 } },
  ];
  await writeFile(mapFile, JSON.stringify({ id: "route", name: "Route", version: "v8",
    size: { width: 8, height: 6 }, layers: [], entities }));
  const projectBefore = await readFile(projectFile);
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const client = new Client({ name: "cut-obstacle-test", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  let workspace: JsonRecord | undefined;
  let sequence = 0;
  async function call(name: string, input: JsonRecord, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: input });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify({ name, envelope }));
    return record(envelope[failure ? "error" : "data"]);
  }
  async function plan(parameters: JsonRecord, failure = false, revision?: unknown): Promise<JsonRecord> {
    assert.ok(workspace);
    const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    const before = await readFile(mapFile);
    const id = `cut-${++sequence}`;
    const planned = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
      requestId: id, actionId: "entity.set_interactive_encounter", actionVersion: 1,
      workspaceHandle: workspace.workspaceHandle, expectedRevision: revision ?? validation.snapshotRevision,
      idempotencyKey: id, parameters,
    } }, failure);
    assert.deepEqual(await readFile(mapFile), before);
    assert.deepEqual(await readFile(projectFile), projectBefore);
    return planned;
  }
  async function savedTree(): Promise<JsonRecord> {
    const map = record(JSON.parse(await readFile(mapFile, "utf8")));
    const tree = (map.entities as JsonRecord[]).find(entity => entity.id === "tree")!;
    assert.deepEqual(tree.pos, entities[0]!.pos);
    assert.deepEqual(tree.properties, { preserved: "yes" });
    assert.deepEqual(record(tree.editorVisual), { elementId: "tree-visual", renderInForeground: false });
    assert.equal(tree.kind, "custom");
    assert.equal(tree.blocksMovement, true);
    return tree;
  }
  const cut = { trigger: "headbutt", encounterTableId: "trees", reusePolicy: "oncePerMapInstance", conditions: [], presentation: { encounterTableId: "trees", encounterKind: "headbutt", battleBackgroundRelativePath: null, battleMusicPath: null, encounterMusicPath: null, battleTransitionIds: [] } };
  try {
    await client.connect(transport);
    const description = await call("pokemap_describe", {});
    const action = (description.mutationActions as JsonRecord[]).find(entry => entry.id === "entity.set_interactive_encounter");
    assert.ok(action);
    assert.deepEqual(record(record(action.extensions).interactiveEncounter).triggers, ["headbutt", "afterRockSmash"]);
    const mapKind = (description.resourceKinds as JsonRecord[]).find(entry => entry.id === "map");
    assert.ok(mapKind && record(mapKind.extensions).interactiveEncounters);
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const initial = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    const set = await plan({ mapId: "route", entityId: "tree", interactiveEncounter: cut });
    await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle, planId: set.planId, operationId: "set-cut" });
    assert.deepEqual((await savedTree()).interactiveEncounter, cut);
    for (const parameters of [
      { mapId: "route", entityId: "wide", interactiveEncounter: cut },
      { mapId: "route", entityId: "no-visual", interactiveEncounter: cut },
      { mapId: "route", entityId: "tree", interactiveEncounter: { ...cut, unknown: true } },
      { mapId: "route", entityId: "tree" },
    ]) {
      const rejected = await plan(parameters, true);
      assert.notEqual(rejected.domainCode, "worker.internal");
    }
    const stale = await plan({ mapId: "route", entityId: "tree", interactiveEncounter: null }, true, initial.snapshotRevision);
    assert.equal(stale.domainCode, "plan.stale");
    const clear = await plan({ mapId: "route", entityId: "tree", interactiveEncounter: null });
    await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle, planId: clear.planId, operationId: "clear-cut" });
    assert.equal(Object.hasOwn(await savedTree(), "interactiveEncounter"), false);
    const history = await call("pokemap_history", { operation: "list", projectHandle: workspace.projectHandle, limit: 1 });
    const entry = (history.entries as JsonRecord[])[0]!;
    await call("pokemap_history", { operation: "undo", projectHandle: workspace.projectHandle, entryId: entry.entryId, idempotencyKey: "undo-clear-cut" });
    assert.deepEqual((await savedTree()).interactiveEncounter, cut);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const reopened = await call("pokemap_query", { projectHandle: workspace.projectHandle,
      resourceKind: "map", operation: "get", ids: ["route"], view: "detail" });
    const reopenedMap = record((reopened.items as unknown[])[0]);
    const reopenedTree = (reopenedMap.entities as JsonRecord[]).find(entity => entity.id === "tree");
    assert.ok(reopenedTree);
    assert.deepEqual(reopenedTree.interactiveEncounter, cut);
    assert.deepEqual(await readFile(projectFile), projectBefore);
    const afterSmash = { ...cut, trigger: "afterRockSmash", encounterTableId: "rocks", presentation: { ...cut.presentation, encounterTableId: "rocks", encounterKind: "special" } };
    const rockPlan = await plan({mapId:"route",entityId:"rock",interactiveEncounter:afterSmash});
    await call("pokemap_apply", {operation:"apply",projectHandle:workspace.projectHandle,planId:rockPlan.planId,operationId:"set-smash-encounter"});
    const rockQuery = await call("pokemap_query",{projectHandle:workspace.projectHandle,resourceKind:"map",operation:"get",ids:["route"],view:"detail"});
    const rockMap = record((rockQuery.items as unknown[])[0]);
    const reopenedRock = (rockMap.entities as JsonRecord[]).find(entity => entity.id === "rock");
    assert.ok(reopenedRock);
    assert.deepEqual(reopenedRock.interactiveEncounter, afterSmash);
    await plan({mapId:"route",entityId:"tree",interactiveEncounter:afterSmash},true);
  } finally {
    if (workspace) await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

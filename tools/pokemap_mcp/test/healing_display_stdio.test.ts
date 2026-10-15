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

test("live MCP discovers healing display and persists set, clear, undo and reopen with stale guards", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "healing-display-mcp-"));
  const mapFile = join(root, "maps/route.json");
  const projectFile = join(root, "project.json");
  await mkdir(join(root, "maps"));
  await writeFile(projectFile, JSON.stringify({ name: "Healing display MCP", version: "v8", pokemon: canonicalPokemonConfig(),
    maps: [{ id: "route", name: "Route", relativePath: "maps/route.json" }],
    tilesets: [1,2].map(sheet => ({id:`sheet-${sheet}`,name:`Sheet ${sheet}`,relativePath:`sheet-${sheet}.png`,source:{kind:"regular_atlas",assetId:`sheet-${sheet}`,pixelWidth:256,pixelHeight:192,tileWidth:64,tileHeight:48,tileProperties:[]}})),
    elementCategories:[{id:"props",name:"Props"}],
    elements:Array.from({length:6},(_,i)=>({id:`balls-${i+1}`,name:`Boules ${i+1}`,tilesetId:`sheet-${i<3?1:2}`,categoryId:"props",frames:Array.from({length:4},(_,x)=>({source:{x,y:i%3+1},durationMs:125}))})) }));
  const entities = [
    {id:"balls",name:"Boules",kind:"custom",pos:{x:2,y:1},blocksMovement:false,properties:{preserved:"yes"}},
    {id:"wide",kind:"custom",pos:{x:4,y:1},size:{width:2,height:1},blocksMovement:false},
    {id:"blocking",kind:"custom",pos:{x:6,y:1}},
  ];
  await writeFile(mapFile, JSON.stringify({ id: "route", name: "Route", version: "v8",
    size: { width: 8, height: 6 }, layers: [], entities }));
  const projectBefore = await readFile(projectFile);
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const client = new Client({ name: "healing-display-test", version: "1.0.0" });
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
    const id = `healing-display-${++sequence}`;
    const planned = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
      requestId: id, actionId: "entity.set_healing_display", actionVersion: 1,
      workspaceHandle: workspace.workspaceHandle, expectedRevision: revision ?? validation.snapshotRevision,
      idempotencyKey: id, parameters,
    } }, failure);
    assert.deepEqual(await readFile(mapFile), before);
    assert.deepEqual(await readFile(projectFile), projectBefore);
    return planned;
  }
  async function savedTree(): Promise<JsonRecord> {
    const map = record(JSON.parse(await readFile(mapFile, "utf8")));
    const tree = (map.entities as JsonRecord[]).find(entity => entity.id === "balls")!;
    assert.deepEqual(tree.pos, entities[0]!.pos);
    assert.deepEqual(tree.properties, { preserved: "yes" });
    assert.equal(tree.editorVisual,null);
    assert.equal(tree.kind, "custom");
    assert.equal(tree.blocksMovement, false);
    return tree;
  }
  const cut = {variantElementIds:Array.from({length:6},(_,i)=>`balls-${i+1}`)};
  try {
    await client.connect(transport);
    const description = await call("pokemap_describe", {});
    const action = (description.mutationActions as JsonRecord[]).find(entry => entry.id === "entity.set_healing_display");
    assert.ok(action);
    assert.deepEqual(record(record(action.extensions).healingDisplay), {
      variantCount:6,variantReference:"projectElement",entityKind:"custom",blocksMovement:false,
      footprint:{width:1,height:1},mapMode:"2d",clearValue:null,parameters:["mapId","entityId","healingDisplay"],
    });
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const initial = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    const set = await plan({ mapId: "route", entityId: "balls", healingDisplay: cut });
    await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle, planId: set.planId, operationId: "set-cut" });
    assert.deepEqual((await savedTree()).healingDisplay, cut);
    for (const parameters of [
      { mapId: "route", entityId: "wide", healingDisplay: cut },
      { mapId: "route", entityId: "blocking", healingDisplay: cut },
      { mapId: "route", entityId: "balls", healingDisplay: { ...cut, unknown: true } },
      { mapId: "route", entityId: "balls" },
    ]) {
      const rejected = await plan(parameters, true);
      assert.notEqual(rejected.domainCode, "worker.internal");
    }
    const stale = await plan({ mapId: "route", entityId: "balls", healingDisplay: null }, true, initial.snapshotRevision);
    assert.equal(stale.domainCode, "plan.stale");
    const clear = await plan({ mapId: "route", entityId: "balls", healingDisplay: null });
    await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle, planId: clear.planId, operationId: "clear-cut" });
    assert.equal(Object.hasOwn(await savedTree(), "healingDisplay"), false);
    const history = await call("pokemap_history", { operation: "list", projectHandle: workspace.projectHandle, limit: 1 });
    const entry = (history.entries as JsonRecord[])[0]!;
    await call("pokemap_history", { operation: "undo", projectHandle: workspace.projectHandle, entryId: entry.entryId, idempotencyKey: "undo-clear-cut" });
    assert.deepEqual((await savedTree()).healingDisplay, cut);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const reopened = await call("pokemap_query", { projectHandle: workspace.projectHandle,
      resourceKind: "map", operation: "get", ids: ["route"], view: "detail" });
    assert.ok(JSON.stringify(reopened).includes(JSON.stringify(cut)));
    assert.deepEqual(await readFile(projectFile), projectBefore);
    const receiptPath = process.env.POKEMAP_TEST_CATALOG_RECEIPT;
    if (receiptPath) await writeFile(receiptPath, JSON.stringify({ action, live: true,
      transport: "MCP stdio", packageRoot: process.cwd(),
      serverSha256: createHash("sha256").update(await readFile(resolve("dist/src/index.js"))).digest("hex"),
      verified: ["describe", "planWithoutWrites", "set", "clear", "undo", "reopen", "staleGuard", "closedPayload", "shapeAndVisualGuards"] }, null, 2) + "\n", { flag: "wx" });
  } finally {
    if (workspace) await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

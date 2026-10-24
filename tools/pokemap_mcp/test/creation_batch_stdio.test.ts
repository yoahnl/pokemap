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

function fact(index: number): JsonRecord {
  return { id: `fact_f${index}`, label: `F${index}`, defaultValue: false };
}

function entity(index: number): JsonRecord {
  return { id: `npc-${index}`, name: `NPC ${index}`, kind: "npc",
    pos: { x: index % 16, y: Math.floor(index / 16) },
    npc: { displayName: `NPC ${index}` }, properties: { source: `batch-${index}` } };
}

test("MCP creates bounded Fact and entity batches with atomic history and cold reopen", { timeout: 240_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "creation-batches-mcp-"));
  const projectFile = join(root, "project.json");
  const mapFile = join(root, "maps/route.json");
  await mkdir(join(root, "maps"));
  await writeFile(projectFile, JSON.stringify({ name: "Creation batches", version: "v8",
    pokemon: canonicalPokemonConfig(), tilesets: [],
    facts: [{ id: "fact_existing", label: "Existing", defaultValue: false }],
    maps: [{ id: "route", name: "Route", relativePath: "maps/route.json" }] }));
  await writeFile(mapFile, JSON.stringify({ id: "route", name: "Route", version: "v8",
    size: { width: 32, height: 32 }, layers: [],
    entities: [{ id: "existing", name: "Existing", kind: "npc", pos: { x: 31, y: 31 } }] }));
  const initialProject = await readFile(projectFile);
  const initialMap = await readFile(mapFile);
  const args = [resolve(process.env.POKEMAP_TEST_MCP_ENTRY ?? "dist/src/index.js"),
    "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  if (process.env.POKEMAP_TEST_AUTHORING_PACKAGE) args.push("--authoring-package", process.env.POKEMAP_TEST_AUTHORING_PACKAGE);
  const client = new Client({ name: "creation-batches", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  let workspace: JsonRecord | undefined;
  let sequence = 0;
  async function call(name: string, input: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const envelope = record((await client.callTool({ name, arguments: input })).structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify({ name, envelope }));
    return record(envelope[failure ? "error" : "data"]);
  }
  async function plan(actionId: string, parameters: JsonRecord, failure = false, dryRun = false): Promise<JsonRecord> {
    const active = workspace;
    assert.ok(active);
    const validation = await call("pokemap_validate", { projectHandle: active.projectHandle });
    const before = [await readFile(projectFile), await readFile(mapFile)];
    const id = `creation-batch-${++sequence}`;
    const planned = await call("pokemap_plan", { projectHandle: active.projectHandle, request: {
      requestId: id, actionId, actionVersion: 1, workspaceHandle: active.workspaceHandle,
      parameters, expectedRevision: validation.snapshotRevision, idempotencyKey: id, dryRun,
    } }, failure);
    assert.deepEqual(await readFile(projectFile), before[0]);
    assert.deepEqual(await readFile(mapFile), before[1]);
    if (failure) assert.notEqual(planned.domainCode, "worker.internal");
    return planned;
  }
  async function apply(actionId: string, parameters: JsonRecord): Promise<JsonRecord> {
    const prepared = await plan(actionId, parameters);
    const active = workspace;
    assert.ok(active);
    const input = { operation: "apply", projectHandle: active.projectHandle,
      planId: prepared.planId, operationId: `apply-creation-${sequence}` };
    const applied = await call("pokemap_apply", input);
    const replay = await call("pokemap_apply", input);
    assert.deepEqual(replay.receipt, applied.receipt);
    return record(applied.receipt);
  }
  try {
    await client.connect(transport);
    const catalog = await call("pokemap_describe");
    for (const [id, minimum, maximum] of [
      ["fact.create_batch", "minFacts", "maxFacts"],
      ["entity.create_batch", "minEntities", "maxEntities"],
    ]) {
      const action = (catalog.mutationActions as JsonRecord[]).find(value => value.id === id);
      assert.ok(action);
      const batch = record(record(action.extensions).batch);
      assert.equal(batch[minimum!], 1);
      assert.equal(batch[maximum!], 128);
      assert.equal(batch.atomic, true);
      assert.equal(batch.semantics, "createOnly");
    }
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    for (const facts of [[], Array.from({ length: 129 }, (_, i) => fact(i)),
      [fact(0), fact(0)], [fact(0), { id: "fact_existing", label: "Existing", defaultValue: true }],
      [fact(0), { ...fact(1), id: "not-canonical" }]]) {
      await plan("fact.create_batch", { facts }, true);
    }
    for (const entities of [[], Array.from({ length: 129 }, (_, i) => entity(i)),
      [entity(0), entity(0)], [entity(0), { ...entity(1), id: "existing" }],
      [entity(0), { ...entity(1), pos: { x: 100, y: 100 } }],
      [entity(0), { ...entity(1), kind: "unknown" }]]) {
      await plan("entity.create_batch", { mapId: "route", entities }, true);
    }
    const preview = await plan("fact.create_batch", { facts: [fact(0)] }, false, true);
    assert.equal(preview.applicable, false);
    const facts = Array.from({ length: 128 }, (_, i) => fact(i));
    const factReceipt = await apply("fact.create_batch", { facts });
    assert.equal((record(JSON.parse(await readFile(projectFile, "utf8"))).facts as unknown[]).length, 129);
    assert.deepEqual(await readFile(mapFile), initialMap);
    const entities = Array.from({ length: 128 }, (_, i) => entity(i));
    const entityReceipt = await apply("entity.create_batch", { mapId: "route", entities });
    const savedMap = record(JSON.parse(await readFile(mapFile, "utf8")));
    const savedEntities = savedMap.entities as JsonRecord[];
    assert.equal(savedEntities.length, 129);
    assert.deepEqual(savedEntities.slice(1).map(value => value.id), entities.map(value => value.id));
    assert.deepEqual(savedEntities.slice(1).map(value => record(value.properties).source), entities.map(value => record(value.properties).source));
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const history = await call("pokemap_history", { operation: "list", projectHandle: workspace.projectHandle });
    assert.equal((history.entries as unknown[]).length, 2);
    const queried = await call("pokemap_query", { projectHandle: workspace.projectHandle,
      resourceKind: "map", operation: "get", ids: ["route"], view: "detail" });
    assert.ok(JSON.stringify(queried).includes('"npc-127"'));
    await call("pokemap_history", { operation: "undo", projectHandle: workspace.projectHandle,
      entryId: entityReceipt.receiptId, idempotencyKey: "undo-creation-entities" });
    assert.deepEqual(await readFile(mapFile), initialMap);
    await call("pokemap_history", { operation: "undo", projectHandle: workspace.projectHandle,
      entryId: factReceipt.receiptId, idempotencyKey: "undo-creation-facts" });
    assert.deepEqual(await readFile(projectFile), initialProject);
    assert.deepEqual(await readFile(mapFile), initialMap);
  } finally {
    if (workspace) await client.callTool({ name: "pokemap_workspace", arguments: {
      operation: "close", workspaceHandle: workspace.workspaceHandle,
    } }).catch(() => undefined);
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

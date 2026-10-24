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

test("live MCP discovers conditional encounters and persists reopens rejects and undoes variants", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "encounter-variants-mcp-"));
  await mkdir(join(root, "maps"));
  const projectFile = join(root, "project.json");
  const mapFile = join(root, "maps/route.json");
  await writeFile(projectFile, JSON.stringify({ name: "Variants", version: "v8", pokemon: canonicalPokemonConfig(), maps: [
    { id: "route", name: "Route", relativePath: "maps/route.json" }], tilesets: [],
    facts: [{ id: "edition", label: "Edition", valueType: "string", defaultValue: "heartgold" }] }));
  await writeFile(mapFile, JSON.stringify({ id: "route", name: "Route", version: "v8", size: { width: 4, height: 4 }, layers: [] }));
  const mapBefore = await readFile(mapFile);
  const projectBefore = await readFile(projectFile);
  await mkdir(join(root, "data/pokemon/species"), { recursive: true });
  await mkdir(join(root, "data/pokemon/media"), { recursive: true });
  await writeFile(join(root, "data/pokemon/species/sentret.json"), JSON.stringify({ schemaVersion: 1, id: "sentret", classification: { isEnabledInProject: true } }));
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const client = new Client({ name: "encounter-variants-test", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  let workspace: JsonRecord | undefined;
  let sequence = 0;
  async function call(name: string, input: JsonRecord, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: input });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify({ name, envelope }));
    return record(envelope[failure ? "error" : "data"]);
  }
  const value = { id: "route_wild", name: "Route wild", encounterKind: "walk", chancePerStep: 0.11, entries: [], variants: [{
    id: "hg_morning", name: "Morning", priority: 1,
    conditions: [{ type: "factEquals", params: { factId: "edition", valueType: "string", value: "heartgold" }, children: [] }],
    timeWindows: [{ startMinute: 240, endMinute: 600 }], entries: [{ speciesId: "sentret", minLevel: 2, maxLevel: 4, weight: 5 }],
  }] };
  async function plan(table: unknown, failure = false, actionId = "campaign.encounter_table.upsert"): Promise<JsonRecord> {
    assert.ok(workspace);
    const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    const id = `variant-${++sequence}`;
    const before = await readFile(projectFile);
    const result = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
      requestId: id, actionId, actionVersion: 1,
      workspaceHandle: workspace.workspaceHandle, expectedRevision: validation.snapshotRevision,
      idempotencyKey: id, parameters: actionId.endsWith("_batch") ? { values: table } : { value: table },
    } }, failure);
    assert.deepEqual(await readFile(projectFile), before);
    assert.deepEqual(await readFile(mapFile), mapBefore);
    return result;
  }
  try {
    await client.connect(transport);
    const description = await call("pokemap_describe", {});
    const action = (description.mutationActions as JsonRecord[]).find(entry => entry.id === "campaign.encounter_table.upsert");
    assert.ok(action);
    const batchAction = (description.mutationActions as JsonRecord[]).find(entry => entry.id === "campaign.encounter_table.upsert_batch");
    assert.ok(batchAction);
    assert.deepEqual(record(batchAction.extensions).batch, { minValues: 1, maxValues: 200, uniqueBy: "id", semantics: "createOrUpdate", atomic: true });
    const contract = record(record(action.extensions).encounterVariants);
    assert.equal(contract.selection, "highestEligiblePriorityBeforeRandom");
    assert.equal(record(contract.timeWindows).endExclusive, true);
    assert.equal(record(contract.timeWindows).wrapsMidnightWhenStartGreaterThanEnd, true);
    const resource = (description.resourceKinds as JsonRecord[]).find(entry => entry.id === "project");
    assert.ok(resource);
    assert.deepEqual(record(record(resource.extensions).encounterTables).variants, contract);
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const planned = await plan(value);
    const applied = await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle, planId: planned.planId, operationId: "apply-variants" });
    assert.ok(applied.receipt);
    const saved = record(JSON.parse(await readFile(projectFile, "utf8")));
    const table = (saved.encounterTables as JsonRecord[])[0]!;
    assert.equal(table.chancePerStep, 0.11);
    assert.equal(((record((table.variants as unknown[])[0]).entries as JsonRecord[])[0]!).speciesId, "sentret");
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const query = await call("pokemap_query", { projectHandle: workspace.projectHandle, resourceKind: "project", operation: "get", ids: ["project"], view: "detail", fieldMask: ["encounterTables"] });
    const items = query.items as JsonRecord[];
    assert.equal(record(((items[0]!.encounterTables as JsonRecord[])[0]!.variants as unknown[])[0]).id, "hg_morning");
    const beforeInvalid = await readFile(projectFile);
    for (const timeWindows of [[{ startMinute: 240, endMinute: 240 }], [{ startMinute: -1, endMinute: 600 }], [{ startMinute: 240.5, endMinute: 600 }]]) {
      const rejected = await plan({ ...value, variants: [{ ...value.variants[0], timeWindows }] }, true);
      assert.notEqual(rejected.domainCode, "worker.internal");
      assert.deepEqual(await readFile(projectFile), beforeInvalid);
    }
    const history = await call("pokemap_history", { operation: "list", projectHandle: workspace.projectHandle, limit: 1 });
    const entry = (history.entries as JsonRecord[])[0]!;
    await call("pokemap_history", { operation: "undo", projectHandle: workspace.projectHandle, entryId: entry.entryId, idempotencyKey: "undo-variants" });
    assert.deepEqual(await readFile(projectFile), projectBefore);
    assert.deepEqual(await readFile(mapFile), mapBefore);
    const batchId = "campaign.encounter_table.upsert_batch";
    const batch = await plan([value, { ...value, id: "second", name: "Second" }], false, batchId);
    await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle, planId: batch.planId, operationId: "apply-encounter-batch" });
    const batchSaved = await readFile(projectFile);
    assert.equal((record(JSON.parse(batchSaved.toString())).encounterTables as unknown[]).length, 2);
    for (const values of [[], [value, value], [value, { ...value, id: "missing-species", entries: [{ speciesId: "missing", minLevel: 2, maxLevel: 3 }] }]]) {
      const rejected = await plan(values, true, batchId);
      assert.notEqual(rejected.domainCode, "worker.internal");
      assert.deepEqual(await readFile(projectFile), batchSaved);
    }
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const batchQuery = await call("pokemap_query", { projectHandle: workspace.projectHandle, resourceKind: "project", operation: "get", ids: ["project"], view: "detail", fieldMask: ["encounterTables"] });
    assert.equal(((batchQuery.items as JsonRecord[])[0]!.encounterTables as unknown[]).length, 2);
    const batchHistory = await call("pokemap_history", { operation: "list", projectHandle: workspace.projectHandle, limit: 1 });
    await call("pokemap_history", { operation: "undo", projectHandle: workspace.projectHandle, entryId: (batchHistory.entries as JsonRecord[])[0]!.entryId, idempotencyKey: "undo-encounter-batch" });
    assert.deepEqual(await readFile(projectFile), projectBefore);
    assert.deepEqual(await readFile(mapFile), mapBefore);
  } finally {
    if (workspace) await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

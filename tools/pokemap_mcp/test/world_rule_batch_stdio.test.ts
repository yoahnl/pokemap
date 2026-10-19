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

function rule(id: string, label: string, effect = "entityVisible"): JsonRecord {
  return { id, label,
    source: { kind: "fact", sourceId: "fact_known", predicate: "isTrue" },
    target: { kind: "mapEntity", mapId: "map", entityId: "actor" },
    effect: { kind: effect },
  };
}

test("L19 MCP discovers and commits one atomic bounded WorldRule batch", { timeout: 180_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "l19-world-rule-batch-"));
  const file = join(root, "project.json");
  const mapFile = join(root, "maps/map.json");
  await mkdir(join(root, "maps"));
  await writeFile(mapFile, JSON.stringify({ id: "map", name: "Map", version: "v8",
    size: { width: 3, height: 3 }, layers: [],
    entities: [{ id: "actor", name: "Actor", kind: "npc", pos: { x: 1, y: 1 } }],
  }));
  const existing = rule("world_rule_existing", "Existing");
  await writeFile(file, JSON.stringify({ name: "WorldRule batch", version: "v8",
    pokemon: canonicalPokemonConfig(), maps: [{ id: "map", name: "Map", relativePath: "maps/map.json" }],
    tilesets: [], facts: [{ id: "fact_known", label: "Known", valueType: "bool", defaultValue: false }],
    worldRules: [existing],
  }));
  const originalMap = await readFile(mapFile);
  const args = [resolve(process.env.POKEMAP_TEST_MCP_ENTRY ?? "dist/src/index.js"),
    "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  if (process.env.POKEMAP_TEST_AUTHORING_PACKAGE) args.push("--authoring-package", process.env.POKEMAP_TEST_AUTHORING_PACKAGE);
  const client = new Client({ name: "l19-world-rule-batch", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  async function call(name: string, input: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const envelope = record((await client.callTool({ name, arguments: input })).structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify({ name, envelope }));
    return record(envelope[failure ? "error" : "data"]);
  }
  let workspace: JsonRecord;
  let sequence = 0;
  async function plan(rules: JsonRecord[], failure = false, dryRun = false): Promise<JsonRecord> {
    const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    const before = await readFile(file);
    const id = `batch-${++sequence}`;
    const result = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
      requestId: id, actionId: "world_rule.upsert_batch", actionVersion: 1,
      workspaceHandle: workspace.workspaceHandle, parameters: { rules },
      expectedRevision: validation.snapshotRevision, idempotencyKey: id, dryRun,
    } }, failure);
    assert.deepEqual(await readFile(file), before);
    assert.deepEqual(await readFile(mapFile), originalMap);
    return result;
  }
  try {
    await client.connect(transport);
    const catalog = await call("pokemap_describe");
    const action = (catalog.mutationActions as JsonRecord[]).find(entry => entry.id === "world_rule.upsert_batch");
    assert.ok(action);
    const contract = record(record(action.extensions).batch);
    assert.equal(contract.minRules, 1);
    assert.equal(contract.maxRules, 128);
    assert.equal(contract.uniqueBy, "id");
    assert.equal(contract.atomic, true);
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const first = rule("world_rule_first", "First");
    const second = rule("world_rule_second", "Second");
    const updated = rule("world_rule_existing", "Existing", "entityHidden");
    for (const rules of [[], Array.from({ length: 129 }, (_, i) => rule(`world_rule_r${i}`, `R${i}`)),
      [first, first], [first, { ...second, source: { kind: "fact", sourceId: "missing", predicate: "isTrue" } }],
      [first, rule("noncanonical", "Wrong identity")]]) {
      const rejected = await plan(rules, true);
      assert.ok(String(rejected.domainCode).startsWith("world_rule.batch_"), JSON.stringify(rejected));
    }
    const values = [updated, first, second];
    const preview = await plan(values, false, true);
    assert.equal(preview.applicable, false);
    const prepared = await plan(values);
    const applyInput = { operation: "apply", projectHandle: workspace.projectHandle,
      planId: prepared.planId, operationId: "l19-batch-apply" };
    const applied = await call("pokemap_apply", applyInput);
    const saved = await readFile(file);
    assert.deepEqual(record(JSON.parse(saved.toString())).worldRules,
      [updated, first, second].map(value => ({ ...value, enabled: true, description: "", priority: 0, tags: [] })));
    const replay = await call("pokemap_apply", applyInput);
    assert.deepEqual(replay.receipt, applied.receipt);
    assert.deepEqual(await readFile(file), saved);
    assert.deepEqual(await readFile(mapFile), originalMap);
    const history = await call("pokemap_history", { projectHandle: workspace.projectHandle, operation: "list" });
    assert.ok(JSON.stringify(history).includes("world_rule.upsert_batch"));
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const queried = await call("pokemap_query", { projectHandle: workspace.projectHandle,
      resourceKind: "worldRule", operation: "list", view: "detail" });
    assert.equal((queried.items as JsonRecord[]).length, 3);
    assert.deepEqual((queried.items as JsonRecord[]).map(item => item.id).sort(), values.map(item => item.id).sort());
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

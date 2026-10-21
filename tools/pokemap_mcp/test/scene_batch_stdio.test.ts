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

function scene(id: string, name: string, dialogue?: string): JsonRecord {
  return { id, name, graph: { startNodeId: "start", nodes: [
    { id: "start", kind: "start" },
    ...(dialogue ? [{ id: "dialogue", kind: "yarnDialogue", payload: { kind: "yarnDialogue", dialogueId: dialogue } }] : []),
    { id: "end", kind: "end" },
  ], edges: [
    { id: "entry", fromNodeId: "start", fromPortId: "completed", toNodeId: dialogue ? "dialogue" : "end", kind: "defaultFlow" },
    ...(dialogue ? [{ id: "exit", fromNodeId: "dialogue", fromPortId: "completed", toNodeId: "end", kind: "defaultFlow" }] : []),
  ] } };
}

test("MCP discovers, refuses invalid tails, commits and undoes an atomic Scene batch", { timeout: 180_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "scene-batch-"));
  const file = join(root, "project.json");
  const mapFile = join(root, "maps/map.json");
  await mkdir(join(root, "maps"));
  await writeFile(mapFile, JSON.stringify({ id: "map", name: "Map", version: "v8",
    size: { width: 3, height: 3 }, layers: [],
    entities: [{ id: "actor", name: "Actor", kind: "npc", pos: { x: 1, y: 1 } }],
  }));
  const existing = scene("scene_existing", "Existing");
  await writeFile(file, JSON.stringify({ name: "Scene batch", version: "v8",
    pokemon: canonicalPokemonConfig(), maps: [{ id: "map", name: "Map", relativePath: "maps/map.json" }],
    tilesets: [], facts: [{ id: "fact_known", label: "Known", valueType: "bool", defaultValue: false }],
    scenes: [existing],
  }));
  const originalMap = await readFile(mapFile);
  const args = [resolve(process.env.POKEMAP_TEST_MCP_ENTRY ?? "dist/src/index.js"),
    "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  if (process.env.POKEMAP_TEST_AUTHORING_PACKAGE) args.push("--authoring-package", process.env.POKEMAP_TEST_AUTHORING_PACKAGE);
  const client = new Client({ name: "scene-batch", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  async function call(name: string, input: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const envelope = record((await client.callTool({ name, arguments: input })).structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify({ name, envelope }));
    return record(envelope[failure ? "error" : "data"]);
  }
  let workspace: JsonRecord;
  let sequence = 0;
  async function plan(scenes: JsonRecord[], failure = false, dryRun = false): Promise<JsonRecord> {
    const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    const before = await readFile(file);
    const id = `batch-${++sequence}`;
    const result = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
      requestId: id, actionId: "scene.upsert_batch", actionVersion: 1,
      workspaceHandle: workspace.workspaceHandle, parameters: { scenes },
      expectedRevision: validation.snapshotRevision, idempotencyKey: id, dryRun,
    } }, failure);
    assert.deepEqual(await readFile(file), before);
    assert.deepEqual(await readFile(mapFile), originalMap);
    return result;
  }
  try {
    await client.connect(transport);
    const catalog = await call("pokemap_describe");
    const action = (catalog.mutationActions as JsonRecord[]).find(entry => entry.id === "scene.upsert_batch");
    assert.ok(action);
    const contract = record(record(action.extensions).batch);
    assert.equal(contract.minScenes, 1);
    assert.equal(contract.maxScenes, 128);
    assert.equal(contract.uniqueBy, "id");
    assert.equal(contract.atomic, true);
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const first = scene("scene_first", "First");
    const second = scene("scene_second", "Second");
    const updated = scene("scene_existing", "Updated");
    for (const scenes of [[], Array.from({ length: 129 }, (_, i) => scene(`scene_r${i}`, `R${i}`)),
      [first, first], [first, scene("invalid", "Invalid", "missing")], [first, {}]]) {
      const rejected = await plan(scenes, true);
      assert.ok(String(rejected.domainCode).startsWith("scene."), JSON.stringify(rejected));
    }
    const values = [updated, first, second];
    const preview = await plan(values, false, true);
    assert.equal(preview.applicable, false);
    const dryRunRefusal = await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle,
      planId: preview.planId, operationId: "scene-batch-dry" }, true);
    assert.equal(dryRunRefusal.domainCode, "plan.dry_run_not_applicable");
    await plan(Array.from({ length: 128 }, (_, i) => scene(`scene_max${i}`, `Maximum ${i}`)));
    const stale = await plan([scene("scene_stale", "Stale")]);
    const prepared = await plan(values);
    const applyInput = { operation: "apply", projectHandle: workspace.projectHandle,
      planId: prepared.planId, operationId: "scene-batch-apply" };
    const applied = await call("pokemap_apply", applyInput);
    const saved = await readFile(file);
    assert.deepEqual((record(JSON.parse(saved.toString())).scenes as JsonRecord[]).map(item => item.id), values.map(item => item.id));
    const staleRefusal = await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle,
      planId: stale.planId, operationId: "scene-batch-stale" }, true);
    assert.equal(staleRefusal.domainCode, "plan.stale");
    assert.deepEqual(await readFile(file), saved);
    const replay = await call("pokemap_apply", applyInput);
    assert.deepEqual(replay.receipt, applied.receipt);
    assert.deepEqual(await readFile(file), saved);
    assert.deepEqual(await readFile(mapFile), originalMap);
    const history = await call("pokemap_history", { projectHandle: workspace.projectHandle, operation: "list" });
    assert.ok(JSON.stringify(history).includes("scene.upsert_batch"));
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const queried = await call("pokemap_query", { projectHandle: workspace.projectHandle,
      resourceKind: "scene", operation: "list", view: "detail" });
    assert.equal((queried.items as JsonRecord[]).length, 3);
    assert.deepEqual((queried.items as JsonRecord[]).map(item => item.id).sort(), values.map(item => item.id).sort());
    const receipt = record(applied.receipt);
    await call("pokemap_history", { projectHandle: workspace.projectHandle, operation: "undo", entryId: receipt.receiptId, idempotencyKey: "undo-scene-batch" });
    const restored = record(JSON.parse((await readFile(file)).toString()));
    assert.deepEqual((restored.scenes as JsonRecord[]).map(item => item.id), [existing.id]);
    assert.deepEqual(await readFile(mapFile), originalMap);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

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

function trainer(id: string, reward = 0): JsonRecord {
  return { id, name: `Trainer ${id}`, trainerClass: "Trainer", moneyReward: reward,
    team: [{ speciesId: "pikachu", level: 10, ballItemId: "ball" }] };
}

test("MCP discovers, atomically authors and reopens a bounded trainer batch", { timeout: 180_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "trainer-batch-mcp-"));
  const projectFile = join(root, "project.json");
  const mapFile = join(root, "maps/map.json");
  const itemsFile = join(root, "data/pokemon/catalogs/items.json");
  await mkdir(join(root, "maps"));
  await mkdir(join(root, "data/pokemon/catalogs"), { recursive: true });
  await writeFile(mapFile, JSON.stringify({ id: "map", name: "Map", version: "v8", size: { width: 4, height: 4 }, layers: [], entities: [] }));
  await writeFile(itemsFile, JSON.stringify({ schemaVersion: 1, entries: [
    { id: "ball", displayName: "Ball", pocketId: "balls", capture: {
      rateNumerator: 1, rateDenominator: 1, allowedEncounterKinds: ["walk"],
    } },
    { id: "potion", displayName: "Potion", pocketId: "medicine", uses: [{
      contexts: ["battle"], target: "party_member", consumption: "on_applied",
      effect: { kind: "heal_hp", mode: "flat", amount: 20 },
    }] },
  ] }));
  await writeFile(projectFile, JSON.stringify({ name: "Trainer batch", version: "v8", tilesets: [],
    pokemon: { ...canonicalPokemonConfig(), catalogFiles: { items: "data/pokemon/catalogs/items.json" } },
    maps: [{ id: "map", name: "Map", relativePath: "maps/map.json" }],
    trainers: [trainer("keep"), trainer("update")],
  }));
  const originalProject = await readFile(projectFile);
  const originalMap = await readFile(mapFile);
  const originalItems = await readFile(itemsFile);
  const args = [resolve(process.env.POKEMAP_TEST_MCP_ENTRY ?? "dist/src/index.js"),
    "--root", root, "--authoring-package", resolve("../../packages/map_authoring"), "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const client = new Client({ name: "trainer-batch", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  let workspace: JsonRecord | undefined;
  let sequence = 0;
  async function call(name: string, args: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const envelope = record((await client.callTool({ name, arguments: args })).structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify({ name, envelope }));
    const result = record(envelope[failure ? "error" : "data"]);
    if (failure) assert.notEqual(result.domainCode, "worker.internal");
    return result;
  }
  async function plan(parameters: JsonRecord, failure = false): Promise<JsonRecord> {
    assert.ok(workspace);
    const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    const before = await readFile(projectFile);
    const id = `trainer-batch-${++sequence}`;
    const result = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
      requestId: id, actionId: "campaign.trainer.upsert_batch", actionVersion: 1,
      workspaceHandle: workspace.workspaceHandle, expectedRevision: validation.snapshotRevision,
      idempotencyKey: id, parameters,
    } }, failure);
    assert.deepEqual(await readFile(projectFile), before);
    assert.deepEqual(await readFile(mapFile), originalMap);
    assert.deepEqual(await readFile(itemsFile), originalItems);
    return result;
  }
  try {
    await client.connect(transport);
    const catalog = await call("pokemap_describe");
    const action = (catalog.mutationActions as JsonRecord[]).find(value => value.id === "campaign.trainer.upsert_batch");
    assert.ok(action);
    const batch = record(record(action.extensions).batch);
    assert.equal(batch.minValues, 1);
    assert.equal(batch.maxValues, 512);
    assert.equal(batch.atomic, true);
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const first = trainer("first", 700);
    for (const parameters of [
      { values: [] }, { values: Array.from({ length: 513 }, (_, i) => trainer(`x${i}`)) },
      { values: [first, first] }, { values: [first, 42] },
      { values: [first, { ...trainer("invalid"), moneyReward: -1 }] },
      { values: [first, { ...trainer("invalid"), team: [{ speciesId: "pikachu", level: 10, ballItemId: "missing" }] }] },
      { values: [first, { ...trainer("invalid"), battleItems: { missing: 1 } }] },
      { values: [first], unknown: true },
    ]) await plan(parameters, true);
    const values = [{ ...trainer("update", 800), battleItems: { potion: 2 } },
      ...Array.from({ length: 412 }, (_, i) => trainer(`batch_${i}`, i))];
    assert.ok(Buffer.byteLength(JSON.stringify({ values }), "utf8") < 2 * 1024 * 1024);
    const prepared = await plan({ values });
    const applyInput = { operation: "apply", projectHandle: workspace.projectHandle,
      planId: prepared.planId, operationId: "trainer-batch-apply" };
    const applied = await call("pokemap_apply", applyInput);
    const saved = await readFile(projectFile);
    const replay = await call("pokemap_apply", applyInput);
    assert.deepEqual(replay.receipt, applied.receipt);
    assert.deepEqual(await readFile(projectFile), saved);
    const savedTrainers = record(JSON.parse(saved.toString())).trainers as JsonRecord[];
    assert.equal(savedTrainers.length, 414);
    assert.deepEqual(savedTrainers.map(value => value.id), ["keep", ...values.map(value => value.id)]);
    assert.deepEqual(savedTrainers.slice(1).map(value => value.moneyReward), values.map(value => value.moneyReward));
    const stale = await plan({ values: [trainer("stale")] });
    await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle,
      planId: (await plan({ values: [trainer("other")] })).planId, operationId: "trainer-revision-change" });
    const beforeStale = await readFile(projectFile);
    const rejectedStale = await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle,
      planId: stale.planId, operationId: "trainer-stale-rejected" }, true);
    assert.equal(rejectedStale.domainCode, "plan.stale");
    assert.deepEqual(await readFile(projectFile), beforeStale);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const query = await call("pokemap_query", { projectHandle: workspace.projectHandle,
      resourceKind: "project", operation: "get", ids: ["project"], view: "detail", fieldMask: ["trainers"] });
    const trainers = record((query.items as JsonRecord[])[0]).trainers as JsonRecord[];
    assert.equal(trainers.length, 415);
    assert.equal(trainers.find(value => value.id === "update")!.moneyReward, 800);
    assert.deepEqual(await readFile(mapFile), originalMap);
    assert.deepEqual(await readFile(itemsFile), originalItems);
    assert.notDeepEqual(await readFile(projectFile), originalProject);
  } finally {
    if (workspace) await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

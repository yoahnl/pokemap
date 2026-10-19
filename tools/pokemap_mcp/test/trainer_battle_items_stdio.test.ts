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

function sha(bytes: Uint8Array): string {
  return createHash("sha256").update(bytes).digest("hex");
}

function medicine(id: string, effect: JsonRecord, extra: JsonRecord = {}): JsonRecord {
  return { id, displayName: id, pocketId: "medicine", uses: [{
    contexts: ["battle"], target: "party_member", consumption: "on_applied", effect, ...extra,
  }] };
}

function assertTrainerFields(actual: JsonRecord, expected: JsonRecord): void {
  for (const [key, value] of Object.entries(expected)) {
    if (key !== "team") assert.deepEqual(actual[key], value, key);
  }
  const actualTeam = actual.team as JsonRecord[];
  const expectedTeam = expected.team as JsonRecord[];
  assert.equal(actualTeam.length, expectedTeam.length);
  for (const [index, member] of expectedTeam.entries()) {
    for (const [key, value] of Object.entries(member)) {
      assert.deepEqual(record(actualTeam[index])[key], value, `team[${index}].${key}`);
    }
  }
}

test("L21a authors finite trainer medicines through the real MCP server", { timeout: 180_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "l21a-stock-mcp-"));
  const file = join(root, "project.json");
  const itemsFile = join(root, "data/pokemon/catalogs/items.json");
  const tonic = medicine("tonic", { kind: "heal_hp", mode: "flat", amount: 20 });
  const cure = medicine("cure", { kind: "cure_status", mode: "all" });
  const original: JsonRecord = { id: "trainer_alpha", name: "Trainer Alpha", trainerClass: "Trainer",
    battleDifficulty: 1, moneyReward: 12, tags: ["preserved"],
    rewardItemGrants: [{ itemId: "tonic", quantity: 3 }],
    team: [{ speciesId: "test_species", level: 10, heldItemId: "tonic" }],
  };
  const bystander: JsonRecord = { id: "trainer_beta", name: "Trainer Beta", trainerClass: "Trainer",
    team: [{ speciesId: "other_test_species", level: 12 }],
  };
  let client: Client | undefined;
  let workspace!: JsonRecord;
  let sequence = 0;
  async function call(name: string, input: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    assert.ok(client);
    const response = await client.callTool({ name, arguments: input });
    const envelope = record(response.structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify({ name, envelope }));
    const data = record(envelope[failure ? "error" : "data"]);
    if (failure) assert.notEqual(data.domainCode, "worker.internal");
    return data;
  }
  async function connect(): Promise<void> {
    const args = [resolve(process.env.POKEMAP_TEST_MCP_ENTRY ?? "dist/src/index.js"),
      "--root", root, "--authoring-timeout-ms", "60000"];
    if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
    if (process.env.POKEMAP_TEST_AUTHORING_PACKAGE) args.push("--authoring-package", process.env.POKEMAP_TEST_AUTHORING_PACKAGE);
    client = new Client({ name: "l21a-stock-test", version: "1.0.0" });
    await client.connect(new StdioClientTransport({ command: process.execPath, args,
      cwd: process.cwd(), stderr: "pipe" }));
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
  }
  async function trainers(): Promise<JsonRecord[]> {
    const page = await call("pokemap_query", { projectHandle: workspace.projectHandle,
      resourceKind: "project", operation: "get", ids: ["project"], view: "detail", fieldMask: ["trainers"] });
    return record((page.items as JsonRecord[])[0]).trainers as JsonRecord[];
  }
  async function plan(actionId: string, parameters: JsonRecord, failure = false): Promise<JsonRecord> {
    const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    const before = sha(await readFile(file));
    const catalogBefore = sha(await readFile(itemsFile));
    const key = `stock-${++sequence}`;
    const result = await call("pokemap_plan", { projectHandle: workspace.projectHandle,
      request: { requestId: key, actionId, actionVersion: 1, workspaceHandle: workspace.workspaceHandle,
        expectedRevision: validation.snapshotRevision, idempotencyKey: key, dryRun: false, parameters } }, failure);
    assert.equal(sha(await readFile(file)), before);
    assert.equal(sha(await readFile(itemsFile)), catalogBefore);
    if (failure) {
      const after = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
      assert.equal(after.snapshotRevision, validation.snapshotRevision);
    }
    return result;
  }
  async function apply(stock: JsonRecord): Promise<void> {
    const planned = await plan("campaign.trainer.upsert", { value: { ...original, battleItems: stock } });
    const result = await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle,
      planId: planned.planId, operationId: `apply-stock-${sequence}` });
    assert.equal(record(result.receipt).status, "applied");
  }
  async function reopen(): Promise<void> {
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    await client?.close();
    await connect();
  }
  try {
    await mkdir(join(root, "data/pokemon/catalogs"), { recursive: true });
    await writeFile(itemsFile, JSON.stringify({ schemaVersion: 1, entries: [tonic, cure,
      medicine("reusable", { kind: "heal_hp", mode: "flat", amount: 20 }, { consumption: "never" }),
      medicine("overworld", { kind: "heal_hp", mode: "flat", amount: 20 }, { contexts: ["overworld"] }),
      medicine("revive", { kind: "revive", rateNumerator: 1, rateDenominator: 2 }),
      medicine("pp", { kind: "restore_pp", mode: "flat", amount: 10 }, { target: "party_move" }),
    ] }));
    await writeFile(file, JSON.stringify({ name: "Trainer stock fixture", version: "v8", maps: [], tilesets: [],
      pokemon: { ...canonicalPokemonConfig(), enabled: true,
        catalogFiles: { items: "data/pokemon/catalogs/items.json" } }, trainers: [original, bystander] }));
    const catalogSha = sha(await readFile(itemsFile));
    await connect();
    const description = await call("pokemap_describe");
    const action = (description.mutationActions as JsonRecord[]).find(entry => entry.id === "campaign.trainer.upsert");
    assert.ok(action);
    const contract = record(record(action.extensions).trainerBattleItems);
    assert.equal(contract.field, "value.battleItems");
    assert.equal(contract.maxDistinctItems, 16);
    assert.deepEqual(contract.quantity, { min: 1, max: 99, integer: true });
    assert.deepEqual(contract.supportedEffects, ["heal_hp", "cure_status"]);
    assert.equal(contract.stockScope, "perBattle");
    await apply({ tonic: 2, cure: 1 });
    const stored = (await trainers()).find(row => row.id === original.id)!;
    assert.deepEqual(stored.battleItems, { tonic: 2, cure: 1 });
    assertTrainerFields(stored, original);
    await reopen();
    assert.deepEqual((await trainers()).find(row => row.id === original.id)?.battleItems, { tonic: 2, cure: 1 });
    for (const invalid of [null, [], { tonic: 0 }, { tonic: -1 }, { tonic: 100 }, { tonic: 1.5 },
      { tonic: true }, { tonic: "2" }, { " tonic ": 1 }, { missing: 1 },
      { reusable: 1 }, { overworld: 1 }, { revive: 1 }, { pp: 1 }]) {
      await plan("campaign.trainer.upsert", { value: { ...original, battleItems: invalid } }, true);
    }
    await plan("item.delete_apply", { itemId: "tonic" }, true);
    await plan("item.update", { itemId: "tonic", definition: { ...tonic, uses: [] } }, true);
    await plan("item.set_battle_effect", { itemId: "tonic", use: {
      contexts: ["battle"], target: "party_member", consumption: "never",
      effect: { kind: "heal_hp", mode: "flat", amount: 20 },
    } }, true);
    await apply({});
    await reopen();
    const final = await trainers();
    assert.deepEqual(final.find(row => row.id === original.id)?.battleItems, {});
    const other = final.find(row => row.id === bystander.id)!;
    assert.deepEqual(other.battleItems, {});
    assertTrainerFields(other, bystander);
    assert.equal(sha(await readFile(itemsFile)), catalogSha);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
  } finally {
    await client?.close();
    await rm(root, { recursive: true, force: true });
  }
});

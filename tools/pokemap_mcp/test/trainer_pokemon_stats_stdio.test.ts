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

const keys = ["hp", "attack", "defense", "specialAttack", "specialDefense", "speed"];
const spread = (value: number): JsonRecord => Object.fromEntries(keys.map(key => [key, value]));
const standard = { natureId: "hardy", ivs: spread(15), evs: spread(0) };
const custom = { natureId: "adamant", ivs: spread(31),
  evs: { ...spread(0), hp: 252, attack: 252, speed: 6 } };
const sha = (bytes: Uint8Array): string => createHash("sha256").update(bytes).digest("hex");
const values = (stats: JsonRecord): unknown[] => keys.map(key => stats[key]);

test("L21b real MCP authors individual stats and queries calculated previews independently of AI",
  { timeout: 240_000 }, async () => {
    const root = await mkdtemp(join(tmpdir(), "l21b-stats-mcp-"));
    const projectFile = join(root, "project.json");
    const itemsFile = join(root, "data/pokemon/catalogs/items.json");
    const speciesFile = join(root, "data/pokemon/species/test_species.json");
    const member: JsonRecord = { speciesId: "test_species", level: 50, formId: "base",
      gender: "male", shiny: true, moves: ["splash"] };
    const original: JsonRecord = { id: "alpha", name: "Alpha", trainerClass: "Trainer",
      battleDifficulty: 1, moneyReward: 12, tags: ["preserved"], team: [member, { ...member, shiny: false }] };
    const bystander: JsonRecord = { id: "beta", name: "Beta", trainerClass: "Trainer",
      team: [{ speciesId: "test_species", level: 50 }] };
    let client: Client | undefined;
    let workspace!: JsonRecord;
    let sequence = 0;
    async function call(name: string, input: JsonRecord = {}, failure = false): Promise<JsonRecord> {
      assert.ok(client);
      const response = await client.callTool({ name, arguments: input });
      const envelope = record(response.structuredContent);
      assert.equal(envelope.ok, !failure, JSON.stringify({ name, envelope }));
      const data = record(envelope[failure ? "error" : "data"]);
      if (failure) {
        assert.notEqual(data.code, "worker.internal");
        assert.ok([
          "worker.request_invalid", "validation.failed", "trainer.pokemon.nature.invalid",
          "trainer.pokemon.ivs.invalid", "trainer.pokemon.evs.invalid", "trainer.pokemon.evs.total_exceeded",
        ].includes(String(data.domainCode ?? data.code)), JSON.stringify(data));
      }
      return data;
    }
    async function connect(): Promise<void> {
      const args = [resolve(process.env.POKEMAP_TEST_MCP_ENTRY ?? "dist/src/index.js"),
        "--root", root, "--authoring-timeout-ms", "60000"];
      if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
      if (process.env.POKEMAP_TEST_AUTHORING_PACKAGE) args.push("--authoring-package", process.env.POKEMAP_TEST_AUTHORING_PACKAGE);
      client = new Client({ name: "l21b-stats-test", version: "1.0.0" });
      await client.connect(new StdioClientTransport({ command: process.execPath, args,
        cwd: process.cwd(), stderr: "pipe" }));
      workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    }
    async function query(input: JsonRecord = {}): Promise<JsonRecord> {
      return call("pokemap_query", { projectHandle: workspace.projectHandle,
        resourceKind: "trainerPokemonStats", operation: "list", view: "detail", ...input });
    }
    async function immutableFiles(): Promise<string[]> {
      return Promise.all([projectFile, itemsFile, speciesFile].map(async path => sha(await readFile(path))));
    }
    async function plan(value: JsonRecord, failure = false): Promise<JsonRecord> {
      const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
      const before = await immutableFiles();
      const id = `stats-${++sequence}`;
      const result = await call("pokemap_plan", { projectHandle: workspace.projectHandle,
        request: { requestId: id, actionId: "campaign.trainer.upsert", actionVersion: 1,
          workspaceHandle: workspace.workspaceHandle, expectedRevision: validation.snapshotRevision,
          idempotencyKey: id, dryRun: false, parameters: { value } } }, failure);
      assert.deepEqual(await immutableFiles(), before);
      if (failure) {
        const after = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
        assert.equal(after.snapshotRevision, validation.snapshotRevision);
      }
      return result;
    }
    async function apply(value: JsonRecord): Promise<void> {
      const planned = await plan(value);
      const applied = await call("pokemap_apply", { operation: "apply",
        projectHandle: workspace.projectHandle, planId: planned.planId, operationId: `apply-${sequence}` });
      assert.equal(record(applied.receipt).status, "applied");
    }
    async function reopen(): Promise<void> {
      await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
      await client?.close();
      await connect();
    }
    try {
      await mkdir(join(root, "data/pokemon/catalogs"), { recursive: true });
      await mkdir(join(root, "data/pokemon/species"), { recursive: true });
      await writeFile(itemsFile, JSON.stringify({ schemaVersion: 1, entries: [] }));
      await writeFile(speciesFile, JSON.stringify({ schemaVersion: 1, id: "test_species",
        slug: "test_species", nationalDex: 1, names: { en: "Test species" },
        typing: { types: ["normal"] }, baseStats: { hp: 100, atk: 100, def: 100, spa: 100, spd: 100, spe: 100, bst: 600 },
        abilities: { primary: "test_ability" },
        progression: { growthRateId: "medium_fast", baseExp: 10, catchRate: 45 },
        dexContent: { heightM: 1, weightKg: 1 } }));
      await writeFile(projectFile, JSON.stringify({ name: "Individual trainer stats", version: "v8",
        maps: [], tilesets: [], pokemon: { ...canonicalPokemonConfig(), enabled: true,
          catalogFiles: { items: "data/pokemon/catalogs/items.json" } }, trainers: [original, bystander] }));
      await connect();
      const description = await call("pokemap_describe");
      const action = (description.mutationActions as JsonRecord[]).find(row => row.id === "campaign.trainer.upsert");
      const contract = record(record(action?.extensions).trainerPokemonStats);
      assert.deepEqual(contract.fields, ["value.team[].natureId", "value.team[].ivs", "value.team[].evs"]);
      assert.deepEqual(contract.standard, standard);
      assert.deepEqual(contract.iv, { min: 0, max: 31, integer: true });
      assert.deepEqual(contract.ev, { min: 0, max: 252, integer: true, totalMax: 510 });
      assert.equal(contract.aiIndependent, true);
      assert.equal(contract.previewResourceKind, "trainerPokemonStats");
      const descriptor = (description.resourceKinds as JsonRecord[]).find(row => row.id === "trainerPokemonStats");
      const extensions = record(descriptor?.extensions);
      assert.equal(extensions.queryIdFormat, "<trainerId>:<pokemonIndex>");
      assert.equal(extensions.readOnly, true);
      assert.equal(extensions.derived, true);
      assert.deepEqual(extensions.statKeys, keys);
      const beforeQuery = await immutableFiles();
      const standardPage = await query();
      assert.equal(standardPage.totalAvailable, 3);
      for (const row of standardPage.items as JsonRecord[]) {
        assert.deepEqual(values(record(row.stats)), [167, 112, 112, 112, 112, 112]);
        for (const [key, expected] of Object.entries(standard)) assert.deepEqual(row[key], expected);
      }
      assert.deepEqual(await immutableFiles(), beforeQuery);
      const customized = { ...original, team: [{ ...member, ...custom }, { ...member, shiny: false }] };
      await apply(customized);
      async function checkCustom(): Promise<void> {
        const page = await query({ operation: "get", ids: ["alpha:0"] });
        const row = record((page.items as JsonRecord[])[0]);
        assert.deepEqual(values(record(row.stats)), [207, 167, 120, 108, 120, 121]);
        for (const [key, expected] of Object.entries(custom)) assert.deepEqual(row[key], expected);
        const masked = await query({ filters: { trainerId: "alpha", pokemonIndex: 1 }, fieldMask: ["id", "stats"] });
        assert.equal((masked.items as JsonRecord[]).length, 1);
        assert.deepEqual(Object.keys((masked.items as JsonRecord[])[0]!).sort(), ["id", "stats"]);
        assert.deepEqual(values(record(record((masked.items as JsonRecord[])[0]).stats)), [167, 112, 112, 112, 112, 112]);
      }
      await checkCustom();
      await reopen();
      await checkCustom();
      await apply({ ...customized, battleDifficulty: 10 });
      await checkCustom();
      const rows: JsonRecord[] = [];
      let cursor: unknown;
      do {
        const page = await query({ pageSize: 1, ...(cursor ? { cursor } : {}) });
        rows.push(...page.items as JsonRecord[]);
        cursor = page.nextCursor;
      } while (cursor);
      assert.deepEqual(rows.map(row => row.id).sort(), ["alpha:0", "alpha:1", "beta:0"]);
      for (const invalid of [
        { natureId: "unknown" }, { natureId: " Adamant " },
        { ivs: { hp: 31 } }, { ivs: { ...spread(31), extra: 0 } },
        { ivs: { ...spread(31), hp: 31.5 } }, { ivs: { ...spread(31), hp: true } },
        { ivs: { ...spread(31), hp: "31" } }, { ivs: { ...spread(31), hp: 32 } },
        { evs: { ...spread(0), hp: -1 } }, { evs: { ...spread(0), hp: 253 } },
        { evs: { ...spread(0), hp: 252, attack: 252, speed: 7 } },
      ]) await plan({ ...original, team: [{ ...member, ...invalid }] }, true);
      await apply({ ...original, team: [{ ...member, natureId: null, ivs: null, evs: null }, { ...member, shiny: false }] });
      await reopen();
      const final = await query();
      for (const row of final.items as JsonRecord[]) {
        assert.deepEqual(values(record(row.stats)), [167, 112, 112, 112, 112, 112]);
      }
      const stored = JSON.parse(await readFile(projectFile, "utf8")) as JsonRecord;
      const trainers = stored.trainers as JsonRecord[];
      const alpha = record(trainers.find(row => row.id === "alpha"));
      const restored = record((alpha.team as JsonRecord[])[0]);
      for (const [key, expected] of Object.entries(member)) assert.deepEqual(restored[key], expected);
      for (const key of ["natureId", "ivs", "evs"]) assert.equal(Object.hasOwn(restored, key), false);
      const beta = record((record(trainers.find(row => row.id === "beta")).team as JsonRecord[])[0]);
      for (const [key, expected] of Object.entries(record((bystander.team as JsonRecord[])[0]))) {
        assert.deepEqual(beta[key], expected);
      }
      await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    } finally {
      await client?.close();
      await rm(root, { recursive: true, force: true });
    }
  });

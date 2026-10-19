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

test("L22 real MCP persists independent pocket limits and refuses invalid plans atomically",
  { timeout: 240_000 }, async () => {
    const root = await mkdtemp(join(tmpdir(), "l22-capacity-mcp-"));
    const projectFile = join(root, "project.json");
    const itemsFile = join(root, "data/pokemon/catalogs/items.json");
    const sha = (bytes: Uint8Array): string => createHash("sha256").update(bytes).digest("hex");
    const limits = {
      medicine: { maxDistinctItems: 2, maxQuantityPerItem: 99 },
      supplies: { maxDistinctItems: 1 },
      archive: { maxQuantityPerItem: 1 },
    };
    let client: Client | undefined;
    let workspace!: JsonRecord;
    let sequence = 0;
    async function call(name: string, input: JsonRecord = {}, failure = false): Promise<JsonRecord> {
      assert.ok(client);
      const response = await client.callTool({ name, arguments: input });
      const envelope = record(response.structuredContent);
      assert.equal(envelope.ok, !failure, JSON.stringify({ name, envelope }));
      const result = record(envelope[failure ? "error" : "data"]);
      if (failure) assert.notEqual(result.code, "worker.internal");
      return result;
    }
    async function connect(): Promise<void> {
      const args = [resolve(process.env.POKEMAP_TEST_MCP_ENTRY ?? "dist/src/index.js"),
        "--root", root, "--authoring-timeout-ms", "60000"];
      if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
      if (process.env.POKEMAP_TEST_AUTHORING_PACKAGE) args.push("--authoring-package", process.env.POKEMAP_TEST_AUTHORING_PACKAGE);
      client = new Client({ name: "l22-capacity-test", version: "1.0.0" });
      await client.connect(new StdioClientTransport({ command: process.execPath, args,
        cwd: process.cwd(), stderr: "pipe" }));
      workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    }
    async function query(extra: JsonRecord = {}): Promise<JsonRecord> {
      return call("pokemap_query", { projectHandle: workspace.projectHandle,
        resourceKind: "bagCapacity", operation: "get", ids: ["project"], view: "detail", ...extra });
    }
    async function hashes(): Promise<string[]> {
      return Promise.all([projectFile, itemsFile].map(async path => sha(await readFile(path))));
    }
    async function plan(parameters: JsonRecord, failure = false): Promise<JsonRecord> {
      const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
      const before = await hashes();
      const id = `capacity-${++sequence}`;
      const result = await call("pokemap_plan", { projectHandle: workspace.projectHandle,
        request: { requestId: id, actionId: "bag.capacity.set", actionVersion: 1,
          workspaceHandle: workspace.workspaceHandle, expectedRevision: validation.snapshotRevision,
          idempotencyKey: id, dryRun: false, parameters } }, failure);
      assert.deepEqual(await hashes(), before);
      if (failure) {
        const after = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
        assert.equal(after.snapshotRevision, validation.snapshotRevision);
      }
      return result;
    }
    async function apply(pockets: JsonRecord): Promise<void> {
      const planned = await plan({ pockets });
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
      await writeFile(itemsFile, JSON.stringify({ schemaVersion: 1, entries: [
        { id: "tonic", displayName: "Tonic", pocketId: "medicine" },
        { id: "rope", displayName: "Rope", pocketId: "supplies" },
      ] }));
      await writeFile(projectFile, JSON.stringify({ name: "Pocket capacity", version: "v8",
        maps: [], tilesets: [], pokemon: { ...canonicalPokemonConfig(), enabled: true,
          catalogFiles: { items: "data/pokemon/catalogs/items.json" } },
        newGame: { initialBag: [{ itemId: "tonic", quantity: 3 }] } }));
      const catalogHash = sha(await readFile(itemsFile));
      await connect();
      const description = await call("pokemap_describe");
      assert.ok((description.mutationActions as JsonRecord[]).some(row => row.id === "bag.capacity.set"));
      assert.ok((description.resourceKinds as JsonRecord[]).some(row => row.id === "bagCapacity"));
      const beforeRead = await hashes();
      const initial = await query();
      assert.deepEqual(record((initial.items as JsonRecord[])[0]).pockets, {});
      assert.deepEqual(await hashes(), beforeRead);
      await apply(limits);
      async function checkLimits(): Promise<void> {
        const result = await query();
        assert.deepEqual(record((result.items as JsonRecord[])[0]).pockets, limits);
        const masked = await query({ fieldMask: ["id", "pockets"] });
        assert.deepEqual(Object.keys(record((masked.items as JsonRecord[])[0])).sort(), ["id", "pockets", "resourceKind"]);
        const listing = await query({ operation: "list", ids: [], pageSize: 1 });
        assert.equal(listing.totalAvailable, 1);
        assert.equal(record((listing.items as JsonRecord[])[0]).id, "project");
      }
      await checkLimits();
      await reopen();
      await checkLimits();
      const initialBagFailure = await plan({ pockets: { medicine: { maxQuantityPerItem: 2 } } }, true);
      assert.equal(initialBagFailure.domainCode ?? initialBagFailure.code, "bag.capacity.stackFull");
      for (const pockets of [
        { medicine: { maxDistinctItems: 0 } },
        { medicine: { maxDistinctItems: -1 } },
        { medicine: { maxDistinctItems: 2.5 } },
        { medicine: { maxDistinctItems: "2" } },
        { medicine: { maxQuantityPerItem: false } },
        { medicine: { maxQuantityPerItem: 0 } },
        { medicine: { maxQuantityPerItem: 1e21 } },
        { medicine: { maxQuantityPerItem: 3, unknown: 1 } },
        { " ": { maxDistinctItems: 1 } },
        { medicine: [] },
      ]) await plan({ pockets }, true);
      await checkLimits();
      await apply({ medicine: { maxDistinctItems: null, maxQuantityPerItem: null } });
      await reopen();
      assert.deepEqual(record(((await query()).items as JsonRecord[])[0]).pockets, {});
      const stored = record(JSON.parse(await readFile(projectFile, "utf8")));
      assert.equal(Object.hasOwn(stored, "bagCapacity"), false);
      assert.equal(stored.name, "Pocket capacity");
      assert.deepEqual(record(stored.newGame).initialBag, [{ itemId: "tonic", quantity: 3 }]);
      assert.equal(sha(await readFile(itemsFile)), catalogHash);
      await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    } finally {
      await client?.close();
      await rm(root, { recursive: true, force: true });
    }
  });

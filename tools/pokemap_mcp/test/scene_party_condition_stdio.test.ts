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

for (const dimension of ["twoD", "threeD"]) {
  test(`MCP authors typed party conditions in ${dimension}`, { timeout: 120_000 }, async () => {
    const root = await mkdtemp(join(tmpdir(), "party-condition-mcp-"));
    const file = join(root, "project.json");
    await writeFile(file, JSON.stringify({
      name: "Party condition fixture", version: dimension === "twoD" ? "v8" : "v9",
      settings: { dimension }, pokemon: { ...canonicalPokemonConfig(), enabled: true, catalogFiles: { moves: "data/moves.json" } }, maps: [], tilesets: [],
      badges: [{ id: "ready", label: "Prêt" }],
      scenes: [{ id: "scene", name: "Trainer branch", metadata: { retained: "true" }, graph: {
        startNodeId: "start", nodes: [
          { id: "start", kind: "start" },
          { id: "check", kind: "condition", payload: { conditionSource: { sourceKind: "badge", sourceId: "ready", operator: "isTrue" } } },
          { id: "end", kind: "end" },
        ], edges: [
          { id: "enter", fromNodeId: "start", fromPortId: "completed", toNodeId: "check", kind: "default" },
          { id: "yes", fromNodeId: "check", fromPortId: "true", toNodeId: "end", kind: "conditionTrue" },
          { id: "no", fromNodeId: "check", fromPortId: "false", toNodeId: "end", kind: "conditionFalse" },
        ],
      } }],
    }));
    await mkdir(join(root, "data"));
    const moves = join(root, "data/moves.json");
    const catalogue = (entries: unknown[]) => writeFile(moves, JSON.stringify({ schemaVersion: 1, kind: "catalog", catalog: "moves", entries }));
    await catalogue([{ id: "tackle", name: "Charge" }]);
    const args = [process.env.POKEMAP_TEST_MCP_ENTRY ?? resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
    if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
    const client = new Client({ name: "party-condition-test", version: "1.0.0" });
    const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
    async function call(name: string, input: JsonRecord, failure = false): Promise<JsonRecord> {
      const envelope = record((await client.callTool({ name, arguments: input })).structuredContent);
      assert.equal(envelope.ok, !failure, JSON.stringify(envelope));
      return record(envelope[failure ? "error" : "data"]);
    }
    try {
      await client.connect(transport);
      const description = await call("pokemap_describe", {});
      const action = (description.mutationActions as JsonRecord[]).find(value => value.id === "scene.condition.set")!;
      const contract = record(record(action.extensions).partyState);
      assert.deepEqual(contract.predicates, ["canReceivePokemon", "knowsMove", "hasUsableMove", "canUseFieldAbility"]);
      assert.deepEqual(contract.projectDimensions, ["twoD", "threeD"]);
      assert.equal(contract.sourceId, "predicateName");
      assert.ok((record(contract.fieldAbility).allowedValues as string[]).includes("rock_smash"));
      for (const id of ["scene.graph.patch", "scene.upsert"]) {
        assert.deepEqual(record((description.mutationActions as JsonRecord[]).find(value => value.id === id)!.extensions).partyState, contract);
      }
      const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
      let sequence = 0;
      async function plan(source: JsonRecord, failure = false): Promise<JsonRecord> {
        const validation = await call("pokemap_validate", { projectHandle: opened.projectHandle });
        const id = `party-condition-${++sequence}`;
        return call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
          requestId: id, actionId: "scene.condition.set", actionVersion: 1,
          workspaceHandle: opened.workspaceHandle, expectedRevision: validation.snapshotRevision,
          idempotencyKey: id, parameters: { sceneId: "scene", nodeId: "check", conditionSource: source },
        } }, failure);
      }
      const predicates: string[] = contract.predicates as string[];
      for (const operator of ["isTrue", "isFalse"]) {
        for (const predicate of predicates) {
        const source: JsonRecord = { sourceKind: "partyState", sourceId: predicate, operator,
          ...(predicate === "knowsMove" || predicate === "hasUsableMove" ? { field: "moveId", value: "tackle" } : {}),
          ...(predicate === "canUseFieldAbility" ? { field: "ability", value: "rock_smash" } : {}),
        };
        const before = await readFile(file);
        const planned = await plan(source);
        assert.deepEqual(await readFile(file), before);
        await call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle,
          planId: planned.planId, operationId: `apply-trainer-${sequence}` });
        const query = await call("pokemap_query", { projectHandle: opened.projectHandle, resourceKind: "scene", operation: "get", ids: ["scene"], view: "detail" });
        const scene = record((query.items as JsonRecord[])[0]);
        const node = (record(scene.graph).nodes as JsonRecord[]).find(value => value.id === "check")!;
        assert.deepEqual(record(record(node.payload).conditionSource), source);
        assert.deepEqual(scene.metadata, { retained: "true" });
        assert.equal((scene.diagnostics as JsonRecord[]).some(value => /conditionPartyMove(CatalogUnavailable|RefUnknown)/.test(String(value.code))), false);
        }
      }
      for (const source of [
        { sourceKind: "partyState", sourceId: 7, operator: "isTrue" },
        { sourceKind: "partyState", sourceId: "knowsMove", operator: "isTrue", field: "moveId", value: "missing" },
        { sourceKind: "partyState", sourceId: "canReceivePokemon", operator: "equals", value: "true" },
        { sourceKind: "partyState", sourceId: "canUseFieldAbility", operator: "isTrue", field: "ability", value: "rockSmash" },
        { sourceKind: "partyState", sourceId: "knowsMove", operator: "isTrue", field: "moveId", value: " tackle" },
      ]) {
        const before = await readFile(file);
        const rejected = await plan(source, true);
        assert.ok(rejected.domainCode);
        assert.notEqual(rejected.domainCode, "worker.internal");
        assert.deepEqual(await readFile(file), before);
      }
      for (const entries of [[{ id: "tackle" }, { id: "tackle" }], [null]]) {
        await catalogue(entries);
        const before = await readFile(file);
        const rejected = await plan({ sourceKind: "partyState", sourceId: "knowsMove", operator: "isTrue", field: "moveId", value: "tackle" }, true);
        assert.equal(rejected.domainCode, "scene.party_move_catalog_unavailable");
        assert.deepEqual(await readFile(file), before);
      }
      await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
    } finally {
      await client.close();
      await rm(root, { recursive: true, force: true });
    }
  });
}

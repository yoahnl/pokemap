import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
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
  test(`MCP authors canonical trainer victory in ${dimension}`, { timeout: 120_000 }, async () => {
    const root = await mkdtemp(join(tmpdir(), "trainer-condition-mcp-"));
    const file = join(root, "project.json");
    await writeFile(file, JSON.stringify({
      name: "Trainer condition fixture", version: dimension === "twoD" ? "v8" : "v9",
      settings: { dimension }, pokemon: canonicalPokemonConfig(), maps: [], tilesets: [],
      trainers: [
        { id: "clair", name: "Sandra", trainerClass: "Championne", team: [] },
        { id: "lugia", name: "Lugia", trainerClass: "Rencontre", team: [], tags: ["static-encounter"] },
      ],
      badges: [{ id: "fog", label: "Badge Brume" }],
      scenes: [{ id: "scene", name: "Trainer branch", metadata: { retained: "true" }, graph: {
        startNodeId: "start", nodes: [
          { id: "start", kind: "start" },
          { id: "check", kind: "condition", payload: { conditionSource: { sourceKind: "badge", sourceId: "fog", operator: "isTrue" } } },
          { id: "end", kind: "end" },
        ], edges: [
          { id: "enter", fromNodeId: "start", fromPortId: "completed", toNodeId: "check", kind: "default" },
          { id: "yes", fromNodeId: "check", fromPortId: "true", toNodeId: "end", kind: "conditionTrue" },
          { id: "no", fromNodeId: "check", fromPortId: "false", toNodeId: "end", kind: "conditionFalse" },
        ],
      } }],
    }));
    const args = [process.env.POKEMAP_TEST_MCP_ENTRY ?? resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
    if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
    const client = new Client({ name: "trainer-condition-test", version: "1.0.0" });
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
      const contract = record(record(action.extensions).trainerDefeated);
      assert.equal(contract.sourceId, "projectTrainerId");
      assert.deepEqual(contract.projectDimensions, ["twoD", "threeD"]);
      const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
      let sequence = 0;
      async function plan(source: JsonRecord, failure = false): Promise<JsonRecord> {
        const validation = await call("pokemap_validate", { projectHandle: opened.projectHandle });
        const id = `trainer-condition-${++sequence}`;
        return call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
          requestId: id, actionId: "scene.condition.set", actionVersion: 1,
          workspaceHandle: opened.workspaceHandle, expectedRevision: validation.snapshotRevision,
          idempotencyKey: id, parameters: { sceneId: "scene", nodeId: "check", conditionSource: source },
        } }, failure);
      }
      for (const operator of ["isTrue", "isFalse"]) {
        const source = { sourceKind: "trainerDefeated", sourceId: "clair", operator };
        const before = await readFile(file);
        const planned = await plan(source);
        assert.deepEqual(await readFile(file), before);
        await call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle,
          planId: planned.planId, operationId: `apply-trainer-${sequence}` });
        const saved = record(JSON.parse(await readFile(file, "utf8")));
        const scene = record((saved.scenes as JsonRecord[])[0]);
        const node = (record(scene.graph).nodes as JsonRecord[]).find(value => value.id === "check")!;
        assert.deepEqual(record(record(node.payload).conditionSource), source);
        assert.deepEqual(saved.facts ?? [], []);
        assert.deepEqual(scene.metadata, { retained: "true" });
      }
      for (const source of [
        { sourceKind: "trainerDefeated", sourceId: "missing", operator: "isTrue" },
        { sourceKind: "trainerDefeated", sourceId: "lugia", operator: "isTrue" },
        { sourceKind: "trainerDefeated", sourceId: "trainer:clair", operator: "isTrue" },
        { sourceKind: "trainerDefeated", sourceId: "clair", operator: "equals", value: "true" },
      ]) {
        const before = await readFile(file);
        const rejected = await plan(source, true);
        assert.ok(rejected.domainCode);
        assert.notEqual(rejected.domainCode, "worker.internal");
        assert.deepEqual(await readFile(file), before);
      }
      await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
    } finally {
      await client.close();
      await rm(root, { recursive: true, force: true });
    }
  });
}

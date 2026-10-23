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

test("live MCP authors native integer input in both dimensions", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "scene-text-fact-mcp-"));
  const command = {kind: "inputIntegerToFact", factId: "rival", prompt: {localizationKey: "number", fallbackText: "Combien ?"},
    digits: 3, minimum: 0, maximum: 999, allowCancel: true, cancellationPolicy: "restoreInitialAndComplete"};
  const scene = { id: "text-fact", name: "Text Fact", graph: {
    startNodeId: "start", nodes: [
      { id: "start", kind: "start" },
      { id: "calculate", kind: "action", payload: {consequence: {kind: "calculateIntegerFacts", factIds: ["rival"], operation: "floorDivide", operand: {kind: "integerFact", factId: "rival"}, minimum: -999, maximum: 999, zeroDivisorPolicy: "keepValueForZeroOrOne", boundaryPolicy: "preserveSaturated"}}},
      { id: "balance", kind: "action", payload: {consequence: {kind: "adjustMoney", operation: "subtract", amount: {kind: "literal", value: -2}, minimum: 0, maximum: 999999}}},
      { id: "payment", kind: "action", payload: {interactiveCommand: {kind: "tryPayMoney", amount: {kind: "literal", value: 2}}}},
      { id: "compare", kind: "condition", payload: {conditionSource: {sourceKind: "integerComparison", sourceId: "integerComparison", operator: "equals", left: {kind: "integerFact", factId: "rival"}, comparison: "greaterThanOrEqual", right: {kind: "gameRead", read: "money"}}}},
      { id: "map", kind: "action", payload: { interactiveCommand: command } },
      { id: "end", kind: "end" },
    ], edges: [
      { id: "start", fromNodeId: "start", fromPortId: "completed", toNodeId: "calculate", kind: "default" },
      { id: "calculate", fromNodeId: "calculate", fromPortId: "completed", toNodeId: "balance", kind: "actionCompleted" },
      { id: "balance", fromNodeId: "balance", fromPortId: "completed", toNodeId: "payment", kind: "actionCompleted" },
      ...["completed", "insufficientFunds", "cancelled"].map(port => ({id: `payment-${port}`, fromNodeId: "payment", fromPortId: port, toNodeId: "compare", kind: "actionCompleted"})),
      ...["true", "false"].map(port => ({id: `compare-${port}`, fromNodeId: "compare", fromPortId: port, toNodeId: "map", kind: port === "true" ? "conditionTrue" : "conditionFalse"})),
      ...["completed", "cancelled"].map(port => ({ id: port, fromNodeId: "map", fromPortId: port, toNodeId: "end", kind: "actionCompleted" })),
    ],
  } };
  for (const spatial of [false, true]) {
    const path = join(root, spatial ? "spatial" : "two-d");
    await mkdir(path);
    await writeFile(join(path, "project.json"), JSON.stringify({
      name: "Text Fact transport", version: spatial ? "v9" : "v8",
      settings: { dimension: spatial ? "threeD" : "twoD" },
      facts: [{id: "rival", label: "Nom", valueType: "int", defaultValue: 4}], pokemon: canonicalPokemonConfig(), maps: [], tilesets: [], scenes: [],
      regionalMap: { schemaVersion: 1, regions: [{ id: "kanto", label: "Kanto" }], pointsOfInterest: [] },
    }));
  }
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const client = new Client({ name: "text-fact-scene-test", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  async function call(name: string, input: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: input });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify(envelope));
    return record(envelope[failure ? "error" : "data"]);
  }
  try {
    await client.connect(transport);
    const description = await call("pokemap_describe");
    for (const id of ["scene.upsert", "scene.graph.patch", "scene.interactive_command.set"]) {
      const action = (description.mutationActions as JsonRecord[]).find(entry => entry.id === id);
      assert.ok(action);
      const contract = record(record(action.extensions).inputIntegerToFact);
      assert.equal(contract.factReference, "knownUniqueIntegerFact");
      assert.equal(contract.atomicity, "orderedSceneConsequenceBuffer");
      assert.deepEqual(contract.outputPorts, ["completed", "cancelled"]);
      if (id !== "scene.interactive_command.set") {
        assert.equal(record(record(action.extensions).calculateIntegerFacts).operandSnapshot, "onceBeforeTargetRange");
        assert.equal(record(record(action.extensions).adjustMoney).amountValidation, "signedIntegerVariation");
        assert.equal(record(record(action.extensions).integerComparison).sourceKind, "integerComparison");
      }
      assert.deepEqual(record(record(action.extensions).tryPayMoney).outputPorts, ["completed", "insufficientFunds", "cancelled"]);
    }
    for (const spatial of [false, true]) {
      const projectRoot = join(root, spatial ? "spatial" : "two-d");
      const file = join(projectRoot, "project.json");
      const workspace = await call("pokemap_workspace", { operation: "open", projectRoot });
      const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
      const before = await readFile(file);
      const planned = await call("pokemap_plan", {
        projectHandle: workspace.projectHandle, request: {
          requestId: `map-${spatial}`, actionId: "scene.upsert", actionVersion: 1,
          workspaceHandle: workspace.workspaceHandle, expectedRevision: validation.snapshotRevision,
          idempotencyKey: `map-${spatial}`, parameters: { scene },
        },
      });
      assert.deepEqual(await readFile(file), before);
      {
        await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle,
          planId: planned.planId, operationId: "apply-map" });
        const queried = await call("pokemap_query", { projectHandle: workspace.projectHandle,
          resourceKind: "scene", operation: "get", ids: ["text-fact"], view: "detail" });
        for (const kind of ["inputIntegerToFact", "calculateIntegerFacts", "adjustMoney", "tryPayMoney", "integerComparison"]) assert.ok(JSON.stringify(queried).includes(`"${kind}"`));
      }
      await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
      {
        const reopened = await call("pokemap_workspace", { operation: "open", projectRoot });
        const cold = await call("pokemap_query", { projectHandle: reopened.projectHandle,
          resourceKind: "scene", operation: "get", ids: ["text-fact"], view: "detail" });
        assert.ok(JSON.stringify(cold).includes('"inputIntegerToFact"'));
        const manifest = record(JSON.parse(await readFile(file, "utf8")));
        const stored = record((manifest.scenes as JsonRecord[])[0]);
        const graph = record(stored.graph);
        const action = (graph.nodes as JsonRecord[]).find(node => node.id === "map");
        assert.deepEqual(record(action!.payload).interactiveCommand, command);
        await call("pokemap_workspace", { operation: "close", workspaceHandle: reopened.workspaceHandle });
      }
    }
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

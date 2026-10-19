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

function preservesFields(actual: unknown, expected: unknown): void {
  if (Array.isArray(expected)) {
    assert.ok(Array.isArray(actual));
    assert.equal(actual.length, expected.length);
    expected.forEach((value, index) => preservesFields(actual[index], value));
  } else if (expected && typeof expected === "object") {
    const object = record(actual);
    for (const [key, value] of Object.entries(expected)) preservesFields(object[key], value);
  } else {
    assert.deepEqual(actual, expected);
  }
}

function scene(command: JsonRecord, title = "Recovery"): JsonRecord {
  return {
    id: "recovery", name: "Recovery", metadata: { keep: "scene metadata" },
    graph: {
      startNodeId: "start",
      nodes: [
        { id: "start", kind: "start" },
        { id: "action", kind: "action", title, payload: {
          kind: "action", interactiveCommand: command,
        } },
        { id: "end", kind: "end" },
      ],
      edges: [
        { id: "entry", fromNodeId: "start", fromPortId: "completed", toNodeId: "action", kind: "default" },
        { id: "finish", fromNodeId: "action", fromPortId: "completed", toNodeId: "end", kind: "actionCompleted" },
      ],
    },
    layout: { nodeLayouts: [{ nodeId: "action", x: 40, y: 80 }], edgeLayouts: [] },
  };
}

test("L24 real MCP authors strict WhiteOut, reopens it and reports proposed recovery honestly",
  { timeout: 240_000 }, async () => {
    const root = await mkdtemp(join(tmpdir(), "l24-whiteout-mcp-"));
    const roots = [join(root, "twoD"), join(root, "threeD")];
    const initialScene = scene({ kind: "wait", durationMs: 0 });
    const untouchedScene = { id: "untouched", name: "Untouched", graph: {
      startNodeId: "start", nodes: [{ id: "start", kind: "start" }, { id: "end", kind: "end" }],
      edges: [{ id: "entry", fromNodeId: "start", fromPortId: "completed", toNodeId: "end", kind: "default" }],
    } };
    let client: Client | undefined;
    let workspace!: JsonRecord;
    let projectRoot = roots[0]!;
    let sequence = 0;
    async function call(name: string, input: JsonRecord = {}, failure = false): Promise<JsonRecord> {
      assert.ok(client);
      const envelope = record((await client.callTool({ name, arguments: input })).structuredContent);
      assert.equal(envelope.ok, !failure, JSON.stringify({ name, envelope }));
      const data = record(envelope[failure ? "error" : "data"]);
      if (failure) {
        assert.notEqual(data.domainCode, "worker.internal");
        assert.notEqual(data.code, "internal");
      }
      return data;
    }
    async function connect(): Promise<void> {
      const args = [resolve(process.env.POKEMAP_TEST_MCP_ENTRY ?? "dist/src/index.js"),
        "--root", root, "--authoring-timeout-ms", "60000"];
      if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
      if (process.env.POKEMAP_TEST_AUTHORING_PACKAGE) args.push("--authoring-package", process.env.POKEMAP_TEST_AUTHORING_PACKAGE);
      client = new Client({ name: "l24-whiteout-test", version: "1.0.0" });
      await client.connect(new StdioClientTransport({ command: process.execPath, args,
        cwd: process.cwd(), stderr: "pipe" }));
      workspace = await call("pokemap_workspace", { operation: "open", projectRoot });
    }
    async function reopen(): Promise<void> {
      await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
      await client?.close();
      await connect();
    }
    async function plan(action: string, command: JsonRecord, failure = false): Promise<JsonRecord> {
      const before = await readFile(join(projectRoot, "project.json"));
      const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
      const candidate = scene(command, `WhiteOut ${++sequence}`);
      const node = record((record(candidate.graph).nodes as JsonRecord[])[1]);
      const id = `whiteout-${sequence}`;
      const result = await call("pokemap_plan", { projectHandle: workspace.projectHandle,
        request: { requestId: id, actionId: action, actionVersion: 1,
          workspaceHandle: workspace.workspaceHandle, expectedRevision: validation.snapshotRevision,
          idempotencyKey: id, dryRun: false,
          parameters: action === "scene.upsert" ? { scene: candidate } : {
            sceneId: "recovery", upsertNodes: [node],
          } } }, failure);
      assert.deepEqual(await readFile(join(projectRoot, "project.json")), before);
      if (failure) {
        const after = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
        assert.equal(after.snapshotRevision, validation.snapshotRevision);
      }
      return result;
    }
    async function query(): Promise<JsonRecord> {
      return call("pokemap_query", { projectHandle: workspace.projectHandle,
        resourceKind: "scene", operation: "get", ids: ["recovery"], view: "detail" });
    }
    async function simulate(maxSteps = 100): Promise<JsonRecord> {
      const result = await call("pokemap_query", { projectHandle: workspace.projectHandle,
        resourceKind: "scene", operation: "get", ids: ["recovery"], view: "detail",
        extensions: { actionId: "scene.simulate", parameters: {
          portsByNodeId: { action: "completed" }, maxSteps,
        } } });
      return record((result.items as JsonRecord[])[0]);
    }
    try {
      for (const [index, path] of roots.entries()) {
        await mkdir(path);
        await writeFile(join(path, "project.json"), JSON.stringify({ name: "L24 engine recovery",
          version: index === 0 ? "v8" : "v9", maps: [], tilesets: [], pokemon: canonicalPokemonConfig(),
          settings: { dimension: index === 0 ? "twoD" : "threeD" },
          scenes: [initialScene, untouchedScene] }));
      }
      await connect();
      const description = await call("pokemap_describe");
      for (const id of ["scene.graph.patch", "scene.upsert"]) {
        const action = (description.mutationActions as JsonRecord[]).find(row => row.id === id);
        assert.ok(action);
        const contract = record(record(action.extensions).whiteOut);
        assert.equal(contract.interactiveCommandKind, "whiteOut");
        assert.deepEqual(contract.parameters, []);
        assert.equal(contract.projectDimension, "twoD");
        assert.equal(contract.activation, "afterSuccessfulSceneCompletion");
        assert.deepEqual(contract.effects, ["healParty", "defeatMoneyPenalty", "returnToRecordedRecoveryPoint"]);
        assert.equal(contract.saveResume, "committedRecoveredState");
        assert.deepEqual(contract.outputPorts, ["completed"]);
      }
      for (const action of ["scene.graph.patch", "scene.upsert"]) {
        const planned = await plan(action, { kind: "whiteOut" });
        const applied = await call("pokemap_apply", { operation: "apply",
          projectHandle: workspace.projectHandle, planId: planned.planId, operationId: `apply-${sequence}` });
        assert.equal(record(applied.receipt).status, "applied");
        await reopen();
        assert.ok(JSON.stringify(await query()).includes('"kind":"whiteOut"'));
        const stored = record(JSON.parse(await readFile(join(projectRoot, "project.json"), "utf8")));
        const saved = record((stored.scenes as JsonRecord[]).find(row => row.id === "recovery"));
        assert.deepEqual(record(saved.graph).edges, record(initialScene.graph).edges);
        assert.deepEqual(saved.layout, initialScene.layout);
        assert.deepEqual(saved.metadata, initialScene.metadata);
        preservesFields((stored.scenes as JsonRecord[]).find(row => row.id === "untouched"), untouchedScene);
        for (const command of [
          { kind: "whiteOut", moneyPenaltyBasisPoints: 0 },
          { kind: "whiteOut", destinationMapId: "invented" },
          { kind: "whiteOut", hp: 50 },
          { kind: "whiteout" },
        ]) await plan(action, command, true);
      }
      const beforeSimulation = await readFile(join(projectRoot, "project.json"));
      const simulated = await simulate();
      assert.equal(simulated.status, "completed");
      assert.equal(simulated.proofKind, "simulation");
      assert.equal(simulated.mountedPlayer, false);
      assert.equal(simulated.effects, "proposedOnly");
      assert.deepEqual(simulated.proposedDefeatRecoveries, [{ nodeId: "action", source: "whiteOut",
        activation: "afterSuccessfulSceneCompletion" }]);
      const failed = await simulate(2);
      assert.equal(failed.status, "failed");
      assert.deepEqual(failed.proposedDefeatRecoveries, []);
      assert.deepEqual(await readFile(join(projectRoot, "project.json")), beforeSimulation);
      await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
      projectRoot = roots[1]!;
      workspace = await call("pokemap_workspace", { operation: "open", projectRoot });
      for (const action of ["scene.graph.patch", "scene.upsert"]) {
        await plan(action, { kind: "whiteOut" }, true);
      }
      await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    } finally {
      await client?.close();
      await rm(root, { recursive: true, force: true });
    }
  });

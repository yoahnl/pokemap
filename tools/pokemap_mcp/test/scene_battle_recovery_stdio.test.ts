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

test("MCP discovers, persists and validates scripted battle defeat recovery", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "scene-recovery-mcp-"));
  const file = join(root, "project.json");
  const scene = { id: "scene", name: "Rival", graph: { startNodeId: "start", nodes: [
    { id: "start", kind: "start" },
    { id: "battle", kind: "battle", payload: { battleKind: "trainer", trainerId: "rival" } },
    { id: "end", kind: "end" },
  ], edges: [
    { id: "entry", fromNodeId: "start", fromPortId: "completed", toNodeId: "battle", kind: "default" },
    { id: "win", fromNodeId: "battle", fromPortId: "victory", toNodeId: "end", kind: "battleVictory" },
    { id: "lose", fromNodeId: "battle", fromPortId: "defeat", toNodeId: "end", kind: "battleDefeat" },
  ] }, layout: { nodeLayouts: [{ nodeId: "battle", x: 40, y: 80 }], edgeLayouts: [] } };
  await writeFile(file, JSON.stringify({ name: "Recovery MCP", version: "v8", pokemon: canonicalPokemonConfig(),
    maps: [], tilesets: [], scenes: [scene], trainers: [
      { id: "rival", name: "Rival", trainerClass: "Rival", team: [{ speciesId: "sproutle", level: 5 }] },
    ] }));
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const client = new Client({ name: "scene-recovery-test", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  async function call(name: string, input: JsonRecord, failure = false): Promise<JsonRecord> {
    const envelope = record((await client.callTool({ name, arguments: input })).structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify(envelope));
    return record(envelope[failure ? "error" : "data"]);
  }
  try {
    await client.connect(transport);
    const description = await call("pokemap_describe", {});
    for (const id of ["scene.graph.patch", "scene.upsert"]) {
      const action = (description.mutationActions as JsonRecord[]).find(action => action.id === id)!;
      const contract = record(record(action.extensions).battleDefeatRecovery);
      assert.equal(contract.field, "defeatRecovery");
      assert.deepEqual(contract.values, ["continueScene", "returnToRecoveryPoint"]);
      assert.equal(contract.projectDimension, "twoD");
    }
    let workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    let sequence = 0;
    async function plan(mode: string, action: string, failure = false): Promise<JsonRecord> {
      const revision = (await call("pokemap_validate", { projectHandle: workspace.projectHandle })).snapshotRevision;
      const before = await readFile(file);
      const node = { ...scene.graph.nodes[1], payload: { ...scene.graph.nodes[1]!.payload, defeatRecovery: mode } };
      const id = `recovery-${++sequence}`;
      const result = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
        requestId: id, actionId: action, actionVersion: 1, workspaceHandle: workspace.workspaceHandle,
        expectedRevision: revision, idempotencyKey: id,
        parameters: action === "scene.graph.patch" ? { sceneId: "scene", upsertNodes: [node] }
          : { scene: { ...scene, graph: { ...scene.graph, nodes: [scene.graph.nodes[0], node, scene.graph.nodes[2]] } } },
      } }, failure);
      assert.deepEqual(await readFile(file), before);
      return result;
    }
    for (const action of ["scene.graph.patch", "scene.upsert"]) {
      for (const mode of ["returnToRecoveryPoint", "continueScene"]) {
        const planned = await plan(mode, action);
        await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle,
          planId: planned.planId, operationId: `apply-${sequence}` });
        await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
        workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
        const queried = await call("pokemap_query", { projectHandle: workspace.projectHandle,
          resourceKind: "scene", operation: "get", ids: ["scene"], view: "detail" });
        assert.equal(JSON.stringify(queried).includes('"defeatRecovery":"returnToRecoveryPoint"'), mode === "returnToRecoveryPoint");
        const saved = (JSON.parse(await readFile(file, "utf8")) as { scenes: JsonRecord[] }).scenes[0]!;
        assert.deepEqual(record(saved.graph).edges, scene.graph.edges);
        assert.deepEqual(saved.layout, scene.layout);
      }
      const invalid = await plan("discardProgress", action, true);
      assert.notEqual(invalid.domainCode, "worker.internal");
    }
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

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

test("MCP edits selected graph nodes and conditions without replacing unrelated content", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "scene-graph-mcp-"));
  const file = join(root, "project.json");
  const edge = (id: string, from: string, port: string, to: string, kind = "default") =>
    ({ id, fromNodeId: from, fromPortId: port, toNodeId: to, kind });
  const scene = { id: "scene", name: "Badge branch", metadata: { kept: "true" },
    graph: { startNodeId: "start", nodes: [
      { id: "start", kind: "start" },
      { id: "check", kind: "condition", title: "Badge ?", payload: {
        conditionSource: { sourceKind: "badge", sourceId: "fog", operator: "isTrue", label: "Badge Brume" } } },
      { id: "end", kind: "end" },
    ], edges: [edge("enter", "start", "completed", "check"),
      edge("yes", "check", "true", "end", "conditionTrue"), edge("no", "check", "false", "end", "conditionFalse")] },
    layout: { nodeLayouts: [{ nodeId: "check", x: 12, y: 24 }], edgeLayouts: [] } };
  const other = { id: "other", name: "Other", graph: { startNodeId: "s",
    nodes: [{ id: "s", kind: "start" }, { id: "e", kind: "end" }], edges: [edge("done", "s", "completed", "e")] } };
  await writeFile(file, JSON.stringify({ name: "Graph MCP", version: "v8", pokemon: canonicalPokemonConfig(),
    maps: [], tilesets: [], scenes: [scene, other], badges: [{ id: "fog", label: "Badge Brume" }] }));
  const catalogs = join(root, "data/pokemon/catalogs");
  await mkdir(catalogs, { recursive: true });
  await writeFile(join(catalogs, "items.json"), JSON.stringify({
    schemaVersion: 1, entries: [{ id: "tm23", displayName: "CT23", pocketId: "tms" }],
  }));
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const client = new Client({ name: "graph-patch-test", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  async function call(name: string, input: JsonRecord, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: input });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify(envelope));
    return record(envelope[failure ? "error" : "data"]);
  }
  try {
    await client.connect(transport);
    const description = await call("pokemap_describe", {});
    for (const id of ["scene.graph.patch", "scene.condition.set", "scene.interactive_command.set"]) {
      assert.ok((description.mutationActions as JsonRecord[]).some(action => action.id === id));
    }
    const workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const beforeOther = await call("pokemap_query", { projectHandle: workspace.projectHandle,
      resourceKind: "scene", operation: "get", ids: ["other"], view: "detail" });
    let sequence = 0;
    async function plan(action: string, parameters: JsonRecord, failure = false): Promise<JsonRecord> {
      const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
      const before = await readFile(file);
      const id = `graph-${++sequence}`;
      const result = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
        requestId: id, actionId: action, actionVersion: 1, workspaceHandle: workspace.workspaceHandle,
        parameters, expectedRevision: validation.snapshotRevision, idempotencyKey: id,
      } }, failure);
      assert.deepEqual(await readFile(file), before);
      return result;
    }
    for (const [action, parameters] of [
      ["scene.graph.patch", { sceneId: "scene", upsertNodes: [
        { id: "end", kind: "end", title: "Fin" },
        { id: "gift", kind: "action", title: "Cadeau", payload: { interactiveCommand: { kind: "giveItem", itemId: "tm23", quantity: 1 } } },
      ], upsertEdges: [edge("yes", "check", "true", "gift", "conditionTrue"),
        edge("received", "gift", "received", "end"), edge("full", "gift", "bagFull", "end")] }],
      ["scene.condition.set", { sceneId: "scene", nodeId: "check", conditionSource: {
        sourceKind: "badge", sourceId: "fog", operator: "isFalse", label: "Sans badge Brume" } }],
      ["scene.interactive_command.set", { sceneId: "scene", nodeId: "gift", command: { kind: "giveItem", itemId: "tm23", quantity: 2 } }],
    ] as [string, JsonRecord][]) {
      const planned = await plan(action, parameters);
      await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle,
        planId: planned.planId, operationId: `apply-${sequence}` });
    }
    const invalid = await plan("scene.graph.patch", { sceneId: "scene", removeNodeIds: ["end"] }, true);
    assert.equal(invalid.domainCode, "scene.graph.invalid_patch");
    const saved = record(JSON.parse(await readFile(file, "utf8")));
    const scenes = saved.scenes as JsonRecord[];
    const afterOther = await call("pokemap_query", { projectHandle: workspace.projectHandle,
      resourceKind: "scene", operation: "get", ids: ["other"], view: "detail" });
    assert.deepEqual(afterOther.items, beforeOther.items);
    assert.deepEqual(scenes[0]?.layout, scene.layout);
    assert.deepEqual(scenes[0]?.metadata, scene.metadata);
    const gift = (record(scenes[0]?.graph).nodes as JsonRecord[]).find(node => node.id === "gift")!;
    assert.equal(record(record(gift.payload).interactiveCommand).quantity, 2);
    assert.equal(gift.title, "Cadeau");
    assert.equal(record(record(scenes[0]?.graph).nodes instanceof Array ? (record(scenes[0]?.graph).nodes as JsonRecord[])[2] : undefined).title, "Fin");
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

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

test("MCP discovers and authors scoped temporary event state with owner validation", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-event-instance-"));
  const file = join(root, "project.json");
  await mkdir(join(root, "maps"));
  await writeFile(join(root, "maps/map.json"), JSON.stringify({
    id: "map", name: "Map", version: "v8", size: { width: 4, height: 4 }, layers: [],
    entities: [{ id: "owner", name: "Owner", kind: "custom", pos: { x: 1, y: 1 } }],
  }));
  await writeFile(file, JSON.stringify({
    name: "EV-02 temporary event state", version: "v8", pokemon: canonicalPokemonConfig(),
    maps: [{ id: "map", name: "Map", relativePath: "maps/map.json" }], tilesets: [],
    eventRegistry: { schemaVersion: 1, mode: "v2Only", records: [], legacyClaims: [] },
  }));
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "ev02-instance-state", version: "1.0.0" });
  let workspace: JsonRecord | undefined;
  let sequence = 0;
  async function call(name: string, parameters: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: parameters });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify(envelope));
    return record(envelope[failure ? "error" : "data"]);
  }
  async function apply(actionId: string, parameters: JsonRecord, failure = false): Promise<void> {
    assert.ok(workspace);
    const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    const before = await readFile(file);
    const id = `ev02-instance-${++sequence}`;
    const planned = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
      requestId: id, actionId, actionVersion: 1, parameters,
      workspaceHandle: workspace.workspaceHandle,
      expectedRevision: validation.snapshotRevision, idempotencyKey: id,
    } }, failure);
    assert.deepEqual(await readFile(file), before);
    if (failure) return;
    const applied = await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle,
      planId: planned.planId, operationId: `${id}-apply` });
    assert.equal(record(applied.receipt).status, "applied");
  }
  const condition = { sourceKind: "mapEventInstanceBoolean", sourceId: "owner",
    mapId: "map", key: "A", operator: "isTrue" };
  const consequence = { kind: "setMapEventInstanceBoolean", mapId: "map", eventId: "owner", key: "A", value: true };
  const scene = { id: "temporary", name: "Temporary state", graph: {
    startNodeId: "start", nodes: [
      { id: "start", kind: "start" },
      { id: "condition", kind: "condition", payload: { conditionSource: condition } },
      { id: "set", kind: "action", payload: { consequence } },
      { id: "end", kind: "end" },
    ], edges: [
      { id: "start-condition", fromNodeId: "start", fromPortId: "completed", toNodeId: "condition", kind: "default" },
      { id: "true", fromNodeId: "condition", fromPortId: "true", toNodeId: "end", kind: "conditionTrue" },
      { id: "false", fromNodeId: "condition", fromPortId: "false", toNodeId: "set", kind: "conditionFalse" },
      { id: "set-end", fromNodeId: "set", fromPortId: "completed", toNodeId: "end", kind: "actionCompleted" },
    ],
  } };
  try {
    await client.connect(transport);
    const description = await call("pokemap_describe");
    const actions = description.mutationActions as JsonRecord[];
    for (const id of ["event_v2.record_upsert", "event_v2.record_upsert_batch", "scene.condition.set", "scene.upsert", "scene.graph.patch"]) {
      const action = actions.find((value) => value.id === id);
      assert.ok(action);
      const extensions = record(action.extensions);
      assert.ok(extensions.mapEventInstanceBoolean, `${id} must describe the temporary owner condition`);
    }
    const sceneDescriptor = record(actions.find((value) => value.id === "scene.upsert")?.extensions);
    assert.ok(sceneDescriptor.setMapEventInstanceBoolean);
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    await apply("scene.upsert", { scene });
    await apply("scene.condition.set", { sceneId: "temporary", nodeId: "condition",
      conditionSource: { ...condition, operator: "isFalse" } });
    const temporaryCondition = { kind: "mapEventInstanceBoolean", mapId: "map", eventId: "owner", key: "A", expectedValue: false };
    const event = { state: "configured", enabled: false, definition: {
      id: "evt_00000000-0000-7000-8000-000000000052", name: "Temporary page",
      source: { kind: "entityInteract", mapId: "map", entityId: "owner" },
      conditions: [temporaryCondition], sceneId: "temporary", reusePolicy: "reusable", priority: 1, order: 0,
    } };
    await apply("event_v2.record_upsert", { record: event });
    const savedBytes = await readFile(file);
    const saved = record(JSON.parse(savedBytes.toString("utf8")));
    const savedScene = (saved.scenes as JsonRecord[]).find((value) => value.id === "temporary");
    assert.ok(savedScene);
    const nodes = record(savedScene.graph).nodes as JsonRecord[];
    assert.equal(record(record(nodes.find((node) => node.id === "condition")?.payload).conditionSource).operator, "isFalse");
    assert.deepEqual(record(record(nodes.find((node) => node.id === "set")?.payload).consequence), consequence);
    assert.deepEqual(record(saved.eventRegistry).records, [event]);
    await apply("scene.condition.set", { sceneId: "temporary", nodeId: "condition",
      conditionSource: { ...condition, sourceId: "missing-owner" } }, true);
    await apply("scene.upsert", { scene: { ...scene, id: "invalid", graph: { ...scene.graph,
      nodes: scene.graph.nodes.map((node) => node.id === "set"
        ? { ...node, payload: { consequence: { ...consequence, eventId: "missing-owner" } } } : node),
    } } }, true);
    assert.deepEqual(await readFile(file), savedBytes);
  } finally {
    if (workspace) await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

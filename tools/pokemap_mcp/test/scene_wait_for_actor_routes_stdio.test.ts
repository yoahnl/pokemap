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
  assert.ok(value && typeof value === "object" && !Array.isArray(value)); return value as JsonRecord;
}
function scene(command: JsonRecord): JsonRecord {
  return { id: "edit", name: "Barrier", metadata: { keep: "metadata" }, graph: {
    startNodeId: "start", nodes: [{ id: "start", kind: "start" },
      { id: "action", kind: "action", title: "Keep title", payload: { actionKind: "keep", parameters: { keep: "value" }, interactiveCommand: command } },
      { id: "end", kind: "end" }], edges: [
      { id: "start-action", fromNodeId: "start", fromPortId: "completed", toNodeId: "action", kind: "default" },
      { id: "done", fromNodeId: "action", fromPortId: "completed", toNodeId: "end", kind: "actionCompleted" }] } };
}
test("live MCP authors an exact native map route barrier and rejects incompatible writes", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "native-route-barrier-mcp-"));
  const manifest = { name: "Barrier", version: "v8", pokemon: canonicalPokemonConfig(), tilesets: [],
    maps: [{ id: "map", name: "Map", relativePath: "maps/map.json" }], scenes: [scene({ kind: "wait", durationMs: 1 })] };
  const map = { id: "map", name: "Map", version: "v8", size: { width: 4, height: 4 }, layers: [] };
  await mkdir(join(root, "maps"));
  const file = join(root, "project.json"); const mapFile = join(root, "maps/map.json");
  await writeFile(file, JSON.stringify(manifest)); await writeFile(mapFile, JSON.stringify(map));
  const beforeMap = await readFile(mapFile);
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const client = new Client({ name: "native-global-routes", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  let workspace: JsonRecord | undefined; let sequence = 0;
  async function call(name: string, input: JsonRecord, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: input }); const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify({ name, input, envelope })); return record(envelope[failure ? "error" : "data"]);
  }
  async function plan(actionId: string, parameters: JsonRecord, failure = false): Promise<JsonRecord> {
    assert.ok(workspace); const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    const id = `barrier-${++sequence}`;
    return call("pokemap_plan", { projectHandle: workspace.projectHandle, request: { requestId: id, actionId, actionVersion: 1,
      workspaceHandle: workspace.workspaceHandle, expectedRevision: validation.snapshotRevision, idempotencyKey: id, parameters } }, failure);
  }
  try {
    await client.connect(transport);
    const description = await call("pokemap_describe", {});
    for (const id of ["scene.interactive_command.set", "scene.upsert", "scene.graph.patch"]) {
      const action = (description.mutationActions as JsonRecord[]).find((a) => a.id === id); assert.ok(action);
      const contract = record(record(action.extensions).waitForActorRoutes);
      assert.deepEqual(contract.parameters, ["mapId"]); assert.equal(contract.projectDimension, "twoD");
      assert.equal(contract.mapReference, "knownUniqueLoaded2DMap"); assert.equal(contract.routeSet, "live");
      assert.equal(contract.completion, "allForcedRoutesFinished"); assert.equal(contract.timeout, "none"); assert.deepEqual(contract.outputPorts, ["completed"]);
    }
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const command = { kind: "waitForActorRoutes", mapId: "map" };
    const before = await readFile(file);
    const change = await plan("scene.interactive_command.set", { sceneId: "edit", nodeId: "action", command });
    assert.deepEqual(await readFile(file), before);
    await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle, planId: change.planId, operationId: "apply-barrier" });
    const saved = record(JSON.parse(await readFile(file, "utf8")));
    const savedScene = record((saved.scenes as JsonRecord[]).find((s) => s.id === "edit"));
    const node = (record(savedScene.graph).nodes as JsonRecord[]).find((n) => n.id === "action"); assert.ok(node);
    assert.deepEqual(record(node.payload).interactiveCommand, command); assert.deepEqual(record(node.payload).parameters, { keep: "value" });
    assert.deepEqual(await readFile(mapFile), beforeMap);
    for (const bad of [{ kind: "waitForActorRoutes", mapId: "missing" }, { ...command, mapId: null }, { ...command, timeoutMs: 100 }, { ...command, entityId: "npc" }]) {
      const stable = await readFile(file); const rejected = await plan("scene.interactive_command.set", { sceneId: "edit", nodeId: "action", command: bad }, true);
      assert.notEqual(rejected.domainCode, "worker.internal"); assert.deepEqual(await readFile(file), stable);
    }
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const queried = await call("pokemap_query", { projectHandle: workspace.projectHandle, resourceKind: "scene", operation: "get", ids: ["edit"], view: "detail" });
    assert.ok(JSON.stringify(queried).includes('"waitForActorRoutes"'));
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle }); workspace = undefined;
    const spatialRoot = join(root, "threeD"); await mkdir(join(spatialRoot, "maps"), { recursive: true });
    const spatialFile = join(spatialRoot, "project.json"); const spatialMapFile = join(spatialRoot, "maps/map.json");
    await writeFile(spatialFile, JSON.stringify({ ...manifest, version: "v9", settings: { dimension: "threeD" } }));
    await writeFile(spatialMapFile, JSON.stringify({ ...map, version: "v9", spatialScene: { schemaVersion: 1, width: 4, depth: 4,
      heightLevels: Array(16).fill(0), levelHeight: 1, instances: [], camera: { mode: "fixed", pitchDegrees: 48.7, yawDegrees: 0, fieldOfViewDegrees: 16.2, distance: 42 } } }));
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: spatialRoot });
    const stable = await readFile(spatialFile); const stableMap = await readFile(spatialMapFile);
    for (const [actionId, parameters] of [
      ["scene.interactive_command.set", { sceneId: "edit", nodeId: "action", command }],
      ["scene.upsert", { scene: scene(command) }],
      ["scene.graph.patch", { sceneId: "edit", upsertNodes: [record(scene(command).graph).nodes as JsonRecord[]].flat().filter((n) => n.id === "action") }],
    ] as [string, JsonRecord][]) {
      const rejected = await plan(actionId, parameters, true);
      assert.equal(rejected.domainCode, "scene.publication_blocked"); assert.ok(JSON.stringify(rejected).includes("commandUnsupportedDimension"));
      assert.deepEqual(await readFile(spatialFile), stable); assert.deepEqual(await readFile(spatialMapFile), stableMap);
    }
  } finally {
    if (workspace) await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    await client.close(); await transport.close(); await rm(root, { recursive: true, force: true });
  }
});

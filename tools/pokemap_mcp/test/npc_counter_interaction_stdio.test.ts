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

for (const spatial of [false, true]) {
test(`live MCP discovers and edits NPC counter sides with revision checks spatial=${spatial}`, { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "npc-counter-mcp-"));
  const mapFile = join(root, "maps/center.json");
  const projectFile = join(root, "project.json");
  await mkdir(join(root, "maps"));
  await writeFile(projectFile, JSON.stringify({ name: "Counter MCP", version: spatial ? "v9" : "v8", settings: {dimension: spatial ? "threeD" : "twoD"}, tilesets: [], pokemon: canonicalPokemonConfig(),
    maps: [{ id: "center", name: "Center", relativePath: "maps/center.json" }] }));
  const entities = [
    { id: "nurse", kind: "npc", pos: { x: 2, y: 1 }, npc: { displayName: "Nurse", facing: "south" } },
    { id: "wide", kind: "npc", pos: { x: 4, y: 1 }, size: { width: 2, height: 1 }, npc: { displayName: "Wide" } },
  ];
  await writeFile(mapFile, JSON.stringify({ id: "center", name: "Center", version: spatial ? "v9" : "v8",
    ...(spatial ? {spatialScene: {schemaVersion: 1, width: 8, depth: 6, heightLevels: Array(48).fill(0), levelHeight: 1, camera: {mode: "fixed", yawDegrees: 0, pitchDegrees: 48.7, fieldOfViewDegrees: 16.2, distance: 42}, instances: []}} : {}),
    size: { width: 8, height: 6 }, layers: [], entities }));
  const projectBefore = await readFile(projectFile);
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const client = new Client({ name: "npc-counter-test", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  let workspace: JsonRecord | undefined;
  let sequence = 0;
  async function call(name: string, input: JsonRecord, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: input });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify({ name, envelope }));
    return record(envelope[failure ? "error" : "data"]);
  }
  async function plan(parameters: JsonRecord, failure = false, revision?: unknown): Promise<JsonRecord> {
    assert.ok(workspace);
    const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    const before = await readFile(mapFile);
    const id = `counter-${++sequence}`;
    const planned = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
      requestId: id, actionId: "npc.set_counter_interaction_sides", actionVersion: 1,
      workspaceHandle: workspace.workspaceHandle, expectedRevision: revision ?? validation.snapshotRevision,
      idempotencyKey: id, parameters,
    } }, failure);
    assert.deepEqual(await readFile(mapFile), before);
    assert.deepEqual(await readFile(projectFile), projectBefore);
    return planned;
  }
  try {
    await client.connect(transport);
    const description = await call("pokemap_describe", {});
    const action = (description.mutationActions as JsonRecord[])
      .find(entry => entry.id === "npc.set_counter_interaction_sides");
    assert.ok(action);
    assert.deepEqual(record(record(action.extensions).counterInteraction), {
      relativeTo: "npc", directions: ["north", "south", "east", "west"], distanceCells: 2,
      intermediateCell: "blockingAndWithoutEntity", npcFootprint: { width: 1, height: 1 },
      mapModes: ["2d", "3d"], parameters: ["mapId", "entityId", "sides"],
    });
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const initial = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    for (const sides of [["south"], ["north", "east"], []]) {
      const planned = await plan({ mapId: "center", entityId: "nurse", sides });
      await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle,
        planId: planned.planId, operationId: `apply-${sequence}` });
      const map = record(JSON.parse(await readFile(mapFile, "utf8")));
      const saved = (map.entities as JsonRecord[]).find(entity => entity.id === "nurse")!;
      assert.deepEqual(record(saved.npc).counterInteractionSides, sides);
      assert.deepEqual(saved.pos, entities[0]!.pos);
      assert.equal(record(saved.npc).displayName, "Nurse");
      assert.deepEqual(map.layers, []);
      const query = await call("pokemap_query", { projectHandle: workspace.projectHandle,
        resourceKind: "map", operation: "get", ids: ["center"], view: "detail" });
      assert.ok(JSON.stringify(query).includes('"nurse"'));
      assert.ok(JSON.stringify(query).includes('"counterInteractionSides"'));
    }
    for (const parameters of [
      { mapId: "center", entityId: "nurse", sides: ["diagonal"] },
      { mapId: "center", entityId: "nurse", sides: ["south", "south"] },
      { mapId: "center", entityId: "wide", sides: ["south"] },
    ]) {
      const rejected = await plan(parameters, true);
      assert.notEqual(rejected.domainCode, "worker.internal");
    }
    const stale = await plan({ mapId: "center", entityId: "nurse", sides: ["south"] }, true, initial.snapshotRevision);
    assert.equal(stale.domainCode, "plan.stale");
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const reopened = await call("pokemap_query", { projectHandle: workspace.projectHandle,
      resourceKind: "map", operation: "get", ids: ["center"], view: "detail" });
    assert.ok(JSON.stringify(reopened).includes('"counterInteractionSides":[]'));
    assert.deepEqual(await readFile(projectFile), projectBefore);
  } finally {
    if (workspace) await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

}

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
test(`live MCP discovers, authors and reopens closed native fixed routes in ${spatial ? "3D refusal" : "2D"}`, { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "npc-fixed-route-mcp-"));
  const projectFile = join(root, "project.json");
  const mapFile = join(root, "maps/center.json");
  await mkdir(join(root, "maps"));
  await writeFile(projectFile, JSON.stringify({ name: "Fixed routes", version: spatial ? "v9" : "v8", settings: { dimension: spatial ? "threeD" : "twoD" }, tilesets: [], pokemon: canonicalPokemonConfig(),
    maps: [{ id: "center", name: "Center", relativePath: "maps/center.json" }] }));
  await writeFile(mapFile, JSON.stringify({ id: "center", name: "Center", version: spatial ? "v9" : "v8", size: { width: 8, height: 6 },
    ...(spatial ? { spatialScene: { schemaVersion: 1, width: 8, depth: 6,
      heightLevels: Array(48).fill(0), levelHeight: 1, instances: [], camera: {
        mode: "fixed", pitchDegrees: 48.7, yawDegrees: 0, fieldOfViewDegrees: 16.2, distance: 42,
      } } } : {}),
    layers: [], entities: [{ id: "npc", kind: "npc", pos: { x: 2, y: 2 }, npc: { displayName: "Guide", facing: "west" } }] }));
  const projectBefore = await readFile(projectFile);
  const client = new Client({ name: "npc-fixed-route-test", version: "1.0.0" });
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-package", resolve("../../packages/map_authoring"),
    "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  let workspace: JsonRecord | undefined;
  let sequence = 0;
  async function call(name: string, input: JsonRecord, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: input });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify(envelope));
    return record(envelope[failure ? "error" : "data"]);
  }
  async function plan(parameters: JsonRecord, failure = false, revision?: unknown): Promise<JsonRecord> {
    assert.ok(workspace);
    const current = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    const before = await readFile(mapFile);
    const id = `route-${++sequence}`;
    const result = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
      requestId: id, actionId: "npc.set_movement_mode", actionVersion: 1, workspaceHandle: workspace.workspaceHandle,
      expectedRevision: revision ?? current.snapshotRevision, idempotencyKey: id, parameters,
    } }, failure);
    assert.deepEqual(await readFile(mapFile), before);
    assert.deepEqual(await readFile(projectFile), projectBefore);
    return result;
  }
  try {
    await client.connect(transport);
    const described = await call("pokemap_describe", {});
    const action = (described.mutationActions as JsonRecord[]).find(action => action.id === "npc.set_movement_mode");
    assert.ok(action);
    const contract = record(record(action.extensions).npcMovement);
    assert.ok((contract.modes as unknown[]).includes("fixedRoute"));
    const fixed = record(contract.fixedRoute);
    assert.deepEqual(fixed.stepKinds, ["move", "face", "randomFacing", "randomMove"]);
    assert.equal(fixed.skippable, false);
    assert.equal(fixed.pathfinding, false);
    assert.equal(fixed.mapMode, "2d");
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const initial = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    const steps = [{ kind: "move", direction: "east" }, { kind: "face", direction: "north" }, { kind: "randomFacing" }, { kind: "randomMove" }];
    const flag = { key: "npc.autonomousRouteStopped", value: true };
    const parameters = { mapId: "center", entityId: "npc", mode: "fixedRoute", routeSteps: steps,
      suspendWhenInstanceBoolean: flag, pauseDurationMs: 1600, stepDurationMs: 250, loop: true };
    if (spatial) {
      const rejected = await plan(parameters, true);
      assert.equal(rejected.domainCode, "npc.movement_invalid");
      assert.deepEqual(await readFile(projectFile), projectBefore);
      return;
    }
    const planned = await plan(parameters);
    await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle,
      planId: planned.planId, operationId: "apply-fixed-route" });
    const saved = record(JSON.parse(await readFile(mapFile, "utf8")));
    const npc = record(record((saved.entities as JsonRecord[])[0]).npc);
    const movement = record(npc.movement);
    assert.equal(movement.mode, "fixedRoute");
    assert.deepEqual(movement.routeSteps, steps);
    assert.deepEqual(movement.suspendWhenInstanceBoolean, flag);
    assert.equal(movement.pauseDurationMs, 1600);
    assert.equal(movement.stepDurationMs, 250);
    assert.equal(npc.displayName, "Guide");
    assert.deepEqual(record((saved.entities as JsonRecord[])[0]).pos, { x: 2, y: 2 });
    for (const override of [
      { routeSteps: [] }, { routeSteps: Array.from({ length: 257 }, () => ({ kind: "randomFacing" })) },
      { routeSteps: [{ kind: "script", script: "Kernel.eval('x')" }] },
      { routeSteps: [{ kind: "move", direction: "east", through: true }] },
      { suspendWhenInstanceBoolean: { key: "npc.stop", value: "true" } },
      { suspendWhenInstanceBoolean: { key: "npc.stop", value: true, mapId: "foreign" } },
      { mode: "idle" },
    ]) {
      const rejected = await plan({ ...parameters, ...override }, true);
      assert.notEqual(rejected.domainCode, "worker.internal");
    }
    const stale = await plan(parameters, true, initial.snapshotRevision);
    assert.equal(stale.domainCode, "plan.stale");
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const query = await call("pokemap_query", { projectHandle: workspace.projectHandle,
      resourceKind: "map", operation: "get", ids: ["center"], view: "detail" });
    assert.ok(JSON.stringify(query).includes('"fixedRoute"'));
    assert.ok(JSON.stringify(query).includes('"randomFacing"'));
    assert.deepEqual(await readFile(projectFile), projectBefore);
  } finally {
    if (workspace) await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

}

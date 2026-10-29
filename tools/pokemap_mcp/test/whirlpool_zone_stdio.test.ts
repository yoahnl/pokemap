import assert from "node:assert/strict";
import { createHash } from "node:crypto";
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

for (const spatial of [false, true]) test(`live MCP authors the canonical ${spatial ? "3D" : "2D"} Whirlpool route with strict gates, undo and a fresh server`, { timeout: 120_000 }, async () => {
  const fixtureFile = resolve("../../packages/map_core/test/fixtures/whirlpool_field_zone.json");
  const fixtureBytes = await readFile(fixtureFile);
  const fixture = record(JSON.parse(fixtureBytes.toString("utf8")));
  const payload = record(fixture.fieldAction);
  const route = record(payload.whirlpool);
  const root = await mkdtemp(join(tmpdir(), "whirlpool-zone-mcp-"));
  const projectFile = join(root, "project.json");
  const mapFile = join(root, "maps/field.json");
  const water: JsonRecord = {
    id: "water",
    name: "Water",
    kind: "movement",
    area: { pos: { x: 0, y: 0 }, size: { width: 8, height: 8 } },
    movement: { requiredMode: "surf" },
  };
  await mkdir(join(root, "maps"));
  await writeFile(projectFile, JSON.stringify({
    name: "Field traversal MCP",
    version: spatial ? "v9" : "v8",
    ...(spatial ? { settings: { dimension: "threeD" } } : {}),
    pokemon: canonicalPokemonConfig(),
    maps: [{ id: "field", name: "Field", relativePath: "maps/field.json" }],
    tilesets: [],
  }));
  await writeFile(mapFile, JSON.stringify({
    id: "field",
    name: "Field",
    version: spatial ? "v9" : "v8",
    size: { width: 8, height: 8 },
    layers: [],
    ...(spatial ? { spatialScene: { schemaVersion: 1, width: 8, depth: 8, levelHeight: 1, heightLevels: Array(64).fill(0),
      camera: { mode: "fixed", projection: "perspective", pitchDegrees: 48.7, yawDegrees: 0, fieldOfViewDegrees: 16.2, distance: 42, orthographicHeight: 12 },
      navigation: { spawn: { x: .5, z: .5 }, allowDiagonalMovement: false, ramps: [], blockedAreas: [] }, instances: [] } } : {}),
  }));
  const projectBefore = await readFile(projectFile);
  let active: { client: Client; transport: StdioClientTransport } | undefined;
  let workspace: JsonRecord | undefined;
  let sequence = 0;
  let stderr = "";

  async function connect(): Promise<void> {
    const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
    if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
    const client = new Client({ name: "whirlpool-zone-test", version: "1.0.0" });
    const transport = new StdioClientTransport({
      command: process.execPath,
      args,
      cwd: process.cwd(),
      stderr: "pipe",
    });
    stderr = "";
    transport.stderr?.on("data", chunk => {
      stderr = (stderr + String(chunk)).slice(-8000);
    });
    active = { client, transport };
    try {
      await client.connect(transport);
    } catch (error) {
      throw new Error(String(error) + "\n" + stderr);
    }
  }

  async function call(name: string, input: JsonRecord, failure = false): Promise<JsonRecord> {
    assert.ok(active);
    try {
      const result = await active.client.callTool({ name, arguments: input });
      const envelope = record(result.structuredContent);
      assert.equal(envelope.ok, !failure, JSON.stringify({ name, envelope }));
      return record(envelope[failure ? "error" : "data"]);
    } catch (error) {
      throw new Error(String(error) + "\n" + stderr);
    }
  }

  async function plan(parameters: JsonRecord, failure = false, revision?: unknown): Promise<JsonRecord> {
    assert.ok(workspace);
    const validation = await call("pokemap_workshop", { operation: "read", projectHandle: workspace.projectHandle,
      actionId: "gameplay_zone.set_field_action_payload", parameters: { mapId: "field", zoneId: fixture.id, ...parameters }, includeDocuments: false });
    const before = await readFile(mapFile);
    const id = "whirlpool-" + ++sequence;
    const result = await call("pokemap_plan", {
      projectHandle: workspace.projectHandle,
      request: {
        requestId: id,
        actionId: "gameplay_zone.set_field_action_payload",
        actionVersion: 1,
        workspaceHandle: workspace.workspaceHandle,
        expectedRevision: revision ?? validation.snapshotRevision,
        idempotencyKey: id,
        parameters: { mapId: "field", zoneId: fixture.id, ...parameters },
      },
    }, failure);
    assert.deepEqual(await readFile(mapFile), before);
    return result;
  }

  async function create(zone: JsonRecord): Promise<void> {
    assert.ok(workspace);
    const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    const before = await readFile(mapFile);
    const id = "whirlpool-" + ++sequence;
    const result = await call("pokemap_plan", {
      projectHandle: workspace.projectHandle,
      request: {
        requestId: id,
        actionId: "gameplay_zone.create",
        actionVersion: 1,
        workspaceHandle: workspace.workspaceHandle,
        expectedRevision: validation.snapshotRevision,
        idempotencyKey: id,
        parameters: { mapId: "field", zone },
      },
    });
    assert.deepEqual(await readFile(mapFile), before);
    await call("pokemap_apply", {
      operation: "apply",
      projectHandle: workspace.projectHandle,
      planId: result.planId,
      operationId: "whirlpool-" + ++sequence,
    });
  }

  async function fieldZone(): Promise<JsonRecord> {
    const map = record(JSON.parse(await readFile(mapFile, "utf8")));
    const zones = map.gameplayZones as JsonRecord[];
    const zone = zones.find(value => value.id === fixture.id);
    assert.ok(zone);
    return zone;
  }

  try {
    await connect();
    const description = await call("pokemap_describe", {});
    const action = (description.mutationActions as JsonRecord[]).find(
      value => value.id === "gameplay_zone.set_field_action_payload",
    );
    assert.ok(action);
    const contract = record(record(action.extensions).fieldActionZone);
    assert.ok((contract.actionKinds as string[]).includes("whirlpool"));
    assert.deepEqual(record(contract.mapModesByActionKind).whirlpool, ["2d", "3d"]);
    assert.equal(record(contract.spatialTraversal).capability, "map3d.field-traversal@1");
    const whirlpool = record(contract.whirlpool);
    assert.equal(whirlpool.fieldAbility, "whirlpool");
    assert.equal(whirlpool.requiresSurf, true);
    assert.equal(whirlpool.coordinateSpace, "zoneRelative");
    assert.equal(whirlpool.pathMinCells, 1);
    assert.equal(whirlpool.pathMaxCells, 256);
    assert.equal(whirlpool.zonePersistence, "persistent");
    assert.equal(whirlpool.saveDuringTraversal, false);
    assert.equal(whirlpool.checkpointDuringTraversal, false);
    assert.equal(whirlpool.consumesPp, false);

    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    await create(water);
    await create(fixture);
    assert.deepEqual(record((await fieldZone()).fieldAction), payload);
    const beforeChange = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    const south: JsonRecord = {
      actionKind: "whirlpool",
      whirlpool: {
        entry: route.exit,
        path: [...route.path as JsonRecord[]].reverse(),
        exit: route.entry,
        direction: "south",
      },
    };
    const planned = await plan({ payload: south });
    assert.deepEqual(record((await fieldZone()).fieldAction), payload);
    await call("pokemap_apply", {
      operation: "apply",
      projectHandle: workspace.projectHandle,
      planId: planned.planId,
      operationId: "whirlpool-" + ++sequence,
    });
    assert.deepEqual(record((await fieldZone()).fieldAction), south);
    const stale = await plan({ payload }, true, beforeChange.snapshotRevision);
    assert.equal(stale.domainCode, "plan.stale");

    const invalidPayloads: JsonRecord[] = [
      { actionKind: "whirlpool", whirlpool: { ...route, requiresSurf: false } },
      { ...payload, darkness: { opacity: 0.7 } },
      { actionKind: "current", current: route },
      { actionKind: "whirlpool", whirlpool: { ...route, entry: { x: 0.5, y: 3 } } },
      { actionKind: "whirlpool", whirlpool: { ...route, exit: { x: 1, y: 0 } } },
      { actionKind: "whirlpool", whirlpool: { ...route, direction: "east" } },
      { actionKind: "whirlpool", whirlpool: { ...route, destinationMapId: "elsewhere" } },
    ];
    for (const invalid of invalidPayloads) {
      const rejected = await plan({ payload: invalid }, true);
      assert.notEqual(rejected.domainCode, "worker.internal");
      assert.deepEqual(record((await fieldZone()).fieldAction), south);
    }
    const history = await call("pokemap_history", {
      operation: "list", projectHandle: workspace.projectHandle, limit: 1,
    });
    await call("pokemap_history", {
      operation: "undo",
      projectHandle: workspace.projectHandle,
      entryId: (history.entries as JsonRecord[])[0]!.entryId,
      idempotencyKey: "undo-whirlpool",
    });
    assert.deepEqual(record((await fieldZone()).fieldAction), payload);
    const deleteArgs = { mapId: "field", zoneId: fixture.id };
    const deleteRead = await call("pokemap_workshop", { operation: "read", projectHandle: workspace.projectHandle,
      actionId: "gameplay_zone.delete", parameters: deleteArgs, includeDocuments: false });
    const deletion = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
      requestId: "delete-route", actionId: "gameplay_zone.delete", actionVersion: 1, idempotencyKey: "delete-route",
      workspaceHandle: workspace.workspaceHandle, expectedRevision: deleteRead.snapshotRevision, parameters: deleteArgs } });
    const deleted = await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle, planId: deletion.planId, operationId: "delete-route" });
    assert.equal((record(JSON.parse(await readFile(mapFile, "utf8"))).gameplayZones as JsonRecord[]).some(zone => zone.id === fixture.id), false);
    await call("pokemap_history", { operation: "undo", projectHandle: workspace.projectHandle,
      entryId: record(deleted.receipt).receiptId, idempotencyKey: "undo-delete-route" });
    assert.deepEqual(record((await fieldZone()).fieldAction), payload);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = undefined;
    await active!.client.close();
    await active!.transport.close();
    active = undefined;
    await connect();
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const reopened = await call("pokemap_query", {
      projectHandle: workspace.projectHandle,
      resourceKind: "map",
      operation: "get",
      ids: ["field"],
      view: "detail",
    });
    assert.ok(JSON.stringify(reopened).includes('"actionKind":"whirlpool"'));
    assert.deepEqual((await fieldZone()).area, fixture.area);
    assert.deepEqual(record((await fieldZone()).fieldAction), payload);
    const map = record(JSON.parse(await readFile(mapFile, "utf8")));
    const waterReopened = (map.gameplayZones as JsonRecord[]).find(value => value.id === "water");
    assert.ok(waterReopened);
    assert.deepEqual(waterReopened.area, water.area);
    assert.equal(record(waterReopened.movement).requiredMode, "surf");
    assert.deepEqual(await readFile(projectFile), projectBefore);
    const receiptPath = spatial ? process.env.POKEMAP_TEST_WHIRLPOOL_3D_RECEIPT : process.env.POKEMAP_TEST_WHIRLPOOL_RECEIPT;
    if (receiptPath) {
      await writeFile(receiptPath, JSON.stringify({
        action,
        live: true,
        transport: "MCP stdio",
        canonicalFixture: fixtureFile,
        fixtureSha256: createHash("sha256").update(fixtureBytes).digest("hex"),
        serverSha256: createHash("sha256").update(await readFile(resolve("dist/src/index.js"))).digest("hex"),
        verified: ["describe", "waterAndWhirlpoolComposition", "nonMutatingPlan", "set", "strictRefusals", "stale", "undo", "query", "freshServerReopen"],
      }, null, 2));
    }
  } finally {
    if (workspace && active) {
      await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    }
    if (active) {
      await active.client.close();
      await active.transport.close();
    }
    await rm(root, { recursive: true, force: true });
  }
});

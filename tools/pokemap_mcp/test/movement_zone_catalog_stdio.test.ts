import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { mkdir, mkdtemp, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { promisify } from "node:util";
import { test } from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("fresh MCP creates a scoped catalog movement zone and preserves it across a fresh worker", { timeout: 120_000 }, async () => {
  const configuredRoot = process.env.POKEMAP_TEST_MOVEMENT_ZONE_ROOT;
  const root = configuredRoot ?? await mkdtemp(join(tmpdir(), "movement-zone-catalog-"));
  if (configuredRoot) await mkdir(root);
  const dart = process.env.POKEMAP_TEST_DART ?? "dart";
  const packageRoot = resolve("../../packages/map_authoring");
  const projectFile = join(root, "project.json");
  const mapFile = join(root, "maps/story.json");
  let active: { client: Client; transport: StdioClientTransport } | undefined;
  let workspace: JsonRecord | undefined;
  let stderr = "";

  async function connect(): Promise<void> {
    const client = new Client({ name: "catalog-movement-zone-proof", version: "1.0.0" });
    const transport = new StdioClientTransport({ command: process.execPath,
      args: [resolve("dist/src/index.js"), "--root", root, "--dart", dart, "--authoring-timeout-ms", "60000"],
      cwd: process.cwd(), stderr: "pipe" });
    stderr = "";
    transport.stderr?.on("data", chunk => { stderr = (stderr + String(chunk)).slice(-8000); });
    active = { client, transport };
    await client.connect(transport);
  }

  async function call(name: string, input: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    assert.ok(active);
    const result = await active.client.callTool({ name, arguments: input });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify({ name, envelope, stderr }));
    return record(envelope[failure ? "error" : "data"]);
  }

  async function disconnect(): Promise<void> {
    try {
      if (workspace && active) {
        await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
      }
    } finally {
      workspace = undefined;
      if (active) {
        const closing = active;
        active = undefined;
        try { await closing.client.close(); }
        finally { await closing.transport.close(); }
      }
    }
  }


  try {
    await promisify(execFile)(dart, [`--packages=${join(packageRoot, ".dart_tool/package_config.json")}`,
      join(packageRoot, "test/support/create_working_catalog_fixture.dart"), root, "--story-map"], { timeout: 60_000 });
    const descriptorBefore = await readFile(projectFile);
    const mapBefore = await readFile(mapFile);
    const original = record(JSON.parse(mapBefore.toString("utf8")));
    const foreignBefore = await readFile(join(root, "maps/foreign.json"));
    const zone = { id: "source-water", name: "Native movement gate", kind: "movement",
      area: { pos: { x: 1, y: 1 }, size: { width: 2, height: 1 } },
      movement: { requiredMode: "surf", allowedModes: [] } };
    const parameters = { mapId: "story", zone };
    await connect();
    const described = await call("pokemap_describe", { actionIds: ["gameplay_zone.create"], view: "full" });
    const actions = described.mutationActions as JsonRecord[];
    assert.equal(actions.length, 1);
    assert.equal(actions[0]!.id, "gameplay_zone.create");
    assert.equal(actions[0]!.version, 1);
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    await call("pokemap_workshop", { operation: "prepare", projectHandle: workspace.projectHandle });
    const scope = await call("pokemap_workshop", { operation: "read", projectHandle: workspace.projectHandle,
      actionId: "gameplay_zone.create", parameters, includeDocuments: false });
    const planned = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
      requestId: "movement-create", actionId: "gameplay_zone.create", actionVersion: 1,
      workspaceHandle: workspace.workspaceHandle, expectedRevision: scope.snapshotRevision,
      idempotencyKey: "movement-create", parameters } });
    assert.deepEqual(await readFile(mapFile), mapBefore);
    const applied = await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle,
      planId: planned.planId, operationId: "movement-create" });
    const saved = record(JSON.parse(await readFile(mapFile, "utf8")));
    const savedZones = saved.gameplayZones as JsonRecord[];
    assert.equal(savedZones.length, 1);
    assert.equal(savedZones[0]!.id, zone.id);
    assert.deepEqual(savedZones[0]!.area, zone.area);
    assert.deepEqual(savedZones[0]!.movement, zone.movement);
    assert.deepEqual({ ...saved, gameplayZones: original.gameplayZones }, original);
    assert.deepEqual(await readFile(projectFile), descriptorBefore);
    assert.deepEqual(await readFile(join(root, "maps/foreign.json")), foreignBefore);
    const savedBytes = await readFile(mapFile);
    const refusal = await call("pokemap_workshop", { operation: "read", projectHandle: workspace.projectHandle,
      actionId: "gameplay_zone.create", parameters: { mapId: "story", zone: { ...zone, id: "foreign-ref",
        kind: "encounter", movement: null, encounter: { encounterTableId: "unadmitted-table" } } },
      includeDocuments: false }, true);
    assert.equal(refusal.domainCode, "catalog.mutation_scope_required");
    assert.deepEqual(await readFile(mapFile), savedBytes);
    await disconnect();
    await connect();
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const queried = await call("pokemap_query", { projectHandle: workspace.projectHandle, resourceKind: "map",
      operation: "get", ids: ["story"], view: "detail" });
    const reopened = record((queried.items as JsonRecord[])[0]);
    const reopenedZone = (reopened.gameplayZones as JsonRecord[]).find(value => value.id === zone.id);
    assert.ok(reopenedZone);
    assert.deepEqual(reopenedZone.movement, zone.movement);
    assert.deepEqual(await readFile(mapFile), savedBytes);
    await call("pokemap_history", { operation: "undo", projectHandle: workspace.projectHandle,
      entryId: record(applied.receipt).receiptId, idempotencyKey: "movement-undo" });
    assert.deepEqual(await readFile(mapFile), mapBefore);
    assert.deepEqual(await readFile(projectFile), descriptorBefore);
    assert.deepEqual(await readFile(join(root, "maps/foreign.json")), foreignBefore);
  } finally {
    try { await disconnect(); }
    finally { await rm(root, { recursive: true, force: true }); }
  }
});

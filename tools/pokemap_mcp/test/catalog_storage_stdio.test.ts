import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
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

test("MCP stdio queries and edits working catalogs with pinned pages and partial persistence", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "catalog-storage-mcp-"));
  const dart = process.env.POKEMAP_TEST_DART ?? "dart";
  const packageRoot = resolve("../../packages/map_authoring");
  await promisify(execFile)(dart, [`--packages=${join(packageRoot, ".dart_tool/package_config.json")}`, join(packageRoot, "test/support/create_working_catalog_fixture.dart"), root], { timeout: 60_000 });
  const descriptor = await readFile(join(root, "project.json"));
  const client = new Client({ name: "catalog-storage-proof", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args: [resolve("dist/src/index.js"), "--root", root, "--dart", dart, "--authoring-timeout-ms", "60000"], cwd: process.cwd(), stderr: "pipe" });
  async function call(name: string, input: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: input });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify(envelope));
    return record(envelope[failure ? "error" : "data"]);
  }
  try {
    await client.connect(transport);
    const described = await call("pokemap_describe");
    assert.ok((described.mutationActions as JsonRecord[]).some(action => action.id === "catalog.definition.update"));
    const tilesetKind = (described.resourceKinds as JsonRecord[]).find(kind => kind.id === "tileset");
    assert.equal(record(record(tilesetKind!.extensions).partitionedStorage).summary, "indexOnly");
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    assert.ok((described.commands as JsonRecord[]).some(command => command.id === "workshop_snapshot"));
    const preparedWorkshop = await call("pokemap_workshop", { operation: "prepare", projectHandle: opened.projectHandle });
    assert.equal(preparedWorkshop.prepared, true);
    const trainerParameters = { value: { id: "local-trainer", name: "Local trainer", trainerClass: "Trainer", team: [] } };
    const workshop = await call("pokemap_workshop", { operation: "read", projectHandle: opened.projectHandle,
      actionId: "campaign.trainer.upsert", parameters: trainerParameters });
    assert.deepEqual(workshop.maps, []);
    const trainerPlan = await call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
      requestId: "local-trainer", actionId: "campaign.trainer.upsert", actionVersion: 1,
      workspaceHandle: opened.workspaceHandle, expectedRevision: workshop.snapshotRevision,
      idempotencyKey: "local-trainer", parameters: trainerParameters } });
    await call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle,
      planId: trainerPlan.planId, operationId: "local-trainer-operation" });
    const workshopAfter = await call("pokemap_workshop", { operation: "read", projectHandle: opened.projectHandle,
      actionId: "campaign.trainer.upsert", parameters: trainerParameters });
    assert.equal(record((record(workshopAfter.project).trainers as JsonRecord[])[0]).name, "Local trainer");
    assert.deepEqual(await readFile(join(root, "project.json")), descriptor);
    await assert.rejects(client.readResource({ uri: `pokemap://project/${encodeURIComponent(String(opened.projectHandle))}` }), /materialization|require/i);
    const explicitProject = await call("pokemap_query", { projectHandle: opened.projectHandle, resourceKind: "project", operation: "get", ids: ["project"], view: "detail", extensions: { materializeProject: true } });
    assert.equal(explicitProject.returned, 1);
    const query = { projectHandle: opened.projectHandle, resourceKind: "tileset", operation: "list", pageSize: 200 };
    const first = await call("pokemap_query", query);
    assert.equal(first.returned, 200);
    assert.equal(first.totalAvailable, 205);
    const last = await call("pokemap_query", { ...query, cursor: first.nextCursor });
    assert.equal(last.returned, 5);
    const resource = await client.readResource({ uri: `pokemap://project/${encodeURIComponent(String(opened.projectHandle))}/catalog/tileset` });
    assert.ok(resource.contents[0] && "text" in resource.contents[0]);
    const detail = await call("pokemap_query", { projectHandle: opened.projectHandle, resourceKind: "tileset", operation: "get", ids: ["tile-204"], view: "detail" });
    assert.equal(record((detail.items as JsonRecord[])[0]).name, "Object 204");
    const planned = await call("pokemap_plan", { projectHandle: opened.projectHandle, request: { requestId: "edit", actionId: "catalog.definition.update", actionVersion: 1, workspaceHandle: opened.workspaceHandle, expectedRevision: detail.snapshotRevision, idempotencyKey: "edit", parameters: { resourceKind: "tileset", id: "tile-204", name: "Renamed", description: "Outside object", placementContext: "exterior" } } });
    const applied = await call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle, planId: planned.planId, operationId: "catalog-edit" });
    assert.equal(record(applied.receipt).actionId, "catalog.definition.update");
    const stale = await call("pokemap_query", { ...query, cursor: first.nextCursor }, true);
    assert.equal(stale.domainCode, "query.cursor_stale");
    const found = await call("pokemap_query", { projectHandle: opened.projectHandle, resourceKind: "tileset", operation: "search", searchTerm: "Outside object", filters: { placementContext: "exterior" } });
    assert.equal(found.returned, 1);
    assert.equal(record((found.items as JsonRecord[])[0]).name, "Renamed");
    assert.deepEqual(await readFile(join(root, "project.json")), descriptor);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
    const reopened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const after = await call("pokemap_query", { projectHandle: reopened.projectHandle, resourceKind: "tileset", operation: "get", ids: ["tile-204"] });
    assert.equal(record((after.items as JsonRecord[])[0]).name, "Renamed");
    assert.equal(record((after.items as JsonRecord[])[0]).placementContext, "exterior");
    const mapQuery = { projectHandle: reopened.projectHandle, resourceKind: "map", operation: "list", view: "detail" };
    const mapsBefore = await call("pokemap_query", { projectHandle: reopened.projectHandle, resourceKind: "project", operation: "get", ids: ["project"], view: "detail", extensions: { materializeProject: true } });
    const mapPlan = await call("pokemap_plan", { projectHandle: reopened.projectHandle, request: { requestId: "create-map", actionId: "map.create", actionVersion: 1, workspaceHandle: reopened.workspaceHandle, expectedRevision: mapsBefore.snapshotRevision, idempotencyKey: "create-map", parameters: { mapId: "garden", name: "Garden", width: 8, height: 6 } } });
    const mapApplied = await call("pokemap_apply", { operation: "apply", projectHandle: reopened.projectHandle, planId: mapPlan.planId, operationId: "create-garden" });
    const created = await call("pokemap_query", { ...mapQuery, operation: "get", ids: ["garden"] });
    assert.equal(record((created.items as JsonRecord[])[0]).name, "Garden");
    const filteredMap = await call("pokemap_query", { ...mapQuery, operation: "get", ids: ["garden"], filters: { name: "Other" } }, true);
    assert.equal(filteredMap.domainCode, "query.resource_not_found");
    assert.deepEqual(await readFile(join(root, "project.json")), descriptor);
    const mapData = { ...record((created.items as JsonRecord[])[0]) };
    delete mapData.resourceKind;
    delete mapData.revision;
    const savePlan = await call("pokemap_plan", { projectHandle: reopened.projectHandle, request: { requestId: "save-map", actionId: "map.save", actionVersion: 1, workspaceHandle: reopened.workspaceHandle, expectedRevision: created.snapshotRevision, idempotencyKey: "save-map", parameters: { map: { ...mapData, properties: { saved: true } } } } });
    const saved = await call("pokemap_apply", { operation: "apply", projectHandle: reopened.projectHandle, planId: savePlan.planId, operationId: "save-garden" });
    const savedMap = await call("pokemap_query", { ...mapQuery, operation: "get", ids: ["garden"] });
    assert.equal(saved.snapshotRevision, savedMap.snapshotRevision);
    const savedBytes = await readFile(join(root, "maps/garden.json"));
    await writeFile(join(root, "maps/garden.json"), JSON.stringify({ ...mapData, properties: { external: true } }));
    const staleMap = await call("pokemap_plan", { projectHandle: reopened.projectHandle, request: { requestId: "stale-map", actionId: "map.save", actionVersion: 1, workspaceHandle: reopened.workspaceHandle, expectedRevision: savedMap.snapshotRevision, idempotencyKey: "stale-map", parameters: { map: { ...mapData, properties: { proposal: true } } } } }, true);
    assert.equal(staleMap.domainCode, "plan.stale");
    await writeFile(join(root, "maps/garden.json"), savedBytes);
    await call("pokemap_history", { operation: "undo", projectHandle: reopened.projectHandle, entryId: record(saved.receipt).receiptId, idempotencyKey: "undo-save-garden" });
    const replayed = await call("pokemap_apply", { operation: "apply", projectHandle: reopened.projectHandle, planId: mapPlan.planId, operationId: "create-garden" });
    assert.equal(record(replayed.receipt).receiptId, record(mapApplied.receipt).receiptId);
    await call("pokemap_history", { operation: "undo", projectHandle: reopened.projectHandle, entryId: record(mapApplied.receipt).receiptId, idempotencyKey: "undo-garden" });
    const mapsAfter = await call("pokemap_query", mapQuery);
    assert.equal(mapsAfter.returned, 0);
    assert.deepEqual(await readFile(join(root, "project.json")), descriptor);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: reopened.workspaceHandle });
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

test("MCP partitions an existing project explicitly and reopens it without replacing its data", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "catalog-partition-mcp-"));
  const dart = process.env.POKEMAP_TEST_DART ?? "dart";
  const packageRoot = resolve("../../packages/map_authoring");
  await promisify(execFile)(dart, [`--packages=${join(packageRoot, ".dart_tool/package_config.json")}`, join(packageRoot, "test/support/create_working_catalog_fixture.dart"), root, "--monolithic"], { timeout: 60_000 });
  const original = await readFile(join(root, "project.json"));
  const client = new Client({ name: "catalog-partition-proof", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args: [resolve("dist/src/index.js"), "--root", root, "--dart", dart, "--authoring-timeout-ms", "60000"], cwd: process.cwd(), stderr: "pipe" });
  async function call(name: string, input: JsonRecord = {}): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: input });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, true, JSON.stringify(envelope));
    return record(envelope.data);
  }
  try {
    await client.connect(transport);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const project = await call("pokemap_query", { projectHandle: opened.projectHandle, resourceKind: "project", operation: "get", ids: ["project"], view: "detail" });
    const planned = await call("pokemap_plan", { projectHandle: opened.projectHandle, request: { requestId: "partition", actionId: "project.catalog.partition", actionVersion: 1, workspaceHandle: opened.workspaceHandle, expectedRevision: project.snapshotRevision, idempotencyKey: "partition", parameters: {} } });
    assert.deepEqual(await readFile(join(root, "project.json")), original);
    assert.equal(record(record(planned.plan).preview).requiresReopen, true);
    const applied = await call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle, planId: planned.planId, operationId: "partition-project" });
    assert.equal(record(applied.receipt).actionId, "project.catalog.partition");
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
    const reopened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const page = await call("pokemap_query", { projectHandle: reopened.projectHandle, resourceKind: "tileset", operation: "list", pageSize: 200 });
    assert.equal(page.returned, 200);
    assert.equal(page.totalAvailable, 205);
    const replay = await call("pokemap_apply", { operation: "apply", projectHandle: reopened.projectHandle, planId: planned.planId, operationId: "partition-project" });
    assert.equal(record(replay.receipt).receiptId, record(applied.receipt).receiptId);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: reopened.workspaceHandle });
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

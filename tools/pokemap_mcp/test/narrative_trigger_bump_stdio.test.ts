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
const eventId = "evt_019abcde-0000-7000-8000-000000000001";
function source(kind = "triggerBump", triggerId = "owner", mapId = "map"): JsonRecord {
  return { kind, mapId, triggerId };
}
function event(value: JsonRecord): JsonRecord {
  return { state: "configured", enabled: false, definition: { id: eventId, name: "Trigger contact",
    source: value, conditions: [], sceneId: "hello", reusePolicy: "reusable", priority: 0, order: 0 } };
}

test("live MCP discovers and authors native trigger contact sources without interaction or legacy substitution", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "native-trigger-contact-mcp-"));
  const file = join(root, "project.json");
  const mapFile = join(root, "maps/map.json");
  await mkdir(join(root, "maps"));
  await writeFile(file, JSON.stringify({ name: "Native contact MCP", version: "v8", pokemon: canonicalPokemonConfig(),
    maps: [{ id: "map", name: "Map", relativePath: "maps/map.json" }],
    tilesets: [],
    scenes: [{ id: "hello", name: "Hello", graph: { startNodeId: "start", nodes: [
      { id: "start", kind: "start" }, { id: "end", kind: "end" }], edges: [
      { id: "done", fromNodeId: "start", fromPortId: "completed", toNodeId: "end", kind: "default" }] } }],
    eventRegistry: { schemaVersion: 1, mode: "v2Only", records: [event({ kind: "mapEnter", mapId: "map" })], legacyClaims: [] } }));
  const triggers = [
    { id: "owner", type: "event" }, { id: "system", type: "custom" },
  ].map((value) => ({ ...value, name: value.id, area: { pos: { x: 1, y: 1 }, size: { width: 1, height: 1 } } }));
  await writeFile(mapFile, JSON.stringify({ id: "map", name: "Map", version: "v8", size: { width: 6, height: 6 }, layers: [], triggers }));
  const beforeMap = await readFile(mapFile);
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const client = new Client({ name: "native-trigger-contact", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  let workspace: JsonRecord | undefined;
  let sequence = 0;
  async function call(name: string, input: JsonRecord, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: input });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify({ name, input, envelope }));
    return record(envelope[failure ? "error" : "data"]);
  }
  async function plan(actionId: string, parameters: JsonRecord, failure = false): Promise<JsonRecord> {
    assert.ok(workspace);
    const validated = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    const before = await readFile(file);
    const id = `trigger-contact-${++sequence}`;
    const planned = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
      requestId: id, actionId, actionVersion: 1, workspaceHandle: workspace.workspaceHandle,
      expectedRevision: validated.snapshotRevision, idempotencyKey: id, dryRun: false, parameters } }, failure);
    assert.deepEqual(await readFile(file), before);
    assert.deepEqual(await readFile(mapFile), beforeMap);
    return planned;
  }
  try {
    await client.connect(transport);
    const description = await call("pokemap_describe", {});
    const resource = (description.resourceKinds as JsonRecord[]).find((entry) => entry.id === "eventV2");
    assert.ok(resource);
    for (const entry of [resource, ...(description.mutationActions as JsonRecord[]).filter((entry) =>
      ["event_v2.create_draft", "event_v2.record_upsert", "event_v2.publish"].includes(String(entry.id)))]) {
      const variants = record(entry.extensions).sourceVariants as JsonRecord[];
      const bump = variants.find((entry) => entry.kind === "triggerBump");
      assert.ok(bump);
      assert.deepEqual(bump.requiredFields, ["kind", "mapId", "triggerId"]);
      assert.equal(bump.dimension, "twoD");
      assert.equal(bump.triggerReference, "knownUniqueEventTriggerWithValidArea");
      assert.ok(variants.some((entry) => entry.kind === "entityInteract"));
    }
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const upsert = await plan("event_v2.record_upsert", { record: event(source()) });
    await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle, planId: upsert.planId, operationId: "apply-trigger-contact" });
    for (const actionId of ["event_v2.unpublish", "event_v2.publish"]) {
      const change = await plan(actionId, { eventId });
      await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle,
        planId: change.planId, operationId: `apply-${actionId}` });
    }
    const draft = await plan("event_v2.create_draft", { name: "Trigger contact draft",
      rawUuid: "019abcde-0000-7000-8000-000000000002", initialSource: source() });
    await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle, planId: draft.planId, operationId: "apply-draft" });
    for (const value of [source("triggerBump", "missing"), source("triggerBump", "duplicate"), source("triggerBump", "system"), source("triggerBump", "owner", "missing"),
      { ...source(), triggerId: null }, { ...source(), triggerId: " owner" }, { ...source(), entityId: "npc" }, { ...source(), unknown: true }]) {
      const rejected = await plan("event_v2.record_upsert", { record: event(value) }, true);
      assert.match(String(rejected.domainCode), /^event_v2\./);
      assert.notEqual(rejected.domainCode, "worker.internal");
    }
    const saved = record(JSON.parse(await readFile(file, "utf8")));
    const registry = record(saved.eventRegistry);
    const records = registry.records as JsonRecord[];
    assert.deepEqual(record(records.find((entry) => record(entry.definition ?? entry.draft).id === eventId)!.definition).source, source());
    assert.deepEqual(record(records.find((entry) => entry.state === "draft")!.draft).source, source());
    assert.deepEqual(registry.legacyClaims, []);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const queried = await call("pokemap_query", { projectHandle: workspace.projectHandle, resourceKind: "eventV2", operation: "list", view: "detail" });
    assert.ok(JSON.stringify(queried).includes('"triggerBump"'));
    assert.ok(!JSON.stringify(queried).includes('"entityInteract"'));
    assert.deepEqual(await readFile(mapFile), beforeMap);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = undefined;
    const ambiguousRoot = join(root, "ambiguous");
    await mkdir(join(ambiguousRoot, "maps"), { recursive: true });
    const ambiguousFile = join(ambiguousRoot, "project.json");
    const ambiguousMapFile = join(ambiguousRoot, "maps/map.json");
    await writeFile(ambiguousFile, JSON.stringify(saved));
    const duplicate = { ...triggers[0], id: "duplicate" };
    await writeFile(ambiguousMapFile, JSON.stringify({ id: "map", name: "Map", version: "v8",
      size: { width: 6, height: 6 }, layers: [], triggers: [...triggers, duplicate, duplicate] }));
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: ambiguousRoot });
    const ambiguousBefore = await readFile(ambiguousFile);
    const ambiguousMapBefore = await readFile(ambiguousMapFile);
    const ambiguousValidation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    const ambiguousId = `ambiguous-${++sequence}`;
    const ambiguousRejected = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
      requestId: ambiguousId, actionId: "event_v2.record_upsert", actionVersion: 1,
      workspaceHandle: workspace.workspaceHandle, expectedRevision: ambiguousValidation.snapshotRevision,
      idempotencyKey: ambiguousId, parameters: { record: event(source("triggerBump", "duplicate")) } } }, true);
    assert.notEqual(ambiguousRejected.domainCode, "worker.internal");
    assert.deepEqual(await readFile(ambiguousFile), ambiguousBefore);
    assert.deepEqual(await readFile(ambiguousMapFile), ambiguousMapBefore);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = undefined;
    const spatialRoot = join(root, "threeD");
    await mkdir(join(spatialRoot, "maps"), { recursive: true });
    const spatialFile = join(spatialRoot, "project.json");
    const spatialMapFile = join(spatialRoot, "maps/map.json");
    const spatialDefinition = record(event(source()).definition);
    delete spatialDefinition.reusePolicy;
    const spatialDraft = { state: "draft", draft: spatialDefinition };
    await writeFile(spatialFile, JSON.stringify({ ...saved, version: "v9", settings: { dimension: "threeD" },
      eventRegistry: { schemaVersion: 1, mode: "v2Only", records: [spatialDraft], legacyClaims: [] } }));
    await writeFile(spatialMapFile, JSON.stringify({ version: "v9", id: "map", name: "Map",
      size: { width: 6, height: 6 }, layers: [], triggers, spatialScene: { schemaVersion: 1, width: 6, depth: 6,
        heightLevels: Array(36).fill(0), levelHeight: 1, instances: [],
        camera: { mode: "fixed", pitchDegrees: 48.7, yawDegrees: 0, fieldOfViewDegrees: 16.2, distance: 42 } } }));
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: spatialRoot });
    const spatialBefore = await readFile(spatialFile);
    const spatialMapBefore = await readFile(spatialMapFile);
    for (const [actionId, parameters] of [
      ["event_v2.record_upsert", { record: event(source()) }],
      ["event_v2.record_upsert", { record: { state: "draft", draft: { ...spatialDefinition, name: "Changed 3D contact" } } }],
      ["event_v2.create_draft", { name: "No 3D contact", rawUuid: "019abcde-0000-7000-8000-000000000003", initialSource: source() }],
      ["event_v2.publish", { eventId }],
    ] as [string, JsonRecord][]) {
      const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
      const id = `spatial-${++sequence}`;
      const rejected = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
        requestId: id, actionId, actionVersion: 1, workspaceHandle: workspace.workspaceHandle,
        expectedRevision: validation.snapshotRevision, idempotencyKey: id, parameters } }, true);
      assert.notEqual(rejected.domainCode, "worker.internal");
      assert.deepEqual(await readFile(spatialFile), spatialBefore);
      assert.deepEqual(await readFile(spatialMapFile), spatialMapBefore);
    }
  } finally {
    if (workspace) await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

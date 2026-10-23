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
function source(kind = "entityAutorun", entityId = "owner", mapId = "map"): JsonRecord {
  return { kind, mapId, entityId };
}
function event(value: JsonRecord): JsonRecord {
  return { state: "configured", enabled: false, definition: { id: eventId, name: "Automatic",
    source: value, conditions: [], sceneId: "hello", reusePolicy: "reusable", priority: 0, order: 0 } };
}

test("live MCP discovers and authors native autorun sources without interaction or legacy substitution", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "native-entity-autorun-mcp-"));
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
  const entities = [
    { id: "owner", kind: "custom", blocksMovement: false },
    { id: "plain-npc", kind: "npc", blocksMovement: false },
    { id: "sign", kind: "sign", blocksMovement: false },
  ].map((value, i) => ({ ...value, pos: { x: i, y: 1 } }));
  await writeFile(mapFile, JSON.stringify({ id: "map", name: "Map", version: "v8", size: { width: 6, height: 6 }, layers: [], entities }));
  const beforeMap = await readFile(mapFile);
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const client = new Client({ name: "native-entity-autorun", version: "1.0.0" });
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
    const id = `autorun-${++sequence}`;
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
    assert.ok(record(resource.extensions).parallelPolicy);
    for (const entry of [resource, ...(description.mutationActions as JsonRecord[]).filter((entry) =>
      ["event_v2.create_draft", "event_v2.record_upsert", "event_v2.publish"].includes(String(entry.id)))]) {
      const variants = record(entry.extensions).sourceVariants as JsonRecord[];
      const bump = variants.find((entry) => entry.kind === "entityAutorun");
      assert.ok(bump);
      assert.deepEqual(bump.requiredFields, ["kind", "mapId", "entityId"]);
      assert.equal(bump.dimension, "twoD");
      assert.equal(bump.entityReference, "knownUniqueLogicalMapEntity");
      assert.ok(variants.some((entry) => entry.kind === "entityInteract"));
    }
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const upsert = await plan("event_v2.record_upsert", { record: event(source()) });
    await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle, planId: upsert.planId, operationId: "apply-autorun" });
    const descriptor = (description.mutationActions as JsonRecord[]).find((entry) => entry.id === "event_v2.record_upsert");
    assert.ok(record(descriptor!.extensions).parallelPolicy);
    const parallel = event(source());
    record(parallel.definition).parallelPolicy = { cadenceMs: 100 };
    const parallelPlan = await plan("event_v2.record_upsert", { record: parallel });
    await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle, planId: parallelPlan.planId, operationId: "apply-parallel" });
    for (const policy of [{ cadenceMs: 99 }, { cadenceMs: 100, ownerVariantId: "missing" }]) {
      record(parallel.definition).parallelPolicy = policy;
      await plan("event_v2.record_upsert", { record: parallel }, true);
    }
    const draft = await plan("event_v2.create_draft", { name: "Automatic draft",
      rawUuid: "019abcde-0000-7000-8000-000000000002", initialSource: source() });
    await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle, planId: draft.planId, operationId: "apply-draft" });
    for (const value of [source("entityAutorun", "missing"), source("entityAutorun", "owner", "missing"),
      { ...source(), entityId: null }, { ...source(), entityId: " owner" }, { ...source(), triggerId: "zone" }, { ...source(), unknown: true }]) {
      const rejected = await plan("event_v2.record_upsert", { record: event(value) }, true);
      assert.match(String(rejected.domainCode), /^event_v2\./);
      assert.notEqual(rejected.domainCode, "worker.internal");
    }
    const saved = record(JSON.parse(await readFile(file, "utf8")));
    const registry = record(saved.eventRegistry);
    const records = registry.records as JsonRecord[];
    assert.deepEqual(record(records.find((entry) => record(entry.definition ?? entry.draft).id === eventId)!.definition).source, source());
    assert.deepEqual(record(records.find((entry) => record(entry.definition ?? entry.draft).id === eventId)!.definition).parallelPolicy, { cadenceMs: 100 });
    assert.deepEqual(record(records.find((entry) => entry.state === "draft")!.draft).source, source());
    assert.deepEqual(registry.legacyClaims, []);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const queried = await call("pokemap_query", { projectHandle: workspace.projectHandle, resourceKind: "eventV2", operation: "list", view: "detail" });
    assert.ok(JSON.stringify(queried).includes('"entityAutorun"'));
    assert.ok(JSON.stringify(queried).includes('"parallelPolicy"'));
    assert.ok(!JSON.stringify(queried).includes('"entityInteract"'));
    assert.deepEqual(await readFile(mapFile), beforeMap);
  } finally {
    if (workspace) await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

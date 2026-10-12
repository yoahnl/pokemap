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

function event(id: string, conditions: JsonRecord[]): JsonRecord {
  return { state: "configured", enabled: false, definition: {
    id, name: "Rencontre au port", source: { kind: "entityInteract", mapId: "port", entityId: "guide" },
    conditions, sceneId: "hello", reusePolicy: "reusable", priority: 0, order: 0,
  } };
}

test("packaged MCP publishes typed Fact events and returns scoped narrative diagnostics", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-typed-event-"));
  const manifestPath = join(root, "project.json");
  const mapPath = join(root, "maps/port.json");
  await mkdir(join(root, "maps"));
  await writeFile(mapPath, JSON.stringify({ id: "port", name: "Port", version: "v8",
    size: { width: 4, height: 4 }, layers: [],
    entities: [{ id: "guide", name: "Guide", kind: "npc", pos: { x: 1, y: 1 } }],
  }));
  await writeFile(manifestPath, JSON.stringify({ name: "Typed Event MCP", version: "v8",
    pokemon: canonicalPokemonConfig(), maps: [{ id: "port", name: "Port", relativePath: "maps/port.json" }],
    tilesets: [], facts: [
      { id: "phase", label: "Phase du port", valueType: "int", defaultValue: 0 },
      { id: "status", label: "État du port", valueType: "string", defaultValue: "fermé" },
    ], scenes: [{ id: "hello", name: "Rencontre", graph: {
      startNodeId: "start", nodes: [{ id: "start", kind: "start" }, { id: "end", kind: "end" }],
      edges: [{ id: "finish", fromNodeId: "start", fromPortId: "completed", toNodeId: "end", kind: "default" }],
    } }], eventRegistry: { schemaVersion: 1, mode: "v2Only", records: [], legacyClaims: [] },
  }));
  const beforeMap = await readFile(mapPath);
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "typed-event-test", version: "1.0.0" });
  let sequence = 0;
  let workspace: JsonRecord | undefined;
  async function call(name: string, parameters: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: parameters });
    assert.equal(result.isError, failure ? true : undefined, JSON.stringify(result.structuredContent));
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, !failure);
    return record(failure ? envelope.error : envelope.data);
  }
  async function plan(value: JsonRecord, failure = false): Promise<JsonRecord> {
    assert.ok(workspace);
    const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    const before = await readFile(manifestPath);
    const requestId = `typed-event-${++sequence}`;
    const planned = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
      requestId, actionId: "event_v2.record_upsert", actionVersion: 1,
      workspaceHandle: workspace.workspaceHandle, parameters: { record: value },
      expectedRevision: validation.snapshotRevision, idempotencyKey: requestId,
    } }, failure);
    assert.deepEqual(await readFile(manifestPath), before);
    assert.deepEqual(await readFile(mapPath), beforeMap);
    return planned;
  }
  try {
    await client.connect(transport);
    const description = await call("pokemap_describe");
    assert.ok((description.mutationActions as JsonRecord[]).some((action) => action.id === "event_v2.record_upsert"));
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const authored = [
      event("evt_00000000-0000-7000-8000-000000000031", [{ kind: "fact", factId: "phase", operator: "greaterThanOrEqual", valueType: "int", expectedValue: 2 }]),
      event("evt_00000000-0000-7000-8000-000000000032", [{ kind: "fact", factId: "status", operator: "equals", valueType: "string", expectedValue: "ouvert" }]),
    ];
    for (const value of authored) {
      const planned = await plan(value);
      const delta = record(record(record(planned.plan).preview).diagnosticDelta);
      for (const key of ["introduced", "resolved", "unchanged"]) assert.ok(Array.isArray(delta[key]));
      const applied = await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle,
        planId: planned.planId, operationId: `typed-event-apply-${sequence}` });
      assert.equal(record(applied.receipt).status, "applied");
    }
    const saved = record(JSON.parse(await readFile(manifestPath, "utf8")));
    assert.deepEqual(record(saved.eventRegistry).records, authored);
    const mismatch = await plan(event("evt_00000000-0000-7000-8000-000000000033", [
      { kind: "fact", factId: "phase", expectedValue: true },
    ]), true);
    assert.equal(mismatch.code, "validation_failed");
    assert.equal(mismatch.domainCode, "event_v2.validation_failed");
    assert.ok(JSON.stringify(mismatch).includes("narrativeEventFactTypeMismatch"));
    assert.ok(!JSON.stringify(mismatch).includes(root));
    const invalid = await plan({ state: "configured", definition: {} }, true);
    assert.equal(invalid.domainCode, "event_v2.record_invalid");
    assert.notEqual(invalid.domainCode, "worker.internal");
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const queried = await call("pokemap_query", { projectHandle: workspace.projectHandle,
      resourceKind: "eventV2", operation: "list", view: "detail" });
    assert.equal((queried.items as JsonRecord[]).length, 2);
    assert.deepEqual(await readFile(mapPath), beforeMap);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

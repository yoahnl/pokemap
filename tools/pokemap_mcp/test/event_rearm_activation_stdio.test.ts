import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { test } from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";

function object(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("MCP refuses activation with a missing rearm outcome without writing", { timeout: 120_000 }, async () => {
  const fixture = object(JSON.parse(await readFile(resolve("../../packages/map_authoring/test/fixtures/event_v2_transport_parity.json"), "utf8")));
  const project = object(fixture.project);
  const eventId = "evt_00000000-0000-7000-8000-000000000081";
  object(project.eventRegistry).records = [{ state: "configured", enabled: false, definition: {
    id: eventId, name: "Réarmement indisponible", source: { kind: "entityInteract", mapId: "port", entityId: "guide" },
    conditions: [], sceneId: "hello", reusePolicy: "oneShot", priority: 0, order: 0,
    resetPolicy: { kind: "onOutcomeReceived", outcome: { producerKind: "scene", producerId: "hello", outcomeId: "missing" } },
  } }];
  const base = process.env.AVELUNE_QA_ROOT ?? join(homedir(), "Library/Caches/AveluneQA/event-rearm-tests");
  await mkdir(base, { recursive: true });
  const root = await mkdtemp(join(base, "mcp-"));
  const manifestPath = join(root, "project.json");
  await writeFile(manifestPath, JSON.stringify(project));
  const maps = fixture.maps as JsonRecord[];
  for (const map of maps) {
    const path = join(root, String(map.relativePath));
    await mkdir(dirname(path), { recursive: true });
    await writeFile(path, JSON.stringify(map.content));
  }
  const before = await readFile(manifestPath);
  const beforeMaps = await Promise.all(maps.map(map => readFile(join(root, String(map.relativePath)))));
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "event-rearm-test", version: "1.0.0" });
  let workspace: JsonRecord | undefined;
  async function call(name: string, parameters: JsonRecord, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: parameters });
    const envelope = object(result.structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify(envelope));
    return object(envelope[failure ? "error" : "data"]);
  }
  try {
    await client.connect(transport);
    const description = await call("pokemap_describe", { actionIds: ["event_v2.activate"], view: "full" });
    assert.ok((description.mutationActions as JsonRecord[]).some(action => action.id === "event_v2.activate"));
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    const rejected = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
      requestId: "rearm-activation", actionId: "event_v2.activate", actionVersion: 1,
      workspaceHandle: workspace.workspaceHandle, expectedRevision: validation.snapshotRevision,
      idempotencyKey: "rearm-activation", parameters: { eventId },
    } }, true);
    assert.equal(rejected.domainCode, "resetOutcomeMissing");
    assert.deepEqual(await readFile(manifestPath), before);
    for (let index = 0; index < maps.length; index++) {
      assert.deepEqual(await readFile(join(root, String(maps[index]!.relativePath))), beforeMaps[index]);
    }
  } finally {
    if (workspace) await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle }).catch(() => undefined);
    await client.close().catch(() => undefined);
    await transport.close().catch(() => undefined);
    await rm(root, { recursive: true, force: true });
  }
});

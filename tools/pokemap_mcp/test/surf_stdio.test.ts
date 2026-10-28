import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { join, resolve } from "node:path";
import test from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";
import { canonicalPokemonConfig } from "./pokemon_fixture.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("Surf crosses fresh MCP preserving content, configuration queries and undo", { timeout: 120_000 }, async () => {
  const qa = "/Users/karim/Library/Caches/AveluneQA/surf-v1/authoring";
  await mkdir(qa, { recursive: true });
  const root = await mkdtemp(join(qa, "surf-mcp-"));
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "surf-test", version: "1.0.0" });
  async function call(name: string, input: JsonRecord, failed = false): Promise<JsonRecord> {
    const envelope = record((await client.callTool({ name, arguments: input })).structuredContent);
    assert.equal(envelope.ok, !failed, JSON.stringify(envelope));
    return record(envelope[failed ? "error" : "data"]);
  }
  try {
    const file = join(root, "project.json");
    await writeFile(file, JSON.stringify({ name: "Adventure", version: "v9", settings: { dimension: "threeD", spatialCamera: { mode: "fixed", projection: "perspective", pitchDegrees: 48.7, yawDegrees: 0, fieldOfViewDegrees: 16.2, distance: 42, orthographicHeight: 12 } }, maps: [], tilesets: [], pokemon: canonicalPokemonConfig(), facts: [{ id: "owned", label: "Device", defaultValue: false }] }));
    await client.connect(transport);
    const catalog = await call("pokemap_describe", {});
    const descriptor = (catalog.mutationActions as JsonRecord[]).find(value => value.id === "surf.configure");
    assert.ok(descriptor);
    assert.deepEqual([...(descriptor.resourceKinds as string[])].sort(), ["project", "surfConfiguration"]);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const query = () => call("pokemap_query", { projectHandle: opened.projectHandle, resourceKind: "surfConfiguration", operation: "get", ids: ["project"], view: "detail" });
    const initial = await query();
    let sequence = 0;
    async function plan(parameters: JsonRecord, revision: unknown = initial.snapshotRevision, failed = false): Promise<JsonRecord> {
      const id = `rename-${++sequence}`;
      return call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
        requestId: id, idempotencyKey: id, workspaceHandle: opened.workspaceHandle,
        actionId: "surf.configure", actionVersion: 1, expectedRevision: revision, parameters,
      } }, failed);
    }
    const before = record(JSON.parse(await readFile(file, "utf8")));
    const original = await readFile(file);
    const configuration = { enabled: true, requiresKnownMove: false, accessMode: "always", speedCellsPerSecond: 4 };
    const planned = await plan({ configuration });
    assert.deepEqual(await readFile(file), original);
    const applied = await call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle, planId: planned.planId, operationId: "rename-apply" });
    assert.deepEqual(JSON.parse(await readFile(file, "utf8")), { ...before, settings: { ...record(before.settings), surf: configuration } });
    const current = await query();
    assert.deepEqual(record((current.items as unknown[])[0]).configuration, configuration);
    await plan({ configuration: { ...configuration, accessMode: "condition" } }, current.snapshotRevision, true);
    await plan({ configuration: null }, initial.snapshotRevision, true);
    await call("pokemap_history", { operation: "undo", projectHandle: opened.projectHandle,
      entryId: record(applied.receipt).receiptId, idempotencyKey: "rename-undo" });
    assert.deepEqual(JSON.parse(await readFile(file, "utf8")), before);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});


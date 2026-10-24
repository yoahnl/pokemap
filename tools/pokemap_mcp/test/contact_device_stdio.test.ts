import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
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

test("contact device crosses fresh MCP preserving content and undo", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "contact-device-mcp-"));
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "contact-device-test", version: "1.0.0" });
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
    const descriptor = (catalog.mutationActions as JsonRecord[]).find(value => value.id === "contact_device.configure");
    assert.ok(descriptor);
    assert.deepEqual([...(descriptor.resourceKinds as string[])].sort(), ["contactDeviceConfiguration", "project"]);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const query = () => call("pokemap_query", { projectHandle: opened.projectHandle, resourceKind: "project", operation: "get", ids: ["project"], view: "detail" });
    const initial = await query();
    const canonicalBefore = { ...record((initial.items as unknown[])[0]) };
    delete canonicalBefore.id;
    delete canonicalBefore.resourceKind;
    let sequence = 0;
    async function plan(parameters: JsonRecord, revision: unknown = initial.snapshotRevision, failed = false): Promise<JsonRecord> {
      const id = `rename-${++sequence}`;
      return call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
        requestId: id, idempotencyKey: id, workspaceHandle: opened.workspaceHandle,
        actionId: "contact_device.configure", actionVersion: 1, expectedRevision: revision, parameters,
      } }, failed);
    }
    const before = record(JSON.parse(await readFile(file, "utf8")));
    const original = await readFile(file);
    const configuration = { id: "device", label: "Carnet", acquiredFactId: "owned", emptyMessage: "Aucun contact.", contacts: [] };
    const planned = await plan({ configuration });
    assert.deepEqual(await readFile(file), original);
    const applied = await call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle, planId: planned.planId, operationId: "rename-apply" });
    assert.deepEqual(JSON.parse(await readFile(file, "utf8")), { ...canonicalBefore, contactDevice: configuration });
    const current = await query();
    await plan({ configuration: { ...configuration, acquiredFactId: "missing" } }, current.snapshotRevision, true);
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


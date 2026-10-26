import assert from "node:assert/strict";
import { test } from "node:test";
import { execFile } from "node:child_process";
import { mkdir, mkdtemp, readFile, rm } from "node:fs/promises";
import { homedir } from "node:os";
import { join, resolve } from "node:path";
import { promisify } from "node:util";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import { InMemoryTransport } from "@modelcontextprotocol/server";

import type { JsonRecord } from "../src/authoring_client.js";
import { MemoryArtifactReader } from "../src/artifacts.js";
import { createPokeMapMcpServer } from "../src/server.js";

test("history maintenance previews by default and rejects unbound application", async () => {
  const calls: Array<{ command: string; args?: JsonRecord }> = [];
  const server = createPokeMapMcpServer({ authoring: {
    async request(command, args) {
      calls.push({ command, ...(args === undefined ? {} : { args }) });
      return { requestId: "retention-preview", data: { fingerprint: "preview" }, artifacts: [] };
    },
    async close() {},
  }, artifacts: new MemoryArtifactReader() });
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "history-maintenance", version: "1.0.0" });
  try {
    await server.connect(serverTransport);
    await client.connect(clientTransport);
    const revision = `sha256:${"a".repeat(64)}`;
    const input = { operation: "maintain", projectHandle: "project:test", expectedRevision: revision };
    const preview = await client.callTool({ name: "pokemap_history", arguments: input });
    assert.equal(preview.isError, undefined, JSON.stringify(preview));
    assert.deepEqual(calls, [{ command: "history_maintenance", args: {
      projectHandle: input.projectHandle, expectedRevision: revision,
      apply: false, maxOperations: 50, maxBytes: 200 * 1024 * 1024,
    } }]);
    for (const invalid of [
      { ...input, apply: true },
      { ...input, apply: "true" },
      { ...input, maxOperations: 51 },
      { ...input, maxBytes: 200 * 1024 * 1024 + 1 },
      { ...input, extra: true },
    ]) {
      await assert.rejects(async () => {
        const response = await client.callTool({ name: "pokemap_history", arguments: invalid });
        if (response.isError) throw new Error("rejected");
      });
      assert.equal(calls.length, 1);
    }
    const applied = await client.callTool({ name: "pokemap_history", arguments: {
      ...input, apply: true, expectedFingerprint: "preview", maxOperations: 1,
    } });
    assert.equal(applied.isError, undefined);
    assert.deepEqual(calls[1], { command: "history_maintenance", args: {
      projectHandle: input.projectHandle, expectedRevision: revision, apply: true,
      expectedFingerprint: "preview", maxOperations: 1, maxBytes: 200 * 1024 * 1024,
    } });
  } finally {
    await client.close();
    await server.close();
  }
});

test("MCP stdio previews and applies canonical history maintenance without changing current project data", { timeout: 120_000 }, async () => {
  const qaRoot = process.env.AVELUNE_QA_ROOT ?? join(homedir(), "Library/Caches/AveluneQA/studio-project-lifecycle");
  await mkdir(qaRoot, { recursive: true });
  const root = await mkdtemp(join(qaRoot, "maintenance-stdio-"));
  const dart = process.env.POKEMAP_TEST_DART ?? "dart";
  const packageRoot = resolve("../../packages/map_authoring");
  const client = new Client({ name: "history-maintenance-stdio", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args: [resolve("dist/src/index.js"), "--root", root, "--dart", dart, "--authoring-timeout-ms", "60000"], cwd: process.cwd(), stderr: "pipe" });
  function record(value: unknown): JsonRecord {
    assert.ok(value && typeof value === "object" && !Array.isArray(value));
    return value as JsonRecord;
  }
  async function call(name: string, args: JsonRecord, failure = false): Promise<JsonRecord> {
    const response = await client.callTool({ name, arguments: args });
    const envelope = record(response.structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify(envelope));
    return record(envelope[failure ? "error" : "data"]);
  }
  try {
    await promisify(execFile)(dart, [`--packages=${join(packageRoot, ".dart_tool/package_config.json")}`, join(packageRoot, "test/support/create_working_catalog_fixture.dart"), root], { timeout: 60_000 });
    await client.connect(transport);
    const described = await call("pokemap_describe", {});
    assert.ok((described.commands as JsonRecord[]).some(command => command.id === "history_maintenance"));
    let opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    await call("pokemap_workshop", { operation: "prepare", projectHandle: opened.projectHandle });
    let revision: unknown;
    let firstPlanId: unknown;
    let firstReceiptId: unknown;
    for (let index = 0; index < 3; index++) {
      const detail = await call("pokemap_query", { projectHandle: opened.projectHandle, resourceKind: "tileset", operation: "get", ids: ["tile-204"], view: "detail" });
      const planned = await call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
        requestId: `maintenance-${index}`, actionId: "catalog.definition.update", actionVersion: 1,
        workspaceHandle: opened.workspaceHandle, expectedRevision: detail.snapshotRevision,
        idempotencyKey: `maintenance-${index}`, parameters: { resourceKind: "tileset", id: "tile-204", name: `Retained ${index}` },
      } });
      const applied = await call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle, planId: planned.planId, operationId: `maintenance-${index}` });
      revision = applied.snapshotRevision;
      if (index === 0) {
        firstPlanId = planned.planId;
        firstReceiptId = record(applied.receipt).receiptId;
      }
    }
    const headBefore = await readFile(join(root, "catalog/HEAD.json"));
    const descriptorBefore = await readFile(join(root, "project.json"));
    const preview = await call("pokemap_history", { operation: "maintain", projectHandle: opened.projectHandle, expectedRevision: revision, maxOperations: 1 });
    assert.equal((preview.retainedEntryIds as unknown[]).length, 1);
    assert.ok((preview.expiredEntryIds as unknown[]).length >= 2);
    assert.deepEqual(await readFile(join(root, "catalog/HEAD.json")), headBefore);
    const mismatch = await call("pokemap_history", { operation: "maintain", projectHandle: opened.projectHandle, expectedRevision: revision, maxOperations: 1, apply: true, expectedFingerprint: "wrong-preview" }, true);
    assert.equal(mismatch.domainCode, "history.retention_stale");
    const result = await call("pokemap_history", { operation: "maintain", projectHandle: opened.projectHandle, expectedRevision: revision, maxOperations: 1, apply: true, expectedFingerprint: preview.fingerprint });
    assert.deepEqual(result.retainedEntryIds, preview.retainedEntryIds);
    assert.ok(Number(result.deletedCatalogObjects) > 0);
    assert.ok(Number(result.deletedHistoryBlobs) > 0);
    assert.deepEqual(await readFile(join(root, "catalog/HEAD.json")), headBefore);
    assert.deepEqual(await readFile(join(root, "project.json")), descriptorBefore);
    const replay = await call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle, planId: firstPlanId, operationId: "maintenance-0" });
    assert.equal(record(replay.receipt).receiptId, firstReceiptId);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
    opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const after = await call("pokemap_query", { projectHandle: opened.projectHandle, resourceKind: "tileset", operation: "get", ids: ["tile-204"], view: "detail" });
    assert.equal(record((after.items as JsonRecord[])[0]).name, "Retained 2");
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

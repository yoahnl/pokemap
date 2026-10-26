import assert from "node:assert/strict";
import { test } from "node:test";
import { execFile } from "node:child_process";
import { createHash } from "node:crypto";
import { lstat, mkdir, mkdtemp, readFile, readdir, realpath, rm, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join, resolve } from "node:path";
import { promisify } from "node:util";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import { InMemoryTransport } from "@modelcontextprotocol/server";

import type { JsonRecord } from "../src/authoring_client.js";
import { MemoryArtifactReader } from "../src/artifacts.js";
import { createPokeMapMcpServer } from "../src/server.js";

async function removeFixtureAdmissions(canonicalRoot: string): Promise<number> {
  const admissions = join(homedir(), ".avelune/authoring/catalog-admissions");
  let removed = 0;
  for (const name of await readdir(admissions).catch(() => [])) {
    if (!/^[a-f0-9]{64}\.json$/.test(name)) continue;
    const path = join(admissions, name);
    const stat = await lstat(path).catch(() => undefined);
    if (!stat?.isFile() || stat.size > 8192) continue;
    const bytes = await readFile(path, "utf8").catch(() => undefined);
    if (bytes === undefined) continue;
    let value: JsonRecord;
    try { value = JSON.parse(bytes) as JsonRecord; } catch { continue; }
    if (!value || typeof value !== "object" || Array.isArray(value)) continue;
    if (value.projectRoot === canonicalRoot || (value.admission as JsonRecord | undefined)?.projectRoot === canonicalRoot) {
      await rm(path);
      removed++;
    }
  }
  return removed;
}

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
    const redone = await client.callTool({ name: "pokemap_history", arguments: {
      operation: "redo", projectHandle: input.projectHandle, entryId: "receipt:original", idempotencyKey: "redo:original",
    } });
    assert.equal(redone.isError, undefined);
    assert.deepEqual(calls[2], { command: "redo", args: {
      projectHandle: input.projectHandle, entryId: "receipt:original", idempotencyKey: "redo:original",
    } });
  } finally {
    await client.close();
    await server.close();
  }
});

test("MCP legacy history converts then survives undo and redo across reopenings", { timeout: 120_000 }, async () => {
  const qaRoot = process.env.AVELUNE_QA_ROOT ?? join(homedir(), "Library/Caches/AveluneQA/studio-project-lifecycle");
  await mkdir(qaRoot, { recursive: true });
  const root = await mkdtemp(join(qaRoot, "legacy-history-mcp-"));
  const canonicalRoot = await realpath(root);
  const evidence = join(qaRoot, "legacy-history-mcp.json");
  const state: JsonRecord = { owner: "retention", projectRoot: root, status: "running", runnerPid: process.pid };
  const dart = process.env.POKEMAP_TEST_DART ?? "dart";
  const packageRoot = resolve("../../packages/map_authoring");
  const client = new Client({ name: "legacy-history-mcp", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--dart", dart, "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe" });
  let opened: JsonRecord | undefined;
  function record(value: unknown): JsonRecord {
    assert.ok(value && typeof value === "object" && !Array.isArray(value));
    return value as JsonRecord;
  }
  async function persist(): Promise<void> { await writeFile(evidence, JSON.stringify(state, null, 2)); }
  async function call(name: string, args: JsonRecord): Promise<JsonRecord> {
    const response = await client.callTool({ name, arguments: args });
    const envelope = record(response.structuredContent);
    assert.equal(envelope.ok, true, `${name}/${String(args.operation)}: ${JSON.stringify(envelope)}`);
    return record(envelope.data);
  }
  async function reopen(): Promise<void> {
    if (opened) await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
    opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
  }
  async function query(): Promise<JsonRecord> {
    return call("pokemap_query", { projectHandle: opened!.projectHandle,
      resourceKind: "tileset", operation: "get", ids: ["tile-204"], view: "detail" });
  }
  try {
    await persist();
    const generated = await promisify(execFile)(dart, [`--packages=${join(packageRoot, ".dart_tool/package_config.json")}`,
      join(packageRoot, "test/support/create_working_catalog_fixture.dart"), root, "--legacy-history"], { timeout: 60_000 });
    assert.notEqual(generated.stdout.trim(), "", "The legacy fixture must report its two original receipts");
    const fixture = record(JSON.parse(generated.stdout));
    state.helperPid = fixture.helperPid;
    const ids = [fixture.first, fixture.second];
    assert.ok(ids.every(id => typeof id === "string"));
    const originalRecords = await Promise.all(ids.map(id => readFile(join(root, ".pokemap/authoring/history-entries", `${String(id)}.json`))));
    await client.connect(transport);
    state.transportPid = transport.pid;
    await persist();
    const described = await call("pokemap_describe", {});
    assert.ok((described.commands as JsonRecord[]).some(command => command.id === "redo"), "Canonical redo must be discoverable");
    await reopen();
    await call("pokemap_workshop", { operation: "prepare", projectHandle: opened!.projectHandle });
    const detail = await query();
    assert.equal(record((detail.items as JsonRecord[])[0]).name, "Legacy second");
    const headBefore = await readFile(join(root, "catalog/HEAD.json"));
    const descriptorBefore = await readFile(join(root, "project.json"));
    const preview = await call("pokemap_history", { operation: "maintain", projectHandle: opened!.projectHandle, expectedRevision: detail.snapshotRevision });
    assert.deepEqual(preview.retainedEntryIds, ids);
    assert.ok((preview.metadataOnlyExpiredEntryIds as unknown[]).length >= 1);
    assert.ok(Object.keys(record(preview.catalogConversions)).length >= 1);
    assert.deepEqual(await readFile(join(root, "catalog/HEAD.json")), headBefore);
    const applied = await call("pokemap_history", { operation: "maintain", projectHandle: opened!.projectHandle,
      expectedRevision: detail.snapshotRevision, apply: true, expectedFingerprint: preview.fingerprint });
    assert.ok(Number(applied.convertedHistoricalGenerations) >= 1);
    assert.deepEqual(applied.retainedEntryIds, ids);
    assert.deepEqual(await readFile(join(root, "catalog/HEAD.json")), headBefore);
    state.convertedHistoricalGenerations = applied.convertedHistoricalGenerations;
    await reopen();
    for (const [operation, index, expectedName] of [
      ["undo", 1, "Legacy first"], ["undo", 0, "Object 204"],
      ["redo", 0, "Legacy first"], ["redo", 1, "Legacy second"],
    ] as const) {
      state.phase = `${operation}-${index}`;
      await persist();
      await call("pokemap_history", { operation, projectHandle: opened!.projectHandle,
        entryId: ids[index], idempotencyKey: `legacy-${operation}-${index}` });
      await reopen();
      assert.equal(record(((await query()).items as JsonRecord[])[0]).name, expectedName);
    }
    assert.deepEqual(await readFile(join(root, "catalog/HEAD.json")), headBefore);
    assert.deepEqual(await readFile(join(root, "project.json")), descriptorBefore);
    assert.equal(await readFile(join(root, "maps/foreign.json"), "utf8"), "foreign map must remain unread");
    state.unrelatedInvalidMapPreserved = true;
    const history = await call("pokemap_history", { operation: "list", projectHandle: opened!.projectHandle, limit: 20 });
    for (const [index, id] of ids.entries()) {
      const original = (history.entries as JsonRecord[]).find(entry => entry.entryId === id);
      assert.deepEqual(record(original).receipt, record(fixture.originalReceipts)[String(id)]);
      assert.deepEqual(await readFile(join(root, ".pokemap/authoring/history-entries", `${String(id)}.json`)), originalRecords[index]);
    }
    for (const raw of Object.values(record(applied.catalogConversions))) {
      const conversion = record(record(raw).conversion);
      const source = record(conversion.source);
      const bytes = await readFile(join(root, "catalog/objects", `${String(source.sha256)}.json`));
      assert.equal(createHash("sha256").update(bytes).digest("hex"), source.sha256);
    }
    state.status = "passed";
    state.undoCount = 2;
    state.redoCount = 2;
  } catch (error) {
    state.status = "failed";
    state.error = String(error);
    throw error;
  } finally {
    if (opened) await client.callTool({ name: "pokemap_workspace", arguments: { operation: "close", workspaceHandle: opened.workspaceHandle } }).catch(() => undefined);
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
    state.removedOwnedAdmissions = await removeFixtureAdmissions(canonicalRoot);
    state.fixtureRemoved = true;
    state.processesClosed = true;
    await persist();
  }
});

test("MCP stdio previews and applies canonical history maintenance without changing current project data", { timeout: 120_000 }, async () => {
  const qaRoot = process.env.AVELUNE_QA_ROOT ?? join(homedir(), "Library/Caches/AveluneQA/studio-project-lifecycle");
  await mkdir(qaRoot, { recursive: true });
  const root = await mkdtemp(join(qaRoot, "maintenance-stdio-"));
  const canonicalRoot = await realpath(root);
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
    await removeFixtureAdmissions(canonicalRoot);
  }
});

import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { access, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { promisify } from "node:util";
import test from "node:test";
import { z } from "zod";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import { InMemoryTransport } from "@modelcontextprotocol/server";
import { createPokeMapMcpServer } from "../src/server.js";
import { MemoryArtifactReader } from "../src/artifacts.js";
import { resourcePackResult, resourcePackToolSchema } from "../src/tools/resource_packs.js";
import type { JsonRecord } from "../src/authoring_client.js";
import { connectPackMcp, controlledPackDart, PackTestGate, packRecord } from "./resource_pack_stdio_support.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}
const run = promisify(execFile);

function comparePublishedShape(published: JsonRecord, validated: JsonRecord): void {
  for (const key of ["type", "additionalProperties", "minLength", "maxLength", "minimum", "maximum", "maxItems", "minItems", "pattern", "const"]) {
    if (published[key] !== undefined) assert.deepEqual(validated[key], published[key], key);
  }
  if (published.required !== undefined) {
    assert.ok(Array.isArray(published.required));
    const required = validated.required === undefined ? [] : validated.required;
    assert.ok(Array.isArray(required));
    assert.deepEqual([...required].sort(), [...published.required].sort());
  }
  if (published.enum) assert.deepEqual(validated.enum, published.enum);
  if (published.properties) {
    const properties = record(published.properties);
    const actual = record(validated.properties);
    assert.deepEqual(Object.keys(actual).sort(), Object.keys(properties).sort());
    for (const key of Object.keys(properties)) comparePublishedShape(record(properties[key]), record(actual[key]));
  }
  if (published.items) comparePublishedShape(record(published.items), record(validated.items));
  if (published.oneOf && !published.properties) {
    const alternatives = (validated.oneOf ?? validated.anyOf) as JsonRecord[];
    assert.equal(alternatives.length, (published.oneOf as unknown[]).length);
    for (const [index, branch] of (published.oneOf as JsonRecord[]).entries()) comparePublishedShape(branch, alternatives[index]!);
  }
}

test("pack MCP full transfer, scoped query and real resources/read", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "p09-mcp-"));
  const packageRoot = resolve("../../packages/map_authoring");
  const transport = new StdioClientTransport({
    command: process.execPath, args: ["dist/src/index.js", "--root", root],
    cwd: process.cwd(), stderr: "pipe",
  });
  const client = new Client({ name: "resource-pack-contract", version: "1.0.0" });
  async function call(name: string, args: JsonRecord = {}, error = false) {
    const response = await client.callTool({ name, arguments: args });
    if (name === "pokemap_resource_pack" || (name === "pokemap_query" && String(args.resourceKind).startsWith("resourcePack"))) {
      assert.ok(Buffer.byteLength(JSON.stringify(response), "utf8") <= 256 * 1024);
    }
    assert.equal(Boolean(response.isError), error, JSON.stringify(response.structuredContent));
    const envelope = record(response.structuredContent);
    return record(error ? envelope.error : envelope.data);
  }
  try {
  await run("dart", ["run", "test/support/resource_pack_transport_fixture.dart", root], { cwd: packageRoot });
    await client.connect(transport);
    const catalog = await call("pokemap_describe");
    const contract = record(catalog.resourcePackTransfer);
    const published = record(contract.inputSchema);
    const validated = z.toJSONSchema(resourcePackToolSchema, { unrepresentable: "any" }) as JsonRecord;
    comparePublishedShape(published, validated);
    assert.equal((published.oneOf as unknown[]).length, 18);
    for (const kind of ["resourcePackJob", "resourcePackInspection", "resourcePackEntry", "resourcePackSelection", "resourcePackPreview"]) {
      assert.ok((catalog.resourceKinds as JsonRecord[]).some((entry) => entry.id === kind), kind);
    }
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: join(root, "target") });
    const projectHandle = opened.projectHandle;
    async function transfer(verb: string, input: JsonRecord = {}, error = false) {
      return call("pokemap_resource_pack", { projectHandle, verb, input }, error);
    }
    async function settle(start: JsonRecord): Promise<JsonRecord> {
      for (let index = 0; index < 3000; index++) {
        const status = await transfer("get", { jobId: start.jobId });
        const snapshot = record(status.snapshot);
        assert.notEqual(snapshot.state, "failed", JSON.stringify(status));
        if (snapshot.state === "succeeded") return record(status.result);
        await new Promise((done) => setTimeout(done, 2));
      }
      throw new Error("Pack job did not finish.");
    }
    const stageStart = await transfer("stage", { sourcePath: join(root, "source.aveluneassets") });
    assert.equal(record(stageStart.snapshot).state, "queued");
    const staged = await settle(stageStart);
    const inspectStart = await transfer("inspect", { archiveHandle: staged.archiveHandle });
    const inspected = await settle(inspectStart);
    const resource = await client.readResource({ uri: inspected.uri as string });
    assert.ok(Buffer.byteLength(JSON.stringify(resource), "utf8") <= 256 * 1024);
    const resourcePage = record(JSON.parse((resource.contents[0] as { text: string }).text));
    assert.equal((resourcePage.items as JsonRecord[])[0]!.inspectionHandle, inspected.inspectionHandle);
    const queried = await call("pokemap_query", { projectHandle, resourceKind: "resourcePackInspection",
      operation: "get", ids: [inspected.inspectionHandle] });
    assert.equal((queried.items as JsonRecord[]).length, 1);
    const selected = await transfer("selection.create", { mode: "archive", inspectionHandle: inspected.inspectionHandle });
    const chosen = await transfer("selection.select_filtered", {
      selectionHandle: selected.selectionHandle, revision: selected.revision, filter: { kind: "element" },
    });
    const validation = await call("pokemap_validate", { projectHandle });
    const prepared = await settle(await transfer("prepare", {
      selectionHandle: chosen.selectionHandle, revision: chosen.revision, expectedRevision: validation.snapshotRevision,
    }));
    const preview = await client.readResource({ uri: prepared.previewUri as string });
    assert.ok(preview.contents.length > 0);
    const planned = await call("pokemap_plan", { projectHandle, request: {
      requestId: "pack-plan", actionId: "resource_pack.import", actionVersion: 1,
      workspaceHandle: opened.workspaceHandle, expectedRevision: validation.snapshotRevision,
      parameters: { preparedImportHandle: prepared.preparedImportHandle }, idempotencyKey: "pack-import",
    } });
    const applied = await settle(await transfer("start_apply", { planId: planned.planId, operationId: "pack-operation" }));
    assert.equal(record(applied.receipt).status, "applied");
    const replayed = await settle(await transfer("start_apply", { planId: planned.planId, operationId: "pack-operation" }));
    assert.equal(record(replayed.receipt).receiptId, record(applied.receipt).receiptId);
    await transfer("cancel", { jobId: stageStart.jobId }, true);
    const other = await call("pokemap_workspace", { operation: "open", projectRoot: join(root, "target") });
    await call("pokemap_resource_pack", { projectHandle: other.projectHandle, verb: "get", input: { jobId: stageStart.jobId } }, true);
    const invalid = await client.callTool({ name: "pokemap_resource_pack", arguments: {
      projectHandle, verb: "stage", input: { sourcePath: "/outside", inlineArchive: "forbidden" },
    } });
    assert.equal(invalid.isError, true);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: other.workspaceHandle });
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

test("real MCP paginates selection and canonical history across reconstruction", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "p09-mcp-lifecycle-"));
  let connection: Awaited<ReturnType<typeof connectPackMcp>> | undefined;
  try {
    await run("dart", ["run", "test/support/resource_pack_transport_fixture.dart", root], { cwd: resolve("../../packages/map_authoring") });
    connection = await connectPackMcp(root);
    let opened = await connection.call("pokemap_workspace", { operation: "open", projectRoot: join(root, "target") });
    const plan = await connection.plan(opened, "lifecycle-import");
    const inspected = packRecord(plan.inspection);
    const selection = packRecord(plan.selection);
    const first = await connection.pack(opened, "entries", { inspectionHandle: inspected.inspectionHandle, limit: 1 });
    let page = first;
    const seen = new Set<string>();
    let pages = 0;
    while (true) {
      pages++;
      assert.equal(page.returned, 1);
      for (const row of page.items as JsonRecord[]) {
        const key = JSON.stringify([row.kind, row.id]);
        assert.equal(seen.has(key), false);
        seen.add(key);
      }
      if (!page.nextCursor) break;
      page = await connection.pack(opened, "entries", { inspectionHandle: inspected.inspectionHandle, limit: 1, cursor: page.nextCursor });
    }
    assert.ok(pages > 1);
    assert.equal(seen.size, first.totalAvailable);
    await connection.pack(opened, "entries", { inspectionHandle: inspected.inspectionHandle, cursor: first.nextCursor,
      filter: { kind: "model3d" } }, "resource_pack.cursor_invalid");
    const hidden = await connection.pack(opened, "entries", { selectionHandle: selection.selectionHandle, filter: { kind: "model3d" } });
    assert.ok((hidden.items as JsonRecord[]).every((row) => row.selected === false));
    const selectedPage = await connection.call("pokemap_query", { projectHandle: opened.projectHandle, resourceKind: "resourcePackEntry",
      operation: "get", ids: [selection.selectionHandle], filters: { selected: true }, pageSize: 1 });
    assert.equal(selectedPage.totalAvailable, selection.selectedCount);
    const resource = await connection.client.readResource({ uri: inspected.entriesUri as string });
    assert.ok(Buffer.byteLength(JSON.stringify({ jsonrpc: "2.0", id: "x".repeat(128), result: resource }), "utf8") <= 256 * 1024);
    await connection.call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle, planId: plan.planId,
      operationId: "lifecycle-operation" }, "resource_pack.job_required");
    const start = await connection.pack(opened, "start_apply", { planId: plan.planId, operationId: "lifecycle-operation" });
    const applied = await connection.result(opened, start);
    const receipt = packRecord(applied.receipt);
    for (const [kind, handle] of [
      ["resourcePackInspection", inspected.inspectionHandle], ["resourcePackSelection", selection.selectionHandle],
      ["resourcePackEntry", selection.selectionHandle], ["resourcePackPreview", packRecord(plan.prepared).previewHandle],
      ["resourcePackJob", start.jobId],
    ]) {
      await connection.call("pokemap_query", { projectHandle: opened.projectHandle, resourceKind: kind, operation: "list" }, "resource_pack.query_invalid");
      const owned = await connection.call("pokemap_query", { projectHandle: opened.projectHandle, resourceKind: kind, operation: "get", ids: [handle] });
      assert.ok((owned.items as unknown[]).length > 0);
    }
    for (const uri of [inspected.uri, inspected.entriesUri, selection.uri, packRecord(plan.prepared).previewUri, start.uri]) {
      const read = await connection.client.readResource({ uri: uri as string });
      assert.ok(Buffer.byteLength(JSON.stringify({ jsonrpc: "2.0", id: "x".repeat(128), result: read }), "utf8") <= 256 * 1024);
      assert.ok((packRecord(JSON.parse((read.contents[0] as { text: string }).text)).items as unknown[]).length > 0);
    }

    const cancel = await connection.pack(opened, "cancel", { jobId: start.jobId }, "resource_pack.cancel_not_allowed");
    assert.equal(packRecord(cancel.details).cancelAllowed, false);
    const undone = await connection.history(opened, "undo", receipt.receiptId, "lifecycle-undo");
    const redone = await connection.history(opened, "redo", receipt.receiptId, "lifecycle-redo");
    const reverted = await connection.history(opened, "revert", packRecord(undone.receipt).receiptId, "lifecycle-revert", packRecord(redone.receipt).receiptId);
    assert.equal(packRecord(reverted.receipt).actionId, "history.revert");
    await connection.call("pokemap_history", { operation: "undo", projectHandle: opened.projectHandle, entryId: receipt.receiptId,
      idempotencyKey: "legacy-history" }, "resource_pack.job_required");
    await connection.call("pokemap_recovery", { projectHandle: opened.projectHandle, operationId: "lifecycle-operation",
      confirmation: "RECOVER lifecycle-operation" }, "resource_pack.job_required");
    const recovered = await connection.result(opened, await connection.pack(opened, "start_recovery", { operationId: "lifecycle-operation" }));
    assert.equal(packRecord(recovered.receipt).receiptId, receipt.receiptId);
    await connection.close();
    connection = await connectPackMcp(root);
    opened = await connection.call("pokemap_workspace", { operation: "open", projectRoot: join(root, "target") });
    await connection.pack(opened, "get", { jobId: start.jobId }, "resource_pack.job_unknown");
    await connection.pack(opened, "entries", { inspectionHandle: inspected.inspectionHandle }, "resource_pack.handle_unknown");
    const replay = await connection.result(opened, await connection.pack(opened, "start_apply", { planId: plan.planId, operationId: "lifecycle-operation" }));
    assert.equal(packRecord(replay.receipt).receiptId, receipt.receiptId);
    const undoReplay = await connection.result(opened, await connection.pack(opened, "start_history", { operation: "undo",
      entryId: receipt.receiptId, operationId: "lifecycle-undo", expectedRevision: "sha256:" + "0".repeat(64) }));
    assert.equal(packRecord(undoReplay.receipt).receiptId, packRecord(undone.receipt).receiptId);
  } finally { await connection?.close(); await rm(root, { recursive: true, force: true }); }
});

for (const reserved of [false, true]) {
  test(`controlled real MCP cancellation ${reserved ? "after" : "before"} canonical reservation`, { timeout: 120_000 }, async () => {
    const root = await mkdtemp(join(tmpdir(), "p09-mcp-barrier-"));
    let connection: Awaited<ReturnType<typeof connectPackMcp>> | undefined;
    const gate = new PackTestGate(root);
    try {
      await run("dart", ["run", "test/support/resource_pack_transport_fixture.dart", root], { cwd: resolve("../../packages/map_authoring") });
      connection = await connectPackMcp(root, await controlledPackDart(root));
      const opened = await connection.call("pokemap_workspace", { operation: "open", projectRoot: join(root, "target") });
      const plan = await connection.plan(opened, "barrier-import");
      const before = await readFile(join(root, "target", "project.json"));
      await gate.arm("reservation", "barrier-operation", reserved ? "afterReservation" : "afterJournalStaged");
      const start = await connection.pack(opened, "start_apply", { planId: plan.planId, operationId: "barrier-operation" });
      await gate.entered("reservation");
      const status = await connection.pack(opened, "get", { jobId: start.jobId });
      assert.equal(packRecord(status.snapshot).state, "running");
      assert.equal(status.cancelAllowed, !reserved);
      const events = await connection.pack(opened, "events", { jobId: start.jobId, afterSequence: 0 });
      assert.ok((events.events as unknown[]).length > 1);
      if (reserved) {
        const denied = await connection.pack(opened, "cancel", { jobId: start.jobId }, "resource_pack.cancel_not_allowed");
        assert.equal(packRecord(denied.details).cancelAllowed, false);
        assert.equal(packRecord(denied.details).phase, "finalizing");
      } else {
        const accepted = await connection.pack(opened, "cancel", { jobId: start.jobId });
        assert.equal(accepted.state, "cancelling");
        assert.equal(accepted.bounded, false);
      }
      await gate.release("reservation");
      const terminal = await connection.poll(opened, start);
      assert.equal(packRecord(terminal.snapshot).state, reserved ? "succeeded" : "cancelled", JSON.stringify(terminal));
      if (reserved) assert.equal(packRecord(packRecord(terminal.result).receipt).status, "applied");
      else {
        assert.equal(terminal.result, undefined);
        assert.deepEqual(await readFile(join(root, "target", "project.json")), before);
      }
      assert.equal((await connection.pack(opened, "recovery_status")).recoveryRequired, false);
    } finally { await gate.release("reservation"); await connection?.close(); await rm(root, { recursive: true, force: true }); }
  });
}

test("controlled real MCP late failure reconstructs permission-checked recovery and durable replay", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "p09-mcp-recovery-"));
  let connection: Awaited<ReturnType<typeof connectPackMcp>> | undefined;
  const gate = new PackTestGate(root);
  try {
    await run("dart", ["run", "test/support/resource_pack_transport_fixture.dart", root], { cwd: resolve("../../packages/map_authoring") });
    const dart = await controlledPackDart(root);
    connection = await connectPackMcp(root, dart);
    let opened = await connection.call("pokemap_workspace", { operation: "open", projectRoot: join(root, "target") });
    const plan = await connection.plan(opened, "fault-import");
    await gate.arm("fault", "fault-operation", "afterResourcePromoted", true);
    const start = await connection.pack(opened, "start_apply", { planId: plan.planId, operationId: "fault-operation" });
    await gate.entered("fault");
    assert.equal((await connection.pack(opened, "get", { jobId: start.jobId })).cancelAllowed, false);
    await gate.release("fault");
    const failed = await connection.poll(opened, start);
    assert.equal(packRecord(failed.snapshot).state, "failed");
    assert.equal(failed.phase, "recoveryRequired");
    await connection.close();
    await writeFile(join(gate.directory, "readonly"), "readonly");
    connection = await connectPackMcp(root, dart);
    opened = await connection.call("pokemap_workspace", { operation: "open", projectRoot: join(root, "target") });
    assert.equal(opened.readOnly, true);
    assert.equal((await connection.pack(opened, "recovery_status")).recoveryRequired, true);
    const denied = await connection.poll(opened, await connection.pack(opened, "start_recovery", { operationId: "fault-operation" }));
    assert.equal(packRecord(denied.snapshot).errorCode, "authorization.permission_denied");
    await connection.close();
    await rm(join(gate.directory, "readonly"));
    connection = await connectPackMcp(root, dart);
    opened = await connection.call("pokemap_workspace", { operation: "open", projectRoot: join(root, "target") });
    await connection.call("pokemap_recovery", { projectHandle: opened.projectHandle, operationId: "fault-operation",
      confirmation: "RECOVER fault-operation" }, "resource_pack.job_required");
    const recovered = await connection.result(opened, await connection.pack(opened, "start_recovery", { operationId: "fault-operation" }));
    assert.equal((await connection.pack(opened, "recovery_status")).recoveryRequired, false);
    await gate.arm("no-promotion", "fault-operation", "afterResourcePromoted", true);
    const replay = await connection.result(opened, await connection.pack(opened, "start_apply", { planId: plan.planId, operationId: "fault-operation" }));
    assert.equal(packRecord(replay.receipt).receiptId, packRecord(recovered.receipt).receiptId);
    await assert.rejects(access(join(gate.directory, "entered-no-promotion")));
  } finally { await gate.release("fault"); await gate.release("no-promotion"); await connection?.close(); await rm(root, { recursive: true, force: true }); }
});

test("a maximum payload chunk is bounded in the complete MCP envelope", async () => {
  const response = await resourcePackResult(async () => ({
    requestId: "chunk", data: { bytesBase64: Buffer.alloc(128 * 1024).toString("base64"),
      offset: 0, totalBytes: 128 * 1024, rawSha256: "a".repeat(64) }, artifacts: [],
  }));
  assert.ok(Buffer.byteLength(JSON.stringify({ jsonrpc: "2.0", id: "x".repeat(128), result: response }), "utf8") <= 256 * 1024);
  assert.ok(response.content[0]!.text.length < 100);
});

test("strict transfer schema rejects giant patches before the gateway", async () => {
  let calls = 0;
  const server = createPokeMapMcpServer({
    authoring: { async request() { calls++; return { requestId: "r", data: {}, artifacts: [] }; }, async close() {} },
    artifacts: new MemoryArtifactReader(),
  });
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "pack-schema", version: "1.0" });
  await server.connect(serverTransport);
  await client.connect(clientTransport);
  try {
    const result = await client.callTool({ name: "pokemap_resource_pack", arguments: {
      projectHandle: "project", verb: "selection.patch", input: {
        selectionHandle: "selection", revision: "sha256:" + "0".repeat(64),
        add: Array.from({ length: 201 }, (_, i) => ({ kind: "element", id: String(i) })),
      },
    } });
    assert.equal(result.isError, true);
    assert.equal(calls, 0);
  } finally { await client.close(); await server.close(); }
});

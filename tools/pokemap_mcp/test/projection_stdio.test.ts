import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import { InMemoryTransport } from "@modelcontextprotocol/server";
import type { AuthoringGateway, JsonRecord } from "../src/authoring_client.js";
import { MemoryArtifactReader } from "../src/artifacts.js";
import { createPokeMapMcpServer } from "../src/server.js";
import { canonicalPokemonConfig } from "./pokemon_fixture.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("L20 MCP bounds a nearly full diff page using the actual escaped RPC identifier", async () => {
  const rows: JsonRecord[] = Array.from({ length: 9 }, (_, index) => ({
    operation: "replace", path: `/entries/${index}`, before: index < 8 ? "界".repeat(10_000) : "",
  }));
  const shape = (entries: JsonRecord[], startIndex = 0): JsonRecord => ({
    diffRef: "diff_scope", fullDiffFingerprint: "stable-fingerprint", totalRows: rows.length,
    startIndex, entries,
    ...(startIndex + entries.length < rows.length ? { nextCursor: `cursor_${startIndex + entries.length}` } : {}),
  });
  const padding = 256 * 1024 - 4096 - Buffer.byteLength(JSON.stringify(shape(rows)), "utf8");
  assert.ok(padding > 0 && padding < 32 * 1024);
  rows[8]!.before = "a".repeat(padding);
  assert.equal(Buffer.byteLength(JSON.stringify(shape(rows)), "utf8"), 256 * 1024 - 4096);
  const calls: JsonRecord[] = [];
  const gateway: AuthoringGateway = {
    async request(command, input = {}) {
      assert.equal(command, "projection");
      calls.push(input);
      const start = input.cursor ? Number(String(input.cursor).slice("cursor_".length)) : 0;
      const limit = Number(input.limit ?? 200);
      return { requestId: "projection", data: shape(rows.slice(start, start + limit), start), artifacts: [] };
    },
    async close() {},
  };
  const server = createPokeMapMcpServer({ authoring: gateway, artifacts: new MemoryArtifactReader() });
  const [left, right] = InMemoryTransport.createLinkedPair();
  const rpcId = "\u0000".repeat(20_000);
  const wireBytes: number[] = [];
  let clientRequestId: string | number = 0;
  const sendRequest = left.send.bind(left);
  left.send = async (message, options) => {
    if ("method" in message && message.method === "tools/call" && "id" in message) {
      clientRequestId = message.id;
      return sendRequest({ ...message, id: rpcId }, options);
    }
    return sendRequest(message, options);
  };
  const sendResponse = right.send.bind(right);
  right.send = async (message, options) => {
    if ("id" in message && message.id === rpcId) {
      wireBytes.push(Buffer.byteLength(JSON.stringify(message), "utf8") + 1);
      return sendResponse({ ...message, id: clientRequestId }, options);
    }
    return sendResponse(message, options);
  };
  const client = new Client({ name: "l20-envelope", version: "1.0.0" });
  await server.connect(right);
  await client.connect(left);
  try {
    const entries: unknown[] = [];
    let cursor: unknown;
    do {
      const response = await client.callTool({ name: "pokemap_projection", arguments: {
        operation: "diff", projectHandle: "project_scope", diffRef: "diff_scope", limit: 200,
        ...(cursor ? { cursor } : {}),
      } });
      assert.ok(wireBytes.at(-1)! <= 256 * 1024);
      const envelope = record(response.structuredContent);
      assert.equal(envelope.ok, true);
      const data = record(envelope.data);
      assert.equal(data.startIndex, entries.length);
      assert.equal(data.fullDiffFingerprint, "stable-fingerprint");
      assert.ok((data.entries as unknown[]).length > 0);
      entries.push(...data.entries as unknown[]);
      cursor = data.nextCursor;
    } while (cursor);
    assert.deepEqual(entries, rows);
    assert.ok(wireBytes.length > 1);
    assert.ok(calls.some(call => Number(call.limit) < 200));
    assert.ok(calls.length <= 10);
  } finally {
    await client.close();
    await server.close();
  }
});

test("L20 MCP refuses an RPC identifier that consumes the success budget before reading", async () => {
  let reads = 0;
  const gateway: AuthoringGateway = {
    async request() {
      reads += 1;
      return { requestId: "projection", data: {}, artifacts: [] };
    },
    async close() {},
  };
  const server = createPokeMapMcpServer({ authoring: gateway, artifacts: new MemoryArtifactReader() });
  const [left, right] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "l20-oversized-id", version: "1.0.0" });
  const rpcId = "\u0000".repeat(44_000);
  let clientRequestId: string | number = 0;
  const sendRequest = left.send.bind(left);
  left.send = async (message, options) => {
    if ("method" in message && message.method === "tools/call" && "id" in message) {
      clientRequestId = message.id;
      return sendRequest({ ...message, id: rpcId }, options);
    }
    return sendRequest(message, options);
  };
  const sendResponse = right.send.bind(right);
  right.send = async (message, options) => sendResponse(
    "id" in message && message.id === rpcId ? { ...message, id: clientRequestId } : message,
    options,
  );
  await server.connect(right);
  await client.connect(left);
  try {
    const response = await client.callTool({ name: "pokemap_projection", arguments: {
      operation: "receipt", projectHandle: "project_scope", receiptId: "receipt_scope",
    } });
    const envelope = record(response.structuredContent);
    assert.equal(envelope.ok, false);
    assert.equal(record(envelope.error).code, "resource_limit");
    assert.equal(reads, 0);
    assert.ok(Buffer.byteLength(JSON.stringify(response), "utf8") < 1024);
  } finally {
    await client.close();
    await server.close();
  }
});

test("L20 reads bounded immutable projections through real MCP sessions", { timeout: 180_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "l20-projection-"));
  const firstRoot = join(root, "first");
  const secondRoot = join(root, "second");
  const description = `Before ${'é界😀"\\\n'.repeat(30_000)} after`;
  const fact = { id: "fact_archive", label: "Archive", description, defaultValue: false };
  for (const projectRoot of [firstRoot, secondRoot]) {
    await mkdir(projectRoot);
    await writeFile(join(projectRoot, "project.json"), JSON.stringify({
      name: "Projection fixture", version: "v8", pokemon: canonicalPokemonConfig(),
      maps: [], tilesets: [], facts: [fact],
    }));
  }
  const file = join(firstRoot, "project.json");
  const before = await readFile(file);
  let client: Client | undefined;
  let sequence = 0;
  async function connect(): Promise<void> {
    const args = [resolve(process.env.POKEMAP_TEST_MCP_ENTRY ?? "dist/src/index.js"),
      "--root", root, "--authoring-timeout-ms", "60000"];
    if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
    if (process.env.POKEMAP_TEST_AUTHORING_PACKAGE) args.push("--authoring-package", process.env.POKEMAP_TEST_AUTHORING_PACKAGE);
    client = new Client({ name: "l20-projection", version: "1.0.0" });
    await client.connect(new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" }));
  }
  async function call(name: string, input: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    assert.ok(client);
    const response = await client.callTool({ name, arguments: input });
    if (name === "pokemap_projection") {
      const bytes = Buffer.byteLength(JSON.stringify({ jsonrpc: "2.0", id: "x".repeat(128), result: response }), "utf8");
      assert.ok(bytes <= 256 * 1024, `Projection wire envelope: ${bytes}`);
    }
    const envelope = record(response.structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify({ name, envelope }));
    assert.ok(!JSON.stringify(envelope).includes(root));
    return record(envelope[failure ? "error" : "data"]);
  }
  async function prepare(workspace: JsonRecord, actionId: string, parameters: JsonRecord): Promise<JsonRecord> {
    const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    const id = `projection-${++sequence}`;
    return call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
      requestId: id, actionId, actionVersion: 1, workspaceHandle: workspace.workspaceHandle,
      parameters, expectedRevision: validation.snapshotRevision, idempotencyKey: id,
    } });
  }
  async function page(workspace: JsonRecord, diffRef: unknown): Promise<JsonRecord> {
    return call("pokemap_projection", { operation: "diff", projectHandle: workspace.projectHandle, diffRef, limit: 1 });
  }
  try {
    await connect();
    assert.ok(client);
    const tools = await client.listTools();
    const projection = tools.tools.find(tool => tool.name === "pokemap_projection");
    assert.ok(projection, "The projection tool must be discoverable.");
    assert.equal(projection.annotations?.readOnlyHint, true);
    assert.equal(projection.annotations?.destructiveHint, false);
    const catalog = await call("pokemap_describe");
    assert.ok((catalog.commands as JsonRecord[]).some(command => command.id === "projection"));
    let workspace = await call("pokemap_workspace", { operation: "open", projectRoot: firstRoot });
    const other = await call("pokemap_workspace", { operation: "open", projectRoot: secondRoot });
    const prepared = await prepare(workspace, "fact.delete", { factId: fact.id });
    const plannedReceipt = record(prepared.receipt);
    const diff = record(plannedReceipt.diff);
    assert.equal(typeof diff.diffRef, "string");
    const original = await page(workspace, diff.diffRef);
    assert.equal(original.fullDiffFingerprint, diff.fullDiffFingerprint);
    assert.equal(original.totalRows, 1);
    const row = record((original.entries as unknown[])[0]);
    const payload = record(row.before);
    assert.equal(payload.projectionType, "jsonPayload");
    assert.ok(Number(payload.byteLength) > 256 * 1024);
    const chunks: Buffer[] = [];
    let offset = 0;
    while (offset < Number(payload.byteLength)) {
      const chunk = await call("pokemap_projection", { operation: "payload", projectHandle: workspace.projectHandle,
        payloadRef: payload.payloadRef, offset, byteLength: 128 * 1024 });
      const bytes = Buffer.from(String(chunk.bytesBase64), "base64");
      assert.ok(bytes.length > 0 && bytes.length <= 128 * 1024);
      assert.equal(chunk.offset, offset);
      assert.equal(chunk.nextOffset, offset + bytes.length);
      assert.equal(chunk.totalBytes, payload.byteLength);
      assert.equal(chunk.rawSha256, payload.rawSha256);
      chunks.push(bytes);
      offset = Number(chunk.nextOffset);
      assert.equal(chunk.complete, offset === payload.byteLength);
    }
    const reconstructed = Buffer.concat(chunks);
    assert.equal(createHash("sha256").update(reconstructed).digest("hex"), payload.rawSha256);
    assert.equal(record(JSON.parse(reconstructed.toString("utf8"))).description, description);
    assert.deepEqual(await readFile(file), before);
    const wrongScope = await call("pokemap_projection", { operation: "diff", projectHandle: other.projectHandle,
      diffRef: diff.diffRef }, true);
    assert.ok(String(wrongScope.domainCode).startsWith("projection."));
    for (const input of [
      { operation: "diff", projectHandle: workspace.projectHandle, diffRef: diff.diffRef, limit: 201 },
      { operation: "payload", projectHandle: workspace.projectHandle, payloadRef: payload.payloadRef, offset: -1 },
      { operation: "payload", projectHandle: workspace.projectHandle, payloadRef: payload.payloadRef, offset: 0, byteLength: 131073 },
      { operation: "receipt", projectHandle: workspace.projectHandle, receiptId: "missing", payloadRef: payload.payloadRef },
    ]) {
      const invalid = await client.callTool({ name: "pokemap_projection", arguments: input });
      assert.equal(invalid.isError, true);
      assert.deepEqual(await readFile(file), before);
    }
    const applyInput = { operation: "apply", projectHandle: workspace.projectHandle, planId: prepared.planId,
      operationId: "l20-delete-archive" };
    const unconfirmed = await call("pokemap_apply", applyInput, true);
    assert.ok(String(unconfirmed.domainCode).includes("confirmation"));
    assert.deepEqual(await readFile(file), before);
    const confirmed = await call("pokemap_apply", { operation: "confirm", projectHandle: workspace.projectHandle,
      planId: prepared.planId });
    assert.equal((await page(workspace, diff.diffRef)).fullDiffFingerprint, original.fullDiffFingerprint);
    const applied = await call("pokemap_apply", { ...applyInput, confirmationToken: confirmed.confirmationToken });
    const receiptId = record(applied.receipt).receiptId;
    const saved = await readFile(file);
    assert.deepEqual(record(JSON.parse(saved.toString())).facts, []);
    const replay = await call("pokemap_apply", { ...applyInput, confirmationToken: confirmed.confirmationToken });
    assert.equal(record(replay.receipt).receiptId, receiptId);
    assert.deepEqual(await readFile(file), saved);
    const historical = await call("pokemap_projection", { operation: "receipt", projectHandle: workspace.projectHandle, receiptId });
    const historicalDiff = record(record(historical.receipt).diff);
    const later = await prepare(workspace, "fact.create", { fact: { id: "fact_later", label: "Later", defaultValue: false } });
    await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle, planId: later.planId,
      operationId: "l20-create-later" });
    assert.equal((await page(workspace, historicalDiff.diffRef)).fullDiffFingerprint, original.fullDiffFingerprint);
    const afterMutation = await call("pokemap_projection", { operation: "receipt", projectHandle: workspace.projectHandle, receiptId });
    assert.equal(record(record(afterMutation.receipt).diff).fullDiffFingerprint, original.fullDiffFingerprint);
    const oldProject = workspace.projectHandle;
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    await client.close();
    client = undefined;
    await connect();
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: firstRoot });
    await call("pokemap_projection", { operation: "receipt", projectHandle: oldProject, receiptId }, true);
    await call("pokemap_projection", { operation: "diff", projectHandle: workspace.projectHandle,
      diffRef: historicalDiff.diffRef }, true);
    const refreshed = await call("pokemap_projection", { operation: "receipt", projectHandle: workspace.projectHandle, receiptId });
    const refreshedDiff = record(record(refreshed.receipt).diff);
    assert.notEqual(refreshedDiff.diffRef, historicalDiff.diffRef);
    assert.equal((await page(workspace, refreshedDiff.diffRef)).fullDiffFingerprint, original.fullDiffFingerprint);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
  } finally {
    await client?.close();
    await rm(root, { recursive: true, force: true });
  }
});

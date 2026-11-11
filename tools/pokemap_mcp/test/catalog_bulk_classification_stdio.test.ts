import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { mkdir, mkdtemp, readFile, rm } from "node:fs/promises";
import { homedir } from "node:os";
import { join, resolve } from "node:path";
import { promisify } from "node:util";
import test from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("live MCP persists a thousand classifications in one undoable operation", { timeout: 180_000 }, async () => {
  const base = join(homedir(), "Library/Caches/AveluneQA/hgss-library-dedup/mcp-tests");
  await mkdir(base, { recursive: true });
  const root = await mkdtemp(join(base, "bulk-"));
  const packageRoot = resolve("../../packages/map_authoring");
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "120000"],
    cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "bulk-classification", version: "1.0.0" });
  async function call(name: string, args: JsonRecord): Promise<JsonRecord> {
    const response = record((await client.callTool({ name, arguments: args }, { timeout: 120_000 })).structuredContent);
    assert.equal(response.ok, true, JSON.stringify(response));
    return record(response.data);
  }
  try {
    await promisify(execFile)(process.env.POKEMAP_TEST_DART ?? "dart", [
      `--packages=${join(packageRoot, ".dart_tool/package_config.json")}`,
      join(packageRoot, "test/support/create_bulk_model_fixture.dart"), root,
    ], { timeout: 90_000 });
    const map = await readFile(join(root, "maps/field.json"));
    const descriptor = await readFile(join(root, "project.json"));
    await client.connect(transport);
    const description = await call("pokemap_describe", { actionIds: ["resource.classify_batch"], domain: "assets", view: "full" });
    const action = record((description.mutationActions as unknown[])[0]);
    const schema = record(record(action.extensions).inputSchema);
    assert.equal(record(record(schema.properties).entries).maxItems, 1000);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const parameters = { entries: Array.from({ length: 1000 }, (_, index) => ({
      resourceKind: "model3d", resourceId: `model-${index}`, familyId: "relief" })) };
    const scoped = await call("pokemap_workshop", { operation: "read", projectHandle: opened.projectHandle,
      actionId: "resource.classify_batch", parameters, includeDocuments: false });
    const planned = await call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
      requestId: "bulk-classify", actionId: "resource.classify_batch", actionVersion: 1,
      workspaceHandle: opened.workspaceHandle, expectedRevision: scoped.snapshotRevision,
      idempotencyKey: "bulk-classify", parameters, extensions: scoped.planExtensions } });
    const applied = await call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle,
      planId: planned.planId, operationId: "bulk-classify" });
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
    const reopened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const query = await call("pokemap_query", { projectHandle: reopened.projectHandle, operation: "batch_get",
      resourceKind: "model3d", ids: ["model-0", "model-499", "model-999", "model-1000"], view: "summary" });
    const models = new Map((query.items as JsonRecord[]).map(model => [model.id, model.familyId]));
    for (const id of ["model-0", "model-499", "model-999"]) assert.equal(models.get(id), "relief");
    assert.equal(models.get("model-1000"), null);
    await call("pokemap_history", { operation: "undo", projectHandle: reopened.projectHandle,
      entryId: record(applied.receipt).receiptId, idempotencyKey: "undo-bulk-classify" });
    const restored = await call("pokemap_query", { projectHandle: reopened.projectHandle, operation: "get",
      resourceKind: "model3d", ids: ["model-499"], view: "summary" });
    assert.equal((restored.items as JsonRecord[])[0]?.familyId, null);
    assert.deepEqual(await readFile(join(root, "maps/field.json")), map);
    assert.deepEqual(await readFile(join(root, "project.json")), descriptor);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: reopened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

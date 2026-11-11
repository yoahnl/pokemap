import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { access, mkdir, mkdtemp, readFile, rm } from "node:fs/promises";
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

test("fresh MCP audits and prunes unused models with confirmation and undo", { timeout: 120_000 }, async () => {
  const base = join(homedir(), "Library/Caches/AveluneQA/catalog-model-delete");
  await mkdir(base, { recursive: true });
  const root = await mkdtemp(join(base, "mcp-"));
  const packageRoot = resolve("../../packages/map_authoring");
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "model-prune-proof", version: "1.0.0" });
  async function call(name: string, args: JsonRecord): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: args });
    assert.equal(result.isError, undefined, JSON.stringify(result.structuredContent));
    return record(record(result.structuredContent).data);
  }
  try {
    await promisify(execFile)(process.env.POKEMAP_TEST_DART ?? "dart", [
      `--packages=${join(packageRoot, ".dart_tool/package_config.json")}`,
      join(packageRoot, "test/support/create_duplicate_model_fixture.dart"), root,
    ], { timeout: 60_000 });
    const beforeMap = await readFile(join(root, "maps/field.json"));
    const source = join(root, "assets/models3d/same.glb");
    const sourceBytes = await readFile(source);
    await client.connect(transport);
    const description = await call("pokemap_describe", { actionIds: ["model3d.prune_unused"] });
    const actions = description.mutationActions as JsonRecord[];
    assert.ok(actions.some(action => action.id === "model3d.prune_unused"));
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const projectHandle = opened.projectHandle;
    await call("pokemap_workshop", { operation: "prepare", projectHandle, scope: "resourceIndexes" });
    const parameters = { modelIds: ["same", "different"] };
    const snapshot = await call("pokemap_workshop", { operation: "read", projectHandle,
      actionId: "model3d.prune_unused", parameters, includeDocuments: false });
    const planned = await call("pokemap_plan", { projectHandle, request: {
      requestId: "prune", actionId: "model3d.prune_unused", actionVersion: 1,
      workspaceHandle: opened.workspaceHandle, parameters,
      expectedRevision: snapshot.snapshotRevision, idempotencyKey: "prune",
      dryRun: false,
      extensions: snapshot.planExtensions,
    } });
    const preview = record(record(planned.plan).preview);
    assert.equal(preview.executionScope, "explicit_library_maintenance");
    assert.deepEqual(preview.deletedModelIds, ["same", "different"]);
    await access(source);
    const confirmed = await call("pokemap_apply", { operation: "confirm", projectHandle, planId: planned.planId });
    const result = await call("pokemap_apply", { operation: "apply", projectHandle,
      planId: planned.planId, operationId: "prune", confirmationToken: confirmed.confirmationToken });
    await assert.rejects(access(source));
    assert.deepEqual(await readFile(join(root, "maps/field.json")), beforeMap);
    const queried = await call("pokemap_query", { projectHandle, operation: "list", resourceKind: "model3d" });
    assert.deepEqual((queried.items as JsonRecord[]).map(item => item.id), ["keep"]);
    const receipt = record(result.receipt);
    await call("pokemap_history", { operation: "undo", projectHandle,
      entryId: receipt.receiptId, idempotencyKey: "undo-prune" });
    assert.deepEqual(await readFile(source), sourceBytes);
    await call("pokemap_history", { operation: "redo", projectHandle,
      entryId: receipt.receiptId, idempotencyKey: "redo-prune" });
    await assert.rejects(access(source));
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

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

test("MCP groups recorded duplicate models without claiming deletion is safe", { timeout: 120_000 }, async () => {
  const base = join(homedir(), "Library/Caches/AveluneQA/hgss-library-dedup/mcp-tests");
  await mkdir(base, { recursive: true });
  const root = await mkdtemp(join(base, "fixture-"));
  const packageRoot = resolve("../../packages/map_authoring");
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "model-duplicate-audit", version: "1.0.0" });
  async function call(name: string, args: JsonRecord): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: args });
    assert.equal(result.isError, undefined, JSON.stringify(result.structuredContent));
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, true, JSON.stringify(envelope));
    return record(envelope.data);
  }
  try {
    await promisify(execFile)(process.env.POKEMAP_TEST_DART ?? "dart", [
      `--packages=${join(packageRoot, ".dart_tool/package_config.json")}`,
      join(packageRoot, "test/support/create_duplicate_model_fixture.dart"), root,
    ], { timeout: 60_000 });
    const beforeHead = await readFile(join(root, "catalog/HEAD.json"));
    const beforeMap = await readFile(join(root, "maps/field.json"));
    const beforeAssets = await readFile(join(root, "assets/.pokemap-assets.json"));
    await client.connect(transport);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const started = await call("pokemap_model_duplicates", { operation: "start", projectHandle: opened.projectHandle });
    assert.equal(started.status, "running");
    let result: JsonRecord = {};
    for (let attempt = 0; attempt < 120; attempt++) {
      result = await call("pokemap_model_duplicates", { operation: "status",
        projectHandle: opened.projectHandle, jobId: started.jobId });
      if (result.status === "completed") break;
      assert.equal(result.status, "running");
      await new Promise(resolve => setTimeout(resolve, 500));
    }
    assert.equal(result.status, "completed");
    assert.equal(result.modelCount, 3);
    assert.equal(result.duplicateGroupCount, 1);
    assert.equal(result.duplicateDefinitionCount, 2);
    assert.equal(result.sourceEvidence, "registered_digest_only");
    assert.equal(result.referenceEvidence, "not_checked");
    const group = record((result.groups as unknown[])[0]);
    assert.equal(group.totalModels, 3);
    assert.equal(group.sameSettings, false);
    const models = group.models as JsonRecord[];
    assert.deepEqual(models.map(model => model.id), ["different", "keep", "same"]);
    assert.match(String(models[1]!.settingsFingerprint), /^sha256:[a-f0-9]{64}$/);
    assert.equal(models[1]!.settingsFingerprint, models[2]!.settingsFingerprint);
    assert.notEqual(models[0]!.settingsFingerprint, models[1]!.settingsFingerprint);
    const next = await call("pokemap_model_duplicates", { operation: "status", projectHandle: opened.projectHandle,
      jobId: started.jobId, offset: 1, expectedAuditRevision: result.auditRevision });
    assert.deepEqual(next.groups, []);
    const stale = await client.callTool({ name: "pokemap_model_duplicates", arguments: {
      operation: "status", projectHandle: opened.projectHandle, jobId: started.jobId,
      expectedAuditRevision: `sha256:${"0".repeat(64)}` } });
    assert.equal(stale.isError, true);
    assert.equal(record(record(stale.structuredContent).error).code, "model_duplicates.stale");
    assert.deepEqual(await readFile(join(root, "catalog/HEAD.json")), beforeHead);
    assert.deepEqual(await readFile(join(root, "maps/field.json")), beforeMap);
    assert.deepEqual(await readFile(join(root, "assets/.pokemap-assets.json")), beforeAssets);
    await call("pokemap_model_duplicates", { operation: "release", projectHandle: opened.projectHandle, jobId: started.jobId });
    let sequence = 0;
    async function mutate(actionId: string, parameters: JsonRecord): Promise<JsonRecord> {
      const snapshot = await call("pokemap_workshop", { operation: "read", projectHandle: opened.projectHandle,
        actionId, parameters });
      const id = `classify-models-${++sequence}`;
      const plan = await call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
        requestId: id, actionId, actionVersion: 1, workspaceHandle: opened.workspaceHandle,
        expectedRevision: snapshot.snapshotRevision, idempotencyKey: id,
        parameters, extensions: snapshot.planExtensions } });
      return call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle,
        planId: plan.planId, operationId: id });
    }
    await mutate("resource.family.create", { familyId: "profiles", name: "Profils" });
    const classified = await mutate("resource.classify_batch", { entries: [
      { resourceKind: "model3d", resourceId: "keep", familyId: "profiles" },
      { resourceKind: "model3d", resourceId: "same", familyId: "profiles" },
    ] });
    const query = await call("pokemap_query", { projectHandle: opened.projectHandle,
      operation: "batch_get", resourceKind: "model3d", ids: ["keep", "same", "different"], view: "detail" });
    assert.deepEqual((query.items as JsonRecord[]).map(model => [model.id, model.familyId]),
      [["different", null], ["keep", "profiles"], ["same", "profiles"]]);
    assert.deepEqual(await readFile(join(root, "maps/field.json")), beforeMap);
    assert.deepEqual(await readFile(join(root, "assets/.pokemap-assets.json")), beforeAssets);
    await call("pokemap_history", { operation: "undo", projectHandle: opened.projectHandle,
      entryId: record(classified.receipt).receiptId, idempotencyKey: "undo-classification" });
    const undone = await call("pokemap_query", { projectHandle: opened.projectHandle,
      operation: "get", resourceKind: "model3d", ids: ["keep"], view: "detail" });
    assert.equal((undone.items as JsonRecord[])[0]?.familyId, null);
    assert.deepEqual(await readFile(join(root, "maps/field.json")), beforeMap);
    assert.deepEqual(await readFile(join(root, "assets/.pokemap-assets.json")), beforeAssets);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

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

test("resource indexes prepare explicitly and guard scope and family mutations through live MCP", { timeout: 180_000 }, async () => {
  const base = join(homedir(), "Library/Caches/AveluneQA/resource-inverse-index/mcp");
  await mkdir(base, { recursive: true });
  const temporary = await mkdtemp(join(base, "fixture-"));
  const root = join(temporary, "project");
  const packageRoot = resolve("../../packages/map_authoring");
  const client = new Client({ name: "resource-indexes", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--dart", process.env.POKEMAP_TEST_DART ?? "dart", "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe" });
  async function call(name: string, args: JsonRecord, failure = false): Promise<JsonRecord> {
    const envelope = record((await client.callTool({ name, arguments: args })).structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify(envelope));
    return record(envelope[failure ? "error" : "data"]);
  }
  try {
    await promisify(execFile)(process.env.POKEMAP_TEST_DART ?? "dart", [
      `--packages=${join(packageRoot, ".dart_tool/package_config.json")}`,
      join(packageRoot, "test/support/create_resource_index_fixture.dart"), root,
    ], { timeout: 60_000 });
    const descriptor = await readFile(join(root, "project.json"));
    const map = await readFile(join(root, "maps/alpha.json"));
    await client.connect(transport);
    const tools = await client.listTools();
    assert.ok(JSON.stringify(tools.tools.find(tool => tool.name === "pokemap_workshop")?.inputSchema).includes("resourceIndexes"));
    const description = await call("pokemap_describe", {});
    assert.equal(record(record(description.workshopPreparation).resourceIndexes).routineEditsMaintainIndexes, true);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    await call("pokemap_workshop", { operation: "prepare", projectHandle: opened.projectHandle });
    const reservation = { resourceKind: "tileset", resourceId: "sheet", mapId: "alpha" };
    const before = await readFile(join(root, "catalog/HEAD.json"));
    const missing = await call("pokemap_workshop", { operation: "read", projectHandle: opened.projectHandle,
      actionId: "resource.classify", parameters: reservation }, true);
    assert.equal(record(missing.details).domainCode, "catalog.resource_usage.preparation_required");
    assert.deepEqual(await readFile(join(root, "catalog/HEAD.json")), before);
    const prepared = await call("pokemap_workshop", { operation: "prepare", projectHandle: opened.projectHandle, scope: "resourceIndexes" });
    assert.equal(prepared.scope, "explicitResourceUsageAndFamilyIndexes");
    const head = await readFile(join(root, "catalog/HEAD.json"));
    await call("pokemap_workshop", { operation: "prepare", projectHandle: opened.projectHandle, scope: "resourceIndexes" });
    assert.deepEqual(await readFile(join(root, "catalog/HEAD.json")), head);
    let sequence = 0;
    async function mutate(actionId: string, parameters: JsonRecord): Promise<JsonRecord> {
      const snapshot = await call("pokemap_workshop", { operation: "read", projectHandle: opened.projectHandle, actionId, parameters });
      const id = `resource-index-${++sequence}`;
      const planned = await call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
        requestId: id, actionId, actionVersion: 1, workspaceHandle: opened.workspaceHandle,
        expectedRevision: snapshot.snapshotRevision, idempotencyKey: id,
        parameters, extensions: snapshot.planExtensions,
      } });
      return call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle, planId: planned.planId, operationId: id });
    }
    await mutate("resource.classify", reservation);
    const conflict = await call("pokemap_workshop", { operation: "read", projectHandle: opened.projectHandle,
      actionId: "resource.classify", parameters: { ...reservation, mapId: "beta" } });
    const refused = await call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
      requestId: "scope-refusal", actionId: "resource.classify", actionVersion: 1, workspaceHandle: opened.workspaceHandle,
      expectedRevision: conflict.snapshotRevision, idempotencyKey: "scope-refusal",
      parameters: { ...reservation, mapId: "beta" }, extensions: conflict.planExtensions,
    } }, true);
    assert.equal(record(refused.details).domainCode, "resource_library.scope_conflict");
    await mutate("resource.family.create", { familyId: "parent", name: "Parent" });
    await mutate("resource.classify", { ...reservation, familyId: "parent" });
    const occupied = await call("pokemap_workshop", { operation: "read", projectHandle: opened.projectHandle,
      actionId: "resource.family.delete", parameters: { familyId: "parent" } }, true);
    assert.equal(record(occupied.details).domainCode, "resource_library.family_not_empty");
    await mutate("resource.classify", { ...reservation, familyId: null });
    await mutate("resource.family.delete", { familyId: "parent" });
    assert.deepEqual(await readFile(join(root, "project.json")), descriptor);
    assert.deepEqual(await readFile(join(root, "maps/alpha.json")), map);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
    const reopened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const snapshot = await call("pokemap_workshop", { operation: "read", projectHandle: reopened.projectHandle,
      actionId: "resource.classify", parameters: reservation });
    assert.equal((record(record(snapshot.project).resourceLibraryCatalog).entries as JsonRecord[])[0]?.mapId, "alpha");
    await call("pokemap_workspace", { operation: "close", workspaceHandle: reopened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(temporary, { recursive: true, force: true });
  }
});

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

test("narrative titles prepare explicitly and page through live MCP", { timeout: 180_000 }, async () => {
  const base = join(homedir(), "Library/Caches/AveluneQA/c1/mcp");
  await mkdir(base, { recursive: true });
  const temporary = await mkdtemp(join(base, "fixture-"));
  const root = join(temporary, "project");
  const packageRoot = resolve("../../packages/map_authoring");
  const client = new Client({ name: "narrative-titles", version: "1.0.0" });
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
      join(packageRoot, "test/support/create_narrative_title_fixture.dart"), root,
    ], { timeout: 90_000 });
    await client.connect(transport);
    const tools = await client.listTools();
    assert.ok(JSON.stringify(tools.tools.find(tool => tool.name === "pokemap_workshop")?.inputSchema).includes("narrativeTitles"));
    const description = await call("pokemap_describe", {});
    const preparation = record(record(description.workshopPreparation).narrativeTitles);
    assert.equal(preparation.routineEditsMaintainIndexes, true);
    assert.equal(preparation.readsMaps, false);
    const kind = (description.resourceKinds as JsonRecord[]).find(entry => entry.id === "narrativeTitle");
    assert.ok(kind);
    assert.equal(record(kind.extensions).preparationScope, "narrativeTitles");
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const query = { projectHandle: opened.projectHandle, resourceKind: "narrativeTitle", operation: "list", pageSize: 100 };
    const missing = await call("pokemap_query", { ...query, filters: { kind: "facts" } }, true);
    assert.equal(missing.domainCode ?? record(missing.details).domainCode, "query.narrative_titles_preparation_required");
    const before = await readFile(join(root, "catalog/HEAD.json"));
    const prepared = await call("pokemap_workshop", { operation: "prepare", projectHandle: opened.projectHandle, scope: "narrativeTitles" });
    assert.equal(prepared.scope, "explicitNarrativeTitleIndex");
    const head = await readFile(join(root, "catalog/HEAD.json"));
    assert.notDeepEqual(head, before);
    await call("pokemap_workshop", { operation: "prepare", projectHandle: opened.projectHandle, scope: "narrativeTitles" });
    assert.deepEqual(await readFile(join(root, "catalog/HEAD.json")), head);
    const first = await call("pokemap_query", { ...query, filters: { kind: "facts" } });
    assert.equal(first.totalAvailable, 130);
    assert.equal((first.items as JsonRecord[]).length, 100);
    assert.deepEqual((first.items as JsonRecord[])[0], { kind: "facts", id: "fact_fact_0", title: "Fact 0", tags: ["main"], category: "quest", position: 0 });
    const second = await call("pokemap_query", { ...query, filters: { kind: "facts" }, cursor: first.nextCursor });
    assert.equal((second.items as JsonRecord[]).length, 30);
    assert.equal(second.nextCursor, undefined);
    const events = await call("pokemap_query", { ...query, filters: { kind: "narrativeEvents" } });
    assert.deepEqual((events.items as JsonRecord[]).map(item => item.title), ["Wake up", "Leave home"]);
    const parameters = { fact: { id: "fact_fact_129", label: "Renamed", description: "", category: "", defaultValue: false, tags: [] } };
    const snapshot = await call("pokemap_workshop", { operation: "read", projectHandle: opened.projectHandle, actionId: "fact.update", parameters });
    const planned = await call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
      requestId: "rename-title", actionId: "fact.update", actionVersion: 1, workspaceHandle: opened.workspaceHandle,
      expectedRevision: snapshot.snapshotRevision, idempotencyKey: "rename-title",
      parameters, extensions: snapshot.planExtensions,
    } });
    await call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle, planId: planned.planId, operationId: "rename-title" });
    const renamed = await call("pokemap_query", { ...query, filters: { kind: "facts" }, cursor: undefined, pageSize: 200 });
    assert.equal(record((renamed.items as JsonRecord[])[129]).title, "Renamed");
    const invalid = await call("pokemap_query", { ...query }, true);
    assert.equal(invalid.domainCode ?? record(invalid.details).domainCode, "query.narrative_title_scope_invalid");
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(temporary, { recursive: true, force: true });
  }
});

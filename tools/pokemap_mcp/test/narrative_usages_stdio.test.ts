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

test("narrative usages prepare explicitly and answer through live MCP", { timeout: 180_000 }, async () => {
  const base = join(homedir(), "Library/Caches/AveluneQA/c1/mcp");
  await mkdir(base, { recursive: true });
  const temporary = await mkdtemp(join(base, "fixture-"));
  const root = join(temporary, "project");
  const packageRoot = resolve("../../packages/map_authoring");
  const client = new Client({ name: "narrative-usages", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--dart", process.env.POKEMAP_TEST_DART ?? "dart", "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe" });
  async function call(name: string, args: JsonRecord, failure = false): Promise<JsonRecord> {
    const envelope = record((await client.callTool({ name, arguments: args })).structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify(envelope));
    return record(envelope[failure ? "error" : "data"]);
  }
  const code = (error: JsonRecord) => error.domainCode ?? record(error.details).domainCode;
  try {
    await promisify(execFile)(process.env.POKEMAP_TEST_DART ?? "dart", [
      `--packages=${join(packageRoot, ".dart_tool/package_config.json")}`,
      join(packageRoot, "test/support/create_narrative_usage_fixture.dart"), root,
    ], { timeout: 90_000 });
    await client.connect(transport);
    const tools = await client.listTools();
    assert.ok(JSON.stringify(tools.tools.find(tool => tool.name === "pokemap_workshop")?.inputSchema).includes("narrativeUsages"));
    const description = await call("pokemap_describe", {});
    assert.equal(record(record(description.workshopPreparation).narrativeUsages).readsMaps, false);
    for (const id of ["narrativeFactUsers", "narrativeMapElementOwners"]) {
      const kind = (description.resourceKinds as JsonRecord[]).find(entry => entry.id === id);
      assert.equal(record(record(kind).extensions).preparationScope, "narrativeUsages");
    }
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const facts = { projectHandle: opened.projectHandle, resourceKind: "narrativeFactUsers", operation: "batch_get", ids: ["fact_fact_2", "fact_fact_3"] };
    assert.equal(code(await call("pokemap_query", facts, true)), "query.narrative_usages_preparation_required");
    const prepared = await call("pokemap_workshop", { operation: "prepare", projectHandle: opened.projectHandle, scope: "narrativeUsages" });
    assert.equal(prepared.scope, "explicitNarrativeUsageIndexes");
    const head = await readFile(join(root, "catalog/HEAD.json"));
    await call("pokemap_workshop", { operation: "prepare", projectHandle: opened.projectHandle, scope: "narrativeUsages" });
    assert.deepEqual(await readFile(join(root, "catalog/HEAD.json")), head);
    const before = (await call("pokemap_query", facts)).items as JsonRecord[];
    assert.deepEqual(before.map(item => item.users), [[], [
      { id: "main", kind: "storyline", role: "write" },
      { id: "world_rule_tree", kind: "worldRule", role: "read" },
    ]]);
    assert.ok((record(before[0]?.coverage).notCovered as string[]).includes("maps"));
    const rule = { id: "world_rule_tree", label: "Tree", description: "", enabled: true,
      source: { kind: "fact", sourceId: "fact_fact_2", predicate: "isTrue" },
      target: { kind: "mapEntity", mapId: "town", entityId: "well" }, effect: { kind: "entityHidden" }, priority: 0, tags: [] };
    const snapshot = await call("pokemap_workshop", { operation: "read", projectHandle: opened.projectHandle, actionId: "world_rule.update", parameters: { rule } });
    const planned = await call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
      requestId: "move-rule", actionId: "world_rule.update", actionVersion: 1, workspaceHandle: opened.workspaceHandle,
      expectedRevision: snapshot.snapshotRevision, idempotencyKey: "move-rule",
      parameters: { rule }, extensions: snapshot.planExtensions,
    } });
    await call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle, planId: planned.planId, operationId: "move-rule" });
    const after = (await call("pokemap_query", facts)).items as JsonRecord[];
    assert.deepEqual(after.map(item => item.users), [
      [{ id: "world_rule_tree", kind: "worldRule", role: "read" }],
      [{ id: "main", kind: "storyline", role: "write" }],
    ]);
    const owners = await call("pokemap_query", { projectHandle: opened.projectHandle, resourceKind: "narrativeMapElementOwners",
      operation: "batch_get", filters: { mapId: "town" }, ids: ["tree", "well"] });
    assert.deepEqual((owners.items as JsonRecord[]).map(item => item.owners), [[],
      [{ id: "world_rule_tree", kind: "worldRule", sourceKind: "entity" }]]);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(temporary, { recursive: true, force: true });
  }
});

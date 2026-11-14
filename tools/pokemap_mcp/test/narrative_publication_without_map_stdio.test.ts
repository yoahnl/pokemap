import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { mkdir, mkdtemp, readFile, rm } from "node:fs/promises";
import { homedir } from "node:os";
import { join, resolve } from "node:path";
import { promisify } from "node:util";
import { test } from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("MCP publishes a dialogue and a world rule on a working catalog without a map", { timeout: 180_000 }, async () => {
  const base = join(homedir(), "Library/Caches/AveluneQA/c4/mcp");
  await mkdir(base, { recursive: true });
  const temporary = await mkdtemp(join(base, "publication-"));
  const root = join(temporary, "project");
  const packageRoot = resolve("../../packages/map_authoring");
  const client = new Client({ name: "publication-without-map", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--dart", process.env.POKEMAP_TEST_DART ?? "dart", "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe" });
  async function call(name: string, input: JsonRecord, failure = false): Promise<JsonRecord> {
    const envelope = record((await client.callTool({ name, arguments: input })).structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify(envelope));
    return record(envelope[failure ? "error" : "data"]);
  }
  try {
    await promisify(execFile)(process.env.POKEMAP_TEST_DART ?? "dart", [
      `--packages=${join(packageRoot, ".dart_tool/package_config.json")}`,
      join(packageRoot, "test/support/create_publication_fixture.dart"), root,
    ], { timeout: 90_000 });
    const mapBefore = await readFile(join(root, "maps/map_0.json"));
    await client.connect(transport);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const parameters = {
      dialogues: [{ entry: { id: "dialogue_mcp", name: "MCP", relativePath: "dialogues/mcp.yarn" },
        source: "title: Start\n---\nBonjour sans carte\n===\n", revision: null }],
      worldRules: [{ id: "world_rule_tree", label: "Tree", description: "", enabled: true,
        source: { kind: "fact", sourceId: "fact_fact_0", predicate: "isTrue" },
        target: { kind: "mapEntity", mapId: "map_0", entityId: "tree" }, effect: { kind: "entityHidden" },
        priority: 0, tags: [] }],
    };
    const read = await call("pokemap_workshop", { operation: "read", projectHandle: opened.projectHandle,
      actionId: "narrative.publish_document", parameters });
    assert.deepEqual((read.maps as JsonRecord[]).map(map => map.id), ["map_0"]);
    assert.deepEqual(record(read.availableProjectDocuments).worldRules, ["world_rule_tree"]);
    const planned = await call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
      requestId: "no-map", actionId: "narrative.publish_document", actionVersion: 1,
      workspaceHandle: opened.workspaceHandle, parameters, expectedRevision: read.snapshotRevision,
      idempotencyKey: "no-map", extensions: read.planExtensions,
    } });
    const applied = await call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle,
      planId: planned.planId, operationId: "no-map" });
    const kinds = (record(applied.receipt).affectedResources as JsonRecord[]).map(resource => resource.kind);
    assert.ok(!kinds.includes("map"), JSON.stringify(kinds));
    assert.deepEqual(await readFile(join(root, "maps/map_0.json")), mapBefore);
    assert.match(await readFile(join(root, "dialogues/mcp.yarn"), "utf8"), /Bonjour sans carte/);
    const after = await call("pokemap_workshop", { operation: "read", projectHandle: opened.projectHandle,
      actionId: "narrative.publish_document", parameters });
    assert.deepEqual((record(after.project).worldRules as JsonRecord[]).map(rule => rule.id), ["world_rule_tree"]);
    const revisionOnly = { mapRevision: "sha256:x" };
    const bare = await call("pokemap_workshop", { operation: "read", projectHandle: opened.projectHandle,
      actionId: "narrative.publish_document", parameters: revisionOnly });
    const refused = await call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
      requestId: "revision-only", actionId: "narrative.publish_document", actionVersion: 1,
      workspaceHandle: opened.workspaceHandle, parameters: revisionOnly,
      expectedRevision: bare.snapshotRevision, idempotencyKey: "revision-only", extensions: bare.planExtensions,
    } }, true);
    assert.equal(refused.domainCode, "worker.request_invalid");
    assert.deepEqual(await readFile(join(root, "maps/map_0.json")), mapBefore);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(temporary, { recursive: true, force: true });
  }
});

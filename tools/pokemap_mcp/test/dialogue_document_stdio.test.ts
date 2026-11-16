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

test("dialogue documents are discoverable and read-only through live MCP", { timeout: 180_000 }, async () => {
  const base = join(homedir(), "Library/Caches/AveluneQA/histoire-d2a-01a1e117/mcp");
  await mkdir(base, { recursive: true });
  const temporary = await mkdtemp(join(base, "dialogue-"));
  const root = join(temporary, "project");
  const packageRoot = resolve("../../packages/map_authoring");
  const client = new Client({ name: "dialogue-document", version: "1.0.0" });
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
      join(packageRoot, "test/support/create_map_directory_fixture.dart"), root,
    ], { timeout: 90_000 });
    await client.connect(transport);
    const description = await call("pokemap_describe", {});
    const kind = (description.resourceKinds as JsonRecord[]).find(entry => entry.id === "dialogueDocument");
    assert.ok(kind);
    assert.deepEqual(record(kind.extensions).operations, ["get"]);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const query = { projectHandle: opened.projectHandle, resourceKind: "dialogueDocument", operation: "get", view: "detail", ids: ["greet"] };
    const head = await readFile(join(root, "catalog/HEAD.json"));
    const source = await readFile(join(root, "dialogues/greet.yarn"));
    const item = record(((await call("pokemap_query", query)).items as JsonRecord[])[0]);
    assert.equal(record(item.entry).id, "greet");
    assert.equal(item.source, source.toString("utf8"));
    assert.deepEqual(record(item.usages).sceneIds, ["scene_talk"]);
    assert.ok((record(item.usages).notCovered as string[]).includes("cinematics"));
    assert.deepEqual(item.reads, { dialogues: 1, scenes: 0, maps: 0 });
    const unknown = await call("pokemap_query", { ...query, ids: ["missing"] }, true);
    assert.equal(unknown.domainCode ?? record(unknown.details).domainCode, "query.resource_not_found");
    const invalid = await call("pokemap_query", { ...query, filters: { extra: true } }, true);
    assert.equal(invalid.domainCode ?? record(invalid.details).domainCode, "query.dialogue_document_scope_invalid");
    assert.deepEqual(await readFile(join(root, "catalog/HEAD.json")), head);
    assert.deepEqual(await readFile(join(root, "dialogues/greet.yarn")), source);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(temporary, { recursive: true, force: true });
  }
});

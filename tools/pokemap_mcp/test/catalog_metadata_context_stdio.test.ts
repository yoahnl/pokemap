import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { mkdir, mkdtemp, readFile, readdir, rm } from "node:fs/promises";
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

test("metadata context preparation crosses live MCP and the canonical CLI", { timeout: 120_000 }, async () => {
  const qa = join(homedir(), "Library/Caches/AveluneQA/3d-performance-implementation/p8-metadata-context");
  await mkdir(qa, { recursive: true });
  const temporary = await mkdtemp(join(qa, "mcp-"));
  const root = join(temporary, "project");
  await mkdir(root);
  const packageRoot = resolve("../../packages/map_authoring");
  const dart = process.env.POKEMAP_TEST_DART ?? "dart";
  const fixture = join(packageRoot, "test/support/create_metadata_context_fixture.dart");
  const client = new Client({ name: "metadata-context", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--dart", dart,
      "--authoring-timeout-ms", "60000"], cwd: process.cwd(), stderr: "pipe" });
  async function call(name: string, args: JsonRecord): Promise<JsonRecord> {
    const response = record((await client.callTool({ name, arguments: args })).structuredContent);
    assert.equal(response.ok, true, JSON.stringify(response));
    return record(response.data);
  }
  try {
    const executableArgs = [`--packages=${join(packageRoot, ".dart_tool/package_config.json")}`, fixture, root];
    await promisify(execFile)(dart, executableArgs, { timeout: 60_000 });
    await client.connect(transport);
    const tools = await client.listTools();
    assert.ok(JSON.stringify(tools.tools.find(tool => tool.name === "pokemap_workshop")?.inputSchema).includes("metadataContext"));
    const description = await call("pokemap_describe", {});
    const prerequisites = record(record(description.workshopPreparation).metadataContext);
    assert.equal(prerequisites.contextVersion, 1);
    assert.equal(prerequisites.requiresPreparedLocalUndoWindow, true);
    assert.equal(prerequisites.requiresPreparedMetadataIndexes, true);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    await call("pokemap_workshop", { operation: "prepare", projectHandle: opened.projectHandle });
    const before = await readFile(join(root, "catalog/HEAD.json"));
    const prepared = await call("pokemap_workshop", { operation: "prepare", projectHandle: opened.projectHandle, scope: "metadataContext" });
    assert.equal(prepared.scope, "explicitCatalogMetadataContext");
    assert.equal(prepared.contextVersion, 1);
    assert.match(String(prepared.metadataRevision), /^sha256:[0-9a-f]{64}$/);
    assert.deepEqual(await readFile(join(root, "catalog/HEAD.json")), before);
    assert.deepEqual(await call("pokemap_workshop", { operation: "prepare", projectHandle: opened.projectHandle, scope: "metadataContext" }), prepared);
    const inspected = await promisify(execFile)(dart, [...executableArgs, "--inspect-context"], { timeout: 60_000 });
    assert.equal(record(JSON.parse(inspected.stdout)).metadataRevision, prepared.metadataRevision);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    const authority = join(homedir(), ".avelune/authoring/catalog-admissions");
    for (const name of await readdir(authority)) {
      if (!name.endsWith(".json")) continue;
      const path = join(authority, name);
      let value: JsonRecord;
      try { value = record(JSON.parse(await readFile(path, "utf8"))); } catch { continue; }
      const admission = value.admission;
      if (value.projectRoot === root || admission && record(admission).projectRoot === root) {
        await rm(path);
      }
    }
    await rm(temporary, { recursive: true, force: true });
  }
});

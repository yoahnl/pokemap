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

test("map directory and scene documents are read through live MCP", { timeout: 180_000 }, async () => {
  const base = join(homedir(), "Library/Caches/AveluneQA/c4/mcp");
  await mkdir(base, { recursive: true });
  const temporary = await mkdtemp(join(base, "scene-"));
  const root = join(temporary, "project");
  const packageRoot = resolve("../../packages/map_authoring");
  const client = new Client({ name: "scene-document", version: "1.0.0" });
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
      join(packageRoot, "test/support/create_map_directory_fixture.dart"), root,
    ], { timeout: 90_000 });
    await client.connect(transport);
    const tools = await client.listTools();
    assert.ok(JSON.stringify(tools.tools.find(tool => tool.name === "pokemap_workshop")?.inputSchema).includes("mapDirectory"));
    const description = await call("pokemap_describe", {});
    assert.equal(record(record(description.workshopPreparation).mapDirectory).readsMaps, true);
    for (const id of ["mapDirectory", "sceneDocument"]) {
      assert.ok((description.resourceKinds as JsonRecord[]).some(entry => entry.id === id), id);
    }
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const scene = { projectHandle: opened.projectHandle, resourceKind: "sceneDocument", operation: "get", view: "detail", ids: ["scene_talk"] };
    assert.equal(code(await call("pokemap_query", scene, true)), "query.map_directory_preparation_required");
    const prepared = await call("pokemap_workshop", { operation: "prepare", projectHandle: opened.projectHandle, scope: "mapDirectory" });
    assert.equal(prepared.scope, "explicitMapDirectoryIndex");
    const head = await readFile(join(root, "catalog/HEAD.json"));
    const item = record(((await call("pokemap_query", scene)).items as JsonRecord[])[0]);
    assert.deepEqual(await readFile(join(root, "catalog/HEAD.json")), head);
    assert.equal(record(item.scene).id, "scene_talk");
    assert.match(String(record((item.dialogues as JsonRecord[])[0]).source), /Welcome to the lab/);
    const page = record((item.mapDirectory as JsonRecord[])[0]);
    assert.equal(page.mapId, "map_0");
    assert.equal(record((page.elements as JsonRecord[])[0]).characterId, "character_0");
    assert.equal(record(item.reads).maps, 0);
    const directory = await call("pokemap_query", { projectHandle: opened.projectHandle, resourceKind: "mapDirectory",
      operation: "batch_get", ids: ["map_0", "map_1"] });
    assert.deepEqual((directory.items as JsonRecord[]).map(entry => entry.name), ["Map 0", "Map 1"]);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(temporary, { recursive: true, force: true });
  }
});

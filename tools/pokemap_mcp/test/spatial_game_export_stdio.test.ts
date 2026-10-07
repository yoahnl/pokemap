import assert from "node:assert/strict";
import { cp, mkdir, mkdtemp, readFile, realpath, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import test from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("authored 3D exploration export crosses fresh MCP stdio and canonical worker", async () => {
  const root = await mkdtemp(join(tmpdir(), "spatial-export-mcp-"));
  const project = join(root, "project");
  const output = process.env.POKEMAP_SPATIAL_EXPORT_OUTPUT ?? join(root, "exports");
  await mkdir(output, { recursive: true });
  await cp(resolve("../../apps/hgss_first_map"), project, {
    recursive: true,
    filter: (path) => !path.includes(`${join("hgss_first_map", ".pokemap")}`),
  });
  await mkdir(join(project, ".pokemap"), { recursive: true });
  await writeFile(join(project, ".pokemap/export-profile-v1.json"), JSON.stringify({
    schemaVersion: 1, gameId: "games.yoahn.halte-falaises", gameVersion: "0.1.0",
    title: "La halte des falaises", author: { name: "Yoahn" },
    locales: { default: "fr", supported: ["fr"] }, requiredCapabilities: [],
    branding: {}, legal: {},
  }));
  const transport = new StdioClientTransport({
    command: process.execPath, args: ["dist/src/index.js", "--root", project,
      "--export-root", output, "--dart", process.env.POKEMAP_TEST_DART ?? "dart"],
    cwd: process.cwd(), stderr: "pipe",
  });
  const client = new Client({ name: "spatial-export-stdio", version: "1.0.0" });
  async function data(name: string, args: JsonRecord): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: args });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, true, JSON.stringify(envelope));
    return record(envelope.data);
  }
  try {
    await client.connect(transport);
    const catalog = await data("pokemap_describe", {});
    assert.ok(catalog.resourceKinds);
    const tools = await client.listTools();
    assert.match(tools.tools.find((tool) => tool.name === "pokemap_game_export")!.description!, /3D exploration/);
    const opened = await data("pokemap_workspace", { operation: "open", projectRoot: project });
    const outputPath = join(output, "la-halte-des-falaises.avelunegame");
    const result = await data("pokemap_game_export", { projectHandle: opened.projectHandle,
      mode: "localTest", outputPath });
    assert.equal(result.mode, "localTest");
    assert.equal(result.outputPath, await realpath(outputPath));
    assert.ok(Number(result.fileCount) > 10);
    const bytes = await readFile(outputPath);
    assert.equal(bytes.length, result.sizeBytes);
    const rejected = await client.callTool({ name: "pokemap_game_export", arguments: {
      projectHandle: opened.projectHandle, mode: "publication",
      outputPath: join(output, "publication.avelunegame"),
    } });
    const failure = record(rejected.structuredContent);
    assert.equal(failure.ok, false);
    assert.match(JSON.stringify(failure), /runtime3d.publication_unsupported/);
    await data("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
    process.stdout.write(`Spatial export receipt: ${JSON.stringify(result)}\n`);
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

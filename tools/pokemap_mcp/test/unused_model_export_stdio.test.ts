import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { createHash } from "node:crypto";
import { mkdir, mkdtemp, readFile, readdir, realpath, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import test from "node:test";
import { promisify } from "node:util";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

async function sourceHashes(root: string): Promise<Record<string, string>> {
  const result: Record<string, string> = {};
  async function visit(path: string): Promise<void> {
    for (const entry of await readdir(join(root, path), { withFileTypes: true })) {
      if (entry.name === ".pokemap") continue;
      const relative = join(path, entry.name);
      if (entry.isDirectory()) await visit(relative);
      else {
        assert.ok(entry.isFile());
        result[relative] = createHash("sha256")
          .update(await readFile(join(root, relative))).digest("hex");
      }
    }
  }
  await visit("");
  return result;
}

test("canonical MCP export omits unused models without changing source files", async () => {
  const root = await realpath(await mkdtemp(join(tmpdir(), "unused-model-mcp-")));
  const project = join(root, "project");
  const output = join(root, "exports");
  const run = promisify(execFile);
  let client: Client | undefined;
  try {
    await mkdir(output);
    const fixture = await run(process.env.POKEMAP_TEST_DART ?? "dart", [
      `--packages=${resolve("../../packages/map_authoring/.dart_tool/package_config.json")}`,
      resolve("test/fixtures/unused_model_export_fixture.dart"), project,
    ]);
    const unused = record(JSON.parse(fixture.stdout.trim()));
    const before = await sourceHashes(project);
    const transport = new StdioClientTransport({
      command: process.execPath,
      args: ["dist/src/index.js", "--root", project, "--export-root", output,
        "--dart", process.env.POKEMAP_TEST_DART ?? "dart",
        "--authoring-timeout-ms", "120000"],
      cwd: process.cwd(), stderr: "pipe",
    });
    client = new Client({ name: "unused-model-export", version: "1.0.0" });
    await client.connect(transport);
    async function data(name: string, args: JsonRecord): Promise<JsonRecord> {
      const envelope = record((await client!.callTool(
        { name, arguments: args }, { timeout: 125000 },
      )).structuredContent);
      assert.equal(envelope.ok, true, JSON.stringify(envelope));
      return record(envelope.data);
    }
    const catalog = await data("pokemap_describe", {});
    assert.ok(catalog.resourceKinds);
    const tools = await client.listTools();
    assert.ok(tools.tools.some((tool) => tool.name === "pokemap_game_export"));
    const opened = await data("pokemap_workspace", { operation: "open", projectRoot: project });
    const outputPath = join(output, "game.avelunegame");
    const receipt = await data("pokemap_game_export", {
      projectHandle: opened.projectHandle, outputPath, mode: "localTest",
    });
    assert.equal(receipt.mode, "localTest");
    assert.equal(receipt.outputPath, await realpath(outputPath));
    const exported = record(JSON.parse((await run("unzip", ["-p", outputPath,
      "project/project.json"])).stdout));
    assert.deepEqual((exported.models3d as JsonRecord[]).map((model) => model.id), ["model"]);
    const entries = (await run("unzip", ["-Z1", outputPath])).stdout.trim().split("\n");
    assert.ok(!entries.includes(`project/${unused.unusedLogicalPath}`));
    assert.ok(!entries.includes(`project/${unused.unusedBlobPath}`));
    assert.deepEqual(await sourceHashes(project), before);
    await data("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client?.close();
    await rm(root, { recursive: true, force: true });
  }
});

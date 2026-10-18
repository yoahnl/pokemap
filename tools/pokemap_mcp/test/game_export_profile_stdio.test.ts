import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { mkdir, mkdtemp, readFile, realpath, rm, unlink } from "node:fs/promises";
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

test("MCP authors an export profile with CAS and exports its persisted metadata", async () => {
  const root = await realpath(await mkdtemp(join(tmpdir(), "export-profile-mcp-")));
  const project = join(root, "project");
  const output = join(root, "exports");
  const run = promisify(execFile);
  let client: Client | undefined;
  try {
    await mkdir(output);
    await run(process.env.POKEMAP_TEST_DART ?? "dart", [
      `--packages=${resolve("../../packages/map_authoring/.dart_tool/package_config.json")}`,
      resolve("test/fixtures/unused_model_export_fixture.dart"), project,
    ]);
    const sidecar = join(project, ".pokemap/export-profile-v1.json");
    const profile = record(JSON.parse(await readFile(sidecar, "utf8")));
    profile.title = "Profil MCP persistant";
    profile.gameVersion = "2.3.4";
    await unlink(sidecar);
    const source = await readFile(join(project, "project.json"));
    client = new Client({ name: "export-profile-authoring", version: "1.0.0" });
    const transport = new StdioClientTransport({
      command: process.execPath,
      args: [process.env.POKEMAP_TEST_MCP_ENTRY ?? resolve("dist/src/index.js"),
        "--root", project, "--export-root", output,
        "--dart", process.env.POKEMAP_TEST_DART ?? "dart",
        "--authoring-timeout-ms", "120000"],
      cwd: process.cwd(), stderr: "pipe",
    });
    await client.connect(transport);
    async function call(name: string, args: JsonRecord, failure = false): Promise<JsonRecord> {
      const envelope = record((await client!.callTool({ name, arguments: args }, { timeout: 125000 })).structuredContent);
      assert.equal(envelope.ok, !failure, JSON.stringify(envelope));
      return record(envelope[failure ? "error" : "data"]);
    }
    const description = await call("pokemap_describe", {});
    const commands = description.commands as JsonRecord[];
    assert.equal(commands.filter(command => String(command.id).startsWith("game_export_profile_")).length, 3);
    const tools = (await client.listTools()).tools;
    for (const operation of ["read", "validate", "save"]) {
      assert.ok(tools.some(tool => tool.name === `pokemap_game_export_profile_${operation}`));
    }
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: project });
    const projectHandle = opened.projectHandle;
    const initial = await call("pokemap_game_export_profile_read", { projectHandle });
    assert.equal(initial.profile, null);
    assert.equal(initial.profileRevision, "absent");
    assert.match(String(initial.contextScope), /project.json/);
    const checked = await call("pokemap_game_export_profile_validate", { projectHandle, profile });
    const revisions = { expectedProfileRevision: checked.profileRevision, expectedContextRevision: checked.contextRevision };
    await call("pokemap_game_export_profile_save", { projectHandle, profile, ...revisions });
    const bytes = await readFile(sidecar);
    assert.deepEqual(JSON.parse(bytes.toString()), profile);
    await call("pokemap_game_export_profile_save", { projectHandle, profile: { ...profile, title: "Stale" }, ...revisions }, true);
    assert.deepEqual(await readFile(sidecar), bytes);
    await call("pokemap_game_export_profile_validate", { projectHandle, profile: { ...profile, legal: { licensePath: "legal/missing.txt" } } }, true);
    assert.deepEqual(await readFile(sidecar), bytes);
    const persisted = await call("pokemap_game_export_profile_read", { projectHandle });
    assert.deepEqual(persisted.profile, profile);
    const outputPath = join(output, "profile.avelunegame");
    const exported = await call("pokemap_game_export", { projectHandle, outputPath, mode: "localTest" });
    assert.equal(exported.title, profile.title);
    assert.equal(exported.gameVersion, "2.3.4");
    assert.equal(exported.outputPath, await realpath(outputPath));
    assert.deepEqual(await readFile(join(project, "project.json")), source);
    const entries = (await run("unzip", ["-Z1", outputPath])).stdout;
    assert.ok(!entries.includes(".pokemap/"));
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client?.close();
    await rm(root, { recursive: true, force: true });
  }
});

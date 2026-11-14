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

test("storyline outline and proposal are read through live MCP", { timeout: 180_000 }, async () => {
  const base = join(homedir(), "Library/Caches/AveluneQA/c2/mcp");
  await mkdir(base, { recursive: true });
  const temporary = await mkdtemp(join(base, "outline-"));
  const root = join(temporary, "project");
  const packageRoot = resolve("../../packages/map_authoring");
  const client = new Client({ name: "storyline-outline", version: "1.0.0" });
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
      join(packageRoot, "test/support/create_storyline_outline_fixture.dart"), root,
    ], { timeout: 90_000 });
    await client.connect(transport);
    const description = await call("pokemap_describe", {});
    for (const id of ["storylineOutline", "storylineProposal"]) {
      const kind = (description.resourceKinds as JsonRecord[]).find(entry => entry.id === id);
      assert.deepEqual(record(record(kind).extensions).operations, ["summary"]);
    }
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const outline = { projectHandle: opened.projectHandle, resourceKind: "storylineOutline", operation: "summary" };
    assert.equal(code(await call("pokemap_query", outline, true)), "query.narrative_titles_preparation_required");
    await call("pokemap_workshop", { operation: "prepare", projectHandle: opened.projectHandle, scope: "narrativeTitles" });
    assert.equal(code(await call("pokemap_query", outline, true)), "query.narrative_usages_preparation_required");
    await call("pokemap_workshop", { operation: "prepare", projectHandle: opened.projectHandle, scope: "narrativeUsages" });
    const head = await readFile(join(root, "catalog/HEAD.json"));
    const item = record(((await call("pokemap_query", outline)).items as JsonRecord[])[0]);
    assert.deepEqual(await readFile(join(root, "catalog/HEAD.json")), head);
    const chapters = record((item.storylines as JsonRecord[])[0]).chapters as JsonRecord[];
    const milestones = chapters[0]!.milestones as JsonRecord[];
    assert.deepEqual(milestones.map(milestone => [milestone.id, milestone.mapIds, milestone.issues]), [
      ["wake_up", ["map_0"], ["completionFactShared", "completionFactCanReset"]],
      ["leave_home", [], ["noBehaviour", "completionFactShared", "completionFactCanReset"]],
    ]);
    assert.equal(record(item.reads).maps, 0);
    const proposal = await call("pokemap_query", { ...outline, resourceKind: "storylineProposal" });
    assert.deepEqual((proposal.items as JsonRecord[])[0], { storyline: null, reason: "storylinesExist" });
    const invalid = await call("pokemap_query", { ...outline, operation: "list" }, true);
    assert.equal(code(invalid), "query.storyline_read_scope_invalid");
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(temporary, { recursive: true, force: true });
  }
});

import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { mkdir, mkdtemp, rm } from "node:fs/promises";
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

const journalActions = ["storyline.milestone.set_journal", "storyline.clues.set"];

test("storyline journal actions edit a working catalog through live MCP", { timeout: 180_000 }, async () => {
  const base = join(homedir(), "Library/Caches/AveluneQA/c6/mcp");
  await mkdir(base, { recursive: true });
  const temporary = await mkdtemp(join(base, "fixture-"));
  const root = join(temporary, "project");
  const packageRoot = resolve("../../packages/map_authoring");
  const client = new Client({ name: "storyline-journal", version: "1.0.0" });
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
      join(packageRoot, "test/support/create_storyline_trame_fixture.dart"), root,
    ], { timeout: 90_000 });
    await client.connect(transport);
    const description = await call("pokemap_describe", {});
    const described = (description.mutationActions as JsonRecord[]).map(action => action.id);
    for (const id of journalActions) assert.ok(described.includes(id), id);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    let sequence = 0;
    async function run(actionId: string, parameters: JsonRecord, failure = false): Promise<JsonRecord> {
      const snapshot = await call("pokemap_workshop", { operation: "read", projectHandle: opened.projectHandle, actionId, parameters });
      const id = `journal-${++sequence}`;
      const planned = await call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
        requestId: id, actionId, actionVersion: 1, workspaceHandle: opened.workspaceHandle,
        expectedRevision: snapshot.snapshotRevision, idempotencyKey: id, parameters, extensions: snapshot.planExtensions,
      } }, failure);
      if (failure) return planned;
      return call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle, planId: planned.planId, operationId: id });
    }
    const journal = { title: { fallback: "Réveil", translations: { en: "Wake up" } }, text: { fallback: "Une longue journée commence." } };
    const set = await run("storyline.milestone.set_journal",
      { storylineId: "main", chapterId: "act_1", stepId: "wake_up", journal });
    const paths = (record(record(set.receipt).diff).entries as JsonRecord[]).map(entry => entry.path);
    assert.deepEqual(paths, ["/storylines/main", "/workshopRevision"]);
    const clue = { id: "gate", factId: "fact_fact_0", text: { fallback: "Le portail est ouvert." } };
    await run("storyline.clues.set", { storylineId: "main", clues: [clue] });
    const missing = await run("storyline.clues.set",
      { storylineId: "main", clues: [{ ...clue, factId: "fact_missing" }] }, true);
    assert.ok(JSON.stringify(missing).includes("journalClueFactInvalid"), JSON.stringify(missing));
    const after = await call("pokemap_workshop", { operation: "read", projectHandle: opened.projectHandle,
      actionId: "storyline.clues.set", parameters: { storylineId: "main", clues: [] } });
    const storyline = (record(after.project).storylines as JsonRecord[])[0]!;
    const step = ((storyline.chapters as JsonRecord[])[0]!.steps as JsonRecord[])[0]!;
    assert.deepEqual(step.journal, journal);
    assert.deepEqual(storyline.journalClues, [clue]);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(temporary, { recursive: true, force: true });
  }
});

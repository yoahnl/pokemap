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

const trameActions = [
  "storyline.chapter.create", "storyline.chapter.rename", "storyline.chapter.set_archived",
  "storyline.milestone.create", "storyline.milestone.rename", "storyline.milestone.move",
  "storyline.milestone.set_archived", "storyline.milestone.attach_scene", "storyline.milestone.detach_scene",
];

test("storyline trame actions edit a working catalog through live MCP", { timeout: 180_000 }, async () => {
  const base = join(homedir(), "Library/Caches/AveluneQA/c2/mcp");
  await mkdir(base, { recursive: true });
  const temporary = await mkdtemp(join(base, "fixture-"));
  const root = join(temporary, "project");
  const packageRoot = resolve("../../packages/map_authoring");
  const client = new Client({ name: "storyline-trame", version: "1.0.0" });
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
    for (const id of trameActions) assert.ok(described.includes(id), id);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    let sequence = 0;
    async function run(actionId: string, parameters: JsonRecord, failure = false): Promise<JsonRecord> {
      const snapshot = await call("pokemap_workshop", { operation: "read", projectHandle: opened.projectHandle, actionId, parameters });
      const id = `trame-${++sequence}`;
      const planned = await call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
        requestId: id, actionId, actionVersion: 1, workspaceHandle: opened.workspaceHandle,
        expectedRevision: snapshot.snapshotRevision, idempotencyKey: id, parameters, extensions: snapshot.planExtensions,
      } }, failure);
      if (failure) return planned;
      return call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle, planId: planned.planId, operationId: id });
    }
    await run("storyline.chapter.create", { storylineId: "main", chapterId: "act_2", title: "Act 2" });
    const created = await run("storyline.milestone.create",
      { storylineId: "main", chapterId: "act_2", stepId: "leave_town", title: "Leave town" });
    const createdPaths = (record(record(created.receipt).diff).entries as JsonRecord[]).map(entry => entry.path);
    assert.deepEqual(createdPaths, ["/facts/fact_leave_town", "/storylines/main", "/workshopRevision"]);
    const attach = { storylineId: "main", chapterId: "act_2", stepId: "leave_town", sceneId: "scene_gate" };
    const read = await call("pokemap_workshop", { operation: "read", projectHandle: opened.projectHandle,
      actionId: "storyline.milestone.attach_scene", parameters: attach });
    assert.deepEqual(read.availableProjectDocuments, { scenes: ["scene_gate"] });
    assert.deepEqual((record(read.project).scenes as JsonRecord[]).map(scene => scene.id), ["scene_gate"]);
    const attached = await run("storyline.milestone.attach_scene", attach);
    const entry = (record(record(attached.receipt).diff).entries as JsonRecord[])
      .find(candidate => candidate.path === "/storylines/main")!;
    assert.deepEqual(record(entry.extensions).detachedFrom, [{ storylineId: "main", chapterId: "act_1", stepId: "wake_up" }]);
    const missing = await run("storyline.milestone.create",
      { storylineId: "main", chapterId: "missing", stepId: "lost", title: "Lost" }, true);
    assert.ok(JSON.stringify(missing).includes("chapterNotFound"), JSON.stringify(missing));
    const after = await call("pokemap_workshop", { operation: "read", projectHandle: opened.projectHandle,
      actionId: "storyline.chapter.rename", parameters: { storylineId: "main", chapterId: "act_2", title: "Finale" } });
    const storyline = (record(after.project).storylines as JsonRecord[])[0]!;
    const chapters = storyline.chapters as JsonRecord[];
    assert.deepEqual(chapters.map(chapter => chapter.id), ["act_1", "act_2"]);
    const steps = chapters[1]!.steps as JsonRecord[];
    assert.deepEqual(steps.map(step => [step.id, step.sceneLinkIds]), [["leave_town", ["scene_gate"]]]);
    assert.deepEqual((chapters[0]!.steps as JsonRecord[])[0]!.sceneLinkIds, []);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(temporary, { recursive: true, force: true });
  }
});

import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { cp, mkdtemp, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";

import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

async function data(client: Client, name: string, args: JsonRecord = {}): Promise<JsonRecord> {
  const result = await client.callTool({ name, arguments: args });
  assert.equal(result.isError, undefined, JSON.stringify(result.structuredContent));
  const envelope = record(result.structuredContent);
  assert.equal(envelope.ok, true);
  return record(envelope.data);
}

test("packaged MCP publishes source and authoritative dirty map coherently", { timeout: 120_000 }, async () => {
  const temporary = await mkdtemp(join(tmpdir(), "studio-narrative-mcp-"));
  const projectRoot = join(temporary, "project");
  await cp(resolve(process.cwd(), "../../examples/playable_runtime_host/golden_item_system"), projectRoot, { recursive: true });
  const original = record(JSON.parse(await readFile(join(projectRoot, "project.json"), "utf8")));
  const entry = (original.maps as JsonRecord[])[0]!;
  const mapPath = join(projectRoot, String(entry.relativePath));
  const before = await readFile(mapPath);
  const map = record(JSON.parse(before.toString("utf8")));
  map.name = "M3 coherent publication";
  const source = "title: Start\n---\nBonjour depuis le transport MCP !\n===\n";
  const args = [resolve(process.cwd(), "dist/src/index.js"), "--root", projectRoot];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "studio-narrative-test", version: "1.0.0" });
  try {
    await client.connect(transport);
    const description = await data(client, "pokemap_describe");
    assert.ok((description.mutationActions as JsonRecord[]).some((action) => action.id === "narrative.publish_document"));
    const opened = await data(client, "pokemap_workspace", { operation: "open", projectRoot });
    const projectHandle = String(opened.projectHandle);
    const validated = await data(client, "pokemap_validate", { projectHandle });
    const planned = await data(client, "pokemap_plan", { projectHandle, request: {
      requestId: "studio-narrative", actionId: "narrative.publish_document", actionVersion: 1,
      workspaceHandle: opened.workspaceHandle, parameters: {
        map, mapRevision: `sha256:${createHash("sha256").update(before).digest("hex")}`,
        dialogues: [{ entry: { id: "studio-hello", name: "Bonjour", relativePath: "dialogues/studio-hello.yarn" }, source, revision: null }],
      }, expectedRevision: validated.snapshotRevision, idempotencyKey: "studio-narrative", dryRun: false,
    } });
    assert.deepEqual(await readFile(mapPath), before);
    const applied = await data(client, "pokemap_apply", {
      operation: "apply", projectHandle, planId: planned.planId, operationId: "studio-narrative-publication",
    });
    assert.equal(record(applied.receipt).status, "applied");
    const after = record(JSON.parse(await readFile(join(projectRoot, "project.json"), "utf8")));
    assert.ok((after.dialogues as JsonRecord[]).some((dialogue) => dialogue.id === "studio-hello"));
    assert.equal(await readFile(join(projectRoot, "dialogues/studio-hello.yarn"), "utf8"), source);
    assert.equal(record(JSON.parse(await readFile(mapPath, "utf8"))).name, map.name);
    assert.deepEqual(after.eventRegistry, original.eventRegistry);
    await data(client, "pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await rm(temporary, { recursive: true, force: true });
  }
});

test("packaged MCP publishes UI07 story ownership without touching maps", { timeout: 120_000 }, async () => {
  const temporary = await mkdtemp(join(tmpdir(), "studio-story-mcp-"));
  const projectRoot = join(temporary, "project");
  await cp(resolve(process.cwd(), "../../examples/playable_runtime_host/golden_item_system"), projectRoot, { recursive: true });
  const original = record(JSON.parse(await readFile(join(projectRoot, "project.json"), "utf8")));
  const maps = await Promise.all((original.maps as JsonRecord[]).map(async (entry) => ({
    path: join(projectRoot, String(entry.relativePath)),
    bytes: await readFile(join(projectRoot, String(entry.relativePath))),
  })));
  const args = [resolve(process.cwd(), "dist/src/index.js"), "--root", projectRoot];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "studio-story-test", version: "1.0.0" });
  try {
    await client.connect(transport);
    const description = await data(client, "pokemap_describe");
    const actions = description.mutationActions as JsonRecord[];
    assert.ok(actions.some((action) => action.id === "storyline.upsert"));
    const opened = await data(client, "pokemap_workspace", { operation: "open", projectRoot });
    const projectHandle = String(opened.projectHandle);
    const stories = [
      { id: "ui07-main", type: "main", title: "Préparer le départ", chapters: [
        { id: "ui07-chapter", title: "Gare", order: 0, steps: [
          { id: "ui07-step", title: "Monter dans le train", order: 0, authorNotes: "Conserver" },
        ] },
      ] },
      { id: "ui07-side", type: "sideQuest", title: "Le sac oublié", relationships: [
        { id: "ui07-requires", kind: "requires", sourceStorylineId: "ui07-side", targetStorylineId: "ui07-main", metadata: {} },
      ] },
    ];
    for (const storyline of stories) {
      const validated = await data(client, "pokemap_validate", { projectHandle });
      const planned = await data(client, "pokemap_plan", { projectHandle, request: {
        requestId: storyline.id, actionId: "storyline.upsert", actionVersion: 1,
        workspaceHandle: opened.workspaceHandle, parameters: { storyline },
        expectedRevision: validated.snapshotRevision, idempotencyKey: storyline.id, dryRun: false,
      } });
      const applied = await data(client, "pokemap_apply", {
        operation: "apply", projectHandle, planId: planned.planId, operationId: `${storyline.id}-publication`,
      });
      assert.equal(record(applied.receipt).status, "applied");
    }
    const after = record(JSON.parse(await readFile(join(projectRoot, "project.json"), "utf8")));
    const saved = after.storylines as JsonRecord[];
    const main = saved.find((story) => story.id === "ui07-main")!;
    const side = saved.find((story) => story.id === "ui07-side")!;
    assert.deepEqual(side.relationships, stories[1]!.relationships);
    const chapter = (main.chapters as JsonRecord[])[0]!;
    assert.equal((chapter.steps as JsonRecord[])[0]!.authorNotes, "Conserver");
    for (const map of maps) assert.deepEqual(await readFile(map.path), map.bytes);
    assert.deepEqual(after.scenes ?? [], original.scenes ?? []);
    const normalizeFacts = (facts: unknown) => (facts as JsonRecord[] ?? []).map((fact) => ({
      description: "", category: "", defaultValue: false, tags: [], ...fact,
    }));
    assert.deepEqual(normalizeFacts(after.facts), normalizeFacts(original.facts));
    await data(client, "pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await rm(temporary, { recursive: true, force: true });
  }
});

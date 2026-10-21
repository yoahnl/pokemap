import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";
import { canonicalPokemonConfig } from "./pokemon_fixture.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

function dialogue(id: string, source = "title: Start\n---\nBonjour 🦊\n===\n"): JsonRecord {
  return { entry: { id, name: id, relativePath: `dialogues/${id}.yarn`, defaultStartNode: "Start" }, source };
}

test("MCP discovers, refuses malformed tails, commits, replays and undoes dialogue creation batches", { timeout: 180_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "dialogue-batch-"));
  const file = join(root, "project.json");
  await mkdir(join(root, "dialogues"));
  await mkdir(join(root, "maps"));
  const mapFile = join(root, "maps/map.json");
  await writeFile(mapFile, JSON.stringify({ id: "map", name: "Map", version: "v8",
    size: { width: 3, height: 3 }, layers: [], entities: [] }));
  const mapBefore = await readFile(mapFile);
  const existing = dialogue("existing");
  await writeFile(join(root, "dialogues/existing.yarn"), existing.source as string);
  await writeFile(file, JSON.stringify({ name: "Dialogue batch", version: "v8",
    maps: [{ id: "map", name: "Map", relativePath: "maps/map.json" }],
    tilesets: [], dialogues: [existing.entry], pokemon: { ...canonicalPokemonConfig(), enabled: false } }));
  const before = await readFile(file);
  const args = [resolve(process.env.POKEMAP_TEST_MCP_ENTRY ?? "dist/src/index.js"),
    "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  if (process.env.POKEMAP_TEST_AUTHORING_PACKAGE) args.push("--authoring-package", process.env.POKEMAP_TEST_AUTHORING_PACKAGE);
  const client = new Client({ name: "dialogue-batch", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  async function call(name: string, input: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: input });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify({ name, envelope }));
    return record(envelope[failure ? "error" : "data"]);
  }
  let workspace: JsonRecord;
  let sequence = 0;
  async function plan(dialogues: unknown[], failure = false, dryRun = false): Promise<JsonRecord> {
    const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    const saved = await readFile(file);
    const id = `dialogue-batch-${++sequence}`;
    const result = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
      requestId: id, actionId: "dialogue.create_batch", actionVersion: 1,
      workspaceHandle: workspace.workspaceHandle, parameters: { dialogues },
      expectedRevision: validation.snapshotRevision, idempotencyKey: id, dryRun,
    } }, failure);
    assert.deepEqual(await readFile(file), saved);
    assert.deepEqual(await readFile(mapFile), mapBefore);
    return result;
  }
  try {
    await client.connect(transport);
    const catalog = await call("pokemap_describe");
    const action = (catalog.mutationActions as JsonRecord[]).find(value => value.id === "dialogue.create_batch");
    assert.ok(action);
    const batch = record(record(action.extensions).batch);
    assert.equal(batch.minDialogues, 1);
    assert.equal(batch.maxDialogues, 128);
    assert.equal(batch.maximumSourceUtf8Bytes, 524288);
    assert.equal(batch.semantics, "createOnly");
    assert.equal(batch.atomic, true);
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const first = dialogue("first");
    const second = dialogue("second");
    const badNode = dialogue("bad_node");
    record(badNode.entry).defaultStartNode = "Absent";
    const duplicatePath = dialogue("other");
    record(duplicatePath.entry).relativePath = "dialogues/FIRST.yarn";
    for (const values of [[], Array.from({ length: 129 }, (_, i) => dialogue(`max_${i}`)),
      [first, first], [first, existing], [first, duplicatePath], [first, 42], [first, badNode],
      [first, dialogue("bad", "Invalid Yarn")], [first, { ...second, extra: true }],
      [dialogue("huge", "é".repeat(262145))]]) {
      const failure = await plan(values, true);
      assert.ok(String(failure.domainCode).startsWith("dialogue.") || String(failure.domainCode).startsWith("narrative."), JSON.stringify(failure));
      assert.deepEqual(await readFile(file), before);
    }
    const preview = await plan([first, second], false, true);
    assert.equal(preview.applicable, false);
    const dryRefusal = await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle,
      planId: preview.planId, operationId: "dialogue-batch-dry" }, true);
    assert.equal(dryRefusal.domainCode, "plan.dry_run_not_applicable");
    const stale = await plan([dialogue("stale")]);
    const planned = await plan([first, second]);
    const apply = { operation: "apply", projectHandle: workspace.projectHandle,
      planId: planned.planId, operationId: "dialogue-batch-apply" };
    const applied = await call("pokemap_apply", apply);
    const saved = await readFile(file);
    assert.deepEqual((record(JSON.parse(saved.toString())).dialogues as JsonRecord[]).map(value => value.id), ["existing", "first", "second"]);
    assert.equal(await readFile(join(root, "dialogues/first.yarn"), "utf8"), first.source);
    assert.equal(await readFile(join(root, "dialogues/second.yarn"), "utf8"), second.source);
    const replay = await call("pokemap_apply", apply);
    assert.deepEqual(replay.receipt, applied.receipt);
    const staleRefusal = await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle,
      planId: stale.planId, operationId: "dialogue-batch-stale" }, true);
    assert.equal(staleRefusal.domainCode, "plan.stale");
    assert.deepEqual(await readFile(file), saved);
    const validated = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    assert.equal(validated.valid, true, JSON.stringify(validated));
    await call("pokemap_history", { operation: "undo", projectHandle: workspace.projectHandle,
      entryId: record(applied.receipt).receiptId, idempotencyKey: "undo-dialogue-batch" });
    assert.deepEqual(await readFile(file), before);
    await assert.rejects(readFile(join(root, "dialogues/first.yarn")));
    await assert.rejects(readFile(join(root, "dialogues/second.yarn")));
    assert.equal(await readFile(join(root, "dialogues/existing.yarn"), "utf8"), existing.source);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

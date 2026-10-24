import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
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

function finish(recordParty: unknown = true): JsonRecord {
  return { kind: "finishGame", contractVersion: 1, endingId: "ending.champion",
    outcome: "victory", commitPolicy: "persistBeforePresentation",
    result: { title: { fallback: "Victoire", translations: { en: "Victory" } },
      summary: { fallback: "Parcours accompli" }, details: [{ fallback: "Équipe gagnante" }] },
    postGamePolicy: "continueGame", recordParty };
}

function scene(id: string, recordParty: unknown = true): JsonRecord {
  return { id, name: id, graph: { startNodeId: "start", nodes: [
    { id: "start", kind: "start" },
    { id: "finish", kind: "action", payload: { consequence: finish(recordParty) } },
    { id: "end", kind: "end" },
  ], edges: [
    { id: "enter", fromNodeId: "start", fromPortId: "completed", toNodeId: "finish", kind: "default" },
    { id: "leave", fromNodeId: "finish", fromPortId: "completed", toNodeId: "end", kind: "actionCompleted" },
  ] } };
}

test("fresh MCP describes party recording, authors it atomically and cold reopens", { timeout: 180_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "completion-party-mcp-"));
  const projectFile = join(root, "project.json");
  await writeFile(projectFile, JSON.stringify({ name: "Completion", version: "v8",
    pokemon: canonicalPokemonConfig(), maps: [], tilesets: [] }));
  const args = [resolve(process.env.POKEMAP_TEST_MCP_ENTRY ?? "dist/src/index.js"),
    "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  if (process.env.POKEMAP_TEST_AUTHORING_PACKAGE) args.push("--authoring-package", process.env.POKEMAP_TEST_AUTHORING_PACKAGE);
  const client = new Client({ name: "completion-party-qualification", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  let workspace: JsonRecord | undefined;
  let sequence = 0;
  async function call(name: string, input: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const envelope = record((await client.callTool({ name, arguments: input })).structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify({ name, envelope }));
    return record(envelope[failure ? "error" : "data"]);
  }
  async function plan(actionId: string, parameters: JsonRecord, failure = false): Promise<JsonRecord> {
    assert.ok(workspace);
    const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    const before = await readFile(projectFile);
    const id = `completion-${++sequence}`;
    const result = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
      requestId: id, actionId, actionVersion: 1, workspaceHandle: workspace.workspaceHandle,
      expectedRevision: validation.snapshotRevision, idempotencyKey: id, parameters,
    } }, failure);
    assert.deepEqual(await readFile(projectFile), before);
    if (failure) assert.notEqual(result.domainCode, "worker.internal");
    return result;
  }
  async function apply(actionId: string, parameters: JsonRecord): Promise<JsonRecord> {
    const prepared = await plan(actionId, parameters);
    assert.ok(workspace);
    const input = { operation: "apply", projectHandle: workspace.projectHandle,
      planId: prepared.planId, operationId: `completion-apply-${sequence}` };
    const applied = await call("pokemap_apply", input);
    assert.deepEqual((await call("pokemap_apply", input)).receipt, applied.receipt);
    return record(applied.receipt);
  }
  try {
    await client.connect(transport);
    const catalog = await call("pokemap_describe");
    for (const id of ["scene.upsert", "scene.upsert_batch", "scene.graph.patch"]) {
      const descriptor = (catalog.mutationActions as JsonRecord[]).find(value => value.id === id);
      assert.ok(descriptor);
      const contract = record(record(descriptor.extensions).finishGame);
      assert.equal(contract.contractVersion, 1);
      const option = record(contract.recordParty);
      assert.equal(option.type, "boolean");
      assert.equal(option.default, false);
      assert.equal(option.requiredCapability, "game.completion-party-journal@1");
    }
    console.log(JSON.stringify({ mutationActions: (catalog.mutationActions as unknown[]).length,
      qualifiedOption: "finishGame.recordParty" }));
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    for (const flag of [null, "true", 1]) {
      await plan("scene.upsert_batch", { scenes: [scene("valid"), scene("invalid", flag)] }, true);
    }
    await apply("scene.upsert", { scene: scene("first") });
    const beforeBatch = await readFile(projectFile);
    const batchReceipt = await apply("scene.upsert_batch", { scenes: [scene("first", false), scene("second")] });
    const afterBatch = await readFile(projectFile);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const query = await call("pokemap_query", { projectHandle: workspace.projectHandle,
      resourceKind: "scene", operation: "get", ids: ["second"], view: "detail" });
    assert.ok(JSON.stringify(query).includes('"recordParty":true'));
    const saved = record(JSON.parse(await readFile(projectFile, "utf8")));
    const second = (saved.scenes as JsonRecord[]).find(value => value.id === "second");
    assert.ok(second);
    const payload = record((record(second.graph).nodes as JsonRecord[])[1]!.payload);
    assert.deepEqual(record(payload.consequence), finish());
    const history = await call("pokemap_history", { operation: "list", projectHandle: workspace.projectHandle });
    assert.equal((history.entries as unknown[]).length, 2);
    const undone = await call("pokemap_history", { operation: "undo", projectHandle: workspace.projectHandle,
      entryId: batchReceipt.receiptId, idempotencyKey: "undo-completion-batch" });
    assert.deepEqual(await readFile(projectFile), beforeBatch);
    await call("pokemap_history", { operation: "undo", projectHandle: workspace.projectHandle,
      entryId: record(undone.receipt).receiptId, idempotencyKey: "restore-completion-batch" });
    assert.deepEqual(await readFile(projectFile), afterBatch);
  } finally {
    if (workspace) await client.callTool({ name: "pokemap_workspace", arguments: {
      operation: "close", workspaceHandle: workspace.workspaceHandle,
    } }).catch(() => undefined);
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

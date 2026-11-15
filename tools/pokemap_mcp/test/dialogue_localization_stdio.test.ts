import assert from "node:assert/strict";
import { mkdtemp, readFile, rm } from "node:fs/promises";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
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

test("MCP discovers, publishes and protects localized dialogue identities", { timeout: 180_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "dialogue-localization-"));
  const source = "title: Start\n---\nBonjour\n===\n";
  const entry = { id: "talk", name: "Accueil", relativePath: "dialogues/talk.yarn" };
  const packageRoot = resolve("../../packages/map_authoring");
  await promisify(execFile)(process.env.POKEMAP_TEST_DART ?? "dart", [
    `--packages=${join(packageRoot, ".dart_tool/package_config.json")}`,
    join(packageRoot, "test/support/create_dialogue_localization_fixture.dart"), root,
  ], { timeout: 90_000 });
  const client = new Client({ name: "dialogue-localization", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe" });
  async function call(name: string, input: JsonRecord, failure = false): Promise<JsonRecord> {
    const envelope = record((await client.callTool({ name, arguments: input })).structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify(envelope));
    return record(envelope[failure ? "error" : "data"]);
  }
  try {
    await client.connect(transport);
    const described = await call("pokemap_describe", { actionIds: ["dialogue.update"], view: "full" });
    const action = (described.mutationActions as JsonRecord[]).find(value => value.id === "dialogue.update");
    assert.ok(action);
    const contract = record(record(action.extensions).localizationContract);
    assert.equal(contract.format, 1);
    assert.equal(contract.storage, "entry.localization");
    assert.equal(contract.runtimeCapability, "project.dialogue-localization@1");
    assert.equal(contract.runtimeExportSupported, false);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const localized = { ...entry, localization: { format: 1, sourceLocale: "fr", units: [{
      id: "greeting", binding: "/Start/0", kind: "line", source: "Bonjour",
      translations: { en: { text: "Hello", source: "Bonjour" } },
    }] } };
    async function plan(parameters: JsonRecord, key: string, failure = false) {
      const read = await call("pokemap_workshop", { operation: "read", projectHandle: opened.projectHandle,
        actionId: "dialogue.update", parameters });
      return call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
        requestId: key, actionId: "dialogue.update", actionVersion: 1,
        workspaceHandle: opened.workspaceHandle, parameters, expectedRevision: read.snapshotRevision,
        idempotencyKey: key, extensions: read.planExtensions,
      } }, failure);
    }
    const planned = await plan({ entry: localized }, "localize");
    const applied = await call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle,
      planId: planned.planId, operationId: "localize" });
    const persisted = await call("pokemap_workshop", { operation: "read", projectHandle: opened.projectHandle,
      actionId: "dialogue.update", parameters: { entry: localized } });
    assert.deepEqual(record((record(persisted.project).dialogues as JsonRecord[])[0]).localization, localized.localization);
    assert.equal(await readFile(join(root, entry.relativePath), "utf8"), source);
    const before = await readFile(join(root, "project.json"));
    const headBefore = await readFile(join(root, "catalog/HEAD.json"));
    const refused = await plan({ entry: localized, source: source.replace("Bonjour", "Salut") }, "stale-source", true);
    assert.match(JSON.stringify(refused), /dialogue.compile_blocking/);
    assert.deepEqual(await readFile(join(root, "project.json")), before);
    assert.deepEqual(await readFile(join(root, "catalog/HEAD.json")), headBefore);
    assert.equal(await readFile(join(root, entry.relativePath), "utf8"), source);
    await call("pokemap_history", { operation: "undo", projectHandle: opened.projectHandle,
      entryId: record(applied.receipt).receiptId, idempotencyKey: "undo-localization" });
    const restored = await call("pokemap_workshop", { operation: "read", projectHandle: opened.projectHandle,
      actionId: "dialogue.update", parameters: { entry } });
    assert.equal(record((record(restored.project).dialogues as JsonRecord[])[0]).localization, undefined);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

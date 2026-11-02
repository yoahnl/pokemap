import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { execFile } from "node:child_process";
import { mkdir, mkdtemp, readFile, rm, stat, writeFile } from "node:fs/promises";
import { join, resolve } from "node:path";
import { test } from "node:test";
import { promisify } from "node:util";

import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

function wav(): Buffer {
  const bytes = Buffer.alloc(108);
  bytes.write("RIFF", 0); bytes.writeUInt32LE(100, 4); bytes.write("WAVEfmt ", 8);
  bytes.writeUInt32LE(16, 16); bytes.writeUInt16LE(1, 20); bytes.writeUInt16LE(1, 22);
  bytes.writeUInt32LE(8000, 24); bytes.writeUInt32LE(16000, 28);
  bytes.writeUInt16LE(2, 32); bytes.writeUInt16LE(16, 34);
  bytes.write("data", 36); bytes.writeUInt32LE(64, 40); bytes[44] = 1;
  return bytes;
}

test("MCP stages a cry, preserves media and replays its transaction", { timeout: 120_000 }, async () => {
  const qaRoot = process.env.AVELUNE_QA_ROOT;
  assert.ok(qaRoot);
  const root = await mkdtemp(join(qaRoot, "pokemon-cry-mcp-"));
  const transport = new StdioClientTransport({
    command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe",
  });
  const client = new Client({ name: "pokemon-cry-test", version: "1.0.0" });
  async function call(name: string, input: JsonRecord = {}): Promise<JsonRecord> {
    const response = await client.callTool({ name, arguments: input });
    const envelope = record(response.structuredContent);
    assert.equal(envelope.ok, true, JSON.stringify(envelope));
    return record(envelope.data);
  }
  try {
    const authoringPackage = resolve("../../packages/map_authoring");
    await promisify(execFile)(process.env.POKEMAP_TEST_DART ?? "dart", [
      `--packages=${join(authoringPackage, ".dart_tool/package_config.json")}`,
      join(authoringPackage, "test/support/create_working_catalog_fixture.dart"), root, "--companion",
    ], { timeout: 60_000 });
    const relativePath = "data/pokemon/media/pikachu.json";
    const mediaPath = join(root, relativePath);
    const sourcePath = join(root, "source.wav");
    const audio = wav();
    const cryPath = `assets/pokemon/battle-cries/${createHash("sha256").update(audio).digest("hex")}.wav`;
    const media = { schemaVersion: 1, speciesId: "pikachu", defaultFormId: "base",
      variants: { base: { frontStatic: "assets/front.png" } }, vendorExtension: { keep: true } };
    const before = Buffer.from(JSON.stringify(media));
    await mkdir(join(root, "data/pokemon/media"), { recursive: true });
    await writeFile(mediaPath, before);
    await writeFile(sourcePath, audio);
    await client.connect(transport);
    const describe = await call("pokemap_describe");
    const action = (describe.mutationActions as JsonRecord[]).find((entry) => entry.id === "pokemon.media.write");
    assert.equal(record(record(action).extensions).battleCryImport instanceof Object, true);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    await call("pokemap_workshop", { operation: "prepare", projectHandle: opened.projectHandle });
    const staged = await call("pokemap_artifact_stage", { sourcePath, declaredMediaType: "audio/wav" });
    const parameters = { relativePath, beforeBytesBase64: before.toString("base64"),
      document: { ...media, variants: { base: { ...media.variants.base, cry: cryPath } } } };
    const scope = await call("pokemap_workshop", { operation: "read", projectHandle: opened.projectHandle,
      actionId: "pokemon.media.write", parameters });
    const plan = await call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
      requestId: "cry-mcp", actionId: "pokemon.media.write", actionVersion: 1,
      workspaceHandle: opened.workspaceHandle, expectedRevision: scope.snapshotRevision,
      idempotencyKey: "cry-mcp", parameters, dryRun: false,
      extensions: { ...record(scope.planExtensions), battleCryArtifact: staged.artifactHandle },
    } });
    await assert.rejects(stat(join(root, cryPath)));
    const applied = await call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle,
      planId: plan.planId, operationId: "cry-mcp" });
    assert.deepEqual(await readFile(join(root, cryPath)), audio);
    const saved = record(JSON.parse(await readFile(mediaPath, "utf8")));
    assert.deepEqual(saved.vendorExtension, { keep: true });
    assert.equal(record(record(saved.variants).base).cry, cryPath);
    const receiptId = record(applied.receipt).receiptId;
    await call("pokemap_history", { operation: "undo", projectHandle: opened.projectHandle,
      entryId: receiptId, idempotencyKey: "undo-cry" });
    await call("pokemap_history", { operation: "redo", projectHandle: opened.projectHandle,
      entryId: receiptId, idempotencyKey: "redo-cry" });
    assert.deepEqual(await readFile(join(root, cryPath)), audio);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

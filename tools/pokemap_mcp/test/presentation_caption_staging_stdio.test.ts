import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";

import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";

import type { JsonRecord } from "../src/authoring_client.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("MCP stages WebVTT with its native MIME while preserving other media guards", { timeout: 180_000 }, async () => {
  const cache = process.platform === "darwin"
    ? join(homedir(), "Library", "Caches")
    : process.env.XDG_CACHE_HOME?.trim() || join(homedir(), ".cache");
  const parent = process.env.AVELUNE_QA_ROOT?.trim()
    || join(cache, "AveluneQA");
  await mkdir(parent, { recursive: true });
  const root = await mkdtemp(join(parent, "caption-staging-mcp-"));
  const args = [
    resolve("dist/src/index.js"), "--root", root, "--artifact-root", root,
    "--authoring-timeout-ms", "120000",
  ];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const transport = new StdioClientTransport({
    command: process.execPath, args, cwd: process.cwd(), stderr: "pipe",
  });
  const client = new Client({ name: "caption-staging-proof", version: "1.0.0" });
  async function call(name: string, input: JsonRecord = {}): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: input }, { timeout: 125_000 });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, true, JSON.stringify(envelope));
    return record(envelope.data);
  }
  async function refuse(input: JsonRecord): Promise<void> {
    const result = await client.callTool({ name: "pokemap_artifact_stage", arguments: input }, { timeout: 125_000 });
    assert.equal(result.isError, true);
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, false);
    assert.match(JSON.stringify(envelope), /artifact\.mime_mismatch/);
  }

  try {
    const sourcePath = join(root, "captions.vtt");
    const bytes = Buffer.from("WEBVTT\n\n00:00.000 --> 00:01.000\nÉté — こんにちは\n");
    await writeFile(sourcePath, bytes);
    const textPath = join(root, "ordinary.txt");
    const text = Buffer.from("ordinary text");
    await writeFile(textPath, text);
    const imagePath = join(root, "image.png");
    const image = Buffer.from("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/iZk9HQAAAABJRU5ErkJggg==", "base64");
    await writeFile(imagePath, image);
    await client.connect(transport);
    await call("pokemap_describe", { view: "compact" });
    const inferred = await call("pokemap_artifact_stage", { sourcePath });
    assert.equal(inferred.mediaType, "text/vtt");
    assert.equal(inferred.byteLength, bytes.length);
    assert.match(String(inferred.artifactHandle), /^artifact:\/\/sha256\/[0-9a-f]{64}$/);
    assert.equal(JSON.stringify(inferred).includes(sourcePath), false);
    const declared = await call("pokemap_artifact_stage", { sourcePath, declaredMediaType: "text/vtt" });
    assert.equal(declared.mediaType, "text/vtt");
    assert.equal(declared.artifactHandle, inferred.artifactHandle);
    assert.equal((await call("pokemap_artifact_stage", { sourcePath: textPath })).mediaType, "text/plain");
    await refuse({ sourcePath, declaredMediaType: "text/plain" });
    await refuse({ sourcePath: textPath, declaredMediaType: "text/vtt" });
    await refuse({ sourcePath: imagePath, declaredMediaType: "text/vtt" });
    for (const [content, expected] of [
      ["WEBVTTfoo", "text/plain"],
      ["WEBVTT\u0000", "application/octet-stream"],
      ["WEBVTT\n\u0000", "application/octet-stream"],
    ]) {
      const otherPath = join(root, "caption-like.txt");
      const otherBytes = Buffer.from(content!);
      await writeFile(otherPath, otherBytes);
      assert.equal((await call("pokemap_artifact_stage", { sourcePath: otherPath })).mediaType, expected);
      assert.deepEqual(await readFile(otherPath), otherBytes);
    }
    assert.deepEqual(await readFile(sourcePath), bytes);
    assert.deepEqual(await readFile(textPath), text);
    assert.deepEqual(await readFile(imagePath), image);
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

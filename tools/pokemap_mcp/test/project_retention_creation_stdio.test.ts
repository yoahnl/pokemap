import assert from "node:assert/strict";
import { mkdtemp, readFile, readdir, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import test from "node:test";

import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("live stdio creates and reopens an exact typed map retention policy", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-retention-creation-"));
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const client = new Client({ name: "retention-creation-proof", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  async function call(name: string, input: JsonRecord): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: input });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, true, JSON.stringify(envelope));
    return record(envelope.data);
  }
  try {
    await client.connect(transport);
    const description = await call("pokemap_describe", {});
    const descriptor = (description.commands as JsonRecord[]).find((entry) => entry.id === "project_create_preview");
    assert.equal(record(descriptor?.mapInstanceRetentionPolicy).dimension, "twoD");
    const policy = { schemaVersion: 1, viewportWidthTiles: 16, viewportHeightTiles: 12,
      marginTiles: 6, clampViewportToMapIds: ["future-map"] };
    const request = { name: "Retention QA", parentPath: root, folderName: "original", template: "empty",
      mapInstanceRetentionPolicy: policy };
    const preview = await call("pokemap_project_create_preview", { request });
    assert.deepEqual(record(preview.request).mapInstanceRetentionPolicy, policy);
    assert.deepEqual(await readdir(root), []);
    const mismatch = await client.callTool({ name: "pokemap_project_create", arguments: {
      request: { ...request, mapInstanceRetentionPolicy: { ...policy, marginTiles: 5 } },
      confirmation: preview.confirmation } });
    assert.equal(record(mismatch.structuredContent).ok, false);
    assert.deepEqual(await readdir(root), []);
    for (const invalid of [
      { ...policy, marginTiles: -1 }, { ...policy, viewportWidthTiles: 1.5 },
      { ...policy, unknown: true }, { ...policy, clampViewportToMapIds: ["same", "same"] },
    ]) {
      let rejected = false;
      try {
        const result = await client.callTool({ name: "pokemap_project_create_preview", arguments: {
          request: { ...request, mapInstanceRetentionPolicy: invalid } } });
        rejected = result.isError === true || record(result.structuredContent).ok === false;
      } catch { rejected = true; }
      assert.equal(rejected, true);
      assert.deepEqual(await readdir(root), []);
    }
    const created = await call("pokemap_project_create", { request, confirmation: preview.confirmation });
    const manifest = record(JSON.parse(await readFile(join(created.projectPath as string, "project.json"), "utf8")));
    assert.deepEqual(record(manifest.settings).mapInstanceRetentionPolicy, policy);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: created.projectPath });
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

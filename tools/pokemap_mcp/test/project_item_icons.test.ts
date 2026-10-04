import assert from "node:assert/strict";
import { cp, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
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

test("packaged MCP imports item icons as project-owned resources", { timeout: 120_000 }, async () => {
  const temporary = await mkdtemp(join(tmpdir(), "project-item-icons-mcp-"));
  const projectRoot = join(temporary, "project");
  await cp(resolve(process.cwd(), "../../examples/playable_runtime_host/golden_item_system"), projectRoot, { recursive: true });
  const sourcePath = join(projectRoot, "input.png");
  const pixels = Buffer.from("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLttAAAAABJRU5ErkJggg==", "base64");
  await writeFile(sourcePath, pixels);
  const args = [resolve(process.cwd(), "dist/src/index.js"), "--root", projectRoot];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "project-item-icons-test", version: "1.0.0" });
  try {
    await client.connect(transport);
    const description = await data(client, "pokemap_describe");
    assert.ok((description.mutationActions as JsonRecord[]).some((action) => action.id === "asset.import_batch"));
    const opened = await data(client, "pokemap_workspace", { operation: "open", projectRoot });
    const projectHandle = String(opened.projectHandle);
    const staged = await data(client, "pokemap_artifact_stage", { sourcePath, declaredMediaType: "image/png" });
    const validated = await data(client, "pokemap_validate", { projectHandle });
    const logicalPath = "data/pokemon/assets/items/potion.png";
    const planned = await data(client, "pokemap_plan", { projectHandle, request: {
      requestId: "project-item-icon", actionId: "asset.import_batch", actionVersion: 1,
      workspaceHandle: opened.workspaceHandle, parameters: { entries: [{
        artifactHandle: staged.artifactHandle, assetId: "item-icon-potion", logicalPath,
      }] }, expectedRevision: validated.snapshotRevision, idempotencyKey: "project-item-icon", dryRun: false,
    } });
    const applied = await data(client, "pokemap_apply", {
      operation: "apply", projectHandle, planId: planned.planId, operationId: "project-item-icon-import",
    });
    assert.equal(record(applied.receipt).status, "applied");
    assert.deepEqual(await readFile(join(projectRoot, logicalPath)), pixels);
    const catalog = record(JSON.parse(await readFile(join(projectRoot, "assets/.pokemap-assets.json"), "utf8")));
    assert.ok((catalog.records as JsonRecord[]).some((asset) => asset.logicalPath === logicalPath));
    await data(client, "pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await rm(temporary, { recursive: true, force: true });
  }
});

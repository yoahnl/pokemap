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

test("packaged MCP discovers and commits Studio native image import", { timeout: 120_000 }, async () => {
  const temporary = await mkdtemp(join(tmpdir(), "studio-resource-mcp-"));
  const projectRoot = join(temporary, "project");
  await cp(resolve(process.cwd(), "../../examples/playable_runtime_host/golden_item_system"), projectRoot, { recursive: true });
  const sourcePath = join(projectRoot, "input.png");
  const pixels = Buffer.from("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLttAAAAABJRU5ErkJggg==", "base64");
  await writeFile(sourcePath, pixels);
  const original = record(JSON.parse(await readFile(join(projectRoot, "project.json"), "utf8")));
  const mapPaths = (original.maps as JsonRecord[]).map((entry) => String(entry.relativePath));
  const mapBytes = await Promise.all(mapPaths.map((path) => readFile(join(projectRoot, path))));
  const args = [resolve(process.cwd(), "dist/src/index.js"), "--root", projectRoot];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "studio-resource-import-test", version: "1.0.0" });
  try {
    await client.connect(transport);
    const description = await data(client, "pokemap_describe");
    assert.ok((description.mutationActions as JsonRecord[]).some((action) => action.id === "tileset.import_image"));
    const opened = await data(client, "pokemap_workspace", { operation: "open", projectRoot });
    const projectHandle = String(opened.projectHandle);
    const staged = await data(client, "pokemap_artifact_stage", { sourcePath, declaredMediaType: "image/png" });
    const validated = await data(client, "pokemap_validate", { projectHandle });
    const planned = await data(client, "pokemap_plan", { projectHandle, request: {
      requestId: "studio-image", actionId: "tileset.import_image", actionVersion: 1,
      workspaceHandle: opened.workspaceHandle, parameters: {
        artifactHandle: staged.artifactHandle, tilesetId: "studio-image", name: "Studio image", tileWidth: 1, tileHeight: 1,
      }, expectedRevision: validated.snapshotRevision, idempotencyKey: "studio-image", dryRun: false,
    } });
    const applied = await data(client, "pokemap_apply", {
      operation: "apply", projectHandle, planId: planned.planId, operationId: "studio-image-import",
    });
    assert.equal(record(applied.receipt).status, "applied");
    const reloaded = record(JSON.parse(await readFile(join(projectRoot, "project.json"), "utf8")));
    const tileset = (reloaded.tilesets as JsonRecord[]).find((entry) => entry.id === "studio-image");
    assert.ok(tileset);
    assert.deepEqual(await readFile(join(projectRoot, String(tileset.relativePath))), pixels);
    for (let index = 0; index < mapPaths.length; index++) {
      assert.deepEqual(await readFile(join(projectRoot, mapPaths[index]!)), mapBytes[index]);
    }
    await data(client, "pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await rm(temporary, { recursive: true, force: true });
  }
});

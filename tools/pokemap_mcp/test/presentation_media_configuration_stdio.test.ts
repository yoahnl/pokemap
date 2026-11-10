import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { promisify } from "node:util";
import { test } from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("MCP configures presentation rights in a working catalog and reopens them", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "presentation-rights-mcp-"));
  const dart = process.env.POKEMAP_TEST_DART ?? "dart";
  const packageRoot = resolve("../../packages/map_authoring");
  const client = new Client({ name: "presentation-rights-proof", version: "1.0.0" });
  const transport = new StdioClientTransport({
    command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--dart", dart, "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe",
  });
  async function call(name: string, input: JsonRecord = {}): Promise<JsonRecord> {
    const result = record((await client.callTool({ name, arguments: input })).structuredContent);
    assert.equal(result.ok, true, JSON.stringify(result));
    return record(result.data);
  }
  try {
    await promisify(execFile)(dart, [
      `--packages=${join(packageRoot, ".dart_tool/package_config.json")}`,
      join(packageRoot, "test/support/create_working_catalog_fixture.dart"), root,
    ], { timeout: 60_000 });
    await mkdir(join(root, "assets"), { recursive: true });
    const mediaPath = join(root, "assets/.pokemap-media.json");
    const original = { id: "kabuto", label: "Kabuto", kind: "image", sourceAssetId: "asset-kabuto" };
    const other = { id: "other", label: "Other", kind: "image", sourceAssetId: "asset-other" };
    await writeFile(mediaPath, JSON.stringify({ schemaVersion: 1, entries: [original, other] }));
    const descriptor = await readFile(join(root, "project.json"));
    await client.connect(transport);
    const described = await call("pokemap_describe", { actionIds: ["presentationMedia.configure"], view: "full" });
    assert.equal(record((described.mutationActions as JsonRecord[])[0]).id, "presentationMedia.configure");
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    await call("pokemap_workshop", { operation: "prepare", projectHandle: opened.projectHandle });
    const parameters = {
      mediaId: "kabuto", posterMediaId: null, fallbackMediaId: null, captions: [],
      provenance: { source: "Original puzzle graphic" },
      license: { identifier: "NOASSERTION", name: "Rights reserved" },
    };
    const scope = await call("pokemap_workshop", {
      operation: "read", projectHandle: opened.projectHandle,
      actionId: "presentationMedia.configure", parameters, includeDocuments: false,
    });
    const planned = await call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
      requestId: "configure-kabuto", actionId: "presentationMedia.configure", actionVersion: 1,
      workspaceHandle: opened.workspaceHandle, expectedRevision: scope.snapshotRevision,
      extensions: scope.planExtensions ?? {}, idempotencyKey: "configure-kabuto", parameters,
    } });
    const applied = await call("pokemap_apply", {
      operation: "apply", projectHandle: opened.projectHandle,
      planId: planned.planId, operationId: "configure-kabuto-operation",
    });
    assert.equal(record(applied.receipt).status, "applied");
    assert.deepEqual(await readFile(join(root, "project.json")), descriptor);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
    const reopened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const result = await call("pokemap_query", {
      projectHandle: reopened.projectHandle, resourceKind: "presentationMedia",
      operation: "batch_get", ids: ["kabuto", "other"], view: "detail",
    });
    const items = (result.items as JsonRecord[]);
    const kabuto = record(items.find((item) => item.id === "kabuto"));
    assert.deepEqual(kabuto.provenance, parameters.provenance);
    assert.deepEqual(kabuto.license, parameters.license);
    const persisted = JSON.parse(await readFile(mediaPath, "utf8")) as { entries: JsonRecord[] };
    assert.deepEqual(persisted.entries.find((entry) => entry.id === "other"), other);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: reopened.workspaceHandle });
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

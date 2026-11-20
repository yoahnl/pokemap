import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { mkdtemp, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
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

test("MCP regrids only unused atlases and rereads the new grid", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "tileset-regrid-mcp-"));
  const dart = process.env.POKEMAP_TEST_DART ?? "dart";
  const packageRoot = resolve("../../packages/map_authoring");
  const client = new Client({ name: "tileset-regrid-proof", version: "1.0.0" });
  const transport = new StdioClientTransport({
    command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--dart", dart],
    cwd: process.cwd(),
    stderr: "pipe",
  });

  async function call(name: string, input: JsonRecord, success = true): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: input });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, success, JSON.stringify(envelope));
    return record(envelope[success ? "data" : "error"]);
  }

  try {
    await promisify(execFile)(dart, [
      `--packages=${join(packageRoot, ".dart_tool/package_config.json")}`,
      join(packageRoot, "test/support/tileset_regrid_fixture.dart"), root,
    ], { timeout: 60_000 });
    await client.connect(transport);
    const description = await call("pokemap_describe", { actionIds: ["tileset.regrid"] });
    const actions = description.mutationActions as JsonRecord[];
    assert.deepEqual(actions.map(action => action.id), ["tileset.regrid"]);
    const [action] = actions;
    assert.ok(action);
    assert.equal(record(action.extensions).preparationScope, "resourceIndexes");
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    await call("pokemap_workshop", { operation: "prepare", projectHandle: opened.projectHandle });
    await call("pokemap_workshop", { operation: "prepare", projectHandle: opened.projectHandle, scope: "resourceIndexes" });
    const query = { resourceKind: "tileset", operation: "get", ids: ["sheet"], view: "detail" };
    const before = await call("pokemap_query", { ...query, projectHandle: opened.projectHandle });
    const headPath = join(root, "catalog/HEAD.json");
    const imagePath = join(root, "assets/sheet.png");
    const [head, image, map] = await Promise.all([
      readFile(headPath), readFile(imagePath), readFile(join(root, "maps/garden.json")),
    ]);
    function plan(id: string, tilesetId: string, success = true, dryRun = false) {
      return call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
        requestId: id, actionId: "tileset.regrid", actionVersion: 1,
        workspaceHandle: opened.workspaceHandle, expectedRevision: before.snapshotRevision,
        idempotencyKey: id, dryRun, parameters: { tilesetId, tileWidth: 16, tileHeight: 16 },
      } }, success);
    }
    const blocked = await plan("blocked-grid", "used", false);
    assert.equal(blocked.domainCode, "catalog.definition_in_use");
    const preview = await plan("preview-grid", "sheet", true, true);
    assert.equal(preview.applicable, false);
    assert.deepEqual(await readFile(headPath), head);
    const prepared = await plan("plan-grid", "sheet");
    await call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle,
      planId: prepared.planId, operationId: "apply-grid" });
    assert.deepEqual(await readFile(imagePath), image);
    assert.deepEqual(await readFile(join(root, "maps/garden.json")), map);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });

    const reopened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const after = await call("pokemap_query", { ...query, projectHandle: reopened.projectHandle });
    const [updated] = after.items as JsonRecord[];
    assert.ok(updated);
    const source = record(updated.source);
    assert.equal(source.tileWidth, 16);
    assert.equal(source.tileHeight, 16);
    assert.equal(source.pixelWidth, 64);
    assert.equal(source.assetId, "asset-sheet");
    await call("pokemap_workspace", { operation: "close", workspaceHandle: reopened.workspaceHandle });
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

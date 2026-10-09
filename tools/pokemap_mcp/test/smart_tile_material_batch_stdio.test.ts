import assert from "node:assert/strict";
import { mkdtemp, readFile, rm } from "node:fs/promises";
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

test("live MCP upserts 217 Smart Tile materials atomically and preserves map data", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-material-batch-mcp-"));
  const transport = new StdioClientTransport({
    command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root],
    cwd: process.cwd(), stderr: "pipe",
  });
  const client = new Client({ name: "smart-tile-material-batch-proof", version: "1.0.0" });
  async function call(name: string, args: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: args });
    assert.equal(result.isError, failure ? true : undefined, JSON.stringify(result.structuredContent ?? result.content));
    const envelope = record(result.structuredContent);
    return record(failure ? envelope.error : envelope.data);
  }
  try {
    await client.connect(transport);
    const described = await call("pokemap_describe");
    const descriptor = (described.mutationActions as JsonRecord[])
      .find((action) => action.id === "smart_tile.material.upsert_batch")!;
    assert.equal(descriptor.version, 1);
    const extensions = record(descriptor.extensions);
    assert.equal(extensions.maximumMaterialCount, 250);
    assert.equal(extensions.batchAtomicity, "all_or_nothing");
    assert.equal(extensions.undoBoundary, "batch");
    const request = { name: "Materials", folderName: "materials", parentPath: root,
      template: "empty", dimension: "threeD", mapWidth: 8, mapHeight: 6 };
    const preview = await call("pokemap_project_create_preview", { request });
    const created = await call("pokemap_project_create", { request, confirmation: preview.confirmation });
    const projectRoot = String(created.projectPath);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    const projectHandle = String(opened.projectHandle);
    const workspaceHandle = String(opened.workspaceHandle);
    let sequence = 0;
    async function plan(actionId: string, parameters: JsonRecord, failure = false): Promise<JsonRecord> {
      const validation = await call("pokemap_validate", { projectHandle });
      const id = `materials-${++sequence}`;
      return call("pokemap_plan", { projectHandle, request: {
        requestId: id, actionId, actionVersion: 1, workspaceHandle, parameters,
        expectedRevision: validation.snapshotRevision, idempotencyKey: id,
      } }, failure);
    }
    async function mutate(actionId: string, parameters: JsonRecord): Promise<JsonRecord> {
      const planned = await plan(actionId, parameters);
      return call("pokemap_apply", { operation: "apply", projectHandle,
        planId: planned.planId, operationId: `apply-materials-${sequence}` });
    }
    await mutate("smart_tile.material.upsert", { material: {
      id: "grass", name: "Grass", connectionGroupId: "ground", terrainType: "grass",
    } });
    const manifestPath = join(projectRoot, "project.json");
    const beforeManifest = await readFile(manifestPath);
    const manifest = JSON.parse(beforeManifest.toString("utf8")) as JsonRecord;
    const mapEntry = record((manifest.maps as unknown[])[0]);
    const mapPath = join(projectRoot, String(mapEntry.relativePath));
    const beforeMap = await readFile(mapPath);
    const materials = Array.from({ length: 217 }, (_, index) => ({
      id: `boardwalk-${index}`, name: `Boardwalk ${index}`, connectionGroupId: "wood",
      pathSurfaceKind: "bridge", editorColorArgb: 4289361715,
    }));
    for (const [documents, expectedCode] of [
      [[], "smart_tile.material.batch_invalid"],
      [Array.from({ length: 251 }, () => materials[0]), "smart_tile.material.batch_invalid"],
      [[materials[0], materials[0]], "smart_tile.material.batch_duplicate"],
      [[materials[0], { id: "broken" }], "smart_tile.request_invalid"],
    ] as const) {
      const rejected = await plan("smart_tile.material.upsert_batch", { materials: documents }, true);
      assert.equal(rejected.domainCode, expectedCode);
      assert.deepEqual(await readFile(manifestPath), beforeManifest);
      assert.deepEqual(await readFile(mapPath), beforeMap);
    }
    const planned = await plan("smart_tile.material.upsert_batch", { materials });
    const planDocument = record(planned.plan);
    assert.equal(record(planDocument.preview).materialCount, 217);
    assert.equal(record(planDocument.preview).projectWidePreflight, "passed");
    assert.equal((record(planDocument.changeSet).changes as unknown[]).length, 1);
    const applyArgs = { operation: "apply", projectHandle,
      planId: planned.planId, operationId: `apply-materials-${sequence}` };
    const applied = await call("pokemap_apply", applyArgs);
    const replayed = await call("pokemap_apply", applyArgs);
    assert.deepEqual(replayed.receipt, applied.receipt);
    assert.equal(record(applied.receipt).status, "applied");
    assert.deepEqual(await readFile(mapPath), beforeMap);
    const after = JSON.parse(await readFile(manifestPath, "utf8")) as JsonRecord;
    const catalog = record(after.smartTileCatalog);
    assert.equal((catalog.materials as unknown[]).length, 218);
    assert.deepEqual((catalog.materials as JsonRecord[]).find((item) => item.id === "grass"),
      (record(manifest.smartTileCatalog).materials as JsonRecord[]).find((item) => item.id === "grass"));
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
    const reopened = await call("pokemap_workspace", { operation: "open", projectRoot });
    const queried = await call("pokemap_query", { projectHandle: reopened.projectHandle,
      resourceKind: "smartTileMaterial", operation: "batch_get", ids: ["boardwalk-0", "boardwalk-216"], view: "detail" });
    assert.equal((queried.items as unknown[]).length, 2);
    for (const item of queried.items as JsonRecord[]) {
      assert.equal(item.pathSurfaceKind, "bridge");
      assert.equal(item.editorColorArgb, 4289361715);
    }
    const history = await call("pokemap_history", { operation: "list", projectHandle: reopened.projectHandle, limit: 1 });
    await call("pokemap_history", { operation: "undo", projectHandle: reopened.projectHandle,
      entryId: record((history.entries as JsonRecord[])[0]).entryId, idempotencyKey: "undo-material-batch" });
    assert.deepEqual(await readFile(manifestPath), beforeManifest);
    assert.deepEqual(await readFile(mapPath), beforeMap);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: reopened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

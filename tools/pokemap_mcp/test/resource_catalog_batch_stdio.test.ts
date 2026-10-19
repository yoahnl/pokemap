import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { setTimeout as delay } from "node:timers/promises";
import { test } from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";
import { resourceManagementFixture } from "./resource_management_fixture.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("resource family and Environment batches cross real MCP and JSONL atomically", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "resource-catalog-batch-"));
  const manifestPath = join(root, "project.json");
  const mapPath = join(root, "garden.json");
  const original = resourceManagementFixture();
  await writeFile(manifestPath, JSON.stringify({ ...original,
    maps: [{ id: "garden", name: "Garden", relativePath: "garden.json" }],
  }));
  await writeFile(mapPath, JSON.stringify({ version: "v8", id: "garden", name: "Garden",
    size: { width: 2, height: 2 }, visualStack: { semanticsVersion: 1 },
    layers: [{ runtimeType: "tile", id: "ground", name: "Ground", cells: [0, 0, 0, 0] }],
  }));
  const beforeMap = await readFile(mapPath);
  const transport = new StdioClientTransport({ command: process.execPath,
    args: ["dist/src/index.js", "--root", root, "--dart", process.env.POKEMAP_TEST_DART ?? "dart",
      "--authoring-timeout-ms", "60000"], cwd: process.cwd(), stderr: "pipe" });
  let stderr = "";
  transport.stderr?.on("data", (chunk: Buffer) => { stderr += chunk.toString(); });
  const client = new Client({ name: "resource-catalog-batch", version: "1.0.0" });
  let lastCall = 0;
  async function envelope(name: string, args: JsonRecord): Promise<JsonRecord> {
    const wait = 150 - (Date.now() - lastCall);
    if (wait > 0) await delay(wait);
    lastCall = Date.now();
    const result = await client.callTool({ name, arguments: args }, { timeout: 60000 });
    return record(result.structuredContent);
  }
  async function data(name: string, args: JsonRecord): Promise<JsonRecord> {
    const result = await envelope(name, args);
    assert.equal(result.ok, true, `${JSON.stringify(result)}\n${stderr}`);
    return record(result.data);
  }
  let workspaceHandle: string | undefined;
  let sequence = 0;
  try {
    await client.connect(transport, { timeout: 60000 });
    const description = await data("pokemap_describe", {});
    const actions = new Map((description.mutationActions as JsonRecord[]).map(row => [row.id, row]));
    for (const id of ["environment.preset.upsert_batch", "resource.family.apply_batch"]) {
      const descriptor = actions.get(id);
      assert.ok(descriptor);
      assert.equal(descriptor.version, 1);
      const schema = record(record(descriptor.extensions).inputSchema);
      const properties = record(schema.properties);
      const field = id.startsWith("environment") ? "presets" : "families";
      assert.equal(record(properties[field]).maxItems, 50);
    }
    const opened = await data("pokemap_workspace", { operation: "open", projectRoot: root });
    workspaceHandle = String(opened.workspaceHandle);
    const projectHandle = opened.projectHandle;
    const initialQuery = await data("pokemap_query", { projectHandle, resourceKind: "project",
      operation: "get", ids: ["project"], view: "detail" });
    const initialProject = record((initialQuery.items as unknown[])[0]);
    async function plan(actionId: string, parameters: JsonRecord): Promise<JsonRecord> {
      const snapshot = await data("pokemap_query", { projectHandle, resourceKind: "project", operation: "summary" });
      const id = `catalog-batch-${sequence++}`;
      return envelope("pokemap_plan", { projectHandle, request: {
        requestId: id, actionId, actionVersion: 1, workspaceHandle,
        expectedRevision: snapshot.snapshotRevision, idempotencyKey: id, parameters, dryRun: false,
      } });
    }
    async function apply(actionId: string, parameters: JsonRecord): Promise<void> {
      const result = await plan(actionId, parameters);
      assert.equal(result.ok, true, JSON.stringify(result));
      const planned = record(result.data);
      const applied = await data("pokemap_apply", { operation: "apply", projectHandle,
        planId: planned.planId, operationId: `catalog-batch-apply-${sequence}` });
      assert.equal(record(applied.receipt).status, "applied");
    }
    await apply("resource.family.apply_batch", { families: [
      { operation: "create", familyId: "child", name: "Child", parentId: "parent" },
      { operation: "create", familyId: "parent", name: "Parent", parentId: "props" },
    ] });
    const preset = (id: string, elementId = "decor"): JsonRecord => ({ id, name: id, templateId: "forest",
      palette: [{ elementId, weight: 1, collisionMode: "useElementDefault", tags: [] }],
      defaultParams: { density: 1, variation: 0, edgeDensity: 1, minSpacingCells: 0 }, sortOrder: 0 });
    const beforeInvalid = await readFile(manifestPath);
    const rejected = await plan("environment.preset.upsert_batch", { presets: [preset("valid"), preset("invalid", "absent")] });
    assert.equal(rejected.ok, false);
    assert.deepEqual(await readFile(manifestPath), beforeInvalid);
    const duplicate = await plan("resource.family.apply_batch", { families: [
      { operation: "update", familyId: "child", name: "First" },
      { operation: "update", familyId: "child", name: "Second" },
    ] });
    assert.equal(duplicate.ok, false);
    assert.deepEqual(await readFile(manifestPath), beforeInvalid);
    await apply("environment.preset.upsert_batch", { presets: Array.from({ length: 50 }, (_, i) => preset(`forest-${i}`)) });
    await data("pokemap_workspace", { operation: "close", workspaceHandle });
    workspaceHandle = undefined;
    const persisted = record(JSON.parse(await readFile(manifestPath, "utf8")));
    const families = record(persisted.resourceLibraryCatalog).families as JsonRecord[];
    assert.equal(families.find(row => row.id === "child")?.parentId, "parent");
    assert.equal((persisted.environmentPresets as unknown[]).length, 50);
    assert.deepEqual(persisted.elements, initialProject.elements);
    assert.deepEqual(persisted.tilesets, initialProject.tilesets);
    assert.deepEqual(await readFile(mapPath), beforeMap);
    const reopened = await data("pokemap_workspace", { operation: "open", projectRoot: root });
    workspaceHandle = String(reopened.workspaceHandle);
    const found = await data("pokemap_query", { projectHandle: reopened.projectHandle, resourceKind: "environmentPreset",
      operation: "get", ids: ["forest-49"], view: "detail" });
    assert.equal(record((found.items as unknown[])[0]).id, "forest-49");
    await data("pokemap_workspace", { operation: "close", workspaceHandle });
    workspaceHandle = undefined;
  } finally {
    if (workspaceHandle) await data("pokemap_workspace", { operation: "close", workspaceHandle }).catch(() => {});
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

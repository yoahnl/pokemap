import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";
import { resourceManagementFixture } from "./resource_management_fixture.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("environment masks, generation and protected deletion cross real MCP stdio", async () => {
  const root = await mkdtemp(join(tmpdir(), "environment-stdio-"));
  const manifestPath = join(root, "project.json");
  const mapPath = join(root, "garden.json");
  const original = resourceManagementFixture();
  const preset = { id: "forest", name: "Forêt", templateId: "forest",
    palette: [{ elementId: "decor", weight: 1, collisionMode: "useElementDefault", tags: [] }],
    defaultParams: { density: 1, variation: 0, edgeDensity: 1, minSpacingCells: 0 }, sortOrder: 0 };
  await writeFile(manifestPath, JSON.stringify({ ...original, environmentPresets: [preset],
    maps: [{ id: "garden", name: "Jardin", relativePath: "garden.json" }] }));
  await writeFile(mapPath, JSON.stringify({ version: "v8", id: "garden", name: "Jardin",
    size: { width: 3, height: 3 }, visualStack: { semanticsVersion: 1 }, layers: [
      { runtimeType: "tile", id: "ground", name: "Sol", cells: Array(9).fill(0) },
      { runtimeType: "environment", id: "environment", name: "Forêt", content: {
        targetTileLayerId: "ground", areas: [] } },
    ] }));
  const transport = new StdioClientTransport({ command: process.execPath,
    args: ["dist/src/index.js", "--root", root, "--dart", process.env.POKEMAP_TEST_DART ?? "dart"],
    cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "environment-stdio", version: "1.0.0" });
  async function data(name: string, args: JsonRecord): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: args });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, true, JSON.stringify(envelope));
    return record(envelope.data);
  }
  try {
    await client.connect(transport);
    const catalog = await data("pokemap_describe", {});
    const actions = new Map((catalog.mutationActions as JsonRecord[]).map(action => [action.id, action]));
    const deletion = actions.get("environment.preset.delete")!;
    assert.equal(deletion.riskLevel, "high");
    const schema = record(record(deletion.extensions).inputSchema);
    assert.equal(schema.additionalProperties, false);
    assert.deepEqual(schema.required, ["presetId"]);
    const opened = await data("pokemap_workspace", { operation: "open", projectRoot: root });
    const projectHandle = opened.projectHandle;
    const initialQuery = await data("pokemap_query", { projectHandle, resourceKind: "project",
      operation: "get", ids: ["project"], view: "detail" });
    const initialProject = record((initialQuery.items as unknown[])[0]);
    let next = 0;
    async function plan(actionId: string, parameters: JsonRecord): Promise<JsonRecord> {
      const validation = await data("pokemap_validate", { projectHandle });
      const beforeManifest = await readFile(manifestPath);
      const beforeMap = await readFile(mapPath);
      const id = next++;
      const planned = await data("pokemap_plan", { projectHandle, request: {
        requestId: `environment-${id}`, actionId, actionVersion: 1,
        workspaceHandle: opened.workspaceHandle, expectedRevision: validation.snapshotRevision,
        idempotencyKey: `environment-${id}`, parameters, dryRun: false } });
      assert.deepEqual(await readFile(manifestPath), beforeManifest);
      assert.deepEqual(await readFile(mapPath), beforeMap);
      return planned;
    }
    async function mutate(actionId: string, parameters: JsonRecord): Promise<void> {
      const planned = await plan(actionId, parameters);
      const confirmation = actions.get(actionId)!.riskLevel === "high"
        ? (await data("pokemap_apply", { operation: "confirm", projectHandle, planId: planned.planId })).confirmationToken
        : undefined;
      const applied = await data("pokemap_apply", { operation: "apply", projectHandle,
        planId: planned.planId, operationId: `environment-apply-${next}`,
        ...(confirmation ? { confirmationToken: confirmation } : {}) });
      assert.equal(record(applied.receipt).status, "applied");
    }
    const target = { mapId: "garden", layerId: "environment", areaId: "area" };
    await mutate("environment.area_create", { ...target, name: "Lisière", presetId: "forest", seed: 37 });
    await mutate("environment.mask_paint", { ...target, cells: [{ x: 0, y: 0 }, { x: 2, y: 2 }] });
    await mutate("environment.generate_apply", target);
    const generated = record(JSON.parse(await readFile(mapPath, "utf8")));
    assert.deepEqual((generated.placedElements as JsonRecord[]).map(entry => entry.pos),
      [{ x: 0, y: 0 }, { x: 2, y: 2 }]);
    const validation = await data("pokemap_validate", { projectHandle });
    const rejected = await client.callTool({ name: "pokemap_plan", arguments: { projectHandle,
      request: { requestId: "environment-in-use", actionId: "environment.preset.delete", actionVersion: 1,
        workspaceHandle: opened.workspaceHandle, expectedRevision: validation.snapshotRevision,
        idempotencyKey: "environment-in-use", parameters: { presetId: "forest" }, dryRun: false } } });
    assert.equal(record(rejected.structuredContent).ok, false);
    await mutate("environment.area_delete", target);
    await mutate("environment.preset.delete", { presetId: "forest" });
    await data("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
    const persisted = record(JSON.parse(await readFile(manifestPath, "utf8")));
    assert.deepEqual(persisted.environmentPresets, []);
    assert.deepEqual(persisted.elements, initialProject.elements);
    assert.deepEqual(persisted.tilesets, initialProject.tilesets);
    assert.deepEqual(record(JSON.parse(await readFile(mapPath, "utf8"))).placedElements, []);
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

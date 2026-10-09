import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
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

test("live MCP paints one atomic material batch and rejects partial writes", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-cell-batch-mcp-"));
  const transport = new StdioClientTransport({
    command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root],
    cwd: process.cwd(), stderr: "pipe",
  });
  const client = new Client({ name: "smart-tile-batch-transport-proof", version: "1.0.0" });
  async function call(name: string, args: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: args });
    assert.equal(result.isError, failure ? true : undefined, JSON.stringify(result.structuredContent));
    const envelope = record(result.structuredContent);
    return record(failure ? envelope.error : envelope.data);
  }
  try {
    await client.connect(transport);
    const described = await call("pokemap_describe");
    const descriptor = (described.mutationActions as JsonRecord[])
      .find((action) => action.id === "smart_tile.cell.paint_batch")!;
    assert.equal(descriptor.version, 1);
    assert.equal(record(descriptor.extensions).maximumTotalCellCount, 65536);
    const request = { name: "Batch", folderName: "batch", parentPath: root,
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
      const id = `batch-${++sequence}`;
      return call("pokemap_plan", { projectHandle, request: {
        requestId: id, actionId, actionVersion: 1, workspaceHandle, parameters,
        expectedRevision: validation.snapshotRevision, idempotencyKey: id,
      } }, failure);
    }
    async function mutate(actionId: string, parameters: JsonRecord): Promise<JsonRecord> {
      const planned = await plan(actionId, parameters);
      return call("pokemap_apply", { operation: "apply", projectHandle,
        planId: planned.planId, operationId: `apply-batch-${sequence}` });
    }
    const manifest = JSON.parse(await readFile(join(projectRoot, "project.json"), "utf8")) as JsonRecord;
    const mapEntry = record((manifest.maps as unknown[])[0]);
    const mapId = String(mapEntry.id);
    const image = join(root, "ground.png");
    await writeFile(image, Buffer.from("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=", "base64"));
    const staged = await call("pokemap_artifact_stage", { sourcePath: image, declaredMediaType: "image/png" });
    await mutate("tileset.import_image", { artifactHandle: staged.artifactHandle,
      tilesetId: "ground-image", name: "Ground", tileWidth: 1, tileHeight: 1 });
    await mutate("smart_tile.atlas.upsert", { atlas: { id: "ground-atlas", name: "Ground",
      tilesetId: "ground-image", cellWidth: 1, cellHeight: 1, columns: 1, rows: 1 } });
    for (const materialId of ["grass", "path"]) await mutate("smart_tile.material.upsert",
      { material: { id: materialId, name: materialId, connectionGroupId: "ground" } });
    await mutate("smart_tile.preset.publish", {
      preset: { id: "ground", name: "Ground", usage: "terrain", topology: "uniform",
        templateHint: "simple", status: "draft", coveragePolicy: "complete",
        coverageProfile: { mode: "template" }, transformPolicy: {},
        defaultMaterialId: "grass", allowedMaterialIds: ["grass", "path"],
        rules: ["grass", "path"].map((materialId) => ({ id: materialId,
          centerMatch: { kind: "material", materialId }, signature: {},
          candidates: [{ id: materialId, parts: [{ source: { kind: "frame",
            frame: { atlasId: "ground-atlas", column: 0, row: 0 } } }] }],
        })),
      }, layer: { mapId, layerId: "terrain", name: "Terrain" },
    });
    const mapPath = join(projectRoot, String(mapEntry.relativePath));
    const beforeMap = await readFile(mapPath);
    const beforeManifest = await readFile(join(projectRoot, "project.json"));
    for (const [materialId, cells, expectedCode] of [
      ["missing", [{ x: 0, y: 1 }], "smart_tile.cell.material_not_allowed"],
      ["path", [{ x: 0, y: 0 }], "smart_tile.cell.batch_conflict"],
    ] as const) {
      const rejected = await plan("smart_tile.cell.paint_batch", { mapId, layerId: "terrain",
        strokes: [{ materialId: "grass", cells: [{ x: 0, y: 0 }] }, { materialId, cells }] }, true);
      assert.equal(rejected.domainCode, expectedCode);
      assert.deepEqual(await readFile(mapPath), beforeMap);
      assert.deepEqual(await readFile(join(projectRoot, "project.json")), beforeManifest);
    }
    const applied = await mutate("smart_tile.cell.paint_batch", { mapId, layerId: "terrain", strokes: [
      { materialId: "grass", cells: [{ x: 0, y: 0 }, { x: 0, y: 0 }, { x: 1, y: 0 }] },
      { materialId: "path", cells: [{ x: 0, y: 1 }, { x: 1, y: 1 }] },
    ] });
    assert.equal(record(applied.receipt).status, "applied");
    assert.deepEqual(await readFile(join(projectRoot, "project.json")), beforeManifest);
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
    const reopened = await call("pokemap_workspace", { operation: "open", projectRoot });
    const queried = await call("pokemap_query", { projectHandle: reopened.projectHandle,
      resourceKind: "map", operation: "get", ids: [mapId], view: "detail" });
    const map = record((queried.items as unknown[])[0]);
    const layer = (map.layers as JsonRecord[]).find((item) => item.id === "terrain")!;
    const palette = layer.materialPalette as string[];
    const cells = record(layer.field).semanticCells as number[];
    assert.deepEqual([0, 1, 8, 9].map((cellIndex) => palette[cells[cellIndex]!]),
      ["grass", "grass", "path", "path"]);
    assert.equal(map.version, "v9");
    await call("pokemap_workspace", { operation: "close", workspaceHandle: reopened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

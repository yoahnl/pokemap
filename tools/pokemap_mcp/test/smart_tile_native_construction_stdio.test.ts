import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import test from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";
import { canonicalPokemonConfig } from "./pokemon_fixture.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("live MCP authors whole native construction sections with bounds and atomic validation", { timeout: 120_000 }, async (context) => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-native-construction-"));
  const png = Buffer.from("iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAASUlEQVR42mNkoAA4LEj4D2MfSFjASI4ZTAwDDEYdMOqAUQeMOmDUAaMOGHAHMCJXqaNRMCBRMNoiGnXAqANGHTDqgFEHjHgHAADb/Qp9KEMvVQAAAABJRU5ErkJggg==", "base64");
  await writeFile(join(root, "native.png"), png);
  const catalog = {
    formatVersion: 8,
    atlases: [{ id: "atlas", name: "Native atlas", tilesetId: "tiles", cellWidth: 32, cellHeight: 32, columns: 1, rows: 1 }],
    materials: [{ id: "native", name: "Native", connectionGroupId: "native" }],
    presets: [{ id: "native", name: "Native construction", usage: "path", topology: "uniform", templateHint: "simple",
      defaultMaterialId: "native", allowedMaterialIds: ["native"], coveragePolicy: "sparse", coverageProfile: { mode: "template" },
      transformPolicy: {}, rules: [{ id: "empty", centerMatch: { kind: "material", materialId: "native" }, candidates: [{ id: "empty", parts: [] }] }] }],
    patterns: [],
  };
  await writeFile(join(root, "project.json"), JSON.stringify({
    name: "Native construction MCP", version: "v8", pokemon: canonicalPokemonConfig(),
    settings: { tileWidth: 32, tileHeight: 32 }, maps: [{ id: "map", name: "Map", relativePath: "map.json" }],
    tilesets: [{ id: "tiles", name: "Tiles", relativePath: "native.png" }], smartTileCatalog: catalog,
  }));
  await writeFile(join(root, "map.json"), JSON.stringify({
    version: "v8", id: "map", name: "Map", size: { width: 20, height: 20 }, visualStack: { semanticsVersion: 1 },
    layers: [{ runtimeType: "smart_tile", id: "native", name: "Native", presetId: "native", usage: "path", materialPalette: [""],
      field: { kind: "cell", semanticCells: Array(400).fill(0) }, patternStrokes: [] }],
  }));
  const pattern: JsonRecord = {
    id: "bridge", name: "Native bridge", usage: "path", width: 5, height: 4, repeatMode: "tiled",
    construction: { y: { repeatStart: 1, repeatLength: 2, minimumRepeats: 1 } },
    cells: Array.from({ length: 20 }, (_, n) => ({ x: n % 5, y: Math.floor(n / 5),
      parts: [{ source: { kind: "frame", frame: { atlasId: "atlas", column: 0, row: 0 } }, channel: "understory" }] })),
  };
  const client = new Client({ name: "native-construction-proof", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--dart", process.env.POKEMAP_TEST_DART ?? "dart", "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe" });
  async function envelope(name: string, args: JsonRecord = {}): Promise<JsonRecord> {
    return record((await client.callTool({ name, arguments: args })).structuredContent);
  }
  async function call(name: string, args: JsonRecord = {}): Promise<JsonRecord> {
    const result = await envelope(name, args);
    assert.equal(result.ok, true, JSON.stringify(result));
    return record(result.data);
  }
  try {
    await client.connect(transport);
    const described = await call("pokemap_describe");
    const describedNativeActions = (described.mutationActions as JsonRecord[]).filter(action =>
      ["smart_tile.pattern.upsert", "smart_tile.pattern.upsert_batch", "smart_tile.pattern.paint", "smart_tile.pattern.paint_batch"].includes(action.id as string));
    context.diagnostic(JSON.stringify({ describedNativeActions }));
    for (const id of ["smart_tile.pattern.upsert", "smart_tile.pattern.upsert_batch", "smart_tile.pattern.paint", "smart_tile.pattern.paint_batch"]) {
      const action = (described.mutationActions as JsonRecord[]).find(action => action.id === id);
      assert.ok(action);
      const contract = record(record(action.extensions).adaptiveConstruction2d);
      assert.equal(contract.minimumCatalogFormatVersion, 8);
      assert.equal(contract.fixedCrossSection, "expand_whole");
      assert.equal(contract.partialPeriods, "reject");
      const clipping = record(record(action.extensions).patternClipping);
      assert.equal(clipping.default, "clip");
      assert.deepEqual(clipping.values, ["clip", "reject"]);
      assert.ok(record(record(contract.schema).properties).y);
    }
    let opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    let sequence = 0;
    async function plan(actionId: string, parameters: JsonRecord): Promise<JsonRecord> {
      const validation = await call("pokemap_validate", { projectHandle: opened.projectHandle });
      const id = `construction-${++sequence}`;
      return envelope("pokemap_plan", { projectHandle: opened.projectHandle, request: {
        requestId: id, actionId, actionVersion: 1, workspaceHandle: opened.workspaceHandle,
        expectedRevision: validation.snapshotRevision, idempotencyKey: id, parameters,
      } });
    }
    async function mutate(actionId: string, parameters: JsonRecord): Promise<void> {
      const before = await readFile(join(root, "map.json"));
      const result = await plan(actionId, parameters);
      assert.equal(result.ok, true, JSON.stringify(result));
      assert.deepEqual(await readFile(join(root, "map.json")), before);
      const applied = await call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle,
        planId: record(result.data).planId, operationId: `apply-${++sequence}` });
      assert.equal(record(applied.receipt).status, "applied");
    }
    const fixedPattern = { ...pattern, id: "whole-stamp", construction: null, repeatMode: "stamp",
      clippingPolicy: "reject", anchorX: 2, anchorY: 1 };
    await mutate("smart_tile.pattern.upsert_batch", { patterns: [pattern, { ...pattern, id: "bridge-alt" }, fixedPattern] });
    const selection = (x: number, y: number, endY: number) => ({ kind: "line", start: { x, y }, end: { x, y: endY } });
    await mutate("smart_tile.pattern.paint", { mapId: "map", layerId: "native", patternId: "bridge", strokeId: "bridge", selection: selection(2, 2, 9) });
    let map = record(JSON.parse(await readFile(join(root, "map.json"), "utf8")));
    let strokes = record((map.layers as JsonRecord[])[0]).patternStrokes as JsonRecord[];
    assert.equal((strokes[0]!.cells as unknown[]).length, 40);
    assert.deepEqual(strokes[0]!.constructionBounds, { pos: { x: 2, y: 2 }, size: { width: 5, height: 8 } });
    const beforeInvalid = await readFile(join(root, "map.json"));
    for (const [invalid, expected] of [
      [{ kind: "rectangle", start: { x: 2, y: 2 }, end: { x: 5, y: 7 } }, "smart_tile.pattern.construction_size_invalid"],
      [selection(18, 2, 7), "smart_tile.pattern.construction_out_of_bounds"],
    ] as const) {
      const result = await plan("smart_tile.pattern.paint", { mapId: "map", layerId: "native", patternId: "bridge", strokeId: "invalid", selection: invalid });
      assert.equal(result.ok, false);
      assert.equal(record(record(result.error).details).domainCode, expected);
      assert.deepEqual(await readFile(join(root, "map.json")), beforeInvalid);
    }
    const invalidBatch = await plan("smart_tile.pattern.paint_batch", { mapId: "map", layerId: "native", strokes: [
      { patternId: "bridge", strokeId: "batch-a", selection: selection(8, 2, 7) },
      { patternId: "bridge-alt", strokeId: "batch-b", selection: selection(8, 10, 14) },
    ] });
    assert.equal(invalidBatch.ok, false);
    assert.deepEqual(await readFile(join(root, "map.json")), beforeInvalid);
    await mutate("smart_tile.pattern.paint_batch", { mapId: "map", layerId: "native", strokes: [
      { patternId: "bridge", strokeId: "batch-a", selection: selection(8, 2, 7) },
      { patternId: "bridge-alt", strokeId: "batch-b", selection: selection(8, 10, 13) },
    ] });
    await mutate("smart_tile.pattern.erase", { mapId: "map", layerId: "native", strokeIds: ["bridge"], cells: Array.from({ length: 5 }, (_, i) => ({ x: 2 + i, y: 2 })) });
    map = record(JSON.parse(await readFile(join(root, "map.json"), "utf8")));
    strokes = record((map.layers as JsonRecord[])[0]).patternStrokes as JsonRecord[];
    assert.equal(strokes.reduce((count, stroke) => count + (stroke.cells as unknown[]).length, 0), 85);
    assert.deepEqual(strokes[0]!.constructionBounds, { pos: { x: 2, y: 2 }, size: { width: 5, height: 8 } });
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
    opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const queried = await call("pokemap_query", { projectHandle: opened.projectHandle, resourceKind: "map", operation: "get", ids: ["map"], view: "detail" });
    assert.deepEqual(record((queried.items as JsonRecord[])[0]).layers, map.layers);
    await call("pokemap_validate", { projectHandle: opened.projectHandle });
    const manifest = record(JSON.parse(await readFile(join(root, "project.json"), "utf8")));
    assert.equal(record(manifest.smartTileCatalog).formatVersion, 9);
    assert.deepEqual((record(manifest.smartTileCatalog).patterns as JsonRecord[])[0]!.construction, pattern.construction);
    assert.equal(((record(manifest.smartTileCatalog).patterns as JsonRecord[]).find(p => p.id === "whole-stamp"))!.clippingPolicy, "reject");
    await mutate("smart_tile.pattern.paint", { mapId: "map", layerId: "native", patternId: "whole-stamp", strokeId: "whole",
      selection: { kind: "stamp", anchor: { x: 2, y: 12 } } });
    const beforeInvalidFixed = await readFile(join(root, "map.json"));
    const fixedBatch = await plan("smart_tile.pattern.paint_batch", { mapId: "map", layerId: "native", strokes: [
      { patternId: "whole-stamp", strokeId: "fixed-valid", selection: { kind: "stamp", anchor: { x: 8, y: 14 } } },
      { patternId: "whole-stamp", strokeId: "fixed-invalid", selection: { kind: "stamp", anchor: { x: 0, y: 0 } } },
    ] });
    assert.equal(fixedBatch.ok, false);
    assert.equal(record(record(fixedBatch.error).details).domainCode, "smart_tile.pattern.stamp_out_of_bounds");
    assert.deepEqual(await readFile(join(root, "map.json")), beforeInvalidFixed);
    await call("pokemap_validate", { projectHandle: opened.projectHandle });
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

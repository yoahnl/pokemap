import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join, resolve } from "node:path";
import test from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("exterior decoration survives cold MCP sessions without rewriting playable maps", {timeout: 120_000}, async () => {
  const base = process.env.POKEMAP_QA_ROOT ?? join(homedir(), "Library", "Caches", "AveluneQA", "exterior-decoration", "mcp");
  await mkdir(base, {recursive: true});
  const root = await mkdtemp(join(base, "fixture-"));
  const camera = {mode: "fixed", projection: "perspective", pitchDegrees: 48.7, yawDegrees: 0, fieldOfViewDegrees: 16.2, distance: 42, orthographicHeight: 12};
  const scene = (width: number, depth: number) => ({schemaVersion: 1, width, depth, heightLevels: Array(width * depth).fill(0), levelHeight: 1, generateCliffs: true, instances: [], camera});
  const map = JSON.stringify({id: "route", name: "Route", version: "v9", size: {width: 4, height: 4}, spatialScene: scene(4, 4), layers: []});
  await mkdir(join(root, "maps"));
  await writeFile(join(root, "maps/route.json"), map);
  await writeFile(join(root, "project.json"), "project must not be decoded");
  async function session(run: (call: (operation: string, input: JsonRecord, fails?: boolean) => Promise<JsonRecord>) => Promise<void>) {
    const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
    if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
    const transport = new StdioClientTransport({command: process.execPath, args, stderr: "pipe"});
    const client = new Client({name: "decoration-stdio-test", version: "1"});
    try {
      await client.connect(transport);
      await run(async (operation, input, fails = false) => {
        const result = await client.callTool({name: `pokemap_map_exterior_decoration_${operation}`, arguments: {projectRoot: root, mapId: "route", ...input}});
        const envelope = record(result.structuredContent);
        assert.equal(envelope.ok, !fails, JSON.stringify(envelope));
        return record(envelope[fails ? "error" : "data"]);
      });
    } finally {
      await client.close();
      await transport.close();
    }
  }
  let receiptId = "";
  try {
    await session(async call => {
      const before = await call("inspect", {});
      assert.equal(before.decoration, null);
      const decoration = {schemaVersion: 1, mapId: "route", playableWidth: 4, playableDepth: 4, west: 2, east: 0, north: 0, south: 0, sectors: []};
      const configured = await call("configure", {expectedRevision: before.revision, operationId: "configure", decoration});
      const input = {expectedRevision: configured.afterRevision, operationId: "plant-sector", sector: {id: "west", originX: -2, originZ: 0, scene: scene(2, 4), layers: []}};
      const planted = await call("sector_set", input);
      receiptId = String(record(planted.receipt).receiptId);
      assert.equal(record((await call("sector_set", input)).receipt).receiptId, receiptId);
      await call("sector_remove", {expectedRevision: configured.afterRevision, operationId: "stale-remove", sectorId: "west"}, true);
    });
    await session(async call => {
      const stored = await call("inspect", {});
      assert.deepEqual(stored.sectorIds, ["west"]);
      assert.equal((record(stored.decoration).sectors as unknown[]).length, 1);
      await call("undo", {expectedRevision: stored.revision, operationId: "undo-sector", receiptId});
      assert.deepEqual((await call("inspect", {})).sectorIds, []);
    });
    assert.equal(await readFile(join(root, "maps/route.json"), "utf8"), map);
    assert.equal(await readFile(join(root, "project.json"), "utf8"), "project must not be decoded");
  } finally {
    await rm(root, {recursive: true, force: true});
  }
});


test("native exterior MCP edits resolve the admitted catalog and retain complete trees", {timeout: 120_000}, async () => {
  const base = process.env.POKEMAP_QA_ROOT ?? join(homedir(), "Library", "Caches", "AveluneQA", "exterior-decoration", "mcp");
  await mkdir(base, {recursive: true});
  const root = await mkdtemp(join(base, "native-"));
  const transport = new StdioClientTransport({command: process.execPath, args: [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"], stderr: "pipe"});
  const client = new Client({name: "decoration-native-stdio-test", version: "1"});
  try {
    const generated = await promisify(execFile)(process.env.POKEMAP_TEST_DART ?? "dart", ["run", "test/support/exterior_decoration_fixture.dart", root], {cwd: resolve("../../packages/map_authoring"), timeout: 60_000});
    const fixture = record(JSON.parse(generated.stdout.trim()));
    const mapBefore = await readFile(join(root, "maps/route.json"));
    await client.connect(transport);
    async function call(operation: string, input: JsonRecord = {}, fails = false) {
      const result = await client.callTool({name: `pokemap_map_exterior_decoration_${operation}`, arguments: {projectRoot: root, mapId: "route", ...input}});
      const envelope = record(result.structuredContent);
      assert.equal(envelope.ok, !fails, JSON.stringify(envelope));
      return record(envelope[fails ? "error" : "data"]);
    }
    const described = await client.callTool({name: "pokemap_describe", arguments: {}});
    const description = record(described.structuredContent);
    assert.equal(description.ok, true);
    const liveCatalog = JSON.stringify(description.data);
    for (const id of ["map.exteriorDecoration.configure", "map.exteriorDecoration.sector.batch", "map.exteriorDecoration.native.edit", "map.exteriorDecoration.references.prepare", "map_exterior_decoration_references_prepare", "map_exterior_decoration_native_catalog", "map_exterior_decoration_native_edit", "map_exterior_decoration_sector_batch"]) {
      assert.ok(liveCatalog.includes(`"${id}"`), id);
    }
    const catalog = await call("native_catalog");
    assert.equal(catalog.catalogRevision, fixture.catalogRevision);
    const prepared = await call("references_prepare", {expectedRevision: fixture.revision, operationId: "prepare-incoming"});
    assert.equal(prepared.afterRevision, fixture.revision);
    const environment = await call("native_edit", {expectedRevision: fixture.revision, expectedCatalogRevision: catalog.catalogRevision, operationId: "native-tree", edit: {kind: "environment.generate", sectorId: "west", presetId: "forest", cells: [{x: -8, z: 8}], areaId: "trees", seed: 42}});
    const input = {expectedRevision: environment.afterRevision, expectedCatalogRevision: catalog.catalogRevision, operationId: "native-grass", edit: {kind: "terrain.paint", sectorId: "west", presetId: "grass", cells: [{x: -8, z: 8}]}};
    const painted = await call("native_edit", input);
    assert.equal(record((await call("native_edit", input)).receipt).receiptId, record(painted.receipt).receiptId);
    const after = await call("inspect");
    const sector = record((record(after.decoration).sectors as unknown[])[0]);
    assert.equal((record(sector.scene).instances as unknown[]).length, 1);
    assert.equal(record((record(sector.scene).instances as unknown[])[0]).modelId, "oak");
    assert.ok((sector.layers as unknown[]).length >= 2);
    await call("native_edit", {...input, expectedRevision: painted.afterRevision, expectedCatalogRevision: "sha256:stale", operationId: "native-stale"}, true);
    assert.equal((await call("inspect")).revision, painted.afterRevision);
    assert.deepEqual(await readFile(join(root, "maps/route.json")), mapBefore);
  } finally {
    await client.close();
    await transport.close();
    await rm(root, {recursive: true, force: true});
  }
});

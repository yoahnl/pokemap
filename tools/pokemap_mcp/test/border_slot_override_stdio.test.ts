import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";
import { canonicalPokemonConfig } from "./pokemon_fixture.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

function feature(map: JsonRecord, id = "target"): JsonRecord {
  const layer = (map.layers as JsonRecord[]).find(value => value.id === "border");
  assert.ok(layer);
  const result = (record(layer.content).features as JsonRecord[]).find(value => value.id === id);
  assert.ok(result);
  return result;
}

function slots(value: JsonRecord): JsonRecord[] {
  return record(value.materialization).placements as JsonRecord[];
}

async function seed(root: string): Promise<void> {
  const snapshotHash = "a".repeat(64);
  const snapshotId = `border-snapshot-sha256:${snapshotHash}`;
  const snapshotPath = `assets/borders/snapshots/${snapshotHash}.png`;
  const metrics = { assetFingerprint: "source", pixelSize: { width: 32, height: 32 },
    opaqueBounds: { x: 0, y: 0, width: 32, height: 32 }, defaultAnchorPx: { x: 16, y: 16 },
    occupancyMaskRle: "border-rle-v1:1024:1:1024" };
  const defaults = { irregularityPermille: 0, detailDensityPermille: 0, variationPermille: 0,
    maxOverlapPx: 32, gapTolerancePx: 32, depthRows: 1 };
  const primitives = ["lineCap", "lineStraight", "lineCorner", "alternate"].map(id => ({
    id, sourceElementId: "sprite", visualSnapshotId: snapshotId,
    role: id === "alternate" ? "lineStraight" : id, weight: 1, anchorPx: { x: 16, y: 16 },
    transforms: { allowedQuarterTurns: [0, 1, 2, 3], allowFlipX: true }, publishedMetrics: metrics,
  }));
  const definition = { name: "Fence", previewSeed: "0", template: "connectedLine",
    primitives, defaults, sortOrder: 0 };
  const makeFeature = (id: string, y: number) => ({ id, name: id, blueprintId: "fence", seed: "0",
    geometry: { kind: "stroke", strokes: [{ id: `${id}-line`, closed: false,
      points: [1, 2, 3].map(x => ({ x, y })) }] }, overrides: [], keepOutRegions: [] });
  await mkdir(join(root, "maps"), { recursive: true });
  await mkdir(join(root, "assets/borders/snapshots"), { recursive: true });
  const png = Buffer.from("iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAI0lEQVR4nO3WAREAAAQEMPp39k4OW4rVJCkA4LP2AQB47SqwWugL866rJOcAAAAASUVORK5CYII=", "base64");
  await writeFile(join(root, "atlas.png"), png);
  await writeFile(join(root, snapshotPath), png);
  await writeFile(join(root, "project.json"), JSON.stringify({ version: "v8", name: "Slot transport",
    pokemon: canonicalPokemonConfig(), maps: [{ id: "map", name: "Map", relativePath: "maps/map.json" }],
    tilesets: [{ id: "atlas", name: "Atlas", relativePath: "atlas.png" }],
    settings: { tileWidth: 32, tileHeight: 32 }, elements: [{ id: "sprite", name: "Sprite",
      tilesetId: "atlas", categoryId: "border", frames: [{ source: { x: 0, y: 0, width: 1, height: 1 } }] }],
    borderCatalog: { formatVersion: 5, records: [{ id: "fence", draft: { baseRevision: 1,
      definition: { ...definition, primitives: primitives.map(({ publishedMetrics, visualSnapshotId: _snapshot, ...primitive }) => ({ ...primitive, currentMetrics: publishedMetrics })) } },
      latestPublished: { revision: 1, definition } }], visualSnapshots: [{ id: snapshotId,
      contentFingerprint: snapshotHash, frames: [{ relativeAssetPath: snapshotPath,
        sourceRectPx: { x: 0, y: 0, width: 32, height: 32 }, durationMs: 120 }] }] },
  }));
  await writeFile(join(root, "maps/map.json"), JSON.stringify({ version: "v8", id: "map", name: "Map",
    size: { width: 8, height: 7 }, visualStack: { semanticsVersion: 1 },
    layers: [{ runtimeType: "border", id: "border", name: "Borders", content: { formatVersion: 3,
      features: [makeFeature("target", 2), makeFeature("other", 4)] } }],
  }));
}

test("MCP authors exact Border slot fields, rejects invalid/stale plans and restores canonical output", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-slot-overrides-mcp-"));
  await seed(root);
  const manifestPath = join(root, "project.json"), mapPath = join(root, "maps/map.json");
  const client = new Client({ name: "border-slot-overrides", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--dart", process.env.POKEMAP_TEST_DART ?? "dart",
      "--authoring-timeout-ms", "60000"], cwd: process.cwd(), stderr: "pipe" });
  async function call(name: string, arguments_: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const response = await client.callTool({ name, arguments: arguments_ });
    const envelope = record(response.structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify(envelope));
    return record(envelope[failure ? "error" : "data"]);
  }
  try {
    await client.connect(transport);
    const catalog = await call("pokemap_describe");
    const fields: Record<string, string | undefined> = { replacement: "primitiveId", offset: "offsetDeltaPx",
      transform: "transformOverride", suppressed: "suppressed", clear_slot_override: undefined };
    for (const [kind, field] of Object.entries(fields)) {
      const id = kind === "clear_slot_override" ? "border_layer.feature_clear_slot_override" : `border_layer.feature_set_${kind}`;
      const action = (catalog.mutationActions as JsonRecord[]).find(value => value.id === id);
      assert.ok(action, `${id} must be discoverable`);
      assert.equal(action.version, 1);
      assert.equal(action.inputSchemaId, `schema.${id}.input.v1`);
      const schema = record(record(action.extensions).inputSchema);
      assert.equal(schema.additionalProperties, false);
      assert.deepEqual([...(schema.required as string[])].sort(),
        ["mapId", "layerId", "featureId", "slotKey", ...(field ? [field] : [])].sort());
      assert.deepEqual(Object.keys(record(schema.properties)).sort(),
        ["mapId", "layerId", "featureId", "slotKey", ...(field ? [field] : [])].sort());
      const properties = record(schema.properties);
      if (kind === "replacement") assert.deepEqual(record(properties.primitiveId).type, ["string", "null"]);
      if (kind === "suppressed") assert.equal(record(properties.suppressed).type, "boolean");
      if (kind === "offset" || kind === "transform") {
        const variants = record(properties[field!]).anyOf as JsonRecord[];
        assert.ok(variants.some(value => value.type === "null"));
        const objectSchema = variants.find(value => value.type === "object");
        assert.ok(objectSchema);
        assert.equal(objectSchema.additionalProperties, false);
        assert.deepEqual([...(objectSchema.required as string[])].sort(),
          kind === "offset" ? ["x", "y"] : ["flipX", "quarterTurns"]);
        const nested = record(objectSchema.properties);
        if (kind === "offset") {
          assert.equal(record(nested.x).type, "integer");
          assert.equal(record(nested.y).type, "integer");
        } else {
          assert.equal(record(nested.quarterTurns).minimum, 0);
          assert.equal(record(nested.quarterTurns).maximum, 3);
          assert.equal(record(nested.flipX).type, "boolean");
        }
      }
    }
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    let sequence = 0;
    const target = { mapId: "map", layerId: "border", featureId: "target" };
    async function plan(actionId: string, parameters: JsonRecord, failure = false): Promise<JsonRecord> {
      const validation = await call("pokemap_validate", { projectHandle: opened.projectHandle });
      const before = await readFile(mapPath), manifest = await readFile(manifestPath);
      const id = `slot-${++sequence}`;
      const result = await call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
        actionId, actionVersion: 1, parameters, requestId: id, idempotencyKey: id,
        workspaceHandle: opened.workspaceHandle, expectedRevision: validation.snapshotRevision } }, failure);
      assert.deepEqual(await readFile(mapPath), before);
      assert.deepEqual(await readFile(manifestPath), manifest);
      return result;
    }
    async function apply(planned: JsonRecord, failure = false): Promise<JsonRecord> {
      return call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle,
        planId: planned.planId, operationId: `apply-${++sequence}` }, failure);
    }
    async function mutate(action: string, parameters: JsonRecord): Promise<void> {
      const result = await apply(await plan(action, parameters));
      assert.equal(record(result.receipt).status, "applied");
    }
    async function query(): Promise<JsonRecord> {
      const result = await call("pokemap_query", { projectHandle: opened.projectHandle,
        resourceKind: "map", operation: "get", ids: ["map"], view: "detail" });
      return record((result.items as JsonRecord[])[0]);
    }
    const materialize = { ...target, tileWidthPx: 32, tileHeightPx: 32, resolverVersion: 3 };
    await mutate("border_layer.materialize_apply", materialize);
    await mutate("border_layer.materialize_apply", { ...materialize, featureId: "other" });
    const initial = await query(), original = feature(initial), other = feature(initial, "other");
    const originalSlots = slots(original);
    const middle = originalSlots.find(value => record(value.anchorCell).x === 2);
    assert.ok(middle);
    const slot = { ...target, slotKey: middle.slotKey };
    const manifest = await readFile(manifestPath);
    const history = await call("pokemap_history", { operation: "list", projectHandle: opened.projectHandle, limit: 10 });
    for (const [action, parameters, code] of [
      ["border_layer.feature_set_replacement", { ...slot, primitiveId: "missing" }, "border"],
      ["border_layer.feature_set_offset", { ...slot, slotKey: "missing", offsetDeltaPx: { x: 1, y: 0 } }, "border"],
      ["border_layer.feature_set_transform", { ...slot, transformOverride: { quarterTurns: 4, flipX: false } }, "invalid"],
    ] as [string, JsonRecord, string][]) {
      const rejected = await plan(action, parameters, true);
      assert.ok(JSON.stringify(rejected).includes(code), JSON.stringify(rejected));
    }
    assert.deepEqual((await call("pokemap_history", { operation: "list", projectHandle: opened.projectHandle, limit: 10 })).entries, history.entries);
    const stale = await plan("border_layer.feature_set_suppressed", { ...slot, suppressed: true });
    await mutate("border_layer.feature_set_replacement", { ...slot, primitiveId: "alternate" });
    let saved = await query();
    assert.deepEqual(feature(saved).materialization, original.materialization);
    const beforeStale = await readFile(mapPath);
    const conflict = await apply(stale, true);
    assert.equal(conflict.domainCode, "plan.stale");
    assert.deepEqual(await readFile(mapPath), beforeStale);
    await mutate("border_layer.feature_set_offset", { ...slot, offsetDeltaPx: { x: 1, y: 2 } });
    await mutate("border_layer.feature_set_transform", { ...slot, transformOverride: { quarterTurns: 1, flipX: true } });
    await mutate("border_layer.materialize_apply", materialize);
    saved = await query();
    const changed = feature(saved), overridden = (changed.overrides as JsonRecord[]).find(value => value.slotKey === slot.slotKey);
    assert.ok(overridden);
    assert.equal(overridden.replacementPrimitiveId, "alternate");
    assert.deepEqual(overridden.offsetDeltaPx, { x: 1, y: 2 });
    assert.deepEqual(overridden.transformOverride, { quarterTurns: 1, flipX: true });
    const moved = slots(changed).find(value => value.slotKey === slot.slotKey);
    assert.ok(moved);
    assert.equal(moved.primitiveId, "alternate");
    assert.deepEqual(moved.transform, { quarterTurns: 1, flipX: true });
    assert.notDeepEqual(moved.topLeftWorldPx, middle.topLeftWorldPx);
    assert.notEqual(record(record(changed.materialization).receipt).inputFingerprint,
      record(record(original.materialization).receipt).inputFingerprint);
    for (const [action, field, value, restored] of [
      ["border_layer.feature_set_replacement", "primitiveId", "replacementPrimitiveId", "alternate"],
      ["border_layer.feature_set_offset", "offsetDeltaPx", "offsetDeltaPx", { x: 1, y: 2 }],
      ["border_layer.feature_set_transform", "transformOverride", "transformOverride", { quarterTurns: 1, flipX: true }],
    ] as [string, string, string, unknown][]) {
      await mutate(action, { ...slot, [field]: null });
      const clearedField = (feature(await query()).overrides as JsonRecord[]).find(override => override.slotKey === slot.slotKey);
      assert.ok(clearedField);
      assert.equal(Object.hasOwn(clearedField, value), false);
      await mutate(action, { ...slot, [field]: restored });
    }
    await mutate("border_layer.feature_set_suppressed", { ...slot, suppressed: true });
    await mutate("border_layer.materialize_apply", materialize);
    assert.equal(slots(feature(await query())).length, originalSlots.length - 1);
    await mutate("border_layer.feature_clear_slot_override", slot);
    await mutate("border_layer.materialize_apply", materialize);
    const cleared = await query();
    assert.deepEqual(feature(cleared).overrides, []);
    assert.deepEqual(slots(feature(cleared)), originalSlots);
    assert.deepEqual(feature(cleared, "other"), other);
    assert.deepEqual(await readFile(manifestPath), manifest);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

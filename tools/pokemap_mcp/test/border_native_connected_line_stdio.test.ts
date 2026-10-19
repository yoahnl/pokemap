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

for (const allowFlipX of [false, true]) {
test(`live MCP publishes native connected-line directions with mirrors ${allowFlipX ? "permitted" : "forbidden"} and reopens exact output`, { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-native-connected-"));
  const png = Buffer.from("iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAASUlEQVR42mNkoAA4LEj4D2MfSFjASI4ZTAwDDEYdMOqAUQeMOmDUAaMOGHAHMCJXqaNRMCBRMNoiGnXAqANGHTDqgFEHjHgHAADb/Qp9KEMvVQAAAABJRU5ErkJggg==", "base64");
  await writeFile(join(root, "native.png"), png);
  await writeFile(join(root, "project.json"), JSON.stringify({
    name: "Native connected directions", version: "v8", pokemon: canonicalPokemonConfig(),
    settings: { tileWidth: 32, tileHeight: 32 },
    maps: [{ id: "map", name: "Map", relativePath: "map.json" }],
    tilesets: [{ id: "atlas", name: "Atlas", relativePath: "native.png" }],
    elements: [{ id: "sprite", name: "Native source", tilesetId: "atlas", categoryId: "border",
      frames: [{ source: { x: 0, y: 0, width: 1, height: 1 } }] }],
    elementCategories: [{ id: "border", name: "Border" }],
  }));
  await writeFile(join(root, "map.json"), JSON.stringify({
    version: "v8", id: "map", name: "Map", size: { width: 8, height: 8 },
    visualStack: { semanticsVersion: 1 },
    layers: [{ runtimeType: "border", id: "border", name: "Borders", content: { formatVersion: 3, features: [] } }],
  }));
  const client = new Client({ name: "native-connected-proof", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--dart", process.env.POKEMAP_TEST_DART ?? "dart",
      "--authoring-timeout-ms", "60000"], cwd: process.cwd(), stderr: "pipe" });
  async function call(name: string, args: JsonRecord = {}): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: args });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, true, JSON.stringify(envelope));
    return record(envelope.data);
  }
  try {
    await client.connect(transport);
    const catalog = await call("pokemap_describe");
    const action = (catalog.mutationActions as JsonRecord[]).find(value => value.id === "border.blueprint.publish");
    assert.ok(action);
    const contract = record(record(action.extensions).nativeConnectedLine2d);
    assert.equal(contract.mirrorFreeLineSide, "primary");
    assert.equal(contract.minimumCatalogFormatVersion, 4);
    assert.equal(contract.mirroredRotation, "targetPlusAuthored");
    assert.deepEqual(contract.orientationReference, { east: 0, south: 1, west: 2, north: 3 });
    let opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    let sequence = 0;
    async function mutate(actionId: string, parameters: JsonRecord): Promise<void> {
      const validation = await call("pokemap_validate", { projectHandle: opened.projectHandle });
      const before = await readFile(join(root, "map.json"));
      const id = `native-${++sequence}`;
      const planned = await call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
        requestId: id, actionId, actionVersion: 1, workspaceHandle: opened.workspaceHandle,
        expectedRevision: validation.snapshotRevision, idempotencyKey: id, parameters,
      } });
      assert.deepEqual(await readFile(join(root, "map.json")), before);
      const applied = await call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle,
        planId: planned.planId, operationId: `apply-${++sequence}` });
      assert.equal(record(applied.receipt).status, "applied");
    }
    const metrics = {
      assetFingerprint: "sha256:8d2b6553ac7ca3ec6d049ff414f3aa9a47085b8d38aface7f325e71407842d9b",
      pixelSize: { width: 32, height: 32 }, opaqueBounds: { x: 0, y: 0, width: 32, height: 32 },
      defaultAnchorPx: { x: 16, y: 16 },
      occupancyMaskRle: "border-rle-v1:1024:0:15,3,29,3,29,3,29,3,29,3,29,3,29,3,29,3,29,3,29,3,29,3,29,3,29,3,29,3,29,3,14,96,15,3,29,3,29,3,29,3,29,3,29,3,29,3,29,3,29,3,29,3,29,3,29,3,29,3,29,3,14",
    };
    const primitives = ["lineCap", "lineStraight", "lineCorner"].flatMap(role =>
      ["east", "south", "west", "north"].map(authoredOrientation => ({
        id: `${role}-${authoredOrientation}`, role, authoredOrientation, sourceElementId: "sprite",
        weight: 1, anchorPx: { x: 16, y: 16 }, currentMetrics: metrics,
        transforms: { allowedQuarterTurns: [0], allowFlipX },
      })));
    const definition = { name: "Native fence", template: "connectedLine", previewSeed: "0", sortOrder: 0,
      defaults: { irregularityPermille: 0, detailDensityPermille: 0, variationPermille: 0,
        maxOverlapPx: 8, gapTolerancePx: 0, depthRows: 1, allowAutoRotation: allowFlipX }, primitives };
    await mutate("border.blueprint.draft.upsert", { record: { id: "native", draft: { baseRevision: 0, definition } } });
    const artifact = await call("pokemap_artifact_stage", { sourcePath: join(root, "native.png"), declaredMediaType: "image/png" });
    await mutate("border.blueprint.publish", { blueprintId: "native",
      acceptedWarningCodes: ["border.publication.repetition_run"],
      primitiveSources: primitives.map(primitive => ({ primitiveId: primitive.id,
        frames: [{ artifactHandle: artifact.artifactHandle, sourceProjectRelativePath: "native.png" }] })),
    });
    const target = { mapId: "map", layerId: "border", featureId: "native-feature" };
    await mutate("border_layer.feature_create", { ...target, name: "Native trace", blueprintId: "native", seed: "0",
      geometry: { kind: "stroke", strokes: [{ id: "main", closed: false,
        points: [{ x: 1, y: 2 }, { x: 2, y: 2 }, { x: 3, y: 2 }, { x: 3, y: 3 }, { x: 3, y: 4 }] }] } });
    await mutate("border_layer.materialize_apply", { ...target, tileWidthPx: 32, tileHeightPx: 32, resolverVersion: 4 });
    const saved = await readFile(join(root, "map.json"));
    const map = record(JSON.parse(saved.toString()));
    const feature = (record((map.layers as JsonRecord[])[0]!.content).features as JsonRecord[])[0]!;
    const placements = record(feature.materialization).placements as JsonRecord[];
    assert.deepEqual(placements.map(p => p.primitiveId), ["lineCap-east", "lineStraight-east", "lineCorner-east", "lineStraight-south", "lineCap-north"]);
    assert.ok(placements.every(p => record(p.transform).quarterTurns === 0 && record(p.transform).flipX === false));
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
    opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const queried = await call("pokemap_query", { projectHandle: opened.projectHandle, resourceKind: "map", operation: "get", ids: ["map"], view: "detail" });
    const reopenedMap = record((queried.items as JsonRecord[])[0]);
    assert.deepEqual(record((reopenedMap.layers as JsonRecord[])[0]!.content).features, record((map.layers as JsonRecord[])[0]!.content).features);
    assert.deepEqual(await readFile(join(root, "map.json")), saved);
    assert.deepEqual(await readFile(join(root, "native.png")), png);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});
}

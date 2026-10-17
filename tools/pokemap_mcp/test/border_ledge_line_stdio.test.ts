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

for (const gap of [0, 8]) {
test(`live MCP publishes and reopens a native cardinal ledgeLine with visual gap ${gap}`, async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-native-ledge-mcp-"));
  const pixels = gap === 8 ? Buffer.from("iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAQUlEQVR4nO3OQREAEBRAQWbkkEkcEcSRSREaGBfzL/sKvC0puAIAAAAAAAAQDuit7p+DMVe+An7OXwIAAAAAAAA4pk0EgaM32K8AAAAASUVORK5CYII=", "base64") : Buffer.from(
    "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAI0lEQVR4nO3WAREAAAQEMPp39k4OW4rVJCkA4LP2AQB47SqwWugL866rJOcAAAAASUVORK5CYII=",
    "base64",
  );
  const sourcePath = join(root, "south.png");
  const manifestPath = join(root, "project.json");
  await writeFile(sourcePath, pixels);
  await writeFile(manifestPath, JSON.stringify({
    name: "Native ledge fixture", version: "v8", maps: [],
    settings: { tileWidth: 32, tileHeight: 32 },
    pokemon: canonicalPokemonConfig(),
    tilesets: [{ id: "source", name: "Source", relativePath: "south.png" }],
    elements: [{ id: "south", name: "Rebord", tilesetId: "source", categoryId: "border",
      frames: [{ source: { x: 0, y: 0, width: 1, height: 1 } }] }],
  }));
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root,
      "--dart", process.env.POKEMAP_TEST_DART ?? "dart",
      "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "native-ledge-proof", version: "1.0.0" });
  async function call(name: string, args: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const response = await client.callTool({ name, arguments: args });
    assert.equal(response.isError, failure ? true : undefined,
      JSON.stringify(response.structuredContent));
    const envelope = record(response.structuredContent);
    return record(failure ? envelope.error : envelope.data);
  }
  try {
    await client.connect(transport);
    const catalog = await call("pokemap_describe");
    for (const id of ["border.blueprint.draft.upsert", "border.blueprint.publish"]) {
      const action = (catalog.mutationActions as JsonRecord[]).find(value => value.id === id);
      assert.ok(action);
      const extension = record(record(action.extensions).ledgeLine);
      assert.equal(extension.alignment, "gridEdges");
      assert.equal(extension.minimumCatalogFormatVersion, 7);
      assert.equal(extension.modulesPerUnitEdge, 1);
      assert.equal(extension.automaticRotation, false);
      assert.equal(extension.jumpSideChangesVisuals, false);
      assert.equal(record(extension.visualGapTolerance).changesCollision, false);
      assert.equal(record(extension.visualGapTolerance).coverage, "allAdmissibleVariantPairs");
    }
    let opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    let projectHandle = String(opened.projectHandle);
    let workspaceHandle = String(opened.workspaceHandle);
    let sequence = 0;
    async function mutate(actionId: string, parameters: JsonRecord, failure = false): Promise<JsonRecord> {
      const validation = await call("pokemap_validate", { projectHandle });
      const before = await readFile(manifestPath);
      const id = `ledge-${sequence++}`;
      const planned = await call("pokemap_plan", { projectHandle, request: {
        requestId: id, actionId, actionVersion: 1, workspaceHandle, parameters,
        expectedRevision: validation.snapshotRevision, idempotencyKey: id,
      } }, failure);
      assert.deepEqual(await readFile(manifestPath), before);
      if (failure) return planned;
      const applied = await call("pokemap_apply", { operation: "apply", projectHandle,
        planId: planned.planId, operationId: `ledge-apply-${sequence++}` });
      assert.equal(record(applied.receipt).status, "applied");
      return applied;
    }
    const jump = { side: "inverted", distanceCells: 2, durationMs: 500, peakHeightPx: 24 };
    const definition = { name: "Rebord sud", template: "ledgeLine", previewSeed: "0", sortOrder: 0,
      jumpBehavior: jump,
      defaults: { irregularityPermille: 0, detailDensityPermille: 0, variationPermille: 0,
        maxOverlapPx: 0, gapTolerancePx: gap, depthRows: 1, allowAutoRotation: false },
      primitives: [{ id: "south", sourceElementId: "south", role: "structureLarge",
        authoredOrientation: "south", weight: 1, anchorPx: { x: 16, y: 31 },
        transforms: { allowFlipX: false, allowedQuarterTurns: [0] }, currentMetrics: gap === 8 ? {"assetFingerprint":"sha256:6d78db2bdfb59fbc13a29c27c6ac8f92423ca4a3d10119ede26baa281d217477","pixelSize":{"width":32,"height":32},"opaqueBounds":{"x":0,"y":16,"width":24,"height":16},"defaultAnchorPx":{"x":16,"y":31},"occupancyMaskRle":"border-rle-v1:1024:0:512,24,8,24,8,24,8,24,8,24,8,24,8,24,8,24,8,24,8,24,8,24,8,24,8,24,8,24,8,24,8,24,8"} : {
          assetFingerprint: "sha256:27ecefe268d655e171154896955798d616479367b6344d61f7f0c4cf9df49ea0",
          pixelSize: { width: 32, height: 32 }, opaqueBounds: { x: 0, y: 0, width: 32, height: 32 },
          defaultAnchorPx: { x: 16, y: 31 }, occupancyMaskRle: "border-rle-v1:1024:1:1,511,32,479,1",
        } }],
    };
    const invalid = { ...definition, jumpBehavior: { ...jump, distanceCells: 3 } };
    await mutate("border.blueprint.draft.upsert", {
      record: { id: "ledge", draft: { baseRevision: 0, definition: invalid } },
    }, true);
    await mutate("border.blueprint.draft.upsert", {
      record: { id: "ledge", draft: { baseRevision: 0, definition } },
    });
    const staged = await call("pokemap_artifact_stage", { sourcePath, declaredMediaType: "image/png" });
    await mutate("border.blueprint.publish", { blueprintId: "ledge", primitiveSources: [{
      primitiveId: "south", frames: [{ artifactHandle: staged.artifactHandle,
        sourceProjectRelativePath: "south.png" }],
    }] });
    assert.equal(record(record(JSON.parse(await readFile(manifestPath, "utf8"))).borderCatalog).formatVersion, 7);
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
    opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    projectHandle = String(opened.projectHandle); workspaceHandle = String(opened.workspaceHandle);
    const queried = await call("pokemap_query", { projectHandle, resourceKind: "borderBlueprint",
      operation: "get", ids: ["ledge"], view: "detail" });
    const blueprint = record((queried.items as JsonRecord[])[0]);
    for (const branch of ["draft", "latestPublished"]) {
      const saved = record(record(blueprint[branch]).definition);
      assert.equal(saved.template, "ledgeLine");
      assert.equal(record(saved.defaults).gapTolerancePx, gap);
      assert.deepEqual(saved.jumpBehavior, jump);
      const primitive = (saved.primitives as JsonRecord[])[0];
      assert.equal(primitive!.authoredOrientation, "south");
      assert.deepEqual(primitive!.anchorPx, { x: 16, y: 31 });
      assert.deepEqual(primitive!.transforms, { allowFlipX: false, allowedQuarterTurns: [0] });
    }
    assert.deepEqual(await readFile(sourcePath), pixels);
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

}

import assert from "node:assert/strict";
import { readFile, writeFile } from "node:fs/promises";
import { resolve } from "node:path";
import test from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("live MCP replaces a canonical 2D ledge slot, refuses an unknown primitive, and reopens exact geometry", async () => {
  const root = process.env.POKEMAP_REPLACEMENT_FIXTURE;
  assert.ok(root);
  const mapPath = resolve(root, "maps/original-map.pokemap.json");
  const original = record(JSON.parse(await readFile(mapPath, "utf8")));
  const layers = original.layers as JsonRecord[];
  const feature = record((record(layers[0]!.content).features as JsonRecord[])[0]);
  const materialization = record(feature.materialization);
  const slot = String((materialization.placements as JsonRecord[])[0]!.slotKey);
  const transport = new StdioClientTransport({
    command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root,
      "--dart", process.env.POKEMAP_TEST_DART ?? "dart",
      "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe",
  });
  const client = new Client({ name: "border-replacement-proof", version: "1.0.0" });
  async function call(name: string, args: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const response = await client.callTool({ name, arguments: args });
    assert.equal(response.isError, failure ? true : undefined, JSON.stringify(response.structuredContent));
    const envelope = record(response.structuredContent);
    return record(failure ? envelope.error : envelope.data);
  }
  let workspaceHandle: string | undefined;
  try {
    await client.connect(transport);
    const catalog = await call("pokemap_describe");
    const action = (catalog.mutationActions as JsonRecord[]).find(value => value.id === "border_layer.feature_set_replacement");
    assert.ok(action);
    assert.deepEqual(record(action.extensions).visualKinds, ["element"]);
    assert.equal(action.version, 1);
    const schema = record(record(action.extensions).inputSchema);
    assert.equal(schema.additionalProperties, false);
    assert.deepEqual(schema.required, ["mapId", "layerId", "featureId", "slotKey", "primitiveId"]);
    let opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    let projectHandle = String(opened.projectHandle);
    workspaceHandle = String(opened.workspaceHandle);
    const params = { mapId: "original-map", layerId: "original-borders", featureId: "ledge-feature", slotKey: slot, primitiveId: "south-alternate" };
    let sequence = 0;
    async function mutate(actionId: string, parameters: JsonRecord, failure = false): Promise<JsonRecord> {
      const validation = await call("pokemap_validate", { projectHandle });
      const before = await readFile(mapPath);
      const id = `replacement-${sequence++}`;
      const plan = await call("pokemap_plan", { projectHandle, request: {
        requestId: id, actionId, actionVersion: 1, workspaceHandle, parameters,
        expectedRevision: validation.snapshotRevision, idempotencyKey: id,
      } }, failure);
      assert.deepEqual(await readFile(mapPath), before);
      if (failure) return plan;
      const applied = await call("pokemap_apply", { operation: "apply", projectHandle,
        planId: plan.planId, operationId: `replacement-apply-${sequence++}` });
      assert.equal(record(applied.receipt).status, "applied");
      return applied;
    }
    const refused = await mutate("border_layer.feature_set_replacement", { ...params, primitiveId: "missing" }, true);
    assert.equal(record(refused.details).domainCode, "border.primitive_missing");
    const badSlot = await mutate("border_layer.feature_set_replacement", { ...params, slotKey: "missing" }, true);
    assert.equal(record(badSlot.details).domainCode, "border.slot_not_resolved");
    await mutate("border_layer.feature_set_replacement", params);
    const republish = record(JSON.parse(await readFile(`${root}-republish-record.json`, "utf8")));
    await mutate("border.blueprint.draft.upsert", { record: republish.record });
    const staged = await call("pokemap_artifact_stage", { sourcePath: resolve(root, "assets/original.png"), declaredMediaType: "image/png" });
    const primitiveSources = (republish.sources as JsonRecord[]).map(source => ({ ...source, frames: (source.frames as JsonRecord[]).map(frame => ({ ...frame, artifactHandle: staged.artifactHandle })) }));
    await mutate("border.blueprint.publish", { blueprintId: "ledge-blueprint", primitiveSources });
    await mutate("border_layer.materialize_apply", { mapId: params.mapId, layerId: params.layerId, featureId: params.featureId, tileWidthPx: 32, tileHeightPx: 32, resolverVersion: 3 });
    const current = record(JSON.parse(await readFile(mapPath, "utf8")));
    const currentLayers = current.layers as JsonRecord[];
    const currentFeature = record((record(currentLayers[0]!.content).features as JsonRecord[])[0]);
    for (const field of ["id", "seed", "geometry", "lineSide", "keepOutRegions"]) assert.deepEqual(currentFeature[field], feature[field]);
    assert.deepEqual(currentLayers.slice(1), layers.slice(1));
    const overrides = currentFeature.overrides as JsonRecord[];
    assert.equal(overrides.length, 1);
    assert.equal(overrides[0]!.replacementPrimitiveId, "south-alternate");
    assert.equal((record(currentFeature.materialization).placements as JsonRecord[])[0]!.primitiveId, "south-alternate");
    assert.equal(record(record(currentFeature.materialization).receipt).resolverVersion, 3);
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
    workspaceHandle = undefined;
    opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    projectHandle = String(opened.projectHandle);
    workspaceHandle = String(opened.workspaceHandle);
    const queried = await call("pokemap_query", { projectHandle, resourceKind: "map", operation: "get", ids: ["original-map"], view: "detail" });
    const reopened = record((queried.items as JsonRecord[])[0]);
    assert.deepEqual(reopened, { ...current, resourceKind: "map" });
    const freshCatalog = await call("pokemap_describe");
    assert.ok((freshCatalog.mutationActions as JsonRecord[]).some(value => value.id === action.id));
    const savedProject = record(JSON.parse(await readFile(resolve(root, "project.json"), "utf8")));
    const blueprint = record((record(savedProject.borderCatalog).records as JsonRecord[])[0]);
    assert.equal(record(blueprint.latestPublished).revision, 2);
    const output = process.env.POKEMAP_REPLACEMENT_RESULT;
    if (output) await writeFile(output, JSON.stringify({ action, refusal: refused, slotRefusal: badSlot, map: current, reopenedExact: true, republishedRevision: 2 }, null, 2));
  } finally {
    if (workspaceHandle) await call("pokemap_workspace", { operation: "close", workspaceHandle });
    await client.close();
    await transport.close();
  }
});

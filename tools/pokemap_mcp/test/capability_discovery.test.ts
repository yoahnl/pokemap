import assert from "node:assert/strict";
import { resolve } from "node:path";
import { test } from "node:test";
import { LocalAuthoringClient, type JsonRecord } from "../src/authoring_client.js";

test("real JSONL discovery is compact, targeted and preserves schema details", async () => {
  const authoring = new LocalAuthoringClient({
    allowedRoots: [resolve(process.cwd(), "../../examples/playable_runtime_host/golden_fangame_slice")],
    authoringPackageRoot: resolve(process.cwd(), "../../packages/map_authoring"),
    workerTimeoutMs: 60000,
    requestTimeoutMs: 65000,
  });
  try {
    const compact = await authoring.request("describe", {domain:"map3d", view:"compact"});
    assert.ok(Buffer.byteLength(JSON.stringify(compact.data)) <= 40000);
    const actions = compact.data.mutationActions as JsonRecord[];
    assert.ok(actions.some(action => action.id === "map.create"));
    assert.ok(actions.some(action => action.id === "smart_tile.cell.paint_batch"));
    assert.ok(actions.some(action => action.id === "border_layer.feature_delete"));
    assert.ok(!actions.some(action => String(action.id).startsWith("scene.")));
    const detail = await authoring.request("describe", {actionIds:["border_layer.feature_delete"], view:"full"});
    const action = (detail.data.mutationActions as JsonRecord[])[0]!;
    const schema = (action.extensions as JsonRecord).inputSchema as JsonRecord;
    assert.deepEqual(schema.required, ["mapId", "layerId", "featureId"]);
    assert.equal(schema.additionalProperties, false);
    await assert.rejects(authoring.request("describe", {domain:"unknown"}));
    await assert.rejects(authoring.request("describe", {actionIds:["missing"]}));
  } finally {
    await authoring.close();
  }
});

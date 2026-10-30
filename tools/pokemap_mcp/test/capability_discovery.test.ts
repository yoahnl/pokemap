import assert from "node:assert/strict";
import { resolve } from "node:path";
import { test } from "node:test";
import { Ajv } from "ajv";
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
    const actions = [...compact.data.mutationActions as JsonRecord[]];
    let next = compact.data.nextRequest;
    while (next) {
      const page = await authoring.request("describe", next as JsonRecord);
      assert.ok(Buffer.byteLength(JSON.stringify(page.data)) <= 40000);
      actions.push(...page.data.mutationActions as JsonRecord[]);
      next = page.data.nextRequest;
    }
    assert.equal(new Set(actions.map(action => action.id)).size, compact.data.actionCount);
    assert.ok(actions.some(action => action.id === "map.create"));
    assert.ok(actions.some(action => action.id === "smart_tile.cell.paint_batch"));
    assert.ok(actions.some(action => action.id === "border_layer.feature_delete"));
    assert.ok(!actions.some(action => String(action.id).startsWith("scene.")));
    const detail = await authoring.request("describe", {actionIds:["border_layer.feature_delete"], view:"full"});
    const action = (detail.data.mutationActions as JsonRecord[])[0]!;
    const schema = (action.extensions as JsonRecord).inputSchema as JsonRecord;
    assert.deepEqual(schema.required, ["mapId", "layerId", "featureId"]);
    assert.equal(schema.additionalProperties, false);
    const examples = await authoring.request("describe", {actionIds:[
      "map3d.edit_batch",
      "map.create", "smart_tile.layer.create", "smart_tile.cell.paint", "smart_tile.cell.paint_batch", "smart_tile.cell.erase",
      "map3d.terrain.surface.upsert_batch", "map3d.terrain.surface.delete_batch", "map3d.instance.upsert_batch", "map3d.instance.delete_batch",
      "border_layer.feature_create", "border_layer.feature_update", "border_layer.feature_delete", "border_layer.feature_move",
      "border_layer.stroke_add", "border_layer.stroke_update", "border_layer.stroke_delete", "border_layer.stroke_erase",
      "border_layer.region_fill", "border_layer.region_clear", "border_layer.feature_set_replacement", "border_layer.feature_set_suppressed",
      "border_layer.feature_clear_slot_override", "border_layer.feature_set_keep_out", "border_layer.relink_apply",
      "border_layer.feature_set_blueprint", "border_layer.materialize_batch_apply",
    ],view:"full"});
    for (const descriptor of examples.data.mutationActions as JsonRecord[]) {
      const extensions = descriptor.extensions as JsonRecord;
      assert.ok(extensions.inputSchema, String(descriptor.id));
      assert.ok(extensions.inputExample, String(descriptor.id));
      const validator = new Ajv({strict:false}).compile(extensions.inputSchema as object);
      assert.equal(validator(extensions.inputExample),true,`${descriptor.id}: ${JSON.stringify(validator.errors)}`);
      if(extensions.intentContracts) {
        for(const contract of Object.values(extensions.intentContracts as Record<string,JsonRecord>)) {
          const validateIntent=new Ajv({strict:false}).compile(contract.inputSchema as object);
          assert.equal(validateIntent(contract.inputExample),true,JSON.stringify(validateIntent.errors));
        }
      }
    }
    await assert.rejects(authoring.request("describe", {domain:"unknown"}));
    await assert.rejects(authoring.request("describe", {actionIds:["missing"]}));
  } finally {
    await authoring.close();
  }
});

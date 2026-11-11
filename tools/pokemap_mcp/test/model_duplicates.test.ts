import assert from "node:assert/strict";
import test from "node:test";
import type { AuthoringGateway, AuthoringWorkerSuccess, JsonRecord } from "../src/authoring_client.js";
import { auditDuplicateModels } from "../src/model_duplicates.js";

const digest = `sha256:${"1".repeat(64)}`;

function model(id: string, path = `assets/models3d/${id}.glb`): JsonRecord {
  return { id, name: "Model", sourceAssetId: `asset-${id}`, relativePath: path,
    definition: { id, name: "Model", sourceAssetId: `asset-${id}`, relativePath: path, scale: 1 } };
}

function asset(id: string, path = `assets/models3d/${id}.glb`): JsonRecord {
  return { id: `asset-${id}`, logicalPath: path,
    artifact: { digest, byteLength: 5, mediaType: "model/gltf-binary" } };
}

function gateway(options: { changeAssetRevision?: boolean } = {}): AuthoringGateway {
  let assetQueries = 0;
  return {
    async request(command, args): Promise<AuthoringWorkerSuccess> {
      assert.equal(command, "query");
      const request = args?.request as JsonRecord;
      const isAsset = request.resourceKind === "asset";
      if (isAsset) assetQueries++;
      const assetRevision = options.changeAssetRevision && assetQueries > 1 ? "asset-v2" : "asset-v1";
      const result = isAsset ? (request.operation === "batch_get"
        ? [asset("a"), asset("b"), asset("mismatch", "assets/models3d/wrong.glb")]
        : []) : [model("a"), model("b"), model("missing"), model("mismatch")];
      return { requestId: "test", artifacts: [], data: { items: result,
        totalAvailable: result.length, snapshotRevision: isAsset ? assetRevision : "model-v1" } };
    },
    async close() {},
  };
}

test("duplicate audit excludes missing and mismatched source records", async () => {
  const result = await auditDuplicateModels(gateway(), "project", 0, 25);
  assert.equal(result.modelCount, 4);
  assert.equal(result.missingAssetCount, 1);
  assert.equal(result.invalidAssetCount, 1);
  assert.equal(result.duplicateDefinitionCount, 1);
  assert.deepEqual(result.families, [{ id: null, count: 4 }]);
  const group = (result.groups as JsonRecord[])[0]!;
  assert.equal(group.sameSettings, true);
  assert.deepEqual((group.models as JsonRecord[]).map(model => model.id), ["a", "b"]);
});

test("models with the same bytes expose matching settings separately from other variants", async () => {
  const original = gateway();
  const mixed: AuthoringGateway = {
    async request(command, args) {
      const response = await original.request(command, args);
      const request = args?.request as JsonRecord;
      if (request.resourceKind === "model3d" && request.pageSize === 200) {
        const variant = model("c");
        variant.definition = { ...(variant.definition as JsonRecord), scale: 2 };
        const result = [...response.data.items as JsonRecord[], variant];
        return { ...response, data: { ...response.data, items: result, totalAvailable: result.length } };
      }
      if (request.resourceKind === "asset" && request.operation === "batch_get") {
        return { ...response, data: { ...response.data, items: [...response.data.items as JsonRecord[], asset("c")] } };
      }
      return response;
    },
    async close() {},
  };
  const result = await auditDuplicateModels(mixed, "project", 0, 25);
  const group = (result.groups as JsonRecord[])[0]!;
  const models = group.models as JsonRecord[];
  assert.equal(group.sameSettings, false);
  assert.match(String(models[0]!.settingsFingerprint), /^sha256:[a-f0-9]{64}$/);
  assert.equal(models[0]!.settingsFingerprint, models[1]!.settingsFingerprint);
  assert.notEqual(models[0]!.settingsFingerprint, models[2]!.settingsFingerprint);
  assert.equal(result.referenceEvidence, "not_checked");
});

test("duplicate audit refuses an asset catalogue changed during its read", async () => {
  await assert.rejects(auditDuplicateModels(gateway({ changeAssetRevision: true }), "project", 0, 25),
    error => (error as { code?: string }).code === "model_duplicates.stale");
});

test("duplicate audit refuses a model page that silently omits records", async () => {
  const original = gateway();
  const incomplete: AuthoringGateway = {
    async request(command, args) {
      const response = await original.request(command, args);
      const request = args?.request as JsonRecord;
      return request.resourceKind === "model3d" && request.pageSize === 200
        ? { ...response, data: { ...response.data, totalAvailable: 5 } }
        : response;
    },
    async close() {},
  };
  await assert.rejects(auditDuplicateModels(incomplete, "project", 0, 25),
    error => (error as { code?: string }).code === "model_duplicates.incomplete");
});

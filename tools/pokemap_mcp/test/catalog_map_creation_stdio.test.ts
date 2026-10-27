import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { mkdir, readFile, rm } from "node:fs/promises";
import { homedir } from "node:os";
import { join, resolve } from "node:path";
import { promisify } from "node:util";
import test from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("scoped 3D map creation crosses live MCP with replay, undo and reopen", { timeout: 120_000 }, async () => {
  const root = join(homedir(), "Library/Caches/AveluneQA/hgss-mauville-maps/api/mcp");
  await mkdir(root, { recursive: true });
  const packageRoot = resolve("../../packages/map_authoring");
  const dart = process.env.POKEMAP_TEST_DART ?? "dart";
  const client = new Client({ name: "scoped-map-creation", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--dart", dart, "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe" });
  async function call(name: string, args: JsonRecord): Promise<JsonRecord> {
    const response = record((await client.callTool({ name, arguments: args })).structuredContent);
    assert.equal(response.ok, true, JSON.stringify(response));
    return record(response.data);
  }
  try {
    await promisify(execFile)(dart, [`--packages=${join(packageRoot, ".dart_tool/package_config.json")}`,
      join(packageRoot, "test/support/create_working_catalog_fixture.dart"), root, "--map-creation"], { timeout: 60_000 });
    const descriptor = await readFile(join(root, "project.json"));
    await client.connect(transport);
    const described = await call("pokemap_describe", {});
    assert.ok((described.mutationActions as JsonRecord[]).some(action => action.id === "map.create"));
    let opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    await call("pokemap_workshop", { operation: "prepare", projectHandle: opened.projectHandle });
    const preparation = await call("pokemap_workshop", { operation: "prepare", projectHandle: opened.projectHandle, scope: "mapCreation" });
    assert.equal(preparation.scope, "explicitMapOwnershipIndex");
    let lastReceipt: JsonRecord = {};
    for (const mapId of ["route-31", "mauville"]) {
      const parameters = { mapId, name: mapId, width: 64, height: 32, role: "exterior" };
      const selection = await call("pokemap_workshop", { operation: "read", projectHandle: opened.projectHandle,
        actionId: "map.create", parameters, includeDocuments: false });
      const planned = await call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
        requestId: mapId, actionId: "map.create", actionVersion: 1, workspaceHandle: opened.workspaceHandle,
        expectedRevision: selection.snapshotRevision, idempotencyKey: mapId, parameters,
        extensions: selection.planExtensions } });
      const args = { operation: "apply", projectHandle: opened.projectHandle, planId: planned.planId, operationId: mapId };
      const applied = await call("pokemap_apply", args);
      lastReceipt = record(applied.receipt);
      const replay = await call("pokemap_apply", args);
      assert.equal(record(replay.receipt).receiptId, lastReceipt.receiptId);
      const map = record(JSON.parse(await readFile(join(root, `maps/${mapId}.json`), "utf8")));
      assert.equal(map.id, mapId);
      assert.ok(map.spatialScene);
    }
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
    opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const selection = await call("pokemap_workshop", { operation: "read", projectHandle: opened.projectHandle,
      actionId: "map.create", parameters: { mapId: "mauville", width: 64, height: 32 } });
    assert.equal((record(selection.project).maps as JsonRecord[])[0]!.id, "mauville");
    await call("pokemap_history", { operation: "undo", projectHandle: opened.projectHandle,
      entryId: lastReceipt.receiptId, idempotencyKey: "undo-mauville" });
    await assert.rejects(readFile(join(root, "maps/mauville.json")), { code: "ENOENT" });
    assert.equal(record(JSON.parse(await readFile(join(root, "maps/route-31.json"), "utf8"))).id, "route-31");
    assert.deepEqual(await readFile(join(root, "project.json")), descriptor);
    const modelArtifact = await call("pokemap_artifact_stage", { sourcePath: join(root, "source.glb"), declaredMediaType: "model/gltf-binary" });
    const imageArtifact = await call("pokemap_artifact_stage", { sourcePath: join(root, "source.png"), declaredMediaType: "image/png" });
    await call("pokemap_workshop", { operation: "prepare", projectHandle: opened.projectHandle, scope: "assetImport" });
    await call("pokemap_workshop", { operation: "prepare", projectHandle: opened.projectHandle, scope: "nativeResources" });
    const operations: [string, JsonRecord][] = [
      ["map.update_metadata", { mapId: "route-31", isIndoor: true }],
      ["map3d.camera.configure", { mapId: "route-31", camera: { ...record(record(JSON.parse(await readFile(join(root, "maps/route-31.json"), "utf8"))).spatialScene).camera as JsonRecord, distance: 60 } }],
      ["model3d.import_batch", { models: ["house", "decoration"].map(modelId => ({ modelId, name: modelId, artifactHandle: modelArtifact.artifactHandle })) }],
      ["tileset.import_image", { tilesetId: "ground", name: "Ground", artifactHandle: imageArtifact.artifactHandle, tileWidth: 16, tileHeight: 16 }],
      ["smart_tile.atlas.upsert", { atlas: { id: "ground-atlas", name: "Ground", tilesetId: "ground", cellWidth: 16, cellHeight: 16, columns: 1, rows: 1 } }],
      ["smart_tile.material.upsert_batch", { materials: [{ id: "grass", name: "Grass", connectionGroupId: "grass" }] }],
      ["smart_tile.preset.publish", { preset: { id: "ground", name: "Ground", usage: "path", topology: "uniform", status: "published", templateHint: "simple", coveragePolicy: "sparse", coverageProfile: { mode: "template" }, transformPolicy: {}, defaultMaterialId: "grass", allowedMaterialIds: ["grass"], rules: [{ id: "ground", centerMatch: { kind: "material", materialId: "grass" }, candidates: [{ id: "native", parts: [{ source: { kind: "frame", frame: { atlasId: "ground-atlas", column: 0, row: 0 } } }] }] }] } }],
      ["border.blueprint.draft.upsert", { record: JSON.parse(await readFile(join(root, "border.json"), "utf8")) }],
      ["border.blueprint.publish", { blueprintId: "fence" }],
    ];
    for (const [actionId, parameters] of operations) {
      const scoped = await call("pokemap_workshop", { operation: "read", projectHandle: opened.projectHandle, actionId, parameters });
      const planned = await call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
        requestId: actionId, actionId, actionVersion: 1, workspaceHandle: opened.workspaceHandle,
        expectedRevision: scoped.snapshotRevision, idempotencyKey: actionId, parameters, extensions: scoped.planExtensions } });
      await call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle, planId: planned.planId, operationId: actionId });
    }
    assert.deepEqual(await readFile(join(root, "assets/models3d/house.glb")), await readFile(join(root, "source.glb")));
    assert.deepEqual(await readFile(join(root, "assets/studio/ground.png")), await readFile(join(root, "source.png")));
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

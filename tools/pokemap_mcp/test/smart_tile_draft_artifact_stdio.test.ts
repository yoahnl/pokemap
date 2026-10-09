import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import test from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("live MCP imports and publishes a verified large native draft without widening request limits", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-draft-artifact-mcp-"));
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "120000"],
    cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "smart-tile-draft-artifact-proof", version: "1.0.0" });
  let maximumResponseBytes = 0;
  async function call(name: string, args: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: args }, { timeout: 125000 });
    maximumResponseBytes = Math.max(maximumResponseBytes, Buffer.byteLength(JSON.stringify(result), "utf8"));
    assert.equal(result.isError, failure ? true : undefined, JSON.stringify(result.structuredContent));
    const envelope = record(result.structuredContent);
    return record(failure ? envelope.error : envelope.data);
  }
  try {
    await client.connect(transport);
    const catalog = await call("pokemap_describe");
    const descriptor = (catalog.mutationActions as JsonRecord[]).find(action => action.id === "smart_tile.preset.draft.import")!;
    assert.equal(descriptor.version, 1);
    assert.equal(record(descriptor.extensions).maximumArtifactByteLength, 8 * 1024 * 1024);
    const request = { name: "Large Draft", folderName: "draft", parentPath: root, template: "empty", dimension: "threeD", mapWidth: 4, mapHeight: 4 };
    const preview = await call("pokemap_project_create_preview", { request });
    const created = await call("pokemap_project_create", { request, confirmation: preview.confirmation });
    const projectRoot = String(created.projectPath);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    const projectHandle = String(opened.projectHandle);
    const workspaceHandle = String(opened.workspaceHandle);
    let sequence = 0;
    async function plan(actionId: string, parameters: JsonRecord, failure = false): Promise<JsonRecord> {
      const valid = await call("pokemap_validate", { projectHandle });
      const id = `draft-artifact-${++sequence}`;
      return call("pokemap_plan", { projectHandle, request: { requestId: id, actionId, actionVersion: 1, workspaceHandle,
        parameters, expectedRevision: valid.snapshotRevision, idempotencyKey: id, dryRun: false } }, failure);
    }
    async function mutate(actionId: string, parameters: JsonRecord): Promise<JsonRecord> {
      const planned = await plan(actionId, parameters);
      return call("pokemap_apply", { operation: "apply", projectHandle, planId: planned.planId, operationId: `apply-draft-artifact-${sequence}` });
    }
    const image = join(root, "ground.png");
    await writeFile(image, Buffer.from("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=", "base64"));
    const imageStage = await call("pokemap_artifact_stage", { sourcePath: image, declaredMediaType: "image/png" });
    await mutate("tileset.import_image", { artifactHandle: imageStage.artifactHandle, tilesetId: "ground-image", name: "Ground", tileWidth: 1, tileHeight: 1 });
    const materialIds = Array.from({ length: 3000 }, (_, i) => `material-${i}`);
    const draft = { id: "large-draft", targetPresetId: "large-ground", name: "Grand sol éditable", usage: "terrain", lastStage: "publish",
      primaryAtlasId: "atlas", sourceTilesetIds: ["ground-image"],
      atlases: [{ id: "atlas", name: "Ground", tilesetId: "ground-image", cellWidth: 1, cellHeight: 1, columns: 1, rows: 1 }],
      materials: materialIds.map(id => ({ id, name: id, connectionGroupId: "ground" })),
      defaultMaterialId: materialIds[0], allowedMaterialIds: materialIds, topology: "uniform", templateHint: "simple", coveragePolicy: "complete",
      coverageProfile: { mode: "explicit", requiredScenarios: materialIds.map(id => ({ id: `scenario-${id}`, centerMaterialId: id, signature: {} })) }, transformPolicy: {},
      rules: materialIds.map(id => ({ id: `rule-${id}`, centerMatch: { kind: "material", materialId: id }, signature: {},
        candidates: [{ id: `candidate-${id}`, label: "Ground variant", parts: [{ source: { kind: "frame", frame: { atlasId: "atlas", column: 0, row: 0 } } }] }] })),
    };
    const json = JSON.stringify(draft);
    assert.ok(Buffer.byteLength(json, "utf8") > 1024 * 1024);
    const prior = JSON.parse(await readFile(join(projectRoot, "project.json"), "utf8")) as JsonRecord;
    const slots = ["northWestCorner", "northEdge", "northEastCorner", "eastEdge", "southEastCorner", "southEdge", "southWestCorner", "westEdge"];
    prior.smartTileCatalog = { formatVersion: 4, categories: [], patterns: [], animations: [], drafts: [],
      atlases: [{ id: "old-atlas", name: "Old", tilesetId: "ground-image", cellWidth: 1, cellHeight: 1, columns: 1, rows: 1 }],
      materials: [{ id: "old-material", name: "Old", connectionGroupId: "old", categoryId: "", terrainType: null, pathSurfaceKind: null, isEmpty: false, sortOrder: 0, editorColorArgb: null, extension: "keep" }],
      presets: [{ id: "old-preset", name: "Old", usage: "terrain", topology: "uniform", status: "published", defaultMaterialId: "old-material", allowedMaterialIds: ["old-material"], coveragePolicy: "complete", transformPolicy: {},
        coverageProfile: { mode: "explicit", allowFallback: false, requiredScenarios: [{ id: "old-scenario", centerMaterialId: "old-material", signature: Object.fromEntries(slots.map(slot => [slot, null])) }] },
        rules: [{ id: "old-rule", centerMatch: { kind: "material", materialId: "old-material" }, signature: Object.fromEntries(slots.map(slot => [slot, { kind: "any" }])),
          candidates: [{ id: "old-candidate", label: "", weight: 1, parts: [{ source: { kind: "frame", frame: { atlasId: "old-atlas", column: 0, row: 0, columnSpan: 1, rowSpan: 1 } },
            transform: { quarterTurns: 0, flipX: false }, channel: "ground", offsetX: 0, offsetY: 0 }] }] }] }] };
    await writeFile(join(projectRoot, "project.json"), JSON.stringify(prior));
    const before = await readFile(join(projectRoot, "project.json"));
    const mapManifest = JSON.parse(before.toString("utf8")) as JsonRecord;
    const firstMap = record((mapManifest.maps as JsonRecord[])[0]);
    const mapPath = join(projectRoot, String(firstMap.relativePath));
    const mapBefore = await readFile(mapPath);
    const refused = await plan("smart_tile.preset.draft.upsert", { draft }, true);
    assert.equal(refused.code, "resource_limit");
    assert.equal(record(refused.details).maximumBytes, 1048576);
    assert.deepEqual(await readFile(join(projectRoot, "project.json")), before);
    const sourcePath = join(root, "draft.json");
    await writeFile(sourcePath, json);
    const staged = await call("pokemap_artifact_stage", { sourcePath, declaredMediaType: "application/json" });
    assert.equal(staged.mediaType, "application/json");
    const wrongId = await plan("smart_tile.preset.draft.import", { draftId: "different", artifactHandle: staged.artifactHandle }, true);
    assert.equal(wrongId.domainCode, "smart_tile.draft.identity_mismatch");
    assert.deepEqual(await readFile(join(projectRoot, "project.json")), before);
    const applied = await mutate("smart_tile.preset.draft.import", { draftId: draft.id, artifactHandle: staged.artifactHandle });
    assert.equal(record(applied.receipt).actionId, "smart_tile.preset.draft.import");
    assert.equal(record(applied.receipt).status, "applied");
    assert.ok(Buffer.byteLength(JSON.stringify(applied), "utf8") < 64 * 1024);
    const imported = JSON.parse(await readFile(join(projectRoot, "project.json"), "utf8")) as JsonRecord;
    const saved = record((record(imported.smartTileCatalog).drafts as JsonRecord[])[0]);
    assert.equal((saved.rules as JsonRecord[]).length, 3000);
    await mutate("smart_tile.preset.publish", { draftId: draft.id });
    assert.deepEqual(await readFile(mapPath), mapBefore);
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
    const reopened = await call("pokemap_workspace", { operation: "open", projectRoot });
    const queried = await call("pokemap_query", { projectHandle: reopened.projectHandle, resourceKind: "smartTilePreset", operation: "get", ids: [draft.targetPresetId], view: "detail", fieldMask: ["id", "name", "rules", "allowedMaterialIds", "coverageProfile"] });
    const preset = record((queried.items as JsonRecord[])[0]);
    assert.deepEqual(preset.allowedMaterialIds, materialIds);
    assert.equal((preset.rules as JsonRecord[]).length, 3000);
    assert.deepEqual((record(preset.coverageProfile).requiredScenarios as JsonRecord[]).map(value => value.id), draft.coverageProfile.requiredScenarios.map(value => value.id));
    assert.deepEqual((preset.rules as JsonRecord[]).map(value => value.id), draft.rules.map(value => value.id));
    const detailedRule = record((preset.rules as JsonRecord[])[0]);
    assert.equal(record(record(detailedRule.signature).northEdge).kind, "any");
    const detailedCandidate = record((detailedRule.candidates as JsonRecord[])[0]);
    assert.equal(detailedCandidate.weight, 1);
    const detailedPart = record((detailedCandidate.parts as JsonRecord[])[0]);
    assert.equal(record(detailedPart.transform).quarterTurns, 0);
    assert.equal(detailedPart.offsetX, 0);
    assert.equal(record(preset.coverageProfile).allowFallback, false);
    const materialQuery = await call("pokemap_query", { projectHandle: reopened.projectHandle, resourceKind: "smartTileMaterial", operation: "get", ids: [materialIds[0]], view: "detail" });
    assert.equal(record((materialQuery.items as JsonRecord[])[0]).isEmpty, false);
    const finalText = await readFile(join(projectRoot, "project.json"), "utf8");
    assert.equal(finalText.includes("\n"), false);
    const finalManifest = JSON.parse(finalText) as JsonRecord;
    assert.equal((record(finalManifest.smartTileCatalog).materials as JsonRecord[]).length, 3001);
    assert.equal((record(finalManifest.smartTileCatalog).drafts as JsonRecord[]).length, 0);
    const storedPreset = (record(finalManifest.smartTileCatalog).presets as JsonRecord[]).find(value => value.id === draft.targetPresetId)!;
    const storedRule = record((storedPreset.rules as JsonRecord[])[0]);
    assert.equal(Object.hasOwn(storedRule, "signature"), false);
    const storedPart = record((record((storedRule.candidates as JsonRecord[])[0]).parts as JsonRecord[])[0]);
    assert.equal(Object.hasOwn(storedPart, "transform"), false);
    assert.equal(Object.hasOwn(storedPart, "offsetX"), false);
    const storedScenario = record((record(storedPreset.coverageProfile).requiredScenarios as JsonRecord[])[0]);
    assert.equal(Object.hasOwn(storedScenario, "signature"), false);
    const storedMaterial = record((record(finalManifest.smartTileCatalog).materials as JsonRecord[])[0]);
    assert.equal(Object.hasOwn(storedMaterial, "isEmpty"), false);
    const oldPreset = (record(finalManifest.smartTileCatalog).presets as JsonRecord[]).find(value => value.id === "old-preset")!;
    const oldRule = record((oldPreset.rules as JsonRecord[])[0]);
    assert.equal(Object.hasOwn(oldRule, "signature"), false);
    const oldPart = record((record((oldRule.candidates as JsonRecord[])[0]).parts as JsonRecord[])[0]);
    assert.equal(Object.hasOwn(oldPart, "transform"), false);
    const oldMaterial = (record(finalManifest.smartTileCatalog).materials as JsonRecord[]).find(value => value.id === "old-material")!;
    assert.equal(Object.hasOwn(oldMaterial, "isEmpty"), false);
    assert.equal(oldMaterial.extension, "keep");
    const initialRoot = { ...mapManifest };
    const finalRoot = { ...finalManifest };
    delete initialRoot.smartTileCatalog;
    delete finalRoot.smartTileCatalog;
    assert.deepEqual(finalRoot, initialRoot);
    await call("pokemap_validate", { projectHandle: reopened.projectHandle });
    assert.ok(maximumResponseBytes < 10 * 1024 * 1024);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: reopened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

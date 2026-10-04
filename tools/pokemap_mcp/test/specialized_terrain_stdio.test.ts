import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";
import { resourceManagementFixture } from "./resource_management_fixture.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("terrain management traverses real MCP stdio without publishing copied drafts", async () => {
  const root = await mkdtemp(join(tmpdir(), "uwu5-terrain-stdio-"));
  const path = join(root, "project.json");
  const original = {...resourceManagementFixture(), characters: [{
    id: "free", name: "Libre", tilesetId: "sheet", frameWidth: 1, frameHeight: 1,
  }]};
  await writeFile(path, JSON.stringify(original));
  const transport = new StdioClientTransport({command: process.execPath,
    args: ["dist/src/index.js", "--root", root, "--dart", process.env.POKEMAP_TEST_DART ?? "dart"],
    cwd: process.cwd(), stderr: "pipe"});
  const client = new Client({name: "uwu5-terrain-stdio", version: "1.0.0"});
  async function data(name: string, args: JsonRecord): Promise<JsonRecord> {
    const result = await client.callTool({name, arguments: args});
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, true, JSON.stringify(envelope));
    return record(envelope.data);
  }
  try {
    await client.connect(transport);
    const catalog = await data("pokemap_describe", {});
    const actions = new Map((catalog.mutationActions as JsonRecord[]).map(a => [a.id, a]));
    for (const id of ["smart_tile.preset.rename", "smart_tile.preset.duplicate",
      "smart_tile.preset.draft.delete", "smart_tile.preset.delete",
      "border.blueprint.delete", "border.blueprint.set_deprecated",
      "characterStudio.character.deletePlan", "characterStudio.character.delete"]) {
      assert.ok(actions.has(id), id);
      assert.equal(record(record(actions.get(id)!.extensions).inputSchema).additionalProperties, false, id);
    }
    const opened = await data("pokemap_workspace", {operation: "open", projectRoot: root});
    const projectHandle = String(opened.projectHandle);
    let next = 0;
    async function mutate(actionId: string, parameters: JsonRecord): Promise<void> {
      const validation = await data("pokemap_validate", {projectHandle});
      const before = await readFile(path);
      const id = next++;
      const planned = await data("pokemap_plan", {projectHandle, request: {
        requestId: `terrain-${id}`, actionId, actionVersion: 1,
        workspaceHandle: opened.workspaceHandle, parameters,
        expectedRevision: validation.snapshotRevision, idempotencyKey: `terrain-${id}`, dryRun: false}});
      assert.deepEqual(await readFile(path), before);
      const confirmation = actions.get(actionId)!.riskLevel === "high"
        ? (await data("pokemap_apply", {operation: "confirm", projectHandle, planId: planned.planId})).confirmationToken
        : undefined;
      const result = await data("pokemap_apply", {operation: "apply", projectHandle, planId: planned.planId,
        operationId: `terrain-apply-${id}`, ...(confirmation ? {confirmationToken: confirmation} : {})});
      assert.equal(record(result.receipt).status, "applied");
    }
    await mutate("smart_tile.preset.rename", {presetId: "ground", name: "Chemin d’été"});
    await mutate("smart_tile.preset.duplicate", {presetId: "ground", newDraftId: "copy-draft",
      targetPresetId: "copy-ground", name: "Copie indépendante"});
    let current = record(JSON.parse(await readFile(path, "utf8")));
    let smart = record(current.smartTileCatalog);
    assert.equal((smart.presets as JsonRecord[]).length, 1);
    assert.equal((smart.presets as JsonRecord[])[0]!.name, "Chemin d’été");
    const copy = (smart.drafts as JsonRecord[]).find(d => d.id === "copy-draft")!;
    assert.equal(copy.targetPresetId, "copy-ground");
    assert.equal(copy.sourcePresetId, null);
    assert.deepEqual(copy.tags, original.smartTileCatalog.presets[0]!.tags);
    await mutate("smart_tile.preset.draft.delete", {draftId: "copy-draft"});
    await mutate("smart_tile.preset.draft.delete", {draftId: "editing"});
    await mutate("smart_tile.preset.delete", {presetId: "ground"});
    current = record(JSON.parse(await readFile(path, "utf8")));
    smart = record(current.smartTileCatalog);
    assert.deepEqual(smart.presets, []);
    assert.deepEqual(smart.drafts, []);
    assert.deepEqual(current.tilesets, original.tilesets);
    assert.deepEqual(current.elements, original.elements);
    assert.deepEqual(smart.atlases, original.smartTileCatalog.atlases);
    const characterId = "free";
    const beforeInspection = await readFile(path);
    const validation = await data("pokemap_validate", {projectHandle});
    const inspection = await data("pokemap_plan", {projectHandle, request: {
      requestId: "character-inspect", actionId: "characterStudio.character.deletePlan",
      actionVersion: 1, workspaceHandle: opened.workspaceHandle,
      parameters: {characterId}, expectedRevision: validation.snapshotRevision,
      idempotencyKey: "character-inspect", dryRun: true}});
    assert.deepEqual(await readFile(path), beforeInspection);
    const rejected = await client.callTool({name: "pokemap_apply", arguments: {
      operation: "apply", projectHandle, planId: inspection.planId,
      operationId: "inspection-must-not-write"}});
    assert.equal(record(rejected.structuredContent).ok, false);
    assert.deepEqual(await readFile(path), beforeInspection);
    await mutate("characterStudio.character.delete", {characterId});
    current = record(JSON.parse(await readFile(path, "utf8")));
    assert.deepEqual(current.characters, []);
    assert.deepEqual(current.tilesets, original.tilesets);
    await data("pokemap_workspace", {operation: "close", workspaceHandle: opened.workspaceHandle});
    const reopened = await data("pokemap_workspace", {operation: "open", projectRoot: root});
    const reread = await data("pokemap_query", {projectHandle: reopened.projectHandle,
      resourceKind: "project", operation: "get", ids: ["project"], view: "detail"});
    assert.ok(JSON.stringify(reread).includes("Planche"));
  } finally {
    await client.close();
    await rm(root, {recursive: true, force: true});
  }
});

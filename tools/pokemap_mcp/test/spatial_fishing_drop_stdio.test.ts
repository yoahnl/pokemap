import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, rm } from "node:fs/promises";
import { join, resolve } from "node:path";
import { homedir, tmpdir } from "node:os";
import test from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("fresh MCP advertises fishing height and preserves it across reopen", { timeout: 120_000 }, async () => {
  const qaRoot = process.env.AVELUNE_QA_ROOT ?? (process.platform === "darwin"
    ? join(homedir(), "Library/Caches/AveluneQA/ecorcia-chapitre7-annexes/fishing-height") : undefined);
  const owner = qaRoot ?? tmpdir();
  await mkdir(owner, { recursive: true });
  const root = await mkdtemp(join(owner, "avelune-fishing-mcp-"));
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"], cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "fishing-drop-proof", version: "1.0.0" });
  async function call(name: string, args: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: args });
    assert.equal(result.isError, failure ? true : undefined, JSON.stringify(result.structuredContent));
    const envelope = record(result.structuredContent);
    return record(failure ? envelope.error : envelope.data);
  }
  try {
    await client.connect(transport);
    const catalog = await call("pokemap_describe", { actionIds: ["map3d.navigation.configure"] });
    const descriptor = (catalog.mutationActions as JsonRecord[]).find(action => action.id === "map3d.navigation.configure")!;
    const extensions = record(descriptor.extensions);
    const navigationSchema = record(record(record(extensions.inputSchema).properties).navigation);
    assert.deepEqual(record(record(navigationSchema.properties).maximumFishingDropWorld).default, .25);
    assert.equal(record(extensions.fishingDrop).capability, "map3d.fishing-drop@1");
    const request = { name: "Fishing", folderName: "project", parentPath: root,
      template: "empty", dimension: "threeD", mapWidth: 8, mapHeight: 8 };
    const preview = await call("pokemap_project_create_preview", { request });
    const created = await call("pokemap_project_create", { request, confirmation: preview.confirmation });
    const projectRoot = String(created.projectPath);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    const projectHandle = String(opened.projectHandle), workspaceHandle = String(opened.workspaceHandle);
    await call("pokemap_workshop", { operation: "prepare", projectHandle });
    const manifest = JSON.parse(await readFile(join(projectRoot, "project.json"), "utf8")) as JsonRecord;
    const entry = record((manifest.maps as unknown[])[0]);
    const mapPath = join(projectRoot, String(entry.relativePath));
    const map = JSON.parse(await readFile(mapPath, "utf8")) as JsonRecord;
    const scene = record(map.spatialScene);
    const originalNavigation = record(scene.navigation);
    let sequence = 0;
    async function plan(drop: unknown, failure = false): Promise<JsonRecord> {
      const validation = await call("pokemap_validate", { projectHandle });
      const id = `fishing-${++sequence}`;
      return call("pokemap_plan", { projectHandle, request: { requestId: id,
        actionId: "map3d.navigation.configure", actionVersion: 1, workspaceHandle,
        parameters: { mapId: map.id, navigation: { ...originalNavigation, maximumFishingDropWorld: drop } },
        expectedRevision: validation.snapshotRevision, idempotencyKey: id } }, failure);
    }
    const before = await readFile(mapPath);
    const planned = await plan(.5);
    assert.deepEqual(await readFile(mapPath), before);
    const applied = await call("pokemap_apply", { operation: "apply", projectHandle,
      planId: planned.planId, operationId: "fishing-drop-apply" });
    assert.equal(record(applied.receipt).status, "applied");
    const saved = await readFile(mapPath);
    for (const invalid of [-1, 4.1, "0.5"]) {
      await plan(invalid, true);
      assert.deepEqual(await readFile(mapPath), saved);
    }
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
    const reopened = await call("pokemap_workspace", { operation: "open", projectRoot });
    const queried = await call("pokemap_query", { projectHandle: reopened.projectHandle,
      resourceKind: "map", operation: "get", ids: [map.id], view: "detail" });
    const reopenedScene = record(record((queried.items as unknown[])[0]).spatialScene);
    assert.equal(record(reopenedScene.navigation).maximumFishingDropWorld, .5);
    assert.deepEqual(reopenedScene.heightLevels, scene.heightLevels);
    assert.deepEqual(reopenedScene.instances, scene.instances);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: reopened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

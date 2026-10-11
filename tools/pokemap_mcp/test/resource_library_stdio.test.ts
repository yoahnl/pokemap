import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";
import { resourceManagementFixture } from "./resource_management_fixture.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("resource families and map scope persist through real MCP transactions", async () => {
  const root = await mkdtemp(join(tmpdir(), "resource-library-mcp-"));
  const manifest = resourceManagementFixture() as JsonRecord;
  manifest.maps = ["a", "b"].map((id) => ({ id, name: id, relativePath: `maps/${id}.json` }));
  await mkdir(join(root, "maps"));
  for (const id of ["a", "b"]) {
    await writeFile(join(root, "maps", `${id}.json`), JSON.stringify({
      version: "v8", id, name: id, size: { width: 8, height: 8 }, layers: [],
      placedElements: [], entities: [], connections: [], warps: [],
    }));
  }
  const manifestPath = join(root, "project.json");
  await writeFile(manifestPath, JSON.stringify(manifest));
  const transport = new StdioClientTransport({
    command: process.execPath,
    args: ["dist/src/index.js", "--root", root],
    cwd: process.cwd(), stderr: "pipe",
  });
  const client = new Client({ name: "resource-library-contract-proof", version: "1.0.0" });
  let sequence = 0;
  async function call(name: string, args: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: args });
    assert.equal(result.isError, failure ? true : undefined, JSON.stringify(result.structuredContent));
    const envelope = record(result.structuredContent);
    return record(failure ? envelope.error : envelope.data);
  }
  try {
    await client.connect(transport);
    const described = await call("pokemap_describe");
    const actions = new Map((described.mutationActions as JsonRecord[]).map((entry) => [entry.id, entry]));
    for (const id of ["resource.family.create", "resource.family.update", "resource.family.delete", "resource.classify"]) {
      assert.ok(actions.has(id), id);
      assert.equal(record(record(actions.get(id)!.extensions).inputSchema).additionalProperties, false);
    }
    const resourceKinds = new Set((described.resourceKinds as JsonRecord[]).map((entry) => entry.id));
    for (const id of ["resourceLibraryCatalog", "resourceFamily", "resourceLibraryEntry"]) {
      assert.ok(resourceKinds.has(id), id);
    }
    console.log(JSON.stringify({ liveMcpCatalog: true, mutationActions: actions.size,
      resourceKinds: resourceKinds.size, resourceLibraryActions: 4, resourceLibraryQueries: 3 }));
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    async function mutate(actionId: string, parameters: JsonRecord, failure = false) {
      const validation = await call("pokemap_validate", { projectHandle: opened.projectHandle });
      const before = await readFile(manifestPath);
      const requestId = `resource-library-${++sequence}`;
      const plan = await call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
        requestId, actionId, actionVersion: 1, workspaceHandle: opened.workspaceHandle,
        parameters, expectedRevision: validation.snapshotRevision, idempotencyKey: requestId,
      } }, failure);
      assert.deepEqual(await readFile(manifestPath), before);
      if (failure) return;
      let confirmationToken: unknown;
      if (actions.get(actionId)?.riskLevel === "high") {
        confirmationToken = (await call("pokemap_apply", { operation: "confirm",
          projectHandle: opened.projectHandle, planId: plan.planId })).confirmationToken;
      }
      const args = { operation: "apply", projectHandle: opened.projectHandle,
        planId: plan.planId, operationId: requestId,
        ...(confirmationToken ? { confirmationToken } : {}) };
      const applied = await call("pokemap_apply", args);
      const repeated = await call("pokemap_apply", args);
      assert.equal(record(applied.receipt).receiptId, record(repeated.receipt).receiptId);
    }
    await mutate("resource.family.create", { familyId: "forest", name: "Forêt A", parentId: "trees" });
    await mutate("resource.family.create", { familyId: "forest-detail", name: "Petits arbres", parentId: "forest" });
    await mutate("resource.family.update", { familyId: "forest", name: "Forêt locale", parentId: "forest-detail" }, true);
    await mutate("resource.classify", { resourceKind: "element", resourceId: "decor", familyId: "forest-detail", mapId: "a" });
    await mutate("resource.classify", { resourceKind: "smartTilePreset", resourceId: "ground", familyId: "ground", mapId: null });
    await mutate("resource.classify", { resourceKind: "element", resourceId: "absent", familyId: "trees" }, true);
    await mutate("resource.classify", { resourceKind: "element", resourceId: "decor", mapId: "absent" }, true);
    await mutate("resource.family.delete", { familyId: "forest-detail" }, true);
    await mutate("resource.family.create", { familyId: "temporary", name: "Temporaire" });
    await mutate("resource.family.delete", { familyId: "temporary" });
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
    const reopened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const catalog = await call("pokemap_query", { projectHandle: reopened.projectHandle,
      resourceKind: "resourceLibraryCatalog", operation: "get", ids: ["resource-library"], view: "detail" });
    assert.ok(JSON.stringify(catalog).includes("forest-detail"));
    const after = record(JSON.parse(await readFile(manifestPath, "utf8")));
    const entries = record(after.resourceLibraryCatalog).entries as JsonRecord[];
    assert.deepEqual(entries.find((entry) => entry.resourceKind === "element"), {
      resourceKind: "element", resourceId: "decor", familyId: "forest-detail", mapId: "a",
    });
    for (const key of ["elements", "tilesets", "smartTileCatalog", "maps"]) {
      assert.deepEqual(after[key], manifest[key], key);
    }
    await call("pokemap_workspace", { operation: "close", workspaceHandle: reopened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

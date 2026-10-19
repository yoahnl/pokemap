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
    args: ["dist/src/index.js", "--root", root, "--authoring-timeout-ms", "60000"],
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
    for (const id of ["resource.family.create", "resource.family.update", "resource.family.delete", "resource.classify", "resource.classify_batch"]) {
      assert.ok(actions.has(id), id);
      assert.equal(record(record(actions.get(id)!.extensions).inputSchema).additionalProperties, false);
    }
    const batchSchema = record(record(actions.get("resource.classify_batch")!.extensions).inputSchema);
    const entriesSchema = record(record(batchSchema.properties).entries);
    assert.equal(entriesSchema.minItems, 1);
    assert.equal(entriesSchema.maxItems, 100);
    assert.equal(record(entriesSchema.items).additionalProperties, false);
    assert.deepEqual(record(record(record(entriesSchema.items).properties).role).enum, ["standard", "component"]);
    for (const schema of [record(record(actions.get("resource.classify")!.extensions).inputSchema), record(entriesSchema.items)]) {
      const description = record(record(schema.properties).description);
      assert.deepEqual(description.type, ["string", "null"]);
      assert.equal(description.maxLength, 2000);
      const context = record(record(schema.properties).placementContext);
      assert.deepEqual(context.type, ["string", "null"]);
      assert.deepEqual(context.enum, ["interior", "exterior", "both", null]);
      assert.match(String(context.description), /omitted preserves/);
      assert.match(String(context.description), /null clears/);
    }
    const entryKind = (described.resourceKinds as JsonRecord[]).find((entry) => entry.id === "resourceLibraryEntry")!;
    assert.deepEqual(record(record(entryKind.extensions).placementContext).enum, ["interior", "exterior", "both", null]);
    const resourceKinds = new Set((described.resourceKinds as JsonRecord[]).map((entry) => entry.id));
    for (const id of ["resourceLibraryCatalog", "resourceFamily", "resourceLibraryEntry"]) {
      assert.ok(resourceKinds.has(id), id);
    }
    console.log(JSON.stringify({ liveMcpCatalog: true, mutationActions: actions.size,
      resourceKinds: resourceKinds.size, resourceLibraryActions: 5, resourceLibraryQueries: 3 }));
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
      if (record(plan.plan).nonApplicableReason === "no_changes") {
        assert.equal(plan.applicable, false);
        return;
      }
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
    for (const action of ["resource.classify", "resource.classify_batch"]) {
      const parameters = (placementContext: unknown, omitted = false) => {
        const entry = { resourceKind: "element", resourceId: "decor", ...(omitted ? {} : { placementContext }) };
        return action === "resource.classify" ? entry : { entries: [entry] };
      };
      for (const placementContext of ["interior", "exterior", "both"]) {
        await mutate(action, parameters(placementContext));
        await mutate(action, parameters(undefined, true));
        let saved = record(JSON.parse(await readFile(manifestPath, "utf8")));
        assert.deepEqual(record(saved.resourceLibraryCatalog).entries, [{ resourceKind: "element", resourceId: "decor", placementContext }]);
        await mutate(action, parameters(null));
        saved = record(JSON.parse(await readFile(manifestPath, "utf8")));
        assert.equal(saved.resourceLibraryCatalog, undefined);
      }
      for (const invalid of ["unknown", "", " interior ", 1, false, [], {}]) {
        await mutate(action, parameters(invalid), true);
      }
    }
    for (const action of ["resource.classify", "resource.classify_batch"]) {
      const parameters = (description: unknown) => {
        const entry = { resourceKind: "element", resourceId: "decor", description };
        return action === "resource.classify" ? entry : { entries: [entry] };
      };
      await mutate(action, parameters("Arbre pour les routes."));
      await mutate(action, action === "resource.classify" ? { resourceKind: "element", resourceId: "decor" } : { entries: [{ resourceKind: "element", resourceId: "decor" }] });
      const saved = record(JSON.parse(await readFile(manifestPath, "utf8")));
      assert.equal((record(saved.resourceLibraryCatalog).entries as JsonRecord[])[0]!.description, "Arbre pour les routes.");
      await mutate("resource.classify_batch", { entries: [
        { resourceKind: "element", resourceId: "decor", description: "Autre usage." },
        { resourceKind: "tileset", resourceId: "sheet", description: 1 },
      ] }, true);
      await mutate(action, parameters(null));
    }
    await mutate("resource.family.create", { familyId: "forest", name: "Forêt A", parentId: "trees" });
    await mutate("resource.family.create", { familyId: "forest-detail", name: "Petits arbres", parentId: "forest" });
    await mutate("resource.family.update", { familyId: "forest", name: "Forêt locale", parentId: "forest-detail" }, true);
    await mutate("resource.classify", { resourceKind: "element", resourceId: "decor", familyId: "forest-detail", mapId: "a", role: "component", placementContext: "interior" });
    await mutate("resource.classify", { resourceKind: "smartTilePreset", resourceId: "ground", familyId: "ground", mapId: null });
    await mutate("resource.classify_batch", { entries: [
      { resourceKind: "element", resourceId: "decor", familyId: "forest-detail" },
      { resourceKind: "smartTilePreset", resourceId: "ground", familyId: "ground", mapId: null },
      { resourceKind: "tileset", resourceId: "sheet", familyId: "props" },
    ] });
    await mutate("resource.classify_batch", { entries: [
      { resourceKind: "element", resourceId: "decor", familyId: "trees" },
      { resourceKind: "tileset", resourceId: "missing", familyId: "props" },
    ] }, true);
    await mutate("resource.classify_batch", { entries: [
      { resourceKind: "element", resourceId: "decor", placementContext: "both" },
      { resourceKind: "tileset", resourceId: "sheet", placementContext: "unknown" },
    ] }, true);
    await mutate("resource.classify_batch", { entries: [] }, true);
    await mutate("resource.classify_batch", { entries: [
      { resourceKind: "element", resourceId: "decor", familyId: "trees" },
      { resourceKind: "element", resourceId: "decor", familyId: "props" },
    ] }, true);
    await mutate("resource.classify", { resourceKind: "element", resourceId: "absent", familyId: "trees" }, true);
    await mutate("resource.classify", { resourceKind: "element", resourceId: "decor", mapId: "absent" }, true);
    await mutate("resource.classify", { resourceKind: "element", resourceId: "decor", role: "unknown" }, true);
    await mutate("resource.classify", { resourceKind: "element", resourceId: "decor", role: null }, true);
    await mutate("resource.family.delete", { familyId: "forest-detail" }, true);
    await mutate("resource.family.create", { familyId: "temporary", name: "Temporaire" });
    await mutate("resource.family.delete", { familyId: "temporary" });
    await mutate("resource.classify", { resourceKind: "element", resourceId: "decor", role: "standard" });
    await mutate("resource.classify_batch", { entries: [{ resourceKind: "element", resourceId: "decor", role: "component" }] });
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
    const reopened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const catalog = await call("pokemap_query", { projectHandle: reopened.projectHandle,
      resourceKind: "resourceLibraryCatalog", operation: "get", ids: ["resource-library"], view: "detail" });
    assert.ok(JSON.stringify(catalog).includes("forest-detail"));
    const after = record(JSON.parse(await readFile(manifestPath, "utf8")));
    const entries = record(after.resourceLibraryCatalog).entries as JsonRecord[];
    assert.equal(record(after.resourceLibraryCatalog).formatVersion, 2);
    assert.deepEqual(entries.find((entry) => entry.resourceKind === "element"), {
      resourceKind: "element", resourceId: "decor", familyId: "forest-detail", mapId: "a", role: "component", placementContext: "interior",
    });
    assert.deepEqual(entries.find((entry) => entry.resourceKind === "tileset"), {
      resourceKind: "tileset", resourceId: "sheet", familyId: "props",
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

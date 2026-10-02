import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
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

test("resource management traverses packaged stdio server and canonical transactions", async () => {
  const root = await mkdtemp(join(tmpdir(), "uwu3-mcp-stdio-"));
  const path = join(root, "project.json");
  const original = resourceManagementFixture();
  await writeFile(path, JSON.stringify(original));
  const transport = new StdioClientTransport({
    command: process.execPath,
    args: ["dist/src/index.js", "--root", root, "--dart", process.env.POKEMAP_TEST_DART ?? "dart"],
    cwd: process.cwd(), stderr: "pipe",
  });
  const client = new Client({ name: "uwu3-real-stdio", version: "1.0.0" });
  async function data(name: string, args: JsonRecord): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: args });
    assert.equal(result.isError, undefined, JSON.stringify(result.structuredContent));
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, true);
    return record(envelope.data);
  }
  try {
    await client.connect(transport);
    const catalog = await data("pokemap_describe", {});
    const actions = new Map((catalog.mutationActions as JsonRecord[]).map((a) => [a.id, a]));
    const operations: Array<[string, JsonRecord]> = [
      ["tileset_folder.upsert", { folder: { id: "destination", name: "Dossier été" } }],
      ["tileset.metadata.update", { tilesetId: "sheet", name: "Planche été", folderId: "destination" }],
      ["tileset_folder.delete", { folderId: "shared" }],
      ["element_category.upsert", { category: { id: "destination", name: "Décors été" } }],
      ["element.category.assign", { elementId: "decor", categoryId: "destination" }],
      ["element_category.delete", { categoryId: "shared" }],
      ["smart_tile.category.upsert", { category: { id: "destination", name: "Terrains été" } }],
      ["smart_tile.preset.category.assign", { presetId: "ground", categoryId: "destination" }],
      ["smart_tile.category.upsert", { category: { id: "empty", name: "Vide" } }],
      ["smart_tile.category.delete", { categoryId: "empty" }],
    ];
    for (const [id] of operations) {
      assert.ok(actions.has(id), id);
      const schema = record(record(actions.get(id)!.extensions).inputSchema);
      assert.equal(schema.additionalProperties, false, id);
      const evidence = (record(catalog.fullParity).mutationActions as JsonRecord[])
        .find((entry) => entry.actionId === id);
      assert.deepEqual(evidence?.endToEndVerifiedTransports, ["cli", "directApi", "mcp"]);
    }
    const opened = await data("pokemap_workspace", { operation: "open", projectRoot: root });
    const projectHandle = String(opened.projectHandle);
    async function usages(issue = "resource.usages.asset_catalog_unavailable"): Promise<JsonRecord> {
      const authorBytes = await readFile(path);
      const result = await data("pokemap_query", {
        projectHandle, resourceKind: "resourceUsage", operation: "get",
        ids: ["images:sheet"], view: "detail",
      });
      assert.deepEqual(await readFile(path), authorBytes);
      const report = record((result.items as unknown[])[0]);
      assert.equal(report.id, "images:sheet");
      assert.equal(report.complete, false);
      assert.ok((report.coverageIssues as string[]).includes(issue),
        JSON.stringify(report.coverageIssues));
      const definition = (report.entries as JsonRecord[])
        .filter((entry) => entry.ownerKind === "element" && entry.ownerId === "decor");
      assert.equal(definition.length, 1);
      assert.equal(definition[0]!.relation, "direct");
      assert.equal(definition[0]!.ownerLabel, "Décor");
      assert.equal(definition[0]!.resourceFamily, "decors");
      assert.equal(definition[0]!.resourceId, "decor");
      return report;
    }
    const usageBefore = await usages();
    assert.deepEqual(usageBefore.coverageIssues, ["resource.usages.asset_catalog_unavailable"]);
    await mkdir(join(root, "data/pokemon"), { recursive: true });
    const unreadableInventory = join(root, "data/pokemon/media");
    await writeFile(unreadableInventory, "This fixture path is a file, not a media directory.");
    await usages("asset.inventory_unavailable");
    await rm(unreadableInventory);
    const beforeDraft = JSON.stringify(original.smartTileCatalog.drafts);
    for (const [index, [actionId, parameters]] of operations.entries()) {
      const validation = await data("pokemap_validate", { projectHandle });
      const before = await readFile(path);
      const planned = await data("pokemap_plan", { projectHandle, request: {
        requestId: `management-${index}`, actionId, actionVersion: 1,
        workspaceHandle: opened.workspaceHandle, parameters,
        expectedRevision: validation.snapshotRevision,
        idempotencyKey: `management-${index}`, dryRun: false,
      } });
      assert.deepEqual(await readFile(path), before);
      let confirmationToken: unknown;
      if (actions.get(actionId)!.riskLevel === "high") {
        confirmationToken = (await data("pokemap_apply", {
          operation: "confirm", projectHandle, planId: planned.planId,
        })).confirmationToken;
      }
      const arguments_ = {
        operation: "apply", projectHandle, planId: planned.planId,
        operationId: `management-apply-${index}`,
        ...(confirmationToken ? { confirmationToken } : {}),
      };
      const applied = await data("pokemap_apply", arguments_);
      assert.equal(record(applied.receipt).status, "applied");
      const bytes = await readFile(path);
      const repeated = await data("pokemap_apply", arguments_);
      assert.equal(record(repeated.receipt).status, "applied");
      assert.deepEqual(await readFile(path), bytes);
    }
    const usageAfter = await usages();
    assert.notEqual(usageAfter.revision, usageBefore.revision);
    assert.notEqual(record(usageAfter.fingerprints).project, record(usageBefore.fingerprints).project);
    const after = record(JSON.parse(await readFile(path, "utf8")));
    const sheet = record((after.tilesets as unknown[])[0]);
    assert.equal(sheet.id, "sheet");
    assert.equal(sheet.name, "Planche été");
    assert.equal(sheet.relativePath, "assets/source.png");
    assert.deepEqual(sheet.source, original.tilesets[0]!.source);
    assert.deepEqual(sheet.extensionData, original.tilesets[0]!.extensionData);
    assert.equal(record((after.elements as unknown[])[0]).categoryId, "destination");
    const smart = record(after.smartTileCatalog);
    assert.equal(record((smart.presets as unknown[])[0]).categoryId, "destination");
    assert.equal(JSON.stringify(smart.drafts), beforeDraft);
    const occupied = await data("pokemap_validate", { projectHandle });
    const refused = await client.callTool({ name: "pokemap_plan", arguments: {
      projectHandle, request: {
        requestId: "occupied", actionId: "smart_tile.category.delete", actionVersion: 1,
        workspaceHandle: opened.workspaceHandle, parameters: { categoryId: "shared" },
        expectedRevision: occupied.snapshotRevision, idempotencyKey: "occupied", dryRun: false,
      },
    } });
    assert.equal(record(refused.structuredContent).ok, false);
    await data("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
    const reopened = await data("pokemap_workspace", { operation: "open", projectRoot: root });
    const sheetQuery = await data("pokemap_query", {
      projectHandle: reopened.projectHandle, resourceKind: "project", operation: "get",
      ids: ["project"], view: "detail",
    });
    assert.ok(JSON.stringify(sheetQuery).includes("Planche été"));
    console.log(JSON.stringify({
      transport: "packaged stdio", actions: [...new Set(operations.map(([id]) => id))],
      read: { resourceKind: "resourceUsage", id: usageAfter.id, complete: usageAfter.complete,
        coverageIssues: usageAfter.coverageIssues, revisionChanged: usageAfter.revision !== usageBefore.revision },
    }));
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

import assert from "node:assert/strict";
import { readFile, realpath } from "node:fs/promises";
import { isAbsolute, relative, resolve, sep } from "node:path";
import test from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";

const authorizedRoot = "/Users/karim/Project/avelune project";
const referencePath = process.env.AVELUNE_LOT6_KANTO_REFERENCE;

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

function opaqueString(value: unknown): string {
  assert.ok(typeof value === "string" && value.length > 0);
  return value;
}

function assertWithinRoot(root: string, candidate: string): void {
  const path = relative(root, candidate);
  assert.ok(path !== ".." && !path.startsWith(`..${sep}`) && !isAbsolute(path),
    "The published reference must stay within the explicitly authorized root");
}

test("published full Kanto crosses a fresh read-only MCP session with all 383 maps", {
  skip: referencePath ? false : "AVELUNE_LOT6_KANTO_REFERENCE must identify a published delivery.json",
  timeout: 360_000,
}, async () => {
  assert.ok(referencePath && isAbsolute(referencePath));
  const root = await realpath(authorizedRoot);
  const reference = await realpath(referencePath);
  assertWithinRoot(root, reference);
  const delivery = record(JSON.parse(await readFile(reference, "utf8")));
  assert.ok(delivery.contentScope === "world" || delivery.contentScope === "full");
  assert.equal(delivery.kind, delivery.contentScope === "world"
    ? "kantoWorldFoundationDelivery" : "fullKantoCanonicalConverterDelivery");
  assert.equal(delivery.phase, "published");
  assert.equal(delivery.published, true);
  assert.equal(delivery.verified, true);
  assert.equal(delivery.sourceUnchanged, true);
  assert.equal(delivery.mapCount, 383);
  const declaredProject = opaqueString(delivery.projectPath);
  assert.ok(isAbsolute(declaredProject));
  const projectRoot = await realpath(declaredProject);
  assertWithinRoot(root, projectRoot);
  const transport = new StdioClientTransport({
    command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", authorizedRoot,
      "--dart", process.env.POKEMAP_TEST_DART ?? "dart",
      "--authoring-timeout-ms", "120000"],
    cwd: process.cwd(),
    stderr: "pipe",
  });
  const client = new Client({ name: "full-kanto-lot6-read-only", version: "1.0.0" });
  const readOnlyTools = new Set(["pokemap_describe", "pokemap_workspace", "pokemap_query", "pokemap_validate"]);
  let workspaceHandle: string | undefined;
  async function call(name: string, args: JsonRecord = {}): Promise<JsonRecord> {
    assert.ok(readOnlyTools.has(name));
    const response = await client.callTool({ name, arguments: args }, { timeout: 125_000 });
    const envelope = record(response.structuredContent);
    assert.equal(response.isError, undefined, JSON.stringify(envelope));
    assert.equal(envelope.ok, true, JSON.stringify(envelope));
    return record(envelope.data);
  }
  try {
    await client.connect(transport);
    const described = await call("pokemap_describe");
    assert.ok(Array.isArray(described.resourceKinds));
    const mapKind = described.resourceKinds.map(record).find(kind => kind.id === "map");
    assert.ok(mapKind, "The live catalog must expose the map resource kind");
    const resourceKind = opaqueString(mapKind.id);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    workspaceHandle = opaqueString(opened.workspaceHandle);
    const projectHandle = opaqueString(opened.projectHandle);
    const mapIds = new Set<string>();
    const cursors = new Set<string>();
    let cursor: string | undefined;
    let revision: string | undefined;
    let pageCount = 0;
    do {
      const page = await call("pokemap_query", {
        projectHandle, resourceKind, operation: "list", view: "summary", pageSize: 200,
        ...(cursor === undefined ? {} : { cursor }),
      });
      assert.equal(page.totalAvailable, 383);
      assert.ok(Array.isArray(page.items));
      assert.equal(page.returned, page.items.length);
      assert.ok(page.items.length > 0 && page.items.length <= 200);
      const pageRevision = opaqueString(page.snapshotRevision);
      if (revision === undefined) revision = pageRevision;
      assert.equal(pageRevision, revision);
      for (const item of page.items) {
        const id = opaqueString(record(item).id);
        assert.ok(!mapIds.has(id), `Duplicate map across pages: ${id}`);
        mapIds.add(id);
      }
      pageCount++;
      assert.ok(pageCount <= 2);
      cursor = page.nextCursor === null || page.nextCursor === undefined
        ? undefined : opaqueString(page.nextCursor);
      if (cursor !== undefined) {
        assert.ok(!cursors.has(cursor), "The live cursor must advance");
        cursors.add(cursor);
      }
    } while (cursor !== undefined);
    assert.equal(mapIds.size, 383);
    assert.equal(pageCount, 2);
    const validation = await call("pokemap_validate", { projectHandle });
    assert.equal(validation.valid, true, JSON.stringify(validation));
    opaqueString(validation.snapshotRevision);
    const afterValidation = await call("pokemap_query", {
      projectHandle, resourceKind, operation: "list", view: "summary", pageSize: 200,
    });
    assert.equal(afterValidation.snapshotRevision, revision);
    console.log(JSON.stringify({
      kind: "fullKantoLot6ReadOnlyMcpQualification", projectPath: projectRoot,
      contentScope: delivery.contentScope,
      resourceKind, mapCount: mapIds.size, pageCount, valid: validation.valid,
      contentMutationCount: 0, sourceScriptsExecuted: 0,
      NoFullCampaignCertified: true,
    }));
  } finally {
    try {
      if (workspaceHandle !== undefined) {
        await call("pokemap_workspace", { operation: "close", workspaceHandle });
      }
    } finally {
      try {
        await client.close();
      } finally {
        await transport.close();
      }
    }
  }
});

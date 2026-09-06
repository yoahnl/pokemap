import assert from "node:assert/strict";
import { cp, mkdtemp, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";

import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";

import type { JsonRecord } from "../src/authoring_client.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

async function data(client: Client, name: string, args: JsonRecord = {}): Promise<JsonRecord> {
  const result = await client.callTool({ name, arguments: args });
  assert.equal(result.isError, undefined, JSON.stringify(result.structuredContent));
  const envelope = record(result.structuredContent);
  assert.equal(envelope.ok, true);
  return record(envelope.data);
}

test("MENU-I packaged MCP authors and queries regional map semantics", { timeout: 120_000 }, async () => {
  const temporaryRoot = await mkdtemp(join(tmpdir(), "pokemap-regional-map-"));
  const projectRoot = join(temporaryRoot, "project");
  await cp(resolve(process.cwd(), "../../examples/playable_runtime_host/golden_item_system"), projectRoot, { recursive: true });
  const manifest = record(JSON.parse(await readFile(join(projectRoot, "project.json"), "utf8")));
  const mapId = String(record((manifest.maps as unknown[])[0]).id);
  const transport = new StdioClientTransport({ command: process.execPath, args: [resolve(process.cwd(), "dist/src/index.js"), "--root", projectRoot], cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "pokemap-regional-map-test", version: "1.0.0" });
  try {
    await client.connect(transport);
    const description = await data(client, "pokemap_describe");
    for (const kind of ["regionalMap", "regionalMapRegion", "regionalMapPoi"]) assert.ok((description.resourceKinds as JsonRecord[]).some((entry) => entry.id === kind));
    for (const action of ["regionalMap.region.upsert", "regionalMap.region.delete", "regionalMap.poi.upsert", "regionalMap.poi.delete"]) assert.ok((description.mutationActions as JsonRecord[]).some((entry) => entry.id === action));
    const opened = await data(client, "pokemap_workspace", { operation: "open", projectRoot });
    const projectHandle = String(opened.projectHandle);
    const workspaceHandle = String(opened.workspaceHandle);
    let sequence = 0;
    async function apply(actionId: string, parameters: JsonRecord): Promise<void> {
      sequence += 1;
      const query = await data(client, "pokemap_query", { projectHandle, resourceKind: "regionalMap", operation: "list", view: "detail" });
      const planned = await data(client, "pokemap_plan", { projectHandle, request: { requestId: `region-${sequence}`, actionId, actionVersion: 1, workspaceHandle, parameters, expectedRevision: query.snapshotRevision, idempotencyKey: `region-${sequence}`, dryRun: false } });
      let confirmation: JsonRecord = {};
      if (actionId.endsWith(".delete")) confirmation = await data(client, "pokemap_apply", { operation: "confirm", projectHandle, planId: planned.planId });
      const applied = await data(client, "pokemap_apply", { operation: "apply", projectHandle, planId: planned.planId, operationId: `region-operation-${sequence}`, ...(confirmation.confirmationToken ? { confirmationToken: confirmation.confirmationToken } : {}) });
      assert.equal(record(applied.receipt).status, "applied");
    }
    await apply("regionalMap.region.upsert", { region: { id: "r", label: "Region" } });
    await apply("regionalMap.poi.upsert", { poi: { id: "town", regionId: "r", label: "Town", labels: { fr: "Ville" }, u: 0.25, v: 0.75, mapIds: [mapId], discovery: "onMapVisit", visibility: "always" } });
    const query = await data(client, "pokemap_query", { projectHandle, resourceKind: "regionalMapPoi", operation: "get", ids: ["town"], view: "detail" });
    const point = record((query.items as unknown[])[0]);
    assert.equal(point.u, 0.25);
    assert.deepEqual(point.mapIds, [mapId]);
    assert.equal(record(point.labels).fr, "Ville");
    const validation = await data(client, "pokemap_validate", { projectHandle });
    const diagnostics = record(validation.references).diagnostics as JsonRecord[];
    assert.equal(diagnostics.filter((entry) => String(entry.code).startsWith("regional_map.")).length, 0);
    await apply("regionalMap.poi.delete", { poiId: "town" });
    await apply("regionalMap.region.delete", { regionId: "r" });
    const reloaded = record(JSON.parse(await readFile(join(projectRoot, "project.json"), "utf8")));
    assert.deepEqual(record(reloaded.regionalMap).regions, []);
    assert.deepEqual(record(reloaded.regionalMap).pointsOfInterest, []);
    await data(client, "pokemap_workspace", { operation: "close", workspaceHandle });
  } finally {
    await client.close();
    await rm(temporaryRoot, { recursive: true, force: true });
  }
});

import assert from "node:assert/strict";
import { cp, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";

import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";

type RecordValue = Record<string, unknown>;

function record(value: unknown): RecordValue {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as RecordValue;
}

async function data(client: Client, name: string, args: RecordValue = {}): Promise<RecordValue> {
  const result = await client.callTool({ name, arguments: args });
  assert.equal(result.isError, undefined, JSON.stringify(result.structuredContent));
  const envelope = record(result.structuredContent);
  assert.equal(envelope.ok, true);
  return record(envelope.data);
}

test("packaged MCP associates a project capture sprite with its item", { timeout: 120_000 }, async () => {
  const temporary = await mkdtemp(join(tmpdir(), "project-capture-mcp-"));
  const projectRoot = join(temporary, "project");
  await cp(resolve(process.cwd(), "../../examples/playable_runtime_host/golden_item_system"), projectRoot, { recursive: true });
  const pixels = Buffer.from("iVBORw0KGgoAAAANSUhEUgAAAEAAAAgACAYAAACW3jXVAAACFUlEQVR42u3BMQEAAADCoPVP7W0HoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAN4ACHgAAfotprsAAAAASUVORK5CYII=", "base64");
  const sourcePath = join(projectRoot, "capture.png");
  await writeFile(sourcePath, pixels);
  const args = [resolve(process.cwd(), "dist/src/index.js"), "--root", projectRoot];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const client = new Client({ name: "project-capture-test", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  try {
    await client.connect(transport);
    const description = await data(client, "pokemap_describe");
    assert.ok((description.mutationActions as RecordValue[]).some(action => action.id === "item.create"));
    const opened = await data(client, "pokemap_workspace", { operation: "open", projectRoot });
    const projectHandle = String(opened.projectHandle);
    const staged = await data(client, "pokemap_artifact_stage", { sourcePath, declaredMediaType: "image/png" });
    const logicalPath = "data/pokemon/assets/items/review-orb/animation.png";
    const validated = await data(client, "pokemap_validate", { projectHandle });
    const importPlan = await data(client, "pokemap_plan", { projectHandle, request: {
      requestId: "capture-import", actionId: "asset.import_batch", actionVersion: 1,
      workspaceHandle: opened.workspaceHandle, parameters: { entries: [{
        artifactHandle: staged.artifactHandle, assetId: "review-orb-animation", logicalPath,
      }] }, expectedRevision: validated.snapshotRevision, idempotencyKey: "capture-import", dryRun: false,
    } });
    const imported = await data(client, "pokemap_apply", { operation: "apply", projectHandle, planId: importPlan.planId, operationId: "capture-import" });
    assert.equal(record(imported.receipt).status, "applied");
    const itemPlan = await data(client, "pokemap_plan", { projectHandle, request: {
      requestId: "capture-item", actionId: "item.create", actionVersion: 1,
      workspaceHandle: opened.workspaceHandle, parameters: { definition: {
        id: "review-orb", displayName: "Review Orb", pocketId: "balls", buyPrice: 0,
        capture: { rateNumerator: 1, rateDenominator: 1, allowedEncounterKinds: ["walk"], animationSpritePath: logicalPath },
      } }, expectedRevision: imported.snapshotRevision, idempotencyKey: "capture-item", dryRun: false,
    } });
    const applied = await data(client, "pokemap_apply", { operation: "apply", projectHandle, planId: itemPlan.planId, operationId: "capture-item" });
    assert.equal(record(applied.receipt).status, "applied");
    const queried = await data(client, "pokemap_query", { projectHandle, resourceKind: "itemDefinition", operation: "list", view: "detail" });
    assert.equal(queried.snapshotRevision, applied.snapshotRevision);
    const catalog = record(JSON.parse(await readFile(join(projectRoot, "data/pokemon/catalogs/items.json"), "utf8")));
    const item = (catalog.entries as RecordValue[]).find(entry => entry.id === "review-orb");
    assert.equal(record(item?.capture).animationSpritePath, logicalPath);
    assert.deepEqual(await readFile(join(projectRoot, logicalPath)), pixels);
    await data(client, "pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await rm(temporary, { recursive: true, force: true });
  }
});


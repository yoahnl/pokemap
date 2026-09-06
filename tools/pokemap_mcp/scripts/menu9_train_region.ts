import assert from "node:assert/strict";
import { readFile, writeFile, mkdir, copyFile } from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";

type RecordValue = Record<string, unknown>;
const root = resolve(dirname(fileURLToPath(import.meta.url)), "../../..");
const packageRoot = join(root, "tools/pokemap_mcp");
const fixture = join(root, "examples/playable_runtime_host/dev/fixtures/menu9");
const [projectArgument, receiptArgument] = process.argv.slice(2);
assert.ok(projectArgument && receiptArgument, "Usage: menu9_train_region.ts ABSOLUTE_PROJECT ABSOLUTE_RECEIPT");
assert.ok(projectArgument.startsWith("/") && receiptArgument.startsWith("/"));
const projectRoot = resolve(projectArgument);
const receiptPath = resolve(receiptArgument);
const catalog = JSON.parse(await readFile(join(fixture, "train-region.json"), "utf8")) as RecordValue;
const manifest = JSON.parse(await readFile(join(projectRoot, "project.json"), "utf8")) as RecordValue;
const mapIds = new Set((manifest.maps as RecordValue[]).map((map) => map.id));
for (const point of catalog.pointsOfInterest as RecordValue[]) {
  for (const mapId of point.mapIds as string[]) assert.ok(mapIds.has(mapId), `Missing source map ${mapId}`);
}
assert.equal(manifest.name, "Le train de 17h42");
await mkdir(dirname(receiptPath), { recursive: true });
await copyFile(join(projectRoot, "project.json"), `${receiptPath}.project-before.json`);
await copyFile(join(projectRoot, "assets/.pokemap-assets.json"), `${receiptPath}.assets-before.json`);
const transport = new StdioClientTransport({ command: process.execPath,
  args: [join(packageRoot, "dist/src/index.js"), "--root", projectRoot, "--artifact-root", fixture, "--authoring-timeout-ms", "60000"],
  cwd: packageRoot, stderr: "pipe" });
const client = new Client({ name: "menu9-train-regional-map", version: "1.0.0" });
const receipts: RecordValue[] = [];
async function data(name: string, args: RecordValue = {}): Promise<RecordValue> {
  const result = await client.callTool({ name, arguments: args });
  const envelope = result.structuredContent as RecordValue;
  assert.ok(!result.isError && envelope?.ok === true, JSON.stringify(envelope));
  return envelope.data as RecordValue;
}
let workspaceHandle: string | undefined;
try {
  await client.connect(transport);
  const description = await data("pokemap_describe");
  assert.ok((description.mutationActions as RecordValue[]).some((action) => action.id === "regionalMap.poi.upsert"));
  const opened = await data("pokemap_workspace", { operation: "open", projectRoot });
  workspaceHandle = String(opened.workspaceHandle);
  const projectHandle = String(opened.projectHandle);
  const runId = Date.now().toString(36);
  async function apply(actionId: string, parameters: RecordValue): Promise<void> {
    const state = await data("pokemap_query", { projectHandle, resourceKind: "regionalMap", operation: "list", view: "detail" });
    const requestId = `menu9-${runId}-${receipts.length}`;
    const plan = await data("pokemap_plan", { projectHandle, request: {
      requestId, actionId, actionVersion: 1, workspaceHandle, parameters,
      expectedRevision: state.snapshotRevision, idempotencyKey: requestId, dryRun: false,
    } });
    const applied = await data("pokemap_apply", { operation: "apply", projectHandle,
      planId: plan.planId, operationId: requestId });
    const receipt = applied.receipt as RecordValue;
    assert.equal(receipt.status, "applied");
    receipts.push({ actionId, ...receipt });
    await writeFile(receiptPath, JSON.stringify({ ticket: "POST-UI-MENU-007", projectRoot, receipts }, null, 2));
    console.log(`${actionId}: applied`);
  }
  const assets = await data("pokemap_query", { projectHandle, resourceKind: "asset", operation: "list", view: "detail" });
  const assetId = "menu9-train-regional-map";
  const existing = (assets.items as RecordValue[]).find((asset) => asset.id === assetId);
  if (!existing) {
    const staged = await data("pokemap_artifact_stage", { sourcePath: join(fixture, "train-region-draft.png"), declaredMediaType: "image/png" });
    await apply("asset.import", { assetId, logicalPath: "assets/menu/regions/train-1742-draft.png",
      artifactHandle: staged.artifactHandle, tags: ["regional-map", "menu9", "artistic-review-pending"] });
  }
  for (const region of catalog.regions as RecordValue[]) await apply("regionalMap.region.upsert", { region });
  for (const poi of catalog.pointsOfInterest as RecordValue[]) await apply("regionalMap.poi.upsert", { poi });
  const query = await data("pokemap_query", { projectHandle, resourceKind: "regionalMap", operation: "list", view: "detail" });
  const validation = await data("pokemap_validate", { projectHandle });
  const references = validation.references as RecordValue;
  const diagnostics = (references.diagnostics as RecordValue[]).filter((entry) => String(entry.code).startsWith("regional_map."));
  assert.equal(diagnostics.length, 0, JSON.stringify(diagnostics));
  await writeFile(receiptPath, JSON.stringify({ ticket: "POST-UI-MENU-007", projectRoot,
    receipts, query, regionalMapDiagnostics: diagnostics, validation }, null, 2));
  console.log(`Regional map: ${receipts.length} applied actions, zero regional diagnostics. Receipt: ${receiptPath}`);
} finally {
  if (workspaceHandle) await data("pokemap_workspace", { operation: "close", workspaceHandle });
  await client.close();
}

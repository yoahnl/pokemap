import assert from "node:assert/strict";
import { cp, mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";
import { record } from "./support/reliability_stdio.js";

test("asset.import exposes opt-in adoption and preserves the source through undo", async () => {
  const temporary = await mkdtemp(join(tmpdir(), "presentation-adopt-"));
  const root = join(temporary, "project");
  const transport = new StdioClientTransport({
    command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000", "--dart", process.env.POKEMAP_TEST_DART ?? "dart"],
    stderr: "pipe",
  });
  const client = new Client({ name: "presentation-asset-adoption", version: "1" });
  async function call(name: string, args: JsonRecord, failure = false) {
    const response = await client.callTool({ name, arguments: args });
    const envelope = record(response.structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify(envelope));
    return record(failure ? envelope.error : envelope.data);
  }
  try {
    await cp(resolve("../../examples/playable_runtime_host/golden_item_system"), root, { recursive: true });
    const logicalPath = "assets/presentation/LICENSE.txt";
    const source = join(root, logicalPath);
    const text = "Licensed for this project";
    await mkdir(join(root, "assets/presentation"), { recursive: true });
    await writeFile(source, text);
    await client.connect(transport);
    const description = await call("pokemap_describe", { domain: "assets", view: "full", actionIds: ["asset.import"] });
    const action = record((description.mutationActions as JsonRecord[])[0]);
    assert.equal(record(record(action.extensions).adoptExisting).default, false);
    const { projectHandle, workspaceHandle } = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const staged = await call("pokemap_artifact_stage", { sourcePath: source, declaredMediaType: "text/plain" });
    const importParameters = { assetId: "presentation-license", logicalPath, artifactHandle: staged.artifactHandle };
    const validated = await call("pokemap_validate", { projectHandle });
    const ordinary = await call("pokemap_plan", { projectHandle, request: {
      requestId: "ordinary-import", idempotencyKey: "ordinary-import", workspaceHandle, actionId: "asset.import",
      actionVersion: 1, parameters: importParameters, expectedRevision: validated.snapshotRevision,
    } });
    const refused = await call("pokemap_apply", { operation: "apply", projectHandle, operationId: "ordinary-import", planId: ordinary.planId }, true);
    assert.equal(record(refused.details).domainCode, "revision.conflict");
    assert.equal(await readFile(source, "utf8"), text);
    const parameters = { ...importParameters, adoptExisting: true };
    const scope = await call("pokemap_workshop", { operation: "read", projectHandle, actionId: "asset.import", parameters, includeDocuments: false });
    const planned = await call("pokemap_plan", { projectHandle, request: {
      requestId: "license-register", idempotencyKey: "license-register", workspaceHandle, actionId: "asset.import",
      actionVersion: 1, parameters, expectedRevision: scope.snapshotRevision, extensions: scope.planExtensions,
    } });
    const applied = await call("pokemap_apply", { projectHandle, operation: "apply", planId: planned.planId, operationId: "license-register" });
    const catalog = JSON.parse(await readFile(join(root, "assets/.pokemap-assets.json"), "utf8"));
    assert.ok(catalog.records.some((entry: JsonRecord) => entry.id === "presentation-license" && entry.logicalPath === logicalPath));
    await call("pokemap_history", { projectHandle, operation: "undo", entryId: record(applied.receipt).receiptId, idempotencyKey: "license-undo" });
    assert.equal(await readFile(source, "utf8"), text);
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
  } finally {
    try { await client.close(); } finally { await transport.close(); }
    await rm(temporary, { recursive: true, force: true });
  }
});

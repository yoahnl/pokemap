import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { mkdir, mkdtemp, readFile, realpath, rm, symlink, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import test from "node:test";

import { Client } from "@modelcontextprotocol/client";
import { InMemoryTransport } from "@modelcontextprotocol/server";

import { LocalAuthoringClient, type JsonRecord } from "../src/authoring_client.js";
import { MemoryArtifactReader } from "../src/artifacts.js";
import { createPokeMapMcpServer } from "../src/server.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}
function digest(bytes: Uint8Array): string {
  return createHash("sha256").update(bytes).digest("hex");
}

test("real MCP and JSONL native creation use witnessed sources sealed plans and canonical replay", async () => {
  const root = await realpath(await mkdtemp(join(tmpdir(), "pokemap-native-mcp-")));
  const outside = await realpath(await mkdtemp(join(tmpdir(), "pokemap-native-outside-")));
  const options = {
    allowedRoots: [root],
    authoringPackageRoot: resolve(process.cwd(), "../../packages/map_authoring"),
    requestTimeoutMs: 30_000,
  };
  const authoring = new LocalAuthoringClient(options);
  const server = createPokeMapMcpServer({ authoring, artifacts: new MemoryArtifactReader() });
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "native-creation-proof", version: "1.0.0" });
  await server.connect(serverTransport);
  await client.connect(clientTransport);
  async function call(name: string, args: JsonRecord = {}, fail = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: args });
    assert.equal(result.isError, fail ? true : undefined, JSON.stringify(result.structuredContent));
    const envelope = record(result.structuredContent);
    return record(fail ? envelope.error : envelope.data);
  }
  try {
    const listedTools = (await client.listTools()).tools;
    const tools = listedTools.map((tool) => tool.name);
    const publishTool = listedTools.find((tool) => tool.name === "pokemap_project_native_publish");
    assert.equal(publishTool?.annotations?.idempotentHint, true);
    assert.equal(publishTool?.annotations?.openWorldHint, false);
    for (const suffix of ["prepare", "plan", "publish", "release"]) {
      assert.ok(tools.includes(`pokemap_project_native_${suffix}`));
    }
    const described = await call("pokemap_describe");
    const commands = described.commands as JsonRecord[];
    const nativeCommands = commands.filter((row) => row.actionId === "project.create_prepared_native");
    assert.equal(nativeCommands.length, 4);
    assert.ok(nativeCommands.every((row) => row.actionVersion === 1 && row.replacesExisting === false));
    const request = { name: "Native transport MCP", folderName: "seed", parentPath: root,
      template: "playable", tileSize: 32, mapWidth: 12, mapHeight: 10 };
    const preview = await call("pokemap_project_create_preview", { request });
    await call("pokemap_project_create", { request, confirmation: preview.confirmation });
    const manifest = record(JSON.parse(await readFile(join(root, "seed/project.json"), "utf8")));
    const maps = await Promise.all((manifest.maps as JsonRecord[]).map(async (map) =>
      JSON.parse(await readFile(join(root, "seed", map.relativePath as string), "utf8"))));
    const assetCatalog = record(JSON.parse(await readFile(join(root, "seed/assets/.pokemap-assets.json"), "utf8")));
    const records = assetCatalog.records as JsonRecord[];
    const artifacts = await Promise.all(records.map(async (row) => {
      const relativePath = `seed/${row.logicalPath as string}`;
      const bytes = await readFile(join(root, relativePath));
      return { reference: row.artifact, source: { relativePath, sha256: digest(bytes), byteLength: bytes.length } };
    }));
    const descriptorPath = join(root, "native-source.json");
    const descriptorBytes = Buffer.from(JSON.stringify({ kind: "nativeProjectCreationSource", schemaVersion: 1,
      input: { manifest, maps, assetCatalog, artifacts, dialogueSources: {} } }));
    await writeFile(descriptorPath, descriptorBytes);
    const source = { descriptorPath, sha256: digest(descriptorBytes), byteLength: descriptorBytes.length };
    assert.ok(Buffer.byteLength(JSON.stringify({ source })) < 512);
    const copiedPath = join(outside, "native-source.json");
    await writeFile(copiedPath, descriptorBytes);
    const denied = await call("pokemap_project_native_prepare", { source: { ...source, descriptorPath: copiedPath } }, true);
    assert.equal(denied.domainCode, "workspace.path_outside_allowed_roots");
    const prepared = await call("pokemap_project_native_prepare", { source });
    const planArgs = { preparedHandle: prepared.preparedHandle,
      expectedInventoryFingerprint: prepared.inventoryFingerprint, parentPath: root, folderName: "native" };
    const altered = await call("pokemap_project_native_plan", { ...planArgs, expectedInventoryFingerprint: "forged00" }, true);
    assert.equal(altered.domainCode, "native_creation.inventory_changed");
    await writeFile(descriptorPath, Buffer.concat([descriptorBytes, Buffer.from(" ")]));
    const changedDescriptor = await call("pokemap_project_native_plan", planArgs, true);
    assert.equal(changedDescriptor.domainCode, "native_creation.source_changed");
    await writeFile(descriptorPath, descriptorBytes);
    const outsideDestination = await call("pokemap_project_native_plan", { ...planArgs, parentPath: outside }, true);
    assert.equal(outsideDestination.domainCode, "workspace.path_outside_allowed_roots");
    const planned = await call("pokemap_project_native_plan", planArgs);
    const blobPath = join(root, artifacts[0]!.source.relativePath);
    const blobBytes = await readFile(blobPath);
    const changedBytes = Buffer.from(blobBytes);
    changedBytes[changedBytes.length - 1] = changedBytes[changedBytes.length - 1]! ^ 1;
    await writeFile(blobPath, changedBytes);
    const publishArgs = { planHandle: planned.planHandle, expectedInventoryFingerprint: planned.inventoryFingerprint };
    const changedBlob = await call("pokemap_project_native_publish", publishArgs, true);
    assert.equal(changedBlob.domainCode, "native_creation.source_changed");
    await writeFile(blobPath, blobBytes);
    const receipt = await call("pokemap_project_native_publish", publishArgs);
    assert.equal(receipt.inventoryFingerprint, prepared.inventoryFingerprint);
    assert.equal(record(receipt.transactionReceipt).beforeRevision, planned.beforeRevision);
    assert.equal(record(receipt.transactionReceipt).afterRevision, planned.afterRevision);
    assert.equal(record(record(receipt.transactionReceipt).extensions).planId, planned.planId);
    assert.ok(planned.diff);
    const replay = await call("pokemap_project_native_publish", publishArgs);
    assert.equal(record(replay.transactionReceipt).operationId, record(receipt.transactionReceipt).operationId);
    assert.deepEqual(await readFile(join(root, "native/assets/starter.png")), blobBytes);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: receipt.projectPath });
    assert.equal(opened.projectName, "Native transport MCP");
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
    const collision = await call("pokemap_project_native_plan", { ...planArgs, folderName: "collision" });
    await mkdir(join(root, "collision"));
    await writeFile(join(root, "collision/keep"), "keep");
    await call("pokemap_project_native_publish", { planHandle: collision.planHandle,
      expectedInventoryFingerprint: collision.inventoryFingerprint }, true);
    assert.equal(await readFile(join(root, "collision/keep"), "utf8"), "keep");
    const other = new LocalAuthoringClient(options);
    try {
      await assert.rejects(other.request("project_native_plan", planArgs),
        (error: unknown) => record(error).domainCode === "native_creation.prepared_unknown");
    } finally { await other.close(); }
    const linkedDescriptor = join(root, "linked-source.json");
    await symlink(copiedPath, linkedDescriptor);
    const linked = await call("pokemap_project_native_prepare", { source: { ...source, descriptorPath: linkedDescriptor } }, true);
    assert.equal(linked.domainCode, "native_creation.source_path");
    await call("pokemap_project_native_release", { preparedHandle: prepared.preparedHandle });
    const released = await call("pokemap_project_native_plan", planArgs, true);
    assert.equal(released.domainCode, "native_creation.prepared_unknown");
  } finally {
    await client.close();
    await server.close();
    await authoring.close();
    await rm(root, { recursive: true, force: true });
    await rm(outside, { recursive: true, force: true });
  }
});

test("native preparation uses the bounded long-operation timeout without widening ordinary requests", async () => {
  const { chmod } = await import("node:fs/promises");
  const root = await mkdtemp(join(tmpdir(), "pokemap-native-timeout-"));
  const executable = join(root, "worker");
  await writeFile(executable, `#!/usr/bin/env node
const { createInterface } = require("node:readline");
createInterface({ input: process.stdin }).on("line", (line) => {
  const request = JSON.parse(line);
  setTimeout(() => process.stdout.write(JSON.stringify({ requestId: request.id,
    status: "success", data: { command: request.command }, artifacts: [] }) + "\\n"), 80);
});
`);
  await chmod(executable, 0o700);
  const authoring = new LocalAuthoringClient({ allowedRoots: [root],
    authoringPackageRoot: root, dartExecutable: executable,
    requestTimeoutMs: 25, exportRequestTimeoutMs: 2_000 });
  try {
    assert.equal((await authoring.request("project_native_prepare", {})).data.command, "project_native_prepare");
    await assert.rejects(authoring.request("describe"));
  } finally {
    await authoring.close();
    await rm(root, { recursive: true, force: true });
  }
});

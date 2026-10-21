import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";
import { canonicalPokemonConfig } from "./pokemon_fixture.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("MCP discovers, authors and clears an atomic native defeat recovery Fact", { timeout: 180_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "defeat-recovery-mcp-"));
  const projectFile = join(root, "project.json");
  await mkdir(join(root, "maps"));
  for (const id of ["intro", "home"]) await writeFile(join(root, `maps/${id}.json`), JSON.stringify({ id, name: id, version: "v8", size: { width: 4, height: 4 }, layers: [], entities: [] }));
  await writeFile(projectFile, JSON.stringify({ name: "Recovery", version: "v8", tilesets: [], facts: [{ id: "after-loss", label: "Accueil", defaultValue: false }, { id: "count", label: "Count", valueType: "int", defaultValue: 0 }], pokemon: canonicalPokemonConfig(), maps: [
    { id: "intro", name: "Intro", relativePath: "maps/intro.json" },
    { id: "home", name: "Home", relativePath: "maps/home.json" },
  ] }));
  const original = await readFile(projectFile);
  const originalHome = await readFile(join(root, "maps/home.json"));
  const args = [resolve(process.env.POKEMAP_TEST_MCP_ENTRY ?? "dist/src/index.js"), "--root", root,
    "--authoring-package", resolve("../../packages/map_authoring"), "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const client = new Client({ name: "defeat-recovery", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  let workspace: JsonRecord | undefined;
  let sequence = 0;
  async function call(name: string, args: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const envelope = record((await client.callTool({ name, arguments: args })).structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify({ name, envelope }));
    const result = record(envelope[failure ? "error" : "data"]);
    if (failure) assert.notEqual(result.domainCode, "worker.internal");
    return result;
  }
  const config = { recoveredFactId: "after-loss" };
  async function plan(defeatRecovery: JsonRecord | null, failure = false): Promise<JsonRecord> {
    assert.ok(workspace);
    const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    const id = `recovery-${++sequence}`;
    const result = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
      requestId: id, actionId: "campaign.defeat_recovery.update", actionVersion: 1,
      workspaceHandle: workspace.workspaceHandle, expectedRevision: validation.snapshotRevision,
      idempotencyKey: id, parameters: { defeatRecovery },
    } }, failure);
    assert.deepEqual(await readFile(projectFile), original);
    return result;
  }
  try {
    await client.connect(transport);
    const catalog = await call("pokemap_describe");
    const action = (catalog.mutationActions as JsonRecord[]).find(value => value.id === "campaign.defeat_recovery.update");
    assert.ok(action);
    const contract = record(record(action.extensions).defeatRecovery);
    assert.equal(contract.valueType, "boolean");
    assert.equal(contract.value, true);
    assert.equal(contract.atomicWith, "nativeDefeatRecovery");
    assert.equal(contract.sceneContinueApplies, false);
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    for (const invalid of [
      { recoveredFactId: "missing" }, { recoveredFactId: "count" },
      { recoveredFactId: "after-loss", value: false }, { recoveredFactId: "" },
    ]) await plan(invalid, true);
    const prepared = await plan(config);
    const input = { operation: "apply", projectHandle: workspace.projectHandle, planId: prepared.planId, operationId: "recovery-apply" };
    const applied = await call("pokemap_apply", input);
    const saved = await readFile(projectFile);
    assert.deepEqual(record(JSON.parse(saved.toString())).defeatRecovery, config);
    assert.deepEqual((await call("pokemap_apply", input)).receipt, applied.receipt);
    assert.deepEqual(await readFile(projectFile), saved);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const query = await call("pokemap_query", { projectHandle: workspace.projectHandle, resourceKind: "project", operation: "get", ids: ["project"], view: "detail", fieldMask: ["defeatRecovery"] });
    assert.deepEqual(record((query.items as JsonRecord[])[0]).defeatRecovery, config);
    assert.deepEqual(await readFile(join(root, "maps/home.json")), originalHome);
    const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    const cleared = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: { requestId: "clear", actionId: "campaign.defeat_recovery.update", actionVersion: 1, workspaceHandle: workspace.workspaceHandle, expectedRevision: validation.snapshotRevision, idempotencyKey: "clear", parameters: { defeatRecovery: null } } });
    await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle, planId: cleared.planId, operationId: "clear" });
    assert.equal(record(JSON.parse((await readFile(projectFile)).toString())).defeatRecovery, undefined);
  } finally {
    if (workspace) await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

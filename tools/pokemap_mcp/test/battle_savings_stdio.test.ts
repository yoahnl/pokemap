import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
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

test("MCP discovers, authors and clears an persistent battle savings policy", { timeout: 180_000 }, async () => {
  const qaRoot = "/Users/karim/Library/Caches/AveluneQA/battle-savings";
  await mkdir(qaRoot, { recursive: true });
  const root = await mkdtemp(join(qaRoot, "mcp-"));
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
  const client = new Client({ name: "battle-savings", version: "1.0.0" });
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
  const config = { enabledFactId: "after-loss", balanceFactId: "count", percentage: 25, maximumBalance: 999999 };
  async function plan(battleSavings: JsonRecord | null, failure = false): Promise<JsonRecord> {
    assert.ok(workspace);
    const validation = await call("pokemap_workshop", { operation: "read", projectHandle: workspace.projectHandle, actionId: "campaign.battle_savings.update", parameters: { battleSavings } });
    const id = `recovery-${++sequence}`;
    const result = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
      requestId: id, actionId: "campaign.battle_savings.update", actionVersion: 1,
      workspaceHandle: workspace.workspaceHandle, expectedRevision: validation.snapshotRevision,
      idempotencyKey: id, parameters: { battleSavings }, extensions: { workshopScope: true },
    } }, failure);
    assert.deepEqual(await readFile(projectFile), original);
    return result;
  }
  try {
    await client.connect(transport);
    const catalog = await call("pokemap_describe");
    const action = (catalog.mutationActions as JsonRecord[]).find(value => value.id === "campaign.battle_savings.update");
    assert.ok(action);
    const contract = record(record(action.extensions).battleSavings);
    assert.equal(contract.percentage, "integer:0..100");
    assert.equal(contract.atomicWith, "battleRewardsAndCompletedRequest");
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    for (const invalid of [
      { ...config, enabledFactId: "missing" }, { ...config, balanceFactId: "after-loss" },
      { ...config, percentage: 101 }, { ...config, maximumBalance: -1 },
    ]) await plan(invalid, true);
    const prepared = await plan(config);
    const input = { operation: "apply", projectHandle: workspace.projectHandle, planId: prepared.planId, operationId: "recovery-apply" };
    const applied = await call("pokemap_apply", input);
    const saved = await readFile(projectFile);
    assert.deepEqual(record(JSON.parse(saved.toString())).battleSavings, config);
    assert.deepEqual((await call("pokemap_apply", input)).receipt, applied.receipt);
    assert.deepEqual(await readFile(projectFile), saved);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const query = await call("pokemap_query", { projectHandle: workspace.projectHandle, resourceKind: "project", operation: "get", ids: ["project"], view: "detail", fieldMask: ["battleSavings"] });
    assert.deepEqual(record((query.items as JsonRecord[])[0]).battleSavings, config);
    assert.deepEqual(await readFile(join(root, "maps/home.json")), originalHome);
    const validation = await call("pokemap_workshop", { operation: "read", projectHandle: workspace.projectHandle, actionId: "campaign.battle_savings.update", parameters: { battleSavings: null } });
    const cleared = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: { requestId: "clear", actionId: "campaign.battle_savings.update", actionVersion: 1, workspaceHandle: workspace.workspaceHandle, expectedRevision: validation.snapshotRevision, idempotencyKey: "clear", parameters: { battleSavings: null }, extensions: { workshopScope: true } } });
    await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle, planId: cleared.planId, operationId: "clear" });
    assert.equal(record(JSON.parse((await readFile(projectFile)).toString())).battleSavings, undefined);
  } finally {
    if (workspace) await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

test("MCP savings rejects a conflicting runtime Fact alias before mutation", { timeout: 180_000 }, async () => {
  const qaRoot = "/Users/karim/Library/Caches/AveluneQA/battle-savings";
  await mkdir(qaRoot, { recursive: true });
  const root = await mkdtemp(join(qaRoot, "mcp-alias-"));
  const projectFile = join(root, "project.json");
  const config = { enabledFactId: "enabled", balanceFactId: "balance", percentage: 25, maximumBalance: 999999 };
  await writeFile(projectFile, JSON.stringify({ name: "Alias conflict", version: "v8", maps: [], tilesets: [], pokemon: canonicalPokemonConfig(), facts: [
    { id: "enabled", label: "Enabled", defaultValue: false, legacyFlagName: "shared" },
    { id: "conflicting", label: "Conflicting", defaultValue: false, legacyFlagName: "shared" },
    { id: "balance", label: "Balance", valueType: "int", defaultValue: 0 },
  ] }));
  const original = await readFile(projectFile);
  const args = [resolve(process.env.POKEMAP_TEST_MCP_ENTRY ?? "dist/src/index.js"), "--root", root,
    "--authoring-package", resolve("../../packages/map_authoring"), "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const client = new Client({ name: "savings-alias", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  let workspace: JsonRecord | undefined;
  async function call(name: string, args: JsonRecord, failure = false): Promise<JsonRecord> {
    const envelope = record((await client.callTool({ name, arguments: args })).structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify(envelope));
    return record(envelope[failure ? "error" : "data"]);
  }
  try {
    await client.connect(transport);
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const scoped = await call("pokemap_workshop", { operation: "read", projectHandle: workspace.projectHandle,
      actionId: "campaign.battle_savings.update", parameters: { battleSavings: config } });
    assert.deepEqual((record(scoped.project).facts as JsonRecord[]).map(fact => fact.id).sort(), ["balance", "conflicting", "enabled"]);
    const rejected = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
      requestId: "alias-conflict", actionId: "campaign.battle_savings.update", actionVersion: 1,
      workspaceHandle: workspace.workspaceHandle, expectedRevision: scoped.snapshotRevision,
      parameters: { battleSavings: config }, idempotencyKey: "alias-conflict", extensions: { workshopScope: true },
    } }, true);
    assert.notEqual(rejected.domainCode, "worker.internal");
    assert.deepEqual(await readFile(projectFile), original);
  } finally {
    if (workspace) await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

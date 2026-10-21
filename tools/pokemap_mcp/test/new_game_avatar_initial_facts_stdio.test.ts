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

test("MCP discovers and authors typed initial facts from the selected avatar", { timeout: 180_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "new-game-avatar-facts-mcp-"));
  const projectFile = join(root, "project.json");
  await mkdir(join(root, "maps"));
  for (const id of ["intro", "home"]) await writeFile(join(root, `maps/${id}.json`), JSON.stringify({ id, name: id, version: "v8", size: { width: 4, height: 4 }, layers: [], entities: [] }));
  await writeFile(projectFile, JSON.stringify({ name: "Recovery", version: "v8", tilesets: [], pokemon: canonicalPokemonConfig(), maps: [
    { id: "intro", name: "Intro", relativePath: "maps/intro.json" },
    { id: "home", name: "Home", relativePath: "maps/home.json" },
  ] }));
  const initial = record(JSON.parse((await readFile(projectFile)).toString()));
  initial.tilesets = [{ id: "actors", name: "Actors", relativePath: "actors.png" }];
  initial.characters = ["a", "b"].map(id => ({ id, name: id, tilesetId: "actors" }));
  initial.facts = [
    { id: "identity", label: "Identity", valueType: "int", defaultValue: -1 },
    { id: "label", label: "Label", valueType: "string", defaultValue: "" },
    { id: "party", label: "Party", defaultValue: false },
  ];
  await writeFile(projectFile, JSON.stringify(initial));
  await writeFile(join(root, "actors.png"), Buffer.from("iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAASUlEQVR42mNkoAA4LEj4D2MfSFjASI4ZTAwDDEYdMOqAUQeMOmDUAaMOGHAHMCJXqaNRMCBRMNoiGnXAqANGHTDqgFEHjHgHAADb/Qp9KEMvVQAAAABJRU5ErkJggg==", "base64"));
  const original = await readFile(projectFile);
  const originalHome = await readFile(join(root, "maps/home.json"));
  const args = [resolve(process.env.POKEMAP_TEST_MCP_ENTRY ?? "dist/src/index.js"), "--root", root,
    "--authoring-package", resolve("../../packages/map_authoring"), "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const client = new Client({ name: "new-game-avatar-facts", version: "1.0.0" });
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
  const mapping = { a: { identity: 0, label: "first" }, b: { identity: 1, label: "second" } };
  const config = { enabled: true, startMapId: "intro", playerAvatarCharacterIds: ["a", "b"],
    existingPartyFactId: "party", initialFactValuesByAvatarCharacterId: mapping };
  async function plan(newGame: JsonRecord, failure = false): Promise<JsonRecord> {
    assert.ok(workspace);
    const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    const id = `recovery-${++sequence}`;
    const result = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
      requestId: id, actionId: "campaign.new_game.update", actionVersion: 1,
      workspaceHandle: workspace.workspaceHandle, expectedRevision: validation.snapshotRevision,
      idempotencyKey: id, parameters: { newGame },
    } }, failure);
    assert.deepEqual(await readFile(projectFile), original);
    return result;
  }
  try {
    await client.connect(transport);
    const catalog = await call("pokemap_describe");
    const action = (catalog.mutationActions as JsonRecord[]).find(value => value.id === "campaign.new_game.update");
    assert.ok(action);
    const contract = record(record(action.extensions).initialFactValuesByAvatarCharacterId);
    assert.equal(contract.omitWhenEmpty, true);
    assert.deepEqual(contract.valueTypes, ["bool", "int", "string"]);
    assert.equal(contract.unknownReferences, "rejectBeforeWrite");
    assert.equal(contract.recomputeOnSaveRestore, false);
    assert.deepEqual(contract.precedence, ["baseInitialFacts", "selectedAvatarFacts", "derivedExistingParty"]);
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    for (const invalid of [
      { missing: { identity: 0 } }, { a: { missing: 0 } }, { a: { identity: true } },
      { a: { label: 1 } }, { a: { party: true } }, { a: [] }, [], null,
    ]) await plan({ ...config, initialFactValuesByAvatarCharacterId: invalid }, true);
    const prepared = await plan(config);
    const input = { operation: "apply", projectHandle: workspace.projectHandle, planId: prepared.planId, operationId: "recovery-apply" };
    const applied = await call("pokemap_apply", input);
    const saved = await readFile(projectFile);
    assert.deepEqual(record(record(JSON.parse(saved.toString())).newGame).initialFactValuesByAvatarCharacterId, mapping);
    assert.equal(record(record(JSON.parse(saved.toString())).newGame).startMapId, "intro");
    assert.deepEqual((await call("pokemap_apply", input)).receipt, applied.receipt);
    assert.deepEqual(await readFile(projectFile), saved);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const query = await call("pokemap_query", { projectHandle: workspace.projectHandle, resourceKind: "project", operation: "get", ids: ["project"], view: "detail", fieldMask: ["newGame"] });
    assert.deepEqual(record(record((query.items as JsonRecord[])[0]).newGame).initialFactValuesByAvatarCharacterId, mapping);
    assert.deepEqual(await readFile(join(root, "maps/home.json")), originalHome);
  } finally {
    if (workspace) await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

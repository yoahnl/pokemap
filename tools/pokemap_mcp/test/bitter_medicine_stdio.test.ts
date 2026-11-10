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

test("fresh MCP authors bitter medicines and held berries and reopens their semantics", { timeout: 180_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "c711c-medicine-"));
  const itemPath = join(root, "data/pokemon/catalogs/items.json");
  await mkdir(join(root, "data/pokemon/catalogs"), { recursive: true });
  await writeFile(join(root, "project.json"), JSON.stringify({name: "Medicine", version: "v8", maps: [], tilesets: [], pokemon: canonicalPokemonConfig()}));
  await writeFile(itemPath, JSON.stringify({schemaVersion: 1, entries: ["powder", "berry"].map(id => ({id, displayName: id, pocketId: "medicine"}))}));
  const connect = async () => {
    const client = new Client({name: "c711c", version: "1.0.0"});
    await client.connect(new StdioClientTransport({command: process.execPath, args: [resolve(process.env.POKEMAP_TEST_MCP_ENTRY ?? "dist/src/index.js"),
      "--root", root, "--authoring-timeout-ms", "120000"], cwd: process.cwd(), stderr: "pipe"}));
    return client;
  };
  let client: Client | undefined;
  const call = async (name: string, input: JsonRecord) => {
    const result = await client!.callTool({name, arguments: input});
    assert.equal(result.isError, undefined, JSON.stringify(result));
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, true, JSON.stringify(envelope));
    return record(envelope.data);
  };
  try {
    client = await connect();
    const description = await call("pokemap_describe", {actionIds: ["item.set_overworld_effect", "item.set_battle_effect", "item.set_held_effect"], view: "full"});
    for (const action of description.mutationActions as JsonRecord[]) {
      const extensions = record(action.extensions);
      if (action.id === "item.set_held_effect") {
        assert.ok((extensions.heldEffectIds as string[]).includes("oran_berry"));
        assert.ok((extensions.heldEffectIds as string[]).includes("pecha_berry"));
      } else {
        assert.equal(record(extensions.friendshipLoss).requiredCapability, "items.friendship-loss@1");
      }
    }
    const opened = await call("pokemap_workspace", {operation: "open", projectRoot: root});
    await call("pokemap_workshop", {operation: "prepare", projectHandle: opened.projectHandle});
    for (const context of ["overworld", "battle", "held"]) {
      const actionId = `item.set_${context}_effect`;
      const parameters = context === "held" ? {itemId: "berry", heldEffectId: "pecha_berry"} : {itemId: "powder", use: {
        contexts: [context], target: "party_member", consumption: "on_applied", friendshipLoss: {low: 5, medium: 5, high: 10},
        effect: {kind: "cure_status", mode: "all", statusIds: [], curesConfusion: true}}};
      const scoped = await call("pokemap_workshop", {operation: "read", projectHandle: opened.projectHandle, actionId, parameters, includeDocuments: false});
      const identity = `c711c-${context}`;
      const plan = await call("pokemap_plan", {projectHandle: opened.projectHandle, request: {requestId: identity, actionId, actionVersion: 1,
        workspaceHandle: opened.workspaceHandle, expectedRevision: scoped.snapshotRevision, extensions: scoped.planExtensions ?? {}, idempotencyKey: identity, parameters}});
      const applied = await call("pokemap_apply", {operation: "apply", projectHandle: opened.projectHandle, planId: plan.planId, operationId: identity});
      assert.equal(record(applied.receipt).status, "applied");
    }
    await call("pokemap_workspace", {operation: "close", workspaceHandle: opened.workspaceHandle});
    await client.close();
    client = await connect();
    const reopened = await call("pokemap_workspace", {operation: "open", projectRoot: root});
    const result = await call("pokemap_query", {projectHandle: reopened.projectHandle, resourceKind: "itemDefinition", operation: "get", ids: ["powder"], view: "detail"});
    const uses = record((result.items as JsonRecord[])[0]).uses as JsonRecord[];
    assert.equal(uses.length, 2);
    for (const use of uses) {
      assert.deepEqual(use.friendshipLoss, {low: 5, medium: 5, high: 10});
      assert.equal(record(use.effect).curesConfusion, true);
    }
    const catalog = JSON.parse(await readFile(itemPath, "utf8")) as {entries: JsonRecord[]};
    assert.equal(catalog.entries.find(item => item.id === "berry")?.heldEffectId, "pecha_berry");
    await call("pokemap_workspace", {operation: "close", workspaceHandle: reopened.workspaceHandle});
  } finally {
    await client?.close();
    await rm(root, {recursive: true, force: true});
  }
});

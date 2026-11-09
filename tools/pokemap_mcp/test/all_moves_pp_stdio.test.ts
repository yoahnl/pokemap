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

async function call(client: Client, name: string, input: JsonRecord): Promise<JsonRecord> {
  const result = await client.callTool({ name, arguments: input });
  assert.equal(result.isError, undefined, JSON.stringify(result));
  const envelope = record(result.structuredContent);
  assert.equal(envelope.ok, true, JSON.stringify(envelope));
  return record(envelope.data);
}

test("C7-04 fresh stdio authors all-move PP scopes and reopens them cold", { timeout: 180_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "c704-all-pp-"));
  const itemPath = join(root, "data/pokemon/catalogs/items.json");
  await mkdir(join(root, "data/pokemon/catalogs"), { recursive: true });
  await writeFile(join(root, "project.json"), JSON.stringify({
    name: "C7-04 PP", version: "v8", maps: [], tilesets: [], pokemon: canonicalPokemonConfig(),
  }));
  await writeFile(itemPath, JSON.stringify({ schemaVersion: 1, entries: [
    { id: "elixir", displayName: "Élixir", pocketId: "medicine" },
  ] }));
  const connect = async () => {
    const client = new Client({ name: "c704-all-pp", version: "1.0.0" });
    await client.connect(new StdioClientTransport({ command: process.execPath,
      args: [resolve(process.env.POKEMAP_TEST_MCP_ENTRY ?? "dist/src/index.js"),
        "--root", root, "--authoring-timeout-ms", "120000"],
      cwd: process.cwd(), stderr: "pipe" }));
    return client;
  };
  let client: Client | undefined;
  try {
    client = await connect();
    const description = await call(client, "pokemap_describe", {
      actionIds: ["item.set_overworld_effect", "item.set_battle_effect"], view: "full",
    });
    for (const action of description.mutationActions as JsonRecord[]) {
      const contract = record(record(action.extensions).restorePp);
      assert.deepEqual(contract.scopes, ["selected_move", "all_moves"]);
      assert.equal(record(contract.allMoves).target, "party_member");
    }
    const opened = await call(client, "pokemap_workspace", { operation: "open", projectRoot: root });
    await call(client, "pokemap_workshop", { operation: "prepare", projectHandle: opened.projectHandle });
    for (const context of ["overworld", "battle"]) {
      for (const mode of ["flat", "full"]) {
        const effect = { kind: "restore_pp", mode, amount: mode === "flat" ? 10 : null, scope: "all_moves" };
        const actionId = `item.set_${context}_effect`;
        const parameters = { itemId: "elixir", use: { contexts: [context], target: "party_member", consumption: "on_applied", effect } };
        const scoped = await call(client, "pokemap_query", {
          projectHandle: opened.projectHandle, resourceKind: "itemDefinition", operation: "list", view: "detail" });
        const id = `c704-${context}-${mode}`;
        const planned = await call(client, "pokemap_plan", { projectHandle: opened.projectHandle, request: {
          requestId: id, actionId, actionVersion: 1, workspaceHandle: opened.workspaceHandle,
          expectedRevision: scoped.snapshotRevision, extensions: scoped.planExtensions ?? {},
          parameters, idempotencyKey: id, dryRun: false,
        } });
        const applied = await call(client, "pokemap_apply", { operation: "apply",
          projectHandle: opened.projectHandle, planId: planned.planId, operationId: `${id}-apply` });
        assert.equal(record(applied.receipt).status, "applied");
        const catalog = JSON.parse(await readFile(itemPath, "utf8")) as {entries: {uses: JsonRecord[]}[]};
        assert.deepEqual(catalog.entries[0]!.uses.find(use => (use.contexts as string[]).includes(context))!.effect, effect);
      }
    }
    await call(client, "pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
    await client.close();
    client = await connect();
    const reopened = await call(client, "pokemap_workspace", { operation: "open", projectRoot: root });
    const result = await call(client, "pokemap_query", { projectHandle: reopened.projectHandle,
      resourceKind: "itemDefinition", operation: "get", view: "detail", ids: ["elixir"] });
    const uses = record((result.items as JsonRecord[])[0]).uses as JsonRecord[];
    assert.equal(uses.length, 2);
    for (const use of uses) assert.deepEqual(use.effect, { kind: "restore_pp", mode: "full", amount: null, scope: "all_moves" });
    await call(client, "pokemap_workspace", { operation: "close", workspaceHandle: reopened.workspaceHandle });
  } finally {
    await client?.close();
    await rm(root, { recursive: true, force: true });
  }
});

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
async function tool(client: Client, name: string, args: JsonRecord = {}): Promise<JsonRecord> {
  const result = await client.callTool({ name, arguments: args });
  assert.equal(result.isError, undefined, JSON.stringify(result));
  const envelope = record(result.structuredContent);
  assert.equal(envelope.ok, true, JSON.stringify(envelope));
  return record(envelope.data);
}

test("fresh stdio authors atomic Full Restore in both contexts and cold reloads", { timeout: 240000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-full-restore-"));
  const catalogPath = join(root, "data/pokemon/catalogs/items.json");
  await mkdir(join(root, "maps"), { recursive: true });
  for (const name of ["catalogs", "species", "learnsets", "evolutions", "media"]) {
    await mkdir(join(root, "data/pokemon", name), { recursive: true });
  }
  await writeFile(join(root, "project.json"), JSON.stringify({
    name: "Full Restore contract", version: "v8", tilesets: [], pokemon: canonicalPokemonConfig(),
    maps: [{ id: "lab", name: "Lab", relativePath: "maps/lab.json" }],
  }));
  await writeFile(join(root, "maps/lab.json"), JSON.stringify({
    id: "lab", name: "Lab", version: "v8", size: { width: 3, height: 3 },
  }));
  await writeFile(catalogPath, JSON.stringify({ schemaVersion: 1, entries: [
    { id: "full-restore", displayName: "Soin Total", pocketId: "medicine" },
  ] }));
  for (const name of ["types", "abilities", "moves", "growth_rates"]) {
    await writeFile(join(root, "data/pokemon/catalogs", `${name}.json`),
      JSON.stringify({ schemaVersion: 1, catalog: name, entries: [] }));
  }
  const connect = async (): Promise<Client> => {
    const client = new Client({ name: "full-restore-contract", version: "1.0.0" });
    await client.connect(new StdioClientTransport({
      command: process.execPath,
      args: [resolve(process.env.POKEMAP_TEST_MCP_ENTRY ?? "dist/src/index.js"),
        "--root", root, "--authoring-timeout-ms", "120000"],
      cwd: process.cwd(), stderr: "pipe",
    }));
    return client;
  };
  let client: Client | undefined;
  try {
    client = await connect();
    const described = await tool(client, "pokemap_describe");
    const actions = described.mutationActions as JsonRecord[];
    for (const context of ["overworld", "battle"]) {
      const descriptor = actions.find((a) => a.id === `item.set_${context}_effect`);
      assert.ok(descriptor);
      const extension = record(descriptor.extensions);
      assert.ok((extension.effectKinds as string[]).includes("full_restore"));
      assert.equal(record(extension.fullRestore).consumption, "one_on_applied");
      assert.equal(record(extension.fullRestore).restoresPp, false);
    }
    const opened = await tool(client, "pokemap_workspace", { operation: "open", projectRoot: root });
    for (const context of ["overworld", "battle"]) {
      const before = await tool(client, "pokemap_validate", { projectHandle: opened.projectHandle });
      const planned = await tool(client, "pokemap_plan", { projectHandle: opened.projectHandle,
        request: { requestId: `full-restore-${context}`, actionId: `item.set_${context}_effect`, actionVersion: 1,
          workspaceHandle: opened.workspaceHandle, expectedRevision: before.snapshotRevision,
          parameters: { itemId: "full-restore", use: {
            contexts: [context], target: "party_member", consumption: "on_applied", effect: { kind: "full_restore" },
          } }, idempotencyKey: `full-restore-${context}`, dryRun: false } });
      await tool(client, "pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle,
        planId: planned.planId, operationId: `apply-full-restore-${context}` });
    }
    const beforeInvalid = await readFile(catalogPath, "utf8");
    const valid = await tool(client, "pokemap_validate", { projectHandle: opened.projectHandle });
    const invalid = await client.callTool({ name: "pokemap_plan", arguments: {
      projectHandle: opened.projectHandle, request: {
        requestId: "invalid-full-restore", actionId: "item.set_battle_effect", actionVersion: 1,
        workspaceHandle: opened.workspaceHandle, expectedRevision: valid.snapshotRevision,
        parameters: { itemId: "full-restore", use: { contexts: ["battle"], target: "party_member",
          consumption: "on_applied", effect: { kind: "full_restore", amount: 50 } } },
        idempotencyKey: "invalid-full-restore", dryRun: false,
      },
    } });
    assert.equal(invalid.isError, true);
    assert.equal(await readFile(catalogPath, "utf8"), beforeInvalid);
    await tool(client, "pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
    await client.close(); client = await connect();
    const reopened = await tool(client, "pokemap_workspace", { operation: "open", projectRoot: root });
    const queried = await tool(client, "pokemap_query", { projectHandle: reopened.projectHandle,
      resourceKind: "itemDefinition", operation: "get", view: "detail", ids: ["full-restore"] });
    const uses = record((queried.items as JsonRecord[])[0]).uses as JsonRecord[];
    assert.equal(uses.length, 2);
    for (const context of ["overworld", "battle"]) {
      const use = uses.find((u) => (u.contexts as string[]).includes(context)); assert.ok(use);
      assert.deepEqual(use.effect, { kind: "full_restore" });
      assert.equal(use.target, "party_member"); assert.equal(use.consumption, "on_applied");
    }
    await tool(client, "pokemap_workspace", { operation: "close", workspaceHandle: reopened.workspaceHandle });
  } finally {
    await client?.close();
    await rm(root, { recursive: true, force: true });
  }
});

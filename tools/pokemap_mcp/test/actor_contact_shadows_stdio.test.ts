import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import test from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";
import { canonicalPokemonConfig } from "./pokemon_fixture.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("actor contact shadows cross fresh MCP with nullable overrides and undo", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "actor-contact-shadow-mcp-"));
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "actor-contact-shadow-test", version: "1.0.0" });
  async function call(name: string, input: JsonRecord, failed = false): Promise<JsonRecord> {
    const envelope = record((await client.callTool({ name, arguments: input })).structuredContent);
    assert.equal(envelope.ok, !failed, JSON.stringify(envelope));
    return record(envelope[failed ? "error" : "data"]);
  }
  try {
    const file = join(root, "project.json");
    await writeFile(file, JSON.stringify({ name: "Contact shadows", version: "v8", maps: [],
      tilesets: [{ id: "actors", name: "Actors", relativePath: "assets/actors.png" }],
      characters: [{ id: "hero", name: "Hero", tilesetId: "actors" }], pokemon: canonicalPokemonConfig() }));
    await client.connect(transport);
    const catalog = await call("pokemap_describe", {});
    const descriptors = catalog.mutationActions as JsonRecord[];
    const projectAction = "project.actor_contact_shadows.configure";
    const descriptor = descriptors.find(value => value.id === projectAction);
    assert.ok(descriptor);
    const schema = record(record(descriptor.extensions).inputSchema);
    assert.deepEqual(schema.required, ["enabled"]);
    const characterDescriptor = descriptors.find(value => value.id === "characterStudio.character.update");
    assert.deepEqual(record(record(record(record(characterDescriptor?.extensions).inputSchema).properties).contactShadow).type, ["boolean", "null"]);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const query = () => call("pokemap_query", { projectHandle: opened.projectHandle, resourceKind: "project", operation: "get", ids: ["project"], view: "detail" });
    let sequence = 0;
    async function plan(actionId: string, parameters: JsonRecord, failed = false): Promise<JsonRecord> {
      const id = `contact-${++sequence}`;
      const current = await query();
      return call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
        requestId: id, idempotencyKey: id, workspaceHandle: opened.workspaceHandle,
        actionId, actionVersion: 1, expectedRevision: current.snapshotRevision, parameters,
      } }, failed);
    }
    async function apply(planned: JsonRecord): Promise<JsonRecord> {
      return call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle,
        planId: planned.planId, operationId: `apply-${++sequence}` });
    }
    const bytes = await readFile(file);
    const planned = await plan(projectAction, { enabled: true });
    assert.deepEqual(await readFile(file), bytes);
    const applied = await apply(planned);
    assert.equal(record(record(JSON.parse(await readFile(file, "utf8"))).settings).actorContactShadowsByDefault, true);
    await call("pokemap_history", { operation: "undo", projectHandle: opened.projectHandle,
      entryId: record(applied.receipt).receiptId, idempotencyKey: "contact-undo" });
    assert.deepEqual(await readFile(file), bytes);
    await apply(await plan(projectAction, { enabled: true }));
    const character = async () => record((record(JSON.parse(await readFile(file, "utf8"))).characters as unknown[])[0]);
    for (const enabled of [false, true]) {
      await apply(await plan("characterStudio.character.update", { characterId: "hero", contactShadow: enabled }));
      assert.equal((await character()).contactShadow, enabled);
    }
    await apply(await plan("characterStudio.character.update", { characterId: "hero", name: "Renamed" }));
    assert.equal((await character()).contactShadow, true);
    await apply(await plan("characterStudio.character.update", { characterId: "hero", contactShadow: null }));
    assert.equal(Object.hasOwn(await character(), "contactShadow"), false);
    const beforeInvalid = await readFile(file);
    await plan(projectAction, { enabled: null }, true);
    await plan("characterStudio.character.update", { characterId: "hero", contactShadow: "false" }, true);
    assert.deepEqual(await readFile(file), beforeInvalid);
    const detail = await call("pokemap_query", { projectHandle: opened.projectHandle,
      resourceKind: "characterStudioCharacter", operation: "get", ids: ["hero"], view: "detail" });
    assert.equal((detail.items as unknown[]).length, 1);
    assert.equal(record((detail.items as unknown[])[0]).effectiveContactShadow, true);
    assert.equal(Object.hasOwn(record((detail.items as unknown[])[0]), "contactShadow"), false);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

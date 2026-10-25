import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { mkdtemp, readFile, readdir, rm, writeFile } from "node:fs/promises";
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

test("targeted contact tools inspect and set without opening a full workspace", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "contact-targeted-mcp-"));
  const outside = await mkdtemp(join(tmpdir(), "contact-targeted-outside-"));
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "targeted-contact-test", version: "1.0.0" });
  async function call(name: string, input: JsonRecord, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: input });
    const body = record(result.structuredContent);
    assert.equal(body.ok, !failure, JSON.stringify(body));
    return record(body[failure ? "error" : "data"]);
  }
  try {
    const file = join(root, "project.json");
    await writeFile(file, JSON.stringify({ version: "v9", name: "Targeted", maps: [], tilesets: [], settings: { dimension: "threeD" },
      characters: [{ id: "hero", name: "Hero", tilesetId: "deliberately-unavailable" }] }));
    await client.connect(transport);
    const names = (await client.listTools()).tools.map(tool => tool.name);
    assert.ok(names.includes("pokemap_character_contact_shadow_inspect"));
    assert.ok(names.includes("pokemap_character_contact_shadow_set"));
    const catalog = await call("pokemap_describe", {});
    assert.equal(record(catalog.characterContactShadowAuthoring).id, "characterStudio.contactShadow.set");
    assert.ok((catalog.commands as JsonRecord[]).some(command => command.id === "character_contact_shadow_set"));
    let current = await call("pokemap_character_contact_shadow_inspect", { projectRoot: root, characterId: "hero" });
    assert.equal(current.contactShadow, null);
    let index = 0;
    for (const enabled of [true, false, null]) {
      const operationId = `targeted-mcp-${++index}`;
      const input = { projectRoot: root, characterId: "hero", expectedRevision: current.revision, enabled, operationId };
      const changed = await call("pokemap_character_contact_shadow_set", input);
      assert.equal(changed.afterValue, enabled);
      const bytes = await readFile(file);
      await call("pokemap_character_contact_shadow_set", input);
      assert.deepEqual(await readFile(file), bytes);
      current = await call("pokemap_character_contact_shadow_inspect", { projectRoot: root, characterId: "hero" });
      assert.equal(current.contactShadow, enabled);
    }
    await call("pokemap_character_contact_shadow_set", { projectRoot: root, characterId: "hero", expectedRevision: "stale-revision", enabled: true, operationId: "targeted-stale" }, true);
    await call("pokemap_character_contact_shadow_inspect", { projectRoot: outside, characterId: "hero" }, true);
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
    await rm(outside, { recursive: true, force: true });
  }
});

test("working catalog contact states use one worker and survive a fresh MCP worker", { timeout: 180_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "contact-catalog-mcp-"));
  const file = join(root, "project.json");
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  async function session<T>(run: (call: (name: string, input?: JsonRecord) => Promise<JsonRecord>) => Promise<T>): Promise<T> {
    const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
    const client = new Client({ name: "catalog-contact-test", version: "1.0.0" });
    async function call(name: string, input: JsonRecord = {}): Promise<JsonRecord> {
      const body = record((await client.callTool({ name, arguments: input })).structuredContent);
      assert.equal(body.ok, true, JSON.stringify(body));
      return record(body.data);
    }
    try {
      await client.connect(transport);
      return await run(call);
    } finally {
      await client.close();
      await transport.close();
    }
  }
  async function inventory(directory = root, prefix = ""): Promise<Map<string, { sha256: string; byteLength: number }>> {
    const result = new Map<string, { sha256: string; byteLength: number }>();
    for (const entry of await readdir(directory, { withFileTypes: true })) {
      const path = join(directory, entry.name);
      const relative = `${prefix}${entry.name}`;
      if (entry.isDirectory()) {
        for (const [key, value] of await inventory(path, `${relative}/`)) result.set(key, value);
      } else if (entry.isFile()) {
        const bytes = await readFile(path);
        result.set(relative, { sha256: createHash("sha256").update(bytes).digest("hex"), byteLength: bytes.byteLength });
      }
    }
    return result;
  }
  try {
    await writeFile(file, JSON.stringify({ version: "v9", name: "Catalog contact", maps: [],
      tilesets: [{ id: "actors", name: "Actors", relativePath: "assets/actors.png" }],
      characters: [{ id: "hero", name: "Hero", tilesetId: "actors", contactShadow: false }],
      settings: { dimension: "threeD", actorContactShadowsByDefault: true }, pokemon: canonicalPokemonConfig() }));
    await session(async call => {
      const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
      const project = await call("pokemap_query", { projectHandle: opened.projectHandle,
        resourceKind: "project", operation: "get", ids: ["project"], view: "detail" });
      const planned = await call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
        requestId: "contact-partition", actionId: "project.catalog.partition", actionVersion: 1,
        workspaceHandle: opened.workspaceHandle, expectedRevision: project.snapshotRevision,
        idempotencyKey: "contact-partition", parameters: {},
      } });
      await call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle,
        planId: planned.planId, operationId: "contact-partition" });
      await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
    });
    const descriptor = await readFile(file);
    assert.equal(record(JSON.parse(descriptor.toString())).format, "avelune.working-catalog");
    let prior: boolean | null = false;
    let index = 0;
    await session(async call => {
      for (const enabled of [true, false, null]) {
        const current = await call("pokemap_character_contact_shadow_inspect", { projectRoot: root, characterId: "hero" });
        assert.equal(current.contactShadow, prior);
        const before = await inventory();
        const operationId = `catalog-contact-${++index}`;
        const input = { projectRoot: root, characterId: "hero", expectedRevision: current.revision, enabled, operationId };
        const changed = await call("pokemap_character_contact_shadow_set", input);
        assert.equal(changed.afterValue, enabled);
        assert.notEqual(changed.afterRevision, current.revision);
        assert.deepEqual(await readFile(file), descriptor);
        const after = await inventory();
        const written = [...after].filter(([key, value]) => before.get(key)?.sha256 !== value.sha256);
        assert.ok(written.length > 0);
        assert.ok(written.every(([key, value]) => (key.startsWith(".pokemap/") || key.startsWith("catalog/")) && value.byteLength < 64 * 1024), JSON.stringify(written));
        assert.ok(written.reduce((sum, [, value]) => sum + value.byteLength, 0) < 256 * 1024, JSON.stringify(written));
        for (const [key, value] of before) {
          if (key.startsWith("catalog/objects/")) assert.deepEqual(after.get(key), value);
        }
        const replayed = await call("pokemap_character_contact_shadow_set", input);
        assert.deepEqual(replayed.receipt, changed.receipt);
        const inspected = await call("pokemap_character_contact_shadow_inspect", { projectRoot: root, characterId: "hero" });
        assert.equal(inspected.contactShadow, enabled);
        prior = enabled;
      }
    });
    await session(async call => {
      const reopened = await call("pokemap_character_contact_shadow_inspect", { projectRoot: root, characterId: "hero" });
      assert.equal(reopened.contactShadow, null);
      assert.deepEqual(await readFile(file), descriptor);
    });
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import test from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";

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

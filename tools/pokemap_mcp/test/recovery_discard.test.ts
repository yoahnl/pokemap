import assert from "node:assert/strict";
import { test } from "node:test";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { Client } from "@modelcontextprotocol/client";
import { InMemoryTransport } from "@modelcontextprotocol/server";
import { LocalAuthoringClient, type AuthoringGateway, type JsonRecord } from "../src/authoring_client.js";
import { MemoryArtifactReader } from "../src/artifacts.js";
import { createPokeMapMcpServer } from "../src/server.js";
import { canonicalPokemonConfig } from "./pokemon_fixture.js";

test("MCP incomplete preparation discard is discoverable and bounded without a receipt", async () => {
  const calls: Array<{ command: string; args?: JsonRecord }> = [];
  const expected = { operationId: "incomplete-test", disposition: "discardedIncompletePreparation", committed: false, recoverable: false, finalized: true, projectDataChanged: false, intendedReceiptId: "intended-test" };
  const authoring: AuthoringGateway = {
    async request(command, args) {
      calls.push({ command, ...(args === undefined ? {} : { args }) });
      return { requestId: "discard-test", data: expected, artifacts: [] };
    },
    async close() {},
  };
  const server = createPokeMapMcpServer({ authoring, artifacts: new MemoryArtifactReader() });
  const [ct, st] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "recovery-discard-test", version: "1.0.0" });
  await server.connect(st);
  await client.connect(ct);
  try {
    const descriptor = (await client.listTools()).tools.find(tool => tool.name === "pokemap_recovery_discard");
    assert.ok(descriptor);
    assert.equal(descriptor.annotations?.readOnlyHint, false);
    assert.equal(descriptor.annotations?.idempotentHint, true);
    assert.equal(descriptor.annotations?.openWorldHint, false);
    const result = await client.callTool({ name: "pokemap_recovery_discard", arguments: { projectHandle: "project-test", operationId: "incomplete-test" } });
    assert.equal(result.isError, undefined);
    const envelope = result.structuredContent as JsonRecord;
    assert.deepEqual(envelope.data, expected);
    assert.equal((envelope.data as JsonRecord).receipt, undefined);
    assert.deepEqual(calls, [{ command: "discard_preparation", args: { projectHandle: "project-test", operationId: "incomplete-test" } }]);
    for (const args of [
      { projectHandle: "project-test", operationId: "incomplete-test", force: true },
      { projectHandle: "project-test", operationId: "" },
      { projectHandle: "", operationId: "incomplete-test" },
      { projectHandle: "project-test", operationId: "incomplete-test", sourcePath: "/tmp/private" },
    ]) {
      let rejected = false;
      try { rejected = (await client.callTool({ name: "pokemap_recovery_discard", arguments: args })).isError === true; }
      catch { rejected = true; }
      assert.equal(rejected, true);
      assert.equal(calls.length, 1);
    }
  } finally {
    await client.close();
    await server.close();
    await authoring.close();
  }
});

test("MCP discard reaches the live typed worker with an idempotent path-free result", { timeout: 90_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-discard-live-"));
  const manifest = JSON.stringify({ name: "Private discard fixture", version: "v8", maps: [], tilesets: [], pokemon: { ...canonicalPokemonConfig(), enabled: false } });
  await writeFile(join(root, "project.json"), manifest);
  const authoring = new LocalAuthoringClient({ allowedRoots: [root], authoringPackageRoot: resolve(process.cwd(), "../../packages/map_authoring"), requestTimeoutMs: 60_000, workerTimeoutMs: 30_000 });
  const server = createPokeMapMcpServer({ authoring, artifacts: new MemoryArtifactReader() });
  const [ct, st] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "recovery-discard-live-test", version: "1.0.0" });
  await server.connect(st);
  await client.connect(ct);
  async function data(name: string, args: JsonRecord): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: args });
    assert.equal(result.isError, undefined, JSON.stringify(result.structuredContent));
    return (result.structuredContent as JsonRecord).data as JsonRecord;
  }
  try {
    const catalog = await data("pokemap_describe", {});
    assert.ok((catalog.commands as JsonRecord[]).some(command => command.id === "discard_preparation"));
    const opened = await data("pokemap_workspace", { operation: "open", projectRoot: root });
    for (let attempt = 0; attempt < 2; attempt++) {
      const result = await data("pokemap_recovery_discard", { projectHandle: opened.projectHandle, operationId: "absent-fixture-operation" });
      assert.deepEqual(result, { operationId: "absent-fixture-operation", disposition: "alreadyAbsent", committed: false, recoverable: false, finalized: true, projectDataChanged: false });
      assert.ok(!JSON.stringify(result).includes(root));
      assert.equal(await readFile(join(root, "project.json"), "utf8"), manifest);
    }
    const denied = await client.callTool({ name: "pokemap_recovery_discard", arguments: { projectHandle: "foreign-project", operationId: "absent-fixture-operation" } });
    assert.equal(denied.isError, true);
    await data("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await server.close();
    await authoring.close();
    await rm(root, { recursive: true, force: true });
  }
});

import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { join, resolve } from "node:path";
import test from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { InMemoryTransport } from "@modelcontextprotocol/server";

import { LocalAuthoringClient, type AuthoringMutationNotification } from "../src/authoring_client.js";
import { MemoryArtifactReader } from "../src/artifacts.js";
import { createPokeMapMcpServer } from "../src/server.js";

function record(value: unknown): Record<string, unknown> {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as Record<string, unknown>;
}

test("MCP imports a bounded batch, preserves custom moves and reports changes", { timeout: 120_000 }, async () => {
  const qa = process.env.AVELUNE_QA_ROOT;
  assert.ok(qa);
  await mkdir(qa, { recursive: true });
  const root = await mkdtemp(join(qa, "battle-batch-mcp-"));
  const packageRoot = resolve("../../packages/map_authoring");
  const dart = process.env.POKEMAP_TEST_DART ?? execFileSync("which", ["dart"], { encoding: "utf8" }).trim();
  const config = join(packageRoot, ".dart_tool/package_config.json");
  const notifications: AuthoringMutationNotification[] = [];
  const authoring = new LocalAuthoringClient({
    allowedRoots: [root],
    onMutation: event => notifications.push(event),
    workerCommand: {
      executable: dart,
      args: [`--packages=${config}`, join(packageRoot, "test/support/battle_recipe_batch_worker.dart")],
      cwd: packageRoot,
    },
  });
  const server = createPokeMapMcpServer({ authoring, artifacts: new MemoryArtifactReader() });
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "battle-batch-test", version: "1" });
  async function call(name: string, args: Record<string, unknown> = {}) {
    const response = record((await client.callTool({ name, arguments: args })).structuredContent);
    assert.equal(response.ok, true, JSON.stringify(response));
    return record(response.data);
  }
  try {
    execFileSync(dart, [`--packages=${config}`, join(packageRoot, "test/support/create_working_catalog_fixture.dart"), root, "--companion"], { timeout: 60_000 });
    const moves = join(root, "data/pokemon/catalogs/moves.json");
    await mkdir(join(root, "data/pokemon/catalogs"), { recursive: true });
    await writeFile(moves, JSON.stringify({ schemaVersion: 1, catalog: "moves", entries: [
      { id: "tackle", source: "heartgold-fr-rom" },
      { id: "surf", source: "heartgold-fr-rom" },
      { id: "thunder", source: "project_custom" },
    ] }));
    const original = await readFile(moves);
    await server.connect(serverTransport);
    await client.connect(clientTransport);
    const description = await call("pokemap_describe");
    assert.ok((description.commands as Record<string, unknown>[]).some(entry => entry.id === "pokemon_move_recipe_batch"));
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const request = { projectHandle: opened.projectHandle, workspaceHandle: opened.workspaceHandle, operationId: "mcp-batch", limit: 1 };
    const first = await call("pokemap_move_recipe_batch", request);
    assert.deepEqual((first.results as Record<string, unknown>[]).map(entry => entry.status), ["imported"]);
    assert.equal(first.remaining, 2);
    const stale = await client.callTool({ name: "pokemap_move_recipe_batch", arguments: {
      ...request, operationId: "mcp-stale", startIndex: first.nextIndex,
      expectedInventoryRevision: `sha256:${"0".repeat(64)}`,
    } });
    assert.equal(record(stale.structuredContent).ok, false);
    assert.equal(record(record(stale.structuredContent).error).domainCode, "catalog.revision_conflict");
    assert.equal(notifications.length, 1);
    const second = await call("pokemap_move_recipe_batch", { ...request, operationId: "mcp-next", startIndex: first.nextIndex,
      expectedInventoryRevision: first.inventoryRevision, limit: 2 });
    assert.deepEqual((second.results as Record<string, unknown>[]).map(entry => entry.status), ["imported", "custom"]);
    assert.equal(second.remaining, 0);
    assert.equal(notifications.length, 2);
    assert.deepEqual(await readFile(moves), original);
    const retry = await call("pokemap_move_recipe_batch", { ...request, operationId: "mcp-retry", limit: 3 });
    assert.deepEqual((retry.results as Record<string, unknown>[]).map(entry => entry.status), ["alreadyPresent", "alreadyPresent", "custom"]);
    assert.equal(notifications.length, 2);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await server.close();
    await authoring.close();
    await rm(root, { recursive: true, force: true });
  }
});

import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";
import { canonicalPokemonConfig } from "./pokemon_fixture.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("live checkout catalog and planner no longer support map shadows", async () => {
  const root = await mkdtemp(join(tmpdir(), "map-visual-contract-"));
  const manifestPath = join(root, "project.json");
  const mapPath = join(root, "garden.json");
  await writeFile(manifestPath, JSON.stringify({
    version: "v8", name: "Jardin", pokemon: canonicalPokemonConfig(), tilesets: [], maps: [
      { id: "garden", name: "Jardin", relativePath: "garden.json" },
    ],
  }));
  await writeFile(mapPath, JSON.stringify({
    version: "v8", id: "garden", name: "Jardin",
    size: { width: 1, height: 1 }, layers: [],
  }));
  const beforeManifest = await readFile(manifestPath);
  const beforeMap = await readFile(mapPath);
  const transport = new StdioClientTransport({
    command: process.execPath,
    args: ["dist/src/index.js", "--root", root, "--dart", process.env.POKEMAP_TEST_DART ?? "dart"],
    cwd: process.cwd(), stderr: "pipe",
  });
  const client = new Client({ name: "map-visual-contract-test", version: "1.0.0" });
  async function data(name: string, args: JsonRecord): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: args });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, true, JSON.stringify(envelope));
    return record(envelope.data);
  }
  try {
    await client.connect(transport);
    const catalog = await data("pokemap_describe", {});
    for (const entry of [
      ...(catalog.resourceKinds as JsonRecord[]),
      ...(catalog.mutationActions as JsonRecord[]),
    ]) {
      assert.doesNotMatch(String(entry.id), /shadow/i);
    }
    const parity = record(catalog.fullParity);
    for (const entry of parity.mutationActions as JsonRecord[]) {
      assert.doesNotMatch(String(entry.actionId), /shadow/i);
    }
    const opened = await data("pokemap_workspace", { operation: "open", projectRoot: root });
    const validation = await data("pokemap_validate", { projectHandle: opened.projectHandle });
    for (const actionId of [
      "placed_element.set_shadow_override", "placed_element.clear_shadow_override",
      "element.set_shadow", "element.set_projected_shadow",
    ]) {
      const result = await client.callTool({
        name: "pokemap_plan", arguments: {
          projectHandle: opened.projectHandle,
          request: {
            requestId: actionId, actionId, actionVersion: 1,
            workspaceHandle: opened.workspaceHandle,
            expectedRevision: validation.snapshotRevision,
            idempotencyKey: actionId, dryRun: true,
            parameters: { mapId: "garden", instanceId: "removed-effect" },
          },
        },
      });
      const envelope = record(result.structuredContent);
      assert.equal(envelope.ok, false);
      assert.equal(record(envelope.error).domainCode, "map.action_unsupported");
      assert.equal(record(envelope.data).planId, undefined);
      assert.deepEqual(await readFile(manifestPath), beforeManifest);
      assert.deepEqual(await readFile(mapPath), beforeMap);
    }
    await data("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

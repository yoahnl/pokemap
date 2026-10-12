import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
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

test("packaged MCP simulates declared scene routes and records proposed effects without writes", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-scene-simulation-"));
  const manifestPath = join(root, "project.json");
  const original = JSON.stringify({ name: "Scene simulation", version: "v8", pokemon: canonicalPokemonConfig(), maps: [], tilesets: [], scenes: [{
    id: "gift", name: "Gift", graph: { startNodeId: "start", nodes: [
      { id: "start", kind: "start" },
      { id: "badge", kind: "condition", payload: { kind: "condition", conditionSource: { sourceKind: "badge", sourceId: "zephyr", operator: "isTrue" } } },
      { id: "gift", kind: "action", payload: { kind: "action", interactiveCommand: { kind: "giveItem", itemId: "tm23", quantity: 1 } } },
      { id: "end", kind: "end" },
    ], edges: [
      { id: "s", fromNodeId: "start", fromPortId: "completed", toNodeId: "badge", kind: "default" },
      { id: "yes", fromNodeId: "badge", fromPortId: "true", toNodeId: "gift", kind: "conditionTrue" },
      { id: "no", fromNodeId: "badge", fromPortId: "false", toNodeId: "end", kind: "conditionFalse" },
      { id: "received", fromNodeId: "gift", fromPortId: "received", toNodeId: "end", kind: "actionCompleted" },
      { id: "bagFull", fromNodeId: "gift", fromPortId: "bagFull", toNodeId: "end", kind: "actionCompleted" },
    ] },
  }] });
  await writeFile(manifestPath, original);
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const client = new Client({ name: "scene-simulation-test", version: "1.0.0" });
  async function call(name: string, parameters: JsonRecord, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: parameters });
    assert.equal(result.isError, failure ? true : undefined, JSON.stringify(result.structuredContent));
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, !failure);
    return record(failure ? envelope.error : envelope.data);
  }
  try {
    await client.connect(new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" }));
    const described = await call("pokemap_describe", {});
    assert.ok(JSON.stringify(described).includes("scene.simulate"));
    const workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    async function simulate(parameters: JsonRecord, failure = false): Promise<JsonRecord> {
      const page = await call("pokemap_query", { projectHandle: workspace.projectHandle, resourceKind: "scene", operation: "get", ids: ["gift"],
        extensions: { actionId: "scene.simulate", parameters } }, failure);
      assert.equal(await readFile(manifestPath, "utf8"), original);
      return failure ? page : record((page.items as JsonRecord[])[0]);
    }
    for (const port of ["received", "bagFull"]) {
      const result = await simulate({ portsByNodeId: { badge: "true", gift: port } });
      assert.equal(result.status, "completed");
      assert.equal(result.proofKind, "simulation");
      assert.equal(result.mountedPlayer, false);
      assert.equal(result.effects, "proposedOnly");
      assert.deepEqual(result.outcomesByNodeId, { badge: "true", gift: port });
    }
    const missing = await simulate({ portsByNodeId: { badge: "true" } });
    assert.equal(missing.status, "failed");
    assert.equal(missing.errorCode, "missingInput");
    assert.equal(missing.missingInputNodeId, "gift");
    const invalid = await simulate({ portsByNodeId: { badge: "victory" } }, true);
    assert.equal(invalid.domainCode, "scene.simulation_invalid");
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

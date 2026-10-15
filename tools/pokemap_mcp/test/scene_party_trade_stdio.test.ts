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

test("live MCP authors a native party trade Scene and rejects 3D", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "scene-party-trade-mcp-"));
  const command = { kind: "openPartyTrade" };
  const scene = { id: "party-trade", name: "Party trade", graph: {
    startNodeId: "start", nodes: [
      { id: "start", kind: "start" },
      { id: "map", kind: "action", payload: { interactiveCommand: command } },
      { id: "end", kind: "end" },
    ], edges: [
      { id: "start", fromNodeId: "start", fromPortId: "completed", toNodeId: "map", kind: "default" },
      ...["completed", "cancelled"].map(port => ({ id: port, fromNodeId: "map", fromPortId: port, toNodeId: "end", kind: "actionCompleted" })),
    ],
  } };
  for (const spatial of [false, true]) {
    const path = join(root, spatial ? "spatial" : "two-d");
    await mkdir(path);
    await writeFile(join(path, "project.json"), JSON.stringify({
      name: "Party trade transport", version: spatial ? "v9" : "v8",
      settings: { dimension: spatial ? "threeD" : "twoD" },
      pokemon: canonicalPokemonConfig(), maps: [], tilesets: [], scenes: [],
      regionalMap: { schemaVersion: 1, regions: [{ id: "kanto", label: "Kanto" }], pointsOfInterest: [] },
    }));
  }
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const client = new Client({ name: "party-trade-scene-test", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  async function call(name: string, input: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: input });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify(envelope));
    return record(envelope[failure ? "error" : "data"]);
  }
  try {
    await client.connect(transport);
    const description = await call("pokemap_describe");
    for (const id of ["scene.upsert", "scene.graph.patch", "scene.interactive_command.set"]) {
      const action = (description.mutationActions as JsonRecord[]).find(entry => entry.id === id);
      assert.ok(action);
      assert.deepEqual(record(record(action.extensions).openPartyTrade), {
        projectDimension: "twoD", parameters: [], selection: "individualIdentity",
        teamOrder: "preserved", partner: "unchanged", evolution: "firstPokemonNativeTradeRules",
        cancellation: "noMutation", commit: "onceAfterConfirmation",
        completion: "closed", persistent: true, outputPorts: ["completed", "cancelled"],
      });
    }
    const held = (description.mutationActions as JsonRecord[]).find(entry => entry.id === "item.set_held_effect");
    assert.ok(held);
    assert.deepEqual(record(held.extensions).heldEffectIds, ["leftovers", "prevent_evolution"]);
    assert.deepEqual(record(record(held.extensions).nativePassiveEffects).prevent_evolution,
      { evolution: "prevented", battle: "neutral", consumed: false });
    for (const spatial of [false, true]) {
      const projectRoot = join(root, spatial ? "spatial" : "two-d");
      const file = join(projectRoot, "project.json");
      const workspace = await call("pokemap_workspace", { operation: "open", projectRoot });
      const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
      const before = await readFile(file);
      const planned = await call("pokemap_plan", {
        projectHandle: workspace.projectHandle, request: {
          requestId: `map-${spatial}`, actionId: "scene.upsert", actionVersion: 1,
          workspaceHandle: workspace.workspaceHandle, expectedRevision: validation.snapshotRevision,
          idempotencyKey: `map-${spatial}`, parameters: { scene },
        },
      }, spatial);
      assert.deepEqual(await readFile(file), before);
      if (spatial) {
        assert.ok(JSON.stringify(planned).includes("commandUnsupportedDimension"));
      } else {
        await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle,
          planId: planned.planId, operationId: "apply-map" });
        const queried = await call("pokemap_query", { projectHandle: workspace.projectHandle,
          resourceKind: "scene", operation: "get", ids: ["party-trade"], view: "detail" });
        assert.ok(JSON.stringify(queried).includes('"openPartyTrade"'));
      }
      await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
      if (!spatial) {
        const reopened = await call("pokemap_workspace", { operation: "open", projectRoot });
        const cold = await call("pokemap_query", { projectHandle: reopened.projectHandle,
          resourceKind: "scene", operation: "get", ids: ["party-trade"], view: "detail" });
        assert.ok(JSON.stringify(cold).includes('"openPartyTrade"'));
        const manifest = record(JSON.parse(await readFile(file, "utf8")));
        const stored = record((manifest.scenes as JsonRecord[])[0]);
        const graph = record(stored.graph);
        const action = (graph.nodes as JsonRecord[]).find(node => node.id === "map");
        assert.deepEqual(record(action!.payload).interactiveCommand, command);
        await call("pokemap_workspace", { operation: "close", workspaceHandle: reopened.workspaceHandle });
      }
    }
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

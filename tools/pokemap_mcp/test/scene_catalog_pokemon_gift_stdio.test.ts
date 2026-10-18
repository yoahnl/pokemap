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

const gift = (level: number): JsonRecord => ({
  kind: "givePokemonFromCatalog", speciesId: "sproutle", formId: "sunny", level,
});

const giftNode = (consequence: JsonRecord): JsonRecord => ({
  id: "gift", kind: "action", title: "Compagnon", payload: { consequence },
});

test("MCP discovers, authors and cold reopens catalog Pokemon gifts in 2D and 3D", { timeout: 180_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "catalog-pokemon-gift-mcp-"));
  const scene = {
    id: "catalog-gift", name: "Compagnon", metadata: { preserved: "yes" },
    layout: { nodeLayouts: [{ nodeId: "gift", x: 21, y: 34 }], edgeLayouts: [] },
    graph: {
      startNodeId: "start", nodes: [
        { id: "start", kind: "start" }, giftNode(gift(5)), { id: "end", kind: "end" },
      ], edges: [
        { id: "enter", fromNodeId: "start", fromPortId: "completed", toNodeId: "gift", kind: "default" },
        { id: "leave", fromNodeId: "gift", fromPortId: "completed", toNodeId: "end", kind: "actionCompleted" },
      ],
    },
  };
  for (const dimension of ["twoD", "threeD"]) {
    const directory = join(root, dimension);
    await mkdir(directory);
    await writeFile(join(directory, "project.json"), JSON.stringify({
      name: "Catalog gift transport", version: dimension === "twoD" ? "v8" : "v9",
      settings: { dimension }, pokemon: canonicalPokemonConfig(), maps: [], tilesets: [], scenes: [],
    }));
  }
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const client = new Client({ name: "catalog-pokemon-gift-test", version: "1.0.0" });
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
    for (const id of ["scene.upsert", "scene.graph.patch"]) {
      const action = (description.mutationActions as JsonRecord[]).find(entry => entry.id === id);
      assert.ok(action);
      assert.deepEqual(record(action.extensions).givePokemonFromCatalog, {
        consequenceKind: "givePokemonFromCatalog", parameters: ["speciesId", "formId", "level"],
        levelRange: [1, 100], catalog: "activeProjectPokemonCatalog", generation: "activeNativeRuleset",
        initialHealth: "fullHpAndPp", moves: "nativeLevelLearnset", destination: "partyThenStorage",
        storageFull: "atomicRefusalWithoutConsumingOperation", pokedex: "seenAndCaughtOnSuccessfulGrant",
        idempotency: "saveIdAndSceneGrantOperationId",
      });
    }
    let sequence = 0;
    for (const dimension of ["twoD", "threeD"]) {
      const directory = join(root, dimension);
      const file = join(directory, "project.json");
      const workspace = await call("pokemap_workspace", { operation: "open", projectRoot: directory });
      async function plan(actionId: string, parameters: JsonRecord, failure = false): Promise<JsonRecord> {
        const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
        const before = await readFile(file);
        const key = `catalog-gift-${++sequence}`;
        const result = await call("pokemap_plan", {
          projectHandle: workspace.projectHandle, request: {
            requestId: key, actionId, actionVersion: 1, workspaceHandle: workspace.workspaceHandle,
            expectedRevision: validation.snapshotRevision, idempotencyKey: key, parameters,
          },
        }, failure);
        assert.deepEqual(await readFile(file), before);
        return result;
      }
      for (const [actionId, parameters] of [
        ["scene.upsert", { scene }],
        ["scene.graph.patch", { sceneId: "catalog-gift", upsertNodes: [giftNode(gift(8))] }],
      ] as [string, JsonRecord][]) {
        const planned = await plan(actionId, parameters);
        const applied = await call("pokemap_apply", {
          operation: "apply", projectHandle: workspace.projectHandle, planId: planned.planId,
          operationId: `catalog-gift-apply-${sequence}`,
        });
        assert.equal(record(applied.receipt).status, "applied");
      }
      const beforeInvalid = await readFile(file);
      for (const invalid of [gift(0), { ...gift(8), currentHp: 8 }, { ...gift(8), abilityId: "unknown" }]) {
        const error = await plan("scene.graph.patch", {
          sceneId: "catalog-gift", upsertNodes: [giftNode(invalid)],
        }, true);
        assert.equal(error.domainCode, "scene.graph.invalid_patch");
        assert.deepEqual(await readFile(file), beforeInvalid);
      }
      await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
      const reopened = await call("pokemap_workspace", { operation: "open", projectRoot: directory });
      const queried = await call("pokemap_query", {
        projectHandle: reopened.projectHandle, resourceKind: "scene", operation: "get",
        ids: ["catalog-gift"], view: "detail",
      });
      assert.ok(JSON.stringify(queried).includes('"givePokemonFromCatalog"'));
      const manifest = record(JSON.parse(await readFile(file, "utf8")));
      const stored = record((manifest.scenes as JsonRecord[])[0]);
      assert.deepEqual(stored.metadata, scene.metadata);
      assert.deepEqual(stored.layout, scene.layout);
      const node = (record(stored.graph).nodes as JsonRecord[]).find(entry => entry.id === "gift");
      assert.deepEqual(record(node!.payload).consequence, gift(8));
      await call("pokemap_workspace", { operation: "close", workspaceHandle: reopened.workspaceHandle });
    }
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

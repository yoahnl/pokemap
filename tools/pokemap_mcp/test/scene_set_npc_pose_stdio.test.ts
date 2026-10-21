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

const gift = (level: number): JsonRecord => ({ kind: "setNpcPose", mapId: "lab", entityId: "rival", x: level === 5 ? 14 : 5, y: 4 });

const giftNode = (consequence: JsonRecord): JsonRecord => ({
  id: "gift", kind: "action", title: "Compagnon", payload: { consequence },
});

test("MCP discovers, authors and cold reopens native hidden actor pose commands", { timeout: 180_000 }, async () => {
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
  for (const dimension of ["twoD"]) {
    const directory = join(root, dimension);
    await mkdir(directory);
    await mkdir(join(directory, "data"));
    await mkdir(join(directory, "maps"));
    await writeFile(join(directory, "maps/lab.json"), JSON.stringify({id: "lab", name: "Laboratoire", version: "v8", size: {width: 20, height: 12}, layers: [], entities: [
      {id: "rival", kind: "custom", pos: {x: 7, y: 6}, size: {width: 1, height: 1}, blocksMovement: false,
        presentation: {schemaVersion: 1, variants: [
          {id: "hidden", characterId: null, condition: {kind: "all", children: []}, size: {width: 1, height: 1}, blocksMovement: false, facing: "south", interactionMode: "front", counterInteractionSides: []},
          {id: "visible", condition: {kind: "leaf", condition: {kind: "fact", factId: "visible", expectedValue: true}}, characterId: "rival-sprite", size: {width: 1, height: 1}, blocksMovement: true, facing: "south", interactionMode: "front", counterInteractionSides: []},
        ]}}
    ]}));
    await writeFile(join(directory, "data/moves.json"), JSON.stringify({ schemaVersion: 1, kind: "catalog", catalog: "moves", entries: [{ id: "tackle" }, { id: "exceptional" }] }));
    await writeFile(join(directory, "project.json"), JSON.stringify({
      name: "Catalog gift transport", version: dimension === "twoD" ? "v8" : "v9",
      settings: { dimension }, pokemon: { ...canonicalPokemonConfig(), enabled: true, catalogFiles: { moves: "data/moves.json" } }, maps: [{id: "lab", name: "Laboratoire", relativePath: "maps/lab.json"}], tilesets: [], scenes: [],
      characters: [{id: "rival-sprite", name: "Rival", tilesetId: "actors"}],
      facts: [{id: "visible", label: "Visible", valueType: "bool", defaultValue: false}],
    }));
  }
  const args = [resolve(process.env.POKEMAP_TEST_MCP_ENTRY ?? "dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
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
      assert.equal(record(record(action.extensions).setNpcPose).target, "validatedNpcPresentationOwner");
    }
    let sequence = 0;
    for (const dimension of ["twoD"]) {
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
        ["scene.graph.patch", { sceneId: "catalog-gift", upsertNodes: [giftNode({kind: "setNpcPose", mapId: "lab", entityId: "rival", facing: "east"})] }],
      ] as [string, JsonRecord][]) {
        const planned = await plan(actionId, parameters);
        const applied = await call("pokemap_apply", {
          operation: "apply", projectHandle: workspace.projectHandle, planId: planned.planId,
          operationId: `catalog-gift-apply-${sequence}`,
        });
        assert.equal(record(applied.receipt).status, "applied");
        if (actionId === "scene.upsert") {
          const savedProject = record(JSON.parse(await readFile(file, "utf8")));
          const savedScene = record((savedProject.scenes as JsonRecord[])[0]);
          const savedNode = (record(savedScene.graph).nodes as JsonRecord[]).find(entry => entry.id === "gift");
          assert.equal(record(record(savedNode!.payload).consequence).moveIds, undefined);
        }
      }
      const beforeInvalid = await readFile(file);
      for (const invalid of [{kind: "setNpcPose", mapId: "lab", entityId: "rival", x: 1, facing: "east"}, {kind: "setNpcPose", mapId: "lab", entityId: "rival", facing: null}, { kind: "setNpcPose" }, { kind: "setNpcPose", mapId: "lab", entityId: " ", x: 1, y: 1 }, { kind: "setNpcPose", mapId: "lab", entityId: "rival", x: -1, y: 1 }]) {
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
      assert.ok(JSON.stringify(queried).includes('"setNpcPose"'));
      const manifest = record(JSON.parse(await readFile(file, "utf8")));
      const stored = record((manifest.scenes as JsonRecord[])[0]);
      assert.deepEqual(stored.metadata, scene.metadata);
      assert.deepEqual(stored.layout, scene.layout);
      const node = (record(stored.graph).nodes as JsonRecord[]).find(entry => entry.id === "gift");
      assert.deepEqual(record(node!.payload).consequence, {kind: "setNpcPose", mapId: "lab", entityId: "rival", facing: "east"});
      await call("pokemap_workspace", { operation: "close", workspaceHandle: reopened.workspaceHandle });
    }
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

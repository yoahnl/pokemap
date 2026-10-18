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

const avatarNode = (characterId: unknown, extra: JsonRecord = {}): JsonRecord => ({
  id: "avatar", kind: "action", title: "Tenue", payload: {
    consequence: { kind: "setPlayerAvatar", characterId, ...extra },
  },
});

test("L15 MCP discovers, changes and restores persistent avatars in 2D and 3D", { timeout: 180_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "l15-avatar-mcp-"));
  const character = (id: string, overrides: JsonRecord = {}): JsonRecord => ({
    id, name: id, tilesetId: "actors", frameWidth: 1, frameHeight: 2,
    animations: ["north", "south", "east", "west"].map(direction => ({
      state: "walk", direction, frames: [{ source: { x: 0, y: 0, width: 1, height: 2 }, durationMs: 150 }],
    })), ...overrides,
  });
  const scene = {
    id: "costume", name: "Changer de tenue", metadata: { preserved: "yes" },
    layout: { nodeLayouts: [{ nodeId: "avatar", x: 20, y: 30 }], edgeLayouts: [] },
    graph: {
      startNodeId: "start", nodes: [
        { id: "start", kind: "start" }, avatarNode("original"), { id: "end", kind: "end" },
      ], edges: [
        { id: "enter", fromNodeId: "start", fromPortId: "completed", toNodeId: "avatar", kind: "default" },
        { id: "leave", fromNodeId: "avatar", fromPortId: "completed", toNodeId: "end", kind: "actionCompleted" },
      ],
    },
  };
  for (const dimension of ["twoD", "threeD"]) {
    const directory = join(root, dimension);
    await mkdir(directory);
    await writeFile(join(directory, "project.json"), JSON.stringify({
      name: "Avatar transport", version: dimension === "twoD" ? "v8" : "v9",
      settings: { dimension }, pokemon: canonicalPokemonConfig(), maps: [], scenes: [],
      tilesets: [{ id: "actors", name: "Acteurs", relativePath: "actors.json" }],
      characters: [character("original"), character("uniform"), character("duplicate"), character("duplicate"),
        character("invalid", { frameWidth: 0 }), character("no-animations", { animations: [] })],
    }));
  }
  const args = [resolve(process.env.POKEMAP_TEST_MCP_ENTRY ?? "dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  if (process.env.POKEMAP_TEST_AUTHORING_PACKAGE) args.push("--authoring-package", process.env.POKEMAP_TEST_AUTHORING_PACKAGE);
  const client = new Client({ name: "l15-avatar-test", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  async function call(name: string, input: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const envelope = record((await client.callTool({ name, arguments: input })).structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify(envelope));
    return record(envelope[failure ? "error" : "data"]);
  }
  try {
    await client.connect(transport);
    const description = await call("pokemap_describe");
    for (const id of ["scene.upsert", "scene.graph.patch"]) {
      const action = (description.mutationActions as JsonRecord[]).find(entry => entry.id === id);
      assert.ok(action);
      const contract = record(record(action.extensions).setPlayerAvatar);
      assert.equal(contract.consequenceKind, "setPlayerAvatar");
      assert.deepEqual(contract.parameters, ["characterId"]);
      assert.deepEqual(contract.projectDimensions, ["twoD", "threeD"]);
      assert.equal(contract.persistentField, "trainerProfile.avatarCharacterId");
      assert.equal(contract.collisionEffect, "none");
      assert.equal(contract.restoration, "explicitCharacterSelection");
    }
    let sequence = 0;
    for (const dimension of ["twoD", "threeD"]) {
      const directory = join(root, dimension);
      const file = join(directory, "project.json");
      const workspace = await call("pokemap_workspace", { operation: "open", projectRoot: directory });
      async function plan(actionId: string, parameters: JsonRecord, failure = false, inspect = false): Promise<JsonRecord> {
        const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
        const before = await readFile(file);
        const key = `avatar-${++sequence}`;
        const result = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
          requestId: key, actionId, actionVersion: 1, workspaceHandle: workspace.workspaceHandle,
            expectedRevision: validation.snapshotRevision, idempotencyKey: key, parameters, dryRun: inspect,
        } }, failure);
        assert.deepEqual(await readFile(file), before);
        return result;
      }
      for (const [actionId, parameters] of [
        ["scene.upsert", { scene }],
        ["scene.graph.patch", { sceneId: "costume", upsertNodes: [avatarNode("uniform")] }],
        ["scene.graph.patch", { sceneId: "costume", upsertNodes: [avatarNode("original")] }],
      ] as [string, JsonRecord][]) {
        const planned = await plan(actionId, parameters);
        await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle,
          planId: planned.planId, operationId: `avatar-apply-${sequence}` });
      }
      const saved = await readFile(file);
      const deletion = await plan("characterStudio.character.deletePlan", { characterId: "original" }, false, true);
      assert.ok(JSON.stringify(deletion).includes("scene_player_avatar_character_required"));
      for (const resolution of ["clear", "replace", "cancel"]) {
        const error = await plan("characterStudio.character.delete", { characterId: "original", resolution,
          ...(resolution === "replace" ? { replacementId: "uniform" } : {}) }, true);
        assert.equal(error.domainCode, `character_studio.character.${resolution === "clear" ? "clear_incompatible" : resolution === "replace" ? "replacement_incompatible" : "delete_cancelled"}`);
        assert.deepEqual(await readFile(file), saved);
      }
      for (const node of [avatarNode("missing"), avatarNode("duplicate"), avatarNode("invalid"),
        avatarNode("no-animations"), avatarNode(null), avatarNode("uniform", { collisionWidth: 5 })]) {
        for (const action of ["scene.upsert", "scene.graph.patch"]) {
          const invalidScene = { ...scene, graph: { ...scene.graph, nodes: scene.graph.nodes.map(entry => entry.id === "avatar" ? node : entry) } };
          const error = await plan(action, action === "scene.upsert" ? { scene: invalidScene }
            : { sceneId: "costume", upsertNodes: [node] }, true);
          assert.ok(error.domainCode);
          assert.deepEqual(await readFile(file), saved);
        }
      }
      await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
      const reopened = await call("pokemap_workspace", { operation: "open", projectRoot: directory });
      const queried = await call("pokemap_query", { projectHandle: reopened.projectHandle, resourceKind: "scene",
        operation: "get", ids: ["costume"], view: "detail" });
      assert.ok(JSON.stringify(queried).includes('"setPlayerAvatar"'));
      const manifest = record(JSON.parse(await readFile(file, "utf8")));
      const stored = record((manifest.scenes as JsonRecord[])[0]);
      assert.deepEqual(stored.layout, scene.layout);
      assert.deepEqual(stored.metadata, scene.metadata);
      const avatar = (record(stored.graph).nodes as JsonRecord[]).find(entry => entry.id === "avatar")!;
      assert.deepEqual(record(avatar.payload).consequence, { kind: "setPlayerAvatar", characterId: "original" });
      await call("pokemap_workspace", { operation: "close", workspaceHandle: reopened.workspaceHandle });
    }
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

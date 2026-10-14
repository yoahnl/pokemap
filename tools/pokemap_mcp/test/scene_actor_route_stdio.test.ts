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

function preserveExplicitFields(actual: unknown, expected: unknown): void {
  if (Array.isArray(expected)) {
    assert.ok(Array.isArray(actual));
    assert.equal(actual.length, expected.length);
    expected.forEach((value, index) => preserveExplicitFields(actual[index], value));
  } else if (expected && typeof expected === "object") {
    const object = record(actual);
    for (const [key, value] of Object.entries(expected)) preserveExplicitFields(object[key], value);
  } else {
    assert.deepEqual(actual, expected);
  }
}

function scene(id: string, command: JsonRecord): JsonRecord {
  return { id, name: id, metadata: { keep: "metadata" }, graph: {
    startNodeId: "start", nodes: [
      { id: "start", kind: "start" },
      { id: "action", kind: "action", title: "Keep title", payload: {
        actionKind: "keep-action", parameters: { keep: "parameter" }, interactiveCommand: command } },
      { id: "end", kind: "end" },
    ], edges: [
      { id: "start", fromNodeId: "start", fromPortId: "completed", toNodeId: "action", kind: "default" },
      ...["completed", "blocked"].map((port) => ({ id: port, fromNodeId: "action", fromPortId: port, toNodeId: "end", kind: "actionCompleted" })),
    ],
  } };
}

function target(mapId = "map", entityId?: string): JsonRecord {
  return { kind: entityId ? "entity" : "player", mapId, ...(entityId ? { entityId } : {}) };
}
function route(actor = target("map", "actor"), mediaAssetId = "door", initialCollisionOwnerEntityId?: string): JsonRecord {
  return { kind: "actorRoute", target: actor, steps: [
    { kind: "face", direction: "south", durationMs: 50 },
    { kind: "move", direction: "south", durationMs: 200, ...(initialCollisionOwnerEntityId === undefined ? {} : { initialCollisionOwnerEntityId }) },
    { kind: "wait", durationMs: 50 },
    { kind: "through", enabled: true },
    { kind: "sound", mediaAssetId, gain: 0.8 },
  ], skippable: false };
}
function visibility(actor = target("map", "actor")): JsonRecord {
  return { kind: "actorVisibility", target: actor, visible: false };
}

test("live MCP authors typed actor routes and visibility with strict references before writes", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "scene-actor-route-mcp-"));
  const file = join(root, "project.json");
  const mapFile = join(root, "maps/map.json");
  const initialCommand = { kind: "warp", destinationMapId: "map", warpId: "arrival" };
  const draft = scene("unrelated-draft", { kind: "playSoundEffect", mediaAssetId: "missing", volume: 0.8 });
  await mkdir(join(root, "maps"));
  await mkdir(join(root, "audio"));
  await mkdir(join(root, "assets"));
  await writeFile(join(root, "assets", "actor.png"), Buffer.from("iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAL0lEQVR4nO3OIQEAAAgDMKIShSg0hRg3E/Ornr2kEhAQEBAQEBAQEBAQEBAQSAcejaD8iD3577EAAAAASUVORK5CYII=", "base64"));
  const wav = Buffer.alloc(46);
  wav.write("RIFF", 0); wav.writeUInt32LE(38, 4); wav.write("WAVEfmt ", 8);
  wav.writeUInt32LE(16, 16); wav.writeUInt16LE(1, 20); wav.writeUInt16LE(1, 22);
  wav.writeUInt32LE(8000, 24); wav.writeUInt32LE(16000, 28);
  wav.writeUInt16LE(2, 32); wav.writeUInt16LE(16, 34);
  wav.write("data", 36); wav.writeUInt32LE(2, 40);
  for (const id of ["door", "music", "fx", "loop", "ambiguous", "ambiguous"]) await writeFile(join(root, "audio", `${id}.wav`), wav);
  await writeFile(file, JSON.stringify({ name: "QA native presentation transport", version: "v8", pokemon: canonicalPokemonConfig(),
    maps: [{ id: "map", name: "Map", relativePath: "maps/map.json" }],
    tilesets: [{ id: "actor-sheet", name: "Original QA sheet", relativePath: "assets/actor.png" }],
    characters: ["actor-character", "duplicate-character", "duplicate-character"].map((id) => ({ id, name: id, tilesetId: "actor-sheet", frameHeight: 1,
      animations: ["north", "south", "east", "west"].map((direction) => ({ state: "idle", direction, frames: [{ source: { x: 0, y: 0, width: 1, height: 1 } }] })) })),
    trainers: [
      { id: "actor-trainer", characterId: "actor-character" },
      { id: "duplicate-trainer", characterId: "actor-character" },
      { id: "duplicate-trainer", characterId: "actor-character" },
      { id: "unknown-character-trainer", characterId: "missing" },
    ].map((value) => ({ ...value, name: value.id, trainerClass: "Original QA" })),
    scenes: [scene("edit", initialCommand), draft],
    cinematicMediaAssets: ["door", "music", "fx", "loop", "ambiguous", "ambiguous"].map((id) => ({ id, label: id, kind: id === "music" ? "music" : id === "fx" ? "cinematicFx" : "sound", relativePath: `audio/${id}.wav`, loopByDefault: id === "loop" })),
  }));
  await writeFile(mapFile, JSON.stringify({ version: "v8", id: "map", name: "Map", size: { width: 4, height: 4 }, layers: [],
    entities: [
      { id: "actor", kind: "npc", npc: { characterId: "actor-character" } },
      { id: "trainer-actor", kind: "npc", npc: { trainerId: " actor-trainer " } },
      { id: "sign", kind: "sign" }, { id: "custom", kind: "custom" },
      { id: "missing-payload", kind: "npc" }, { id: "empty-payload", kind: "npc", npc: {} },
      { id: "unknown-character", kind: "npc", npc: { characterId: "missing" } },
      { id: "ambiguous-character", kind: "npc", npc: { characterId: "duplicate-character" } },
      { id: "unknown-trainer", kind: "npc", npc: { trainerId: "missing" } },
      { id: "ambiguous-trainer", kind: "npc", npc: { trainerId: "duplicate-trainer" } },
      { id: "trainer-character-missing", kind: "npc", npc: { trainerId: "unknown-character-trainer" } },
      { id: "invalid-direct", kind: "npc", npc: { characterId: "missing", trainerId: "actor-trainer" } },
      { id: "wide-owner", kind: "npc", size: { width: 2, height: 1 }, npc: { characterId: "actor-character" } },
      { id: "tall-owner", kind: "npc", size: { width: 1, height: 2 }, npc: { characterId: "actor-character" } },
      { id: "shifted-owner", kind: "npc", size: { width: 2, height: 1 }, properties: { "collision.width": "1", "collision.offsetX": "1" }, npc: { characterId: "actor-character" } },
      { id: "anchored-tall", kind: "npc", size: { width: 1, height: 2 }, properties: { "collision.height": "1", "collision.offsetY": "0" }, npc: { characterId: "actor-character" } },
      { id: "duplicate-owner", kind: "npc", npc: { characterId: "actor-character" } },
      { id: "duplicate-owner", kind: "sign" },
    ].map((value) => ({ ...value, pos: { x: 0, y: 0 } })),
    warps: [{ id: "arrival", pos: { x: 1, y: 1 }, targetMapId: "map", targetPos: { x: 1, y: 1 }, triggerMode: "on_bump" }] }));
  await writeFile(join(root, "maps", "spatial.json"), JSON.stringify({ version: "v9", id: "spatial", name: "Spatial", size: { width: 4, height: 4 }, layers: [],
    entities: [{ id: "actor", kind: "npc", pos: { x: 0, y: 0 }, npc: { characterId: "actor-character" } }],
    spatialScene: { schemaVersion: 1, width: 4, depth: 4, heightLevels: Array(16).fill(0), levelHeight: 1, instances: [],
      camera: { mode: "fixed", pitchDegrees: 48.7, yawDegrees: 0, fieldOfViewDegrees: 16.2, distance: 42 } } }));
  const mapBefore = await readFile(mapFile);
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const client = new Client({ name: "native-actor-route-transport", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  let workspace: JsonRecord | undefined;
  async function call(name: string, input: JsonRecord, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: input });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify({ tool: name, input, envelope }));
    return record(envelope[failure ? "error" : "data"]);
  }
  try {
    await client.connect(transport);
    const description = await call("pokemap_describe", {});
    const action = (description.mutationActions as JsonRecord[]).find((value) => value.id === "scene.interactive_command.set");
    assert.ok(action);
    const extension = record(action.extensions);
    assert.equal(record(extension.actorRoute).targetReference, "uniqueActorOnExactMap");
    for (const contract of [record(extension.actorRoute), record(extension.actorVisibility)]) {
      assert.equal(contract.targetMapMode, "2D");
      assert.equal(contract.entityKind, "npc");
      assert.equal(contract.entityCharacterReference, "knownUniqueDirectOrTrainerCharacter");
    }
    assert.deepEqual(record(extension.actorRoute).stepKinds, ["face", "move", "wait", "through", "sound"]);
    assert.equal(record(extension.actorRoute).dynamicCollisionValidation, "runtime");
    for (const id of ["scene.interactive_command.set", "scene.upsert", "scene.graph.patch"]) {
      const descriptor = (description.mutationActions as JsonRecord[]).find((value) => value.id === id);
      assert.ok(descriptor);
      const contract = record(record(descriptor.extensions).actorRoute);
      assert.deepEqual(record(contract.stepFields).move, ["kind", "direction", "durationMs", "initialCollisionOwnerEntityId"]);
      assert.deepEqual(record(contract.stepOptionalFields).move, ["initialCollisionOwnerEntityId"]);
      const owner = record(contract.initialCollisionOwner);
      assert.equal(owner.status, "partial");
      assert.equal(owner.targetKind, "player");
      assert.equal(owner.effectiveThrough, false);
      assert.equal(owner.reference, "knownUniqueNPCCharacterOnExactTargetMap");
      assert.deepEqual(owner.collisionFootprintSize, [1, 1]);
      assert.equal(owner.collisionFootprintAnchor, "sameAsEntityAnchor");
      assert.equal(owner.collisionExemption, "initialOwnerOverlapOnly");
      assert.equal(owner.absent, "ordinaryCollisionValidation");
      assert.equal(owner.explicitNull, "rejected");
      assert.equal(owner.identity, "canonicalNonempty");
    }
    assert.equal(record(extension.actorVisibility).collisionEffect, "none");
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    let sequence = 0;
    async function plan(command: JsonRecord, failure = false, actionId = "scene.interactive_command.set"): Promise<JsonRecord> {
      assert.ok(workspace);
      const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
      const before = await readFile(file);
      const id = `presentation-${++sequence}`;
      const draftScene = scene("edit", command);
      const parameters = actionId === "scene.upsert" ? { scene: draftScene }
        : actionId === "scene.graph.patch" ? { sceneId: "edit", upsertNodes: [(record(draftScene.graph).nodes as JsonRecord[])[1]] }
        : { sceneId: "edit", nodeId: "action", command };
      const result = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
        requestId: id, actionId, actionVersion: 1,
        workspaceHandle: workspace.workspaceHandle, expectedRevision: validation.snapshotRevision,
        idempotencyKey: id, dryRun: false, parameters,
      } }, failure);
      assert.deepEqual(await readFile(file), before);
      assert.deepEqual(await readFile(mapFile), mapBefore);
      return result;
    }
    const commands = [route(), route(target()), route(target("map", "trainer-actor")), visibility(),
      route(target(), "door", "actor"), route(target(), "door", "anchored-tall"), route(target(), "door", "trainer-actor")];
    const mutations = [...commands.map((command) => ({ command, actionId: "scene.interactive_command.set" })),
      ...["scene.upsert", "scene.graph.patch"].map((actionId) => ({ command: route(target(), "door", actionId === "scene.upsert" ? "actor" : "trainer-actor"), actionId }))];
    for (const { command, actionId } of mutations) {
      const planned = await plan(command, false, actionId);
      await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle, planId: planned.planId, operationId: `apply-${sequence}` });
      const saved = record(JSON.parse((await readFile(file)).toString("utf8")));
      const scenes = saved.scenes as JsonRecord[];
      preserveExplicitFields(scenes.find((value) => value.id === "unrelated-draft"), draft);
      const edited = scenes.find((value) => value.id === "edit")!;
      const node = (record(edited.graph).nodes as JsonRecord[]).find((value) => value.id === "action")!;
      const payload = record(node.payload);
      assert.deepEqual(payload.interactiveCommand, command);
      assert.equal(payload.actionKind, "keep-action");
      assert.deepEqual(payload.parameters, { keep: "parameter" });
      assert.equal(node.title, "Keep title");
      assert.deepEqual(await readFile(mapFile), mapBefore);
    }
    for (const id of ["missing", "music", "fx", "loop", "ambiguous"]) await plan(route(target("map", "actor"), id), true);
    await plan(route(target("missing")), true);
    await plan(route(target("map", "missing")), true);
    await plan(visibility(target("map", "missing")), true);
    for (const id of ["sign", "custom", "missing-payload", "empty-payload", "unknown-character", "ambiguous-character", "unknown-trainer", "ambiguous-trainer", "trainer-character-missing", "invalid-direct"]) {
      await plan(route(target("map", id)), true);
      await plan(visibility(target("map", id)), true);
    }
    for (const id of ["missing", "sign", "custom", "missing-payload", "empty-payload", "unknown-character", "ambiguous-character", "unknown-trainer", "ambiguous-trainer", "trainer-character-missing", "invalid-direct", "wide-owner", "tall-owner", "shifted-owner", "duplicate-owner"]) {
      for (const actionId of ["scene.interactive_command.set", "scene.upsert", "scene.graph.patch"]) {
        await plan(route(target(), "door", id), true, actionId);
      }
    }
    await plan(route(target("map", "actor"), "door", "actor"), true);
    for (const owner of [null, "", " actor", "actor ", 8]) {
      await plan({ ...route(target()), steps: [{ kind: "move", direction: "south", durationMs: 200, initialCollisionOwnerEntityId: owner }] }, true);
    }
    await plan({ ...route(target()), steps: [{ kind: "through", enabled: true },
      { kind: "move", direction: "south", durationMs: 200, initialCollisionOwnerEntityId: "actor" }] }, true);
    await plan({ ...route(target()), steps: [{ kind: "face", direction: "south", durationMs: 50, initialCollisionOwnerEntityId: "actor" }] }, true);
    await plan({ ...route(target()), steps: [{ kind: "move", direction: "south", durationMs: 200, initialCollisionOwnerEntityId: "actor", unknown: true }] }, true);
    await plan({ ...route(), steps: [{ kind: "sound", mediaAssetId: "door", gain: 0.8, pitch: 100 }] }, true);
    await plan({ ...route(), steps: [{ kind: "move", direction: "south", durationMs: 0 }] }, true);
    await plan({ ...route(), steps: [{ kind: "jump", x: 1, y: 1 }] }, true);
    await plan({ ...visibility(), visible: "false" }, true);
    const stable = await readFile(file);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const result = await call("pokemap_query", { projectHandle: workspace.projectHandle, resourceKind: "scene", operation: "get", ids: ["edit"], view: "detail" });
    assert.ok(JSON.stringify(result).includes('"actorRoute"'));
    assert.ok(JSON.stringify(result).includes('"initialCollisionOwnerEntityId"'));
    assert.ok(JSON.stringify(result).includes('"trainer-actor"'));
    assert.deepEqual(await readFile(file), stable);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = undefined;
    const spatialManifest = record(JSON.parse(stable.toString("utf8")));
    spatialManifest.version = "v9";
    spatialManifest.settings = { ...record(spatialManifest.settings), dimension: "threeD" };
    spatialManifest.maps = [{ id: "spatial", name: "Spatial", relativePath: "maps/spatial.json" }];
    await writeFile(file, JSON.stringify(spatialManifest));
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    for (const actor of [target("spatial"), target("spatial", "actor")]) {
      await plan(route(actor), true);
      await plan(visibility(actor), true);
    }
    await plan(route(target("spatial"), "door", "actor"), true);
  } finally {
    if (workspace) await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

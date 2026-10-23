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
      ...(command.kind === "wait" ? ["completed"] : ["completed", "blocked"]).map((port) => ({ id: port, fromNodeId: "action", fromPortId: port, toNodeId: "end", kind: "actionCompleted" })),
    ],
  } };
}

test("live MCP persists native presentation data and refuses invalid sound references without writes", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "scene-presentation-mcp-"));
  const file = join(root, "project.json");
  const mapFile = join(root, "maps/map.json");
  const initialCommand = { kind: "warp", destinationMapId: "map", warpId: "arrival" };
  const draft = scene("unrelated-draft", { kind: "playSoundEffect", mediaAssetId: "missing", volume: 0.8 });
  await mkdir(join(root, "maps"));
  await mkdir(join(root, "audio"));
  const wav = Buffer.alloc(46);
  wav.write("RIFF", 0); wav.writeUInt32LE(38, 4); wav.write("WAVEfmt ", 8);
  wav.writeUInt32LE(16, 16); wav.writeUInt16LE(1, 20); wav.writeUInt16LE(1, 22);
  wav.writeUInt32LE(8000, 24); wav.writeUInt32LE(16000, 28);
  wav.writeUInt16LE(2, 32); wav.writeUInt16LE(16, 34);
  wav.write("data", 36); wav.writeUInt32LE(2, 40);
  for (const id of ["door", "music", "fx", "loop"]) await writeFile(join(root, "audio", `${id}.wav`), wav);
  await writeFile(file, JSON.stringify({ name: "QA native presentation transport", version: "v8", pokemon: canonicalPokemonConfig(),
    maps: [{ id: "map", name: "Map", relativePath: "maps/map.json" }], tilesets: [],
    scenes: [scene("edit", initialCommand), draft],
    cinematicMediaAssets: ["door", "music", "fx", "loop"].map((id) => ({ id, label: id, kind: id === "music" ? "music" : id === "fx" ? "cinematicFx" : "sound", relativePath: `audio/${id}.wav`, loopByDefault: id === "loop" })),
  }));
  await writeFile(mapFile, JSON.stringify({ version: "v8", id: "map", name: "Map", size: { width: 4, height: 4 }, layers: [],
    warps: [{ id: "arrival", pos: { x: 1, y: 1 }, targetMapId: "map", targetPos: { x: 1, y: 1 }, triggerMode: "on_bump" }] }));
  const mapBefore = await readFile(mapFile);
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const client = new Client({ name: "native-presentation-transport", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  let workspace: JsonRecord | undefined;
  async function call(name: string, input: JsonRecord, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: input });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify(envelope));
    return record(envelope[failure ? "error" : "data"]);
  }
  try {
    await client.connect(transport);
    const description = await call("pokemap_describe", {});
    const action = (description.mutationActions as JsonRecord[]).find((value) => value.id === "scene.interactive_command.set");
    assert.ok(action);
    const extension = record(action.extensions);
    assert.equal(record(extension.playSoundEffect).mediaReference, "knownNonLoopingSound");
    assert.deepEqual(record(extension.playSoundEffect).volumeRange, [0, 1]);
    assert.deepEqual(record(extension.playSoundEffect).unsupportedParameters, ["pitch"]);
    assert.equal(record(extension.sceneMusic).scope, "ownerScoped");
    assert.deepEqual(record(extension.sceneMusic).scopes, ["scene", "map"]);
    assert.deepEqual(record(extension.sceneMusic).channels, ["music", "ambience", "both"]);
    assert.equal(record(extension.sceneMusic).forcedLoop, true);
    assert.equal(record(extension.sceneMusic).restoreBaseline, "capturedBeforeFirstModification");
    assert.deepEqual(record(extension.sceneMusic).operations, {
      play: ["operation", "mediaAssetId", "volume"], restore: ["operation"], fadeOut: ["operation", "durationMs"],
      stop: ["operation"], memorize: ["operation"], restoreMemorized: ["operation"],
    });
    assert.equal(record(extension.playMusicEffect).role, "musicEffect");
    assert.equal(record(extension.playMusicEffect).mediaReference, "knownNonLoopingSound");
    assert.deepEqual(record(extension.playMusicEffect).bgmInterruption,
      { parameters: ["fadeOutMs", "fadeInMs"], integerRange: [0, 60000] });
    assert.deepEqual(record(extension.worldTone).durationMsRange, [0, 2147483647]);
    assert.deepEqual(record(extension.wait).parameters, ["durationMs"]);
    assert.deepEqual(record(extension.wait).durationMsRange, [0, 2147483647]);
    assert.deepEqual(record(extension.wait).outputPorts, ["completed"]);
    assert.equal(record(extension.wait).completion, "elapsed");
    for (const id of ["wait", "worldTone", "playSoundEffect", "playMusicEffect", "sceneMusic"]) {
      assert.equal(record(extension[id]).projectDimension, "twoD");
    }
    assert.deepEqual(record(extension.stopSoundEffects).scopes, ["scene", "map"]);
    assert.ok(extension.worldPresentation);
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    let sequence = 0;
    async function plan(command: JsonRecord, failure = false, replacePorts = false): Promise<JsonRecord> {
      assert.ok(workspace);
      const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
      const before = await readFile(file);
      const id = `presentation-${++sequence}`;
      const result = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
        requestId: id, actionId: replacePorts ? "scene.graph.patch" : "scene.interactive_command.set", actionVersion: 1,
        workspaceHandle: workspace.workspaceHandle, expectedRevision: validation.snapshotRevision,
        idempotencyKey: id, parameters: replacePorts ? { sceneId: "edit", removeEdgeIds: ["blocked"],
          upsertNodes: [{ id: "action", kind: "action", title: "Keep title", payload: {
            actionKind: "keep-action", parameters: { keep: "parameter" }, interactiveCommand: command } }] }
          : { sceneId: "edit", nodeId: "action", command },
      } }, failure);
      assert.deepEqual(await readFile(file), before);
      assert.deepEqual(await readFile(mapFile), mapBefore);
      return result;
    }
    const commands = [
      { kind: "worldTone", red: -255, green: -254.5, blue: 0, gray: 10, durationMs: 300 },
      { kind: "playSoundEffect", mediaAssetId: "door", volume: 0.8 },
      { kind: "playMusicEffect", mediaAssetId: "door", volume: 0.8, bgmInterruption: { fadeOutMs: 200, fadeInMs: 400 } },
      { kind: "sceneMusic", operation: "play", mediaAssetId: "music", volume: 0.8 },
      { kind: "sceneMusic", operation: "restore" },
      { kind: "sceneMusic", operation: "fadeOut", durationMs: 0 },
      { kind: "sceneMusic", operation: "play", channel: "ambience", scope: "map", mediaAssetId: "music", volume: .4 },
      { kind: "sceneMusic", operation: "memorize", channel: "both", scope: "map" },
      { kind: "sceneMusic", operation: "stop", channel: "music", scope: "map" },
      { kind: "sceneMusic", operation: "restoreMemorized", channel: "both", scope: "map" },
      { kind: "stopSoundEffects", scope: "map" },
      { kind: "worldPresentation", operation: "erasePicture", scope: "scene", durationMs: 0, waitForCompletion: false, slotId: 1 },
      { kind: "worldPresentation", operation: "flash", scope: "scene", durationMs: 300, waitForCompletion: false, red: 255, green: 20, blue: 0, alpha: 128 },
      { kind: "worldPresentation", operation: "shake", scope: "scene", durationMs: 500, waitForCompletion: false, referenceWidth: 512, referenceHeight: 384, power: 8, speed: 3 },
      { kind: "wait", durationMs: 400 },
    ];
    for (const command of commands) {
      const planned = await plan(command, false, command.kind === "wait");
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
      if (command.kind === "sceneMusic") {
        const stableMusic = await readFile(file);
        await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace!.workspaceHandle });
        workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
        const reopened = await call("pokemap_query", { projectHandle: workspace.projectHandle,
          resourceKind: "scene", operation: "get", ids: ["edit"], view: "detail" });
        assert.ok(JSON.stringify(reopened).includes('"sceneMusic"'));
        assert.ok(JSON.stringify(reopened).includes(`"${command.operation}"`));
        assert.deepEqual(await readFile(file), stableMusic);
      }
    }
    for (const id of ["missing", "door", "fx", "loop"]) {
      await plan({ kind: "sceneMusic", operation: "play", mediaAssetId: id, volume: .8 }, true);
    }
    for (const command of [
      { kind: "sceneMusic", operation: "restore", volume: 0 },
      { kind: "sceneMusic", operation: "play", mediaAssetId: "music", volume: "NaN" },
      { kind: "sceneMusic", operation: "play", mediaAssetId: "music", volume: 1.1 },
      { kind: "sceneMusic", operation: "fadeOut", durationMs: 60001 },
      { kind: "sceneMusic", operation: "fadeOut", durationMs: -1 },
      { kind: "sceneMusic", operation: "play", channel: "both", mediaAssetId: "music", volume: .8 },
      { kind: "stopSoundEffects", scope: "all" },
      { kind: "worldPresentation", operation: "erasePicture", slotId: 0 },
      { kind: "worldPresentation", operation: "flash", red: 256, green: 0, blue: 0, alpha: 255, durationMs: 300 },
      { kind: "worldPresentation", operation: "showPicture", slotId: 1, mediaAssetId: "missing", referenceWidth: 512, referenceHeight: 384, x: 0, y: 0, scaleX: 1, scaleY: 1, opacity: 1, origin: "topLeft" },
    ]) await plan(command, true);
    for (const id of ["missing", "music", "fx", "loop"]) await plan({ kind: "playSoundEffect", mediaAssetId: id, volume: 0.8 }, true);
    for (const id of ["missing", "music", "fx", "loop"]) await plan({ kind: "playMusicEffect", mediaAssetId: id, volume: .8,
      bgmInterruption: { fadeOutMs: 0, fadeInMs: 0 } }, true);
    for (const bgmInterruption of [null, { fadeOutMs: -1, fadeInMs: 0 }, { fadeOutMs: 0, fadeInMs: 60001 }]) {
      await plan({ kind: "playMusicEffect", mediaAssetId: "door", volume: .8, bgmInterruption }, true);
    }
    await plan({ kind: "playMusicEffect", mediaAssetId: "door", volume: .8, pitch: 100,
      bgmInterruption: { fadeOutMs: 0, fadeInMs: 0 } }, true);
    await plan({ kind: "playSoundEffect", mediaAssetId: "door", volume: 1.01 }, true);
    await plan({ kind: "playSoundEffect", mediaAssetId: "door", volume: 0.8, pitch: 100 }, true);
    await plan({ kind: "worldTone", red: "NaN", green: 0, blue: 0, gray: 0, durationMs: 300 }, true);
    for (const durationMs of [null, -1, 0.5, 2147483648, "400"]) {
      await plan({ kind: "wait", durationMs }, true);
    }
    await plan({ kind: "wait", durationMs: 400, target: "player" }, true);
    const stable = await readFile(file);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const result = await call("pokemap_query", { projectHandle: workspace.projectHandle, resourceKind: "scene", operation: "get", ids: ["edit"], view: "detail" });
    assert.ok(JSON.stringify(result).includes('"wait"'));
    assert.ok(JSON.stringify(result).includes('"durationMs":400'));
    assert.deepEqual(await readFile(file), stable);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = undefined;
    const spatialRoot = join(root, "spatial");
    await mkdir(join(spatialRoot, "maps"), { recursive: true });
    const spatialFile = join(spatialRoot, "project.json");
    const spatialMapFile = join(spatialRoot, "maps/map.json");
    const presentationCommands = [
      { kind: "wait", durationMs: 400 },
      { kind: "worldTone", red: -255, green: 0, blue: 0, gray: 0, durationMs: 300 },
      { kind: "playSoundEffect", mediaAssetId: "door", volume: 0.8 },
      { kind: "playMusicEffect", mediaAssetId: "door", volume: 0.8, bgmInterruption: { fadeOutMs: 200, fadeInMs: 400 } },
      { kind: "sceneMusic", operation: "restore" },
    ];
    const initialCommands = [
      { kind: "wait", durationMs: 1 },
      { kind: "worldTone", red: 0, green: 0, blue: 0, gray: 0, durationMs: 1 },
      { kind: "playSoundEffect", mediaAssetId: "door", volume: 1 },
      { kind: "playMusicEffect", mediaAssetId: "door", volume: 1, bgmInterruption: { fadeOutMs: 0, fadeInMs: 0 } },
      { kind: "sceneMusic", operation: "fadeOut", durationMs: 1 },
    ];
    await mkdir(join(spatialRoot, "audio"));
    await writeFile(join(spatialRoot, "audio/door.wav"), wav);
    await writeFile(spatialFile, JSON.stringify({ name: "3D presentation refusal", version: "v9",
      pokemon: canonicalPokemonConfig(), settings: { dimension: "threeD" },
      maps: [{ id: "map", name: "Map", relativePath: "maps/map.json" }], tilesets: [],
      cinematicMediaAssets: [{ id: "door", label: "Door", kind: "sound", relativePath: "audio/door.wav" }],
      scenes: initialCommands.map((command) => scene(`edit-${command.kind}`, command)) }));
    await writeFile(spatialMapFile, JSON.stringify({ version: "v9", id: "map", name: "Map",
      size: { width: 4, height: 4 }, layers: [], spatialScene: { schemaVersion: 1, width: 4, depth: 4, heightLevels: Array(16).fill(0), levelHeight: 1, instances: [],
        camera: { mode: "fixed", pitchDegrees: 48.7, yawDegrees: 0, fieldOfViewDegrees: 16.2, distance: 42 } } }));
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: spatialRoot });
    const spatialBefore = await readFile(spatialFile);
    const spatialMapBefore = await readFile(spatialMapFile);
    for (const command of presentationCommands) {
      const sceneId = `edit-${command.kind}`;
      const invalidScene = scene(sceneId, command);
      for (const actionId of ["scene.interactive_command.set", "scene.upsert", "scene.graph.patch"]) {
        const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
        const parameters = actionId === "scene.upsert" ? { scene: invalidScene }
          : actionId === "scene.graph.patch" ? { sceneId, upsertNodes: [
            (record(invalidScene.graph).nodes as JsonRecord[])[1]] }
            : { sceneId, nodeId: "action", command };
        const id = `spatial-${++sequence}`;
        const error = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
          requestId: id, actionId, actionVersion: 1, workspaceHandle: workspace.workspaceHandle,
          expectedRevision: validation.snapshotRevision, idempotencyKey: id, parameters } }, true);
        assert.ok(JSON.stringify(error).includes("commandUnsupportedDimension"));
        assert.deepEqual(await readFile(spatialFile), spatialBefore);
        assert.deepEqual(await readFile(spatialMapFile), spatialMapBefore);
      }
    }
  } finally {
    if (workspace) await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

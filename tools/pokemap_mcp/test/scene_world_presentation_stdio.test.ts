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
    assert.deepEqual(record(extension.worldTone).durationMsRange, [0, 2147483647]);
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    let sequence = 0;
    async function plan(command: JsonRecord, failure = false): Promise<JsonRecord> {
      assert.ok(workspace);
      const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
      const before = await readFile(file);
      const id = `presentation-${++sequence}`;
      const result = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
        requestId: id, actionId: "scene.interactive_command.set", actionVersion: 1,
        workspaceHandle: workspace.workspaceHandle, expectedRevision: validation.snapshotRevision,
        idempotencyKey: id, parameters: { sceneId: "edit", nodeId: "action", command },
      } }, failure);
      assert.deepEqual(await readFile(file), before);
      assert.deepEqual(await readFile(mapFile), mapBefore);
      return result;
    }
    const commands = [
      { kind: "worldTone", red: -255, green: -254.5, blue: 0, gray: 10, durationMs: 300 },
      { kind: "playSoundEffect", mediaAssetId: "door", volume: 0.8 },
    ];
    for (const command of commands) {
      const planned = await plan(command);
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
    for (const id of ["missing", "music", "fx", "loop"]) await plan({ kind: "playSoundEffect", mediaAssetId: id, volume: 0.8 }, true);
    await plan({ kind: "playSoundEffect", mediaAssetId: "door", volume: 1.01 }, true);
    await plan({ kind: "playSoundEffect", mediaAssetId: "door", volume: 0.8, pitch: 100 }, true);
    await plan({ kind: "worldTone", red: "NaN", green: 0, blue: 0, gray: 0, durationMs: 300 }, true);
    const stable = await readFile(file);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const result = await call("pokemap_query", { projectHandle: workspace.projectHandle, resourceKind: "scene", operation: "get", ids: ["edit"], view: "detail" });
    assert.ok(JSON.stringify(result).includes('"playSoundEffect"'));
    assert.ok(JSON.stringify(result).includes('"door"'));
    assert.deepEqual(await readFile(file), stable);
  } finally {
    if (workspace) await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

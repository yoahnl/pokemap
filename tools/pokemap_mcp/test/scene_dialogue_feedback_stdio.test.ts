import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import test from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";
import { canonicalPokemonConfig } from "./pokemon_fixture.js";

const source = "title: Start\n---\nFound!\n-> Yes\n    <<outcome yes>>\n-> No\n    <<outcome no>>\nAfter.\n===\n";
const choiceAction = "scene.dialogue.choicePolicy.update";
const feedbackAction = "scene.dialogue.lineFeedback.update";
const audioAction = "scene.dialogue.audioMedia.import";
const mapAudioAction = "map.audio.update";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

function dialoguePayload(scene: JsonRecord): JsonRecord {
  const nodes = record(scene.graph).nodes as JsonRecord[];
  const dialogue = nodes.find((node) => node.id === "dialogue");
  assert.ok(dialogue);
  return record(dialogue.payload);
}

function fixture(): JsonRecord {
  return {
    name: "Original MCP dialogue feedback",
    version: "v8", pokemon: canonicalPokemonConfig(),
    maps: [], tilesets: [],
    dialogues: [{ id: "choice", name: "Choice", relativePath: "dialogues/choice.yarn",
      declaredOutcomes: [{ id: "yes", label: "Yes" }, { id: "no", label: "No" }] }],
    scenes: [{ id: "scene", name: "Scene", graph: { startNodeId: "start", nodes: [
      { id: "start", kind: "start" },
      { id: "dialogue", kind: "yarnDialogue", payload: { dialogueId: "choice",
        expectedOutcomes: ["yes", "no", "cancel"], declaredCancellationOutcomes: ["cancel"] } },
      { id: "end", kind: "end" },
    ], edges: [
      { id: "entry", fromNodeId: "start", fromPortId: "completed", toNodeId: "dialogue", kind: "default" },
      { id: "completed", fromNodeId: "dialogue", fromPortId: "completed", toNodeId: "end", kind: "default" },
      ...["yes", "no", "cancel"].map((id) => ({ id, fromNodeId: "dialogue", fromPortId: id,
        toNodeId: "end", kind: "dialogueOutcome" })),
    ] } }],
  };
}

function sound(): Buffer {
  const bytes = Buffer.alloc(8044, 128);
  bytes.fill(0, 0, 44);
  bytes.write("RIFF", 0); bytes.writeUInt32LE(bytes.length - 8, 4);
  bytes.write("WAVEfmt ", 8); bytes.writeUInt32LE(16, 16);
  bytes.writeUInt16LE(1, 20); bytes.writeUInt16LE(1, 22);
  bytes.writeUInt32LE(8000, 24); bytes.writeUInt32LE(8000, 28);
  bytes.writeUInt16LE(1, 32); bytes.writeUInt16LE(8, 34);
  bytes.write("data", 36); bytes.writeUInt32LE(8000, 40);
  return bytes;
}

test("live MCP routes scoped choice cancellation and line feedback through canonical durable transactions", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-dialogue-feedback-mcp-"));
  await mkdir(join(root, "dialogues"));
  const manifestPath = join(root, "project.json");
  const sourcePath = join(root, "dialogues/choice.yarn");
  const original = fixture();
  await writeFile(manifestPath, JSON.stringify(original));
  await writeFile(sourcePath, source);
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--artifact-root", root,
      "--authoring-timeout-ms", "60000"], cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "scene-dialogue-feedback-proof", version: "1.0.0" });
  let sequence = 0;
  async function call(name: string, args: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: args });
    assert.equal(result.isError, failure ? true : undefined, JSON.stringify(result.structuredContent));
    const envelope = record(result.structuredContent);
    return record(failure ? envelope.error : envelope.data);
  }
  let workspace: JsonRecord | undefined;
  try {
    await client.connect(transport);
    const catalog = await call("pokemap_describe");
    const actions = new Map((catalog.mutationActions as JsonRecord[]).map((action) => [action.id, action]));
    for (const actionId of [choiceAction, feedbackAction, audioAction, mapAudioAction]) {
      const descriptor = actions.get(actionId);
      assert.ok(descriptor, actionId);
      assert.equal(descriptor.version, 1);
      assert.ok((descriptor.guarantees as string[]).includes("atomic"));
    }
    assert.ok((record(actions.get(mapAudioAction)!.extensions).parameterNames as string[]).includes("musicVolume"));
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    async function plan(actionId: string, parameters: JsonRecord, failure = false): Promise<JsonRecord> {
      assert.ok(workspace);
      const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
      const before = await readFile(manifestPath);
      const beforeSource = await readFile(sourcePath);
      const requestId = `dialogue-${++sequence}`;
      const planned = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
        requestId, actionId, actionVersion: 1, workspaceHandle: workspace.workspaceHandle,
        parameters, expectedRevision: validation.snapshotRevision, idempotencyKey: requestId,
      } }, failure);
      assert.deepEqual(await readFile(manifestPath), before);
      assert.deepEqual(await readFile(sourcePath), beforeSource);
      return planned;
    }
    async function mutate(actionId: string, parameters: JsonRecord): Promise<void> {
      const planned = await plan(actionId, parameters);
      assert.ok(workspace);
      const args = { operation: "apply", projectHandle: workspace.projectHandle,
        planId: planned.planId, operationId: `dialogue-apply-${sequence}` };
      const applied = await call("pokemap_apply", args);
      const replay = await call("pokemap_apply", args);
      assert.equal(record(applied.receipt).receiptId, record(replay.receipt).receiptId);
    }
    async function scene(): Promise<JsonRecord> {
      assert.ok(workspace);
      const queried = await call("pokemap_query", { projectHandle: workspace.projectHandle,
        resourceKind: "scene", operation: "get", ids: ["scene"], view: "detail" });
      const result = (queried.items as JsonRecord[])[0];
      assert.ok(result);
      assert.equal(result.runtimeBuildable, true);
      return result;
    }
    for (const cancellation of [{ kind: "branch", outcomeId: "cancel" },
      { kind: "choice", outcomeId: "no" }, { kind: "disabled" }]) {
      const choicePolicy = { nodeName: "Start", choiceIndex: 0, defaultOutcomeId: "yes", cancellation };
      await mutate(choiceAction, { sceneId: "scene", nodeId: "dialogue", choicePolicy });
      assert.deepEqual(dialoguePayload(await scene()).choicePolicies, [choicePolicy]);
    }
    const soundPath = join(root, "original.wav");
    await writeFile(soundPath, sound());
    const artifact = await call("pokemap_artifact_stage", { sourcePath: soundPath, declaredMediaType: "audio/wav" });
    await mutate(audioAction, { artifactHandle: artifact.artifactHandle, assetId: "pickup_audio",
      mediaId: "pickup", label: "Found", logicalPath: "assets/dialogue/found.wav" });
    assert.deepEqual(await readFile(join(root, "assets/dialogue/found.wav")), sound());
    await mutate("map.create", { mapId: "route", name: "Original route", width: 4, height: 4 });
    await mutate(mapAudioAction, { mapId: "route", musicPath: "assets/dialogue/found.wav", musicVolume: 0.64 });
    async function map(): Promise<JsonRecord> {
      assert.ok(workspace);
      const queried = await call("pokemap_query", { projectHandle: workspace.projectHandle,
        resourceKind: "map", operation: "get", ids: ["route"], view: "detail" });
      return record((queried.items as JsonRecord[])[0]);
    }
    assert.equal(record((await map()).mapMetadata).musicVolume, 0.64);
    await mutate(mapAudioAction, { mapId: "route", musicPath: null });
    assert.equal(record((await map()).mapMetadata).musicVolume, 0.64);
    assert.equal(record((await map()).mapMetadata).musicPath, null);
    await mutate(mapAudioAction, { mapId: "route", musicPath: "assets/dialogue/found.wav" });
    assert.equal(record((await map()).mapMetadata).musicVolume, 0.64);
    const badVolume = await plan(mapAudioAction, { mapId: "route", musicVolume: 1.01 }, true);
    assert.ok(badVolume.code);
    const linePolicy = { nodeName: "Start", lineIndex: 0, feedback: {
      segments: [{ kind: "text", text: "Found!", style: { colorArgb: 0xff0070f8 } }],
      revealIntervalMicros: 25000, advance: { kind: "autoAfterReveal", delayMicros: 1000000 },
      audioCue: { mediaAssetId: "pickup", cueId: "item-found", volume: 0.64,
        role: "musicEffect", bgmInterruption: { fadeOutMs: 200, fadeInMs: 1000 } },
    } };
    await mutate(feedbackAction, { sceneId: "scene", nodeId: "dialogue", linePolicy });
    const after = await scene();
    assert.deepEqual(dialoguePayload(after).linePolicies, [linePolicy]);
    assert.deepEqual(dialoguePayload(after).declaredCancellationOutcomes, ["cancel"]);
    assert.deepEqual(record(after.graph).edges, record(record((original.scenes as JsonRecord[])[0]).graph).edges);
    const invalidInterruption = await plan(feedbackAction, { sceneId: "scene", nodeId: "dialogue",
      linePolicy: { ...linePolicy, feedback: { ...linePolicy.feedback, audioCue: {
        ...linePolicy.feedback.audioCue, role: "effect" } } } }, true);
    assert.equal(invalidInterruption.domainCode, "scene.dialogue.line_feedback.invalid");
    const wrongText = await plan(feedbackAction, { sceneId: "scene", nodeId: "dialogue",
      linePolicy: { ...linePolicy, feedback: { ...linePolicy.feedback,
        segments: [{ kind: "text", text: "Changed!" }] } } }, true);
    assert.equal(wrongText.domainCode, "scene.dialogue.line_feedback.invalid");
    const changedSource = await plan("dialogue.source_update", { dialogueId: "choice",
      source: source.replace("Found!", "Changed!") }, true);
    assert.equal(changedSource.domainCode, "dialogue.scene_line_policy_references_blocking");
    const danglingChoice = await plan(choiceAction, { sceneId: "scene", nodeId: "dialogue",
      choicePolicy: { nodeName: "Start", choiceIndex: 0, cancellation: { kind: "branch", outcomeId: "missing" } } }, true);
    assert.equal(danglingChoice.domainCode, "scene.dialogue.choice_policy.invalid");
    const conflict = await plan(audioAction, { artifactHandle: artifact.artifactHandle, assetId: "another_audio",
      mediaId: "pickup", label: "Conflict", logicalPath: "assets/dialogue/other.wav" }, true);
    assert.equal(conflict.domainCode, "scene.dialogue.audio_media.conflict");
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = undefined;
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    assert.deepEqual(dialoguePayload(await scene()), dialoguePayload(after));
    assert.equal(record((await map()).mapMetadata).musicVolume, 0.64);
    assert.equal(await readFile(sourcePath, "utf8"), source);
    const saved = record(JSON.parse(await readFile(manifestPath, "utf8")));
    const media = (saved.cinematicMediaAssets as JsonRecord[])[0];
    assert.ok(media);
    assert.equal(media.kind, "sound"); assert.equal(media.durationMs, 1000);
    assert.notEqual(media.loopByDefault, true);
    console.log(JSON.stringify({ liveCatalog: true, actions: [choiceAction, feedbackAction, audioAction, mapAudioAction],
      choicePoliciesApplied: 3, lineFeedbackApplied: true, audioArtifactImported: true,
      musicEffectPolicyApplied: true, mapVolumeAppliedAndPreserved: true,
      exactRejections: 6, reopenedThroughMcp: true }));
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = undefined;
  } finally {
    if (workspace) await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

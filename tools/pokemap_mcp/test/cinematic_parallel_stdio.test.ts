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

function cinematic(variant: string): JsonRecord {
  const metadata = { "authoring.kind": "basicBlock", "authoring.source": "cinematic-builder-v0", "authoring.block": "actorMove", "actor.movementMode": "walk", "actor.pathMode": "direct", "actor.facingMode": "preserve" };
  const bindings: JsonRecord[] = [{ actorId: "actor", kind: "player" }, { actorId: "other", kind: "mapEntity", mapEntityId: "npc-other" }];
  const steps: JsonRecord[] = [
    { id: "face", kind: "actorFace", actorId: "actor", metadata: { "authoring.kind": "basicBlock", "authoring.source": "cinematic-builder-v0", "authoring.block": "actorFace", "actor.direction": "left" } },
    { id: "move", kind: "actorMove", actorId: "actor", targetId: "destination", durationMs: 1000, parallelGroupId: "pair", metadata },
    { id: "otherMove", kind: "actorMove", actorId: "other", targetId: "otherTarget", durationMs: 1000, parallelGroupId: "pair", metadata },
    { id: "camera", kind: "camera", durationMs: 1500, parallelGroupId: "pair", metadata: { "camera.mode": "focus", "camera.targetKind": "actor", "camera.targetActorId": "actor", "camera.zoomPreset": "medium" } },
  ];
  if (variant === "sequential") for (const step of steps) delete step.parallelGroupId;
  if (variant === "mismatch") steps[2]!.durationMs = 900;
  if (variant === "alias") bindings[1] = { actorId: "other", kind: "player" };
  if (variant === "noncontiguous") steps.splice(2, 0, { id: "gap", kind: "wait", durationMs: 100 });
  if (variant === "cameraConflict") steps.push({ ...steps[3], id: "camera-copy" });
  if (variant === "invalidId") steps[1]!.parallelGroupId = "";
  if (variant === "sharedChannel" || variant === "distinctChannels") steps.splice(0, steps.length,
    { id: "audio-a", kind: "sound", assetRef: "sound-a", durationMs: 500, parallelGroupId: "audio" },
    { id: "audio-b", kind: variant === "sharedChannel" ? "music" : "sound", assetRef: variant === "sharedChannel" ? "music-shared" : "sound-b", durationMs: 900, parallelGroupId: "audio" });
  return {
    id: "parallel", title: "Parallel fixture", mapId: "room", actorCompletionPolicy: "keepFinal",
    requiredActors: [{ actorId: "actor", label: "Actor" }, { actorId: "other", label: "Other" }],
    movementTargets: [{ targetId: "destination", label: "Destination" }, { targetId: "otherTarget", label: "Other destination" }],
    stageContext: {
      actorBindings: bindings,
      initialPlacements: variant.startsWith("relative") ? [] : [{ actorId: "actor", kind: "stagePoint", stagePointId: "start" }, { actorId: "other", kind: "stagePoint", stagePointId: "otherStart" }],
      stagePoints: [{ id: "start", label: "Start", x: 4, y: 4 }, { id: "destination", label: "Destination", x: variant.startsWith("relative") ? -1 : 8, y: 4, ...(variant.startsWith("relative") ? { relativeToActorId: variant === "relativeMissing" ? "missing" : "actor" } : {}) }, { id: "otherStart", label: "Other start", x: 4, y: 8 }, { id: "otherEnd", label: "Other end", x: 8, y: 8 }],
      movementTargetBindings: [{ targetId: "destination", kind: "stagePoint", sourceId: "destination" }, { targetId: "otherTarget", kind: "stagePoint", sourceId: "otherEnd" }],
    },
    timeline: { steps },
  };
}

test("MCP authors parallel actor camera groups and refuses conflicts mismatch and noncontiguity without writes", { timeout: 90_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "cinematic-parallel-mcp-"));
  const file = join(root, "project.json");
  const untouched = { id: "untouched", title: "Unchanged", timeline: { steps: [{ id: "wait", kind: "wait", durationMs: 500, metadata: {} }] } };
  await mkdir(join(root, "maps"));
  await writeFile(join(root, "maps/room.json"), JSON.stringify({ version: "v8", id: "room", name: "Room", size: { width: 16, height: 16 }, layers: [] }));
  await writeFile(file, JSON.stringify({ name: "Cinematic parallel", version: "v8", pokemon: canonicalPokemonConfig(), maps: [{ id: "room", name: "Room", relativePath: "maps/room.json" }], tilesets: [], cinematicMediaAssets: [
    { id: "sound-a", label: "Sound A", kind: "sound", relativePath: "audio/a.ogg", channel: "channel-a" },
    { id: "sound-b", label: "Sound B", kind: "sound", relativePath: "audio/b.ogg", channel: "channel-b" },
    { id: "music-shared", label: "Music", kind: "music", relativePath: "audio/music.ogg", channel: "channel-a" },
  ], cinematics: [untouched] }));
  const args = [process.env.POKEMAP_TEST_MCP_ENTRY ?? resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const client = new Client({ name: "cinematic-parallel-test", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  async function call(name: string, input: JsonRecord, failure = false): Promise<JsonRecord> {
    const envelope = record((await client.callTool({ name, arguments: input })).structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify(envelope));
    return record(envelope[failure ? "error" : "data"]);
  }
  try {
    await client.connect(transport);
    const described = await call("pokemap_describe", {});
    const descriptor = (described.mutationActions as JsonRecord[]).find(action => action.id === "cinematic.upsert");
    assert.match(String(descriptor?.summary), /parallelGroupId/);
    assert.match(String(descriptor?.summary), /relativeToActorId/);
    assert.match(String(descriptor?.summary), /actorMove\/actorJump durations/);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    let sequence = 0;
    async function plan(asset: JsonRecord, failure = false): Promise<JsonRecord> {
      const state = await call("pokemap_validate", { projectHandle: opened.projectHandle });
      const id = `parallel-${++sequence}`;
      return call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
        requestId: id, actionId: "cinematic.upsert", actionVersion: 1,
        workspaceHandle: opened.workspaceHandle, expectedRevision: state.snapshotRevision,
        idempotencyKey: id, parameters: { cinematic: asset },
      } }, failure);
    }
    for (const mode of ["grouped", "sequential", "relative"]) {
      const before = await readFile(file);
      const planned = await plan(cinematic(mode));
      assert.deepEqual(await readFile(file), before);
      await call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle, planId: planned.planId, operationId: `apply-parallel-${sequence}` });
      const query = await call("pokemap_query", { projectHandle: opened.projectHandle, resourceKind: "project", operation: "get", ids: ["project"], view: "detail", fieldMask: ["cinematics"] });
      const project = record((query.items as JsonRecord[])[0]);
      const item = record((project.cinematics as JsonRecord[]).find(asset => asset.id === "parallel"));
      const steps = record(item.timeline).steps as JsonRecord[];
      assert.equal(item.actorCompletionPolicy, "keepFinal");
      assert.equal(steps[1]!.parallelGroupId, mode !== "sequential" ? "pair" : undefined);
      assert.equal(steps[2]!.parallelGroupId, mode !== "sequential" ? "pair" : undefined);
      assert.equal(steps[3]!.parallelGroupId, mode !== "sequential" ? "pair" : undefined);
      assert.equal(steps[1]!.durationMs, 1000);
      assert.equal(steps[2]!.durationMs, 1000);
      assert.equal(steps[3]!.durationMs, 1500);
      if (mode === "relative") {
        const destination = (record(item.stageContext).stagePoints as JsonRecord[]).find(point => point.id === "destination");
        assert.equal(destination?.relativeToActorId, "actor");
        assert.equal(destination?.x, -1);
      }
      const disk = record(JSON.parse(await readFile(file, "utf8")));
      const other = (disk.cinematics as JsonRecord[]).find(asset => asset.id === "untouched");
      assert.equal(record(other).title, untouched.title);
      assert.deepEqual(record(record(other).timeline).steps, untouched.timeline.steps);
    }
    const mediaBefore = await readFile(file);
    const mediaPlanned = await plan(cinematic("distinctChannels"));
    assert.deepEqual(await readFile(file), mediaBefore);
    await call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle, planId: mediaPlanned.planId, operationId: `apply-parallel-${sequence}` });
    const mediaQuery = await call("pokemap_query", { projectHandle: opened.projectHandle, resourceKind: "project", operation: "get", ids: ["project"], view: "detail", fieldMask: ["cinematics", "cinematicMediaAssets"] });
    const mediaProject = record((mediaQuery.items as JsonRecord[])[0]);
    const mediaAsset = record((mediaProject.cinematics as JsonRecord[]).find(asset => asset.id === "parallel"));
    const mediaSteps = record(mediaAsset.timeline).steps as JsonRecord[];
    assert.deepEqual(mediaSteps.map(step => [step.kind, step.assetRef, step.parallelGroupId]), [["sound", "sound-a", "audio"], ["sound", "sound-b", "audio"]]);
    assert.deepEqual((mediaProject.cinematicMediaAssets as JsonRecord[]).map(asset => asset.channel), ["channel-a", "channel-b", "channel-a"]);
    for (const asset of ["mismatch", "alias", "noncontiguous", "cameraConflict", "invalidId", "sharedChannel", "relativeMissing"].map(cinematic)) {
      const before = await readFile(file);
      const rejected = await plan(asset, true);
      assert.equal(rejected.domainCode, "cinematic.invalid");
      assert.notEqual(rejected.domainCode, "worker.internal");
      assert.deepEqual(await readFile(file), before);
    }
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

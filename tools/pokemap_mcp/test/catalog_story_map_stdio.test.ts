import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { createHash } from "node:crypto";
import { mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join, resolve } from "node:path";
import { promisify } from "node:util";
import test from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("partitioned story entities and triggers cross live MCP and preserve unrelated maps", { timeout: 120_000 }, async () => {
  const root = join(homedir(), "Library/Caches/AveluneQA/targeted-story-authoring/mcp");
  await mkdir(root, { recursive: true });
  const dart = process.env.POKEMAP_TEST_DART ?? "dart";
  const packageRoot = resolve("../../packages/map_authoring");
  const client = new Client({ name: "catalog-story-map-proof", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--dart", dart, "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe" });
  async function call(name: string, input: JsonRecord = {}): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: input });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, true, JSON.stringify(envelope));
    return record(envelope.data);
  }
  try {
    await promisify(execFile)(dart, [`--packages=${join(packageRoot, ".dart_tool/package_config.json")}`,
      join(packageRoot, "test/support/create_working_catalog_fixture.dart"), root, "--story-map"], { timeout: 60_000 });
    const descriptor = await readFile(join(root, "project.json"));
    const foreign = await readFile(join(root, "maps/foreign.json"));
    await client.connect(transport);
    const described = await call("pokemap_describe");
    for (const id of ["entity.upsert", "trigger.create"]) {
      assert.ok((described.mutationActions as JsonRecord[]).some(value => value.id === id));
    }
    let opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    await call("pokemap_workshop", { operation: "prepare", projectHandle: opened.projectHandle });
    async function mutate(actionId: string, parameters: JsonRecord, id: string): Promise<JsonRecord> {
      const workshop = await call("pokemap_workshop", { operation: "read", projectHandle: opened.projectHandle,
        actionId, parameters, includeDocuments: false });
      const plan = await call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
        requestId: id, actionId, actionVersion: 1, workspaceHandle: opened.workspaceHandle,
        expectedRevision: workshop.snapshotRevision, idempotencyKey: id, parameters } });
      return call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle,
        planId: plan.planId, operationId: id });
    }
    const entity = { id: "guide", name: "Guide", kind: "npc", pos: { x: 2, y: 2 }, npc: { displayName: "Guide" } };
    await mutate("entity.upsert", { mapId: "story", entity }, "guide-create");
    await mutate("entity.upsert", { mapId: "story", entity: { ...entity, name: "Updated guide" } }, "guide-update");
    const consumedEventId = "evt_018f0f8c-7b8a-7def-8000-000000000001";
    await mutate("entity.upsert", { mapId: "story", entity: {
      id: "presented", kind: "custom", pos: { x: 1, y: 1 }, presentation: { schemaVersion: 2, variants: [
        { id: "visible", condition: { kind: "leaf", condition: {
          kind: "narrativeEventConsumed", eventId: consumedEventId, expectedValue: true } }, blocksMovement: false, characterId: null, facing: "south",
          size: { width: 1, height: 1 }, interactionMode: "front", movement: {},
          startsOnNpcContact: false, counterInteractionSides: [] },
      ] },
    } }, "presented-create");
    for (const alternate of [false, true]) {
      await mutate("entity.upsert", { mapId: "story", entity: {
        id: "balls", kind: "custom", blocksMovement: false, pos: { x: 4, y: 2 },
        healingDisplay: { variantElementIds: Array.from({ length: 6 }, (_, i) => `${alternate ? "alternate-" : ""}healing-${i + 1}`) },
      } }, `healing-${alternate}`);
    }
    const beforePublication = await readFile(join(root, "maps/story.json"));
    const narrativeMap = record(JSON.parse(beforePublication.toString()));
    await mutate("narrative.publish_document", {
      map: { ...narrativeMap, properties: { story: "published" } },
      mapRevision: `sha256:${createHash("sha256").update(beforePublication).digest("hex")}`,
      dialogues: [], facts: [], scenes: [], cinematics: [], storylines: [], events: [],
    }, "native-map-narrative");
    const triggerParameters = { mapId: "story", trigger: { id: "story-event", name: "Story event", type: "event",
      area: { pos: { x: 3, y: 2 }, size: { width: 1, height: 1 } } } };
    const beforeTrigger = await readFile(join(root, "maps/story.json"));
    const applied = await mutate("trigger.create", triggerParameters, "trigger-create");
    let map = record(JSON.parse(await readFile(join(root, "maps/story.json"), "utf8")));
    assert.equal((map.entities as JsonRecord[])[0]!.name, "Updated guide");
    assert.equal((map.triggers as JsonRecord[])[0]!.id, "story-event");
    await call("pokemap_history", { operation: "undo", projectHandle: opened.projectHandle,
      entryId: record(applied.receipt).receiptId, idempotencyKey: "trigger-undo" });
    assert.deepEqual(await readFile(join(root, "maps/story.json")), beforeTrigger);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
    opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const reopened = await call("pokemap_workshop", { operation: "read", projectHandle: opened.projectHandle,
      actionId: "trigger.create", parameters: triggerParameters });
    map = (reopened.maps as JsonRecord[])[0]!;
    assert.equal((map.entities as JsonRecord[])[0]!.name, "Updated guide");
    assert.deepEqual(map.triggers, []);
    const wav = Buffer.alloc(8044, 128);
    wav.write("RIFF", 0); wav.writeUInt32LE(8036, 4); wav.write("WAVEfmt ", 8);
    wav.writeUInt32LE(16, 16); wav.writeUInt16LE(1, 20); wav.writeUInt16LE(1, 22);
    wav.writeUInt32LE(8000, 24); wav.writeUInt32LE(8000, 28);
    wav.writeUInt16LE(1, 32); wav.writeUInt16LE(8, 34);
    wav.write("data", 36); wav.writeUInt32LE(8000, 40);
    await writeFile(join(root, "source.wav"), wav);
    const artifact = await call("pokemap_artifact_stage", {
      sourcePath: join(root, "source.wav"), declaredMediaType: "audio/wav" });
    const audioParameters = { artifactHandle: artifact.artifactHandle, assetId: "rival-music",
      mediaId: "rival-music", label: "Rival", logicalPath: "assets/music/rival.wav", mediaKind: "music" };
    const imported = await mutate("scene.dialogue.audioMedia.import", audioParameters, "rival-music");
    assert.deepEqual(await readFile(join(root, "assets/music/rival.wav")), wav);
    const audio = await call("pokemap_workshop", { operation: "read", projectHandle: opened.projectHandle,
      actionId: "scene.dialogue.audioMedia.import", parameters: audioParameters });
    const media = (record(audio.project).cinematicMediaAssets as JsonRecord[])[0]!;
    assert.equal(media.kind, "music");
    assert.equal(media.loopByDefault, true);
    assert.equal(media.durationMs, 1000);
    await call("pokemap_history", { operation: "undo", projectHandle: opened.projectHandle,
      entryId: record(imported.receipt).receiptId, idempotencyKey: "music-undo" });
    const undoneAudio = await call("pokemap_workshop", { operation: "read", projectHandle: opened.projectHandle,
      actionId: "scene.dialogue.audioMedia.import", parameters: { mediaId: "rival-music" } });
    assert.deepEqual(record(undoneAudio.project).cinematicMediaAssets, []);
    assert.deepEqual(await readFile(join(root, "project.json")), descriptor);
    assert.deepEqual(await readFile(join(root, "maps/foreign.json")), foreign);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

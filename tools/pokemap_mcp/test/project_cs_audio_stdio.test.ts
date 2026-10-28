import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { join, resolve } from "node:path";
import test from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";
import { canonicalPokemonConfig } from "./pokemon_fixture.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("project CS and sound cues use scoped MCP settings actions", { timeout: 120_000 }, async () => {
  const qa = "/Users/karim/Library/Caches/AveluneQA/surf-v1/authoring";
  await mkdir(qa, { recursive: true });
  const root = await mkdtemp(join(qa, "cs-audio-mcp-"));
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "cs-audio-test", version: "1.0.0" });
  async function call(name: string, input: JsonRecord, failed = false): Promise<JsonRecord> {
    const envelope = record((await client.callTool({ name, arguments: input })).structuredContent);
    assert.equal(envelope.ok, !failed, JSON.stringify(envelope));
    return record(envelope[failed ? "error" : "data"]);
  }
  try {
    const file = join(root, "project.json");
    await writeFile(file, JSON.stringify({ name: "Adventure", version: "v9",
      settings: { dimension: "threeD", spatialCamera: { mode: "fixed", projection: "perspective", pitchDegrees: 48.7, yawDegrees: 0, fieldOfViewDegrees: 16.2, distance: 42, orthographicHeight: 12 } },
      maps: [], tilesets: [], pokemon: canonicalPokemonConfig(), customExtension: { preserve: true } }));
    await client.connect(transport);
    const catalog = await call("pokemap_describe", {});
    for (const id of ["field_ability.configure", "project.audio.cue.configure", "project.audio.media.adopt_asset"]) {
      assert.ok((catalog.mutationActions as JsonRecord[]).some(value => value.id === id));
    }
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    let sequence = 0;
    async function mutate(actionId: string, resourceKind: string, parameters: JsonRecord): Promise<JsonRecord> {
      const query = resourceKind === "global" ? await call("pokemap_validate", {
        projectHandle: opened.projectHandle,
      }) : await call("pokemap_query", { projectHandle: opened.projectHandle,
        resourceKind, operation: "get", ids: ["project"], view: "detail",
        extensions: { actionId, parameters } });
      if (["presentationMedia.import", "project.audio.media.adopt_asset"].includes(actionId)) {
        const projection = record((query.items as unknown[])[0]);
        assert.equal(projection.configurationAvailable, false);
        assert.equal(Object.hasOwn(projection, "configuration"), false);
      }
      const id = `settings-${++sequence}`;
      const planned = await call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
        requestId: id, idempotencyKey: id, workspaceHandle: opened.workspaceHandle,
        actionId, actionVersion: 1, expectedRevision: query.snapshotRevision, parameters,
      } });
      return call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle,
        planId: planned.planId, operationId: `apply-${id}` });
    }
    for (const abilityId of ["rock_climb", "defog"]) {
      await mutate("field_ability.configure", "fieldAbilityConfiguration", { abilityId, enabled: false });
    }
    assert.deepEqual(record(record(JSON.parse(await readFile(file, "utf8"))).settings).fieldAbilities,
      { disabledAbilities: ["defog", "rock_climb"] });
    await mutate("project.audio.cue.configure", "projectAudio", {
      cueId: "ui.select", binding: { source: "silent", gain: 0.5 },
    });
    assert.deepEqual(record(record(JSON.parse(await readFile(file, "utf8"))).settings).fieldAbilities,
      { disabledAbilities: ["defog", "rock_climb"] });
    await mutate("project.audio.cue.configure", "projectAudio", { cueId: "ui.select", binding: null });
    const abilities = await call("pokemap_query", { projectHandle: opened.projectHandle,
      resourceKind: "fieldAbilityConfiguration", operation: "get", ids: ["project"] });
    const entries = record((abilities.items as unknown[])[0]).abilities as JsonRecord[];
    assert.equal(entries.length, 11);
    for (const id of ["rock_climb", "defog"]) {
      assert.ok(entries.some(entry => entry.id === id && entry.enabled === false && entry.activationOnly === true));
      await mutate("field_ability.configure", "fieldAbilityConfiguration", { abilityId: id, enabled: true });
    }
    assert.equal(record(record(JSON.parse(await readFile(file, "utf8"))).settings).fieldAbilities, undefined);
    await mutate("field_ability.configure", "fieldAbilityConfiguration", { abilityId: "dive", enabled: false });
    assert.deepEqual(record(record(JSON.parse(await readFile(file, "utf8"))).settings).fieldAbilities,
      { disabledAbilities: ["dive"] });
    const applied = await mutate("project.audio.cue.configure", "projectAudio", {
      cueId: "ui.confirm", binding: { source: "silent", gain: 1 },
    });
    const project = record(JSON.parse(await readFile(file, "utf8")));
    assert.deepEqual(record(project.settings).audio, { cues: { "ui.confirm": { source: "silent", gain: 1 } } });
    assert.deepEqual(project.customExtension, { preserve: true });
    await call("pokemap_history", { operation: "undo", projectHandle: opened.projectHandle,
      entryId: record(applied.receipt).receiptId, idempotencyKey: "undo-sound" });
    const restored = record(record(JSON.parse(await readFile(file, "utf8"))).settings);
    assert.equal(restored.audio, undefined);
    assert.deepEqual(restored.fieldAbilities, { disabledAbilities: ["dive"] });
    const wave = Buffer.alloc(44 + 16_000);
    wave.write("RIFF", 0); wave.writeUInt32LE(wave.length - 8, 4);
    wave.write("WAVEfmt ", 8); wave.writeUInt32LE(16, 16);
    wave.writeUInt16LE(1, 20); wave.writeUInt16LE(1, 22);
    wave.writeUInt32LE(8_000, 24); wave.writeUInt32LE(16_000, 28);
    wave.writeUInt16LE(2, 32); wave.writeUInt16LE(16, 34);
    wave.write("data", 36); wave.writeUInt32LE(16_000, 40);
    const sourcePath = join(root, "click.wav");
    await writeFile(sourcePath, wave);
    const staged = await call("pokemap_artifact_stage", { sourcePath, declaredMediaType: "audio/wav" });
    await mutate("presentationMedia.import", "projectAudio", {
      artifactHandle: staged.artifactHandle, assetId: "click-audio", mediaId: "click",
      label: "Click", kind: "audio", logicalPath: "assets/audio/click.wav",
    });
    const library = await call("pokemap_query", { projectHandle: opened.projectHandle,
      resourceKind: "presentationMedia", operation: "list", filters: { kind: "audio" }, pageSize: 1 });
    assert.equal(record((library.items as unknown[])[0]).id, "click");
    await mutate("project.audio.cue.configure", "projectAudio", {
      cueId: "door.open", binding: { source: "custom", mediaId: "click", gain: 0.6 },
    });
    const custom = record(record(JSON.parse(await readFile(file, "utf8"))).settings);
    assert.deepEqual(custom.audio, { cues: { "door.open": { source: "custom", mediaId: "click", gain: 0.6 } } });
    const legacyStaged = await call("pokemap_artifact_stage", { sourcePath, declaredMediaType: "audio/wav" });
    await mutate("asset.import", "global", {
      artifactHandle: legacyStaged.artifactHandle, assetId: "legacy-click",
      logicalPath: "assets/audio/legacy.WAV",
    });
    const assetsBefore = await readFile(join(root, "assets/.pokemap-assets.json"));
    const candidates = await call("pokemap_query", { projectHandle: opened.projectHandle,
      resourceKind: "asset", operation: "list", filters: { audioOnly: true } });
    assert.ok((candidates.items as JsonRecord[]).some(value => value.id === "legacy-click"));
    const adopted = await mutate("project.audio.media.adopt_asset", "projectAudio", {
      assetId: "legacy-click", mediaId: "legacy", label: "Ancien clic",
    });
    assert.deepEqual(await readFile(join(root, "assets/.pokemap-assets.json")), assetsBefore);
    await call("pokemap_history", { operation: "undo", projectHandle: opened.projectHandle,
      entryId: record(adopted.receipt).receiptId, idempotencyKey: "undo-adoption" });
    const afterUndo = record(JSON.parse(await readFile(join(root, "assets/.pokemap-media.json"), "utf8")));
    assert.equal((afterUndo.entries as JsonRecord[]).some(value => value.id === "legacy"), false);
    await mutate("project.audio.media.adopt_asset", "projectAudio", {
      assetId: "legacy-click", mediaId: "legacy", label: "Ancien clic",
    });
    await mutate("project.audio.cue.configure", "projectAudio", {
      cueId: "door.close", binding: { source: "custom", mediaId: "legacy", gain: 0.4 },
    });
    assert.deepEqual(await readFile(join(root, "assets/audio/legacy.WAV")), wave);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

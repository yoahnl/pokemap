import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";
import { createHash } from "node:crypto";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";
import { canonicalPokemonConfig } from "./pokemon_fixture.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("live MCP authors, templates, publishes and links Presentations in a v9 spatial project", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "presentation-v9-mcp-"));
  const file = join(root, "project.json");
  const scene = {
    id: "intro", name: "Introduction", executionProfile: "preSession",
    declaredOutcomes: [{ id: "ready", label: "Ready" }],
    graph: {
      startNodeId: "start",
      nodes: [
        { id: "start", kind: "start" },
        { id: "end", kind: "end", payload: { sceneOutcomeId: "ready", outcomePolicy: "progression" } },
      ],
      edges: [{ id: "start_end", fromNodeId: "start", fromPortId: "completed", toNodeId: "end", kind: "defaultFlow" }],
    },
  };
  await writeFile(file, JSON.stringify({
    name: "Spatial Presentation fixture", version: "v9",
    settings: { dimension: "threeD", spatialCamera: { mode: "fixed", pitchDegrees: 48.7, yawDegrees: 0, fieldOfViewDegrees: 16.2, distance: 42 } },
    pokemon: canonicalPokemonConfig(), maps: [], tilesets: [], scenes: [scene],
  }));
  const sourceBytes = Buffer.from([1, 2, 3]);
  const artifactName = Buffer.from("artifact-content", "utf8");
  const nameLength = Buffer.alloc(8), byteLength = Buffer.alloc(8);
  nameLength.writeBigUInt64BE(BigInt(artifactName.length));
  byteLength.writeBigUInt64BE(BigInt(sourceBytes.length));
  const digest = createHash("sha256").update(nameLength).update(artifactName).update(byteLength).update(sourceBytes).digest("hex");
  const videoBytes = Buffer.from([4, 5, 6]);
  const videoDigest = createHash("sha256").update(nameLength).update(artifactName).update(byteLength).update(videoBytes).digest("hex");
  const media = { id: "library-image", label: "image.png", kind: "image", sourceAssetId: "source",
    technicalMetadata: { mediaType: "image/png", container: "png", codec: "png", sizeBytes: 3, width: 1, height: 1 } };
  await mkdir(join(root, "assets/.pokemap-store"), { recursive: true });
  await mkdir(join(root, "presentation"), { recursive: true });
  await writeFile(join(root, `assets/.pokemap-store/${digest}.blob`), sourceBytes);
  await writeFile(join(root, `assets/.pokemap-store/${videoDigest}.blob`), videoBytes);
  await writeFile(join(root, "assets/.pokemap-assets.json"), JSON.stringify({ schemaVersion: 1, records: [{
    id: "source", logicalPath: "presentation/image.png", usages: [], tags: [],
    artifact: { digest: `sha256:${digest}`, handle: `artifact://sha256/${digest}`, mediaType: "image/png", byteLength: 3 },
  }, { id: "loop-source", logicalPath: "presentation/loop.mp4", usages: [], tags: [],
    artifact: { digest: `sha256:${videoDigest}`, handle: `artifact://sha256/${videoDigest}`, mediaType: "video/mp4", byteLength: 3 },
  }] }));
  await writeFile(join(root, "assets/.pokemap-media.json"), JSON.stringify({ schemaVersion: 1, entries: [media] }));
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const client = new Client({ name: "presentation-v9-proof", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  let workspace: JsonRecord | undefined;
  async function call(name: string, input: JsonRecord, failureDomain?: string): Promise<JsonRecord> {
    const envelope = record((await client.callTool({ name, arguments: input })).structuredContent);
    assert.equal(envelope.ok, failureDomain === undefined, JSON.stringify(envelope));
    if (failureDomain) assert.equal(record(envelope.error).domainCode, failureDomain);
    return record(envelope[failureDomain ? "error" : "data"]);
  }
  try {
    await client.connect(transport);
    const description = await call("pokemap_describe", {});
    const actionIds = (description.mutationActions as JsonRecord[]).map((action) => action.id);
    for (const action of ["presentationCinematic.create", "presentationCinematicTemplate.instantiate",
      "presentationCinematic.publish", "scene.preSession.presentation.createAndLink", "presentationMedia.rename", "presentationMedia.delete", "cinematicLibraryFolder.create", "cinematicLibraryEntry.place"]) {
      assert.ok(actionIds.includes(action));
    }
    const presentationDescriptor = (description.resourceKinds as JsonRecord[]).find((kind) => kind.id === "projectPresentationProfile");
    assert.ok(presentationDescriptor);
    assert.deepEqual(record(record(presentationDescriptor.extensions).titleLoopLimits), {
      maxDurationMilliseconds: 120000, maxSizeBytes: 64 * 1024 * 1024,
      maxBitrateKbps: 12000, maxLongestEdgePixels: 1920, maxShortestEdgePixels: 1080, audioCodec: "none",
    });
    assert.deepEqual(record(record(presentationDescriptor.extensions).titleMusicEndBehavior), {
      field: "branding.titleMusicEndBehavior", values: ["loop", "replayIntro"], default: "loop",
      replayIntroRequires: ["branding.titleMusicPath", "intro.allowReplay"], trigger: "naturalAudioCompletion", eligibleSurface: "titlePrompt",
    });
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const invalidRevision = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    const invalidBefore = await readFile(file);
    const invalidProfile = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
      requestId: "invalid-profile-bitrate", actionId: "presentation.update", actionVersion: 1,
      workspaceHandle: workspace.workspaceHandle, expectedRevision: invalidRevision.snapshotRevision,
      idempotencyKey: "invalid-profile-bitrate", parameters: { profile: { schemaVersion: 10,
        intro: { media: { landscape: { videoPath: "presentation/private-intro.mp4", posterPath: "presentation/private-poster.png",
          durationMilliseconds: 6000, width: 1920, height: 1080, bitrateKbps: 12448,
          sizeBytes: 4000000, videoCodec: "h264", audioCodec: "none" } } },
      } },
    } }, "presentation.validation_failed");
    assert.equal(invalidProfile.code, "validation_failed");
    assert.equal(invalidProfile.message, "The presentation profile has blocking diagnostics.");
    assert.ok((record(invalidProfile.details).diagnostics as JsonRecord[]).some((diagnostic) =>
      diagnostic.code === "introBitrateExceeded" && diagnostic.path === "$.presentation.intro.media.landscape.bitrateKbps"));
    assert.ok(!JSON.stringify(invalidProfile).includes(root));
    assert.deepEqual(await readFile(file), invalidBefore);
    for (const [duration, size] of [[30000, 64 * 1024 * 1024], [90000, 64 * 1024 * 1024],
      [120000, 64 * 1024 * 1024], [120001, 64 * 1024 * 1024], [90000, 64 * 1024 * 1024 + 1]] as const) {
      const accepted = duration <= 120000 && size <= 64 * 1024 * 1024;
      const variant = { videoPath: "presentation/loop.mp4", posterPath: "presentation/image.png",
        durationMilliseconds: duration, width: 1920, height: 1080, bitrateKbps: 10000,
        sizeBytes: size, videoCodec: "h264", audioCodec: "none" };
      const titleLoop = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
        requestId: `title-loop-${duration}-${size}`, actionId: "presentation.update", actionVersion: 1,
        workspaceHandle: workspace.workspaceHandle, expectedRevision: invalidRevision.snapshotRevision,
        idempotencyKey: `title-loop-${duration}-${size}`, dryRun: false, parameters: { profile: {
          schemaVersion: 10, titleMotion: { promptLoop: { landscape: variant }, menuLoop: { landscape: variant } },
        } },
      } }, accepted ? undefined : "presentation.validation_failed");
      if (accepted) assert.equal(titleLoop.applicable, true);
      else assert.deepEqual((record(titleLoop.details).diagnostics as JsonRecord[]).map((diagnostic) => diagnostic.code),
        duration > 120000 ? ["titleLoopDurationExceeded", "titleLoopDurationExceeded"] : ["titleMotionCombinedSizeExceeded", "titleLoopSizeExceeded", "titleLoopSizeExceeded"]);
      assert.deepEqual(await readFile(file), invalidBefore);
    }
    const invalidReplay = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
      requestId: "invalid-music-replay", actionId: "presentation.update", actionVersion: 1,
      workspaceHandle: workspace.workspaceHandle, expectedRevision: invalidRevision.snapshotRevision,
      idempotencyKey: "invalid-music-replay", parameters: { profile: { branding: { titleMusicEndBehavior: "replayIntro" } } },
    } }, "presentation.validation_failed");
    assert.deepEqual((record(invalidReplay.details).diagnostics as JsonRecord[]).map((diagnostic) => diagnostic.code),
      ["titleMusicReplayRequiresIntro", "titleMusicReplayRequiresMusic"]);
    let sequence = 0;
    async function mutate(actionId: string, parameters: JsonRecord, failureDomain?: string): Promise<void> {
      assert.ok(workspace);
      const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
      const before = await readFile(file);
      const id = `presentation-${++sequence}`;
      const planned = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
        requestId: id, actionId, actionVersion: 1, workspaceHandle: workspace.workspaceHandle,
        expectedRevision: validation.snapshotRevision, idempotencyKey: id, parameters,
      } }, failureDomain);
      assert.deepEqual(await readFile(file), before);
      if (failureDomain) return;
      const confirmation = actionId.endsWith("delete")
        ? await call("pokemap_apply", { operation: "confirm", projectHandle: workspace.projectHandle, planId: planned.planId })
        : undefined;
      await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle,
        planId: planned.planId, operationId: `apply-${id}`,
        ...(confirmation ? { confirmationToken: confirmation.confirmationToken } : {}) });
    }
    const audioBytes = Buffer.from([7, 8, 9]);
    const audioDigest = createHash("sha256").update(nameLength).update(artifactName).update(byteLength).update(audioBytes).digest("hex");
    await writeFile(join(root, `assets/.pokemap-store/${audioDigest}.blob`), audioBytes);
    const replayCatalogPath = join(root, "assets/.pokemap-assets.json");
    const replayCatalog = record(JSON.parse(await readFile(replayCatalogPath, "utf8")));
    (replayCatalog.records as JsonRecord[]).push({ id: "title-music", logicalPath: "presentation/music.ogg", usages: [], tags: [],
      artifact: { digest: `sha256:${audioDigest}`, handle: `artifact://sha256/${audioDigest}`, mediaType: "audio/ogg", byteLength: 3 } });
    await writeFile(replayCatalogPath, JSON.stringify(replayCatalog));
    await mutate("presentation.update", { profile: {
      schemaVersion: 10,
      branding: { titleMusicPath: "presentation/music.ogg", titleMusicEndBehavior: "replayIntro" },
      intro: { media: { landscape: { videoPath: "presentation/loop.mp4", posterPath: "presentation/image.png",
        durationMilliseconds: 6000, width: 1920, height: 1080, bitrateKbps: 4000, sizeBytes: 3, videoCodec: "h264", audioCodec: "none" } } },
    } });
    const replaySaved = record(JSON.parse(await readFile(file, "utf8")));
    assert.equal(record(record(replaySaved.presentation).branding).titleMusicEndBehavior, "replayIntro");
    await mutate("presentation.update", { profile: { schemaVersion: 10 } });
    await mutate("asset.delete", { assetId: "title-music" });
    await mutate("presentationCinematic.create", {
      cinematicId: "created", title: "Created", description: null, durationUs: 1_000_000,
    });
    await mutate("presentationCinematicTemplate.instantiate", {
      templateId: "titleIdentity", templateVersion: 1, cinematicId: "template", title: "Title", description: null,
    });
    const saved = record(JSON.parse((await readFile(file)).toString("utf8")));
    const created = (saved.presentationCinematics as JsonRecord[]).find((cinematic) => cinematic.id === "created");
    assert.ok(created);
    await mutate("presentationCinematic.publish", {
      cinematic: {
        ...created, id: "published", title: "Published",
        layers: [{ id: "title", label: "Title", zIndex: 0, visible: true, locked: false }],
        tracks: [{ id: "visuals", label: "Visuals", kind: "visual", clips: [{
          id: "title", kind: "visual", contentKind: "text", layerId: "title", text: "Opening",
          startUs: 0, durationUs: 1_000_000,
          from: { translateX: 0.5, opacity: 1 }, to: { translateX: 1, opacity: 1 },
        }] }],
      },
      expectedCinematic: null, expectedEntry: null, expectedMedia: [], folderId: null, imports: [],
    });
    const publishedProject = record(JSON.parse((await readFile(file)).toString("utf8")));
    const published = (publishedProject.presentationCinematics as JsonRecord[]).find((item) => item.id === "published");
    assert.ok(published);
    const publishedEntry = (record(publishedProject.cinematicLibraryCatalog).entries as JsonRecord[])
      .find((entry) => entry.cinematicId === "published");
    assert.ok(publishedEntry);
    await mutate("presentationCinematic.publish", {
      cinematic: { ...published, title: "Published after JavaScript round trip" },
      expectedCinematic: published, expectedEntry: publishedEntry,
    });
    await mutate("scene.preSession.presentation.createAndLink", {
      sceneId: "intro", nodeId: "linked", targetNodeId: "end", cinematicId: "linked",
      title: "Linked", templateId: "blank", templateVersion: 1, targetFolderId: null, targetIndex: 0,
    });
    const linked = record(JSON.parse((await readFile(file)).toString("utf8")));
    const baseScene = (linked.scenes as JsonRecord[])[0];
    assert.ok(baseScene);
    await mutate("presentationCinematic.publish", {
      cinematic: { ...created, id: "published-linked", title: "Published and linked" },
      expectedCinematic: null, expectedEntry: null, expectedMedia: [], folderId: null, imports: [],
      link: { baseScene, scene: baseScene, nodeId: "published-linked", targetNodeId: "end" },
    });
    await mutate("cinematicLibraryFolder.create", { folderId: "startup", family: "presentation", name: "Démarrage", parentFolderId: null, targetIndex: 0 });
    await mutate("cinematicLibraryFolder.create", { folderId: "new-game", family: "presentation", name: "Nouvelle partie", parentFolderId: "startup", targetIndex: 0 });
    await mutate("cinematicLibraryEntry.place", { family: "presentation", cinematicId: "linked", targetFolderId: "new-game", targetIndex: 0 });
    await mutate("asset.delete", { assetId: "source" }, "asset.references_blocking");
    await mutate("presentationMedia.rename", { mediaId: "library-image", label: "Introduction — portrait", expectedMedia: media });
    await mutate("presentationMedia.delete", { mediaId: "library-image", expectedMedia: media }, "presentation_media.baseline_changed");
    const currentMedia = record(JSON.parse((await readFile(join(root, "assets/.pokemap-media.json"))).toString("utf8")));
    await mutate("presentationMedia.delete", { mediaId: "library-image", expectedMedia: (currentMedia.entries as JsonRecord[])[0] });
    assert.deepEqual(record(JSON.parse(await readFile(join(root, "assets/.pokemap-media.json"), "utf8"))).entries, []);
    assert.deepEqual(await readFile(join(root, `assets/.pokemap-store/${digest}.blob`)), sourceBytes);
    await mutate("asset.delete", { assetId: "source" });
    assert.deepEqual((record(JSON.parse(await readFile(join(root, "assets/.pokemap-assets.json"), "utf8"))).records as JsonRecord[]).map((asset) => asset.id), ["loop-source"]);
    const stable = await readFile(file);
    const final = record(JSON.parse(stable.toString("utf8")));
    assert.equal(final.version, "v9");
    const classified = (record(final.cinematicLibraryCatalog).entries as JsonRecord[]).find((item) => item.cinematicId === "linked");
    assert.equal(classified?.folderId, "new-game");
    assert.equal(record(final.settings).dimension, "threeD");
    assert.deepEqual((final.presentationCinematics as JsonRecord[]).map((item) => item.id),
      ["created", "template", "published", "linked", "published-linked"]);
    assert.equal((final.presentationCinematics as JsonRecord[]).find((item) => item.id === "published")?.title,
      "Published after JavaScript round trip");
    const nodes = record(record((final.scenes as JsonRecord[])[0]).graph).nodes as JsonRecord[];
    for (const id of ["linked", "published-linked"]) {
      const node = nodes.find((entry) => entry.id === id);
      assert.ok(node);
      assert.equal(node.kind, "presentationCinematic");
      assert.equal(record(node.payload).presentationCinematicId, id);
    }
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const query = await call("pokemap_query", { projectHandle: workspace.projectHandle,
      resourceKind: "presentationCinematic", operation: "list", view: "detail" });
    assert.equal(query.totalAvailable, 5);
    assert.deepEqual(await readFile(file), stable);
  } finally {
    if (workspace) await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

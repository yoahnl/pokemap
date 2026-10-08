import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { cp, mkdir, readFile, realpath, writeFile } from "node:fs/promises";
import { resolve, join } from "node:path";
import { pathToFileURL } from "node:url";
import { setTimeout as delay } from "node:timers/promises";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";
import { matchesRequestedState, promoteValidatedValboisExport, questIds, questScenes } from "./author_valbois_gameplay.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

export const storyDoor = {
  mapId: "first-map", modelId: "bw2-normal-door-1", instanceId: "valbois-home-interactive-door",
  pivot: { x: -.5, y: .375, z: 0 },
  instance: { id: "valbois-home-interactive-door", modelId: "bw2-normal-door-1",
    position: { x: 7.5, y: .0224609375, z: 7.985 }, rotationDegrees: 0, scale: 1,
    animationIndex: null, animationLoop: false, animationSpeed: 1, blocksMovement: true },
  fact: { id: "fact_valbois_home_door_open", label: "La porte de la maison est ouverte", category: "Valbois",
    defaultValue: false, tags: ["Valbois", "porte", "3D"] },
  warp: { id: "home-door", pos: { x: 7, y: 7 }, targetMapId: "valbois-home", targetPos: { x: 5, y: 6 },
    triggerMode: "on_enter", allowedApproachFacings: [], triggerPadding: { left: 0, right: 0, top: 0, bottom: 0 } },
};

export function withStoryDoorNavigation(navigation: JsonRecord): JsonRecord {
  const original = { x: 5, z: 4, width: 5, depth: 4 };
  const replacements = [{ x: 5, z: 4, width: 5, depth: 3 },
    { x: 5, z: 7, width: 2, depth: 1 }, { x: 8, z: 7, width: 2, depth: 1 }];
  const areas = navigation.blockedAreas as JsonRecord[];
  const exists = areas.some(area => matchesRequestedState(area, original));
  if (!exists) {
    assert.ok(replacements.every(value => areas.some(area => matchesRequestedState(area, value))),
      "The authored house collision footprint changed before the story recipe");
    return navigation;
  }
  return { ...navigation, blockedAreas: areas.flatMap(area => matchesRequestedState(area, original) ? replacements : [area]) };
}

export const storyDialogs = [
  { id: "valbois-story-quest-start", speaker: "Émile", lines: [
    "Avant la promenade, regarde : la porte de ta maison s’ouvre maintenant quand tu interagis avec elle.",
    "Je te montre l’entrée. Ensuite, suis le sentier au nord jusqu’au vieux chêne, puis reviens me raconter !"] },
  { id: "valbois-story-door-locked", speaker: "Voyageur", lines: ["Émile m’attend près du chemin. Je vais lui parler avant de partir."] },
  { id: "valbois-story-door-open", speaker: "Voyageur", lines: ["J’ouvre la porte. Je pourrai entrer me reposer à la maison."] },
  { id: "valbois-story-door-close", speaker: "Voyageur", lines: ["Je referme la porte derrière moi."] },
];

export const guideStagePoints = [
  { id: "guide-start", label: "Le poste d’Émile", x: 12.5, y: 12.5 },
  { id: "guide-crossing", label: "Le carrefour", x: 12.5, y: 10.5 },
  { id: "guide-house-path", label: "Le chemin de la maison", x: 8.5, y: 10.5 },
  { id: "guide-door-side", label: "À côté de l’entrée", x: 8.5, y: 9.5 },
  { id: "guide-return-side", label: "Contourner le visiteur", x: 9.5, y: 9.5 },
  { id: "guide-return-path", label: "Retrouver le chemin", x: 9.5, y: 10.5 },
  { id: "door-focus", label: "L’entrée de la maison", x: 7.5, y: 9.5 },
];

export function guideCinematic(returning = false): JsonRecord {
  const block = (kind: string) => ({ "authoring.kind": "basicBlock", "authoring.source": "cinematic-builder-v0", "authoring.block": kind });
  const move = (id: string, targetId: string, durationMs: number) => ({ id, kind: "actorMove", actorId: "guide",
    targetId, durationMs, metadata: { ...block("actorMove"), "actor.movementMode": "walk", "actor.pathMode": "manual" } });
  return { id: returning ? "valbois-guide-return-cinematic" : "valbois-guide-door-cinematic",
    title: returning ? "Émile revient au village" : "Émile montre la porte", mapId: "first-map", tags: ["Valbois", "3D", "trajet"],
    requiredActors: [{ actorId: "guide", label: "Émile", entityId: "valbois-guide" }],
    movementTargets: [{ targetId: "door-side", label: "À côté de la porte" }, { targetId: "guide-home", label: "Le poste d’Émile" }],
    stageContext: { backdropMode: "projectMap", actorBindings: [{ actorId: "guide", kind: "mapEntity", mapEntityId: "valbois-guide" }],
      initialPlacements: [returning ? { actorId: "guide", kind: "stagePoint", stagePointId: "guide-door-side" }
        : { actorId: "guide", kind: "fromMapEntity" }],
      movementTargetBindings: [{ targetId: "door-side", kind: "stagePoint", sourceId: "guide-door-side" },
        { targetId: "guide-home", kind: "stagePoint", sourceId: "guide-start" }],
      stagePoints: guideStagePoints,
      manualPaths: [returning ? { id: "guide-back", label: "Revenir au carrefour", ownerActorMoveStepId: "guide-walk-back",
        waypointStagePointIds: ["guide-return-side", "guide-return-path", "guide-crossing", "guide-start"] }
        : { id: "guide-to-door", label: "Aller vers la maison", ownerActorMoveStepId: "guide-walk-out",
          waypointStagePointIds: ["guide-crossing", "guide-house-path", "guide-door-side"] }] },
    timeline: { steps: [
      { id: "settle", kind: "wait", durationMs: 250, metadata: block("wait") },
      { id: "look-house", kind: "camera", durationMs: 650, metadata: { ...block("camera"), "camera.mode": "focus", "camera.targetKind": "stagePoint",
        "camera.targetStagePointId": "door-focus", "camera.zoomPreset": "medium" } },
      ...(returning ? [move("guide-walk-back", "guide-home", 3200)] : [move("guide-walk-out", "door-side", 2800),
      { id: "guide-face-door", kind: "actorFace", actorId: "guide", durationMs: 150,
        metadata: { ...block("actorFace"), "actor.direction": "left" } },
      { id: "show-door", kind: "wait", durationMs: 600, metadata: block("wait") },
      { id: "door-marker", kind: "marker", label: "Entrée présentée" }]),
      ...(returning ? [{ id: "guide-face-player", kind: "actorFace", actorId: "guide", durationMs: 150,
        metadata: { ...block("actorFace"), "actor.direction": "right" } }] : []),
      { id: "reset-camera", kind: "camera", durationMs: 500, metadata: { ...block("camera"), "camera.mode": "reset" } },
    ] } };
}

function scene(id: string, name: string, nodes: JsonRecord[], edges: JsonRecord[]): JsonRecord {
  return { id, name, tags: ["Valbois", "3D", "scénario"], graph: { startNodeId: "start",
    nodes: [{ id: "start", kind: "start" }, ...nodes, { id: "end", kind: "end", payload: { kind: "end", outcomePolicy: "progression" } }],
    edges: [{ id: "begin", fromNodeId: "start", fromPortId: "completed", toNodeId: String(nodes[0]!.id), kind: "default" }, ...edges] } };
}

function dialogueNode(id: string): JsonRecord {
  return { id: "dialogue", kind: "yarnDialogue", payload: { kind: "yarnDialogue", dialogueId: id, yarnNodeName: "Accueil" } };
}

function edge(id: string, fromNodeId: string, toNodeId: string, kind = "default", fromPortId = "completed"): JsonRecord {
  return { id, fromNodeId, fromPortId, toNodeId, kind };
}

export function storyScenes(): JsonRecord[] {
  const quest = scene("valbois-quest-start-scene", "La promenade et la porte d’Émile", [
    dialogueNode("valbois-story-quest-start"),
    { id: "guide-route", kind: "cinematic", payload: { kind: "cinematic", cinematicId: "valbois-guide-door-cinematic" } },
    { id: "accept", kind: "action", payload: { kind: "action", consequence: { kind: "setFact", factId: questIds.accepted, value: true } } },
  ], [edge("walk", "dialogue", "guide-route"), edge("accepted", "guide-route", "accept", "cinematicCompleted"),
    edge("finish", "accept", "end", "actionCompleted")]);
  const locked = scene("valbois-door-locked-scene", "Avant la promenade", [dialogueNode("valbois-story-door-locked")],
    [edge("finish", "dialogue", "end")]);
  const animation = (open: boolean): JsonRecord => {
    const id = open ? "valbois-door-open-scene" : "valbois-door-close-scene";
    const result = scene(id, open ? "Ouvrir la porte" : "Fermer la porte", [
      dialogueNode(open ? "valbois-story-door-open" : "valbois-story-door-close"),
      { id: "door-animation", kind: "action", payload: { kind: "action", interactiveCommand: { kind: "playModelAnimation",
        mapId: storyDoor.mapId, instanceId: storyDoor.instanceId, animationIndex: open ? 0 : 1, speed: .25,
        blocksMovementAfter: !open } } },
      { id: "persist-door", kind: "action", payload: { kind: "action", consequence: { kind: "setFact", factId: storyDoor.fact.id, value: open } } },
      { id: "retry", kind: "end", payload: { kind: "end", outcomePolicy: "retryable" } },
    ], [edge("animate", "dialogue", "door-animation"), edge("persist", "door-animation", "persist-door", "actionCompleted"),
      edge("done", "persist-door", "end", "actionCompleted"),
      edge("blocked", "door-animation", "retry", "actionCompleted", "blocked"),
      edge("cancelled", "door-animation", "retry", "actionCompleted", "cancelled")]);
    return result;
  };
  const reward = structuredClone(questScenes().find(value => value.id === "valbois-reward-scene")!);
  const rewardGraph = record(reward.graph), rewardNodes = rewardGraph.nodes as JsonRecord[], rewardEdges = rewardGraph.edges as JsonRecord[];
  rewardNodes.splice(2, 0, { id: "guide-return", kind: "cinematic", payload: { kind: "cinematic", cinematicId: "valbois-guide-return-cinematic" } });
  rewardEdges.find(value => value.fromNodeId === "dialogue")!.toNodeId = "guide-return";
  rewardEdges.push(edge("return-completed", "guide-return", "effect-0", "cinematicCompleted"));
  return [quest, locked, animation(true), animation(false), reward];
}

export function storyEvents(): JsonRecord[] {
  const condition = (factId: string, expectedValue: boolean) => ({ kind: "fact", factId, expectedValue });
  return [
    { name: "Avant d’ouvrir la maison", sceneId: "valbois-door-locked-scene", conditions: [condition(questIds.accepted, false)] },
    { name: "Ouvrir la maison", sceneId: "valbois-door-open-scene", conditions: [condition(questIds.accepted, true), condition(storyDoor.fact.id, false)] },
    { name: "Fermer la maison", sceneId: "valbois-door-close-scene", conditions: [condition(questIds.accepted, true), condition(storyDoor.fact.id, true)] },
  ].map((value, index) => ({ state: "draft", draft: { ...value,
    id: `evt_019a61a0-0000-7000-8000-${String(index + 1).padStart(12, "0")}`,
    source: { kind: "modelInteract", mapId: storyDoor.mapId, instanceId: storyDoor.instanceId },
    reusePolicy: "reusable", priority: 30, order: 30 + index } }));
}

export function storyDefinitions(): JsonRecord {
  return { door: storyDoor, dialogues: storyDialogs, cinematics: [guideCinematic(), guideCinematic(true)], scenes: storyScenes(), events: storyEvents() };
}

class CanonicalFailure extends Error {
  constructor(readonly domainCode: string, data: JsonRecord) { super(JSON.stringify(data)); }
}

export async function authorValboisStory(args: string[]): Promise<void> {
  if (args.includes("--definitions")) { process.stdout.write(`${JSON.stringify(storyDefinitions())}\n`); return; }
  const option = (name: string, fallback: string) => { const index = args.indexOf(name); return index < 0 ? fallback : args[index + 1]!; };
  const root = await realpath(option("--project", "/Users/karim/Desktop/pokeMap Project/avelune_3d_village_demo"));
  assert.equal(root.split("/").at(-1), "avelune_3d_village_demo");
  const exportOnly = args.includes("--export-only"), inspect = args.includes("--inspect");
  const exportPath = args.includes("--export") ? resolve(option("--export", "")) : undefined;
  const finalPath = exportPath ? join(root, "exports/Valbois-demo.avelunegame") : undefined;
  if (exportPath) assert.equal(resolve(exportPath, ".."), join(root, "exports"));
  const client = new Client({ name: "valbois-story-author", version: "0.2.0" });
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--export-root", join(root, "exports"), "--authoring-timeout-ms", "120000"],
    cwd: resolve("."), stderr: "pipe" });
  const lastCalls = new Map<string, number>();
  const appliedActions: JsonRecord[] = [];
  let projectHandle = "", workspaceHandle = "", count = 0, backupPath: string | undefined;
  let descriptors = new Map<string, JsonRecord>();
  async function call(name: string, parameters: JsonRecord = {}): Promise<JsonRecord> {
    const wait = 1100 - (Date.now() - (lastCalls.get(name) ?? 0));
    if (wait > 0) await delay(wait);
    lastCalls.set(name, Date.now());
    const response = await client.callTool({ name, arguments: parameters });
    const envelope = record(response.structuredContent);
    if (envelope.ok !== true) { const error = record(envelope.error); throw new CanonicalFailure(String(error.domainCode ?? error.code), error); }
    return record(envelope.data);
  }
  async function query(kind: string, id: string): Promise<JsonRecord> {
    return call("pokemap_query", { projectHandle, resourceKind: kind, operation: "get", ids: [id], view: "detail" });
  }
  async function project(): Promise<JsonRecord> { return record(((await query("project", "project")).items as unknown[])[0]); }
  async function map(id: string): Promise<JsonRecord> { return record(((await query("map", id)).items as unknown[])[0]); }
  async function mutate(actionId: string, parameters: JsonRecord): Promise<void> {
    process.stderr.write(`Valbois story: planning ${actionId}\n`);
    const descriptor = descriptors.get(actionId); assert.ok(descriptor, `Undiscovered action ${actionId}`);
    const snapshot = await query("project", "project"), id = randomUUID();
    const plan = await call("pokemap_plan", { projectHandle, request: { requestId: id, idempotencyKey: id, workspaceHandle,
      actionId, actionVersion: descriptor.version, expectedRevision: snapshot.snapshotRevision, parameters } });
    if (plan.applicable === false && plan.nonApplicableReason === "no_changes") return;
    assert.equal(plan.applicable, true, JSON.stringify(plan));
    if (!backupPath) {
      backupPath = join("/private/tmp", `valbois-story-backup-${Date.now()}-${randomUUID()}`);
      await mkdir(backupPath);
      await cp(root, join(backupPath, "avelune_3d_village_demo"), { recursive: true });
      assert.equal((await query("project", "project")).snapshotRevision, snapshot.snapshotRevision,
        "The project changed during the immutable pre-story backup");
      await writeFile(join(backupPath, "receipt.json"), JSON.stringify({ projectRoot: root, snapshotRevision: snapshot.snapshotRevision }, null, 2));
    }
    let confirmationToken: string | undefined;
    if (["high", "destructive"].includes(String(descriptor.riskLevel)))
      confirmationToken = String((await call("pokemap_apply", { operation: "confirm", projectHandle, planId: plan.planId })).confirmationToken);
    const applied = await call("pokemap_apply", { operation: "apply", projectHandle, planId: plan.planId, operationId: id,
      ...(confirmationToken ? { confirmationToken } : {}) });
    assert.equal(record(applied.receipt).status, "applied", JSON.stringify(applied));
    appliedActions.push({ actionId, planId: plan.planId, beforeRevision: snapshot.snapshotRevision, receipt: applied.receipt });
    count++;
  }
  try {
    await client.connect(transport);
    const catalog = await call("pokemap_describe");
    descriptors = new Map((catalog.mutationActions as JsonRecord[]).map(value => [String(value.id), value]));
    for (const id of ["model3d.configure", "map3d.instance.upsert", "map3d.navigation.configure", "warp.update_pair_apply",
      "fact.create", "fact.update", "dialogue.create", "dialogue.update", "cinematic.upsert", "scene.upsert",
      "event_v2.record_upsert", "event_v2.publish", "event_v2.activate"]) assert.ok(descriptors.has(id), id);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    projectHandle = String(opened.projectHandle); workspaceHandle = String(opened.workspaceHandle);
    const initial = await query("project", "project"), manifest = record((initial.items as unknown[])[0]);
    assert.equal(manifest.name, "Valbois — Voyage en 3D"); assert.equal(record(manifest.settings).dimension, "threeD");
    const expectedRevision = option("--expected-revision", String(initial.snapshotRevision));
    assert.equal(initial.snapshotRevision, expectedRevision, "Valbois changed before the story recipe");
    const doorModel = (manifest.models3d as JsonRecord[]).find(value => value.id === storyDoor.modelId)!;
    assert.ok(doorModel);
    const clips = record(doorModel.inspection).animations as JsonRecord[];
    assert.ok(clips.some(clip => clip.index === 0 && clip.name === "door_op"));
    assert.ok(clips.some(clip => clip.index === 1 && clip.name === "door_cl"));
    if (inspect) {
      process.stdout.write(`${JSON.stringify({ projectRoot: root, revision: initial.snapshotRevision, doorModel, definitions: storyDefinitions() })}\n`);
      return;
    }
    if (!exportOnly) {
      let current = await project();
      if (!matchesRequestedState(doorModel.pivot, storyDoor.pivot)) await mutate("model3d.configure", { modelId: storyDoor.modelId, pivot: storyDoor.pivot });
      let village = await map("first-map"), spatial = record(village.spatialScene);
      const navigation = withStoryDoorNavigation(record(spatial.navigation));
      if (!matchesRequestedState(spatial.navigation, navigation)) await mutate("map3d.navigation.configure", { mapId: "first-map", navigation });
      const warp = (village.warps as JsonRecord[]).find(value => value.id === "home-door")!;
      if (!matchesRequestedState(warp, storyDoor.warp)) await mutate("warp.update_pair_apply", { mapId: "first-map", warpId: "home-door", reciprocalWarpId: "home-exit", warp: storyDoor.warp });
      village = await map("first-map");
      if (!matchesRequestedState((record(village.spatialScene).instances as JsonRecord[]).find(value => value.id === storyDoor.instanceId), storyDoor.instance))
        await mutate("map3d.instance.upsert", { mapId: "first-map", instance: storyDoor.instance });
      current = await project();
      const fact = (current.facts as JsonRecord[]).find(value => value.id === storyDoor.fact.id);
      if (!fact) await mutate("fact.create", { fact: { ...storyDoor.fact, label: storyDoor.fact.id.slice(5).replaceAll("_", " ") } });
      if (!fact || !matchesRequestedState(fact, storyDoor.fact)) await mutate("fact.update", { fact: storyDoor.fact });
      for (const dialogue of storyDialogs) {
        current = await project();
        const entry = { id: dialogue.id, name: dialogue.id, relativePath: `dialogues/${dialogue.id}.yarn`, defaultStartNode: "Accueil" };
        const source = `title: Accueil\n---\n${dialogue.lines.map(line => `${dialogue.speaker}: ${line}`).join("\n")}\n===\n`;
        const exists = (current.dialogues as JsonRecord[]).some(value => value.id === dialogue.id);
        if (exists && await readFile(join(root, entry.relativePath), "utf8") === source) continue;
        await mutate(exists ? "dialogue.update" : "dialogue.create", { entry, source });
      }
      for (const cinematic of [guideCinematic(), guideCinematic(true)]) {
        current = await project();
        if (!matchesRequestedState((current.cinematics as JsonRecord[]).find(value => value.id === cinematic.id), cinematic)) await mutate("cinematic.upsert", { cinematic });
      }
      for (const value of storyScenes()) {
        current = await project();
        if (!matchesRequestedState((current.scenes as JsonRecord[]).find(existing => existing.id === value.id), value)) await mutate("scene.upsert", { scene: value });
      }
      for (const event of storyEvents()) {
        current = await project();
        const draft = record(event.draft), id = String(draft.id);
        const existing = (record(current.eventRegistry).records as JsonRecord[]).find(value => record(value.definition ?? value.draft).id === id);
        if (existing?.state === "configured" && existing.enabled === true && matchesRequestedState(existing.definition, draft)) continue;
        await mutate("event_v2.record_upsert", { record: event });
        await mutate("event_v2.publish", { eventId: id });
        await mutate("event_v2.activate", { eventId: id });
      }
    }
    const finalSnapshot = await query("project", "project"), finalManifest = record((finalSnapshot.items as unknown[])[0]);
    assert.equal(record(finalManifest.eventRegistry).mode, "v2Only");
    assert.ok([guideCinematic(), guideCinematic(true)].every(cinematic => (finalManifest.cinematics as JsonRecord[]).some(value => matchesRequestedState(value, cinematic))));
    assert.ok(storyScenes().every(value => (finalManifest.scenes as JsonRecord[]).some(existing => matchesRequestedState(existing, value))));
    const validation = await call("pokemap_validate", { projectHandle });
    assert.equal(validation.valid, true, JSON.stringify(validation));
    let exported: JsonRecord = {};
    if (exportPath) {
      const tools = await client.listTools();
      assert.match(tools.tools.find(value => value.name === "pokemap_game_export")!.description!, /map3d\.story@1/);
      const profile = await promisify(execFile)(process.env.POKEMAP_TEST_DART ?? "dart", [
        `--packages=${resolve("../../packages/map_authoring/.dart_tool/package_config.json")}`,
        resolve("tool/configure_valbois_story_export.dart"), root]);
      const exportReceipt = await call("pokemap_game_export", { projectHandle, mode: "localTest", outputPath: exportPath });
      const expectedPrevious = option("--replace-export-sha256", "");
      exported = { exportProfileReceipt: JSON.parse(profile.stdout), exportReceipt,
        ...(expectedPrevious ? { exportPromotion: await promoteValidatedValboisExport(exportPath, finalPath!, expectedPrevious, exportReceipt) } : {}) };
    }
    const receipt = { projectRoot: root, canonicalActions: count, backupPath, initialRevision: initial.snapshotRevision,
      finalRevision: finalSnapshot.snapshotRevision, validation, ...exported, gameVersion: "0.2.0", appliedActions, definitions: storyDefinitions() };
    const receiptPath = option("--receipt", `/private/tmp/valbois-story-${Date.now()}.receipt.json`);
    await writeFile(receiptPath, JSON.stringify(receipt, null, 2));
    process.stdout.write(`${JSON.stringify({ ...receipt, definitions: undefined, appliedActions: undefined, receiptPath })}\n`);
  } finally {
    if (projectHandle) await call("pokemap_workspace", { operation: "close", workspaceHandle }).catch(() => undefined);
    await client.close();
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href)
  authorValboisStory(process.argv.slice(2)).catch(error => { process.stderr.write(`${error}\n`); process.exitCode = 1; });

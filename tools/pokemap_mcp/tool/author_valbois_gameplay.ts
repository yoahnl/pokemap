import assert from "node:assert/strict";
import { randomUUID, createHash } from "node:crypto";
import { lstat, readFile, realpath, rename } from "node:fs/promises";
import { basename, dirname, join, resolve } from "node:path";
import { pathToFileURL } from "node:url";
import { isDeepStrictEqual } from "node:util";
import { setTimeout as delay } from "node:timers/promises";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";
import { actors, encounterAreas, pathPresetForMap, worldPlan } from "./author_valbois_demo.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

export function matchesRequestedState(actual: unknown, expected: unknown): boolean {
  if (Array.isArray(expected)) return Array.isArray(actual) && actual.length === expected.length &&
    expected.every((value, index) => matchesRequestedState(actual[index], value));
  if (expected && typeof expected === "object") return Boolean(actual && typeof actual === "object" && !Array.isArray(actual)) &&
    Object.entries(record(expected)).every(([key, value]) => matchesRequestedState(record(actual)[key], value));
  return Object.is(actual, expected);
}

export async function promoteValidatedValboisExport(stagedPath: string, finalPath: string,
  expectedPreviousSha256: string, exportReceipt: JsonRecord): Promise<JsonRecord> {
  assert.equal(dirname(stagedPath), dirname(finalPath));
  assert.equal(basename(finalPath), "Valbois-demo.avelunegame");
  assert.match(expectedPreviousSha256, /^[a-f0-9]{64}$/);
  assert.ok((await lstat(stagedPath)).isFile());
  assert.ok((await lstat(finalPath)).isFile());
  const previousSha256 = createHash("sha256").update(await readFile(finalPath)).digest("hex");
  const sha256 = createHash("sha256").update(await readFile(stagedPath)).digest("hex");
  assert.equal(previousSha256, expectedPreviousSha256, "The previous final package changed before replacement");
  assert.equal(exportReceipt.outputPath, stagedPath);
  assert.equal(sha256, exportReceipt.sha256, "The canonically exported package changed before replacement");
  await rename(stagedPath, finalPath);
  assert.equal(createHash("sha256").update(await readFile(finalPath)).digest("hex"), sha256);
  return { canonicalOutputPath: stagedPath, outputPath: finalPath, sha256, previousSha256, atomicReplacement: true };
}

export const questFacts = [
  { id: "fact_valbois_quest_accepted", label: "La promenade d’Émile a commencé" },
  { id: "fact_valbois_clearing_visited", label: "La clairière du vieux chêne a été explorée" },
  { id: "fact_valbois_quest_rewarded", label: "La récompense d’Émile a été reçue" },
  { id: "fact_valbois_potion_picked", label: "La Potion de la forêt a été ramassée" },
].map(fact => ({ ...fact, category: "Valbois", defaultValue: false, tags: ["Valbois", "démo"] }));

export const questIds = {
  accepted: questFacts[0]!.id, visited: questFacts[1]!.id,
  rewarded: questFacts[2]!.id, picked: questFacts[3]!.id,
};

export const valboisSigns = [
  { mapId: "first-map", id: "valbois-village-sign", x: 17, y: 11, title: "Valbois", text: "Nord : forêt et vieux chêne. Est : prairie des rencontres. Le point de soin est dans la maison à droite." },
  { mapId: "valbois-meadow", id: "valbois-meadow-sign", x: 4, y: 9, title: "Prairie", text: "Des Roucool et des Rattata se cachent dans les hautes herbes. Affaiblis-les puis utilise une Poké Ball depuis le sac en combat." },
  { mapId: "valbois-forest", id: "valbois-forest-sign", x: 13, y: 20, title: "Forêt de Valbois", text: "Le sentier mène à la clairière du vieux chêne. Un petit détour à droite permet parfois de trouver un objet." },
];

export const valboisInteriorMetadata = [
  { mapId: "valbois-home", role: "interior", isIndoor: true },
  { mapId: "valbois-care", role: "interior", isIndoor: true },
];

export const valboisOrdinaryInteractions = [
  ...actors.filter(actor => !["valbois-guide", "valbois-healer", "valbois-parent"].includes(actor.id))
    .map(actor => ({ mapId: actor.mapId, entityId: actor.id, name: `Parler à ${actor.name}`,
      sceneId: `${actor.id}-dialogue-scene`, dialogueId: `${actor.id}-welcome` })),
  ...valboisSigns.map(sign => ({ mapId: sign.mapId, entityId: sign.id, name: `Lire ${sign.title}`,
    sceneId: `${sign.id}-scene`, dialogueId: `${sign.id}-dialogue` })),
];

export const valboisDialogs = [
  { id: "valbois-quest-start", speaker: "Émile", lines: ["Bulbizarre a l’air impatient de partir avec toi !", "Va découvrir le vieux chêne dans la clairière, tout au nord de la forêt. Reviens ensuite me raconter ta promenade."] },
  { id: "valbois-quest-reminder", speaker: "Émile", lines: ["Suis le sentier au nord du village jusqu’au vieux chêne. Tu peux t’entraîner dans la prairie et te soigner ici avant de partir."] },
  { id: "valbois-quest-ready", speaker: "Émile", lines: ["Tu as trouvé le vieux chêne ? Viens me raconter !"] },
  { id: "valbois-quest-reward", speaker: "Émile", lines: ["Bravo pour cette première promenade !", "Voici 5 Poké Balls, 2 Potions et 300 pièces pour la suite. La prairie et la forêt t’attendent encore."] },
  { id: "valbois-quest-finished", speaker: "Émile", lines: ["Valbois est maintenant un peu plus chez toi. Prends soin de ton équipe et reviens quand tu veux."] },
  { id: "valbois-clearing-arrival", speaker: "Éloi", lines: ["Bienvenue près du vieux chêne. Tu as trouvé la clairière !", "Émile sera content de te revoir au village. Le sentier vers le sud te ramène chez lui."] },
  { id: "valbois-pickup-dialogue", speaker: "Voyageur", lines: ["Une Potion était cachée près du sentier ! Elle a été ajoutée au sac."] },
  { id: "valbois-heal-dialogue", speaker: "Infirmière", lines: ["Bienvenue au point de soin de Valbois. Confie-moi ton équipe si tu veux faire une pause."] },
  { id: "valbois-home-rest", speaker: "Maman", lines: ["Une petite pause fait toujours du bien. Ton équipe peut se reposer ici."] },
  ...valboisSigns.map(sign => ({ id: `${sign.id}-dialogue`, speaker: sign.title, lines: [sign.text] })),
  ...actors.filter(actor => valboisOrdinaryInteractions.some(interaction => interaction.entityId === actor.id))
    .map(actor => ({ id: `${actor.id}-welcome`, speaker: actor.name, lines: actor.lines })),
];

export function linearScene(id: string, name: string, dialogueId: string, consequences: JsonRecord[]): JsonRecord {
  const nodes: JsonRecord[] = [{ id: "start", kind: "start" },
    { id: "dialogue", kind: "yarnDialogue", payload: { kind: "yarnDialogue", dialogueId, yarnNodeName: "Accueil" } },
    ...consequences.map((consequence, index) => ({ id: `effect-${index}`, kind: "action", payload: { kind: "action", consequence } })),
    { id: "end", kind: "end", payload: { kind: "end", outcomePolicy: "progression" } }];
  return { id, name, tags: ["Valbois", "démo"], graph: { startNodeId: "start", nodes,
    edges: nodes.slice(0, -1).map((node, index) => ({ id: `edge-${index}`, fromNodeId: node.id,
      fromPortId: "completed", toNodeId: nodes[index + 1]!.id,
      kind: node.kind === "action" ? "actionCompleted" : "default" })) } };
}

export function questScenes(): JsonRecord[] {
  const fact = (factId: string) => ({ kind: "setFact", factId, value: true });
  const healing = linearScene("valbois-heal-scene", "Soigner l’équipe", "valbois-heal-dialogue", [{ kind: "healParty" }]);
  const healGraph = record(healing.graph);
  (healGraph.nodes as JsonRecord[]).find(node => node.id === "effect-0")!.payload = {
    kind: "action", interactiveCommand: { kind: "openHeal", requiresConfirmation: true } };
  (healGraph.edges as JsonRecord[]).push({ id: "heal-cancelled", fromNodeId: "effect-0", fromPortId: "cancelled", toNodeId: "end", kind: "actionCompleted" });
  return [
    linearScene("valbois-quest-start-scene", "La promenade d’Émile", "valbois-quest-start", [fact(questIds.accepted)]),
    linearScene("valbois-clearing-scene", "Découvrir le vieux chêne", "valbois-clearing-arrival", [fact(questIds.visited)]),
    linearScene("valbois-pickup-scene", "Trouver une Potion", "valbois-pickup-dialogue", [
      { kind: "giveItem", itemId: "potion", quantity: 1 }, fact(questIds.picked)]),
    linearScene("valbois-reward-scene", "La récompense d’Émile", "valbois-quest-reward", [
      { kind: "giveItem", itemId: "poke_ball", quantity: 5 }, { kind: "giveItem", itemId: "potion", quantity: 2 },
      { kind: "giveMoney", amount: 300 }, fact(questIds.rewarded)]),
    healing,
    linearScene("valbois-home-rest-scene", "Se reposer à la maison", "valbois-home-rest", [{ kind: "healParty" }]),
    linearScene("valbois-quest-reminder-scene", "La promenade continue", "valbois-quest-reminder", []),
    linearScene("valbois-quest-finished-scene", "Après la promenade", "valbois-quest-finished", []),
    ...valboisOrdinaryInteractions.map(interaction => linearScene(interaction.sceneId, interaction.name, interaction.dialogueId, [])),
  ];
}

export function questEvents(): JsonRecord[] {
  const condition = (factId: string, expectedValue: boolean) => ({ kind: "fact", factId, expectedValue });
  const interaction = (mapId: string, entityId: string) => ({ kind: "entityInteract", mapId, entityId });
  const definitions = [
    { name: "Accepter la promenade", source: interaction("first-map", "valbois-guide"), sceneId: "valbois-quest-start-scene", conditions: [condition(questIds.accepted, false), condition(questIds.rewarded, false)] },
    { name: "Explorer la clairière", source: { kind: "mapEnter", mapId: "valbois-clearing" }, sceneId: "valbois-clearing-scene", conditions: [condition(questIds.accepted, true), condition(questIds.visited, false)] },
    { name: "Ramasser la Potion", source: interaction("valbois-forest", "valbois-forest-pickup"), sceneId: "valbois-pickup-scene", conditions: [condition(questIds.picked, false)] },
    { name: "Recevoir la récompense", source: interaction("first-map", "valbois-guide"), sceneId: "valbois-reward-scene", conditions: [condition(questIds.accepted, true), condition(questIds.visited, true), condition(questIds.rewarded, false)] },
    { name: "Point de soin", source: interaction("valbois-care", "valbois-healer"), sceneId: "valbois-heal-scene", conditions: [] },
    { name: "Repos à la maison", source: interaction("valbois-home", "valbois-parent"), sceneId: "valbois-home-rest-scene", conditions: [] },
    { name: "Rappeler la promenade", source: interaction("first-map", "valbois-guide"), sceneId: "valbois-quest-reminder-scene",
      conditions: [condition(questIds.accepted, true), condition(questIds.visited, false), condition(questIds.rewarded, false)] },
    { name: "Discuter après la promenade", source: interaction("first-map", "valbois-guide"), sceneId: "valbois-quest-finished-scene",
      conditions: [condition(questIds.rewarded, true)] },
    ...valboisOrdinaryInteractions.map(value => ({ name: value.name, source: interaction(value.mapId, value.entityId),
      sceneId: value.sceneId, conditions: [] })),
  ];
  return definitions.map((definition, index) => ({ state: "draft", draft: {
    ...definition, id: `evt_019a6190-0000-7000-8000-${String(index + 1).padStart(12, "0")}`,
    reusePolicy: index < 4 ? "oneShot" : "reusable", priority: 20, order: index } }));
}

export const valboisItems: JsonRecord[] = [
  { id: "potion", displayName: "Potion", pocketId: "medicine", description: "Restaure 20 PV à un Pokémon.", buyPrice: 200, sellPrice: 100,
    uses: [{ contexts: ["overworld", "battle"], target: "party_member", consumption: "on_applied", effect: { kind: "heal_hp", mode: "flat", amount: 20 } }] },
  { id: "poke_ball", displayName: "Poké Ball", pocketId: "balls", description: "Permet de capturer un Pokémon sauvage.", buyPrice: 200, sellPrice: 100,
    capture: { rateNumerator: 1, rateDenominator: 1, allowedEncounterKinds: ["walk"], animationSpritePath: "assets/items/poke_ball/capture.png" } },
];

export const encounterTables: JsonRecord[] = [
  { id: "valbois-meadow-walk", name: "Prairie de Valbois", encounterKind: "walk", chancePerStep: .18,
    entries: [{ speciesId: "pidgey", minLevel: 2, maxLevel: 4, weight: 6 }, { speciesId: "rattata", minLevel: 2, maxLevel: 4, weight: 4 }] },
  { id: "valbois-forest-walk", name: "Forêt de Valbois", encounterKind: "walk", chancePerStep: .16,
    entries: [{ speciesId: "caterpie", minLevel: 2, maxLevel: 4, weight: 7 }, { speciesId: "pidgey", minLevel: 3, maxLevel: 4, weight: 3 }] },
];

export function newGameDefinition(): JsonRecord {
  return { enabled: true, startMapId: "first-map", startSpawnId: "first-map-spawn", playerName: "Voyageur",
    playerAvatarCharacterIds: ["voyageur-psdk"], playerPronounSet: "neutral", startingMoney: 500,
    initialBag: [{ itemId: "poke_ball", quantity: 8 }, { itemId: "potion", quantity: 3 }],
    initialParty: [{ individualId: "valbois-bulbasaur-starter", speciesId: "bulbasaur", formId: "base", natureId: "hardy", abilityId: "overgrow",
      gender: "male", level: 5, ivs: { hp: 12, attack: 12, defense: 12, specialAttack: 12, specialDefense: 12, speed: 12 },
      knownMoveIds: ["tackle", "growl"], currentPpByMoveId: { tackle: 35, growl: 40 }, currentHp: 20, friendship: 70 }],
    initialFacts: {}, starterOptions: [], preSessionSceneId: "valbois-intro" };
}

export const pickupHiddenRule: JsonRecord = { id: "world_rule_valbois_pickup_hidden", label: "La Potion ramassée disparaît", enabled: true,
  source: { kind: "fact", sourceId: questIds.picked, predicate: "isTrue" },
  target: { kind: "mapEntity", mapId: "valbois-forest", entityId: "valbois-forest-pickup" }, effect: { kind: "entityHidden" } };

export const valboisWindmill = {
  mapId: "first-map", modelId: "bw2-windmill", name: "Moulin de Valbois · pales animées NB2",
  sourceSha256: "c0afb1fca68ce9ef0a776f7cad2acc1c89b4028a614ae1145655faabab960d46",
  pivot: { x: 0, y: .25, z: 0 },
  instance: { id: "village-windmill", modelId: "bw2-windmill", position: { x: 26.5, y: 0, z: 5.5 },
    rotationDegrees: 0, scale: 1, animationIndex: 0, animationLoop: true, animationSpeed: 1, blocksMovement: false },
  buildingBounds: [-2.25, .25, -2.25, 2.25, 7, 2],
  blockedArea: { x: 24.25, z: 3.25, width: 4.5, depth: 4.25 },
};

export function withValboisWindmillNavigation(navigation: JsonRecord): JsonRecord {
  const blockedAreas = navigation.blockedAreas as JsonRecord[];
  return { ...navigation, blockedAreas: blockedAreas.some(area => matchesRequestedState(area, valboisWindmill.blockedArea))
    ? blockedAreas : [...blockedAreas, valboisWindmill.blockedArea] };
}

class CanonicalFailure extends Error {
  constructor(readonly domainCode: string, data: JsonRecord) { super(JSON.stringify(data)); }
}

export async function authorValboisGameplay(args: string[]): Promise<void> {
  const option = (name: string, fallback: string) => { const index = args.indexOf(name); return index < 0 ? fallback : args[index + 1]!; };
  const projectRoot = await realpath(option("--project", "/Users/karim/Desktop/pokeMap Project/avelune_3d_village_demo"));
  assert.equal(projectRoot.split("/").at(-1), "avelune_3d_village_demo");
  const exportOnly = args.includes("--export-only");
  const metadataOnly = args.includes("--metadata-only");
  const actorPlacementOnly = args.includes("--actor-placement-only");
  const provisional = args.includes("--provisional");
  const replaceExport = args.includes("--replace-export");
  const expectedPreviousExportSha256 = option("--expected-export-sha256", "");
  if (replaceExport) {
    assert.equal(provisional, false);
    assert.match(expectedPreviousExportSha256, /^[a-f0-9]{64}$/);
  }
  const assetRoot = exportOnly || metadataOnly || actorPlacementOnly ? projectRoot : await realpath(option("--assets", "/private/tmp/valbois-gameplay-assets-20261008"));
  const finalExportPath = args.includes("--export") || exportOnly || replaceExport ? join(projectRoot, "exports", provisional ? "Valbois-demo-provisoire.avelunegame" : "Valbois-demo.avelunegame") : undefined;
  const exportPath = replaceExport ? join(projectRoot, "exports", `Valbois-demo-${randomUUID()}.avelunegame`) : finalExportPath;
  const doorRoot = args.includes("--door-assets") ? await realpath(option("--door-assets", "")) : undefined;
  const windmillRoot = args.includes("--windmill-assets") ? await realpath(option("--windmill-assets", "")) : undefined;
  const pack = exportOnly || metadataOnly || actorPlacementOnly ? { assets: [] } : record(JSON.parse(await readFile(join(assetRoot, "valbois_pokemon_pack.json"), "utf8")));
  const assets = pack.assets as JsonRecord[];
  for (const asset of assets) assert.equal(createHash("sha256").update(await readFile(join(assetRoot, String(asset.file)))).digest("hex"), asset.sha256);
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", projectRoot, "--artifact-root", assetRoot,
      ...(doorRoot ? ["--artifact-root", doorRoot] : []), ...(windmillRoot ? ["--artifact-root", windmillRoot] : []),
      ...(exportPath ? ["--export-root", projectRoot] : []),
      "--authoring-timeout-ms", "120000"], cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "avelune-valbois-gameplay-author", version: "1.0.0" });
  let projectHandle = "", workspaceHandle = "", count = 0;
  const lastCalls = new Map<string, number>();
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
  async function query(kind: string, id: string): Promise<JsonRecord> { return call("pokemap_query", { projectHandle, resourceKind: kind, operation: "get", ids: [id], view: "detail" }); }
  async function project(): Promise<JsonRecord> { return record(((await query("project", "project")).items as unknown[])[0]); }
  async function map(id: string): Promise<JsonRecord> { return record(((await query("map", id)).items as unknown[])[0]); }
  async function mutate(actionId: string, parameters: JsonRecord): Promise<void> {
    assert.ok(descriptors.has(actionId), `Undiscovered action ${actionId}`);
    const snapshot = await query("project", "project");
    const id = randomUUID();
    let plan: JsonRecord;
    try { plan = await call("pokemap_plan", { projectHandle, request: { requestId: id, idempotencyKey: id,
      workspaceHandle, actionId, actionVersion: 1, expectedRevision: snapshot.snapshotRevision, parameters } }); }
    catch (error) { if (error instanceof CanonicalFailure && error.domainCode.endsWith(".no_change")) return; throw error; }
    if (plan.applicable === false && plan.nonApplicableReason === "no_changes") return;
    let confirmationToken: string | undefined;
    if (["high", "destructive"].includes(String(descriptors.get(actionId)!.riskLevel))) {
      confirmationToken = String((await call("pokemap_apply", { operation: "confirm", projectHandle, planId: plan.planId })).confirmationToken);
    }
    const applied = await call("pokemap_apply", { operation: "apply", projectHandle, planId: plan.planId, operationId: id,
      ...(confirmationToken ? { confirmationToken } : {}) });
    assert.equal(record(applied.receipt).status, "applied", JSON.stringify(applied));
    if (++count % 15 === 0) process.stderr.write(`Valbois gameplay: ${count} canonical actions applied (${actionId})\n`);
  }
  async function stage(file: string, declaredMediaType: string): Promise<string> {
    return String((await call("pokemap_artifact_stage", { sourcePath: join(assetRoot, file), declaredMediaType })).artifactHandle);
  }
  async function writeDocument(actionId: string, parameters: JsonRecord): Promise<void> {
    const path = join(projectRoot, String(parameters.relativePath));
    let before: Buffer | undefined;
    try { before = await readFile(path); } catch (error) { if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error; }
    if (before && isDeepStrictEqual(JSON.parse(before.toString("utf8")), parameters.document)) return;
    await mutate(actionId, { ...parameters, ...(before ? { beforeBytesBase64: before.toString("base64") } : {}) });
  }
  async function exportValidatedProject(validation: JsonRecord): Promise<JsonRecord> {
    assert.ok(exportPath);
    assert.equal(validation.valid, true, JSON.stringify(validation));
    const profile = await promisify(execFile)(process.env.POKEMAP_TEST_DART ?? "dart", [
      `--packages=${resolve("../../packages/map_authoring/.dart_tool/package_config.json")}`,
      resolve("tool/configure_valbois_export.dart"), projectRoot]);
    const exportProfileReceipt = record(JSON.parse(profile.stdout));
    const exportReceipt = await call("pokemap_game_export", { projectHandle, mode: "localTest", outputPath: exportPath });
    const exportPromotion = replaceExport ? await promoteValidatedValboisExport(exportPath, finalExportPath!, expectedPreviousExportSha256, exportReceipt) : undefined;
    return { exportReceipt, exportProfileReceipt, ...(exportPromotion ? { exportPromotion } : {}), finality: !provisional };
  }
  async function ensureInteriorMetadata(readOnly = false): Promise<void> {
    const manifest = await project();
    for (const metadata of valboisInteriorMetadata) {
      const entry = (manifest.maps as JsonRecord[]).find(value => value.id === metadata.mapId)!;
      const content = await map(metadata.mapId);
      if (entry.role === metadata.role && record(content.mapMetadata).isIndoor === metadata.isIndoor) continue;
      assert.equal(readOnly, false, `Interior metadata must be authored before export: ${metadata.mapId}`);
      await mutate("map.update_metadata", metadata);
    }
  }
  async function ensureGardenerPlacement(): Promise<void> {
    const actor = actors.find(value => value.id === "valbois-gardener")!;
    const gardener = ((await map(actor.mapId)).entities as JsonRecord[]).find(value => value.id === actor.id)!;
    assert.equal(gardener.kind, "npc");
    if (!matchesRequestedState(gardener.pos, { x: actor.x, y: actor.y }))
      await mutate("entity.move", { mapId: actor.mapId, entityId: actor.id, x: actor.x, y: actor.y });
  }
  try {
    await client.connect(transport);
    const catalog = await call("pokemap_describe");
    if (exportPath) {
      assert.ok((catalog.commands as JsonRecord[]).some(command => command.id === "game_export"));
      const tools = await client.listTools();
      assert.match(tools.tools.find(tool => tool.name === "pokemap_game_export")!.description!, /map3d\.gameplay@1/);
    }
    descriptors = new Map((catalog.mutationActions as JsonRecord[]).map(action => [String(action.id), action]));
    for (const id of ["pokemon.documents.write", "pokemon.catalog.write", "campaign.new_game.update", "fact.create", "scene.upsert",
      "event_v2.record_upsert", "event_v2.publish", "event_v2.activate", "world_rule.create", "entity.set_visual", "map3d.instance.delete",
      "smart_tile.layer.change_preset", "smart_tile.preset.publish", "asset.replace",
      "map3d.instance.upsert", "map3d.navigation.configure", "entity.move"]) assert.ok(descriptors.has(id), id);
    if (windmillRoot) for (const id of ["model3d.import", "model3d.configure", "asset.import"]) assert.ok(descriptors.has(id), id);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    workspaceHandle = String(opened.workspaceHandle); projectHandle = String(opened.projectHandle);
    let current = await project();
    assert.equal(current.name, "Valbois — Voyage en 3D"); assert.equal(record(current.settings).dimension, "threeD");
    assert.equal(record(current.settings).tileWidth, 32); assert.equal(record(current.settings).tileHeight, 32);
    if (exportOnly || metadataOnly || actorPlacementOnly) {
      if (actorPlacementOnly) await ensureGardenerPlacement();
      if (!provisional) await ensureInteriorMetadata(exportOnly || actorPlacementOnly);
      const validation = await call("pokemap_validate", { projectHandle });
      const exported = exportPath ? await exportValidatedProject(validation) : {};
      process.stdout.write(`${JSON.stringify({ projectRoot, canonicalActions: count, validation, ...exported })}\n`);
      return;
    }
    if (!record(current.pokemon).enabled) await mutate("pokemon.configuration.set_enabled", { enabled: true });
    let assetQuery = await call("pokemap_query", { projectHandle, resourceKind: "asset", operation: "list", view: "detail", pageSize: 200 });
    const existingAssets = new Map((assetQuery.items as JsonRecord[]).map(value => [String(value.id), value]));
    for (const asset of assets.filter(value => value.id !== "valbois-pickup-sheet")) {
      const existing = existingAssets.get(String(asset.id));
      if (existing) {
        const bytes = await readFile(join(projectRoot, String(existing.logicalPath)));
        if (createHash("sha256").update(bytes).digest("hex") === asset.sha256) continue;
        await mutate("asset.replace", { assetId: asset.id,
          artifactHandle: await stage(String(asset.file), String(asset.file).endsWith(".ogg") ? "audio/ogg" : "image/png") });
        continue;
      }
      await mutate("asset.import", { assetId: asset.id, logicalPath: asset.logicalPath,
        artifactHandle: await stage(String(asset.file), String(asset.file).endsWith(".ogg") ? "audio/ogg" : "image/png"), tags: ["PSDK", "Valbois"] });
    }
    for (const catalogDocument of pack.catalogs as JsonRecord[]) {
      await writeDocument("pokemon.catalog.write", { relativePath: `data/pokemon/catalogs/${catalogDocument.catalog}.json`, document: catalogDocument });
    }
    for (const document of pack.documents as JsonRecord[]) await writeDocument(String(document.actionId), record(document.parameters));
    try { await readFile(join(projectRoot, "data/pokemon/catalogs/items.json")); }
    catch (error) {
      if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
      await writeDocument("pokemon.catalog.write", { relativePath: "data/pokemon/catalogs/items.json", document: { schemaVersion: 1, entries: [] } });
      await call("pokemap_workspace", { operation: "close", workspaceHandle });
      const refreshed = await call("pokemap_workspace", { operation: "open", projectRoot });
      workspaceHandle = String(refreshed.workspaceHandle); projectHandle = String(refreshed.projectHandle);
    }
    for (const definition of valboisItems) {
      const itemId = String(definition.id);
      let existing: JsonRecord | undefined;
      try { existing = ((await query("itemDefinition", itemId)).items as JsonRecord[])[0]; }
      catch (error) { if (!(error instanceof CanonicalFailure && error.domainCode === "query.resource_not_found")) throw error; }
      if (existing && matchesRequestedState(existing, definition)) continue;
      await mutate(existing ? "item.update" : "item.create", { definition, ...(existing ? { itemId } : {}) });
    }
    for (const value of encounterTables) {
      current = await project();
      if (!matchesRequestedState((current.encounterTables as JsonRecord[]).find(table => table.id === value.id), value)) await mutate("campaign.encounter_table.upsert", { value });
    }
    for (const area of encounterAreas) {
      const payload = { encounterTableId: area.mapId === "valbois-meadow" ? "valbois-meadow-walk" : "valbois-forest-walk", encounterKind: "walk" };
      const zone = ((await map(area.mapId)).gameplayZones as JsonRecord[]).find(value => value.id === area.id)!;
      if (!matchesRequestedState(zone.encounter, payload)) await mutate("gameplay_zone.set_encounter_payload", { mapId: area.mapId, zoneId: area.id, payload });
    }
    for (const fact of questFacts) {
      current = await project();
      const existing = ((current.facts ?? []) as JsonRecord[]).find(value => value.id === fact.id);
      if (!existing) await mutate("fact.create", { fact: { ...fact, label: fact.id.slice(5).replaceAll("_", " ") } });
      if (!existing || existing.label !== fact.label) await mutate("fact.update", { fact });
    }
    for (const dialogue of valboisDialogs) {
      current = await project();
      const entry = { id: dialogue.id, name: dialogue.id, relativePath: `dialogues/${dialogue.id}.yarn`, defaultStartNode: "Accueil" };
      const source = `title: Accueil\n---\n${dialogue.lines.map(line => `${dialogue.speaker}: ${line}`).join("\n")}\n===\n`;
      const exists = (current.dialogues as JsonRecord[]).some(value => value.id === dialogue.id);
      if (exists && await readFile(join(projectRoot, entry.relativePath), "utf8") === source) continue;
      await mutate(exists ? "dialogue.update" : "dialogue.create", { entry, source });
    }
    for (const scene of questScenes()) {
      current = await project();
      if (!matchesRequestedState((current.scenes as JsonRecord[]).find(value => value.id === scene.id), scene)) await mutate("scene.upsert", { scene });
    }
    current = await project();
    if (!((current.scenes ?? []) as JsonRecord[]).some(scene => scene.id === "valbois-intro")) {
      await mutate("scene.preSession.create", { sceneId: "valbois-intro", name: "Bienvenue à Valbois", templateId: "minimal", setAsEntrypoint: true });
    }
    current = await project();
    const intro = (current.scenes as JsonRecord[]).find(scene => scene.id === "valbois-intro")!;
    if (!(record(intro.graph).nodes as JsonRecord[]).some(node => node.id === "welcome")) await mutate("scene.preSession.interaction.insert", {
      sceneId: "valbois-intro", nodeId: "welcome", targetNodeId: "end", title: "Le début du voyage",
      interaction: { kind: "message", prompt: { localizationKey: "valbois.intro", fallbackText: "Bienvenue à Valbois ! Bulbizarre t’accompagne pour ta première promenade. Ton sac contient 8 Poké Balls et 3 Potions. Retrouve Émile près du chemin du village." } } });
    current = await project();
    if (!matchesRequestedState(current.newGame, newGameDefinition())) await mutate("campaign.new_game.update", { newGame: newGameDefinition() });
    current = await project();
    if (!(current.tilesets as JsonRecord[]).some(value => value.id === "valbois-pickup-sheet")) await mutate("tileset.import_image", {
      tilesetId: "valbois-pickup-sheet", name: "Poké Ball posée — PSDK", tileWidth: 32, tileHeight: 32,
      artifactHandle: await stage("assets/items/pickup/pokeball.png", "image/png") });
    else {
      const pickup = assets.find(value => value.id === "valbois-pickup-sheet")!;
      if (createHash("sha256").update(await readFile(join(projectRoot, "assets/studio/valbois-pickup-sheet.png"))).digest("hex") !== pickup.sha256)
        await mutate("asset.replace", { assetId: "image_valbois-pickup-sheet", artifactHandle: await stage(String(pickup.file), "image/png") });
    }
    for (const presetId of ["valbois-path", "valbois-forest-path"]) {
      current = await project();
      const pathPreset = (record(current.smartTileCatalog).presets as JsonRecord[]).find(value => value.id === presetId)!;
      if (pathPreset.coveragePolicy !== "sparse") await mutate("smart_tile.preset.publish", { preset: { ...pathPreset, coveragePolicy: "sparse" } });
    }
    for (const mapId of ["valbois-forest", "valbois-clearing"]) {
      const layer = ((await map(mapId)).layers as JsonRecord[]).find(value => value.id === "paths")!;
      if (layer.presetId !== pathPresetForMap(mapId)) await mutate("smart_tile.layer.change_preset", {
        mapId, layerId: "paths", targetPresetId: pathPresetForMap(mapId), materialMappings: { "valbois-forest-path": "valbois-path" } });
    }
    const care = await map("valbois-care");
    const careScene = record(care.spatialScene);
    const carePlan = worldPlan().find(value => value.id === "valbois-care")!;
    const careTable = carePlan.instances.find(value => value.id === "care-table")!;
    if (!matchesRequestedState((careScene.instances as JsonRecord[]).find(value => value.id === careTable.id), careTable))
      await mutate("map3d.instance.upsert", { mapId: "valbois-care", instance: careTable });
    const careNavigation = { spawn: record(careScene.navigation).spawn, allowDiagonalMovement: false, ramps: carePlan.ramps, blockedAreas: carePlan.blocks };
    if (!matchesRequestedState(careScene.navigation, careNavigation)) await mutate("map3d.navigation.configure", {
      mapId: "valbois-care", navigation: careNavigation });
    current = await project();
    const categoryId = "valbois-items";
    const pickupElement = { id: "valbois-pokeball-pickup", name: "Objet ramassable PSDK", categoryId,
      tilesetId: "valbois-pickup-sheet", frames: [{ source: { x: 0, y: 0, width: 1, height: 1 } }], tags: ["PSDK", "Valbois"] };
    if (!matchesRequestedState((current.elements as JsonRecord[]).find(value => value.id === pickupElement.id), pickupElement)) await mutate("element.upsert", { element: pickupElement,
      ...((current.elementCategories as JsonRecord[]).some(value => value.id === categoryId) ? {} : { category: { id: categoryId, name: "Objets de Valbois" } }) });
    const forest = await map("valbois-forest");
    const pickupVisual = { elementId: "valbois-pokeball-pickup" };
    const pickupEntity = (forest.entities as JsonRecord[]).find(value => value.id === "valbois-forest-pickup")!;
    if (!matchesRequestedState(pickupEntity.editorVisual, pickupVisual)) await mutate("entity.set_visual", { mapId: "valbois-forest", entityId: "valbois-forest-pickup", payload: pickupVisual });
    if ((record(forest.spatialScene).instances as JsonRecord[]).some(value => value.id === "forest-pickup-model")) await mutate("map3d.instance.delete", { mapId: "valbois-forest", instanceId: "forest-pickup-model" });
    current = await project();
    if (!((current.worldRules ?? []) as JsonRecord[]).some(value => value.id === pickupHiddenRule.id)) {
      await mutate("world_rule.create", { rule: { ...pickupHiddenRule, label: "Valbois pickup hidden" } });
    }
    current = await project();
    if (!matchesRequestedState((current.worldRules as JsonRecord[]).find(value => value.id === pickupHiddenRule.id), pickupHiddenRule)) await mutate("world_rule.update", { rule: pickupHiddenRule });
    const guideDialogue = { dialogueId: "valbois-quest-reminder", startNode: "Accueil" };
    const guide = record(((await map("first-map")).entities as JsonRecord[]).find(value => value.id === "valbois-guide")!.npc);
    if (!matchesRequestedState(guide.dialogue, guideDialogue)) await mutate("npc.set_dialogue", { mapId: "first-map", entityId: "valbois-guide", dialogue: guideDialogue });
    const conditional = [
      { factId: questIds.rewarded, dialogueId: "valbois-quest-finished" },
      { factId: questIds.visited, dialogueId: "valbois-quest-ready" },
      { factId: questIds.accepted, dialogueId: "valbois-quest-reminder" },
    ];
    const entities = (await map("first-map")).entities as JsonRecord[];
    const npc = record(entities.find(value => value.id === "valbois-guide")!.npc);
    for (const entry of conditional) {
      if (((npc.conditionalDialogues ?? []) as JsonRecord[]).some(value => record(value.dialogue).dialogueId === entry.dialogueId)) continue;
      await mutate("npc.conditional_dialogue_add", { mapId: "first-map", entityId: "valbois-guide", conditionalDialogue: {
        when: { kind: "storyFlagSet", refId: entry.factId }, dialogue: { dialogueId: entry.dialogueId, startNode: "Accueil" } } });
    }
    for (const sign of valboisSigns) {
      const entity = { id: sign.id, name: sign.title, kind: "sign", pos: { x: sign.x, y: sign.y }, size: { width: 1, height: 1 },
        blocksMovement: true, sign: { title: sign.title, plainText: "", dialogue: { dialogueId: `${sign.id}-dialogue`, startNode: "Accueil" } } };
      if (!matchesRequestedState(((await map(sign.mapId)).entities as JsonRecord[]).find(value => value.id === sign.id), entity)) await mutate("entity.upsert", { mapId: sign.mapId, entity });
    }
    current = await project();
    if (record(current.eventRegistry).mode !== "v2Only") await mutate("event_v2.registry_mode.set", { mode: "v2Only" });
    for (const eventRecord of questEvents()) {
      current = await project();
      const eventId = String(record(eventRecord.draft).id);
      const existing = (record(current.eventRegistry).records as JsonRecord[]).find(value =>
        record(value[value.state === "draft" ? "draft" : "definition"]).id === eventId);
      const changed = !existing || !matchesRequestedState(record(existing[existing.state === "draft" ? "draft" : "definition"]), eventRecord.draft);
      if (changed) await mutate("event_v2.record_upsert", { record: eventRecord });
      if (changed || existing?.state === "draft") await mutate("event_v2.publish", { eventId });
      if (changed || existing?.enabled !== true) await mutate("event_v2.activate", { eventId });
    }
    assetQuery = await call("pokemap_query", { projectHandle, resourceKind: "asset", operation: "list", view: "detail", pageSize: 200 });
    const provenance = (assetQuery.items as JsonRecord[]).find(value => value.id === "valbois-gameplay-provenance");
    if (!provenance) await mutate("asset.import", {
      assetId: "valbois-gameplay-provenance", logicalPath: "assets/provenance/valbois-gameplay.json", tags: ["provenance", "PSDK", "Valbois"],
      artifactHandle: await stage("valbois_pokemon_pack.json", "text/plain") });
    else if (!(await readFile(join(projectRoot, String(provenance.logicalPath)))).equals(await readFile(join(assetRoot, "valbois_pokemon_pack.json")))) {
      await mutate("asset.replace", { assetId: provenance.id, artifactHandle: await stage("valbois_pokemon_pack.json", "text/plain") });
    }
    if (doorRoot) {
      assert.equal(createHash("sha256").update(await readFile(join(doorRoot, "bw2_normal_door_1.glb"))).digest("hex"),
        "8d6ae867067d9bbb4d894794b4a18c49a80c8f968ea1099279820c7dff94cb4e");
      current = await project();
      if (!(current.models3d as JsonRecord[]).some(value => value.id === "bw2-normal-door-1")) {
        const artifact = await call("pokemap_artifact_stage", { sourcePath: join(doorRoot, "bw2_normal_door_1.glb"), declaredMediaType: "model/gltf-binary" });
        await mutate("model3d.import", { modelId: "bw2-normal-door-1", name: "Porte NB2 · ouverture et fermeture", artifactHandle: artifact.artifactHandle });
      }
      assetQuery = await call("pokemap_query", { projectHandle, resourceKind: "asset", operation: "list", view: "detail", pageSize: 200 });
      if (!(assetQuery.items as JsonRecord[]).some(value => value.id === "valbois-door-provenance")) {
        const artifact = await call("pokemap_artifact_stage", { sourcePath: join(doorRoot, "bw2_normal_door_1_provenance.json") });
        await mutate("asset.import", { assetId: "valbois-door-provenance", logicalPath: "assets/provenance/valbois-door.json",
          artifactHandle: artifact.artifactHandle, tags: ["NB2", "Valbois", "provenance"] });
      }
    }
    if (windmillRoot) {
      const glbPath = join(windmillRoot, "bw2_windmill.glb");
      const provenancePath = join(windmillRoot, "bw2_windmill_provenance.json");
      const source = record(JSON.parse(await readFile(provenancePath, "utf8")));
      assert.equal(createHash("sha256").update(await readFile(glbPath)).digest("hex"), valboisWindmill.sourceSha256);
      assert.equal(source.outputSha256, valboisWindmill.sourceSha256);
      assert.deepEqual(record(source.boundsCells).building, valboisWindmill.buildingBounds);
      assert.equal(source.assetId, "582888");
      current = await project();
      let model = (current.models3d as JsonRecord[]).find(value => value.id === valboisWindmill.modelId);
      if (!model) {
        const artifact = await call("pokemap_artifact_stage", { sourcePath: glbPath, declaredMediaType: "model/gltf-binary" });
        await mutate("model3d.import", { modelId: valboisWindmill.modelId, name: valboisWindmill.name, artifactHandle: artifact.artifactHandle });
        model = ((await project()).models3d as JsonRecord[]).find(value => value.id === valboisWindmill.modelId)!;
      }
      assert.equal(createHash("sha256").update(await readFile(join(projectRoot, String(model.relativePath)))).digest("hex"), valboisWindmill.sourceSha256);
      const configuration = { name: valboisWindmill.name, scale: 1, pivot: valboisWindmill.pivot };
      if (!matchesRequestedState(model, configuration)) await mutate("model3d.configure", { modelId: valboisWindmill.modelId, ...configuration });
      const scene = record((await map(valboisWindmill.mapId)).spatialScene);
      if (!matchesRequestedState((scene.instances as JsonRecord[]).find(value => value.id === valboisWindmill.instance.id), valboisWindmill.instance))
        await mutate("map3d.instance.upsert", { mapId: valboisWindmill.mapId, instance: valboisWindmill.instance });
      const navigation = withValboisWindmillNavigation(record(scene.navigation));
      if (!matchesRequestedState(scene.navigation, navigation)) await mutate("map3d.navigation.configure", { mapId: valboisWindmill.mapId, navigation });
      assetQuery = await call("pokemap_query", { projectHandle, resourceKind: "asset", operation: "list", view: "detail", pageSize: 200 });
      const provenance = (assetQuery.items as JsonRecord[]).find(value => value.id === "valbois-windmill-provenance");
      if (!provenance || !(await readFile(join(projectRoot, String(provenance.logicalPath)))).equals(await readFile(provenancePath))) {
        const artifact = await call("pokemap_artifact_stage", { sourcePath: provenancePath, declaredMediaType: "text/plain" });
        await mutate(provenance ? "asset.replace" : "asset.import", provenance
          ? { assetId: provenance.id, artifactHandle: artifact.artifactHandle }
          : { assetId: "valbois-windmill-provenance", logicalPath: "assets/provenance/valbois-windmill.json",
            artifactHandle: artifact.artifactHandle, tags: ["NB2", "Valbois", "provenance"] });
      }
    }
    await ensureInteriorMetadata();
    await ensureGardenerPlacement();
    const validation = await call("pokemap_validate", { projectHandle });
    const exported = exportPath ? await exportValidatedProject(validation) : {};
    current = await project();
    process.stdout.write(`${JSON.stringify({ projectRoot, canonicalActions: count, sourceAssetCount: assets.length,
      newGame: current.newGame, facts: current.facts, events: current.eventRegistry, scenes: (current.scenes as JsonRecord[]).map(scene => scene.id),
      encounterTables: current.encounterTables, worldRules: current.worldRules, validation,
      ...exported })}\n`);
  } finally {
    try { if (workspaceHandle) await call("pokemap_workspace", { operation: "close", workspaceHandle }); }
    finally { await client.close(); }
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) await authorValboisGameplay(process.argv.slice(2));

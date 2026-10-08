import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { createHash } from "node:crypto";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import type { JsonRecord } from "../src/authoring_client.js";
import { questFacts, questIds, questScenes, questEvents, valboisDialogs, valboisItems,
  encounterTables, newGameDefinition, pickupHiddenRule, matchesRequestedState, valboisSigns, valboisInteriorMetadata,
  promoteValidatedValboisExport, valboisWindmill, withValboisWindmillNavigation } from "../tool/author_valbois_gameplay.js";
import { actors, worldPlan, pathPresetForMap, preset, passages } from "../tool/author_valbois_demo.js";

function record(value: unknown): JsonRecord { return value as JsonRecord; }

test("Final export replacement retains both files if either immutable receipt mismatches", async () => {
  const root = await mkdtemp(join(tmpdir(), "valbois-export-promotion-"));
  try {
    const stagedPath = join(root, "staged.avelunegame"), finalPath = join(root, "Valbois-demo.avelunegame");
    await writeFile(finalPath, "previous"); await writeFile(stagedPath, "new canonical package");
    const digest = (value: string) => createHash("sha256").update(value).digest("hex");
    const exportReceipt = { outputPath: stagedPath, sha256: digest("new canonical package") };
    await assert.rejects(promoteValidatedValboisExport(stagedPath, finalPath, "0".repeat(64), exportReceipt));
    await assert.rejects(promoteValidatedValboisExport(stagedPath, finalPath, digest("previous"), { ...exportReceipt, sha256: "0".repeat(64) }));
    assert.equal(await readFile(finalPath, "utf8"), "previous");
    assert.equal(await readFile(stagedPath, "utf8"), "new canonical package");
    const receipt = await promoteValidatedValboisExport(stagedPath, finalPath, digest("previous"), exportReceipt);
    assert.equal(receipt.atomicReplacement, true);
    assert.equal(receipt.sha256, exportReceipt.sha256);
    assert.equal(await readFile(finalPath, "utf8"), "new canonical package");
    await assert.rejects(readFile(stagedPath));
  } finally { await rm(root, { recursive: true }); }
});

test("Reruns accept canonical defaults but detect changed authoring values and array order", () => {
  assert.ok(matchesRequestedState({ elementId: "pickup", renderInForeground: false }, { elementId: "pickup" }));
  assert.ok(matchesRequestedState({ graph: { nodes: [{ id: "end", tags: [] }] }, tags: [] }, { graph: { nodes: [{ id: "end" }] } }));
  assert.equal(matchesRequestedState({ amount: 2 }, { amount: 3 }), false);
  assert.equal(matchesRequestedState({ enabled: false }, { enabled: true }), false);
  assert.equal(matchesRequestedState(["reward", "reminder"], ["reminder", "reward"]), false);
  assert.equal(matchesRequestedState(["reward", "reminder"], ["reward"]), false);
  assert.equal(matchesRequestedState(null, { elementId: "pickup" }), false);
});

test("Valbois events close their sources, scene and fact references", () => {
  const facts = new Set(questFacts.map(value => value.id));
  const scenes = new Set(questScenes().map(value => value.id));
  const knownEntities = new Set([...actors.map(actor => `${actor.mapId}:${actor.id}`),
    ...valboisSigns.map(sign => `${sign.mapId}:${sign.id}`), "valbois-forest:valbois-forest-pickup"]);
  const events = questEvents();
  assert.equal(new Set(events.map(value => record(value.draft).id)).size, 15);
  for (const event of events) {
    const draft = record(event.draft);
    assert.match(String(draft.id), /^evt_[\da-f]{8}-[\da-f]{4}-7[\da-f]{3}-8[\da-f]{3}-[\da-f]{12}$/);
    assert.ok(scenes.has(draft.sceneId));
    for (const condition of draft.conditions as JsonRecord[]) assert.ok(facts.has(String(condition.factId)));
    const source = record(draft.source);
    if (source.kind === "entityInteract") assert.ok(knownEntities.has(`${source.mapId}:${source.entityId}`));
    else assert.deepEqual(source, { kind: "mapEnter", mapId: "valbois-clearing" });
  }
});

test("Rewards and pickup finish by persisting the same guarded Fact atomically", () => {
  const scenes = questScenes();
  const events = questEvents().map(value => record(value.draft));
  for (const [sceneId, factId] of [["valbois-reward-scene", questIds.rewarded], ["valbois-pickup-scene", questIds.picked]]) {
    const scene = scenes.find(value => value.id === sceneId)!;
    const consequences = (record(scene.graph).nodes as JsonRecord[]).filter(node => node.kind === "action")
      .map(node => record(record(node.payload).consequence));
    assert.deepEqual(consequences.at(-1), { kind: "setFact", factId, value: true });
    assert.ok(consequences.some(effect => effect.kind === "giveItem"));
    const event = events.find(value => value.sceneId === sceneId)!;
    assert.equal(event.reusePolicy, "oneShot");
    assert.ok((event.conditions as JsonRecord[]).some(condition => condition.factId === factId && condition.expectedValue === false));
  }
  assert.equal(record(pickupHiddenRule.source).sourceId, questIds.picked);
  assert.equal(record(pickupHiddenRule.effect).kind, "entityHidden");
});

test("All scene paths reach a declared progression terminal with portable dialogue refs", () => {
  const dialogs = new Set([...valboisDialogs.map(dialogue => dialogue.id), ...actors.map(actor => `${actor.id}-welcome`)]);
  for (const scene of questScenes()) {
    const graph = record(scene.graph);
    const nodes = graph.nodes as JsonRecord[];
    const edges = graph.edges as JsonRecord[];
    assert.equal(edges.filter(edge => edge.fromPortId === "completed").length, nodes.length - 1);
    for (let index = 0; index < nodes.length - 1; index++) {
      assert.equal(edges[index]!.fromNodeId, nodes[index]!.id);
      assert.equal(edges[index]!.toNodeId, nodes[index + 1]!.id);
      if (nodes[index]!.kind === "yarnDialogue") assert.ok(dialogs.has(String(record(nodes[index]!.payload).dialogueId)));
    }
    assert.equal(record(nodes.at(-1)!.payload).outcomePolicy, "progression");
  }
});

test("V2-only ordinary NPCs and signs have exactly one reusable interaction scene", () => {
  const events = questEvents().map(value => record(value.draft));
  const scenes = new Map(questScenes().map(scene => [scene.id, scene]));
  for (const entity of [...actors.filter(actor => !["valbois-guide", "valbois-healer", "valbois-parent"].includes(actor.id)), ...valboisSigns]) {
    const matching = events.filter(event => record(event.source).kind === "entityInteract" &&
      record(event.source).mapId === entity.mapId && record(event.source).entityId === entity.id);
    assert.equal(matching.length, 1, entity.id);
    const event = matching[0]!;
    assert.equal(event.reusePolicy, "reusable");
    assert.deepEqual(event.conditions, []);
    const nodes = record(scenes.get(event.sceneId)!.graph).nodes as JsonRecord[];
    assert.equal(nodes.filter(node => node.kind === "yarnDialogue").length, 1);
    assert.equal(nodes.filter(node => node.kind === "action").length, 0);
  }
});

test("Guide interactions partition every fact combination without duplicate quest dialogue", () => {
  const events = questEvents().map(value => record(value.draft)).filter(event => record(event.source).entityId === "valbois-guide");
  assert.equal(events.length, 4);
  for (let mask = 0; mask < 8; mask++) {
    const facts = { [questIds.accepted]: Boolean(mask & 1), [questIds.visited]: Boolean(mask & 2), [questIds.rewarded]: Boolean(mask & 4) };
    const matches = events.filter(event => (event.conditions as JsonRecord[]).every(condition => facts[String(condition.factId)] === condition.expectedValue));
    assert.equal(matches.length, 1, JSON.stringify(facts));
    const chosen = matches[0]!;
    assert.equal(chosen.sceneId, mask & 4 ? "valbois-quest-finished-scene" : !(mask & 1) ? "valbois-quest-start-scene" :
      mask & 2 ? "valbois-reward-scene" : "valbois-quest-reminder-scene");
    assert.equal(chosen.reusePolicy, mask & 4 || mask === 1 ? "reusable" : "oneShot");
  }
});

test("All exterior paths use authentic Floccesy dirt while terrain remains independently editable", () => {
  for (const map of worldPlan().filter(map => !map.interior)) assert.equal(pathPresetForMap(map.id), "valbois-path");
  assert.equal(preset("path", "Path", "source", true, 1, "path").coveragePolicy, "sparse");
  assert.equal(preset("ground", "Ground", "source").coveragePolicy, "complete");
});

test("The nurse uses the canonical healing service and cancellation returns safely", () => {
  const healing = questScenes().find(scene => scene.id === "valbois-heal-scene")!;
  const graph = record(healing.graph);
  const action = (graph.nodes as JsonRecord[]).find(node => node.id === "effect-0")!;
  assert.deepEqual(record(action.payload).interactiveCommand, { kind: "openHeal", requiresConfirmation: true });
  assert.equal(record(action.payload).consequence, undefined);
  const exits = (graph.edges as JsonRecord[]).filter(edge => edge.fromNodeId === action.id);
  assert.deepEqual(exits.map(edge => edge.fromPortId).sort(), ["cancelled", "completed"]);
  assert.ok(exits.every(edge => edge.toNodeId === "end"));
  const home = questScenes().find(scene => scene.id === "valbois-home-rest-scene")!;
  assert.deepEqual(record(record((record(home.graph).nodes as JsonRecord[]).find(node => node.id === "effect-0")!.payload).consequence), { kind: "healParty" });
});

test("Every native sign owns a portable Yarn dialogue with the same authored text", () => {
  assert.equal(valboisSigns.length, 3);
  for (const sign of valboisSigns) {
    const dialogue = valboisDialogs.find(value => value.id === `${sign.id}-dialogue`)!;
    assert.ok(dialogue);
    assert.deepEqual(dialogue.lines, [sign.text]);
    assert.equal(dialogue.speaker, sign.title);
  }
});

test("Canonical metadata marks exactly the two furnished native interiors", () => {
  assert.deepEqual(valboisInteriorMetadata.map(value => value.mapId).sort(), worldPlan().filter(map => map.interior).map(map => map.id).sort());
  assert.ok(valboisInteriorMetadata.every(value => value.role === "interior" && value.isIndoor));
});

test("The native animated windmill blocks only its measured building and leaves village routes free", () => {
  const village = worldPlan().find(map => map.id === valboisWindmill.mapId)!;
  const [minX, minY, minZ, maxX, , maxZ] = valboisWindmill.buildingBounds;
  const position = valboisWindmill.instance.position;
  const area = valboisWindmill.blockedArea;
  assert.equal(minY! - valboisWindmill.pivot.y + position.y, 0);
  assert.deepEqual(area, { x: position.x + minX!, z: position.z + minZ!, width: maxX! - minX!, depth: maxZ! - minZ! });
  assert.equal(valboisWindmill.instance.blocksMovement, false);
  assert.equal(valboisWindmill.instance.animationIndex, 0);
  assert.equal(valboisWindmill.instance.animationLoop, true);
  assert.equal(valboisWindmill.instance.animationSpeed, 1);
  const overlaps = (x: number, z: number, width: number, depth: number) =>
    x < area.x + area.width && x + width > area.x && z < area.z + area.depth && z + depth > area.z;
  for (const block of village.blocks) assert.equal(overlaps(block.x, block.z, block.width, block.depth), false);
  for (const cell of village.paths) assert.equal(overlaps(cell.x, cell.y, 1, 1), false);
  for (const actor of actors.filter(actor => actor.mapId === village.id)) assert.equal(overlaps(actor.x, actor.y, 1, 1), false);
  for (const passage of passages.filter(passage => passage.mapId === village.id))
    assert.equal(overlaps(passage.warp.pos.x, passage.warp.pos.y, 1, 1), false);
  assert.equal(overlaps(village.spawn.x, village.spawn.y, 1, 1), false);
  assert.ok(area.x > 0 && area.x + area.width < village.width && area.z > 0 && area.z + area.depth < village.height);
  const navigation = { spawn: { x: 14.5, z: 14.5 }, allowDiagonalMovement: false, ramps: [{ id: "preserved" }], blockedAreas: village.blocks };
  const updated = withValboisWindmillNavigation(navigation);
  assert.deepEqual(updated.spawn, navigation.spawn);
  assert.deepEqual(updated.ramps, navigation.ramps);
  assert.equal((updated.blockedAreas as unknown[]).length, village.blocks.length + 1);
  assert.deepEqual(withValboisWindmillNavigation(updated), updated);
});

test("Optional windmill provenance matches the exact authored animation and body footprint", { skip: !process.env.AVELUNE_VALBOIS_WINDMILL_ASSETS }, async () => {
  const root = process.env.AVELUNE_VALBOIS_WINDMILL_ASSETS!;
  const source = record(JSON.parse(await readFile(join(root, "bw2_windmill_provenance.json"), "utf8")));
  assert.equal(source.assetId, "582888");
  assert.equal(source.outputSha256, valboisWindmill.sourceSha256);
  assert.equal(createHash("sha256").update(await readFile(join(root, "bw2_windmill.glb"))).digest("hex"), valboisWindmill.sourceSha256);
  assert.deepEqual(record(source.boundsCells).building, valboisWindmill.buildingBounds);
  assert.equal((source.clips as JsonRecord[])[0]!.index, valboisWindmill.instance.animationIndex);
  assert.equal((source.clips as JsonRecord[])[0]!.keyCount, 120);
  assert.equal((source.clips as JsonRecord[])[0]!.durationSeconds, 119 / 60);
  assert.equal(source.triangleCount, 138);
  assert.ok((source.omitted as JsonRecord[]).some(value => value.texture === "h_kage.png"));
  const visible = record(source.boundsCells).visible as number[];
  assert.ok(visible[0]! < valboisWindmill.buildingBounds[0]! && visible[3]! > valboisWindmill.buildingBounds[3]!);
});

test("New Game, starter and wild encounters use the bounded real Pokemon and item closure", () => {
  const game = newGameDefinition();
  assert.equal(game.enabled, true);
  assert.equal(game.startMapId, "first-map");
  assert.equal(game.startSpawnId, "first-map-spawn");
  assert.deepEqual(game.playerAvatarCharacterIds, ["voyageur-psdk"]);
  const starter = (game.initialParty as JsonRecord[])[0]!;
  assert.equal(starter.speciesId, "bulbasaur");
  assert.equal(starter.level, 5);
  assert.deepEqual(starter.ivs, { hp: 12, attack: 12, defense: 12, specialAttack: 12, specialDefense: 12, speed: 12 });
  assert.deepEqual(starter.knownMoveIds, ["tackle", "growl"]);
  const items = new Set(valboisItems.map(item => item.id));
  for (const entry of game.initialBag as JsonRecord[]) assert.ok(items.has(entry.itemId));
  for (const table of encounterTables) {
    assert.equal(table.encounterKind, "walk");
    assert.ok(Number(table.chancePerStep) > 0 && Number(table.chancePerStep) <= 1);
    for (const entry of table.entries as JsonRecord[]) {
      assert.ok(["pidgey", "rattata", "caterpie"].includes(String(entry.speciesId)));
      assert.ok(Number(entry.minLevel) >= 2 && Number(entry.maxLevel) <= 4);
    }
  }
  const healing = record((valboisItems[0]!.uses as JsonRecord[])[0]);
  assert.deepEqual(healing.contexts, ["overworld", "battle"]);
  assert.equal(record(healing.effect).amount, 20);
  assert.deepEqual(record(valboisItems[1]!.capture).allowedEncounterKinds, ["walk"]);
});

test("Optional PSDK build closes every authored level-up move and authentic media path", { skip: !process.env.AVELUNE_VALBOIS_POKEMON_PACK }, async () => {
  const pack = record(JSON.parse(await readFile(process.env.AVELUNE_VALBOIS_POKEMON_PACK!, "utf8")));
  const moveIds = new Set(((pack.catalogs as JsonRecord[]).find(value => value.catalog === "moves")!.entries as JsonRecord[]).map(value => value.id));
  const mediaPaths = new Set((pack.assets as JsonRecord[]).map(value => value.logicalPath));
  for (const document of pack.documents as JsonRecord[]) {
    const value = record(record(document.parameters).document);
    if (document.actionId === "pokemon.learnset.write") {
      for (const move of value.levelUp as JsonRecord[]) assert.ok(moveIds.has(move.moveId));
      for (const move of value.startingMoves as string[]) assert.ok(moveIds.has(move));
    }
    if (document.actionId === "pokemon.media.write") {
      const media = record(record(value.variants).base);
      for (const role of ["frontStatic", "backStatic", "frontShinyStatic", "backShinyStatic", "icon", "party", "cry"]) assert.ok(mediaPaths.has(media[role]));
    }
  }
});

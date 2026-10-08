import assert from "node:assert/strict";
import { createHash, randomUUID } from "node:crypto";
import { access, readFile, realpath } from "node:fs/promises";
import { join, resolve } from "node:path";
import { pathToFileURL } from "node:url";
import { isDeepStrictEqual } from "node:util";
import { setTimeout as delay } from "node:timers/promises";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";

type Cell = { x: number; y: number };
type Area = { x: number; z: number; width: number; depth: number };
class CanonicalFailure extends Error {
  constructor(readonly domainCode: string, data: JsonRecord) {
    super(JSON.stringify(data));
  }
}
type MapPlan = {
  id: string; name: string; width: number; height: number; interior: boolean;
  spawn: Cell; paths: Cell[]; grass: Cell[]; instances: JsonRecord[];
  blocks: Area[]; levels: JsonRecord[]; ramps: JsonRecord[];
};

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

export function rectangle(x: number, y: number, width: number, height: number): Cell[] {
  return Array.from({ length: width * height }, (_, index) => ({ x: x + index % width, y: y + Math.floor(index / width) }));
}

export function surplusPaintedCells(field: number[], width: number, desired: Cell[]): Cell[] {
  const allowed = new Set(desired.map(cell => `${cell.x},${cell.y}`));
  return field.flatMap((material, index) => {
    const cell = { x: index % width, y: Math.floor(index / width) };
    return material !== 0 && !allowed.has(`${cell.x},${cell.y}`) ? [cell] : [];
  });
}

export function pathPresetForMap(mapId: string): string {
  assert.ok(mapId === "first-map" || mapId.startsWith("valbois-"));
  return "valbois-path";
}

function unique(cells: Cell[]): Cell[] {
  return [...new Map(cells.map(cell => [`${cell.x},${cell.y}`, cell])).values()];
}

function instance(id: string, modelId: string, x: number, z: number,
  scale = 1, rotationDegrees = 0, y = 0, blocksMovement = false): JsonRecord {
  return { id, modelId, position: { x, y, z }, scale, rotationDegrees,
    animationIndex: null, blocksMovement };
}

export const connections = [
  { mapId: "first-map", direction: "east", targetMapId: "valbois-meadow", offset: 4 },
  { mapId: "first-map", direction: "north", targetMapId: "valbois-forest", offset: 3 },
  { mapId: "valbois-forest", direction: "north", targetMapId: "valbois-clearing", offset: 4 },
];

export const passages = [
  { mapId: "first-map", warp: { id: "home-door", pos: { x: 7, y: 8 }, targetMapId: "valbois-home", targetPos: { x: 5, y: 6 } }, reciprocalWarpId: "home-exit" },
  { mapId: "first-map", warp: { id: "care-door", pos: { x: 20, y: 8 }, targetMapId: "valbois-care", targetPos: { x: 5, y: 6 } }, reciprocalWarpId: "care-exit" },
];

export const actors = [
  { mapId: "first-map", id: "valbois-guide", name: "Émile", character: "psdk-professor", x: 12, y: 12, facing: "east", lines: ["Bienvenue à Valbois ! La prairie est à l’est ; la forêt commence au nord.", "Prends le temps de te préparer chez toi et de passer au point de soin."] },
  { mapId: "first-map", id: "valbois-gardener", name: "Lina", character: "psdk-lass", x: 17, y: 16, facing: "west", lines: ["Les jardins adorent le soleil. Les Pokémon, eux, préfèrent souvent les hautes herbes."] },
  { mapId: "valbois-home", id: "valbois-parent", name: "Maman", character: "psdk-lass", x: 6, y: 4, facing: "south", lines: ["Ton premier voyage commence ici. Repasse te reposer quand tu en as besoin."] },
  { mapId: "valbois-care", id: "valbois-healer", name: "Infirmière", character: "psdk-nurse", x: 5, y: 2, facing: "south", lines: ["Bienvenue au point de soin de Valbois. Ici, ton équipe peut reprendre des forces."] },
  { mapId: "valbois-meadow", id: "valbois-young-trainer", name: "Hugo", character: "psdk-bug-catcher", x: 9, y: 10, facing: "south", lines: ["Il y a beaucoup de Pokémon dans cette prairie. Regarde bien avant de traverser les herbes."] },
  { mapId: "valbois-forest", id: "valbois-ranger", name: "Sylvain", character: "psdk-riley", x: 12, y: 18, facing: "west", lines: ["Le sentier rejoint deux petites clairières. Celle tout au nord est plus tranquille.", "Je garde aussi un œil sur le passage vers le plateau."] },
  { mapId: "valbois-clearing", id: "valbois-clearing-guide", name: "Éloi", character: "psdk-professor", x: 9, y: 7, facing: "west", lines: ["Tu as trouvé la clairière de Valbois. Le village paraît déjà loin, n’est-ce pas ?"] },
];

export const encounterAreas = [
  { mapId: "valbois-meadow", id: "valbois-meadow-grass-west", x: 5, y: 2, width: 5, height: 3 },
  { mapId: "valbois-meadow", id: "valbois-meadow-grass-east", x: 14, y: 10, width: 6, height: 4 },
  { mapId: "valbois-forest", id: "valbois-forest-grass", x: 3, y: 5, width: 5, height: 3 },
  { mapId: "valbois-clearing", id: "valbois-clearing-grass", x: 3, y: 4, width: 3, height: 3 },
];

export function worldPlan(): MapPlan[] {
  const maps: MapPlan[] = [
    { id: "first-map", name: "Valbois", width: 30, height: 24, spawn: { x: 14, y: 14 }, interior: false,
      paths: unique([...rectangle(13, 0, 3, 21), ...rectangle(4, 10, 26, 3),
        ...rectangle(6, 8, 3, 4), ...rectangle(19, 8, 3, 4), ...rectangle(6, 17, 9, 3), ...rectangle(15, 17, 11, 3)]),
      grass: [], instances: [
        instance("player-house", "bw2-floccesy-house", 7.5, 6),
        instance("care-house", "bw2-accumula-house", 20.5, 6),
        instance("village-house", "bw2-champion-house", 7.5, 15.3),
        instance("village-greenhouse", "bw2-greenhouse", 23, 16),
        instance("village-sign", "bw2-sign-01", 17.5, 11.5, .65),
        instance("garden-corner", "bw2-fence", 23.5, 20.5, .55, 180),
        instance("garden-flowers", "bw2-plant-01", 20, 19.5, .9),
        instance("garden-stump", "bw2-stump-01", 4, 20.5, .55),
      ], blocks: [{ x: 5, z: 4, width: 5, depth: 4 }, { x: 18, z: 4, width: 6, depth: 4 },
        { x: 5, z: 13, width: 5, depth: 4 }, { x: 19, z: 14, width: 8, depth: 3 }], levels: [], ramps: [] },
    ...["home", "care"].map(kind => ({ id: `valbois-${kind}`, name: kind === "home" ? "Maison du joueur" : "Point de soin",
      width: 10, height: 9, spawn: { x: 5, y: 6 }, interior: true, paths: [], grass: [],
      instances: [instance(`${kind}-walls`, "bw2-room-walls", 5, 4.25),
        ...(kind === "home" ? [
          instance("home-bed", "bw2-bed-01", 2, 2),
          instance("home-bookshelf", "bw2-bookshelf-02", 7.5, 1.3),
          instance("home-table", "bw2-table-01", 3, 4.5, .65),
          instance("home-chair", "bw2-chair-04", 3, 5.8, 1, 180),
          instance("home-desk", "bw2-desk-01", 8, 3.5, .75),
          instance("home-plant", "bw2-plant-01", 1.4, 6.4, .65),
        ] : [
          instance("care-table", "bw2-center-table", 7.5, 3.5, 1.4),
          instance("care-vending", "bw2-vending-machine", 8, 1.5),
          instance("care-bookshelf", "bw2-bookshelf-02", 2.5, 1.3),
          instance("care-chair", "bw2-chair-04", 2, 5.5),
          instance("care-side-table", "bw2-table-04", 2, 4.5),
          instance("care-plant", "bw2-plant-01", 8, 6, .75),
        ])],
      blocks: [{ x: 0, z: 0, width: 10, depth: 1 }, { x: 0, z: 1, width: 1, depth: 7 },
        { x: 9, z: 1, width: 1, depth: 7 }, { x: 0, z: 8, width: 10, depth: 1 },
        ...(kind === "home" ? [{ x: 1, z: 1, width: 2, depth: 2 }, { x: 2, z: 4, width: 2, depth: 1 }, { x: 7, z: 1, width: 2, depth: 1 }]
          : [{ x: 7, z: 3, width: 1, depth: 2 }, { x: 7, z: 1, width: 2, depth: 1 }])], levels: [], ramps: [] })),
    { id: "valbois-meadow", name: "Prairie des rencontres", width: 24, height: 20, spawn: { x: 2, y: 7 }, interior: false,
      paths: unique([...rectangle(0, 6, 20, 3), ...rectangle(11, 5, 3, 13), ...rectangle(13, 15, 7, 3), ...rectangle(17, 2, 3, 7)]), grass: [],
      instances: [instance("meadow-sign", "bw2-sign-02", 4.5, 9.5, .65),
        instance("meadow-stump", "bw2-stump-01", 5.5, 16, .55),
        instance("meadow-rock-1", "bw2-pinwheel-rock", 17.5, 5.5, 1.5),
        instance("meadow-rock-2", "bw2-pinwheel-rock", 20, 16, 1.8, 45)],
      blocks: [], levels: rectangle(16, 1, 6, 6).map(cell => ({ x: cell.x, z: cell.y, level: 1 })),
      ramps: [{ id: "meadow-slope", x: 17, z: 6, width: 3, depth: 3, lowLevel: 0, highLevel: 1, direction: "north" }] },
    { id: "valbois-forest", name: "Forêt de Valbois", width: 24, height: 24, spawn: { x: 11, y: 21 }, interior: false,
      paths: unique([...rectangle(10, 0, 3, 24), ...rectangle(4, 8, 9, 3), ...rectangle(10, 15, 10, 3),
        ...rectangle(3, 7, 6, 5), ...rectangle(15, 13, 6, 6)]), grass: [],
      instances: [instance("forest-sign", "bw2-sign-02", 13.5, 20.5, .65),
        instance("forest-hollow-stump", "bw2-stump-02", 5, 10, .65),
        instance("forest-pickup-model", "bw2-pinwheel-rock", 18.5, 15.5, .65),
        instance("forest-rock", "bw2-pinwheel-rock", 7.5, 16.5, 1.8)],
      blocks: [], levels: [], ramps: [] },
    { id: "valbois-clearing", name: "Clairière du vieux chêne", width: 16, height: 16, spawn: { x: 7, y: 13 }, interior: false,
      paths: unique([...rectangle(6, 8, 3, 8), ...rectangle(5, 6, 6, 5)]), grass: [],
      instances: [instance("clearing-old-tree", "bw2-pinwheel-tree", 7.5, 3.5, 1.45),
        instance("clearing-stump", "bw2-stump-01", 11, 10, .55),
        instance("clearing-sign", "bw2-sign-02", 4.5, 11.5, .65)], blocks: [{ x: 7, z: 3, width: 1, depth: 1 }], levels: [], ramps: [] },
  ];
  for (const area of encounterAreas) {
    maps.find(map => map.id === area.mapId)!.grass.push(...rectangle(area.x, area.y, area.width, area.height));
  }
  for (const map of maps.filter(map => !map.interior)) {
    const positions: Cell[] = [];
    for (let x = 1; x < map.width; x += 2) for (const y of [1, map.height - 1]) positions.push({ x, y });
    for (let y = 3; y < map.height - 2; y += 2) for (const x of [1, map.width - 1]) positions.push({ x, y });
    if (map.id === "valbois-forest") positions.push(...[
      { x: 5, y: 3 }, { x: 7, y: 3 }, { x: 15, y: 4 }, { x: 17, y: 5 }, { x: 19, y: 7 },
      { x: 5, y: 14 }, { x: 3, y: 16 }, { x: 5, y: 18 }, { x: 7, y: 20 }, { x: 17, y: 21 },
      { x: 20, y: 20 }, { x: 21, y: 11 },
    ]);
    for (const [index, cell] of positions.entries()) {
      const nearPath = map.paths.some(path => Math.abs(path.x - cell.x) <= 1 && Math.abs(path.y - cell.y) <= 1);
      const overlaps = map.blocks.some(block => cell.x >= block.x - 1 && cell.x < block.x + block.width + 1 && cell.y >= block.z - 1 && cell.y < block.z + block.depth + 1);
      if (nearPath || overlaps) continue;
      const level = map.levels.find(level => level.x === cell.x && level.z === cell.y)?.level;
      map.instances.push(instance(`${map.id}-tree-${index}`, "bw2-pinwheel-tree", cell.x + .5, cell.y + .5, 1, 0, Number(level ?? 0)));
      map.blocks.push({ x: cell.x, z: cell.y, width: 1, depth: 1 });
    }
  }
  for (const map of maps) for (const value of map.instances) {
    if (value.modelId !== "bw2-room-walls" && (map.interior || String(value.id).includes("stump") || String(value.id).includes("rock"))) value.blocksMovement = true;
  }
  return maps;
}

export function preset(id: string, name: string, atlasId: string, maskFrames = false,
  span = 1, usage = "terrain"): JsonRecord {
  const edges = ["northEdge", "eastEdge", "southEdge", "westEdge"];
  return { id, name, usage, topology: "cardinal_4", templateHint: "free", coveragePolicy: usage === "path" ? "sparse" : "complete",
    coverageProfile: { mode: "explicit", requiredScenarios: Array.from({ length: 16 }, (_, mask) => ({
      id: `${id}-${mask}`, centerMaterialId: id,
      signature: Object.fromEntries(edges.map((edge, index) => [edge, mask & (1 << index) ? id : null])) })) },
    defaultMaterialId: id, allowedMaterialIds: [id],
    rules: Array.from({ length: 16 }, (_, mask) => ({ id: `${id}-${mask}`,
      centerMatch: { kind: "material", materialId: id },
      signature: Object.fromEntries(edges.map((edge, index) => [edge, { kind: mask & (1 << index) ? "same" : "different" }])),
      candidates: [{ id: `${id}-frame-${mask}`, parts: [{ source: { kind: "frame", frame: { atlasId,
        column: maskFrames ? mask : 0, row: 0, columnSpan: span, rowSpan: span } },
        frameSampling: span > 1 ? "tessellated" : "full_frame", channel: "ground" }] }] })),
    tags: ["NB2", "Valbois"], transformPolicy: {} };
}

export async function authorValbois(args: string[]): Promise<void> {
  function option(name: string): string {
    const index = args.indexOf(name);
    assert.ok(index >= 0 && args[index + 1], `Required ${name}`);
    return resolve(args[index + 1]!);
  }
  const assetRoot = await realpath(option("--assets"));
  const playerRoot = await realpath(option("--player"));
  const npcRoot = await realpath(option("--npc-root"));
  const parent = await realpath(option("--parent"));
  const projectRoot = join(parent, "avelune_3d_village_demo");
  const layoutOnly = args.includes("--layout-only");
  const manifest = record(JSON.parse(await readFile(join(assetRoot, "bw2_village_assets_manifest.json"), "utf8")));
  const models = manifest.models as JsonRecord[];
  const textures = manifest.terrainTextures as JsonRecord[];
  const atlases = manifest.smartTileAtlases as JsonRecord[];
  assert.equal(models.length, 21);
  for (const resource of [...models, ...textures, ...atlases]) {
    const file = String(resource.file);
    assert.equal(file, file.split(/[\\/]/).at(-1));
    const bytes = await readFile(join(assetRoot, file));
    assert.equal(createHash("sha256").update(bytes).digest("hex"), resource.sha256, file);
  }
  const characters = [
    { id: "psdk-player", name: "Voyageur PSDK", file: "walk.png", root: playerRoot, sha: "ea9f9bdc96c95a5abaceee896577f4611c49ba76586654244568ff3a637123f3", run: true },
    { id: "psdk-professor", name: "Professeur PSDK", file: "npc_prof_elm.png", root: npcRoot, sha: "e2482fb401f70e0eea8d6e2652ee273f3c870c446e4dbc3294f528aaeeda35f4" },
    { id: "psdk-nurse", name: "Infirmière PSDK", file: "npc_nurse-01.png", root: npcRoot, sha: "4d872fc6b36b841577a5dbe1e9c7c505304f2b43ba2646d0522173e2d9b3f78f" },
    { id: "psdk-lass", name: "Villageoise PSDK", file: "npc_lass-01.png", root: npcRoot, sha: "cd77fd3ee8f06ac41ebb1cd570c04fa7693fb06dfc2b7ef17ba03ce1754eb8b3" },
    { id: "psdk-bug-catcher", name: "Jeune dresseur PSDK", file: "npc_bug-catcher-01.png", root: npcRoot, sha: "53ed77bb6bd0be8095973073321dec3bc25fc640256ccf17f2e5b212cebe06e3" },
    { id: "psdk-riley", name: "Garde forestier PSDK", file: "npc_riley.png", root: npcRoot, sha: "49018dd40a36ee8e5cefd8350dda3404c7cd564fe7b6669be0c601a9966eb579" },
  ];
  for (const character of characters) {
    const bytes = await readFile(join(character.root, character.file));
    assert.equal(createHash("sha256").update(bytes).digest("hex"), character.sha);
    assert.equal(bytes.readUInt32BE(16), 128);
    assert.equal(bytes.readUInt32BE(20), 128);
  }
  const runBytes = await readFile(join(playerRoot, "run.png"));
  assert.equal(createHash("sha256").update(runBytes).digest("hex"), "983f3e0c33120df5b08344e49331227a387134bc06507df049532550244ed9be");
  const maps = worldPlan();
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", parent, "--artifact-root", assetRoot,
      "--artifact-root", playerRoot, "--artifact-root", npcRoot, "--authoring-timeout-ms", "120000"],
    cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "avelune-valbois-native-author", version: "1.0.0" });
  let projectHandle = "", workspaceHandle = "", count = 0;
  const lastCalls = new Map<string, number>();
  async function call(name: string, parameters: JsonRecord = {}): Promise<JsonRecord> {
    const wait = 1100 - (Date.now() - (lastCalls.get(name) ?? 0));
    if (wait > 0) await delay(wait);
    lastCalls.set(name, Date.now());
    const response = await client.callTool({ name, arguments: parameters });
    const envelope = record(response.structuredContent);
    if (envelope.ok !== true) {
      const error = record(envelope.error);
      throw new CanonicalFailure(String(error.domainCode ?? error.code), error);
    }
    return record(envelope.data);
  }
  async function query(kind: string, id: string): Promise<JsonRecord> {
    return call("pokemap_query", { projectHandle, resourceKind: kind, operation: "get", ids: [id], view: "detail" });
  }
  async function project(): Promise<JsonRecord> {
    return record(((await query("project", "project")).items as unknown[])[0]);
  }
  async function mutate(actionId: string, parameters: JsonRecord): Promise<void> {
    const snapshot = await query("project", "project");
    const id = randomUUID();
    let plan: JsonRecord;
    try {
      plan = await call("pokemap_plan", { projectHandle, request: { requestId: id, idempotencyKey: id,
        workspaceHandle, actionId, actionVersion: 1, expectedRevision: snapshot.snapshotRevision, parameters } });
    } catch (error) {
      if (error instanceof CanonicalFailure && error.domainCode.endsWith(".no_change")) return;
      throw error;
    }
    const applied = await call("pokemap_apply", { operation: "apply", projectHandle, planId: plan.planId, operationId: id });
    assert.equal(record(applied.receipt).status, "applied", JSON.stringify(applied));
    if (++count % 25 === 0) process.stderr.write(`Valbois: ${count} canonical actions applied (${actionId})\n`);
  }
  async function stage(root: string, file: string, declaredMediaType = "image/png"): Promise<string> {
    const result = await call("pokemap_artifact_stage", { sourcePath: join(root, file), declaredMediaType });
    return String(result.artifactHandle);
  }
  try {
    await client.connect(transport);
    const catalog = await call("pokemap_describe");
    const actions = new Set((catalog.mutationActions as JsonRecord[]).map(action => action.id));
    for (const action of ["model3d.import", "map.create", "map.update_metadata", "map3d.navigation.configure",
      "map3d.terrain.set_levels", "map3d.instance.upsert", "tileset.import_image", "smart_tile.preset.publish",
      "smart_tile.cell.paint", "smart_tile.cell.erase", "connection.create_bidirectional_apply", "warp.create_reciprocal_apply",
      "dialogue.create", "entity.upsert", "gameplay_zone.create", "characterStudio.animationClip.upsert"]) assert.ok(actions.has(action), action);
    let exists = true;
    try { await access(projectRoot); } catch { exists = false; }
    if (!exists) {
      assert.ok(!layoutOnly, "A layout refresh requires the previously authored Valbois project");
      const request = { name: "Valbois — Voyage en 3D", folderName: "avelune_3d_village_demo", parentPath: parent,
        template: "empty", dimension: "threeD", tileSize: 32, mapWidth: 30, mapHeight: 24,
        spatialCamera: { mode: "fixed", pitchDegrees: 48.7, yawDegrees: 0, fieldOfViewDegrees: 24, distance: 42 } };
      const preview = await call("pokemap_project_create_preview", { request });
      const created = await call("pokemap_project_create", { request, confirmation: preview.confirmation });
      assert.equal(created.projectPath, projectRoot);
      assert.equal((created.mapIds as string[])[0], "first-map");
    }
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    workspaceHandle = String(opened.workspaceHandle);
    projectHandle = String(opened.projectHandle);
    let current = await project();
    assert.equal(record(current.settings).dimension, "threeD");
    assert.equal(current.name, "Valbois — Voyage en 3D");
    for (const map of maps) {
      if (!(current.maps as JsonRecord[]).some(entry => entry.id === map.id)) await mutate("map.create", {
        mapId: map.id, name: map.name, width: map.width, height: map.height, role: map.interior ? "interior" : "exterior" });
      else if ((current.maps as JsonRecord[]).find(entry => entry.id === map.id)!.name !== map.name) await mutate("map.update_metadata", { mapId: map.id, name: map.name });
    }
    for (const model of models) if (!((current.models3d ?? []) as JsonRecord[]).some(value => value.id === model.id)) {
      await mutate("model3d.import", { modelId: model.id, name: model.label,
        artifactHandle: await stage(assetRoot, String(model.file), "model/gltf-binary") });
    }
    for (const texture of [...textures, ...atlases]) if (!(current.tilesets as JsonRecord[]).some(value => value.id === texture.id)) {
      const size = texture.sizePx as number[];
      const width = size[0] === 8 ? 8 : 16;
      const height = size[1] === 8 ? 8 : 16;
      await mutate("tileset.import_image", { tilesetId: texture.id, name: texture.label,
        artifactHandle: await stage(assetRoot, String(texture.file)), tileWidth: width, tileHeight: height });
      await mutate("smart_tile.atlas.upsert", { atlas: { id: texture.id, name: texture.label, tilesetId: texture.id,
        cellWidth: width, cellHeight: height, columns: size[0]! / width, rows: size[1]! / height } });
    }
    const definitions = [
      preset("valbois-grass", "Herbe du village", "bw2-terrain-587487-grass01ax", false, 4),
      preset("valbois-forest-ground", "Herbe de la forêt", "bw2-terrain-587518-grass01ax", false, 4),
      preset("valbois-path", "Chemins de Valbois", "bw2-path-atlas-587487", true, 1, "path"),
      preset("valbois-forest-path", "Sentiers de la forêt", "bw2-path-atlas-587518", true, 1, "path"),
      preset("valbois-tall-grass", "Hautes herbes NB2", "bw2-terrain-587518-ue_grass00"),
      preset("valbois-floor", "Parquet de la maison", "bw2-terrain-583927-m_h02_01_lm1"),
      preset("valbois-carpet", "Tapis de la maison", "bw2-terrain-583927-m_h02_03_lm1", false, 2),
    ];
    current = await project();
    const smart = record(current.smartTileCatalog ?? {});
    for (const definition of definitions) {
      if (layoutOnly) continue;
      if (!((smart.materials ?? []) as JsonRecord[]).some(value => value.id === definition.id)) await mutate("smart_tile.material.upsert", {
        material: { id: definition.id, name: definition.name, connectionGroupId: definition.id } });
      await mutate("smart_tile.preset.publish", { preset: definition });
    }
    const characterIds = new Map<string, string>();
    for (const character of characters) {
      current = await project();
      let entry = (current.characters as JsonRecord[]).find(value => value.name === character.name);
      if (!entry) {
        const artifactHandle = await stage(character.root, character.file);
        await mutate("tileset.import_image", { artifactHandle, tilesetId: character.id, name: character.name, tileWidth: 32, tileHeight: 32 });
        await mutate("characterStudio.character.create", { name: character.name, tilesetId: character.id, frameWidth: 1, frameHeight: 1 });
        current = await project();
        entry = (current.characters as JsonRecord[]).find(value => value.name === character.name);
      }
      assert.ok(entry);
      const characterId = String(entry.id);
      characterIds.set(character.id, characterId);
      if (layoutOnly) continue;
      const assets = new Set(((await call("pokemap_query", { projectHandle, resourceKind: "asset", operation: "list", view: "summary", pageSize: 200 })).items as JsonRecord[]).map(asset => asset.id));
      for (const state of ["idle", "walk", ...(character.run ? ["run"] : [])]) {
        const assetId = `${character.id}-${state === "run" ? "run" : "walk"}`;
        if (!assets.has(assetId)) {
          await mutate("characterStudio.asset.import", { artifactHandle: await stage(character.root, state === "run" ? "run.png" : character.file),
            assetId, logicalPath: `assets/characters/valbois/${assetId}.png`, mediaKind: "spriteSheet", tags: ["PSDK", "Valbois"] });
          assets.add(assetId);
        }
        for (const [row, direction] of ["south", "west", "east", "north"].entries()) {
          const frames = (state === "idle" ? [0] : [1, 2, 3, 2]).map(column => ({
            source: { x: column * 32, y: row * 32, width: 32, height: 32 }, durationMs: state === "run" ? 85 : 117 }));
          const existing = (entry.animations as JsonRecord[]).find(clip => clip.state === state && clip.direction === direction);
          if (existing?.sourceAssetId === assetId && isDeepStrictEqual(existing.frames, frames)) continue;
          await mutate("characterStudio.animationClip.upsert", { characterId, kind: "system", state, direction, loop: true, sourceAssetId: assetId, frames });
        }
      }
    }
    current = await project();
    if (record(current.settings).defaultPlayerCharacterId !== characterIds.get("psdk-player")) await mutate("characterStudio.character.setDefault", { characterId: characterIds.get("psdk-player") });
    for (const map of maps) {
      const ground = map.interior ? "valbois-floor" : map.id.includes("forest") || map.id.includes("clearing") ? "valbois-forest-ground" : "valbois-grass";
      const path = pathPresetForMap(map.id);
      const layers = [{ id: "ground", preset: ground, name: "Sol" },
        ...(map.paths.length ? [{ id: "paths", preset: path, name: "Chemins" }] : []),
        ...(map.grass.length ? [{ id: "tall-grass", preset: "valbois-tall-grass", name: "Hautes herbes" }] : []),
        ...(map.interior ? [{ id: "carpet", preset: "valbois-carpet", name: "Tapis" }] : [])];
      const persisted = record(((await query("map", map.id)).items as unknown[])[0]);
      for (const layer of layers) if (!(persisted.layers as JsonRecord[]).some(value => value.id === layer.id)) await mutate("smart_tile.layer.create", {
        mapId: map.id, layerId: layer.id, name: layer.name, presetId: layer.preset });
      for (const [id, cells] of [["paths", map.paths], ["tall-grass", map.grass], ["carpet", map.interior ? rectangle(4, 6, 3, 2) : []]] as const) {
        const existing = (persisted.layers as JsonRecord[]).find(layer => layer.id === id);
        if (!existing) continue;
        const field = record(existing.field).semanticCells as number[];
        const surplus = surplusPaintedCells(field, map.width, cells);
        if (surplus.length) await mutate("smart_tile.cell.erase", { mapId: map.id, layerId: id, cells: surplus });
      }
      await mutate("smart_tile.cell.paint", { mapId: map.id, layerId: "ground", materialId: ground,
        selection: { kind: "rectangle", start: { x: 0, y: 0 }, end: { x: map.width - 1, y: map.height - 1 } } });
      if (map.paths.length) await mutate("smart_tile.cell.paint", { mapId: map.id, layerId: "paths", materialId: path, cells: map.paths });
      if (map.grass.length) await mutate("smart_tile.cell.paint", { mapId: map.id, layerId: "tall-grass", materialId: "valbois-tall-grass", cells: map.grass });
      if (map.interior) await mutate("smart_tile.cell.paint", { mapId: map.id, layerId: "carpet", materialId: "valbois-carpet", cells: rectangle(4, 6, 3, 2) });
      const order = (record(((await query("map", map.id)).items as unknown[])[0]).layers as JsonRecord[]).map(value => value.id);
      const operations: JsonRecord[] = [];
      for (const [newIndex, id] of layers.map(layer => layer.id).reverse().entries()) {
        const oldIndex = order.indexOf(id);
        if (oldIndex !== newIndex) {
          operations.push({ kind: "layer.reorder", oldIndex, newIndex });
          order.splice(newIndex, 0, ...order.splice(oldIndex, 1));
        }
      }
      if (operations.length) await mutate("map.apply_operations", { mapId: map.id, operations });
      if (map.levels.length) await mutate("map3d.terrain.set_levels", { mapId: map.id, cells: map.levels });
      await mutate("map3d.terrain.configure_appearance", { mapId: map.id, cliffFrame: { atlasId: "bw2-terrain-587518-yamagake01", column: 0, row: 0, rowSpan: 2 } });
      const spawn = layoutOnly ? record(record(persisted.spatialScene).navigation).spawn : { x: map.spawn.x + .5, z: map.spawn.y + .5 };
      await mutate("map3d.navigation.configure", { mapId: map.id, navigation: { spawn,
        allowDiagonalMovement: false, ramps: map.ramps, blockedAreas: map.blocks } });
      const existingInstances = record(persisted.spatialScene).instances as JsonRecord[];
      for (const value of map.instances) {
        const existing = existingInstances.find(instance => instance.id === value.id);
        if (existing && Object.keys(value).every(key => isDeepStrictEqual(value[key], existing[key]))) continue;
        await mutate("map3d.instance.upsert", { mapId: map.id, instance: value });
      }
      if (!layoutOnly) await mutate("entity.upsert", { mapId: map.id, entity: { id: `${map.id}-spawn`, name: `Départ — ${map.name}`, kind: "spawn",
        pos: map.spawn, size: { width: 1, height: 1 }, blocksMovement: false,
        spawn: { role: map.id === "first-map" ? "player_start" : "other", facing: "south" } } });
    }
    for (const connection of connections) {
      const map = record(((await query("map", connection.mapId)).items as unknown[])[0]);
      const existing = ((map.connections ?? []) as JsonRecord[]).find(value => value.direction === connection.direction);
      if (existing) assert.deepEqual(existing, { direction: connection.direction, targetMapId: connection.targetMapId, offset: connection.offset });
      else await mutate("connection.create_bidirectional_apply", connection);
    }
    for (const passage of passages) {
      const map = record(((await query("map", passage.mapId)).items as unknown[])[0]);
      if (!((map.warps ?? []) as JsonRecord[]).some(value => value.id === passage.warp.id)) await mutate("warp.create_reciprocal_apply", passage);
    }
    for (const actor of actors) {
      if (layoutOnly) continue;
      current = await project();
      const entry = { id: `${actor.id}-welcome`, name: `${actor.name} — accueil`, relativePath: `dialogues/${actor.id}-welcome.yarn`, defaultStartNode: "Accueil" };
      const source = `title: Accueil\n---\n${actor.lines.map(line => `${actor.name}: ${line}`).join("\n")}\n===\n`;
      await mutate((current.dialogues as JsonRecord[]).some(value => value.id === entry.id) ? "dialogue.update" : "dialogue.create", { entry, source });
      await mutate("entity.upsert", { mapId: actor.mapId, entity: { id: actor.id, name: actor.name, kind: "npc",
        pos: { x: actor.x, y: actor.y }, size: { width: 1, height: 1 }, blocksMovement: true,
        npc: { displayName: actor.name, characterId: characterIds.get(actor.character), facing: actor.facing } } });
      await mutate("npc.set_dialogue", { mapId: actor.mapId, entityId: actor.id, dialogue: { dialogueId: entry.id, startNode: "Accueil" } });
    }
    for (const zone of encounterAreas) {
      if (layoutOnly) continue;
      const map = record(((await query("map", zone.mapId)).items as unknown[])[0]);
      if (!((map.gameplayZones ?? []) as JsonRecord[]).some(value => value.id === zone.id)) await mutate("gameplay_zone.create", {
        mapId: zone.mapId, zone: { id: zone.id, name: "Hautes herbes", kind: "encounter",
          area: { pos: { x: zone.x, y: zone.y }, size: { width: zone.width, height: zone.height } }, encounter: {} } });
    }
    if (!layoutOnly) await mutate("entity.upsert", { mapId: "valbois-forest", entity: { id: "valbois-forest-pickup", name: "Objet trouvé dans la clairière", kind: "custom",
      pos: { x: 18, y: 15 }, size: { width: 1, height: 1 }, blocksMovement: true } });
    const provenance = await call("pokemap_query", { projectHandle, resourceKind: "asset", operation: "list", view: "summary", pageSize: 200 });
    if (!(provenance.items as JsonRecord[]).some(value => value.id === "valbois-bw2-provenance")) await mutate("asset.import", {
      artifactHandle: await stage(assetRoot, "bw2_village_assets_manifest.json", "application/json"),
      assetId: "valbois-bw2-provenance", logicalPath: "assets/provenance/valbois-bw2.json", tags: ["provenance", "NB2", "Valbois"] });
    const validation = await call("pokemap_validate", { projectHandle });
    current = await project();
    const finalMaps = [];
    for (const map of maps) finalMaps.push(record(((await query("map", map.id)).items as unknown[])[0]));
    process.stdout.write(`${JSON.stringify({ projectRoot, canonicalActions: count, characterIds: Object.fromEntries(characterIds),
      maps: finalMaps.map(map => ({ id: map.id, size: map.size, instances: (record(map.spatialScene).instances as unknown[]).length,
        layers: (map.layers as JsonRecord[]).map(layer => layer.id), entities: (map.entities as JsonRecord[]).map(entity => entity.id),
        connections: map.connections, warps: map.warps, gameplayZones: map.gameplayZones })),
      modelCount: (current.models3d as unknown[]).length, validation })}\n`);
  } finally {
    if (workspaceHandle) await call("pokemap_workspace", { operation: "close", workspaceHandle });
    await client.close();
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) await authorValbois(process.argv.slice(2));

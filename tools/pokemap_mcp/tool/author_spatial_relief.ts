import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { realpath } from "node:fs/promises";
import { join, resolve } from "node:path";
import { isDeepStrictEqual } from "node:util";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

const projectRoot = await realpath(resolve(process.argv[2] ?? ""));
const kitRoot = await realpath(resolve(process.argv[3] ?? ""));
const mapId = "atelier-relief-nb2";
const staircaseGroundClearance = .01;
const staircaseRamp = { id: "montee", x: 9.3125, z: 6, width: 1.375, depth: 1, lowLevel: 0, highLevel: 1, direction: "north" };
const staircaseRails = [
  { x: 8.8125, z: 6, width: .5, depth: 1 },
  { x: 10.6875, z: 6, width: .5, depth: 1 },
];
const transport = new StdioClientTransport({ command: process.execPath,
  args: [resolve("dist/src/index.js"), "--root", projectRoot, "--artifact-root", kitRoot],
  cwd: process.cwd(), stderr: "pipe" });
const client = new Client({ name: "avelune-native-relief-authoring", version: "1.0.0" });

async function call(name: string, args: JsonRecord = {}): Promise<JsonRecord> {
  const result = await client.callTool({ name, arguments: args });
  const envelope = record(result.structuredContent);
  assert.equal(envelope.ok, true, JSON.stringify(envelope.error));
  return record(envelope.data);
}

try {
  await client.connect(transport);
  const catalog = await call("pokemap_describe");
  assert.ok((catalog.mutationActions as JsonRecord[]).some((action) => action.id === "map3d.terrain.configure_appearance"));
  const opened = await call("pokemap_workspace", { operation: "open", projectRoot });
  const projectHandle = String(opened.projectHandle), workspaceHandle = String(opened.workspaceHandle);
  async function query(kind: string, id: string): Promise<JsonRecord> {
    return call("pokemap_query", { projectHandle, resourceKind: kind, operation: "get", ids: [id], view: "detail" });
  }
  async function mutate(actionId: string, parameters: JsonRecord): Promise<void> {
    const snapshot = await query("project", "project");
    const id = randomUUID();
    const plan = await call("pokemap_plan", { projectHandle, request: {
      requestId: id, actionId, actionVersion: 1, workspaceHandle, parameters,
      expectedRevision: snapshot.snapshotRevision, idempotencyKey: id } });
    await call("pokemap_apply", { operation: "apply", projectHandle, planId: plan.planId, operationId: id });
  }
  try {
    let project = record(((await query("project", "project")).items as unknown[])[0]);
    assert.equal(record(project.settings).dimension, "threeD");
    if ((project.maps as JsonRecord[]).some((entry) => entry.id === mapId) && process.argv[4] === "--add-stairs") {
      assert.ok((project.models3d as JsonRecord[]).some((model) => model.id === "stairs"));
      const map = record(((await query("map", mapId)).items as unknown[])[0]);
      assert.equal(map.name, "Atelier relief NB2");
      const navigation = record(record(map.spatialScene).navigation);
      const staircaseNavigation = {
        ...navigation, spawn: { x: 10, z: 10.5 },
        ramps: (navigation.ramps as JsonRecord[]).map((ramp) => ramp.id === "montee" ? staircaseRamp : ramp),
        blockedAreas: [...(navigation.blockedAreas as JsonRecord[]).filter((area) =>
          !staircaseRails.some((rail) => area.x === rail.x && area.z === rail.z && area.width === rail.width && area.depth === rail.depth)), ...staircaseRails] };
      if (!isDeepStrictEqual(navigation, staircaseNavigation)) {
        await mutate("map3d.navigation.configure", { mapId, navigation: staircaseNavigation });
      }
      const updatedMap = record(((await query("map", mapId)).items as unknown[])[0]);
      const staircase = {
        id: "escalier", modelId: "stairs", position: { x: 9, y: staircaseGroundClearance, z: 6 }, rotationDegrees: 0, scale: 1, animationIndex: null, blocksMovement: false };
      const existingStaircase = (record(updatedMap.spatialScene).instances as JsonRecord[]).find((instance) => instance.id === "escalier");
      if (!isDeepStrictEqual(existingStaircase, staircase)) {
        await mutate("map3d.instance.upsert", { mapId, instance: staircase });
      }
      console.log(JSON.stringify({ projectRoot, mapId, result: "stairs_added", validation: await call("pokemap_validate", { projectHandle }) }));
    } else if ((project.maps as JsonRecord[]).some((entry) => entry.id === mapId)) {
      console.log(JSON.stringify({ projectRoot, mapId, result: "already_exists_preserved" }));
    } else {
      assert.ok((record(project.smartTileCatalog).presets as JsonRecord[]).some((preset) => preset.id === "psdk-grass"));
      assert.ok((record(project.smartTileCatalog).presets as JsonRecord[]).some((preset) => preset.id === "psdk-paths"));
      if (!(project.models3d as JsonRecord[]).some((model) => model.id === "bw2-construction-house")) {
        const staged = await call("pokemap_artifact_stage", { sourcePath: join(kitRoot, "bw2_construction_house.glb"), declaredMediaType: "model/gltf-binary" });
        await mutate("model3d.import", { modelId: "bw2-construction-house", name: "Maison NB2 · chantier", artifactHandle: staged.artifactHandle });
      }
      if (!(project.tilesets as JsonRecord[]).some((image) => image.id === "bw2-cliff")) {
        const staged = await call("pokemap_artifact_stage", { sourcePath: join(kitRoot, "bw2_route20_cliff.png"), declaredMediaType: "image/png" });
        await mutate("tileset.import_image", { tilesetId: "bw2-cliff", name: "Paroi NB2 · Route 20", artifactHandle: staged.artifactHandle, tileWidth: 16, tileHeight: 32 });
      }
      project = record(((await query("project", "project")).items as unknown[])[0]);
      if (!(record(project.smartTileCatalog).atlases as JsonRecord[]).some((atlas) => atlas.id === "bw2-cliff")) {
        await mutate("smart_tile.atlas.upsert", { atlas: { id: "bw2-cliff", name: "Paroi NB2 · Route 20", tilesetId: "bw2-cliff", cellWidth: 16, cellHeight: 32, columns: 1, rows: 1 } });
      }
      await mutate("map.create", { mapId, name: "Atelier relief NB2", width: 14, height: 13 });
      await mutate("smart_tile.layer.create", { mapId, layerId: "herbe", name: "Herbe", presetId: "psdk-grass" });
      await mutate("smart_tile.layer.create", { mapId, layerId: "chemin", name: "Chemin", presetId: "psdk-paths" });
      const created = record(((await query("map", mapId)).items as unknown[])[0]);
      const order = (created.layers as JsonRecord[]).map((layer) => layer.id);
      const pathIndex = order.indexOf("chemin");
      if (pathIndex !== 0) await mutate("map.apply_operations", { mapId, operations: [{ kind: "layer.reorder", oldIndex: pathIndex, newIndex: 0 }] });
      const cells: JsonRecord[] = [];
      for (let z = 1; z <= 5; z++) for (let x = 2; x <= 11; x++) cells.push({ x, z, level: x >= 10 && z <= 2 ? 2 : 1 });
      await mutate("map3d.terrain.set_levels", { mapId, cells });
      await mutate("map3d.navigation.configure", { mapId, navigation: {
        spawn: { x: 10, z: 10.5 }, allowDiagonalMovement: false,
        ramps: [staircaseRamp], blockedAreas: staircaseRails } });
      await mutate("map3d.terrain.configure_appearance", { mapId, cliffFrame: { atlasId: "bw2-cliff", column: 0, row: 0 } });
      await mutate("smart_tile.cell.paint", { mapId, layerId: "herbe", materialId: "psdk-grass", selection: { kind: "rectangle", start: { x: 0, y: 0 }, end: { x: 13, y: 12 } } });
      await mutate("smart_tile.cell.paint", { mapId, layerId: "chemin", materialId: "psdk-dirt", selection: { kind: "rectangle", start: { x: 9, y: 4 }, end: { x: 10, y: 11 } } });
      await mutate("smart_tile.cell.paint", { mapId, layerId: "chemin", materialId: "psdk-dirt", selection: { kind: "rectangle", start: { x: 7, y: 4 }, end: { x: 10, y: 5 } } });
      await mutate("map3d.instance.upsert", { mapId, instance: {
        id: "maison-nb2", modelId: "bw2-construction-house", position: { x: 5, y: 1, z: 3 },
        rotationDegrees: 0, scale: 1, animationIndex: null, blocksMovement: true } });
      if ((project.models3d as JsonRecord[]).some((model) => model.id === "stairs")) {
        await mutate("map3d.instance.upsert", { mapId, instance: {
          id: "escalier", modelId: "stairs", position: { x: 9, y: staircaseGroundClearance, z: 6 }, rotationDegrees: 0, scale: 1, animationIndex: null, blocksMovement: false } });
      }
      await mutate("map3d.camera.configure", { mapId, camera: {
        mode: "fixed", pitchDegrees: 48.7, yawDegrees: 0, fieldOfViewDegrees: 24, distance: 35 } });
      const validation = await call("pokemap_validate", { projectHandle });
      assert.equal(record(validation.structure).valid, true, JSON.stringify(validation));
      const saved = record(((await query("map", mapId)).items as unknown[])[0]);
      console.log(JSON.stringify({ projectRoot, mapId, result: "created", revision: (await query("map", mapId)).snapshotRevision,
        raisedCells: (record(saved.spatialScene).heightLevels as number[]).filter((level) => level > 0).length,
        ramps: record(record(saved.spatialScene).navigation).ramps, validation }));
    }
  } finally {
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
  }
} finally {
  await client.close();
  await transport.close();
}

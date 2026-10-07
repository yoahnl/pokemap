import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { realpath } from "node:fs/promises";
import { join, resolve } from "node:path";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

const projectRoot = await realpath(resolve(process.argv[2] ?? ""));
const kitRoot = await realpath(resolve(process.argv[3] ?? ""));
const modelId = "bw2-normal-door-1", mapId = "atelier-animations";
const transport = new StdioClientTransport({ command: process.execPath,
  args: [resolve("dist/src/index.js"), "--root", projectRoot, "--artifact-root", kitRoot],
  cwd: process.cwd(), stderr: "pipe" });
const client = new Client({ name: "avelune-native-door-authoring", version: "1.0.0" });

async function call(name: string, args: JsonRecord = {}): Promise<JsonRecord> {
  const result = await client.callTool({ name, arguments: args });
  const envelope = record(result.structuredContent);
  assert.equal(envelope.ok, true, JSON.stringify(envelope.error));
  return record(envelope.data);
}

try {
  await client.connect(transport);
  const catalog = await call("pokemap_describe");
  const action = (catalog.mutationActions as JsonRecord[]).find((item) => item.id === "map3d.instance.upsert");
  assert.ok(action);
  const input = record(record(action.extensions).inputSchema);
  const instance = record(record(record(input.properties).instance).properties);
  assert.ok(instance.animationLoop && instance.animationSpeed);
  const opened = await call("pokemap_workspace", { operation: "open", projectRoot });
  const projectHandle = String(opened.projectHandle), workspaceHandle = String(opened.workspaceHandle);
  async function query(kind: string, id: string): Promise<JsonRecord> {
    return record(((await call("pokemap_query", { projectHandle, resourceKind: kind, operation: "get", ids: [id], view: "detail" })).items as unknown[])[0]);
  }
  async function mutate(actionId: string, parameters: JsonRecord): Promise<void> {
    const snapshot = await call("pokemap_validate", { projectHandle });
    const id = randomUUID();
    const plan = await call("pokemap_plan", { projectHandle, request: { requestId: id, actionId, actionVersion: 1,
      workspaceHandle, expectedRevision: snapshot.snapshotRevision, idempotencyKey: id, parameters } });
    await call("pokemap_apply", { operation: "apply", projectHandle, planId: plan.planId, operationId: id });
  }
  let project = await query("project", "project");
  assert.equal(record(project.settings).dimension, "threeD");
  if (!(project.models3d as JsonRecord[]).some((model) => model.id === modelId)) {
    const staged = await call("pokemap_artifact_stage", { sourcePath: join(kitRoot, "bw2_normal_door_1.glb"), declaredMediaType: "model/gltf-binary" });
    await mutate("model3d.import", { modelId, name: "Porte NB2 · ouverture et fermeture", artifactHandle: staged.artifactHandle });
  }
  project = await query("project", "project");
  const model = (project.models3d as JsonRecord[]).find((item) => item.id === modelId)!;
  assert.deepEqual((record(model.inspection).animations as JsonRecord[]).map((clip) => clip.name), ["door_op", "door_cl"]);
  if (!(project.maps as JsonRecord[]).some((map) => map.id === mapId)) {
    await mutate("map.create", { mapId, name: "Atelier animations", width: 8, height: 8 });
    const catalog = record(project.smartTileCatalog);
    const grass = (catalog.presets as JsonRecord[]).find((preset) => preset.id === "psdk-grass");
    if (grass) {
      await mutate("smart_tile.layer.create", { mapId, layerId: "herbe", name: "Herbe", presetId: grass.id });
      await mutate("smart_tile.cell.paint", { mapId, layerId: "herbe", materialId: "psdk-grass", selection: { kind: "rectangle", start: { x: 0, y: 0 }, end: { x: 7, y: 7 } } });
    }
    await mutate("map3d.navigation.configure", { mapId, navigation: { spawn: { x: 4.5, z: 6.5 }, allowDiagonalMovement: false, ramps: [], blockedAreas: [] } });
    await mutate("map3d.camera.configure", { mapId, camera: { mode: "fixed", pitchDegrees: 48.7, yawDegrees: 0, fieldOfViewDegrees: 16.2, distance: 24 } });
    for (const [id, x, animationIndex] of [["ouverture", 2.5, 0], ["fermeture", 5.5, 1]] as const) {
      await mutate("map3d.instance.upsert", { mapId, instance: { id, modelId, position: { x, y: 0, z: 3.5 }, rotationDegrees: 0,
        scale: 1, animationIndex, animationLoop: false, animationSpeed: .25, blocksMovement: true } });
    }
  }
  console.log(JSON.stringify({ projectRoot, mapId, modelId, result: "ready", scene: record((await query("map", mapId)).spatialScene), validation: await call("pokemap_validate", { projectHandle }) }));
  await call("pokemap_workspace", { operation: "close", workspaceHandle });
} finally {
  await client.close();
  await transport.close();
}

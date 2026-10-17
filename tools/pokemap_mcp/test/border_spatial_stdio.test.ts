import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import test from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

function unitGlb(animated = false): Buffer {
  const binary = Buffer.alloc(animated ? 68 : 36);
  [-.2, 0, -.2, .2, 0, -.2, 0, 1, .2].forEach((value, index) =>
    binary.writeFloatLE(value, index * 4));
  const gltf: JsonRecord = {
    asset: { version: "2.0" }, scene: 0,
    scenes: [{ nodes: [0] }], nodes: [{ mesh: 0 }],
    meshes: [{ primitives: [{ attributes: { POSITION: 0 } }] }],
    buffers: [{ byteLength: binary.length }],
    bufferViews: [{ buffer: 0, byteLength: 36 }],
    accessors: [{ bufferView: 0, componentType: 5126, count: 3,
      type: "VEC3", min: [-.2, 0, -.2], max: [.2, 1, .2] }],
  };
  if (animated) {
    binary.writeFloatLE(2, 40);
    binary.writeFloatLE(1, 56);
    (gltf.bufferViews as JsonRecord[]).push(
      { buffer: 0, byteOffset: 36, byteLength: 8 },
      { buffer: 0, byteOffset: 44, byteLength: 24 },
    );
    (gltf.accessors as JsonRecord[]).push(
      { bufferView: 1, componentType: 5126, count: 2, type: "SCALAR" },
      { bufferView: 2, componentType: 5126, count: 2, type: "VEC3" },
    );
    gltf.animations = [{ name: "Wind", samplers: [{ input: 1, output: 2 }],
      channels: [{ sampler: 0, target: { node: 0, path: "translation" } }] }];
  }
  const json = Buffer.from(JSON.stringify(gltf));
  const length = Math.ceil(json.length / 4) * 4;
  const bytes = Buffer.alloc(28 + length + binary.length);
  bytes.writeUInt32LE(0x46546c67, 0);
  bytes.writeUInt32LE(2, 4);
  bytes.writeUInt32LE(bytes.length, 8);
  bytes.writeUInt32LE(length, 12);
  bytes.writeUInt32LE(0x4e4f534a, 16);
  bytes.fill(32, 20, 20 + length);
  json.copy(bytes, 20);
  bytes.writeUInt32LE(binary.length, 20 + length);
  bytes.writeUInt32LE(0x004e4942, 24 + length);
  binary.copy(bytes, 28 + length);
  return bytes;
}

test("live MCP native Borders preserve editable strokes, live models and ownership", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-border-spatial-mcp-"));
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "border-spatial-transport-proof", version: "1.0.0" });
  async function call(name: string, args: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const response = await client.callTool({ name, arguments: args });
    assert.equal(response.isError, failure ? true : undefined, JSON.stringify(response.structuredContent));
    const envelope = record(response.structuredContent);
    return record(failure ? envelope.error : envelope.data);
  }
  try {
    await client.connect(transport);
    const catalog = await call("pokemap_describe");
    const actions = catalog.mutationActions as JsonRecord[];
    for (const id of ["border.blueprint.draft.upsert", "border.blueprint.publish",
      "border_layer.feature_create", "border_layer.materialize_apply",
      "map3d.instance.delete_batch"]) {
      assert.ok(actions.some(action => action.id === id), id);
    }
    for (const id of ["border_layer.feature_set_replacement", "border_layer.feature_set_transform",
      "border_layer.feature_set_suppressed", "border_layer.feature_clear_slot_override"]) {
      const action = actions.find(value => value.id === id)!;
      assert.deepEqual(record(action.extensions).visualKinds, ["element", "model3d"]);
    }
    assert.deepEqual(record(actions.find(value => value.id === "border_layer.feature_set_offset")!.extensions)
      .visualKinds, ["element"]);
    for (const id of ["border.blueprint.draft.upsert", "border.blueprint.publish"]) {
      assert.deepEqual(record(actions.find(value => value.id === id)!.extensions).spatialGroundContact,
        { enabledBy: "replacesGround", offsetField: "groundBaseOffset", offsetMaximum: 0,
          offsetUnits: "model", appliesTo: "nativeGroundOnly", preservesModelGeometry: true,
          footprintsField: "primitives[].groundFootprints", footprintsMinimumCatalogVersion: 8,
          footprintsCoordinates: "modelXZ", footprintsShape: "unionOfStrictlyConvexPolygons",
          footprintsMaximumPolygons: 8, footprintsVerticesPerPolygon: [3, 16],
          footprintsPreserveNavigation: true });
      assert.deepEqual(record(actions.find(value => value.id === id)!.extensions).spatialGroundMask,
        { enabledBy: "masksGroundCells", geometry: "cellCenteredStroke", scope: "allNativeGroundLayers",
          units: "logicalCell", independentOfMeshBounds: true, preservesNavigation: true });
    }
    const request = { name: "Native fences", folderName: "fences", parentPath: root,
      template: "empty", dimension: "threeD", mapWidth: 8, mapHeight: 6 };
    const preview = await call("pokemap_project_create_preview", { request });
    const created = await call("pokemap_project_create", { request, confirmation: preview.confirmation });
    const projectRoot = String(created.projectPath);
    let opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    let projectHandle = String(opened.projectHandle), workspaceHandle = String(opened.workspaceHandle);
    const manifestPath = join(projectRoot, "project.json");
    const manifest = record(JSON.parse(await readFile(manifestPath, "utf8")));
    const entry = (manifest.maps as JsonRecord[])[0]!;
    const mapId = String(entry.id), mapPath = join(projectRoot, String(entry.relativePath));
    let sequence = 0;
    async function plan(actionId: string, parameters: JsonRecord, failure = false): Promise<JsonRecord> {
      const validation = await call("pokemap_validate", { projectHandle });
      const before = await readFile(mapPath);
      const id = `native-border-${sequence++}`;
      const planned = await call("pokemap_plan", { projectHandle, request: {
        requestId: id, actionId, actionVersion: 1, workspaceHandle, parameters,
        expectedRevision: validation.snapshotRevision, idempotencyKey: id } }, failure);
      assert.deepEqual(await readFile(mapPath), before);
      return planned;
    }
    async function apply(planned: JsonRecord, failure = false): Promise<JsonRecord> {
      return call("pokemap_apply", { operation: "apply", projectHandle,
        planId: planned.planId, operationId: `native-border-apply-${sequence++}` }, failure);
    }
    async function mutate(actionId: string, parameters: JsonRecord): Promise<void> {
      const applied = await apply(await plan(actionId, parameters));
      assert.equal(record(applied.receipt).status, "applied");
    }
    const modelPath = join(root, "fence.glb");
    await writeFile(modelPath, unitGlb());
    const artifact = await call("pokemap_artifact_stage", {
      sourcePath: modelPath, declaredMediaType: "model/gltf-binary" });
    await mutate("model3d.import", { modelId: "fence-unit", name: "Fence", artifactHandle: artifact.artifactHandle });
    await mutate("map.apply_operations", { mapId, operations: [
      { kind: "layer.add", layerKind: "border", layerId: "fences", name: "Fences" },
    ] });
    const cliffDefinition = {
      name: "Directed cliff", previewSeed: "17", template: "connectedLine", sortOrder: 0,
      followContourDirection: true,
      replacesGround: true,
      groundBaseOffset: -.0625,
      primitives: [
        { id: "cliff-straight", role: "lineStraight" },
        { id: "cliff-cap", role: "lineCap" },
        { id: "cliff-right", role: "lineCorner", cornerTurn: "right" },
        { id: "cliff-left", role: "lineCorner", cornerTurn: "left" },
      ].map(piece => ({ ...piece, sourceModelId: "fence-unit", weight: 1,
        authoredOrientation: "east", anchorWorld: { x: 0, y: 2, z: 0 },
        transforms: { allowFlipX: false, allowedQuarterTurns: [0, 1, 2, 3] } })),
      defaults: { irregularityPermille: 0, detailDensityPermille: 0,
        variationPermille: 0, maxOverlapPx: 0, gapTolerancePx: 0, depthRows: 1 },
    };
    await mutate("border.blueprint.draft.upsert", { record: { id: "cliff",
      draft: { baseRevision: 0, definition: cliffDefinition } } });
    await mutate("border.blueprint.publish", { blueprintId: "cliff" });
    const cliffPublished = record(JSON.parse(await readFile(manifestPath, "utf8")));
    const cliffRecord = (record(cliffPublished.borderCatalog).records as JsonRecord[])
      .find(value => value.id === "cliff")!;
    const publishedDefinition = record(record(cliffRecord.latestPublished).definition);
    assert.equal(publishedDefinition.followContourDirection, true);
    assert.equal(publishedDefinition.replacesGround, true);
    assert.equal(publishedDefinition.groundBaseOffset, -.0625);
    const cliffQuery = await call("pokemap_query", { projectHandle, resourceKind: "borderBlueprint",
      operation: "get", ids: ["cliff"], view: "detail" });
    const queriedCliff = record((cliffQuery.items as JsonRecord[])[0]);
    for (const section of ["draft", "latestPublished"]) {
      assert.equal(record(record(queriedCliff[section]).definition).groundBaseOffset, -.0625);
    }
    assert.deepEqual(new Set((publishedDefinition.primitives as JsonRecord[])
      .filter(piece => piece.role === "lineCorner").map(piece => piece.cornerTurn)),
      new Set(["left", "right"]));
    const plateauCells = Array.from({ length: 48 }, (_, index) => {
      const x = index % 8, z = Math.floor(index / 8);
      return { x, z, level: x >= 1 && x <= 6 && z >= 1 && z <= 4 && !(x === 3 && z === 2) ? 8 : 0 };
    });
    await mutate("map3d.terrain.set_levels", { mapId, cells: plateauCells });
    const cliffTarget = { mapId, layerId: "fences", featureId: "cliff" };
    await mutate("border_layer.feature_create", { ...cliffTarget, blueprintId: "cliff",
      name: "Plateau with a hole", seed: "17", geometry: { kind: "region", width: 8, height: 6,
        cells: plateauCells.map(cell => cell.level === 8) } });
    await mutate("border_layer.materialize_apply", cliffTarget);
    const cliffBytes = await readFile(mapPath);
    const cliffMap = record(JSON.parse(cliffBytes.toString()));
    const cliffInstances = record(cliffMap.spatialScene).instances as JsonRecord[];
    assert.equal(cliffInstances.length, 24);
    assert.deepEqual(new Set(cliffInstances.map(instance => instance.rotationDegrees)),
      new Set([0, -90, -180, -270]));
    const expectedCliffY = Number(record(cliffMap.spatialScene).levelHeight ?? .25) * 8 - 2;
    assert.ok(cliffInstances.every(instance => record(instance.position).y === expectedCliffY));
    const cliffLayer = (cliffMap.layers as JsonRecord[]).find(value => value.id === "fences")!;
    const cliffFeature = (record(cliffLayer.content).features as JsonRecord[]).find(value => value.id === "cliff")!;
    const cornerIds = new Set((record(cliffFeature.materialization).spatialPlacements as JsonRecord[])
      .map(piece => piece.primitiveId));
    assert.ok(cornerIds.has("cliff-left") && cornerIds.has("cliff-right"));
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
    opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    projectHandle = String(opened.projectHandle); workspaceHandle = String(opened.workspaceHandle);
    assert.deepEqual(await readFile(mapPath), cliffBytes);
    await mutate("border_layer.feature_delete", cliffTarget);
    const edgeTarget = { mapId, layerId: "fences", featureId: "cliff-edge" };
    await mutate("border_layer.feature_create", { ...edgeTarget, blueprintId: "cliff",
      name: "Westward cliff", seed: "17", geometry: { kind: "stroke", alignment: "gridEdges",
        strokes: [{ id: "edge", closed: false,
          points: [6, 5, 4, 3, 2, 1].map(x => ({ x, y: 5 })) }] } });
    await mutate("border_layer.materialize_apply", edgeTarget);
    const edgeMap = record(JSON.parse(await readFile(mapPath, "utf8")));
    const edgeInstances = record(edgeMap.spatialScene).instances as JsonRecord[];
    assert.equal(edgeInstances.length, 6);
    assert.ok(edgeInstances.every(instance => record(instance.position).y === expectedCliffY));
    assert.ok(edgeInstances.every(instance => instance.rotationDegrees === -180));
    const edgeLayer = (edgeMap.layers as JsonRecord[]).find(value => value.id === "fences")!;
    const edgeFeature = (record(edgeLayer.content).features as JsonRecord[]).find(value => value.id === "cliff-edge")!;
    const edgeStroke = record((record(edgeFeature.geometry).strokes as JsonRecord[])[0]);
    assert.equal((edgeStroke.points as JsonRecord[])[0]!.x, 6);
    await mutate("border_layer.feature_delete", edgeTarget);
    const centerTarget = { mapId, layerId: "fences", featureId: "cliff-crown" };
    await mutate("border_layer.feature_create", { ...centerTarget, blueprintId: "cliff",
      name: "Crown beside the upper land", seed: "17",
      geometry: { kind: "stroke", alignment: "cellCenters",
        strokes: [{ id: "crown", closed: false,
          points: [1, 2, 3, 4, 5, 6].map(x => ({ x, y: 0 })) }] } });
    await mutate("border_layer.materialize_apply", centerTarget);
    const centerBytes = await readFile(mapPath);
    const centerMap = record(JSON.parse(centerBytes.toString()));
    const centerInstances = record(centerMap.spatialScene).instances as JsonRecord[];
    assert.equal(centerInstances.length, 6);
    assert.ok(centerInstances.every(instance => record(instance.position).y === expectedCliffY));
    assert.ok(centerInstances.every(instance => record(instance.position).z === .5));
    assert.ok(centerInstances.every(instance => instance.rotationDegrees === 0));
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
    opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    projectHandle = String(opened.projectHandle); workspaceHandle = String(opened.workspaceHandle);
    assert.deepEqual(await readFile(mapPath), centerBytes);
    await mutate("border_layer.feature_delete", centerTarget);
    await mutate("map3d.terrain.set_levels", { mapId, cells: plateauCells.map(cell => ({ ...cell, level: 0 })) });
    const draft = { id: "fence", draft: { baseRevision: 0, definition: {
      name: "Fence", previewSeed: "17", template: "connectedLine", sortOrder: 0,
      primitives: ["lineStraight", "lineCorner", "lineCap"].map(role => ({
        id: role, sourceModelId: "fence-unit", role, weight: 1,
        transforms: { allowFlipX: false, allowedQuarterTurns: [0, 1, 2, 3] },
      })), defaults: { irregularityPermille: 0, detailDensityPermille: 0,
        variationPermille: 1000, maxOverlapPx: 0, gapTolerancePx: 0, depthRows: 1 },
    } } };
    await mutate("border.blueprint.draft.upsert", { record: draft });
    await mutate("border.blueprint.publish", { blueprintId: "fence" });
    const published = record(JSON.parse(await readFile(manifestPath, "utf8")));
    const border = record(published.borderCatalog);
    assert.deepEqual(border.visualSnapshots, []);
    assert.ok(!JSON.stringify(border.records).includes("visualSnapshotId"));
    const free = ["free-a", "free-b"].map((id, index) => ({
      id, modelId: "fence-unit", position: { x: 5.5, y: 0, z: 1.5 + index },
      rotationDegrees: 0, scale: 1, blocksMovement: false,
    }));
    await mutate("map3d.instance.upsert_batch", { mapId, instances: free });
    const beforeDelete = await readFile(mapPath);
    await plan("map3d.instance.delete_batch", { mapId, instanceIds: ["free-a", "missing"] }, true);
    assert.deepEqual(await readFile(mapPath), beforeDelete);
    await mutate("map3d.instance.delete_batch", { mapId, instanceIds: free.map(value => value.id) });
    const afterDelete = record(JSON.parse(await readFile(mapPath, "utf8")));
    assert.deepEqual(record(afterDelete.spatialScene).instances, []);
    const straightDraft = { id: "straight-cliff", draft: { baseRevision: 0, definition: {
      ...draft.draft.definition, name: "Straight cliff", straightOnly: true,
      primitives: draft.draft.definition.primitives.filter(value => value.role !== "lineCorner"),
    } } };
    await mutate("border.blueprint.draft.upsert", { record: straightDraft });
    await mutate("border.blueprint.publish", { blueprintId: "straight-cliff" });
    const straightFeature = { mapId, layerId: "fences", featureId: "straight",
      blueprintId: "straight-cliff", name: "Straight cliff", seed: "19",
      lineSide: "primary", spatialOffsetWorld: { x: .25, y: 2, z: .125 },
      geometry: { kind: "stroke", strokes: [{ id: "straight-line", closed: false,
        points: [{ x: 1, y: 4 }, { x: 2, y: 4 }, { x: 3, y: 4 }],
      }] },
    };
    const rejectedTurn = await plan("border_layer.feature_create", {
      ...straightFeature,
      geometry: { kind: "stroke", strokes: [{ id: "turn", closed: false,
        points: [{ x: 1, y: 4 }, { x: 2, y: 4 }, { x: 2, y: 5 }],
      }] },
    }, true);
    assert.ok(JSON.stringify(rejectedTurn).includes("border.spatial.straight_only_geometry_required"));
    await mutate("border_layer.feature_create", straightFeature);
    await mutate("border_layer.materialize_apply", { mapId, layerId: "fences", featureId: "straight" });
    const straightSaved = record(JSON.parse(await readFile(mapPath, "utf8")));
    const offsetInstances = record(straightSaved.spatialScene).instances as JsonRecord[];
    assert.equal(offsetInstances.length, 3);
    const straightLayer = (straightSaved.layers as JsonRecord[]).find(value => value.id === "fences")!;
    const straight = (record(straightLayer.content).features as JsonRecord[])[0]!;
    assert.deepEqual(straight.spatialOffsetWorld, straightFeature.spatialOffsetWorld);
    assert.equal(straight.lineSide ?? "primary", "primary");
    await mutate("border_layer.feature_update", {
      mapId, layerId: "fences", featureId: "straight", spatialOffsetWorld: null,
    });
    await mutate("border_layer.materialize_apply", { mapId, layerId: "fences", featureId: "straight" });
    const unshifted = record(JSON.parse(await readFile(mapPath, "utf8")));
    for (const instance of record(unshifted.spatialScene).instances as JsonRecord[]) {
      const shifted = offsetInstances.find(value => value.id === instance.id)!;
      const position = record(instance.position), shiftedPosition = record(shifted.position);
      assert.equal(Number(shiftedPosition.x) - Number(position.x), .25);
      assert.equal(Number(shiftedPosition.y) - Number(position.y), 2);
      assert.equal(Number(shiftedPosition.z) - Number(position.z), .125);
    }
    await mutate("border_layer.feature_update", {
      mapId, layerId: "fences", featureId: "straight", lineSide: "inverted",
    });
    const invertedBytes = await readFile(mapPath);
    const inverted = record(JSON.parse(invertedBytes.toString()));
    assert.deepEqual(record(inverted.spatialScene).instances, record(unshifted.spatialScene).instances);
    const rejectedInversion = await plan("border_layer.materialize_apply", {
      mapId, layerId: "fences", featureId: "straight",
    }, true);
    assert.ok(JSON.stringify(rejectedInversion).includes("border.spatial.line_side_inversion_unsupported"));
    assert.ok(JSON.stringify(rejectedInversion).includes("border.action.use_primary_line_side"));
    assert.deepEqual(await readFile(mapPath), invertedBytes);
    await mutate("border_layer.feature_delete", { mapId, layerId: "fences", featureId: "straight" });
    const afterStraight = record(JSON.parse(await readFile(mapPath, "utf8")));
    assert.deepEqual(record(afterStraight.spatialScene).instances, []);
    const maskDraft = { id: "masked-wall", draft: { baseRevision: 0, definition: {
      ...straightDraft.draft.definition, name: "Wall with independent ground mask",
      replacesGround: false, groundBaseOffset: 0, masksGroundCells: true,
    } } };
    await mutate("border.blueprint.draft.upsert", { record: maskDraft });
    await mutate("border.blueprint.publish", { blueprintId: "masked-wall" });
    const maskTarget = { mapId, layerId: "fences", featureId: "masked-wall" };
    const maskGeometry = { kind: "stroke", alignment: "cellCenters", strokes: [{ id: "mask", closed: false,
      points: [{ x: 1, y: 4 }, { x: 2, y: 4 }, { x: 3, y: 4 }] }] };
    const maskedBefore = await readFile(mapPath);
    const unsupportedMask = await plan("border_layer.feature_create", { ...maskTarget,
      blueprintId: "masked-wall", name: "Unsupported edge", seed: "19",
      geometry: { ...maskGeometry, alignment: "gridEdges" } }, true);
    assert.ok(JSON.stringify(unsupportedMask).includes("border.spatial.ground_mask_cell_centers_required"), JSON.stringify(unsupportedMask));
    assert.deepEqual(await readFile(mapPath), maskedBefore);
    await mutate("border_layer.feature_create", { ...maskTarget, blueprintId: "masked-wall", name: "Masked wall", seed: "19", geometry: maskGeometry });
    await mutate("border_layer.materialize_apply", maskTarget);
    const maskedMapBytes = await readFile(mapPath);
    const maskedDefinition = await call("pokemap_query", { projectHandle, resourceKind: "borderBlueprint", operation: "get", ids: ["masked-wall"], view: "detail" });
    for (const section of ["draft", "latestPublished"]) {
      assert.equal(record(record((maskedDefinition.items as JsonRecord[])[0]![section]).definition).masksGroundCells, true);
    }
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
    opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    projectHandle = String(opened.projectHandle); workspaceHandle = String(opened.workspaceHandle);
    assert.deepEqual(await readFile(mapPath), maskedMapBytes);
    await mutate("border_layer.feature_delete", maskTarget);
    assert.deepEqual(record(record(JSON.parse(await readFile(mapPath, "utf8"))).spatialScene).instances, []);
    const repeatedDraft = { id: "repeated-unit", draft: { baseRevision: 0, definition: {
      ...draft.draft.definition, name: "Repeated shore unit", straightOnly: true,
      primitives: [
        { id: "body", sourceModelId: "fence-unit", role: "lineStraight", weight: 1,
          authoredOrientation: "south", anchorWorld: { x: 0, y: .25, z: 0 },
          transforms: { allowFlipX: false, allowedQuarterTurns: [0, 1, 2, 3] } },
        ...["south", "north"].map((authoredOrientation, index) => ({
          id: `cap-${index}`, sourceModelId: "fence-unit", role: "lineCap", weight: 1,
          authoredOrientation, anchorWorld: { x: 0, y: .25, z: 0 },
          transforms: { allowFlipX: false, allowedQuarterTurns: [1, 2] },
        })),
      ],
    } } };
    await mutate("border.blueprint.draft.upsert", { record: repeatedDraft });
    await mutate("border.blueprint.publish", { blueprintId: "repeated-unit" });
    const repeatedFeature = { ...straightFeature, featureId: "repeated", blueprintId: "repeated-unit",
      lineSide: "inverted", spatialOffsetWorld: { x: 0, y: .25, z: .125 },
      geometry: { kind: "stroke", alignment: "cellCenters", strokes: [{ id: "repeated-line", closed: false,
        points: [{ x: 1, y: 4 }, { x: 2, y: 4 }, { x: 3, y: 4 }],
      }] },
    };
    const badRepeated = await plan("border_layer.feature_create", { ...repeatedFeature,
      featureId: "bad-repeated", geometry: { kind: "stroke", strokes: [{ id: "bad-line", closed: false,
        points: [{ x: 1, y: 4 }, { x: 2, y: 4 }, { x: 2, y: 5 }],
      }] },
    }, true);
    assert.ok(JSON.stringify(badRepeated).includes("border.spatial.straight_only_geometry_required"));
    await mutate("border_layer.feature_create", repeatedFeature);
    const repeatedTarget = { mapId, layerId: "fences", featureId: "repeated" };
    const repeatedPreview = await plan("border_layer.materialize_apply", repeatedTarget);
    assert.ok(JSON.stringify(record(repeatedPreview.plan).preview).includes("modelInstances"));
    await apply(repeatedPreview);
    const repeatedBytes = await readFile(mapPath);
    const repeatedSaved = record(JSON.parse(repeatedBytes.toString()));
    const repeatedInstances = record(repeatedSaved.spatialScene).instances as JsonRecord[];
    assert.equal(repeatedInstances.length, 3);
    assert.ok(repeatedInstances.every(instance => instance.rotationDegrees === -90));
    for (const [index, instance] of repeatedInstances.entries()) {
      assert.deepEqual(instance.position, { x: index + 1.5, y: 0, z: 4.625 });
    }
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
    opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    projectHandle = String(opened.projectHandle); workspaceHandle = String(opened.workspaceHandle);
    assert.deepEqual(await readFile(mapPath), repeatedBytes);
    await mutate("border_layer.feature_delete", repeatedTarget);
    await mutate("border_layer.feature_create", { mapId, layerId: "fences", featureId: "fence",
      blueprintId: "fence", name: "Fence", seed: "17", geometry: { kind: "stroke", strokes: [
        { id: "line", closed: false, points: [{ x: 1, y: 1 }, { x: 2, y: 1 }, { x: 3, y: 1 }, { x: 3, y: 2 }] },
      ] } });
    const target = { mapId, layerId: "fences", featureId: "fence" };
    const stalePlan = await plan("border_layer.materialize_apply", target);
    assert.ok(JSON.stringify(record(stalePlan.plan).preview).includes("modelInstances"));
    await mutate("model3d.configure", { modelId: "fence-unit", name: "Live renamed source" });
    assert.equal((await apply(stalePlan, true)).code, "revision_conflict");
    const before = await readFile(mapPath);
    await mutate("border_layer.materialize_apply", target);
    const savedBytes = await readFile(mapPath);
    const saved = record(JSON.parse(savedBytes.toString()));
    const instances = record(saved.spatialScene).instances as JsonRecord[];
    assert.equal(instances.length, 4);
    assert.deepEqual(saved.placedElements, []);
    assert.ok(instances.every(instance => instance.modelId === "fence-unit"));
    const layer = (saved.layers as JsonRecord[]).find(value => value.id === "fences")!;
    const feature = (record(layer.content).features as JsonRecord[])[0]!;
    const materialization = record(feature.materialization);
    assert.equal((materialization.spatialPlacements as JsonRecord[]).length, 4);
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
    opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    projectHandle = String(opened.projectHandle); workspaceHandle = String(opened.workspaceHandle);
    assert.deepEqual(await readFile(mapPath), savedBytes);
    const history = await call("pokemap_history", { operation: "list", projectHandle, limit: 1 });
    await call("pokemap_history", { operation: "undo", projectHandle,
      entryId: record((history.entries as JsonRecord[])[0]).entryId, idempotencyKey: "undo-native-border" });
    assert.deepEqual(await readFile(mapPath), before);

    const variantArtifact = await call("pokemap_artifact_stage", {
      sourcePath: modelPath, declaredMediaType: "model/gltf-binary" });
    await mutate("model3d.import", { modelId: "alternate-unit", name: "Alternate fence",
      artifactHandle: variantArtifact.artifactHandle });
    const straightPrimitive = draft.draft.definition.primitives.find(value => value.role === "lineStraight")!;
    await mutate("border.blueprint.draft.upsert", { record: { id: "slot-fence", draft: {
      baseRevision: 0, definition: { ...draft.draft.definition, name: "Fence variants",
        defaults: { ...draft.draft.definition.defaults, variationPermille: 0 },
        primitives: [...draft.draft.definition.primitives,
          { ...straightPrimitive, id: "z-alternate", sourceModelId: "alternate-unit" }],
      },
    } } });
    await mutate("border.blueprint.publish", { blueprintId: "slot-fence" });
    await mutate("map3d.instance.upsert_batch", { mapId, instances: [free[0]!] });
    const slotTarget = { mapId, layerId: "fences", featureId: "variant" };
    await mutate("border_layer.feature_create", { ...slotTarget, blueprintId: "slot-fence",
      name: "Variants", seed: "0", geometry: { kind: "stroke", strokes: [{ id: "variant-line",
        closed: false, points: [1, 2, 3].map(x => ({ x, y: 4 })) }] } });
    await mutate("border_layer.materialize_apply", slotTarget);
    const originalVariantBytes = await readFile(mapPath);
    const originalVariant = record(JSON.parse(originalVariantBytes.toString()));
    const originalInstances = record(originalVariant.spatialScene).instances as JsonRecord[];
    const selected = originalInstances.find(value => record(value.position).x === 2.5
      && record(value.position).z === 4.5)!;
    assert.equal(selected.modelId, "fence-unit");
    function variantFeature(map: JsonRecord): JsonRecord {
      const borders = (map.layers as JsonRecord[]).find(value => value.id === "fences")!;
      return (record(borders.content).features as JsonRecord[]).find(value => value.id === "variant")!;
    }
    const slotKey = (record(variantFeature(originalVariant).materialization).spatialPlacements as JsonRecord[])
      .find(value => value.instanceId === selected.id)!.slotKey;
    const slotParameters = { ...slotTarget, slotKey };
    const variantManifestBytes = await readFile(manifestPath);
    await mutate("border_layer.feature_set_replacement", { ...slotParameters, primitiveId: "z-alternate" });
    const pendingVariant = record(JSON.parse(await readFile(mapPath, "utf8")));
    assert.deepEqual(record(pendingVariant.spatialScene).instances, originalInstances);
    await mutate("border_layer.materialize_apply", slotTarget);
    const replaced = record(JSON.parse(await readFile(mapPath, "utf8")));
    const replacedInstances = record(replaced.spatialScene).instances as JsonRecord[];
    assert.equal(replacedInstances.find(value => value.id === selected.id)!.modelId, "alternate-unit");
    assert.deepEqual(replacedInstances.filter(value => value.id !== selected.id),
      originalInstances.filter(value => value.id !== selected.id));
    await mutate("border_layer.feature_set_transform", { ...slotParameters,
      transformOverride: { quarterTurns: 1, flipX: false } });
    await mutate("border_layer.materialize_apply", slotTarget);
    const rotated = record(JSON.parse(await readFile(mapPath, "utf8")));
    const rotatedInstance = (record(rotated.spatialScene).instances as JsonRecord[])
      .find(value => value.id === selected.id)!;
    assert.equal(rotatedInstance.rotationDegrees, -90);
    assert.deepEqual(rotatedInstance.position, selected.position);
    await mutate("border_layer.feature_set_suppressed", { ...slotParameters, suppressed: true });
    await mutate("border_layer.materialize_apply", slotTarget);
    const suppressed = record(JSON.parse(await readFile(mapPath, "utf8")));
    assert.deepEqual(record(suppressed.spatialScene).instances,
      originalInstances.filter(value => value.id !== selected.id));
    await mutate("border_layer.feature_clear_slot_override", slotParameters);
    await mutate("border_layer.materialize_apply", slotTarget);
    assert.deepEqual(await readFile(mapPath), originalVariantBytes);
    assert.deepEqual(await readFile(manifestPath), variantManifestBytes);
    const missingSlot = await plan("border_layer.feature_set_replacement",
      { ...slotParameters, slotKey: "missing", primitiveId: "z-alternate" }, true);
    assert.ok(JSON.stringify(missingSlot).includes("border.slot_missing"), JSON.stringify(missingSlot));
    const mirroredSlot = await plan("border_layer.feature_set_transform", { ...slotParameters,
      transformOverride: { quarterTurns: 0, flipX: true } }, true);
    assert.ok(JSON.stringify(mirroredSlot).includes("border.spatial.sprite_override_unsupported"), JSON.stringify(mirroredSlot));
    const pixelOffset = await plan("border_layer.feature_set_offset", { ...slotParameters,
      offsetDeltaPx: null }, true);
    assert.ok(JSON.stringify(pixelOffset).includes("border.spatial.sprite_override_unsupported"), JSON.stringify(pixelOffset));
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
    opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    projectHandle = String(opened.projectHandle); workspaceHandle = String(opened.workspaceHandle);
    assert.deepEqual(await readFile(mapPath), originalVariantBytes);
    assert.deepEqual(await readFile(manifestPath), variantManifestBytes);
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

test("live MCP native Border contracts preserve explicit playback, collision and a null default clip", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-border-behavior-mcp-"));
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "border-playback-transport-proof", version: "1.0.0" });
  async function call(name: string, args: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const response = await client.callTool({ name, arguments: args });
    assert.equal(response.isError, failure ? true : undefined, JSON.stringify(response.structuredContent));
    const envelope = record(response.structuredContent);
    return record(failure ? envelope.error : envelope.data);
  }
  try {
    await client.connect(transport);
    const catalog = await call("pokemap_describe");
    const actions = catalog.mutationActions as JsonRecord[];
    const upsert = actions.find(action => action.id === "border.blueprint.draft.upsert")!;
    const publish = actions.find(action => action.id === "border.blueprint.publish")!;
    for (const field of ["animationIndex", "animationLoop", "animationSpeed", "blocksMovement"]) {
      assert.ok(String(upsert.summary).includes(field), field);
    }
    assert.equal(record(upsert.extensions).catalogFormatVersion, 10);
    assert.ok(String(publish.summary).includes("null animationIndex does not start a clip"));
    const request = { name: "Native playback", folderName: "playback", parentPath: root,
      template: "empty", dimension: "threeD", mapWidth: 8, mapHeight: 6 };
    const preview = await call("pokemap_project_create_preview", { request });
    const created = await call("pokemap_project_create", { request, confirmation: preview.confirmation });
    const projectRoot = String(created.projectPath);
    let opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    let projectHandle = String(opened.projectHandle), workspaceHandle = String(opened.workspaceHandle);
    const manifestPath = join(projectRoot, "project.json");
    const manifest = record(JSON.parse(await readFile(manifestPath, "utf8")));
    const entry = (manifest.maps as JsonRecord[])[0]!;
    const mapId = String(entry.id), mapPath = join(projectRoot, String(entry.relativePath));
    let sequence = 0;
    async function plan(actionId: string, parameters: JsonRecord, failure = false): Promise<JsonRecord> {
      const beforeManifest = await readFile(manifestPath), beforeMap = await readFile(mapPath);
      const validation = await call("pokemap_validate", { projectHandle });
      const id = `border-playback-${sequence++}`;
      const result = await call("pokemap_plan", { projectHandle, request: {
        requestId: id, actionId, actionVersion: 1, workspaceHandle, parameters,
        expectedRevision: validation.snapshotRevision, idempotencyKey: id } }, failure);
      assert.deepEqual(await readFile(manifestPath), beforeManifest);
      assert.deepEqual(await readFile(mapPath), beforeMap);
      return result;
    }
    async function mutate(actionId: string, parameters: JsonRecord): Promise<void> {
      const planned = await plan(actionId, parameters);
      const applied = await call("pokemap_apply", { operation: "apply", projectHandle,
        planId: planned.planId, operationId: `border-playback-apply-${sequence++}` });
      assert.equal(record(applied.receipt).status, "applied");
    }
    const modelPath = join(root, "animated-fence.glb");
    await writeFile(modelPath, unitGlb(true));
    const artifact = await call("pokemap_artifact_stage", {
      sourcePath: modelPath, declaredMediaType: "model/gltf-binary" });
    await mutate("model3d.import", { modelId: "animated-fence", name: "Animated fence",
      artifactHandle: artifact.artifactHandle });
    const imported = record(JSON.parse(await readFile(manifestPath, "utf8")));
    const inspection = record((imported.models3d as JsonRecord[])[0]!.inspection);
    assert.equal((inspection.animations as JsonRecord[])[0]!.index, 0);
    await mutate("map.apply_operations", { mapId, operations: [
      { kind: "layer.add", layerKind: "border", layerId: "fences", name: "Fences" },
    ] });
    function draft(id: string, settings: JsonRecord): JsonRecord {
      return { id, draft: { baseRevision: 0, definition: {
        name: id, previewSeed: "17", template: "connectedLine", sortOrder: 0,
        primitives: ["lineStraight", "lineCorner", "lineCap"].map(role => ({
          id: role, sourceModelId: "animated-fence", role, weight: 1, ...settings,
          transforms: { allowFlipX: false, allowedQuarterTurns: [0, 1, 2, 3] },
        })), defaults: { irregularityPermille: 0, detailDensityPermille: 0,
          variationPermille: 1000, maxOverlapPx: 0, gapTolerancePx: 0, depthRows: 1 },
      } } };
    }
    for (const invalid of [
      { animationIndex: -1 }, { animationIndex: .5 }, { animationIndex: "0" },
      { animationLoop: "false" }, { animationLoop: null },
      { animationSpeed: 0 }, { animationSpeed: -.5 }, { animationSpeed: 16.1 },
      { animationSpeed: "1" }, { blocksMovement: 0 }, { blocksMovement: null },
    ]) {
      await plan("border.blueprint.draft.upsert", { record: draft("invalid", invalid) }, true);
    }
    await mutate("border.blueprint.draft.upsert", { record: draft("missing-clip", { animationIndex: 1 }) });
    const missingClip = await plan("border.blueprint.publish", { blueprintId: "missing-clip" }, true);
    assert.ok(JSON.stringify(missingClip).includes("border.blueprint.publication_invalid"));
    const authored = { animationIndex: 0, animationLoop: false, animationSpeed: .5, blocksMovement: false };
    await mutate("border.blueprint.draft.upsert", { record: draft("explicit", authored) });
    await mutate("border.blueprint.publish", { blueprintId: "explicit" });
    const queried = await call("pokemap_query", { projectHandle, resourceKind: "borderBlueprint",
      operation: "get", ids: ["explicit"], view: "detail" });
    const blueprint = record((queried.items as JsonRecord[])[0]);
    for (const section of ["draft", "latestPublished"]) {
      const definition = record(record(blueprint[section]).definition);
      for (const primitive of definition.primitives as JsonRecord[]) {
        for (const [field, value] of Object.entries(authored)) assert.equal(primitive[field], value);
      }
    }
    function feature(id: string, blueprintId: string, row: number): JsonRecord {
      return { mapId, layerId: "fences", featureId: id, blueprintId, name: id, seed: "17",
        geometry: { kind: "stroke", strokes: [{ id: "line", closed: false,
          points: [1, 2, 3].map(x => ({ x, y: row })) }] } };
    }
    await mutate("border_layer.feature_create", feature("explicit", "explicit", 1));
    await mutate("border_layer.materialize_apply", { mapId, layerId: "fences", featureId: "explicit" });
    const map = record(JSON.parse(await readFile(mapPath, "utf8")));
    const instances = record(map.spatialScene).instances as JsonRecord[];
    assert.equal(instances.length, 3);
    for (const instance of instances) {
      for (const [field, value] of Object.entries(authored)) assert.equal(instance[field], value);
    }
    const savedManifest = await readFile(manifestPath), savedMap = await readFile(mapPath);
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
    opened = await call("pokemap_workspace", { operation: "open", projectRoot });
    projectHandle = String(opened.projectHandle); workspaceHandle = String(opened.workspaceHandle);
    const restored = await call("pokemap_query", { projectHandle, resourceKind: "map",
      operation: "get", ids: [mapId], view: "detail" });
    assert.deepEqual(record((restored.items as JsonRecord[])[0]!.spatialScene).instances, instances);
    assert.deepEqual(await readFile(manifestPath), savedManifest);
    assert.deepEqual(await readFile(mapPath), savedMap);
    await mutate("border.blueprint.draft.upsert", { record: draft("default", {}) });
    await mutate("border.blueprint.publish", { blueprintId: "default" });
    await mutate("border_layer.feature_create", feature("default", "default", 3));
    await mutate("border_layer.materialize_apply", { mapId, layerId: "fences", featureId: "default" });
    const defaultMap = record(JSON.parse(await readFile(mapPath, "utf8")));
    const all = record(defaultMap.spatialScene).instances as JsonRecord[];
    assert.equal(all.length, 6);
    const existingIds = new Set(instances.map(instance => instance.id));
    for (const instance of all.filter(value => !existingIds.has(value.id))) {
      assert.equal(instance.animationIndex, null);
      assert.equal(instance.animationLoop, true);
      assert.equal(instance.animationSpeed, 1);
      assert.equal(instance.blocksMovement, true);
    }
    assert.deepEqual(all.filter(value => existingIds.has(value.id)), instances);
    await call("pokemap_workspace", { operation: "close", workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

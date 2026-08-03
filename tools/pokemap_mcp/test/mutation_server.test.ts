import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";

import { Client } from "@modelcontextprotocol/client";
import { InMemoryTransport } from "@modelcontextprotocol/server";

import {
  AuthoringClientError,
  type AuthoringGateway,
  type JsonRecord,
  LocalAuthoringClient,
} from "../src/authoring_client.js";
import { MemoryArtifactReader } from "../src/artifacts.js";
import { createPokeMapMcpServer } from "../src/server.js";

const repositoryRoot = resolve(process.cwd(), "../..");
const authoringPackageRoot = resolve(repositoryRoot, "packages/map_authoring");
const scaffold = resolve(
  repositoryRoot,
  "examples/playable_runtime_host/phase6_authoring_golden_slice/project.json",
);

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

async function toolData(
  client: Client,
  name: string,
  args: JsonRecord,
): Promise<JsonRecord> {
  const result = await client.callTool({ name, arguments: args });
  assert.equal(result.isError, undefined, JSON.stringify(result.structuredContent));
  const envelope = record(result.structuredContent);
  assert.equal(envelope.ok, true);
  return record(envelope.data);
}

async function mutationFixture(
  options: {
    withLegacyAtlasGap?: boolean;
    withSmartTileM01?: boolean;
    withNativeSmartTileV5?: boolean | "mixed";
  } = {},
) {
  const root = await mkdtemp(join(tmpdir(), "pokemap-mcp-mutation-"));
  const scaffoldBytes = await readFile(scaffold);
  if (options.withNativeSmartTileV5) {
    await mkdir(join(root, "maps"), { recursive: true });
    await writeFile(
      join(root, "project.json"),
      JSON.stringify(
        nativeSmartTileV5Project(options.withNativeSmartTileV5 === "mixed"),
      ),
    );
    await writeFile(
      join(root, "maps/native_v5.json"),
      JSON.stringify(
        nativeSmartTileV5Map(options.withNativeSmartTileV5 === "mixed"),
      ),
    );
  } else if (options.withSmartTileM01) {
    await mkdir(join(root, "maps"), { recursive: true });
    await writeFile(
      join(root, "project.json"),
      JSON.stringify(smartTileM01Project()),
    );
    await writeFile(
      join(root, "maps/map_hanazuki_village.json"),
      JSON.stringify(smartTileM01Map()),
    );
  } else if (options.withLegacyAtlasGap) {
    const project = JSON.parse(scaffoldBytes.toString("utf8")) as JsonRecord;
    const tilesets = Array.isArray(project.tilesets) ? project.tilesets : [];
    const categories = Array.isArray(project.elementCategories)
      ? project.elementCategories
      : [];
    const elements = Array.isArray(project.elements) ? project.elements : [];
    project.tilesets = [
      ...tilesets,
      {
        id: "tileset_m00_hanazuki_guesthouse_room",
        name: "M00 Guesthouse",
        relativePath: "images/m00.png",
      },
    ];
    project.elementCategories = [
      ...categories,
      { id: "legacy-m00", name: "Legacy M00", sortOrder: 0 },
    ];
    project.elements = [
      ...elements,
      {
        id: "legacy-m00-bed",
        name: "Legacy M00 Bed",
        tilesetId: "tileset_m00_hanazuki_guesthouse_room",
        categoryId: "legacy-m00",
        frames: [{ source: { x: 0, y: 0 } }],
      },
    ];
    await writeFile(join(root, "project.json"), JSON.stringify(project));
  } else {
    await writeFile(join(root, "project.json"), scaffoldBytes);
  }
  const authoring = new LocalAuthoringClient({
    allowedRoots: [root],
    authoringPackageRoot,
  });
  const server = createPokeMapMcpServer({
    authoring,
    artifacts: new MemoryArtifactReader(),
  });
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "pokemap-mutation-test", version: "1.0.0" });
  await server.connect(serverTransport);
  await client.connect(clientTransport);
  return { authoring, client, root, server };
}

function nativeSmartTileV5Project(mixed = false): JsonRecord {
  return {
    name: "Native Smart Tile v5 MCP fixture",
    version: "v5",
    maps: [
      {
        id: "native_v5",
        name: "Native v5",
        relativePath: "maps/native_v5.json",
      },
    ],
    tilesets: [],
    smartTileCatalog: {
      formatVersion: 2,
      categories: [],
      atlases: [],
      animations: [],
      materials: [
        {
          id: "grass",
          name: "Grass",
          connectionGroupId: "ground",
        },
        {
          id: "road",
          name: "Road",
          connectionGroupId: "road",
        },
      ],
      presets: [
        {
          id: "terrain",
          name: "Terrain",
          usage: "terrain",
          topology: "uniform",
          templateHint: "simple",
          status: "draft",
          coveragePolicy: "sparse",
          coverageProfile: {
            mode: "template",
            requiredScenarios: [],
            allowFallback: false,
          },
          transformPolicy: {
            allowHFlip: false,
            allowVFlip: false,
            allowQuarterTurns: false,
          },
          defaultMaterialId: "grass",
          allowedMaterialIds: ["grass"],
          rules: [],
          tags: [],
          sortOrder: 0,
          seedSalt: 0,
        },
        {
          id: "path",
          name: "Path",
          usage: "path",
          topology: mixed ? "wang_8" : "uniform",
          templateHint: mixed ? "mixed_256" : "simple",
          status: "draft",
          coveragePolicy: "sparse",
          coverageProfile: {
            mode: "template",
            requiredScenarios: [],
            allowFallback: false,
          },
          transformPolicy: {
            allowHFlip: false,
            allowVFlip: false,
            allowQuarterTurns: false,
          },
          defaultMaterialId: "road",
          allowedMaterialIds: ["road"],
          rules: [],
          tags: [],
          sortOrder: 0,
          seedSalt: 0,
        },
      ],
    },
  };
}

function nativeSmartTileV5Map(mixed = false): JsonRecord {
  return {
    id: "native_v5",
    name: "Native v5",
    size: { width: 2, height: 2 },
    version: "v5",
    layers: [
      {
        id: "base",
        name: "Base",
        tiles: [0, 0, 0, 0],
        runtimeType: "tile",
      },
      {
        id: "terrain",
        name: "Terrain",
        presetId: "terrain",
        usage: "terrain",
        materialPalette: ["", "grass"],
        field: {
          kind: "cell",
          semanticCells: [1, 1, 1, 1],
        },
        runtimeType: "smart_tile",
      },
      {
        id: "smart",
        name: "Smart",
        presetId: "path",
        usage: "path",
        materialPalette: ["", "road"],
        field: mixed
          ? {
              kind: "mixed",
              semanticCells: [0, 0, 0, 0],
              horizontalEdges: [0, 0, 0, 0, 0, 0],
              verticalEdges: [0, 0, 0, 0, 0, 0],
              corners: [0, 0, 0, 0, 0, 0, 0, 0, 0],
            }
          : {
              kind: "cell",
              semanticCells: [1, 0, 0, 0],
            },
        runtimeType: "smart_tile",
      },
    ],
  };
}

function smartTileM01Project(): JsonRecord {
  return {
    name: "M01 Smart Tile MCP fixture",
    version: "v5",
    maps: [
      {
        id: "map_hanazuki_village",
        name: "Hanazuki Village",
        relativePath: "maps/map_hanazuki_village.json",
      },
    ],
    tilesets: [
      {
        id: "smart_tileset",
        name: "Smart Tileset",
        relativePath: "assets/smart_tileset.png",
      },
    ],
    smartTileCatalog: {
      formatVersion: 2,
      categories: [],
      atlases: [
        {
          id: "atlas",
          name: "Atlas",
          tilesetId: "smart_tileset",
          columns: 1,
          rows: 1,
        },
      ],
      animations: [],
      materials: [
        { id: "grass", name: "Grass", connectionGroupId: "ground" },
        {
          id: "smart_material_empty",
          name: "Legacy empty",
          connectionGroupId: "empty",
          isEmpty: true,
        },
        { id: "dirt", name: "Dirt", connectionGroupId: "path" },
      ],
      presets: [
        {
          id: "terrain",
          name: "Terrain",
          usage: "terrain",
          topology: "wang_8",
          templateHint: "mixed_256",
          coveragePolicy: "complete",
          coverageProfile: {
            mode: "template",
            requiredScenarios: [],
            allowFallback: false,
          },
          transformPolicy: {
            allowHFlip: false,
            allowVFlip: false,
            allowQuarterTurns: false,
            preferUntransformed: true,
          },
          defaultMaterialId: "grass",
          allowedMaterialIds: ["grass"],
        },
        {
          id: "path",
          name: "Path",
          usage: "path",
          topology: "wang_8",
          templateHint: "mixed_256",
          coveragePolicy: "complete",
          coverageProfile: {
            mode: "template",
            requiredScenarios: [],
            allowFallback: false,
          },
          transformPolicy: {
            allowHFlip: false,
            allowVFlip: false,
            allowQuarterTurns: false,
            preferUntransformed: true,
          },
          defaultMaterialId: "dirt",
          allowedMaterialIds: ["dirt"],
        },
      ],
    },
  };
}

function smartTileM01Map(): JsonRecord {
  const zeros12 = Array<number>(12).fill(0);
  const zeros16 = Array<number>(16).fill(0);
  return {
    id: "map_hanazuki_village",
    name: "Hanazuki Village",
    size: { width: 3, height: 3 },
    version: "v5",
    layers: [
      {
        id: "base",
        name: "Base",
        tiles: Array<number>(9).fill(0),
        runtimeType: "tile",
      },
      {
        id: "terrain",
        name: "Terrain metadata",
        isVisible: false,
        opacity: 0.75,
        presetId: "terrain",
        usage: "terrain",
        materialPalette: ["", "grass", "smart_material_empty"],
        field: {
          kind: "mixed",
          semanticCells: Array<number>(9).fill(1),
          horizontalEdges: zeros12,
          verticalEdges: zeros12,
          corners: zeros16,
        },
        layerSeed: 71,
        properties: { keep: "terrain" },
        runtimeType: "smart_tile",
      },
      {
        id: "path_target",
        name: "Target metadata",
        isVisible: false,
        opacity: 0.55,
        presetId: "path",
        usage: "path",
        materialPalette: ["", "dirt"],
        field: {
          kind: "mixed",
          semanticCells: [0, 0, 0, 1, 1, 1, 0, 0, 0],
          horizontalEdges: [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
          verticalEdges: zeros12,
          corners: zeros16,
        },
        layerSeed: 29,
        properties: { keep: "yes" },
        runtimeType: "smart_tile",
      },
      {
        id: "path_source",
        name: "Source",
        presetId: "path",
        usage: "path",
        materialPalette: ["", "dirt"],
        field: {
          kind: "mixed",
          semanticCells: [0, 1, 0, 0, 1, 0, 0, 1, 0],
          horizontalEdges: [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0],
          verticalEdges: [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0],
          corners: [0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
        },
        layerSeed: 0,
        properties: {},
        runtimeType: "smart_tile",
      },
      {
        id: "collisions",
        name: "Collisions",
        collisions: Array<boolean>(9).fill(false),
        runtimeType: "collision",
      },
    ],
  };
}

async function applyMutation(
  client: Client,
  input: {
    projectHandle: string;
    workspaceHandle: string;
    expectedRevision: string;
    actionId: string;
    parameters: JsonRecord;
    sequence: string;
  },
): Promise<string> {
  const planned = await toolData(client, "pokemap_plan", {
    projectHandle: input.projectHandle,
    request: {
      requestId: `cold-start-${input.sequence}`,
      actionId: input.actionId,
      actionVersion: 1,
      workspaceHandle: input.workspaceHandle,
      parameters: input.parameters,
      expectedRevision: input.expectedRevision,
      idempotencyKey: `idem-cold-start-${input.sequence}`,
      dryRun: false,
    },
  });
  assert.equal(record(planned.receipt).status, "planned");
  const applied = await toolData(client, "pokemap_apply", {
    operation: "apply",
    projectHandle: input.projectHandle,
    planId: planned.planId,
    operationId: `operation-cold-start-${input.sequence}`,
  });
  const receipt = record(applied.receipt);
  assert.equal(receipt.status, "applied");
  assert.equal(receipt.actionId, input.actionId);
  assert.match(String(receipt.afterRevision), /^sha256:[0-9a-f]{64}$/);
  const validation = await toolData(client, "pokemap_validate", {
    projectHandle: input.projectHandle,
  });
  return String(validation.snapshotRevision);
}

test("MCP preserves CLI plan/apply parity for one complete map batch", async () => {
  const fixture = await mutationFixture();
  try {
    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const projectHandle = String(opened.projectHandle);
    const workspaceHandle = String(opened.workspaceHandle);
    const validation = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });

    const planned = await toolData(fixture.client, "pokemap_plan", {
      projectHandle,
      request: {
        requestId: "mcp-map-create",
        actionId: "map.create",
        actionVersion: 1,
        workspaceHandle,
        parameters: { mapId: "mcp_batch_map", width: 3, height: 2 },
        expectedRevision: validation.snapshotRevision,
        idempotencyKey: "idem-mcp-map-create",
        dryRun: false,
      },
    });
    assert.equal(record(planned.receipt).status, "planned");
    await assert.rejects(readFile(join(fixture.root, "maps/mcp_batch_map.json")));

    const applied = await toolData(fixture.client, "pokemap_apply", {
      operation: "apply",
      projectHandle,
      planId: planned.planId,
      operationId: "operation-mcp-map-create",
    });
    const retried = await toolData(fixture.client, "pokemap_apply", {
      operation: "apply",
      projectHandle,
      planId: planned.planId,
      operationId: "operation-mcp-map-create",
    });
    assert.deepEqual(retried, applied);

    const queried = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "map",
      operation: "get",
      view: "detail",
      ids: ["mcp_batch_map"],
    });
    assert.equal(record((queried.items as unknown[])[0]).id, "mcp_batch_map");

    const history = await toolData(fixture.client, "pokemap_history", {
      operation: "list",
      projectHandle,
      limit: 1,
    });
    assert.equal((history.entries as unknown[]).length, 1);
    assert.equal(record((history.entries as unknown[])[0]).operationId, "operation-mcp-map-create");

    const afterValidation = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });
    assert.notEqual(afterValidation.snapshotRevision, validation.snapshotRevision);

    const batchPlan = await toolData(fixture.client, "pokemap_plan", {
      projectHandle,
      request: {
        requestId: "mcp-map-batch",
        actionId: "map.apply_operations",
        actionVersion: 1,
        workspaceHandle,
        parameters: {
          mapId: "mcp_batch_map",
          operations: [
            {
              kind: "layer.add",
              layerKind: "tile",
              layerId: "ground",
              name: "Ground",
            },
            {
              kind: "region.fill",
              layerId: "ground",
              x: 0,
              y: 0,
              width: 3,
              height: 2,
              value: 7,
            },
          ],
        },
        expectedRevision: afterValidation.snapshotRevision,
        idempotencyKey: "idem-mcp-map-batch",
        dryRun: false,
      },
    });
    assert.equal(record(batchPlan.receipt).status, "planned");
    const batchApplied = await toolData(fixture.client, "pokemap_apply", {
      operation: "apply",
      projectHandle,
      planId: batchPlan.planId,
      operationId: "operation-mcp-map-batch",
    });
    assert.equal(record(batchApplied.receipt).actionId, "map.apply_operations");

    const batchHistory = await toolData(fixture.client, "pokemap_history", {
      operation: "list",
      projectHandle,
      limit: 2,
    });
    assert.deepEqual(
      (batchHistory.entries as JsonRecord[]).map((entry) => entry.operationId),
      ["operation-mcp-map-batch", "operation-mcp-map-create"],
    );
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test("MCP routes Smart Tile layer creation to its canonical action", async () => {
  const fixture = await mutationFixture({ withNativeSmartTileV5: true });
  try {
    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const projectHandle = String(opened.projectHandle);
    const before = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });
    const beforeMap = await readFile(join(fixture.root, "maps/native_v5.json"));

    const rejected = await fixture.client.callTool({
      name: "pokemap_plan",
      arguments: {
        projectHandle,
        request: {
          requestId: "native-v5-layer-add-rejected",
          actionId: "map.apply_operations",
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle,
          parameters: {
            mapId: "native_v5",
            operations: [
              {
                kind: "layer.add",
                layerKind: "smart_tile",
                layerId: "smart_path",
                name: "Smart Path",
                presetId: "path",
                usage: "path",
                defaultMaterialId: "road",
              },
            ],
          },
          expectedRevision: before.snapshotRevision,
          idempotencyKey: "idem-native-v5-layer-add-rejected",
          dryRun: false,
        },
      },
    });

    assert.equal(rejected.isError, true);
    const error = record(record(rejected.structuredContent).error);
    assert.equal(error.domainCode, "smart_tile_canonical_layer_action_required");
    const after = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });
    assert.equal(after.snapshotRevision, before.snapshotRevision);
    assert.deepEqual(
      await readFile(join(fixture.root, "maps/native_v5.json")),
      beforeMap,
    );
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test("MCP relays the canonical STN-05 Smart Tile paint rejection", async () => {
  const fixture = await mutationFixture({ withNativeSmartTileV5: "mixed" });
  try {
    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const projectHandle = String(opened.projectHandle);
    const before = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });
    const beforeMap = await readFile(join(fixture.root, "maps/native_v5.json"));

    const rejected = await fixture.client.callTool({
      name: "pokemap_plan",
      arguments: {
        projectHandle,
        request: {
          requestId: "native-v5-paint-rejected",
          actionId: "map.apply_operations",
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle,
          parameters: {
            mapId: "native_v5",
            operations: [
              {
                kind: "region.paint",
                layerId: "smart",
                x: 0,
                y: 0,
                value: "road",
              },
            ],
          },
          expectedRevision: before.snapshotRevision,
          idempotencyKey: "idem-native-v5-paint-rejected",
          dryRun: false,
        },
      },
    });

    assert.equal(rejected.isError, true);
    const error = record(record(rejected.structuredContent).error);
    assert.equal(
      error.domainCode,
      "smart_tile_wang_paint_compiler_required",
    );
    const after = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });
    assert.equal(after.snapshotRevision, before.snapshotRevision);
    assert.deepEqual(
      await readFile(join(fixture.root, "maps/native_v5.json")),
      beforeMap,
    );
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test("MCP applies Smart Tile cell edits through the canonical transport", async () => {
  const fixture = await mutationFixture({ withNativeSmartTileV5: true });
  try {
    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const projectHandle = String(opened.projectHandle);
    const before = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });
    const planned = await toolData(fixture.client, "pokemap_plan", {
      projectHandle,
      request: {
        requestId: "native-v5-clear",
        actionId: "map.apply_operations",
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle,
        parameters: {
          mapId: "native_v5",
          operations: [
            { kind: "layer.clear", layerId: "smart" },
            {
              kind: "region.paint",
              layerId: "smart",
              x: 1,
              y: 1,
              value: "road",
            },
          ],
        },
        expectedRevision: before.snapshotRevision,
        idempotencyKey: "idem-native-v5-clear",
        dryRun: false,
      },
    });
    const applied = await toolData(fixture.client, "pokemap_apply", {
      operation: "apply",
      projectHandle,
      planId: planned.planId,
      operationId: "operation-native-v5-clear",
    });
    assert.equal(record(applied.receipt).actionId, "map.apply_operations");
    const after = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });
    assert.notEqual(after.snapshotRevision, before.snapshotRevision);
    const persisted = record(
      JSON.parse(
        await readFile(join(fixture.root, "maps/native_v5.json"), "utf8"),
      ),
    );
    const smartLayerValue = (persisted.layers as unknown[]).find(
      (layer) => record(layer).id === "smart",
    );
    assert.ok(smartLayerValue);
    const smartLayer = record(smartLayerValue);
    const field = record(smartLayer.field);
    assert.deepEqual(field.semanticCells, [0, 0, 0, 1]);
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test("MCP marks dry-run plans non-applicable before confirmation or apply", async () => {
  const fixture = await mutationFixture();
  try {
    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const projectHandle = String(opened.projectHandle);
    const validation = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });
    const planned = await toolData(fixture.client, "pokemap_plan", {
      projectHandle,
      request: {
        requestId: "mcp-dry-run",
        actionId: "map.create",
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle,
        parameters: { mapId: "dry_run_map", width: 2, height: 2 },
        expectedRevision: validation.snapshotRevision,
        idempotencyKey: "idem-mcp-dry-run",
        dryRun: true,
      },
    });
    assert.equal(planned.applicable, false);
    assert.equal(record(planned.plan).applicable, false);
    assert.equal(record(planned.plan).nonApplicableReason, "dry_run");

    for (const arguments_ of [
      {
        operation: "confirm",
        projectHandle,
        planId: planned.planId,
      },
      {
        operation: "apply",
        projectHandle,
        planId: planned.planId,
        operationId: "operation-mcp-dry-run",
      },
    ]) {
      const result = await fixture.client.callTool({
        name: "pokemap_apply",
        arguments: arguments_,
      });
      assert.equal(result.isError, true);
      const error = record(record(result.structuredContent).error);
      assert.equal(error.domainCode, "plan.dry_run_not_applicable");
      assert.match(String(error.message), /dry-run preview/i);
      assert.notEqual(error.domainCode, "idempotency.apply_required");
    }
    await assert.rejects(readFile(join(fixture.root, "maps/dry_run_map.json")));
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test("MCP normalizes and atomically merges the complete M01 Smart Tile fixture", async () => {
  const fixture = await mutationFixture({ withSmartTileM01: true });
  try {
    const described = await toolData(fixture.client, "pokemap_describe", {});
    const actionIds = (described.mutationActions as JsonRecord[]).map(
      (action) => action.id,
    );
    for (const actionId of [
      "smart_tile.animation.delete",
      "smart_tile.animation.upsert",
      "smart_tile.atlas.upsert",
      "smart_tile.layer.create",
      "smart_tile.layer.delete",
      "smart_tile.layer.merge",
      "smart_tile.layer.normalize",
      "smart_tile.material.upsert",
      "smart_tile.preset.draft.delete",
      "smart_tile.preset.draft.upsert",
      "smart_tile.preset.delete",
      "smart_tile.preset.publish",
    ]) {
      assert.ok(actionIds.includes(actionId), actionId);
    }
    const resourceKindIds = (described.resourceKinds as JsonRecord[]).map(
      (resource) => resource.id,
    );
    for (const resourceKind of [
      "smartTileAnimation",
      "smartTileAtlas",
      "smartTileDraft",
      "smartTileLayer",
      "smartTileMaterial",
      "smartTilePreset",
    ]) {
      assert.ok(resourceKindIds.includes(resourceKind), resourceKind);
    }

    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const projectHandle = String(opened.projectHandle);
    const workspaceHandle = String(opened.workspaceHandle);
    let validation = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });

    const rejectedBatch = await fixture.client.callTool({
      name: "pokemap_plan",
      arguments: {
        projectHandle,
        request: {
          requestId: "m01-precise-diagnostic",
          actionId: "map.apply_operations",
          actionVersion: 1,
          workspaceHandle,
          parameters: {
            mapId: "map_hanazuki_village",
            operations: [
              { kind: "layer.rename", layerId: "path_target", name: "Path" },
            ],
          },
          expectedRevision: validation.snapshotRevision,
          idempotencyKey: "idem-m01-precise-diagnostic",
          dryRun: false,
        },
      },
    });
    assert.equal(rejectedBatch.isError, true);
    const diagnostic = record(record(rejectedBatch.structuredContent).error);
    assert.equal(
      diagnostic.domainCode,
      "map.smart_tile_material_not_allowed",
    );
    assert.match(String(diagnostic.message), /smart_material_empty/);
    assert.equal(record(diagnostic.details).layerId, "terrain");
    assert.equal(record(diagnostic.details).field, "materialPalette");
    assert.equal(
      record(diagnostic.details).materialId,
      "smart_material_empty",
    );
    assert.equal(record(diagnostic.details).presetId, "terrain");
    assert.equal(record(diagnostic.details).validationState, "pre_existing");
    assert.ok(
      (diagnostic.remediation as string[]).includes(
        "Run smart_tile.layer.normalize for terrain.",
      ),
    );

    async function applyAction(
      actionId: string,
      parameters: JsonRecord,
      sequence: string,
    ): Promise<JsonRecord> {
      const planned = await toolData(fixture.client, "pokemap_plan", {
        projectHandle,
        request: {
          requestId: `m01-${sequence}`,
          actionId,
          actionVersion: 1,
          workspaceHandle,
          parameters,
          expectedRevision: validation.snapshotRevision,
          idempotencyKey: `idem-m01-${sequence}`,
          dryRun: false,
        },
      });
      if (sequence === "normalize") {
        const preview = record(record(planned.plan).preview);
        assert.equal(preview.removedMaterialCount, 1);
        assert.deepEqual(preview.removedMaterials, [
          { materialId: "smart_material_empty", oldIndex: 2 },
        ]);
      }
      const applied = await toolData(fixture.client, "pokemap_apply", {
        operation: "apply",
        projectHandle,
        planId: planned.planId,
        operationId: `operation-m01-${sequence}`,
      });
      assert.equal(record(applied.receipt).actionId, actionId);
      validation = await toolData(fixture.client, "pokemap_validate", {
        projectHandle,
      });
      return applied;
    }

    await applyAction(
      "smart_tile.layer.normalize",
      { mapId: "map_hanazuki_village", layerId: "terrain" },
      "normalize",
    );
    await applyAction(
      "smart_tile.layer.merge",
      {
        mapId: "map_hanazuki_village",
        sourceLayerIds: ["path_target", "path_source"],
        targetLayerId: "path_target",
        mode: "union",
        removeSources: true,
        conflictPolicy: "reject",
      },
      "merge",
    );
    await applyAction(
      "smart_tile.animation.upsert",
      {
        animation: {
          id: "wind",
          name: "Wind",
          frames: [
            {
              frame: { atlasId: "atlas", column: 0, row: 0 },
              durationMs: 120,
            },
          ],
          sync: "global",
          loop: "repeat",
        },
      },
      "animation",
    );

    await applyAction(
      "smart_tile.preset.draft.upsert",
      {
        draft: {
          id: "mcp-draft",
          targetPresetId: "mcp-draft-target",
          name: "MCP draft",
          usage: "terrain",
          lastStage: "usage",
        },
      },
      "draft-upsert",
    );
    const queriedDraft = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "smartTileDraft",
      operation: "get",
      view: "detail",
      ids: ["mcp-draft"],
    });
    assert.equal(record((queriedDraft.items as unknown[])[0]).id, "mcp-draft");

    const queriedAnimations = await toolData(
      fixture.client,
      "pokemap_query",
      {
        projectHandle,
        resourceKind: "smartTileAnimation",
        operation: "list",
      },
    );
    assert.deepEqual(
      (queriedAnimations.items as JsonRecord[]).map((item) => item.id),
      ["wind"],
    );

    assert.equal(validation.valid, true);
    assert.equal(record(validation.structure).valid, true);
    assert.equal(record(validation.references).valid, true);
    assert.equal(
      record(validation.capabilityCertification).status,
      "not_requested",
    );
    const map = JSON.parse(
      await readFile(
        join(fixture.root, "maps/map_hanazuki_village.json"),
        "utf8",
      ),
    ) as JsonRecord;
    assert.equal(map.version, "v5");
    const layers = map.layers as JsonRecord[];
    assert.deepEqual(
      layers.map((layer) => layer.id),
      ["base", "terrain", "path_target", "collisions"],
    );
    const terrain = layers[1];
    const target = layers[2];
    assert.ok(terrain);
    assert.ok(target);
    assert.deepEqual(terrain.materialPalette, ["", "grass"]);
    const targetField = record(target.field);
    assert.equal(targetField.kind, "mixed");
    assert.deepEqual(targetField.semanticCells, [0, 1, 0, 1, 1, 1, 0, 1, 0]);
    assert.deepEqual(targetField.horizontalEdges, [
      1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0,
    ]);
    assert.deepEqual(targetField.verticalEdges, [
      0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,
    ]);
    assert.deepEqual(targetField.corners, [
      0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
    ]);
    assert.equal(target.name, "Target metadata");
    assert.equal(target.isVisible, false);
    assert.equal(target.opacity, 0.55);
    assert.equal(target.layerSeed, 29);
    assert.deepEqual(target.properties, { keep: "yes" });

    const queried = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "map",
      operation: "get",
      view: "detail",
      ids: ["map_hanazuki_village"],
    });
    assert.equal(record((queried.items as unknown[])[0]).id, "map_hanazuki_village");
    await toolData(fixture.client, "pokemap_workspace", {
      operation: "close",
      workspaceHandle,
    });

    const reopened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const reopenedAnimations = await toolData(
      fixture.client,
      "pokemap_query",
      {
        projectHandle: String(reopened.projectHandle),
        resourceKind: "smartTileAnimation",
        operation: "list",
      },
    );
    assert.deepEqual(
      (reopenedAnimations.items as JsonRecord[]).map((item) => item.id),
      ["wind"],
    );
    await toolData(fixture.client, "pokemap_workspace", {
      operation: "close",
      workspaceHandle: String(reopened.workspaceHandle),
    });
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test("MCP completes a cold-start 34-element visual import", async () => {
  const fixture = await mutationFixture({ withLegacyAtlasGap: true });
  try {
    const sourcePath = join(fixture.root, "source.png");
    await writeFile(
      sourcePath,
      Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00]),
    );
    const staged = await toolData(fixture.client, "pokemap_artifact_stage", {
      sourcePath,
      declaredMediaType: "image/png",
    });
    assert.match(String(staged.artifactHandle), /^artifact:\/\/sha256\/[0-9a-f]{64}$/);
    assert.equal(staged.mediaType, "image/png");

    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const projectHandle = String(opened.projectHandle);
    const workspaceHandle = String(opened.workspaceHandle);
    const described = await toolData(fixture.client, "pokemap_describe", {});
    assert.ok(
      (described.resourceKinds as JsonRecord[])
        .map((kind) => kind.id)
        .includes("tilesetFolder"),
    );
    assert.ok(
      (described.resourceKinds as JsonRecord[])
        .map((kind) => kind.id)
        .includes("elementCategory"),
    );
    const actionIds = (described.mutationActions as JsonRecord[]).map(
      (action) => action.id,
    );
    assert.ok(actionIds.includes("tileset_folder.upsert"));
    assert.ok(actionIds.includes("element_category.upsert"));
    assert.ok(
      (described.commands as JsonRecord[])
        .map((command) => command.id)
        .includes("stage_artifact"),
    );

    const initial = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });
    let revision = String(initial.snapshotRevision);
    revision = await applyMutation(fixture.client, {
      projectHandle,
      workspaceHandle,
      expectedRevision: revision,
      actionId: "asset.import",
      parameters: {
        artifactHandle: staged.artifactHandle,
        assetId: "m02-atlas",
        logicalPath: "images/m02.png",
      },
      sequence: "asset",
    });
    revision = await applyMutation(fixture.client, {
      projectHandle,
      workspaceHandle,
      expectedRevision: revision,
      actionId: "tileset_folder.upsert",
      parameters: {
        folder: { id: "m02", name: "M02", sortOrder: 2 },
      },
      sequence: "folder",
    });
    revision = await applyMutation(fixture.client, {
      projectHandle,
      workspaceHandle,
      expectedRevision: revision,
      actionId: "element_category.upsert",
      parameters: {
        category: { id: "m02-elements", name: "M02", sortOrder: 2 },
      },
      sequence: "category",
    });
    revision = await applyMutation(fixture.client, {
      projectHandle,
      workspaceHandle,
      expectedRevision: revision,
      actionId: "tileset.upsert",
      parameters: {
        tileset: {
          id: "m02-tileset",
          name: "M02",
          relativePath: "images/m02.png",
          folderId: "m02",
          sortOrder: 2,
        },
        atlas: {
          tilesetId: "m02-tileset",
          assetId: "m02-atlas",
          pixelWidth: 128,
          pixelHeight: 80,
          tileWidth: 16,
          tileHeight: 16,
          tileProperties: [],
        },
      },
      sequence: "tileset",
    });

    for (let index = 0; index < 34; index += 1) {
      const elementId = `m02-element-${String(index + 1).padStart(2, "0")}`;
      revision = await applyMutation(fixture.client, {
        projectHandle,
        workspaceHandle,
        expectedRevision: revision,
        actionId: "element.upsert",
        parameters: {
          element: {
            id: elementId,
            name: `M02 Element ${index + 1}`,
            tilesetId: "m02-tileset",
            categoryId: "m02-elements",
            frames: [
              {
                source: {
                  x: index % 8,
                  y: Math.floor(index / 8),
                },
              },
            ],
            sortOrder: index,
          },
        },
        sequence: `element-${String(index + 1).padStart(2, "0")}`,
      });
    }

    const folders = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "tilesetFolder",
      operation: "get",
      view: "detail",
      ids: ["m02"],
    });
    assert.equal(record((folders.items as unknown[])[0]).name, "M02");
    const categories = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "elementCategory",
      operation: "get",
      view: "detail",
      ids: ["m02-elements"],
    });
    assert.equal(record((categories.items as unknown[])[0]).name, "M02");

    const project = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "project",
      operation: "get",
      view: "detail",
      ids: ["project"],
    });
    const projectDetail = record((project.items as unknown[])[0]);
    assert.equal(
      (projectDetail.elements as JsonRecord[]).filter((element) =>
        String(element.id).startsWith("m02-element-"),
      ).length,
      34,
    );

    const validated = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });
    assert.equal(validated.snapshotRevision, revision);
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test("MCP returns a revision conflict without silently rebuilding the plan", async () => {
  const fixture = await mutationFixture();
  try {
    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const projectHandle = String(opened.projectHandle);
    const validation = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });
    const planned = await toolData(fixture.client, "pokemap_plan", {
      projectHandle,
      request: {
        requestId: "mcp-conflict",
        actionId: "map.create",
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle,
        parameters: { mapId: "conflicted_map", width: 2, height: 2 },
        expectedRevision: validation.snapshotRevision,
        idempotencyKey: "idem-mcp-conflict",
        dryRun: false,
      },
    });
    const manifestPath = join(fixture.root, "project.json");
    await writeFile(manifestPath, `${await readFile(manifestPath, "utf8")}\n`);

    const result = await fixture.client.callTool({
      name: "pokemap_apply",
      arguments: {
        operation: "apply",
        projectHandle,
        planId: planned.planId,
        operationId: "operation-mcp-conflict",
      },
    });
    assert.equal(result.isError, true);
    const error = record(record(result.structuredContent).error);
    assert.equal(error.code, "revision_conflict");
    assert.equal(error.retryable, true);
    await assert.rejects(readFile(join(fixture.root, "maps/conflicted_map.json")));
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test("recovery requires an exact confirmation and preserves permission errors", async () => {
  const calls: string[] = [];
  const authoring: AuthoringGateway = {
    async request(command) {
      calls.push(command);
      throw new AuthoringClientError(
        "permission_denied",
        "The actor lacks recovery permission.",
        false,
        ["Grant project.recovery before retrying."],
        { domainCode: "authorization.permission_denied" },
      );
    },
    async close() {},
  };
  const server = createPokeMapMcpServer({
    authoring,
    artifacts: new MemoryArtifactReader(),
  });
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "pokemap-recovery-test", version: "1.0.0" });
  await server.connect(serverTransport);
  await client.connect(clientTransport);
  try {
    const missingConfirmation = await client.callTool({
      name: "pokemap_recovery",
      arguments: {
        projectHandle: "project-test",
        operationId: "operation-recovery",
        confirmation: "yes",
      },
    });
    let error = record(record(missingConfirmation.structuredContent).error);
    assert.equal(error.code, "confirmation.required");
    assert.deepEqual(calls, []);

    const denied = await client.callTool({
      name: "pokemap_recovery",
      arguments: {
        projectHandle: "project-test",
        operationId: "operation-recovery",
        confirmation: "RECOVER operation-recovery",
      },
    });
    error = record(record(denied.structuredContent).error);
    assert.equal(error.code, "permission_denied");
    assert.equal(error.domainCode, "authorization.permission_denied");
    assert.deepEqual(calls, ["recover"]);
  } finally {
    await client.close();
    await server.close();
  }
});

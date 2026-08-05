import assert from "node:assert/strict";
import { createHash } from "node:crypto";
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
    await writeCanonicalSmartTileImage(root);
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
    await writeCanonicalSmartTileImage(root);
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

async function writeCanonicalSmartTileImage(root: string): Promise<void> {
  const bytes = Buffer.from(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=",
    "base64",
  );
  const logicalName = Buffer.from("artifact-content", "utf8");
  const pathLength = Buffer.alloc(8);
  pathLength.writeBigUInt64BE(BigInt(logicalName.length));
  const byteLength = Buffer.alloc(8);
  byteLength.writeBigUInt64BE(BigInt(bytes.length));
  const hexDigest = createHash("sha256")
    .update(pathLength)
    .update(logicalName)
    .update(byteLength)
    .update(bytes)
    .digest("hex");
  const digest = `sha256:${hexDigest}`;
  const artifact = {
    digest,
    handle: `artifact://sha256/${hexDigest}`,
    mediaType: "image/png",
    byteLength: bytes.length,
  };

  // Publishing validates the decoded bytes from the canonical asset store;
  // merely placing a PNG beside project.json would bypass the contract being
  // certified by this MCP workflow.
  await mkdir(join(root, "assets/.pokemap-store"), { recursive: true });
  await writeFile(join(root, "assets/smart_tileset.png"), bytes);
  await writeFile(
    join(root, "assets/.pokemap-assets.json"),
    JSON.stringify({
      schemaVersion: 1,
      records: [
        {
          id: "smart-tileset-image",
          logicalPath: "assets/smart_tileset.png",
          artifact,
          usages: [],
          tags: [],
        },
      ],
    }),
  );
  await writeFile(
    join(root, `assets/.pokemap-store/${hexDigest}.blob`),
    bytes,
  );
}

function nativeSmartTileV5Project(mixed = false): JsonRecord {
  return {
    name: "Native Smart Tile v5 MCP fixture",
    version: "v6",
    maps: [
      {
        id: "native_v5",
        name: "Native v5",
        relativePath: "maps/native_v5.json",
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
    version: "v6",
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
    version: "v6",
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
    version: "v6",
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

function completeSimpleSmartTileDraft(input: {
  id: string;
  targetPresetId: string;
  usage: "terrain" | "path" | "forest_surface";
}): JsonRecord {
  const atlasId = `${input.id}-atlas`;
  const materialId = `${input.id}-material`;
  return {
    id: input.id,
    targetPresetId: input.targetPresetId,
    name: `Certified ${input.targetPresetId}`,
    usage: input.usage,
    lastStage: "publish",
    sourceTilesetIds: ["smart_tileset"],
    atlases: [
      {
        id: atlasId,
        name: `Atlas ${input.targetPresetId}`,
        tilesetId: "smart_tileset",
        cellWidth: 1,
        cellHeight: 1,
        columns: 1,
        rows: 1,
      },
    ],
    primaryAtlasId: atlasId,
    materials: [
      {
        id: materialId,
        name: `Material ${input.targetPresetId}`,
        connectionGroupId: materialId,
      },
    ],
    defaultMaterialId: materialId,
    allowedMaterialIds: [materialId],
    topology: "uniform",
    templateHint: "simple",
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
    rules: [
      {
        id: "base",
        centerMatch: { kind: "material", materialId },
        candidates: [
          {
            id: "base",
            parts: [
              {
                source: {
                  kind: "frame",
                  frame: { atlasId, column: 0, row: 0 },
                },
              },
            ],
          },
        ],
      },
    ],
  };
}

function completeMultiMaterialSmartTileDraft(input: {
  id: string;
  targetPresetId: string;
}): JsonRecord {
  const atlasId = `${input.id}-atlas`;
  const grassId = `${input.id}-grass`;
  const waterId = `${input.id}-water`;
  const stoneId = `${input.id}-stone`;
  return {
    id: input.id,
    targetPresetId: input.targetPresetId,
    name: `Multi-material ${input.targetPresetId}`,
    usage: "path",
    lastStage: "publish",
    sourceTilesetIds: ["smart_tileset"],
    atlases: [
      {
        id: atlasId,
        name: `Atlas ${input.targetPresetId}`,
        tilesetId: "smart_tileset",
        cellWidth: 1,
        cellHeight: 1,
        columns: 1,
        rows: 1,
      },
    ],
    primaryAtlasId: atlasId,
    materials: [
      { id: grassId, name: "Grass", connectionGroupId: grassId },
      { id: waterId, name: "Water", connectionGroupId: waterId },
      { id: stoneId, name: "Stone", connectionGroupId: stoneId },
    ],
    defaultMaterialId: grassId,
    allowedMaterialIds: [grassId, waterId, stoneId],
    topology: "wang_edge_4",
    templateHint: "free",
    coveragePolicy: "sparse",
    coverageProfile: {
      mode: "explicit",
      requiredScenarios: [
        {
          id: "grass-water-stone",
          centerMaterialId: grassId,
          signature: { northEdge: waterId, eastEdge: stoneId },
        },
      ],
      allowFallback: false,
    },
    transformPolicy: {
      allowHFlip: false,
      allowVFlip: false,
      allowQuarterTurns: false,
      preferUntransformed: true,
    },
    rules: [
      {
        id: "grass-water-stone",
        centerMatch: { kind: "material", materialId: grassId },
        signature: {
          northEdge: { kind: "material", materialId: waterId },
          eastEdge: { kind: "material", materialId: stoneId },
        },
        candidates: [
          {
            id: "multi-material-visual",
            parts: [
              {
                source: {
                  kind: "frame",
                  frame: { atlasId, column: 0, row: 0 },
                },
                channel: "foreground",
                offsetUnit: "pixel",
                offsetX: 2,
                offsetY: -1,
                footprintWidth: 2,
                footprintHeight: 3,
                anchorX: 4,
                anchorY: 5,
                drawOrder: 6,
              },
            ],
          },
        ],
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

test("MCP applies and rereads the authored Avelune cartridge color", async () => {
  const fixture = await mutationFixture();
  try {
    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const projectHandle = String(opened.projectHandle);
    const workspaceHandle = String(opened.workspaceHandle);
    const described = await toolData(fixture.client, "pokemap_describe", {});
    const actionIds = (described.mutationActions as JsonRecord[]).map(
      (action) => String(action.id),
    );
    assert.ok(actionIds.includes("presentation.update"));

    const validated = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });
    const appliedRevision = await applyMutation(fixture.client, {
      projectHandle,
      workspaceHandle,
      expectedRevision: String(validated.snapshotRevision),
      actionId: "presentation.update",
      parameters: {
        profile: {
          schemaVersion: 1,
          branding: { accentColor: "#126E78" },
        },
      },
      sequence: "avelune-cartridge-color",
    });

    const queried = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "project",
      operation: "get",
      view: "detail",
      ids: ["project"],
    });
    const project = record((queried.items as unknown[])[0]);
    assert.equal(
      record(record(project.presentation).branding).accentColor,
      "#126E78",
    );
    const persisted = record(
      JSON.parse(await readFile(join(fixture.root, "project.json"), "utf8")),
    );
    assert.equal(
      record(record(persisted.presentation).branding).accentColor,
      "#126E78",
    );
    const finalValidation = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });
    assert.equal(String(finalValidation.snapshotRevision), appliedRevision);
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test("MCP exposes Event V2 activation and safe raw asset replacement", async () => {
  const fixture = await mutationFixture();
  try {
    const rawAssetPath = join(fixture.root, "assets/audio/pikachu.ogg");
    const replacementPath = join(fixture.root, "replacement.ogg");
    const beforeBytes = Buffer.from([0x4f, 0x67, 0x67, 0x53, 0x00, 0x01]);
    const afterBytes = Buffer.from([0x4f, 0x67, 0x67, 0x53, 0x00, 0x02]);
    await mkdir(join(fixture.root, "assets/audio"), { recursive: true });
    await writeFile(rawAssetPath, beforeBytes);
    await writeFile(replacementPath, afterBytes);

    const expected = await toolData(fixture.client, "pokemap_artifact_stage", {
      sourcePath: rawAssetPath,
      declaredMediaType: "audio/ogg",
    });
    const replacement = await toolData(
      fixture.client,
      "pokemap_artifact_stage",
      {
        sourcePath: replacementPath,
        declaredMediaType: "audio/ogg",
      },
    );
    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const projectHandle = String(opened.projectHandle);
    const workspaceHandle = String(opened.workspaceHandle);
    const described = await toolData(fixture.client, "pokemap_describe", {});
    const actionIds = (described.mutationActions as JsonRecord[]).map(
      (action) => String(action.id),
    );
    assert.ok(actionIds.includes("event_v2.registry_mode.set"));
    assert.ok(actionIds.includes("asset.raw.replace"));

    const validated = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });
    const eventRevision = await applyMutation(fixture.client, {
      projectHandle,
      workspaceHandle,
      expectedRevision: String(validated.snapshotRevision),
      actionId: "event_v2.registry_mode.set",
      parameters: { mode: "dualRead" },
      sequence: "event-v2-mode",
    });
    const project = record(
      JSON.parse(await readFile(join(fixture.root, "project.json"), "utf8")),
    );
    assert.equal(record(project.eventRegistry).mode, "dualRead");

    await applyMutation(fixture.client, {
      projectHandle,
      workspaceHandle,
      expectedRevision: eventRevision,
      actionId: "asset.raw.replace",
      parameters: {
        logicalPath: "assets/audio/pikachu.ogg",
        expectedArtifactHandle: expected.artifactHandle,
        replacementArtifactHandle: replacement.artifactHandle,
      },
      sequence: "raw-asset-replace",
    });
    assert.deepEqual(await readFile(rawAssetPath), afterBytes);
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test("MCP preserves CLI plan/apply parity for one complete map batch", async () => {
  const fixture = await mutationFixture();
  try {
    const projectPath = join(fixture.root, "project.json");
    const project = JSON.parse(await readFile(projectPath, "utf8")) as JsonRecord;
    const tilesets = Array.isArray(project.tilesets) ? project.tilesets : [];
    project.tilesets = [
      ...tilesets,
      {
        id: "mcp_palette_a",
        name: "MCP palette A",
        relativePath: "assets/mcp_palette_a.png",
        source: {
          kind: "regular_atlas",
          assetId: "mcp-palette-a-image",
          pixelWidth: 1,
          pixelHeight: 1,
          tileWidth: 1,
          tileHeight: 1,
          tileProperties: [],
        },
      },
      {
        id: "mcp_palette_b",
        name: "MCP palette B",
        relativePath: "assets/mcp_palette_b.png",
        source: {
          kind: "regular_atlas",
          assetId: "mcp-palette-b-image",
          pixelWidth: 1,
          pixelHeight: 1,
          tileWidth: 1,
          tileHeight: 1,
          tileProperties: [],
        },
      },
    ];
    await writeFile(projectPath, JSON.stringify(project));

    const described = await toolData(fixture.client, "pokemap_describe", {});
    const mapAction = (described.mutationActions as JsonRecord[]).find(
      (action) => action.id === "map.apply_operations",
    );
    assert.ok(mapAction);
    assert.equal(record(mapAction.extensions).tileLayerEncoding, "tile_palette_v1");
    assert.equal(
      (record(mapAction.extensions).tileLayerAddParameters as unknown[]).includes(
        "tilesetId",
      ),
      false,
    );
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
              value: {
                tilesetId: "mcp_palette_a",
                localTileId: 0,
              },
            },
            {
              kind: "region.paint",
              layerId: "ground",
              x: 1,
              y: 0,
              value: {
                tilesetId: "mcp_palette_b",
                localTileId: 0,
              },
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

    const region = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "map",
      operation: "get",
      view: "detail",
      ids: ["mcp_batch_map"],
      extensions: {
        region: { x: 0, y: 0, width: 3, height: 1 },
      },
    });
    const regionItem = record((region.items as unknown[])[0]);
    const ground = (regionItem.layers as JsonRecord[]).find(
      (layer) => layer.id === "ground",
    );
    assert.ok(ground);
    assert.equal(ground.encoding, "tile_palette_v1");
    assert.deepEqual(
      (ground.palette as JsonRecord[]).map((entry) => entry.tilesetId),
      ["mcp_palette_a", "mcp_palette_b"],
    );
    assert.deepEqual(ground.rows, [[1, 2, 1]]);

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

test("MCP rejects generic operations for Smart Tile layer creation", async () => {
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
    assert.equal(error.domainCode, "map.operation_invalid");
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

test("MCP paints every lattice from a geometric Wang selection", async () => {
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
    const planned = await toolData(fixture.client, "pokemap_plan", {
      projectHandle,
      request: {
        requestId: "native-v5-mixed-paint",
        actionId: "smart_tile.cell.paint",
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle,
        parameters: {
          mapId: "native_v5",
          layerId: "smart",
          materialId: "road",
          selection: {
            kind: "line",
            start: { x: 0, y: 0 },
            end: { x: 0, y: 0 },
          },
        },
        expectedRevision: before.snapshotRevision,
        idempotencyKey: "idem-native-v5-mixed-paint",
        dryRun: false,
      },
    });
    const applied = await toolData(fixture.client, "pokemap_apply", {
      operation: "apply",
      projectHandle,
      planId: planned.planId,
      operationId: "operation-native-v5-mixed-paint",
    });
    assert.equal(record(applied.receipt).actionId, "smart_tile.cell.paint");
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
    const field = record(record(smartLayerValue).field);
    assert.deepEqual(field.semanticCells, [1, 0, 0, 0]);
    assert.deepEqual(field.horizontalEdges, [1, 0, 1, 0, 0, 0]);
    assert.deepEqual(field.verticalEdges, [1, 1, 0, 0, 0, 0]);
    assert.deepEqual(field.corners, [1, 1, 0, 1, 1, 0, 0, 0, 0]);
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
    let revision = String(before.snapshotRevision);
    async function applyCellAction(
      actionId: "smart_tile.cell.erase" | "smart_tile.cell.paint",
      parameters: JsonRecord,
      sequence: string,
    ): Promise<void> {
      const planned = await toolData(fixture.client, "pokemap_plan", {
        projectHandle,
        request: {
          requestId: `native-v5-${sequence}`,
          actionId,
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle,
          parameters,
          expectedRevision: revision,
          idempotencyKey: `idem-native-v5-${sequence}`,
          dryRun: false,
        },
      });
      const applied = await toolData(fixture.client, "pokemap_apply", {
        operation: "apply",
        projectHandle,
        planId: planned.planId,
        operationId: `operation-native-v5-${sequence}`,
      });
      assert.equal(record(applied.receipt).actionId, actionId);
      const validated = await toolData(fixture.client, "pokemap_validate", {
        projectHandle,
      });
      revision = String(validated.snapshotRevision);
    }
    await applyCellAction(
      "smart_tile.cell.erase",
      {
        mapId: "native_v5",
        layerId: "smart",
        cells: [{ x: 0, y: 0 }],
      },
      "erase",
    );
    await applyCellAction(
      "smart_tile.cell.paint",
      {
        mapId: "native_v5",
        layerId: "smart",
        materialId: "road",
        cells: [{ x: 1, y: 1 }, { x: 0, y: 1 }],
      },
      "paint",
    );
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
    assert.deepEqual(field.semanticCells, [0, 0, 1, 1]);
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test("MCP upserts and paints a reusable Smart Tile pattern", async () => {
  const fixture = await mutationFixture({ withNativeSmartTileV5: true });
  try {
    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const projectHandle = String(opened.projectHandle);
    let revision = String(
      (
        await toolData(fixture.client, "pokemap_validate", {
          projectHandle,
        })
      ).snapshotRevision,
    );
    async function apply(
      actionId: string,
      parameters: JsonRecord,
      sequence: string,
    ): Promise<void> {
      const planned = await toolData(fixture.client, "pokemap_plan", {
        projectHandle,
        request: {
          requestId: `pattern-${sequence}`,
          actionId,
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle,
          parameters,
          expectedRevision: revision,
          idempotencyKey: `idem-pattern-${sequence}`,
          dryRun: false,
        },
      });
      const applied = await toolData(fixture.client, "pokemap_apply", {
        operation: "apply",
        projectHandle,
        planId: planned.planId,
        operationId: `operation-pattern-${sequence}`,
      });
      assert.equal(record(applied.receipt).actionId, actionId);
      revision = String(
        (
          await toolData(fixture.client, "pokemap_validate", {
            projectHandle,
          })
        ).snapshotRevision,
      );
    }

    await apply(
      "smart_tile.pattern.upsert",
      {
        pattern: {
          id: "road-cutout",
          name: "Road cutout",
          usage: "path",
          width: 1,
          height: 1,
          repeatMode: "stamp",
          cells: [{ x: 0, y: 0, eraseMaterial: true }],
        },
      },
      "upsert",
    );
    await apply(
      "smart_tile.pattern.paint",
      {
        mapId: "native_v5",
        layerId: "smart",
        patternId: "road-cutout",
        strokeId: "cutout-1",
        selection: { kind: "stamp", anchor: { x: 0, y: 0 } },
      },
      "paint",
    );

    const query = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "smartTilePattern",
      operation: "list",
      view: "detail",
    });
    assert.equal(query.totalAvailable, 1);
    const persisted = record(
      JSON.parse(
        await readFile(join(fixture.root, "maps/native_v5.json"), "utf8"),
      ),
    );
    const smartLayer = record(
      (persisted.layers as unknown[]).find(
        (layer) => record(layer).id === "smart",
      ),
    );
    assert.equal(
      (record(smartLayer.field).semanticCells as unknown[])[0],
      0,
    );
    assert.equal(
      record((smartLayer.patternStrokes as unknown[])[0]).patternId,
      "road-cutout",
    );
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test("MCP imports a Tiled tileset through one canonical receipt", async () => {
  const fixture = await mutationFixture();
  try {
    const sourcePath = join(fixture.root, "road.png");
    await writeFile(
      sourcePath,
      Buffer.from(
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=",
        "base64",
      ),
    );
    const staged = await toolData(fixture.client, "pokemap_artifact_stage", {
      sourcePath,
      declaredMediaType: "image/png",
    });
    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const projectHandle = String(opened.projectHandle);
    const validated = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });
    const planned = await toolData(fixture.client, "pokemap_plan", {
      projectHandle,
      request: {
        requestId: "tiled-tileset-import",
        actionId: "tileset.tiled.import",
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle,
        parameters: {
          artifactHandle: staged.artifactHandle,
          assetId: "mcp-road-image",
          logicalPath: "assets/mcp-road.png",
          tilesetId: "mcp-road-tileset",
          displayName: "MCP Road",
          tsx: tiledWangTsx,
          importId: "mcp-road",
          selections: [{ wangSetIndex: 0, usage: "path" }],
          tags: ["tiled"],
          usages: ["smart-tiles-studio"],
        },
        expectedRevision: validated.snapshotRevision,
        idempotencyKey: "idem-tiled-tileset-import",
        dryRun: false,
      },
    });
    const applied = await toolData(fixture.client, "pokemap_apply", {
      operation: "apply",
      projectHandle,
      planId: planned.planId,
      operationId: "operation-tiled-tileset-import",
    });
    assert.equal(record(applied.receipt).actionId, "tileset.tiled.import");
    const persisted = record(
      JSON.parse(await readFile(join(fixture.root, "project.json"), "utf8")),
    );
    const tilesets = persisted.tilesets as JsonRecord[];
    const importedTileset = tilesets.find(
      (tileset) => tileset.id === "mcp-road-tileset",
    );
    assert.ok(importedTileset);
    assert.equal(record(importedTileset.source).kind, "regular_atlas");
    const catalog = record(persisted.smartTileCatalog);
    const presets = catalog.presets as JsonRecord[];
    assert.ok(presets.some((preset) => preset.id === "mcp-road-w0-preset"));
    const assets = record(
      JSON.parse(
        await readFile(
          join(fixture.root, "assets/.pokemap-assets.json"),
          "utf8",
        ),
      ),
    );
    assert.ok(
      (assets.records as JsonRecord[]).some(
        (asset) => asset.id === "mcp-road-image",
      ),
    );
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test("MCP imports one complete TMX bundle through one canonical receipt", async () => {
  const fixture = await mutationFixture();
  try {
    const sourcePath = join(fixture.root, "tmx-road.png");
    await writeFile(
      sourcePath,
      Buffer.from(
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=",
        "base64",
      ),
    );
    const staged = await toolData(fixture.client, "pokemap_artifact_stage", {
      sourcePath,
      declaredMediaType: "image/png",
    });
    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const projectHandle = String(opened.projectHandle);
    const validated = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });
    const planned = await toolData(fixture.client, "pokemap_plan", {
      projectHandle,
      request: {
        requestId: "tiled-map-import",
        actionId: "map.tiled.import",
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle,
        parameters: {
          mapId: "mcp-tiled-road",
          displayName: "MCP Tiled Road",
          role: "exterior",
          tmx: tiledMapTmx,
          layerModes: { "1": "data" },
          tilesets: [
            {
              source: "road.tsx",
              tsx: tiledWangTsx,
              tilesetId: "mcp-tiled-road-tileset",
              assetId: "mcp-tiled-road-image",
              logicalPath: "assets/mcp-tiled-road.png",
              imageArtifacts: [
                {
                  source: "road.png",
                  artifactHandle: staged.artifactHandle,
                },
              ],
            },
          ],
        },
        expectedRevision: validated.snapshotRevision,
        idempotencyKey: "idem-tiled-map-import",
        dryRun: false,
      },
    });
    assert.equal(record(planned.receipt).status, "planned");
    const applied = await toolData(fixture.client, "pokemap_apply", {
      operation: "apply",
      projectHandle,
      planId: planned.planId,
      operationId: "operation-tiled-map-import",
    });
    assert.equal(record(applied.receipt).actionId, "map.tiled.import");
    const persistedMap = record(
      JSON.parse(
        await readFile(join(fixture.root, "maps/mcp-tiled-road.json"), "utf8"),
      ),
    );
    const layer = record((persistedMap.layers as unknown[])[0]);
    assert.equal(layer.runtimeType, "tile");
    assert.equal(layer.purpose, "data");
    assert.equal(layer.isVisible, false);
    assert.deepEqual(layer.cells, [1, 0]);
    assert.equal(record((layer.palette as unknown[])[0]).tilesetId, "mcp-tiled-road-tileset");
    const persistedProject = record(
      JSON.parse(await readFile(join(fixture.root, "project.json"), "utf8")),
    );
    assert.ok(
      (persistedProject.maps as JsonRecord[]).some(
        (map) => map.id === "mcp-tiled-road",
      ),
    );
    const importedTileset = (persistedProject.tilesets as JsonRecord[]).find(
      (tileset) => tileset.id === "mcp-tiled-road-tileset",
    );
    assert.equal(importedTileset?.transparentColor, "f05ba1");
    const importedSource = record(importedTileset?.source);
    const tileAnimations = importedSource.tileAnimations as unknown[];
    assert.equal(tileAnimations.length, 1);
    assert.equal(record(tileAnimations[0]).tileId, 0);
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test("MCP imports a TMX larger than its request budget through an artifact handle", async () => {
  const fixture = await mutationFixture();
  try {
    const imagePath = join(fixture.root, "large-tmx-road.png");
    await writeFile(
      imagePath,
      Buffer.from(
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=",
        "base64",
      ),
    );
    const largeTmx = tiledMapTmx.replace(
      "<map",
      `<!--${" ".repeat(1_100_000)}--><map`,
    );
    const tmxPath = join(fixture.root, "large-road.tmx");
    await writeFile(tmxPath, largeTmx);
    const stagedImage = await toolData(
      fixture.client,
      "pokemap_artifact_stage",
      { sourcePath: imagePath, declaredMediaType: "image/png" },
    );
    const stagedTmx = await toolData(
      fixture.client,
      "pokemap_artifact_stage",
      { sourcePath: tmxPath },
    );
    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const projectHandle = String(opened.projectHandle);
    const validated = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });
    const baseRequest = {
      requestId: "large-tiled-map-import",
      actionId: "map.tiled.import",
      actionVersion: 1,
      workspaceHandle: opened.workspaceHandle,
      parameters: {
        mapId: "mcp-large-tiled-road",
        displayName: "MCP Large Tiled Road",
        role: "exterior",
        tilesets: [
          {
            source: "road.tsx",
            tsx: tiledWangTsx,
            tilesetId: "mcp-large-tiled-road-tileset",
            assetId: "mcp-large-tiled-road-image",
            logicalPath: "assets/mcp-large-tiled-road.png",
            imageArtifacts: [
              {
                source: "road.png",
                artifactHandle: stagedImage.artifactHandle,
              },
            ],
          },
        ],
      },
      expectedRevision: validated.snapshotRevision,
      idempotencyKey: "idem-large-tiled-map-import",
      dryRun: false,
    };
    const rejectedInline = await fixture.client.callTool({
      name: "pokemap_plan",
      arguments: {
        projectHandle,
        request: {
          ...baseRequest,
          parameters: { ...baseRequest.parameters, tmx: largeTmx },
        },
      },
    });
    assert.equal(rejectedInline.isError, true);
    assert.equal(
      record(record(rejectedInline.structuredContent).error).code,
      "resource_limit",
    );

    const planned = await toolData(fixture.client, "pokemap_plan", {
      projectHandle,
      request: {
        ...baseRequest,
        parameters: {
          ...baseRequest.parameters,
          tmxArtifactHandle: stagedTmx.artifactHandle,
        },
      },
    });
    await toolData(fixture.client, "pokemap_apply", {
      operation: "apply",
      projectHandle,
      planId: planned.planId,
      operationId: "operation-large-tiled-map-import",
    });
    const persisted = JSON.parse(
      await readFile(
        join(fixture.root, "maps/mcp-large-tiled-road.json"),
        "utf8",
      ),
    ) as JsonRecord;
    assert.equal(persisted.id, "mcp-large-tiled-road");
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test("MCP packs a Tiled image collection through one canonical receipt", async () => {
  const fixture = await mutationFixture();
  try {
    const sourcePath = join(fixture.root, "prop.png");
    await writeFile(
      sourcePath,
      Buffer.from(
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=",
        "base64",
      ),
    );
    const staged = await toolData(fixture.client, "pokemap_artifact_stage", {
      sourcePath,
      declaredMediaType: "image/png",
    });
    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const projectHandle = String(opened.projectHandle);
    const validated = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });
    const planned = await toolData(fixture.client, "pokemap_plan", {
      projectHandle,
      request: {
        requestId: "tiled-collection-import",
        actionId: "tileset.tiled.import",
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle,
        parameters: {
          imageArtifacts: [
            { source: "flower.png", artifactHandle: staged.artifactHandle },
            { source: "water.png", artifactHandle: staged.artifactHandle },
          ],
          assetId: "mcp-props",
          logicalPath: "assets/tilesets/mcp-props",
          tilesetId: "mcp-props",
          displayName: "MCP Props",
          tsx: tiledCollectionTsx,
          importId: "mcp-props",
          selections: [],
          tags: ["tiled", "prop"],
          usages: ["smart-tiles-studio"],
        },
        expectedRevision: validated.snapshotRevision,
        idempotencyKey: "idem-tiled-collection-import",
        dryRun: false,
      },
    });
    const preview = record(record(planned.plan).preview);
    assert.equal(preview.sourceKind, "image_collection");
    assert.equal(preview.sourceImageCount, 2);
    assert.equal(preview.generatedPageCount, 1);

    const applied = await toolData(fixture.client, "pokemap_apply", {
      operation: "apply",
      projectHandle,
      planId: planned.planId,
      operationId: "operation-tiled-collection-import",
    });
    assert.equal(record(applied.receipt).actionId, "tileset.tiled.import");
    const persisted = record(
      JSON.parse(await readFile(join(fixture.root, "project.json"), "utf8")),
    );
    const tilesets = persisted.tilesets as JsonRecord[];
    const imported = tilesets.find((tileset) => tileset.id === "mcp-props");
    assert.ok(imported);
    const source = record(imported.source);
    assert.equal(source.kind, "image_collection");
    assert.deepEqual(
      (source.tileDefinitions as JsonRecord[]).map((tile) => tile.tileId),
      [5, 9],
    );
    const assets = record(
      JSON.parse(
        await readFile(
          join(fixture.root, "assets/.pokemap-assets.json"),
          "utf8",
        ),
      ),
    );
    assert.ok(
      (assets.records as JsonRecord[]).some(
        (asset) => asset.id === "mcp-props-page-0000",
      ),
    );
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
      "smart_tile.cell.erase",
      "smart_tile.cell.paint",
      "smart_tile.layer.create",
      "smart_tile.layer.delete",
      "smart_tile.layer.merge",
      "smart_tile.layer.normalize",
      "smart_tile.material.upsert",
      "smart_tile.pattern.delete",
      "smart_tile.pattern.erase",
      "smart_tile.pattern.paint",
      "smart_tile.pattern.upsert",
      "smart_tile.preset.draft.delete",
      "smart_tile.preset.draft.upsert",
      "smart_tile.preset.delete",
      "smart_tile.preset.publish",
      "tileset.tiled.import",
    ]) {
      assert.ok(actionIds.includes(actionId), actionId);
    }
    assert.equal(actionIds.includes("smart_tile.tiled_wang.import"), false);
    const paintAction = (described.mutationActions as JsonRecord[]).find(
      (action) => action.id === "smart_tile.cell.paint",
    );
    assert.ok(paintAction);
    assert.deepEqual(record(paintAction.extensions).supportedSelections, [
      "cells",
      "line",
      "rectangle",
      "floodFill",
    ]);
    const resourceKindIds = (described.resourceKinds as JsonRecord[]).map(
      (resource) => resource.id,
    );
    for (const resourceKind of [
      "smartTileAnimation",
      "smartTileAtlas",
      "smartTileDraft",
      "smartTileLayer",
      "smartTileMaterial",
      "smartTilePattern",
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
        draft: completeMultiMaterialSmartTileDraft({
          id: "mcp-library-draft",
          targetPresetId: "mcp-library-preset",
        }),
      },
      "draft-upsert-library",
    );
    const queriedDraft = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "smartTileDraft",
      operation: "get",
      view: "detail",
      ids: ["mcp-library-draft"],
    });
    assert.equal(
      record((queriedDraft.items as unknown[])[0]).id,
      "mcp-library-draft",
    );
    const queriedMultiDraft = record((queriedDraft.items as unknown[])[0]);
    const queriedMultiRule = record(
      (queriedMultiDraft.rules as unknown[])[0],
    );
    const queriedMultiSignature = record(queriedMultiRule.signature);
    const queriedMultiCandidate = record(
      (queriedMultiRule.candidates as unknown[])[0],
    );
    const queriedMultiPart = record(
      (queriedMultiCandidate.parts as unknown[])[0],
    );
    assert.equal(
      record(queriedMultiSignature.northEdge).materialId,
      "mcp-library-draft-water",
    );
    assert.equal(
      record(queriedMultiSignature.eastEdge).materialId,
      "mcp-library-draft-stone",
    );
    assert.equal(queriedMultiPart.channel, "foreground");
    assert.equal(queriedMultiPart.offsetUnit, "pixel");
    assert.equal(queriedMultiPart.offsetX, 2);
    assert.equal(queriedMultiPart.offsetY, -1);
    assert.equal(queriedMultiPart.footprintWidth, 2);
    assert.equal(queriedMultiPart.footprintHeight, 3);
    assert.equal(queriedMultiPart.anchorX, 4);
    assert.equal(queriedMultiPart.anchorY, 5);
    assert.equal(queriedMultiPart.drawOrder, 6);

    await applyAction(
      "smart_tile.preset.publish",
      { draftId: "mcp-library-draft" },
      "publish-library",
    );
    const libraryPresets = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "smartTilePreset",
      operation: "list",
    });
    assert.ok(
      (libraryPresets.items as JsonRecord[]).some(
        (item) => item.id === "mcp-library-preset",
      ),
    );

    await applyAction(
      "smart_tile.preset.draft.upsert",
      {
        draft: completeSimpleSmartTileDraft({
          id: "mcp-map-draft",
          targetPresetId: "mcp-map-preset",
          usage: "path",
        }),
      },
      "draft-upsert-map",
    );
    await applyAction(
      "smart_tile.preset.publish",
      {
        draftId: "mcp-map-draft",
        layer: {
          mapId: "map_hanazuki_village",
          layerId: "mcp_map_layer",
          name: "MCP map layer",
        },
      },
      "publish-map",
    );
    const publishedLayers = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "smartTileLayer",
      operation: "list",
    });
    assert.ok(
      (publishedLayers.items as JsonRecord[]).some(
        (item) => item.id === "map_hanazuki_village:mcp_map_layer",
      ),
    );

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
    assert.equal(map.version, "v6");
    const layers = map.layers as JsonRecord[];
    assert.deepEqual(
      layers.map((layer) => layer.id),
      ["base", "terrain", "path_target", "collisions", "mcp_map_layer"],
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
    const reopenedPresets = await toolData(fixture.client, "pokemap_query", {
      projectHandle: String(reopened.projectHandle),
      resourceKind: "smartTilePreset",
      operation: "list",
    });
    assert.ok(
      (reopenedPresets.items as JsonRecord[]).some(
        (item) => item.id === "mcp-library-preset",
      ),
    );
    assert.ok(
      (reopenedPresets.items as JsonRecord[]).some(
        (item) => item.id === "mcp-map-preset",
      ),
    );
    const reopenedLayers = await toolData(fixture.client, "pokemap_query", {
      projectHandle: String(reopened.projectHandle),
      resourceKind: "smartTileLayer",
      operation: "list",
    });
    assert.ok(
      (reopenedLayers.items as JsonRecord[]).some(
        (item) => item.id === "map_hanazuki_village:mcp_map_layer",
      ),
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

const tiledWangTsx = `
<tileset name="Road" tilewidth="1" tileheight="1" tilecount="1" columns="1">
  <image source="road.png" trans="f05ba1" width="1" height="1"/>
  <tile id="0"><animation><frame tileid="0" duration="120"/></animation></tile>
  <wangsets>
    <wangset name="Road" type="edge" tile="-1">
      <wangcolor name="Road" color="#c8a162" tile="0" probability="1"/>
      <wangtile tileid="0" wangid="1,0,1,0,1,0,1,0"/>
    </wangset>
  </wangsets>
</tileset>
`;

const tiledCollectionTsx = `
<tileset name="Props" tilewidth="1" tileheight="1" tilecount="2" columns="0">
  <tileoffset x="2" y="-3"/>
  <tile id="5"><image source="flower.png" width="1" height="1"/></tile>
  <tile id="9">
    <image source="water.png" width="1" height="1"/>
    <animation><frame tileid="5" duration="120"/></animation>
  </tile>
</tileset>
`;

const tiledMapTmx = `
<map version="1.10" tiledversion="1.11.2" orientation="orthogonal"
  renderorder="right-down" width="2" height="1" tilewidth="1" tileheight="1"
  infinite="0" nextlayerid="2" nextobjectid="1">
  <tileset firstgid="1" source="road.tsx"/>
  <layer id="1" name="Ground" width="2" height="1">
    <data encoding="csv">1,0</data>
  </layer>
</map>
`;

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
      (action) => String(action.id),
    );
    assert.ok(actionIds.includes("tileset_folder.upsert"));
    assert.ok(actionIds.includes("element_category.upsert"));
    assert.equal(
      actionIds.some((id) =>
        ["terrain.", "path.", "surface."].some((prefix) => id.startsWith(prefix)),
      ),
      false,
    );
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
          source: {
            kind: "regular_atlas",
            assetId: "m02-atlas",
            pixelWidth: 128,
            pixelHeight: 80,
            tileWidth: 16,
            tileHeight: 16,
            tileProperties: [],
          },
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

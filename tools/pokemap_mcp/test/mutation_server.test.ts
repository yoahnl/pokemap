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
import { canonicalPokemonConfig } from "./pokemon_fixture.js";

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

function pngHeader(width: number, height: number, marker = 0): Buffer {
  const bytes = Buffer.alloc(24);
  Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]).copy(bytes, 0);
  bytes[8] = marker;
  Buffer.from([73, 72, 68, 82]).copy(bytes, 12);
  bytes.writeUInt32BE(width, 16);
  bytes.writeUInt32BE(height, 20);
  return bytes;
}

function mp4Box(type: string, payload: Buffer): Buffer {
  const bytes = Buffer.alloc(8 + payload.length);
  bytes.writeUInt32BE(bytes.length, 0);
  bytes.write(type, 4, 4, "ascii");
  payload.copy(bytes, 8);
  return bytes;
}

function h264Mp4Fixture(width: number, height: number): Buffer {
  const ftyp = mp4Box(
    "ftyp",
    Buffer.from([0x69, 0x73, 0x6f, 0x6d, 0, 0, 0, 0, 0x69, 0x73, 0x6f, 0x6d]),
  );
  const mvhd = Buffer.alloc(20);
  mvhd.writeUInt32BE(1000, 12);
  mvhd.writeUInt32BE(1000, 16);
  const tkhd = Buffer.alloc(84);
  tkhd.writeUInt32BE(width << 16, tkhd.length - 8);
  tkhd.writeUInt32BE(height << 16, tkhd.length - 4);
  const hdlr = Buffer.alloc(12);
  hdlr.write("vide", 8, 4, "ascii");
  const stsd = mp4Box("stsd", Buffer.from("avc1", "ascii"));
  const stbl = mp4Box("stbl", stsd);
  const minf = mp4Box("minf", stbl);
  const mdia = mp4Box("mdia", Buffer.concat([mp4Box("hdlr", hdlr), minf]));
  const trak = mp4Box(
    "trak",
    Buffer.concat([mp4Box("tkhd", tkhd), mdia]),
  );
  const moov = mp4Box(
    "moov",
    Buffer.concat([mp4Box("mvhd", mvhd), trak]),
  );
  return Buffer.concat([ftyp, moov]);
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
    withSmartTileReconstruction?: boolean;
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
  } else if (options.withSmartTileReconstruction) {
    await mkdir(join(root, "maps"), { recursive: true });
    await writeFile(
      join(root, "project.json"),
      JSON.stringify(smartTileReconstructionProject()),
    );
    await writeFile(
      join(root, "maps/reconstruction.json"),
      JSON.stringify(smartTileReconstructionMap()),
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
  const projectPath = join(root, "project.json");
  const project = record(JSON.parse(await readFile(projectPath, "utf8")));
  project.pokemon = canonicalPokemonConfig();
  await writeFile(projectPath, JSON.stringify(project));
  for (const directory of ["species", "learnsets", "evolutions", "media"]) {
    await mkdir(join(root, "data/pokemon", directory), { recursive: true });
  }
  const catalogDirectory = join(root, "data/pokemon/catalogs");
  await mkdir(catalogDirectory, { recursive: true });
  for (const catalogId of [
    "types",
    "abilities",
    "moves",
    "growth_rates",
    "items",
  ]) {
    await writeFile(
      join(catalogDirectory, `${catalogId}.json`),
      JSON.stringify({
        schemaVersion: 1,
        ...(catalogId === "items" ? {} : { catalog: catalogId }),
        entries: [],
      }),
    );
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

function smartTileReconstructionProject(): JsonRecord {
  return {
    name: "Smart Tile reconstruction MCP fixture",
    version: "v6",
    maps: [
      {
        id: "reconstruction",
        name: "Reconstruction",
        relativePath: "maps/reconstruction.json",
      },
    ],
    tilesets: [
      {
        id: "tiles",
        name: "Tiles",
        relativePath: "assets/smart_tileset.png",
        source: {
          kind: "regular_atlas",
          assetId: "asset",
          pixelWidth: 64,
          pixelHeight: 32,
          tileWidth: 32,
          tileHeight: 32,
          tileProperties: [],
        },
      },
    ],
    smartTileCatalog: {
      formatVersion: 2,
      categories: [],
      atlases: [
        {
          id: "atlas",
          name: "Atlas",
          tilesetId: "tiles",
          columns: 2,
          rows: 1,
        },
      ],
      animations: [],
      materials: [
        { id: "dirt", name: "Dirt", connectionGroupId: "ground" },
        { id: "grass", name: "Grass", connectionGroupId: "ground" },
      ],
      presets: [
        {
          id: "edge",
          name: "Edge",
          usage: "path",
          topology: "wang_edge_4",
          templateHint: "free",
          status: "published",
          coveragePolicy: "sparse",
          coverageProfile: {
            mode: "explicit",
            requiredScenarios: [
              {
                id: "north_grass",
                centerMaterialId: "dirt",
                signature: { northEdge: "grass" },
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
          defaultMaterialId: "dirt",
          allowedMaterialIds: ["dirt", "grass"],
          rules: [
            {
              id: "north_grass",
              centerMatch: { kind: "any" },
              signature: {
                northWestCorner: { kind: "any" },
                northEdge: { kind: "material", materialId: "grass" },
                northEastCorner: { kind: "any" },
                eastEdge: { kind: "any" },
                southEastCorner: { kind: "any" },
                southEdge: { kind: "any" },
                southWestCorner: { kind: "any" },
                westEdge: { kind: "any" },
              },
              candidates: [
                {
                  id: "north_grass_candidate",
                  weight: 1,
                  parts: [
                    {
                      source: {
                        kind: "frame",
                        frame: {
                          atlasId: "atlas",
                          column: 1,
                          row: 0,
                        },
                      },
                    },
                  ],
                },
              ],
            },
          ],
        },
      ],
    },
  };
}

function smartTileReconstructionMap(): JsonRecord {
  return {
    id: "reconstruction",
    name: "Reconstruction",
    size: { width: 1, height: 1 },
    version: "v6",
    layers: [
      {
        id: "literal",
        name: "Literal",
        palette: [{ tilesetId: "tiles", localTileId: 1 }],
        cells: [1],
        runtimeType: "tile",
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
              {
                source: {
                  kind: "frame",
                  frame: { atlasId, column: 0, row: 0 },
                },
                channel: "actor_occlusion",
                drawOrder: 7,
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

test("MCP scene.upsert preserves a non-base Pokemon form", async () => {
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
    assert.ok(actionIds.includes("scene.upsert"));
    const validated = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });
    await applyMutation(fixture.client, {
      projectHandle,
      workspaceHandle,
      expectedRevision: String(validated.snapshotRevision),
      actionId: "scene.upsert",
      sequence: "scene-pokemon-form",
      parameters: {
        scene: {
          id: "gift-scene-mcp",
          name: "Gift Scene MCP",
          graph: {
            startNodeId: "start",
            nodes: [
              { id: "start", kind: "start" },
              {
                id: "gift",
                kind: "action",
                payload: {
                  kind: "action",
                  consequence: {
                    kind: "givePokemon",
                    speciesId: "sproutle",
                    formId: "sunny",
                    level: 7,
                    currentHp: 24,
                    natureId: "hardy",
                    abilityId: "overgrow",
                  },
                },
              },
              { id: "end", kind: "end" },
            ],
            edges: [
              {
                id: "start-gift",
                fromNodeId: "start",
                fromPortId: "completed",
                toNodeId: "gift",
                kind: "default",
              },
              {
                id: "gift-end",
                fromNodeId: "gift",
                fromPortId: "completed",
                toNodeId: "end",
                kind: "actionCompleted",
              },
            ],
          },
        },
      },
    });

    const project = record(
      JSON.parse(await readFile(join(fixture.root, "project.json"), "utf8")),
    );
    const scenes = project.scenes as JsonRecord[];
    const scene = scenes.find((candidate) => candidate.id === "gift-scene-mcp");
    const graph = record(scene?.graph);
    const nodes = graph.nodes as JsonRecord[];
    const gift = nodes.find((candidate) => candidate.id === "gift");
    const consequence = record(record(gift?.payload).consequence);
    assert.equal(consequence.speciesId, "sproutle");
    assert.equal(consequence.formId, "sunny");
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
    await rm(fixture.root, { recursive: true, force: true });
  }
});

+test("MCP persists a typed pause menu visibility consequence", async () => {
  const fixture = await mutationFixture();
  try {
    const projectDocument = record(
      JSON.parse(await readFile(join(fixture.root, "project.json"), "utf8")),
    );
    const scenes = Array.isArray(projectDocument.scenes)
      ? projectDocument.scenes
      : [];
    projectDocument.scenes = [
      ...scenes,
      {
        id: "intro_scene",
        name: "Intro scene",
        graph: {
          startNodeId: "start",
          nodes: [
            { id: "start", kind: "start" },
            {
              id: "action",
              kind: "action",
              payload: {
                kind: "action",
                parameters: {},
                interactiveCommand: { kind: "openPc" },
              },
            },
            { id: "end", kind: "end" },
          ],
          edges: [
            {
              id: "start_action",
              fromNodeId: "start",
              fromPortId: "completed",
              toNodeId: "action",
              kind: "default",
            },
            {
              id: "action_end",
              fromNodeId: "action",
              fromPortId: "completed",
              toNodeId: "end",
              kind: "actionCompleted",
            },
          ],
        },
      },
    ];
    await writeFile(
      join(fixture.root, "project.json"),
      JSON.stringify(projectDocument),
    );

    const described = await toolData(fixture.client, "pokemap_describe", {});
    const pauseAction = (
      record(described.fullParity).mutationActions as JsonRecord[]
    ).find(
      (action) =>
        String(action.actionId) === "scene.pause_menu_visibility.set",
    );
    assert.ok(pauseAction);

    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const validated = await toolData(fixture.client, "pokemap_validate", {
      projectHandle: String(opened.projectHandle),
    });

    await applyMutation(fixture.client, {
      projectHandle: String(opened.projectHandle),
      workspaceHandle: String(opened.workspaceHandle),
      expectedRevision: String(validated.snapshotRevision),
      actionId: "scene.pause_menu_visibility.set",
      parameters: {
        sceneId: "intro_scene",
        nodeId: "action",
        actionId: "pokedex",
        visible: false,
      },
      sequence: "pause-menu-visibility",
    });

    const persisted = record(
      JSON.parse(await readFile(join(fixture.root, "project.json"), "utf8")),
    );
    const persistedScene = (persisted.scenes as JsonRecord[]).find(
      (scene) => String(scene.id) === "intro_scene",
    );
    assert.ok(persistedScene);
    const graph = record(persistedScene.graph);
    const actionNode = (graph.nodes as JsonRecord[]).find(
      (node) => String(node.id) === "action",
    );
    assert.ok(actionNode);
    assert.deepEqual(record(record(actionNode.payload).consequence), {
      kind: "setPauseMenuEntryVisibility",
      actionId: "pokedex",
      visible: false,
    });
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
    await rm(fixture.root, { recursive: true, force: true });
  }
});


test("CIN-033 certifies preSession and Presentation through live MCP", async () => {
  const fixture = await mutationFixture();
  try {
    await mkdir(join(fixture.root, "maps"), { recursive: true });
    await writeFile(
      join(fixture.root, "maps/map_start.json"),
      JSON.stringify({
        id: "map_start",
        name: "Départ",
        version: "v6",
        size: { width: 2, height: 2 },
        layers: [
          {
            id: "ground",
            name: "Sol",
            tiles: [0, 0, 0, 0],
            runtimeType: "tile",
          },
        ],
      }),
    );
    await writeFile(
      join(fixture.root, "project.json"),
      JSON.stringify({
        name: "CIN-033 MCP fixture",
        version: "v7",
        maps: [
          {
            id: "map_start",
            name: "Départ",
            relativePath: "maps/map_start.json",
          },
        ],
        tilesets: [],
        pokemon: canonicalPokemonConfig(),
        presentationCinematics: [
          {
            schemaVersion: 3,
            capabilities: ["cinematic.presentation"],
            timebase: { unit: "microsecond", ticksPerSecond: 1_000_000 },
            id: "opening",
            title: "Opening",
            description: "",
            durationUs: 4_000_000,
            layers: [
              {
                id: "background",
                label: "Background",
                zIndex: 0,
                visible: true,
                locked: false,
              },
              {
                id: "foreground",
                label: "Foreground",
                zIndex: 2,
                visible: true,
                locked: false,
              },
            ],
            visualFolders: [],
            tracks: [
              {
                id: "visual",
                label: "Visual",
                kind: "visual",
                clips: [
                  {
                    id: "line",
                    kind: "visual",
                    contentKind: "text",
                    startUs: 250_000,
                    durationUs: 1_000_000,
                    layerId: "background",
                    text: "Opening",
                  },
                ],
              },
              {
                id: "secondary",
                label: "Secondary",
                kind: "marker",
                clips: [
                  {
                    id: "cue_player_name",
                    kind: "marker",
                    startUs: 500_000,
                    durationUs: 0,
                    label: "Ask player name",
                    markerKind: "interactionCue",
                    required: false,
                  },
                ],
              },
            ],
          },
          {
            schemaVersion: 3,
            capabilities: ["cinematic.presentation"],
            timebase: { unit: "microsecond", ticksPerSecond: 1_000_000 },
            id: "credits",
            title: "Credits",
            description: "",
            durationUs: 1_000_000,
            layers: [],
            visualFolders: [],
            tracks: [],
          },
        ],
        newGame: {
          enabled: true,
          startMapId: "map_start",
        },
      }),
    );
    const described = await toolData(fixture.client, "pokemap_describe", {});
    const catalog = new Map(
      (record(described.fullParity).mutationActions as JsonRecord[]).map(
        (action) => [String(action.actionId), action],
      ),
    );
    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const projectHandle = String(opened.projectHandle);
    const workspaceHandle = String(opened.workspaceHandle);
    let revision = String(
      (
        await toolData(fixture.client, "pokemap_validate", {
          projectHandle,
        })
      ).snapshotRevision,
    );
    const initialRevision = revision;
    const observedActionIds = new Set<string>();
    let sequence = 0;
    let firstReceipt: JsonRecord | undefined;

    const apply = async (
      actionId: string,
      parameters: JsonRecord,
      confirmed = false,
    ): Promise<void> => {
      sequence += 1;
      let planned: JsonRecord;
      try {
        planned = await toolData(fixture.client, "pokemap_plan", {
          projectHandle,
          request: {
            requestId: "cin033-request-" + sequence,
            actionId,
            actionVersion: 1,
            workspaceHandle,
            parameters,
            expectedRevision: revision,
            idempotencyKey: "cin033-idempotency-" + sequence,
            dryRun: false,
          },
        });
      } catch (error) {
        throw new Error(`Failed to plan ${actionId}`, { cause: error });
      }
      const confirmation = confirmed
        ? await toolData(fixture.client, "pokemap_apply", {
            operation: "confirm",
            projectHandle,
            planId: planned.planId,
          })
        : undefined;
      const operationId = "cin033-operation-" + sequence;
      const applied = await toolData(fixture.client, "pokemap_apply", {
        operation: "apply",
        projectHandle,
        planId: planned.planId,
        operationId,
        ...(confirmation
          ? { confirmationToken: confirmation.confirmationToken }
          : {}),
      });
      const receipt = record(applied.receipt);
      assert.equal(receipt.actionId, actionId);
      assert.equal(receipt.status, "applied");
      observedActionIds.add(actionId);
      if (sequence === 1) {
        firstReceipt = receipt;
        const replay = await toolData(fixture.client, "pokemap_apply", {
          operation: "apply",
          projectHandle,
          planId: planned.planId,
          operationId,
        });
        assert.deepEqual(record(replay.receipt), receipt);
      }
      revision = String(
        (
          await toolData(fixture.client, "pokemap_validate", {
            projectHandle,
          })
        ).snapshotRevision,
      );
    };

    const presentationSteps: Array<{
      actionId: string;
      parameters: JsonRecord;
      confirmed?: boolean;
    }> = [
      {
        actionId: "presentationCinematic.create",
        parameters: {
          cinematicId: "intro",
          title: "Intro",
          description: "Before title",
          durationUs: 1_500_000,
        },
      },
      {
        actionId: "presentationCinematic.update",
        parameters: {
          cinematicId: "intro",
          title: "Intro revised",
          description: null,
          durationUs: 1_750_000,
        },
      },
      {
        actionId: "presentationCinematic.duplicate",
        parameters: {
          cinematicId: "intro",
          duplicateId: "intro-copy",
          title: "Intro copy",
        },
      },
      {
        actionId: "presentationCinematic.delete",
        parameters: { cinematicId: "credits" },
        confirmed: true,
      },
      {
        actionId: "presentationTrack.create",
        parameters: {
          cinematicId: "opening",
          track: {
            id: "transient",
            label: "Transient",
            kind: "marker",
            clips: [],
          },
        },
      },
      {
        actionId: "presentationTrack.update",
        parameters: {
          cinematicId: "opening",
          track: {
            id: "secondary",
            label: "Secondary revised",
            kind: "marker",
            clips: [],
          },
        },
      },
      {
        actionId: "presentationTrack.move",
        parameters: {
          cinematicId: "opening",
          trackId: "secondary",
          insertionIndex: 0,
        },
      },
      {
        actionId: "presentationTrack.duplicate",
        parameters: {
          cinematicId: "opening",
          trackId: "secondary",
          duplicateId: "secondary-copy",
          label: "Secondary copy",
        },
      },
      {
        actionId: "presentationTrack.delete",
        parameters: {
          cinematicId: "opening",
          trackId: "transient",
        },
        confirmed: true,
      },
      {
        actionId: "presentationClip.create",
        parameters: {
          cinematicId: "opening",
          trackId: "visual",
          clip: {
            id: "extra",
            kind: "visual",
            contentKind: "text",
            startUs: 2_000_000,
            durationUs: 500_000,
            layerId: "background",
            text: "Extra",
          },
        },
      },
      {
        actionId: "presentationClip.update",
        parameters: {
          cinematicId: "opening",
          trackId: "visual",
          clip: {
            id: "line",
            kind: "visual",
            contentKind: "text",
            startUs: 250_000,
            durationUs: 1_000_000,
            layerId: "background",
            text: "Opening revised",
          },
        },
      },
      {
        actionId: "presentationClip.move",
        parameters: {
          cinematicId: "opening",
          clipId: "line",
          targetTrackId: "visual",
          startUs: 500_000,
        },
      },
      {
        actionId: "presentationClip.resize",
        parameters: {
          cinematicId: "opening",
          clipId: "line",
          durationUs: 1_250_000,
        },
      },
      {
        actionId: "presentationClip.duplicate",
        parameters: {
          cinematicId: "opening",
          clipId: "line",
          duplicateId: "line-copy",
          targetTrackId: "visual",
          startUs: 2_500_000,
        },
      },
      {
        actionId: "presentationClip.delete",
        parameters: {
          cinematicId: "opening",
          clipId: "extra",
        },
        confirmed: true,
      },
      {
        actionId: "presentationClip.create",
        parameters: {
          cinematicId: "opening",
          trackId: "secondary",
          clip: {
            id: "cue_player_name",
            kind: "marker",
            startUs: 500_000,
            durationUs: 0,
            label: "Ask player name",
            markerKind: "interactionCue",
            required: false,
          },
        },
      },
      {
        actionId: "presentationLayer.create",
        parameters: {
          cinematicId: "opening",
          layer: {
            id: "transient-layer",
            label: "Transient layer",
            zIndex: 4,
            visible: true,
            locked: false,
          },
        },
      },
      {
        actionId: "presentationLayer.update",
        parameters: {
          cinematicId: "opening",
          layer: {
            id: "background",
            label: "Background revised",
            zIndex: 0,
            visible: true,
            locked: false,
          },
        },
      },
      {
        actionId: "presentationLayer.move",
        parameters: {
          cinematicId: "opening",
          layerId: "background",
          insertionIndex: 1,
          targetFolderId: null,
        },
      },
      {
        actionId: "presentationLayer.duplicate",
        parameters: {
          cinematicId: "opening",
          layerId: "background",
          duplicateId: "background-copy",
          label: "Background copy",
          zIndex: 8,
        },
      },
      {
        actionId: "presentationLayer.delete",
        parameters: {
          cinematicId: "opening",
          layerId: "transient-layer",
        },
        confirmed: true,
      },
    ];
    const preSessionSteps: Array<{
      actionId: string;
      parameters: JsonRecord;
    }> = [
      {
        actionId: "scene.preSession.create",
        parameters: {
          sceneId: "new_game_intro",
          name: "Nouvelle partie",
          templateId: "minimal",
          setAsEntrypoint: true,
        },
      },
      {
        actionId: "scene.preSession.interaction.insert",
        parameters: {
          sceneId: "new_game_intro",
          nodeId: "ask_name",
          targetNodeId: "end",
          interaction: {
            kind: "text",
            prompt: { localizationKey: "newGame.playerName.prompt" },
            resultBinding: { field: "playerName" },
          },
        },
      },
      {
        actionId: "scene.preSession.presentation.insert",
        parameters: {
          sceneId: "new_game_intro",
          nodeId: "opening",
          targetNodeId: "ask_name",
          presentationCinematicId: "opening",
        },
      },
      {
        actionId: "scene.preSession.interaction.update",
        parameters: {
          sceneId: "new_game_intro",
          nodeId: "ask_name",
          interaction: {
            kind: "text",
            prompt: {
              localizationKey: "newGame.playerName.prompt",
              fallbackText: "Comment veux-tu t’appeler ?",
            },
            textConstraints: { minGraphemes: 0, maxGraphemes: 48 },
            resultBinding: { field: "playerName" },
          },
          cueBinding: {
            presentationNodeId: "opening",
            markerId: "cue_player_name",
          },
        },
      },
      {
        actionId: "scene.preSession.presentation.createAndLink",
        parameters: {
          sceneId: "new_game_intro",
          nodeId: "studio_logo",
          targetNodeId: "end",
          cinematicId: "presentation_studio_logo",
          title: "Logo du studio",
          templateId: "blank",
          templateVersion: 1,
          targetFolderId: null,
          targetIndex: 0,
        },
      },
      {
        actionId: "scene.preSession.condition.insert",
        parameters: {
          sceneId: "new_game_intro",
          nodeId: "has_name",
          targetNodeId: "end",
          falseEndNodeId: "end_missing_name",
          draftField: "playerName",
          operator: "isTrue",
        },
      },
      {
        actionId: "scene.preSession.end.configure",
        parameters: {
          sceneId: "new_game_intro",
          nodeId: "end",
          outcomeId: "ready",
          outcomeLabel: "Prêt",
          outcomePolicy: "progression",
        },
      },
      // BETA-CIN-081: the CIN-V2 branches travel the MCP transport too, and
      // land in the live catalog like every other action.
      {
        actionId: "scene.presentation.cue.routes.set",
        parameters: {
          sceneId: "new_game_intro",
          presentationNodeId: "opening",
          markerId: "cue_player_name",
          routes: [
            {
              outputPortId: "completed",
              outcome: {
                kind: "repeatFromMarker",
                markerId: "cue_player_name",
              },
            },
          ],
        },
      },
    ];

    for (const step of presentationSteps) {
      await apply(step.actionId, step.parameters, step.confirmed);
    }
    for (const step of preSessionSteps) {
      await apply(step.actionId, step.parameters);
    }

    const expectedActionIds = new Set(
      [...presentationSteps, ...preSessionSteps].map((step) => step.actionId),
    );
    assert.deepEqual(observedActionIds, expectedActionIds);
    assert.equal(firstReceipt?.status, "applied");
    for (const actionId of expectedActionIds) {
      const action = catalog.get(actionId);
      assert.ok(action, actionId);
      assert.deepEqual(
        [...(action.endToEndVerifiedTransports as string[])].sort(),
        ["cli", "directApi", "editor", "mcp"],
        actionId,
      );
    }

    for (const resourceKind of [
      "presentationCinematic",
      "presentationTrack",
      "presentationClip",
      "presentationLayer",
    ]) {
      const filters =
        resourceKind === "presentationCinematic"
          ? {}
          : { cinematicId: "opening" };
      const firstPage = await toolData(fixture.client, "pokemap_query", {
        projectHandle,
        resourceKind,
        operation: "list",
        view: "detail",
        filters,
        pageSize: 1,
      });
      assert.equal((firstPage.items as unknown[]).length, 1, resourceKind);
      assert.equal(typeof firstPage.nextCursor, "string", resourceKind);
      const nextPage = await toolData(fixture.client, "pokemap_query", {
        projectHandle,
        resourceKind,
        operation: "list",
        view: "detail",
        filters,
        pageSize: 1,
        cursor: firstPage.nextCursor,
      });
      assert.equal((nextPage.items as unknown[]).length, 1, resourceKind);
    }
    const scene = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "scene",
      operation: "get",
      view: "detail",
      ids: ["new_game_intro"],
    });
    assert.equal((scene.items as unknown[]).length, 1);

    // Parity of receipts is not enough: read the branch back through the same
    // MCP query route an agent would use (BETA-CIN-081).
    const sceneDetail = record((scene.items as unknown[])[0]);
    const graph = record(sceneDetail.graph);
    const presentationNode = (graph.nodes as unknown[])
      .map((node) => record(node))
      .find((node) => node.id === "opening");
    assert.ok(presentationNode, "the Presentation node is queryable");
    const bindings = record(presentationNode.payload)
      .interactionCueBindings as unknown[];
    assert.deepEqual(record(bindings[0]).outcomeRoutes, [
      {
        outputPortId: "completed",
        outcome: { kind: "repeatFromMarker", markerId: "cue_player_name" },
      },
    ]);

    const stale = await fixture.client.callTool({
      name: "pokemap_plan",
      arguments: {
        projectHandle,
        request: {
          requestId: "cin033-stale",
          actionId: "scene.preSession.interaction.insert",
          actionVersion: 1,
          workspaceHandle,
          parameters: {
            sceneId: "new_game_intro",
            nodeId: "stale",
            targetNodeId: "end",
            interaction: {
              kind: "message",
              prompt: { localizationKey: "stale.prompt" },
            },
          },
          expectedRevision: initialRevision,
          idempotencyKey: "cin033-stale",
          dryRun: false,
        },
      },
    });
    assert.equal(stale.isError, true);
    assert.equal(
      record(record(stale.structuredContent).error).domainCode,
      "plan.stale",
    );
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test("MCP commits and undoes one atomic Presentation clip batch", async () => {
  const fixture = await mutationFixture();
  try {
    const described = await toolData(fixture.client, "pokemap_describe", {});
    const actions = new Map(
      (record(described.fullParity).mutationActions as JsonRecord[]).map(
        (action) => [String(action.actionId), action],
      ),
    );
    for (const actionId of [
      "presentationClip.batch",
      "presentationClip.deleteBatch",
      "presentationTimeline.insert",
    ]) {
      const action = actions.get(actionId);
      assert.ok(action);
      assert.deepEqual(action.endToEndVerifiedTransports, [
        "cli",
        "directApi",
        "editor",
        "mcp",
      ]);
      assert.deepEqual(Object.keys(record(action.endToEndEvidence)).sort(), [
        "cli",
        "directApi",
        "editor",
        "mcp",
      ]);
    }
    await writeFile(
      join(fixture.root, "project.json"),
      JSON.stringify({
        name: "Presentation clip batch MCP fixture",
        version: "v7",
        maps: [],
        tilesets: [],
        pokemon: canonicalPokemonConfig(),
        presentationCinematics: [
          {
            schemaVersion: 3,
            capabilities: ["cinematic.presentation"],
            timebase: { unit: "microsecond", ticksPerSecond: 1_000_000 },
            id: "opening",
            title: "Opening",
            description: "",
            durationUs: 5_000_000,
            layers: [],
            visualFolders: [],
            tracks: [
              {
                id: "markers",
                label: "Markers",
                kind: "marker",
                clips: [
                  {
                    id: "anchor",
                    kind: "marker",
                    startUs: 1_000_000,
                    durationUs: 0,
                    label: "Anchor",
                    markerKind: "ordinary",
                  },
                ],
              },
            ],
          },
        ],
      }),
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
        requestId: "cin024-mcp-batch",
        actionId: "presentationClip.batch",
        actionVersion: 1,
        workspaceHandle,
        parameters: {
          cinematicId: "opening",
          operations: [
            {
              kind: "edit",
              clipId: "anchor",
              targetTrackId: "markers",
              startUs: 2_000_000,
              durationUs: 0,
            },
          ],
        },
        expectedRevision: validation.snapshotRevision,
        idempotencyKey: "cin024-mcp-batch",
        dryRun: false,
      },
    });
    const applied = await toolData(fixture.client, "pokemap_apply", {
      operation: "apply",
      projectHandle,
      planId: planned.planId,
      operationId: "cin024-mcp-batch-apply",
    });
    assert.equal(record(applied.receipt).actionId, "presentationClip.batch");
    const queried = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "presentationClip",
      operation: "list",
      view: "detail",
      filters: { cinematicId: "opening", trackId: "markers" },
    });
    assert.equal(record((queried.items as unknown[])[0]).startUs, 2_000_000);
    const history = await toolData(fixture.client, "pokemap_history", {
      operation: "list",
      projectHandle,
      limit: 1,
    });
    const entry = record((history.entries as unknown[])[0]);
    await toolData(fixture.client, "pokemap_history", {
      operation: "undo",
      projectHandle,
      entryId: String(entry.entryId),
      idempotencyKey: "cin024-mcp-batch-undo",
    });
    const restored = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "presentationClip",
      operation: "list",
      view: "detail",
      filters: { cinematicId: "opening", trackId: "markers" },
    });
    assert.equal(record((restored.items as unknown[])[0]).startUs, 1_000_000);
    const deleteValidation = await toolData(
      fixture.client,
      "pokemap_validate",
      { projectHandle },
    );
    const deletePlan = await toolData(fixture.client, "pokemap_plan", {
      projectHandle,
      request: {
        requestId: "cin024-mcp-delete-batch",
        actionId: "presentationClip.deleteBatch",
        actionVersion: 1,
        workspaceHandle,
        parameters: { cinematicId: "opening", clipIds: ["anchor"] },
        expectedRevision: deleteValidation.snapshotRevision,
        idempotencyKey: "cin024-mcp-delete-batch",
        dryRun: false,
      },
    });
    const deleteConfirmation = await toolData(
      fixture.client,
      "pokemap_apply",
      {
        operation: "confirm",
        projectHandle,
        planId: deletePlan.planId,
      },
    );
    const deleted = await toolData(fixture.client, "pokemap_apply", {
      operation: "apply",
      projectHandle,
      planId: deletePlan.planId,
      operationId: "cin024-mcp-delete-batch-apply",
      confirmationToken: deleteConfirmation.confirmationToken,
    });
    assert.equal(
      record(deleted.receipt).actionId,
      "presentationClip.deleteBatch",
    );
    const afterDelete = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "presentationClip",
      operation: "list",
      view: "detail",
      filters: { cinematicId: "opening", trackId: "markers" },
    });
    assert.equal((afterDelete.items as unknown[]).length, 0);
    const deleteHistory = await toolData(
      fixture.client,
      "pokemap_history",
      { operation: "list", projectHandle, limit: 1 },
    );
    const deleteEntry = record((deleteHistory.entries as unknown[])[0]);
    await toolData(fixture.client, "pokemap_history", {
      operation: "undo",
      projectHandle,
      entryId: String(deleteEntry.entryId),
      idempotencyKey: "cin024-mcp-delete-batch-undo",
    });
    const deleteRestored = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "presentationClip",
      operation: "list",
      view: "detail",
      filters: { cinematicId: "opening", trackId: "markers" },
    });
    assert.equal((deleteRestored.items as unknown[]).length, 1);

    const insertValidation = await toolData(
      fixture.client,
      "pokemap_validate",
      { projectHandle },
    );
    const insertPlan = await toolData(fixture.client, "pokemap_plan", {
      projectHandle,
      request: {
        requestId: "cin055-mcp-timeline-insert",
        actionId: "presentationTimeline.insert",
        actionVersion: 1,
        workspaceHandle,
        parameters: {
          cinematicId: "opening",
          targetVisualFolderId: null,
          layer: null,
          track: {
            id: "inserted-markers",
            label: "Inserted markers",
            kind: "marker",
            clips: [
              {
                id: "inserted-marker",
                kind: "marker",
                startUs: 3_000_000,
                durationUs: 0,
                label: "Inserted marker",
                markerKind: "ordinary",
              },
            ],
          },
        },
        expectedRevision: insertValidation.snapshotRevision,
        idempotencyKey: "cin055-mcp-timeline-insert",
        dryRun: false,
      },
    });
    const inserted = await toolData(fixture.client, "pokemap_apply", {
      operation: "apply",
      projectHandle,
      planId: insertPlan.planId,
      operationId: "cin055-mcp-timeline-insert-apply",
    });
    assert.equal(
      record(inserted.receipt).actionId,
      "presentationTimeline.insert",
    );
    const insertedClips = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "presentationClip",
      operation: "list",
      view: "detail",
      filters: { cinematicId: "opening", trackId: "inserted-markers" },
    });
    assert.equal((insertedClips.items as unknown[]).length, 1);
    assert.equal(
      record((insertedClips.items as unknown[])[0]).startUs,
      3_000_000,
    );
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test("MCP executes and rereads every cinematic library catalog action", async () => {
  const fixture = await mutationFixture();
  try {
    await writeFile(
      join(fixture.root, "project.json"),
      JSON.stringify({
        name: "Cinematic library MCP fixture",
        version: "v7",
        maps: [],
        tilesets: [],
        pokemon: canonicalPokemonConfig(),
        cinematics: [
          {
            id: "world-a",
            title: "World A",
            timeline: { steps: [] },
          },
          {
            id: "world-b",
            title: "World B",
            timeline: { steps: [] },
          },
        ],
      }),
    );
    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const projectHandle = String(opened.projectHandle);
    const workspaceHandle = String(opened.workspaceHandle);
    let revision = String(
      (
        await toolData(fixture.client, "pokemap_validate", {
          projectHandle,
        })
      ).snapshotRevision,
    );
    let sequence = 0;
    const observedActionIds = new Set<string>();
    const actionIds = [
      "cinematicLibraryAsset.create",
      "cinematicLibraryAsset.duplicate",
      "cinematicLibraryAsset.delete",
      "cinematicLibraryFolder.create",
      "cinematicLibraryFolder.rename",
      "cinematicLibraryFolder.move",
      "cinematicLibraryFolder.reorder",
      "cinematicLibraryFolder.setArchived",
      "cinematicLibraryFolder.delete",
      "cinematicLibraryEntry.place",
      "cinematicLibraryEntry.reorder",
      "cinematicLibraryEntry.setArchived",
      "cinematicLibraryEntry.remove",
    ];

    const apply = async (
      actionId: string,
      parameters: JsonRecord,
      confirmed = false,
    ): Promise<void> => {
      sequence += 1;
      const planned = await toolData(fixture.client, "pokemap_plan", {
        projectHandle,
        request: {
          requestId: `cin049-plan-${sequence}`,
          actionId,
          actionVersion: 1,
          workspaceHandle,
          parameters,
          expectedRevision: revision,
          idempotencyKey: `cin049-idempotency-${sequence}`,
          dryRun: false,
        },
      });
      const confirmation = confirmed
        ? await toolData(fixture.client, "pokemap_apply", {
            operation: "confirm",
            projectHandle,
            planId: planned.planId,
          })
        : undefined;
      const applied = await toolData(fixture.client, "pokemap_apply", {
        operation: "apply",
        projectHandle,
        planId: planned.planId,
        operationId: `cin049-operation-${sequence}`,
        ...(confirmation
          ? { confirmationToken: confirmation.confirmationToken }
          : {}),
      });
      assert.equal(record(applied.receipt).actionId, actionId);
      observedActionIds.add(actionId);
      revision = String(
        (
          await toolData(fixture.client, "pokemap_validate", {
            projectHandle,
          })
        ).snapshotRevision,
      );
    };

    await apply("cinematicLibraryFolder.create", {
      folderId: "root-a",
      family: "world",
      name: "Root A",
      parentFolderId: null,
      targetIndex: 0,
    });
    await apply("cinematicLibraryFolder.create", {
      folderId: "root-b",
      family: "world",
      name: "Root B",
      parentFolderId: null,
      targetIndex: 1,
    });
    await apply("cinematicLibraryFolder.create", {
      folderId: "chapter",
      family: "world",
      name: "Chapter",
      parentFolderId: "root-a",
      targetIndex: 0,
    });
    await apply("cinematicLibraryFolder.rename", {
      folderId: "chapter",
      name: "Opening",
    });
    await apply("cinematicLibraryFolder.move", {
      folderId: "chapter",
      targetParentFolderId: "root-b",
      targetIndex: 0,
    });
    await apply("cinematicLibraryFolder.reorder", {
      folderId: "root-b",
      targetIndex: 0,
    });
    await apply("cinematicLibraryFolder.setArchived", {
      folderId: "root-a",
      isArchived: true,
    });
    await apply("cinematicLibraryEntry.place", {
      family: "world",
      cinematicId: "world-a",
      targetFolderId: "chapter",
      targetIndex: 0,
    });
    await apply("cinematicLibraryEntry.place", {
      family: "world",
      cinematicId: "world-b",
      targetFolderId: "chapter",
      targetIndex: 1,
    });
    await apply("cinematicLibraryEntry.reorder", {
      family: "world",
      cinematicId: "world-b",
      targetIndex: 0,
    });
    await apply("cinematicLibraryEntry.setArchived", {
      family: "world",
      cinematicId: "world-a",
      isArchived: true,
    });
    await apply("cinematicLibraryAsset.create", {
      family: "world",
      cinematicId: "world-created",
      title: "World created",
      targetFolderId: "chapter",
      targetIndex: 2,
      startingPoint: "blank",
    });
    await apply("cinematicLibraryAsset.duplicate", {
      family: "world",
      cinematicId: "world-created",
      duplicateId: "world-created-copy",
      title: "World created copy",
      targetFolderId: "chapter",
      targetIndex: 3,
    });
    await apply(
      "cinematicLibraryAsset.delete",
      { family: "world", cinematicId: "world-created-copy" },
      true,
    );
    await apply(
      "cinematicLibraryAsset.delete",
      { family: "world", cinematicId: "world-created" },
      true,
    );
    await apply(
      "cinematicLibraryEntry.remove",
      { family: "world", cinematicId: "world-a" },
      true,
    );
    await apply(
      "cinematicLibraryFolder.delete",
      { folderId: "root-a" },
      true,
    );

    assert.deepEqual([...observedActionIds].sort(), [...actionIds].sort());
    const described = await toolData(fixture.client, "pokemap_describe", {});
    const resourceKinds = new Set(
      (described.resourceKinds as JsonRecord[]).map((kind) => String(kind.id)),
    );
    for (const resourceKind of [
      "cinematicLibraryCatalog",
      "cinematicLibraryFolder",
      "cinematicLibraryEntry",
    ]) {
      assert.ok(resourceKinds.has(resourceKind), resourceKind);
    }
    const parityActions = record(described.fullParity)
      .mutationActions as JsonRecord[];
    for (const actionId of actionIds) {
      const parity = parityActions.find(
        (action) => String(action.actionId) === actionId,
      );
      assert.deepEqual(record(parity).endToEndVerifiedTransports, [
        "cli",
        "directApi",
        "editor",
        "mcp",
      ]);
    }
    const folders = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "cinematicLibraryFolder",
      operation: "list",
      filters: { family: "world" },
      view: "detail",
    });
    const chapter = (folders.items as JsonRecord[]).find(
      (folder) => String(folder.id) === "chapter",
    );
    assert.equal(record(chapter).parentFolderId, "root-b");
    const entries = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "cinematicLibraryEntry",
      operation: "list",
      filters: { family: "world" },
      view: "detail",
    });
    assert.deepEqual(
      (entries.items as JsonRecord[]).map((entry) => entry.cinematicId),
      ["world-b"],
    );
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test("MCP applies and rereads the authored presentation profile", async () => {
  const fixture = await mutationFixture();
  try {
    await mkdir(join(fixture.root, "assets"), { recursive: true });
    const importedSourcePath = join(fixture.root, "imported-opening.png");
    await writeFile(importedSourcePath, pngHeader(1920, 1080));
    const stagedImport = await toolData(
      fixture.client,
      "pokemap_artifact_stage",
      {
        sourcePath: importedSourcePath,
        declaredMediaType: "image/png",
      },
    );
    await writeFile(
      join(fixture.root, "assets/.pokemap-media.json"),
      JSON.stringify({
        schemaVersion: 1,
        entries: [
          {
            id: "opening-captions-fr",
            label: "Sous-titres FR",
            kind: "captions",
            sourceAssetId: "asset.opening-captions-fr",
            technicalMetadata: {
              mediaType: "text/vtt",
              container: "webvtt",
              codec: "webvtt",
              sizeBytes: 20,
            },
          },
          {
            id: "opening-poster",
            label: "Poster ouverture",
            kind: "poster",
            sourceAssetId: "asset.opening-poster",
            technicalMetadata: {
              mediaType: "image/png",
              container: "png",
              codec: "png",
              sizeBytes: 20,
              width: 1920,
              height: 1080,
            },
          },
          {
            id: "opening-video",
            label: "Video ouverture",
            kind: "video",
            sourceAssetId: "asset.opening-video",
            technicalMetadata: {
              mediaType: "video/mp4",
              container: "mp4",
              codec: "h264",
              sizeBytes: 100,
              width: 1920,
              height: 1080,
              durationMilliseconds: 1000,
            },
          },
        ],
      }),
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
    assert.ok(actionIds.includes("presentation.update"));
    assert.ok(actionIds.includes("presentationMedia.import"));
    assert.ok(actionIds.includes("presentationMedia.configure"));
    for (const actionId of [
      "presentation.preset.import_plan",
      "presentation.preset.import_apply",
      "presentation.preset.export",
      "presentation.preset.delete_plan",
      "presentation.preset.delete_apply",
    ]) {
      assert.ok(actionIds.includes(actionId));
    }
    const presentationKind = (described.resourceKinds as JsonRecord[]).find(
      (kind) => String(kind.id) === "projectPresentationProfile",
    );
    assert.equal(Number(presentationKind?.version), 10);
    const presetKind = (described.resourceKinds as JsonRecord[]).find(
      (kind) => String(kind.id) === "projectPresentationPreset",
    );
    assert.equal(Number(presetKind?.version), 2);
    const presentationAction = (
      record(described.fullParity).mutationActions as JsonRecord[]
    ).find((action) => String(action.actionId) === "presentation.update");
    assert.deepEqual(record(presentationAction).endToEndVerifiedTransports, [
      "cli",
      "directApi",
      "editor",
      "mcp",
    ]);
    const mediaImportAction = (
      record(described.fullParity).mutationActions as JsonRecord[]
    ).find((action) => String(action.actionId) === "presentationMedia.import");
    assert.deepEqual(record(mediaImportAction).endToEndVerifiedTransports, [
      "cli",
      "directApi",
      "editor",
      "mcp",
    ]);
    const mediaConfigurationAction = (
      record(described.fullParity).mutationActions as JsonRecord[]
    ).find(
      (action) => String(action.actionId) === "presentationMedia.configure",
    );
    assert.deepEqual(
      record(mediaConfigurationAction).endToEndVerifiedTransports,
      ["cli", "directApi", "mcp"],
    );

    const mediaValidated = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });
    let mediaRevision = String(mediaValidated.snapshotRevision);
    mediaRevision = await applyMutation(fixture.client, {
      projectHandle,
      workspaceHandle,
      expectedRevision: mediaRevision,
      actionId: "presentationMedia.import",
      parameters: {
        artifactHandle: stagedImport.artifactHandle,
        mediaId: "imported-opening",
        label: "Imported opening",
        kind: "image",
        assetId: "asset.imported-opening",
        logicalPath: "assets/presentation/imported-opening.png",
      },
      sequence: "opening-media-import",
    });
    const importedMedia = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "presentationMedia",
      operation: "get",
      view: "detail",
      ids: ["imported-opening"],
    });
    assert.equal(
      record((importedMedia.items as unknown[])[0]).sourceAssetId,
      "asset.imported-opening",
    );
    await applyMutation(fixture.client, {
      projectHandle,
      workspaceHandle,
      expectedRevision: mediaRevision,
      actionId: "presentationMedia.configure",
      parameters: {
        mediaId: "opening-video",
        posterMediaId: "opening-poster",
        fallbackMediaId: "opening-poster",
        captions: [
          { locale: "fr-FR", mediaId: "opening-captions-fr" },
        ],
        provenance: {
          source: "Avelune Studio original",
          creator: "Yoahn",
        },
        license: {
          identifier: "LicenseRef-Avelune-Proprietary",
          name: "Avelune proprietary media license",
        },
      },
      sequence: "opening-media-metadata",
    });
    const queriedMedia = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "presentationMedia",
      operation: "get",
      view: "detail",
      ids: ["opening-video"],
    });
    const openingVideo = record((queriedMedia.items as unknown[])[0]);
    assert.equal(record(openingVideo.provenance).creator, "Yoahn");
    assert.equal(
      record(openingVideo.license).identifier,
      "LicenseRef-Avelune-Proprietary",
    );
    assert.deepEqual(openingVideo.captions, [
      { locale: "fr-FR", mediaId: "opening-captions-fr" },
    ]);

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
          schemaVersion: 10,
          branding: { accentColor: "#126E78" },
          title: {
            title: "Aube sur Hanazuki",
            subtitle: "Studio Brume",
            prompt: "Appuyez pour commencer",
            actions: [
              {
                id: "newGame",
                label: "Commencer",
                icon: "sparkles",
                visible: true,
              },
              {
                id: "continueGame",
                label: "Reprendre",
                icon: "play",
                visible: true,
              },
              { id: "options", visible: false },
            ],
          },
          pause: {
            title: "Escale",
            hint: "A pour choisir",
            actions: [
              {
                id: "pokedex",
                label: "Carnet de voyage",
                icon: "book",
                visible: true,
              },
              { id: "resume", icon: "play", visible: true },
              { id: "map", icon: "map", visible: false },
            ],
            composition: {
              compactPortrait: {
                entrySize: "regular",
                entrySpacing: "regular",
                showTitle: true,
                showHint: true,
                showRootDetailPanel: false,
              },
              compactLandscape: {
                entrySize: "compact",
                entrySpacing: "tight",
                showTitle: true,
                showHint: false,
                showRootDetailPanel: true,
              },
              expanded: {
                entrySize: "large",
                entrySpacing: "airy",
                showTitle: true,
                showHint: true,
                showRootDetailPanel: false,
              },
            },
          },
          dialogue: {
            placement: "top",
            maxWidthFactor: 0.64,
            margin: 20,
            contentPadding: 24,
            shape: "speech",
            cornerRadius: 18,
            borderWidth: 3,
            fillOpacity: 0.82,
            surfaceColor: "#102030",
            borderColor: "#A0B0C0",
            textColor: "#F0F0F0",
            portraitSide: "end",
            portraitSize: 112,
            portraitShape: "circle",
            portraitFrameWidth: 4,
            portraitFrameColor: "#C0FFEE",
            nameplateStyle: "floating",
            nameplateBorderWidth: 2,
            nameplateSurfaceColor: "#334455",
            nameplateBorderColor: "#778899",
            nameplateTextColor: "#FFFFFF",
            choiceSpacing: 14,
            choiceShape: "cutCorner",
            choiceDisabledOpacity: 0.35,
            choiceSelectedColor: "#FFAA00",
            progressIndicator: "dots",
            progressIndicatorColor: "#00FFAA",
            portraitTransition: "slide",
            portraitTransitionMilliseconds: 320,
          },
          battle: {
            commandLayout: "radial",
            commandColumns: 2,
            showCommandIcons: true,
            commands: [
              { id: "run", label: "Retraite", icon: "run" },
              { id: "fight", label: "Techniques", icon: "fight" },
              { id: "party", label: "Alliés", icon: "party" },
              { id: "bag", label: "Inventaire", icon: "bag" },
            ],
            hpBarShape: "segmented",
            hpHealthyColor: "#00AA55",
            hpWarningColor: "#FFAA00",
            hpDangerColor: "#CC2244",
            moves: {
              layout: "grid",
              columns: 2,
              shape: "cutCorner",
              padding: 16,
            },
          },
          windows: {
            styles: [
              {
                id: "default",
                fillToken: "surface",
                borderToken: "outline",
                borderWidth: 1,
                cornerRadius: 16,
                contentPadding: 24,
                shadowElevation: 8,
              },
              {
                id: "pause-menu",
                fillToken: "menuSurface",
                borderToken: "primary",
                borderWidth: 2,
                cornerRadius: 24,
                contentPadding: 20,
                shadowElevation: 12,
                shape: "cutCorner",
                fillOpacity: 0.8,
              },
              {
                id: "dialogue",
                fillToken: "dialogueSurface",
                borderToken: "outline",
                borderWidth: 1,
                cornerRadius: 8,
                contentPadding: 12,
                shadowElevation: 4,
              },
              {
                id: "battle",
                fillToken: "battleHudSurface",
                borderToken: "primary",
                borderWidth: 2,
                cornerRadius: 12,
                contentPadding: 12,
                shadowElevation: 4,
              },
            ],
            defaultStyleId: "default",
            pauseMenuStyleId: "pause-menu",
            dialogueStyleId: "dialogue",
            battleStyleId: "battle",
            pauseBackdropOpacity: 0.8,
          },
          layouts: {
            title: responsiveLayout(
              "bottomCenter",
              "center",
              "bottomLeft",
            ),
            pauseMenu: responsiveLayout(
              "fullScreen",
              "left",
              "right",
            ),
            dialogue: responsiveLayout(
              "bottomCenter",
              "topCenter",
              "bottomCenter",
            ),
            battle: responsiveLayout(
              "bottomCenter",
              "right",
              "fullScreen",
            ),
          },
          typography: {
            combat: {
              family: "Battle Mono",
              fallbackFamilies: ["sans-serif"],
              metrics: {
                sizeScale: 1.1,
                weight: 600,
                lineHeight: 1.25,
                letterSpacing: 0.5,
              },
            },
          },
          surfacePalettes: {
            battle: {
              surface: "#102030",
              border: "#63E6FF",
              text: "#FFFFFF",
              accent: "#63E6FF",
            },
          },
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
    assert.equal(
      record(record(project.presentation).title).title,
      "Aube sur Hanazuki",
    );
    assert.deepEqual(
      (record(record(project.presentation).title).actions as JsonRecord[]).map(
        (action) => action.id,
      ),
      ["newGame", "continueGame", "options"],
    );
    assert.equal(
      record(
        (record(record(project.presentation).pause).actions as unknown[])[0],
      ).label,
      "Carnet de voyage",
    );
    assert.equal(
      record(
        record(record(record(project.presentation).pause).composition)
          .expanded,
      ).entrySize,
      "large",
    );
    assert.equal(
      record(record(project.presentation).windows).pauseMenuStyleId,
      "pause-menu",
    );
    assert.equal(
      record(record(project.presentation).windows).battleStyleId,
      "battle",
    );
    assert.equal(
      record(record(project.presentation).dialogue).placement,
      "top",
    );
    assert.equal(
      record(record(project.presentation).dialogue).surfaceColor,
      "#102030",
    );
    assert.equal(
      record(record(project.presentation).dialogue).portraitSide,
      "end",
    );
    assert.equal(
      record(record(project.presentation).dialogue).nameplateStyle,
      "floating",
    );
    assert.equal(
      record(record(project.presentation).dialogue).choiceShape,
      "cutCorner",
    );
    assert.equal(
      record(record(project.presentation).dialogue).progressIndicator,
      "dots",
    );
    assert.equal(
      record(record(project.presentation).battle).commandLayout,
      "radial",
    );
    assert.deepEqual(
      (record(record(project.presentation).battle).commands as JsonRecord[]).map(
        (command) => command.id,
      ),
      ["run", "fight", "party", "bag"],
    );
    assert.equal(
      record(
        (record(record(project.presentation).battle).commands as unknown[])[0],
      ).label,
      "Retraite",
    );
    assert.equal(
      record(record(project.presentation).battle).hpBarShape,
      "segmented",
    );
    assert.equal(
      record(record(record(project.presentation).typography).combat).family,
      "Battle Mono",
    );
    assert.equal(
      record(
        record(record(record(project.presentation).typography).combat).metrics,
      ).sizeScale,
      1.1,
    );
    assert.equal(
      record(
        record(record(project.presentation).surfacePalettes).battle,
      ).surface,
      "#102030",
    );
    assert.equal(
      record(
        (record(record(project.presentation).windows).styles as unknown[]).find(
          (style) => record(style).id === "pause-menu",
        ),
      ).shape,
      "cutCorner",
    );
    assert.equal(
      record(
        record(record(record(project.presentation).layouts).battle).regular,
      ).slot,
      "right",
    );
    assert.equal(
      record(
        record(record(record(project.presentation).layouts).title).expanded,
      ).slot,
      "bottomLeft",
    );
    const persisted = record(
      JSON.parse(await readFile(join(fixture.root, "project.json"), "utf8")),
    );
    assert.equal(
      record(record(persisted.presentation).branding).accentColor,
      "#126E78",
    );
    assert.equal(
      record(record(persisted.presentation).title).prompt,
      "Appuyez pour commencer",
    );
    assert.equal(
      record(
        (record(record(persisted.presentation).title).actions as unknown[])[2],
      ).visible,
      false,
    );
    assert.equal(
      record(record(persisted.presentation).pause).title,
      "Escale",
    );
    assert.equal(
      record(
        record(record(record(persisted.presentation).pause).composition)
          .expanded,
      ).showRootDetailPanel,
      false,
    );
    assert.equal(
      record(record(persisted.presentation).windows).dialogueStyleId,
      "dialogue",
    );
    assert.equal(
      record(record(persisted.presentation).windows).battleStyleId,
      "battle",
    );
    assert.equal(
      record(record(persisted.presentation).dialogue).maxWidthFactor,
      0.64,
    );
    assert.equal(
      record(record(persisted.presentation).dialogue).portraitShape,
      "circle",
    );
    assert.equal(
      record(record(persisted.presentation).dialogue).portraitTransition,
      "slide",
    );
    const presentationResource = await toolData(
      fixture.client,
      "pokemap_query",
      {
        projectHandle,
        resourceKind: "projectPresentationProfile",
        operation: "list",
        view: "detail",
      },
    );
    const presentationItem = record(
      (presentationResource.items as unknown[])[0],
    );
    assert.equal(
      record(record(presentationItem.profile).windows).pauseBackdropOpacity,
      0.8,
    );
    assert.equal(
      record(record(presentationItem.profile).dialogue).shape,
      "speech",
    );
    assert.equal(
      record(record(presentationItem.profile).dialogue).nameplateTextColor,
      "#FFFFFF",
    );
    assert.equal(
      record(record(presentationItem.profile).dialogue).choiceSelectedColor,
      "#FFAA00",
    );
    assert.equal(
      record(record(presentationItem.profile).battle).commandLayout,
      "radial",
    );
    assert.equal(
      record(record(record(presentationItem.profile).battle).moves).shape,
      "cutCorner",
    );
    const finalValidation = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });
    assert.equal(String(finalValidation.snapshotRevision), appliedRevision);

    const exportPlan = await toolData(fixture.client, "pokemap_plan", {
      projectHandle,
      request: {
        requestId: "mcp-preset-export",
        actionId: "presentation.preset.export",
        actionVersion: 1,
        workspaceHandle,
        parameters: {
          presetId: "avelune-profile",
          label: "Avelune Profile",
          description: "Shareable MCP presentation profile.",
          licenses: {},
          scope: "dialogue",
          replacedSections: ["dialogue", "layouts.dialogue"],
        },
        expectedRevision: finalValidation.snapshotRevision,
        idempotencyKey: "idem-mcp-preset-export",
        dryRun: false,
      },
    });
    const exportArtifact = record(
      (record(exportPlan.receipt).artifacts as JsonRecord[])[0],
    );
    const exported = await toolData(fixture.client, "pokemap_apply", {
      operation: "apply",
      projectHandle,
      planId: exportPlan.planId,
      operationId: "operation-mcp-preset-export",
    });
    assert.equal(
      record(exported.receipt).actionId,
      "presentation.preset.export",
    );
    let validation = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });
    const presetResource = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "projectPresentationPreset",
      operation: "list",
      view: "detail",
    });
    const presetItem = record((presetResource.items as unknown[])[0]);
    assert.equal(presetItem.id, "avelune-profile");
    assert.equal(presetItem.scope, "dialogue");
    assert.deepEqual(presetItem.replacedSections, [
      "dialogue",
      "layouts.dialogue",
    ]);

    const deletePreview = await toolData(fixture.client, "pokemap_plan", {
      projectHandle,
      request: {
        requestId: "mcp-preset-delete-preview",
        actionId: "presentation.preset.delete_plan",
        actionVersion: 1,
        workspaceHandle,
        parameters: { presetId: "avelune-profile" },
        expectedRevision: validation.snapshotRevision,
        idempotencyKey: "idem-mcp-preset-delete-preview",
        dryRun: true,
      },
    });
    assert.equal(deletePreview.applicable, false);

    const deletePlan = await toolData(fixture.client, "pokemap_plan", {
      projectHandle,
      request: {
        requestId: "mcp-preset-delete",
        actionId: "presentation.preset.delete_apply",
        actionVersion: 1,
        workspaceHandle,
        parameters: { presetId: "avelune-profile" },
        expectedRevision: validation.snapshotRevision,
        idempotencyKey: "idem-mcp-preset-delete",
        dryRun: false,
      },
    });
    const deleteConfirmation = await toolData(
      fixture.client,
      "pokemap_apply",
      {
        operation: "confirm",
        projectHandle,
        planId: deletePlan.planId,
      },
    );
    await toolData(fixture.client, "pokemap_apply", {
      operation: "apply",
      projectHandle,
      planId: deletePlan.planId,
      operationId: "operation-mcp-preset-delete",
      confirmationToken: deleteConfirmation.confirmationToken,
    });
    validation = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });

    const importPreview = await toolData(fixture.client, "pokemap_plan", {
      projectHandle,
      request: {
        requestId: "mcp-preset-import-preview",
        actionId: "presentation.preset.import_plan",
        actionVersion: 1,
        workspaceHandle,
        parameters: { artifactHandle: exportArtifact.uri },
        expectedRevision: validation.snapshotRevision,
        idempotencyKey: "idem-mcp-preset-import-preview",
        dryRun: true,
      },
    });
    assert.equal(importPreview.applicable, false);

    const importPlan = await toolData(fixture.client, "pokemap_plan", {
      projectHandle,
      request: {
        requestId: "mcp-preset-import",
        actionId: "presentation.preset.import_apply",
        actionVersion: 1,
        workspaceHandle,
        parameters: { artifactHandle: exportArtifact.uri },
        expectedRevision: validation.snapshotRevision,
        idempotencyKey: "idem-mcp-preset-import",
        dryRun: false,
      },
    });
    await toolData(fixture.client, "pokemap_apply", {
      operation: "apply",
      projectHandle,
      planId: importPlan.planId,
      operationId: "operation-mcp-preset-import",
    });
    const reimportedResource = await toolData(
      fixture.client,
      "pokemap_query",
      {
        projectHandle,
        resourceKind: "projectPresentationPreset",
        operation: "list",
        view: "detail",
      },
    );
    const reimportedPreset = record(
      (reimportedResource.items as unknown[])[0],
    );
    assert.equal(reimportedPreset.id, "avelune-profile");
    assert.equal(reimportedPreset.scope, "dialogue");
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test("MCP applies and rereads title motion and intro accessibility", async () => {
  const fixture = await mutationFixture();
  try {
    await writePresentationMediaCatalog(fixture.root);
    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const projectHandle = String(opened.projectHandle);
    const workspaceHandle = String(opened.workspaceHandle);
    const validated = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });

    await applyMutation(fixture.client, {
      projectHandle,
      workspaceHandle,
      expectedRevision: String(validated.snapshotRevision),
      actionId: "presentation.update",
      parameters: {
        profile: {
          schemaVersion: 9,
          branding: { layoutVariant: "standard" },
          intro: {
            media: {
              landscape: presentationVideo(
                "presentation/intro-landscape.mp4",
                "presentation/intro-landscape.png",
              ),
            },
            allowReplay: true,
            reducedMotionBehavior: "poster",
          },
          titleMotion: {
            promptLoop: {
              landscape: presentationVideo(
                "presentation/prompt-landscape.mp4",
                "presentation/prompt-landscape.png",
              ),
            },
          },
        },
      },
      sequence: "phase-c-media",
    });

    const queried = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "projectPresentationProfile",
      operation: "list",
      view: "detail",
    });
    const profile = record(record((queried.items as unknown[])[0]).profile);
    assert.equal(record(profile.intro).allowReplay, true);
    assert.equal(record(profile.intro).reducedMotionBehavior, "poster");
    assert.equal(
      record(record(record(profile.intro).media).landscape).videoPath,
      "presentation/intro-landscape.mp4",
    );
    assert.equal(
      record(record(record(profile.titleMotion).promptLoop).landscape)
        .videoPath,
      "presentation/prompt-landscape.mp4",
    );

    const persisted = record(
      JSON.parse(await readFile(join(fixture.root, "project.json"), "utf8")),
    );
    assert.equal(
      record(record(persisted.presentation).intro).allowReplay,
      true,
    );
    assert.equal(
      record(
        record(
          record(record(persisted.presentation).titleMotion).promptLoop,
        ).landscape,
      ).posterPath,
      "presentation/prompt-landscape.png",
    );
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
    await rm(fixture.root, { recursive: true, force: true });
  }
});

function presentationVideo(videoPath: string, posterPath: string): JsonRecord {
  return {
    videoPath,
    posterPath,
    durationMilliseconds: 6000,
    width: 1920,
    height: 1080,
    bitrateKbps: 2500,
    sizeBytes: 4000000,
    videoCodec: "h264",
    audioCodec: "none",
  };
}

async function writePresentationMediaCatalog(root: string): Promise<void> {
  const assets = [
    ["intro-landscape", "presentation/intro-landscape.mp4", "video/mp4"],
    ["intro-landscape-poster", "presentation/intro-landscape.png", "image/png"],
    ["prompt-landscape", "presentation/prompt-landscape.mp4", "video/mp4"],
    ["prompt-landscape-poster", "presentation/prompt-landscape.png", "image/png"],
    ["presentation-license", "presentation/license.txt", "text/plain"],
  ] as const;
  const records: JsonRecord[] = [];
  await mkdir(join(root, "assets/.pokemap-store"), { recursive: true });
  await mkdir(join(root, "presentation"), { recursive: true });
  for (const [id, logicalPath, mediaType] of assets) {
    const bytes = Buffer.from(`presentation-media:${id}`, "utf8");
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
    await writeFile(join(root, logicalPath), bytes);
    await writeFile(
      join(root, `assets/.pokemap-store/${hexDigest}.blob`),
      bytes,
    );
    records.push({
      id,
      logicalPath,
      artifact: {
        digest: `sha256:${hexDigest}`,
        handle: `artifact://sha256/${hexDigest}`,
        mediaType,
        byteLength: bytes.length,
      },
      usages: [],
      tags: [],
    });
  }
  await writeFile(
    join(root, "assets/.pokemap-assets.json"),
    JSON.stringify({ schemaVersion: 1, records }),
  );
}

function responsiveLayout(
  compactSlot: string,
  regularSlot: string,
  expandedSlot: string,
): JsonRecord {
  return {
    compact: layoutVariant("compact", compactSlot),
    regular: layoutVariant("regular", regularSlot),
    expanded: layoutVariant("expanded", expandedSlot),
  };
}

function layoutVariant(breakpoint: string, slot: string): JsonRecord {
  return {
    breakpoint,
    slot,
    width: "comfortable",
    spacing: "normal",
    screenMargin: "compact",
    visibleSecondaryElements: [],
  };
}

test("MCP authors, rereads, and safely deletes an encounter table", async () => {
  const fixture = await mutationFixture();
  try {
    const described = await toolData(fixture.client, "pokemap_describe", {});
    const actionIds = (described.mutationActions as JsonRecord[]).map(
      (action) => String(action.id),
    );
    assert.ok(actionIds.includes("campaign.encounter_table.upsert"));
    assert.ok(actionIds.includes("campaign.encounter_table.delete"));

    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const projectHandle = String(opened.projectHandle);
    const workspaceHandle = String(opened.workspaceHandle);
    const validation = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });
    const afterUpsertRevision = await applyMutation(fixture.client, {
      projectHandle,
      workspaceHandle,
      expectedRevision: String(validation.snapshotRevision),
      actionId: "campaign.encounter_table.upsert",
      parameters: {
        value: {
          id: "route_one_grass",
          name: "Route 1 — Hautes herbes",
          encounterKind: "walk",
          chancePerStep: 0.14,
          conditions: [],
          entries: [
            {
              speciesId: "rattata",
              minLevel: 2,
              maxLevel: 4,
              weight: 3,
              pokemonOverrides: {
                natureId: "jolly",
                shinyPolicy: "never",
                knownMoveIds: [],
              },
            },
            {
              speciesId: "pidgey",
              minLevel: 3,
              maxLevel: 5,
              weight: 1,
            },
          ],
          tags: ["route", "early-game"],
        },
      },
      sequence: "encounter-upsert",
    });
    const queried = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "project",
      operation: "get",
      view: "detail",
      ids: ["project"],
    });
    const project = record((queried.items as unknown[])[0]);
    const table = (project.encounterTables as JsonRecord[]).find(
      (entry) => entry.id === "route_one_grass",
    );
    assert.ok(table);
    assert.equal(table.encounterKind, "walk");
    assert.equal((table.entries as unknown[]).length, 2);
    assert.deepEqual(record((table.entries as JsonRecord[])[0]).pokemonOverrides, {
      natureId: "jolly",
      abilityId: null,
      gender: null,
      ivs: null,
      shinyPolicy: "never",
      knownMoveIds: [],
    });
    assert.deepEqual(table.tags, ["route", "early-game"]);

    const plannedDelete = await toolData(fixture.client, "pokemap_plan", {
      projectHandle,
      request: {
        requestId: "mcp-encounter-delete",
        actionId: "campaign.encounter_table.delete",
        actionVersion: 1,
        workspaceHandle,
        parameters: { id: "route_one_grass" },
        expectedRevision: afterUpsertRevision,
        idempotencyKey: "idem-mcp-encounter-delete",
        dryRun: false,
      },
    });
    const rejected = await fixture.client.callTool({
      name: "pokemap_apply",
      arguments: {
        operation: "apply",
        projectHandle,
        planId: plannedDelete.planId,
        operationId: "operation-mcp-encounter-delete-unconfirmed",
      },
    });
    assert.equal(rejected.isError, true);
    assert.equal(
      record(record(rejected.structuredContent).error).domainCode,
      "confirmation.required",
    );
    const confirmation = await toolData(fixture.client, "pokemap_apply", {
      operation: "confirm",
      projectHandle,
      planId: plannedDelete.planId,
    });
    const deleted = await toolData(fixture.client, "pokemap_apply", {
      operation: "apply",
      projectHandle,
      planId: plannedDelete.planId,
      operationId: "operation-mcp-encounter-delete",
      confirmationToken: confirmation.confirmationToken,
    });
    assert.equal(
      record(deleted.receipt).actionId,
      "campaign.encounter_table.delete",
    );
    const persisted = record(
      JSON.parse(await readFile(join(fixture.root, "project.json"), "utf8")),
    );
    assert.equal(
      (persisted.encounterTables as JsonRecord[]).some(
        (entry) => entry.id === "route_one_grass",
      ),
      false,
    );
    await toolData(fixture.client, "pokemap_workspace", {
      operation: "close",
      workspaceHandle,
    });
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

    const mapBeforeRejection = await readFile(
      join(fixture.root, "maps/native_v5.json"),
    );
    const rejected = await fixture.client.callTool({
      name: "pokemap_plan",
      arguments: {
        projectHandle,
        request: {
          requestId: "native-v5-material-rejection",
          actionId: "smart_tile.cell.paint",
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle,
          parameters: {
            mapId: "native_v5",
            layerId: "smart",
            materialId: "water",
            cells: [{ x: 0, y: 0 }],
          },
          expectedRevision: revision,
          idempotencyKey: "idem-native-v5-material-rejection",
          dryRun: false,
        },
      },
    });
    assert.equal(rejected.isError, true);
    const rejection = record(record(rejected.structuredContent).error);
    assert.equal(
      rejection.domainCode,
      "smart_tile.cell.material_not_allowed",
    );
    const afterRejection = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });
    assert.equal(afterRejection.snapshotRevision, revision);
    assert.deepEqual(
      await readFile(join(fixture.root, "maps/native_v5.json")),
      mapBeforeRejection,
    );
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

test("MCP changes, reopens, undoes, and reapplies a Smart Tile layer preset", async () => {
  const fixture = await mutationFixture({ withNativeSmartTileV5: true });
  try {
    const described = await toolData(fixture.client, "pokemap_describe", {});
    const actionIds = (described.mutationActions as JsonRecord[]).map(
      (action) => action.id,
    );
    assert.ok(actionIds.includes("smart_tile.layer.change_preset"));
    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const projectHandle = String(opened.projectHandle);
    const workspaceHandle = String(opened.workspaceHandle);
    let revision = String(
      (
        await toolData(fixture.client, "pokemap_validate", {
          projectHandle,
        })
      ).snapshotRevision,
    );
    async function applyAction(
      actionId: string,
      parameters: JsonRecord,
      sequence: string,
    ): Promise<JsonRecord> {
      const planned = await toolData(fixture.client, "pokemap_plan", {
        projectHandle,
        request: {
          requestId: `preset-change-${sequence}`,
          actionId,
          actionVersion: 1,
          workspaceHandle,
          parameters,
          expectedRevision: revision,
          idempotencyKey: `idem-preset-change-${sequence}`,
          dryRun: false,
        },
      });
      const applied = await toolData(fixture.client, "pokemap_apply", {
        operation: "apply",
        projectHandle,
        planId: planned.planId,
        operationId: `operation-preset-change-${sequence}`,
      });
      revision = String(
        (
          await toolData(fixture.client, "pokemap_validate", {
            projectHandle,
          })
        ).snapshotRevision,
      );
      return applied;
    }

    await applyAction(
      "smart_tile.preset.draft.upsert",
      {
        draft: completeSimpleSmartTileDraft({
          id: "preset-change-source-draft",
          targetPresetId: "preset-change-source",
          usage: "path",
        }),
      },
      "source-draft",
    );
    await applyAction(
      "smart_tile.preset.publish",
      {
        draftId: "preset-change-source-draft",
        layer: {
          mapId: "native_v5",
          layerId: "restyled_path",
          name: "Restyled path",
        },
      },
      "source-publish",
    );
    await applyAction(
      "smart_tile.preset.draft.upsert",
      {
        draft: completeSimpleSmartTileDraft({
          id: "preset-change-target-draft",
          targetPresetId: "preset-change-target",
          usage: "path",
        }),
      },
      "target-draft",
    );
    await applyAction(
      "smart_tile.preset.publish",
      { draftId: "preset-change-target-draft" },
      "target-publish",
    );

    const mapPath = join(fixture.root, "maps/native_v5.json");
    const beforeMap = record(JSON.parse(await readFile(mapPath, "utf8")));
    const beforeLayers = beforeMap.layers as JsonRecord[];
    const beforeLayer = record(
      beforeLayers.find((layer) => layer.id === "restyled_path"),
    );
    const beforeField = record(beforeLayer.field);
    const planned = await toolData(fixture.client, "pokemap_plan", {
      projectHandle,
      request: {
        requestId: "preset-change-apply",
        actionId: "smart_tile.layer.change_preset",
        actionVersion: 1,
        workspaceHandle,
        parameters: {
          mapId: "native_v5",
          layerId: "restyled_path",
          targetPresetId: "preset-change-target",
          materialMappings: {
            "preset-change-source-draft-material":
              "preset-change-target-draft-material",
          },
        },
        expectedRevision: revision,
        idempotencyKey: "idem-preset-change-apply",
        dryRun: false,
      },
    });
    const preview = record(record(planned.plan).preview);
    assert.equal(preview.sourcePresetId, "preset-change-source");
    assert.equal(preview.targetPresetId, "preset-change-target");
    assert.equal(preview.geometryPreserved, true);
    assert.equal(preview.layerIdentityPreserved, true);
    assert.equal(preview.gameplayZonesChanged, false);
    const applied = await toolData(fixture.client, "pokemap_apply", {
      operation: "apply",
      projectHandle,
      planId: planned.planId,
      operationId: "operation-preset-change-apply",
    });
    const receipt = record(applied.receipt);
    const afterMap = record(JSON.parse(await readFile(mapPath, "utf8")));
    const afterLayers = afterMap.layers as JsonRecord[];
    const afterLayer = record(
      afterLayers.find((layer) => layer.id === "restyled_path"),
    );
    assert.deepEqual(
      afterLayers.map((layer) => layer.id),
      beforeLayers.map((layer) => layer.id),
    );
    assert.equal(afterLayer.presetId, "preset-change-target");
    assert.deepEqual(record(afterLayer.field), beforeField);
    assert.deepEqual(afterMap.gameplayZones, beforeMap.gameplayZones);

    await toolData(fixture.client, "pokemap_workspace", {
      operation: "close",
      workspaceHandle,
    });
    const reopened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const reopenedProjectHandle = String(reopened.projectHandle);
    const reopenedWorkspaceHandle = String(reopened.workspaceHandle);
    const queried = await toolData(fixture.client, "pokemap_query", {
      projectHandle: reopenedProjectHandle,
      resourceKind: "smartTileLayer",
      operation: "get",
      view: "detail",
      ids: ["native_v5:restyled_path"],
    });
    assert.equal(
      record((queried.items as unknown[])[0]).presetId,
      "preset-change-target",
    );
    const history = await toolData(fixture.client, "pokemap_history", {
      operation: "list",
      projectHandle: reopenedProjectHandle,
      limit: 10,
    });
    const historyEntry = (history.entries as JsonRecord[]).find(
      (entry) => record(entry.receipt).receiptId === receipt.receiptId,
    );
    assert.ok(historyEntry);
    await toolData(fixture.client, "pokemap_history", {
      operation: "undo",
      projectHandle: reopenedProjectHandle,
      entryId: String(historyEntry.entryId),
      idempotencyKey: "idem-preset-change-undo",
    });
    let persisted = record(JSON.parse(await readFile(mapPath, "utf8")));
    let persistedLayer = record(
      (persisted.layers as JsonRecord[]).find(
        (layer) => layer.id === "restyled_path",
      ),
    );
    assert.equal(persistedLayer.presetId, "preset-change-source");

    const undoValidation = await toolData(fixture.client, "pokemap_validate", {
      projectHandle: reopenedProjectHandle,
    });
    const redoPlan = await toolData(fixture.client, "pokemap_plan", {
      projectHandle: reopenedProjectHandle,
      request: {
        requestId: "preset-change-redo",
        actionId: "smart_tile.layer.change_preset",
        actionVersion: 1,
        workspaceHandle: reopenedWorkspaceHandle,
        parameters: {
          mapId: "native_v5",
          layerId: "restyled_path",
          targetPresetId: "preset-change-target",
          materialMappings: {
            "preset-change-source-draft-material":
              "preset-change-target-draft-material",
          },
        },
        expectedRevision: undoValidation.snapshotRevision,
        idempotencyKey: "idem-preset-change-redo",
        dryRun: false,
      },
    });
    await toolData(fixture.client, "pokemap_apply", {
      operation: "apply",
      projectHandle: reopenedProjectHandle,
      planId: redoPlan.planId,
      operationId: "operation-preset-change-redo",
    });
    persisted = record(JSON.parse(await readFile(mapPath, "utf8")));
    persistedLayer = record(
      (persisted.layers as JsonRecord[]).find(
        (layer) => layer.id === "restyled_path",
      ),
    );
    assert.equal(persistedLayer.presetId, "preset-change-target");
    await toolData(fixture.client, "pokemap_workspace", {
      operation: "close",
      workspaceHandle: reopenedWorkspaceHandle,
    });
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
      "smart_tile.layer.change_preset",
      "smart_tile.layer.create",
      "smart_tile.layer.delete",
      "smart_tile.layer.merge",
      "smart_tile.layer.normalize",
      "smart_tile.layer.reconstruct",
      "smart_tile.layer.set_animation_activation",
      "smart_tile.material.upsert",
      "smart_tile.pattern.delete",
      "smart_tile.pattern.erase",
      "smart_tile.pattern.paint",
      "smart_tile.pattern.upsert",
      "smart_tile.preset.draft.delete",
      "smart_tile.preset.draft.upsert",
      "smart_tile.preset.delete",
      "smart_tile.preset.publish",
      "gameplay_zone.smart_tile.sync",
      "tileset.tiled.import",
      "tileset.tiled.wang_bundle.delete",
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
      "gameplay_zone.smart_tile.sync",
      {
        mapId: "map_hanazuki_village",
        zones: [
          {
            id: "path-tall-grass",
            name: "Path tall grass",
            kind: "encounter",
            area: {
              pos: { x: 0, y: 1 },
              size: { width: 3, height: 1 },
            },
            encounter: { encounterKind: "walk" },
            smartTileProvenance: {
              smartTileLayerId: "path_target",
              smartTilePresetId: "path",
              materialId: "dirt",
              behaviorKey: "encounter.walk",
            },
          },
        ],
      },
      "sync-tall-grass",
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
      "smart_tile.layer.set_animation_activation",
      {
        mapId: "map_hanazuki_village",
        layerId: "path_target",
        activation: "on_enter",
      },
      "animation-activation",
    );
    const triggeredLayers = await toolData(
      fixture.client,
      "pokemap_query",
      {
        projectHandle,
        resourceKind: "smartTileLayer",
        operation: "get",
        view: "detail",
        ids: ["map_hanazuki_village:path_target"],
      },
    );
    const triggeredLayer = (triggeredLayers.items as JsonRecord[]).find(
      (item) => item.id === "map_hanazuki_village:path_target",
    );
    assert.ok(triggeredLayer);
    assert.equal(triggeredLayer.animationActivation, "on_enter");
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
    const queriedActorOcclusionPart = record(
      (queriedMultiCandidate.parts as unknown[])[1],
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
    assert.equal(queriedActorOcclusionPart.channel, "actor_occlusion");

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
    const publishedLibraryPreset = await toolData(
      fixture.client,
      "pokemap_query",
      {
        projectHandle,
        resourceKind: "smartTilePreset",
        operation: "get",
        view: "detail",
        ids: ["mcp-library-preset"],
      },
    );
    const publishedRule = record(
      (record((publishedLibraryPreset.items as JsonRecord[])[0]).rules as
        unknown[])[0],
    );
    const publishedCandidate = record(
      (publishedRule.candidates as unknown[])[0],
    );
    assert.equal(
      record((publishedCandidate.parts as unknown[])[1]).channel,
      "actor_occlusion",
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
    const gameplayZones = map.gameplayZones as JsonRecord[];
    assert.equal(gameplayZones.length, 1);
    const gameplayZone = gameplayZones[0];
    assert.ok(gameplayZone);
    assert.deepEqual(record(gameplayZone.smartTileProvenance), {
      smartTileLayerId: "path_target",
      smartTilePresetId: "path",
      materialId: "dirt",
      behaviorKey: "encounter.walk",
    });
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

test("MCP previews and confirms literal Smart Tile reconstruction", async () => {
  const fixture = await mutationFixture({ withSmartTileReconstruction: true });
  try {
    const described = await toolData(fixture.client, "pokemap_describe", {});
    const actionIds = (described.mutationActions as JsonRecord[]).map(
      (action) => action.id,
    );
    assert.ok(actionIds.includes("smart_tile.layer.reconstruct"));

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
        requestId: "mcp-reconstruct",
        actionId: "smart_tile.layer.reconstruct",
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle,
        parameters: {
          mapId: "reconstruction",
          sourceLayerId: "literal",
          presetId: "edge",
          targetLayerId: "native",
          name: "Native path",
        },
        expectedRevision: validation.snapshotRevision,
        idempotencyKey: "idem-mcp-reconstruct",
        dryRun: false,
      },
    });
    const preview = record(record(planned.plan).preview);
    assert.equal(preview.coverage, 1);
    assert.equal(preview.exactVisualMatchCount, 1);
    assert.equal(preview.sourcePreserved, true);
    assert.equal(preview.confirmationRequired, true);
    assert.match(String(preview.assessmentChecksum), /^sha256:/);

    const rejected = await fixture.client.callTool({
      name: "pokemap_apply",
      arguments: {
        operation: "apply",
        projectHandle,
        planId: planned.planId,
        operationId: "operation-mcp-reconstruct-without-confirmation",
      },
    });
    assert.equal(rejected.isError, true);

    const confirmation = await toolData(fixture.client, "pokemap_apply", {
      operation: "confirm",
      projectHandle,
      planId: planned.planId,
    });
    const applied = await toolData(fixture.client, "pokemap_apply", {
      operation: "apply",
      projectHandle,
      planId: planned.planId,
      operationId: "operation-mcp-reconstruct",
      confirmationToken: confirmation.confirmationToken,
    });
    assert.equal(
      record(applied.receipt).actionId,
      "smart_tile.layer.reconstruct",
    );

    const map = JSON.parse(
      await readFile(join(fixture.root, "maps/reconstruction.json"), "utf8"),
    ) as JsonRecord;
    const layers = map.layers as JsonRecord[];
    assert.equal(layers.length, 2);
    const sourceLayer = layers[0];
    const targetLayer = layers[1];
    assert.ok(sourceLayer);
    assert.ok(targetLayer);
    assert.equal(sourceLayer.id, "literal");
    assert.equal(sourceLayer.name, "Literal");
    assert.deepEqual(sourceLayer.cells, [1]);
    const sourcePalette = sourceLayer.palette as JsonRecord[];
    assert.equal(sourcePalette.length, 1);
    assert.equal(sourcePalette[0]?.tilesetId, "tiles");
    assert.equal(sourcePalette[0]?.localTileId, 1);
    assert.equal(targetLayer.runtimeType, "smart_tile");
    assert.equal(targetLayer.id, "native");
    assert.equal(targetLayer.isVisible, false);
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
    const sourceBytes = Buffer.from([
      0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00,
    ]);
    await writeFile(sourcePath, sourceBytes);
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
    assert.deepEqual(
      await readFile(join(fixture.root, "images/m02.png")),
      sourceBytes,
    );
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

test("MCP stages an H.264 MP4 as video instead of M4A audio", async () => {
  const fixture = await mutationFixture();
  try {
    const sourcePath = join(fixture.root, "opening.mp4");
    await writeFile(sourcePath, h264Mp4Fixture(640, 360));

    const staged = await toolData(fixture.client, "pokemap_artifact_stage", {
      sourcePath,
      declaredMediaType: "video/mp4",
    });

    assert.equal(staged.mediaType, "video/mp4");
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test("CHS-057 live MCP certifies identity and portrait transports", async () => {
  const fixture = await mutationFixture();
  try {
    const described = await toolData(fixture.client, "pokemap_describe", {});
    const actionIds = new Set(
      (described.mutationActions as JsonRecord[]).map((action) =>
        String(action.id),
      ),
    );
    const identityPortraitActionIds = [
      "characterStudio.character.create",
      "characterStudio.character.update",
      "characterStudio.character.delete",
      "characterStudio.character.deletePlan",
      "characterStudio.character.setDefault",
      "characterStudio.character.portrait.assign",
      "characterStudio.character.portrait.clear",
      "characterStudio.portraitState.create",
      "characterStudio.portraitState.update",
      "characterStudio.portraitState.reorder",
      "characterStudio.portraitState.delete",
      "characterStudio.portraitState.deletePlan",
    ];
    for (const actionId of identityPortraitActionIds) {
      assert.ok(actionIds.has(actionId), actionId);
    }
    const projectDocument = record(
      JSON.parse(await readFile(join(fixture.root, "project.json"), "utf8")),
    );
    const tilesets = Array.isArray(projectDocument.tilesets)
      ? (projectDocument.tilesets as JsonRecord[])
      : [];
    const tilesetId =
      tilesets.length > 0 ? String(record(tilesets[0]).id) : "mcp-characters";
    if (tilesets.length === 0) {
      projectDocument.tilesets = [
        {
          id: tilesetId,
          name: "MCP Characters",
          relativePath: "assets/mcp-characters.png",
        },
      ];
      await writeFile(
        join(fixture.root, "project.json"),
        JSON.stringify(projectDocument),
      );
    }
    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const projectHandle = String(opened.projectHandle);
    const workspaceHandle = String(opened.workspaceHandle);
    const initialRevision = String(
      (
        await toolData(fixture.client, "pokemap_validate", {
          projectHandle,
        })
      ).snapshotRevision,
    );
    let revision = initialRevision;
    let sequence = 0;

    const plan = async (
      actionId: string,
      parameters: JsonRecord,
      options: { dryRun?: boolean; expectedRevision?: string } = {},
    ): Promise<JsonRecord> =>
      toolData(fixture.client, "pokemap_plan", {
        projectHandle,
        request: {
          requestId: `chs057-plan-${sequence}`,
          actionId,
          actionVersion: 1,
          workspaceHandle,
          parameters,
          expectedRevision: options.expectedRevision ?? revision,
          idempotencyKey: `idem-chs057-plan-${sequence++}`,
          dryRun: options.dryRun ?? false,
        },
      });

    const apply = async (
      actionId: string,
      parameters: JsonRecord,
      requiresConfirmation = false,
    ): Promise<void> => {
      const planned = await plan(actionId, parameters);
      const confirmation = requiresConfirmation
        ? await toolData(fixture.client, "pokemap_apply", {
            operation: "confirm",
            projectHandle,
            planId: planned.planId,
          })
        : undefined;
      const applied = await toolData(fixture.client, "pokemap_apply", {
        operation: "apply",
        projectHandle,
        planId: planned.planId,
        operationId: `operation-chs057-${sequence}`,
        ...(confirmation
          ? { confirmationToken: confirmation.confirmationToken }
          : {}),
      });
      assert.equal(record(applied.receipt).actionId, actionId);
      revision = String(
        (
          await toolData(fixture.client, "pokemap_validate", {
            projectHandle,
          })
        ).snapshotRevision,
      );
    };

    await apply("characterStudio.portraitState.create", {
      displayName: "MCP Neutre",
    });
    const revisionAfterFirstMutation = revision;
    for (const failure of [
      {
        actionId: "characterStudio.portraitState.create",
        parameters: { displayName: "MCP Neutre" },
        expectedRevision: revision,
        domainCode: "character_studio.portrait_state.id_conflict",
      },
      {
        actionId: "characterStudio.portraitState.create",
        parameters: { displayName: "MCP Obsolète" },
        expectedRevision: initialRevision,
        domainCode: "plan.stale",
      },
    ]) {
      const rejected = await fixture.client.callTool({
        name: "pokemap_plan",
        arguments: {
          projectHandle,
          request: {
            requestId: `chs057-rejected-${sequence}`,
            actionId: failure.actionId,
            actionVersion: 1,
            workspaceHandle,
            parameters: failure.parameters,
            expectedRevision: failure.expectedRevision,
            idempotencyKey: `idem-chs057-rejected-${sequence++}`,
            dryRun: false,
          },
        },
      });
      assert.equal(rejected.isError, true);
      assert.equal(
        record(record(rejected.structuredContent).error).domainCode,
        failure.domainCode,
      );
      const validated = await toolData(fixture.client, "pokemap_validate", {
        projectHandle,
      });
      assert.equal(validated.snapshotRevision, revisionAfterFirstMutation);
    }
    await apply("characterStudio.portraitState.create", {
      displayName: "MCP Joyeux",
    });
    await apply("characterStudio.portraitState.update", {
      id: "mcp-joyeux",
      displayName: "MCP Heureux",
    });
    await apply("characterStudio.portraitState.reorder", {
      orderedIds: ["mcp-joyeux", "mcp-neutre"],
    });
    await apply("characterStudio.character.create", {
      name: "MCP Hero",
      tilesetId,
      frameWidth: 1,
      frameHeight: 1,
    });
    await apply("characterStudio.character.update", {
      characterId: "mcp-hero",
      name: "MCP Heroïne",
      tags: ["player"],
    });
    await apply("characterStudio.character.setDefault", {
      characterId: "mcp-hero",
    });
    const portraitAssignment = {
      characterId: "mcp-hero",
      portraitStateId: "mcp-neutre",
      assetId: "mcp-hero-neutral",
      fitMode: "cover",
    };
    await apply(
      "characterStudio.character.portrait.assign",
      portraitAssignment,
    );
    await apply("characterStudio.character.portrait.clear", {
      characterId: "mcp-hero",
      portraitStateId: "mcp-neutre",
    });
    await apply(
      "characterStudio.character.portrait.assign",
      portraitAssignment,
    );
    const portraitDeletePlan = await plan(
      "characterStudio.portraitState.deletePlan",
      { id: "mcp-neutre" },
      { dryRun: true },
    );
    assert.equal(record(record(portraitDeletePlan.plan).preview).requiresResolution, true);
    await apply(
      "characterStudio.portraitState.delete",
      {
        id: "mcp-neutre",
        resolution: "replace",
        replacementId: "mcp-joyeux",
      },
      true,
    );
    const characterDeletePlan = await plan(
      "characterStudio.character.deletePlan",
      { characterId: "mcp-hero" },
      { dryRun: true },
    );
    assert.equal(record(record(characterDeletePlan.plan).preview).requiresResolution, true);
    await apply(
      "characterStudio.character.delete",
      { characterId: "mcp-hero", resolution: "clear" },
      true,
    );
    await toolData(fixture.client, "pokemap_workspace", {
      operation: "close",
      workspaceHandle,
    });
    const reopened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const characters = await toolData(fixture.client, "pokemap_query", {
      projectHandle: String(reopened.projectHandle),
      resourceKind: "characterStudioCharacter",
      operation: "list",
      view: "detail",
    });
    assert.deepEqual(characters.items, []);
    const catalog = await toolData(fixture.client, "pokemap_query", {
      projectHandle: String(reopened.projectHandle),
      resourceKind: "characterStudioCatalog",
      operation: "get",
      view: "detail",
      ids: ["catalog"],
    });
    const catalogItem = record((catalog.items as unknown[])[0]);
    assert.deepEqual(
      (catalogItem.portraitStates as JsonRecord[]).map((state) => state.id),
      ["mcp-joyeux"],
    );
    await toolData(fixture.client, "pokemap_workspace", {
      operation: "close",
      workspaceHandle: reopened.workspaceHandle,
    });
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test("CHS-058 live MCP certifies animation frame and asset transports", async () => {
  const fixture = await mutationFixture();
  try {
    const described = await toolData(fixture.client, "pokemap_describe", {});
    const describedActionIds = new Set(
      (described.mutationActions as JsonRecord[]).map((action) =>
        String(action.id),
      ),
    );
    const animationActionIds = [
      "characterStudio.animationDefinition.create",
      "characterStudio.animationDefinition.update",
      "characterStudio.animationDefinition.reorder",
      "characterStudio.animationDefinition.delete",
      "characterStudio.animationDefinition.deletePlan",
      "characterStudio.animationClip.upsert",
      "characterStudio.animationClip.delete",
      "characterStudio.animationFrame.insert",
      "characterStudio.animationFrame.update",
      "characterStudio.animationFrame.reorder",
      "characterStudio.animationFrame.delete",
      "characterStudio.asset.import",
      "characterStudio.asset.replace",
    ];
    for (const actionId of animationActionIds) {
      assert.ok(describedActionIds.has(actionId), actionId);
    }
    const projectDocument = record(
      JSON.parse(await readFile(join(fixture.root, "project.json"), "utf8")),
    );
    const tilesets = Array.isArray(projectDocument.tilesets)
      ? (projectDocument.tilesets as JsonRecord[])
      : [];
    const tilesetId =
      tilesets.length > 0 ? String(record(tilesets[0]).id) : "mcp-characters";
    if (tilesets.length === 0) {
      projectDocument.tilesets = [
        {
          id: tilesetId,
          name: "MCP Characters",
          relativePath: "assets/mcp-characters.png",
        },
      ];
      await writeFile(
        join(fixture.root, "project.json"),
        JSON.stringify(projectDocument),
      );
    }
    const sourcePath = join(fixture.root, "mcp-character-sheet.png");
    const replacementPath = join(
      fixture.root,
      "mcp-character-sheet-replacement.png",
    );
    await writeFile(sourcePath, pngHeader(64, 64));
    await writeFile(replacementPath, pngHeader(32, 32, 7));
    const stagedSource = await toolData(
      fixture.client,
      "pokemap_artifact_stage",
      { sourcePath, declaredMediaType: "image/png" },
    );
    const stagedReplacement = await toolData(
      fixture.client,
      "pokemap_artifact_stage",
      { sourcePath: replacementPath, declaredMediaType: "image/png" },
    );
    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const projectHandle = String(opened.projectHandle);
    const workspaceHandle = String(opened.workspaceHandle);
    let revision = String(
      (
        await toolData(fixture.client, "pokemap_validate", {
          projectHandle,
        })
      ).snapshotRevision,
    );
    let sequence = 0;
    const observedActionIds = new Set<string>();

    const plan = async (
      actionId: string,
      parameters: JsonRecord,
      dryRun = false,
    ): Promise<JsonRecord> =>
      toolData(fixture.client, "pokemap_plan", {
        projectHandle,
        request: {
          requestId: `chs058-plan-${sequence}`,
          actionId,
          actionVersion: 1,
          workspaceHandle,
          parameters,
          expectedRevision: revision,
          idempotencyKey: `idem-chs058-plan-${sequence++}`,
          dryRun,
        },
      });

    const apply = async (
      actionId: string,
      parameters: JsonRecord,
      options: { confirmed?: boolean; counted?: boolean } = {},
    ): Promise<void> => {
      const planned = await plan(actionId, parameters);
      const confirmation = options.confirmed
        ? await toolData(fixture.client, "pokemap_apply", {
            operation: "confirm",
            projectHandle,
            planId: planned.planId,
          })
        : undefined;
      const applied = await toolData(fixture.client, "pokemap_apply", {
        operation: "apply",
        projectHandle,
        planId: planned.planId,
        operationId: `operation-chs058-${sequence}`,
        ...(confirmation
          ? { confirmationToken: confirmation.confirmationToken }
          : {}),
      });
      assert.equal(record(applied.receipt).actionId, actionId);
      if (options.counted ?? true) observedActionIds.add(actionId);
      revision = String(
        (
          await toolData(fixture.client, "pokemap_validate", {
            projectHandle,
          })
        ).snapshotRevision,
      );
    };

    const expectFailure = async (
      actionId: string,
      parameters: JsonRecord,
      domainCode: string,
    ): Promise<void> => {
      const revisionBeforeFailure = revision;
      const rejected = await fixture.client.callTool({
        name: "pokemap_plan",
        arguments: {
          projectHandle,
          request: {
            requestId: `chs058-rejected-${sequence}`,
            actionId,
            actionVersion: 1,
            workspaceHandle,
            parameters,
            expectedRevision: revision,
            idempotencyKey: `idem-chs058-rejected-${sequence++}`,
            dryRun: false,
          },
        },
      });
      assert.equal(rejected.isError, true);
      assert.equal(
        record(record(rejected.structuredContent).error).domainCode,
        domainCode,
      );
      const validated = await toolData(fixture.client, "pokemap_validate", {
        projectHandle,
      });
      assert.equal(validated.snapshotRevision, revisionBeforeFailure);
    };

    await apply(
      "characterStudio.character.create",
      {
        name: "MCP Hero",
        tilesetId,
        frameWidth: 8,
        frameHeight: 8,
      },
      { counted: false },
    );
    await apply("characterStudio.asset.import", {
      artifactHandle: stagedSource.artifactHandle,
      assetId: "mcp-hero-sheet",
      logicalPath: "assets/characters/mcp-hero/sheet.png",
      mediaKind: "spriteSheet",
      binding: {
        kind: "animationClip",
        characterId: "mcp-hero",
        slotKind: "system",
        state: "idle",
        direction: "north",
        frames: [],
        loop: true,
      },
    });
    for (const definition of [
      { displayName: "MCP Saluer", mode: "directional" },
      { displayName: "MCP Cligner", mode: "single" },
      { displayName: "MCP Acclamer", mode: "directional" },
    ]) {
      await apply("characterStudio.animationDefinition.create", definition);
    }
    await apply("characterStudio.animationDefinition.update", {
      id: "mcp-cligner",
      displayName: "MCP Cligner vite",
    });
    await apply("characterStudio.animationDefinition.reorder", {
      orderedIds: ["mcp-cligner", "mcp-acclamer", "mcp-saluer"],
    });
    await expectFailure(
      "characterStudio.animationClip.upsert",
      {
        characterId: "mcp-hero",
        kind: "custom",
        definitionId: "mcp-saluer",
        sourceAssetId: "mcp-hero-sheet",
      },
      "character_studio.animation.direction_required",
    );
    await apply("characterStudio.animationClip.upsert", {
      characterId: "mcp-hero",
      kind: "custom",
      definitionId: "mcp-saluer",
      direction: "south",
      sourceAssetId: "mcp-hero-sheet",
      loop: false,
      frames: [
        {
          source: { x: 0, y: 0, width: 8, height: 8 },
          durationMs: 100,
        },
        {
          source: { x: 8, y: 0, width: 8, height: 8 },
          durationMs: 110,
        },
      ],
    });
    await apply("characterStudio.animationClip.upsert", {
      characterId: "mcp-hero",
      kind: "custom",
      definitionId: "mcp-cligner",
      sourceAssetId: "mcp-hero-sheet",
      frames: [
        {
          source: { x: 0, y: 8, width: 8, height: 8 },
          durationMs: 90,
        },
      ],
    });
    await expectFailure(
      "characterStudio.asset.replace",
      {
        artifactHandle: stagedReplacement.artifactHandle,
        assetId: "mcp-hero-sheet",
        sourceRect: { x: 0, y: 0, width: 33, height: 32 },
      },
      "character_studio.asset.source_rect_out_of_bounds",
    );
    await apply("characterStudio.asset.replace", {
      artifactHandle: stagedReplacement.artifactHandle,
      assetId: "mcp-hero-sheet",
    });
    await apply("characterStudio.animationFrame.insert", {
      characterId: "mcp-hero",
      kind: "custom",
      definitionId: "mcp-saluer",
      direction: "south",
      frameIndex: 1,
      frame: {
        source: { x: 16, y: 0, width: 8, height: 8 },
        durationMs: 120,
      },
    });
    await apply("characterStudio.animationFrame.update", {
      characterId: "mcp-hero",
      kind: "custom",
      definitionId: "mcp-saluer",
      direction: "south",
      frameIndex: 1,
      frame: {
        source: { x: 16, y: 0, width: 8, height: 8 },
        durationMs: 130,
      },
    });
    await apply("characterStudio.animationFrame.reorder", {
      characterId: "mcp-hero",
      kind: "custom",
      definitionId: "mcp-saluer",
      direction: "south",
      fromIndex: 1,
      toIndex: 2,
    });
    await expectFailure(
      "characterStudio.animationFrame.update",
      {
        characterId: "mcp-hero",
        kind: "custom",
        definitionId: "mcp-saluer",
        direction: "south",
        frameIndex: 9,
        frame: {
          source: { x: 0, y: 0, width: 8, height: 8 },
          durationMs: 100,
        },
      },
      "character_studio.animation.frame_index_invalid",
    );
    await apply("characterStudio.animationFrame.delete", {
      characterId: "mcp-hero",
      kind: "custom",
      definitionId: "mcp-saluer",
      direction: "south",
      frameIndex: 0,
    });
    await apply("characterStudio.animationClip.delete", {
      characterId: "mcp-hero",
      kind: "custom",
      definitionId: "mcp-cligner",
    });
    const deletePlan = await plan(
      "characterStudio.animationDefinition.deletePlan",
      { id: "mcp-saluer" },
      true,
    );
    observedActionIds.add("characterStudio.animationDefinition.deletePlan");
    assert.equal(record(record(deletePlan.plan).preview).requiresResolution, true);
    await apply(
      "characterStudio.animationDefinition.delete",
      {
        id: "mcp-saluer",
        resolution: "replace",
        replacementId: "mcp-acclamer",
      },
      { confirmed: true },
    );
    assert.deepEqual(
      [...observedActionIds].sort(),
      [...animationActionIds].sort(),
    );
    await toolData(fixture.client, "pokemap_workspace", {
      operation: "close",
      workspaceHandle,
    });
    const reopened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const characterQuery = await toolData(fixture.client, "pokemap_query", {
      projectHandle: String(reopened.projectHandle),
      resourceKind: "characterStudioCharacter",
      operation: "get",
      view: "detail",
      ids: ["mcp-hero"],
    });
    const character = record((characterQuery.items as unknown[])[0]);
    const systemClip = record((character.animations as JsonRecord[])[0]);
    assert.equal(systemClip.sourceAssetId, "mcp-hero-sheet");
    const customClip = record((character.customAnimations as JsonRecord[])[0]);
    assert.equal(customClip.definitionId, "mcp-acclamer");
    assert.equal(customClip.direction, "south");
    assert.equal((customClip.frames as unknown[]).length, 2);
    const catalogQuery = await toolData(fixture.client, "pokemap_query", {
      projectHandle: String(reopened.projectHandle),
      resourceKind: "characterStudioCatalog",
      operation: "get",
      view: "detail",
      ids: ["catalog"],
    });
    const catalog = record((catalogQuery.items as unknown[])[0]);
    assert.deepEqual(
      (catalog.animationDefinitions as JsonRecord[])
        .filter((definition) => definition.system === false)
        .map((definition) => definition.id),
      ["mcp-acclamer", "mcp-cligner"],
    );
    const serializedProject = await readFile(
      join(fixture.root, "project.json"),
      "utf8",
    );
    const serializedAssets = await readFile(
      join(fixture.root, "assets/.pokemap-assets.json"),
      "utf8",
    );
    assert.equal(serializedProject.includes(fixture.root), false);
    assert.equal(serializedAssets.includes(fixture.root), false);
    await toolData(fixture.client, "pokemap_workspace", {
      operation: "close",
      workspaceHandle: reopened.workspaceHandle,
    });
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test("CHS-059 live MCP publishes all Character Studio transport evidence", async () => {
  const fixture = await mutationFixture();
  try {
    const described = await toolData(fixture.client, "pokemap_describe", {});
    const actions = (
      record(described.fullParity).mutationActions as JsonRecord[]
    ).filter((action) => String(action.actionId).startsWith("characterStudio."));
    assert.equal(actions.length, 25);
    for (const action of actions) {
      assert.deepEqual(action.endToEndVerifiedTransports, [
        "cli",
        "directApi",
        "editor",
        "mcp",
      ]);
      assert.deepEqual(Object.keys(record(action.endToEndEvidence)).sort(), [
        "cli",
        "directApi",
        "editor",
        "mcp",
      ]);
    }
    assert.equal(record(record(described.fullParity).summary).transportCertificationComplete, false);
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test("CHS-053 live MCP certifies the complete Character Studio lifecycle", async () => {
  const fixture = await mutationFixture();
  try {
    const described = await toolData(fixture.client, "pokemap_describe", {});
    const actionIds = new Set(
      (described.mutationActions as JsonRecord[]).map((action) =>
        String(action.id),
      ),
    );
    for (const actionId of [
      "characterStudio.portraitState.create",
      "characterStudio.character.create",
      "characterStudio.character.setDefault",
      "characterStudio.asset.import",
      "characterStudio.character.portrait.assign",
      "characterStudio.animationDefinition.create",
      "characterStudio.animationClip.upsert",
      "characterStudio.animationFrame.insert",
      "cinematic.character_animation.upsert",
    ]) {
      assert.ok(actionIds.has(actionId), actionId);
    }
    const resourceKindIds = new Set(
      (described.resourceKinds as JsonRecord[]).map((resource) =>
        String(resource.id),
      ),
    );
    for (const resourceKindId of [
      "characterStudioCatalog",
      "characterStudioCharacter",
      "characterStudioDependency",
      "characterStudioReadiness",
    ]) {
      assert.ok(resourceKindIds.has(resourceKindId), resourceKindId);
    }
    const templates = await fixture.client.listResourceTemplates();
    assert.ok(
      templates.resourceTemplates.some(
        (template) =>
          template.uriTemplate ===
          "pokemap://project/{projectHandle}/catalog/{resourceKind}",
      ),
    );
    const projectDocument = record(
      JSON.parse(await readFile(join(fixture.root, "project.json"), "utf8")),
    );
    const tilesets = Array.isArray(projectDocument.tilesets)
      ? (projectDocument.tilesets as JsonRecord[])
      : [];
    const tilesetId =
      tilesets.length > 0 ? String(record(tilesets[0]).id) : "mcp-characters";
    if (tilesets.length === 0) {
      projectDocument.tilesets = [
        {
          id: tilesetId,
          name: "MCP Characters",
          relativePath: "assets/mcp-characters.png",
        },
      ];
      await writeFile(
        join(fixture.root, "project.json"),
        JSON.stringify(projectDocument),
      );
    }
    const portraitPath = join(fixture.root, "mcp-character-portrait.png");
    await writeFile(
      portraitPath,
      Buffer.from(
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=",
        "base64",
      ),
    );
    const staged = await toolData(fixture.client, "pokemap_artifact_stage", {
      sourcePath: portraitPath,
      declaredMediaType: "image/png",
    });
    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const projectHandle = String(opened.projectHandle);
    const workspaceHandle = String(opened.workspaceHandle);
    let revision = String(
      (
        await toolData(fixture.client, "pokemap_validate", {
          projectHandle,
        })
      ).snapshotRevision,
    );
    const catalogBeforeDryRun = await toolData(
      fixture.client,
      "pokemap_query",
      {
        projectHandle,
        resourceKind: "characterStudioCatalog",
        operation: "get",
        view: "detail",
        ids: ["catalog"],
      },
    );
    const dryRun = await toolData(fixture.client, "pokemap_plan", {
      projectHandle,
      request: {
        requestId: "character-studio-dry-run",
        actionId: "characterStudio.portraitState.create",
        actionVersion: 1,
        workspaceHandle,
        parameters: { displayName: "MCP Neutre" },
        expectedRevision: revision,
        idempotencyKey: "idem-character-studio-dry-run",
        dryRun: true,
      },
    });
    assert.equal(dryRun.applicable, false);
    assert.equal(record(dryRun.plan).nonApplicableReason, "dry_run");
    const catalogAfterDryRun = await toolData(
      fixture.client,
      "pokemap_query",
      {
        projectHandle,
        resourceKind: "characterStudioCatalog",
        operation: "get",
        view: "detail",
        ids: ["catalog"],
      },
    );
    assert.deepEqual(catalogAfterDryRun.items, catalogBeforeDryRun.items);
    assert.equal(
      String(catalogAfterDryRun.snapshotRevision),
      String(catalogBeforeDryRun.snapshotRevision),
    );
    const actions: Array<{ id: string; parameters: JsonRecord }> = [
      {
        id: "characterStudio.portraitState.create",
        parameters: { displayName: "MCP Neutre" },
      },
      {
        id: "characterStudio.character.create",
        parameters: {
          name: "MCP Hero",
          tilesetId,
          frameWidth: 1,
          frameHeight: 1,
        },
      },
      {
        id: "characterStudio.character.setDefault",
        parameters: { characterId: "mcp-hero" },
      },
      {
        id: "characterStudio.asset.import",
        parameters: {
          artifactHandle: staged.artifactHandle,
          assetId: "mcp-hero-neutral",
          logicalPath: "assets/characters/mcp-hero/neutral.png",
          mediaKind: "portrait",
        },
      },
      {
        id: "characterStudio.character.portrait.assign",
        parameters: {
          characterId: "mcp-hero",
          portraitStateId: "mcp-neutre",
          assetId: "mcp-hero-neutral",
        },
      },
      {
        id: "characterStudio.animationDefinition.create",
        parameters: { displayName: "MCP Saluer", mode: "directional" },
      },
      {
        id: "characterStudio.animationClip.upsert",
        parameters: {
          characterId: "mcp-hero",
          kind: "custom",
          definitionId: "mcp-saluer",
          direction: "south",
          sourceAssetId: "mcp-hero-neutral",
        },
      },
      {
        id: "characterStudio.animationFrame.insert",
        parameters: {
          characterId: "mcp-hero",
          kind: "custom",
          definitionId: "mcp-saluer",
          direction: "south",
          frameIndex: 0,
          frame: {
            source: { x: 0, y: 0, width: 1, height: 1 },
            durationMs: 120,
          },
        },
      },
    ];
    for (const [index, action] of actions.entries()) {
      revision = await applyMutation(fixture.client, {
        projectHandle,
        workspaceHandle,
        expectedRevision: revision,
        actionId: action.id,
        parameters: action.parameters,
        sequence: `character-studio-${index}`,
      });
    }
    await toolData(fixture.client, "pokemap_workspace", {
      operation: "close",
      workspaceHandle,
    });
    const reopened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const queried = await toolData(fixture.client, "pokemap_query", {
      projectHandle: String(reopened.projectHandle),
      resourceKind: "characterStudioCharacter",
      operation: "get",
      view: "detail",
      ids: ["mcp-hero"],
    });
    const character = record((queried.items as unknown[])[0]);
    assert.equal((character.portraits as unknown[]).length, 1);
    assert.equal((character.customAnimations as unknown[]).length, 1);
    assert.equal(
      (record((character.customAnimations as JsonRecord[])[0]).frames as unknown[])
        .length,
      1,
    );
    const readiness = await toolData(fixture.client, "pokemap_query", {
      projectHandle: String(reopened.projectHandle),
      resourceKind: "characterStudioReadiness",
      operation: "get",
      view: "detail",
      ids: ["mcp-hero"],
    });
    assert.equal(record((readiness.items as unknown[])[0]).id, "mcp-hero");
    const resource = await fixture.client.readResource({
      uri:
        `pokemap://project/${encodeURIComponent(String(reopened.projectHandle))}` +
        "/catalog/characterStudioCharacter",
    });
    const resourceContent = resource.contents[0];
    assert.ok(resourceContent && "text" in resourceContent);
    const resourcePage = record(JSON.parse(resourceContent.text));
    assert.equal(
      record((resourcePage.items as unknown[])[0]).id,
      "mcp-hero",
    );
    await toolData(fixture.client, "pokemap_workspace", {
      operation: "close",
      workspaceHandle: reopened.workspaceHandle,
    });
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

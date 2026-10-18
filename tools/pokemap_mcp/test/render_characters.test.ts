import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";
import { deflateSync, inflateSync } from "node:zlib";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";
import { canonicalPokemonConfig } from "./pokemon_fixture.js";

type Rgba = readonly [number, number, number, number];
interface Raster { width: number; height: number; pixels: Buffer }

const ground: Rgba = [24, 48, 72, 255];
const atlasActor: Rgba = [220, 40, 60, 255];
const dedicatedActor: Rgba = [20, 80, 230, 255];
const occluder: Rgba = [230, 190, 30, 255];

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

function sha256(bytes: Uint8Array): string {
  return createHash("sha256").update(bytes).digest("hex");
}

function solidRaster(width: number, height: number, color: Rgba): Raster {
  const raster = { width, height, pixels: Buffer.alloc(width * height * 4) };
  paintRect(raster, 0, 0, width, height, color);
  return raster;
}

function paintRect(raster: Raster, x: number, y: number, width: number, height: number, color: Rgba): void {
  for (let row = y; row < y + height; row += 1) {
    for (let column = x; column < x + width; column += 1) {
      raster.pixels.set(color, (row * raster.width + column) * 4);
    }
  }
}

function pixel(raster: Raster, x: number, y: number): number[] {
  assert.ok(x >= 0 && x < raster.width && y >= 0 && y < raster.height);
  const offset = (y * raster.width + x) * 4;
  return [...raster.pixels.subarray(offset, offset + 4)];
}

function pngChunk(type: string, data: Buffer): Buffer {
  const body = Buffer.concat([Buffer.from(type, "ascii"), data]);
  let crc = 0xffffffff;
  for (const byte of body) {
    crc ^= byte;
    for (let bit = 0; bit < 8; bit += 1) crc = (crc >>> 1) ^ ((crc & 1) ? 0xedb88320 : 0);
  }
  const header = Buffer.alloc(4);
  header.writeUInt32BE(data.length);
  const trailer = Buffer.alloc(4);
  trailer.writeUInt32BE((crc ^ 0xffffffff) >>> 0);
  return Buffer.concat([header, body, trailer]);
}

function encodePng(raster: Raster): Buffer {
  const header = Buffer.alloc(13);
  header.writeUInt32BE(raster.width, 0);
  header.writeUInt32BE(raster.height, 4);
  header[8] = 8;
  header[9] = 6;
  const stride = raster.width * 4;
  const scanlines = Buffer.alloc((stride + 1) * raster.height);
  for (let row = 0; row < raster.height; row += 1) {
    raster.pixels.copy(scanlines, row * (stride + 1) + 1, row * stride, (row + 1) * stride);
  }
  return Buffer.concat([
    Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    pngChunk("IHDR", header), pngChunk("IDAT", deflateSync(scanlines)), pngChunk("IEND", Buffer.alloc(0)),
  ]);
}

function paeth(left: number, up: number, upperLeft: number): number {
  const prediction = left + up - upperLeft;
  const distances = [Math.abs(prediction - left), Math.abs(prediction - up), Math.abs(prediction - upperLeft)];
  return distances[0]! <= distances[1]! && distances[0]! <= distances[2]! ? left
    : distances[1]! <= distances[2]! ? up : upperLeft;
}

function decodePng(bytes: Buffer): Raster {
  assert.deepEqual([...bytes.subarray(0, 8)], [137, 80, 78, 71, 13, 10, 26, 10]);
  const compressed: Buffer[] = [];
  let width = 0;
  let height = 0;
  let channels = 0;
  for (let offset = 8; offset < bytes.length;) {
    const length = bytes.readUInt32BE(offset);
    const type = bytes.toString("ascii", offset + 4, offset + 8);
    const data = bytes.subarray(offset + 8, offset + 8 + length);
    if (type === "IHDR") {
      width = data.readUInt32BE(0);
      height = data.readUInt32BE(4);
      assert.equal(data[8], 8);
      assert.ok(data[9] === 2 || data[9] === 6, `Unsupported PNG color type: ${data[9]}`);
      channels = data[9] === 6 ? 4 : 3;
      assert.equal(data[12], 0);
    } else if (type === "IDAT") compressed.push(data);
    offset += length + 12;
  }
  assert.ok(width > 0 && height > 0 && channels > 0);
  const encoded = inflateSync(Buffer.concat(compressed));
  const stride = width * channels;
  assert.equal(encoded.length, (stride + 1) * height);
  const decoded = Buffer.alloc(stride * height);
  for (let row = 0; row < height; row += 1) {
    const filter = encoded[row * (stride + 1)]!;
    assert.ok(filter >= 0 && filter <= 4);
    for (let column = 0; column < stride; column += 1) {
      const index = row * stride + column;
      const left = column >= channels ? decoded[index - channels]! : 0;
      const up = row > 0 ? decoded[index - stride]! : 0;
      const upperLeft = row > 0 && column >= channels ? decoded[index - stride - channels]! : 0;
      const prediction = filter === 0 ? 0 : filter === 1 ? left : filter === 2 ? up
        : filter === 3 ? Math.floor((left + up) / 2) : paeth(left, up, upperLeft);
      decoded[index] = (encoded[row * (stride + 1) + column + 1]! + prediction) & 255;
    }
  }
  const raster = solidRaster(width, height, [0, 0, 0, 255]);
  for (let index = 0; index < width * height; index += 1) {
    decoded.copy(raster.pixels, index * 4, index * channels, (index + 1) * channels);
  }
  return raster;
}

function artifactDigest(bytes: Buffer): string {
  const name = Buffer.from("artifact-content");
  const nameLength = Buffer.alloc(8);
  const byteLength = Buffer.alloc(8);
  nameLength.writeBigUInt64BE(BigInt(name.length));
  byteLength.writeBigUInt64BE(BigInt(bytes.length));
  return sha256(Buffer.concat([nameLength, name, byteLength, bytes]));
}

async function fixture(root: string): Promise<Map<string, string>> {
  const dedicatedPng = encodePng(solidRaster(16, 16, dedicatedActor));
  const digest = artifactDigest(dedicatedPng);
  const animation = (sourceAssetId?: string): JsonRecord => ({
    state: "idle", direction: "south", ...(sourceAssetId ? { sourceAssetId } : {}),
    frames: [{ source: { x: 0, y: 0, width: sourceAssetId ? 16 : 2, height: sourceAssetId ? 16 : 2 }, durationMs: 150 }],
  });
  const entity = (id: string, characterId: string, x: number): JsonRecord => ({
    id, name: id, kind: "npc", pos: { x, y: 2 }, size: { width: 1, height: 1 }, npc: { characterId, facing: "south" },
  });
  const files = new Map<string, Buffer>([
    ["assets/ground.png", encodePng(solidRaster(8, 8, ground))],
    ["assets/atlas-actor.png", encodePng(solidRaster(16, 16, atlasActor))],
    ["assets/occluder.png", encodePng(solidRaster(8, 16, occluder))],
    [`assets/.pokemap-store/${digest}.blob`, dedicatedPng],
  ]);
  files.set("assets/.pokemap-assets.json", Buffer.from(JSON.stringify({ schemaVersion: 1, records: [{
    id: "dedicated-animation", logicalPath: "characters/dedicated.png",
    artifact: { digest: `sha256:${digest}`, handle: `artifact://sha256/${digest}`, mediaType: "image/png", byteLength: dedicatedPng.length },
    usages: [], tags: ["character-studio:spriteSheet"],
  }] })));
  files.set("project.json", Buffer.from(JSON.stringify({
    name: "L17 synthetic character raster", version: "v8",
    pokemon: { ...canonicalPokemonConfig(), enabled: false },
    settings: { tileWidth: 8, tileHeight: 8, displayScale: 1 },
    maps: [{ id: "synthetic-map", name: "Synthetic map", relativePath: "maps/synthetic.json" }],
    tilesets: [
      { id: "ground", name: "Ground", relativePath: "assets/ground.png" },
      { id: "atlas-actor", name: "Atlas actor", relativePath: "assets/atlas-actor.png" },
      { id: "occluder", name: "Occluder", relativePath: "assets/occluder.png" },
    ],
    elementCategories: [{ id: "synthetic", name: "Synthetic" }],
    elements: [
      { id: "ground-plane", name: "Ground plane", tilesetId: "ground", categoryId: "synthetic",
        frames: [{ source: { x: 0, y: 0, width: 1, height: 1 } }] },
      { id: "screen", name: "Half mask", tilesetId: "occluder", categoryId: "synthetic",
        frames: [{ source: { x: 0, y: 0, width: 1, height: 2 } }],
        collisionProfile: { occlusionMask: { widthPx: 8, heightPx: 16,
          encoding: "packed_bits_v1", dataBase64: Buffer.alloc(16, 0xf0).toString("base64") } } },
    ],
    characters: [
      { id: "atlas-character", name: "Atlas character", tilesetId: "atlas-actor", frameWidth: 2, frameHeight: 2,
        animations: [animation()] },
      { id: "dedicated-character", name: "Dedicated character", tilesetId: "atlas-actor", frameWidth: 2, frameHeight: 2,
        animations: [animation("dedicated-animation")] },
    ],
  })));
  files.set("maps/synthetic.json", Buffer.from(JSON.stringify({
    id: "synthetic-map", name: "Synthetic map", version: "v8", size: { width: 8, height: 5 },
    layers: [
      { id: "ground", name: "Ground", runtimeType: "tile", cells: Array(40).fill(0) },
      { id: "decor", name: "Decor", runtimeType: "tile", cells: Array(40).fill(0) },
    ],
    placedElements: [
      { id: "plane", layerId: "ground", elementId: "ground-plane", pos: { x: 0, y: 0 }, pixelSize: { width: 64, height: 40 },
        applyCollision: false, properties: { pokemapPlacementOrigin: "authored" } },
      { id: "screen", layerId: "decor", elementId: "screen", pos: { x: 2, y: 1 },
        applyCollision: false, properties: { pokemapPlacementOrigin: "authored" } },
    ],
    entities: [entity("atlas-npc", "atlas-character", 2), entity("dedicated-npc", "dedicated-character", 5)],
  })));
  for (const [path, bytes] of files) {
    await mkdir(resolve(root, path, ".."), { recursive: true });
    await writeFile(join(root, path), bytes);
  }
  return new Map([...files].map(([path, bytes]) => [path, sha256(bytes)]));
}

test("L17 MCP stdio renders authored character pixels and existing occlusion through the real Flutter worker", {
  timeout: 360_000,
  skip: process.env.POKEMAP_TEST_REAL_RENDER === "1" ? false : "Set POKEMAP_TEST_REAL_RENDER=1 for the local Flutter raster journey",
}, async (context) => {
  const root = await mkdtemp(join(tmpdir(), "l17-render-characters-mcp-"));
  const args = [resolve(process.env.POKEMAP_TEST_MCP_ENTRY ?? "dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  for (const [variable, option] of [
    ["POKEMAP_TEST_DART", "--dart"], ["POKEMAP_TEST_FLUTTER", "--flutter"],
    ["POKEMAP_TEST_AUTHORING_PACKAGE", "--authoring-package"], ["POKEMAP_TEST_RUNTIME_PACKAGE", "--runtime-package"],
    ["POKEMAP_TEST_REPOSITORY_ROOT", "--repository-root"],
  ]) {
    const value = process.env[variable!];
    if (value) args.push(option!, value);
  }
  const client = new Client({ name: "l17-character-pixels-test", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  async function call(name: string, input: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: input }, { timeout: 150_000 });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify({ name, envelope }));
    return record(envelope[failure ? "error" : "data"]);
  }
  async function render(input: JsonRecord): Promise<{ data: JsonRecord; raster: Raster }> {
    const result = await client.callTool({ name: "pokemap_render", arguments: input }, { timeout: 150_000 });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, true, JSON.stringify(envelope));
    const data = record(envelope.data);
    assert.equal(data.mimeType, "image/png");
    const artifact = record((envelope.artifacts as JsonRecord[])[0]);
    assert.match(String(artifact.uri), /^artifact:\/\/sha256\/[0-9a-f]{64}$/u);
    const fetched = await call("pokemap_artifact", { uri: artifact.uri });
    assert.equal(fetched.mediaType, "image/png");
    const raster = decodePng(Buffer.from(String(fetched.blob), "base64"));
    assert.equal(raster.width, data.width);
    assert.equal(raster.height, data.height);
    return { data, raster };
  }
  try {
    const originalFiles = await fixture(root);
    await client.connect(transport);
    context.diagnostic(JSON.stringify({ stdioServerPid: transport.pid }));
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const request = { projectHandle: opened.projectHandle, mapId: "synthetic-map", cellPixelSize: 8 };
    const full = await render(request);
    assert.deepEqual([full.raster.width, full.raster.height], [64, 40]);
    assert.deepEqual(full.data.layerIds, ["ground", "decor"]);
    assert.deepEqual(full.data.overlays, []);
    assert.deepEqual(full.data.overlayCounts, {});
    assert.match(String(full.data.sourceRevision), /^sha256:[0-9a-f]{64}$/u);
    assert.deepEqual(pixel(full.raster, 14, 10), atlasActor, "authored atlas NPC is visible without the entities overlay");
    assert.deepEqual(pixel(full.raster, 38, 10), dedicatedActor, "dedicated animation asset uses its runtime alias");
    assert.deepEqual(pixel(full.raster, 18, 10), atlasActor, "unmasked decor stays behind the NPC");
    assert.deepEqual(pixel(full.raster, 22, 10), occluder, "existing occlusion pixels stay in front of the NPC");
    const expected = solidRaster(64, 40, ground);
    paintRect(expected, 12, 8, 16, 16, atlasActor);
    paintRect(expected, 36, 8, 16, 16, dedicatedActor);
    paintRect(expected, 20, 8, 4, 16, occluder);
    assert.equal(sha256(full.raster.pixels), sha256(expected.pixels), "full decoded raster matches independently authored expected pixels");
    const renderTool = (await client.listTools()).tools.find(tool => tool.name === "pokemap_render");
    assert.ok(renderTool);
    assert.match(renderTool.description ?? "", /authored NPC sprites/u);
    assert.match(renderTool.description ?? "", /placed-element occlusion/u);
    assert.deepEqual(Object.keys(record(renderTool.inputSchema.properties)).sort(), [
      "cellPixelSize", "layerIds", "mapId", "overlays", "projectHandle", "region",
    ]);
    const cropped = await render({ ...request, region: { x: 1, y: 1, width: 3, height: 2 }, layerIds: ["ground"], overlays: ["entities"] });
    assert.deepEqual([cropped.raster.width, cropped.raster.height], [24, 16]);
    assert.deepEqual(cropped.data.region, { x: 1, y: 1, width: 3, height: 2 });
    assert.equal(cropped.data.sourceRevision, full.data.sourceRevision);
    assert.deepEqual(cropped.data.layerIds, ["ground"]);
    assert.deepEqual(cropped.data.overlays, ["entities"]);
    assert.deepEqual(cropped.data.overlayCounts, { entities: 1 });
    assert.deepEqual(pixel(cropped.raster, 6, 2), atlasActor);
    assert.deepEqual(pixel(cropped.raster, 14, 2), atlasActor, "excluded decor does not occlude characters");
    const overlaid = pixel(cropped.raster, 12, 12);
    assert.ok(overlaid[0]! < 80 && overlaid[1]! > 150 && overlaid[2]! > 150, `entities overlay remains above authored sprites: ${overlaid}`);
    const invalid = await call("pokemap_render", { ...request, region: { x: 7, y: 0, width: 2, height: 1 } }, true);
    assert.equal(invalid.code, "render.request_invalid");
    assert.equal(invalid.domainCode, undefined);
    for (const [path, digest] of originalFiles) assert.equal(sha256(await readFile(join(root, path))), digest, path);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
    context.diagnostic(JSON.stringify({ rasterSha256: sha256(full.raster.pixels), expectedRasterSha256: sha256(expected.pixels), fixtureFiles: Object.fromEntries(originalFiles) }));
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

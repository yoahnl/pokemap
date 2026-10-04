import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { deflateSync } from "node:zlib";

import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";
import { resourceManagementFixture } from "./resource_management_fixture.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

function png(red: number): Buffer {
  function chunk(name: string, bytes: Buffer): Buffer {
    const body = Buffer.concat([Buffer.from(name), bytes]);
    let crc = 0xffffffff;
    for (const value of body) {
      crc ^= value;
      for (let bit = 0; bit < 8; bit++) crc = (crc >>> 1) ^ ((crc & 1) ? 0xedb88320 : 0);
    }
    const size = Buffer.alloc(4);
    size.writeUInt32BE(bytes.length);
    const checksum = Buffer.alloc(4);
    checksum.writeUInt32BE((crc ^ 0xffffffff) >>> 0);
    return Buffer.concat([size, body, checksum]);
  }
  const header = Buffer.alloc(13);
  header.writeUInt32BE(32, 0);
  header.writeUInt32BE(32, 4);
  header[8] = 8;
  header[9] = 6;
  const raster = Buffer.alloc(32 * 129);
  for (let y = 0; y < 32; y++) for (let x = 0; x < 32; x++) {
    const offset = y * 129 + 1 + x * 4;
    raster.set([red, 128, 64, 255], offset);
  }
  return Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    chunk("IHDR", header), chunk("IDAT", deflateSync(raster)), chunk("IEND", Buffer.alloc(0))]);
}

test("resource lifecycle traverses actual stdio server, retained PNGs and recoverable transactions", async () => {
  const root = await mkdtemp(join(tmpdir(), "uwu4-real-stdio-"));
  const path = join(root, "project.json");
  const beforePng = png(0);
  const afterPng = png(255);
  const source = join(root, "candidate.png");
  const fixture = resourceManagementFixture();
  await writeFile(path, JSON.stringify({version: "v8", name: "Ressources réelles", maps: [],
    pokemon: {...fixture.pokemon, enabled: false}, tilesets: [], elements: [],
    elementCategories: [{id: "props", name: "Décors"}]}));
  const transport = new StdioClientTransport({command: process.execPath,
    args: ["dist/src/index.js", "--root", root, "--dart", process.env.POKEMAP_TEST_DART ?? "dart"],
    cwd: process.cwd(), stderr: "pipe"});
  const client = new Client({name: "uwu4-real-stdio", version: "1.0.0"});
  async function data(name: string, args: JsonRecord): Promise<JsonRecord> {
    const result = await client.callTool({name, arguments: args});
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, true, JSON.stringify(envelope));
    return record(envelope.data);
  }
  try {
    await client.connect(transport);
    const described = await data("pokemap_describe", {});
    const actions = new Map((described.mutationActions as JsonRecord[]).map((action) => [action.id, action]));
    const actionIds = ["tileset.source.replace", "tileset.remove", "element.duplicate", "element.delete"];
    for (const id of actionIds) {
      assert.ok(actions.has(id), id);
      const schema = record(record(actions.get(id)!.extensions).inputSchema);
      assert.equal(schema.additionalProperties, false, id);
    }
    assert.equal(actions.get("tileset.source.replace")!.riskLevel, "high");
    const opened = await data("pokemap_workspace", {operation: "open", projectRoot: root});
    const projectHandle = String(opened.projectHandle);
    let next = 0;
    async function mutate(actionId: string, parameters: JsonRecord): Promise<JsonRecord> {
      const validation = await data("pokemap_validate", {projectHandle});
      const before = await readFile(path);
      const id = next++;
      const planned = await data("pokemap_plan", {projectHandle, request: {
        requestId: `lifecycle-${id}`, actionId, actionVersion: 1,
        workspaceHandle: opened.workspaceHandle, parameters,
        expectedRevision: validation.snapshotRevision, idempotencyKey: `lifecycle-${id}`, dryRun: false}});
      assert.deepEqual(await readFile(path), before);
      const confirmation = actions.get(actionId)!.riskLevel === "high"
        ? (await data("pokemap_apply", {operation: "confirm", projectHandle, planId: planned.planId})).confirmationToken : undefined;
      const args = {operation: "apply", projectHandle, planId: planned.planId,
        operationId: `lifecycle-apply-${id}`, ...(confirmation ? {confirmationToken: confirmation} : {})};
      const applied = await data("pokemap_apply", args);
      assert.equal(record(applied.receipt).status, "applied");
      const after = await readFile(path);
      await data("pokemap_apply", args);
      assert.deepEqual(await readFile(path), after);
      return planned;
    }
    async function stage(bytes: Buffer): Promise<string> {
      await writeFile(source, bytes);
      const staged = await data("pokemap_artifact_stage", {sourcePath: source, declaredMediaType: "image/png"});
      return String(staged.artifactHandle);
    }
    for (const tilesetId of ["sheet", "shared-sheet"]) {
      await mutate("tileset.import_image", {tilesetId, name: tilesetId,
        artifactHandle: await stage(beforePng), tileWidth: 32, tileHeight: 32});
    }
    await mutate("element.upsert", {element: {id: "decor", name: "Décor", tilesetId: "sheet",
      categoryId: "props", frames: [{source: {x: 0, y: 0, width: 1, height: 1}}]}});
    await mutate("element.duplicate", {sourceElementId: "decor", newElementId: "copy",
      name: "Décor — copie", categoryId: "props"});
    const stagedHandle = await stage(afterPng);
    await writeFile(source, png(99));
    await mutate("tileset.source.replace", {tilesetId: "sheet", artifactHandle: stagedHandle});
    assert.deepEqual(await readFile(join(root, "assets/studio/sheet.png")), afterPng);
    assert.deepEqual(await readFile(join(root, "assets/studio/shared-sheet.png")), beforePng);
    const current = record(JSON.parse(await readFile(path, "utf8")));
    assert.equal((current.elements as unknown[]).length, 2);
    await mutate("element.delete", {elementId: "copy"});
    await mutate("element.delete", {elementId: "decor"});
    await mutate("tileset.remove", {tilesetId: "sheet", removeSource: true});
    const final = record(JSON.parse(await readFile(path, "utf8")));
    assert.deepEqual(final.elements, []);
    assert.equal(record((final.tilesets as unknown[])[0]).id, "shared-sheet");
    assert.deepEqual(await readFile(join(root, "assets/studio/shared-sheet.png")), beforePng);
    await data("pokemap_workspace", {operation: "close", workspaceHandle: opened.workspaceHandle});
    const reopened = await data("pokemap_workspace", {operation: "open", projectRoot: root});
    const independent = await data("pokemap_query", {projectHandle: reopened.projectHandle,
      resourceKind: "project", operation: "get", ids: ["project"], view: "detail"});
    assert.ok(JSON.stringify(independent).includes("shared-sheet"));
    console.log(JSON.stringify({transport: "real MCP stdio with Dart canonical worker",
      actions: actionIds, retainedCandidate: true, sourceBytesMatched: true,
      sharedBytesPreserved: true, independentReopen: true,
      strictSchemas: actionIds.map((id) => ({id, schema: record(actions.get(id)!.extensions).inputSchema}))}));
  } finally {
    await client.close();
    await rm(root, {recursive: true, force: true});
  }
});

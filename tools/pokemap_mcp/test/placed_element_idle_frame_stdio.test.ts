import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import test from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";
import { canonicalPokemonConfig } from "./pokemon_fixture.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("live MCP preserves a numbered waiting image through canonical animation and cold reopen", { timeout: 120_000 }, async (context) => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-idle-frame-"));
  const png = Buffer.from("iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAASUlEQVR42mNkoAA4LEj4D2MfSFjASI4ZTAwDDEYdMOqAUQeMOmDUAaMOGHAHMCJXqaNRMCBRMNoiGnXAqANGHTDqgFEHjHgHAADb/Qp9KEMvVQAAAABJRU5ErkJggg==", "base64");
  await writeFile(join(root, "native.png"), png);
  await writeFile(join(root, "project.json"), JSON.stringify({
    name: "Idle image MCP", version: "v8", pokemon: canonicalPokemonConfig(),
    settings: { tileWidth: 32, tileHeight: 32 }, maps: [{ id: "map", name: "Map", relativePath: "map.json" }],
    tilesets: [{ id: "tiles", name: "Tiles", relativePath: "native.png" }],
    elementCategories: [{ id: "decor", name: "Décors" }],
    elements: [{ id: "effect", name: "Effect", tilesetId: "tiles", categoryId: "decor", frames: [100,250,150].map(durationMs => ({ source: { x: 0, y: 0, width: 1, height: 1 }, durationMs })) }],
  }));
  await writeFile(join(root, "map.json"), JSON.stringify({
    version: "v8", id: "map", name: "Map", size: { width: 3, height: 3 },
    layers: [{ runtimeType: "tile", id: "decor", name: "Décors", cells: Array(9).fill(0) }],
    placedElements: [{ id: "effect-1", layerId: "decor", elementId: "effect", pos: { x: 1, y: 1 }, properties: { pokemapPlacementOrigin: "authored" } }],
  }));
  const client = new Client({ name: "idle-frame-proof", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--dart", process.env.POKEMAP_TEST_DART ?? "dart", "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe" });
  async function envelope(name: string, args: JsonRecord = {}): Promise<JsonRecord> {
    return record((await client.callTool({ name, arguments: args })).structuredContent);
  }
  async function call(name: string, args: JsonRecord = {}): Promise<JsonRecord> {
    const result = await envelope(name, args);
    assert.equal(result.ok, true, JSON.stringify(result));
    return record(result.data);
  }
  try {
    await client.connect(transport);
    const described = await call("pokemap_describe");
    const action = (described.mutationActions as JsonRecord[]).find(a => a.id === "placed_element.set_animation");
    assert.ok(action);
    context.diagnostic(JSON.stringify({ actualDescribeAnimationAction: action }));
    let opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    let sequence = 0;
    async function plan(animation: JsonRecord): Promise<JsonRecord> {
      const validation = await call("pokemap_validate", { projectHandle: opened.projectHandle });
      const id = `idle-${++sequence}`;
      return envelope("pokemap_plan", { projectHandle: opened.projectHandle, request: {
        requestId: id, actionId: "placed_element.set_animation", actionVersion: 1,
        workspaceHandle: opened.workspaceHandle, expectedRevision: validation.snapshotRevision,
        idempotencyKey: id, parameters: { mapId: "map", instanceId: "effect-1", animation },
      } });
    }
    const animation = { enabled: true, mode: "loop", autoplay: false, speed: 2.5, startOffsetMs: 350, randomStart: false };
    const before = await readFile(join(root, "map.json"));
    for (const invalid of [{ ...animation, startOffsetMs: -1 }, { ...animation, speed: 0 }]) {
      const rejected = await plan(invalid);
      assert.equal(rejected.ok, false);
      assert.deepEqual(await readFile(join(root, "map.json")), before);
    }
    const planned = await plan(animation);
    assert.equal(planned.ok, true, JSON.stringify(planned));
    assert.deepEqual(await readFile(join(root, "map.json")), before);
    await call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle,
      planId: record(planned.data).planId, operationId: "apply-idle" });
    const saved = record(JSON.parse(await readFile(join(root, "map.json"), "utf8")));
    assert.deepEqual(record((saved.placedElements as JsonRecord[])[0]).animation, animation);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
    opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const query = await call("pokemap_query", { projectHandle: opened.projectHandle, resourceKind: "map", operation: "get", ids: ["map"], view: "detail" });
    assert.deepEqual(record((record((query.items as JsonRecord[])[0]).placedElements as JsonRecord[])[0]).animation, animation);
    await call("pokemap_validate", { projectHandle: opened.projectHandle });
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

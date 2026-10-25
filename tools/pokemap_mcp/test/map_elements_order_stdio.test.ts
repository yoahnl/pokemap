import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, mkdir, writeFile } from "node:fs/promises";
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

test("map elements MCP edits only the selected stack and preserves unknown data", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "map-order-mcp-"));
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  let diagnostics = "";
  transport.stderr?.on("data", chunk => { diagnostics += String(chunk); });
  const client = new Client({ name: "map-order-test", version: "1" });
  async function call(name: string, input: JsonRecord = {}, fails = false): Promise<JsonRecord> {
    const body = record((await client.callTool({ name, arguments: input })).structuredContent);
    assert.equal(body.ok, !fails, JSON.stringify(body));
    return record(body[fails ? "error" : "data"]);
  }
  try {
    await mkdir(join(root, "maps"));
    const project = join(root, "project.json");
    await writeFile(project, "undecodable project");
    const mapFile = join(root, "maps", "bourg.json");
    const map = {
      id: "bourg", name: "Bourg", version: "v8", size: { width: 2, height: 2 }, futureField: { preserved: true },
      layers: [
        { id: "front", name: "Front", runtimeType: "tile", cells: [], futureLayer: "keep" },
        { id: "back", name: "Back", runtimeType: "tile", cells: [] },
      ],
      placedElements: [
        { id: "particles", layerId: "front", elementId: "particles", pos: { x: 0, y: 0 }, visualOrder: 0, futureDecor: "keep" },
        { id: "tree", layerId: "front", elementId: "tree", pos: { x: 0, y: 0 }, visualOrder: 1 },
      ],
    };
    await writeFile(mapFile, JSON.stringify(map));
    await client.connect(transport);
    const catalog = await call("pokemap_describe");
    assert.equal(record(catalog.mapElementOrderAuthoring).id, "map.elements.reorder");
    const initial = await call("pokemap_map_elements_inspect", { projectRoot: root, mapId: "bourg" });
    const reordered = await call("pokemap_map_elements_reorder", {
      projectRoot: root, mapId: "bourg", expectedRevision: initial.revision,
      kind: "decor", layerId: "front", frontFirstIds: ["particles", "tree"], operationId: "order-decor",
    });
    const afterDecor = JSON.parse(await readFile(mapFile, "utf8")) as JsonRecord;
    assert.deepEqual(afterDecor.futureField, { preserved: true });
    const decorations = afterDecor.placedElements as JsonRecord[];
    assert.equal(decorations[0]?.visualOrder, 1);
    assert.equal(decorations[0]?.futureDecor, "keep");
    assert.equal(decorations[1]?.visualOrder, 0);
    const layers = await call("pokemap_map_elements_reorder", {
      projectRoot: root, mapId: "bourg", expectedRevision: reordered.afterRevision,
      kind: "layers", frontFirstIds: ["back", "front"], operationId: "order-layers",
    });
    assert.deepEqual((record(layers.afterMap).layers as JsonRecord[]).map(layer => layer.id), ["back", "front"]);
    await call("pokemap_map_elements_reorder", {
      projectRoot: root, mapId: "bourg", expectedRevision: layers.afterRevision,
      kind: "layers", frontFirstIds: ["back", "back"], operationId: "order-invalid",
    }, true);
    const undone = await call("pokemap_map_elements_undo", {
      projectRoot: root, mapId: "bourg", expectedRevision: layers.afterRevision,
      receiptId: record(layers.receipt).receiptId, operationId: "undo-layers",
    });
    assert.deepEqual((record(undone.afterMap).layers as JsonRecord[]).map(layer => layer.id), ["front", "back"]);
    assert.equal(await readFile(project, "utf8"), "undecodable project");
  } catch (error) {
    throw new Error(`${String(error)}; worker diagnostics: ${diagnostics}`, { cause: error });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

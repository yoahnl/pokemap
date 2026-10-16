import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";
import { canonicalPokemonConfig } from "./pokemon_fixture.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("live MCP retains illustrated warp presentation and advertises the closed contract", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "scene-warp-options-mcp-"));
  const file = join(root, "project.json");
  const mapFile = join(root, "maps/centre.json");
  const command = { kind: "warp", destinationMapId: "centre", warpId: "arrival",
    arrivalFacing: "north", transition: "none", presentation: {
      mode: "illustrated", illustrationElementId: "picture", fadeOutMs: 300,
      transferDelayMs: 400, revealMs: 300, illustrationHoldMs: 1000, illustrationFadeMs: 1500 } };
  const original = { name: "Warp MCP", version: "v8", pokemon: canonicalPokemonConfig(),
    maps: [{ id: "centre", name: "Centre", relativePath: "maps/centre.json" }], tilesets: [{ id: "picture-sheet", name: "Picture",
      relativePath: "tilesets/picture.png", source: { kind: "regular_atlas", assetId: "picture-sheet",
        pixelWidth: 1, pixelHeight: 1, tileWidth: 1, tileHeight: 1, tileProperties: [] } }],
    elementCategories: [{id: "pictures", name: "Pictures"}],
    elements: [{ id: "picture", name: "Picture", tilesetId: "picture-sheet", categoryId: "pictures",
      frames: [{ source: { x: 0, y: 0, width: 1, height: 1 } }] }],
    scenes: [{ id: "scene", name: "Entrer", graph: { startNodeId: "start", nodes: [
      { id: "start", kind: "start" },
      { id: "warp", kind: "action", title: "Entrée", payload: {
        actionKind: "authored-transfer", parameters: { annotation: "keep" },
        interactiveCommand: { kind: "warp", destinationMapId: "centre", warpId: "arrival" } } },
      { id: "end", kind: "end" },
    ], edges: [
      { id: "enter", fromNodeId: "start", fromPortId: "completed", toNodeId: "warp", kind: "default" },
      ...["completed", "blocked"].map((port) => ({ id: port, fromNodeId: "warp", fromPortId: port,
        toNodeId: "end", kind: "actionCompleted" })),
    ] } }],
  };
  await mkdir(join(root, "maps"));
  await writeFile(mapFile, JSON.stringify({ version: "v8", id: "centre", name: "Centre",
    size: { width: 8, height: 8 }, layers: [], warps: [{ id: "arrival", pos: { x: 2, y: 3 },
      targetMapId: "centre", targetPos: { x: 2, y: 3 }, triggerMode: "on_bump" }] }));
  await writeFile(file, JSON.stringify(original));
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const client = new Client({ name: "warp-options-proof", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args,
    cwd: process.cwd(), stderr: "pipe" });
  async function call(name: string, input: JsonRecord, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: input });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify(envelope));
    return record(envelope[failure ? "error" : "data"]);
  }
  let workspace: JsonRecord | undefined;
  try {
    await client.connect(transport);
    const description = await call("pokemap_describe", {});
    const action = (description.mutationActions as JsonRecord[])
      .find((entry) => entry.id === "scene.interactive_command.set");
    assert.ok(action);
    const warp = record(record(action.extensions).warp);
    assert.deepEqual(warp.transitionValues, ["mapDefault", "none"]);
    assert.deepEqual(warp.arrivalFacingValues, ["north", "south", "east", "west"]);
    assert.equal(warp.absentArrivalFacing, "preserveCurrentDirection");
    assert.ok((warp.parameters as string[]).includes("presentation"));
    const presentation = record(warp.presentation);
    assert.deepEqual(presentation.modes, ["fade", "illustrated", "caveEntrance", "caveExit"]);
    assert.equal(presentation.projectDimension, "twoD");
    assert.deepEqual(presentation.durationMsRange, [0, 10000]);
    if (process.env.POKEMAP_WARP_CATALOG_RECEIPT) {
      await writeFile(process.env.POKEMAP_WARP_CATALOG_RECEIPT,
        JSON.stringify({ liveCatalog: true, actionId: action.id, warp }, null, 2));
    }
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    let sequence = 0;
    async function plan(value: JsonRecord, failure = false): Promise<JsonRecord> {
      assert.ok(workspace);
      const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
      const before = await readFile(file);
      const beforeMap = await readFile(mapFile);
      const id = `warp-${++sequence}`;
      const result = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
        requestId: id, actionId: "scene.interactive_command.set", actionVersion: 1,
        workspaceHandle: workspace.workspaceHandle, expectedRevision: validation.snapshotRevision,
        idempotencyKey: id, parameters: { sceneId: "scene", nodeId: "warp", command: value },
      } }, failure);
      assert.deepEqual(await readFile(file), before);
      assert.deepEqual(await readFile(mapFile), beforeMap);
      return result;
    }
    const planned = await plan(command);
    await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle,
      planId: planned.planId, operationId: "apply-warp" });
    const stable = await readFile(file);
    const saved = record(JSON.parse(stable.toString("utf8")));
    const scene = record((saved.scenes as JsonRecord[])[0]);
    const node = (record(scene.graph).nodes as JsonRecord[]).find((entry) => entry.id === "warp")!;
    const payload = record(node.payload);
    assert.deepEqual(payload.interactiveCommand, command);
    assert.equal(payload.actionKind, "authored-transfer");
    assert.deepEqual(payload.parameters, { annotation: "keep" });
    for (const key of ["arrivalFacing", "transition", "warpId", "destinationMapId"]) {
      await plan({ ...command, [key]: "missing" }, true);
    }
    await plan({ ...command, presentation: { ...command.presentation, illustrationElementId: "missing" } }, true);
    await plan({ ...command, presentation: { ...command.presentation, extra: true } }, true);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const queried = await call("pokemap_query", { projectHandle: workspace.projectHandle,
      resourceKind: "scene", operation: "get", ids: ["scene"], view: "detail" });
    assert.ok(JSON.stringify(queried).includes('"arrivalFacing":"north"'));
    assert.deepEqual(await readFile(file), stable);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = undefined;
  } finally {
    if (workspace) {
      await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    }
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

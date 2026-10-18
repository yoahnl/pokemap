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

test("live MCP discovers and edits typed conditional entity presentations", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "entity-presentation-mcp-"));
  await mkdir(join(root, "maps"));
  const mapFile = join(root, "maps/map.json");
  const projectFile = join(root, "project.json");
  await writeFile(projectFile, JSON.stringify({ name: "Presentation MCP", version: "v8",
    pokemon: canonicalPokemonConfig(), tilesets: [],
    maps: [{ id: "map", name: "Map", relativePath: "maps/map.json" }] }));
  await writeFile(mapFile, JSON.stringify({ id: "map", name: "Map", version: "v8",
    size: { width: 8, height: 6 }, layers: [], entities: [
      { id: "owner", kind: "custom", pos: { x: 2, y: 1 } },
    ] }));
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const client = new Client({ name: "entity-presentation-test", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  let workspace: JsonRecord | undefined;
  let sequence = 0;
  async function call(name: string, input: JsonRecord, failed = false): Promise<JsonRecord> {
    const response = record((await client.callTool({ name, arguments: input })).structuredContent);
    assert.equal(response.ok, !failed, JSON.stringify(response));
    return record(response[failed ? "error" : "data"]);
  }
  const presentation = { schemaVersion: 1, variants: [{ id: "first", condition: { kind: "all", children: [] },
    characterId: null, facing: "south", interactionMode: "overlap", blocksMovement: false,
    size: { width: 2, height: 2 }, counterInteractionSides: ["south"] }] };
  try {
    await client.connect(transport);
    const description = await call("pokemap_describe", {});
    const action = (description.mutationActions as JsonRecord[]).find(value => value.id === "entity.set_presentation");
    assert.ok(action);
    assert.deepEqual(record(record(action.extensions).presentation).conditionExpressionKinds, ["leaf", "all", "any", "not"]);
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const projectBefore = await readFile(projectFile);
    for (const payload of [presentation, null]) {
      const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
      const id = `presentation-${++sequence}`;
      const before = await readFile(mapFile);
      const plan = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
        requestId: id, actionId: "entity.set_presentation", actionVersion: 1,
        workspaceHandle: workspace.workspaceHandle, expectedRevision: validation.snapshotRevision,
        idempotencyKey: id, parameters: { mapId: "map", entityId: "owner", presentation: payload },
      } });
      assert.deepEqual(await readFile(mapFile), before);
      await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle,
        planId: plan.planId, operationId: `apply-${id}` });
      const saved = record((record(JSON.parse(await readFile(mapFile, "utf8"))).entities as unknown[])[0]);
      assert.deepEqual(saved.presentation ?? null, payload);
      assert.deepEqual(saved.pos, { x: 2, y: 1 });
      assert.deepEqual(await readFile(projectFile), projectBefore);
    }
    const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    const failure = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
      requestId: "invalid", actionId: "entity.set_presentation", actionVersion: 1,
      workspaceHandle: workspace.workspaceHandle, expectedRevision: validation.snapshotRevision,
      idempotencyKey: "invalid", parameters: { mapId: "map", entityId: "owner",
        presentation: { ...presentation, schemaVersion: 99 } },
    } }, true);
    assert.notEqual(failure.domainCode, "worker.internal");
  } finally {
    if (workspace) await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

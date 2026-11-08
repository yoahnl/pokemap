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

function placed(id: string, elementId: string, x: number, y: number): JsonRecord {
  return { id, layerId: "decor", elementId, pos: { x, y } };
}

function map(id: string, placedElements: JsonRecord[]): JsonRecord {
  return { version: "v8", id, name: id.toUpperCase(), size: { width: 6, height: 6 },
    layers: [{ runtimeType: "tile", id: "decor", name: "Decor", cells: new Array(36).fill(0) }], placedElements };
}

function element(id: string, width = 1): JsonRecord {
  return { id, name: id, tilesetId: "ts", categoryId: "cat", frames: [{ source: { x: 0, y: 0, width, height: 1 } }] };
}

test("live MCP reviews, confirms, applies and undoes the replacement of every décor usage", { timeout: 180_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "replace-usages-mcp-"));
  const paths = ["project.json", "maps/alpha.json", "maps/beta.json", "maps/gamma.json"];
  await mkdir(join(root, "maps"));
  await writeFile(join(root, "project.json"), JSON.stringify({ name: "Usages MCP", version: "v8",
    pokemon: { ...canonicalPokemonConfig(), enabled: false },
    tilesets: [{ id: "ts", name: "TS", relativePath: "assets/ts.png" }],
    elementCategories: [{ id: "cat", name: "Cat" }],
    elements: [element("rock"), element("bush"), element("stone"), element("wide", 3)],
    maps: ["alpha", "beta", "gamma"].map((id) => ({ id, name: id.toUpperCase(), relativePath: `maps/${id}.json` })) }));
  await writeFile(join(root, "maps/alpha.json"), JSON.stringify(map("alpha", [placed("r1", "rock", 1, 1), placed("r2", "rock", 2, 3)])));
  await writeFile(join(root, "maps/beta.json"), JSON.stringify(map("beta", [placed("r3", "rock", 5, 0), placed("s1", "stone", 0, 0)])));
  await writeFile(join(root, "maps/gamma.json"), JSON.stringify(map("gamma", [placed("s2", "stone", 1, 1)])));
  const snapshot = async () => Promise.all(paths.map((path) => readFile(join(root, path))));
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const client = new Client({ name: "replace-usages-proof", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  async function call(name: string, input: JsonRecord, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: input });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify(envelope));
    return record(envelope[failure ? "error" : "data"]);
  }
  try {
    await client.connect(transport);
    const description = await call("pokemap_describe", {});
    const action = (description.mutationActions as JsonRecord[]).find((entry) => entry.id === "resource.usages.replace");
    assert.ok(action);
    assert.equal(action.riskLevel, "high");
    const schema = record(record(action.extensions).inputSchema);
    assert.equal(schema.additionalProperties, false);
    assert.deepEqual(record(record(schema.properties).family).enum, ["decors", "models3d"]);
    const workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    let sequence = 0;
    async function plan(parameters: JsonRecord, failure = false): Promise<JsonRecord> {
      const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
      const before = await snapshot();
      const id = `usages-${++sequence}`;
      const result = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
        requestId: id, actionId: "resource.usages.replace", actionVersion: 1,
        workspaceHandle: workspace.workspaceHandle, expectedRevision: validation.snapshotRevision,
        idempotencyKey: id, parameters: { family: "decors", resourceId: "rock", ...parameters },
      } }, failure);
      assert.deepEqual(await snapshot(), before);
      return result;
    }
    const original = await snapshot();
    const incompatible = await plan({ replacementId: "wide" }, true);
    assert.equal(incompatible.domainCode, "resource.usages.replacement_incompatible");
    assert.equal(record(incompatible.details).reason, "outOfBounds");
    assert.equal((await plan({ replacementId: "ghost" }, true)).domainCode, "resource.usages.replacement_unknown");
    assert.equal((await plan({ replacementId: "bush", extra: true }, true)).domainCode, "visual.parameters_unknown");
    const planned = await plan({ replacementId: "bush" });
    const preview = record(record(planned.plan).preview);
    assert.equal(preview.mapCount, 2);
    assert.equal(preview.occurrenceCount, 3);
    assert.deepEqual((preview.maps as JsonRecord[]).map((entry) => [entry.mapId, entry.instanceIds]),
      [["alpha", ["r1", "r2"]], ["beta", ["r3"]]]);
    await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle,
      planId: planned.planId, operationId: "replace-unconfirmed" }, true);
    assert.deepEqual(await snapshot(), original);
    const confirmation = await call("pokemap_apply", { operation: "confirm", projectHandle: workspace.projectHandle,
      planId: planned.planId });
    const applied = await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle,
      planId: planned.planId, operationId: "replace-usages", confirmationToken: confirmation.confirmationToken });
    const receipt = record(applied.receipt);
    assert.equal(receipt.status, "applied");
    const after = await snapshot();
    assert.deepEqual(after[0], original[0]);
    assert.deepEqual(after[3], original[3]);
    const alpha = record(JSON.parse(after[1]!.toString("utf8")));
    const beta = record(JSON.parse(after[2]!.toString("utf8")));
    assert.deepEqual((alpha.placedElements as JsonRecord[]).map((entry) => entry.elementId), ["bush", "bush"]);
    assert.deepEqual((beta.placedElements as JsonRecord[]).map((entry) => [entry.id, entry.elementId]),
      [["r3", "bush"], ["s1", "stone"]]);
    await call("pokemap_history", { operation: "undo", projectHandle: workspace.projectHandle,
      entryId: receipt.receiptId, idempotencyKey: "undo-replace-usages" });
    assert.deepEqual(await snapshot(), original);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

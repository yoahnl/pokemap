import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("live MCP preserves the five guided condition families and refuses invalid sources", { timeout: 120_000 }, async () => {
  const fixture = record(JSON.parse(await readFile(resolve(
    "../../packages/map_authoring/test/fixtures/scene_condition_forms.json",
  ), "utf8")));
  const root = await mkdtemp(join(tmpdir(), "condition-forms-mcp-"));
  const file = join(root, "project.json");
  await writeFile(file, JSON.stringify(fixture.project));
  await mkdir(join(root, "maps"));
  const mapFile = join(root, "maps/hall.json");
  await writeFile(mapFile, JSON.stringify(fixture.map));
  const mapBefore = await readFile(mapFile);
  await mkdir(join(root, "data/pokemon/catalogs"), { recursive: true });
  await writeFile(join(root, "data/pokemon/catalogs/items.json"), JSON.stringify(fixture.itemCatalog));
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const client = new Client({ name: "condition-forms-proof", version: "1.0.0" });
  const transport = new StdioClientTransport({
    command: process.execPath, args, cwd: process.cwd(), stderr: "pipe",
  });
  async function call(name: string, input: JsonRecord, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: input });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify(envelope));
    return record(envelope[failure ? "error" : "data"]);
  }
  try {
    await client.connect(transport);
    const description = await call("pokemap_describe", {});
    assert.ok((description.mutationActions as JsonRecord[])
      .some(action => action.id === "scene.condition.set"));
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    let sequence = 0;
    async function plan(source: JsonRecord, failure = false): Promise<JsonRecord> {
      const validation = await call("pokemap_validate", { projectHandle: opened.projectHandle });
      const id = `condition-${++sequence}`;
      const before = await readFile(file);
      const planned = await call("pokemap_plan", {
        projectHandle: opened.projectHandle,
        request: {
          requestId: id, actionId: "scene.condition.set", actionVersion: 1,
          workspaceHandle: opened.workspaceHandle,
          expectedRevision: validation.snapshotRevision, idempotencyKey: id,
          parameters: { sceneId: "condition_scene", nodeId: "check", conditionSource: source },
        },
      }, failure);
      assert.deepEqual(await readFile(file), before);
      return planned;
    }
    for (const source of fixture.sources as JsonRecord[]) {
      const prepared = await plan(source);
      const result = await call("pokemap_apply", {
        operation: "apply", projectHandle: opened.projectHandle,
        planId: prepared.planId, operationId: `apply-condition-${sequence}`,
      });
      assert.equal(record(result.receipt).actionId, "scene.condition.set");
      assert.equal(record(result.receipt).status, "applied");
      const saved = record(JSON.parse(await readFile(file, "utf8")));
      const scene = record((saved.scenes as JsonRecord[])[0]);
      const condition = (record(scene.graph).nodes as JsonRecord[])
        .find(node => node.id === "check");
      assert.ok(condition);
      assert.deepEqual(record(condition.payload).conditionSource, source);
      assert.deepEqual(scene.metadata, { preserved: "yes" });
      assert.deepEqual(scene.layout, record((record(fixture.project).scenes as JsonRecord[])[0]).layout);
      assert.equal((record(scene.graph).edges as JsonRecord[]).length, 3);
      assert.deepEqual(await readFile(mapFile), mapBefore);
    }
    for (const source of fixture.invalidSources as JsonRecord[]) {
      const before = await readFile(file);
      const error = await plan(source, true);
      assert.ok(error.domainCode);
      assert.deepEqual(await readFile(file), before);
      assert.deepEqual(await readFile(mapFile), mapBefore);
    }
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
    const reopened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const queried = await call("pokemap_query", {
      projectHandle: reopened.projectHandle, resourceKind: "scene", operation: "get",
      ids: ["condition_scene"], view: "detail",
    });
    assert.equal((queried.items as unknown[]).length, 1);
    const cold = record(JSON.parse(await readFile(file, "utf8")));
    const node = (record(record((cold.scenes as JsonRecord[])[0]).graph).nodes as JsonRecord[])
      .find(value => value.id === "check");
    assert.deepEqual(record(record(node).payload).conditionSource, (fixture.sources as JsonRecord[]).at(-1));
    await call("pokemap_workspace", { operation: "close", workspaceHandle: reopened.workspaceHandle });
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

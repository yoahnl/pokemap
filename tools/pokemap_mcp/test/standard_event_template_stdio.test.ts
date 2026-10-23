import assert from "node:assert/strict";
import { createHash } from "node:crypto";
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

test("packaged MCP applies and reopens coordinated standard event pages", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-standard-template-"));
  await mkdir(join(root, "maps"));
  await mkdir(join(root, "dialogues"));
  const mapPath = join(root, "maps/room.json");
  const manifestPath = join(root, "project.json");
  await writeFile(mapPath, JSON.stringify({ id: "room", name: "Room", version: "v8",
    size: { width: 4, height: 4 }, layers: [], entities: [
      { id: "guide", name: "Guide", kind: "custom", pos: { x: 1, y: 1 } },
      { id: "second", name: "Second", kind: "custom", pos: { x: 2, y: 1 } },
    ] }));
  for (const id of ["hello", "after"]) {
    await writeFile(join(root, `dialogues/${id}.yarn`), "title: Start\n---\nHello.\n===\n");
  }
  await writeFile(join(root, "people.png"), Buffer.from(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+j4WQAAAAASUVORK5CYII=", "base64"));
  await writeFile(manifestPath, JSON.stringify({ name: "Synthetic standard events", version: "v8",
    pokemon: canonicalPokemonConfig(), maps: [{ id: "room", name: "Room", relativePath: "maps/room.json" }],
    tilesets: [{ id: "people", name: "People", relativePath: "people.png" }],
    characters: [{ id: "person", name: "Person", tilesetId: "people" }],
    facts: [{ id: "met", label: "Met", defaultValue: false }],
    dialogues: ["hello", "after"].map((id) => ({ id, name: id, relativePath: `dialogues/${id}.yarn` })),
    eventRegistry: { schemaVersion: 1, mode: "v2Only", records: [], legacyClaims: [] },
  }));
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "standard-template-test", version: "1.0.0" });
  let workspace: JsonRecord;
  let sequence = 0;
  async function call(name: string, parameters: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: parameters });
    assert.equal(result.isError, failure ? true : undefined, JSON.stringify(result.structuredContent));
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, !failure);
    return record(failure ? envelope.error : envelope.data);
  }
  async function plan(entityId: string, dialogueId = "hello", failure = false): Promise<JsonRecord> {
    const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    const mapBefore = await readFile(mapPath);
    const projectBefore = await readFile(manifestPath);
    const requestId = `standard-template-${++sequence}`;
    const result = await call("pokemap_plan", { projectHandle: workspace.projectHandle, request: {
      requestId, actionId: "event_v2.template.apply", actionVersion: 1,
      workspaceHandle: workspace.workspaceHandle, expectedRevision: validation.snapshotRevision, idempotencyKey: requestId,
      parameters: { mapRevision: `sha256:${createHash("sha256").update(mapBefore).digest("hex")}`,
        spec: { schemaVersion: 1, kind: "conditionalNpc", mapId: "room", entityId, name: "Guide",
          parameters: { factId: "met", dialogueId, alternateDialogueId: "after", characterId: "person" } } },
    } }, failure);
    assert.deepEqual(await readFile(mapPath), mapBefore);
    assert.deepEqual(await readFile(manifestPath), projectBefore);
    return result;
  }
  try {
    await client.connect(transport);
    const description = await call("pokemap_describe");
    const descriptor = (description.mutationActions as JsonRecord[]).find((action) => action.id === "event_v2.template.apply");
    assert.ok(descriptor);
    assert.match(JSON.stringify(descriptor), /versionedRecipeAndExactRecompileBeforeOverwrite/);
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const invalid = await plan("guide", "missing", true);
    assert.equal(invalid.domainCode, "event_v2.template.reference_unavailable");
    for (const entity of ["guide", "second"]) {
      const planned = await plan(entity);
      const preview = record(record(planned.plan).preview);
      assert.equal((preview.pages as unknown[]).length, 2);
      const applied = await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle,
        planId: planned.planId, operationId: `apply-${sequence}` });
      assert.equal(record(applied.receipt).status, "applied");
    }
    const saved = record(JSON.parse(await readFile(manifestPath, "utf8")));
    const events = record(saved.eventRegistry).records as JsonRecord[];
    assert.equal(events.length, 4);
    assert.equal(new Set(events.map((event) => record(event.definition).id)).size, 4);
    assert.equal((saved.scenes as unknown[]).length, 4);
    assert.equal((saved.dialogues as unknown[]).length, 2);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const queried = await call("pokemap_query", { projectHandle: workspace.projectHandle,
      resourceKind: "eventV2", operation: "list", view: "detail" });
    assert.equal((queried.items as unknown[]).length, 4);
    const edited = await plan("guide", "after");
    await call("pokemap_apply", { operation: "apply", projectHandle: workspace.projectHandle,
      planId: edited.planId, operationId: `edit-${sequence}` });
    const after = record(JSON.parse(await readFile(manifestPath, "utf8")));
    assert.deepEqual((record(after.eventRegistry).records as JsonRecord[]).map((event) => record(event.definition).id),
      events.map((event) => record(event.definition).id));
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

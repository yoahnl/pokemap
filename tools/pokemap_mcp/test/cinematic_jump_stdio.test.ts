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

function cinematic(mode: string, height = 1.25, duration = 1400, targetId = "destination"): JsonRecord {
  return {
    id: "jump", title: "Jump fixture", actorCompletionPolicy: "keepFinal", mapId: "room",
    requiredActors: [{ actorId: "actor", label: "Actor" }],
    movementTargets: [{ targetId: "destination", label: "Destination" }],
    stageContext: {
      actorBindings: [{ actorId: "actor", kind: "player" }],
      initialPlacements: [{ actorId: "actor", kind: "stagePoint", stagePointId: "start" }],
      stagePoints: [{ id: "start", label: "Start", x: 4, y: 4 }, { id: "destination", label: "Destination", x: 8, y: 4 }],
      movementTargetBindings: [{ targetId: "destination", kind: "stagePoint", sourceId: "destination" }],
    },
    timeline: { steps: [
      { id: "face", kind: "actorFace", actorId: "actor", metadata: { "authoring.kind": "basicBlock", "authoring.source": "cinematic-builder-v0", "authoring.block": "actorFace", "actor.direction": "left" } },
      { id: "jump-step", kind: "actorJump", actorId: "actor", targetId, durationMs: duration, metadata: {
        "authoring.kind": "basicBlock", "authoring.source": "cinematic-builder-v0", "authoring.block": "actorJump",
        "actor.jumpHeightCells": String(height), "actor.facingMode": mode,
      } },
    ] },
  };
}

test("MCP authors cinematic jumps and refuses invalid height duration target and facing without writes", { timeout: 90_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "cinematic-jump-mcp-"));
  const file = join(root, "project.json");
  const untouched = { id: "untouched", title: "Unchanged", timeline: { steps: [{ id: "wait", kind: "wait", durationMs: 500, metadata: {} }] } };
  await mkdir(join(root, "maps"));
  await writeFile(join(root, "maps/room.json"), JSON.stringify({ version: "v8", id: "room", name: "Room", size: { width: 16, height: 16 }, layers: [] }));
  await writeFile(file, JSON.stringify({ name: "Cinematic jump", version: "v8", pokemon: canonicalPokemonConfig(), maps: [{ id: "room", name: "Room", relativePath: "maps/room.json" }], tilesets: [], cinematics: [untouched] }));
  const args = [process.env.POKEMAP_TEST_MCP_ENTRY ?? resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const client = new Client({ name: "cinematic-jump-test", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  async function call(name: string, input: JsonRecord, failure = false): Promise<JsonRecord> {
    const envelope = record((await client.callTool({ name, arguments: input })).structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify(envelope));
    return record(envelope[failure ? "error" : "data"]);
  }
  try {
    await client.connect(transport);
    const described = await call("pokemap_describe", {});
    const descriptor = (described.mutationActions as JsonRecord[]).find(action => action.id === "cinematic.upsert");
    assert.match(String(descriptor?.summary), /actorJump/);
    assert.match(String(descriptor?.summary), /actor.jumpHeightCells/);
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    let sequence = 0;
    async function plan(asset: JsonRecord, failure = false): Promise<JsonRecord> {
      const state = await call("pokemap_validate", { projectHandle: opened.projectHandle });
      const id = `jump-${++sequence}`;
      return call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
        requestId: id, actionId: "cinematic.upsert", actionVersion: 1,
        workspaceHandle: opened.workspaceHandle, expectedRevision: state.snapshotRevision,
        idempotencyKey: id, parameters: { cinematic: asset },
      } }, failure);
    }
    for (const mode of ["preserve", "followMovement"]) {
      const before = await readFile(file);
      const planned = await plan(cinematic(mode));
      assert.deepEqual(await readFile(file), before);
      await call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle, planId: planned.planId, operationId: `apply-jump-${sequence}` });
      const query = await call("pokemap_query", { projectHandle: opened.projectHandle, resourceKind: "project", operation: "get", ids: ["project"], view: "detail", fieldMask: ["cinematics"] });
      const project = record((query.items as JsonRecord[])[0]);
      const item = record((project.cinematics as JsonRecord[]).find(asset => asset.id === "jump"));
      const steps = record(item.timeline).steps as JsonRecord[];
      assert.equal(item.actorCompletionPolicy, "keepFinal");
      assert.equal(record(steps[1]!.metadata)["actor.facingMode"], mode);
      assert.equal(Number(record(steps[1]!.metadata)["actor.jumpHeightCells"]), 1.25);
      assert.equal(steps[1]!.kind, "actorJump");
      assert.equal(steps[1]!.durationMs, 1400);
      assert.equal(record(steps[0]!.metadata)["actor.direction"], "left");
      const disk = record(JSON.parse(await readFile(file, "utf8")));
      const other = (disk.cinematics as JsonRecord[]).find(asset => asset.id === "untouched");
      assert.equal(record(other).title, untouched.title);
      assert.deepEqual(record(record(other).timeline).steps, untouched.timeline.steps);
    }
    for (const asset of [cinematic("sideways"), cinematic("preserve", 0), cinematic("preserve", 5), cinematic("preserve", .5, 199), cinematic("preserve", .5, 30001), cinematic("preserve", .5, 1000, "missing")]) {
      const before = await readFile(file);
      const rejected = await plan(asset, true);
      assert.equal(rejected.domainCode, "cinematic.invalid");
      assert.notEqual(rejected.domainCode, "worker.internal");
      assert.deepEqual(await readFile(file), before);
    }
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

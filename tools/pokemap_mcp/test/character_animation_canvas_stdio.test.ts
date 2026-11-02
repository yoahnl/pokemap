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

test("animation canvas is discoverable and survives MCP set preserve clear and cold reopen", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "character-canvas-mcp-"));
  const file = join(root, "project.json");
  const frame = { source: { x: 0, y: 0, width: 32, height: 56 }, durationMs: 100 };
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const initial = { version: "v9", name: "Canvas", maps: [],
    settings: { dimension: "threeD", spatialCamera: { mode: "fixed", projection: "perspective",
      pitchDegrees: 48.7, yawDegrees: 0, fieldOfViewDegrees: 16.2,
      distance: 42, orthographicHeight: 12 } }, pokemon: canonicalPokemonConfig(),
    tilesets: [{ id: "actors", name: "Actors", relativePath: "actors.png" }],
    characterStudioCatalog: { customAnimationDefinitions: [{ id: "floating", displayName: "Floating", mode: "single" }] },
    characters: [{ id: "hero", name: "Hero", tilesetId: "actors", animations: [
      { state: "surf_idle", direction: "south", sourceAssetId: "surf", frames: [frame] },
    ], customAnimations: [{ definitionId: "floating", sourceAssetId: "surf", frames: [frame] }] }] };
  await writeFile(file, JSON.stringify(initial));
  let sequence = 0;
  async function session(run: (call: (name: string, input?: JsonRecord, failure?: boolean) => Promise<JsonRecord>) => Promise<void>): Promise<void> {
    const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
    const client = new Client({ name: "character-canvas-test", version: "1.0.0" });
    async function call(name: string, input: JsonRecord = {}, failure = false): Promise<JsonRecord> {
      const body = record((await client.callTool({ name, arguments: input })).structuredContent);
      assert.equal(body.ok, !failure, JSON.stringify(body));
      return record(body[failure ? "error" : "data"]);
    }
    try {
      await client.connect(transport);
      await run(call);
    } finally {
      await client.close();
      await transport.close();
    }
  }
  try {
    await session(async call => {
      const catalog = await call("pokemap_describe");
      const action = (catalog.mutationActions as JsonRecord[]).find(value => value.id === "characterStudio.animationClip.upsert")!;
      const schema = record(record(record(action.extensions).inputSchema).properties);
      assert.deepEqual(record(schema.presentationReferenceHeightPx).type, ["integer", "null"]);
      assert.equal(record(schema.presentationReferenceHeightPx).omittedUpdate, "preserve");
      assert.equal(record(schema.presentationReferenceHeightPx).null, "clear");
      assert.equal(record(schema.presentationReferenceHeightPx).requiredRuntimeCapability, "character.animation-canvas@1");
      const resource = (catalog.resourceKinds as JsonRecord[]).find(value => value.id === "characterStudioCharacter")!;
      assert.equal(record(record(resource.extensions).animationCanvas).requiresDedicatedSource, true);
      const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
      const query = () => call("pokemap_query", { projectHandle: opened.projectHandle, resourceKind: "characterStudioCharacter", operation: "get", ids: ["hero"], view: "detail" });
      for (const kind of ["system", "custom"]) {
        const slot = kind === "system" ? { kind, state: "surf_idle", direction: "south" } : { kind, definitionId: "floating" };
        for (const mode of ["set", "preserve", "clear", "set"]) {
          const current = await query();
          const id = `canvas-${++sequence}`;
          const parameters: JsonRecord = { characterId: "hero", ...slot,
            ...(mode === "set" ? { presentationReferenceHeightPx: 32 } : {}),
            ...(mode === "clear" ? { presentationReferenceHeightPx: null } : {}),
            ...(mode === "preserve" ? { loop: false } : {}),
          };
          const planned = await call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
            requestId: id, idempotencyKey: id, workspaceHandle: opened.workspaceHandle,
            actionId: action.id, actionVersion: 1, expectedRevision: current.snapshotRevision, parameters,
          } });
          await call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle, planId: planned.planId, operationId: id });
          const project = record(JSON.parse(await readFile(file, "utf8")));
          const character = record((project.characters as unknown[])[0]);
          const clip = record((character[kind === "system" ? "animations" : "customAnimations"] as unknown[])[0]);
          assert.equal(clip.presentationReferenceHeightPx, mode === "clear" ? undefined : 32);
          assert.deepEqual(clip.frames, [frame]);
        }
        for (const value of [0, 8193, 32.5, "32", true, 57]) {
          const before = await readFile(file);
          const current = await query();
          const id = `canvas-invalid-${++sequence}`;
          await call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
            requestId: id, idempotencyKey: id, workspaceHandle: opened.workspaceHandle,
            actionId: action.id, actionVersion: 1, expectedRevision: current.snapshotRevision,
            parameters: { characterId: "hero", ...slot, presentationReferenceHeightPx: value },
          } }, true);
          assert.deepEqual(await readFile(file), before);
        }
      }
      await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
    });
    await session(async call => {
      const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
      const result = await call("pokemap_query", { projectHandle: opened.projectHandle, resourceKind: "characterStudioCharacter", operation: "get", ids: ["hero"], view: "detail" });
      const character = record((result.items as unknown[])[0]);
      for (const key of ["animations", "customAnimations"]) {
        assert.equal(record((character[key] as unknown[])[0]).presentationReferenceHeightPx, 32);
      }
      await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
    });
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

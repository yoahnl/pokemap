import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
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

test("runtime verification policies cross fresh MCP with independent project data and stale guards", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "runtime-policies-mcp-"));
  const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "runtime-policy", version: "1.0.0" });
  async function call(name: string, input: JsonRecord, failed = false): Promise<JsonRecord> {
    const envelope = record((await client.callTool({ name, arguments: input })).structuredContent);
    assert.equal(envelope.ok, !failed, JSON.stringify(envelope));
    return record(envelope[failed ? "error" : "data"]);
  }
  try {
    await client.connect(transport);
    const catalog = await call("pokemap_describe", {});
    assert.ok((catalog.resourceKinds as JsonRecord[]).some(value => value.id === "runtimeSmokeProfile"));
    assert.ok((catalog.mutationActions as JsonRecord[]).some(value => value.id === "validation.runtime_smoke_profile.configure"));
    let sequence = 0;
    for (const id of ["first", "second"]) {
      const project = join(root, id);
      await mkdir(project);
      const file = join(project, "project.json");
      await writeFile(file, JSON.stringify({ name: id, version: "v8", maps: [], tilesets: [], pokemon: canonicalPokemonConfig() }));
      const opened = await call("pokemap_workspace", { operation: "open", projectRoot: project });
      const handle = opened.projectHandle;
      async function query(): Promise<JsonRecord> {
        return call("pokemap_query", { projectHandle: handle, resourceKind: "runtimeSmokeProfile", operation: "list", view: "detail" });
      }
      async function configure(profile: JsonRecord | null, revision?: unknown, failed = false): Promise<JsonRecord> {
        const current = await query();
        const requestId = `policy-${++sequence}`;
        return call("pokemap_plan", { projectHandle: handle, request: {
          requestId, idempotencyKey: requestId, workspaceHandle: opened.workspaceHandle,
          actionId: "validation.runtime_smoke_profile.configure", actionVersion: 1,
          expectedRevision: revision ?? current.snapshotRevision, parameters: { profile },
        } }, failed);
      }
      const initial = await query();
      assert.deepEqual(initial.items, []);
      const profile = { id: `${id}-runtime`, version: 2, requiredSuiteIds: [`${id}-start`, `${id}-win`] };
      const original = await readFile(file);
      const plan = await configure(profile);
      assert.deepEqual(await readFile(file), original);
      await call("pokemap_apply", { operation: "apply", projectHandle: handle, planId: plan.planId, operationId: `apply-${id}` });
      const saved = await query();
      assert.deepEqual((saved.items as JsonRecord[]).map(value => value.id), [profile.id]);
      assert.deepEqual(record(JSON.parse(await readFile(file, "utf8"))).runtimeSmokeProfile, profile);
      const bytes = await readFile(file);
      await configure({ ...profile, version: 0 }, undefined, true);
      await configure(null, initial.snapshotRevision, true);
      assert.deepEqual(await readFile(file), bytes);
      const clear = await configure(null);
      await call("pokemap_apply", { operation: "apply", projectHandle: handle, planId: clear.planId, operationId: `clear-${id}` });
      assert.deepEqual((await query()).items, []);
      assert.equal(record(JSON.parse(await readFile(file, "utf8"))).runtimeSmokeProfile, undefined);
      await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
    }
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

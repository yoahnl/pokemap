import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";

import { Client } from "@modelcontextprotocol/client";
import { InMemoryTransport } from "@modelcontextprotocol/server";

import { LocalAuthoringClient, type AuthoringGateway, type JsonRecord } from "../src/authoring_client.js";
import { MemoryArtifactReader } from "../src/artifacts.js";
import { createPokeMapMcpServer } from "../src/server.js";
import { canonicalPokemonConfig } from "./pokemon_fixture.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

async function connect(authoring: AuthoringGateway) {
  const server = createPokeMapMcpServer({ authoring, artifacts: new MemoryArtifactReader() });
  const [ct, st] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "recovery-status-test", version: "1.0.0" });
  await server.connect(st);
  await client.connect(ct);
  return {
    client,
    async close() {
      await client.close();
      await server.close();
      await authoring.close();
    },
  };
}

test("MCP recovery status is discoverable, strictly read-only and routes opaque identities", async () => {
  const calls: Array<{ command: string; args?: JsonRecord }> = [];
  const expected = { operationId: "operation-test", committed: true, finalized: false, recoverable: true, receiptId: "receipt-test" };
  const f = await connect({
    async request(command, args) {
      calls.push({ command, ...(args === undefined ? {} : { args }) });
      return { requestId: "status-test", data: expected, artifacts: [] };
    },
    async close() {},
  });
  try {
    const descriptor = (await f.client.listTools()).tools.find(tool => tool.name === "pokemap_recovery_status");
    assert.ok(descriptor);
    assert.equal(descriptor.annotations?.readOnlyHint, true);
    assert.equal(descriptor.annotations?.destructiveHint, false);
    assert.equal(descriptor.annotations?.openWorldHint, false);
    const result = await f.client.callTool({ name: "pokemap_recovery_status", arguments: { projectHandle: "project-test", operationId: "operation-test" } });
    assert.equal(result.isError, undefined);
    assert.deepEqual(record(result.structuredContent).data, expected);
    assert.deepEqual(calls, [{ command: "recovery_status", args: { projectHandle: "project-test", operationId: "operation-test" } }]);
    for (const input of [
      { projectHandle: "project-test", operationId: "operation-test", confirmation: "RECOVER operation-test" },
      { projectHandle: "project-test", operationId: "" },
      { projectHandle: "", operationId: "operation-test" },
    ]) {
      let rejected = false;
      try {
        rejected = (await f.client.callTool({ name: "pokemap_recovery_status", arguments: input })).isError === true;
      } catch {
        rejected = true;
      }
      assert.equal(rejected, true);
      assert.equal(calls.length, 1);
    }
  } finally {
    await f.close();
  }
});

test("MCP recovery status reads a completed operation without replay or cross-project disclosure", { timeout: 90_000 }, async () => {
  const roots = await Promise.all([0, 1].map(() => mkdtemp(join(tmpdir(), "pokemap-private-status-"))));
  const authoring = new LocalAuthoringClient({
    allowedRoots: roots,
    authoringPackageRoot: resolve(process.cwd(), "../../packages/map_authoring"),
    requestTimeoutMs: 60_000,
    workerTimeoutMs: 30_000,
  });
  let f: Awaited<ReturnType<typeof connect>> | undefined;
  try {
    for (const root of roots) {
      await writeFile(join(root, "project.json"), JSON.stringify({ name: "private-secret", version: "v8", maps: [], tilesets: [], pokemon: { ...canonicalPokemonConfig(), enabled: false } }));
    }
    f = await connect(authoring);
    const client = f.client;
    async function data(name: string, args: JsonRecord): Promise<JsonRecord> {
      const result = await client.callTool({ name, arguments: args });
      assert.equal(result.isError, undefined, JSON.stringify(result.structuredContent));
      return record(record(result.structuredContent).data);
    }
    const first = await data("pokemap_workspace", { operation: "open", projectRoot: roots[0] });
    const second = await data("pokemap_workspace", { operation: "open", projectRoot: roots[1] });
    const described = await data("pokemap_describe", {});
    assert.ok((described.commands as JsonRecord[]).some(command => command.id === "recovery_status"));
    const validation = await data("pokemap_validate", { projectHandle: first.projectHandle });
    const planned = await data("pokemap_plan", {
      projectHandle: first.projectHandle,
      request: {
        requestId: "status-map-create", actionId: "map.create", actionVersion: 1,
        workspaceHandle: first.workspaceHandle, idempotencyKey: "status-map-create",
        expectedRevision: validation.snapshotRevision,
        parameters: { mapId: "town", name: "Town", width: 2, height: 2 },
      },
    });
    const applied = await data("pokemap_apply", { operation: "apply", projectHandle: first.projectHandle, planId: planned.planId, operationId: "status-operation" });
    const receipt = record(applied.receipt);
    const root = roots[0]!;
    const paths = [join(root, "project.json"), join(root, "maps/town.json"), join(root, ".pokemap/authoring/history.jsonl")];
    const before = await Promise.all(paths.map(path => readFile(path)));
    for (let attempt = 0; attempt < 2; attempt++) {
      const status = await data("pokemap_recovery_status", { projectHandle: first.projectHandle, operationId: "status-operation" });
      assert.equal(status.committed, true);
      assert.equal(status.finalized, true);
      assert.equal(status.recoverable, false);
      assert.equal(status.receiptId, receipt.receiptId);
      const encoded = JSON.stringify(status);
      assert.ok(!encoded.includes("private-secret"));
      for (const path of roots) assert.ok(!encoded.includes(path));
    }
    const foreign = await data("pokemap_recovery_status", { projectHandle: second.projectHandle, operationId: "status-operation" });
    assert.deepEqual(foreign, { operationId: "status-operation", disposition: "notFound" });
    const unknown = await data("pokemap_recovery_status", { projectHandle: first.projectHandle, operationId: "unknown-operation" });
    assert.deepEqual(unknown, { operationId: "unknown-operation", disposition: "notFound" });
    const rejected = await client.callTool({ name: "pokemap_recovery_status", arguments: { projectHandle: "project-foreign-handle", operationId: "status-operation" } });
    assert.equal(rejected.isError, true);
    const failure = JSON.stringify(rejected.structuredContent);
    assert.ok(!failure.includes(String(receipt.receiptId)));
    for (const path of roots) assert.ok(!failure.includes(path));
    assert.deepEqual(await Promise.all(paths.map(path => readFile(path))), before);
    await data("pokemap_workspace", { operation: "close", workspaceHandle: first.workspaceHandle });
    await data("pokemap_workspace", { operation: "close", workspaceHandle: second.workspaceHandle });
  } finally {
    if (f) await f.close();
    else await authoring.close();
    for (const root of roots) await rm(root, { recursive: true, force: true });
  }
});

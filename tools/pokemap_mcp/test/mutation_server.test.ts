import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";

import { Client } from "@modelcontextprotocol/client";
import { InMemoryTransport } from "@modelcontextprotocol/server";

import {
  AuthoringClientError,
  type AuthoringGateway,
  type JsonRecord,
  LocalAuthoringClient,
} from "../src/authoring_client.js";
import { MemoryArtifactReader } from "../src/artifacts.js";
import { createPokeMapMcpServer } from "../src/server.js";

const repositoryRoot = resolve(process.cwd(), "../..");
const authoringPackageRoot = resolve(repositoryRoot, "packages/map_authoring");
const scaffold = resolve(
  repositoryRoot,
  "examples/playable_runtime_host/phase6_authoring_golden_slice/project.json",
);

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

async function toolData(
  client: Client,
  name: string,
  args: JsonRecord,
): Promise<JsonRecord> {
  const result = await client.callTool({ name, arguments: args });
  assert.equal(result.isError, undefined, JSON.stringify(result.structuredContent));
  const envelope = record(result.structuredContent);
  assert.equal(envelope.ok, true);
  return record(envelope.data);
}

async function mutationFixture() {
  const root = await mkdtemp(join(tmpdir(), "pokemap-mcp-mutation-"));
  await writeFile(join(root, "project.json"), await readFile(scaffold));
  const authoring = new LocalAuthoringClient({
    allowedRoots: [root],
    authoringPackageRoot,
  });
  const server = createPokeMapMcpServer({
    authoring,
    artifacts: new MemoryArtifactReader(),
  });
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "pokemap-mutation-test", version: "1.0.0" });
  await server.connect(serverTransport);
  await client.connect(clientTransport);
  return { authoring, client, root, server };
}

test("MCP preserves CLI plan/apply parity for one complete map batch", async () => {
  const fixture = await mutationFixture();
  try {
    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const projectHandle = String(opened.projectHandle);
    const workspaceHandle = String(opened.workspaceHandle);
    const validation = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });

    const planned = await toolData(fixture.client, "pokemap_plan", {
      projectHandle,
      request: {
        requestId: "mcp-map-create",
        actionId: "map.create",
        actionVersion: 1,
        workspaceHandle,
        parameters: { mapId: "mcp_batch_map", width: 3, height: 2 },
        expectedRevision: validation.snapshotRevision,
        idempotencyKey: "idem-mcp-map-create",
        dryRun: false,
      },
    });
    assert.equal(record(planned.receipt).status, "planned");
    await assert.rejects(readFile(join(fixture.root, "maps/mcp_batch_map.json")));

    const applied = await toolData(fixture.client, "pokemap_apply", {
      operation: "apply",
      projectHandle,
      planId: planned.planId,
      operationId: "operation-mcp-map-create",
    });
    const retried = await toolData(fixture.client, "pokemap_apply", {
      operation: "apply",
      projectHandle,
      planId: planned.planId,
      operationId: "operation-mcp-map-create",
    });
    assert.deepEqual(retried, applied);

    const queried = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "map",
      operation: "get",
      view: "detail",
      ids: ["mcp_batch_map"],
    });
    assert.equal(record((queried.items as unknown[])[0]).id, "mcp_batch_map");

    const history = await toolData(fixture.client, "pokemap_history", {
      operation: "list",
      projectHandle,
      limit: 1,
    });
    assert.equal((history.entries as unknown[]).length, 1);
    assert.equal(record((history.entries as unknown[])[0]).operationId, "operation-mcp-map-create");

    const afterValidation = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });
    assert.notEqual(afterValidation.snapshotRevision, validation.snapshotRevision);

    const batchPlan = await toolData(fixture.client, "pokemap_plan", {
      projectHandle,
      request: {
        requestId: "mcp-map-batch",
        actionId: "map.apply_operations",
        actionVersion: 1,
        workspaceHandle,
        parameters: {
          mapId: "mcp_batch_map",
          operations: [
            {
              kind: "layer.add",
              layerKind: "tile",
              layerId: "ground",
              name: "Ground",
            },
            {
              kind: "region.fill",
              layerId: "ground",
              x: 0,
              y: 0,
              width: 3,
              height: 2,
              value: 7,
            },
          ],
        },
        expectedRevision: afterValidation.snapshotRevision,
        idempotencyKey: "idem-mcp-map-batch",
        dryRun: false,
      },
    });
    assert.equal(record(batchPlan.receipt).status, "planned");
    const batchApplied = await toolData(fixture.client, "pokemap_apply", {
      operation: "apply",
      projectHandle,
      planId: batchPlan.planId,
      operationId: "operation-mcp-map-batch",
    });
    assert.equal(record(batchApplied.receipt).actionId, "map.apply_operations");

    const batchHistory = await toolData(fixture.client, "pokemap_history", {
      operation: "list",
      projectHandle,
      limit: 2,
    });
    assert.deepEqual(
      (batchHistory.entries as JsonRecord[]).map((entry) => entry.operationId),
      ["operation-mcp-map-batch", "operation-mcp-map-create"],
    );
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test("MCP returns a revision conflict without silently rebuilding the plan", async () => {
  const fixture = await mutationFixture();
  try {
    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const projectHandle = String(opened.projectHandle);
    const validation = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });
    const planned = await toolData(fixture.client, "pokemap_plan", {
      projectHandle,
      request: {
        requestId: "mcp-conflict",
        actionId: "map.create",
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle,
        parameters: { mapId: "conflicted_map", width: 2, height: 2 },
        expectedRevision: validation.snapshotRevision,
        idempotencyKey: "idem-mcp-conflict",
        dryRun: false,
      },
    });
    const manifestPath = join(fixture.root, "project.json");
    await writeFile(manifestPath, `${await readFile(manifestPath, "utf8")}\n`);

    const result = await fixture.client.callTool({
      name: "pokemap_apply",
      arguments: {
        operation: "apply",
        projectHandle,
        planId: planned.planId,
        operationId: "operation-mcp-conflict",
      },
    });
    assert.equal(result.isError, true);
    const error = record(record(result.structuredContent).error);
    assert.equal(error.code, "revision_conflict");
    assert.equal(error.retryable, true);
    await assert.rejects(readFile(join(fixture.root, "maps/conflicted_map.json")));
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test("recovery requires an exact confirmation and preserves permission errors", async () => {
  const calls: string[] = [];
  const authoring: AuthoringGateway = {
    async request(command) {
      calls.push(command);
      throw new AuthoringClientError(
        "permission_denied",
        "The actor lacks recovery permission.",
        false,
        ["Grant project.recovery before retrying."],
        { domainCode: "authorization.permission_denied" },
      );
    },
    async close() {},
  };
  const server = createPokeMapMcpServer({
    authoring,
    artifacts: new MemoryArtifactReader(),
  });
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "pokemap-recovery-test", version: "1.0.0" });
  await server.connect(serverTransport);
  await client.connect(clientTransport);
  try {
    const missingConfirmation = await client.callTool({
      name: "pokemap_recovery",
      arguments: {
        projectHandle: "project-test",
        operationId: "operation-recovery",
        confirmation: "yes",
      },
    });
    let error = record(record(missingConfirmation.structuredContent).error);
    assert.equal(error.code, "confirmation.required");
    assert.deepEqual(calls, []);

    const denied = await client.callTool({
      name: "pokemap_recovery",
      arguments: {
        projectHandle: "project-test",
        operationId: "operation-recovery",
        confirmation: "RECOVER operation-recovery",
      },
    });
    error = record(record(denied.structuredContent).error);
    assert.equal(error.code, "permission_denied");
    assert.equal(error.domainCode, "authorization.permission_denied");
    assert.deepEqual(calls, ["recover"]);
  } finally {
    await client.close();
    await server.close();
  }
});

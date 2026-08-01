import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";

import { Client } from "@modelcontextprotocol/client";
import { InMemoryTransport } from "@modelcontextprotocol/server";

import type {
  AuthoringGateway,
  JsonRecord,
} from "../src/authoring_client.js";
import { LocalAuthoringClient } from "../src/authoring_client.js";
import { MemoryArtifactReader } from "../src/artifacts.js";
import { PokeMapRequestGuard } from "../src/request_guard.js";
import { createPokeMapMcpServer } from "../src/server.js";

const repositoryRoot = resolve(process.cwd(), "../..");
const authoringPackageRoot = resolve(repositoryRoot, "packages/map_authoring");
const emptyProjectScaffold = resolve(
  repositoryRoot,
  "examples/playable_runtime_host/phase6_authoring_golden_slice/project.json",
);

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

async function connect(
  authoring: AuthoringGateway,
  guard = new PokeMapRequestGuard(),
) {
  const server = createPokeMapMcpServer({
    authoring,
    artifacts: new MemoryArtifactReader(),
    guard,
  });
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "pmcp085-conformance", version: "1.0.0" });
  await server.connect(serverTransport);
  await client.connect(clientTransport);
  return { client, server };
}

test("all ten tools publish strict schemas, outputs and annotations", async () => {
  const gateway: AuthoringGateway = {
    async request() {
      return { requestId: "conformance", data: {}, artifacts: [] };
    },
    async close() {},
  };
  const fixture = await connect(gateway);
  try {
    const tools = (await fixture.client.listTools()).tools;
    assert.deepEqual(
      tools.map((tool) => tool.name),
      [
        "pokemap_artifact",
        "pokemap_describe",
        "pokemap_query",
        "pokemap_validate",
        "pokemap_workspace",
        "pokemap_artifact_stage",
        "pokemap_plan",
        "pokemap_apply",
        "pokemap_history",
        "pokemap_recovery",
      ],
    );
    for (const tool of tools) {
      assert.ok(tool.inputSchema);
      assert.ok(tool.outputSchema);
      assertStrictSchema(tool.inputSchema, tool.name);
      assert.equal(typeof tool.annotations?.readOnlyHint, "boolean", tool.name);
    }
  } finally {
    await fixture.client.close();
    await fixture.server.close();
  }
});

test("rate and UTF-8 size budgets fail closed before reaching a gateway", async () => {
  const calls: string[] = [];
  const gateway: AuthoringGateway = {
    async request(command) {
      calls.push(command);
      return { requestId: command, data: {}, artifacts: [] };
    },
    async close() {},
  };
  const fixture = await connect(
    gateway,
    new PokeMapRequestGuard({
      maxRequestsPerWindow: 2,
      windowMs: 60_000,
      maxInputBytes: 32,
    }),
  );
  try {
    await fixture.client.callTool({ name: "pokemap_describe", arguments: {} });
    const tooLarge = await fixture.client.callTool({
      name: "pokemap_workspace",
      arguments: { operation: "open", projectRoot: `/${"é".repeat(64)}` },
    });
    assert.equal(tooLarge.isError, true);
    assert.equal(record(record(tooLarge.structuredContent).error).code, "resource_limit");

    await fixture.client.callTool({ name: "pokemap_describe", arguments: {} });
    const throttled = await fixture.client.callTool({
      name: "pokemap_describe",
      arguments: {},
    });
    assert.equal(throttled.isError, true);
    assert.equal(record(record(throttled.structuredContent).error).code, "rate_limited");
    assert.deepEqual(calls, ["describe", "describe"]);
  } finally {
    await fixture.client.close();
    await fixture.server.close();
  }
});

test("strict schemas reject a deterministic malformed-envelope corpus", async () => {
  let gatewayCalls = 0;
  const gateway: AuthoringGateway = {
    async request() {
      gatewayCalls += 1;
      return { requestId: "unexpected", data: {}, artifacts: [] };
    },
    async close() {},
  };
  const fixture = await connect(gateway);
  try {
    const corpus: JsonRecord[] = [
      {},
      { projectHandle: "p", resourceKind: "map", operation: "get" },
      { projectHandle: "p", resourceKind: "../map", operation: "list" },
      { projectHandle: "p", resourceKind: "map", operation: "list", extra: true },
      { projectHandle: "p", resourceKind: "map", operation: "search", searchTerm: "" },
      { projectHandle: "p", resourceKind: "map", operation: "list", pageSize: 0 },
      { projectHandle: "p", resourceKind: "map", operation: "list", pageSize: 201 },
      ...Array.from({ length: 64 }, (_, index) => ({
        projectHandle: `project-${index}`,
        resourceKind: index % 2 === 0 ? "map" : "project",
        operation: "list",
        [`unexpected_${index}`]: true,
      })),
    ];
    for (const arguments_ of corpus) {
      try {
        const result = await fixture.client.callTool({
          name: "pokemap_query",
          arguments: arguments_,
        });
        assert.equal(result.isError, true, JSON.stringify(arguments_));
      } catch (error) {
        assert.ok(error instanceof Error);
      }
    }
    assert.equal(gatewayCalls, 0);
  } finally {
    await fixture.client.close();
    await fixture.server.close();
  }
});

function assertStrictSchema(schema: unknown, toolName: string): void {
  const object = record(schema);
  if (object.additionalProperties === false) return;
  const alternatives = object.oneOf ?? object.anyOf;
  assert.ok(Array.isArray(alternatives) && alternatives.length > 0, toolName);
  for (const alternative of alternatives) {
    assert.equal(record(alternative).additionalProperties, false, toolName);
  }
}

test("MCP emits the same map.create golden receipt as direct API, CLI and editor", async () => {
  const expected = JSON.parse(
    await readFile(
      resolve(
        repositoryRoot,
        "packages/map_authoring/test/fixtures/pmcp085_golden_receipt.json",
      ),
      "utf8",
    ),
  );
  const root = await mkdtemp(join(tmpdir(), "pmcp085-mcp-golden-"));
  await writeFile(join(root, "project.json"), await readFile(emptyProjectScaffold));
  const authoring = new LocalAuthoringClient({
    allowedRoots: [root],
    authoringPackageRoot,
  });
  const fixture = await connect(authoring);
  try {
    const opened = record(
      record(
        (
          await fixture.client.callTool({
            name: "pokemap_workspace",
            arguments: { operation: "open", projectRoot: root },
          })
        ).structuredContent,
      ).data,
    );
    const projectHandle = String(opened.projectHandle);
    const validation = record(
      record(
        (
          await fixture.client.callTool({
            name: "pokemap_validate",
            arguments: { projectHandle },
          })
        ).structuredContent,
      ).data,
    );
    const planned = record(
      record(
        (
          await fixture.client.callTool({
            name: "pokemap_plan",
            arguments: {
              projectHandle,
              request: {
                requestId: "pmcp085-golden-request",
                actionId: "map.create",
                actionVersion: 1,
                workspaceHandle: opened.workspaceHandle,
                parameters: {
                  mapId: "pmcp085_golden_map",
                  width: 3,
                  height: 2,
                },
                expectedRevision: validation.snapshotRevision,
                idempotencyKey: "pmcp085-golden-idempotency",
                dryRun: false,
              },
            },
          })
        ).structuredContent,
      ).data,
    );
    const result = await fixture.client.callTool({
      name: "pokemap_apply",
      arguments: {
        operation: "apply",
        projectHandle,
        planId: planned.planId,
        operationId: "pmcp085-mcp-apply",
      },
    });
    const transported = record(record(result.structuredContent).data);
    const actualReceipt = record(transported.receipt);
    assert.deepEqual(
      {
        actionId: actualReceipt.actionId,
        actionVersion: actualReceipt.actionVersion,
        status: actualReceipt.status,
        changes: (record(actualReceipt.diff).entries as unknown[]).map(
          (rawChange) => {
            const change = record(rawChange);
            const resource = record(change.resource);
            return {
              operation: change.operation,
              resource: { kind: resource.kind, id: resource.id },
              path: change.path,
            };
          },
        ),
      },
      expected,
    );
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await authoring.close();
    await rm(root, { recursive: true, force: true });
  }
});

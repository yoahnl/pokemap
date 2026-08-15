import assert from "node:assert/strict";
import { resolve } from "node:path";
import { setTimeout as delay } from "node:timers/promises";
import { test } from "node:test";

import { Client } from "@modelcontextprotocol/client";
import { InMemoryTransport } from "@modelcontextprotocol/server";

import { LocalAuthoringClient, type JsonRecord } from "../src/authoring_client.js";
import { MemoryArtifactReader } from "../src/artifacts.js";
import { LocalRuntimeGateway } from "../src/runtime_gateway.js";
import { createPokeMapMcpServer } from "../src/server.js";
import { PokeMapToolError } from "../src/tool_error.js";

const repositoryRoot = resolve(process.cwd(), "../..");
const projectRoot = resolve(
  repositoryRoot,
  "examples/playable_runtime_host/golden_fangame_slice",
);

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

async function tool(
  client: Client,
  name: string,
  args: JsonRecord,
): Promise<{ data: JsonRecord; artifacts: JsonRecord[] }> {
  const result = await client.callTool({ name, arguments: args });
  assert.equal(result.isError, undefined, JSON.stringify(result.structuredContent));
  const envelope = record(result.structuredContent);
  assert.equal(envelope.ok, true);
  return {
    data: record(envelope.data),
    artifacts: envelope.artifacts as JsonRecord[],
  };
}

async function runtimeFixture() {
  const authoring = new LocalAuthoringClient({
    allowedRoots: [projectRoot],
    authoringPackageRoot: resolve(repositoryRoot, "packages/map_authoring"),
  });
  const artifacts = new MemoryArtifactReader();
  let nextJob = 0;
  let failOnce = true;
  let catalogRepairPending = true;
  let projectionBuildCount = 0;
  let projectionDisposeCount = 0;
  let executorCount = 0;
  const executedProjectRoots: string[] = [];
  const runtime = new LocalRuntimeGateway({
    roots: authoring,
    artifacts,
    runtimePackageRoot: resolve(repositoryRoot, "packages/map_runtime"),
    runtimeHostRoot: resolve(repositoryRoot, "examples/playable_runtime_host"),
    repositoryRoot,
    jobIdFactory: () => `job-test-${++nextJob}`,
    playtestProjectionFactory: async ({ jobId, request }) => {
      projectionBuildCount += 1;
      if (request.scenarioId === "catalog.invalid") {
        throw new PokeMapToolError(
          "pokemon.catalog_not_ready",
          "The projected Pokemon catalog is invalid.",
        );
      }
      if (request.scenarioId === "catalog.repair" && catalogRepairPending) {
        catalogRepairPending = false;
        throw new PokeMapToolError(
          "pokemon.catalog_not_ready",
          "The projected Pokemon catalog is invalid.",
          true,
        );
      }
      return {
        projectRoot: resolve(repositoryRoot, "build", "test-projections", jobId),
        projectRelativeRoot: `build/test-projections/${jobId}`,
        projectTreeHash: "a".repeat(64),
        authoringRevision: `sha256:${"b".repeat(64)}`,
        dispose: async () => {
          projectionDisposeCount += 1;
        },
      };
    },
    playtestExecutor: async ({
      jobId,
      projectRoot,
      request,
      signal,
      emit,
    }) => {
      executorCount += 1;
      executedProjectRoots.push(projectRoot);
      emit("playtest.sandbox_started", { isolated: true });
      if (request.scenarioId === "slow.cancel") {
        await new Promise<never>((_resolve, reject) => {
          signal.addEventListener(
            "abort",
            () => reject(new Error("cancelled")),
            { once: true },
          );
        });
      }
      if (request.scenarioId === "fail.once" && failOnce) {
        failOnce = false;
        throw new Error("controlled failure");
      }
      const uri = `artifact://sha256/${jobId.padEnd(64, "0").slice(0, 64)}`;
      artifacts.registerText(uri, "application/json", '{"sandboxed":true}');
      return {
        data: {
          receipt: {
            receiptId: `receipt-${jobId}`,
            scenarioId: request.scenarioId,
            terminalState: "stopped",
          },
        },
        artifacts: [
          {
            id: "receipt",
            uri,
            mediaType: "application/json",
          },
        ],
      };
    },
  });
  const server = createPokeMapMcpServer({ authoring, artifacts, runtime });
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "pokemap-runtime-test", version: "1.0.0" });
  await server.connect(serverTransport);
  await client.connect(clientTransport);
  const opened = await tool(client, "pokemap_workspace", {
    operation: "open",
    projectRoot,
  });
  return {
    authoring,
    artifacts,
    client,
    projectHandle: String(opened.data.projectHandle),
    projectionStats: {
      get buildCount() {
        return projectionBuildCount;
      },
      get disposeCount() {
        return projectionDisposeCount;
      },
      get executorCount() {
        return executorCount;
      },
      executedProjectRoots,
    },
    runtime,
    server,
  };
}

async function terminalJob(client: Client, jobId: string): Promise<{
  data: JsonRecord;
  artifacts: JsonRecord[];
}> {
  for (let attempt = 0; attempt < 100; attempt += 1) {
    const snapshot = await tool(client, "pokemap_job", {
      operation: "get",
      jobId,
    });
    if (["succeeded", "failed", "cancelled"].includes(String(snapshot.data.state))) {
      return snapshot;
    }
    await delay(10);
  }
  assert.fail("runtime job did not reach a terminal state");
}

test("runtime MCP renders through map_runtime and registers opaque PNG bytes", async () => {
  const fixture = await runtimeFixture();
  try {
    const rendered = await tool(fixture.client, "pokemap_render", {
      projectHandle: fixture.projectHandle,
      mapId: "golden_town",
      cellPixelSize: 1,
      overlays: ["collision", "entities"],
    });
    assert.equal(rendered.data.mimeType, "image/png");
    assert.equal(rendered.data.width, 6);
    assert.equal(rendered.data.height, 5);
    assert.equal(rendered.artifacts.length, 1);
    const uri = String(rendered.artifacts[0]?.uri);
    assert.match(uri, /^artifact:\/\/sha256\/[0-9a-f]{64}$/);

    const artifact = await tool(fixture.client, "pokemap_artifact", { uri });
    assert.equal(artifact.data.mediaType, "image/png");
    assert.ok(Buffer.from(String(artifact.data.blob), "base64").subarray(0, 4).equals(
      Buffer.from([137, 80, 78, 71]),
    ));
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.runtime.close();
    await fixture.authoring.close();
  }
});

test("sandboxed playtest job returns receipt, artifacts and ordered events", async () => {
  const fixture = await runtimeFixture();
  try {
    const started = await tool(fixture.client, "pokemap_playtest", {
      projectHandle: fixture.projectHandle,
      scenarioId: "fake.sandbox",
    });
    const jobId = String(started.data.jobId);
    const terminal = await terminalJob(fixture.client, jobId);
    assert.equal(terminal.data.state, "succeeded");
    assert.equal(record(record(terminal.data.result).receipt).terminalState, "stopped");
    assert.equal(terminal.artifacts.length, 1);
    assert.equal(fixture.projectionStats.buildCount, 1);
    assert.equal(fixture.projectionStats.disposeCount, 1);
    assert.equal(fixture.projectionStats.executorCount, 1);
    assert.match(
      fixture.projectionStats.executedProjectRoots[0] ?? "",
      /build\/test-projections\/job-test-1$/u,
    );

    const events = await tool(fixture.client, "pokemap_job", {
      operation: "events",
      jobId,
      afterSequence: 0,
    });
    const values = events.data.events as JsonRecord[];
    assert.deepEqual(
      values.map((event) => event.sequence),
      values.map((_event, index) => index + 1),
    );
    assert.ok(values.some((event) => event.type === "playtest.sandbox_started"));
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.runtime.close();
    await fixture.authoring.close();
  }
});

test("playtest jobs support bounded cancellation", async () => {
  const fixture = await runtimeFixture();
  try {
    const started = await tool(fixture.client, "pokemap_playtest", {
      projectHandle: fixture.projectHandle,
      scenarioId: "slow.cancel",
    });
    const jobId = String(started.data.jobId);
    await tool(fixture.client, "pokemap_job", {
      operation: "cancel",
      jobId,
    });
    const terminal = await terminalJob(fixture.client, jobId);
    assert.equal(terminal.data.state, "cancelled");
    assert.equal(fixture.projectionStats.disposeCount, 1);
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.runtime.close();
    await fixture.authoring.close();
  }
});

test("failed playtest jobs can be retried as a new traced attempt", async () => {
  const fixture = await runtimeFixture();
  try {
    const started = await tool(fixture.client, "pokemap_playtest", {
      projectHandle: fixture.projectHandle,
      scenarioId: "fail.once",
    });
    const failed = await terminalJob(fixture.client, String(started.data.jobId));
    assert.equal(failed.data.state, "failed");

    const retried = await tool(fixture.client, "pokemap_job", {
      operation: "retry",
      jobId: failed.data.jobId,
    });
    const succeeded = await terminalJob(fixture.client, String(retried.data.jobId));
    assert.equal(succeeded.data.state, "succeeded");
    assert.equal(succeeded.data.attempt, 2);
    assert.equal(succeeded.data.retryOfJobId, failed.data.jobId);
    assert.equal(fixture.projectionStats.buildCount, 2);
    assert.equal(fixture.projectionStats.disposeCount, 2);
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.runtime.close();
    await fixture.authoring.close();
  }
});

test("Pokemon preflight failure never creates a runtime executor", async () => {
  const fixture = await runtimeFixture();
  try {
    const started = await tool(fixture.client, "pokemap_playtest", {
      projectHandle: fixture.projectHandle,
      scenarioId: "catalog.invalid",
    });
    const terminal = await terminalJob(fixture.client, String(started.data.jobId));

    assert.equal(terminal.data.state, "failed");
    assert.equal(record(terminal.data.error).code, "pokemon.catalog_not_ready");
    assert.equal(fixture.projectionStats.executorCount, 0);
    assert.equal(fixture.projectionStats.disposeCount, 0);
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.runtime.close();
    await fixture.authoring.close();
  }
});

test("retry rebuilds and revalidates a fresh Pokemon projection", async () => {
  const fixture = await runtimeFixture();
  try {
    const started = await tool(fixture.client, "pokemap_playtest", {
      projectHandle: fixture.projectHandle,
      scenarioId: "catalog.repair",
    });
    const failed = await terminalJob(fixture.client, String(started.data.jobId));
    assert.equal(failed.data.state, "failed");
    assert.equal(fixture.projectionStats.executorCount, 0);

    const retried = await tool(fixture.client, "pokemap_job", {
      operation: "retry",
      jobId: failed.data.jobId,
    });
    const succeeded = await terminalJob(fixture.client, String(retried.data.jobId));

    assert.equal(succeeded.data.state, "succeeded");
    assert.equal(fixture.projectionStats.buildCount, 2);
    assert.equal(fixture.projectionStats.executorCount, 1);
    assert.equal(fixture.projectionStats.disposeCount, 1);
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.runtime.close();
    await fixture.authoring.close();
  }
});

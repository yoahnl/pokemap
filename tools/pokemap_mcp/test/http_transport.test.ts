import assert from "node:assert/strict";
import { test } from "node:test";
import { request as httpRequest } from "node:http";
import {
  Client,
  StreamableHTTPClientTransport,
} from "@modelcontextprotocol/client";
import { MemoryArtifactReader } from "../src/artifacts.js";
import { createPokeMapMcpServer } from "../src/server.js";
import { startPokeMapHttp } from "../src/http_transport.js";
import type { PokeMapServerRuntime } from "../src/server_runtime.js";
import type { RuntimeGateway } from "../src/runtime_gateway.js";

test("loopback authentication and origin/host checks precede session creation", async () => {
  let created = 0;
  const host = await startPokeMapHttp({
    createRuntime: () => {
      created++;
      throw Error("unused");
    },
  });
  try {
    assert.match(host.url, /^http:\/\/127\.0\.0\.1:/);
    assert.equal((await fetch(host.url)).status, 401);
    assert.equal(
      (
        await fetch(host.url, {
          headers: {
            Authorization: `Bearer ${host.token}`,
            Origin: "https://foreign.invalid",
          },
        })
      ).status,
      403,
    );
    const badHost = await new Promise<number>((accept, reject) => {
      const request = httpRequest(
        host.url,
        {
          headers: {
            Authorization: `Bearer ${host.token}`,
            Host: "foreign.invalid",
          },
        },
        (response) => {
          response.resume();
          accept(response.statusCode!);
        },
      );
      request.on("error", reject);
      request.end();
    });
    assert.equal(badHost, 403);
    assert.equal(created, 0);
  } finally {
    await host.close();
  }
});

test("two SDK sessions own independent gateways and release only their workers", async () => {
  const closed: number[] = [];
  let next = 0;
  const host = await startPokeMapHttp({
    createRuntime: () => {
      const id = ++next;
      const authoring = {
        resolveProjectRoot: () => "/fixture",
        close: async () => {
          closed.push(id);
        },
        request: async () => ({
          requestId: "describe",
          data: { session: id },
          artifacts: [],
        }),
      };
      const artifacts = new MemoryArtifactReader();
      return {
        authoring,
        runtime: {} as RuntimeGateway,
        createServer: (protocolVersions) =>
          createPokeMapMcpServer({
            authoring,
            artifacts,
            ...(protocolVersions ? { protocolVersions } : {}),
          }),
        close: authoring.close,
      } satisfies PokeMapServerRuntime;
    },
  });
  const clients = [0, 1].map(
    (id) =>
      new Client(
        { name: `http-test-${id}`, version: "1" },
        { versionNegotiation: { mode: "legacy" } },
      ),
  );
  const transports = clients.map(
    () =>
      new StreamableHTTPClientTransport(new URL(host.url), {
        requestInit: { headers: { Authorization: `Bearer ${host.token}` } },
      }),
  );
  try {
    for (const [index, client] of clients.entries())
      await client.connect(transports[index]!);
    assert.equal(host.sessionCount(), 2);
    for (const [index, client] of clients.entries()) {
      const listed = await client.listTools();
      assert.ok(listed.tools.some((tool) => tool.name === "pokemap_map_edit"));
      const result = await client.callTool({
        name: "pokemap_describe",
        arguments: {},
      });
      assert.equal(
        (result.structuredContent as { data: { session: number } }).data
          .session,
        index + 1,
      );
    }
    await transports[0]!.terminateSession();
    await clients[0]!.close();
    assert.deepEqual(closed, [1]);
    assert.equal(host.sessionCount(), 1);
    assert.ok((await clients[1]!.listTools()).tools.length > 0);
    await host.invalidateSessions();
    assert.deepEqual(closed.sort(), [1, 2]);
    assert.equal(host.sessionCount(), 0);
  } finally {
    await Promise.allSettled(clients.map((client) => client.close()));
    await host.close();
  }
});

test("revocation waits for admitted initialization and disposes its late runtime", async () => {
  let admitted!: () => void,
    finish!: (runtime: PokeMapServerRuntime) => void,
    closed = 0;
  const started = new Promise<void>((accept) => {
    admitted = accept;
  });
  const pending = new Promise<PokeMapServerRuntime>((accept) => {
    finish = accept;
  });
  let signal: AbortSignal | undefined;
  const host = await startPokeMapHttp({
    maxSessions: 1,
    createRuntime: (abort) => {
      signal = abort;
      admitted();
      return pending;
    },
  });
  const initialize = () =>
    fetch(host.url, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${host.token}`,
        "Content-Type": "application/json",
        Accept: "application/json, text/event-stream",
      },
      body: JSON.stringify({
        jsonrpc: "2.0",
        id: 1,
        method: "initialize",
        params: {
          protocolVersion: "2025-11-25",
          capabilities: {},
          clientInfo: { name: "late", version: "1" },
        },
      }),
    });
  try {
    const request = initialize();
    await started;
    assert.equal((await initialize()).status, 429);
    let revoked = false;
    const revocation = host.invalidateSessions().then(() => {
      revoked = true;
    });
    assert.equal(signal?.aborted, true);
    await Promise.resolve();
    assert.equal(revoked, false);
    finish({
      close: async () => {
        closed++;
      },
    } as PokeMapServerRuntime);
    assert.equal((await request).status, 503);
    await revocation;
    assert.equal(closed, 1);
    assert.equal(host.sessionCount(), 0);
  } finally {
    await host.close();
  }
});

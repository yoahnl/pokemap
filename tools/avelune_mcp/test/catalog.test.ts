import assert from "node:assert/strict";
import { tmpdir } from "node:os";
import { test } from "node:test";

import { Client } from "@modelcontextprotocol/client";
import { InMemoryTransport } from "@modelcontextprotocol/server";
import { serveStdio } from "@modelcontextprotocol/server/stdio";

import {
  AveluneController,
  type AveluneApi,
  type ControlState,
} from "../src/controller.js";
import { createAveluneMcpServer } from "../src/server.js";

test("publishes the complete Avelune control catalog", async () => {
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  const server = serveStdio(
    () =>
      createAveluneMcpServer(
        new AveluneController({ api: fakeApi(), allowedRoots: [tmpdir()] }),
      ),
    { legacy: "serve", transport: serverTransport },
  );
  const client = new Client(
    { name: "avelune-catalog-test", version: "1.0.0" },
    { versionNegotiation: { mode: { pin: "2026-07-28" } } },
  );
  try {
    await client.connect(clientTransport);
    const catalog = await client.listTools();
    assert.deepEqual(
      catalog.tools.map((tool) => tool.name),
      [
        "avelune_describe",
        "avelune_state",
        "avelune_install",
        "avelune_launch",
        "avelune_return_to_hub",
        "avelune_wait",
      ],
    );
    const result = await client.callTool({
      name: "avelune_describe",
      arguments: {},
    });
    assert.equal(result.isError, undefined);
    assert.equal(
      (result.structuredContent as { ok?: boolean } | undefined)?.ok,
      true,
    );
  } finally {
    await client.close();
    await server.close();
  }
});

function fakeApi(): AveluneApi {
  const state: ControlState = {
    protocolVersion: 1,
    dashboardStatus: "ready",
    surface: "hub",
    activeGameId: null,
    install: { generation: 0, status: "idle", message: null },
    games: [],
  };
  return {
    describe: async () => ({
      name: "Avelune Control API",
      protocolVersion: 1,
      capabilities: ["state", "install", "launch", "returnToHub"],
    }),
    state: async () => state,
    install: async () => state,
    launch: async () => state,
    returnToHub: async () => state,
  };
}

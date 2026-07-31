import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { resolve } from "node:path";
import { test } from "node:test";

import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import { InMemoryTransport } from "@modelcontextprotocol/server";
import { serveStdio } from "@modelcontextprotocol/server/stdio";

import { createCompatibilityServer } from "../src/compatibility_server.js";
import {
  FALLBACK_PROTOCOL_VERSION,
  MCP_COMPATIBILITY,
  MCP_SERVER_NAME,
  PREFERRED_PROTOCOL_VERSION,
} from "../src/protocol.js";

async function connectInMemory(mode: "modern" | "legacy") {
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  const server = serveStdio(createCompatibilityServer, {
    legacy: "serve",
    transport: serverTransport,
  });
  const client = new Client(
    { name: "pokemap-compatibility-test", version: "1.0.0" },
    mode === "modern"
      ? { versionNegotiation: { mode: { pin: PREFERRED_PROTOCOL_VERSION } } }
      : undefined,
  );

  await client.connect(clientTransport);

  return { client, server };
}

async function assertDiscoveryAndStructuredContent(client: Client): Promise<void> {
  const tools = await client.listTools();
  assert.deepEqual(
    tools.tools.map((tool) => tool.name),
    ["pokemap_protocol_probe"],
  );
  assert.ok(tools.tools[0]?.outputSchema);

  const result = await client.callTool({
    name: "pokemap_protocol_probe",
    arguments: {},
  });
  assert.equal(result.isError, undefined);
  assert.deepEqual(result.structuredContent, {
    server: MCP_SERVER_NAME,
    preferredProtocol: PREFERRED_PROTOCOL_VERSION,
    fallbackProtocol: FALLBACK_PROTOCOL_VERSION,
    selectedTransports: ["stdio"],
    jobMode: "pokemap_job",
  });

  const resources = await client.listResources();
  assert.deepEqual(
    resources.resources.map((resource) => resource.uri),
    ["pokemap://compatibility"],
  );
  const resource = await client.readResource({ uri: "pokemap://compatibility" });
  const content = resource.contents[0];
  assert.ok(content && "text" in content);
  assert.equal(content.mimeType, "application/json");
  assert.deepEqual(
    JSON.parse(content.text),
    MCP_COMPATIBILITY,
  );
}

test("official SDK negotiates 2026-07-28 and preserves structured content", async () => {
  const { client, server } = await connectInMemory("modern");
  try {
    assert.equal(client.getProtocolEra(), "modern");
    assert.equal(client.getNegotiatedProtocolVersion(), PREFERRED_PROTOCOL_VERSION);
    await assertDiscoveryAndStructuredContent(client);
  } finally {
    await client.close();
    await server.close();
  }
});

test("official SDK falls back to the documented 2025-11-25 handshake", async () => {
  const { client, server } = await connectInMemory("legacy");
  try {
    assert.equal(client.getProtocolEra(), "legacy");
    assert.equal(client.getNegotiatedProtocolVersion(), FALLBACK_PROTOCOL_VERSION);
    await assertDiscoveryAndStructuredContent(client);
  } finally {
    await client.close();
    await server.close();
  }
});

test("unsupported pinned protocol fails closed", async () => {
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  const server = serveStdio(createCompatibilityServer, {
    legacy: "serve",
    transport: serverTransport,
  });
  const client = new Client(
    { name: "pokemap-unsupported-version-test", version: "1.0.0" },
    { versionNegotiation: { mode: { pin: "2099-01-01" } } },
  );

  await assert.rejects(client.connect(clientTransport), /protocol|version/i);
  await client.close();
  await server.close();
});

test("the packaged stdio entrypoint completes a real modern client exchange", async () => {
  const projectRoot = resolve(
    process.cwd(),
    "../../examples/playable_runtime_host/golden_fangame_slice",
  );
  const transport = new StdioClientTransport({
    command: process.execPath,
    args: ["dist/src/index.js", "--root", projectRoot],
    cwd: process.cwd(),
    stderr: "pipe",
  });
  const client = new Client(
    { name: "pokemap-stdio-test", version: "1.0.0" },
    { versionNegotiation: { mode: { pin: PREFERRED_PROTOCOL_VERSION } } },
  );

  try {
    await client.connect(transport);
    assert.equal(client.getProtocolEra(), "modern");
    assert.equal(client.getNegotiatedProtocolVersion(), PREFERRED_PROTOCOL_VERSION);
    const tools = await client.listTools();
    assert.deepEqual(
      tools.tools.map((tool) => tool.name),
      [
        "pokemap_artifact",
        "pokemap_describe",
        "pokemap_query",
        "pokemap_validate",
        "pokemap_workspace",
        "pokemap_plan",
        "pokemap_apply",
        "pokemap_history",
        "pokemap_recovery",
        "pokemap_render",
        "pokemap_playtest",
        "pokemap_job",
      ],
    );
    const described = await client.callTool({
      name: "pokemap_describe",
      arguments: {},
    });
    assert.equal(described.isError, undefined);
    assert.equal(
      (described.structuredContent as { ok?: boolean } | undefined)?.ok,
      true,
    );
  } finally {
    await client.close();
  }
});

test("Tasks remain disabled until the official 2026 extension API is stable", () => {
  assert.equal(MCP_COMPATIBILITY.jobs.mode, "pokemap_job");
  assert.match(MCP_COMPATIBILITY.jobs.reason, /no stable.*Tasks extension/i);
});

test("the packaged entrypoint refuses missing roots without protocol noise", () => {
  const result = spawnSync(process.execPath, ["dist/src/index.js"], {
    cwd: process.cwd(),
    encoding: "utf8",
  });
  assert.equal(result.status, 64);
  assert.equal(result.stdout, "");
  assert.equal(
    result.stderr,
    "[pokemap-mcp] At least one --root option is required.\n",
  );
});

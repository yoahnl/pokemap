import assert from "node:assert/strict";
import { test } from "node:test";
import { PassThrough } from "node:stream";
import { createServer } from "node:net";
import {
  Client,
  StreamableHTTPClientTransport,
} from "@modelcontextprotocol/client";
import { parseConfig } from "../src/config.js";
import { startStudioCompanion } from "../src/studio_companion.js";
import { MemoryArtifactReader } from "../src/artifacts.js";
import { createPokeMapMcpServer } from "../src/server.js";
import type { PokeMapServerRuntime } from "../src/server_runtime.js";
import type { RuntimeGateway } from "../src/runtime_gateway.js";
import type { JsonRecord } from "../src/authoring_client.js";

function channel() {
  const input = new PassThrough(),
    output = new PassThrough();
  const events: Record<string, unknown>[] = [];
  const waiters = new Set<() => void>();
  let pending = "";
  output.on("data", (chunk) => {
    pending += chunk.toString();
    for (let end; (end = pending.indexOf("\n")) >= 0;) {
      events.push(JSON.parse(pending.slice(0, end)));
      pending = pending.slice(end + 1);
    }
    for (const waiter of waiters) waiter();
  });
  return {
    input,
    output,
    events,
    send: (value: unknown) => input.write(`${JSON.stringify(value)}\n`),
    wait: async (predicate: (value: Record<string, unknown>) => boolean) => {
      const existing = events.find(predicate);
      if (existing) return existing;
      return new Promise<Record<string, unknown>>((accept, reject) => {
        const timer = setTimeout(() => {
          waiters.delete(check);
          reject(Error("Control response timed out."));
        }, 2000);
        const check = () => {
          const value = events.find(predicate);
          if (value) {
            clearTimeout(timer);
            waiters.delete(check);
            accept(value);
          }
        };
        waiters.add(check);
      });
    },
  };
}

function runtime(
  data: () => JsonRecord | Promise<JsonRecord>,
  onClose: () => void = () => {},
): PokeMapServerRuntime {
  const authoring = {
    resolveProjectRoot: () => "/fixture",
    close: async () => onClose(),
    request: async () => ({
      requestId: "describe",
      data: await data(),
      artifacts: [],
    }),
  };
  return {
    authoring,
    runtime: {} as RuntimeGateway,
    close: authoring.close,
    createServer: (protocolVersions) =>
      createPokeMapMcpServer({
        authoring,
        artifacts: new MemoryArtifactReader(),
        ...(protocolVersions ? { protocolVersions } : {}),
      }),
  };
}

test("companion announces an initialized endpoint and revokes sessions when the project changes", async () => {
  const control = channel();
  const seen: string[][] = [];
  let closed = 0;
  const service = await startStudioCompanion(
    parseConfig(["--transport", "http", "--companion", "true"]),
    {
      ...control,
      createRuntime: (config) => {
        seen.push([...config.allowedRoots]);
        return runtime(
          () => ({ roots: config.allowedRoots }),
          () => {
            closed++;
          },
        );
      },
    },
  );
  const ready = await control.wait((event) => event.type === "ready");
  assert.deepEqual(ready.protocolVersions, ["2025-11-25"]);
  const client = new Client(
    { name: "studio-bootstrap-test", version: "1" },
    { versionNegotiation: { mode: "legacy" } },
  );
  try {
    await client.connect(
      new StreamableHTTPClientTransport(new URL(ready.url as string), {
        requestInit: { headers: { Authorization: `Bearer ${ready.token}` } },
      }),
    );
    const result = await client.callTool({
      name: "pokemap_describe",
      arguments: {},
    });
    assert.deepEqual(
      (result.structuredContent as { data: { roots: string[] } }).data.roots,
      [],
    );
    control.send({ id: "grant", command: "set_roots", roots: ["/fixture"] });
    assert.equal(
      (await control.wait((event) => event.id === "grant")).ok,
      true,
    );
    await assert.rejects(
      client.callTool({ name: "pokemap_describe", arguments: {} }),
    );
    assert.equal(closed, 3);
    control.send({ id: "broad", command: "set_roots", roots: ["/"] });
    const rejected = await control.wait((event) => event.id === "broad");
    assert.equal(rejected.ok, false);
    assert.equal(rejected.code, "control.root_invalid");
    assert.deepEqual(seen, [[], [], ["/fixture"]]);
  } finally {
    await client.close();
    await service.close();
    control.input.destroy();
    control.output.destroy();
  }
  assert.equal(closed, 3);
});

for (const stop of ["abort", "shutdown", "eof"] as const) {
  test(`${stop} while initializing closes the probe and never publishes ready`, async () => {
    const control = channel(),
      signal = new AbortController();
    let entered!: () => void,
      rejectProbe!: (error: Error) => void,
      closed = 0;
    const running = new Promise<void>((accept) => {
      entered = accept;
    });
    const probe = new Promise<never>((_, reject) => {
      rejectProbe = reject;
    });
    const starting = startStudioCompanion(
      parseConfig(["--transport", "http", "--companion", "true"]),
      {
        ...control,
        signal: signal.signal,
        createRuntime: () =>
          runtime(
            () => {
              entered();
              return probe;
            },
            () => {
              closed++;
              rejectProbe(Error("closed"));
            },
          ),
      },
    );
    const rejected = assert.rejects(starting);
    await running;
    if (stop === "abort") signal.abort();
    else if (stop === "shutdown")
      control.send({ id: "stop", command: "shutdown" });
    else control.input.end();
    await rejected;
    if (stop === "shutdown")
      assert.equal(
        (await control.wait((event) => event.id === "stop")).ok,
        true,
      );
    assert.equal(closed, 1);
    assert.equal(
      control.events.some((event) => event.type === "ready"),
      false,
    );
    control.input.destroy();
    control.output.destroy();
  });
}

test("an occupied port fails without adopting or stopping its owner", async () => {
  const occupied = createServer();
  await new Promise<void>((accept) => occupied.listen(0, "127.0.0.1", accept));
  const address = occupied.address();
  assert.ok(address && typeof address !== "string");
  const control = channel();
  let closed = 0;
  try {
    await assert.rejects(
      startStudioCompanion(
        parseConfig([
          "--transport",
          "http",
          "--companion",
          "true",
          "--port",
          String(address.port),
        ]),
        {
          ...control,
          createRuntime: () =>
            runtime(
              () => ({}),
              () => {
                closed++;
              },
            ),
        },
      ),
      /EADDRINUSE/,
    );
    assert.equal(closed, 1);
    assert.equal(occupied.listening, true);
    assert.equal(
      control.events.some((event) => event.type === "ready"),
      false,
    );
  } finally {
    control.input.destroy();
    control.output.destroy();
    await new Promise<void>((accept) => occupied.close(() => accept()));
  }
});

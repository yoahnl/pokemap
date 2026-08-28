import assert from "node:assert/strict";
import { mkdtemp, writeFile } from "node:fs/promises";
import { createServer } from "node:http";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";

import { HttpAveluneApiClient } from "../src/api_client.js";
import { AveluneMcpError } from "../src/controller.js";

test("authenticates loopback API requests and preserves domain errors", async () => {
  const server = createServer((request, response) => {
    assert.equal(request.headers.authorization, "Bearer control-token");
    response.setHeader("content-type", "application/json");
    if (request.url === "/v1/state") {
      response.end(
        JSON.stringify({
          protocolVersion: 1,
          dashboardStatus: "ready",
          surface: "hub",
          activeGameId: null,
          install: { generation: 0, status: "idle", message: null },
          games: [],
        }),
      );
      return;
    }
    response.statusCode = 404;
    response.end(
      JSON.stringify({ code: "gameNotFound", message: "Missing game." }),
    );
  });
  await new Promise<void>((resolve) => server.listen(0, "127.0.0.1", resolve));
  const address = server.address();
  assert.ok(address && typeof address !== "string");
  const client = new HttpAveluneApiClient(async () => ({
    apiUrl: `http://127.0.0.1:${address.port}`,
    token: "control-token",
    bundleId: "app.pokemap.hub",
  }));
  try {
    assert.equal((await client.state()).dashboardStatus, "ready");
    await assert.rejects(
      () => client.launch("missing"),
      (error: unknown) =>
        error instanceof AveluneMcpError && error.code === "gameNotFound",
    );
  } finally {
    await new Promise<void>((resolve, reject) =>
      server.close((error) => (error ? reject(error) : resolve())),
    );
  }
});

test("streams a package to the authenticated install endpoint", async () => {
  const expected = Buffer.from("controlled-package");
  let uploaded = Buffer.alloc(0);
  const server = createServer(async (request, response) => {
    assert.equal(request.method, "POST");
    assert.equal(
      request.url,
      "/v1/install?filename=controlled.avelunegame",
    );
    assert.equal(request.headers.authorization, "Bearer control-token");
    const chunks: Buffer[] = [];
    for await (const chunk of request) chunks.push(Buffer.from(chunk));
    uploaded = Buffer.concat(chunks);
    response.setHeader("content-type", "application/json");
    response.end(
      JSON.stringify({
        protocolVersion: 1,
        dashboardStatus: "ready",
        surface: "hub",
        activeGameId: null,
        install: { generation: 1, status: "succeeded", message: null },
        games: [],
      }),
    );
  });
  await new Promise<void>((resolve) => server.listen(0, "127.0.0.1", resolve));
  const address = server.address();
  assert.ok(address && typeof address !== "string");
  const root = await mkdtemp(join(tmpdir(), "avelune-api-client-"));
  const packagePath = join(root, "controlled.avelunegame");
  await writeFile(packagePath, expected);
  const client = new HttpAveluneApiClient(async () => ({
    apiUrl: `http://127.0.0.1:${address.port}`,
    token: "control-token",
    bundleId: "app.pokemap.hub",
  }));
  try {
    const result = await client.install(packagePath, 5_000);
    assert.equal(result.install.status, "succeeded");
    assert.deepEqual(uploaded, expected);
  } finally {
    await new Promise<void>((resolve, reject) =>
      server.close((error) => (error ? reject(error) : resolve())),
    );
  }
});

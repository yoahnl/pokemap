import assert from "node:assert/strict";
import { chmod, mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";

import { MemoryArtifactReader } from "../src/artifacts.js";
import { LocalRuntimeGateway } from "../src/runtime_gateway.js";
import { PokeMapToolError } from "../src/tool_error.js";
import { failureEnvelope } from "../src/tools/result.js";

const request = {
  projectHandle: "project-test",
  mapId: "map-test",
  layerIds: [],
  overlays: [],
  cellPixelSize: 8,
};

async function fixture(body: string) {
  const root = await mkdtemp(join(tmpdir(), "pokemap-render-diagnostic-test-"));
  const executable = join(root, "worker.cjs");
  await writeFile(executable, `#!${process.execPath}\n${body}\n`);
  await chmod(executable, 0o700);
  const artifacts = new MemoryArtifactReader();
  const gateway = new LocalRuntimeGateway({
    roots: { resolveProjectRoot: () => root },
    artifacts,
    runtimePackageRoot: root,
    runtimeHostRoot: root,
    repositoryRoot: root,
    flutterExecutable: executable,
  });
  return {
    gateway,
    artifacts,
    async dispose() {
      await gateway.close();
      await rm(root, { recursive: true, force: true });
    },
  };
}

for (const scenario of [
  {
    name: "asset failure on stderr",
    stream: "stderr",
    output: "Unable to load asset: /Users/private/project/secret.png\nAPI_KEY=top-secret\n#0 Secret.load (file:///private/source.dart:42)",
    cause: "asset_load_failed",
    truncated: false,
  },
  {
    name: "compilation failure on stdout",
    stream: "stdout",
    output: "Compiler failed at C:\\Users\\private\\secret.dart\nAuthorization: Bearer top-secret\nFailed to compile the application.",
    cause: "compilation_failed",
    truncated: false,
  },
  {
    name: "unrecognized oversized stderr",
    stream: "stderr",
    output: "password=top-secret\n".repeat(5000),
    cause: "unclassified_worker_failure",
    truncated: true,
  },
] as const) {
  test(`render preserves a safe bounded diagnostic for ${scenario.name}`, {
    skip: process.platform === "win32",
  }, async () => {
    const f = await fixture(`process.${scenario.stream}.write(${JSON.stringify(scenario.output)}); process.exitCode = 7;`);
    try {
      let previousTrace: string | undefined;
      for (let attempt = 0; attempt < 2; attempt++) {
        await assert.rejects(f.gateway.render(request), (error: unknown) => {
          assert.ok(error instanceof PokeMapToolError);
          assert.equal(error.code, "render.worker_failed");
          assert.equal(error.retryable, true);
          assert.equal(error.details.exitCode, 7);
          assert.equal(error.details.signal, null);
          assert.match(String(error.details.traceId), /^[0-9a-f-]{36}$/u);
          assert.notEqual(error.details.traceId, previousTrace);
          previousTrace = String(error.details.traceId);
          const diagnostic = error.details.workerDiagnostic as Record<string, unknown>;
          assert.equal(diagnostic.cause, scenario.cause);
          assert.equal(diagnostic.source, scenario.stream);
          assert.equal(diagnostic.truncated, scenario.truncated);
          assert.equal(typeof diagnostic.summary, "string");
          const envelope = JSON.stringify(failureEnvelope(error));
          assert.ok(Buffer.byteLength(envelope) < 2048);
          for (const forbidden of ["top-secret", "/Users/", "/private/", "C:\\Users", "#0", "Authorization", "password", "API_KEY"]) {
            assert.ok(!envelope.includes(forbidden), forbidden);
          }
          return true;
        });
      }
    } finally {
      await f.dispose();
    }
  });
}

test("render reports a terminated worker without exposing its output", {
  skip: process.platform === "win32",
}, async () => {
  const f = await fixture("process.kill(process.pid, 'SIGTERM');");
  try {
    await assert.rejects(f.gateway.render(request), (error: unknown) => {
      assert.ok(error instanceof PokeMapToolError);
      assert.equal(error.code, "render.worker_failed");
      assert.equal(error.details.signal, "SIGTERM");
      assert.equal(error.details.exitCode, null);
      assert.match(String(error.details.traceId), /^[0-9a-f-]{36}$/u);
      return true;
    });
  } finally {
    await f.dispose();
  }
});

test("successful render still returns its exact envelope and artifact bytes", {
  skip: process.platform === "win32",
}, async () => {
  const response = {
    status: "success",
    data: { width: 8, height: 8, snapshotRevision: "unchanged" },
    artifact: { uri: "artifact://sha256/test-render", mediaType: "image/png", id: "render-map-test" },
    blob: Buffer.from("exact PNG bytes").toString("base64"),
  };
  const f = await fixture(`const fs = require('node:fs');
const argument = process.argv.find(value => value.startsWith('--dart-define=POKEMAP_RENDER_RESPONSE_PATH='));
fs.writeFileSync(argument.slice(argument.indexOf('=') + 1).slice('POKEMAP_RENDER_RESPONSE_PATH='.length), JSON.stringify(${JSON.stringify(response)}));
process.stderr.write(${JSON.stringify("password=top-secret\n")});`);
  try {
    assert.deepEqual(await f.gateway.render(request), {
      data: response.data,
      artifacts: [response.artifact],
    });
    assert.equal((await f.artifacts.read(response.artifact.uri)).blob, response.blob);
  } finally {
    await f.dispose();
  }
});

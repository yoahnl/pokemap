import assert from "node:assert/strict";
import { chmod, mkdir, mkdtemp, rm, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";

import { AuthoringClientError, LocalAuthoringClient } from "../src/authoring_client.js";

const qaRoot = join(homedir(), "Library/Caches/AveluneQA/mcp-studio-integration/i0");

async function workerFixture() {
  await mkdir(qaRoot, { recursive: true });
  const root = await mkdtemp(join(qaRoot, "pokemap-worker-process-id-"));
  const executable = join(root, "worker");
  await writeFile(executable, `#!/usr/bin/env node
const { createInterface } = require("node:readline");
const lines = createInterface({ input: process.stdin });
lines.on("line", (line) => {
  const request = JSON.parse(line);
  if (request.command === "exit") {
    process.exit(0);
  }
  if (request.command === "signal") {
    process.kill(process.pid, "SIGTERM");
    return;
  }
  process.stdout.write(JSON.stringify({ requestId: request.id, status: "success", data: { pid: process.pid }, artifacts: [] }) + "\\n");
});
`);
  await chmod(executable, 0o700);
  const client = new LocalAuthoringClient({
    allowedRoots: [root], authoringPackageRoot: root, dartExecutable: executable,
  });
  return { client, root };
}

test("packaged authoring command preserves arguments and never invokes Dart", async (t) => {
  await mkdir(qaRoot, { recursive: true });
  const root = await mkdtemp(join(qaRoot, "worker été "));
  t.after(() => rm(root, { recursive: true, force: true }));
  const script = join(root, "worker.mjs");
  await writeFile(script, `import { createInterface } from "node:readline";
createInterface({ input: process.stdin }).on("line", (line) => {
  const request = JSON.parse(line);
  process.stdout.write(JSON.stringify({ requestId: request.id, status: "success", data: { args: process.argv.slice(2), cwd: process.cwd() }, artifacts: [] }) + "\\n");
});`);
  const client = new LocalAuthoringClient({
    allowedRoots: [root],
    dartExecutable: join(root, "absent-dart"),
    workerCommand: { executable: process.execPath, args: [script], cwd: root },
  });
  t.after(() => client.close());
  const result = await client.request("describe");
  assert.equal(result.data.cwd, root);
  assert.deepEqual((result.data.args as string[]).slice(0, 2), ["--root", root]);
  assert.ok(!(result.data.args as string[]).includes("bin/pokemap_authoring.dart"));
});

test("discovery without roots is explicit and rejects file access before starting a worker", async () => {
  assert.throws(() => new LocalAuthoringClient({ allowedRoots: [], authoringPackageRoot: qaRoot }), AuthoringClientError);
  for (const options of [{ allowedRoots: [qaRoot] }, { allowedRoots: [], artifactRoots: [qaRoot] }, { allowedRoots: [], exportRoots: [qaRoot] }]) {
    assert.throws(() => new LocalAuthoringClient({ ...options, authoringPackageRoot: qaRoot, discoveryOnly: true }), AuthoringClientError);
  }
  const client = new LocalAuthoringClient({ allowedRoots: [], authoringPackageRoot: qaRoot, discoveryOnly: true });
  await assert.rejects(client.request("open", { projectRoot: qaRoot }), (error: unknown) => {
    assert.ok(error instanceof AuthoringClientError);
    assert.equal(error.code, "workspace.path_outside_allowed_roots");
    return true;
  });
  assert.equal(client.workerProcessId, undefined);
  await client.close();
});

test("packaged authoring commands reject relative executables and working directories", () => {
  for (const command of [
    { executable: "dart", args: [], cwd: qaRoot },
    { executable: process.execPath, args: [], cwd: "." },
  ]) {
    assert.throws(() => new LocalAuthoringClient({ allowedRoots: [qaRoot], workerCommand: command }), AuthoringClientError);
  }
});

test("worker process ID is passive, identifies the direct worker and clears during close", async () => {
  const { client, root } = await workerFixture();
  try {
    assert.equal(client.workerProcessId, undefined);
    assert.equal(client.workerProcessId, undefined);
    await client.close();
    assert.equal(client.workerProcessId, undefined);
    const response = await client.request("describe");
    const pid = response.data.pid;
    assert.equal(typeof pid, "number");
    assert.notEqual(pid, process.pid);
    assert.equal(client.workerProcessId, pid);
    assert.equal(client.workerProcessId, pid);
    const closing = client.close();
    assert.equal(client.workerProcessId, undefined);
    await closing;
    assert.equal(client.workerProcessId, undefined);
    await client.close();
    assert.equal(client.workerProcessId, undefined);
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

for (const command of ["exit", "signal"]) {
  test(`worker process ID clears when the worker ends by ${command}`, async () => {
    const { client, root } = await workerFixture();
    try {
      const response = await client.request("describe");
      assert.equal(client.workerProcessId, response.data.pid);
      await assert.rejects(client.request(command), (error: unknown) => {
        assert.ok(error instanceof AuthoringClientError);
        assert.equal(error.code, "worker.exited");
        if (command === "exit") {
          assert.equal(error.details.exitCode, 0);
        } else {
          assert.equal(error.details.exitCode, undefined);
        }
        return true;
      });
      assert.equal(client.workerProcessId, undefined);
    } finally {
      await client.close();
      await rm(root, { recursive: true, force: true });
    }
  });
}

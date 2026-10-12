import assert from "node:assert/strict";
import { chmod, mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";

import { AuthoringClientError, LocalAuthoringClient } from "../src/authoring_client.js";

async function workerFixture() {
  const root = await mkdtemp(join(tmpdir(), "pokemap-worker-process-id-"));
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

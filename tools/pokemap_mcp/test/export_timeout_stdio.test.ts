import assert from "node:assert/strict";
import { chmod, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";

for (const customized of [false, true]) {
  test(`packaged CLI propagates independent export and ordinary deadlines: ${customized ? "explicit" : "defaults"}`, async () => {
    const root = await mkdtemp(join(tmpdir(), "pokemap-cli-export-timeout-"));
    const executable = join(root, "worker");
    const timerLog = join(root, "timers.jsonl");
    const preload = join(root, "timer-probe.mjs");
    await writeFile(preload, `import { appendFileSync } from "node:fs";
const original = globalThis.setTimeout;
globalThis.setTimeout = function (callback, delay, ...args) {
  appendFileSync(${JSON.stringify(timerLog)}, JSON.stringify(delay) + "\\n");
  return original(callback, delay, ...args);
};
`);
    await writeFile(executable, `#!/usr/bin/env node
const { createInterface } = require("node:readline");
createInterface({ input: process.stdin }).on("line", (line) => {
  const request = JSON.parse(line);
  process.stdout.write(JSON.stringify({ requestId: request.id, status: "success", data: { argv: process.argv.slice(2), command: request.command }, artifacts: [] }) + "\\n");
});
`);
    await chmod(executable, 0o700);
    const args = ["--import", preload, resolve("dist/src/index.js"), "--root", root, "--dart", executable];
    if (customized) args.push("--export-timeout-ms", "600000", "--authoring-timeout-ms", "60000");
    const client = new Client({ name: "cli-export-deadline", version: "1.0.0" });
    const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
    try {
      await client.connect(transport);
      const ordinary = await client.callTool({ name: "pokemap_describe", arguments: {} });
      const native = await client.callTool({ name: "pokemap_project_native_prepare", arguments: {
        source: { descriptorPath: join(root, "descriptor.json"), sha256: "0".repeat(64), byteLength: 1 },
      } });
      for (const result of [ordinary, native]) {
        const envelope = result.structuredContent as { ok: boolean; data: { argv: string[] } };
        assert.equal(envelope.ok, true, JSON.stringify(result));
        const workerArgs = envelope.data.argv;
        assert.equal(workerArgs[workerArgs.indexOf("--timeout-ms") + 1], customized ? "60000" : "10000");
        assert.equal(workerArgs[workerArgs.indexOf("--export-timeout-ms") + 1], customized ? "600000" : "120000");
        assert.equal(workerArgs.filter((arg) => arg === "--root").length, 1);
        assert.equal(workerArgs[workerArgs.indexOf("--root") + 1], root);
      }
      const delays = (await readFile(timerLog, "utf8")).trim().split("\n").map(Number);
      assert.ok(delays.includes(customized ? 65000 : 15000), JSON.stringify(delays));
      assert.ok(delays.includes(customized ? 605000 : 125000), JSON.stringify(delays));
    } finally {
      await client.close();
      await transport.close();
      await rm(root, { recursive: true, force: true });
    }
  });
}

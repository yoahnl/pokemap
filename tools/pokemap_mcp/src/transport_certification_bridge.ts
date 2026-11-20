import assert from "node:assert/strict";
import { resolve } from "node:path";
import { createInterface } from "node:readline";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";

import type { JsonRecord } from "./authoring_client.js";

function command(name: string, args: JsonRecord): [string, JsonRecord] {
  switch (name) {
    case "open":
    case "close":
      return ["pokemap_workspace", { operation: name, ...args }];
    case "workshop_snapshot":
      return ["pokemap_workshop", { operation: "read", ...args }];
    case "stage_artifact":
      return ["pokemap_artifact_stage", args];
    case "query":
      return ["pokemap_query", { ...record(args.request), projectHandle: args.projectHandle }];
    case "plan":
      return ["pokemap_plan", args];
    case "confirm":
    case "apply":
      return ["pokemap_apply", { operation: name, ...args }];
    default:
      throw new Error("Unknown certification command " + name);
  }
}

function record(value: unknown): JsonRecord {
  assert.ok(value !== null && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

async function main(): Promise<void> {
  const [server, project, authoringPackage, dart] = process.argv.slice(2);
  assert.ok(server && project && authoringPackage && dart);
  const transport = new StdioClientTransport({
    command: process.execPath,
    args: [resolve(server), "--root", project, "--authoring-package", authoringPackage, "--dart", dart, "--authoring-timeout-ms", "120000"],
    cwd: process.cwd(),
    stderr: "pipe",
  });
  transport.stderr?.pipe(process.stderr);
  const client = new Client({ name: "pmcp085-transport-certifier", version: "1" });
  try {
    await client.connect(transport);
    const input = createInterface({ input: process.stdin, terminal: false });
    try {
      for await (const line of input) {
        const request = record(JSON.parse(line));
        const [name, args] = command(String(request.command), record(request.args));
        const response = await client.callTool({ name, arguments: args });
        const envelope = record(response.structuredContent);
        assert.equal(response.isError === true, envelope.ok !== true);
        process.stdout.write(JSON.stringify({ id: request.id, ...envelope }) + "\n");
      }
    } finally {
      input.close();
    }
  } finally {
    try {
      await client.close();
    } finally {
      await transport.close();
    }
  }
}

void main().catch((error: unknown) => {
  process.stderr.write(String(error) + "\n");
  process.exitCode = 1;
});

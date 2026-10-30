import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { rm, rmdir } from "node:fs/promises";
import { resolve } from "node:path";
import { promisify } from "node:util";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../../src/authoring_client.js";

const execute = promisify(execFile);
const qaRoot = "/Users/karim/Library/Caches/AveluneQA/mcp-map-reliability/r3";

export function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

export async function reliabilityStdio(variant: string, storage: "classic" | "catalog") {
  const generated = await execute(process.env.POKEMAP_TEST_DART ?? "dart", [
    "run", "test/support/create_reliability_transport_fixture.dart", variant, storage,
  ], { cwd: resolve("../../packages/map_authoring"), maxBuffer: 2 * 1024 * 1024 });
  const fixture = record(JSON.parse(generated.stdout.trim().split("\n").at(-1)!));
  const root = String(fixture.root);
  assert.ok(root.startsWith(`${qaRoot}/`));
  const args = [resolve("dist/src/index.js"), "--profile", "map-builder", "--root", root];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  const transport = new StdioClientTransport({ command: process.execPath, args,
    cwd: process.cwd(), stderr: "pipe" });
  const client = new Client({ name: "map-reliability-stdio", version: "1" });
  let connected = false;
  async function call(name: string, input: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    assert.equal(connected, true);
    const result = await client.callTool({name, arguments: input});
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, !failure, `${name}: ${JSON.stringify(envelope)}`);
    assert.equal(result.isError === true, failure);
    return record(failure ? envelope.error : envelope.data);
  }
  async function close(): Promise<void> {
    try { await client.close(); } finally { await transport.close(); }
    await rm(root, {recursive: true, force: true});
    try { await rmdir(qaRoot); }
    catch (error) { if (!["ENOENT", "ENOTEMPTY"].includes(String((error as NodeJS.ErrnoException).code))) throw error; }
  }
  try {
    await client.connect(transport);
    connected = true;
    return {client, call, close, fixture, root};
  } catch (error) {
    await close();
    throw error;
  }
}

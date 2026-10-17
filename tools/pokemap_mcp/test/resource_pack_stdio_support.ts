import assert from "node:assert/strict";
import { watch } from "node:fs";
import { access, chmod, mkdir, writeFile } from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";

export function packRecord(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

export async function connectPackMcp(root: string, dart?: string) {
  const client = new Client({ name: "resource-pack-lifecycle", version: "1.0.0" });
  try {
    await client.connect(new StdioClientTransport({ command: process.execPath,
    args: ["dist/src/index.js", "--root", root, ...(dart ? ["--dart", dart] : [])],
    ...(process.env.POKEMAP_RESOURCE_PACK_TEST_WORKER ? {
      env: { POKEMAP_RESOURCE_PACK_TEST_WORKER: process.env.POKEMAP_RESOURCE_PACK_TEST_WORKER },
    } : {}),
    cwd: process.cwd(), stderr: "pipe" }));
  } catch (error) { await client.close(); throw error; }
  async function call(name: string, args: JsonRecord = {}, error?: string): Promise<JsonRecord> {
    const response = await client.callTool({ name, arguments: args });
    if (name === "pokemap_resource_pack" || name === "pokemap_query") {
      assert.ok(Buffer.byteLength(JSON.stringify({ jsonrpc: "2.0", id: "x".repeat(128), result: response }), "utf8") <= 256 * 1024);
    }
    assert.equal(Boolean(response.isError), error !== undefined, JSON.stringify(response.structuredContent));
    const envelope = packRecord(response.structuredContent);
    if (error !== undefined) {
      const failure = packRecord(envelope.error);
      assert.equal(failure.domainCode ?? failure.code, error);
      return failure;
    }
    return packRecord(envelope.data);
  }
  function pack(opened: JsonRecord, verb: string, input: JsonRecord = {}, error?: string) {
    return call("pokemap_resource_pack", { projectHandle: opened.projectHandle, verb, input }, error);
  }
  async function poll(opened: JsonRecord, start: JsonRecord) {
    for (let i = 0; i < 3000; i++) {
      const state = await pack(opened, "get", { jobId: start.jobId });
      if (["succeeded", "failed", "cancelled"].includes(String(packRecord(state.snapshot).state))) return state;
      await new Promise((done) => setTimeout(done, 1));
    }
    throw new Error("The resource pack job did not settle.");
  }
  async function result(opened: JsonRecord, start: JsonRecord) {
    const state = await poll(opened, start);
    assert.equal(packRecord(state.snapshot).state, "succeeded", JSON.stringify(state));
    return packRecord(state.result);
  }
  async function plan(opened: JsonRecord, key: string): Promise<JsonRecord> {
    const staged = await result(opened, await pack(opened, "stage", { sourcePath: join(root, "source.aveluneassets") }));
    const inspected = await result(opened, await pack(opened, "inspect", { archiveHandle: staged.archiveHandle }));
    const selected = await pack(opened, "selection.create", { mode: "archive", inspectionHandle: inspected.inspectionHandle });
    const chosen = await pack(opened, "selection.select_filtered", { selectionHandle: selected.selectionHandle,
      revision: selected.revision, filter: { kind: "element" } });
    const validated = await call("pokemap_validate", { projectHandle: opened.projectHandle });
    const prepared = await result(opened, await pack(opened, "prepare", { selectionHandle: chosen.selectionHandle,
      revision: chosen.revision, expectedRevision: validated.snapshotRevision }));
    const planned = await call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
      requestId: key, actionId: "resource_pack.import", actionVersion: 1, workspaceHandle: opened.workspaceHandle,
      expectedRevision: validated.snapshotRevision, parameters: { preparedImportHandle: prepared.preparedImportHandle },
      idempotencyKey: key,
    } });
    return { ...planned, inspection: inspected, selection: chosen, prepared };
  }
  async function history(opened: JsonRecord, operation: string, entryId: unknown, operationId: string, expectedHeadEntryId?: unknown) {
    const validated = await call("pokemap_validate", { projectHandle: opened.projectHandle });
    return result(opened, await pack(opened, "start_history", { operation, entryId, operationId,
      expectedRevision: validated.snapshotRevision, ...(expectedHeadEntryId ? { expectedHeadEntryId } : {}) }));
  }
  return { client, call, pack, poll, result, plan, history, close: () => client.close() };
}

export async function controlledPackDart(root: string) {
  const path = join(root, "controlled-dart.cjs");
  const worker = resolve("../../packages/map_authoring/test/support/resource_pack_controlled_jsonl_worker.dart");
  await writeFile(path, `#!/usr/bin/env node\nconst {spawn}=require('node:child_process');\nconst binary=process.env.POKEMAP_RESOURCE_PACK_TEST_WORKER;\nconst child=spawn(binary||'dart',binary?process.argv.slice(4):['run',${JSON.stringify(worker)},...process.argv.slice(4)],{stdio:'inherit'});\nprocess.on('SIGTERM',()=>child.kill('SIGTERM'));\nprocess.on('SIGINT',()=>child.kill('SIGINT'));\nchild.on('error',()=>process.exit(1));\nchild.on('exit',code=>process.exit(code??1));\n`);
  await chmod(path, 0o700);
  return path;
}

export class PackTestGate {
  readonly directory: string;
  constructor(root: string) { this.directory = join(root, ".p09-resource-pack-control"); }
  async arm(id: string, operationId: string, checkpoint: string, crash = false) {
    await mkdir(this.directory, { recursive: true });
    await writeFile(join(this.directory, "request.json"), JSON.stringify({ id, operationId, checkpoint, crash }));
  }
  entered(id: string) { return waitForPackFile(join(this.directory, `entered-${id}`)); }
  async release(id: string) {
    await mkdir(this.directory, { recursive: true });
    await writeFile(join(this.directory, `release-${id}`), "release");
  }
}

async function waitForPackFile(path: string) {
  await new Promise<void>((done, reject) => {
    const watcher = watch(dirname(path), () => { void access(path).then(() => finish(), () => {}); });
    const timer = setTimeout(() => finish(new Error("The test checkpoint was not reached.")), 20_000);
    let settled = false;
    function finish(error?: Error) {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      watcher.close();
      if (error) reject(error); else done();
    }
    watcher.on("error", finish);
    void access(path).then(() => finish(), () => {});
  });
}

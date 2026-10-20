import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { test } from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

function contains(actual: unknown, expected: unknown): void {
  if (Array.isArray(expected)) {
    assert.ok(Array.isArray(actual));
    assert.equal(actual.length, expected.length);
    expected.forEach((value, index) => contains(actual[index], value));
  } else if (expected && typeof expected === "object") {
    const object = record(actual);
    for (const [key, value] of Object.entries(expected)) contains(object[key], value);
  } else {
    assert.deepEqual(actual, expected);
  }
}

test("live MCP certifies the shared nine-action Event V2 cycle and atomic refusals", { timeout: 120_000 }, async () => {
  const fixturePath = resolve("../../packages/map_authoring/test/fixtures/event_v2_transport_parity.json");
  const fixtureBytes = await readFile(fixturePath);
  const fixture = record(JSON.parse(fixtureBytes.toString("utf8")));
  assert.equal(fixture.formatVersion, 1);
  const project = record(fixture.project);
  const maps = fixture.maps as JsonRecord[];
  const operations = fixture.operations as JsonRecord[];
  const refusals = fixture.refusals as JsonRecord[];
  const expectedActions = fixture.expectedActionIds as string[];
  const root = await mkdtemp(join(tmpdir(), "event-v2-parity-mcp-"));
  const manifest = join(root, "project.json");
  await writeFile(manifest, JSON.stringify(project));
  for (const map of maps) {
    const path = join(root, String(map.relativePath));
    await mkdir(dirname(path), { recursive: true });
    await writeFile(path, JSON.stringify(map.content));
  }
  const beforeMaps = await Promise.all(maps.map(map => readFile(join(root, String(map.relativePath)))));
  let active: { client: Client; transport: StdioClientTransport } | undefined;
  let workspace: JsonRecord | undefined;
  let sequence = 0;
  let stderr = "";

  async function connect(): Promise<void> {
    const args = [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"];
    if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
    const client = new Client({ name: "event-v2-parity-test", version: "1.0.0" });
    const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
    stderr = "";
    transport.stderr?.on("data", chunk => { stderr = (stderr + String(chunk)).slice(-8000); });
    active = { client, transport };
    await client.connect(transport);
  }

  async function call(name: string, input: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    assert.ok(active);
    try {
      const result = await active.client.callTool({ name, arguments: input });
      const envelope = record(result.structuredContent);
      assert.equal(envelope.ok, !failure, JSON.stringify({ name, envelope }));
      return record(envelope[failure ? "error" : "data"]);
    } catch (error) {
      throw new Error(String(error) + "\n" + stderr);
    }
  }

  async function unchanged(before: Buffer): Promise<void> {
    assert.deepEqual(await readFile(manifest), before);
    for (let index = 0; index < maps.length; index++) {
      assert.deepEqual(await readFile(join(root, String(maps[index]!.relativePath))), beforeMaps[index]);
    }
  }

  async function assertState(expected: unknown): Promise<void> {
    const saved = record(JSON.parse(await readFile(manifest, "utf8")));
    assert.deepEqual(saved.eventRegistry, expected);
    for (const [key, value] of Object.entries(project)) {
      if (key !== "eventRegistry") contains(saved[key], value);
    }
    for (let index = 0; index < maps.length; index++) {
      assert.deepEqual(await readFile(join(root, String(maps[index]!.relativePath))), beforeMaps[index]);
    }
    assert.ok(workspace);
    const query = await call("pokemap_query", {
      projectHandle: workspace.projectHandle,
      resourceKind: "eventV2", operation: "list", view: "detail",
    });
    const items = query.items as JsonRecord[];
    const expectedRecords = record(expected).records as JsonRecord[];
    assert.equal(items.length, expectedRecords.length);
    const queriedRecords = Object.fromEntries(items.map(value => [String(value.id), {
      state: value.state,
      ...(value.state === "draft" ? { draft: value.draft } : {
        definition: value.definition,
        enabled: value.enabled,
        ...("activeInLegacyMode" in value ? { activeInLegacyMode: value.activeInLegacyMode } : {}),
      }),
    }]));
    const expectedById = Object.fromEntries(expectedRecords.map(value => [
      String(record(value.definition ?? value.draft).id), value,
    ]));
    assert.deepEqual(queriedRecords, expectedById);
  }

  async function plan(actionId: unknown, parameters: unknown, failure = false): Promise<JsonRecord> {
    assert.ok(workspace);
    const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    const before = await readFile(manifest);
    const requestId = "event-v2-" + ++sequence;
    const result = await call("pokemap_plan", {
      projectHandle: workspace.projectHandle,
      request: {
        requestId, actionId, actionVersion: 1,
        workspaceHandle: workspace.workspaceHandle,
        expectedRevision: validation.snapshotRevision,
        idempotencyKey: requestId, parameters,
      },
    }, failure);
    await unchanged(before);
    return result;
  }

  async function apply(planned: JsonRecord, confirmation: boolean, replay = true): Promise<JsonRecord> {
    assert.ok(workspace);
    let token: unknown;
    if (confirmation) {
      const before = await readFile(manifest);
      const denied = await call("pokemap_apply", {
        operation: "apply", projectHandle: workspace.projectHandle,
        planId: planned.planId, operationId: "event-v2-unconfirmed-" + ++sequence,
      }, true);
      assert.equal(denied.domainCode, fixture.confirmationDomainCode);
      await unchanged(before);
      token = (await call("pokemap_apply", {
        operation: "confirm", projectHandle: workspace.projectHandle, planId: planned.planId,
      })).confirmationToken;
    }
    const input: JsonRecord = {
      operation: "apply", projectHandle: workspace.projectHandle,
      planId: planned.planId, operationId: "event-v2-apply-" + ++sequence,
      ...(token ? { confirmationToken: token } : {}),
    };
    const applied = await call("pokemap_apply", input);
    const receipt = record(applied.receipt);
    assert.equal(receipt.status, "applied");
    if (replay) {
      const before = await readFile(manifest);
      const replayed = await call("pokemap_apply", input);
      assert.equal(record(replayed.receipt).receiptId, receipt.receiptId);
      await unchanged(before);
    }
    return receipt;
  }

  async function rejectAfter(id: unknown): Promise<void> {
    for (const refusal of refusals.filter(value => value.afterOperation === id)) {
      const before = await readFile(manifest);
      const rejected = await plan(refusal.actionId, refusal.parameters, true);
      assert.equal(rejected.domainCode, refusal.domainCode, String(refusal.id));
      assert.notEqual(rejected.domainCode, "worker.internal");
      assert.ok(!JSON.stringify(rejected).includes(root));
      await unchanged(before);
    }
  }

  try {
    await connect();
    const description = await call("pokemap_describe");
    const advertised = (description.mutationActions as JsonRecord[]).filter(action => expectedActions.includes(String(action.id)));
    assert.deepEqual(advertised.map(action => String(action.id)).sort(), [...expectedActions].sort());
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    const beforeBound = await readFile(manifest);
    assert.equal((fixture.acceptedBatch as JsonRecord[]).length, 128);
    await plan("event_v2.record_upsert_batch", { records: fixture.acceptedBatch });
    await unchanged(beforeBound);
    await rejectAfter("initial");
    let previous: unknown = project.eventRegistry;
    for (const operation of operations) {
      const planned = await plan(operation.actionId, operation.parameters);
      const stalePlan = operation.id === "batch" ? await plan(operation.actionId, operation.parameters) : undefined;
      const receipt = await apply(planned, operation.confirmation === true);
      await assertState(operation.expectedRegistry);
      if (stalePlan) {
        const before = await readFile(manifest);
        const rejected = await call("pokemap_apply", {
          operation: "apply", projectHandle: workspace.projectHandle,
          planId: stalePlan.planId, operationId: "event-v2-stale-" + ++sequence,
        }, true);
        assert.equal(rejected.domainCode, fixture.staleDomainCode);
        await unchanged(before);
      }
      if (operation.id === "batch" || operation.id === "delete") {
        const history = await call("pokemap_history", {
          operation: "list", projectHandle: workspace.projectHandle, limit: 1,
        });
        assert.equal(record((history.entries as JsonRecord[])[0]).entryId, receipt.receiptId);
        await call("pokemap_history", {
          operation: "undo", projectHandle: workspace.projectHandle,
          entryId: receipt.receiptId, idempotencyKey: "event-v2-undo-" + ++sequence,
        });
        await assertState(previous);
        await apply(await plan(operation.actionId, operation.parameters), operation.confirmation === true, false);
        await assertState(operation.expectedRegistry);
      }
      await rejectAfter(operation.id);
      previous = operation.expectedRegistry;
    }
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    workspace = undefined;
    await active!.client.close();
    await active!.transport.close();
    active = undefined;
    await connect();
    workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    await assertState(previous);
    const receiptPath = process.env.POKEMAP_TEST_EVENT_V2_RECEIPT;
    if (receiptPath) {
      await writeFile(receiptPath, JSON.stringify({
        live: true, transport: "MCP stdio", fixturePath,
        fixtureSha256: createHash("sha256").update(fixtureBytes).digest("hex"),
        serverSha256: createHash("sha256").update(await readFile(resolve("dist/src/index.js"))).digest("hex"),
        actions: advertised, operations: operations.map(value => value.id),
        refusalIds: refusals.map(value => value.id),
        verified: ["describe", "planWithoutMutation", "nineActions", "replay", "atomicRefusals", "staleApply", "confirmation", "undoBatchAndDelete", "batch128Accepted", "mapsScenesFactsPreserved", "queryFullStateEachStep", "freshServerReopen"],
      }, null, 2));
    }
  } finally {
    if (workspace && active) {
      await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    }
    if (active) {
      await active.client.close();
      await active.transport.close();
    }
    await rm(root, { recursive: true, force: true });
  }
});

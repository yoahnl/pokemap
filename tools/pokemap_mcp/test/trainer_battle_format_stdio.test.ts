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
    const actualRecord = record(actual);
    for (const [key, value] of Object.entries(expected)) contains(actualRecord[key], value);
  } else {
    assert.deepEqual(actual, expected);
  }
}

test("L32 real MCP opts into Standard trainer doubles with atomic refusals and fresh-server reopen",
  { timeout: 180_000 }, async () => {
    const fixturePath = resolve("../../packages/map_authoring/test/fixtures/trainer_battle_format.json");
    const fixtureBytes = await readFile(fixturePath);
    const fixture = record(JSON.parse(fixtureBytes.toString("utf8")));
    assert.equal(fixture.fixtureVersion, 1);
    const project = record(fixture.project);
    const doubles = record(fixture.doubles);
    const codes = record(fixture.domainCodes);
    const sourcePackage = resolve("../../packages/map_authoring");
    const serverEntry = resolve("dist/src/index.js");
    const root = await mkdtemp(join(tmpdir(), "trainer-format-mcp-"));
    const manifest = join(root, "project.json");
    const mapEntry = record((project.maps as unknown[])[0]);
    const mapFile = join(root, String(mapEntry.relativePath));
    await mkdir(dirname(mapFile), { recursive: true });
    await writeFile(manifest, JSON.stringify(project));
    await writeFile(mapFile, JSON.stringify(fixture.map));
    const initial = await readFile(manifest);
    const protectedMap = await readFile(mapFile);
    let active: { client: Client; transport: StdioClientTransport } | undefined;
    let workspace: JsonRecord | undefined;
    let sequence = 0;
    let connections = 0;
    let toolCalls = 0;
    let stderr = "";

    async function connect(): Promise<void> {
      const client = new Client({ name: "trainer-battle-format-test", version: "1.0.0" });
      const transport = new StdioClientTransport({ command: process.execPath,
        args: [serverEntry, "--root", root, "--authoring-package", sourcePackage,
          "--dart", process.env.POKEMAP_TEST_DART ?? "dart", "--authoring-timeout-ms", "60000"],
        cwd: process.cwd(), stderr: "pipe" });
      stderr = "";
      transport.stderr?.on("data", chunk => { stderr = (stderr + String(chunk)).slice(-8000); });
      active = { client, transport };
      await client.connect(transport);
      connections++;
    }

    async function call(name: string, input: JsonRecord = {}, failure = false): Promise<JsonRecord> {
      assert.ok(active);
      toolCalls++;
      try {
        const response = await active.client.callTool({ name, arguments: input });
        const envelope = record(response.structuredContent);
        assert.equal(envelope.ok, !failure, JSON.stringify({ name, envelope }));
        return record(envelope[failure ? "error" : "data"]);
      } catch (error) {
        throw new Error(`${name}: ${String(error)}\n${stderr}`);
      }
    }

    async function unchanged(before: Buffer): Promise<void> {
      assert.deepEqual(await readFile(manifest), before);
      assert.deepEqual(await readFile(mapFile), protectedMap);
    }

    async function revision(): Promise<unknown> {
      assert.ok(workspace);
      return (await call("pokemap_validate", { projectHandle: workspace.projectHandle })).snapshotRevision;
    }

    async function plan(actionId: string, parameters: JsonRecord, failure = false,
      expectedRevision?: unknown): Promise<JsonRecord> {
      assert.ok(workspace);
      const currentRevision = expectedRevision ?? await revision();
      const before = await readFile(manifest);
      const id = `trainer-format-${++sequence}`;
      const result = await call("pokemap_plan", { projectHandle: workspace.projectHandle,
        request: { requestId: id, actionId, actionVersion: 1,
          workspaceHandle: workspace.workspaceHandle, expectedRevision: currentRevision,
          idempotencyKey: id, parameters } }, failure);
      await unchanged(before);
      return result;
    }

    async function refuse(actionId: string, parameters: JsonRecord, code: unknown,
      expectedRevision?: unknown): Promise<void> {
      const denied = await plan(actionId, parameters, true, expectedRevision);
      assert.notEqual(denied.domainCode, "worker.internal");
      assert.equal(denied.domainCode, code);
    }

    async function apply(planned: JsonRecord): Promise<JsonRecord> {
      assert.ok(workspace);
      const input = { operation: "apply", projectHandle: workspace.projectHandle,
        planId: planned.planId, operationId: `trainer-format-apply-${++sequence}` };
      const applied = await call("pokemap_apply", input);
      const receipt = record(applied.receipt);
      assert.equal(receipt.status, "applied");
      const before = await readFile(manifest);
      assert.deepEqual(record((await call("pokemap_apply", input)).receipt), receipt);
      await unchanged(before);
      return receipt;
    }

    async function query(format: string, profile: unknown, trainer: unknown): Promise<void> {
      assert.ok(workspace);
      const before = await readFile(manifest);
      const page = await call("pokemap_query", { projectHandle: workspace.projectHandle,
        resourceKind: "project", operation: "get", ids: ["project"], view: "detail",
        fieldMask: ["pokemon", "trainers"] });
      const queried = record((page.items as unknown[])[0]);
      const trainers = queried.trainers as JsonRecord[];
      assert.equal(trainers.length, 1);
      assert.equal(trainers[0]!.battleFormat, format);
      contains(trainers[0], trainer);
      assert.deepEqual(record(queried.pokemon).ruleset, profile);
      const saved = record(JSON.parse(before.toString("utf8")));
      contains((saved.trainers as unknown[])[0], trainer);
      for (const [key, value] of Object.entries(project)) {
        if (key !== "trainers" && key !== "pokemon") contains(saved[key], value);
      }
      const pokemon = record(project.pokemon);
      for (const [key, value] of Object.entries(pokemon)) {
        if (key !== "ruleset") contains(record(saved.pokemon)[key], value);
      }
      assert.deepEqual(record(saved.pokemon).ruleset, profile);
      await unchanged(before);
    }

    async function undo(receipt: JsonRecord): Promise<void> {
      assert.ok(workspace);
      await call("pokemap_history", { operation: "undo", projectHandle: workspace.projectHandle,
        entryId: receipt.receiptId, idempotencyKey: `trainer-format-undo-${++sequence}` });
    }

    async function close(): Promise<void> {
      if (workspace && active) {
        await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
        workspace = undefined;
      }
      if (active) {
        await active.client.close();
        await active.transport.close();
        active = undefined;
      }
    }

    try {
      await connect();
      const description = await call("pokemap_describe");
      const actions = description.mutationActions as JsonRecord[];
      const trainerAction = actions.find(action => action.id === "campaign.trainer.upsert");
      const profileAction = actions.find(action => action.id === "pokemon.ruleset.set");
      assert.deepEqual(record(trainerAction?.extensions).trainerBattleFormat, fixture.descriptor);
      assert.deepEqual(record(profileAction?.extensions).profiles, {
        default: "pokemap-beta-v1", values: [fixture.betaProfile, fixture.standardProfile],
      });
      workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
      await query("singles", fixture.betaProfile, fixture.singles);
      await refuse("campaign.trainer.upsert", { value: doubles }, codes.featureDisabled);
      const profileReceipt = await apply(await plan("pokemon.ruleset.set", { profile: fixture.standardProfile }));
      const profileOnly = await readFile(manifest);
      const stale = await plan("campaign.trainer.upsert", { value: { ...doubles, name: "Stale trainer" } });
      const trainerReceipt = await apply(await plan("campaign.trainer.upsert", { value: doubles }));
      await query("doubles", fixture.standardProfile, doubles);
      const published = await readFile(manifest);
      const staleDenied = await call("pokemap_apply", { operation: "apply",
        projectHandle: workspace.projectHandle, planId: stale.planId,
        operationId: `trainer-format-stale-${++sequence}` }, true);
      assert.equal(staleDenied.domainCode, codes.stalePlan);
      await unchanged(published);
      const currentRevision = await revision();
      await refuse("pokemon.ruleset.set", { profile: fixture.betaProfile }, codes.rulesetDowngrade, currentRevision);
      for (const invalid of fixture.invalidFormats as unknown[]) {
        await refuse("campaign.trainer.upsert", { value: { ...doubles, battleFormat: invalid } },
          codes.invalidFormat, currentRevision);
      }
      for (const size of fixture.invalidDoubleTeamSizes as number[]) {
        const team = doubles.team as unknown[];
        await refuse("campaign.trainer.upsert", { value: { ...doubles,
          team: Array.from({ length: size }, (_, index) => team[index % team.length]) } },
        codes.invalidDoubleTeamSize, currentRevision);
      }
      await refuse("campaign.trainer.upsert", { value: fixture.staticTrainer }, codes.staticDoublesUnsupported, currentRevision);
      assert.equal(await revision(), currentRevision);
      await unchanged(published);
      await undo(trainerReceipt);
      await unchanged(profileOnly);
      await query("singles", fixture.standardProfile, fixture.singles);
      await undo(profileReceipt);
      await unchanged(initial);
      await query("singles", fixture.betaProfile, fixture.singles);
      await apply(await plan("pokemon.ruleset.set", { profile: fixture.standardProfile }));
      await apply(await plan("campaign.trainer.upsert", { value: doubles }));
      await close();
      await connect();
      workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
      await query("doubles", fixture.standardProfile, doubles);
      assert.equal(connections, 2);
      const receiptPath = process.env.POKEMAP_TEST_TRAINER_BATTLE_FORMAT_RECEIPT;
      if (receiptPath) {
        const sha = (bytes: Uint8Array): string => createHash("sha256").update(bytes).digest("hex");
        await writeFile(receiptPath, JSON.stringify({ live: true, transport: "MCP stdio to canonical Dart JSONL CLI",
          fixturePath, fixtureSha256: sha(fixtureBytes), serverEntry, serverSha256: sha(await readFile(serverEntry)),
          authoringPackage: sourcePackage, authoringEntry: "bin/pokemap_authoring.dart",
          authoringEntrySha256: sha(await readFile(join(sourcePackage, "bin/pokemap_authoring.dart"))),
          actions: [trainerAction, profileAction], freshServerConnections: connections, toolCalls,
          strictFormatRefusals: fixture.invalidFormats, invalidDoubleTeamSizes: fixture.invalidDoubleTeamSizes,
          verified: ["freshDescribe", "betaDoublesRefused", "explicitStandardOptIn", "trainerDoublesUpsert",
            "replay", "requery", "staleApply", "atomicDowngradeRefused", "strictFormatRefusals",
            "doubleTeamBounds", "staticDoublesRefused", "orderedTrainerAndProfileUndo", "sourceFieldsPreserved",
            "mapsByteIdentical", "freshServerColdReopen"],
          limitations: ["Authoring transport proof; battle simulation and native gameplay are qualified separately."],
        }, null, 2));
      }
    } finally {
      try {
        await close();
      } finally {
        await rm(root, { recursive: true, force: true });
      }
    }
  });

import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";
import { canonicalPokemonConfig } from "./pokemon_fixture.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

function sha256(bytes: Uint8Array): string {
  return createHash("sha256").update(bytes).digest("hex");
}

const expectedBallContract: JsonRecord = {
  field: "value.team[].ballItemId",
  defaultPolicy: "none",
  referenceKind: "itemDefinition",
  requiredCapability: "capture",
  allowedEncounterKindsRestrictPresentation: false,
};

const originalTrainer: JsonRecord = {
  id: "capsule-review",
  name: "Capsule Researcher",
  trainerClass: "Researcher",
  battleDifficulty: 3,
  moneyReward: 75,
  tags: ["preserved", "independent-of-species"],
  team: [
    { speciesId: "same-species", level: 7, moves: ["tackle"], heldItemId: "tonic", gender: "male", shiny: true },
    { speciesId: "same-species", level: 12, moves: ["growl"], gender: "female", shiny: false },
  ],
};

function withBalls(first: unknown, second: unknown): JsonRecord {
  return {
    ...originalTrainer,
    team: (originalTrainer.team as JsonRecord[]).map((member, index) => ({
      ...member,
      ballItemId: index === 0 ? first : second,
    })),
  };
}

function assertTrainerFields(trainer: JsonRecord): void {
  for (const [key, value] of Object.entries(originalTrainer)) {
    if (key !== "team") assert.deepEqual(trainer[key], value, key);
  }
  const members = trainer.team as JsonRecord[];
  assert.equal(members.length, 2);
  for (const [index, expected] of (originalTrainer.team as JsonRecord[]).entries()) {
    const actual = record(members[index]);
    for (const [key, value] of Object.entries(expected)) {
      assert.deepEqual(actual[key], value, `team[${index}].${key}`);
    }
  }
}

async function connect(root: string) {
  const args = [resolve(process.env.POKEMAP_TEST_MCP_ENTRY ?? "dist/src/index.js"),
    "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_DART) args.push("--dart", process.env.POKEMAP_TEST_DART);
  if (process.env.POKEMAP_TEST_AUTHORING_PACKAGE) args.push("--authoring-package", process.env.POKEMAP_TEST_AUTHORING_PACKAGE);
  const client = new Client({ name: "l16-trainer-ball-test", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args,
    cwd: process.cwd(), stderr: "pipe" });
  async function call(name: string, input: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: input });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify({ name, input, envelope }));
    return record(envelope[failure ? "error" : "data"]);
  }
  try {
    await client.connect(transport);
  } catch (error) {
    await client.close();
    throw error;
  }
  return { client, call };
}

test("L16 MCP authors individual trainer Balls without a default and rejects invalid references atomically",
  { timeout: 180_000 }, async (context) => {
    const root = await mkdtemp(join(tmpdir(), "l16-trainer-ball-mcp-"));
    const file = join(root, "project.json");
    const itemsFile = join(root, "data/pokemon/catalogs/items.json");
    let session: Awaited<ReturnType<typeof connect>> | undefined;
    let sequence = 0;
    const capture = (id: string, encounter: string): JsonRecord => ({
      id, displayName: id, pocketId: "balls",
      capture: { rateNumerator: 1, rateDenominator: 1, allowedEncounterKinds: [encounter] },
    });
    try {
      await mkdir(join(root, "data/pokemon/catalogs"), { recursive: true });
      await writeFile(itemsFile, JSON.stringify({ schemaVersion: 1, entries: [
        capture("standard-orb", "walk"), capture("ocean-orb", "surf"),
        { id: "tonic", displayName: "Tonic", pocketId: "medicine" },
        capture("ambiguous-orb", "walk"), capture("ambiguous-orb", "surf"),
      ] }));
      const untouchedTrainer = { id: "bystander", name: "Bystander", trainerClass: "Trainer",
        team: [{ speciesId: "other-species", level: 5 }], tags: ["untouched"] };
      await writeFile(file, JSON.stringify({
        name: "Trainer Ball transport", version: "v8", maps: [], tilesets: [],
        pokemon: { ...canonicalPokemonConfig(), enabled: true,
          catalogFiles: { items: "data/pokemon/catalogs/items.json" } },
        trainers: [originalTrainer, untouchedTrainer],
      }));
      const initialManifestSha = sha256(await readFile(file));
      const itemsSha = sha256(await readFile(itemsFile));
      session = await connect(root);
      const description = await session.call("pokemap_describe");
      const upsert = (description.mutationActions as JsonRecord[]).find(entry => entry.id === "campaign.trainer.upsert");
      const projectResource = (description.resourceKinds as JsonRecord[]).find(entry => entry.id === "project");
      assert.ok(upsert);
      assert.ok(projectResource);
      assert.deepEqual(record(upsert.extensions).trainerPokemonBall, expectedBallContract);
      let workspace = await session.call("pokemap_workspace", { operation: "open", projectRoot: root });

      async function query(): Promise<JsonRecord> {
        assert.ok(session);
        const page = await session.call("pokemap_query", {
          projectHandle: workspace.projectHandle, resourceKind: projectResource!.id,
          operation: "get", ids: ["project"], view: "detail", fieldMask: ["trainers"],
        });
        const rows = page.items as JsonRecord[];
        assert.equal(rows.length, 1);
        const row = record(rows[0]);
        const trainers = row.trainers as JsonRecord[];
        assert.equal(trainers.length, 2);
        const trainer = trainers.find(entry => entry.id === "capsule-review");
        assert.ok(trainer);
        return record(trainer);
      }

      async function plan(value: JsonRecord, expectedFailure?: string): Promise<JsonRecord> {
        assert.ok(session);
        const validation = await session.call("pokemap_validate", { projectHandle: workspace.projectHandle });
        const before = await readFile(file);
        const key = `trainer-ball-${++sequence}`;
        const planned = await session.call("pokemap_plan", {
          projectHandle: workspace.projectHandle,
          request: { requestId: key, actionId: upsert!.id, actionVersion: upsert!.version,
            workspaceHandle: workspace.workspaceHandle, expectedRevision: validation.snapshotRevision,
            idempotencyKey: key, dryRun: false, parameters: { value } },
        }, expectedFailure !== undefined);
        assert.equal(sha256(await readFile(file)), sha256(before));
        assert.equal(sha256(await readFile(itemsFile)), itemsSha);
        if (expectedFailure !== undefined) {
          assert.notEqual(planned.domainCode, "worker.internal");
          assert.ok(JSON.stringify(planned).includes(expectedFailure), JSON.stringify(planned));
          const after = await session.call("pokemap_validate", { projectHandle: workspace.projectHandle });
          assert.equal(after.snapshotRevision, validation.snapshotRevision);
        }
        return planned;
      }

      async function apply(value: JsonRecord): Promise<void> {
        assert.ok(session);
        const planned = await plan(value);
        const applied = await session.call("pokemap_apply", {
          operation: "apply", projectHandle: workspace.projectHandle,
          planId: planned.planId, operationId: `trainer-ball-apply-${sequence}`,
        });
        assert.equal(record(applied.receipt).status, "applied");
        assert.equal(sha256(await readFile(itemsFile)), itemsSha);
      }

      async function coldReopen(): Promise<void> {
        assert.ok(session);
        await session.call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
        await session.client.close();
        session = await connect(root);
        workspace = await session.call("pokemap_workspace", { operation: "open", projectRoot: root });
      }

      const original = await query();
      assertTrainerFields(original);
      assert.ok((original.team as JsonRecord[]).every(member => !Object.hasOwn(member, "ballItemId")));
      assert.equal(sha256(await readFile(file)), initialManifestSha);
      await apply(withBalls("standard-orb", "ocean-orb"));
      const authored = await query();
      assertTrainerFields(authored);
      assert.deepEqual((authored.team as JsonRecord[]).map(member => member.ballItemId), ["standard-orb", "ocean-orb"]);
      const authoredManifestSha = sha256(await readFile(file));
      assert.notEqual(authoredManifestSha, initialManifestSha);

      for (const [invalid, code] of [
        ["missing-orb", "trainer.ball_item_unknown"],
        ["tonic", "trainer.ball_item_not_capture"],
        ["", "trainer.ball_item_id_invalid"],
        ["   ", "trainer.ball_item_id_invalid"],
        [" standard-orb ", "trainer.ball_item_id_invalid"],
        [42, "trainer.ball_item_id_invalid"],
        ["ambiguous-orb", "trainer.ball_item_ambiguous"],
      ] as [unknown, string][]) {
        await plan(withBalls(invalid, "ocean-orb"), code);
        assert.equal(sha256(await readFile(file)), authoredManifestSha);
        assert.deepEqual(await query(), authored);
      }

      await coldReopen();
      assert.deepEqual(await query(), authored);
      assert.equal(sha256(await readFile(file)), authoredManifestSha);
      const removed = withBalls("standard-orb", null);
      const removedMembers = removed.team as JsonRecord[];
      delete removedMembers[0]!.ballItemId;
      await apply(removed);
      const cleared = await query();
      assertTrainerFields(cleared);
      assert.ok((cleared.team as JsonRecord[]).every(member => !Object.hasOwn(member, "ballItemId")));
      const finalManifestSha = sha256(await readFile(file));
      await coldReopen();
      assert.deepEqual(await query(), cleared);
      assert.equal(sha256(await readFile(file)), finalManifestSha);
      assert.equal(sha256(await readFile(itemsFile)), itemsSha);
      const manifest = record(JSON.parse(await readFile(file, "utf8")));
      const storedBystander = (manifest.trainers as JsonRecord[]).find(trainer => trainer.id === "bystander");
      assert.ok(storedBystander);
      for (const [key, value] of Object.entries(untouchedTrainer)) {
        if (key !== "team") assert.deepEqual(storedBystander[key], value);
      }
      const bystanderMember = record((storedBystander.team as JsonRecord[])[0]);
      assert.equal(bystanderMember.speciesId, "other-species");
      assert.equal(bystanderMember.level, 5);
      assert.ok(!Object.hasOwn(bystanderMember, "ballItemId"));
      await session.call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
      context.diagnostic(JSON.stringify({ initialManifestSha, authoredManifestSha, finalManifestSha, itemsSha }));
    } finally {
      await session?.client.close();
      await rm(root, { recursive: true, force: true });
    }
  });

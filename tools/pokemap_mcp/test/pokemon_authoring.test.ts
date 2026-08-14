import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";

import { Client } from "@modelcontextprotocol/client";
import { InMemoryTransport } from "@modelcontextprotocol/server";

import { LocalAuthoringClient, type JsonRecord } from "../src/authoring_client.js";
import { MemoryArtifactReader } from "../src/artifacts.js";
import { createPokeMapMcpServer } from "../src/server.js";

const repositoryRoot = resolve(process.cwd(), "../..");
const authoringPackageRoot = resolve(repositoryRoot, "packages/map_authoring");

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

async function toolData(
  client: Client,
  name: string,
  args: JsonRecord = {},
): Promise<JsonRecord> {
  const result = await client.callTool({ name, arguments: args });
  assert.equal(result.isError, undefined, JSON.stringify(result.structuredContent));
  const envelope = record(result.structuredContent);
  assert.equal(envelope.ok, true);
  return record(envelope.data);
}

async function toolFailure(
  client: Client,
  name: string,
  args: JsonRecord,
): Promise<void> {
  const result = await client.callTool({ name, arguments: args });
  assert.equal(result.isError, true);
  assert.equal(record(result.structuredContent).ok, false);
}

test("MCP writes the shared Pokemon species schema and rejects future versions", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-mcp-pokemon-"));
  await writeFile(
    join(root, "project.json"),
    JSON.stringify({
      name: "MCP Pokemon fixture",
      version: "v6",
      maps: [],
      tilesets: [],
    }),
  );
  const authoring = new LocalAuthoringClient({
    allowedRoots: [root],
    authoringPackageRoot,
    requestTimeoutMs: 60_000,
    workerTimeoutMs: 30_000,
  });
  const server = createPokeMapMcpServer({
    authoring,
    artifacts: new MemoryArtifactReader(),
  });
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "pokemap-pokemon-test", version: "1.0.0" });
  await server.connect(serverTransport);
  await client.connect(clientTransport);

  try {
    const described = await toolData(client, "pokemap_describe");
    const actionIds = (described.mutationActions as JsonRecord[]).map(
      (descriptor) => String(descriptor.id),
    );
    assert.ok(actionIds.includes("pokemon.species.write"));
    assert.ok(actionIds.includes("pokemon.ruleset.set"));

    const opened = await toolData(client, "pokemap_workspace", {
      operation: "open",
      projectRoot: root,
    });
    const projectHandle = String(opened.projectHandle);
    const workspaceHandle = String(opened.workspaceHandle);
    const validation = await toolData(client, "pokemap_validate", {
      projectHandle,
    });
    const initialRevision = String(validation.snapshotRevision);
    const rulesetPlan = await toolData(client, "pokemap_plan", {
      projectHandle,
      request: rulesetMutationRequest(workspaceHandle, initialRevision),
    });
    const rulesetApplied = await toolData(client, "pokemap_apply", {
      operation: "apply",
      projectHandle,
      planId: String(rulesetPlan.planId),
      operationId: "pokemon-ruleset-mcp",
    });
    const rulesetReceipt = record(rulesetApplied.receipt);
    assert.equal(rulesetReceipt.actionId, "pokemon.ruleset.set");
    assert.deepEqual(rulesetFromReceipt(rulesetReceipt), rulesetProfile());
    const project = JSON.parse(
      await readFile(join(root, "project.json"), "utf8"),
    ) as JsonRecord;
    assert.deepEqual(record(record(project.pokemon).ruleset), rulesetProfile());

    const refreshed = await toolData(client, "pokemap_validate", {
      projectHandle,
    });
    const snapshotRevision = String(refreshed.snapshotRevision);
    const document = speciesDocument(1);

    await toolFailure(client, "pokemap_plan", {
      projectHandle,
      request: mutationRequest(
        workspaceHandle,
        snapshotRevision,
        speciesDocument(2),
        "future",
      ),
    });

    const planned = await toolData(client, "pokemap_plan", {
      projectHandle,
      request: mutationRequest(
        workspaceHandle,
        snapshotRevision,
        document,
        "current",
      ),
    });
    const applied = await toolData(client, "pokemap_apply", {
      operation: "apply",
      projectHandle,
      planId: String(planned.planId),
      operationId: "pokemon-species-mcp",
    });
    const receipt = record(applied.receipt);
    assert.equal(receipt.actionId, "pokemon.species.write");
    assert.equal(receipt.status, "applied");

    const persisted = JSON.parse(
      await readFile(
        join(root, "data/pokemon/species/sproutle.json"),
        "utf8",
      ),
    ) as JsonRecord;
    assert.equal(persisted.schemaVersion, 1);
    assert.equal(persisted.vendorExtension, true);
  } finally {
    await client.close();
    await server.close();
    await authoring.close();
    await rm(root, { recursive: true, force: true });
  }
});

function mutationRequest(
  workspaceHandle: string,
  expectedRevision: string,
  document: JsonRecord,
  suffix: string,
): JsonRecord {
  return {
    requestId: `pokemon-species-${suffix}`,
    actionId: "pokemon.species.write",
    actionVersion: 1,
    workspaceHandle,
    parameters: {
      relativePath: "data/pokemon/species/sproutle.json",
      document,
    },
    expectedRevision,
    idempotencyKey: `pokemon-species-${suffix}`,
    dryRun: false,
  };
}

function rulesetMutationRequest(
  workspaceHandle: string,
  expectedRevision: string,
): JsonRecord {
  return {
    requestId: "pokemon-ruleset-current",
    actionId: "pokemon.ruleset.set",
    actionVersion: 1,
    workspaceHandle,
    parameters: { profile: rulesetProfile() },
    expectedRevision,
    idempotencyKey: "pokemon-ruleset-current",
    dryRun: false,
  };
}

function rulesetProfile(): JsonRecord {
  return {
    schemaVersion: 1,
    profileId: "pokemap-beta-v1",
    typeChartId: "mainline-modern-v1",
    maxLevel: 100,
    experiencePolicyId: "pokemap-simple-exp-v1",
    capturePolicyId: "pokemap-capture-mvp-v1",
    moveMachinePolicyId: "authored-consumability-v1",
    criticalHitPolicyId: "mainline-gen9-critical",
    speedTiePolicyId: "mainline-gen9-seeded-random",
    friendshipPolicyId: "mainline-0-255-v1",
    evolutionPolicyId: "pokemap-beta-evolution-v1",
    disabledFeatures: [
      "breeding",
      "double-battles",
      "modern-gimmicks",
      "online",
    ],
  };
}

function rulesetFromReceipt(receipt: JsonRecord): JsonRecord {
  const entries = record(receipt.diff).entries;
  assert.ok(Array.isArray(entries));
  const rulesetEntry = entries
    .map((entry) => record(entry))
    .find((entry) => entry.path === "/pokemon/ruleset");
  assert.ok(rulesetEntry);
  return record(rulesetEntry.after);
}

function speciesDocument(schemaVersion: number): JsonRecord {
  return {
    schemaVersion,
    id: "sproutle",
    typing: { types: ["grass"] },
    baseStats: { hp: 45, atk: 49, def: 49, spa: 65, spd: 65, spe: 45 },
    abilities: { primary: "overgrow" },
    progression: {
      growthRateId: "medium_slow",
      baseExp: 64,
      catchRate: 45,
    },
    refs: { learnset: "sproutle" },
    vendorExtension: true,
  };
}

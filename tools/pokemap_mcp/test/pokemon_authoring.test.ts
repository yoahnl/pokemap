import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";

import { Client } from "@modelcontextprotocol/client";
import { InMemoryTransport } from "@modelcontextprotocol/server";

import { LocalAuthoringClient, type JsonRecord } from "../src/authoring_client.js";
import { MemoryArtifactReader } from "../src/artifacts.js";
import { createPokeMapMcpServer } from "../src/server.js";
import {
  canonicalPokemonConfig,
  canonicalPokemonRulesetProfile,
} from "./pokemon_fixture.js";

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
): Promise<JsonRecord> {
  const result = await client.callTool({ name, arguments: args });
  assert.equal(result.isError, true);
  const envelope = record(result.structuredContent);
  assert.equal(envelope.ok, false);
  return record(envelope.error);
}

test("MCP writes canonical Pokemon species and rejects invalid schemas", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-mcp-pokemon-"));
  await writeFile(
    join(root, "project.json"),
    JSON.stringify({
      name: "MCP Pokemon fixture",
      version: "v6",
      maps: [],
      tilesets: [],
      pokemon: { ...canonicalPokemonConfig(), enabled: true },
    }),
  );
  await mkdir(join(root, "data/pokemon/catalogs"), { recursive: true });
  await writeFile(join(root, "data/pokemon/catalogs/moves.json"), JSON.stringify({
    schemaVersion: 1, catalog: "moves", entries: [{ id: "tackle", power: 40 }],
  }));
  const authoring = new LocalAuthoringClient({
    allowedRoots: [root],
    artifactRoots: [root],
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
    assert.ok(actionIds.includes("pokemon.catalog.entries.add"));
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
    const rulesetFailure = await toolFailure(client, "pokemap_plan", {
      projectHandle,
      request: rulesetMutationRequest(workspaceHandle, initialRevision),
    });
    assert.equal(rulesetFailure.domainCode, "pokemon.ruleset.no_change");
    const project = JSON.parse(
      await readFile(join(root, "project.json"), "utf8"),
    ) as JsonRecord;
    assert.deepEqual(record(record(project.pokemon).ruleset), rulesetProfile());

    const refreshed = await toolData(client, "pokemap_validate", {
      projectHandle,
    });
    const snapshotRevision = String(refreshed.snapshotRevision);
    const document = speciesDocument(1);
    const missingSchemaDocument = speciesDocument(1);
    delete missingSchemaDocument.schemaVersion;

    await toolFailure(client, "pokemap_plan", {
      projectHandle,
      request: mutationRequest(
        workspaceHandle,
        snapshotRevision,
        missingSchemaDocument,
        "missing",
      ),
    });

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
    assert.equal(persisted.slug, "");
    assert.equal(persisted.vendorExtension, undefined);

    const gated = await toolData(client, "pokemap_validate", {
      projectHandle,
    });
    assert.equal(gated.valid, false);
    const pokemonCatalog = record(gated.pokemonCatalog);
    assert.equal(pokemonCatalog.canPlaytest, false);
    const diagnostics = pokemonCatalog.diagnostics as JsonRecord[];
    const statTotal = diagnostics.find(
      (diagnostic) => diagnostic.code === "species.stat_total_mismatch",
    );
    assert.ok(statTotal);
    assert.equal(statTotal.severity, "error");
    assert.equal(typeof statTotal.path, "string");
    assert.equal(typeof statTotal.recommendedAction, "string");

    const evolution = {
      schemaVersion: 1,
      speciesId: "sproutle",
      evolutions: [{
        targetSpeciesId: "sproutle",
        method: "conditional",
        minLevel: 30,
        conditionText: { en: "Trigger: level-up. Needs overworld rain" },
      }],
    };
    const evolutionPlan = await toolData(client, "pokemap_plan", {
      projectHandle,
      request: {
        requestId: "conditional-evolution",
        idempotencyKey: "conditional-evolution",
        actionId: "pokemon.documents.write",
        actionVersion: 1,
        workspaceHandle,
        expectedRevision: String(gated.snapshotRevision),
        parameters: { documents: [{ actionId: "pokemon.evolution.write", parameters: {
          relativePath: "data/pokemon/evolutions/sproutle.json", document: evolution,
        } }] },
      },
    });
    await toolData(client, "pokemap_apply", {
      operation: "apply", projectHandle,
      planId: String(evolutionPlan.planId), operationId: "conditional-evolution",
    });
    const afterEvolution = await toolData(client, "pokemap_validate", { projectHandle });
    const afterDiagnostics = record(afterEvolution.pokemonCatalog).diagnostics as JsonRecord[];
    assert.equal(afterDiagnostics.find(d => d.code === "evolution.method_catalog_only")?.severity, "warning");
    assert.equal(afterDiagnostics.find(d => d.code === "evolution.self_target")?.severity, "error");
    const storedEvolution = JSON.parse(await readFile(join(root, "data/pokemon/evolutions/sproutle.json"), "utf8")) as JsonRecord;
    const storedEntry = (storedEvolution.evolutions as JsonRecord[])[0];
    assert.ok(storedEntry);
    assert.equal(record(storedEntry.conditionText).en, "Trigger: level-up. Needs overworld rain");
    const sourcePath = join(root, "incoming.txt");
    await writeFile(sourcePath, "same staged sprite bytes");
    const staged = await toolData(client, "pokemap_artifact_stage", { sourcePath, declaredMediaType: "text/plain" });
    const batchPlan = await toolData(client, "pokemap_plan", { projectHandle, request: {
      requestId: "asset-batch", idempotencyKey: "asset-batch", actionId: "asset.import_batch",
      actionVersion: 1, workspaceHandle, expectedRevision: String(afterEvolution.snapshotRevision),
      parameters: { entries: ["first", "second"].map(id => ({
        assetId: id, logicalPath: `assets/${id}.txt`, artifactHandle: staged.artifactHandle,
      })) },
    } });
    await toolData(client, "pokemap_apply", { operation: "apply", projectHandle,
      planId: String(batchPlan.planId), operationId: "asset-batch" });
    for (const id of ["first", "second"]) assert.equal(await readFile(join(root, `assets/${id}.txt`), "utf8"), "same staged sprite bytes");
    const beforeCatalog = await toolData(client, "pokemap_validate", { projectHandle });
    const catalogPlan = await toolData(client, "pokemap_plan", { projectHandle, request: {
      requestId: "catalog-add", idempotencyKey: "catalog-add", actionId: "pokemon.catalog.entries.add",
      actionVersion: 1, workspaceHandle, expectedRevision: String(beforeCatalog.snapshotRevision),
      parameters: { relativePath: "data/pokemon/catalogs/moves.json", entries: [{ id: "ember", power: 40 }] },
    } });
    await toolData(client, "pokemap_apply", { operation: "apply", projectHandle,
      planId: String(catalogPlan.planId), operationId: "catalog-add" });
    const catalog = JSON.parse(await readFile(join(root, "data/pokemon/catalogs/moves.json"), "utf8")) as JsonRecord;
    assert.deepEqual(catalog.entries, [{ id: "tackle", power: 40 }, { id: "ember", power: 40 }]);
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
  return canonicalPokemonRulesetProfile();
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

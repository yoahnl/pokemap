import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";

import { Client } from "@modelcontextprotocol/client";
import { InMemoryTransport } from "@modelcontextprotocol/server";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";

import { LocalAuthoringClient, type JsonRecord } from "../src/authoring_client.js";
import { MemoryArtifactReader } from "../src/artifacts.js";
import { createPokeMapMcpServer } from "../src/server.js";
import { canonicalPokemonConfig } from "./pokemon_fixture.js";

const repositoryRoot = resolve(process.cwd(), "../..");
const authoringPackageRoot = resolve(repositoryRoot, "packages/map_authoring");

const itemMutationScenarios = [
  {
    actionId: "item.create",
    slug: "item-create",
    parameters: {
      definition: {
        id: "field-tonic",
        displayName: "Field Tonic",
        pocketId: "medicine",
        buyPrice: 300,
      },
    },
  },
  {
    actionId: "item.update",
    slug: "item-update",
    parameters: {
      itemId: "potion",
      definition: {
        id: "potion",
        displayName: "Super Potion",
        pocketId: "medicine",
        buyPrice: 700,
      },
    },
  },
  {
    actionId: "item.clone",
    slug: "item-clone",
    parameters: {
      sourceItemId: "potion",
      newItemId: "potion-copy",
      displayName: "Potion Copy",
    },
  },
  {
    actionId: "item.delete_apply",
    slug: "item-delete-apply",
    parameters: { itemId: "discardable" },
  },
  {
    actionId: "item.set_overworld_effect",
    slug: "item-set-overworld-effect",
    parameters: {
      itemId: "potion",
      use: {
        contexts: ["overworld"],
        target: "world",
        consumption: "on_applied",
        effect: { kind: "repel", steps: 250 },
      },
    },
  },
  {
    actionId: "item.set_battle_effect",
    slug: "item-set-battle-effect",
    parameters: {
      itemId: "potion",
      use: {
        contexts: ["battle"],
        target: "party_member",
        consumption: "on_applied",
        effect: { kind: "heal_hp", mode: "flat", amount: 15 },
      },
    },
  },
  ...["flat", "full"].map((mode) => ({
    actionId: "item.set_battle_effect",
    slug: `item-set-battle-pp-${mode}`,
    parameters: {
      itemId: "potion",
      use: {
        contexts: ["battle"],
        target: "party_move",
        consumption: "on_applied",
        effect: { kind: "restore_pp", mode, amount: mode === "flat" ? 10 : null },
      },
    },
  })),
  {
    actionId: "item.set_held_effect",
    slug: "item-set-held-effect",
    parameters: { itemId: "potion", heldEffectId: "leftovers" },
  },
  ...["lum_berry", "sitrus_berry", "smoke_ball"].map((heldEffectId) => ({
    actionId: "item.set_held_effect",
    slug: `item-set-held-${heldEffectId}`,
    parameters: { itemId: "potion", heldEffectId },
  })),
  {
    actionId: "item.set_capture_effect",
    slug: "item-set-capture-effect",
    parameters: {
      itemId: "potion",
      capture: {
        rateNumerator: 3,
        rateDenominator: 2,
        allowedEncounterKinds: ["walk"],
      },
    },
  },
  {
    actionId: "item.set_tm_hm_move",
    slug: "item-set-tm-hm-move",
    parameters: {
      itemId: "potion",
      machine: { moveId: "cut", kind: "tm", consumable: true },
    },
  },
] as const;

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

test("MCP describes queries and mutates canonical items", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-mcp-items-"));
  await writeFixture(root);
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
  const client = new Client({ name: "pokemap-item-test", version: "1.0.0" });
  await server.connect(serverTransport);
  await client.connect(clientTransport);

  try {
    const description = await toolData(client, "pokemap_describe");
    const resourceKinds = (description.resourceKinds as JsonRecord[]).map(
      (descriptor) => String(descriptor.id),
    );
    for (const resourceKind of [
      "itemCatalog",
      "itemDefinition",
      "itemUsage",
      "itemReadiness",
    ]) {
      assert.ok(resourceKinds.includes(resourceKind), resourceKind);
    }
    const mutationActions = (description.mutationActions as JsonRecord[])
      .map((descriptor) => String(descriptor.id))
      .filter((id) => id.startsWith("item."));
    const heldDescriptor = (description.mutationActions as JsonRecord[])
      .find((descriptor) => descriptor.id === "item.set_held_effect");
    const battleDescriptor = (description.mutationActions as JsonRecord[])
      .find((descriptor) => descriptor.id === "item.set_battle_effect");
    assert.ok(battleDescriptor);
    assert.ok((record(battleDescriptor.extensions).effectKinds as string[]).includes("restore_pp"));
    assert.ok(heldDescriptor);
    const heldEffects = record(heldDescriptor.extensions).heldEffectIds as string[];
    for (const effectId of ["lum_berry", "sitrus_berry", "smoke_ball"]) {
      assert.ok(heldEffects.includes(effectId), effectId);
    }
    assert.deepEqual(mutationActions.sort(), [
      "item.clone",
      "item.create",
      "item.delete_apply",
      "item.set_battle_effect",
      "item.set_capture_effect",
      "item.set_held_effect",
      "item.set_overworld_effect",
      "item.set_tm_hm_move",
      "item.update",
    ]);

    const opened = await toolData(client, "pokemap_workspace", {
      operation: "open",
      projectRoot: root,
    });
    const projectHandle = String(opened.projectHandle);
    const workspaceHandle = String(opened.workspaceHandle);
    const definitions = await toolData(client, "pokemap_query", {
      projectHandle,
      resourceKind: "itemDefinition",
      operation: "list",
      view: "detail",
    });
    assert.equal(definitions.returned, 2);
    let snapshotRevision = String(definitions.snapshotRevision);

    const simulation = await toolData(client, "pokemap_query", {
      projectHandle,
      resourceKind: "itemDefinition",
      operation: "get",
      view: "detail",
      ids: ["potion"],
      extensions: {
        actionId: "item.simulate",
        parameters: { itemId: "potion", context: "overworld" },
      },
    });
    assert.equal(
      record(record((simulation.items as JsonRecord[])[0]).simulation).context,
      "overworld",
    );

    const executedActions = new Set<string>();
    const receiptIds = new Set<string>();
    for (const scenario of itemMutationScenarios) {
      const planned = await toolData(client, "pokemap_plan", {
        projectHandle,
        request: {
          requestId: `mcp-${scenario.slug}`,
          actionId: scenario.actionId,
          actionVersion: 1,
          workspaceHandle,
          parameters: scenario.parameters,
          expectedRevision: snapshotRevision,
          idempotencyKey: `mcp-${scenario.slug}`,
          dryRun: false,
        },
      });
      let confirmationToken: string | undefined;
      if (scenario.actionId === "item.delete_apply") {
        const confirmation = await toolData(client, "pokemap_apply", {
          operation: "confirm",
          projectHandle,
          planId: String(planned.planId),
        });
        confirmationToken = String(confirmation.confirmationToken);
      }
      const applied = await toolData(client, "pokemap_apply", {
        operation: "apply",
        projectHandle,
        planId: String(planned.planId),
        operationId: `operation-mcp-${scenario.slug}`,
        ...(confirmationToken ? { confirmationToken } : {}),
      });
      const receipt = record(applied.receipt);
      assert.equal(receipt.actionId, scenario.actionId);
      assert.equal(receipt.status, "applied");
      assert.match(String(receipt.beforeRevision), /^sha256:[0-9a-f]{64}$/);
      assert.match(String(receipt.afterRevision), /^sha256:[0-9a-f]{64}$/);
      assert.notEqual(receipt.afterRevision, receipt.beforeRevision);
      const appliedRevision = String(applied.snapshotRevision);
      assert.notEqual(appliedRevision, snapshotRevision);

      const queried = await toolData(client, "pokemap_query", {
        projectHandle,
        resourceKind: "itemDefinition",
        operation: "list",
        view: "detail",
      });
      snapshotRevision = String(queried.snapshotRevision);
      assert.equal(snapshotRevision, appliedRevision);
      if (scenario.slug.startsWith("item-set-battle-pp-")) {
        const definition = (queried.items as JsonRecord[]).find((item) => item.id === "potion");
        assert.ok(definition);
        assert.deepEqual((definition.uses as JsonRecord[]).find((use) =>
          (use.contexts as string[]).includes("battle")), record(scenario.parameters).use);
      }
      if (scenario.actionId === "item.set_held_effect") {
        const definition = (queried.items as JsonRecord[])
          .find((item) => item.id === "potion");
        assert.equal(definition?.heldEffectId,
          record(scenario.parameters).heldEffectId);
        const readiness = await toolData(client, "pokemap_query", {
          projectHandle,
          resourceKind: "itemReadiness",
          operation: "get",
          view: "detail",
          ids: ["potion"],
        });
        assert.equal(record((readiness.items as JsonRecord[])[0]).ready, true);
      }
      const validation = await toolData(client, "pokemap_validate", {
        projectHandle,
      });
      assert.equal(validation.snapshotRevision, snapshotRevision);
      assert.equal(validation.valid, true);

      executedActions.add(String(receipt.actionId));
      receiptIds.add(String(receipt.receiptId));
    }
    assert.deepEqual(executedActions, new Set(mutationActions));
    assert.equal(receiptIds.size, itemMutationScenarios.length);

    const hiddenItemPlan = await toolData(client, "pokemap_plan", {
      projectHandle,
      request: {
        requestId: "mcp-hidden-item",
        actionId: "entity.set_item_payload",
        actionVersion: 1,
        workspaceHandle,
        parameters: {
          mapId: "lab",
          entityId: "secret",
          payload: {
            gameItemId: "field-tonic",
            quantity: 1,
            pickupMode: "once",
            respawnPolicy: "none",
            visibility: "hidden",
          },
        },
        expectedRevision: snapshotRevision,
        idempotencyKey: "mcp-hidden-item",
        dryRun: false,
      },
    });
    const hiddenItemApplied = await toolData(client, "pokemap_apply", {
      operation: "apply",
      projectHandle,
      planId: String(hiddenItemPlan.planId),
      operationId: "operation-mcp-hidden-item",
    });
    const hiddenItemReceipt = record(hiddenItemApplied.receipt);
    assert.equal(hiddenItemReceipt.actionId, "entity.set_item_payload");
    assert.equal(hiddenItemReceipt.status, "applied");
    snapshotRevision = String(hiddenItemApplied.snapshotRevision);
    const authoredMap = record(
      JSON.parse(await readFile(join(root, "maps/lab.json"), "utf8")),
    );
    const entities = authoredMap.entities as JsonRecord[];
    assert.equal(record(record(entities[0]).item).visibility, "hidden");

    const created = await toolData(client, "pokemap_query", {
      projectHandle,
      resourceKind: "itemDefinition",
      operation: "get",
      view: "detail",
      ids: ["field-tonic"],
    });
    assert.equal(record((created.items as JsonRecord[])[0]).displayName, "Field Tonic");

    for (const refusal of [
      {
        slug: "stale",
        actionId: "item.create",
        parameters: {
          definition: {
            id: "stale-item",
            displayName: "Stale Item",
            pocketId: "custom",
          },
        },
        expectedRevision: `sha256:${"0".repeat(64)}`,
        domainCode: "plan.stale",
      },
      {
        slug: "invalid-id",
        actionId: "item.set_held_effect",
        parameters: { itemId: " potion ", heldEffectId: "leftovers" },
        expectedRevision: snapshotRevision,
        domainCode: "item.parameter_invalid",
      },
      {
        slug: "referenced-delete",
        actionId: "item.delete_apply",
        parameters: { itemId: "potion" },
        expectedRevision: snapshotRevision,
        domainCode: "item.delete_references_blocking",
      },
      {
        slug: "battle-pp-wrong-target",
        actionId: "item.set_battle_effect",
        parameters: {
          itemId: "potion",
          use: {
            contexts: ["battle"],
            target: "party_member",
            consumption: "on_applied",
            effect: { kind: "restore_pp", mode: "flat", amount: 10 },
          },
        },
        expectedRevision: snapshotRevision,
        domainCode: "item.catalog_invalid",
      },
      {
        slug: "unknown-held-effect",
        actionId: "item.set_held_effect",
        parameters: {
          itemId: "potion",
          heldEffectId: "never_registered_effect",
        },
        expectedRevision: snapshotRevision,
        domainCode: "item.catalog_invalid",
      },
    ]) {
      const error = await toolFailure(client, "pokemap_plan", {
        projectHandle,
        request: {
          requestId: `mcp-refusal-${refusal.slug}`,
          actionId: refusal.actionId,
          actionVersion: 1,
          workspaceHandle,
          parameters: refusal.parameters,
          expectedRevision: refusal.expectedRevision,
          idempotencyKey: `mcp-refusal-${refusal.slug}`,
          dryRun: false,
        },
      });
      assert.equal(error.domainCode, refusal.domainCode);
      const afterRefusal = await toolData(client, "pokemap_query", {
        projectHandle,
        resourceKind: "itemDefinition",
        operation: "list",
        view: "detail",
      });
      assert.equal(afterRefusal.snapshotRevision, snapshotRevision);
    }

    const closed = await toolData(client, "pokemap_workspace", {
      operation: "close",
      workspaceHandle,
    });
    assert.equal(closed.closed, true);
  } finally {
    await client.close();
    await server.close();
    await authoring.close();
    await rm(root, { recursive: true, force: true });
  }
});

test("MCP bicycle contracts expose restriction, reusable effect and eight directional clips", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-mcp-bicycle-"));
  await writeFixture(root);
  const manifestPath = join(root, "project.json");
  const manifest = record(JSON.parse(await readFile(manifestPath, "utf8")));
  manifest.tilesets = [{ id: "hero-sheet", name: "Hero", relativePath: "hero.png" }];
  manifest.characters = [{ id: "hero", name: "Hero", tilesetId: "hero-sheet" }];
  await writeFile(manifestPath, JSON.stringify(manifest));
  const authoring = new LocalAuthoringClient({ allowedRoots: [root], authoringPackageRoot,
    requestTimeoutMs: 60_000, workerTimeoutMs: 30_000 });
  const server = createPokeMapMcpServer({ authoring, artifacts: new MemoryArtifactReader() });
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "pokemap-bicycle-test", version: "1.0.0" });
  await server.connect(serverTransport); await client.connect(clientTransport);
  try {
    const description = await toolData(client, "pokemap_describe");
    const actions = description.mutationActions as JsonRecord[];
    const map = actions.find((action) => action.id === "map.update_metadata")!;
    assert.ok(record(record(record(map.extensions).inputSchema).properties).allowBicycle);
    const item = actions.find((action) => action.id === "item.set_overworld_effect")!;
    assert.ok((record(item.extensions).effectKinds as string[]).includes("bicycle"));
    const clip = actions.find((action) => action.id === "characterStudio.animationClip.upsert")!;
    assert.ok((record(clip.extensions).systemStates as string[]).includes("bicycle_idle"));
    const opened = await toolData(client, "pokemap_workspace", { operation: "open", projectRoot: root });
    const projectHandle = String(opened.projectHandle);
    let sequence = 0;
    async function mutate(actionId: string, parameters: JsonRecord): Promise<void> {
      const snapshot = await toolData(client, "pokemap_validate", { projectHandle });
      sequence++;
      const plan = await toolData(client, "pokemap_plan", { projectHandle, request: {
        requestId: `bicycle-${sequence}`, actionId, actionVersion: 1,
        workspaceHandle: opened.workspaceHandle, parameters,
        expectedRevision: snapshot.snapshotRevision, idempotencyKey: `bicycle-${sequence}`,
      } });
      await toolData(client, "pokemap_apply", { operation: "apply", projectHandle, planId: plan.planId,
        operationId: `bicycle-${sequence}` });
    }
    await mutate("item.create", { definition: { id: "custom-cycle", displayName: "Vélo",
      pocketId: "key-items", tags: ["key-item"] } });
    await mutate("item.set_overworld_effect", { itemId: "custom-cycle", use: {
      contexts: ["overworld"], target: "world", consumption: "never", effect: { kind: "bicycle" },
    } });
    await mutate("map.update_metadata", { mapId: "lab", allowBicycle: false });
    for (const state of ["bicycle_idle", "bicycle"]) {
      for (const direction of ["south", "west", "east", "north"]) {
        await mutate("characterStudio.animationClip.upsert", { characterId: "hero", kind: "system",
          state, direction, sourceAssetId: "cycle", frames: [{
            source: { x: 0, y: 0, width: 32, height: 32 }, durationMs: 100,
          }] });
      }
    }
    const catalog = record(JSON.parse(await readFile(join(root, "data/pokemon/catalogs/items.json"), "utf8")));
    const bicycle = (catalog.entries as JsonRecord[]).find((entry) => entry.id === "custom-cycle")!;
    assert.equal(record((bicycle.uses as JsonRecord[])[0]).consumption, "never");
    const authoredMap = record(JSON.parse(await readFile(join(root, "maps/lab.json"), "utf8")));
    assert.equal(record(authoredMap.mapMetadata).allowBicycle, false);
    const after = record(JSON.parse(await readFile(manifestPath, "utf8")));
    assert.equal(((after.characters as JsonRecord[])[0]!.animations as JsonRecord[]).length, 8);
  } finally {
    await client.close(); await server.close(); await authoring.close();
    await rm(root, { recursive: true, force: true });
  }
});

test("MCP fishing contracts expose three reusable rods and reject extra effect fields", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-mcp-fishing-"));
  await writeFixture(root);
  const authoring = new LocalAuthoringClient({
    allowedRoots: [root],
    authoringPackageRoot,
    requestTimeoutMs: 60_000,
    workerTimeoutMs: 30_000,
  });
  const server = createPokeMapMcpServer({ authoring, artifacts: new MemoryArtifactReader() });
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "pokemap-fishing-test", version: "1.0.0" });
  await server.connect(serverTransport);
  await client.connect(clientTransport);
  try {
    const description = await toolData(client, "pokemap_describe");
    const actions = description.mutationActions as JsonRecord[];
    const itemAction = actions.find((action) => action.id === "item.set_overworld_effect")!;
    assert.ok((record(itemAction.extensions).effectKinds as string[]).includes("fishing"));
    assert.deepEqual(record(record(itemAction.extensions).fishing), {
      rodKinds: ["old_rod", "good_rod", "super_rod"],
      target: "world",
      consumption: "never",
      requiredTag: "key-item",
      runtime: "2d",
      source: "front_water_cell",
      chance: "authored_per_attempt",
    });
    const tableResource = (description.resourceKinds as JsonRecord[])
      .find((resource) => resource.id === "project")!;
    const tableContract = record(record(tableResource.extensions).encounterTables);
    assert.deepEqual(tableContract.fishingKinds, ["old_rod", "good_rod", "super_rod"]);
    assert.equal(tableContract.fishingChancePerAttemptField, "chancePerStep");
    const opened = await toolData(client, "pokemap_workspace", { operation: "open", projectRoot: root });
    const projectHandle = String(opened.projectHandle);
    const workspaceHandle = String(opened.workspaceHandle);
    let sequence = 0;
    async function mutate(actionId: string, parameters: JsonRecord): Promise<void> {
      const snapshot = await toolData(client, "pokemap_validate", { projectHandle });
      sequence++;
      const plan = await toolData(client, "pokemap_plan", { projectHandle, request: {
        requestId: `fishing-${sequence}`,
        actionId,
        actionVersion: 1,
        workspaceHandle,
        parameters,
        expectedRevision: snapshot.snapshotRevision,
        idempotencyKey: `fishing-${sequence}`,
      } });
      const applied = await toolData(client, "pokemap_apply", {
        operation: "apply", projectHandle, planId: plan.planId, operationId: `fishing-${sequence}`,
      });
      assert.equal(record(applied.receipt).status, "applied");
    }
    await mutate("item.create", { definition: {
      id: "custom-tool", displayName: "Outil", pocketId: "custom", tags: ["key-item"],
    } });
    for (const rodKind of ["old_rod", "good_rod", "super_rod"]) {
      const use = {
        contexts: ["overworld"], target: "world", consumption: "never",
        effect: { kind: "fishing", rodKind },
      };
      await mutate("item.set_overworld_effect", { itemId: "custom-tool", use });
      await mutate("campaign.encounter_table.upsert", { value: {
        id: `table-${rodKind}`, name: rodKind, encounterKind: rodKind,
        chancePerStep: 0.4, conditions: [], tags: [],
        entries: [{ speciesId: "rattata", minLevel: 2, maxLevel: 4, weight: 1 }],
      } });
      const query = await toolData(client, "pokemap_query", {
        projectHandle, resourceKind: "itemDefinition", operation: "get", view: "detail", ids: ["custom-tool"],
      });
      const definition = record((query.items as JsonRecord[])[0]);
      assert.equal(definition.pocketId, "custom");
      assert.deepEqual(definition.uses, [use]);
    }
    const tables = await toolData(client, "pokemap_query", {
      projectHandle, resourceKind: "project", operation: "get", view: "detail", ids: ["project"],
    });
    const project = record((tables.items as JsonRecord[])[0]);
    assert.deepEqual((project.encounterTables as JsonRecord[]).map((table) =>
      [table.encounterKind, table.chancePerStep]).sort(),
    [["old_rod", 0.4], ["good_rod", 0.4], ["super_rod", 0.4]].sort());
    for (const effect of [
      { kind: "fishing", rodKind: "walk" },
      { kind: "fishing", rodKind: "old_rod", chance: 1 },
    ]) {
      const before = await toolData(client, "pokemap_validate", { projectHandle });
      const beforeCatalog = await readFile(join(root, "data/pokemon/catalogs/items.json"), "utf8");
      sequence++;
      await toolFailure(client, "pokemap_plan", { projectHandle, request: {
        requestId: `fishing-refuse-${sequence}`,
        actionId: "item.set_overworld_effect",
        actionVersion: 1,
        workspaceHandle,
        parameters: { itemId: "custom-tool", use: {
          contexts: ["overworld"], target: "world", consumption: "never", effect,
        } },
        expectedRevision: before.snapshotRevision,
        idempotencyKey: `fishing-refuse-${sequence}`,
      } });
      const after = await toolData(client, "pokemap_validate", { projectHandle });
      assert.equal(after.snapshotRevision, before.snapshotRevision);
      assert.equal(await readFile(join(root, "data/pokemon/catalogs/items.json"), "utf8"), beforeCatalog);
    }
    const closed = await toolData(client, "pokemap_workspace", { operation: "close", workspaceHandle });
    assert.equal(closed.closed, true);
  } finally {
    await client.close();
    await server.close();
    await authoring.close();
    await rm(root, { recursive: true, force: true });
  }
});

test("fresh stdio MCP authors battle PP and preserves it after cold reopen", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-battle-pp-"));
  await writeFixture(root);
  const connect = async () => {
    const transport = new StdioClientTransport({
      command: process.execPath,
      args: [resolve(process.env.POKEMAP_TEST_MCP_ENTRY ?? "dist/src/index.js"),
        "--root", root, "--authoring-timeout-ms", "60000"],
      cwd: process.cwd(), stderr: "pipe",
    });
    const client = new Client({ name: "battle-pp-fixture", version: "1.0.0" });
    await client.connect(transport);
    return client;
  };
  let client = await connect();
  try {
    const description = await toolData(client, "pokemap_describe");
    const action = (description.mutationActions as JsonRecord[])
      .find((entry) => entry.id === "item.set_battle_effect");
    assert.ok(action);
    assert.ok((record(action.extensions).effectKinds as string[]).includes("restore_pp"));
    const opened = await toolData(client, "pokemap_workspace", { operation: "open", projectRoot: root });
    const projectHandle = String(opened.projectHandle);
    const workspaceHandle = String(opened.workspaceHandle);
    for (const mode of ["flat", "full"]) {
      const before = await toolData(client, "pokemap_query", { projectHandle,
        resourceKind: "itemDefinition", operation: "list", view: "detail" });
      const use = { contexts: ["battle"], target: "party_move", consumption: "on_applied",
        effect: { kind: "restore_pp", mode, amount: mode === "flat" ? 10 : null } };
      const planned = await toolData(client, "pokemap_plan", { projectHandle,
        request: { requestId: `pp-${mode}`, actionId: "item.set_battle_effect", actionVersion: 1,
          workspaceHandle, parameters: { itemId: "potion", use },
          expectedRevision: before.snapshotRevision, idempotencyKey: `pp-${mode}`, dryRun: false } });
      await toolData(client, "pokemap_apply", { operation: "apply", projectHandle,
        planId: planned.planId, operationId: `apply-pp-${mode}` });
      const queried = await toolData(client, "pokemap_query", { projectHandle,
        resourceKind: "itemDefinition", operation: "get", view: "detail", ids: ["potion"] });
      assert.deepEqual(record((queried.items as JsonRecord[])[0]).uses, [use]);
    }
    await toolData(client, "pokemap_workspace", { operation: "close", workspaceHandle });
    await client.close();
    client = await connect();
    const reopened = await toolData(client, "pokemap_workspace", { operation: "open", projectRoot: root });
    const persisted = await toolData(client, "pokemap_query", { projectHandle: reopened.projectHandle,
      resourceKind: "itemDefinition", operation: "get", view: "detail", ids: ["potion"] });
    const use = record((record((persisted.items as JsonRecord[])[0]).uses as JsonRecord[])[0]);
    assert.equal(record(use.effect).mode, "full");
    assert.equal(use.target, "party_move");
    await toolData(client, "pokemap_workspace", { operation: "close", workspaceHandle: reopened.workspaceHandle });
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

async function writeFixture(root: string): Promise<void> {
  await writeFile(
    join(root, "project.json"),
    JSON.stringify({
      name: "MCP item fixture",
      version: "v8",
      maps: [
        {
          id: "lab",
          name: "Lab",
          relativePath: "maps/lab.json",
        },
      ],
      tilesets: [],
      pokemon: canonicalPokemonConfig(),
      newGame: {
        initialBag: [{ itemId: "potion", quantity: 1 }],
      },
    }),
  );
  const mapsDirectory = join(root, "maps");
  await mkdir(mapsDirectory, { recursive: true });
  await writeFile(
    join(mapsDirectory, "lab.json"),
    JSON.stringify({
      id: "lab",
      name: "Lab",
      version: "v8",
      size: { width: 3, height: 3 },
      entities: [
        {
          id: "secret",
          kind: "item",
          pos: { x: 1, y: 1 },
          item: {
            gameItemId: "potion",
            quantity: 1,
            pickupMode: "once",
            respawnPolicy: "none",
          },
        },
      ],
    }),
  );
  const catalogDirectory = join(root, "data/pokemon/catalogs");
  await mkdir(catalogDirectory, { recursive: true });
  for (const directory of ["species", "learnsets", "evolutions", "media"]) {
    await mkdir(join(root, "data/pokemon", directory), { recursive: true });
  }
  await writeFile(
    join(catalogDirectory, "items.json"),
    JSON.stringify({
      schemaVersion: 1,
      entries: [
        {
          id: "potion",
          displayName: "Potion",
          pocketId: "medicine",
        },
        {
          id: "discardable",
          displayName: "Discardable",
          pocketId: "custom",
        },
      ],
    }),
  );
  for (const catalogId of ["types", "abilities", "moves", "growth_rates"]) {
    await writeFile(
      join(catalogDirectory, `${catalogId}.json`),
      JSON.stringify({ schemaVersion: 1, catalog: catalogId, entries: [] }),
    );
  }
}

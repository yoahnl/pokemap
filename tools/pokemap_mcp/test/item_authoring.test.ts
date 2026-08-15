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
        target: "party_member",
        consumption: "on_applied",
        effect: { kind: "heal_hp", mode: "flat", amount: 20 },
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
  {
    actionId: "item.set_held_effect",
    slug: "item-set-held-effect",
    parameters: { itemId: "potion", heldEffectId: "leftovers" },
  },
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
        slug: "unsupported-battle-pp",
        actionId: "item.set_battle_effect",
        parameters: {
          itemId: "potion",
          use: {
            contexts: ["battle"],
            target: "party_move",
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

async function writeFixture(root: string): Promise<void> {
  await writeFile(
    join(root, "project.json"),
    JSON.stringify({
      name: "MCP item fixture",
      version: "v6",
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
      version: "v6",
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
}

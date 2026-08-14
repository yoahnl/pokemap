import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { execFileSync } from "node:child_process";
import {
  cp,
  mkdtemp,
  readFile,
  readdir,
  rm,
} from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, relative, resolve } from "node:path";
import { test } from "node:test";

import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";

import type { JsonRecord } from "../src/authoring_client.js";

const repositoryRoot = resolve(process.cwd(), "../..");
const fixtureRoot = resolve(
  repositoryRoot,
  "examples/playable_runtime_host/golden_item_system",
);
const packagedServer = resolve(process.cwd(), "dist/src/index.js");

const itemMutationScenarios = [
  {
    actionId: "item.create",
    slug: "create",
    parameters: {
      definition: {
        id: "smoke-item",
        displayName: "Smoke Item",
        pocketId: "custom",
      },
    },
  },
  {
    actionId: "item.update",
    slug: "update",
    parameters: {
      itemId: "smoke-item",
      definition: {
        id: "smoke-item",
        displayName: "Updated Smoke Item",
        pocketId: "custom",
        buyPrice: 100,
      },
    },
  },
  {
    actionId: "item.clone",
    slug: "clone",
    parameters: {
      sourceItemId: "smoke-item",
      newItemId: "smoke-copy",
      displayName: "Smoke Copy",
    },
  },
  {
    actionId: "item.delete_apply",
    slug: "delete",
    parameters: { itemId: "smoke-copy" },
  },
  {
    actionId: "item.set_overworld_effect",
    slug: "overworld",
    parameters: {
      itemId: "smoke-item",
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
    slug: "battle",
    parameters: {
      itemId: "smoke-item",
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
    slug: "held",
    parameters: { itemId: "smoke-item", heldEffectId: "leftovers" },
  },
  {
    actionId: "item.set_capture_effect",
    slug: "capture",
    parameters: {
      itemId: "smoke-item",
      capture: {
        rateNumerator: 1,
        rateDenominator: 1,
        allowedEncounterKinds: ["walk"],
      },
    },
  },
  {
    actionId: "item.set_tm_hm_move",
    slug: "machine",
    parameters: {
      itemId: "smoke-item",
      machine: { moveId: "protect", kind: "tm", consumable: true },
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

test(
  "packaged live MCP executes the complete item mutation smoke contract",
  { timeout: 120_000 },
  async () => {
    const temporaryRoot = await mkdtemp(join(tmpdir(), "pokemap-live-items-"));
    const projectRoot = join(temporaryRoot, "golden_item_system");
    await cp(fixtureRoot, projectRoot, { recursive: true });
    const binding = {
      commit: execFileSync("git", ["rev-parse", "HEAD"], {
        cwd: repositoryRoot,
        encoding: "utf8",
      }).trim(),
      buildDigest: await directoryDigest(resolve(process.cwd(), "dist/src")),
      fixtureDigest: await directoryDigest(projectRoot),
    };
    const transport = new StdioClientTransport({
      command: process.execPath,
      args: [packagedServer, "--root", projectRoot],
      cwd: process.cwd(),
      stderr: "pipe",
    });
    const client = new Client({ name: "pokemap-live-item-smoke", version: "1.0.0" });

    try {
      assert.match(binding.commit, /^[0-9a-f]{40}$/);
      assert.match(binding.buildDigest, /^sha256:[0-9a-f]{64}$/);
      assert.match(binding.fixtureDigest, /^sha256:[0-9a-f]{64}$/);
      await client.connect(transport);
      const description = await toolData(client, "pokemap_describe");
      const resourceKinds = new Set(
        (description.resourceKinds as JsonRecord[]).map((entry) => String(entry.id)),
      );
      const actionIds = new Set(
        (description.mutationActions as JsonRecord[])
          .map((entry) => String(entry.id))
          .filter((id) => id.startsWith("item.")),
      );
      assert.deepEqual(
        new Set(
          ["itemCatalog", "itemDefinition", "itemUsage", "itemReadiness"],
        ),
        new Set([...resourceKinds].filter((id) => id.startsWith("item"))),
      );
      assert.deepEqual(
        actionIds,
        new Set(itemMutationScenarios.map((scenario) => scenario.actionId)),
      );

      const opened = await toolData(client, "pokemap_workspace", {
        operation: "open",
        projectRoot,
      });
      const projectHandle = String(opened.projectHandle);
      const workspaceHandle = String(opened.workspaceHandle);
      const itemQueries = [
        {
          resourceKind: "itemCatalog",
          operation: "summary",
          view: "summary",
        },
        {
          resourceKind: "itemDefinition",
          operation: "list",
          view: "detail",
        },
        {
          resourceKind: "itemUsage",
          operation: "list",
          view: "detail",
        },
        {
          resourceKind: "itemReadiness",
          operation: "get",
          view: "detail",
          ids: ["potion"],
        },
      ] as const;
      const queriedItemResources = await Promise.all(
        itemQueries.map((query) =>
          toolData(client, "pokemap_query", { projectHandle, ...query }),
        ),
      );
      const queriedRevisions = new Set(
        queriedItemResources.map((query) => String(query.snapshotRevision)),
      );
      assert.equal(queriedRevisions.size, 1);
      let revision = [...queriedRevisions][0];
      const baselineValidation = await toolData(client, "pokemap_validate", {
        projectHandle,
      });
      const baselinePokemonCatalog = record(baselineValidation.pokemonCatalog);
      const receipts = new Set<string>();
      const boundReceipts: JsonRecord[] = [];

      for (const scenario of itemMutationScenarios) {
        const planned = await toolData(client, "pokemap_plan", {
          projectHandle,
          request: {
            requestId: `live-${scenario.slug}`,
            actionId: scenario.actionId,
            actionVersion: 1,
            workspaceHandle,
            parameters: scenario.parameters,
            expectedRevision: revision,
            idempotencyKey: `live-${scenario.slug}`,
            dryRun: false,
          },
        });
        let confirmationToken: string | undefined;
        if (scenario.actionId === "item.delete_apply") {
          confirmationToken = String(
            (
              await toolData(client, "pokemap_apply", {
                operation: "confirm",
                projectHandle,
                planId: String(planned.planId),
              })
            ).confirmationToken,
          );
        }
        const applied = await toolData(client, "pokemap_apply", {
          operation: "apply",
          projectHandle,
          planId: String(planned.planId),
          operationId: `live-${scenario.slug}`,
          ...(confirmationToken ? { confirmationToken } : {}),
        });
        const receipt = record(applied.receipt);
        assert.equal(receipt.actionId, scenario.actionId);
        receipts.add(String(receipt.receiptId));
        boundReceipts.push({
          actionId: scenario.actionId,
          transport: "mcp",
          observedReceiptId: String(receipt.receiptId),
          ...binding,
        });
        const queried = await toolData(client, "pokemap_query", {
          projectHandle,
          resourceKind: "itemDefinition",
          operation: "list",
          view: "detail",
        });
        revision = String(queried.snapshotRevision);
        assert.equal(revision, applied.snapshotRevision);
        const validation = await toolData(client, "pokemap_validate", {
          projectHandle,
        });
        const structure = record(validation.structure);
        const references = record(validation.references);
        const pokemonCatalog = record(validation.pokemonCatalog);
        assert.deepEqual(pokemonCatalog, baselinePokemonCatalog);
        assert.equal(
          validation.valid,
          Boolean(structure.valid) &&
            Boolean(references.valid) &&
            Boolean(pokemonCatalog.canPlaytest),
          `${scenario.actionId}: ${JSON.stringify(validation)}`,
        );
        assert.equal(validation.snapshotRevision, revision);
      }

      assert.equal(receipts.size, itemMutationScenarios.length);
      assert.equal(boundReceipts.length, itemMutationScenarios.length);
      for (const receipt of boundReceipts) {
        assert.equal(receipt.commit, binding.commit);
        assert.equal(receipt.buildDigest, binding.buildDigest);
        assert.equal(receipt.fixtureDigest, binding.fixtureDigest);
      }
      const closed = await toolData(client, "pokemap_workspace", {
        operation: "close",
        workspaceHandle,
      });
      assert.equal(closed.closed, true);
    } finally {
      await client.close();
      await rm(temporaryRoot, { recursive: true, force: true });
    }
  },
);

async function directoryDigest(root: string): Promise<string> {
  const files = await listFiles(root);
  const hash = createHash("sha256");
  for (const path of files) {
    const logicalPath = relative(root, path);
    const bytes = await readFile(path);
    hash.update(String(Buffer.byteLength(logicalPath)));
    hash.update(":");
    hash.update(logicalPath);
    hash.update(":");
    hash.update(String(bytes.length));
    hash.update(":");
    hash.update(bytes);
  }
  return `sha256:${hash.digest("hex")}`;
}

async function listFiles(root: string): Promise<string[]> {
  const paths: string[] = [];
  for (const entry of await readdir(root, { withFileTypes: true })) {
    const path = join(root, entry.name);
    if (entry.isDirectory()) {
      paths.push(...(await listFiles(path)));
    } else if (entry.isFile()) {
      paths.push(path);
    }
  }
  return paths.sort();
}

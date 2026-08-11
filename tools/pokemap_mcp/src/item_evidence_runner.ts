import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { cp, mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { basename, dirname, join, resolve } from "node:path";

import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";

import type { JsonRecord } from "./authoring_client.js";

const actions = [
  {
    actionId: "item.create",
    parameters: {
      definition: {
        id: "cert-probe",
        displayName: "Certification Probe",
        pocketId: "custom",
      },
    },
  },
  {
    actionId: "item.update",
    parameters: {
      itemId: "cert-probe",
      definition: {
        id: "cert-probe",
        displayName: "Updated Certification Probe",
        pocketId: "custom",
        buyPrice: 100,
      },
    },
  },
  {
    actionId: "item.clone",
    parameters: {
      sourceItemId: "cert-probe",
      newItemId: "cert-copy",
      displayName: "Certification Copy",
    },
  },
  {
    actionId: "item.delete_apply",
    parameters: { itemId: "cert-copy" },
  },
  {
    actionId: "item.set_overworld_effect",
    parameters: {
      itemId: "cert-probe",
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
    parameters: {
      itemId: "cert-probe",
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
    parameters: { itemId: "cert-probe", heldEffectId: "leftovers" },
  },
  {
    actionId: "item.set_capture_effect",
    parameters: {
      itemId: "cert-probe",
      capture: {
        rateNumerator: 1,
        rateDenominator: 1,
        allowedEncounterKinds: ["walk"],
      },
    },
  },
  {
    actionId: "item.set_tm_hm_move",
    parameters: {
      itemId: "cert-probe",
      machine: { moveId: "protect", kind: "tm", consumable: true },
    },
  },
] as const;

async function main(): Promise<void> {
  const projectRoot = requiredArgument("--project-root");
  const serverPath = requiredArgument("--server");
  const temporaryRoot = await mkdtemp(join(tmpdir(), "pokemap-mcp-evidence-"));
  const workingRoot = join(temporaryRoot, basename(projectRoot));
  await cp(projectRoot, workingRoot, { recursive: true });
  const transport = new StdioClientTransport({
    command: process.execPath,
    args: [serverPath, "--root", workingRoot],
    cwd: resolve(dirname(serverPath), "../.."),
    stderr: "pipe",
  });
  const client = new Client({
    name: "pokemap-item-evidence-runner",
    version: "1.0.0",
  });

  try {
    await client.connect(transport);
    const opened = await toolData(client, "pokemap_workspace", {
      operation: "open",
      projectRoot: workingRoot,
    });
    const projectHandle = String(opened.projectHandle);
    const workspaceHandle = String(opened.workspaceHandle);
    let revision = String(
      (
        await toolData(client, "pokemap_query", {
          projectHandle,
          resourceKind: "itemDefinition",
          operation: "list",
          view: "detail",
        })
      ).snapshotRevision,
    );
    const pairs: JsonRecord[] = [];
    const receiptIds = new Set<string>();

    for (const [index, action] of actions.entries()) {
      const planned = await toolData(client, "pokemap_plan", {
        projectHandle,
        request: {
          requestId: `cert-mcp-${index}`,
          actionId: action.actionId,
          actionVersion: 1,
          workspaceHandle,
          parameters: action.parameters,
          expectedRevision: revision,
          idempotencyKey: `cert-mcp-${index}`,
          dryRun: false,
        },
      });
      let confirmationToken: string | undefined;
      if (action.actionId === "item.delete_apply") {
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
        operationId: `cert-mcp-${index}`,
        ...(confirmationToken ? { confirmationToken } : {}),
      });
      const receipt = record(applied.receipt);
      assert.equal(receipt.actionId, action.actionId);
      assert.equal(receipt.status, "applied");
      assert.ok(receiptIds.add(String(receipt.receiptId)));
      const queried = await toolData(client, "pokemap_query", {
        projectHandle,
        resourceKind: "itemDefinition",
        operation: "list",
        view: "detail",
      });
      revision = String(queried.snapshotRevision);
      assert.equal(revision, applied.snapshotRevision);
      const definitions = (queried.items as JsonRecord[]).map(record);
      verifySemanticState(definitions, action.actionId);
      const validation = await toolData(client, "pokemap_validate", {
        projectHandle,
      });
      assert.equal(validation.valid, true, JSON.stringify(validation));
      pairs.push({
        actionId: action.actionId,
        transport: "mcp",
        receiptSha256: canonicalSha256(normalizedReceipt(receipt)),
        semanticStateSha256: canonicalSha256(definitions),
        afterRevision: revision,
      });
    }

    assert.equal(receiptIds.size, actions.length);
    await toolData(client, "pokemap_workspace", {
      operation: "close",
      workspaceHandle,
    });
    process.stdout.write(
      JSON.stringify({ schemaVersion: 1, transport: "mcp", pairs }),
    );
  } finally {
    await client.close();
    await rm(temporaryRoot, { recursive: true, force: true });
  }
}

async function toolData(
  client: Client,
  name: string,
  args: JsonRecord,
): Promise<JsonRecord> {
  const result = await client.callTool({ name, arguments: args });
  assert.equal(result.isError, undefined, JSON.stringify(result.structuredContent));
  const envelope = record(result.structuredContent);
  assert.equal(envelope.ok, true, JSON.stringify(envelope));
  return record(envelope.data);
}

function verifySemanticState(
  definitions: JsonRecord[],
  actionId: string,
): void {
  const definitionFor = (id: string): JsonRecord | undefined =>
    definitions.find((definition) => definition.id === id);
  const probe = definitionFor("cert-probe");
  if (actionId === "item.create") {
    assert.equal(probe?.displayName, "Certification Probe");
    return;
  }
  assert.ok(probe);
  if (actionId === "item.update") {
    assert.equal(probe.displayName, "Updated Certification Probe");
    assert.equal(probe.buyPrice, 100);
  } else if (actionId === "item.clone") {
    const copy = definitionFor("cert-copy");
    assert.equal(copy?.displayName, "Certification Copy");
    assert.equal(copy?.buyPrice, 100);
  } else if (actionId === "item.delete_apply") {
    assert.equal(definitionFor("cert-copy"), undefined);
  } else if (actionId === "item.set_overworld_effect") {
    assert.equal(effectAmount(probe, "overworld"), 20);
  } else if (actionId === "item.set_battle_effect") {
    assert.equal(effectAmount(probe, "overworld"), 20);
    assert.equal(effectAmount(probe, "battle"), 15);
  } else if (actionId === "item.set_held_effect") {
    assert.equal(probe.heldEffectId, "leftovers");
  } else if (actionId === "item.set_capture_effect") {
    const capture = record(probe.capture);
    assert.equal(capture.rateNumerator, 1);
    assert.equal(capture.rateDenominator, 1);
    assert.deepEqual(capture.allowedEncounterKinds, ["walk"]);
  } else if (actionId === "item.set_tm_hm_move") {
    const machine = record(probe.machine);
    assert.equal(machine.moveId, "protect");
    assert.equal(machine.kind, "tm");
    assert.equal(machine.consumable, true);
  } else {
    assert.fail(`Unknown item evidence action ${actionId}`);
  }
}

function effectAmount(definition: JsonRecord, context: string): number {
  const use = (definition.uses as JsonRecord[])
    .map(record)
    .find((entry) => (entry.contexts as string[]).includes(context));
  assert.ok(use);
  const effect = record(use.effect);
  assert.equal(effect.kind, "heal_hp");
  return Number(effect.amount);
}

function normalizedReceipt(receipt: JsonRecord): JsonRecord {
  const normalized = { ...receipt };
  delete normalized.receiptId;
  delete normalized.createdAtUtc;
  const rawExtensions = normalized.extensions;
  if (
    rawExtensions &&
    typeof rawExtensions === "object" &&
    !Array.isArray(rawExtensions)
  ) {
    const extensions = { ...(rawExtensions as JsonRecord) };
    delete extensions.planId;
    normalized.extensions = extensions;
  }
  return normalized;
}

function canonicalSha256(value: unknown): string {
  return createHash("sha256").update(JSON.stringify(canonical(value))).digest("hex");
}

function canonical(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(canonical);
  if (value && typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value as JsonRecord)
        .sort(([left], [right]) => left.localeCompare(right))
        .map(([key, entry]) => [key, canonical(entry)]),
    );
  }
  return value;
}

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

function requiredArgument(name: string): string {
  const index = process.argv.indexOf(name);
  if (index < 0 || index + 1 >= process.argv.length) {
    throw new Error(`Missing ${name}`);
  }
  return resolve(process.argv[index + 1]!);
}

void main().catch((error: unknown) => {
  process.stderr.write(`${error instanceof Error ? error.stack : String(error)}\n`);
  process.exitCode = 1;
});

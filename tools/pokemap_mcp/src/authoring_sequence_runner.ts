import assert from "node:assert/strict";
import { cp, mkdtemp, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { basename, dirname, join, resolve } from "node:path";

import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";

import type { JsonRecord } from "./authoring_client.js";

/**
 * Replays an arbitrary authoring action sequence over MCP and writes back the
 * project it produced.
 *
 * Deliberately generic. `item_evidence_runner` hard-codes its actions and its
 * per-action semantic assertions, so proving MCP parity for a new domain used
 * to mean copying that whole file. Here the sequence arrives as JSON — the
 * same list the Dart fixture declares — so the caller owns what is authored
 * and this runner owns only how MCP is driven. Nothing about the actions is
 * interpreted, which is the point: an assertion here would be a second
 * definition of the journey.
 */
interface SequenceAction {
  readonly actionId: string;
  readonly parameters: JsonRecord;
}

async function main(): Promise<void> {
  const projectRoot = requiredArgument("--project-root");
  const serverPath = requiredArgument("--server");
  const actionsPath = requiredArgument("--actions");
  const projectOut = requiredArgument("--project-out");

  const actions = JSON.parse(
    await readFile(actionsPath, "utf8"),
  ) as SequenceAction[];
  assert.ok(Array.isArray(actions) && actions.length > 0, "empty sequence");

  const temporaryRoot = await mkdtemp(join(tmpdir(), "pokemap-mcp-sequence-"));
  const workingRoot = join(temporaryRoot, basename(projectRoot));
  await cp(projectRoot, workingRoot, { recursive: true });
  const transport = new StdioClientTransport({
    command: process.execPath,
    args: [serverPath, "--root", workingRoot],
    cwd: resolve(dirname(serverPath), "../.."),
    stderr: "pipe",
  });
  const client = new Client({
    name: "pokemap-authoring-sequence-runner",
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
      (await toolData(client, "pokemap_validate", { projectHandle }))
        .snapshotRevision,
    );

    const appliedActionIds: string[] = [];
    for (const [index, action] of actions.entries()) {
      const planned = await toolData(client, "pokemap_plan", {
        projectHandle,
        request: {
          requestId: `sequence-mcp-${index}`,
          actionId: action.actionId,
          actionVersion: 1,
          workspaceHandle,
          parameters: action.parameters,
          expectedRevision: revision,
          idempotencyKey: `sequence-mcp-${index}`,
          dryRun: false,
        },
      });
      const applied = await toolData(client, "pokemap_apply", {
        operation: "apply",
        projectHandle,
        planId: String(planned.planId),
        operationId: `sequence-mcp-${index}`,
      });
      const receipt = record(applied.receipt);
      assert.equal(receipt.actionId, action.actionId);
      assert.equal(receipt.status, "applied");
      appliedActionIds.push(String(receipt.actionId));
      const validation = await toolData(client, "pokemap_validate", {
        projectHandle,
      });
      assert.equal(validation.valid, true, JSON.stringify(validation));
      revision = String(validation.snapshotRevision);
    }

    await toolData(client, "pokemap_workspace", {
      operation: "close",
      workspaceHandle,
    });

    // The project itself is the evidence: the caller compares it against the
    // other transports rather than trusting a digest computed here.
    await cp(join(workingRoot, "project.json"), projectOut);
    process.stdout.write(
      JSON.stringify({
        schemaVersion: 1,
        transport: "mcp",
        appliedActionIds,
        finalRevision: revision,
      }),
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
  assert.equal(
    result.isError,
    undefined,
    JSON.stringify(result.structuredContent),
  );
  const envelope = record(result.structuredContent);
  assert.equal(envelope.ok, true, JSON.stringify(envelope));
  return record(envelope.data);
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
  process.stderr.write(
    `${error instanceof Error ? error.stack : String(error)}\n`,
  );
  process.exitCode = 1;
});

import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, rm, writeFile, access } from "node:fs/promises";
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

test("MCP canonically batch-deletes exact Pokemon copies and undoes the complete operation", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-mcp-pokemon-delete-"));
  await writeFile(join(root, "project.json"), JSON.stringify({ name: "Delete copies", version: "v8", maps: [], tilesets: [], pokemon: canonicalPokemonConfig() }));
  const documents = [];
  for (const [directory, kind, id] of [["learnsets", "learnset", "alpha"], ["evolutions", "evolution", "beta"]] as const) {
    await mkdir(join(root, "data/pokemon", directory), { recursive: true });
    const relativePath = `data/pokemon/${directory}/${id} 2.json`;
    const bytes = Buffer.from(JSON.stringify({ speciesId: id, sourceData: true }) + "\n");
    await writeFile(join(root, relativePath), bytes);
    documents.push({ actionId: `pokemon.${kind}.delete`, parameters: { relativePath, resourceId: id, beforeBytesBase64: bytes.toString("base64") } });
  }
  const authoring = new LocalAuthoringClient({ allowedRoots: [root], authoringPackageRoot, requestTimeoutMs: 60_000, workerTimeoutMs: 30_000 });
  const server = createPokeMapMcpServer({ authoring, artifacts: new MemoryArtifactReader() });
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "pokemon-delete-test", version: "1.0.0" });
  await server.connect(serverTransport);
  await client.connect(clientTransport);
  try {
    const described = await toolData(client, "pokemap_describe");
    const action = (described.mutationActions as JsonRecord[]).find(a => a.id === "pokemon.documents.delete");
    assert.equal(action?.riskLevel, "high");
    assert.ok((action?.guarantees as string[]).includes("undoable"));
    const opened = await toolData(client, "pokemap_workspace", { operation: "open", projectRoot: root });
    const projectHandle = opened.projectHandle;
    const validation = await toolData(client, "pokemap_validate", { projectHandle });
    const planned = await toolData(client, "pokemap_plan", { projectHandle, request: { requestId: "delete", actionId: "pokemon.documents.delete", actionVersion: 1, workspaceHandle: opened.workspaceHandle, expectedRevision: validation.snapshotRevision, parameters: { documents }, idempotencyKey: "delete", dryRun: false } });
    const confirmed = await toolData(client, "pokemap_apply", { operation: "confirm", projectHandle, planId: planned.planId });
    const applied = await toolData(client, "pokemap_apply", { operation: "apply", projectHandle, planId: planned.planId, operationId: "delete", confirmationToken: confirmed.confirmationToken });
    const receipt = record(applied.receipt);
    assert.equal(receipt.status, "applied");
    for (const document of documents) await assert.rejects(access(join(root, document.parameters.relativePath)));
    await toolData(client, "pokemap_history", { operation: "undo", projectHandle, entryId: receipt.receiptId, idempotencyKey: "restore" });
    for (const document of documents) assert.deepEqual(await readFile(join(root, document.parameters.relativePath)), Buffer.from(document.parameters.beforeBytesBase64, "base64"));
  } finally {
    await client.close();
    await server.close();
    await authoring.close();
    await rm(root, { recursive: true, force: true });
  }
});

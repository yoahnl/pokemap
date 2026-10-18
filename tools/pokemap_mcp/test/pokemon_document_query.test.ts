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

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

async function toolData(client: Client, name: string, args: JsonRecord = {}): Promise<JsonRecord> {
  const input = name === "pokemap_query" && args.request ? { ...record(args.request), projectHandle: args.projectHandle } : args;
  const result = await client.callTool({ name, arguments: input });
  assert.equal(result.isError, undefined, JSON.stringify(result));
  return record(record(result.structuredContent).data);
}

test("MCP discovers and queries every Pokemon document family, orphans and canonical write preimages", { timeout: 90_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-pokemon-document-query-"));
  const files: Record<string, JsonRecord> = {
    "data/pokemon/catalogs/items.json": { schemaVersion: 1, entries: [] },
    "data/pokemon/catalogs/moves.json": { schemaVersion: 1, catalog: "moves", entries: [] },
    "data/pokemon/species/visible.json": { schemaVersion: 1, id: "visible" },
    "data/pokemon/media/visible.json": { schemaVersion: 1, speciesId: "visible", variants: {} },
    "data/pokemon/learnsets/orphan-file.json": { schemaVersion: 1, speciesId: "orphan-id" },
    "data/pokemon/evolutions/other-orphan.json": { schemaVersion: 1, speciesId: "other-id", evolutions: [] },
  };
  for (const [path, json] of Object.entries(files)) {
    await mkdir(join(root, path, ".."), { recursive: true });
    await writeFile(join(root, path), ` ${JSON.stringify(json)}\n\n`);
  }
  await writeFile(join(root, "project.json"), JSON.stringify({ name: "Pokemon query", version: "v8", maps: [], tilesets: [], pokemon: { ...canonicalPokemonConfig(), enabled: true } }));
  const authoring = new LocalAuthoringClient({ allowedRoots: [root], authoringPackageRoot: resolve(process.cwd(), "../../packages/map_authoring"), requestTimeoutMs: 60_000, workerTimeoutMs: 30_000 });
  const server = createPokeMapMcpServer({ authoring, artifacts: new MemoryArtifactReader() });
  const [ct, st] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "pokemon-document-query-test", version: "1.0.0" });
  try {
    await server.connect(st);
    await client.connect(ct);
    const queryTool = (await client.listTools()).tools.find(tool => tool.name === "pokemap_query");
    assert.equal(queryTool?.annotations?.readOnlyHint, true);
    const described = await toolData(client, "pokemap_describe");
    const descriptor = (described.resourceKinds as JsonRecord[]).find(resource => resource.id === "pokemonDocument");
    assert.equal(record(descriptor?.extensions).queryIdFormat, "<documentKind>:<projectRelativePath>");
    const opened = await toolData(client, "pokemap_workspace", { operation: "open", projectRoot: root });
    const projectHandle = opened.projectHandle;
    const rows: JsonRecord[] = [];
    let cursor: unknown;
    do {
      const page = await toolData(client, "pokemap_query", { projectHandle, request: { resourceKind: "pokemonDocument", operation: "list", pageSize: 2, ...(cursor ? { cursor } : {}) } });
      assert.equal(page.totalAvailable, 6);
      rows.push(...page.items as JsonRecord[]);
      cursor = page.nextCursor;
    } while (cursor);
    assert.deepEqual(new Set(rows.map(row => row.documentKind)), new Set(["catalog", "species", "media", "learnset", "evolution"]));
    for (const row of rows) {
      const page = await toolData(client, "pokemap_query", { projectHandle, request: { resourceKind: "pokemonDocument", operation: "get", view: "detail", ids: [row.id] } });
      const detail = (page.items as JsonRecord[])[0]!;
      assert.equal(detail.id, row.id);
      assert.equal(detail.revision, row.revision);
      assert.equal(record(detail.mutationResourceRef).id, `${row.documentKind}:${detail.documentId}`);
      assert.deepEqual(Buffer.from(String(detail.beforeBytesBase64), "base64"), await readFile(join(root, String(row.relativePath))));
    }
    const relativePath = "data/pokemon/learnsets/orphan-file.json";
    const query = { resourceKind: "pokemonDocument", operation: "get", view: "detail", ids: [`learnset:${relativePath}`] };
    const page = await toolData(client, "pokemap_query", { projectHandle, request: query });
    const detail = (page.items as JsonRecord[])[0]!;
    const untouched = await Promise.all(Object.keys(files).filter(path => path !== relativePath).map(path => readFile(join(root, path))));
    const planned = await toolData(client, "pokemap_plan", { projectHandle, request: { requestId: "query-write", actionId: "pokemon.learnset.write", actionVersion: 1, workspaceHandle: opened.workspaceHandle, expectedRevision: page.snapshotRevision, idempotencyKey: "query-write", parameters: { relativePath, beforeBytesBase64: detail.beforeBytesBase64, document: { ...record(detail.document), startingMoves: ["tackle"] } } } });
    const confirmed = await toolData(client, "pokemap_apply", { operation: "confirm", projectHandle, planId: planned.planId });
    await toolData(client, "pokemap_apply", { operation: "apply", projectHandle, planId: planned.planId, operationId: "query-write", confirmationToken: confirmed.confirmationToken });
    const after = await toolData(client, "pokemap_query", { projectHandle, request: query });
    const afterDetail = (after.items as JsonRecord[])[0]!;
    assert.equal(afterDetail.id, detail.id);
    assert.notEqual(afterDetail.revision, detail.revision);
    assert.deepEqual(record(afterDetail.document).startingMoves, ["tackle"]);
    assert.deepEqual(await Promise.all(Object.keys(files).filter(path => path !== relativePath).map(path => readFile(join(root, path)))), untouched);
    for (const request of [
      { resourceKind: "pokemonDocument", operation: "get", view: "detail", ids: ["species:../../outside.json"] },
      { resourceKind: "pokemonDocument", operation: "list", filters: { "document.speciesId": "orphan-id" } },
    ]) {
      const result = await client.callTool({ name: "pokemap_query", arguments: { projectHandle, ...request } });
      assert.equal(result.isError, true);
      assert.ok(!JSON.stringify(result.structuredContent).includes(root));
    }
    await writeFile(join(root, "data/pokemon/species/malformed.json"), "private-malformed-source");
    const metadata = await toolData(client, "pokemap_query", { projectHandle, request: { resourceKind: "pokemonDocument", operation: "get", view: "detail", ids: ["species:data/pokemon/species/malformed.json"], fieldMask: ["id", "revision"] } });
    assert.equal((metadata.items as JsonRecord[]).length, 1);
    const invalid = await client.callTool({ name: "pokemap_query", arguments: { projectHandle, resourceKind: "pokemonDocument", operation: "get", view: "detail", ids: ["species:data/pokemon/species/malformed.json"] } });
    assert.equal(invalid.isError, true);
    assert.ok(JSON.stringify(invalid.structuredContent).includes("query.pokemon_document_invalid"));
    assert.ok(!JSON.stringify(invalid.structuredContent).includes("private-malformed-source"));
    await toolData(client, "pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await server.close();
    await authoring.close();
    await rm(root, { recursive: true, force: true });
  }
});

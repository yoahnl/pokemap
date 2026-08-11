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

test("authoring MCP refuses Bag commands and cannot write a user save", async () => {
  const sandbox = await mkdtemp(join(tmpdir(), "pokemap-mcp-player-state-"));
  const projectRoot = join(sandbox, "project");
  const userSave = join(sandbox, "user-save.json");
  await mkdir(projectRoot);
  await writeFixture(projectRoot);
  await writeFile(userSave, "untouched");
  const authoring = new LocalAuthoringClient({
    allowedRoots: [projectRoot],
    authoringPackageRoot,
  });
  const server = createPokeMapMcpServer({
    authoring,
    artifacts: new MemoryArtifactReader(),
  });
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "pokemap-player-state-test", version: "1.0.0" });
  await server.connect(serverTransport);
  await client.connect(clientTransport);

  try {
    const description = await toolData(client, "pokemap_describe");
    const mutationActions = (description.mutationActions as JsonRecord[]).map(
      (descriptor) => String(descriptor.id),
    );
    assert.ok(mutationActions.includes("item.create"));
    assert.ok(!mutationActions.some((actionId) => actionId.includes("bag.")));
    assert.ok(!mutationActions.some((actionId) => actionId.startsWith("sandbox.")));

    const opened = await toolData(client, "pokemap_workspace", {
      operation: "open",
      projectRoot,
    });
    const projectHandle = String(opened.projectHandle);
    const workspaceHandle = String(opened.workspaceHandle);
    const queried = await toolData(client, "pokemap_query", {
      projectHandle,
      resourceKind: "itemDefinition",
      operation: "list",
      view: "summary",
    });

    for (const actionId of ["bag.give", "sandbox.bag.give"]) {
      const rejected = await client.callTool({
        name: "pokemap_plan",
        arguments: {
          projectHandle,
          request: {
            requestId: `reject-${actionId.replaceAll(".", "-")}`,
            actionId,
            actionVersion: 1,
            workspaceHandle,
            parameters: { itemId: "potion", quantity: 99, savePath: userSave },
            expectedRevision: queried.snapshotRevision,
            idempotencyKey: `reject-${actionId.replaceAll(".", "-")}`,
            dryRun: false,
          },
        },
      });
      assert.equal(rejected.isError, true, actionId);
      const error = record(record(rejected.structuredContent).error);
      assert.equal(error.domainCode, "map.action_unsupported", actionId);
    }

    assert.equal(await readFile(userSave, "utf8"), "untouched");
    await toolData(client, "pokemap_workspace", {
      operation: "close",
      workspaceHandle,
    });
  } finally {
    await client.close();
    await server.close();
    await authoring.close();
    await rm(sandbox, { recursive: true, force: true });
  }
});

async function writeFixture(root: string): Promise<void> {
  await writeFile(
    join(root, "project.json"),
    JSON.stringify({
      name: "Player state boundary fixture",
      version: "v6",
      maps: [],
      tilesets: [],
      newGame: {
        initialBag: [{ itemId: "potion", quantity: 1 }],
      },
    }),
  );
  const catalogDirectory = join(root, "data/pokemon/catalogs");
  await mkdir(catalogDirectory, { recursive: true });
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
      ],
    }),
  );
}

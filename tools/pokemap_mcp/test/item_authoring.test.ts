import assert from "node:assert/strict";
import { mkdir, mkdtemp, rm, writeFile } from "node:fs/promises";
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

test("MCP describes queries and mutates canonical items", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-mcp-items-"));
  await writeFixture(root);
  const authoring = new LocalAuthoringClient({
    allowedRoots: [root],
    authoringPackageRoot,
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
    assert.equal(definitions.returned, 1);
    const snapshotRevision = String(definitions.snapshotRevision);

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

    const planned = await toolData(client, "pokemap_plan", {
      projectHandle,
      request: {
        requestId: "mcp-item-create",
        actionId: "item.create",
        actionVersion: 1,
        workspaceHandle,
        parameters: {
          definition: {
            id: "field-tonic",
            displayName: "Field Tonic",
            pocketId: "medicine",
            buyPrice: 300,
          },
        },
        expectedRevision: snapshotRevision,
        idempotencyKey: "mcp-item-create",
        dryRun: false,
      },
    });
    const applied = await toolData(client, "pokemap_apply", {
      operation: "apply",
      projectHandle,
      planId: String(planned.planId),
      operationId: "operation-mcp-item-create",
    });
    assert.equal(record(applied.receipt).actionId, "item.create");

    const created = await toolData(client, "pokemap_query", {
      projectHandle,
      resourceKind: "itemDefinition",
      operation: "get",
      view: "detail",
      ids: ["field-tonic"],
    });
    assert.equal(record((created.items as JsonRecord[])[0]).displayName, "Field Tonic");

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

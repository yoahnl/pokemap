import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";

import { Client } from "@modelcontextprotocol/client";
import { InMemoryTransport } from "@modelcontextprotocol/server";

import {
  AuthoringClientError,
  type AuthoringGateway,
  type JsonRecord,
  LocalAuthoringClient,
} from "../src/authoring_client.js";
import { MemoryArtifactReader } from "../src/artifacts.js";
import { createPokeMapMcpServer } from "../src/server.js";

const repositoryRoot = resolve(process.cwd(), "../..");
const authoringPackageRoot = resolve(repositoryRoot, "packages/map_authoring");
const scaffold = resolve(
  repositoryRoot,
  "examples/playable_runtime_host/phase6_authoring_golden_slice/project.json",
);

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

async function toolData(
  client: Client,
  name: string,
  args: JsonRecord,
): Promise<JsonRecord> {
  const result = await client.callTool({ name, arguments: args });
  assert.equal(result.isError, undefined, JSON.stringify(result.structuredContent));
  const envelope = record(result.structuredContent);
  assert.equal(envelope.ok, true);
  return record(envelope.data);
}

async function mutationFixture(
  options: { withLegacyAtlasGap?: boolean } = {},
) {
  const root = await mkdtemp(join(tmpdir(), "pokemap-mcp-mutation-"));
  const scaffoldBytes = await readFile(scaffold);
  if (options.withLegacyAtlasGap) {
    const project = JSON.parse(scaffoldBytes.toString("utf8")) as JsonRecord;
    const tilesets = Array.isArray(project.tilesets) ? project.tilesets : [];
    const categories = Array.isArray(project.elementCategories)
      ? project.elementCategories
      : [];
    const elements = Array.isArray(project.elements) ? project.elements : [];
    project.tilesets = [
      ...tilesets,
      {
        id: "tileset_m00_hanazuki_guesthouse_room",
        name: "M00 Guesthouse",
        relativePath: "images/m00.png",
      },
    ];
    project.elementCategories = [
      ...categories,
      { id: "legacy-m00", name: "Legacy M00", sortOrder: 0 },
    ];
    project.elements = [
      ...elements,
      {
        id: "legacy-m00-bed",
        name: "Legacy M00 Bed",
        tilesetId: "tileset_m00_hanazuki_guesthouse_room",
        categoryId: "legacy-m00",
        frames: [{ source: { x: 0, y: 0 } }],
      },
    ];
    await writeFile(join(root, "project.json"), JSON.stringify(project));
  } else {
    await writeFile(join(root, "project.json"), scaffoldBytes);
  }
  const authoring = new LocalAuthoringClient({
    allowedRoots: [root],
    authoringPackageRoot,
  });
  const server = createPokeMapMcpServer({
    authoring,
    artifacts: new MemoryArtifactReader(),
  });
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "pokemap-mutation-test", version: "1.0.0" });
  await server.connect(serverTransport);
  await client.connect(clientTransport);
  return { authoring, client, root, server };
}

async function applyMutation(
  client: Client,
  input: {
    projectHandle: string;
    workspaceHandle: string;
    expectedRevision: string;
    actionId: string;
    parameters: JsonRecord;
    sequence: string;
  },
): Promise<string> {
  const planned = await toolData(client, "pokemap_plan", {
    projectHandle: input.projectHandle,
    request: {
      requestId: `cold-start-${input.sequence}`,
      actionId: input.actionId,
      actionVersion: 1,
      workspaceHandle: input.workspaceHandle,
      parameters: input.parameters,
      expectedRevision: input.expectedRevision,
      idempotencyKey: `idem-cold-start-${input.sequence}`,
      dryRun: false,
    },
  });
  assert.equal(record(planned.receipt).status, "planned");
  const applied = await toolData(client, "pokemap_apply", {
    operation: "apply",
    projectHandle: input.projectHandle,
    planId: planned.planId,
    operationId: `operation-cold-start-${input.sequence}`,
  });
  const receipt = record(applied.receipt);
  assert.equal(receipt.status, "applied");
  assert.equal(receipt.actionId, input.actionId);
  assert.match(String(receipt.afterRevision), /^sha256:[0-9a-f]{64}$/);
  const validation = await toolData(client, "pokemap_validate", {
    projectHandle: input.projectHandle,
  });
  return String(validation.snapshotRevision);
}

test("MCP preserves CLI plan/apply parity for one complete map batch", async () => {
  const fixture = await mutationFixture();
  try {
    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const projectHandle = String(opened.projectHandle);
    const workspaceHandle = String(opened.workspaceHandle);
    const validation = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });

    const planned = await toolData(fixture.client, "pokemap_plan", {
      projectHandle,
      request: {
        requestId: "mcp-map-create",
        actionId: "map.create",
        actionVersion: 1,
        workspaceHandle,
        parameters: { mapId: "mcp_batch_map", width: 3, height: 2 },
        expectedRevision: validation.snapshotRevision,
        idempotencyKey: "idem-mcp-map-create",
        dryRun: false,
      },
    });
    assert.equal(record(planned.receipt).status, "planned");
    await assert.rejects(readFile(join(fixture.root, "maps/mcp_batch_map.json")));

    const applied = await toolData(fixture.client, "pokemap_apply", {
      operation: "apply",
      projectHandle,
      planId: planned.planId,
      operationId: "operation-mcp-map-create",
    });
    const retried = await toolData(fixture.client, "pokemap_apply", {
      operation: "apply",
      projectHandle,
      planId: planned.planId,
      operationId: "operation-mcp-map-create",
    });
    assert.deepEqual(retried, applied);

    const queried = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "map",
      operation: "get",
      view: "detail",
      ids: ["mcp_batch_map"],
    });
    assert.equal(record((queried.items as unknown[])[0]).id, "mcp_batch_map");

    const history = await toolData(fixture.client, "pokemap_history", {
      operation: "list",
      projectHandle,
      limit: 1,
    });
    assert.equal((history.entries as unknown[]).length, 1);
    assert.equal(record((history.entries as unknown[])[0]).operationId, "operation-mcp-map-create");

    const afterValidation = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });
    assert.notEqual(afterValidation.snapshotRevision, validation.snapshotRevision);

    const batchPlan = await toolData(fixture.client, "pokemap_plan", {
      projectHandle,
      request: {
        requestId: "mcp-map-batch",
        actionId: "map.apply_operations",
        actionVersion: 1,
        workspaceHandle,
        parameters: {
          mapId: "mcp_batch_map",
          operations: [
            {
              kind: "layer.add",
              layerKind: "tile",
              layerId: "ground",
              name: "Ground",
            },
            {
              kind: "region.fill",
              layerId: "ground",
              x: 0,
              y: 0,
              width: 3,
              height: 2,
              value: 7,
            },
          ],
        },
        expectedRevision: afterValidation.snapshotRevision,
        idempotencyKey: "idem-mcp-map-batch",
        dryRun: false,
      },
    });
    assert.equal(record(batchPlan.receipt).status, "planned");
    const batchApplied = await toolData(fixture.client, "pokemap_apply", {
      operation: "apply",
      projectHandle,
      planId: batchPlan.planId,
      operationId: "operation-mcp-map-batch",
    });
    assert.equal(record(batchApplied.receipt).actionId, "map.apply_operations");

    const batchHistory = await toolData(fixture.client, "pokemap_history", {
      operation: "list",
      projectHandle,
      limit: 2,
    });
    assert.deepEqual(
      (batchHistory.entries as JsonRecord[]).map((entry) => entry.operationId),
      ["operation-mcp-map-batch", "operation-mcp-map-create"],
    );
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test("MCP completes a cold-start 34-element visual import", async () => {
  const fixture = await mutationFixture({ withLegacyAtlasGap: true });
  try {
    const sourcePath = join(fixture.root, "source.png");
    await writeFile(
      sourcePath,
      Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00]),
    );
    const staged = await toolData(fixture.client, "pokemap_artifact_stage", {
      sourcePath,
      declaredMediaType: "image/png",
    });
    assert.match(String(staged.artifactHandle), /^artifact:\/\/sha256\/[0-9a-f]{64}$/);
    assert.equal(staged.mediaType, "image/png");

    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const projectHandle = String(opened.projectHandle);
    const workspaceHandle = String(opened.workspaceHandle);
    const described = await toolData(fixture.client, "pokemap_describe", {});
    assert.ok(
      (described.resourceKinds as JsonRecord[])
        .map((kind) => kind.id)
        .includes("tilesetFolder"),
    );
    assert.ok(
      (described.resourceKinds as JsonRecord[])
        .map((kind) => kind.id)
        .includes("elementCategory"),
    );
    const actionIds = (described.mutationActions as JsonRecord[]).map(
      (action) => action.id,
    );
    assert.ok(actionIds.includes("tileset_folder.upsert"));
    assert.ok(actionIds.includes("element_category.upsert"));
    assert.ok(
      (described.commands as JsonRecord[])
        .map((command) => command.id)
        .includes("stage_artifact"),
    );

    const initial = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });
    let revision = String(initial.snapshotRevision);
    revision = await applyMutation(fixture.client, {
      projectHandle,
      workspaceHandle,
      expectedRevision: revision,
      actionId: "asset.import",
      parameters: {
        artifactHandle: staged.artifactHandle,
        assetId: "m02-atlas",
        logicalPath: "images/m02.png",
      },
      sequence: "asset",
    });
    revision = await applyMutation(fixture.client, {
      projectHandle,
      workspaceHandle,
      expectedRevision: revision,
      actionId: "tileset_folder.upsert",
      parameters: {
        folder: { id: "m02", name: "M02", sortOrder: 2 },
      },
      sequence: "folder",
    });
    revision = await applyMutation(fixture.client, {
      projectHandle,
      workspaceHandle,
      expectedRevision: revision,
      actionId: "element_category.upsert",
      parameters: {
        category: { id: "m02-elements", name: "M02", sortOrder: 2 },
      },
      sequence: "category",
    });
    revision = await applyMutation(fixture.client, {
      projectHandle,
      workspaceHandle,
      expectedRevision: revision,
      actionId: "tileset.upsert",
      parameters: {
        tileset: {
          id: "m02-tileset",
          name: "M02",
          relativePath: "images/m02.png",
          folderId: "m02",
          sortOrder: 2,
        },
        atlas: {
          tilesetId: "m02-tileset",
          assetId: "m02-atlas",
          pixelWidth: 128,
          pixelHeight: 80,
          tileWidth: 16,
          tileHeight: 16,
          tileProperties: [],
        },
      },
      sequence: "tileset",
    });

    for (let index = 0; index < 34; index += 1) {
      const elementId = `m02-element-${String(index + 1).padStart(2, "0")}`;
      revision = await applyMutation(fixture.client, {
        projectHandle,
        workspaceHandle,
        expectedRevision: revision,
        actionId: "element.upsert",
        parameters: {
          element: {
            id: elementId,
            name: `M02 Element ${index + 1}`,
            tilesetId: "m02-tileset",
            categoryId: "m02-elements",
            frames: [
              {
                source: {
                  x: index % 8,
                  y: Math.floor(index / 8),
                },
              },
            ],
            sortOrder: index,
          },
        },
        sequence: `element-${String(index + 1).padStart(2, "0")}`,
      });
    }

    const folders = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "tilesetFolder",
      operation: "get",
      view: "detail",
      ids: ["m02"],
    });
    assert.equal(record((folders.items as unknown[])[0]).name, "M02");
    const categories = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "elementCategory",
      operation: "get",
      view: "detail",
      ids: ["m02-elements"],
    });
    assert.equal(record((categories.items as unknown[])[0]).name, "M02");

    const project = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "project",
      operation: "get",
      view: "detail",
      ids: ["project"],
    });
    const projectDetail = record((project.items as unknown[])[0]);
    assert.equal(
      (projectDetail.elements as JsonRecord[]).filter((element) =>
        String(element.id).startsWith("m02-element-"),
      ).length,
      34,
    );

    const validated = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });
    assert.equal(validated.snapshotRevision, revision);
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test("MCP returns a revision conflict without silently rebuilding the plan", async () => {
  const fixture = await mutationFixture();
  try {
    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: fixture.root,
    });
    const projectHandle = String(opened.projectHandle);
    const validation = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });
    const planned = await toolData(fixture.client, "pokemap_plan", {
      projectHandle,
      request: {
        requestId: "mcp-conflict",
        actionId: "map.create",
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle,
        parameters: { mapId: "conflicted_map", width: 2, height: 2 },
        expectedRevision: validation.snapshotRevision,
        idempotencyKey: "idem-mcp-conflict",
        dryRun: false,
      },
    });
    const manifestPath = join(fixture.root, "project.json");
    await writeFile(manifestPath, `${await readFile(manifestPath, "utf8")}\n`);

    const result = await fixture.client.callTool({
      name: "pokemap_apply",
      arguments: {
        operation: "apply",
        projectHandle,
        planId: planned.planId,
        operationId: "operation-mcp-conflict",
      },
    });
    assert.equal(result.isError, true);
    const error = record(record(result.structuredContent).error);
    assert.equal(error.code, "revision_conflict");
    assert.equal(error.retryable, true);
    await assert.rejects(readFile(join(fixture.root, "maps/conflicted_map.json")));
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
    await rm(fixture.root, { recursive: true, force: true });
  }
});

test("recovery requires an exact confirmation and preserves permission errors", async () => {
  const calls: string[] = [];
  const authoring: AuthoringGateway = {
    async request(command) {
      calls.push(command);
      throw new AuthoringClientError(
        "permission_denied",
        "The actor lacks recovery permission.",
        false,
        ["Grant project.recovery before retrying."],
        { domainCode: "authorization.permission_denied" },
      );
    },
    async close() {},
  };
  const server = createPokeMapMcpServer({
    authoring,
    artifacts: new MemoryArtifactReader(),
  });
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "pokemap-recovery-test", version: "1.0.0" });
  await server.connect(serverTransport);
  await client.connect(clientTransport);
  try {
    const missingConfirmation = await client.callTool({
      name: "pokemap_recovery",
      arguments: {
        projectHandle: "project-test",
        operationId: "operation-recovery",
        confirmation: "yes",
      },
    });
    let error = record(record(missingConfirmation.structuredContent).error);
    assert.equal(error.code, "confirmation.required");
    assert.deepEqual(calls, []);

    const denied = await client.callTool({
      name: "pokemap_recovery",
      arguments: {
        projectHandle: "project-test",
        operationId: "operation-recovery",
        confirmation: "RECOVER operation-recovery",
      },
    });
    error = record(record(denied.structuredContent).error);
    assert.equal(error.code, "permission_denied");
    assert.equal(error.domainCode, "authorization.permission_denied");
    assert.deepEqual(calls, ["recover"]);
  } finally {
    await client.close();
    await server.close();
  }
});

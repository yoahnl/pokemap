import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import test from "node:test";

import { Client } from "@modelcontextprotocol/client";
import { InMemoryTransport } from "@modelcontextprotocol/server";

import { LocalAuthoringClient, type JsonRecord } from "../src/authoring_client.js";
import { MemoryArtifactReader } from "../src/artifacts.js";
import { createPokeMapMcpServer } from "../src/server.js";
import { canonicalPokemonConfig } from "./pokemon_fixture.js";

const repositoryRoot = resolve(process.cwd(), "../..");
const authoringPackageRoot = resolve(repositoryRoot, "packages/map_authoring");
const pngBytes = Buffer.from(
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=",
  "base64",
);

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

test("MCP exposes and applies the canonical Border blueprint lifecycle", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-mcp-border-"));
  const sourcePath = join(root, "fence.png");
  await writeFile(sourcePath, pngBytes);
  await writeFile(
    join(root, "project.json"),
    JSON.stringify({
      name: "MCP Border fixture",
      version: "v6",
      maps: [],
      tilesets: [],
      pokemon: canonicalPokemonConfig(),
      elements: [
        {
          id: "fence-element",
          name: "Fence element",
          tilesetId: "tileset",
          categoryId: "border",
          frames: [
            {
              tilesetId: "",
              source: { x: 0, y: 0, width: 1, height: 1 },
              durationMs: null,
            },
          ],
        },
      ],
      borderCatalog: {
        formatVersion: 4,
        records: [],
        visualSnapshots: [],
      },
    }),
  );

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
  const client = new Client({ name: "pokemap-border-test", version: "1.0.0" });
  await server.connect(serverTransport);
  await client.connect(clientTransport);

  try {
    const described = await toolData(client, "pokemap_describe");
    const actionIds = (described.mutationActions as JsonRecord[]).map(
      (descriptor) => String(descriptor.id),
    );
    assert.deepEqual(
      actionIds.filter((id) => id.startsWith("border.blueprint.")),
      [
        "border.blueprint.delete",
        "border.blueprint.draft.upsert",
        "border.blueprint.publish",
        "border.blueprint.set_deprecated",
      ],
    );

    const opened = await toolData(client, "pokemap_workspace", {
      operation: "open",
      projectRoot: root,
    });
    const projectHandle = String(opened.projectHandle);
    const workspaceHandle = String(opened.workspaceHandle);
    const staged = await toolData(client, "pokemap_artifact_stage", {
      sourcePath,
      declaredMediaType: "image/png",
    });

    async function apply(
      actionId: string,
      parameters: JsonRecord,
      sequence: string,
    ): Promise<JsonRecord> {
      const validation = await toolData(client, "pokemap_validate", {
        projectHandle,
      });
      const plan = await toolData(client, "pokemap_plan", {
        projectHandle,
        request: {
          requestId: `border-${sequence}`,
          actionId,
          actionVersion: 1,
          workspaceHandle,
          parameters,
          expectedRevision: String(validation.snapshotRevision),
          idempotencyKey: `border-${sequence}`,
          dryRun: false,
        },
      });
      const needsConfirmation =
        actionId === "border.blueprint.delete" ||
        actionId === "border.blueprint.set_deprecated";
      const confirmation = needsConfirmation
        ? await toolData(client, "pokemap_apply", {
            operation: "confirm",
            projectHandle,
            planId: plan.planId,
          })
        : undefined;
      const applied = await toolData(client, "pokemap_apply", {
        operation: "apply",
        projectHandle,
        planId: plan.planId,
        operationId: `border-${sequence}`,
        ...(confirmation
          ? { confirmationToken: confirmation.confirmationToken }
          : {}),
      });
      assert.equal(record(applied.receipt).actionId, actionId);
      assert.equal(record(applied.receipt).status, "applied");
      return applied;
    }

    await apply(
      "border.blueprint.draft.upsert",
      { record: borderRecord("fence", true) },
      "upsert-fence",
    );
    await apply(
      "border.blueprint.draft.upsert",
      { record: borderRecord("scratch", false) },
      "upsert-scratch",
    );
    await apply(
      "border.blueprint.delete",
      { blueprintId: "scratch" },
      "delete-scratch",
    );
    await apply(
      "border.blueprint.publish",
      {
        blueprintId: "fence",
        acceptedWarningCodes: ["border.publication.coverage_gap_exceeded"],
        primitiveSources: ["cap", "span", "corner"].map((primitiveId) => ({
          primitiveId,
          frames: [
            {
              artifactHandle: staged.artifactHandle,
              sourceProjectRelativePath: "assets/tilesets/fence.png",
            },
          ],
        })),
      },
      "publish-fence",
    );
    await apply(
      "border.blueprint.set_deprecated",
      { blueprintId: "fence", isDeprecated: true },
      "deprecate-fence",
    );

    const queried = await toolData(client, "pokemap_query", {
      projectHandle,
      resourceKind: "borderBlueprint",
      operation: "get",
      view: "detail",
      ids: ["fence"],
    });
    assert.equal(queried.totalAvailable, 1);
    const blueprint = record((queried.items as unknown[])[0]);
    assert.equal(blueprint.id, "fence");
    const queriedSnapshots = await toolData(client, "pokemap_query", {
      projectHandle,
      resourceKind: "borderSnapshot",
      operation: "list",
      view: "detail",
    });
    assert.equal(queriedSnapshots.totalAvailable, 1);
    const snapshot = record((queriedSnapshots.items as unknown[])[0]);
    assert.equal(snapshot.resourceKind, "borderSnapshot");
    assert.match(String(snapshot.contentFingerprint), /^[0-9a-f]{64}$/);
    assert.equal((snapshot.frames as unknown[]).length, 1);

    const project = JSON.parse(
      await readFile(join(root, "project.json"), "utf8"),
    ) as JsonRecord;
    const borderCatalog = record(project.borderCatalog);
    const records = borderCatalog.records as JsonRecord[];
    assert.equal(records.length, 1);
    const firstRecord = records[0];
    assert.ok(firstRecord);
    assert.equal(firstRecord.isDeprecated, true);
    assert.equal(record(firstRecord.latestPublished).revision, 1);
    assert.equal((borderCatalog.visualSnapshots as unknown[]).length, 1);
  } finally {
    await client.close();
    await server.close();
    await authoring.close();
    await rm(root, { recursive: true, force: true });
  }
});

function borderRecord(id: string, withPrimitives: boolean): JsonRecord {
  return {
    id,
    draft: {
      baseRevision: 0,
      definition: {
        name: id === "fence" ? "Fence" : "Scratch",
        previewSeed: "0",
        template: "connectedLine",
        primitives: withPrimitives
          ? [
              primitive("cap", "lineCap"),
              primitive("span", "lineStraight"),
              primitive("corner", "lineCorner"),
            ]
          : [],
        defaults: {
          irregularityPermille: 0,
          detailDensityPermille: 0,
          variationPermille: 0,
          maxOverlapPx: 8,
          gapTolerancePx: 0,
          depthRows: 1,
          allowAutoRotation: false,
        },
        sortOrder: 0,
      },
    },
  };
}

function primitive(id: string, role: string): JsonRecord {
  return {
    id,
    sourceElementId: "fence-element",
    role,
    weight: 1000,
    anchorPx: { x: 0, y: 0 },
    transforms: {
      allowFlipX: true,
      allowedQuarterTurns: [0, 1, 2, 3],
    },
    currentMetrics: {
      assetFingerprint:
        "sha256:d1fae0a5eeaa3e7d08676887aab09574cd286b7f5676777206275c407cae8e81",
      pixelSize: { width: 1, height: 1 },
      opaqueBounds: { x: 0, y: 0, width: 1, height: 1 },
      defaultAnchorPx: { x: 0, y: 0 },
      occupancyMaskRle: "border-rle-v1:1:1:1",
    },
  };
}

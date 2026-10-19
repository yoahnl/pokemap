import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import test from "node:test";

import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import { InMemoryTransport } from "@modelcontextprotocol/server";

import { LocalAuthoringClient, type JsonRecord } from "../src/authoring_client.js";
import { MemoryArtifactReader } from "../src/artifacts.js";
import { createPokeMapMcpServer } from "../src/server.js";
import { canonicalPokemonConfig } from "./pokemon_fixture.js";

const repositoryRoot = resolve(process.cwd(), "../..");
const authoringPackageRoot = resolve(repositoryRoot, "packages/map_authoring");
const networkPngBytes = {
  lineCap: Buffer.from(
    "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAI0lEQVR4nO3WAREAAAQEMPp39k4OW4rVJCkA4LP2AQB47SqwWugL866rJOcAAAAASUVORK5CYII=",
    "base64",
  ),
  lineStraight: Buffer.from(
    "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAI0lEQVR4nO3WAQ0AAAgDoNs/9J05hBSkbQMAfDY+AACvXQUWcxoL9n1OGtMAAAAASUVORK5CYII=",
    "base64",
  ),
  lineCorner: Buffer.from(
    "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAASUlEQVR4nO2WsQkAMAzDXP//s0tv8GAK0h4QKJAoSVTQzte0AtYYIyASjDECIsEYI6AxZ37PW/gHvl9CIyASjDECIsGYaYJ3SS+xeRgizvP++gAAAABJRU5ErkJggg==",
    "base64",
  ),
} as const;

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
  const networkSourcePaths = {
    lineCap: join(root, "lineCap.png"),
    lineStraight: join(root, "lineStraight.png"),
    lineCorner: join(root, "lineCorner.png"),
  } as const;
  for (const role of networkRoles) {
    await writeFile(networkSourcePaths[role], networkPngBytes[role]);
  }
  await writeFile(
    join(root, "project.json"),
    JSON.stringify({
      name: "MCP Border fixture",
      version: "v8",
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
    const stagedByRole = {} as Record<NetworkRole, JsonRecord>;
    for (const role of networkRoles) {
      stagedByRole[role] = await toolData(client, "pokemap_artifact_stage", {
        sourcePath: networkSourcePaths[role],
        declaredMediaType: "image/png",
      });
    }

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
      { record: borderRecord("fence", true, false) },
      "upsert-fence",
    );
    const disconnectedValidation = await toolData(client, "pokemap_validate", {
      projectHandle,
    });
    const disconnectedPlanResult = await client.callTool({
      name: "pokemap_plan",
      arguments: {
        projectHandle,
        request: {
          requestId: "border-publish-disconnected",
          actionId: "border.blueprint.publish",
          actionVersion: 1,
          workspaceHandle,
          parameters: publishParameters(stagedByRole),
          expectedRevision: String(disconnectedValidation.snapshotRevision),
          idempotencyKey: "border-publish-disconnected",
          dryRun: false,
        },
      },
    });
    const disconnectedEnvelope = record(
      disconnectedPlanResult.structuredContent,
    );
    assert.equal(disconnectedEnvelope.ok, false);
    const disconnectedError = record(disconnectedEnvelope.error);
    assert.equal(
      disconnectedError.code,
      "validation_failed",
    );
    assert.equal(
      disconnectedError.domainCode,
      "border.blueprint.publication_invalid",
    );
    const disconnectedDetails = record(disconnectedError.details);
    const disconnectedDiagnostics = disconnectedDetails.diagnostics as JsonRecord[];
    assert.ok(
      disconnectedDiagnostics.some(
        (diagnostic) =>
          diagnostic.code ===
          "border.publication.connected_line_disconnected",
      ),
    );
    await apply(
      "border.blueprint.draft.upsert",
      { record: borderRecord("fence", true, true) },
      "repair-fence",
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
      publishParameters(stagedByRole),
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
    assert.equal(queriedSnapshots.totalAvailable, 3);
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
    const publishedPrimitives = record(
      record(firstRecord.latestPublished).definition,
    ).primitives as JsonRecord[];
    assert.deepEqual(
      publishedPrimitives.map((primitiveValue) => primitiveValue.anchorPx),
      networkRoles.map(() => ({ x: 16, y: 16 })),
    );
    assert.equal((borderCatalog.visualSnapshots as unknown[]).length, 3);
  } finally {
    await client.close();
    await server.close();
    await authoring.close();
    await rm(root, { recursive: true, force: true });
  }
});

function borderRecord(
  id: string,
  withPrimitives: boolean,
  centered = true,
): JsonRecord {
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
              primitive("cap", "lineCap", centered),
              primitive("span", "lineStraight", centered),
              primitive("corner", "lineCorner", centered),
            ]
          : [],
        defaults: {
          irregularityPermille: 0,
          detailDensityPermille: 0,
          variationPermille: 0,
          maxOverlapPx: 8,
          gapTolerancePx: 1,
          depthRows: 1,
          allowAutoRotation: false,
        },
        sortOrder: 0,
      },
    },
  };
}

type NetworkRole = keyof typeof networkPngBytes;

const networkRoles = [
  "lineCap",
  "lineStraight",
  "lineCorner",
] as const satisfies readonly NetworkRole[];

const oldAnchors: Record<NetworkRole, JsonRecord> = {
  lineCap: { x: 22, y: 30 },
  lineStraight: { x: 16, y: 31 },
  lineCorner: { x: 11, y: 31 },
};

const assetFingerprints: Record<NetworkRole, string> = {
  lineCap:
    "sha256:381689f91ad6678fd33ed14af549ef9eca2b053682b8eb88e4b671c757a152a2",
  lineStraight:
    "sha256:f9efff63cde566fd4da80d31f8241b7a6646cdcd059975038de2ac734f13d255",
  lineCorner:
    "sha256:ae579c1df284beb0a1a43a0eb32d61f719dffd3f79fd06d9ec555fdc66ff0c1d",
};

function primitive(id: string, role: NetworkRole, centered: boolean): JsonRecord {
  const anchorPx = centered ? { x: 16, y: 16 } : oldAnchors[role];
  return {
    id,
    sourceElementId: "fence-element",
    role,
    weight: 1000,
    anchorPx,
    transforms: {
      allowFlipX: true,
      allowedQuarterTurns: [0, 1, 2, 3],
    },
    currentMetrics: {
      assetFingerprint: assetFingerprints[role],
      pixelSize: { width: 32, height: 32 },
      opaqueBounds: { x: 0, y: 0, width: 32, height: 32 },
      defaultAnchorPx: anchorPx,
      occupancyMaskRle:
        role === "lineCorner"
          ? "border-rle-v1:1024:1:1,15,1,31,1,31,1,31,1,31,1,31,1,31,1,31,1,31,1,31,1,31,1,31,1,31,1,31,1,31,1,31,1,15,32,16,1,31,1,31,1,31,1,31,1,31,1,31,1,31,1,31,1,31,1,31,1,31,1,31,1,31,1,31,1,14,1"
          : "border-rle-v1:1024:1:1,511,32,479,1",
    },
  };
}

function publishParameters(
  stagedByRole: Record<NetworkRole, JsonRecord>,
): JsonRecord {
  const primitiveIds: Record<NetworkRole, string> = {
    lineCap: "cap",
    lineStraight: "span",
    lineCorner: "corner",
  };
  return {
    blueprintId: "fence",
    acceptedWarningCodes: [
      "border.publication.coverage_gap_exceeded",
      "border.publication.coverage_overlap_exceeded",
    ],
    primitiveSources: networkRoles.map((role) => ({
      primitiveId: primitiveIds[role],
      frames: [
        {
          artifactHandle: stagedByRole[role].artifactHandle,
          sourceProjectRelativePath: `assets/tilesets/${role}.png`,
        },
      ],
    })),
  };
}


test("STDIO MCP publishes horizontal facades and refuses unsupported strokes atomically", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-horizontal-facade-"));
  const client = new Client({ name: "horizontal-facade-test", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--dart", process.env.POKEMAP_TEST_DART ?? "dart", "--authoring-timeout-ms", "30000"],
    cwd: process.cwd(), stderr: "pipe" });
  await writeFile(join(root, "project.json"), JSON.stringify({
    name: "Facade transport", version: "v8", pokemon: canonicalPokemonConfig(),
    settings: { tileWidth: 32, tileHeight: 32 },
    maps: [{ id: "map", name: "Reception", relativePath: "map.json" }],
    tilesets: [{ id: "atlas", name: "Atlas", relativePath: "atlas.png" }],
    elements: [{ id: "fence-element", name: "Facade", tilesetId: "atlas", categoryId: "border",
      frames: [{ source: { x: 0, y: 0, width: 1, height: 1 } }] }],
  }));
  await writeFile(join(root, "atlas.png"), networkPngBytes.lineCap);
  await writeFile(join(root, "map.json"), JSON.stringify({ version: "v8", id: "map", name: "Reception",
    size: { width: 12, height: 10 }, visualStack: { semanticsVersion: 1 },
    layers: [{ runtimeType: "border", id: "border", name: "Facades", content: { formatVersion: 2, features: [] } }] }));
  let opened: JsonRecord | undefined;
  let sequence = 0;
  try {
    await client.connect(transport);
    const catalog = await toolData(client, "pokemap_describe");
    const descriptor = (catalog.mutationActions as JsonRecord[]).find(value => value.id === "border.blueprint.draft.upsert");
    assert.ok(descriptor);
    const contract = record(record(descriptor.extensions).horizontalFacade);
    assert.equal(contract.allowedAxis, "horizontal");
    assert.equal(contract.minimumCatalogFormatVersion, 11);
    assert.deepEqual(contract.canonicalGallery, ["longEdge", "endpoint", "opening"]);
    opened = await toolData(client, "pokemap_workspace", { operation: "open", projectRoot: root });
    async function plan(actionId: string, parameters: JsonRecord, failure = false): Promise<JsonRecord> {
      const validation = await toolData(client, "pokemap_validate", { projectHandle: opened!.projectHandle });
      const id = `facade-${++sequence}`;
      const response = await client.callTool({ name: "pokemap_plan", arguments: { projectHandle: opened!.projectHandle,
        request: { requestId: id, idempotencyKey: id, actionId, actionVersion: 1, parameters,
          workspaceHandle: opened!.workspaceHandle, expectedRevision: validation.snapshotRevision } } });
      const envelope = record(response.structuredContent);
      assert.equal(envelope.ok, !failure, JSON.stringify(envelope));
      return record(envelope[failure ? "error" : "data"]);
    }
    async function mutate(actionId: string, parameters: JsonRecord): Promise<void> {
      const planned = await plan(actionId, parameters);
      const result = await toolData(client, "pokemap_apply", { operation: "apply", projectHandle: opened!.projectHandle,
        planId: planned.planId, operationId: `facade-apply-${++sequence}` });
      assert.equal(record(result.receipt).status, "applied");
    }
    const draft = borderRecord("fence", true);
    const definition = record(record(draft.draft).definition);
    definition.template = "horizontalFacade";
    definition.primitives = (definition.primitives as JsonRecord[]).filter(value => value.role !== "lineCorner").map(value => ({
      ...value, transforms: { allowedQuarterTurns: [0], allowFlipX: false },
    }));
    await mutate("border.blueprint.draft.upsert", { record: draft });
    const primitiveSources: JsonRecord[] = [];
    for (const [role, primitiveId] of [["lineCap", "cap"], ["lineStraight", "span"]] as const) {
      const sourcePath = join(root, `${role}.png`);
      await writeFile(sourcePath, networkPngBytes[role]);
      const staged = await toolData(client, "pokemap_artifact_stage", { sourcePath, declaredMediaType: "image/png" });
      primitiveSources.push({ primitiveId, frames: [{ artifactHandle: staged.artifactHandle,
        sourceProjectRelativePath: `assets/tilesets/${role}.png` }] });
    }
    await mutate("border.blueprint.publish", { blueprintId: "fence", primitiveSources });
    const base = { mapId: "map", layerId: "border", name: "Facade", blueprintId: "fence", seed: "0" };
    const geometry = { kind: "stroke", strokes: [
      { id: "left", closed: false, points: [1, 2, 3].map(x => ({ x, y: 3 })) },
      { id: "right", closed: false, points: [7, 8, 9].map(x => ({ x, y: 3 })) },
    ] };
    await mutate("border_layer.feature_create", { ...base, featureId: "facade", geometry });
    await mutate("border_layer.materialize_apply", { mapId: "map", layerId: "border", featureId: "facade",
      tileWidthPx: 32, tileHeightPx: 32, resolverVersion: 3 });
    const batchDescriptor = (catalog.mutationActions as JsonRecord[]).find(value => value.id === "border_layer.materialize_batch_apply");
    assert.ok(batchDescriptor);
    assert.equal(record(batchDescriptor.extensions).maximumFeatureCount, 128);
    for (const [featureId, y] of [["facade-second", 5], ["facade-third", 7]] as const) {
      await mutate("border_layer.feature_create", { ...base, featureId, geometry: { kind: "stroke", strokes: [
        { id: featureId, closed: false, points: [1, 2, 3].map(x => ({ x, y })) },
      ] } });
    }
    const beforeBatch = await readFile(join(root, "map.json"));
    await plan("border_layer.materialize_batch_apply", { mapId: "map", features: [
      { layerId: "border", featureId: "facade-second" }, { layerId: "border", featureId: "missing" },
    ], tileWidthPx: 32, tileHeightPx: 32, resolverVersion: 3 }, true);
    assert.deepEqual(await readFile(join(root, "map.json")), beforeBatch);
    const historyBefore = (await readFile(join(root, ".pokemap/authoring/history.jsonl"), "utf8")).trimEnd().split("\n");
    await mutate("border_layer.materialize_batch_apply", { mapId: "map", features: [
      { layerId: "border", featureId: "facade-second" }, { layerId: "border", featureId: "facade-third" },
    ], tileWidthPx: 32, tileHeightPx: 32, resolverVersion: 3 });
    const historyAfter = (await readFile(join(root, ".pokemap/authoring/history.jsonl"), "utf8")).trimEnd().split("\n");
    assert.equal(historyAfter.length, historyBefore.length + 1);
    assert.deepEqual(historyAfter.slice(0, historyBefore.length), historyBefore);
    const mapPath = join(root, "map.json"), before = await readFile(mapPath);
    const saved = JSON.parse(before.toString()) as JsonRecord;
    const layer = (saved.layers as JsonRecord[]).find(value => value.id === "border");
    assert.ok(layer);
    const feature = (record(layer.content).features as JsonRecord[])[0]!;
    const generatedFeatures = record(layer.content).features as JsonRecord[];
    assert.equal(generatedFeatures.length, 3);
    for (const generated of generatedFeatures) assert.ok(generated.materialization);
    const placements = record(feature.materialization).placements as JsonRecord[];
    assert.equal(placements.length, 6);
    assert.deepEqual(placements.map(value => record(value.anchorCell).x), [1, 2, 3, 7, 8, 9]);
    for (const placement of placements) assert.deepEqual(placement.transform, { quarterTurns: 0, flipX: false });
    for (const points of [[{ x: 2, y: 1 }, { x: 2, y: 2 }],
      [{ x: 1, y: 1 }, { x: 2, y: 1 }, { x: 2, y: 2 }],
      [{ x: 1, y: 1 }, { x: 2, y: 2 }]]) {
      await plan("border_layer.feature_create", { ...base, featureId: "invalid",
        geometry: { kind: "stroke", strokes: [{ id: "invalid", closed: false, points }] } }, true);
      assert.deepEqual(await readFile(mapPath), before);
    }
    const manifest = JSON.parse(await readFile(join(root, "project.json"), "utf8")) as JsonRecord;
    assert.equal(record(manifest.borderCatalog).formatVersion, 11);
    const lastEntry = record(record(JSON.parse(historyAfter.at(-1)!)).payload).entry;
    const undo = await toolData(client, "pokemap_history", { operation: "undo", projectHandle: opened.projectHandle,
      entryId: record(lastEntry).entryId, idempotencyKey: "facade-batch-undo" });
    assert.ok(undo);
    assert.deepEqual(await readFile(mapPath), beforeBatch);
  } finally {
    if (opened) await toolData(client, "pokemap_workspace", { operation: "close", projectHandle: opened.projectHandle }).catch(() => {});
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

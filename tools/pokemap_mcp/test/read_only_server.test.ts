import assert from "node:assert/strict";
import { resolve } from "node:path";
import { test } from "node:test";

import { Client } from "@modelcontextprotocol/client";
import { InMemoryTransport } from "@modelcontextprotocol/server";

import { LocalAuthoringClient } from "../src/authoring_client.js";
import { MemoryArtifactReader } from "../src/artifacts.js";
import { createPokeMapMcpServer } from "../src/server.js";

const repositoryRoot = resolve(process.cwd(), "../..");
const projectRoot = resolve(
  repositoryRoot,
  "examples/playable_runtime_host/golden_fangame_slice",
);
const presentationProjectRoot = resolve(
  repositoryRoot,
  "examples/playable_runtime_host/golden_personalization_v3",
);
const authoringPackageRoot = resolve(repositoryRoot, "packages/map_authoring");

type JsonRecord = Record<string, unknown>;

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

async function connectReadOnlyServer(allowedProjectRoot = projectRoot) {
  const authoring = new LocalAuthoringClient({
    allowedRoots: [allowedProjectRoot],
    authoringPackageRoot,
  });
  const artifacts = new MemoryArtifactReader();
  const artifactUri = `artifact://sha256/${"a".repeat(64)}`;
  artifacts.registerText(artifactUri, "application/json", '{"ready":true}');

  const server = createPokeMapMcpServer({ authoring, artifacts });
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "pokemap-read-only-test", version: "1.0.0" });
  await server.connect(serverTransport);
  await client.connect(clientTransport);
  return { artifacts, artifactUri, authoring, client, server };
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

test("read-only MCP inspects a real project with cursor pagination", async () => {
  const fixture = await connectReadOnlyServer();
  try {
    const tools = await fixture.client.listTools();
    assert.deepEqual(
      tools.tools.map((tool) => tool.name),
      [
        "pokemap_artifact",
        "pokemap_describe",
        "pokemap_query",
        "pokemap_validate",
        "pokemap_workspace",
        "pokemap_artifact_stage",
        "pokemap_plan",
        "pokemap_apply",
        "pokemap_history",
        "pokemap_recovery",
      ],
    );
    assert.ok(tools.tools.slice(0, 5).every((tool) => tool.annotations?.readOnlyHint));
    assert.ok(tools.tools.slice(5).every((tool) => !tool.annotations?.readOnlyHint));

    const description = await toolData(fixture.client, "pokemap_describe");
    assert.equal(description.protocol, "pokemap.authoring.v1");
    assert.equal(description.readOnly, false);

    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot,
    });
    const projectHandle = String(opened.projectHandle);
    const workspaceHandle = String(opened.workspaceHandle);

    const first = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "map",
      operation: "list",
      view: "summary",
      pageSize: 1,
    });
    assert.equal(first.returned, 1);
    assert.equal(first.totalAvailable, 3);
    assert.equal(typeof first.nextCursor, "string");

    const second = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "map",
      operation: "list",
      view: "summary",
      pageSize: 1,
      cursor: first.nextCursor,
    });
    assert.equal(second.returned, 1);
    assert.notDeepEqual(first.items, second.items);

    const validation = await toolData(fixture.client, "pokemap_validate", {
      projectHandle,
    });
    assert.match(String(validation.snapshotRevision), /^sha256:[0-9a-f]{64}$/);
    const structure = record(validation.structure);
    const references = record(validation.references);
    const pokemonCatalog = record(validation.pokemonCatalog);
    const capabilityCertification = record(
      validation.capabilityCertification,
    );
    assert.equal(structure.valid, true);
    assert.equal(typeof references.valid, "boolean");
    assert.equal(capabilityCertification.requested, false);
    assert.equal(capabilityCertification.status, "not_requested");
    assert.equal(capabilityCertification.valid, null);
    assert.equal(
      validation.valid,
      Boolean(structure.valid) &&
        Boolean(references.valid) &&
        Boolean(pokemonCatalog.canPlaytest),
    );

    const closed = await toolData(fixture.client, "pokemap_workspace", {
      operation: "close",
      workspaceHandle,
    });
    assert.equal(closed.closed, true);
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
  }
});

test("MCP exposes paginated project presentation preview contexts", async () => {
  const fixture = await connectReadOnlyServer(presentationProjectRoot);
  try {
    const description = await toolData(fixture.client, "pokemap_describe");
    const resource = (description.resourceKinds as JsonRecord[]).find(
      (kind) => kind.id === "presentationPreviewContext",
    );
    assert.equal(resource?.version, 2);
    const presentationProfile = (
      description.resourceKinds as JsonRecord[]
    ).find((kind) => kind.id === "projectPresentationProfile");
    assert.equal(presentationProfile?.version, 10);

    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot: presentationProjectRoot,
    });
    const first = await toolData(fixture.client, "pokemap_query", {
      projectHandle: String(opened.projectHandle),
      resourceKind: "presentationPreviewContext",
      operation: "list",
      view: "detail",
      pageSize: 2,
    });

    assert.equal(first.totalAvailable, 7);
    assert.equal(first.returned, 2);
    assert.equal(typeof first.nextCursor, "string");
    assert.deepEqual(
      (first.items as JsonRecord[]).map((item) => item.id),
      ["characterPortrait:leo:happy", "dialogue:welcome_leo"],
    );
    assert.equal(record((first.items as JsonRecord[])[0]).availability, "ready");

    const second = await toolData(fixture.client, "pokemap_query", {
      projectHandle: String(opened.projectHandle),
      resourceKind: "presentationPreviewContext",
      operation: "list",
      view: "detail",
      pageSize: 2,
      cursor: first.nextCursor,
    });
    assert.deepEqual(
      (second.items as JsonRecord[]).map((item) => item.id),
      [
        "dialogueScenario:welcome_leo:0:0",
        "dialogueScenario:welcome_leo:0:1",
      ],
    );
    const characterLine = record((second.items as JsonRecord[])[0]);
    assert.equal(characterLine.scenarioKind, "characterLine");
    assert.equal(characterLine.characterName, "Léo");
    assert.equal(characterLine.portraitAssetId, "portrait-leo-happy");

    const choice = await toolData(fixture.client, "pokemap_query", {
      projectHandle: String(opened.projectHandle),
      resourceKind: "presentationPreviewContext",
      operation: "get",
      view: "detail",
      ids: ["dialogueScenario:welcome_leo:0:2"],
    });
    const choiceContext = record((choice.items as JsonRecord[])[0]);
    assert.equal(choiceContext.scenarioKind, "choice");
    assert.deepEqual(
      (choiceContext.choices as JsonRecord[]).map((entry) => entry.label),
      ["Partir explorer", "Rester au village"],
    );
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
  }
});

test("MCP exposes connection and bounded world graph reads", async () => {
  const fixture = await connectReadOnlyServer();
  try {
    const description = await toolData(fixture.client, "pokemap_describe");
    const resourceKinds = description.resourceKinds as JsonRecord[];
    const resourceKindIds = resourceKinds.map((kind) => String(kind.id));
    for (const resourceKind of [
      "mapConnection",
      "worldGraph",
      "worldGraphEdge",
      "worldGraphIssue",
      "worldGraphNode",
    ]) {
      assert.ok(resourceKindIds.includes(resourceKind), resourceKind);
    }
    const mapConnection = resourceKinds.find(
      (kind) => kind.id === "mapConnection",
    );
    assert.ok(mapConnection);
    assert.deepEqual(record(mapConnection.extensions).queryActions, [
      "connection.list",
      "connection.get",
      "connection.preview_alignment",
      "connection.validate",
    ]);

    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot,
    });
    const projectHandle = String(opened.projectHandle);

    const connections = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "mapConnection",
      operation: "list",
      view: "detail",
    });
    assert.equal(typeof connections.totalAvailable, "number");

    const mapConnections = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "map",
      operation: "get",
      ids: ["golden_route"],
      fieldMask: ["connections"],
    });
    assert.ok(
      Array.isArray(record((mapConnections.items as unknown[])[0]).connections),
    );

    const preview = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "mapConnection",
      operation: "summary",
      view: "detail",
      extensions: {
        actionId: "connection.preview_alignment",
        parameters: {
          mapId: "golden_route",
          targetMapId: "golden_town",
          direction: "east",
          offset: 0,
        },
      },
    });
    assert.equal(record((preview.items as unknown[])[0]).overlapLength, 5);

    const validation = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "mapConnection",
      operation: "summary",
      view: "detail",
      extensions: {
        actionId: "connection.validate",
        parameters: {},
      },
    });
    assert.equal(
      typeof record((validation.items as unknown[])[0]).valid,
      "boolean",
    );

    const graph = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "worldGraph",
      operation: "get",
      view: "detail",
      ids: ["world-graph"],
      extensions: {
        actionId: "world_graph.inspect",
        parameters: {},
      },
    });
    const graphItem = record((graph.items as unknown[])[0]);
    assert.equal(graphItem.nodeCount, 3);
    assert.equal(graphItem.actionId, "world_graph.inspect");
    assert.deepEqual(record(graphItem.resources), {
      nodes: "worldGraphNode",
      edges: "worldGraphEdge",
      issues: "worldGraphIssue",
    });

    const connected = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "worldGraphNode",
      operation: "list",
      view: "detail",
      pageSize: 1,
      extensions: {
        actionId: "world_graph.list_connected",
        parameters: { fromMapId: "golden_route" },
      },
    });
    assert.equal(connected.returned, 1);
    assert.ok(Number(connected.totalAvailable) >= 1);

    const issues = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "worldGraphIssue",
      operation: "list",
      view: "detail",
      pageSize: 1,
      extensions: {
        actionId: "world_graph.validate_consistency",
        parameters: {},
      },
    });
    assert.equal(typeof issues.totalAvailable, "number");
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
  }
});

test("resource templates project map catalog and diagnostics use explicit handles", async () => {
  const fixture = await connectReadOnlyServer();
  try {
    const opened = await toolData(fixture.client, "pokemap_workspace", {
      operation: "open",
      projectRoot,
    });
    const projectHandle = String(opened.projectHandle);

    const templates = await fixture.client.listResourceTemplates();
    assert.deepEqual(
      templates.resourceTemplates.map((template) => template.uriTemplate),
      [
        "pokemap://project/{projectHandle}",
        "pokemap://project/{projectHandle}/catalog/{resourceKind}",
        "pokemap://project/{projectHandle}/diagnostics",
        "pokemap://project/{projectHandle}/map/{mapId}",
      ],
    );

    const projectResource = await fixture.client.readResource({
      uri: `pokemap://project/${encodeURIComponent(projectHandle)}`,
    });
    const projectContent = projectResource.contents[0];
    assert.ok(projectContent && "text" in projectContent);
    const project = record(JSON.parse(projectContent.text));
    assert.equal(record((project.items as unknown[])[0]).name, "Golden Fangame Slice");

    const maps = await toolData(fixture.client, "pokemap_query", {
      projectHandle,
      resourceKind: "map",
      operation: "list",
      view: "summary",
      pageSize: 1,
    });
    const mapId = String(record((maps.items as unknown[])[0]).id);
    const mapResource = await fixture.client.readResource({
      uri: `pokemap://project/${encodeURIComponent(projectHandle)}/map/${encodeURIComponent(mapId)}`,
    });
    const mapContent = mapResource.contents[0];
    assert.ok(mapContent && "text" in mapContent);
    assert.equal(record((record(JSON.parse(mapContent.text)).items as unknown[])[0]).id, mapId);

    const diagnostics = await fixture.client.readResource({
      uri: `pokemap://project/${encodeURIComponent(projectHandle)}/diagnostics`,
    });
    assert.equal(diagnostics.contents[0]?.mimeType, "application/json");

    const catalog = await fixture.client.readResource({
      uri: `pokemap://project/${encodeURIComponent(projectHandle)}/catalog/asset`,
    });
    assert.equal(catalog.contents[0]?.mimeType, "application/json");

    await assert.rejects(
      fixture.client.readResource({ uri: "pokemap://project/../../etc/passwd" }),
      /resource|uri|not found/i,
    );
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
  }
});

test("artifact reads are handle-only and unknown handles fail closed", async () => {
  const fixture = await connectReadOnlyServer();
  try {
    const artifact = await toolData(fixture.client, "pokemap_artifact", {
      uri: fixture.artifactUri,
    });
    assert.equal(artifact.uri, fixture.artifactUri);
    assert.equal(artifact.mediaType, "application/json");
    assert.equal(artifact.text, '{"ready":true}');

    const unknown = await fixture.client.callTool({
      name: "pokemap_artifact",
      arguments: { uri: `artifact://sha256/${"b".repeat(64)}` },
    });
    assert.equal(unknown.isError, true);
    const envelope = record(unknown.structuredContent);
    assert.equal(record(envelope.error).code, "artifact.unknown");

    const invalidScheme = await fixture.client.callTool({
      name: "pokemap_artifact",
      arguments: { uri: "file:///etc/passwd" },
    });
    assert.equal(invalidScheme.isError, true);
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
  }
});

test("workspace open cannot escape the configured roots", async () => {
  const fixture = await connectReadOnlyServer();
  try {
    const result = await fixture.client.callTool({
      name: "pokemap_workspace",
      arguments: { operation: "open", projectRoot: repositoryRoot },
    });
    assert.equal(result.isError, true);
    const envelope = record(result.structuredContent);
    const error = record(envelope.error);
    assert.equal(error.code, "permission_denied");
    assert.equal(error.domainCode, "workspace.path_outside_allowed_roots");
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await fixture.authoring.close();
  }
});

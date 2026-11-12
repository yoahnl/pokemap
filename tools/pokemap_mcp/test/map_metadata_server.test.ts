import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import test from "node:test";

import { Client } from "@modelcontextprotocol/client";
import { InMemoryTransport } from "@modelcontextprotocol/server";

import { LocalAuthoringClient, type JsonRecord } from "../src/authoring_client.js";
import { MemoryArtifactReader } from "../src/artifacts.js";
import { createPokeMapMcpServer } from "../src/server.js";
import { canonicalPokemonConfig } from "./pokemon_fixture.js";

async function data(client: Client, name: string, args: JsonRecord = {}) {
  const result = await client.callTool({ name, arguments: args });
  assert.equal(result.isError, undefined, JSON.stringify(result.structuredContent));
  const envelope = result.structuredContent as JsonRecord;
  assert.equal(envelope.ok, true);
  return envelope.data as JsonRecord;
}

test("MCP updates map title and indoor role without changing identity or path", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-mcp-map-title-"));
  const map = {
    id: "town", name: "Town", version: "v8", tilesetId: "",
    size: { width: 5, height: 4 }, layers: [],
    warps: [{ id: "return", pos: { x: 1, y: 1 },
      targetMapId: "town", targetPos: { x: 2, y: 2 }, triggerMode: "on_enter",
      allowedApproachFacings: [], triggerPadding: { left: 0, right: 0, top: 0, bottom: 0 }, transition: { type: "fade", durationSeconds: 0.2 } }],
  };
  await mkdir(join(root, "documents"));
  await writeFile(join(root, "documents/unusual.json"), JSON.stringify(map));
  await writeFile(join(root, "items.json"), JSON.stringify({ schemaVersion: 1, entries: [{ id: "rope", displayName: "Corde Sortie", pocketId: "items" }] }));
  await writeFile(join(root, "project.json"), JSON.stringify({
    name: "Map title fixture", version: "v8", tilesets: [], pokemon: { ...canonicalPokemonConfig(), catalogFiles: { items: "items.json" } },
    scenes: [{ id: "secret", name: "Secret", graph: { startNodeId: "start", nodes: [
      { id: "start", kind: "start" }, { id: "end", kind: "end" },
    ], edges: [{ id: "edge", fromNodeId: "start", fromPortId: "completed", toNodeId: "end", kind: "default" }] } }],
    groups: [{ id: "cave", name: "Grotte", type: "dungeon" }],
    maps: [{ id: "town", name: "Town", relativePath: "documents/unusual.json" }],
  }));
  const authoring = new LocalAuthoringClient({
    allowedRoots: [root], authoringPackageRoot: resolve(process.cwd(), "../../packages/map_authoring"),
    dartExecutable: process.env.DART ?? "dart",
    requestTimeoutMs: 60_000, workerTimeoutMs: 45_000,
  });
  const server = createPokeMapMcpServer({ authoring, artifacts: new MemoryArtifactReader() });
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "pokemap-map-title-test", version: "1.0.0" });
  await server.connect(serverTransport);
  await client.connect(clientTransport);
  try {
    const described = await data(client, "pokemap_describe");
    const descriptor = (described.mutationActions as JsonRecord[])
      .find((action) => action.id === "map.update_metadata");
    assert.equal(descriptor?.inputSchemaId, "schema.map.update_metadata.input.v1");
    const schema = (descriptor?.extensions as JsonRecord).inputSchema as JsonRecord;
    assert.deepEqual(schema.required, ["mapId"]);
    assert.deepEqual(schema.anyOf, [
      { required: ["name"] }, { required: ["role"] }, { required: ["isIndoor"] }, { required: ["allowBicycle"] }, { required: ["allowEscapeRope"] }, { required: ["escapeRopeDungeonId"] }, { required: ["contextualItemUses"] }, { required: ["defaultSpawnId"] },
    ]);
    const properties = schema.properties as JsonRecord;
    assert.deepEqual((properties.defaultSpawnId as JsonRecord).type, ["string", "null"]);
    assert.equal((properties.isIndoor as JsonRecord).type, "boolean");
    assert.ok(((properties.role as JsonRecord).enum as string[]).includes("interior"));
    assert.equal(schema.additionalProperties, false);
    const opened = await data(client, "pokemap_workspace", { operation: "open", projectRoot: root });
    const projectHandle = opened.projectHandle;
    const validation = await data(client, "pokemap_validate", { projectHandle });
    const planned = await data(client, "pokemap_plan", { projectHandle,
      request: { requestId: "title", actionId: "map.update_metadata", actionVersion: 1,
        workspaceHandle: opened.workspaceHandle, parameters: { mapId: "town", name: " Village été " },
        expectedRevision: validation.snapshotRevision, idempotencyKey: "title" },
    });
    assert.equal(JSON.parse(await readFile(join(root, "documents/unusual.json"), "utf8")).name, "Town");
    await data(client, "pokemap_apply", { operation: "apply", projectHandle,
      planId: planned.planId, operationId: "title" });
    const updated = JSON.parse(await readFile(join(root, "documents/unusual.json"), "utf8"));
    const manifest = JSON.parse(await readFile(join(root, "project.json"), "utf8"));
    assert.equal(updated.name, "Village été");
    for (const [key, value] of Object.entries(map)) {
      if (key !== "name") assert.deepEqual(updated[key], value);
    }
    assert.equal(manifest.maps[0].id, "town");
    assert.equal(manifest.maps[0].name, "Village été");
    assert.equal(manifest.maps[0].relativePath, "documents/unusual.json");
    const revision = await data(client, "pokemap_validate", { projectHandle });
    const noop = await client.callTool({ name: "pokemap_plan", arguments: { projectHandle,
      request: { requestId: "same", actionId: "map.update_metadata", actionVersion: 1,
        workspaceHandle: opened.workspaceHandle, parameters: { mapId: "town", name: "Village été" },
        expectedRevision: revision.snapshotRevision, idempotencyKey: "same" },
    } });
    assert.equal(noop.isError, true);
    assert.match(JSON.stringify(noop.structuredContent), /map.no_change/);
    const indoor = await data(client, "pokemap_plan", { projectHandle,
      request: { requestId: "indoor", actionId: "map.update_metadata", actionVersion: 1,
        workspaceHandle: opened.workspaceHandle,
        parameters: { mapId: "town", role: "interior", isIndoor: true },
        expectedRevision: revision.snapshotRevision, idempotencyKey: "indoor" },
    });
    assert.equal(JSON.parse(await readFile(join(root, "project.json"), "utf8")).maps[0].role, "exterior");
    await data(client, "pokemap_apply", { operation: "apply", projectHandle,
      planId: indoor.planId, operationId: "indoor" });
    const indoorMap = JSON.parse(await readFile(join(root, "documents/unusual.json"), "utf8"));
    const indoorManifest = JSON.parse(await readFile(join(root, "project.json"), "utf8"));
    assert.equal(indoorMap.mapMetadata.isIndoor, true);
    assert.equal(indoorManifest.maps[0].role, "interior");
    assert.equal(indoorMap.name, "Village été");
    assert.equal(indoorManifest.maps[0].name, "Village été");
    assert.equal(indoorManifest.maps[0].relativePath, "documents/unusual.json");
    assert.deepEqual(indoorMap.warps, updated.warps);
    const indoorRevision = await data(client, "pokemap_validate", { projectHandle });
    const conflict = await client.callTool({ name: "pokemap_plan", arguments: { projectHandle,
      request: { requestId: "conflict", actionId: "map.update_metadata", actionVersion: 1,
        workspaceHandle: opened.workspaceHandle,
        parameters: { mapId: "town", role: "interior", isIndoor: false },
        expectedRevision: indoorRevision.snapshotRevision, idempotencyKey: "conflict" },
    } });
    assert.equal(conflict.isError, true);
    assert.match(JSON.stringify(conflict.structuredContent), /map.metadata_inconsistent/);
    assert.deepEqual(JSON.parse(await readFile(join(root, "documents/unusual.json"), "utf8")), indoorMap);
    assert.deepEqual(JSON.parse(await readFile(join(root, "project.json"), "utf8")), indoorManifest);
    const escapeRevision = await data(client, "pokemap_validate", { projectHandle });
    const escape = await data(client, "pokemap_plan", { projectHandle,
      request: { requestId: "rope", actionId: "map.update_metadata", actionVersion: 1,
        workspaceHandle: opened.workspaceHandle,
        parameters: { mapId: "town", escapeRopeDungeonId: "cave", allowEscapeRope: false },
        expectedRevision: escapeRevision.snapshotRevision, idempotencyKey: "rope" },
    });
    await data(client, "pokemap_apply", { operation: "apply", projectHandle,
      planId: escape.planId, operationId: "rope" });
    const escapeMap = JSON.parse(await readFile(join(root, "documents/unusual.json"), "utf8"));
    assert.equal(escapeMap.mapMetadata.escapeRopeDungeonId, "cave");
    assert.equal(escapeMap.mapMetadata.allowEscapeRope, false);
    assert.deepEqual(escapeMap.warps, indoorMap.warps);
    assert.deepEqual(JSON.parse(await readFile(join(root, "project.json"), "utf8")), indoorManifest);
    const contextualRevision = await data(client, "pokemap_validate", { projectHandle });
    const rules = [{ id: "secret-use", itemId: "rope", sceneId: "secret", priority: 10, position: { x: 2, y: 2 }, facing: "north" }];
    const contextual = await data(client, "pokemap_plan", { projectHandle,
      request: { requestId: "contextual", actionId: "map.update_metadata", actionVersion: 1,
        workspaceHandle: opened.workspaceHandle, parameters: { mapId: "town", contextualItemUses: rules },
        expectedRevision: contextualRevision.snapshotRevision, idempotencyKey: "contextual" },
    });
    await data(client, "pokemap_apply", { operation: "apply", projectHandle, planId: contextual.planId, operationId: "contextual" });
    assert.deepEqual(JSON.parse(await readFile(join(root, "documents/unusual.json"), "utf8")).mapMetadata.contextualItemUses, rules);
    const afterContext = await data(client, "pokemap_validate", { projectHandle });
    const invalidContext = await client.callTool({ name: "pokemap_plan", arguments: { projectHandle,
      request: { requestId: "bad-context", actionId: "map.update_metadata", actionVersion: 1,
        workspaceHandle: opened.workspaceHandle, parameters: { mapId: "town", contextualItemUses: [{ ...rules[0], sceneId: "missing" }] },
        expectedRevision: afterContext.snapshotRevision, idempotencyKey: "bad-context" },
    } });
    assert.equal(invalidContext.isError, true);
    assert.deepEqual(JSON.parse(await readFile(join(root, "documents/unusual.json"), "utf8")).mapMetadata.contextualItemUses, rules);
    const partitionRevision = await data(client, "pokemap_validate", { projectHandle });
    const partition = await data(client, "pokemap_plan", { projectHandle, request: {
      requestId: "partition", actionId: "project.catalog.partition", actionVersion: 1, workspaceHandle: opened.workspaceHandle,
      expectedRevision: partitionRevision.snapshotRevision, idempotencyKey: "partition", parameters: {},
    } });
    await data(client, "pokemap_apply", { operation: "apply", projectHandle, planId: partition.planId, operationId: "partition" });
    await data(client, "pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
    const native = await data(client, "pokemap_workspace", { operation: "open", projectRoot: root });
    const groups = { groups: [{ id: "cave", name: "Grotte", type: "dungeon" }, { id: "alpha", name: "Alpha", type: "dungeon" }], assignments: [] };
    const selected = await data(client, "pokemap_workshop", { operation: "read", projectHandle: native.projectHandle,
      actionId: "map.library.reorganize", parameters: groups, includeDocuments: false });
    const addition = await data(client, "pokemap_plan", { projectHandle: native.projectHandle, request: {
      requestId: "add-group", actionId: "map.library.reorganize", actionVersion: 1, workspaceHandle: native.workspaceHandle,
      expectedRevision: selected.snapshotRevision, idempotencyKey: "add-group", parameters: groups, extensions: selected.planExtensions,
    } });
    await data(client, "pokemap_apply", { operation: "apply", projectHandle: native.projectHandle, planId: addition.planId, operationId: "add-group" });
    const nativeParams = { mapId: "town", contextualItemUses: [{ ...rules[0], priority: 11 }] };
    const nativeScope = await data(client, "pokemap_workshop", { operation: "read", projectHandle: native.projectHandle,
      actionId: "map.update_metadata", parameters: nativeParams, includeDocuments: false });
    const nativePlan = await data(client, "pokemap_plan", { projectHandle: native.projectHandle, request: {
      requestId: "native-context", actionId: "map.update_metadata", actionVersion: 1, workspaceHandle: native.workspaceHandle,
      expectedRevision: nativeScope.snapshotRevision, idempotencyKey: "native-context", parameters: nativeParams, extensions: nativeScope.planExtensions,
    } });
    await data(client, "pokemap_apply", { operation: "apply", projectHandle: native.projectHandle, planId: nativePlan.planId, operationId: "native-context" });
    assert.deepEqual(JSON.parse(await readFile(join(root, "documents/unusual.json"), "utf8")).mapMetadata.contextualItemUses, nativeParams.contextualItemUses);
    await data(client, "pokemap_workspace", { operation: "close", workspaceHandle: native.workspaceHandle });
  } finally {
    await client.close();
    await server.close();
    await authoring.close();
    await rm(root, { recursive: true, force: true });
  }
});

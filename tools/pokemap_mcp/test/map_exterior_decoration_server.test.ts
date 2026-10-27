import assert from "node:assert/strict";
import test from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { InMemoryTransport } from "@modelcontextprotocol/server";
import { createPokeMapMcpServer } from "../src/server.js";
import { MemoryArtifactReader } from "../src/artifacts.js";
import type { AuthoringGateway, JsonRecord } from "../src/authoring_client.js";

test("exterior decoration exposes targeted inspection and revision checked sector edits", async () => {
  const calls: {command: string; args: JsonRecord}[] = [];
  const authoring: AuthoringGateway = {
    async request(command, args = {}) {
      calls.push({command, args});
      return {requestId: "exterior-1", data: {revision: "sha256:current"}, artifacts: []};
    },
    async close() {},
  };
  const server = createPokeMapMcpServer({authoring, artifacts: new MemoryArtifactReader()});
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  const client = new Client({name: "exterior-decoration-test", version: "1"});
  await server.connect(serverTransport);
  await client.connect(clientTransport);
  try {
    const names = (await client.listTools()).tools.map(tool => tool.name);
    for (const operation of ["inspect", "configure", "sector_set", "sector_batch", "native_catalog", "native_edit", "references_prepare", "sector_remove", "border_set", "border_remove", "undo"]) {
      assert.ok(names.includes(`pokemap_map_exterior_decoration_${operation}`), operation);
    }
    const identity = {projectRoot: "/allowed/project", mapId: "route"};
    const prepare = {...identity, expectedRevision: "sha256:before", operationId: "prepare-incoming"};
    await client.callTool({name: "pokemap_map_exterior_decoration_references_prepare", arguments: prepare});
    assert.deepEqual(calls.at(-1), {command: "map_exterior_decoration_references_prepare", args: prepare});
    await client.callTool({name: "pokemap_map_exterior_decoration_inspect", arguments: {...identity, sectorIds: ["west"]}});
    assert.deepEqual(calls.at(-1), {command: "map_exterior_decoration_inspect", args: {...identity, sectorIds: ["west"]}});
    const sector = {id: "west", originX: -2, originZ: 0, scene: {width: 2, depth: 2}, layers: []};
    const input = {...identity, expectedRevision: "sha256:before", operationId: "sector-edit", sector};
    await client.callTool({name: "pokemap_map_exterior_decoration_sector_set", arguments: input});
    assert.deepEqual(calls.at(-1), {command: "map_exterior_decoration_sector_set", args: input});
    const borderInput = {...identity, expectedRevision: "sha256:before", operationId: "border-edit", border: {id: "shore"}};
    await client.callTool({name: "pokemap_map_exterior_decoration_border_set", arguments: borderInput});
    assert.deepEqual(calls.at(-1), {command: "map_exterior_decoration_border_set", args: borderInput});
    const batchInput = {...identity, expectedRevision: "sha256:before", operationId: "batch-edit", sectors: [sector]};
    await client.callTool({name: "pokemap_map_exterior_decoration_sector_batch", arguments: batchInput});
    assert.deepEqual(calls.at(-1), {command: "map_exterior_decoration_sector_batch", args: batchInput});
    const nativeInput = {...identity, expectedRevision: "sha256:before", expectedCatalogRevision: "sha256:catalog", operationId: "native-edit", edit: {kind: "environment.generate", presetId: "trees", sectorId: "west", areaId: "trees", cells: [{x: -1, z: 1}], seed: 42}};
    await client.callTool({name: "pokemap_map_exterior_decoration_native_edit", arguments: nativeInput});
    assert.deepEqual(calls.at(-1), {command: "map_exterior_decoration_native_edit", args: nativeInput});
    const before = calls.length;
    const {expectedCatalogRevision: omitted, ...missingCatalog} = nativeInput;
    assert.ok(omitted);
    assert.equal((await client.callTool({name: "pokemap_map_exterior_decoration_native_edit", arguments: missingCatalog})).isError, true);
    assert.equal(calls.length, before);
    const rejected = await client.callTool({name: "pokemap_map_exterior_decoration_sector_set", arguments: {...identity, sector}});
    assert.equal(rejected.isError, true);
    assert.equal(calls.length, before);
  } finally {
    await client.close();
    await server.close();
  }
});

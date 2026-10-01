import assert from "node:assert/strict";
import { access, mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import test from "node:test";

import { Client } from "@modelcontextprotocol/client";
import { InMemoryTransport } from "@modelcontextprotocol/server";

import type { JsonRecord } from "../src/authoring_client.js";
import { canonicalPokemonConfig } from "./pokemon_fixture.js";

async function data(client: Client, name: string, args: JsonRecord = {}) {
  const result = await client.callTool({ name, arguments: args });
  assert.equal(result.isError, undefined, JSON.stringify(result.structuredContent));
  const envelope = result.structuredContent as JsonRecord;
  assert.equal(envelope.ok, true);
  return envelope.data as JsonRecord;
}

test("packaged MCP applies map lifecycle transactions and preserves their safety checks", async () => {
  const compiledDirectory = "../dist/src";
  const { LocalAuthoringClient } = await import(`${compiledDirectory}/authoring_client.js`);
  const { MemoryArtifactReader } = await import(`${compiledDirectory}/artifacts.js`);
  const { createPokeMapMcpServer } = await import(`${compiledDirectory}/server.js`);
  const root = await mkdtemp(join(tmpdir(), "pokemap-mcp-map-lifecycle-"));
  const source = {
    id: "town", name: "Town", version: "v8", tilesetId: "",
    size: { width: 5, height: 4 }, layers: [],
    warps: [{ id: "return", pos: { x: 1, y: 1 },
      targetMapId: "town", targetPos: { x: 2, y: 2 }, triggerMode: "on_enter",
      allowedApproachFacings: [], triggerPadding: { left: 0, right: 0, top: 0, bottom: 0 } }],
  };
  await mkdir(join(root, "documents"));
  const sourcePath = join(root, "documents/unusual.json");
  await writeFile(sourcePath, JSON.stringify(source));
  await writeFile(join(root, "project.json"), JSON.stringify({
    name: "Map lifecycle fixture", version: "v8", tilesets: [],
    pokemon: canonicalPokemonConfig(), newGame: { enabled: false, startMapId: "town" },
    groups: [{ id: "folder", name: "Folder", type: "city" }],
    maps: [{ id: "town", name: "Town", relativePath: "documents/unusual.json" }],
  }));
  const authoring = new LocalAuthoringClient({
    allowedRoots: [root], authoringPackageRoot: resolve(process.cwd(), "../../packages/map_authoring"),
    dartExecutable: process.env.DART ?? "dart",
  });
  const server = createPokeMapMcpServer({ authoring, artifacts: new MemoryArtifactReader() });
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "pokemap-map-lifecycle-test", version: "1.0.0" });
  await server.connect(serverTransport);
  await client.connect(clientTransport);
  try {
    const before = await readFile(sourcePath);
    const described = await data(client, "pokemap_describe");
    const descriptor = (described.mutationActions as JsonRecord[])
      .find((action) => action.id === "map.duplicate");
    const schema = (descriptor?.extensions as JsonRecord).inputSchema as JsonRecord;
    assert.deepEqual((schema.properties as JsonRecord).groupId, { type: ["string", "null"] });
    assert.equal(schema.selfReferences, "sourceMap");
    const opened = await data(client, "pokemap_workspace", { operation: "open", projectRoot: root });
    const projectHandle = opened.projectHandle;
    let sequence = 0;
    async function plan(actionId: string, parameters: JsonRecord) {
      const validated = await data(client, "pokemap_validate", { projectHandle });
      const id = `map-operation-${sequence++}`;
      return data(client, "pokemap_plan", { projectHandle,
        request: { requestId: id, actionId, actionVersion: 1,
          workspaceHandle: opened.workspaceHandle, parameters,
          expectedRevision: validated.snapshotRevision, idempotencyKey: id },
      });
    }
    async function apply(planned: JsonRecord, destructive = false) {
      const confirmation = destructive ? await data(client, "pokemap_apply", {
        operation: "confirm", projectHandle, planId: planned.planId,
      }) : {};
      const result = await data(client, "pokemap_apply", { operation: "apply", projectHandle,
        planId: planned.planId, operationId: `apply-${sequence++}`,
        ...(destructive ? { confirmationToken: confirmation.confirmationToken } : {}),
      });
      assert.equal((result.receipt as JsonRecord).status, "applied");
    }
    async function maps() {
      const queried = await data(client, "pokemap_query", {
        projectHandle, resourceKind: "map", operation: "list", view: "summary", pageSize: 200,
      });
      return queried.items as JsonRecord[];
    }
    const blockedRevision = await data(client, "pokemap_validate", { projectHandle });
    const blocked = await client.callTool({ name: "pokemap_plan", arguments: { projectHandle,
      request: { requestId: "delete-start", actionId: "map.delete_apply", actionVersion: 1,
        workspaceHandle: opened.workspaceHandle, parameters: { mapId: "town" },
        expectedRevision: blockedRevision.snapshotRevision, idempotencyKey: "delete-start" },
    } });
    assert.equal(blocked.isError, true);
    assert.match(JSON.stringify(blocked.structuredContent), /map.references_blocking/);
    const duplicated = await plan("map.duplicate", {
      sourceMapId: "town", targetMapId: "copy", name: "Copy", groupId: "folder",
    });
    assert.deepEqual(await readFile(sourcePath), before);
    await apply(duplicated);
    const manifest = JSON.parse(await readFile(join(root, "project.json"), "utf8"));
    const copyEntry = (manifest.maps as JsonRecord[]).find((entry) => entry.id === "copy");
    assert.ok(copyEntry);
    assert.equal(copyEntry.groupId, "folder");
    const copyPath = join(root, String(copyEntry.relativePath));
    const copied = JSON.parse(await readFile(copyPath, "utf8"));
    assert.equal(copied.warps[0].targetMapId, "town");
    assert.deepEqual(copied.size, source.size);
    assert.ok((await maps()).some((map) => map.id === "copy"));
    await apply(await plan("map.resize_apply", { mapId: "copy", width: 7, height: 6 }));
    assert.deepEqual(JSON.parse(await readFile(copyPath, "utf8")).size, { width: 7, height: 6 });
    const resource = await client.readResource({
      uri: `pokemap://project/${encodeURIComponent(String(projectHandle))}/map/copy`,
    });
    const content = resource.contents[0];
    assert.ok(content && "text" in content);
    const mapDetail = (JSON.parse(content.text).items as JsonRecord[])[0];
    assert.ok(mapDetail);
    assert.equal(mapDetail.id, "copy");
    assert.deepEqual(mapDetail.size, { width: 7, height: 6 });
    const stale = await plan("map.resize_apply", { mapId: "copy", width: 8, height: 6 });
    const edited = JSON.parse(await readFile(copyPath, "utf8"));
    edited.name = "Concurrent copy";
    await writeFile(copyPath, JSON.stringify(edited));
    const editedBytes = await readFile(copyPath);
    const denied = await client.callTool({ name: "pokemap_apply", arguments: {
      operation: "apply", projectHandle, planId: stale.planId, operationId: "stale-copy",
    } });
    assert.equal(denied.isError, true);
    assert.match(JSON.stringify(denied.structuredContent), /revision_conflict|plan.stale/);
    assert.deepEqual(await readFile(copyPath), editedBytes);
    const deletion = await plan("map.delete_apply", { mapId: "copy" });
    const unconfirmed = await client.callTool({ name: "pokemap_apply", arguments: {
      operation: "apply", projectHandle, planId: deletion.planId, operationId: "unconfirmed-copy",
    } });
    assert.equal(unconfirmed.isError, true);
    assert.match(JSON.stringify(unconfirmed.structuredContent), /confirmation.required/);
    assert.deepEqual(await readFile(copyPath), editedBytes);
    await apply(deletion, true);
    await assert.rejects(access(copyPath), { code: "ENOENT" });
    assert.deepEqual((await maps()).map((map) => map.id), ["town"]);
    assert.deepEqual(await readFile(sourcePath), before);
    await data(client, "pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await server.close();
    await authoring.close();
    await rm(root, { recursive: true, force: true });
  }
});

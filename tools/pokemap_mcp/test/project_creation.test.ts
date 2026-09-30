import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, readdir, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import test from "node:test";

import { Client } from "@modelcontextprotocol/client";
import { InMemoryTransport } from "@modelcontextprotocol/server";

import { LocalAuthoringClient, type JsonRecord } from "../src/authoring_client.js";
import { MemoryArtifactReader } from "../src/artifacts.js";
import { createPokeMapMcpServer } from "../src/server.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("real MCP/JSONL bootstrap previews, confirms, creates and independently opens exact grid", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-create-mcp-"));
  const outside = await mkdtemp(join(tmpdir(), "pokemap-create-outside-"));
  const authoring = new LocalAuthoringClient({
    allowedRoots: [root],
    authoringPackageRoot: resolve(process.cwd(), "../../packages/map_authoring"),
    requestTimeoutMs: 30_000,
  });
  const server = createPokeMapMcpServer({ authoring, artifacts: new MemoryArtifactReader() });
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "creation-proof", version: "1.0.0" });
  await server.connect(serverTransport);
  await client.connect(clientTransport);
  async function call(name: string, args: JsonRecord = {}, fail = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: args });
    assert.equal(result.isError, fail ? true : undefined, JSON.stringify(result.structuredContent));
    const envelope = record(result.structuredContent);
    return record(fail ? envelope.error : envelope.data);
  }
  try {
    const listed = (await client.listTools()).tools.map((tool) => tool.name);
    assert.ok(listed.includes("pokemap_project_create_preview"));
    assert.ok(listed.includes("pokemap_project_create"));
    const catalog = await call("pokemap_describe");
    const commands = catalog.commands as JsonRecord[];
    assert.ok(commands.some((item) => item.id === "project_create_preview"));
    assert.ok(commands.some((item) => item.id === "project_create" && item.undoable === false));
    const clairbois = await call("pokemap_project_create_preview", {
      request: { name: "Clairbois MCP", folderName: "clairbois", parentPath: root, template: "clairbois" },
    });
    assert.equal(record(clairbois.request).tileSize, 32);
    assert.ok((clairbois.writes as string[]).includes("maps/maison.json"));
    assert.deepEqual(await readdir(root), []);
    for (const tileSize of [16, 32, 48]) {
      const request = { name: "Projet MCP", folderName: `game-${tileSize}`, parentPath: root,
        template: "playable", tileSize, mapWidth: 24, mapHeight: 18 };
      const preview = await call("pokemap_project_create_preview", { request });
      assert.equal(preview.undoable, false);
      assert.equal((await readdir(root)).includes(request.folderName), false);
      const wrong = await call("pokemap_project_create", {
        request: { ...request, name: "Autre jeu" }, confirmation: preview.confirmation,
      }, true);
      assert.equal(wrong.domainCode, "confirmation.binding_mismatch");
      const created = await call("pokemap_project_create", { request, confirmation: preview.confirmation });
      const manifest = JSON.parse(await readFile(join(root, request.folderName, "project.json"), "utf8")) as JsonRecord;
      assert.equal(record(manifest.settings).tileWidth, tileSize);
      assert.equal(record(manifest.settings).tileHeight, tileSize);
      assert.equal(record(manifest.settings).defaultMapWidth, 24);
      assert.equal(created.tileWidth, tileSize);
      const opened = await call("pokemap_workspace", { operation: "open", projectRoot: created.projectPath });
      assert.equal(opened.projectName, request.name);
      await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
      const duplicate = await call("pokemap_project_create", { request, confirmation: preview.confirmation }, true);
      assert.equal(duplicate.domainCode, "project.destination_exists");
    }
    const outsideError = await call("pokemap_project_create_preview", {
      request: { name: "No", folderName: "no", parentPath: outside },
    }, true);
    assert.equal(outsideError.domainCode, "workspace.path_outside_allowed_roots");
    assert.deepEqual(await readdir(outside), []);
    const request = { name: "Collision", folderName: "collision", parentPath: root, template: "empty" };
    const preview = await call("pokemap_project_create_preview", { request });
    await mkdir(join(root, "collision"));
    await writeFile(join(root, "collision", "keep"), "preserved");
    const collision = await call("pokemap_project_create", { request, confirmation: preview.confirmation }, true);
    assert.equal(collision.domainCode, "project.destination_exists");
    assert.equal(await readFile(join(root, "collision", "keep"), "utf8"), "preserved");
  } finally {
    await client.close();
    await server.close();
    await authoring.close();
    await rm(root, { recursive: true, force: true });
    await rm(outside, { recursive: true, force: true });
  }
});

import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { mkdir, readFile, rm } from "node:fs/promises";
import { homedir } from "node:os";
import { join, resolve } from "node:path";
import { promisify } from "node:util";
import { test } from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import { resolvePackagedRuntime } from "../src/packaged_runtime.js";
import { isRecord, type JsonRecord } from "../src/authoring_client.js";

const manifest = process.env.POKEMAP_INSTALLED_MCP_MANIFEST;
const execute = promisify(execFile);

test(
  "installed headless distribution opens, edits, checks and resumes outside checkout without an SDK PATH",
  {
    skip: !manifest,
    timeout: 180_000,
  },
  async () => {
    const qa = process.env.POKEMAP_QA_ROOT ?? join(
      homedir(),
      "Library/Caches/AveluneQA/mcp-studio-integration/qualification",
    );
    await mkdir(qa, { recursive: true });
    const generated = await execute(
      "dart",
      [
        "run",
        "test/support/create_reliability_transport_fixture.dart",
        "interiorHole",
        "classic",
        qa,
      ],
      {
        cwd: resolve("../../packages/map_authoring"),
        maxBuffer: 1024 * 1024,
      },
    );
    const fixture = JSON.parse(generated.stdout.trim().split("\n").at(-1)!) as {
      root: string;
      mapId: string;
      mapPath: string;
    };
    assert.ok(fixture.root.startsWith(qa + "/"));
    const packaged = await resolvePackagedRuntime(manifest!);
    for (const id of ["authoring", "authoring-headless"]) {
      assert.ok(packaged.components.get(id)?.licenses.includes("licenses/dart.txt"));
    }
    const client = new Client({
      name: "installed-distribution-qa",
      version: "1",
    });
    const transport = new StdioClientTransport({
      command: packaged.command("node-headless").executable,
      args: [
        packaged.components.get("server")!.absolutePath,
        "--runtime-manifest",
        manifest!,
        "--root",
        fixture.root,
        "--profile",
        "map-builder",
        "--authoring-timeout-ms",
        "60000",
      ],
      cwd: fixture.root,
      env: { PATH: "", HOME: homedir(), TMPDIR: qa },
      stderr: "pipe",
    });
    const call = async (
      name: string,
      args: JsonRecord,
    ): Promise<JsonRecord> => {
      const result = await client.callTool({ name, arguments: args });
      assert.ok(isRecord(result.structuredContent));
      const envelope = result.structuredContent;
      assert.equal(
        envelope.ok,
        true,
        JSON.stringify({ name, error: envelope.error }),
      );
      assert.ok(isRecord(envelope.data));
      return envelope.data;
    };
    try {
      await client.connect(transport);
      const tools = await client.listTools();
      assert.ok(tools.tools.some((tool) => tool.name === "pokemap_map_edit"));
      await call("pokemap_describe", {
        actionIds: ["map3d.edit_batch"],
        view: "full",
      });
      let opened = await call("pokemap_workspace", {
        operation: "open",
        projectRoot: fixture.root,
      });
      await call("pokemap_workshop", {
        projectHandle: opened.projectHandle,
        operation: "prepare",
      });
      const before = await call("pokemap_map_check", {
        projectHandle: opened.projectHandle,
        mapId: fixture.mapId,
        visual: "none",
      });
      assert.equal(before.verdict, "fail");
      const original = await readFile(fixture.mapPath);
      const input = {
        projectHandle: opened.projectHandle,
        mapId: fixture.mapId,
        operationId: "installed-qualification-edit",
        operations: [
          {
            actionId: "smart_tile.cell.paint",
            actionVersion: 1,
            parameters: {
              layerId: "terrain",
              materialId: "grass",
              cells: [{ x: 12, y: 8 }],
            },
          },
        ],
      };
      const planned = await call("pokemap_map_edit", {
        ...input,
        dryRun: true,
      });
      assert.equal(planned.status, "planned");
      assert.deepEqual(await readFile(fixture.mapPath), original);
      const applied = await call("pokemap_map_edit", input);
      assert.equal(applied.status, "applied");
      const durable = await readFile(fixture.mapPath);
      assert.notDeepEqual(durable, original);
      const checked = await call("pokemap_map_check", {
        projectHandle: opened.projectHandle,
        mapId: fixture.mapId,
        visual: "none",
      });
      assert.equal(checked.verdict, "pass");
      await call("pokemap_workspace", {
        operation: "close",
        workspaceHandle: opened.workspaceHandle,
      });
      opened = await call("pokemap_workspace", {
        operation: "open",
        projectRoot: fixture.root,
      });
      const replay = await call("pokemap_map_edit", {
        ...input,
        projectHandle: opened.projectHandle,
      });
      assert.equal(replay.status, applied.status);
      assert.deepEqual(replay.receipt, applied.receipt);
      assert.deepEqual(await readFile(fixture.mapPath), durable);
      const queried = await call("pokemap_query", {
        projectHandle: opened.projectHandle,
        resourceKind: "map",
        operation: "get",
        ids: [fixture.mapId],
        view: "detail",
      });
      assert.ok(Array.isArray(queried.items));
      const map = queried.items[0];
      assert.ok(isRecord(map) && Array.isArray(map.layers));
      const ground = map.layers.find(
        (layer) => isRecord(layer) && layer.id === "terrain",
      );
      assert.ok(
        isRecord(ground) &&
          isRecord(ground.field) &&
          Array.isArray(ground.field.semanticCells) &&
          Array.isArray(ground.materialPalette),
      );
      assert.equal(
        ground.materialPalette[
          ground.field.semanticCells[8 * 24 + 12] as number
        ],
        "grass",
      );
      await call("pokemap_workspace", {
        operation: "close",
        workspaceHandle: opened.workspaceHandle,
      });
    } finally {
      await client.close();
      await transport.close();
      await rm(fixture.root, { recursive: true, force: true });
    }
  },
);

import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { test } from "node:test";
import {
  Client,
  StreamableHTTPClientTransport,
} from "@modelcontextprotocol/client";
import { isRecord, type JsonRecord } from "../src/authoring_client.js";

const connectionPath = process.env.POKEMAP_STUDIO_QA_CONNECTION;
const projectRoot = process.env.POKEMAP_STUDIO_QA_PROJECT;
const evaluationRoot = process.env.POKEMAP_STUDIO_QA_EVALUATION_PROJECT;

test(
  "signed Studio completes headless and interactive playtests with sealed receipts",
  {
    skip: !connectionPath || !evaluationRoot,
    timeout: 180_000,
  },
  async () => {
    const exported = JSON.parse(await readFile(connectionPath!, "utf8"));
    const configuration = Object.values(exported.mcpServers)[0] as {
      url: string;
      headers: Record<string, string>;
    };
    const client = new Client(
      { name: "studio-installed-evaluation", version: "1" },
      {
        versionNegotiation: { mode: "legacy" },
      },
    );
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
      await client.connect(
        new StreamableHTTPClientTransport(new URL(configuration.url), {
          requestInit: { headers: configuration.headers },
        }),
      );
      const opened = await call("pokemap_workspace", {
        operation: "open",
        projectRoot: evaluationRoot,
      });
      for (const target of ["headless", "interactive"]) {
        const started = await call("pokemap_playtest", {
          projectHandle: opened.projectHandle,
          scenarioId: "native-smoke",
          target,
          policy: "certify",
        });
        let job: JsonRecord = started;
        const deadline = Date.now() + 75_000;
        while (
          !["succeeded", "failed", "cancelled"].includes(String(job.state)) &&
          Date.now() < deadline
        ) {
          await new Promise((accept) => setTimeout(accept, 250));
          job = await call("pokemap_job", {
            operation: "get",
            jobId: started.jobId,
          });
        }
        assert.equal(job.state, "succeeded", JSON.stringify({ target, job }));
        assert.ok(isRecord(job.result) && isRecord(job.result.receipt));
      }
      await call("pokemap_workspace", {
        operation: "close",
        workspaceHandle: opened.workspaceHandle,
      });
    } finally {
      await client.close();
    }
  },
);

test(
  "signed Studio serves native project edits and render artifacts without user SDKs",
  {
    skip: !connectionPath || !projectRoot,
    timeout: 240_000,
  },
  async () => {
    const exported = JSON.parse(await readFile(connectionPath!, "utf8"));
    const configuration = Object.values(exported.mcpServers)[0] as {
      url: string;
      headers: Record<string, string>;
    };
    const client = new Client(
      { name: "studio-installed-qualification", version: "1" },
      {
        versionNegotiation: { mode: "legacy" },
      },
    );
    const call = async (name: string, args: JsonRecord) => {
      const result = await client.callTool({ name, arguments: args });
      assert.ok(isRecord(result.structuredContent));
      const envelope = result.structuredContent;
      assert.equal(
        envelope.ok,
        true,
        JSON.stringify({ name, error: envelope.error }),
      );
      return envelope;
    };
    try {
      await client.connect(
        new StreamableHTTPClientTransport(new URL(configuration.url), {
          requestInit: { headers: configuration.headers },
        }),
      );
      const tools = await client.listTools();
      assert.ok(tools.tools.some((tool) => tool.name === "pokemap_map_edit"));
      await call("pokemap_describe", {
        actionIds: ["map3d.edit_batch"],
        view: "full",
      });
      const opened = await call("pokemap_workspace", {
        operation: "open",
        projectRoot,
      });
      assert.ok(isRecord(opened.data));
      const projectHandle = opened.data.projectHandle;
      await call("pokemap_workshop", { projectHandle, operation: "prepare" });
      const request = {
        projectHandle,
        mapId: "map",
        operationId: `native-studio-${randomUUID()}`,
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
      const applied = await call("pokemap_map_edit", request);
      const bytes = await readFile(join(projectRoot!, "maps/map.json"));
      const replay = await call("pokemap_map_edit", request);
      assert.ok(isRecord(applied.data) && isRecord(replay.data));
      assert.deepEqual(replay.data.receipt, applied.data.receipt);
      assert.deepEqual(
        await readFile(join(projectRoot!, "maps/map.json")),
        bytes,
      );
      const checked = await call("pokemap_map_check", {
        projectHandle,
        mapId: "map",
        visual: "none",
      });
      assert.ok(isRecord(checked.data));
      assert.equal(checked.data.verdict, "pass");
      for (const [name, args] of [
        ["pokemap_render", { cellPixelSize: 8 }],
        ["pokemap_render_3d", { view: "game" }],
        ["pokemap_render_3d_scan", { maxViews: 2, grid: true }],
      ] as const) {
        const rendered = await call(name, {
          projectHandle,
          mapId: "map",
          ...args,
        });
        assert.ok(Array.isArray(rendered.artifacts));
        for (const artifact of rendered.artifacts) {
          assert.ok(isRecord(artifact) && typeof artifact.uri === "string");
          const result = await client.callTool({
            name: "pokemap_artifact",
            arguments: { uri: artifact.uri },
          });
          assert.ok(
            result.content.some(
              (part) =>
                part.type === "resource" &&
                "blob" in part.resource &&
                part.resource.mimeType === "image/png" &&
                Buffer.from(part.resource.blob, "base64")
                  .subarray(0, 8)
                  .equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10])),
            ),
          );
        }
      }
      await call("pokemap_workspace", {
        operation: "close",
        workspaceHandle: opened.data.workspaceHandle,
      });
    } finally {
      await client.close();
    }
  },
);

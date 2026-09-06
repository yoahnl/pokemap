import assert from "node:assert/strict";
import test from "node:test";

import { Client } from "@modelcontextprotocol/client";
import { InMemoryTransport } from "@modelcontextprotocol/server";

import type {
  AuthoringGateway,
  JsonRecord,
  ProjectRootResolver,
} from "../src/authoring_client.js";
import { MemoryArtifactReader } from "../src/artifacts.js";
import { createPokeMapMcpServer } from "../src/server.js";

test("pokemap_game_export routes an opaque project handle to game_export", async () => {
  const calls: Array<{ command: string; args: JsonRecord | undefined }> = [];
  const authoring: AuthoringGateway = {
    async request(command, args) {
      calls.push({ command, args });
      return {
        requestId: "export-1",
        data: {
          outputPath: "/allowed/output/game.avelunegame",
          sizeBytes: 42,
          sha256: "a".repeat(64),
          gameId: "games.example.fixture",
          gameVersion: "1.0.0",
          title: "Fixture",
          fileCount: 3,
          treeSha256: "b".repeat(64),
        },
        artifacts: [],
      };
    },
    async close() {},
  };
  const projectRoots: ProjectRootResolver = {
    resolveProjectRoot(projectHandle) {
      assert.equal(projectHandle, "prj_fixture");
      return "/allowed/project";
    },
  };
  const server = createPokeMapMcpServer({
    authoring,
    projectRoots,
    artifacts: new MemoryArtifactReader(),
  });
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "game-export-test", version: "1.0.0" });
  await server.connect(serverTransport);
  await client.connect(clientTransport);

  try {
    const tools = (await client.listTools()).tools.map((tool) => tool.name);
    assert.ok(tools.includes("pokemap_game_export"));

    const result = await client.callTool({
      name: "pokemap_game_export",
      arguments: {
        projectHandle: "prj_fixture",
        outputPath: "/allowed/output/game.avelunegame",
      },
    });

    assert.equal(result.isError, undefined);
    assert.deepEqual(calls, [
      {
        command: "game_export",
        args: {
          projectRoot: "/allowed/project",
          outputPath: "/allowed/output/game.avelunegame",
        },
      },
    ]);

    const localTest = await client.callTool({
      name: "pokemap_game_export",
      arguments: {
        projectHandle: "prj_fixture",
        outputPath: "/allowed/output/test.avelunegame",
        mode: "localTest",
      },
    });
    assert.equal(localTest.isError, undefined);
    assert.deepEqual(calls.at(-1)?.args, {
      projectRoot: "/allowed/project",
      outputPath: "/allowed/output/test.avelunegame",
      mode: "localTest",
    });
  } finally {
    await client.close();
    await server.close();
  }
});

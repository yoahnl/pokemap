import assert from "node:assert/strict";
import { test } from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { InMemoryTransport } from "@modelcontextprotocol/server";
import { MemoryArtifactReader } from "../src/artifacts.js";
import { createPokeMapMcpServer } from "../src/server.js";
import { parseConfig } from "../src/config.js";
import type { RuntimeGateway } from "../src/runtime_gateway.js";

test("map-builder retains canonical creation and recovery with compact discovery", async () => {
  const calls: unknown[] = [];
  const server = createPokeMapMcpServer({
    profile: "map-builder",
    authoring: { close: async () => {}, request: async (command, args) => {
      calls.push({ command, args });
      return { requestId: "profile-test", data: { mutationActions: [] }, artifacts: [] };
    } },
    artifacts: new MemoryArtifactReader(),
    runtime: Object.fromEntries(["render","render3d","scan3d","startPlaytest","getJob","jobEvents","cancelJob","retryJob","close"]
      .map(name=>[name,async()=>{throw new Error("Discovery must not execute the renderer");}])) as unknown as RuntimeGateway,
  });
  const [left, right] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "map-builder-profile-test", version: "1" });
  await server.connect(right);
  await client.connect(left);
  try {
    const result = await client.listTools();
    const names = result.tools.map(tool => tool.name);
    assert.deepEqual(names.sort(), [
      "pokemap_apply", "pokemap_artifact", "pokemap_describe", "pokemap_history", "pokemap_map_check", "pokemap_map_edit",
      "pokemap_plan", "pokemap_query", "pokemap_recovery_status", "pokemap_workshop", "pokemap_workspace",
      "pokemap_render_3d", "pokemap_render_3d_scan",
    ].sort());
    assert.ok(Buffer.byteLength(JSON.stringify(result)) <= 25000,
      JSON.stringify({total:Buffer.byteLength(JSON.stringify(result)),tools:result.tools.map(tool=>[tool.name,Buffer.byteLength(JSON.stringify(tool))])}));
    const described = await client.callTool({name:"pokemap_describe", arguments:{domain:"map3d", view:"compact"}});
    assert.equal(described.isError, undefined);
    assert.deepEqual(calls, [{command:"describe", args:{domain:"map3d", view:"compact"}}]);
  } finally {
    await client.close();
    await server.close();
  }
});

test("profile configuration defaults to full and rejects unknown profiles", () => {
  assert.equal(parseConfig(["--root", process.cwd()]).profile, "full");
  assert.equal(parseConfig(["--root", process.cwd(), "--profile", "map-builder"]).profile, "map-builder");
  assert.throws(() => parseConfig(["--root", process.cwd(), "--profile", "unknown"]));
});

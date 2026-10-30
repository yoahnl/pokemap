import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import type { JsonRecord } from "../src/authoring_client.js";
import { record, reliabilityStdio } from "./support/reliability_stdio.js";

for (const storage of ["classic", "catalog"] as const) {
  test(`live map-builder ${storage} edits without a client planId and replays after reopen`, {timeout: 90_000}, async () => {
    const host = await reliabilityStdio("interiorHole", storage);
    try {
      const tools = await host.client.listTools();
      const bytes = Buffer.byteLength(JSON.stringify(tools));
      console.info(`map-builder live listToolsBytes=${bytes}`);
      assert.ok(bytes <= 25_000, `map-builder listTools uses ${bytes} bytes`);
      assert.ok(tools.tools.some(tool => tool.name === "pokemap_map_edit"));
      assert.ok(tools.tools.some(tool => tool.name === "pokemap_map_check"));
      const described = await host.call("pokemap_describe", {actionIds:["map3d.edit_batch"],view:"full"});
      assert.equal((described.mutationActions as JsonRecord[])[0]!.id,"map3d.edit_batch");
      let opened = await host.call("pokemap_workspace", {operation:"open",projectRoot:host.root});
      const project = () => ({projectHandle:opened.projectHandle});
      await host.call("pokemap_workshop", {...project(),operation:"prepare"});
      const beforeCheck = await host.call("pokemap_map_check", {...project(),mapId:host.fixture.mapId,visual:"none"});
      assert.equal(beforeCheck.verdict,"fail");
      const input: JsonRecord = {...project(),operationId:`stdio-${storage}`,mapId:host.fixture.mapId,
        operations:[{actionId:"smart_tile.cell.paint",actionVersion:1,parameters:{
          layerId:"terrain",materialId:"grass",cells:[{x:12,y:8}],
        }}]};
      assert.equal("planId" in input,false);
      const original = await readFile(String(host.fixture.mapPath));
      const preview = await host.call("pokemap_map_edit", {...input,dryRun:true});
      assert.equal(preview.status,"planned");
      assert.deepEqual(await readFile(String(host.fixture.mapPath)),original);
      const failure = await host.call("pokemap_map_edit", {...input,operationId:`invalid-${storage}`,
        operations:[...(input.operations as JsonRecord[]),
          {actionId:"smart_tile.cell.paint",actionVersion:1,parameters:{layerId:"terrain",materialId:"missing",cells:[{x:11,y:8}]}}]},true);
      assert.equal(failure.domainCode,"map3d.edit_batch.operation_failed");
      assert.deepEqual(await readFile(String(host.fixture.mapPath)),original);
      const applied = await host.call("pokemap_map_edit", input);
      assert.equal(applied.status,"applied");
      const bytesAfter = await readFile(String(host.fixture.mapPath));
      await host.call("pokemap_workspace", {operation:"close",workspaceHandle:opened.workspaceHandle});
      opened = await host.call("pokemap_workspace", {operation:"open",projectRoot:host.root});
      const replay = await host.call("pokemap_map_edit", {...input,...project()});
      assert.deepEqual(replay.receipt,applied.receipt);
      assert.deepEqual(await readFile(String(host.fixture.mapPath)),bytesAfter);
      const check = await host.call("pokemap_map_check", {...project(),mapId:host.fixture.mapId,visual:"none"});
      assert.equal(check.verdict,"pass");
      assert.equal(record(record(check.checks).visual).status,"not_run");
      const page = await host.call("pokemap_query", {...project(),resourceKind:"map",operation:"get",ids:[host.fixture.mapId],view:"detail"});
      const map = record((page.items as JsonRecord[])[0]);
      assert.equal(map.id,host.fixture.mapId);
      const ground = (map.layers as JsonRecord[]).find(layer => layer.id === "terrain")!;
      const cells = record(ground.field).semanticCells as number[];
      assert.equal((ground.materialPalette as string[])[cells[8*24+12]!],"grass");
      await host.call("pokemap_workspace", {operation:"close",workspaceHandle:opened.workspaceHandle});
    } finally { await host.close(); }
  });
}

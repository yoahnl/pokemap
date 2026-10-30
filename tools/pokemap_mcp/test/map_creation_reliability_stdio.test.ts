import assert from "node:assert/strict";
import test from "node:test";
import type { JsonRecord } from "../src/authoring_client.js";
import { record, reliabilityStdio } from "./support/reliability_stdio.js";

for (const storage of ["classic", "catalog"] as const) {
  test(`T7 live map-builder ${storage} creates a native field with ground and a resolved height step`, {timeout: 120_000}, async () => {
    const host = await reliabilityStdio("noWorkingMap",storage);
    try {
      let opened = await host.call("pokemap_workspace", {operation:"open",projectRoot:host.root});
      const project = () => ({projectHandle:opened.projectHandle});
      await host.call("pokemap_workshop", {...project(),operation:"prepare"});
      let sequence = 0;
      async function mutate(actionId: string, parameters: JsonRecord): Promise<JsonRecord> {
        const scoped = storage === "catalog" ? await host.call("pokemap_workshop", {
          ...project(),operation:"read",actionId,parameters,includeDocuments:false,
        }) : await host.call("pokemap_query", {...project(),resourceKind:"map",operation:"list"});
        const id = `t7-${++sequence}`;
        const planned = await host.call("pokemap_plan", {...project(),request:{
          requestId:id,actionId,actionVersion:1,workspaceHandle:opened.workspaceHandle,
          parameters,expectedRevision:scoped.snapshotRevision,idempotencyKey:id,
          ...(storage === "catalog" ? {extensions:scoped.planExtensions} : {}),
        }});
        const applied = await host.call("pokemap_apply", {...project(),operation:"apply",
          planId:planned.planId,operationId:`apply-${id}`});
        assert.equal(record(applied.receipt).status,"applied");
        return record(record(planned.plan).preview);
      }
      const created = await mutate("map.create",{mapId:"new-field",name:"Native creation proof",width:24,height:16});
      const mapId = String(created.mapId);
      assert.equal(mapId,"new-field");
      const ground = await mutate("smart_tile.layer.create",{mapId,layerId:"ground",name:"Ground",presetId:"ground"});
      const groundId = String(ground.layerId);
      assert.equal(groundId,"ground");
      const layer = await mutate("map.apply_operations",{mapId,operations:[{
        kind:"layer.add",layerKind:"border",layerId:"relief",name:"Relief",
      }]});
      assert.ok((layer.touchedLayerIds as string[]).includes("relief"));
      const before = await host.call("pokemap_query",{...project(),resourceKind:"map",operation:"get",ids:[mapId],view:"detail"});
      const initial = record((before.items as JsonRecord[])[0]);
      const reliefId = String((initial.layers as JsonRecord[]).find(item=>item.id === "relief")!.id);
      const edit = await host.call("pokemap_map_edit",{...project(),operationId:`t7-native-step-${storage}`,mapId,
        operations:[
          {actionId:"smart_tile.cell.paint",actionVersion:1,parameters:{layerId:groundId,materialId:"grass",
            cells:Array.from({length:24*16},(_,index)=>({x:index%24,y:Math.floor(index/24)}))}},
          {actionId:"map3d.terrain.surface.upsert_batch",actionVersion:1,parameters:{surfaces:[{
            id:"plateau",x:0,z:4,height:1,footprints:[[{x:0,z:0},{x:24,z:0},{x:24,z:12},{x:0,z:12}]],
          }]}},
          {actionId:"intent.border.trace_step",actionVersion:1,parameters:{layerId:reliefId,featureId:"step",
            blueprintId:"fence",lowerHeight:0,upperHeight:1,region:{x:2,y:2,width:6,height:5}}},
        ]});
      assert.equal(edit.status,"applied");
      await host.call("pokemap_workspace",{operation:"close",workspaceHandle:opened.workspaceHandle});
      opened = await host.call("pokemap_workspace",{operation:"open",projectRoot:host.root});
      const page = await host.call("pokemap_query",{...project(),resourceKind:"map",operation:"get",ids:[mapId],view:"detail"});
      const map = record((page.items as JsonRecord[])[0]);
      assert.equal(map.id,mapId);
      assert.deepEqual(map.size,{width:24,height:16});
      const scene = record(map.spatialScene);
      assert.equal((record(scene.terrainSurfaces).surfaces as JsonRecord[]).find(surface=>surface.id==="plateau")!.height,1);
      const persistedGround = (map.layers as JsonRecord[]).find(item=>item.id===groundId)!;
      const palette = persistedGround.materialPalette as string[];
      assert.ok((record(persistedGround.field).semanticCells as number[]).every(cell=>palette[cell]==="grass"));
      const relief = (map.layers as JsonRecord[]).find(item=>item.id===reliefId)!;
      const feature = (record(relief.content).features as JsonRecord[]).find(item=>item.id==="step")!;
      assert.ok(feature);
      assert.equal(record(feature.geometry).alignment,"gridEdges");
      const placements = record(feature.materialization).spatialPlacements as JsonRecord[];
      assert.ok(placements.length>0);
      const instanceIds = new Set((scene.instances as JsonRecord[]).map(instance=>instance.id));
      assert.ok(placements.every(placement=>instanceIds.has(placement.instanceId)));
      const check = await host.call("pokemap_map_check",{...project(),mapId,visual:"none"});
      assert.equal(record(record(check.checks).borders).status,"pass",JSON.stringify(check));
      assert.equal(record(record(check.checks).visual).status,"not_run");
      await host.call("pokemap_workspace",{operation:"close",workspaceHandle:opened.workspaceHandle});
    } finally { await host.close(); }
  });
}

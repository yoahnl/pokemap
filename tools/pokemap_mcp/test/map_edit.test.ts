import assert from "node:assert/strict";
import { test } from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { InMemoryTransport } from "@modelcontextprotocol/server";
import { MemoryArtifactReader } from "../src/artifacts.js";
import { createPokeMapMcpServer } from "../src/server.js";
import { mapEditSchema } from "../src/tools/map_edit.js";

const request = {projectHandle:"project",operationId:"paint-1",mapId:"map",
  operations:[{actionId:"smart_tile.cell.paint",actionVersion:1,
    parameters:{layerId:"ground",material:{name:"Herbe"},cells:[{x:2,y:3}]}}]};

test("map edit rejects unknown fields and invalid transaction identities", () => {
  for (const value of [{...request,confirmation:true}, {...request,operationId:"../x"},
    {...request,operations:[]},{...request,operations:Array(65).fill(request.operations[0])},
    {...request,seed:-1},{...request,guards:{groundGaps:"ignore"}},
    {...request,operations:[{...request.operations[0],extra:true}]}]) {
    assert.equal(mapEditSchema.safeParse(value).success,false);
  }
});

test("both profiles forward exactly one canonical operation without client retries", async () => {
  for (const profile of ["full","map-builder"] as const) {
    const calls: unknown[]=[];
    const server=createPokeMapMcpServer({profile,artifacts:new MemoryArtifactReader(),
      authoring:{close:async()=>{},request:async(command,args)=>{
        calls.push({command,args});
        return {requestId:"edit",data:{status:"recovery_required",operationId:request.operationId},artifacts:[]};
      }}});
    const [left,right]=InMemoryTransport.createLinkedPair();
    const client=new Client({name:"map-edit-test",version:"1"});
    await server.connect(right); await client.connect(left);
    try {
      const result=await client.callTool({name:"pokemap_map_edit",arguments:request});
      assert.equal(result.isError,undefined);
      assert.deepEqual(calls,[{command:"map_edit",args:{...request,seed:0,guards:{},dryRun:false}}]);
      assert.match(JSON.stringify(result.structuredContent),/recovery_required/);
    } finally {await client.close();await server.close();}
  }
});

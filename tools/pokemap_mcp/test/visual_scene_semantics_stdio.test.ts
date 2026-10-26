import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import test from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";
import { canonicalPokemonConfig } from "./pokemon_fixture.js";
function record(v:unknown):JsonRecord {assert.ok(v && typeof v === "object" && !Array.isArray(v));return v as JsonRecord;}
test("canonical MCP cinematic and World Rule actions preserve typed atmosphere semantics",{timeout:120_000},async()=>{
 const root=await mkdtemp(join(tmpdir(),"visual-semantics-"));
 await mkdir(join(root,"maps"));await writeFile(join(root,"maps/room.json"),JSON.stringify({version:"v8",id:"room",name:"Room",size:{width:8,height:8},layers:[]}));
 await writeFile(join(root,"project.json"),JSON.stringify({version:"v8",name:"Visual contracts",pokemon:canonicalPokemonConfig(),maps:[{id:"room",name:"Room",relativePath:"maps/room.json"}],tilesets:[],facts:[{id:"storm",label:"Storm"}]}));
 const args=[resolve("dist/src/index.js"),"--root",root,"--authoring-timeout-ms","60000"];
 if(process.env.POKEMAP_TEST_DART)args.push("--dart",process.env.POKEMAP_TEST_DART);
 const transport=new StdioClientTransport({command:process.execPath,args,cwd:process.cwd(),stderr:"pipe"});const client=new Client({name:"visual-semantics",version:"1"});
 async function call(name:string,input:JsonRecord={},failure=false){const r=record((await client.callTool({name,arguments:input})).structuredContent);assert.equal(r.ok,!failure,JSON.stringify(r));return record(r[failure?"error":"data"]);}
 try{
  await client.connect(transport);const catalog=await call("pokemap_describe");const actions=catalog.mutationActions as JsonRecord[];
  assert.equal(record(record(actions.find(a=>a.id==="cinematic.upsert")!.extensions).atmosphere).stepKind,"atmosphere");
  assert.equal(record(record(actions.find(a=>a.id==="world_rule.create")!.extensions).atmosphere).effectKind,"atmosphere");
  const opened=await call("pokemap_workspace",{operation:"open",projectRoot:root});let seq=0;
  async function plan(actionId:string,parameters:JsonRecord,failure=false){const snapshot=await call("pokemap_validate",{projectHandle:opened.projectHandle});const id=`visual-semantic-${++seq}`;return call("pokemap_plan",{projectHandle:opened.projectHandle,request:{requestId:id,actionId,actionVersion:1,workspaceHandle:opened.workspaceHandle,expectedRevision:snapshot.snapshotRevision,idempotencyKey:id,parameters}},failure);}
  const visual={depthOfFieldEnabled:true,depthOfFieldStrength:.65,depthOfFieldFocusRange:5,haloStrength:1.2};
  const cinematic={id:"visual-scene",title:"Visual scene",mapId:"room",timeline:{steps:[{id:"atmosphere",kind:"atmosphere",durationMs:1000,visualSettings:visual,metadata:{}}]}};
  const first=await plan("cinematic.upsert",{cinematic});await call("pokemap_apply",{operation:"apply",projectHandle:opened.projectHandle,planId:first.planId,operationId:"apply-visual-cinematic"});
  const rule={id:"world_rule_storm_atmosphere",label:"Storm atmosphere",source:{kind:"fact",sourceId:"storm",predicate:"isTrue"},target:{kind:"atmosphere",mapId:"room"},effect:{kind:"atmosphere",visualSettings:{fogOpacity:.4}}};
  const second=await plan("world_rule.create",{rule});await call("pokemap_apply",{operation:"apply",projectHandle:opened.projectHandle,planId:second.planId,operationId:"apply-visual-rule"});
  const disk=record(JSON.parse(await readFile(join(root,"project.json"),"utf8")));
  const savedAsset=record((disk.cinematics as JsonRecord[])[0]);
  const savedStep=record((record(savedAsset.timeline).steps as JsonRecord[])[0]);
  assert.deepEqual(savedStep.visualSettings,visual);
  assert.deepEqual(record(record((disk.worldRules as JsonRecord[])[0]).effect).visualSettings,{fogOpacity:.4});
  const before=await readFile(join(root,"project.json"));await plan("cinematic.upsert",{cinematic:{...cinematic,timeline:{steps:[{id:"bad",kind:"atmosphere",durationMs:1000,visualSettings:{fogOpacity:3}}]}}},true);assert.deepEqual(await readFile(join(root,"project.json")),before);
  await call("pokemap_workspace",{operation:"close",workspaceHandle:opened.workspaceHandle});
 }finally{await client.close();await transport.close();await rm(root,{recursive:true,force:true});}
});

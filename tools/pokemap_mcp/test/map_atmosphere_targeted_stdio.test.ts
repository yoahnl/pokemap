import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, mkdir, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import test from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";
function record(value: unknown): JsonRecord {assert.ok(value && typeof value === "object" && !Array.isArray(value));return value as JsonRecord;}
test("map atmosphere tools save cold states without opening or rewriting the project", {timeout:150_000}, async()=>{
 const root=await mkdtemp(join(tmpdir(),"atmosphere-mcp-"));
 const outside=await mkdtemp(join(tmpdir(),"atmosphere-outside-"));
 const args=[resolve("dist/src/index.js"),"--root",root,"--authoring-timeout-ms","60000"];
 if(process.env.POKEMAP_TEST_DART) args.push("--dart",process.env.POKEMAP_TEST_DART);
 async function session(run:(call:(name:string,input?:JsonRecord,fails?:boolean)=>Promise<JsonRecord>)=>Promise<void>):Promise<void>{
  const transport=new StdioClientTransport({command:process.execPath,args,cwd:process.cwd(),stderr:"pipe"});
  const client=new Client({name:"atmosphere-test",version:"1"});
  async function call(name:string,input:JsonRecord={},fails=false):Promise<JsonRecord>{const body=record((await client.callTool({name,arguments:input})).structuredContent);assert.equal(body.ok,!fails,JSON.stringify(body));return record(body[fails?"error":"data"]);}
  try{await client.connect(transport);const names=(await client.listTools()).tools.map(t=>t.name);assert.ok(names.includes("pokemap_map_atmosphere_inspect"));assert.ok(names.includes("pokemap_map_atmosphere_set"));assert.ok(names.includes("pokemap_map_atmosphere_undo"));await run(call);}finally{await client.close();await transport.close();}
 }
 try{
  const map=join(root,"maps","shore.json"),project=join(root,"project.json");
  await mkdir(join(root,"maps"));await writeFile(map,"undecodable map");await writeFile(project,"undecodable project");
  let index=0;
  let lastReceipt="";
  for(const flag of ["halosEnabled","depthFogEnabled","depthOfFieldEnabled","waterAnimated","windowsLit","fireflies"]){await session(async call=>{
   const catalog=await call("pokemap_describe");assert.equal(record(catalog.mapAtmosphereAuthoring).id,"map.atmosphere.set");const extensions=record(record(catalog.mapAtmosphereAuthoring).extensions);assert.ok((extensions.effects as string[]).includes("depthOfFieldEnabled"));assert.ok((extensions.effects as string[]).includes("weather"));assert.ok((extensions.settingsFields as string[]).includes("depthOfFieldFocusRange"));assert.ok((catalog.commands as JsonRecord[]).some(c=>c.id==="map_atmosphere_set"));
   const initial=await call("pokemap_map_atmosphere_inspect",{projectRoot:root,mapId:"shore"});const settings={...record(initial.settings),weather:{enabled:true,kind:"rain",intensity:.6,lightning:false},[flag]:true,depthOfFieldStrength:.65,depthOfFieldFocusRange:18,haloStrength:1.4,fogOpacity:.32,fogStart:39,fogEnd:49,halos:[{instanceId:"lamp",localPosition:{x:0,y:2.25,z:0},radiusX:1,radiusY:1,opacity:.3,colorRgb:0xffcf83,window:false}]};const input={projectRoot:root,mapId:"shore",expectedRevision:initial.revision,settings,operationId:`atmosphere-${index++}`};
   const changed=await call("pokemap_map_atmosphere_set",input);assert.equal(record(record(changed.afterSettings).weather).kind,"rain");assert.equal(record(changed.afterSettings)[flag],true);assert.equal(record(changed.afterSettings).depthOfFieldStrength,.65);assert.equal(record(changed.afterSettings).depthOfFieldFocusRange,18);lastReceipt=String(record(changed.receipt).receiptId);const sidecar=await readFile(join(root,"maps","shore.atmosphere.json"));assert.ok(sidecar.length<2048);
   const replay=await call("pokemap_map_atmosphere_set",input);assert.equal(record(replay.receipt).receiptId,record(changed.receipt).receiptId);assert.deepEqual(await readFile(join(root,"maps","shore.atmosphere.json")),sidecar);
   await call("pokemap_map_atmosphere_set",{...input,settings:{...settings,[flag]:false}},true);
  });}
  await session(async call=>{const final=await call("pokemap_map_atmosphere_inspect",{projectRoot:root,mapId:"shore"});for(const flag of ["halosEnabled","depthFogEnabled","depthOfFieldEnabled","waterAnimated","windowsLit","fireflies"])assert.equal(record(final.settings)[flag],true);const undoInput={projectRoot:root,mapId:"shore",receiptId:lastReceipt,expectedRevision:final.revision,operationId:"undo-mcp"};const undone=await call("pokemap_map_atmosphere_undo",undoInput);assert.equal(record(undone.afterSettings).fireflies,false);const replay=await call("pokemap_map_atmosphere_undo",undoInput);assert.equal(record(replay.receipt).receiptId,record(undone.receipt).receiptId);await call("pokemap_map_atmosphere_inspect",{projectRoot:outside,mapId:"shore"},true);await call("pokemap_map_atmosphere_set",{projectRoot:root,mapId:"shore",expectedRevision:"sha256:"+"0".repeat(64),settings:record(final.settings),operationId:"stale"},true);});
  assert.equal((await readFile(project)).toString(),"undecodable project");assert.equal((await readFile(map)).toString(),"undecodable map");
 }finally{await rm(root,{recursive:true,force:true});await rm(outside,{recursive:true,force:true});}
});

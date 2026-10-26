import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, mkdir, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import test from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";
function record(value: unknown): JsonRecord {assert.ok(value && typeof value === "object" && !Array.isArray(value));return value as JsonRecord;}
test("visual defaults and map inheritance use bounded canonical documents across cold MCP sessions", {timeout:150_000}, async()=>{
 const root=await mkdtemp(join(tmpdir(),"visual-mcp-"));
 const args=[resolve("dist/src/index.js"),"--root",root,"--authoring-timeout-ms","60000"];
 if(process.env.POKEMAP_TEST_DART) args.push("--dart",process.env.POKEMAP_TEST_DART);
 async function session(run:(call:(name:string,input?:JsonRecord,fails?:boolean)=>Promise<JsonRecord>)=>Promise<void>){
  const transport=new StdioClientTransport({command:process.execPath,args,cwd:process.cwd(),stderr:"pipe"});
  const client=new Client({name:"visual-test",version:"1"});
  async function call(name:string,input:JsonRecord={},fails=false){const body=record((await client.callTool({name,arguments:input})).structuredContent);assert.equal(body.ok,!fails,JSON.stringify(body));return record(body[fails?"error":"data"]);}
  try{await client.connect(transport);await run(call);}finally{await client.close();await transport.close();}
 }
 try{
  await mkdir(join(root,"maps"));await writeFile(join(root,"project.json"),"unreadable unrelated project");await writeFile(join(root,"maps","shore.json"),"unreadable map");
  for(const [i,settings] of [{depthOfFieldEnabled:true,pitchDegrees:34,timeMode:"real",weatherMode:"real",weatherSequence:["clear","rain"],weatherIntervalSeconds:600},{depthOfFieldEnabled:false,timeMode:"fixed",minuteOfDay:1320,weatherMode:"fixed",weatherKind:"storm"},{},{timeMode:"cycle",weatherMode:"automatic",fireflyLighting:true,fireflyGreenAmount:.5,fireflyBlueAmount:.8,fireflyLightRadius:1.25},{weatherEnabled:true,weatherKind:"snow",weatherIntensity:.8},{weatherEnabled:false,weatherKind:"snow"},{weatherEnabled:true,weatherKind:"rain",weatherSoundEnabled:true,weatherRainVolume:.8,weatherWindVolume:.4},{weatherSoundEnabled:false},{}].entries()){
   await session(async call=>{
    const catalog=await call("pokemap_describe");assert.equal(record(catalog.visualSettingsAuthoring).id,"visual.settings.set");
    assert.ok(JSON.stringify(catalog.visualSettingsAuthoring).includes("weatherSoundEnabled"));
    assert.ok(JSON.stringify(catalog.visualSettingsAuthoring).includes("timeMode"));
    assert.ok(JSON.stringify(catalog.visualSettingsAuthoring).includes("weatherSequence"));
    assert.ok(JSON.stringify(catalog.visualSettingsAuthoring).includes("map3d.real-weather@1"));
    const initial=await call("pokemap_visual_settings_inspect",{projectRoot:root});
    const input={projectRoot:root,expectedRevision:initial.revision,settings,operationId:`visual-${i}`};
    const changed=await call("pokemap_visual_settings_set",input);assert.deepEqual(changed.afterSettings,settings);
    const bytes=await readFile(join(root,"project.visual.json"));assert.ok(bytes.length<512);
    const replay=await call("pokemap_visual_settings_set",input);assert.deepEqual(replay.receipt,changed.receipt);
   });
  }
  await session(async call=>{
   const first=await call("pokemap_visual_settings_inspect",{projectRoot:root,mapId:"shore"});
   const changed=await call("pokemap_visual_settings_set",{projectRoot:root,mapId:"shore",expectedRevision:first.revision,settings:{haloStrength:1.2},operationId:"map-visual"});
   await call("pokemap_visual_settings_set",{projectRoot:root,mapId:"shore",expectedRevision:first.revision,settings:{haloStrength:1.4},operationId:"stale-map"},true);
   const undone=await call("pokemap_visual_settings_undo",{projectRoot:root,mapId:"shore",receiptId:record(changed.receipt).receiptId,expectedRevision:changed.afterRevision,operationId:"undo-map-visual"});assert.deepEqual(undone.afterSettings,{});
  });
  assert.equal((await readFile(join(root,"project.json"))).toString(),"unreadable unrelated project");
  assert.equal((await readFile(join(root,"maps","shore.json"))).toString(),"unreadable map");
 }finally{await rm(root,{recursive:true,force:true});}
});

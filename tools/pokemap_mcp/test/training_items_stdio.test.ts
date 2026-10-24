import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";
import { canonicalPokemonConfig } from "./pokemon_fixture.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}
async function tool(client: Client, name: string, args: JsonRecord = {}): Promise<JsonRecord> {
  const result = await client.callTool({ name, arguments: args });
  assert.equal(result.isError, undefined, JSON.stringify(result));
  const envelope = record(result.structuredContent);
  assert.equal(envelope.ok, true, JSON.stringify(envelope));
  return record(envelope.data);
}

test("fresh MCP authors vitamins and battle preparations with typed cold reload", { timeout: 240000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-training-items-"));
  const catalogPath = join(root, "data/pokemon/catalogs/items.json");
  await mkdir(join(root, "maps"), { recursive: true });
  for (const name of ["catalogs", "species", "learnsets", "evolutions", "media"]) {
    await mkdir(join(root, "data/pokemon", name), { recursive: true });
  }
  await writeFile(join(root, "project.json"), JSON.stringify({
    name: "Full Restore contract", version: "v8", tilesets: [], pokemon: canonicalPokemonConfig(),
    maps: [{ id: "lab", name: "Lab", relativePath: "maps/lab.json" }],
  }));
  await writeFile(join(root, "maps/lab.json"), JSON.stringify({
    id: "lab", name: "Lab", version: "v8", size: { width: 3, height: 3 },
  }));
  await writeFile(catalogPath, JSON.stringify({ schemaVersion: 1, entries: [
    { id: "full-restore", displayName: "Soin Total", pocketId: "medicine" },
  ] }));
  for (const name of ["types", "abilities", "moves", "growth_rates"]) {
    await writeFile(join(root, "data/pokemon/catalogs", `${name}.json`),
      JSON.stringify({ schemaVersion: 1, catalog: name, entries: [] }));
  }
  const connect = async (): Promise<Client> => {
    const client = new Client({ name: "full-restore-contract", version: "1.0.0" });
    await client.connect(new StdioClientTransport({
      command: process.execPath,
      args: [resolve(process.env.POKEMAP_TEST_MCP_ENTRY ?? "dist/src/index.js"),
        "--root", root, "--authoring-timeout-ms", "120000"],
      cwd: process.cwd(), stderr: "pipe",
    }));
    return client;
  };

  let client: Client | undefined;
  try {
    client=await connect();
    const described=await tool(client,"pokemap_describe");
    const actions=described.mutationActions as JsonRecord[];
    for(const [context,kind] of [["overworld","vitamin"],["battle","battle_boost"],["battle","battle_preparation"]]) {
      const action=actions.find(a=>a.id===`item.set_${context}_effect`);assert.ok(action);
      assert.ok((record(action.extensions).effectKinds as string[]).includes(kind!));
    }
    const opened=await tool(client,"pokemap_workspace",{operation:"open",projectRoot:root});
    const cases: [string,JsonRecord][]=[
      ["overworld",{kind:"vitamin",stat:"hp",amount:10,maximumPerStat:100,maximumTotal:510,friendshipGainLow:5,friendshipGainMedium:3,friendshipGainHigh:2}],
      ["battle",{kind:"battle_boost",stat:"accuracy",stages:1}],
      ["battle",{kind:"battle_preparation",effect:"focusEnergy",turns:null}],
      ["battle",{kind:"battle_preparation",effect:"mist",turns:5}],
    ];
    for(const [index,[context,effect]] of cases.entries()) {
      const before=await tool(client,"pokemap_validate",{projectHandle:opened.projectHandle});
      const planned=await tool(client,"pokemap_plan",{projectHandle:opened.projectHandle,request:{
        requestId:`training-${index}`,actionId:`item.set_${context}_effect`,actionVersion:1,
        workspaceHandle:opened.workspaceHandle,expectedRevision:before.snapshotRevision,
        parameters:{itemId:"full-restore",use:{contexts:[context],target:"party_member",consumption:"on_applied",effect}},
        idempotencyKey:`training-${index}`,dryRun:false}});
      await tool(client,"pokemap_apply",{operation:"apply",projectHandle:opened.projectHandle,planId:planned.planId,operationId:`training-apply-${index}`});
      const catalog=JSON.parse(await readFile(catalogPath,"utf8")) as {entries: {uses: JsonRecord[]}[]};
      const actual=catalog.entries[0]!.uses.find(u=>(u.contexts as string[]).includes(context));assert.ok(actual);
      assert.deepEqual(actual.effect,effect);
    }
    await tool(client,"pokemap_workspace",{operation:"close",workspaceHandle:opened.workspaceHandle});
    await client.close();client=await connect();
    const reopened=await tool(client,"pokemap_workspace",{operation:"open",projectRoot:root});
    const queried=await tool(client,"pokemap_query",{projectHandle:reopened.projectHandle,resourceKind:"itemDefinition",operation:"get",view:"detail",ids:["full-restore"]});
    const uses=record((queried.items as JsonRecord[])[0]).uses as JsonRecord[];
    assert.equal(uses.length,2);
    assert.equal(record(uses.find(u=>(u.contexts as string[]).includes("overworld"))!.effect).kind,"vitamin");
    assert.deepEqual(uses.find(u=>(u.contexts as string[]).includes("battle"))!.effect,{kind:"battle_preparation",effect:"mist",turns:5});
    await tool(client,"pokemap_workspace",{operation:"close",workspaceHandle:reopened.workspaceHandle});
  } finally {await client?.close();await rm(root,{recursive:true,force:true});}
});


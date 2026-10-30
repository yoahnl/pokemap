import assert from "node:assert/strict";
import { test } from "node:test";
import type { AuthoringGateway, JsonRecord } from "../src/authoring_client.js";
import { checkMapHealth } from "../src/tools/map_check.js";

const revision = `sha256:${"a".repeat(64)}`;

function gateway(verdict = "pass"): AuthoringGateway {
  return {close: async () => {}, request: async () => ({requestId:"health",
    artifacts: [], data: {snapshotRevision:revision, items:[{
      mapId:"map", revision, verdict, issueCount:0, issues:[],
      checks:{visual:{status:"not_run"}}, coverage:{kind:"structural"},
    }]}})};
}

const request = {projectHandle:"project", mapId:"map", visual:"full" as const};

test("none reports only the requested structural scope", async () => {
  const result = await checkMapHealth(gateway(), undefined, {...request,visual:"none"});
  assert.equal(result.data.verdict,"pass");
  assert.equal((result.data.coverage as JsonRecord).requested,"none");
  assert.equal(((result.data.checks as JsonRecord).visual as JsonRecord).status,"not_run");
});

test("full passes only a same-revision complete scan and states its detector limit", async () => {
  const result = await checkMapHealth(gateway(), {scan3d:async () => ({data:{
    revision, views:[{kind:"grid",holeRatio:0}], errors:[], skippedTargetCount:0,
    viewCount:1,gridViewCount:1},artifacts:[]})}, request);
  assert.equal(result.data.verdict,"pass");
  assert.match(String((result.data.coverage as JsonRecord).visualProof),/sentinel/);
});

test("native gaps fail and only relevant images are returned", async () => {
  const result = await checkMapHealth(gateway(), {scan3d:async () => ({data:{
    revision, views:[{kind:"grid",holeRatio:.1,artifactUri:"artifact://hole"},
      {kind:"grid",holeRatio:0,artifactUri:"artifact://clean"}],
    errors:[],skippedTargetCount:0,viewCount:2,gridViewCount:2},
    artifacts:[{uri:"artifact://hole"},{uri:"artifact://clean"}]})}, request);
  assert.equal(result.data.verdict,"fail");
  assert.deepEqual(result.artifacts,[{uri:"artifact://hole"}]);
});

test("missing coverage, skipped views, failures and changed revisions are incomplete", async () => {
  const samples: JsonRecord[] = [
    {revision:"other",views:[],errors:[],skippedTargetCount:0,viewCount:1,gridViewCount:1},
    {revision,views:[],errors:[],skippedTargetCount:2,viewCount:1,gridViewCount:1},
    {revision,views:[],errors:["failure"],skippedTargetCount:0,viewCount:1,gridViewCount:1},
    {revision,views:[],errors:[],skippedTargetCount:0,viewCount:0,gridViewCount:0},
    {},
  ];
  for (const data of samples) {
    const result = await checkMapHealth(gateway(), {scan3d:async () => ({data,artifacts:[]})}, request);
    assert.equal(result.data.verdict,"incomplete",JSON.stringify(data));
  }
  assert.equal((await checkMapHealth(gateway(),undefined,request)).data.verdict,"incomplete");
  assert.equal((await checkMapHealth(gateway(),{scan3d:async () => {throw Error("failed");}},request)).data.verdict,"incomplete");
});

test("a proved structural failure remains failed when visuals are unavailable", async () => {
  assert.equal((await checkMapHealth(gateway("fail"),undefined,request)).data.verdict,"fail");
});

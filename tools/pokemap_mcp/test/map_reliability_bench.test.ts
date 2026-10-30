import assert from "node:assert/strict";
import { test } from "node:test";
import { runMapReliabilityBench,summarizeMapReliabilityBench,type BenchDriver } from "../bench/map_reliability_bench.js";

test("the harness isolates every task and scores persisted independent criteria",async()=>{
  let created=0,closed=0;
  const driver:BenchDriver={
    createFixture:async task=>{
      created++;let calls=0;
      return {tools:[{name:"edit"}],publicContext:{mapId:"field",cell:{x:2,y:3}},cancelAndDrain:async()=>true,call:async()=>{
        calls++;return {result:{status:"applied"},internalRequests:2,work:{mapEncodings:1}};
      },observe:async()=>({source:"persisted_independent_observation",mapHealthVerdict:"pass",
        checks:Object.fromEntries(task.criteria.map(key=>[key,task.id==="T2"?false:calls===1]))}),
      close:async()=>{closed++;}};
    },next:async()=>({content:"edit",usage:{inputTokens:20,outputTokens:10},
      calls:[{name:"edit",arguments:{}}],done:true}),
  };
  const runs=await runMapReliabilityBench({serverVersion:"candidate-sha",models:[{id:"fake",version:"1",parameters:{temperature:0}}],
    budget:{calls:3,tokens:100,milliseconds:1000},repetitions:5},driver);
  assert.equal(runs.length,50);assert.equal(created,50);assert.equal(closed,50);
  assert.equal(runs.filter(run=>run.verdict==="pass").length,45);
  assert.ok(runs.filter(run=>run.taskId==="T2").every(run=>run.verdict==="fail"));
  assert.ok(runs.every(run=>run.calls===1&&run.internalRequests===2&&run.work.mapEncodings===1));
  assert.equal(summarizeMapReliabilityBench(runs)[0]!.calls.median,1);
});

test("safe refusals are counted without being mistaken for corruption or success",async()=>{
  const driver:BenchDriver={createFixture:async()=>({tools:[],publicContext:{},cancelAndDrain:async()=>true,call:async()=>({result:{error:"ambiguous"},internalRequests:1,outcome:"ambiguity"}),
    observe:async()=>({source:"persisted_independent_observation",checks:{zero_writes:true}}),close:async()=>{}}),
    next:async()=>({content:"choose",usage:{inputTokens:1,outputTokens:1},calls:[{name:"edit",arguments:{}}],done:false})};
  const runs=await runMapReliabilityBench({serverVersion:"sha",models:[{id:"fake",version:"1",parameters:{}}],
    budget:{calls:2,tokens:100,milliseconds:1000},repetitions:1},driver);
  assert.ok(runs.every(run=>run.calls===2&&run.stopReason==="call_budget"&&run.verdict==="incomplete"&&run.outcomes.ambiguity===2));
});

test("time budgets abort a stuck model and still observe and close its fixture",async()=>{
  let closed=0;
  const driver:BenchDriver={createFixture:async()=>({tools:[],publicContext:{},cancelAndDrain:async()=>true,call:async()=>{throw Error("unused");},
    observe:async()=>({source:"persisted_independent_observation",checks:{}}),close:async()=>{closed++;}}),
    next:async()=>new Promise(()=>{})};
  const runs=await runMapReliabilityBench({serverVersion:"sha",models:[{id:"fake",version:"1",parameters:{}}],
    budget:{calls:1,tokens:1,milliseconds:5},repetitions:1,split:"reserved"},driver);
  assert.equal(runs.length,9);assert.equal(closed,9);
  assert.ok(runs.every(run=>run.stopReason==="time_budget"&&run.verdict==="incomplete"));
});

test("a satisfied oracle cannot pass an over-budget or undrained run",async()=>{
  for(const drained of [true,false]) {
    let observations=0;
    const driver:BenchDriver={createFixture:async task=>({tools:[],publicContext:{},cancelAndDrain:async()=>drained,
      call:async()=>({result:{},internalRequests:0}),observe:async()=>{
        observations++;return {source:"persisted_independent_observation",checks:Object.fromEntries(task.criteria.map(key=>[key,true]))};
      },close:async()=>{}}),next:async()=>({content:"done",usage:{inputTokens:20,outputTokens:20},calls:[],done:true})};
    const runs=await runMapReliabilityBench({serverVersion:"sha",models:[{id:"fake",version:"1",parameters:{}}],
      budget:{calls:1,tokens:10,milliseconds:1000},repetitions:1},driver);
    assert.ok(runs.every(run=>run.verdict==="incomplete"));
    assert.equal(observations,drained?10:0);
  }
});

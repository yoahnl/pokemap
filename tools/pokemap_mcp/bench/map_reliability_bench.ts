import { performance } from "node:perf_hooks";
import { pathToFileURL } from "node:url";
import { resolve } from "node:path";
import { readFile, writeFile } from "node:fs/promises";
import {
  evaluateMapReliabilityCase, reliabilityCasesForSplit,
  type MapReliabilityCase, type ReliabilityOracleObservation,
} from "./map_reliability_cases.js";

export interface BenchBudget { calls: number; tokens: number; milliseconds: number }
export interface BenchModel { id: string; version: string; parameters: Record<string,unknown> }
export interface BenchConfiguration {
  serverVersion: string;
  models: BenchModel[];
  budget: BenchBudget;
  repetitions?: number;
  split?: "reference" | "reserved";
  evaluationTimeoutMs?: number;
}
export interface BenchMessage { role: "user" | "assistant" | "tool"; content: unknown }
export interface BenchModelReply {
  content: unknown;
  usage: {inputTokens:number;outputTokens:number};
  calls: {name:string;arguments:Record<string,unknown>}[];
  done: boolean;
}
export interface BenchFixture {
  tools: unknown[];
  publicContext: Record<string,unknown>;
  call(name:string,args:Record<string,unknown>,signal:AbortSignal): Promise<{
    result: unknown;
    internalRequests: number;
    outcome?: "guard_refusal" | "ambiguity" | "schema_error" | "retry";
    work?: Record<string,number>;
  }>;
  observe(): Promise<ReliabilityOracleObservation>;
  cancelAndDrain(): Promise<boolean>;
  close(): Promise<void>;
}
export interface BenchDriver {
  createFixture(task:MapReliabilityCase,variant:number,runId:string):Promise<BenchFixture>;
  next(model:BenchModel,messages:readonly BenchMessage[],tools:unknown[],
    remainingTokens:number,signal:AbortSignal):Promise<BenchModelReply>;
}
export interface BenchRun {
  taskId:string; variant:number; repetition:number;
  model:BenchModel; serverVersion:string;
  verdict:"pass"|"fail"|"incomplete";
  failed:string[];missing:string[];
  stopReason:string;
  calls:number;internalRequests:number;bytes:number;
  inputTokens:number;outputTokens:number;milliseconds:number;
  agentMilliseconds:number;
  outcomes:Record<string,number>;work:Record<string,number>;
}

export async function runMapReliabilityBench(config:BenchConfiguration,driver:BenchDriver):Promise<BenchRun[]> {
  const repetitions=config.repetitions??5;
  const evaluationTimeoutMs=config.evaluationTimeoutMs??30000;
  if (!Number.isInteger(repetitions)||repetitions<1||repetitions>100 ||
      Object.values(config.budget).some(value=>!Number.isSafeInteger(value)||value<1) ||
      !Number.isSafeInteger(evaluationTimeoutMs)||evaluationTimeoutMs<1||evaluationTimeoutMs>300000||
      !config.serverVersion||!config.models.length||config.models.some(model=>!model.id||!model.version)) {
    throw new Error("Specify versioned models, a server version and positive integer budgets.");
  }
  const runs:BenchRun[]=[];
  for (const model of config.models) for (const {task,variant} of reliabilityCasesForSplit(config.split??"reference")) {
    for(let repetition=0;repetition<repetitions;repetition++) {
      const runId=`${runs.length}-${task.id}-${variant}-${repetition}`;
      const fixture=await driver.createFixture(task,variant,runId);
      const controller=new AbortController();
      const started=performance.now();
      const timer=setTimeout(()=>controller.abort(new Error("time_budget")),config.budget.milliseconds);
      const messages:BenchMessage[]=[{role:"user",content:{instruction:task.instruction,context:fixture.publicContext}}];
      const run:BenchRun={taskId:task.id,variant,repetition,model,serverVersion:config.serverVersion,
        verdict:"incomplete",failed:[],missing:[...task.criteria],stopReason:"model_done",
        calls:0,internalRequests:0,bytes:Buffer.byteLength(JSON.stringify(fixture.tools)),
        inputTokens:0,outputTokens:0,milliseconds:0,agentMilliseconds:0,outcomes:{},work:{}};
      try {
        while(true) {
          const remaining=config.budget.tokens-run.inputTokens-run.outputTokens;
          if(remaining<=0) {run.stopReason="token_budget";break;}
          const reply=await abortable(driver.next(model,messages,fixture.tools,remaining,controller.signal),controller.signal);
          for(const tokens of Object.values(reply.usage)) {
            if(!Number.isSafeInteger(tokens)||tokens<0) throw new Error("invalid_usage");
          }
          run.inputTokens+=reply.usage.inputTokens;run.outputTokens+=reply.usage.outputTokens;
          messages.push({role:"assistant",content:reply.content});
          run.bytes+=Buffer.byteLength(JSON.stringify(reply));
          if(run.inputTokens+run.outputTokens>config.budget.tokens) {run.stopReason="token_budget";break;}
          if(reply.calls.length===0) {
            if(!reply.done) run.stopReason="model_stalled";
            break;
          }
          for(const call of reply.calls) {
            if(run.calls>=config.budget.calls) {run.stopReason="call_budget";break;}
            controller.signal.throwIfAborted();
            run.calls++;
            run.bytes+=Buffer.byteLength(JSON.stringify(call));
            const response=await abortable(fixture.call(call.name,call.arguments,controller.signal),controller.signal);
            if(!Number.isSafeInteger(response.internalRequests)||response.internalRequests<0) throw new Error("invalid_request_count");
            run.internalRequests+=response.internalRequests;
            if(response.outcome) run.outcomes[response.outcome]=(run.outcomes[response.outcome]??0)+1;
            for(const [key,value] of Object.entries(response.work??{})) {
              if(!Number.isFinite(value)||value<0) throw new Error("invalid_work_measurement");
              run.work[key]=(run.work[key]??0)+value;
            }
            run.bytes+=Buffer.byteLength(JSON.stringify(response.result));
            messages.push({role:"tool",content:{name:call.name,result:response.result}});
          }
          if(run.stopReason==="call_budget") break;
          if(reply.done) break;
        }
      } catch(error) {
        run.stopReason=controller.signal.aborted?"time_budget":error instanceof Error?error.message:"driver_error";
      } finally {
        run.agentMilliseconds=performance.now()-started;
        if(run.agentMilliseconds>config.budget.milliseconds&&run.stopReason==="model_done") run.stopReason="time_budget";
        clearTimeout(timer);
        controller.abort();
        try {
          if(!await abortable(fixture.cancelAndDrain(),AbortSignal.timeout(evaluationTimeoutMs))) throw new Error("fixture_still_running");
          const observation=await abortable(fixture.observe(),AbortSignal.timeout(evaluationTimeoutMs));
          if(observation.source!=="persisted_independent_observation") throw new Error("invalid_oracle_provenance");
          Object.assign(run,evaluateMapReliabilityCase(task,observation));
          if(run.verdict==="pass"&&run.stopReason!=="model_done") run.verdict="incomplete";
        } catch {
          run.stopReason+=";oracle_unavailable";
        }
        await abortable(fixture.close(),AbortSignal.timeout(evaluationTimeoutMs));
        run.milliseconds=performance.now()-started;
      }
      runs.push(run);
    }
  }
  return runs;
}

function abortable<T>(work:Promise<T>,signal:AbortSignal):Promise<T> {
  return new Promise((accept,reject)=>{
    const abort=()=>reject(signal.reason);
    signal.addEventListener("abort",abort,{once:true});
    work.then(accept,reject).finally(()=>signal.removeEventListener("abort",abort));
    if(signal.aborted) abort();
  });
}

function quantile(values:number[],fraction:number):number {
  const sorted=[...values].sort((a,b)=>a-b),index=(sorted.length-1)*fraction;
  const low=sorted[Math.floor(index)]??0,high=sorted[Math.ceil(index)]??low;
  return low+(high-low)*(index-Math.floor(index));
}

export function summarizeMapReliabilityBench(runs:readonly BenchRun[]) {
  const groups=new Map<string,BenchRun[]>();
  for(const run of runs) {
    const key=JSON.stringify([run.serverVersion,run.model,run.taskId]);
    const group=groups.get(key)??[];group.push(run);groups.set(key,group);
  }
  return [...groups.values()].map(group=>({serverVersion:group[0]!.serverVersion,
    model:group[0]!.model,taskId:group[0]!.taskId,total:group.length,
    pass:group.filter(run=>run.verdict==="pass").length,
    fail:group.filter(run=>run.verdict==="fail").length,
    incomplete:group.filter(run=>run.verdict==="incomplete").length,
    passRate:group.filter(run=>run.verdict==="pass").length/group.length,
    calls:{median:quantile(group.map(run=>run.calls),.5),q1:quantile(group.map(run=>run.calls),.25),q3:quantile(group.map(run=>run.calls),.75)},
    milliseconds:{median:quantile(group.map(run=>run.milliseconds),.5),q1:quantile(group.map(run=>run.milliseconds),.25),q3:quantile(group.map(run=>run.milliseconds),.75)},
  }));
}

async function main():Promise<void> {
  const [configuration,driverPath,output]=process.argv.slice(2);
  if(!configuration||!driverPath||!output) throw new Error("Usage: map_reliability_bench.ts configuration.json driver.mjs result.json; real models are opt-in.");
  const config=JSON.parse(await readFile(resolve(configuration),"utf8")) as BenchConfiguration;
  const driver=(await import(pathToFileURL(resolve(driverPath)).href)).default as BenchDriver;
  const runs=await runMapReliabilityBench(config,driver);
  await writeFile(resolve(output),JSON.stringify({configuration:config,runs,summary:summarizeMapReliabilityBench(runs)},null,2));
}

if(process.argv[1]&&import.meta.url===pathToFileURL(resolve(process.argv[1])).href) {
  main().catch(error=>{process.stderr.write(`${error instanceof Error?error.message:"Benchmark failed"}\n`);process.exitCode=1;});
}

import assert from "node:assert/strict";
import { mkdir, mkdtemp, rm, stat, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { LocalAuthoringClient } from "../src/authoring_client.js";

test("durable canonical notifications bind old handles and skip plan and revoked roots", async (t) => {
  const qa = join(homedir(), "Library/Caches/AveluneQA/mcp-studio-integration/i3");
  await mkdir(qa, { recursive: true });
  const root = await mkdtemp(join(qa, "observer-"));
  t.after(() => rm(root, { recursive: true, force: true }));
  const script = join(root, "worker.mjs");
  await writeFile(script, `import { createInterface } from 'node:readline';
createInterface({input:process.stdin}).on('line',line=>{
 const r=JSON.parse(line);
 const payload=Buffer.from(JSON.stringify(Array.from({length:1000},(_,i)=>({kind:'map',id:'map-'+i}))));
 const data=r.command==='surf_configure'?{receipt:{status:'applied',afterRevision:'settings-revision',affectedResources:[{kind:'project',id:'project'}],diff:{entries:[{resource:{kind:'project',id:'project'},path:'/settings/surf',before:{enabled:true},after:{enabled:false}}]}}}:
 r.command==='map_atmosphere_set'?{receipt:{status:'applied',afterRevision:'native-revision',affectedResources:[{kind:'mapAtmosphere',id:'native-map'}],extensions:{operationId:'native-op'}}}:
 r.command==='projection'&&r.args.operation==='payload'?{bytesBase64:payload.subarray(r.args.offset,r.args.offset+1024).toString('base64'),nextOffset:Math.min(payload.length,r.args.offset+1024)}:
 r.command==='large'?{changeNotification:{revision:'large-revision',revisionScope:'transaction_resource_set',status:'resumed',resources:{projectionType:'jsonPayload',payloadRef:'owned-payload',byteLength:payload.length}}}:
 r.command==='open'?{projectHandle:'old-project',workspaceHandle:'old-workspace'}:
  r.command==='plan'?{receipt:{status:'planned',affectedResources:[{kind:'map',id:'wrong'}]}}:
  r.command==='close'?{}:{changeNotification:{revision:'resource-set-revision',revisionScope:'transaction_resource_set',status:'applied',operationId:'canonical-op',resources:[{kind:'map',id:'actual-map'}]}};
 setTimeout(()=>process.stdout.write(JSON.stringify({requestId:r.id,status:'success',data,artifacts:[]})+'\\n'),r.command==='late'?50:0);
});`);
  const events: unknown[] = [];
  const client = new LocalAuthoringClient({ allowedRoots: [root],
    workerCommand: { executable: process.execPath, args: [script], cwd: root },
    onMutation: event => { events.push(event); },
  });
  t.after(() => client.close());
  await client.request('open', { projectRoot: root });
  await client.request('plan', {projectHandle:'old-project'});
  assert.equal(events.length, 0);
  for (const command of ['projection','query','history','recovery_status']) {
    await client.request(command,{projectHandle:'old-project',operation:'receipt'});
    assert.equal(events.length,0,command+' must not publish a mutation from a stored receipt');
  }
  await client.request('apply', {projectHandle:'old-project',mapId:'parameter-must-not-leak'});
  assert.deepEqual(events, [{ type:'mutation',projectRoot:root,revision:'resource-set-revision',operationId:'canonical-op',resources:[{kind:'map',id:'actual-map'}]}]);
  await client.request('map_atmosphere_set',{projectRoot:root,mapId:'wrong-parameter'});
  assert.deepEqual(events.at(-1),{type:'mutation',projectRoot:root,revision:'native-revision',operationId:'native-op',resources:[{kind:'mapAtmosphere',id:'native-map'}]});
  await client.request('surf_configure',{projectRoot:root,configuration:{enabled:true}});
  assert.deepEqual(events.at(-1),{type:'mutation',projectRoot:root,revision:'settings-revision',resources:[{kind:'project',id:'project'},{kind:'projectSettings',id:'surf'}]});
  await client.request('large',{projectHandle:'old-project'});
  assert.equal(events.length,13);
  assert.deepEqual(events.slice(3).flatMap(event=>(event as {resources:unknown[]}).resources),Array.from({length:1000},(_,i)=>({kind:'map',id:'map-'+i})));
  const late = client.request('late', {projectHandle:'old-project'});
  await client.request('close', {workspaceHandle:'old-workspace'});
  await late;
  assert.equal(events.length, 13);
});

for (const scope of ["same-directory", "parent-directory", "virtual-directory"] as const) {
  test(`successful open binds authorized spelling only for the same directory: ${scope}`, {
    skip: scope === "same-directory" && process.platform !== "darwin",
  }, async (t) => {
    const qa = join(homedir(), "Library/Caches/AveluneQA/mcp-studio-integration/i3");
    await mkdir(qa, { recursive: true });
    const root = await mkdtemp(join(qa, "unicode-binding-"));
    t.after(() => rm(root, { recursive: true, force: true }));
    const script = join(root, "worker.mjs");
    await writeFile(script, `import { createInterface } from 'node:readline';
createInterface({input:process.stdin}).on('line',line=>{
 const r=JSON.parse(line);
 const data=r.command==='open'?{projectHandle:'project',workspaceHandle:'workspace'}:
 {changeNotification:{revision:'durable-revision',revisionScope:'transaction_resource_set',status:'applied',resources:[{kind:'map',id:'actual-map'}]}};
 process.stdout.write(JSON.stringify({requestId:r.id,status:'success',data,artifacts:[]})+'\\n');
});`);
    const project = join(root, "Jeu émeraude");
    await mkdir(project);
    const requested = scope === "virtual-directory" ? "/virtual/pokemap/project" : project.normalize("NFC");
    const allowed = scope === "same-directory" ? project.normalize("NFD") :
      scope === "parent-directory" ? root : "/virtual/pokemap";
    const expected = scope === "same-directory" ? allowed : requested;
    if (scope === "same-directory") {
      assert.notEqual(allowed, requested);
      const a = await stat(allowed, {bigint:true}), b = await stat(requested, {bigint:true});
      assert.equal(a.dev, b.dev);
      assert.equal(a.ino, b.ino);
    }
    const events: unknown[] = [];
    const client = new LocalAuthoringClient({allowedRoots:[allowed],
      workerCommand:{executable:process.execPath,args:[script],cwd:root}, onMutation:event=>events.push(event)});
    t.after(() => client.close());
    await client.request("open", {projectRoot:requested});
    assert.equal(client.resolveProjectRoot("project"), expected);
    await client.request("map_edit", {projectHandle:"project"});
    assert.deepEqual(events, [{type:"mutation",projectRoot:expected,revision:"durable-revision",resources:[{kind:"map",id:"actual-map"}]}]);
    await client.request("close", {workspaceHandle:"workspace"});
    assert.throws(() => client.resolveProjectRoot("project"));
  });
}

import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { chmod, copyFile, mkdir, mkdtemp, readFile, rm, symlink, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { homedir } from "node:os";
import { test } from "node:test";

import { PackagedRuntimeError, resolvePackagedRuntime } from "../src/packaged_runtime.js";

const qaRoot = join(homedir(), "Library/Caches/AveluneQA/mcp-studio-integration/i0");

async function fixture() {
  await mkdir(qaRoot, { recursive: true });
  const root = await mkdtemp(join(qaRoot, "bundle été "));
  await mkdir(join(root, "bin"));
  const binary = join(root, "bin", process.platform === "win32" ? "worker.exe" : "worker");
  await copyFile(process.execPath, binary);
  await chmod(binary, 0o700);
  const bytes = await readFile(binary);
  const manifest = {
    schemaVersion: 1,
    platform: process.platform,
    architecture: process.arch,
    provenance: { version: "0.1.0", commit: "1".repeat(40) },
    components: [{
      id: "authoring", kind: "executable", path: `bin/${process.platform === "win32" ? "worker.exe" : "worker"}`,
      sha256: createHash("sha256").update(bytes).digest("hex"),
      capabilities: ["authoring", "game_export"], licenses: ["MIT"],
    }],
  };
  const manifestPath = join(root, "runtime.json");
  const save = () => writeFile(manifestPath, JSON.stringify(manifest));
  await save();
  return { root, binary, manifest, manifestPath, save };
}

test("resolves packaged components from the manifest with spaces and Unicode", async (t) => {
  const f = await fixture();
  t.after(() => rm(f.root, { recursive: true, force: true }));
  const runtime = await resolvePackagedRuntime(f.manifestPath);
  assert.equal(runtime.bundleRoot, f.root);
  assert.equal(runtime.components.get("authoring")?.absolutePath, f.binary);
  assert.deepEqual(runtime.command("authoring"), { executable: f.binary, args: [], cwd: f.root });
  assert.throws(() => runtime.command("absent"), PackagedRuntimeError);
});

test("rejects missing components, corrupted bytes and incompatible platforms without fallback", async (t) => {
  const f = await fixture();
  t.after(() => rm(f.root, { recursive: true, force: true }));
  await assert.rejects(resolvePackagedRuntime(f.manifestPath, { platform: "unsupported" }), /platform/);
  await assert.rejects(resolvePackagedRuntime(f.manifestPath, { architecture: "unsupported" }), /architecture/);
  await writeFile(f.binary, "damaged");
  await assert.rejects(resolvePackagedRuntime(f.manifestPath), /integrity/);
  await rm(f.binary);
  await assert.rejects(resolvePackagedRuntime(f.manifestPath), /unavailable/);
});

test("rejects absolute paths, traversal, duplicate IDs and unknown manifest versions", async (t) => {
  const f = await fixture();
  t.after(() => rm(f.root, { recursive: true, force: true }));
  for (const path of [f.binary, "../outside", "bin/../bin/worker", "C:\\worker.exe", "bin\\worker", ""]) {
    f.manifest.components[0]!.path = path;
    await f.save();
    await assert.rejects(resolvePackagedRuntime(f.manifestPath), /path/);
  }
  f.manifest.components[0]!.path = "bin/worker";
  f.manifest.components.push({ ...f.manifest.components[0]! });
  await f.save();
  await assert.rejects(resolvePackagedRuntime(f.manifestPath), /duplicate/);
  f.manifest.schemaVersion = 2;
  await f.save();
  await assert.rejects(resolvePackagedRuntime(f.manifestPath), /version/);
});

test("rejects symlink escapes, undeclared licences and non-executable components", async (t) => {
  const f = await fixture();
  t.after(() => rm(f.root, { recursive: true, force: true }));
  if (process.platform !== "win32") {
    await rm(f.binary);
    await symlink(process.execPath, f.binary);
    await assert.rejects(resolvePackagedRuntime(f.manifestPath), /outside/);
    await rm(f.binary);
    await copyFile(process.execPath, f.binary);
    await chmod(f.binary, 0o600);
    await assert.rejects(resolvePackagedRuntime(f.manifestPath), /executable/);
  }
  f.manifest.components[0]!.licenses = [];
  await f.save();
  await assert.rejects(resolvePackagedRuntime(f.manifestPath), /licen/);
});

test("verifies declared resources and refuses to execute them", async (t) => {
  const f = await fixture();
  t.after(() => rm(f.root, { recursive: true, force: true }));
  const contents = "packaged server module";
  await writeFile(join(f.root, "server.js"), contents);
  f.manifest.components.push({
    id: "server", kind: "resource", path: "server.js",
    sha256: createHash("sha256").update(contents).digest("hex"),
    capabilities: ["mcp"], licenses: ["MIT"],
  });
  await f.save();
  const runtime = await resolvePackagedRuntime(f.manifestPath);
  assert.equal(runtime.components.get("server")?.absolutePath, join(f.root, "server.js"));
  assert.throws(() => runtime.command("server"), PackagedRuntimeError);
  await writeFile(join(f.root, "server.js"), "changed");
  await assert.rejects(resolvePackagedRuntime(f.manifestPath), /integrity/);
});

test("launches a precompiled snapshot only through a verified resource reference",async t=>{
  const f=await fixture();t.after(()=>rm(f.root,{recursive:true,force:true}));
  const snapshot=join(f.root,"bin/authoring.aot"),bytes=Buffer.from("snapshot-fixture");
  await writeFile(snapshot,bytes);
  f.manifest.components.push({id:"snapshot",kind:"resource",path:"bin/authoring.aot",
    sha256:createHash("sha256").update(bytes).digest("hex"),capabilities:["authoring.snapshot"],licenses:["MIT"]});
  Object.assign(f.manifest.components[0]!,{entrypoint:"snapshot"});await f.save();
  const runtime=await resolvePackagedRuntime(f.manifestPath);
  assert.deepEqual(runtime.command("authoring").args,[snapshot]);
  Object.assign(f.manifest.components[0]!,{entrypoint:"absent"});await f.save();
  const missing=await resolvePackagedRuntime(f.manifestPath);
  assert.throws(()=>missing.command("authoring"),/snapshot/);
  Object.assign(f.manifest.components[0]!,{entrypoint:"../snapshot"});await f.save();
  await assert.rejects(resolvePackagedRuntime(f.manifestPath),/entrypoint/);
});

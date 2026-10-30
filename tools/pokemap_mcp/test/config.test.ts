import assert from "node:assert/strict";
import { resolve } from "node:path";
import { test } from "node:test";

import { parseConfig } from "../src/config.js";

test("stdio remains the default and rootless discovery requires the Studio companion",()=>{
  assert.equal(parseConfig(["--root","/fixture"]).transport,"stdio");
  assert.equal(parseConfig(["--root","/fixture"]).companion,false);
  assert.throws(()=>parseConfig([]));
  assert.throws(()=>parseConfig(["--transport","http"]));
  assert.throws(()=>parseConfig(["--companion","true"]));
  const companion=parseConfig(["--transport","http","--companion","true"]);
  assert.deepEqual(companion.allowedRoots,[]);
  assert.deepEqual(companion.artifactRoots,[]);
  assert.deepEqual(companion.exportRoots,[]);
  assert.equal(companion.port,0);
});

test("installed configuration never accepts checkout or executable overrides",()=>{
  const args=["--runtime-manifest","/installed/runtime-manifest.json","--root","/fixture"];
  assert.equal(parseConfig(args).repositoryRoot,"/installed");
  for(const option of ["--authoring-package","--repository-root","--runtime-package","--runtime-host","--render-host","--dart","--flutter"]) {
    assert.throws(()=>parseConfig([...args,option,"/checkout/override"]));
  }
  for(const value of ["-1","65536","1.5","NaN"]) assert.throws(()=>parseConfig(["--root","/fixture","--port",value]));
  assert.throws(()=>parseConfig(["--root","/fixture","--transport","websocket"]));
});

test("parses artifact roots separately from project roots", () => {
  const repositoryRoot = resolve(process.cwd(), "../..");
  const projectRoot = resolve(repositoryRoot, "examples/playable_runtime_host");
  const artifactRoot = resolve(repositoryRoot, ".dart_tool/pokemap-artifacts");

  const config = parseConfig([
    "--root",
    projectRoot,
    "--artifact-root",
    artifactRoot,
    "--authoring-package",
    resolve(repositoryRoot, "packages/map_authoring"),
    "--repository-root",
    repositoryRoot,
    "--runtime-package",
    resolve(repositoryRoot, "packages/map_runtime"),
    "--runtime-host",
    resolve(repositoryRoot, "examples/playable_runtime_host"),
  ]);

  assert.deepEqual(config.allowedRoots, [projectRoot]);
  assert.deepEqual(config.artifactRoots, [artifactRoot]);
});

test("accepts a bounded authoring deadline for large project mutations", () => {
  const roots = ["--root", resolve(process.cwd(), "../..")];
  assert.equal(parseConfig([...roots, "--authoring-timeout-ms", "60000"]).authoringTimeoutMs, 60000);
  for (const value of ["0", "-1", "1.5", "NaN", "120001"]) {
    assert.throws(() => parseConfig([...roots, "--authoring-timeout-ms", value]));
  }
});

test("accepts a separate bounded export deadline without widening ordinary requests", () => {
  const roots = ["--root", resolve(process.cwd(), "../..")];
  assert.equal(parseConfig(roots).exportTimeoutMs, undefined);
  assert.equal(parseConfig(roots).authoringTimeoutMs, undefined);
  for (const value of [1, 120000, 600000]) {
    const config = parseConfig([...roots, "--export-timeout-ms", String(value)]);
    assert.equal(config.exportTimeoutMs, value);
    assert.equal(config.authoringTimeoutMs, undefined);
    assert.deepEqual(config.allowedRoots, [resolve(process.cwd(), "../..")]);
    assert.deepEqual(config.artifactRoots, []);
    assert.deepEqual(config.exportRoots, []);
  }
  for (const value of ["0", "-1", "1.5", "NaN", "Infinity", "600001"]) {
    assert.throws(() => parseConfig([...roots, "--export-timeout-ms", value]));
  }
  assert.throws(() => parseConfig([...roots, "--export-timeout-ms"]));
  assert.throws(() => parseConfig([...roots, "--authoring-timeout-ms", "120001"]));
  const both = parseConfig([...roots, "--export-timeout-ms", "600000", "--authoring-timeout-ms", "120000"]);
  assert.equal(both.exportTimeoutMs, 600000);
  assert.equal(both.authoringTimeoutMs, 120000);
});

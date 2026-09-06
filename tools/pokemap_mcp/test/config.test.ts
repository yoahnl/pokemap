import assert from "node:assert/strict";
import { resolve } from "node:path";
import { test } from "node:test";

import { parseConfig } from "../src/config.js";

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

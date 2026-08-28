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

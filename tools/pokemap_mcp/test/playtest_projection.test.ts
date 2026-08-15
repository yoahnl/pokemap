import assert from "node:assert/strict";
import {
  mkdtemp,
  mkdir,
  readFile,
  readdir,
  realpath,
  rm,
  stat,
  symlink,
  writeFile,
} from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, relative, resolve } from "node:path";
import { test } from "node:test";

import {
  LocalAuthoringClient,
  type AuthoringGateway,
  type AuthoringWorkerSuccess,
  type JsonRecord,
} from "../src/authoring_client.js";
import {
  createLocalPlaytestProjectionFactory,
  type CertifiedPlaytestProjection,
} from "../src/playtest_projection.js";
import { PokeMapToolError } from "../src/tool_error.js";

const revision = `sha256:${"a".repeat(64)}`;

test("playtest projection freezes validated bytes and removes them on dispose", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-playtest-projection-"));
  const sourceRoot = resolve(root, "projects", "source");
  const runtimeHostRoot = resolve(root, "runtime-host");
  await mkdir(resolve(sourceRoot, "data"), { recursive: true });
  await writeFile(resolve(sourceRoot, "project.json"), '{"version":1}');
  await writeFile(resolve(sourceRoot, "data", "catalog.json"), '{"value":"old"}');
  const validatedRoots: string[] = [];
  const factory = createLocalPlaytestProjectionFactory({
    authoring: readyAuthoring(),
    authoringPackageRoot: root,
    repositoryRoot: root,
    runtimeHostRoot,
    projectionValidator: async (projectRoot) => {
      validatedRoots.push(projectRoot);
      assert.equal(
        await readFile(resolve(projectRoot, "data", "catalog.json"), "utf8"),
        '{"value":"old"}',
      );
      return readyValidation();
    },
  });

  let projection: CertifiedPlaytestProjection | undefined;
  try {
    projection = await factory(context(sourceRoot));
    await writeFile(resolve(sourceRoot, "data", "catalog.json"), '{"value":"new"}');

    assert.deepEqual(validatedRoots, [projection.projectRoot]);
    assert.equal(
      await readFile(resolve(projection.projectRoot, "data", "catalog.json"), "utf8"),
      '{"value":"old"}',
    );
    assert.match(projection.projectTreeHash, /^[0-9a-f]{64}$/u);
    assert.equal(projection.authoringRevision, revision);
    assert.equal(
      projection.projectRelativeRoot,
      relative(await realpath(root), projection.projectRoot)
        .split("\\")
        .join("/"),
    );

    const projectionParent = resolve(projection.projectRoot, "..");
    await projection.dispose();
    projection = undefined;
    await assert.rejects(stat(projectionParent));
  } finally {
    await projection?.dispose();
    await rm(root, { recursive: true, force: true });
  }
});

test("playtest projection fails closed and cleans invalid catalog bytes", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-playtest-invalid-"));
  const sourceRoot = resolve(root, "projects", "source");
  const runtimeHostRoot = resolve(root, "runtime-host");
  await mkdir(sourceRoot, { recursive: true });
  await writeFile(resolve(sourceRoot, "project.json"), '{}');
  const factory = createLocalPlaytestProjectionFactory({
    authoring: readyAuthoring(),
    authoringPackageRoot: root,
    repositoryRoot: root,
    runtimeHostRoot,
    projectionValidator: async () => ({
      valid: false,
      snapshotRevision: revision,
      pokemonCatalog: { canPlaytest: false, diagnostics: [{ code: "invalid" }] },
    }),
  });

  try {
    await assert.rejects(factory(context(sourceRoot)), (error: unknown) => {
      assert.ok(error instanceof PokeMapToolError);
      assert.equal(error.code, "pokemon.catalog_not_ready");
      return true;
    });
    const inputRoot = resolve(runtimeHostRoot, "build", "pokemap-eval", "input");
    const remaining = await readdir(inputRoot).catch(() => []);
    assert.deepEqual(remaining, []);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("playtest projection rejects bytes changed by validation", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-playtest-drift-"));
  const sourceRoot = resolve(root, "projects", "source");
  const runtimeHostRoot = resolve(root, "runtime-host");
  await mkdir(sourceRoot, { recursive: true });
  await writeFile(resolve(sourceRoot, "project.json"), '{}');
  const factory = createLocalPlaytestProjectionFactory({
    authoring: readyAuthoring(),
    authoringPackageRoot: root,
    repositoryRoot: root,
    runtimeHostRoot,
    projectionValidator: async (projectRoot) => {
      await writeFile(resolve(projectRoot, "project.json"), '{"drift":true}');
      return readyValidation();
    },
  });

  try {
    await assert.rejects(factory(context(sourceRoot)), (error: unknown) => {
      assert.ok(error instanceof PokeMapToolError);
      assert.equal(error.code, "playtest.revision_drift");
      return true;
    });
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("playtest projection uses the canonical Authoring validator on its copy", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-playtest-canonical-"));
  const sourceRoot = resolve(root, "projects", "source");
  for (const directory of ["species", "learnsets", "evolutions", "media"]) {
    await mkdir(resolve(sourceRoot, "data", "pokemon", directory), {
      recursive: true,
    });
  }
  await writeFile(
    resolve(sourceRoot, "project.json"),
    JSON.stringify({
      name: "Playtest projection",
      version: "v6",
      maps: [],
      tilesets: [],
      pokemon: {
        enabled: false,
        dataRoot: "data/pokemon",
        speciesDir: "data/pokemon/species",
        learnsetsDir: "data/pokemon/learnsets",
        evolutionsDir: "data/pokemon/evolutions",
        mediaDir: "data/pokemon/media",
        catalogFiles: {},
        ruleset: canonicalRuleset(),
      },
    }),
  );
  const authoringPackageRoot = resolve(process.cwd(), "../../packages/map_authoring");
  const authoring = new LocalAuthoringClient({
    allowedRoots: [sourceRoot],
    authoringPackageRoot,
    requestTimeoutMs: 60_000,
  });

  try {
    const opened = await authoring.request("open", { projectRoot: sourceRoot });
    const projectHandle = String(opened.data.projectHandle);
    const factory = createLocalPlaytestProjectionFactory({
      authoring,
      authoringPackageRoot,
      repositoryRoot: root,
      runtimeHostRoot: resolve(root, "runtime-host"),
    });
    const projection = await factory({
      ...context(sourceRoot),
      projectHandle,
    });

    assert.match(projection.projectTreeHash, /^[0-9a-f]{64}$/u);
    assert.match(projection.authoringRevision, /^sha256:[0-9a-f]{64}$/u);
    await projection.dispose();
  } finally {
    await authoring.close();
    await rm(root, { recursive: true, force: true });
  }
});

test("playtest projection rejects a symlink in its destination chain", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-playtest-destination-"));
  const sourceRoot = resolve(root, "projects", "source");
  const runtimeHostRoot = resolve(root, "runtime-host");
  const outsideRoot = resolve(root, "outside");
  await mkdir(sourceRoot, { recursive: true });
  await mkdir(runtimeHostRoot, { recursive: true });
  await mkdir(outsideRoot, { recursive: true });
  await writeFile(resolve(sourceRoot, "project.json"), "{}");
  await symlink(outsideRoot, resolve(runtimeHostRoot, "build"));
  const factory = createLocalPlaytestProjectionFactory({
    authoring: readyAuthoring(),
    authoringPackageRoot: root,
    repositoryRoot: root,
    runtimeHostRoot,
    projectionValidator: async () => readyValidation(),
  });

  try {
    await assert.rejects(factory(context(sourceRoot)), (error: unknown) => {
      assert.ok(error instanceof PokeMapToolError);
      assert.equal(error.code, "playtest.projection_path_unsafe");
      return true;
    });
    assert.deepEqual(await readdir(outsideRoot), []);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("playtest projection stops traversal at its entry quota", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-playtest-quota-"));
  const sourceRoot = resolve(root, "projects", "source");
  const runtimeHostRoot = resolve(root, "runtime-host");
  await mkdir(resolve(sourceRoot, "data"), { recursive: true });
  await writeFile(resolve(sourceRoot, "project.json"), "{}");
  await writeFile(resolve(sourceRoot, "data", "catalog.json"), "{}");
  const factory = createLocalPlaytestProjectionFactory({
    authoring: readyAuthoring(),
    authoringPackageRoot: root,
    repositoryRoot: root,
    runtimeHostRoot,
    maxFileCount: 1,
    projectionValidator: async () => readyValidation(),
  });

  try {
    await assert.rejects(factory(context(sourceRoot)), (error: unknown) => {
      assert.ok(error instanceof PokeMapToolError);
      assert.equal(error.code, "playtest.projection_quota_exceeded");
      return true;
    });
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("playtest projection fails closed when immutability is unavailable", async () => {
  const root = await mkdtemp(join(tmpdir(), "pokemap-playtest-platform-"));
  let authoringRequests = 0;
  const factory = createLocalPlaytestProjectionFactory({
    authoring: {
      request: async () => {
        authoringRequests += 1;
        throw new Error("must not validate");
      },
      close: async () => {},
    },
    authoringPackageRoot: root,
    repositoryRoot: root,
    runtimeHostRoot: resolve(root, "runtime-host"),
    platform: "win32",
  });

  try {
    await assert.rejects(factory(context(root)), (error: unknown) => {
      assert.ok(error instanceof PokeMapToolError);
      assert.equal(error.code, "playtest.projection_immutable_unavailable");
      return true;
    });
    assert.equal(authoringRequests, 0);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

function context(sourceProjectRoot: string) {
  return {
    jobId: "job",
    projectHandle: "project-handle",
    sourceProjectRoot,
    request: {
      projectHandle: "project-handle",
      scenarioId: "scenario",
      target: "headless" as const,
    },
    signal: new AbortController().signal,
    emit: () => {},
  };
}

function readyAuthoring(): AuthoringGateway {
  return {
    request: async (command: string): Promise<AuthoringWorkerSuccess> => {
      assert.equal(command, "validate");
      return {
        requestId: "request",
        data: readyValidation(),
        artifacts: [],
      };
    },
    close: async () => {},
  };
}

function readyValidation(): JsonRecord {
  return {
    valid: true,
    snapshotRevision: revision,
    pokemonCatalog: { canPlaytest: true, diagnostics: [] },
  };
}

function canonicalRuleset(): JsonRecord {
  return {
    schemaVersion: 1,
    profileId: "pokemap-beta-v1",
    typeChartId: "mainline-modern-v1",
    maxLevel: 100,
    experiencePolicyId: "pokemap-simple-exp-v1",
    capturePolicyId: "pokemap-capture-mvp-v1",
    moveMachinePolicyId: "authored-consumability-v1",
    criticalHitPolicyId: "mainline-gen9-critical",
    speedTiePolicyId: "mainline-gen9-seeded-random",
    friendshipPolicyId: "mainline-0-255-v1",
    evolutionPolicyId: "pokemap-beta-evolution-v1",
    disabledFeatures: [
      "breeding",
      "double-battles",
      "modern-gimmicks",
      "online",
    ],
  };
}

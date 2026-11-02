import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { homedir, tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";
import { promisify } from "node:util";

import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";

import type { JsonRecord } from "../src/authoring_client.js";
import { canonicalPokemonConfig } from "./pokemon_fixture.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("MCP rejects scoped media undo after the manifest media directory moves", { timeout: 120_000 }, async () => {
  const qaRoot = process.env.AVELUNE_QA_ROOT ?? (process.platform === "darwin"
    ? join(homedir(), "Library/Caches/AveluneQA")
    : tmpdir());
  await mkdir(qaRoot, { recursive: true });
  const root = await mkdtemp(join(qaRoot, "pokemon-media-history-mcp-"));
  const entry = resolve(process.env.POKEMAP_TEST_MCP_ENTRY ?? "dist/src/index.js");
  const args = [entry, "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_AUTHORING_PACKAGE) {
    args.push("--authoring-package", process.env.POKEMAP_TEST_AUTHORING_PACKAGE,
      "--repository-root", resolve(process.cwd(), "../.."));
  }
  const client = new Client({ name: "pokemon-media-history-test", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  async function call(name: string, input: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: input });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify(envelope));
    return record(envelope[failure ? "error" : "data"]);
  }
  try {
    const relativePath = "data/pokemon/media/cyndaquil.json";
    const mediaPath = join(root, relativePath);
    const projectPath = join(root, "project.json");
    const project = {
      name: "Pokemon media history", version: "v8", maps: [], tilesets: [],
      pokemon: { ...canonicalPokemonConfig(), enabled: true },
    };
    const media = {
      schemaVersion: 2, speciesId: "cyndaquil", defaultFormId: "base",
      variants: { base: { frontAnimated: "assets/front.gif" } },
    };
    const before = Buffer.from(JSON.stringify(media));
    await mkdir(join(root, "data/pokemon/media"), { recursive: true });
    await writeFile(projectPath, JSON.stringify(project));
    await writeFile(mediaPath, before);
    await client.connect(transport);
    const workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    await call("pokemap_workshop", { operation: "prepare", projectHandle: workspace.projectHandle });
    const parameters = {
      relativePath,
      beforeBytesBase64: before.toString("base64"),
      document: { ...media, variants: { base: { frontAnimated: "assets/front.gif", frontStatic: "assets/front.png" } } },
    };
    const scope = await call("pokemap_workshop", {
      operation: "read", projectHandle: workspace.projectHandle, actionId: "pokemon.media.write", parameters,
    });
    const plan = await call("pokemap_plan", {
      projectHandle: workspace.projectHandle,
      request: {
        requestId: "media-history", actionId: "pokemon.media.write", actionVersion: 1,
        workspaceHandle: workspace.workspaceHandle, expectedRevision: scope.snapshotRevision,
        extensions: scope.planExtensions, idempotencyKey: "media-history", parameters,
      },
    });
    const applied = await call("pokemap_apply", {
      operation: "apply", projectHandle: workspace.projectHandle,
      planId: plan.planId, operationId: "media-history",
    });
    const after = await readFile(mediaPath);
    await writeFile(projectPath, JSON.stringify({
      ...project, pokemon: { ...project.pokemon, mediaDir: "data/pokemon/moved" },
    }));
    const error = await call("pokemap_history", {
      operation: "undo", projectHandle: workspace.projectHandle,
      entryId: record(applied.receipt).receiptId, idempotencyKey: "media-history-undo",
    }, true);
    assert.equal(error.domainCode, "history.pokemon_media_path_changed");
    assert.deepEqual(await readFile(mediaPath), after);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

test("MCP rejects media schema changes before interpreting legacy extensions", { timeout: 120_000 }, async () => {
  const qaRoot = process.env.AVELUNE_QA_ROOT ?? (process.platform === "darwin"
    ? join(homedir(), "Library/Caches/AveluneQA")
    : tmpdir());
  await mkdir(qaRoot, { recursive: true });
  const root = await mkdtemp(join(qaRoot, "pokemon-media-mcp-"));
  const entry = resolve(process.env.POKEMAP_TEST_MCP_ENTRY ?? "dist/src/index.js");
  const args = [entry, "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_AUTHORING_PACKAGE) {
    args.push("--authoring-package", process.env.POKEMAP_TEST_AUTHORING_PACKAGE,
      "--repository-root", resolve(process.cwd(), "../.."));
  }
  const client = new Client({ name: "pokemon-media-schema-test", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });

  async function call(name: string, input: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: input });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify(envelope));
    return record(envelope[failure ? "error" : "data"]);
  }

  try {
    await client.connect(transport);
    const description = await call("pokemap_describe");
    for (const id of ["pokemon.media.write", "pokemon.documents.write"]) {
      assert.ok((description.mutationActions as JsonRecord[]).some(action => action.id === id && action.version === 1));
    }
    const cases = [
      { from: 1, to: 2, extension: "assets/legacy.gif", batch: false },
      { from: 1, to: 2, extension: { opaque: true }, batch: false },
      { from: 2, to: 1, extension: "assets/front.gif", batch: false },
      { from: 1, to: 2, extension: "assets/legacy.gif", batch: true },
    ];
    for (const [index, item] of cases.entries()) {
      const projectRoot = join(root, `project-${index}`);
      const relativePath = "data/pokemon/media/cyndaquil.json";
      const mediaPath = join(projectRoot, relativePath);
      const media = {
        schemaVersion: item.from,
        speciesId: "cyndaquil",
        defaultFormId: "base",
        variants: { base: { frontStatic: "assets/front.png", frontAnimated: item.extension } },
        vendorExtension: { keep: true },
      };
      const before = Buffer.from(`${JSON.stringify(media)}\n`);
      await mkdir(join(projectRoot, "data/pokemon/media"), { recursive: true });
      await writeFile(join(projectRoot, "project.json"), JSON.stringify({
        name: "Pokemon media schema", version: "v8", maps: [], tilesets: [],
        pokemon: { ...canonicalPokemonConfig(), enabled: true },
      }));
      await writeFile(mediaPath, before);
      const workspace = await call("pokemap_workspace", { operation: "open", projectRoot });
      const validation = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
      const edited = {
        ...media,
        variants: { base: { ...media.variants.base, frontStatic: "assets/changed.png" } },
      };
      const parameters = {
        relativePath,
        beforeBytesBase64: before.toString("base64"),
        document: edited,
      };
      const request = (version: number, suffix: string): JsonRecord => ({
        projectHandle: workspace.projectHandle,
        request: {
          requestId: `media-schema-${index}-${suffix}`,
          actionId: item.batch ? "pokemon.documents.write" : "pokemon.media.write",
          actionVersion: 1,
          workspaceHandle: workspace.workspaceHandle,
          expectedRevision: validation.snapshotRevision,
          idempotencyKey: `media-schema-${index}-${suffix}`,
          parameters: item.batch
            ? { documents: [{ actionId: "pokemon.media.write", parameters: { ...parameters, document: { ...edited, schemaVersion: version } } }] }
            : { ...parameters, document: { ...edited, schemaVersion: version } },
        },
      });
      const unchangedPlan = await call("pokemap_plan", request(item.from, "same"));
      assert.equal(unchangedPlan.applicable, true);
      const error = await call("pokemap_plan", request(item.to, "changed"), true);
      assert.equal(error.domainCode, "worker.request_invalid");
      assert.deepEqual(await readFile(mediaPath), before);
      if (index === 0) {
        const forged = Buffer.from(JSON.stringify({ ...media, schemaVersion: 2 })).toString("base64");
        for (const [suffix, preimage] of [["missing", null], ["forged", forged]] as const) {
          const planned = await call("pokemap_plan", {
            projectHandle: workspace.projectHandle,
            request: {
              requestId: `media-schema-${suffix}`,
              actionId: "pokemon.media.write",
              actionVersion: 1,
              workspaceHandle: workspace.workspaceHandle,
              expectedRevision: validation.snapshotRevision,
              idempotencyKey: `media-schema-${suffix}`,
              parameters: {
                relativePath,
                document: { ...edited, schemaVersion: 2 },
                ...(preimage === null ? {} : { beforeBytesBase64: preimage }),
              },
            },
          });
          const applyError = await call("pokemap_apply", {
            operation: "apply",
            projectHandle: workspace.projectHandle,
            planId: planned.planId,
            operationId: `media-schema-${suffix}`,
          }, true);
          assert.equal(applyError.domainCode, "revision.conflict");
          assert.deepEqual(await readFile(mediaPath), before);
        }
        const applied = await call("pokemap_apply", {
          operation: "apply",
          projectHandle: workspace.projectHandle,
          planId: unchangedPlan.planId,
          operationId: "media-schema-same",
        });
        assert.equal(record(applied.receipt).status, "applied");
        const persisted = record(JSON.parse(await readFile(mediaPath, "utf8")));
        assert.equal(persisted.schemaVersion, 1);
        assert.deepEqual(persisted.vendorExtension, { keep: true });
        const base = record(record(persisted.variants).base);
        assert.equal(base.frontStatic, "assets/changed.png");
        assert.equal(base.frontAnimated, "assets/legacy.gif");
      }
      await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
    }
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

test("MCP explicitly migrates unchanged legacy media and can undo it", { timeout: 120_000 }, async () => {
  const qaRoot = process.env.AVELUNE_QA_ROOT ?? (process.platform === "darwin"
    ? join(homedir(), "Library/Caches/AveluneQA")
    : tmpdir());
  await mkdir(qaRoot, { recursive: true });
  const root = await mkdtemp(join(qaRoot, "pokemon-media-migration-mcp-"));
  const entry = resolve(process.env.POKEMAP_TEST_MCP_ENTRY ?? "dist/src/index.js");
  const args = [entry, "--root", root, "--authoring-timeout-ms", "60000"];
  if (process.env.POKEMAP_TEST_AUTHORING_PACKAGE) {
    args.push("--authoring-package", process.env.POKEMAP_TEST_AUTHORING_PACKAGE,
      "--repository-root", resolve(process.cwd(), "../.."));
  }
  const client = new Client({ name: "pokemon-media-migration-test", version: "1.0.0" });
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: "pipe" });
  async function call(name: string, input: JsonRecord = {}): Promise<JsonRecord> {
    const result = await client.callTool({ name, arguments: input });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, true, JSON.stringify(envelope));
    return record(envelope.data);
  }
  try {
    const relativePath = "data/pokemon/media/cyndaquil.json";
    const mediaPath = join(root, relativePath);
    const media = {
      schemaVersion: 1,
      speciesId: "cyndaquil",
      defaultFormId: "base",
      variants: { base: { frontStatic: "assets/front.png", vendorField: { value: 7 } } },
      vendorExtension: { keep: true },
    };
    const before = Buffer.from(`${JSON.stringify(media)}\n`);
    const authoringRoot = resolve("../../packages/map_authoring");
    await promisify(execFile)(process.env.POKEMAP_TEST_DART ?? "dart", [
      `--packages=${join(authoringRoot, ".dart_tool/package_config.json")}`,
      join(authoringRoot, "test/support/create_working_catalog_fixture.dart"), root,
    ], { timeout: 60_000 });
    await mkdir(join(root, "data/pokemon/media"), { recursive: true });
    await writeFile(mediaPath, before);
    await client.connect(transport);
    const description = await call("pokemap_describe", {
      domain: "battle", view: "full", actionIds: ["pokemon.media.write"],
    });
    const action = (description.mutationActions as JsonRecord[])[0];
    assert.ok(action);
    assert.equal(record(record(action.extensions).schemaMigration).parameter, "migrateSchema");
    const workspace = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    await call("pokemap_workshop", { operation: "prepare", projectHandle: workspace.projectHandle });
    const migrationScope = await call("pokemap_workshop", {
      operation: "read", projectHandle: workspace.projectHandle, actionId: "pokemon.media.write",
      parameters: { relativePath, document: media },
    });
    const forged = { ...media, vendorExtension: { keep: false } };
    const forgedPlan = await call("pokemap_plan", {
      projectHandle: workspace.projectHandle,
      request: {
        requestId: "forged-migration", actionId: "pokemon.media.write", actionVersion: 1,
        workspaceHandle: workspace.workspaceHandle, expectedRevision: migrationScope.snapshotRevision,
        extensions: migrationScope.planExtensions,
        idempotencyKey: "forged-migration", parameters: {
          relativePath, beforeBytesBase64: Buffer.from(JSON.stringify(forged)).toString("base64"),
          document: { ...forged, schemaVersion: 2 }, migrateSchema: true,
        },
      },
    });
    const forgedResult = await client.callTool({ name: "pokemap_apply", arguments: {
      operation: "apply", projectHandle: workspace.projectHandle,
      planId: forgedPlan.planId, operationId: "forged-migration",
    } });
    const forgedEnvelope = record(forgedResult.structuredContent);
    assert.equal(forgedEnvelope.ok, false);
    assert.equal(record(forgedEnvelope.error).domainCode, "revision.conflict");
    assert.deepEqual(await readFile(mediaPath), before);
    const planned = await call("pokemap_plan", {
      projectHandle: workspace.projectHandle,
      request: {
        requestId: "migrate-media", actionId: "pokemon.media.write", actionVersion: 1,
        workspaceHandle: workspace.workspaceHandle, expectedRevision: migrationScope.snapshotRevision,
        extensions: migrationScope.planExtensions,
        idempotencyKey: "migrate-media", parameters: {
          relativePath, beforeBytesBase64: before.toString("base64"),
          document: { ...media, schemaVersion: 2 }, migrateSchema: true,
        },
      },
    });
    const applied = await call("pokemap_apply", {
      operation: "apply", projectHandle: workspace.projectHandle,
      planId: planned.planId, operationId: "migrate-media",
    });
    assert.deepEqual(JSON.parse(await readFile(mediaPath, "utf8")), { ...media, schemaVersion: 2 });
    const migratedBytes = await readFile(mediaPath);
    const gifBytes = Buffer.from("R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==", "base64");
    const gifInput = join(root, "source.gif");
    const gifPath = "assets/pokemon/cyndaquil/front.gif";
    await writeFile(gifInput, gifBytes);
    const gifArtifact = await call("pokemap_artifact_stage", {
      sourcePath: gifInput, declaredMediaType: "image/gif",
    });
    const assetRevision = await call("pokemap_validate", { projectHandle: workspace.projectHandle });
    const assetPlan = await call("pokemap_plan", {
      projectHandle: workspace.projectHandle,
      request: {
        requestId: "import-gif", actionId: "asset.import", actionVersion: 1,
        workspaceHandle: workspace.workspaceHandle, expectedRevision: assetRevision.snapshotRevision,
        idempotencyKey: "import-gif", parameters: {
          artifactHandle: gifArtifact.artifactHandle, assetId: "cyndaquil-front-gif",
          logicalPath: gifPath, tags: [], usages: [],
        },
      },
    });
    const imported = await call("pokemap_apply", {
      operation: "apply", projectHandle: workspace.projectHandle,
      planId: assetPlan.planId, operationId: "import-gif",
    });
    assert.deepEqual(await readFile(join(root, gifPath)), gifBytes);
    const linked = {
      ...media, schemaVersion: 2,
      variants: { base: { ...media.variants.base, frontAnimated: gifPath } },
    };
    const linkRevision = await call("pokemap_workshop", {
      operation: "read", projectHandle: workspace.projectHandle, actionId: "pokemon.media.write",
      parameters: { relativePath, document: linked },
    });
    const linkPlan = await call("pokemap_plan", {
      projectHandle: workspace.projectHandle,
      request: {
        requestId: "link-gif", actionId: "pokemon.media.write", actionVersion: 1,
        workspaceHandle: workspace.workspaceHandle, expectedRevision: linkRevision.snapshotRevision,
        extensions: linkRevision.planExtensions,
        idempotencyKey: "link-gif", parameters: {
          relativePath, beforeBytesBase64: migratedBytes.toString("base64"), document: linked,
        },
      },
    });
    const linkedResult = await call("pokemap_apply", {
      operation: "apply", projectHandle: workspace.projectHandle,
      planId: linkPlan.planId, operationId: "link-gif",
    });
    assert.equal(record(record(record(JSON.parse(await readFile(mediaPath, "utf8"))).variants).base).frontAnimated, gifPath);
    await call("pokemap_history", {
      operation: "undo", projectHandle: workspace.projectHandle,
      entryId: record(linkedResult.receipt).receiptId, idempotencyKey: "undo-link-gif",
    });
    await call("pokemap_history", {
      operation: "undo", projectHandle: workspace.projectHandle,
      entryId: record(imported.receipt).receiptId, idempotencyKey: "undo-import-gif",
    });
    await call("pokemap_history", {
      operation: "undo", projectHandle: workspace.projectHandle,
      entryId: record(applied.receipt).receiptId, idempotencyKey: "undo-migration",
    });
    assert.deepEqual(await readFile(mediaPath), before);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: workspace.workspaceHandle });
  } finally {
    await client.close();
    await rm(root, { recursive: true, force: true });
  }
});

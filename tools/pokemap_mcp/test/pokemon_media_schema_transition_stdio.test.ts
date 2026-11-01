import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { homedir, tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";

import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";

import type { JsonRecord } from "../src/authoring_client.js";
import { canonicalPokemonConfig } from "./pokemon_fixture.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

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

import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { execFile } from "node:child_process";
import { mkdir, mkdtemp, readFile, rm, stat, writeFile } from "node:fs/promises";
import { join, resolve } from "node:path";
import { test } from "node:test";
import { promisify } from "node:util";

import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import type { JsonRecord } from "../src/authoring_client.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

test("MCP imports a PNG without replacing existing Pokémon media", { timeout: 120_000 }, async () => {
  const qaRoot = process.env.AVELUNE_QA_ROOT;
  assert.ok(qaRoot);
  const root = await mkdtemp(join(qaRoot, "pokemon-png-mcp-"));
  const transport = new StdioClientTransport({
    command: process.execPath,
    args: [resolve("dist/src/index.js"), "--root", root, "--authoring-timeout-ms", "60000"],
    cwd: process.cwd(), stderr: "pipe",
  });
  const client = new Client({ name: "pokemon-png-test", version: "1.0.0" });
  async function call(name: string, input: JsonRecord = {}): Promise<JsonRecord> {
    const response = await client.callTool({ name, arguments: input });
    const envelope = record(response.structuredContent);
    assert.equal(envelope.ok, true, JSON.stringify(envelope));
    return record(envelope.data);
  }
  try {
    const authoringPackage = resolve("../../packages/map_authoring");
    await promisify(execFile)(process.env.POKEMAP_TEST_DART ?? "dart", [
      `--packages=${join(authoringPackage, ".dart_tool/package_config.json")}`,
      join(authoringPackage, "test/support/create_pokemon_bulk_fixture.dart"), root,
    ], { timeout: 60_000 });
    const relativePath = "data/pokemon/media/pikachu.json";
    const mediaPath = join(root, relativePath);
    const sourcePath = join(root, "source.png");
    const png = await readFile(resolve("../../packages/map_editor/assets/branding/pokemap_event_builder_mark.png"));
    const imagePath = `assets/pokemon/images/${createHash("sha256").update(png).digest("hex")}.png`;
    const media = { schemaVersion: 1, speciesId: "pikachu", defaultFormId: "base",
      variants: { base: { frontStatic: "assets/front.png" } }, vendorExtension: { keep: true } };
    const before = Buffer.from(JSON.stringify(media));
    await mkdir(join(root, "data/pokemon/media"), { recursive: true });
    await writeFile(mediaPath, before);
    await writeFile(sourcePath, png);
    await client.connect(transport);
    const describe = await call("pokemap_describe");
    const action = (describe.mutationActions as JsonRecord[]).find((entry) => entry.id === "pokemon.media.write");
    assert.equal(record(record(action).extensions).pokemonPngImport instanceof Object, true);
    const roles = record(record(record(action).extensions).pokemonPngImport).roles as string[];
    assert.ok(roles.includes("overworldShiny"));
    const batchAction = (describe.mutationActions as JsonRecord[]).find((entry) => entry.id === "pokemon.media.import");
    assert.ok((record(record(batchAction).extensions).roles as string[]).includes("overworld"));
    const opened = await call("pokemap_workspace", { operation: "open", projectRoot: root });
    await call("pokemap_workshop", { operation: "prepare", projectHandle: opened.projectHandle });
    const staged = await call("pokemap_artifact_stage", { sourcePath, declaredMediaType: "image/png" });
    const parameters = { relativePath, beforeBytesBase64: before.toString("base64"),
      document: { ...media, variants: { base: { ...media.variants.base, icon: imagePath,
        overworld: imagePath, overworldShiny: imagePath } } } };
    const scope = await call("pokemap_workshop", { operation: "read", projectHandle: opened.projectHandle,
      actionId: "pokemon.media.write", parameters });
    const plan = await call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
      requestId: "png-mcp", actionId: "pokemon.media.write", actionVersion: 1,
      workspaceHandle: opened.workspaceHandle, expectedRevision: scope.snapshotRevision,
      idempotencyKey: "png-mcp", parameters, dryRun: false,
      extensions: { ...record(scope.planExtensions), pokemonPngArtifacts: { icon: staged.artifactHandle,
        overworld: staged.artifactHandle, overworldShiny: staged.artifactHandle } },
    } });
    await assert.rejects(stat(join(root, imagePath)));
    const applied = await call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle,
      planId: plan.planId, operationId: "png-mcp" });
    assert.deepEqual(await readFile(join(root, imagePath)), png);
    const saved = record(JSON.parse(await readFile(mediaPath, "utf8")));
    assert.deepEqual(saved.vendorExtension, { keep: true });
    assert.equal(record(record(saved.variants).base).frontStatic, "assets/front.png");
    assert.equal(record(record(saved.variants).base).icon, imagePath);
    assert.equal(record(record(saved.variants).base).overworld, imagePath);
    assert.equal(record(record(saved.variants).base).overworldShiny, imagePath);
    const receiptId = record(applied.receipt).receiptId;
    await call("pokemap_history", { operation: "undo", projectHandle: opened.projectHandle,
      entryId: receiptId, idempotencyKey: "undo-png" });
    await call("pokemap_history", { operation: "redo", projectHandle: opened.projectHandle,
      entryId: receiptId, idempotencyKey: "redo-png" });
    assert.deepEqual(await readFile(join(root, imagePath)), png);
    const validation = await call("pokemap_validate", { projectHandle: opened.projectHandle });
    const bulkPlan = await call("pokemap_plan", { projectHandle: opened.projectHandle, request: {
      requestId: "overworld-mcp", actionId: "pokemon.media.import", actionVersion: 1,
      workspaceHandle: opened.workspaceHandle, expectedRevision: validation.snapshotRevision,
      idempotencyKey: "overworld-mcp", parameters: { entries: [
        { speciesId: "riolu", formId: "base", role: "overworld", artifactHandle: staged.artifactHandle },
        { speciesId: "riolu", formId: "base", role: "overworldShiny", artifactHandle: staged.artifactHandle },
      ] },
    } });
    await call("pokemap_apply", { operation: "apply", projectHandle: opened.projectHandle,
      planId: bulkPlan.planId, operationId: "overworld-mcp" });
    const riolu = record(JSON.parse(await readFile(join(root, "data/pokemon/media/riolu.json"), "utf8")));
    const rioluBase = record(record(riolu.variants).base);
    assert.ok(String(rioluBase.overworld).includes("/overworld/"));
    assert.equal(rioluBase.overworldShiny, rioluBase.overworld);
    await call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});

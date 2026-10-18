import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { mkdir, mkdtemp, rm, symlink, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { assertRegularRecipeTree, assertStagedRecipeArtifact, captureRecipeArtifact, captureRecipeBindings, parseContentRecipe, resolveRecipeBindings, verifyRecipeFile } from "../src/content_recipe.js";

const recipe = { schemaVersion: 1, id: "independent", validation: "authoring", actions: [{ actionId: "scene.upsert", parameters: { scene: { id: "intro" } } }] };

test("recipe schema rejects ambiguous or executable content before authoring", () => {
  assert.equal(parseContentRecipe(recipe).id, "independent");
  for (const value of [[], { ...recipe, schemaVersion: 0 }, { ...recipe, validation: null }, { ...recipe, actions: [] }, { ...recipe, script: "process.exit()" }, { ...recipe, actions: [{ ...recipe.actions[0], capture: { result: "/receipt/id" } }] }]) assert.throws(() => parseContentRecipe(value));
  for (const path of ["../outside", "/outside", "a//b", "a/../b", "a\\b", "C:outside"]) assert.throws(() => parseContentRecipe({ ...recipe, requiredFiles: { [path]: "a".repeat(64) } }));
});

test("only explicit preview captures and declared bindings enter canonical parameters", () => {
  const bindings = new Map<string, unknown>([["image", "artifact-1"]]);
  captureRecipeBindings({ preview: { characterId: "authored-character" } }, { character: "/preview/characterId" }, bindings);
  assert.deepEqual(resolveRecipeBindings({ characterId: { $binding: "character" }, images: [{ $binding: "image" }] }, bindings), { characterId: "authored-character", images: ["artifact-1"] });
  assert.throws(() => captureRecipeBindings({ preview: {} }, { other: "/preview/missing" }, bindings));
  assert.throws(() => captureRecipeBindings({ preview: { characterId: "other" } }, { character: "/preview/characterId" }, bindings));
  assert.throws(() => resolveRecipeBindings({ $binding: "missing" }, bindings));
  assert.throws(() => resolveRecipeBindings({ $binding: "image", extra: true }, bindings));
});

test("declared inputs verify bytes and refuse symlinks in every path component", async () => {
  const root = await mkdtemp(join(tmpdir(), "recipe-inputs-"));
  try {
    await mkdir(join(root, "inputs"));
    await mkdir(join(root, "outside"));
    await writeFile(join(root, "outside", "asset.png"), "approved");
    await symlink(join(root, "outside"), join(root, "inputs", "linked"));
    await symlink(join(root, "outside", "asset.png"), join(root, "inputs", "file.png"));
    const sha = createHash("sha256").update("approved").digest("hex");
    assert.equal(await verifyRecipeFile(join(root, "outside"), "asset.png", sha), join(root, "outside", "asset.png").replace(/^\/var\//, "/private/var/"));
    await assert.rejects(verifyRecipeFile(join(root, "outside"), "asset.png", "0".repeat(64)));
    await assert.rejects(verifyRecipeFile(join(root, "inputs"), "linked/asset.png", sha));
    await assert.rejects(verifyRecipeFile(join(root, "inputs"), "file.png", sha));
    await assert.rejects(assertRegularRecipeTree(join(root, "inputs")));
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("a source replaced before staging cannot inherit its approved provenance", async () => {
  const root = await mkdtemp(join(tmpdir(), "recipe-race-"));
  try {
    await writeFile(join(root, "source.json"), "approved");
    const sha256 = createHash("sha256").update("approved").digest("hex");
    const expected = await captureRecipeArtifact(root, "source.json", sha256);
    await writeFile(join(root, "source.json"), "replaced");
    const changed = await captureRecipeArtifact(root, "source.json", createHash("sha256").update("replaced").digest("hex"));
    assert.throws(() => assertStagedRecipeArtifact(changed, expected), /Staged artifact differs/);
    assertStagedRecipeArtifact(expected, expected);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

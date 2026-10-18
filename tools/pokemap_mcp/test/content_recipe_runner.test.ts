import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { execFile } from "node:child_process";
import { mkdir, mkdtemp, readFile, rm, stat, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { promisify } from "node:util";
import test from "node:test";
import { canonicalPokemonConfig } from "./pokemon_fixture.js";

const execute = promisify(execFile);

for (const id of ["alpha", "beta"]) {
  test(`a canonical recipe publishes the full ${id} project and preserves its source`, { timeout: 120_000 }, async () => {
    const root = await mkdtemp(join(tmpdir(), "content-recipe-"));
    try {
      const project = join(root, id);
      await mkdir(join(project, "dialogues"), { recursive: true });
      const maps = ["orchard", "observatory"].map(mapId => ({ id: mapId, name: mapId, relativePath: `maps/${mapId}.json` }));
      await mkdir(join(project, "maps"));
      for (const map of maps) await writeFile(join(project, map.relativePath), JSON.stringify({ version: "v8", id: map.id, name: map.name, size: { width: 2, height: 2 }, layers: [{ runtimeType: "object", id: "base", name: "Base", objects: [] }, { runtimeType: "object", id: "moss-crown", name: "Arbitrary identity", objects: [] }] }));
      const source = JSON.stringify({ name: id, version: "v8", maps, tilesets: [], pokemon: canonicalPokemonConfig() });
      await writeFile(join(project, "project.json"), source);
      const dialogue = `title: Intro\n---\n${id}: Authored content.\n===\n`;
      await writeFile(join(project, "dialogues", `${id}.yarn`), dialogue);
      const media = join(root, "media");
      await mkdir(media);
      const provenance = JSON.stringify({ id, source: "explicit recipe input" });
      await writeFile(join(media, "source.json"), provenance);
      const artifact = { input: "media", path: "source.json", sha256: createHash("sha256").update(provenance).digest("hex"), mediaType: "application/json" };
      const exportProfile = { schemaVersion: 1, gameId: `games.tests.${id}`, gameVersion: "0.1.0", title: id, author: { name: "Fixture" }, locales: { default: "fr", supported: ["fr"] }, requiredCapabilities: [], branding: {}, legal: {} };
      const actions = join(root, "actions.json");
      const fact = { id: `fact_${id}`, label: id };
      const choose = { resource: { kind: "fact", id: fact.id }, matches: fact, present: { actionId: "fact.update", parameters: { fact } }, absent: { actionId: "fact.create", parameters: { fact } } };
      await writeFile(actions, JSON.stringify({schemaVersion: 1, id, validation: "authoring", exportProfile, artifacts: { source: artifact }, actions: [...maps.map(map => ({ actionId: "map.apply_operations", parameters: { mapId: map.id, operations: [{ kind: "layer.reorder_by_id", layerId: "moss-crown", newIndex: 0 }] } })), choose, choose, { actionId: "asset.import", parameters: { assetId: `source_${id}`, logicalPath: `assets/provenance/${id}.json`, artifactHandle: { $binding: "source" } } }, { actionId: "validation.runtime_smoke_profile.configure", parameters: { profile: { id, version: 1, requiredSuiteIds: [`${id}-start`] } } }]}));
      const output = join(root, "output");
      await execute(process.execPath, ["--import", "tsx", "src/authoring_sequence_runner.ts", "--project-root", project, "--server", resolve("dist/src/index.js"), "--actions", actions, "--project-out", output, "--input", `media=${media}`], { cwd: process.cwd(), timeout: 100_000 });
      assert.ok((await stat(output)).isDirectory());
      for (const map of maps) {
        assert.deepEqual(JSON.parse(await readFile(join(output, map.relativePath), "utf8")).layers.map((layer: { id: string }) => layer.id), ["moss-crown", "base"]);
        assert.deepEqual(JSON.parse(await readFile(join(project, map.relativePath), "utf8")).layers.map((layer: { id: string }) => layer.id), ["base", "moss-crown"]);
      }
      assert.equal(await readFile(join(output, "dialogues", `${id}.yarn`), "utf8"), dialogue);
      const authored = JSON.parse(await readFile(join(output, "project.json"), "utf8"));
      assert.equal(authored.runtimeSmokeProfile.id, id);
      assert.equal(authored.facts.length, 1);
      assert.equal(authored.facts[0].id, fact.id);
      assert.equal(await readFile(join(output, "assets/provenance", `${id}.json`), "utf8"), provenance);
      assert.equal(JSON.parse(await readFile(join(output, ".pokemap/export-profile-v1.json"), "utf8")).gameId, exportProfile.gameId);
      assert.equal(await readFile(join(project, "project.json"), "utf8"), source);
    } finally {
      await rm(root, { recursive: true, force: true });
    }
  });
}

test("an invalid action never publishes a partial project or changes its source", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "content-recipe-failure-"));
  try {
    const project = join(root, "source");
    await mkdir(project);
    const source = JSON.stringify({ name: "Independent", version: "v8", maps: [], tilesets: [], pokemon: canonicalPokemonConfig() });
    await writeFile(join(project, "project.json"), source);
    const actions = join(root, "actions.json");
    await writeFile(actions, JSON.stringify({schemaVersion: 1, id: "invalid", validation: "authoring", actions: [{ actionId: "validation.runtime_smoke_profile.configure", parameters: { profile: { id: "valid", version: 1, requiredSuiteIds: ["start"] } } }, { actionId: "validation.runtime_smoke_profile.configure", parameters: { profile: { id: "invalid", version: 0, requiredSuiteIds: ["start"] } } }]}));
    const output = join(root, "output");
    await assert.rejects(execute(process.execPath, ["--import", "tsx", "src/authoring_sequence_runner.ts", "--project-root", project, "--server", resolve("dist/src/index.js"), "--actions", actions, "--project-out", output], { cwd: process.cwd(), timeout: 100_000 }));
    await assert.rejects(stat(output), { code: "ENOENT" });
    assert.equal(await readFile(join(project, "project.json"), "utf8"), source);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

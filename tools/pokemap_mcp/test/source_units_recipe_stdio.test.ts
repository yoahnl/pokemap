import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { promisify } from "node:util";
import test from "node:test";
import { canonicalPokemonConfig } from "./pokemon_fixture.js";

const execute = promisify(execFile);

test("two explicit source unit recipes import generated GLBs through canonical MCP", { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "source-units-mcp-"));
  try {
    const generated = join(root, "generated");
    await execute("python3", ["-B", "-c", `
from pathlib import Path
import json,sys
from test_source_units import dataset,recipe
from extract_units import build_recipe
root=Path(sys.argv[1])
first=dataset(root/'bronze','bronze','copper')
second=dataset(root/'textile','textile','velvet',8)
build_recipe(recipe([first,second],['copper','velvet']),{'bronze':root/'bronze','textile':root/'textile'},root/'generated')
`, root], { cwd: resolve("../../tools/source_units"), timeout: 10_000 });
    const units = JSON.parse(await readFile(join(generated, "manifest.json"), "utf8")) as {
      models: { id: string; file: string; sha256: string }[];
    };
    assert.equal(units.models.length, 2);
    for (const model of units.models) {
      const project = join(root, `${model.id}-source`);
      await mkdir(project);
      const manifest = JSON.stringify({ name: model.id, version: "v9", maps: [], tilesets: [],
        settings: { dimension: "threeD", spatialCamera: { mode: "fixed", pitchDegrees: 48.7,
          yawDegrees: 0, fieldOfViewDegrees: 16.2, distance: 42 } }, pokemon: canonicalPokemonConfig() });
      await writeFile(join(project, "project.json"), manifest);
      const actions = join(root, `${model.id}-actions.json`);
      await writeFile(actions, JSON.stringify({ schemaVersion: 1, id: model.id, validation: "authoring",
        artifacts: { model: { input: "generated", path: model.file, sha256: model.sha256, mediaType: "model/gltf-binary" } },
        requiredFiles: {}, requirements: [], actions: [{ actionId: "model3d.import",
          parameters: { modelId: model.id, name: model.id, artifactHandle: { $binding: "model" } } }] }));
      const output = join(root, `${model.id}-output`);
      await execute(process.execPath, ["--import", "tsx", "src/authoring_sequence_runner.ts",
        "--project-root", project, "--server", resolve("dist/src/index.js"), "--actions", actions,
        "--project-out", output, "--input", `generated=${generated}`], { cwd: process.cwd(), timeout: 50_000 });
      const authored = JSON.parse(await readFile(join(output, "project.json"), "utf8"));
      assert.equal(authored.models3d.length, 1);
      assert.equal(authored.models3d[0].id, model.id);
      assert.equal(await readFile(join(project, "project.json"), "utf8"), manifest);
    }
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { promisify } from "node:util";
import test from "node:test";
import { canonicalPokemonConfig } from "./pokemon_fixture.js";

const execute = promisify(execFile);

test("two source geometry recipes cross canonical MCP without game identities", { timeout: 150_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "source-geometry-recipe-"));
  try {
    for (const id of ["aurora", "clockwork"]) {
      const generated = join(root, id);
      await execute("python3", ["-c", `
from pathlib import Path
from hashlib import sha256
import sys, zipfile
from test_source_policy import profile
from test_source_asset_conversion import source, texture
from build_cities import build_city
root=Path(sys.argv[1]);root.mkdir()
data=source().replace(b'id="node"',b'id="ground-custom"').replace(b'0 0 0 16 0 0 16 16 0 0 16 0',b'0 0 0 16 0 0 16 0 16 0 0 16')
source_root=root/'source';source_root.mkdir()
archive=source_root/'input.zip'
with zipfile.ZipFile(archive,'w') as target:
 target.writestr('scene.dae',data);target.writestr('art.png',texture())
policy=profile();policy['ground']['floorRules'][0]['selector']['exact']=['material'];policy['output']['namespace']=sys.argv[2]
record={'id':sys.argv[2],'name':'Independent','local_path':'input.zip','sha256':sha256(archive.read_bytes()).hexdigest(),'page_url':'https://example.invalid/source'}
build_city({'id':'garden','name':'Garden','sourceId':sys.argv[2],'sourcePolicy':policy,'groupId':'independent-group'},source_root,record,root/'generated')
`, generated, id], { cwd: resolve("../../tools/source_geometry"), timeout: 10_000 });
      const project = join(root, `${id}-source`);
      await mkdir(project);
      const manifest = JSON.stringify({ name: id, version: "v9", maps: [], tilesets: [],
        settings: { dimension: "threeD", spatialCamera: { mode: "fixed", pitchDegrees: 48.7,
          yawDegrees: 0, fieldOfViewDegrees: 16.2, distance: 42 } },
        groups: [{ id: "independent-group", name: "Independent", type: "special" }],
        pokemon: canonicalPokemonConfig() });
      await writeFile(join(project, "project.json"), manifest);
      const output = join(root, `${id}-output`);
      await execute(process.execPath, ["--import", "tsx", "src/authoring_sequence_runner.ts",
        "--project-root", project, "--server", resolve("dist/src/index.js"),
        "--actions", join(generated, "generated/actions.json"), "--project-out", output,
        "--input", `generated=${join(generated, "generated")}`], { cwd: process.cwd(), timeout: 65_000 });
      const authored = JSON.parse(await readFile(join(output, "project.json"), "utf8"));
      assert.equal(authored.maps[0].id, `${id}-garden`);
      const map = JSON.parse(await readFile(join(output, authored.maps[0].relativePath), "utf8"));
      assert.equal(map.id, `${id}-garden`);
      assert.ok(map.spatialScene.navigation);
      assert.equal(await readFile(join(project, "project.json"), "utf8"), manifest);
    }
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

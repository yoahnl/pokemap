import contextlib
import io
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

from PIL import Image

from asset_contract import create_contract, validate_contract
from asset_contract import main as contract_main
from asset_resolver import index_assets, resolve_missing_assets
from asset_resolver import main as resolver_main
from blueprint_tool import create_blueprint, validate_blueprint
from blueprint_tool import main as blueprint_main
from reference_analyzer import analyze_reference


class GenericProfilesTest(unittest.TestCase):
    def test_distinct_grids_and_visual_sources_use_the_same_pipeline(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for cell_size, source in [(16, "gba"), (48, "original")]:
                with self.subTest(cell_size=cell_size):
                    assets = root / source
                    assets.mkdir()
                    image = Image.new("RGBA", (cell_size * 2, cell_size), (80, 120, 60, 255))
                    image.putpixel((0, 0), (0, 0, 0, 0))
                    image.save(assets / "wood_bridge.png")
                    style = {"id": source, "allowedProvenance": [source, "custom"]}
                    blueprint = create_blueprint(
                        str(root / "reference.png"), source, source, 8, 8,
                        cell_size_px=cell_size, style_profile=style,
                    )
                    contract = create_contract(
                        "wood-bridge", 2, 1, str(assets / "wood_bridge.png"),
                        "required", [source], cell_size_px=cell_size,
                        style_profile=style,
                    )
                    blueprint["missingAssets"].append(contract)
                    self.assertEqual(validate_blueprint(blueprint), [])
                    self.assertEqual(validate_contract(contract)[0], [])
                    catalog = index_assets(
                        [{"path": str(assets), "provenance": source}],
                        cell_size_px=cell_size, style_profile=style,
                    )
                    report = resolve_missing_assets(blueprint, catalog)
                    self.assertEqual(report["resolutions"][0]["decision"], "reuse")
                    self.assertEqual(report["resolutions"][0]["expectedCanvas"],
                                     {"widthPx": cell_size * 2, "heightPx": cell_size})
                    catalog["cellSizePx"] = 32
                    with self.assertRaises(ValueError):
                        resolve_missing_assets(blueprint, catalog)

    def test_source_eligibility_is_declared_by_profile(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            Image.new("RGBA", (16, 16), (0, 0, 0, 0)).save(root / "tree.png")
            catalog = index_assets(
                [{"path": str(root), "provenance": "undeclared"}],
                cell_size_px=16,
                style_profile={"id": "project-a", "allowedProvenance": ["approved"]},
            )
            self.assertFalse(catalog["assets"][0]["eligible"])

    def test_reference_analysis_uses_selected_grid(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            reference = root / "reference.png"
            Image.new("RGB", (32, 32), (80, 120, 60)).save(reference)
            blueprint, _ = analyze_reference(reference, "map-a", "Map A", {
                "schemaVersion": 1, "cellSizePx": 16,
                "styleProfile": {"id": "original", "allowedProvenance": ["original", "custom"]},
                "classes": [{"semantic": "grass", "family": "surface",
                             "seeds": [{"x": 0, "y": 0}]}],
            })
            self.assertEqual(blueprint["cellSizePx"], 16)
            self.assertEqual(blueprint["map"]["widthCells"], 2)
            self.assertEqual(blueprint["styleProfile"]["id"], "original")

    def test_invalid_style_profiles_and_grids_are_rejected(self):
        for cell_size in [0, True, 24, 1024]:
            with self.subTest(cell_size=cell_size), self.assertRaises(ValueError):
                create_blueprint("/reference.png", "map", "Map", 2, 2, cell_size_px=cell_size)
        for style in [None, {"id": "", "allowedProvenance": ["project"]},
                      {"id": "project", "allowedProvenance": []},
                      {"id": "project", "allowedProvenance": ["project", "project"]},
                      {"id": "project", "allowedProvenance": ["project"], "unknown": True}]:
            with self.subTest(style=style), self.assertRaises(ValueError):
                create_blueprint("/reference.png", "map", "Map", 2, 2, style_profile=style)

    def test_cli_roundtrip_uses_an_explicit_profile_and_grid(self):
        with tempfile.TemporaryDirectory() as directory, contextlib.redirect_stdout(io.StringIO()):
            root = Path(directory)
            assets = root / "assets"
            assets.mkdir()
            image = Image.new("RGBA", (32, 16), (80, 120, 60, 255))
            image.putpixel((0, 0), (0, 0, 0, 0))
            image.save(assets / "wood_bridge.png")
            style = {"id": "gba", "allowedProvenance": ["gba", "custom"]}
            profile_path = root / "style.json"
            profile_path.write_text(json.dumps(style))
            blueprint_path = root / "blueprint.json"
            self.assertEqual(blueprint_main([
                "init", "--output", str(blueprint_path), "--reference", "/reference.png",
                "--map-id", "map-a", "--width", "4", "--height", "4",
                "--cell-size", "16", "--style-profile", str(profile_path),
            ]), 0)
            contract_path = root / "contract.json"
            self.assertEqual(contract_main([
                "init", "--output", str(contract_path), "--asset-id", "wood-bridge",
                "--width-cells", "2", "--height-cells", "1", "--png", str(assets / "wood_bridge.png"),
                "--cell-size", "16", "--style-profile", str(profile_path), "--style-reference", "GBA",
            ]), 0)
            self.assertEqual(contract_main(["validate", str(contract_path)]), 0)
            blueprint = json.loads(blueprint_path.read_text())
            blueprint["missingAssets"].append(json.loads(contract_path.read_text()))
            blueprint_path.write_text(json.dumps(blueprint))
            catalog_path = root / "catalog.json"
            self.assertEqual(resolver_main([
                "index", "--root", str(assets) + "=gba", "--output", str(catalog_path),
                "--cell-size", "16", "--style-profile", str(profile_path),
            ]), 0)
            resolution_path = root / "resolution.json"
            self.assertEqual(resolver_main([
                "resolve", "--blueprint", str(blueprint_path), "--catalog", str(catalog_path),
                "--output", str(resolution_path),
            ]), 0)
            self.assertEqual(json.loads(resolution_path.read_text())["resolutions"][0]["decision"], "reuse")
            self.assertEqual(blueprint_main(["validate", str(blueprint_path)]), 0)

    def test_explicit_null_profile_is_refused_by_every_entrypoint(self):
        with tempfile.TemporaryDirectory() as directory, contextlib.redirect_stderr(io.StringIO()):
            root = Path(directory)
            profile = root / "style.json"
            profile.write_text("null")
            output = root / "output.json"
            calls = [
                (blueprint_main, ["init", "--output", str(output), "--reference", "/reference.png",
                                  "--map-id", "map-a", "--width", "4", "--height", "4"]),
                (contract_main, ["init", "--output", str(output), "--asset-id", "asset-a",
                                 "--width-cells", "1", "--height-cells", "1"]),
                (resolver_main, ["index", "--root", str(root) + "=project", "--output", str(output)]),
            ]
            for main, args in calls:
                with self.subTest(entrypoint=main.__module__):
                    self.assertEqual(main(args + ["--style-profile", str(profile)]), 2)
                    self.assertFalse(output.exists())
            reference = root / "reference.png"
            Image.new("RGB", (32, 32)).save(reference)
            with self.assertRaises(ValueError):
                analyze_reference(reference, "map-a", "Map A", {
                    "cellSizePx": 32, "styleProfile": None,
                    "classes": [{"semantic": "grass", "family": "surface", "seeds": [{"x": 0, "y": 0}]}],
                })

    def test_catalog_symlinks_and_null_profiles_are_refused(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            assets = root / "assets"
            assets.mkdir()
            Image.new("RGBA", (32, 32), (0, 0, 0, 0)).save(root / "outside.png")
            (assets / "linked.png").symlink_to(root / "outside.png")
            self.assertFalse(index_assets([{"path": str(assets), "provenance": "project"}])["assets"][0]["eligible"])
            blueprint = create_blueprint("/reference.png", "map", "Map", 2, 2)
            blueprint["styleProfile"] = None
            self.assertTrue(validate_blueprint(blueprint))
            contract = create_contract("asset", 1, 1, None, "optional", [])
            contract["styleProfile"] = None
            self.assertTrue(validate_contract(contract)[0])


class GenericLauncherTest(unittest.TestCase):
    launcher = Path(__file__).resolve().parents[3] / "scripts/start_pokemap_mcp"

    def test_project_selection_is_required_without_game_default(self):
        env = dict(os.environ)
        env.pop("POKEMAP_PROJECT_ROOT", None)
        result = subprocess.run(["zsh", str(self.launcher)], env=env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 64)
        self.assertIn("POKEMAP_PROJECT_ROOT", result.stderr)
        self.assertNotIn("le_train", result.stderr)

    def test_two_selected_projects_remain_narrow_and_explicit(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            repository = root / "engine"
            entry = repository / "tools/pokemap_mcp/dist/src/index.js"
            entry.parent.mkdir(parents=True)
            entry.write_text("")
            (repository / "packages/map_authoring").mkdir(parents=True)
            binaries = root / "bin"
            binaries.mkdir()
            node = binaries / "node"
            node.write_text('#!/bin/sh\nprintf "%s\\n" "$@"\n')
            node.chmod(0o755)
            for name in ["game-a", "game-b"]:
                project = root / name
                project.mkdir()
                (project / "project.json").write_text(json.dumps({"name": name}))
                env = {**os.environ, "POKEMAP_REPOSITORY_ROOT": str(repository),
                       "POKEMAP_PROJECT_ROOT": str(project), "POKEMAP_DART_EXECUTABLE": "/usr/bin/true",
                       "PATH": str(binaries) + os.pathsep + os.environ["PATH"]}
                result = subprocess.run(["zsh", str(self.launcher)], env=env, capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                args = result.stdout.splitlines()
                self.assertEqual(args[args.index("--root") + 1], str(project.resolve()))
                self.assertNotIn("le_train", result.stdout)
                self.assertNotIn(str(root.resolve()), [args[args.index("--root") + 1]])

    def test_relative_broad_and_symlink_manifest_roots_are_refused(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            selected = root / "project"
            selected.mkdir()
            (root / "outside.json").write_text("{}")
            (selected / "project.json").symlink_to(root / "outside.json")
            for project in ["relative", "/", str(selected)]:
                env = {**os.environ, "POKEMAP_PROJECT_ROOT": project,
                       "POKEMAP_REPOSITORY_ROOT": str(root), "POKEMAP_DART_EXECUTABLE": "/usr/bin/true"}
                result = subprocess.run(["zsh", str(self.launcher)], env=env, capture_output=True, text=True)
                self.assertEqual(result.returncode, 64, result.stderr)


if __name__ == "__main__":
    unittest.main()

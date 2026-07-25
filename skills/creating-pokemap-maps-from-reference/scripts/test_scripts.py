#!/usr/bin/env python3
"""Regression tests for the skill's destructive and evidence-producing tools."""

from __future__ import annotations

import hashlib
import json
import os
import struct
import subprocess
import sys
import tempfile
import unittest
import zlib
from pathlib import Path


SCRIPTS = Path(__file__).resolve().parent


def _png_chunk(kind: bytes, payload: bytes) -> bytes:
    return (
        struct.pack(">I", len(payload))
        + kind
        + payload
        + struct.pack(">I", zlib.crc32(kind + payload) & 0xFFFFFFFF)
    )


def _write_rgba_png(path: Path, rgba: tuple[int, int, int, int]) -> bytes:
    payload = (
        b"\x89PNG\r\n\x1a\n"
        + _png_chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 6, 0, 0, 0))
        + _png_chunk(b"IDAT", zlib.compress(bytes((0, *rgba))))
        + _png_chunk(b"IEND", b"")
    )
    path.write_bytes(payload)
    return payload


def _run(script: str, *args: str) -> subprocess.CompletedProcess[str]:
    environment = dict(os.environ)
    environment["PYTHONDONTWRITEBYTECODE"] = "1"
    return subprocess.run(
        [sys.executable, str(SCRIPTS / script), *args],
        check=False,
        capture_output=True,
        text=True,
        env=environment,
    )


class InventoryAssetsTest(unittest.TestCase):
    def test_strict_inventory_accepts_inspected_rgba_png_with_provenance(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            assets = root / "assets"
            assets.mkdir()
            image = assets / "sprite.png"
            _write_rgba_png(image, (10, 20, 30, 0))
            provenance = root / "provenance.json"
            provenance.write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "assets": {
                            "sprite.png": {
                                "source": "approved fixture",
                                "license": "test-only",
                                "status": "approved",
                            }
                        },
                    }
                ),
                encoding="utf-8",
            )
            output = root / "inventory.json"

            result = _run(
                "inventory_assets.py",
                "--root",
                str(assets),
                "--output",
                str(output),
                "--provenance",
                str(provenance),
                "--require-approved-provenance",
                "--strict",
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            entry = json.loads(output.read_text(encoding="utf-8"))["assets"][0]
            self.assertEqual(entry["alphaInspection"], "used")
            self.assertEqual(entry["provenance"]["status"], "approved")


class ReferenceBriefTest(unittest.TestCase):
    def test_force_never_overwrites_the_reference_image(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            reference = Path(temporary) / "reference.png"
            original = _write_rgba_png(reference, (1, 2, 3, 255))

            result = _run(
                "create_reference_brief.py",
                "--reference",
                str(reference),
                "--map-id",
                "map_test",
                "--output",
                str(reference),
                "--force",
            )

            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(reference.read_bytes(), original)

    def test_brief_requires_scale_topology_and_edge_independence_evidence(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            reference = root / "reference.png"
            output = root / "brief.md"
            _write_rgba_png(reference, (1, 2, 3, 255))

            result = _run(
                "create_reference_brief.py",
                "--reference",
                str(reference),
                "--map-id",
                "map_test",
                "--output",
                str(output),
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            brief = output.read_text(encoding="utf-8")
            self.assertIn("## Scale contract", brief)
            self.assertIn("## Functional topology", brief)
            self.assertIn("## Edge-independence proof", brief)
            self.assertIn("## Engine proof", brief)


class ValidateAuthoredMapTest(unittest.TestCase):
    def _fixture(
        self,
        root: Path,
        *,
        element_width: int = 2,
        element_height: int = 2,
        position: tuple[int, int] = (1, 1),
        collisions: list[bool] | None = None,
    ) -> tuple[Path, Path]:
        project = root / "project.json"
        map_file = root / "map.json"
        project.write_text(
            json.dumps(
                {
                    "settings": {
                        "tileWidth": 32,
                        "tileHeight": 32,
                        "displayScale": 2.0,
                    },
                    "tilesets": [{"id": "tileset_test"}],
                    "elements": [
                        {
                            "id": "element_test",
                            "name": "Test prop",
                            "tilesetId": "tileset_test",
                            "frames": [
                                {
                                    "source": {
                                        "x": 0,
                                        "y": 0,
                                        "width": element_width,
                                        "height": element_height,
                                    }
                                }
                            ],
                        }
                    ],
                }
            ),
            encoding="utf-8",
        )
        map_file.write_text(
            json.dumps(
                {
                    "id": "map_test",
                    "size": {"width": 4, "height": 4},
                    "tilesetId": "tileset_test",
                    "properties": {
                        "referenceRuntimeUnderlay": False,
                        "pokemapAuthored": True,
                    },
                    "layers": [
                        {
                            "runtimeType": "tile",
                            "id": "visual",
                            "tiles": [0] * 16,
                        },
                        {
                            "runtimeType": "collision",
                            "id": "collision",
                            "collisions": collisions or [False] * 16,
                        },
                    ],
                    "placedElements": [
                        {
                            "id": "placed_test",
                            "layerId": "visual",
                            "elementId": "element_test",
                            "pos": {"x": position[0], "y": position[1]},
                        }
                    ],
                }
            ),
            encoding="utf-8",
        )
        return project, map_file

    def test_rejects_a_full_canvas_element_used_as_a_map_shell(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            project, map_file = self._fixture(
                Path(temporary),
                element_width=4,
                element_height=4,
                position=(0, 0),
            )

            result = _run(
                "validate_authored_map.py",
                "--project",
                str(project),
                "--map",
                str(map_file),
                "--entry",
                "0,0",
                "--target",
                "3,3",
            )

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("full-canvas-composite", result.stdout)

    def test_accepts_modular_in_bounds_elements_and_connected_routes(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            project, map_file = self._fixture(Path(temporary))

            result = _run(
                "validate_authored_map.py",
                "--project",
                str(project),
                "--map",
                str(map_file),
                "--entry",
                "0,0",
                "--target",
                "3,3",
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("PASS", result.stdout)

    def test_rejects_out_of_bounds_elements_even_when_the_engine_clips_them(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            project, map_file = self._fixture(
                Path(temporary),
                element_width=2,
                element_height=2,
                position=(3, 3),
            )

            result = _run(
                "validate_authored_map.py",
                "--project",
                str(project),
                "--map",
                str(map_file),
                "--entry",
                "0,0",
            )

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("out-of-bounds-element", result.stdout)

    def test_rejects_an_unreachable_required_target(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            collisions = [False] * 16
            collisions[4:8] = [True] * 4
            project, map_file = self._fixture(
                Path(temporary),
                collisions=collisions,
            )

            result = _run(
                "validate_authored_map.py",
                "--project",
                str(project),
                "--map",
                str(map_file),
                "--entry",
                "0,0",
                "--target",
                "0,3",
            )

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("unreachable-target", result.stdout)


class AssetUsageApplyTest(unittest.TestCase):
    def _fixture(self, root: Path) -> tuple[Path, Path, Path]:
        assets = root / "assets"
        maps = root / "maps"
        assets.mkdir()
        maps.mkdir()
        (root / "project.json").write_text(
            json.dumps({"name": "fixture", "maps": [], "tilesets": []}),
            encoding="utf-8",
        )
        map_file = maps / "map.json"
        map_file.write_text("{}", encoding="utf-8")
        asset = assets / "candidate.png"
        _write_rgba_png(asset, (5, 6, 7, 255))
        return asset, map_file, root / "usage.json"

    def test_apply_refuses_asset_that_became_runtime_used_after_review(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            asset, map_file, manifest = self._fixture(root)
            dry_run = _run(
                "audit_project_asset_usage.py",
                "--project-root",
                str(root),
                "--dry-run",
                "--manifest",
                str(manifest),
            )
            self.assertEqual(dry_run.returncode, 0, dry_run.stderr)
            manifest_hash = json.loads(manifest.read_text(encoding="utf-8"))[
                "manifestSha256"
            ]
            map_file.write_text(
                json.dumps({"newReference": "assets/candidate.png"}),
                encoding="utf-8",
            )

            apply = _run(
                "audit_project_asset_usage.py",
                "--project-root",
                str(root),
                "--apply",
                "--manifest",
                str(manifest),
                "--expected-sha256",
                manifest_hash,
            )

            self.assertNotEqual(apply.returncode, 0)
            self.assertTrue(asset.exists())

    def test_dry_run_retains_provenance_metadata(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            self._fixture(root)
            provenance = root / "assets" / "provenance" / "family.json"
            provenance.parent.mkdir()
            provenance.write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "family": "fixture",
                        "source": "owner supplied",
                    }
                ),
                encoding="utf-8",
            )
            manifest = root / "provenance-usage.json"

            result = _run(
                "audit_project_asset_usage.py",
                "--project-root",
                str(root),
                "--dry-run",
                "--manifest",
                str(manifest),
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            document = json.loads(manifest.read_text(encoding="utf-8"))
            entry = next(
                item
                for item in document["files"]
                if item["path"] == "provenance/family.json"
            )
            self.assertEqual(entry["classification"], "reference-retained")

    def test_dry_run_classifies_plural_sources_directory_as_atlas_source(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            self._fixture(root)
            sources = root / "assets" / "sources"
            sources.mkdir()
            source = sources / "family.png"
            _write_rgba_png(source, (11, 22, 33, 255))
            (root / "assets" / "ATLAS_LAYOUTS.json").write_text(
                json.dumps(
                    {
                        "atlases": {
                            "fixture": {
                                "items": [{"file": "sources/family.png"}],
                            }
                        }
                    }
                ),
                encoding="utf-8",
            )
            manifest = root / "source-usage.json"

            result = _run(
                "audit_project_asset_usage.py",
                "--project-root",
                str(root),
                "--dry-run",
                "--manifest",
                str(manifest),
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            document = json.loads(manifest.read_text(encoding="utf-8"))
            entry = next(
                item
                for item in document["files"]
                if item["path"] == "sources/family.png"
            )
            self.assertEqual(entry["classification"], "atlas-source-used")

    def test_manifest_inside_scan_root_is_stable_and_applyable(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            asset, _, _ = self._fixture(root)
            evidence = root / "evidence"
            evidence.mkdir()
            manifest = evidence / "usage.json"
            arguments = (
                "--project-root",
                str(root),
                "--dry-run",
                "--manifest",
                str(manifest),
                "--reference-root",
                str(evidence),
            )

            first = _run("audit_project_asset_usage.py", *arguments)
            self.assertEqual(first.returncode, 0, first.stderr)
            first_bytes = manifest.read_bytes()
            document = json.loads(first_bytes)
            manifest_hash = document["manifestSha256"]

            second = _run("audit_project_asset_usage.py", *arguments, "--force")
            self.assertEqual(second.returncode, 0, second.stderr)
            self.assertEqual(manifest.read_bytes(), first_bytes)

            apply = _run(
                "audit_project_asset_usage.py",
                "--project-root",
                str(root),
                "--apply",
                "--manifest",
                str(manifest),
                "--expected-sha256",
                manifest_hash,
                "--reference-root",
                str(evidence),
            )

            self.assertEqual(apply.returncode, 0, apply.stderr)
            self.assertFalse(asset.exists())

    @unittest.skipUnless(hasattr(os, "symlink"), "symlinks unsupported")
    def test_dry_run_rejects_symlinked_assets(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            assets = root / "assets"
            assets.mkdir()
            (root / "maps").mkdir()
            (root / "project.json").write_text(
                json.dumps({"name": "fixture", "maps": [], "tilesets": []}),
                encoding="utf-8",
            )
            outside = root / "outside.png"
            _write_rgba_png(outside, (9, 8, 7, 255))
            (assets / "linked.png").symlink_to(outside)

            result = _run(
                "audit_project_asset_usage.py",
                "--project-root",
                str(root),
                "--dry-run",
                "--manifest",
                str(root / "usage.json"),
            )

            self.assertNotEqual(result.returncode, 0)
            self.assertTrue(outside.exists())

    @unittest.skipUnless(hasattr(os, "symlink"), "symlinks unsupported")
    def test_dry_run_rejects_a_symlinked_asset_root(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            real_assets = root / "real_assets"
            real_assets.mkdir()
            (root / "maps").mkdir()
            (root / "project.json").write_text(
                json.dumps({"name": "fixture", "maps": [], "tilesets": []}),
                encoding="utf-8",
            )
            _write_rgba_png(real_assets / "candidate.png", (2, 3, 4, 255))
            (root / "assets").symlink_to(real_assets, target_is_directory=True)

            result = _run(
                "audit_project_asset_usage.py",
                "--project-root",
                str(root),
                "--dry-run",
                "--manifest",
                str(root / "usage.json"),
            )

            self.assertNotEqual(result.returncode, 0)
            self.assertTrue((real_assets / "candidate.png").exists())

    def test_apply_requires_the_same_scan_root_content_fingerprint(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            asset, _, manifest = self._fixture(root)
            first = root / "first" / "shared"
            second = root / "second" / "shared"
            first.mkdir(parents=True)
            second.mkdir(parents=True)
            (first / "test.txt").write_text("first evidence", encoding="utf-8")
            (second / "test.txt").write_text("different evidence", encoding="utf-8")
            dry_run = _run(
                "audit_project_asset_usage.py",
                "--project-root",
                str(root),
                "--dry-run",
                "--manifest",
                str(manifest),
                "--test-root",
                str(first),
            )
            self.assertEqual(dry_run.returncode, 0, dry_run.stderr)
            manifest_hash = json.loads(manifest.read_text(encoding="utf-8"))[
                "manifestSha256"
            ]

            apply = _run(
                "audit_project_asset_usage.py",
                "--project-root",
                str(root),
                "--apply",
                "--manifest",
                str(manifest),
                "--expected-sha256",
                manifest_hash,
                "--test-root",
                str(second),
            )

            self.assertNotEqual(apply.returncode, 0)
            self.assertTrue(asset.exists())

    def test_manifest_hash_is_content_derived(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            _, _, manifest = self._fixture(root)
            result = _run(
                "audit_project_asset_usage.py",
                "--project-root",
                str(root),
                "--dry-run",
                "--manifest",
                str(manifest),
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            document = json.loads(manifest.read_text(encoding="utf-8"))
            expected = document.pop("manifestSha256")
            canonical = json.dumps(
                document, sort_keys=True, ensure_ascii=False, separators=(",", ":")
            ).encode("utf-8")
            self.assertEqual(hashlib.sha256(canonical).hexdigest(), expected)


if __name__ == "__main__":
    unittest.main()

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

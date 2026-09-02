#!/usr/bin/env python3
import contextlib
import io
import json
import tempfile
import unittest
from pathlib import Path

from PIL import Image

from asset_resolver import main as asset_main
from blueprint_quality import main as quality_main
from reference_analyzer import main as analyzer_main


class ReferenceBuilderCliTest(unittest.TestCase):
    def test_analyze_index_resolve_lint_and_compare_workflow(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            output = io.StringIO()
            root = Path(directory)
            reference = root / "reference.png"
            candidate = root / "candidate.png"
            Image.new("RGB", (64, 64), (45, 160, 70)).save(reference)
            Image.new("RGB", (64, 64), (45, 160, 70)).save(candidate)
            profile = root / "profile.json"
            profile.write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "cellSizePx": 32,
                        "classes": [
                            {
                                "semantic": "grass",
                                "name": "Grass",
                                "family": "surface",
                                "seeds": [{"x": 0, "y": 0}],
                            }
                        ],
                    }
                ),
                encoding="utf-8",
            )
            reference_blueprint = root / "reference-blueprint.json"
            reference_report = root / "reference-report.json"
            reference_overlay = root / "reference-overlay.png"
            candidate_blueprint = root / "candidate-blueprint.json"
            candidate_report = root / "candidate-report.json"

            with contextlib.redirect_stdout(output):
                analyze_reference_exit = analyzer_main(
                    [
                        "analyze",
                        "--reference",
                        str(reference),
                        "--profile",
                        str(profile),
                        "--map-id",
                        "map-test",
                        "--name",
                        "Map Test",
                        "--output-blueprint",
                        str(reference_blueprint),
                        "--output-report",
                        str(reference_report),
                        "--output-overlay",
                        str(reference_overlay),
                    ]
                )
            self.assertEqual(analyze_reference_exit, 0)
            self.assertTrue(reference_overlay.is_file())
            with contextlib.redirect_stdout(output):
                analyze_candidate_exit = analyzer_main(
                    [
                        "analyze",
                        "--reference",
                        str(candidate),
                        "--profile",
                        str(profile),
                        "--map-id",
                        "map-test",
                        "--name",
                        "Map Test",
                        "--output-blueprint",
                        str(candidate_blueprint),
                        "--output-report",
                        str(candidate_report),
                    ]
                )
            self.assertEqual(analyze_candidate_exit, 0)
            assets = root / "assets"
            assets.mkdir()
            asset = Image.new("RGBA", (32, 32), (90, 130, 70, 255))
            asset.putpixel((0, 0), (0, 0, 0, 0))
            asset.save(assets / "hgss_tree.png")
            catalog = root / "catalog.json"
            resolution = root / "resolution.json"

            with contextlib.redirect_stdout(output):
                index_exit = asset_main(["index", "--root", f"{assets}=hgss_ds", "--output", str(catalog)])
            self.assertEqual(index_exit, 0)
            with contextlib.redirect_stdout(output):
                resolve_exit = asset_main(
                    [
                        "resolve",
                        "--blueprint",
                        str(reference_blueprint),
                        "--catalog",
                        str(catalog),
                        "--output",
                        str(resolution),
                    ]
                )
            self.assertEqual(resolve_exit, 0)
            lint_report = root / "lint.json"
            comparison = root / "comparison.json"
            with contextlib.redirect_stdout(output):
                lint_exit = quality_main(["lint", "--blueprint", str(candidate_blueprint), "--output", str(lint_report)])
            self.assertEqual(lint_exit, 0)
            with contextlib.redirect_stdout(output):
                compare_exit = quality_main(
                    [
                        "compare",
                        "--reference",
                        str(reference_blueprint),
                        "--candidate",
                        str(candidate_blueprint),
                        "--asset-report",
                        str(resolution),
                        "--reference-image",
                        str(reference),
                        "--candidate-image",
                        str(candidate),
                        "--threshold",
                        "80",
                        "--output",
                        str(comparison),
                    ]
                )
            self.assertEqual(compare_exit, 0)
            report = json.loads(comparison.read_text(encoding="utf-8"))
            self.assertEqual(report["technicalScore"], 100)
            self.assertEqual(report["axes"]["visualFidelity"], 100)
            self.assertEqual(report["score"], 100)

    def test_compare_without_visual_evidence_is_not_reviewable(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            blueprint = root / "blueprint.json"
            blueprint.write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "map": {"id": "map-test", "name": "Map Test", "widthCells": 2, "heightCells": 2},
                        "layers": [
                            {
                                "id": "grass",
                                "family": "surface",
                                "semantic": "grass",
                                "geometry": {
                                    "kind": "cells",
                                    "cells": [{"x": 0, "y": 0}],
                                },
                            }
                        ],
                    }
                ),
                encoding="utf-8",
            )
            comparison = root / "comparison.json"

            with contextlib.redirect_stdout(io.StringIO()):
                compare_exit = quality_main(
                    [
                        "compare",
                        "--reference",
                        str(blueprint),
                        "--candidate",
                        str(blueprint),
                        "--output",
                        str(comparison),
                    ]
                )

            report = json.loads(comparison.read_text(encoding="utf-8"))
            self.assertEqual(compare_exit, 1)
            self.assertIsNone(report["score"])
            self.assertEqual(report["technicalScore"], 100)
            self.assertIn("visual_evidence_missing", report["failedGates"])
            self.assertFalse(report["eligibleForHumanReview"])


if __name__ == "__main__":
    unittest.main()

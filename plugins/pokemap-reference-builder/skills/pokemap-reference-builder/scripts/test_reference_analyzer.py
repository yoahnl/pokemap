#!/usr/bin/env python3
import tempfile
import unittest
from pathlib import Path

from PIL import Image

from blueprint_tool import validate_blueprint
from reference_analyzer import analyze_reference, render_analysis_overlay


class ReferenceAnalyzerTest(unittest.TestCase):
    def test_builds_proposed_semantic_layers_from_seed_cells(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            reference = Path(directory) / "reference.png"
            image = Image.new("RGB", (128, 96), (45, 160, 70))
            for y in range(32):
                for x in range(128):
                    image.putpixel((x, y), (35, 120, 190))
            for y in range(32, 64):
                for x in range(96, 128):
                    image.putpixel((x, y), (130, 90, 45))
            image.save(reference)
            profile = {
                "schemaVersion": 1,
                "cellSizePx": 32,
                "sampleInsetPx": 4,
                "classes": [
                    {
                        "semantic": "paddy_water",
                        "name": "Paddy water",
                        "family": "surface",
                        "seeds": [{"x": 0, "y": 0}],
                        "minimumConfidence": 0.8,
                    },
                    {
                        "semantic": "grass",
                        "name": "Grass",
                        "family": "surface",
                        "seeds": [{"x": 0, "y": 1}],
                        "minimumConfidence": 0.8,
                    },
                    {
                        "semantic": "ignored_structure",
                        "name": "Ignored structure",
                        "seeds": [{"x": 3, "y": 1}],
                        "minimumConfidence": 0.8,
                    },
                ],
                "missingAssets": [
                    {
                        "id": "asset-wood-bridge",
                        "semantic": "bridge",
                        "tags": ["wood"],
                        "status": "proposed",
                        "widthCells": 3,
                        "heightCells": 2,
                        "pixelWidth": 96,
                        "pixelHeight": 64,
                        "anchor": {"x": 1, "y": 1},
                        "collisionCells": [],
                        "provenance": "custom_hgss_compatible",
                        "alphaPolicy": "required",
                        "styleReferences": ["HGSS wooden bridge"],
                    }
                ],
            }

            blueprint, report = analyze_reference(
                reference,
                "map-test",
                "Map Test",
                profile,
            )

            self.assertEqual(blueprint["map"]["widthCells"], 4)
            self.assertEqual(blueprint["map"]["heightCells"], 3)
            self.assertEqual(validate_blueprint(blueprint), [])
            layers = {layer["semantic"]: layer for layer in blueprint["layers"]}
            self.assertEqual(
                layers["paddy_water"]["geometry"]["cells"],
                [{"x": 0, "y": 0}, {"x": 1, "y": 0}, {"x": 2, "y": 0}, {"x": 3, "y": 0}],
            )
            self.assertEqual(len(layers["grass"]["geometry"]["cells"]), 7)
            self.assertNotIn("ignored_structure", layers)
            self.assertEqual(report["ignoredCells"], 1)
            self.assertEqual(report["unclassifiedCells"], 0)
            self.assertTrue(report["requiresHumanReview"])
            self.assertEqual(blueprint["missingAssets"][0]["pixelWidth"], 96)
            overlay = Path(directory) / "overlay.png"
            render_analysis_overlay(reference, blueprint, report, overlay)
            with Image.open(overlay) as rendered:
                self.assertEqual(rendered.size, (128, 96))

    def test_rejects_reference_that_does_not_match_native_grid(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            reference = Path(directory) / "reference.png"
            Image.new("RGB", (65, 64), (0, 0, 0)).save(reference)
            profile = {
                "schemaVersion": 1,
                "cellSizePx": 32,
                "classes": [
                    {
                        "semantic": "ground",
                        "name": "Ground",
                        "family": "surface",
                        "seeds": [{"x": 0, "y": 0}],
                    }
                ],
            }

            with self.assertRaisesRegex(ValueError, "multiple of 32"):
                analyze_reference(reference, "map-test", "Map Test", profile)

    def test_accepts_integer_downscaled_capture_with_native_output_grid(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            reference = Path(directory) / "capture.png"
            Image.new("RGB", (64, 48), (45, 160, 70)).save(reference)
            profile = {
                "schemaVersion": 1,
                "cellSizePx": 32,
                "sourceCellSizePx": 16,
                "classes": [
                    {
                        "semantic": "ground",
                        "name": "Ground",
                        "family": "surface",
                        "seeds": [{"x": 0, "y": 0}],
                    }
                ],
            }

            blueprint, report = analyze_reference(reference, "map-test", "Map Test", profile)

            self.assertEqual(blueprint["cellSizePx"], 32)
            self.assertEqual(blueprint["map"]["widthCells"], 4)
            self.assertEqual(blueprint["map"]["heightCells"], 3)
            self.assertEqual(report["sourceCellSizePx"], 16)

    def test_removes_small_isolated_components_before_blueprint_creation(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            reference = Path(directory) / "reference.png"
            image = Image.new("RGB", (128, 64), (45, 160, 70))
            for x in range(96):
                for y in range(32):
                    image.putpixel((x, y), (185, 150, 80))
            for x in range(96, 128):
                for y in range(32, 64):
                    image.putpixel((x, y), (185, 150, 80))
            image.save(reference)
            profile = {
                "schemaVersion": 1,
                "cellSizePx": 32,
                "classes": [
                    {
                        "semantic": "path",
                        "name": "Path",
                        "family": "network",
                        "seeds": [{"x": 0, "y": 0}],
                        "minimumComponentCells": 2,
                    },
                    {
                        "semantic": "grass",
                        "name": "Grass",
                        "family": "surface",
                        "seeds": [{"x": 0, "y": 1}],
                    },
                ],
            }

            blueprint, report = analyze_reference(reference, "map-test", "Map Test", profile)

            path = next(layer for layer in blueprint["layers"] if layer["semantic"] == "path")
            self.assertEqual(path["geometry"]["cells"], [{"x": 0, "y": 0}, {"x": 1, "y": 0}, {"x": 2, "y": 0}])
            path_report = next(item for item in report["classes"] if item["semantic"] == "path")
            self.assertEqual(path_report["removedIsolatedCells"], 1)

    def test_rejects_profile_that_would_generate_invalid_blueprint(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            reference = Path(directory) / "reference.png"
            Image.new("RGB", (32, 32), (45, 160, 70)).save(reference)
            profile = {
                "schemaVersion": 1,
                "cellSizePx": 32,
                "classes": [
                    {
                        "semantic": "ground",
                        "name": "Ground",
                        "family": "imaginary",
                        "seeds": [{"x": 0, "y": 0}],
                    }
                ],
            }

            with self.assertRaisesRegex(ValueError, "generated blueprint is invalid"):
                analyze_reference(reference, "map-test", "Map Test", profile)


if __name__ == "__main__":
    unittest.main()

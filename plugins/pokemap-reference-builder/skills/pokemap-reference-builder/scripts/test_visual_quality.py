#!/usr/bin/env python3
import tempfile
import unittest
import json
from pathlib import Path

from PIL import Image, ImageDraw

from visual_quality import compare_images


def reference_scene(path: Path, scale: int = 1) -> None:
    image = Image.new("RGB", (64 * scale, 52 * scale), (59, 116, 45))
    draw = ImageDraw.Draw(image)
    water = (39, 103, 116)
    bank = (126, 112, 58)
    path_color = (178, 145, 86)
    for left, top, right, bottom in ((4, 6, 18, 20), (24, 6, 38, 20), (44, 6, 58, 20), (4, 31, 18, 46), (24, 31, 38, 46), (44, 31, 58, 46)):
        draw.rectangle(tuple(value * scale for value in (left - 1, top - 1, right + 1, bottom + 1)), fill=bank)
        draw.rectangle(tuple(value * scale for value in (left, top, right, bottom)), fill=water)
        for y in range(top + 2, bottom, 3):
            for x in range(left + 2, right, 3):
                draw.point((x * scale, y * scale), fill=(86, 144, 55))
    draw.rectangle((0, 23 * scale, 64 * scale, 28 * scale), fill=path_color)
    draw.rectangle((20 * scale, 0, 23 * scale, 52 * scale), fill=path_color)
    draw.rectangle((40 * scale, 0, 43 * scale, 52 * scale), fill=path_color)
    for x in range(0, 64, 3):
        draw.ellipse((x * scale, 0, (x + 3) * scale, 4 * scale), fill=(31, 78, 31))
        draw.ellipse((x * scale, 48 * scale, (x + 3) * scale, 52 * scale), fill=(31, 78, 31))
    image.save(path)


def flat_candidate(path: Path) -> None:
    image = Image.new("RGB", (64, 52), (96, 201, 157))
    draw = ImageDraw.Draw(image)
    for box in ((4, 6, 18, 20), (24, 6, 38, 20), (44, 6, 58, 20), (4, 31, 18, 46), (24, 31, 38, 46), (44, 31, 58, 46)):
        draw.rectangle(box, fill=(23, 148, 255))
    draw.rectangle((0, 21, 64, 30), fill=(236, 205, 139))
    draw.rectangle((18, 0, 25, 52), fill=(236, 205, 139))
    draw.rectangle((38, 0, 45, 52), fill=(236, 205, 139))
    image.save(path)


class VisualQualityTest(unittest.TestCase):
    def test_identical_scene_at_integer_scale_reaches_visual_gate(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            reference = root / "reference.png"
            candidate = root / "candidate.png"
            reference_scene(reference)
            Image.open(reference).resize((128, 104), Image.Resampling.NEAREST).save(candidate)

            report = compare_images(reference, candidate, threshold=80)

        self.assertGreaterEqual(report["score"], 98)
        self.assertTrue(report["eligibleForVisualReview"])
        self.assertEqual(report["failedAxes"], [])

    def test_flat_palette_shifted_scene_fails_visual_gate(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            reference = root / "reference.png"
            candidate = root / "candidate.png"
            reference_scene(reference, scale=2)
            flat_candidate(candidate)

            report = compare_images(reference, candidate, threshold=80)

        self.assertLess(report["score"], 80)
        self.assertFalse(report["eligibleForVisualReview"])
        self.assertIn("paletteAndStyle", report["failedAxes"])
        self.assertIn("visualHierarchy", report["failedAxes"])
        self.assertTrue(report["regions"])

    def test_different_aspect_ratios_are_not_comparable(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            reference = root / "reference.png"
            candidate = root / "candidate.png"
            Image.new("RGB", (64, 52), "green").save(reference)
            Image.new("RGB", (64, 48), "green").save(candidate)

            with self.assertRaisesRegex(ValueError, "aspect ratio"):
                compare_images(reference, candidate)

    def test_blueprint_scores_semantic_materials_by_family(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            reference = root / "reference.png"
            candidate = root / "candidate.png"
            blueprint = root / "blueprint.json"
            reference_image = Image.new("RGB", (40, 10), "red")
            ImageDraw.Draw(reference_image).rectangle((20, 0, 39, 9), fill="blue")
            reference_image.save(reference)
            candidate_image = Image.new("RGB", (40, 10), "blue")
            ImageDraw.Draw(candidate_image).rectangle((20, 0, 39, 9), fill="red")
            candidate_image.save(candidate)
            blueprint.write_text(
                json.dumps(
                    {
                        "map": {"widthCells": 4, "heightCells": 1},
                        "layers": [
                            {
                                "id": "surface-red",
                                "name": "Red surface",
                                "family": "surface",
                                "geometry": {"cells": [{"x": 0, "y": 0}, {"x": 1, "y": 0}]},
                            },
                            {
                                "id": "surface-blue",
                                "name": "Blue surface",
                                "family": "surface",
                                "geometry": {"cells": [{"x": 2, "y": 0}, {"x": 3, "y": 0}]},
                            },
                        ],
                    }
                ),
                encoding="utf-8",
            )

            report = compare_images(reference, candidate, threshold=80, blueprint_path=blueprint)

        self.assertLess(report["axes"]["semanticMaterials"], 60)
        self.assertIn("semanticMaterials", report["failedAxes"])
        self.assertEqual(len(report["semanticFamilies"]), 2)


if __name__ == "__main__":
    unittest.main()

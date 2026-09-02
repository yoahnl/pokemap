#!/usr/bin/env python3
import unittest

from blueprint_quality import compare_blueprints, lint_blueprint
from blueprint_tool import create_blueprint


def passing_visual_report() -> dict:
    return {
        "schemaVersion": 1,
        "threshold": 80,
        "score": 100,
        "axes": {
            "paletteAndStyle": 100,
            "visualHierarchy": 100,
            "detailDensity": 100,
        },
        "failedAxes": [],
        "eligibleForVisualReview": True,
        "repairPlan": [],
    }


def cells_layer(layer_id: str, family: str, semantic: str, cells: list[tuple[int, int]], **constraints: object) -> dict:
    return {
        "id": layer_id,
        "family": family,
        "semantic": semantic,
        "name": semantic,
        "status": "proposed",
        "geometry": {
            "kind": "cells",
            "cells": [{"x": x, "y": y} for x, y in cells],
        },
        "bindings": [],
        "constraints": constraints,
        "notes": [],
    }


def placement_layer(layer_id: str, semantic: str, x: int, y: int, width: int, height: int) -> dict:
    return {
        "id": layer_id,
        "family": "structure",
        "semantic": semantic,
        "name": semantic,
        "status": "proposed",
        "geometry": {
            "kind": "placement",
            "origin": {"x": x, "y": y},
            "size": {"width": width, "height": height},
        },
        "bindings": [],
        "constraints": {},
        "notes": [],
    }


class BlueprintQualityTest(unittest.TestCase):
    def test_rejects_trees_over_water_structures_and_rails(self) -> None:
        blueprint = create_blueprint("/reference.png", "map-test", "Map Test", 12, 12)
        blueprint["layers"].extend(
            [
                cells_layer("water", "surface", "paddy_water", [(2, 2)]),
                placement_layer("house", "station_building", 4, 4, 2, 2),
                cells_layer("rail", "network", "rail_track", [(8, 8)]),
                cells_layer("trees", "decoration", "tree", [(2, 2), (4, 4), (8, 8)]),
            ]
        )

        report = lint_blueprint(blueprint)

        self.assertFalse(report["valid"])
        self.assertEqual(
            {error["code"] for error in report["errors"]},
            {"tree_in_water", "tree_in_structure", "tree_on_rail"},
        )

    def test_rejects_disconnected_network_marked_as_continuous(self) -> None:
        blueprint = create_blueprint("/reference.png", "map-test", "Map Test", 12, 12)
        blueprint["layers"].append(
            cells_layer(
                "path",
                "network",
                "main_path",
                [(1, 1), (2, 1), (8, 8)],
                continuityRequired=True,
            )
        )

        report = lint_blueprint(blueprint)

        self.assertFalse(report["valid"])
        self.assertTrue(any(error["code"] == "network_disconnected" for error in report["errors"]))

    def test_rejects_large_repeated_terrain_assets_that_flatten_semantic_families(self) -> None:
        blueprint = create_blueprint("/reference.png", "map-test", "Map Test", 20, 20)
        blueprint["layers"].extend(
            [
                placement_layer("paddy-northwest", "rice_paddy", 1, 1, 6, 6),
                placement_layer("paddy-northeast", "rice_paddy", 12, 1, 6, 6),
                placement_layer("paddy-southwest", "rice_paddy", 1, 12, 6, 6),
                placement_layer("paddy-southeast", "rice_paddy", 12, 12, 6, 6),
            ]
        )

        report = lint_blueprint(blueprint)

        self.assertFalse(report["valid"])
        flattening = next(error for error in report["errors"] if error["code"] == "semantic_family_flattening")
        self.assertEqual(flattening["semantic"], "rice_paddy")
        self.assertEqual(flattening["placementCount"], 4)
        self.assertGreater(flattening["coverageRatio"], 0.25)

    def test_identical_blueprints_reach_review_gate_but_not_human_acceptance(self) -> None:
        reference = create_blueprint("/reference.png", "map-test", "Map Test", 12, 12)
        reference["layers"].extend(
            [
                cells_layer("water", "surface", "paddy_water", [(1, 1), (2, 1), (1, 2), (2, 2)]),
                cells_layer(
                    "path",
                    "network",
                    "main_path",
                    [(5, 1), (5, 2), (5, 3)],
                    continuityRequired=True,
                ),
                placement_layer("station", "station_building", 7, 2, 3, 2),
            ]
        )
        candidate = create_blueprint("/candidate.png", "map-test", "Map Test", 12, 12)
        candidate["layers"] = reference["layers"]

        report = compare_blueprints(reference, candidate, visual_report=passing_visual_report(), threshold=80)

        self.assertEqual(report["score"], 100)
        self.assertTrue(report["eligibleForHumanReview"])
        self.assertFalse(report["humanAccepted"])
        self.assertEqual(report["axes"]["topology"], 100)
        self.assertEqual(report["axes"]["scale"], 100)
        self.assertEqual(report["repairPlan"], [])

    def test_missing_visual_evidence_blocks_review_without_publishing_a_score(self) -> None:
        reference = create_blueprint("/reference.png", "map-test", "Map Test", 12, 12)
        candidate = create_blueprint("/candidate.png", "map-test", "Map Test", 12, 12)
        reference["layers"].append(cells_layer("ground", "surface", "grass", [(1, 1), (2, 1)]))
        candidate["layers"] = reference["layers"]

        report = compare_blueprints(reference, candidate, threshold=80)

        self.assertIsNone(report["score"])
        self.assertEqual(report["technicalScore"], 100)
        self.assertFalse(report["eligibleForHumanReview"])
        self.assertIn("visual_evidence_missing", report["failedGates"])

    def test_low_visual_fidelity_blocks_a_technically_identical_candidate(self) -> None:
        reference = create_blueprint("/reference.png", "map-test", "Map Test", 12, 12)
        candidate = create_blueprint("/candidate.png", "map-test", "Map Test", 12, 12)
        reference["layers"].append(cells_layer("ground", "surface", "grass", [(1, 1), (2, 1)]))
        candidate["layers"] = reference["layers"]
        visual_report = passing_visual_report()
        visual_report.update(
            {
                "score": 40,
                "failedAxes": ["paletteAndStyle", "visualHierarchy"],
                "eligibleForVisualReview": False,
                "repairPlan": [
                    {
                        "priority": "blocking",
                        "action": "repair_visual_hierarchy",
                        "reason": "Visual hierarchy is below 80",
                    }
                ],
            }
        )

        report = compare_blueprints(reference, candidate, visual_report=visual_report, threshold=80)

        self.assertLess(report["score"], 80)
        self.assertFalse(report["eligibleForHumanReview"])
        self.assertIn("visual_fidelity", report["failedGates"])
        self.assertEqual(report["axes"]["visualFidelity"], 40)
        self.assertIn("repair_visual_hierarchy", {item["action"] for item in report["repairPlan"]})

    def test_hard_rule_failure_blocks_review_even_above_threshold(self) -> None:
        reference = create_blueprint("/reference.png", "map-test", "Map Test", 12, 12)
        reference_trees = [(3, 2), (3, 3), (4, 3), (5, 3), (6, 3), (7, 3), (8, 3), (9, 3), (10, 3), (10, 4)]
        candidate_trees = [(2, 2), *reference_trees[1:]]
        reference["layers"].extend(
            [
                cells_layer("water", "surface", "paddy_water", [(2, 2)]),
                cells_layer("trees", "decoration", "tree", reference_trees),
            ]
        )
        candidate = create_blueprint("/candidate.png", "map-test", "Map Test", 12, 12)
        candidate["layers"].extend(
            [
                cells_layer("water", "surface", "paddy_water", [(2, 2)]),
                cells_layer("trees", "decoration", "tree", candidate_trees),
            ]
        )

        report = compare_blueprints(reference, candidate, visual_report=passing_visual_report(), threshold=80)

        self.assertGreaterEqual(report["score"], 80)
        self.assertFalse(report["eligibleForHumanReview"])
        self.assertIn("spatial_rules", report["failedGates"])
        actions = {item["action"] for item in report["repairPlan"]}
        self.assertIn("remove_tree_overlap", actions)


if __name__ == "__main__":
    unittest.main()

#!/usr/bin/env python3
import copy
import unittest

from blueprint_tool import create_blueprint, validate_blueprint


class BlueprintToolTest(unittest.TestCase):
    def setUp(self) -> None:
        self.blueprint = create_blueprint(
            "/reference.png",
            "map_hanazuki_reference",
            "Hanazuki Reference",
            48,
            32,
        )

    def layer(self, family: str, semantic: str, action_family: str, resource_id: str) -> dict:
        return {
            "id": f"layer-{family}-{semantic}",
            "family": family,
            "semantic": semantic,
            "name": semantic.title(),
            "status": "approved",
            "geometry": {
                "kind": "cells",
                "cells": [{"x": 1, "y": 1}, {"x": 2, "y": 1}],
            },
            "bindings": [
                {
                    "role": "primary",
                    "resourceId": resource_id,
                    "actionFamily": action_family,
                    "provenance": "hgss_ds",
                }
            ],
            "constraints": {},
            "notes": [],
        }

    def test_accepts_approved_forest_bound_to_environment(self) -> None:
        self.blueprint["layers"].append(
            self.layer("surface", "forest", "environment", "environment-hgss-forest")
        )
        self.assertEqual(validate_blueprint(self.blueprint), [])

    def test_rejects_forest_bound_as_repeated_elements(self) -> None:
        self.blueprint["layers"].append(
            self.layer("surface", "forest", "placed_element", "element-hgss-tree")
        )
        errors = validate_blueprint(self.blueprint)
        self.assertTrue(any("Environment capability" in error for error in errors))

    def test_rejects_ocean_binding_for_river(self) -> None:
        layer = self.layer("network", "river", "smart_tile", "preset-hgss-ocean-water")
        layer["constraints"] = {"waterBodyType": "river"}
        self.blueprint["layers"].append(layer)
        errors = validate_blueprint(self.blueprint)
        self.assertTrue(any("ocean resources" in error for error in errors))

    def test_rejects_unapproved_border(self) -> None:
        self.blueprint["layers"].append(
            self.layer("border", "forest-edge", "border_layer", "border-hgss-forest")
        )
        errors = validate_blueprint(self.blueprint)
        self.assertTrue(any("explicitApproval" in error for error in errors))

    def test_rejects_gba_provenance(self) -> None:
        layer = self.layer("decoration", "tree", "placed_element", "element-gba-tree")
        layer["bindings"][0]["provenance"] = "gba"
        self.blueprint["layers"].append(layer)
        errors = validate_blueprint(self.blueprint)
        self.assertTrue(any("GBA" in error or "hgss_ds" in error for error in errors))

    def test_rejects_wrong_missing_asset_canvas(self) -> None:
        asset = {
            "id": "asset-custom-torii",
            "status": "proposed",
            "widthCells": 4,
            "heightCells": 5,
            "pixelWidth": 96,
            "pixelHeight": 160,
            "anchor": {"x": 2, "y": 4},
            "collisionCells": [],
            "provenance": "custom_hgss_compatible",
            "alphaPolicy": "required",
            "styleReferences": [],
        }
        self.blueprint["missingAssets"].append(copy.deepcopy(asset))
        errors = validate_blueprint(self.blueprint)
        self.assertTrue(any("widthCells * 32" in error for error in errors))

    def test_rejects_invalid_v2_spatial_constraints(self) -> None:
        layer = self.layer("network", "path", "smart_tile", "preset-hgss-path")
        layer["constraints"] = {"continuityRequired": "yes", "networkWidthCells": 0}
        self.blueprint["layers"].append(layer)

        errors = validate_blueprint(self.blueprint)

        self.assertTrue(any("continuityRequired" in error for error in errors))
        self.assertTrue(any("networkWidthCells" in error for error in errors))

    def test_rejects_invalid_missing_asset_semantic_tags(self) -> None:
        asset = {
            "id": "asset-custom-bridge",
            "semantic": "bridge",
            "tags": ["wood", ""],
            "status": "proposed",
            "widthCells": 3,
            "heightCells": 2,
            "pixelWidth": 96,
            "pixelHeight": 64,
            "anchor": {"x": 1, "y": 1},
            "collisionCells": [],
            "provenance": "custom_hgss_compatible",
            "alphaPolicy": "required",
            "styleReferences": [],
        }
        self.blueprint["missingAssets"].append(asset)

        errors = validate_blueprint(self.blueprint)

        self.assertTrue(any("tags" in error for error in errors))


if __name__ == "__main__":
    unittest.main()

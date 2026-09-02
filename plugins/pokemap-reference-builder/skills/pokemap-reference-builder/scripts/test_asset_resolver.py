#!/usr/bin/env python3
import json
import tempfile
import unittest
from pathlib import Path

from PIL import Image

from asset_contract import validate_contract
from asset_resolver import index_assets, materialize_gap_workshop, resolve_missing_assets
from blueprint_tool import create_blueprint


def write_asset(path: Path, width: int, height: int, transparent: bool = True) -> None:
    image = Image.new("RGBA", (width, height), (90, 130, 70, 255))
    if transparent:
        image.putpixel((0, 0), (0, 0, 0, 0))
    image.save(path)


class AssetResolverTest(unittest.TestCase):
    def test_ranks_exact_footprint_and_semantic_tags_first(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            write_asset(root / "hgss_wood_bridge_3x2.png", 96, 64)
            write_asset(root / "hgss_station_house_3x2.png", 96, 64)
            write_asset(root / "hgss_wood_bridge_wrong_size.png", 64, 64)

            catalog = index_assets([{"path": str(root), "provenance": "hgss_ds"}])
            blueprint = create_blueprint("/reference.png", "map-test", "Map Test", 20, 20)
            blueprint["missingAssets"].append(
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
            )

            report = resolve_missing_assets(blueprint, catalog)

            resolution = report["resolutions"][0]
            self.assertEqual(resolution["decision"], "reuse")
            self.assertEqual(Path(resolution["candidates"][0]["path"]).name, "hgss_wood_bridge_3x2.png")
            self.assertEqual(resolution["candidates"][0]["widthCells"], 3)
            self.assertEqual(resolution["candidates"][0]["heightCells"], 2)
            self.assertGreaterEqual(resolution["candidates"][0]["score"], 80)

    def test_returns_exact_gap_canvas_when_no_asset_matches(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            write_asset(root / "hgss_bridge_3x2.png", 96, 64)
            catalog = index_assets([{"path": str(root), "provenance": "hgss_ds"}])
            blueprint = create_blueprint("/reference.png", "map-test", "Map Test", 20, 20)
            blueprint["missingAssets"].append(
                {
                    "id": "asset-wide-bridge",
                    "semantic": "bridge",
                    "tags": ["wood"],
                    "status": "proposed",
                    "widthCells": 4,
                    "heightCells": 2,
                    "pixelWidth": 128,
                    "pixelHeight": 64,
                    "anchor": {"x": 2, "y": 1},
                    "collisionCells": [],
                    "provenance": "custom_hgss_compatible",
                    "alphaPolicy": "required",
                    "styleReferences": ["HGSS wooden bridge"],
                }
            )

            report = resolve_missing_assets(blueprint, catalog)

            resolution = report["resolutions"][0]
            self.assertEqual(resolution["decision"], "gap")
            self.assertEqual(resolution["expectedCanvas"], {"widthPx": 128, "heightPx": 64})
            self.assertEqual(resolution["candidates"], [])

    def test_unknown_provenance_is_never_eligible(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            write_asset(root / "bridge.png", 96, 64)
            catalog = index_assets([{"path": str(root), "provenance": "unknown"}])
            self.assertFalse(catalog["assets"][0]["eligible"])

    def test_materializes_exact_transparent_canvas_for_unresolved_gap(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            blueprint = create_blueprint("/reference.png", "map-test", "Map Test", 20, 20)
            blueprint["missingAssets"].append(
                {
                    "id": "asset-wide-bridge",
                    "semantic": "bridge",
                    "tags": ["wood"],
                    "status": "proposed",
                    "widthCells": 4,
                    "heightCells": 2,
                    "pixelWidth": 128,
                    "pixelHeight": 64,
                    "anchor": {"x": 2, "y": 1},
                    "collisionCells": [{"x": 0, "y": 1}, {"x": 3, "y": 1}],
                    "provenance": "custom_hgss_compatible",
                    "alphaPolicy": "required",
                    "styleReferences": ["HGSS wooden bridge"],
                }
            )
            resolutions = resolve_missing_assets(blueprint, {"assets": []})

            manifest = materialize_gap_workshop(blueprint, resolutions, root / "workshop")

            item = manifest["assets"][0]
            canvas = Path(item["canvas"])
            contract_path = Path(item["contract"])
            with Image.open(canvas) as image:
                self.assertEqual(image.size, (128, 64))
                self.assertEqual(image.mode, "RGBA")
                self.assertEqual(image.getchannel("A").getextrema(), (0, 0))
            contract = json.loads(contract_path.read_text(encoding="utf-8"))
            errors, metadata = validate_contract(contract, contract_path.parent)
            self.assertEqual(errors, [])
            self.assertTrue(metadata["alphaUsed"])


if __name__ == "__main__":
    unittest.main()

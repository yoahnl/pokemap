import tempfile
import unittest
from pathlib import Path

from PIL import Image

from psdk_rule_patterns import extract_rules


class PsdkRulePatternsTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        for folder in ("Maps", "Tilesets", "Assets"):
            (self.root / folder).mkdir()
        sheet = Image.new("RGBA", (64, 32), (120, 60, 30, 255))
        sheet.paste((20, 80, 140, 255), (32, 0, 64, 32))
        sheet.save(self.root / "Assets" / "test.png")
        (self.root / "Tilesets" / "test.tsx").write_text(
            '<tileset tilewidth="32" tileheight="32" tilecount="2" columns="2">'
            '<image source="../Assets/test.png" width="64" height="32"/>'
            '</tileset>',
            encoding="utf-8",
        )

    def write_map(self, filename, layers):
        contents = '<map orientation="orthogonal" tilewidth="32" tileheight="32" width="2" height="2" infinite="1">'
        contents += '<tileset firstgid="1" source="../Tilesets/test.tsx"/>'
        for name, values in layers:
            contents += f'<layer name="{name}" width="2" height="2"><data encoding="csv"><chunk x="0" y="0" width="2" height="2">'
            contents += ",".join(str(value) for value in values)
            contents += '</chunk></data></layer>'
        contents += '</map>'
        (self.root / "Maps" / filename).write_text(contents, encoding="utf-8")

    def building_layers(self, output_gid=1):
        return [
            ("regions_input", [0, 0, 1, 0]),
            ("regions_output", [1, 1, 0, 0]),
            ("input_▬_Bld_input", [0, 0, 2, 0]),
            ("output_▬_Bld_A_1", [1, output_gid, 0, 0]),
        ]

    def test_anchor_uses_union_when_input_is_outside_output_region(self):
        self.write_map("rules_TECH_buildings.tmx", self.building_layers())
        patterns = extract_rules(self.root)
        self.assertEqual(len(patterns), 1)
        self.assertEqual(patterns[0]["image"].size, (64, 64))
        self.assertEqual(patterns[0]["anchor"], {
            "x": 0,
            "y": 1,
            "basis": "regions_input",
            "kind": "rule_input_marker",
        })

    def test_building_marker_is_excluded_and_prop_input_is_visible(self):
        self.write_map("rules_TECH_buildings.tmx", self.building_layers())
        self.write_map("rules_TECH_assets.tmx", [
            ("input_Furniture_A_1", [0, 0, 2, 0]),
            ("output_Furniture_A_2", [1, 0, 0, 0]),
        ])
        patterns = extract_rules(self.root)
        building = next(pattern for pattern in patterns if pattern["family"] == "buildings")
        prop = next(pattern for pattern in patterns if pattern["family"] == "props")
        self.assertEqual(building["image"].getpixel((16, 48))[3], 0)
        self.assertEqual(prop["image"].getpixel((16, 48)), (20, 80, 140, 255))
        self.assertFalse(any(cell["layer"].startswith("input_") for cell in building["sourceCells"]))
        self.assertEqual(len(building["inputCells"]), 1)

    def test_missing_gid_is_reported_and_keeps_declared_canvas(self):
        self.write_map("rules_TECH_buildings.tmx", self.building_layers(output_gid=3))
        pattern = extract_rules(self.root)[0]
        self.assertEqual(pattern["status"], "incomplete_source")
        self.assertEqual(pattern["confidence"], "low")
        self.assertEqual(pattern["image"].size, (64, 64))
        self.assertEqual(pattern["image"].getpixel((48, 16))[3], 0)
        self.assertEqual(pattern["image"].getpixel((16, 16)), (120, 60, 30, 255))
        self.assertEqual(len(pattern["missingSourceCells"]), 1)
        self.assertEqual(pattern["missingSourceCells"][0]["gid"], 3)
        self.assertIsNone(pattern["collisionCells"])


if __name__ == "__main__":
    unittest.main()

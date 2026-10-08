import hashlib
import json
import os
import unittest
from pathlib import Path

from PIL import Image


@unittest.skipUnless(os.environ.get("AVELUNE_VALBOIS_POKEMON_PACK") and os.environ.get("AVELUNE_PSDK_SOURCE"), "PSDK source and generated Valbois pack required")
class ValboisPokemonPackTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.path = Path(os.environ["AVELUNE_VALBOIS_POKEMON_PACK"])
        cls.pack = json.loads(cls.path.read_text())
        cls.source = Path(os.environ["AVELUNE_PSDK_SOURCE"])
        cls.documents = [entry["parameters"]["document"] for entry in cls.pack["documents"]]

    def test_all_source_receipts_match_real_psdk_bytes(self):
        for entry in self.pack["sources"]:
            data = (self.source / entry["path"]).read_bytes()
            self.assertEqual(entry["sha256"], hashlib.sha256(data).hexdigest())
            self.assertEqual(entry["bytes"], len(data))

    def test_base_stats_and_every_level_up_move_come_from_psdk(self):
        species = {entry["id"]: entry for entry in self.documents if "nationalDex" in entry}
        learnsets = {entry["speciesId"]: entry for entry in self.documents if "levelUp" in entry}
        self.assertEqual(set(species), {"bulbasaur", "pidgey", "rattata", "caterpie"})
        for name, entry in species.items():
            raw = json.loads((self.source / f"Data/Studio/pokemon/{name}.json").read_text())
            form = raw["forms"][0]
            keys = {"hp": "baseHp", "atk": "baseAtk", "def": "baseDfe", "spa": "baseAts", "spd": "baseDfs", "spe": "baseSpd"}
            for output, source in keys.items():
                self.assertEqual(entry["baseStats"][output], form[source])
            self.assertEqual(entry["progression"]["catchRate"], form["catchRate"])
            published_abilities = [ability for ability in entry["abilities"].values() if ability]
            self.assertEqual(entry["abilities"]["primary"], form["abilities"][0])
            self.assertEqual(set(published_abilities), set(form["abilities"]))
            self.assertEqual(len(published_abilities), len(set(published_abilities)))
            expected = [(move["move"], move["level"]) for move in form["moveSet"] if move["klass"] == "LevelLearnableMove"]
            actual = [(move["moveId"], move["level"]) for move in learnsets[name]["levelUp"]]
            self.assertEqual(actual, expected)

    def test_moves_are_closed_and_keep_psdk_method_and_target(self):
        catalog = next(entry for entry in self.pack["catalogs"] if entry["catalog"] == "moves")
        moves = {entry["id"]: entry for entry in catalog["entries"]}
        required = {move["moveId"] for entry in self.documents if "levelUp" in entry for move in entry["levelUp"]}
        self.assertEqual(set(moves), required)
        for name, move in moves.items():
            source = json.loads((self.source / f"Data/Studio/moves/{name}.json").read_text())
            self.assertEqual(move["basePower"], source["power"])
            self.assertEqual(move["pp"], source["pp"])
            self.assertEqual(move["battleEngineMethod"], source["battleEngineMethod"])
            self.assertIn(f"psdk_method:{source['battleEngineMethod']}", move["unsupportedReasons"])
            self.assertNotEqual(move["target"], "scripted")
        self.assertEqual(moves["string_shot"]["effects"][0]["stageChanges"], [{"stat": "speed", "stages": -2}])
        self.assertEqual(moves["growl"]["effects"][0]["stageChanges"], [{"stat": "attack", "stages": -1}])
        self.assertEqual(moves["razor_leaf"]["critRatio"], 2)
        self.assertIn("slicing", moves["razor_leaf"]["flags"])

    def test_media_are_original_bytes_or_exact_authenticated_crops(self):
        for asset in self.pack["assets"]:
            original = self.source / asset["sourcePath"]
            destination = self.path.parent / asset["file"]
            data = destination.read_bytes()
            self.assertEqual(asset["sha256"], hashlib.sha256(data).hexdigest())
            self.assertEqual(asset["sourceSha256"], hashlib.sha256(original.read_bytes()).hexdigest())
            if "sourceRectPx" not in asset:
                self.assertEqual(data, original.read_bytes())
                continue
            with Image.open(original) as source_image, Image.open(destination) as target_image:
                source = source_image.convert("RGBA")
                target = target_image.convert("RGBA")
                rect = asset["sourceRectPx"]
                dest = asset.get("destinationRectPx", {"x": 0, "y": 0})
                scale = asset.get("nearestScale", 1)
                for y in range(rect["height"]):
                    for x in range(rect["width"]):
                        expected = source.getpixel((rect["x"] + x, rect["y"] + y))
                        for sy in range(scale):
                            for sx in range(scale):
                                actual = target.getpixel((dest["x"] + x * scale + sx, dest["y"] + y * scale + sy))
                                self.assertEqual(actual[3], expected[3])
                                if expected[3]:
                                    self.assertEqual(actual, expected)
                self.assertEqual(target.size, (32, 32))
                if "destinationRectPx" in asset:
                    self.assertEqual(set(target.getchannel("A").get_flattened_data()), {0, 255})

    def test_pickup_is_authentic_nearest_double_size_with_a_bottom_anchor(self):
        pickup = next(asset for asset in self.pack["assets"] if asset["id"] == "valbois-pickup-sheet")
        self.assertEqual(pickup.get("nearestScale"), 2)
        self.assertEqual(pickup["sourceRectPx"], {"x": 3, "y": 3, "width": 10, "height": 10})
        self.assertEqual(pickup["destinationRectPx"], {"x": 6, "y": 10, "width": 20, "height": 20})
        with Image.open(self.path.parent / pickup["file"]) as image:
            self.assertEqual(image.size, (32, 32))
            self.assertEqual(image.convert("RGBA").getbbox(), (6, 10, 26, 30))

    def test_bag_icons_follow_real_psdk_item_icon_ids_and_canonical_paths(self):
        assets = {asset["logicalPath"]: asset for asset in self.pack["assets"]}
        for item in ("poke_ball", "potion"):
            definition = json.loads((self.source / f"Data/Studio/items/{item}.json").read_text())
            icon = assets[f"data/pokemon/assets/items/{item}.png"]
            self.assertEqual(icon["sourcePath"], f"graphics/icons/{definition['icon']}.png")
            self.assertEqual((self.path.parent / icon["file"]).read_bytes(), (self.source / icon["sourcePath"]).read_bytes())


if __name__ == "__main__":
    unittest.main()

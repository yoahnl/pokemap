import json
import copy
from pathlib import Path
import unittest

from build_periodic_water_modules import placements, require_water_recipe
from source_conversion_fixtures import water_recipe


class WaterProfileTest(unittest.TestCase):
    def test_two_different_maps_use_declared_coverage_and_names(self):
        original = water_recipe()
        for width, depth, name in [(56, 82, 'first'), (24, 18, 'second')]:
            with self.subTest(map=name):
                profile = require_water_recipe({**original, 'id': name, 'mapId': name,
                    'width': width, 'depth': depth, 'modulePrefix': name + '-water-',
                    'MODULE_SIZES': [[16, 16], [8, 16], [16, 2], [8, 2]]})
                rows = placements(recipe=profile)
                self.assertTrue(all(row['id'].startswith(name + '-water-') for row in rows))
                cells = sum(int(row['modelId'].split('-')[-1].split('x')[0]) *
                            int(row['modelId'].split('x')[-1]) for row in rows)
                self.assertEqual(cells, width * depth)

    def test_explicit_recipe_is_required_and_strict(self):
        with self.assertRaises(TypeError):
            placements()
        for value in [None, {}, {'schemaVersion': 1}]:
            with self.assertRaises(ValueError):
                require_water_recipe(value)

    def test_malformed_geometry_and_policy_are_rejected_before_generation(self):
        original = water_recipe()
        invalid = [
            {'schemaVersion': True}, {'width': True}, {'width': 25},
            {'modulePrefix': '../outside/'}, {'ANIMATION_SHA256': 'unpinned'},
            {'ANIMATION_SPEED': 0}, {'durationSeconds': 5},
            {'uvTransform': [[0, 0, 0]]}, {'nativeOriginUv': [0, 0]},
            {'excludedMaterials': None}, {'extra': 'unsupported'},
            {'MODULE_SIZES': original['MODULE_SIZES'] + [original['MODULE_SIZES'][0]]},
        ]
        for changes in invalid:
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                require_water_recipe({**copy.deepcopy(original), **changes})

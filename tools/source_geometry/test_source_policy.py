from copy import deepcopy
from hashlib import sha256
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch
import json
import unittest
import zipfile

from source_policy import matches, policy_for_asset, read_source_policy, require_source_policy
from city_geometry import Surface, source_scene
from city_ground import floor_kind, ground_triangle, is_water
from city_models import category
from build_cities import build_city, map_groups
from build_routes import combine_sectors, route_source
from test_source_asset_conversion import source, texture


ROOT = Path(__file__).resolve().parents[2]


from source_conversion_fixtures import geometry_policy

def profile():
    return require_source_policy(geometry_policy())

def surface(material, height=0):
    return Surface('group', 'mesh', material, 'art.png', ['CLAMP', 'CLAMP'], 1,
        [[[0, height, 0, 0, 0, 1, 1, 1], [1, height, 0, 1, 0, 1, 1, 1],
          [0, height, 1, 0, 1, 1, 1, 1]]], True)


class SourcePolicyTest(unittest.TestCase):
    def test_draft_output_refuses_unsafe_ids_and_source_overlap_before_writes(self):
        with TemporaryDirectory() as directory:
            root = Path(directory)
            source_root = root / 'source'
            source_root.mkdir()
            city = {'id': 'garden', 'name': 'Garden', 'sourcePolicy': profile()}
            for identifier in ['../escape', '/absolute', 'nested/name', '']:
                destination = root / 'output'
                with patch('build_cities.source_scene', side_effect=AssertionError('Source read before preflight')):
                    with self.assertRaises(ValueError):
                        build_city({**city, 'id': identifier}, source_root, {}, destination)
                self.assertFalse(destination.exists())
            for destination in [source_root, source_root / 'output', root]:
                with self.assertRaises(ValueError):
                    build_city(city, source_root, {}, destination)
            self.assertFalse((source_root / 'output').exists())

    def test_two_material_profiles_are_independent_of_city_and_source_names(self):
        for identifier, name in [('arbitrary-garden', 'copper'), ('arbitrary-village', 'crystal')]:
            policy = profile()
            policy['ground']['floorRules'][0]['selector']['exact'] = [name]
            city = {'id': identifier, 'sourcePolicy': policy}
            value = surface(name, 3)
            self.assertEqual(floor_kind(city, value), 'terrain')
            self.assertTrue(ground_triangle(city, value, value.triangles[0]))
            self.assertIsNone(floor_kind(city, surface('undeclared-floor')))
            policy['ground']['maximumSourceHeight'] = 2
            self.assertFalse(ground_triangle(city, value, value.triangles[0]))

    def test_water_and_model_categories_use_only_declared_selectors(self):
        policy = profile()
        self.assertTrue(is_water(surface('liquid'), policy=policy))
        self.assertFalse(is_water(surface('undeclared-water'), policy=policy))
        self.assertEqual(category(surface('brick'), policy=policy), 'building')
        self.assertEqual(category(surface('house'), policy=policy), 'details')
        self.assertFalse(matches('anything', {}))
        with self.assertRaises(TypeError):
            is_water(surface('liquid'))

    def test_profiles_reject_unknown_operators_and_invalid_quotas(self):
        for change in [
            lambda p: p['ground']['floorRules'][0].update(selector={'python': ['True']}),
            lambda p: p['scene'].update(unitsPerCell=0),
            lambda p: p['scene'].update(unitsPerCell=True),
            lambda p: p['ground'].update(minimumNormalY=2),
            lambda p: p['output'].update(assetDirectory='../escape'),
        ]:
            value = profile()
            change(value)
            with self.assertRaises(ValueError):
                require_source_policy(value)
        with self.assertRaises(ValueError):
            policy_for_asset(profile(), {'unknown': {}})

    def test_scene_conversion_uses_explicit_units_and_node_roles(self):
        for identifier, units in [('first-source', 16), ('second-source', 8)]:
            policy = profile()
            policy['scene']['unitsPerCell'] = units
            data = source().replace(b'id="node"', b'id="ground-custom"')
            surfaces, images, provenance = source_scene(Path('.'), {'id': identifier, 'sha256': 'pinned'},
                archive_reader=lambda *_: (data, {'art.png': texture()}, {}), policy=policy)
            self.assertTrue(surfaces[0].terrain)
            self.assertEqual(surfaces[0].bounds[3], 16 / units)
            self.assertEqual(images['art.png'], texture())
            self.assertEqual(provenance['omitted'], [])
        with self.assertRaises(TypeError):
            source_scene(Path('.'), {'sha256': 'pinned'})

    def test_material_omission_requires_explicit_data(self):
        policy = profile()
        policy['scene']['omittedMaterials'] = {'exact': ['material']}
        surfaces, _, proof = source_scene(Path('.'), {'sha256': 'pinned'},
            archive_reader=lambda *_: (source(), {'art.png': texture()}, {}), policy=policy)
        self.assertEqual(surfaces, [])
        self.assertEqual(proof['omitted'][0]['material'], 'material')

    def test_clipping_is_explicit_for_any_source_identity(self):
        for identifier in ['first-source', 'other-source']:
            value = surface('copper')
            record = {'id': identifier, 'sourcePolicy': profile(), 'sourceCrop': {
                'planes': [{'axis': 0, 'boundary': .5, 'keepGreater': True}],
                'reason': 'Declared source region'}}
            with patch('build_routes.source_scene', return_value=([value], {}, {})):
                clipped, _, proof = route_source(Path('.'), record)
            self.assertGreaterEqual(clipped[0].bounds[0], .5)
            self.assertEqual(proof['sourceCrop'], record['sourceCrop'])

    def test_sector_composition_has_no_fixed_files_offsets_or_scene_ids(self):
        with TemporaryDirectory() as directory:
            folder = Path(directory)
            for name in ['alpha.dae', 'beta.dae']:
                (folder / name).write_bytes(source())
            recipe = {'sceneId': 'independent-scene', 'sceneName': 'Independent',
                'omittedMaterials': {}, 'omissionReason': 'None', 'sectors': [
                    {'daeFile': name, 'idPrefix': f'{index}-', 'rootNodeId': f'root-{index}',
                     'terrainNodeId': f'ground-{index}', 'translation': [index * 24, 0, 0]}
                    for index, name in enumerate(['alpha.dae', 'beta.dae'])]}
            data, omitted = combine_sectors(folder, recipe)
            self.assertIn(b'independent-scene', data)
            self.assertIn(b'24 0 0', data)
            self.assertEqual(omitted, [])
            recipe['sectors'][0]['daeFile'] = '../escape.dae'
            with self.assertRaises(ValueError):
                combine_sectors(folder, recipe)

    def test_two_project_drafts_emit_canonical_actions_without_touching_sources(self):
        with TemporaryDirectory() as directory:
            root = Path(directory)
            data = source().replace(b'id="node"', b'id="ground-custom"').replace(
                b'0 0 0 16 0 0 16 16 0 0 16 0', b'0 0 0 16 0 0 16 0 16 0 0 16')
            source_root = root / 'source'
            source_root.mkdir()
            archive = source_root / 'source.zip'
            with zipfile.ZipFile(archive, 'w') as zipped:
                zipped.writestr('scene.dae', data)
                zipped.writestr('art.png', texture())
            before = archive.read_bytes()
            record = {'id': 'source-id', 'name': 'Source', 'local_path': archive.name,
                'sha256': sha256(before).hexdigest(), 'page_url': 'https://example.invalid/source'}
            for identifier in ['aurora', 'clockwork']:
                policy = profile()
                policy['ground']['floorRules'][0]['selector']['exact'] = ['material']
                policy['output']['namespace'] = identifier
                city = {'id': 'garden', 'name': 'Garden', 'groupId': 'independent-group',
                    'sourceId': record['id'], 'sourcePolicy': policy}
                folder = root / identifier
                summary = build_city(city, source_root, record, folder)
                recipe = json.loads((folder / 'actions.json').read_text())
                actions = recipe['actions']
                self.assertEqual(recipe['schemaVersion'], 1)
                self.assertEqual(recipe['validation'], 'authoring')
                self.assertEqual(recipe['qa']['requiredMapGroupId'], city['groupId'])
                self.assertEqual(len(recipe['artifacts']), 1)
                self.assertTrue(any(action['actionId'] == 'asset.import' for action in actions))
                self.assertEqual(summary['mapId'], identifier + '-garden')
                self.assertTrue(any(action['actionId'] == 'map.create' for action in actions))
                self.assertTrue(any(action['actionId'] == 'map3d.navigation.configure' for action in actions))
            self.assertEqual(archive.read_bytes(), before)

    def test_catalogue_preserves_declared_groups_and_explicit_floor_overrides(self):
        catalogue = {'groups': [{'id': 'garden', 'name': 'Garden', 'type': 'special'}]}
        groups = map_groups(catalogue)
        self.assertEqual(groups, catalogue['groups'])
        self.assertIsNot(groups, catalogue['groups'])
        base = profile()
        result = policy_for_asset(base, {'ground': {'maximumSourceHeight': 3}})
        self.assertEqual(result['ground']['maximumSourceHeight'], 3)
        self.assertIsNone(base['ground']['maximumSourceHeight'])

if __name__ == '__main__':
    unittest.main()

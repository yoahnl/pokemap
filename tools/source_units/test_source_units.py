from copy import deepcopy
from hashlib import sha256
import json
import os
from pathlib import Path
import subprocess
import sys
import struct
from tempfile import TemporaryDirectory
import unittest
from unittest.mock import patch
import zipfile

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
sys.path[:0] = [str(HERE), str(HERE.parent / 'scripts')]
from source_conversion_fixtures import geometry_policy
from test_source_asset_conversion import source, texture
import extract_units as extraction
from test_nitro_materials import model_container, srt_container

TOOL = HERE / 'extract_units.py'


def dataset(root, identity, material, units=16):
    root.mkdir()
    data = source().replace(b'id="material"', f'id="material" name="{material}"'.encode())
    archive = root / 'shape.zip'
    with zipfile.ZipFile(archive, 'w') as output:
        output.writestr('shape.dae', data)
        output.writestr('art.png', texture())
    policy = geometry_policy()
    policy['scene']['unitsPerCell'] = units
    record = {'id': identity, 'name': identity, 'local_path': 'shape.zip',
              'sha256': sha256(archive.read_bytes()).hexdigest(), 'page_url': 'https://example.invalid/synthetic'}
    frame = {'mapId': 'map-' + identity, 'sourceToNativeTranslation': [3, 4, 5],
             'width': 12, 'depth': 13, 'levelHeight': .25}
    return {'id': identity, 'input': identity, 'record': record, 'sourcePolicy': policy, 'frame': frame}


def recipe(sources, materials):
    return {'schemaVersion': 1, 'id': 'independent-units', 'sources': deepcopy(sources),
            'units': [{'id': 'unit-' + row['id'], 'sourceId': row['id'], 'family': 'prop',
                       'selection': {'materials': [material], 'groups': [], 'triangleIndices': {},
                                     'allVerticesBounds': None},
                       'clipBounds': None, 'support': {'kind': 'literal', 'position': [0, 0, 0]},
                       'maxSize': [3, 3, 3], 'maxTriangles': 20,
                       'collision': {'kind': 'none'}, 'socketsSource': [], 'quarterTurns': 0,
                       'corner': None, 'animation': None}
                      for row, material in zip(sources, materials)],
            'provenance': {'kind': 'synthetic-independent-fixtures'}}


class SourceUnitsTest(unittest.TestCase):
    def test_failed_output_generation_cleans_only_its_staging_and_existing_output_is_preserved(self):
        with TemporaryDirectory() as temporary:
            root = Path(temporary)
            row = dataset(root / 'source', 'bronze', 'copper')
            declaration = recipe([row], ['copper'])
            inputs = {'bronze': root / 'source'}
            with patch.object(extraction, 'emit_unit', side_effect=ValueError('Injected generation failure')):
                with self.assertRaisesRegex(ValueError, 'Injected generation failure'):
                    extraction.build_recipe(declaration, inputs, root / 'kit')
            self.assertFalse((root / 'kit').exists())
            self.assertFalse(list(root.glob('.source-unit-*')))
            (root / 'kit').mkdir()
            (root / 'kit/preserve.bin').write_bytes(b'existing output')
            with self.assertRaisesRegex(ValueError, 'new directory'):
                extraction.build_recipe(declaration, inputs, root / 'kit')
            self.assertEqual((root / 'kit/preserve.bin').read_bytes(), b'existing output')

    def test_verified_inventory_image_is_used_when_path_changes_after_capture(self):
        with TemporaryDirectory() as temporary:
            root = Path(temporary)
            row = dataset(root / 'source', 'bronze', 'copper')
            declaration = recipe([row], ['copper'])
            nitro = root / 'nitro'
            (nitro / 'nitro-original').mkdir(parents=True)
            model = model_container().replace(b'water'.ljust(16, b'\0'), b'copper'.ljust(16, b'\0'))
            (nitro / 'model.bin').write_bytes(model)
            data = srt_container(3, [(0x20000000, 4096), (0x20000000, 4096),
                (0x20000000, 4096 << 16), (0x10000000, struct.pack('<hhh', 0, -1024, -2048)),
                (0x20000000, 0)], 'copper')
            (nitro / 'nitro-original/source.dat').write_bytes(data)
            inventory = json.dumps({'animations': [{'type': 'SRT0', 'tracks': [{'material': 'copper'}],
                'name': 'test', 'sha256': sha256(data).hexdigest(), 'extracted_files': ['source.dat'],
                'origins': [{'path': 'synthetic-format-resource'}]}]}).encode()
            (nitro / 'animation-inventory.json').write_bytes(inventory)
            declaration['units'][0]['animation'] = {
                'input': 'nitro', 'inventorySha256': sha256(inventory).hexdigest(),
                'frameRate': 30, 'frameRateEvidence': 'Measured synthetic scheduling',
                'modelSources': [{'relativePath': 'model.bin', 'sha256': sha256(model).hexdigest()}],
                'bindings': {'copper': {'sourceClip': 'test', 'sourceModelNames': ['pool'],
                                        'matrixModeEvidence': 'exact_source_model'}}, 'clipName': 'Explicit animation'}
            original_read = extraction.source_bytes

            def replace_after_capture(source_root, path, digest):
                captured = original_read(source_root, path, digest)
                if path == 'animation-inventory.json':
                    (source_root / path).write_text('{"animations":[]}')
                return captured

            with patch.object(extraction, 'source_bytes', side_effect=replace_after_capture):
                result = extraction.build_recipe(declaration, {'bronze': root / 'source', 'nitro': nitro}, root / 'kit')
            self.assertEqual(result['models'][0]['animation']['sourceEvidence'][0]['animationSha256'], sha256(data).hexdigest())
            document, _ = extraction.read_glb((root / 'kit' / result['models'][0]['file']).read_bytes())
            self.assertEqual(document['extras']['aveluneAnimationSource']['frameRate'], 30)
            self.assertEqual(document['extras']['aveluneMaterialAnimations']['clips'][0]['durationSeconds'], .1)

    def test_recipe_rejects_unknown_fields_ids_nonfinite_values_and_incomplete_clocks(self):
        with TemporaryDirectory() as temporary:
            row = dataset(Path(temporary) / 'source', 'bronze', 'copper')
            valid = recipe([row], ['copper'])
            for mutate in [lambda value: value.update({'fallbackProfile': 'hidden'}),
                           lambda value: value.update({'schemaVersion': True}),
                           lambda value: value['units'][0].update({'sourceId': 'missing'}),
                           lambda value: value['sources'][0]['frame'].update({'width': True}),
                           lambda value: value['units'][0].update({'id': '../escape'}),
                           lambda value: value['units'][0]['maxSize'].__setitem__(0, float('nan')),
                           lambda value: value['units'][0].update({'animation': {'frameRate': 30}}),
                           lambda value: value['units'][0]['selection'].update({'triangleIndices': {'other': [0]}})]:
                declaration = deepcopy(valid)
                mutate(declaration)
                with self.subTest(declaration=declaration), self.assertRaises(ValueError):
                    extraction.require_recipe(declaration)

    def test_stale_sources_symlinks_overlapping_outputs_and_empty_selection_publish_nothing(self):
        with TemporaryDirectory() as temporary:
            root = Path(temporary)
            row = dataset(root / 'source', 'bronze', 'copper')
            declaration = recipe([row], ['copper'])
            inputs = {'bronze': root / 'source'}
            with self.assertRaises(ValueError):
                extraction.build_recipe(declaration, inputs, root / 'source' / 'kit')
            declaration['sources'][0]['record']['sha256'] = 'f' * 64
            with self.assertRaisesRegex(ValueError, 'digest changed'):
                extraction.build_recipe(declaration, inputs, root / 'kit')
            declaration = recipe([row], ['copper'])
            original = root / 'source' / 'shape.zip'
            target = root / 'original.zip'
            original.rename(target)
            original.symlink_to(target)
            with self.assertRaisesRegex(ValueError, 'symbolic link'):
                extraction.build_recipe(declaration, inputs, root / 'kit')
            original.unlink()
            target.rename(original)
            declaration['units'][0]['selection']['groups'] = ['unrelated/sector']
            with self.assertRaisesRegex(ValueError, 'Empty source unit'):
                extraction.build_recipe(declaration, inputs, root / 'kit')
            self.assertFalse((root / 'kit').exists())
            self.assertFalse(list(root.glob('.source-unit-*')))

    def test_declared_rotation_moves_geometry_and_sockets_around_the_same_support(self):
        with TemporaryDirectory() as temporary:
            root = Path(temporary)
            row = dataset(root / 'source', 'bronze', 'copper')
            declaration = recipe([row], ['copper'])['units'][0]
            declaration['quarterTurns'] = 1
            declaration['socketsSource'] = [[1, 0, 0]]
            scene = extraction.load_scene(root / 'source', row)
            selected = extraction.selected_unit(scene, declaration)
            self.assertEqual(selected['socketsSource'], [[0, 0, -1]])
            self.assertEqual(extraction.entries_bounds(selected['entries']), [0, 0, -1, 0, 1, 0])

    def test_two_sources_are_selected_from_recipe_without_named_defaults(self):
        with TemporaryDirectory() as temporary:
            root = Path(temporary)
            first = dataset(root / 'bronze', 'bronze', 'copper')
            second = dataset(root / 'textile', 'textile', 'velvet', 8)
            declaration = recipe([first, second], ['copper', 'velvet'])
            path = root / 'recipe.json'
            path.write_text(json.dumps(declaration))
            before = {str(file.relative_to(root)): sha256(file.read_bytes()).hexdigest()
                      for source_root in [root / 'bronze', root / 'textile'] for file in source_root.iterdir()}
            result = subprocess.run([sys.executable, '-B', str(TOOL), '--recipe', str(path),
                '--input', 'bronze=' + str(root / 'bronze'), '--input', 'textile=' + str(root / 'textile'),
                '--output-root', str(root / 'kit')], capture_output=True, text=True,
                env={**os.environ, 'PYTHONPATH': str(HERE.parent / 'source_geometry')})
            self.assertEqual(result.returncode, 0, result.stderr)
            manifest = json.loads((root / 'kit/manifest.json').read_text())
            self.assertEqual([row['id'] for row in manifest['models']], ['unit-bronze', 'unit-textile'])
            self.assertEqual(manifest['models'][0]['sourceBoundsCells'], [0, 0, 0, 1, 1, 0])
            self.assertEqual(manifest['models'][1]['sourceBoundsCells'], [0, 0, 0, 2, 2, 0])
            self.assertEqual([row['triangleCount'] for row in manifest['models']], [2, 2])
            self.assertEqual(before, {str(file.relative_to(root)): sha256(file.read_bytes()).hexdigest()
                      for source_root in [root / 'bronze', root / 'textile'] for file in source_root.iterdir()})
            for row in manifest['models']:
                self.assertEqual(sha256((root / 'kit' / row['file']).read_bytes()).hexdigest(), row['sha256'])
                self.assertEqual(row['textureSources'][0]['sha256'], sha256(texture()).hexdigest())


if __name__ == '__main__':
    unittest.main()

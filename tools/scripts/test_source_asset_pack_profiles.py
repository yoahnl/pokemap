from copy import deepcopy
from hashlib import sha256
from pathlib import Path
from tempfile import TemporaryDirectory
import csv
import json
import unittest
import zipfile

from convert_source_asset_pack import extract, require_pack_recipe
from test_source_asset_conversion import source, texture


def fixture(root, identifier):
    root.mkdir()
    archive = root / 'mesh.zip'
    with zipfile.ZipFile(archive, 'w') as target:
        target.writestr('mesh.dae', source())
        target.writestr('art.png', texture())
    with (root / 'catalogue.csv').open('w') as output:
        writer = csv.DictWriter(output, fieldnames=['id', 'name', 'local_path', 'page_url'])
        writer.writeheader()
        writer.writerow({'id': identifier, 'name': identifier, 'local_path': archive.name,
                         'page_url': 'https://example.invalid/source'})
    return {'schemaVersion': 1, 'id': identifier, 'sourceUnitsPerCell': 16,
        'manifestFile': 'pack.json', 'omittedTextures': [],
        'sources': [{'id': identifier, 'sha256': sha256(archive.read_bytes()).hexdigest()}],
        'models': [{'sourceId': identifier, 'id': identifier + '-model',
            'label': 'Model', 'category': 'Objects', 'file': identifier + '.glb', 'selections': None}],
        'textures': [], 'atlases': [], 'provenance': {'fixture': True}}


class AssetPackProfileTest(unittest.TestCase):
    def test_two_unrelated_sources_produce_deterministic_packs_without_source_writes(self):
        with TemporaryDirectory() as temporary:
            root = Path(temporary)
            for identifier in ['aurora', 'clockwork']:
                source_root = root / identifier
                recipe = fixture(source_root, identifier)
                before = {p.name: p.read_bytes() for p in source_root.iterdir()}
                outputs = []
                for index in range(2):
                    destination = root / f'{identifier}-{index}'
                    manifest = extract(source_root, destination, recipe=recipe)
                    self.assertEqual(manifest['models'][0]['id'], identifier + '-model')
                    self.assertEqual(manifest['recipe'], recipe)
                    outputs.append({p.name: p.read_bytes() for p in destination.iterdir()})
                self.assertEqual(outputs[0], outputs[1])
                self.assertEqual({p.name: p.read_bytes() for p in source_root.iterdir()}, before)

    def test_recipe_is_required_and_unknown_selectors_or_duplicate_destinations_fail(self):
        with TemporaryDirectory() as temporary:
            root = Path(temporary)
            recipe = fixture(root / 'source', 'custom')
            with self.assertRaises(TypeError):
                extract(root / 'source', root / 'output')
            for change in [
                lambda r: r['models'][0].update(selections=[{'geometry': 'geometry', 'materials': {'art': 'material'}, 'python': 'True'}]),
                lambda r: r['models'].append(deepcopy(r['models'][0])),
                lambda r: r['models'][0].update(file='../outside.glb'),
                lambda r: r.update(sourceUnitsPerCell=True),
                lambda r: r['sources'][0].update(sha256='unqualified'),
            ]:
                invalid = deepcopy(recipe)
                change(invalid)
                with self.assertRaises(ValueError):
                    require_pack_recipe(invalid)

    def test_changed_sources_and_occupied_outputs_do_not_publish_partial_results(self):
        with TemporaryDirectory() as temporary:
            root = Path(temporary)
            recipe = fixture(root / 'source', 'custom')
            (root / 'source/mesh.zip').write_bytes(b'changed')
            with self.assertRaisesRegex(ValueError, 'digest mismatch'):
                extract(root / 'source', root / 'output', recipe=recipe)
            self.assertFalse((root / 'output').exists())
            destination = root / 'occupied'
            destination.mkdir()
            (destination / 'preserved').write_bytes(b'content')
            with self.assertRaises(ValueError):
                extract(root / 'source', destination, recipe=recipe)
            self.assertEqual((destination / 'preserved').read_bytes(), b'content')

    def test_source_archive_cannot_escape_its_declared_root(self):
        with TemporaryDirectory() as temporary:
            root = Path(temporary)
            recipe = fixture(root / 'source', 'custom')
            outside = root / 'outside.zip'
            outside.write_bytes((root / 'source/mesh.zip').read_bytes())
            text = (root / 'source/catalogue.csv').read_text().replace('mesh.zip', '../outside.zip')
            (root / 'source/catalogue.csv').write_text(text)
            with self.assertRaisesRegex(ValueError, 'escapes'):
                extract(root / 'source', root / 'output', recipe=recipe)
            self.assertFalse((root / 'output').exists())



if __name__ == '__main__':
    unittest.main()

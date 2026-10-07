import importlib.util
import json
from pathlib import Path
import shutil
import struct
import tempfile
import unittest


SCRIPT = Path(__file__).with_name('extract_hgss_small_map_assets.py')
SPEC = importlib.util.spec_from_file_location('small_map_assets', SCRIPT)
ASSETS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ASSETS)
SOURCE = SCRIPT.parents[2] / 'apps/hgss_render_lab/assets/city/olivine'


def read_glb(path):
    data = path.read_bytes()
    magic, version, length = struct.unpack_from('<III', data)
    if (magic, version, length) != (0x46546C67, 2, len(data)):
        raise AssertionError('Invalid GLB header')
    json_length, json_type = struct.unpack_from('<II', data, 12)
    if json_type != 0x4E4F534A:
        raise AssertionError('Missing JSON chunk')
    document = json.loads(data[20:20 + json_length])
    offset = 20 + json_length
    binary_length, binary_type = struct.unpack_from('<II', data, offset)
    if binary_type != 0x004E4942 or offset + 8 + binary_length != len(data):
        raise AssertionError('Invalid embedded binary chunk')
    return document, data[offset + 8:]


def positions(document, binary):
    result = []
    for primitive in document['meshes'][0]['primitives']:
        accessor = document['accessors'][primitive['attributes']['POSITION']]
        view = document['bufferViews'][accessor['bufferView']]
        offset = view['byteOffset']
        result.extend(struct.unpack_from('<fff', binary, offset + i * 12)
                      for i in range(accessor['count']))
    return result


class SmallMapAssetsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temporary = tempfile.TemporaryDirectory()
        cls.output = Path(cls.temporary.name) / 'output'
        cls.provenance = ASSETS.extract(SOURCE, cls.output)

    @classmethod
    def tearDownClass(cls):
        cls.temporary.cleanup()

    def test_standalone_opaque_models_preserve_texture_bytes(self):
        for model in self.provenance['models']:
            document, binary = read_glb(self.output / model['file'])
            self.assertNotIn('uri', document['buffers'][0])
            self.assertEqual(document['extensionsRequired'], ['KHR_materials_unlit'])
            for index, image in enumerate(document['images']):
                self.assertNotIn('uri', image)
                view = document['bufferViews'][image['bufferView']]
                embedded = binary[view['byteOffset']:view['byteOffset'] + view['byteLength']]
                material = document['materials'][index]
                self.assertEqual(embedded, (SOURCE / material['name']).read_bytes())
                self.assertEqual(material['alphaMode'], 'OPAQUE')
                self.assertFalse(material.get('doubleSided', False))
            vertices = positions(document, binary)
            self.assertEqual(len(vertices) // 3, model['triangleCount'])
            for expected, actual in zip(model['bounds'], ASSETS.bounds(vertices)):
                self.assertAlmostEqual(expected, actual, places=5)

    def test_cliff_repeat_has_matching_source_edge_profiles(self):
        document, binary = read_glb(self.output / 'cliff_straight.glb')
        vertices = positions(document, binary)
        profiles = [{tuple(round(v[a], 5) for a in (1, 2)) for v in vertices
                     if abs(v[0] - edge) < 1e-5} for edge in (0, 1)]
        self.assertEqual(profiles[0], profiles[1])
        self.assertEqual(len(profiles[0]), 4)
        self.assertEqual(len(vertices) // 3, 6)

    def test_stair_center_matches_continuous_two_stage_height(self):
        document, binary = read_glb(self.output / 'stairs.glb')
        vertices = positions(document, binary)
        for vertex in vertices:
            if 0.31249 <= vertex[0] <= 1.68751 and abs(vertex[1] + vertex[2] - 1) < 1e-4:
                self.assertAlmostEqual(vertex[1], 1 - vertex[2], places=5)
        walkable = [v for v in vertices if 0.31249 <= v[0] <= 1.68751
                    and abs(v[1] + v[2] - 1) < 1e-4]
        self.assertEqual(len(walkable), 12)
        layout = json.loads((self.output / 'layout.json').read_text())
        first, second = layout['ramps']
        self.assertEqual(first['rect'][3], second['rect'][1])
        self.assertEqual(first['heightSouth'], second['heightNorth'])
        self.assertEqual((first['heightNorth'], second['heightSouth']), (2, 0))

    def test_every_extracted_position_and_uv_matches_recorded_source(self):
        scene = json.loads((SOURCE / 'scene.json').read_text())
        nodes = {node['name']: node for node in scene['nodes']}
        for model in self.provenance['models']:
            if not model['sourceSelections']:
                continue
            expected = []
            for selection in model['sourceSelections']:
                surface = next(s for s in nodes[selection['nodeName']]['surfaces']
                               if s['materialId'] == selection['materialId'])
                for index in selection['triangleIndices']:
                    expected.extend(struct.unpack('<fffff', struct.pack('<fffff',
                                          *[v[a] + selection['translation'][a] for a in range(3)], *v[3:5]))
                                    for v in surface['vertices'][index * 3:index * 3 + 3])
            document, binary = read_glb(self.output / model['file'])
            actual = []
            for primitive in document['meshes'][0]['primitives']:
                decoded = []
                for attribute, size in [('POSITION', 3), ('TEXCOORD_0', 2)]:
                    accessor = document['accessors'][primitive['attributes'][attribute]]
                    offset = document['bufferViews'][accessor['bufferView']]['byteOffset']
                    decoded.append([struct.unpack_from('<' + 'f' * size, binary, offset + i * size * 4)
                                    for i in range(accessor['count'])])
                actual.extend(position + uv for position, uv in zip(*decoded))
            self.assertCountEqual(expected, actual)

    def test_outputs_are_repeatable(self):
        other = Path(self.temporary.name) / 'other'
        ASSETS.extract(SOURCE, other)
        for path in self.output.iterdir():
            self.assertEqual(path.read_bytes(), (other / path.name).read_bytes())

    def test_source_hash_drift_is_rejected(self):
        copied = Path(self.temporary.name) / 'copied'
        shutil.copytree(SOURCE.parent, copied)
        with (copied / 'olivine' / 'grass01gs.png').open('ab') as image:
            image.write(b'drift')
        with self.assertRaisesRegex(ValueError, 'hash mismatch: grass01gs.png'):
            ASSETS.extract(copied / 'olivine', Path(self.temporary.name) / 'rejected')

    def test_output_cannot_mutate_read_only_source(self):
        for target in (SOURCE, SOURCE / 'output', SOURCE.parent):
            with self.subTest(target=target):
                with self.assertRaisesRegex(ValueError, 'outside the read-only source'):
                    ASSETS.extract(SOURCE, target)

    def test_output_symlinks_are_rejected_before_any_write(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            copied = root / 'source'
            shutil.copytree(SOURCE.parent, copied)
            before = {path.relative_to(copied): path.read_bytes()
                      for path in copied.rglob('*') if path.is_file()}
            for filename in ('cliff_straight.glb', 'stairs.glb', 'house.glb',
                             'terrain.glb', 'layout.json', 'provenance.json'):
                with self.subTest(filename=filename):
                    output = root / filename.replace('.', '_')
                    output.mkdir()
                    (output / filename).symlink_to(copied / 'olivine' / 'scene.json')
                    with self.assertRaisesRegex(ValueError, 'symlink'):
                        ASSETS.extract(copied / 'olivine', output)
                    self.assertEqual([path.name for path in output.iterdir()], [filename])
                    self.assertEqual(before, {path.relative_to(copied): path.read_bytes()
                                              for path in copied.rglob('*') if path.is_file()})


if __name__ == '__main__':
    unittest.main()

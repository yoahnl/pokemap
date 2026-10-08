import importlib.util
from io import BytesIO
import json
from pathlib import Path
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET
import zipfile

from PIL import Image

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).parent))
from test_convert_bw2_door_asset import accessor, read_glb, transform

SCRIPT = Path(__file__).with_name('convert_bw2_windmill_asset.py')
ARCHIVE = Path('/Users/karim/Downloads/pokemon-black2-white2-models-sans-pokemon/archives/map-objects/windmill-with-reflection--582888.zip')
NS = {'c': 'http://www.collada.org/2005/11/COLLADASchema'}
CONVERTER = None
if SCRIPT.exists():
    spec = importlib.util.spec_from_file_location('windmill', SCRIPT)
    CONVERTER = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(CONVERTER)


class WindmillConverterTest(unittest.TestCase):
    def setUp(self):
        if not ARCHIVE.exists():
            self.skipTest('Authoritative local BW2 archive unavailable')
        with zipfile.ZipFile(ARCHIVE) as archive:
            self.source = archive.read('c7_windmill_01.dae')
            self.textures = {n: archive.read(n) for n in archive.namelist() if n.endswith('.png')}

    def convert(self, source=None, textures=None):
        self.assertIsNotNone(CONVERTER, 'Native rigid windmill conversion is unavailable')
        return CONVERTER.convert_dae(source or self.source, textures or self.textures)

    def test_native_parts_and_clip_convert_without_skin_or_reflection(self):
        data, receipt = self.convert()
        document, binary = read_glb(data)
        self.assertNotIn('skins', document)
        self.assertEqual([n['name'] for n in document['nodes']], ['native_units_to_map_cells', 'joint0', 'joint1', 'joint3'])
        self.assertTrue(all('matrix' not in n and 'skin' not in n for n in document['nodes']))
        self.assertEqual(receipt['triangleCount'], 138)
        self.assertEqual(receipt['sourceTriangleCount'], 256)
        self.assertEqual(sum(len(m['primitives']) for m in document['meshes']), 3)
        self.assertEqual(document['animations'][0]['name'], 'c7_windmill_01')
        self.assertEqual(len(document['animations']), 1)
        channels = document['animations'][0]['channels']
        self.assertEqual({c['target']['node'] for c in channels}, {1, 2, 3})
        self.assertEqual(receipt['omitted'], [{'joint': 'joint2', 'reason': 'Native below-ground reflection', 'triangleCount': 70}, {'material': 'material3', 'reason': 'Native below-ground roof reflection', 'triangleCount': 12}, {'material': 'material5', 'reason': 'Native below-ground building reflection', 'triangleCount': 28}, {'texture': 'h_kage.png', 'reason': 'Baked translucent shadow', 'triangleCount': 8}])
        self.assertGreaterEqual(receipt['boundsCells']['building'][1], 0)
        rotation = next(c for c in channels if c['target'] == {'node': 2, 'path': 'rotation'})
        sampler = document['animations'][0]['samplers'][rotation['sampler']]
        times = accessor(document, binary, sampler['input'])
        values = accessor(document, binary, sampler['output'])
        self.assertEqual(len(times), 120)
        self.assertAlmostEqual(times[-1][0], 119 / 60, places=6)
        self.assertAlmostEqual(abs(sum(a * b for a, b in zip(values[0], values[-1]))), 1)
        self.assertNotEqual(values[0], values[30])

    def test_original_png_bytes_and_closed_material_profile(self):
        document, binary = read_glb(self.convert()[0])
        self.assertEqual({m['name'] for m in document['materials']}, {'c7wind1.png', 'c7wind2.png', 'c7wind3.png'})
        for material in document['materials']:
            texture = document['textures'][material['pbrMetallicRoughness']['baseColorTexture']['index']]
            image = document['images'][texture['source']]
            view = document['bufferViews'][image['bufferView']]
            self.assertEqual(binary[view['byteOffset']:view['byteOffset'] + view['byteLength']], self.textures[material['name']])
            self.assertIn(material['alphaMode'], ('OPAQUE', 'MASK'))
            if material['alphaMode'] == 'MASK':
                self.assertEqual(material['alphaCutoff'], .5)
        self.assertTrue(all(s['wrapS'] in (10497, 33071) and s['wrapT'] in (10497, 33071) for s in document['samplers']))

    def test_every_original_key_preserves_rigid_vertex_pose(self):
        data, receipt = self.convert()
        document, binary = read_glb(data)
        root = ET.fromstring(self.source)
        arrays = {n.get('id'): n for n in root.findall('.//c:source', NS)}
        animation = document['animations'][0]
        for node_index in (2, 3):
            node = document['nodes'][node_index]
            original = list(map(float, arrays[f'anim0-{node["name"]}-matrix'].findtext('c:float_array', namespaces=NS).split()))
            channels = {c['target']['path']: animation['samplers'][c['sampler']] for c in animation['channels'] if c['target']['node'] == node_index}
            keys = {path: accessor(document, binary, sampler['output']) for path, sampler in channels.items()}
            for primitive in document['meshes'][node['mesh']]['primitives']:
                positions = accessor(document, binary, primitive['attributes']['POSITION'])
                for frame in range(120):
                    matrix = original[frame * 16:(frame + 1) * 16]
                    for position in positions:
                        expected = [sum(matrix[a * 4 + b] * position[b] for b in range(3)) + matrix[a * 4 + 3] for a in range(3)]
                        actual = transform(position, *(keys[path][frame] for path in ('translation', 'rotation', 'scale')))
                        for x, y in zip(actual, expected):
                            self.assertAlmostEqual(x / 16, y / 16, places=5)
        self.assertLess(max(c['maxMidpointPositionErrorMapUnits'] for c in receipt['channels']), .0011)

    def test_rejects_nonrigid_weights_and_cross_joint_polygons(self):
        root = ET.fromstring(self.source)
        weights = root.find('.//c:vertex_weights', NS)
        counts = weights.find('c:vcount', NS)
        counts.text = '2 ' + ' '.join(counts.text.split()[1:])
        with self.assertRaisesRegex(ValueError, 'one influence'):
            self.convert(ET.tostring(root))
        root = ET.fromstring(self.source)
        values = root.find('.//c:vertex_weights/c:v', NS)
        parts = values.text.split()
        parts[0] = '3' if parts[0] != '3' else '1'
        values.text = ' '.join(parts)
        with self.assertRaisesRegex(ValueError, 'cross-joint'):
            self.convert(ET.tostring(root))

    def test_rejects_translucent_png_unsupported_wrap_and_nontrs_key(self):
        image = Image.open(BytesIO(self.textures['c7wind1.png'])).convert('RGBA')
        image.putpixel((0, 0), (255, 255, 255, 128))
        output = BytesIO()
        image.save(output, format='PNG')
        with self.assertRaisesRegex(ValueError, 'translucent'):
            self.convert(textures={**self.textures, 'c7wind1.png': output.getvalue()})
        with self.assertRaisesRegex(ValueError, 'wrap|WRAP'):
            self.convert(self.source.replace(b'<wrap_s>CLAMP</wrap_s>', b'<wrap_s>MIRROR</wrap_s>', 1))
        root = ET.fromstring(self.source)
        array = root.find('.//c:source[@id="anim0-joint1-matrix"]/c:float_array', NS)
        parts = array.text.split()
        parts[1] = '0.2'
        array.text = ' '.join(parts)
        with self.assertRaisesRegex(ValueError, 'shear'):
            self.convert(ET.tostring(root))

    def test_rerunnable_archive_conversion_records_source_hashes(self):
        self.assertIsNotNone(CONVERTER)
        with tempfile.TemporaryDirectory() as directory:
            root = ARCHIVE.parents[2]
            CONVERTER.convert(root, Path(directory))
            first = (Path(directory) / CONVERTER.OUTPUT).read_bytes()
            provenance = json.loads((Path(directory) / CONVERTER.PROVENANCE).read_text())
            CONVERTER.convert(root, Path(directory))
            self.assertEqual(first, (Path(directory) / CONVERTER.OUTPUT).read_bytes())
            self.assertEqual(provenance['source']['archiveSha256'], CONVERTER.ARCHIVE_SHA256)
            self.assertEqual(len(provenance['source']['members']), 5)
            self.assertEqual(provenance['triangleCount'], 138)


if __name__ == '__main__':
    unittest.main()

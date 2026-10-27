from collections import Counter, defaultdict
from copy import deepcopy
from hashlib import sha256
from io import BytesIO
import json
import math
from pathlib import Path
import struct
import tempfile
import unittest

from PIL import Image

import generate
from validate_glb import cross, decode_glb, dot, inspect_bytes, inspect_file, ray_z_hits


QA_ROOT = Path.home() / 'Library/Caches/AveluneQA/a3d-01-house-tree/tests'


def encoded(document, binary):
    payload = json.dumps(document, separators=(',', ':')).encode()
    payload += b' ' * (-len(payload) % 4)
    binary += b'\0' * (-len(binary) % 4)
    return (struct.pack('<III', 0x46546C67, 2, 28 + len(payload) + len(binary))
            + struct.pack('<II', len(payload), 0x4E4F534A) + payload
            + struct.pack('<II', len(binary), 0x004E4942) + binary)


class PilotAssetsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        QA_ROOT.mkdir(parents=True, exist_ok=True)
        cls.temporary = tempfile.TemporaryDirectory(prefix='structural-', dir=QA_ROOT)
        cls.addClassCleanup(cls.temporary.cleanup)
        cls.root = Path(cls.temporary.name)
        cls.parameters = json.loads(Path(generate.__file__).with_name('parameters.json').read_text())
        cls.exporter_before = sha256((generate.REPOSITORY / 'tools/scripts/convert_source_asset_pack.py').read_bytes()).hexdigest()
        cls.first = cls.root / 'first'
        cls.second = cls.root / 'second'
        cls.manifest = generate.generate(deepcopy(cls.parameters), cls.first)
        generate.generate(deepcopy(cls.parameters), cls.second)
        cls.models = {key: inspect_file(cls.first / cls.parameters[key]['file']) for key in ('house', 'tree')}

    def test_exactly_two_nonempty_unique_models(self):
        paths = sorted(self.first.glob('*.glb'))
        self.assertEqual([path.name for path in paths], ['japanese_house.glb', 'volumetric_tree.glb'])
        self.assertEqual(len({sha256(path.read_bytes()).hexdigest() for path in paths}), 2)
        self.assertTrue(all(path.stat().st_size > 1000 for path in paths))

    def test_two_generations_are_byte_identical_for_every_output(self):
        first = {p.name: sha256(p.read_bytes()).hexdigest() for p in self.first.iterdir()}
        second = {p.name: sha256(p.read_bytes()).hexdigest() for p in self.second.iterdir()}
        self.assertEqual(first, second)

    def test_manifest_matches_independent_binary_inspection(self):
        for asset in self.manifest['assets']:
            result = inspect_file(self.first / asset['file'])
            self.assertEqual(asset['sha256'], result['sha256'])
            self.assertEqual(asset['sizeBytes'], result['bytes'])
            self.assertEqual(asset['triangleCount'], result['triangles'])
            self.assertEqual(asset['materialCount'], len(result['materials']))
            self.assertEqual(asset['pivot'], [0, 0, 0])
            self.assertEqual(sorted(texture['sha256'] for texture in asset['textures']),
                             sorted(image['sha256'] for image in result['images']))
            for texture in asset['textures']:
                self.assertEqual(sha256((self.first / texture['file']).read_bytes()).hexdigest(), texture['sha256'])
            for a, b in zip(asset['bounds'], result['bounds']):
                self.assertAlmostEqual(a, b, places=5)

    def test_triangles_and_material_budgets(self):
        self.assertTrue(600 <= self.models['house']['triangles'] <= 2000)
        self.assertTrue(2 <= len(self.models['house']['materials']) <= 4)
        self.assertTrue(150 <= self.models['tree']['triangles'] <= 500)
        self.assertTrue(1 <= len(self.models['tree']['materials']) <= 2)

    def test_model_envelopes_and_ground_alignment_preserve_native_coordinates(self):
        source_bounds = {
            'house': [-2.875, .125, -2.375, 2.875, 5.626220703125, 2.125],
            'tree': [-2, 0, -2.5478515625, 2, 3.083984375, 0],
        }
        for name, result in self.models.items():
            bounds = source_bounds[name]
            for axis in range(3):
                self.assertGreaterEqual(result['bounds'][axis] + 1e-6, bounds[axis])
                self.assertLessEqual(result['bounds'][axis + 3] - 1e-6, bounds[axis + 3])
        self.assertAlmostEqual(self.models['house']['bounds'][1], .125, places=5)
        self.assertAlmostEqual(self.models['tree']['bounds'][1], 0, places=5)
        self.assertLessEqual(self.models['tree']['bounds'][5], 0)

    def test_entire_door_plane_visible_without_added_closed_panel(self):
        triangles = [triangle for primitive in self.models['house']['primitives'] for triangle in primitive['triangles']]
        for ix in range(19):
            x = -1.625457763671875 + .005 + (1.25 - .01) * ix / 18
            for iy in range(23):
                y = .123779296875 + .01 + (1.56097412109375 - .02) * iy / 22
                blockers = [hit for triangle in triangles if (hit := ray_z_hits(triangle, x, y)) is not None and hit > 1.21734619140625 + 1e-5]
                self.assertEqual(blockers, [], f'Door obscured at x={x}, y={y}, z={blockers}')

    def test_window_material_and_existing_glow_rectangles_preserved(self):
        glass = next(p for p in self.models['house']['primitives'] if p['name'] == 'h_mado')
        for x, y, z in [(.5625, 1.15625, 1.46875), (1.1875, 1.15625, 1.46875),
                        (-.46875, 3.0640869140625, 1.4375), (.46875, 3.0640869140625, 1.4375)]:
            hits = [hit for triangle in glass['triangles'] if (hit := ray_z_hits(triangle, x, y)) is not None]
            self.assertTrue(any(abs(hit - z) < 1e-5 for hit in hits), (x, y, z, hits))
        self.assertTrue(all(0 <= value <= 1 for uv in glass['uvs'] for value in uv))

    def test_foliage_is_multiple_closed_solid_masses(self):
        foliage = next(p for p in self.models['tree']['primitives'] if p['name'] == 'foliage')
        edges = Counter()
        graph = defaultdict(set)
        volume = 0
        for a, b, c in foliage['triangles']:
            volume += dot(a, cross(b, c)) / 6
            points = [tuple(round(value, 5) for value in point) for point in (a, b, c)]
            for p, q in zip(points, points[1:] + points[:1]):
                edges[tuple(sorted((p, q)))] += 1
                graph[p].add(q)
                graph[q].add(p)
        self.assertTrue(all(count == 2 for count in edges.values()))
        self.assertGreater(volume, 2)
        remaining = set(graph)
        components = 0
        while remaining:
            components += 1
            pending = [remaining.pop()]
            while pending:
                for point in graph[pending.pop()] & remaining:
                    remaining.remove(point)
                    pending.append(point)
        self.assertEqual(components, len(self.parameters['tree']['crowns']))
        self.assertGreaterEqual(components, 4)
        for axis in range(3):
            self.assertGreater(max(p[axis] for p in foliage['positions']) - min(p[axis] for p in foliage['positions']), 1)

    def test_original_exporter_is_unchanged(self):
        current = sha256((generate.REPOSITORY / 'tools/scripts/convert_source_asset_pack.py').read_bytes()).hexdigest()
        self.assertEqual(current, self.exporter_before)

    def test_parameter_validation_rejects_invalid_schema_and_geometry(self):
        cases = [('schemaVersion', 999), ('seed', 'random')]
        for name, value in cases:
            parameters = deepcopy(self.parameters)
            parameters[name] = value
            with self.subTest(name=name), self.assertRaises(ValueError):
                generate.generate(parameters, self.root / f'invalid-{name}')
        for name, field, value in [('house', 'roofRows', 0), ('house', 'roofColumns', -1),
                                   ('tree', 'segments', 2), ('tree', 'rings', 1),
                                   ('tree', 'textureSize', 1024), ('house', 'roofRidgeY', math.nan)]:
            parameters = deepcopy(self.parameters)
            parameters[name][field] = value
            with self.subTest(field=field), self.assertRaises(ValueError):
                generate.generate(parameters, self.root / f'invalid-{field}')

    def test_export_rejects_degenerate_and_nonfinite_triangles(self):
        stream = BytesIO()
        Image.new('RGB', (2, 2), (80, 90, 100)).save(stream, format='PNG')
        for label, points in [('degenerate', [(0, 0, 0)] * 3),
                              ('nonfinite', [(0, 0, 0), (1, 0, 0), (0, math.inf, 0)])]:
            mesh = generate.Mesh()
            mesh.triangle('test', *points)
            with self.subTest(label=label), self.assertRaises(ValueError):
                generate.write_preserved_model(self.root / f'{label}.glb', mesh, {'test': stream.getvalue()})

    def test_vertex_tint_cannot_exceed_native_color_range(self):
        for color in [(1.014, 1.014, 1.014), (1.01, 1.01, 1.01), (-.01, 0, 0), (math.nan, 0, 0)]:
            with self.subTest(color=color), self.assertRaises(ValueError):
                generate.Mesh().triangle('tint', (0, 0, 0), (1, 0, 0), (0, 1, 0), color=color)

    def test_invalid_parameters_do_not_create_output_directory(self):
        for name in ('../escape.glb', self.parameters['house']['file']):
            parameters = deepcopy(self.parameters)
            parameters['tree']['file'] = name
            destination = self.root / 'invalid-filename'
            with self.subTest(name=name), self.assertRaises(ValueError):
                generate.generate(parameters, destination)
            self.assertFalse(destination.exists())

    def test_validator_rejects_corrupt_header_truncation_and_nan_positions(self):
        data = (self.first / self.parameters['tree']['file']).read_bytes()
        for invalid in (b'invalid', data[:-1], b'bad!' + data[4:]):
            with self.assertRaises(ValueError):
                inspect_bytes(invalid)
        document, binary = decode_glb(data)
        accessor = document['accessors'][document['meshes'][0]['primitives'][0]['attributes']['POSITION']]
        view = document['bufferViews'][accessor['bufferView']]
        binary = bytearray(binary)
        struct.pack_into('<f', binary, view.get('byteOffset', 0), math.nan)
        with self.assertRaisesRegex(ValueError, 'Nonfinite'):
            inspect_bytes(encoded(document, binary))

    def test_rejected_envelope_preserves_existing_delivery_and_creates_nothing(self):
        before = {p.name: p.read_bytes() for p in self.first.iterdir()}
        for name, field, value in [('house', 'roofRidgeY', 100),
                                   ('tree', 'trunkTop', [0, 100, -1.27])]:
            parameters = deepcopy(self.parameters)
            parameters[name][field] = value
            with self.subTest(name=name), self.assertRaisesRegex(ValueError, 'envelope'):
                generate.generate(parameters, self.first)
            self.assertEqual(before, {p.name: p.read_bytes() for p in self.first.iterdir()})
            destination = self.root / f'invalid-envelope-{name}'
            with self.assertRaisesRegex(ValueError, 'envelope'):
                generate.generate(parameters, destination)
            self.assertFalse(destination.exists())

    def test_validator_rejects_ignored_render_dependencies_and_bad_indices(self):
        data = (self.first / self.parameters['tree']['file']).read_bytes()
        for mutation in ('metallic', 'animation', 'indices'):
            document, binary = decode_glb(data)
            if mutation == 'metallic':
                document['materials'][0]['pbrMetallicRoughness']['metallicFactor'] = 1
            elif mutation == 'animation':
                document['animations'] = [{}]
            else:
                primitive = document['meshes'][0]['primitives'][0]
                primitive['indices'] = primitive['attributes']['POSITION']
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                inspect_bytes(encoded(document, binary))


if __name__ == '__main__':
    unittest.main()

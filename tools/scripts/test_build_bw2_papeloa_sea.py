from io import BytesIO
from collections import defaultdict
from copy import deepcopy
from pathlib import Path
from tempfile import TemporaryDirectory
from types import SimpleNamespace
import sys
import unittest

from PIL import Image

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))

from build_bw2_papeloa_sea import (ANIMATION_SHA256, animated_sea_document, module_geometry, placements,
                                 polygon_area, sea_surface_footprints, sea_surface_geometry,
                                 subtract_footprints, surface_uv_transform)
from convert_bw2_village_assets import emit_model
from rigidify_bw2_animation import accessor_rows, read_glb


def source_surface(z_offset=0, uv_offset=0):
    vertices = [[x, -5.6875, z + z_offset, x / 4, (z + z_offset) / 4 + 1 + uv_offset, 1, 1, 1]
                for x, z in [(-16, -16), (-16, 16), (16, 16), (16, -16)]]
    return SimpleNamespace(triangles=[[vertices[0], vertices[1], vertices[2]],
                                    [vertices[0], vertices[2], vertices[3]]],
                           wraps=['WRAP', 'WRAP'])


def animation_fixture(mode=0):
    samples = [[1, 1, 0, 1, frame / 239, frame / 239] for frame in range(240)]
    track = {'material': 'sea_mizu1_1', 'samples': samples, 'clip': 'out58_ita', 'frames': 240,
             'source': {'sha256': ANIMATION_SHA256, 'origins': [{'path': 'a/0/6/8', 'narc_member': 50}]}}
    sources = SimpleNamespace(by_material=defaultdict(list, {'sea_mizu1_1': [track]}),
                              modes=lambda names, material: {mode})
    context = {'materials': {'sea_mizu1_1': {'textures': ['sea.png'],
                                            'groups': ['map_0300_24_5/terrain_1', 'map_0301_24_4/terrain']}}}
    return sources, context


class PapeloaSeaTests(unittest.TestCase):
    def test_source_uv_transform_preserves_orientation_and_sector_wrap_phase(self):
        transform = surface_uv_transform([source_surface(), source_surface(32, -8)])
        self.assertEqual(transform, [[.25, 0, 0], [0, .25, 1]])

    def test_source_uv_transform_rejects_noninteger_sector_phase_changes(self):
        with self.assertRaisesRegex(ValueError, 'UV phase'):
            surface_uv_transform([source_surface(), source_surface(32, .125)])

    def test_modules_embed_exact_pixels_with_opaque_materials_and_exact_bounds(self):
        image = BytesIO()
        Image.new('RGBA', (2, 2), (8, 123, 173, 255)).save(image, 'PNG')
        pixels = image.getvalue()
        transform = surface_uv_transform([source_surface()])
        with TemporaryDirectory() as directory:
            for width, depth in [(16, 16), (8, 16), (16, 2), (8, 2)]:
                result = module_geometry(width, depth, 'sea.png', pixels, transform)
                path = Path(directory) / f'{width}x{depth}.glb'
                metrics = emit_model(path, result)
                document, binary = read_glb(path.read_bytes())
                self.assertEqual(metrics['triangleCount'], 2)
                self.assertEqual(metrics['bounds'], [-width / 2, 0, -depth / 2, width / 2, 0, depth / 2])
                self.assertEqual(document['materials'][0]['alphaMode'], 'OPAQUE')
                self.assertEqual(document['materials'][0]['pbrMetallicRoughness']['baseColorFactor'], [1, 1, 1, 1])
                view = document['bufferViews'][document['images'][0]['bufferView']]
                self.assertEqual(binary[view['byteOffset']:view['byteOffset'] + view['byteLength']], pixels)
                primitive = document['meshes'][0]['primitives'][0]
                uv = accessor_rows(document, binary, primitive['attributes']['TEXCOORD_0'])
                self.assertEqual(uv[0], [-6, -7.25])
                self.assertEqual(uv[1], [-6, -7.25 + depth / 4])
                self.assertEqual(uv[2], [-6 + width / 4, -7.25 + depth / 4])
                self.assertEqual(document['samplers'][0]['wrapS'], 10497)
                self.assertEqual(document['samplers'][0]['wrapT'], 10497)

    def test_24_noncolliding_modules_cover_the_map_once(self):
        instances = placements()
        self.assertEqual(len(instances), 24)
        self.assertEqual(len({instance['id'] for instance in instances}), 24)
        coverage = {}
        for instance in instances:
            self.assertFalse(instance['blocksMovement'])
            self.assertEqual(instance['position']['y'], -2.0625)
            self.assertEqual(instance['scale'], 1)
            self.assertEqual(instance['rotationDegrees'], 0)
            width, depth = map(int, instance['modelId'].rsplit('-', 1)[1].split('x'))
            left = instance['position']['x'] - width / 2
            top = instance['position']['z'] - depth / 2
            self.assertEqual((left / 4) % 1, 0)
            self.assertEqual((top / 4) % 1, 0)
            for z in range(int(top), int(top + depth)):
                for x in range(int(left), int(left + width)):
                    coverage[x, z] = coverage.get((x, z), 0) + 1
        self.assertEqual(set(coverage), {(x, z) for z in range(82) for x in range(56)})
        self.assertEqual(set(coverage.values()), {1})

    def test_animated_module_reuses_native_matrix_without_v_flip_and_preserves_geometry(self):
        image = BytesIO()
        Image.new('RGBA', (2, 2), (8, 123, 173, 255)).save(image, 'PNG')
        with TemporaryDirectory() as directory:
            path = Path(directory) / 'sea.glb'
            emit_model(path, module_geometry(16, 16, 'sea.png', image.getvalue(), surface_uv_transform([source_surface()])))
            document, binary = read_glb(path.read_bytes())
            before = deepcopy(document)
            sources, context = animation_fixture()
            animated, evidence = animated_sea_document(document, binary, context, sources)
            self.assertEqual(document, before)
            for key in ('nodes', 'meshes', 'images', 'textures', 'samplers', 'accessors', 'bufferViews', 'buffers'):
                self.assertEqual(animated[key], before[key])
            material = deepcopy(animated['materials'][0])
            material.pop('extras')
            self.assertEqual(material, before['materials'][0])
            self.assertEqual(evidence[0]['animationSha256'], ANIMATION_SHA256)
            self.assertEqual(evidence[0]['matrixMode'], 0)
            track = animated['extras']['aveluneMaterialAnimations']['clips'][0]['tracks'][0]
            self.assertEqual(track['durationSeconds'], 4)
            self.assertEqual(track['times'][120], 2)
            self.assertEqual(track['times'][-1], 4)
            self.assertEqual(track['transforms'][120], [1, 0, 0, 1, -120 / 239, 120 / 239])
            self.assertEqual(track['transforms'][239], [1, 0, 0, 1, -1, 1])
            self.assertEqual(track['transforms'][-1], track['transforms'][0])
            self.assertEqual(track['interpolation'], 'STEP')

    def test_animation_preserves_source_phase_at_all_module_vertices_and_tiers(self):
        transform = surface_uv_transform([source_surface()])
        for frame in (0, 30, 120, 239):
            q = frame / 239
            for instance in placements():
                width, depth = map(int, instance['modelId'].rsplit('-', 1)[1].split('x'))
                left = instance['position']['x'] - width / 2
                top = instance['position']['z'] - depth / 2
                result = module_geometry(width, depth, 'sea.png', b'', transform)
                for vertex in result['surfaces']['sea.png']:
                    u, v = vertex[3] - q, vertex[4] + q
                    source_u = (vertex[0] + left - 24) / 4 - q
                    source_v = (vertex[2] + top - 33) / 4 + 1 + q
                    self.assertAlmostEqual(u - source_u, round(u - source_u))
                    self.assertAlmostEqual(v - source_v, round(v - source_v))
                    self.assertEqual(instance['position']['y'], -2.0625)

    def test_animation_rejects_a_different_native_matrix_mode(self):
        image = BytesIO()
        Image.new('RGBA', (2, 2), (8, 123, 173, 255)).save(image, 'PNG')
        with TemporaryDirectory() as directory:
            path = Path(directory) / 'sea.glb'
            emit_model(path, module_geometry(8, 2, 'sea.png', image.getvalue(), surface_uv_transform([source_surface()])))
            document, binary = read_glb(path.read_bytes())
            sources, context = animation_fixture(2)
            with self.assertRaisesRegex(ValueError, 'matrix mode'):
                animated_sea_document(document, binary, context, sources)

    def test_surface_difference_retains_the_outer_water_and_excludes_an_interior_hole(self):
        pieces = subtract_footprints([(0, 0), (4, 0), (4, 4), (0, 4)],
                                     [[(1, 1), (3, 1), (3, 3)], [(1, 1), (3, 3), (1, 3)]])
        self.assertAlmostEqual(sum(polygon_area(piece) for piece in pieces), 12)

        def contains(polygon, point):
            x, y = point
            hits = 0
            for a, b in zip(polygon, polygon[1:] + polygon[:1]):
                if (a[1] > y) != (b[1] > y) and x < (b[0] - a[0]) * (y - a[1]) / (b[1] - a[1]) + a[0]:
                    hits += 1
            return hits % 2 == 1

        for point, count in [((.3, .4), 1), ((3.5, 2.2), 1), ((1.75, 2.25), 0), ((2.25, 1.75), 0)]:
            self.assertEqual(sum(contains(piece, point) for piece in pieces), count)

    def test_surface_difference_accepts_reversed_and_duplicate_masks_and_ignores_vertical_footprints(self):
        square = [(0, 0), (4, 0), (4, 4), (0, 4)]
        triangle = [(1, 1), (3, 1), (2, 3)]
        masks = [triangle[::-1], triangle, [(0, 0), (1, 0), (2, 0)]]
        self.assertAlmostEqual(sum(polygon_area(piece) for piece in subtract_footprints(square, masks)), 14)
        self.assertEqual(subtract_footprints(square, [square]), [])
        self.assertEqual(subtract_footprints([(0, 0), (1, 0), (2, 0)], masks), [])

    def test_surface_masks_exclude_native_and_shallow_water_and_preserve_underwater_rock_coverage(self):
        triangle = [[0, -5.6875, 0], [1, -5.6875, 0], [0, -5.6875, 1]]
        surfaces = [SimpleNamespace(material=name, triangles=[triangle]) for name in
                    ['sea_mizu1_1', 'sea_mizu1', 'out58_ragu04', 'out58_zan2b', 'sea_zanami',
                     'sea_simi_1', 'sea_jimen', 'out58_gake02']]
        masks, materials = sea_surface_footprints(surfaces)
        self.assertEqual(len(masks), 6)
        self.assertNotIn('sea_mizu1', materials)
        self.assertNotIn('out58_gake02', materials)
        self.assertEqual(masks[0], [(24, 33), (25, 33), (24, 34)])

    def test_clipped_surface_triangulation_preserves_holes_area_normals_and_native_uv(self):
        pieces = subtract_footprints([(0, 0), (4, 0), (4, 4), (0, 4)],
                                     [[(1, 1), (3, 1), (3, 3)], [(1, 1), (3, 3), (1, 3)]])
        geometry = sea_surface_geometry(pieces, 'sea.png', b'', [[.25, 0, 0], [0, .25, 1]])
        vertices = geometry['surfaces']['sea.png']
        area = 0
        for index in range(0, len(vertices), 3):
            triangle = vertices[index:index + 3]
            signed = polygon_area([(v[0], v[2]) for v in triangle])
            self.assertLess(signed, 0)
            area -= signed
            for x, y, z, u, v, *color in triangle:
                self.assertEqual(y, 0)
                self.assertAlmostEqual(u, (x - 24) / 4)
                self.assertAlmostEqual(v, (z - 33) / 4 + 1)
        self.assertAlmostEqual(area, 12)
        self.assertFalse(geometry['doubleSided']['sea.png'])


if __name__ == '__main__':
    unittest.main()

from copy import deepcopy
from importlib import import_module
from io import BytesIO
from pathlib import Path
import sys
from tempfile import TemporaryDirectory
from types import SimpleNamespace
import unittest

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
sys.path[:0] = [str(HERE), str(HERE.parent / 'scripts')]
import extract_units
import terrain
import semantic_tiles
import periodic_surfaces
import directed_profiles
import stairs
import details
from source_conversion_fixtures import geometry_policy


def fixture_policy():
    policy = geometry_policy()
    policy['ground']['floorRules'] = [{'kind': 'terrain', 'selector': {'exact': ['copper', 'marble']}}]
    return policy


def fixture_paint(scene, frame):
    return terrain.paint_recipe({**scene, 'sourcePolicy': fixture_policy()}, frame,
        decal_materials=['print-a', 'print-b', 'print-c', 'print-d', 'print-e', 'print-f'],
        grass_materials=['foliage'], grass_model_id='grass-model')


def fixture_areas(scene, frame):
    return terrain.source_areas({**scene, 'sourcePolicy': fixture_policy()}, frame,
        area_kinds={name: 'decoration' for name in ['print-a', 'print-b', 'print-c', 'print-d', 'print-e', 'print-f']})


class GeometryOperationsTest(unittest.TestCase):
    def test_periodic_layers_keep_explicit_phases_heights_and_reject_fractional_phase_origins(self):
        for period, translation in [([2, 3], [5, -.25, 7]), ([3, 1], [-4, 2, -2])]:
            phases = {(x, z): f'phase-{x}-{z}' for z in range(period[1]) for x in range(period[0])}
            layers = [{'phases': phases, 'period': period, 'sourceY': 1.5, 'animationIndex': None}]
            result = periodic_surfaces.surface_pattern(layers, translation, pattern_id='explicit-pattern',
                label='Explicit layers', width=4, depth=3, tags=['synthetic'])
            self.assertEqual(len(result['cells']), 12)
            for cell in result['cells']:
                part = cell['parts'][0]['source']
                self.assertEqual(part['modelId'], phases[(cell['x'] - translation[0]) % period[0],
                                                         (cell['y'] - translation[2]) % period[1]])
                self.assertEqual(part['offsetY'], 1.5 + translation[1])
            with self.assertRaises(ValueError):
                periodic_surfaces.surface_pattern(layers, [.5, 0, 0], pattern_id='explicit-pattern',
                    label='Explicit layers', width=4, depth=3, tags=[])

    def test_repeated_geometry_uses_declared_marker_period_and_preserves_source_attributes(self):
        surface = extract_units.Surface('arbitrary-sector', 'repeated', 'marker', 'marker.png', ['WRAP', 'WRAP'], 1, [], True)
        a, b, c, d = [[*position, position[0], position[2], .3, .5, .7] for position in
                      [[0, 0, 0], [0, 0, 1], [2, 0, 1], [2, 0, 0]]]
        surface.triangles = [[a, b, c], [a, c, d]]
        units = list(details.repeated_candidates({'surfaces': [surface]}, marker_material='marker',
                    materials=['marker'], period=[1, 1], height_range=[0, 1]))
        self.assertEqual(len(units), 2)
        self.assertEqual([row[1] for row in units], [[0, 0, 1, 1], [1, 0, 2, 1]])
        self.assertTrue(all(any(extract_units.point_in_triangle(vertex, original) for original in surface.triangles)
                            for entries, _, _, _ in units for _, triangle in entries for vertex in triangle))

    def test_directed_corner_assemblies_keep_source_attributes_and_matching_sockets(self):
        surface = extract_units.Surface('arbitrary-sector', 'profile', 'stone', 'stone.png', ['WRAP', 'WRAP'], 1, [], True)
        for rectangle in [[[-.5, 1, -.5], [.5, 1, -.5], [.5, 1, 0], [-.5, 1, 0]],
                          [[-.5, 1, 0], [.5, 1, 0], [.5, 0, 0], [-.5, 0, 0]],
                          [[-.5, 0, 0], [.5, 0, 0], [.5, 0, .5], [-.5, 0, .5]]]:
            vertices = [[*position, position[0], position[2] + position[1], .4, .6, .8] for position in rectangle]
            surface.triangles.extend([[vertices[0], vertices[1], vertices[2]], [vertices[0], vertices[2], vertices[3]]])
        scene = {'id': 'arbitrary-source', 'surfaces': [surface]}
        straight = extract_units.unit(scene['id'], 'straight', 'custom-relief',
            [(surface, triangle) for triangle in surface.triangles], [0, 1, 0], ['stone'], [1, 1, 1], pieceRole='straight')
        inner = directed_profiles.compose_inner_profile(scene, straight, 'inner')
        outer = directed_profiles.compose_outer_profile(scene, straight, 'outer')
        self.assertEqual(inner['family'], 'custom-relief')
        self.assertEqual(outer['family'], 'custom-relief')
        self.assertLessEqual(max(directed_profiles.socket_proof([straight, inner, outer]).values()), 1e-6)
        for corner in [inner, outer]:
            self.assertEqual(extract_units.entries_bounds(corner['entries'])[1:5:3], [0, 1])
            self.assertTrue(all(abs(value - expected) < 1e-9 for _, triangle in corner['entries'] for vertex in triangle
                                for value, expected in zip(vertex[5:], [.4, .6, .8])))
            self.assertTrue(corner['assemblySourceReferences'])

    def test_source_walking_plane_and_native_ramp_use_declared_frame_contacts(self):
        surface = extract_units.Surface('slope-sector', 'slope', 'ramp', 'ramp.png', ['CLAMP', 'CLAMP'], 1, [], True)
        a, b, c, d = [[*position, position[0], position[2], 1, 1, 1] for position in
                      [[1, 0, 1], [1, 0, 2], [3, 1, 2], [3, 1, 1]]]
        entries = [(surface, [a, b, c]), (surface, [a, c, d])]
        plane = stairs.walking_plane(entries)
        levels = [0] * 20
        for z in range(4):
            levels[z * 5 + 3] = 4
            levels[z * 5 + 4] = 4
        frame = {'sourceToNativeTranslation': [0, 0, 0], 'width': 5, 'depth': 4,
                 'levelHeight': .25, 'nativePaint': {'heightLevels': levels}}
        result = stairs.native_ramp(plane, frame, 'explicit-ramp')
        self.assertEqual(result['ramp']['direction'], 'east')
        self.assertEqual((result['ramp']['lowLevel'], result['ramp']['highLevel']), (0, 4))
        self.assertEqual(result['maximumNativeHeightError'], 0)
        self.assertTrue(result['contactSamples'])

    def module(self):
        return SimpleNamespace(**{**vars(extract_units), 'paint_recipe': fixture_paint, 'source_areas': fixture_areas})

    def semantic_module(self):
        return semantic_tiles

    def water_module(self):
        return periodic_surfaces

    def supplementary_module(self, name):
        module = import_module(name)
        if name == 'cell_geometry':
            module.area = import_module('rotation').area
        return module

    def test_mixed_family_selection_is_rejected(self):
        module = self.module()
        surface = module.Surface('sector', 'mesh', 'copper', 'grass.png', ['WRAP', 'WRAP'], 1, [], True)
        triangle = [[0, 0, 0, 0, 0, 1, 1, 1], [1, 0, 0, 1, 0, 1, 1, 1], [0, 0, 1, 0, 1, 1, 1, 1]]
        with self.assertRaisesRegex(ValueError, 'material'):
            module.validate_unit([(surface, triangle)], {'materials': ['wood'], 'maxSize': [2, 4, 2]})

    def test_support_preserves_visual_offset_and_source_orientation(self):
        module = self.module()
        surface = module.Surface('sector', 'mesh', 'foliage', 'grass.png', ['WRAP', 'WRAP'], 1, [], True)
        triangle = [[19, 1.125, 4, 0, 0, 1, 1, 1], [19, 1.125, 5, 0, 1, 1, 1, 1], [20, 1.125, 4, 1, 0, 1, 1, 1]]
        result = module.unit_geometry([(surface, triangle)], [19.5, 1, 4.5])
        self.assertEqual(result['sourceAnchorCells'], [19.5, 1.125, 4.5])
        self.assertEqual(result['supportAnchorLocal'], [0, -0.125, 0])
        self.assertEqual(result['normals'], [[0, 1, 0]])

    def test_clipping_preserves_uv_phase_and_color(self):
        module = self.module()
        surface = module.Surface('sector', 'mesh', 'rail', 'fence.png', ['CLAMP', 'WRAP'], 1, [], True)
        triangle = [[0, 0, 0, 0, 1, 0.2, 0.4, 0.6], [2, 0, 0, 0, 5, 0.2, 0.4, 0.6], [0, 0, 1, 1, 1, 0.2, 0.4, 0.6]]
        entries = module.clip_selected([(surface, triangle)], [1, 0, 2, 1])
        self.assertTrue(entries)
        self.assertEqual(min((v[4] for _, t in entries for v in t)), 3)
        self.assertTrue(all((v[5:] == [0.2, 0.4, 0.6] for _, t in entries for v in t)))

    def test_deduplication_does_not_hide_non_affine_source_vertex_color(self):
        module = self.module()
        surface = module.Surface('sector', 'mesh', 'wood', 'tree.png', ['WRAP', 'WRAP'], 1, [], True)
        a = [0, 0, 0, 0, 0, 1, 1, 1]
        b = [1, 0, 0, 1, 0, 1, 1, 1]
        c = [1, 0, 1, 1, 1, 1, 1, 1]
        d = [0, 0, 1, 0, 1, 1, 1, 1]
        center = [0.5, 0, 0.5, 0.5, 0.5, 0.25, 0.25, 0.25]
        flat = [(surface, [a, b, c]), (surface, [a, c, d])]
        shaded = [(surface, [a, b, center]), (surface, [b, c, center]), (surface, [c, d, center]), (surface, [d, a, center])]
        self.assertNotEqual(module.geometry_identity(flat), module.geometry_identity(shaded))

    def paint_surface(self, module, material, height, color=(0, 100, 0, 255)):
        positions = [[0, height, 0], [0, height, 1], [1, height, 1], [1, height, 0]]
        vertices = [[*position, position[0], position[2], 1, 1, 1] for position in positions]
        surface = module.Surface('sector', material, material, material + '.png', ['WRAP', 'WRAP'], 1, [[vertices[0], vertices[1], vertices[2]], [vertices[0], vertices[2], vertices[3]]], True)
        stream = module.BytesIO()
        module.Image.new('RGBA', (2, 2), color).save(stream, format='PNG')
        return (surface, stream.getvalue())

    def paint_frame(self):
        return {'sourceToNativeTranslation': [0, -0.25, 0], 'width': 1, 'depth': 1, 'levelHeight': 0.25}

    def test_ground_motifs_do_not_raise_support_or_change_their_source_geometry(self):
        module = self.module()
        for material in ['print-a', 'print-b', 'print-c', 'print-d', 'print-e', 'print-f']:
            with self.subTest(material=material):
                ground, ground_png = self.paint_surface(module, 'copper', 1)
                decal, decal_png = self.paint_surface(module, material, 1.1875, (200, 0, 0, 255))
                scene = {'id': 'dataset-one', 'surfaces': [ground, decal], 'textures': {ground.texture: ground_png, decal.texture: decal_png}}
                original = deepcopy(scene)
                recipe = module.paint_recipe(scene, self.paint_frame())
                self.assertEqual(recipe['heightLevels'], [3])
                self.assertEqual(recipe['sourceNativeHeights'], [0.75])
                self.assertEqual(recipe['sourceCellSamples'][0]['material'], 'copper')
                area = next((row for row in module.source_areas(scene, self.paint_frame()) if row['material'] == material))
                self.assertEqual(area['sourceTriangles'], decal.triangles)
                self.assertEqual(scene, original)

    def test_ground_motif_without_underlying_support_remains_unclassified(self):
        module = self.module()
        decal, png = self.paint_surface(module, 'print-c', 1.1875)
        scene = {'id': 'dataset-one', 'surfaces': [decal], 'textures': {decal.texture: png}}
        recipe = module.paint_recipe(scene, self.paint_frame())
        self.assertEqual(recipe['heightLevels'], [None])
        self.assertEqual(recipe['sourceNativeHeights'], [None])
        self.assertEqual(recipe['missingSupportCells'], 1)
        self.assertTrue(module.source_areas(scene, self.paint_frame()))

    def test_ground_motif_cannot_promote_transparent_ground_to_support(self):
        module = self.module()
        ground, ground_png = self.paint_surface(module, 'copper', 1, (0, 100, 0, 0))
        decal, decal_png = self.paint_surface(module, 'print-e', 1.1875)
        scene = {'id': 'dataset-one', 'surfaces': [ground, decal], 'textures': {ground.texture: ground_png, decal.texture: decal_png}}
        self.assertEqual(module.paint_recipe(scene, self.paint_frame())['heightLevels'], [None])

    def test_ground_support_keeps_a_real_higher_platform(self):
        module = self.module()
        ground, ground_png = self.paint_surface(module, 'copper', 1)
        platform, platform_png = self.paint_surface(module, 'marble', 5)
        decal, decal_png = self.paint_surface(module, 'print-e', 5.1875)
        scene = {'id': 'dataset-two', 'surfaces': [ground, platform, decal], 'textures': {ground.texture: ground_png, platform.texture: platform_png, decal.texture: decal_png}}
        recipe = module.paint_recipe(scene, self.paint_frame())
        self.assertEqual(recipe['heightLevels'], [19])
        self.assertEqual(recipe['sourceCellSamples'][0]['material'], 'marble')

    def test_ground_support_keeps_source_slope_interpolation(self):
        module = self.module()
        ground, png = self.paint_surface(module, 'copper', 1)
        for triangle in ground.triangles:
            for vertex in triangle:
                vertex[1] = 1 + vertex[0]
        scene = {'id': 'dataset-one', 'surfaces': [ground], 'textures': {ground.texture: png}}
        recipe = module.paint_recipe(scene, self.paint_frame())
        self.assertEqual(recipe['sourceNativeHeights'], [1.25])
        self.assertEqual(recipe['heightLevels'], [5])

    def test_native_blob_gate_uses_the_core_cardinal_and_corner_bit_contract(self):
        module = self.semantic_module()
        self.assertEqual(module.blob_mask(240), 0)
        self.assertEqual(module.blob_mask(49), 1)
        self.assertEqual(module.blob_mask(51), 35)
        self.assertEqual(len({module.blob_mask(mask) for mask in range(256)}), 47)

    def test_equal_neighbor_masks_with_different_source_contours_remain_ambiguous(self):
        module = self.semantic_module()
        image = module.extraction.Image.new('RGBA', (16, 16), (1, 2, 3, 255))
        variant = image.copy()
        variant.putpixel((0, 0), (1, 2, 3, 0))
        with TemporaryDirectory() as directory:
            analysis = module.path_analysis({(2, 2): image, (4, 4): variant}, 'path', Path(directory))
        case = next((row for row in analysis['cases'] if row['mask'] == 0))
        self.assertEqual(case['alphaContourVariants'], 2)
        self.assertEqual(case['status'], 'ambiguous_source_geometry_or_uv')
        self.assertTrue(analysis['missingMasks'])
        self.assertEqual(len(analysis['draftRules'][0]['candidates']), 1)

    def test_periodic_native_frame_preserves_original_pixels_and_map_phase(self):
        module = self.semantic_module()
        image = module.extraction.Image.new('RGBA', (64, 64))
        for y in range(64):
            for x in range(64):
                image.putpixel((x, y), (x, y, 0, 255))
        mapping = {'periodCells': 4, 'uvMatrix': [[0.25, 0, 0], [0, 0.25, 0]], 'area': {'wraps': ['WRAP', 'WRAP']}}
        result = module.pattern_image(image, mapping, [17, -0.25, 25])
        self.assertEqual(result.getpixel((0, 0)), (48, 48, 0, 255))
        self.assertEqual(result.getpixel((16, 16)), (0, 0, 0, 255))

    def test_cliff_face_detection_rejects_sloped_trapezoid_extent(self):
        module = self.supplementary_module('borders')
        extraction = module.extraction
        a, b, c, d = [[*position, 0, 0, 1, 1, 1] for position in ([0, 0, 0], [2, 0, 0], [2, 3, 0], [1, 3, 0])]
        surface = extraction.Surface('sector', 'mesh', 'wall', 'wall.png', ['WRAP', 'WRAP'], 1, [[a, b, c], [a, c, d]], True)
        self.assertEqual(module.rectangular_faces({'surfaces': [surface]}, materials=['wall']), [])
        d[0] = 0
        faces = module.rectangular_faces({'surfaces': [surface]}, materials=['wall'])
        self.assertEqual(len(faces), 1)
        self.assertEqual(faces[0]['sourceArea'], 6)
        clipped = module.clip_face(faces[0], 0.5, 1.5)
        self.assertEqual(extraction.entries_bounds(clipped), [0.5, 0, 0, 1.5, 3, 0])

    def test_cliff_socket_follows_actual_recipe_levels_without_moving_source_wall(self):
        module = self.supplementary_module('borders')
        frame = {'sourceToNativeTranslation': [0, -0.25, 0], 'width': 4, 'depth': 4, 'levelHeight': 0.25, 'nativePaint': {'heightLevels': [12] * 16}}
        face = {'first': 0.5, 'last': 2.5, 'constantAxis': 2, 'alongAxis': 0, 'constant': 1.2, 'low': 2, 'high': 5.75, 'normal': [0, 0, 1]}
        model = {'id': 'wall', 'bounds': [-0.5, 0, 0, 0.5, 3.75, 0], 'normals': [[0, 0, 1]]}
        runs, grid = module.border_runs(face, model, frame, 'face')
        self.assertEqual(grid['alignment'], 'gridEdges')
        self.assertEqual(len(runs), 1)
        anchor = runs[0]['primitiveSuggestions'][0]['anchorWorld']
        self.assertAlmostEqual(3 - anchor['y'], 1.75)
        self.assertAlmostEqual(1 - anchor['z'], 1.2)
        self.assertEqual(runs[0]['expectedNativeMaximumY'], 5.5)

    def test_water_partial_unit_uses_cell_pivot_without_changing_uv(self):
        module = self.water_module()
        extraction = module.extraction
        surface = extraction.Surface('sector', 'mesh', 'liquid', 'water.png', ['WRAP', 'WRAP'], 1, [], True)
        triangle = [[0, -2, 0, 0, 1, 1, 1, 1], [0.5, -2, 0, 0.0625, 1, 1, 1, 1], [0, -2, 1, 0, 1.125, 1, 1, 1]]
        with TemporaryDirectory() as directory:
            image = extraction.Image.new('RGBA', (1, 1), (0, 0, 255, 255))
            stream = module.BytesIO()
            image.save(stream, format='PNG')
            path = Path(directory) / 'water.glb'
            extraction.write_glb(path, [(surface, triangle)], {'water.png': stream.getvalue()})
            document, binary = extraction.read_glb(path.read_bytes())
            document.setdefault('extras', {})['sourceUnit'] = {}
            path.write_bytes(extraction.glb_bytes(document, binary))
            geometry = extraction.unit_geometry([(surface, triangle)], [0.5, -2, 0.5])
            model = module.reanchor_model({'path': str(path), **geometry}, [0.5, -2, 0.5])
            document, binary = extraction.read_glb(path.read_bytes())
            primitive = document['meshes'][0]['primitives'][0]
            accessor = document['accessors'][primitive['attributes']['POSITION']]
            view = document['bufferViews'][accessor['bufferView']]
            start = view.get('byteOffset', 0) + accessor.get('byteOffset', 0)
            positions = [module.struct.unpack_from('<fff', binary, start + index * view.get('byteStride', 12)) for index in range(accessor['count'])]
            self.assertEqual(positions, [(-0.5, 0, -0.5), (0, 0, -0.5), (-0.5, 0, 0.5)])
            self.assertEqual(model['sourceBoundsCells'], [0, -2, 0, 0.5, -2, 1])
            self.assertEqual(model['bounds'], [-0.5, 0, -0.5, 0, 0, 0.5])
            accessor = document['accessors'][primitive['attributes']['TEXCOORD_0']]
            view = document['bufferViews'][accessor['bufferView']]
            start = view.get('byteOffset', 0) + accessor.get('byteOffset', 0)
            uvs = [module.struct.unpack_from('<ff', binary, start + index * view.get('byteStride', 8)) for index in range(accessor['count'])]
            self.assertEqual(uvs, [(0, 1), (0.0625, 1), (0, 1.125)])

    def test_guardrail_cell_clipping_keeps_boundary_planes_once(self):
        module = self.supplementary_module('cell_geometry')
        extraction = module.extraction
        a, b, c, d = [[*position, 0, 0, 1, 1, 1] for position in ([1, 0, 0], [1, 1, 0], [1, 1, 2], [1, 0, 2])]
        surface = extraction.Surface('sector', 'mesh', 'rail', 'fence.png', ['WRAP', 'WRAP'], 1, [[a, b, c], [a, c, d]], True)
        cells = module.cell_entries({'surfaces': [surface]}, {'sourceToNativeTranslation': [0, 0, 0], 'width': 3, 'depth': 3}, materials=['rail'], component_materials=[], omit_flat_materials=[])
        self.assertEqual({key[:2] for key in cells}, {(1, 0), (1, 1)})
        self.assertAlmostEqual(sum((module.area(entries) for entries in cells.values())), 2)

    def test_relief_profiles_accept_source_extrusions_and_reject_cut_triangular_faces(self):
        module = self.supplementary_module('relief')
        extraction = module.extraction
        a, b, c, d = [[*position, 0, 0, 1, 1, 1] for position in ([0, 0, 0], [1, 0, 0], [1, 1, 1], [0, 1, 1])]
        surface = extraction.Surface('sector', 'mesh', 'rock', 'rock.png', ['WRAP', 'WRAP'], 1, [], True)
        entries = [(surface, [a, b, c]), (surface, [a, c, d])]
        self.assertEqual(module.profile_axis(entries), 0)
        self.assertIsNone(module.profile_axis(entries[:1]))

    def test_strict_relief_sampler_proof_detects_uv_and_vertex_color_differences(self):
        module = self.supplementary_module('relief')
        extraction = module.extraction
        surface = extraction.Surface('sector', 'mesh', 'rock', 'rock.png', ['WRAP', 'WRAP'], 1, [], True)
        triangle = [[0, 0, 0, 0.125, 0.25, 1, 1, 1], [1, 0, 0, 0.625, 0.25, 1, 1, 1], [0, 1, 1, 0.125, 0.75, 1, 1, 1]]
        entries = [(surface, triangle)]
        periodic = [(surface, [[*vertex[:3], vertex[3] + 1, vertex[4] + 2, *vertex[5:]] for vertex in triangle])]
        shifted = [(surface, [[*vertex[:3], vertex[3] + 0.25, *vertex[4:]] for vertex in triangle])]
        shaded = [(surface, [[*vertex[:5], 0.5, *vertex[6:]] for vertex in triangle])]
        self.assertAlmostEqual(module.appearance_error(entries, periodic, 0), 0)
        self.assertAlmostEqual(module.appearance_error(entries, shifted, 0), 0.25)
        self.assertAlmostEqual(module.appearance_error(entries, shaded, 0), 0.5)

if __name__ == '__main__':
    unittest.main()

import importlib.util
from copy import deepcopy
from pathlib import Path
import sys
from tempfile import TemporaryDirectory
import unittest


sys.dont_write_bytecode = True
TOOL = Path(__file__).with_name('extract_units.py')


class ModularExtractionTest(unittest.TestCase):
    def module(self):
        self.assertTrue(TOOL.is_file(), 'The reusable source-unit extractor is missing')
        spec = importlib.util.spec_from_file_location('nb2_extract_units', TOOL)
        module = importlib.util.module_from_spec(spec)
        sys.modules[spec.name] = module
        spec.loader.exec_module(module)
        return module

    def test_mixed_family_selection_is_rejected(self):
        module = self.module()
        surface = module.Surface('sector', 'mesh', 'grass01ax', 'grass.png', ['WRAP', 'WRAP'], 1, [], True)
        triangle = [[0, 0, 0, 0, 0, 1, 1, 1], [1, 0, 0, 1, 0, 1, 1, 1], [0, 0, 1, 0, 1, 1, 1, 1]]
        with self.assertRaisesRegex(ValueError, 'material'):
            module.validate_unit([(surface, triangle)], {'materials': ['ki02c'], 'maxSize': [2, 4, 2]})

    def test_support_preserves_visual_offset_and_source_orientation(self):
        module = self.module()
        surface = module.Surface('sector', 'mesh', 'kusa_ec1', 'grass.png', ['WRAP', 'WRAP'], 1, [], True)
        triangle = [[19, 1.125, 4, 0, 0, 1, 1, 1], [19, 1.125, 5, 0, 1, 1, 1, 1], [20, 1.125, 4, 1, 0, 1, 1, 1]]
        result = module.unit_geometry([(surface, triangle)], [19.5, 1, 4.5])
        self.assertEqual(result['sourceAnchorCells'], [19.5, 1.125, 4.5])
        self.assertEqual(result['supportAnchorLocal'], [0, -.125, 0])
        self.assertEqual(result['normals'], [[0, 1, 0]])

    def test_clipping_preserves_uv_phase_and_color(self):
        module = self.module()
        surface = module.Surface('sector', 'mesh', 'saku01a', 'fence.png', ['CLAMP', 'WRAP'], 1, [], True)
        triangle = [[0, 0, 0, 0, 1, .2, .4, .6], [2, 0, 0, 0, 5, .2, .4, .6], [0, 0, 1, 1, 1, .2, .4, .6]]
        entries = module.clip_selected([(surface, triangle)], [1, 0, 2, 1])
        self.assertTrue(entries)
        self.assertEqual(min(v[4] for _, t in entries for v in t), 3)
        self.assertTrue(all(v[5:] == [.2, .4, .6] for _, t in entries for v in t))

    def test_known_route_units_keep_the_three_grass_layers_and_only_tree_family(self):
        module = self.module()
        source = Path('/Users/karim/Desktop/pokeMap Project/pokemon_nb2/.pokemap/authoring/routes-19-20/sources')
        if not source.is_dir():
            self.skipTest('Local private source corpus is unavailable')
        scene = module.load_scene(source, 'rom-route19', True)
        units = module.route_units(scene['surfaces'])
        grass = next(unit for unit in units if unit['id'] == 'bw2-tallgrass-three-layer')
        tree = next(unit for unit in units if unit['id'] == 'bw2-tree-ki03')
        self.assertEqual(len(grass['entries']), 6)
        self.assertEqual({round(v[1], 6) for _, t in grass['entries'] for v in t}, {1.125, 1.375, 1.5})
        self.assertEqual({s.material for s, _ in tree['entries']}, {'ki02c', 'ki03ax', 'ki03bx', 'ki03dx'})
        self.assertEqual(len(tree['entries']), 10)

    def test_adjacent_source_tree_repetitions_share_one_geometry_identity(self):
        module = self.module()
        source = Path('/Users/karim/Desktop/pokeMap Project/pokemon_nb2/.pokemap/authoring/routes-19-20/sources')
        if not source.is_dir():
            self.skipTest('Local private source corpus is unavailable')
        scene = module.load_scene(source, 'rom-route19', True)
        candidates = list(module.tree_candidates(scene))
        self.assertEqual(module.geometry_identity(candidates[0][0]), module.geometry_identity(candidates[1][0]))

    def test_deduplication_does_not_hide_non_affine_source_vertex_color(self):
        module = self.module()
        surface = module.Surface('sector', 'mesh', 'ki02c', 'tree.png', ['WRAP', 'WRAP'], 1, [], True)
        a = [0, 0, 0, 0, 0, 1, 1, 1]
        b = [1, 0, 0, 1, 0, 1, 1, 1]
        c = [1, 0, 1, 1, 1, 1, 1, 1]
        d = [0, 0, 1, 0, 1, 1, 1, 1]
        center = [.5, 0, .5, .5, .5, .25, .25, .25]
        flat = [(surface, [a, b, c]), (surface, [a, c, d])]
        shaded = [(surface, [a, b, center]), (surface, [b, c, center]),
                  (surface, [c, d, center]), (surface, [d, a, center])]
        self.assertNotEqual(module.geometry_identity(flat), module.geometry_identity(shaded))

    def test_native_paint_keeps_source_height_and_reports_partial_grass_edges(self):
        module = self.module()
        source = Path('/Users/karim/Desktop/pokeMap Project/pokemon_nb2/.pokemap/authoring/routes-19-20/sources')
        if not source.is_dir():
            self.skipTest('Local private source corpus is unavailable')
        scene = module.load_scene(source, 'rom-route19', True)
        frame = {'sourceToNativeTranslation': [17, -.25, 25], 'width': 68, 'depth': 43, 'levelHeight': .25}
        recipe = module.paint_recipe(scene, frame)
        self.assertEqual(recipe['sourceNativeHeights'][15 * 68 + 26], 5.75)
        self.assertEqual(recipe['heightLevels'][15 * 68 + 26], 23)
        self.assertTrue(recipe['tallGrass']['partialCoverageCells'])
        self.assertTrue(all(0 < cell['sourceCoverageRatio'] < 1 for cell in recipe['tallGrass']['partialCoverageCells']))
        self.assertGreater(recipe['missingSupportCells'], 0)

    def paint_surface(self, module, material, height, color=(0, 100, 0, 255)):
        positions = [[0, height, 0], [0, height, 1], [1, height, 1], [1, height, 0]]
        vertices = [[*position, position[0], position[2], 1, 1, 1] for position in positions]
        surface = module.Surface('sector', material, material, material + '.png', ['WRAP', 'WRAP'], 1,
                                 [[vertices[0], vertices[1], vertices[2]],
                                  [vertices[0], vertices[2], vertices[3]]], True)
        stream = module.BytesIO()
        module.Image.new('RGBA', (2, 2), color).save(stream, format='PNG')
        return surface, stream.getvalue()

    def paint_frame(self):
        return {'sourceToNativeTranslation': [0, -.25, 0], 'width': 1, 'depth': 1, 'levelHeight': .25}

    def test_ground_motifs_do_not_raise_support_or_change_their_source_geometry(self):
        module = self.module()
        for material in ['michi_hage', 'michi_hage02', 'michi_hibi', 'michi_isi', 'ue_grass00', 'ue_grass01']:
            with self.subTest(material=material):
                ground, ground_png = self.paint_surface(module, 'grass01ax', 1)
                decal, decal_png = self.paint_surface(module, material, 1.1875, (200, 0, 0, 255))
                scene = {'id': 'rom-route19', 'surfaces': [ground, decal],
                         'textures': {ground.texture: ground_png, decal.texture: decal_png}}
                original = deepcopy(scene)
                recipe = module.paint_recipe(scene, self.paint_frame())
                self.assertEqual(recipe['heightLevels'], [3])
                self.assertEqual(recipe['sourceNativeHeights'], [.75])
                self.assertEqual(recipe['sourceCellSamples'][0]['material'], 'grass01ax')
                area = next(row for row in module.source_areas(scene, self.paint_frame())
                            if row['material'] == material)
                self.assertEqual(area['sourceTriangles'], decal.triangles)
                self.assertEqual(scene, original)

    def test_ground_motif_without_underlying_support_remains_unclassified(self):
        module = self.module()
        decal, png = self.paint_surface(module, 'michi_hibi', 1.1875)
        scene = {'id': 'rom-route19', 'surfaces': [decal], 'textures': {decal.texture: png}}
        recipe = module.paint_recipe(scene, self.paint_frame())
        self.assertEqual(recipe['heightLevels'], [None])
        self.assertEqual(recipe['sourceNativeHeights'], [None])
        self.assertEqual(recipe['missingSupportCells'], 1)
        self.assertTrue(module.source_areas(scene, self.paint_frame()))

    def test_ground_motif_cannot_promote_transparent_ground_to_support(self):
        module = self.module()
        ground, ground_png = self.paint_surface(module, 'grass01ax', 1, (0, 100, 0, 0))
        decal, decal_png = self.paint_surface(module, 'ue_grass00', 1.1875)
        scene = {'id': 'rom-route19', 'surfaces': [ground, decal],
                 'textures': {ground.texture: ground_png, decal.texture: decal_png}}
        self.assertEqual(module.paint_recipe(scene, self.paint_frame())['heightLevels'], [None])

    def test_ground_support_keeps_a_real_higher_platform(self):
        module = self.module()
        ground, ground_png = self.paint_surface(module, 'grass01ax', 1)
        platform, platform_png = self.paint_surface(module, 'C12_tile', 5)
        decal, decal_png = self.paint_surface(module, 'ue_grass00', 5.1875)
        scene = {'id': '587455', 'surfaces': [ground, platform, decal],
                 'textures': {ground.texture: ground_png, platform.texture: platform_png,
                              decal.texture: decal_png}}
        recipe = module.paint_recipe(scene, self.paint_frame())
        self.assertEqual(recipe['heightLevels'], [19])
        self.assertEqual(recipe['sourceCellSamples'][0]['material'], 'C12_tile')

    def test_ground_support_keeps_source_slope_interpolation(self):
        module = self.module()
        ground, png = self.paint_surface(module, 'grass01ax', 1)
        for triangle in ground.triangles:
            for vertex in triangle:
                vertex[1] = 1 + vertex[0]
        scene = {'id': 'rom-route19', 'surfaces': [ground], 'textures': {ground.texture: png}}
        recipe = module.paint_recipe(scene, self.paint_frame())
        self.assertEqual(recipe['sourceNativeHeights'], [1.25])
        self.assertEqual(recipe['heightLevels'], [5])

    def test_route_ground_support_uses_the_floor_below_original_cracks(self):
        module = self.module()
        source = Path('/Users/karim/Desktop/pokeMap Project/pokemon_nb2/.pokemap/authoring/routes-19-20/sources')
        if not source.is_dir():
            self.skipTest('Local private source corpus is unavailable')
        scene = module.load_scene(source, 'rom-route19', True)
        frame = {'sourceToNativeTranslation': [17, -.25, 25], 'width': 68, 'depth': 43, 'levelHeight': .25}
        recipe = module.paint_recipe(scene, frame)
        for x, z in [(22, 33), (38, 33), (25, 29), (41, 32)]:
            with self.subTest(cell=(x, z)):
                self.assertEqual(recipe['heightLevels'][z * 68 + x], 3)
                self.assertEqual(recipe['sourceNativeHeights'][z * 68 + x], .75)

    def test_pavonnay_ground_support_uses_the_floor_below_original_motifs(self):
        module = self.module()
        source = Path('/Users/karim/Downloads/pokemon-black2-white2-models-sans-pokemon')
        if not source.is_dir():
            self.skipTest('Local private source corpus is unavailable')
        scene = module.load_scene(source, '587455')
        frame = {'sourceToNativeTranslation': [24, 0, 16], 'width': 48, 'depth': 72, 'levelHeight': .25}
        recipe = module.paint_recipe(scene, frame)
        for x, z, height in [(7, 9, 9), (10, 15, 5), (7, 35, 5), (8, 62, 5), (36, 62, 1)]:
            with self.subTest(cell=(x, z)):
                self.assertEqual(recipe['sourceNativeHeights'][z * 48 + x], height)
                self.assertEqual(recipe['heightLevels'][z * 48 + x], height * 4)

    def semantic_module(self):
        self.module()
        spec = importlib.util.spec_from_file_location('nb2_semantic_tiles', TOOL.with_name('build_semantic_tiles.py'))
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module

    def test_native_blob_gate_uses_the_core_cardinal_and_corner_bit_contract(self):
        module = self.semantic_module()
        self.assertEqual(module.blob_mask(0xf0), 0)
        self.assertEqual(module.blob_mask(0x31), 1)
        self.assertEqual(module.blob_mask(0x33), 0x23)
        self.assertEqual(len({module.blob_mask(mask) for mask in range(256)}), 47)

    def test_equal_neighbor_masks_with_different_source_contours_remain_ambiguous(self):
        module = self.semantic_module()
        image = module.extraction.Image.new('RGBA', (16, 16), (1, 2, 3, 255))
        variant = image.copy()
        variant.putpixel((0, 0), (1, 2, 3, 0))
        with TemporaryDirectory() as directory:
            analysis = module.path_analysis({(2, 2): image, (4, 4): variant}, 'path', Path(directory))
        case = next(row for row in analysis['cases'] if row['mask'] == 0)
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
        mapping = {'periodCells': 4, 'uvMatrix': [[.25, 0, 0], [0, .25, 0]],
                   'area': {'wraps': ['WRAP', 'WRAP']}}
        result = module.pattern_image(image, mapping, [17, -.25, 25])
        self.assertEqual(result.getpixel((0, 0)), (48, 48, 0, 255))
        self.assertEqual(result.getpixel((16, 16)), (0, 0, 0, 255))

    def water_module(self):
        self.module()
        spec = importlib.util.spec_from_file_location('nb2_water_tiles', TOOL.with_name('build_water_tiles.py'))
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module

    def supplementary_module(self, name):
        self.module()
        spec = importlib.util.spec_from_file_location('nb2_' + name, TOOL.with_name(name + '.py'))
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module

    def test_cliff_face_detection_rejects_sloped_trapezoid_extent(self):
        module = self.supplementary_module('build_cliff_borders')
        extraction = module.extraction
        a, b, c, d = [[*position, 0, 0, 1, 1, 1] for position in
                      ([0, 0, 0], [2, 0, 0], [2, 3, 0], [1, 3, 0])]
        surface = extraction.Surface('sector', 'mesh', 'yamagake01', 'wall.png', ['WRAP', 'WRAP'], 1,
                                     [[a, b, c], [a, c, d]], True)
        self.assertEqual(module.rectangular_faces({'surfaces': [surface]}), [])
        d[0] = 0
        faces = module.rectangular_faces({'surfaces': [surface]})
        self.assertEqual(len(faces), 1)
        self.assertEqual(faces[0]['sourceArea'], 6)
        clipped = module.clip_face(faces[0], .5, 1.5)
        self.assertEqual(extraction.entries_bounds(clipped), [.5, 0, 0, 1.5, 3, 0])

    def test_cliff_socket_follows_actual_recipe_levels_without_moving_source_wall(self):
        module = self.supplementary_module('build_cliff_borders')
        frame = {'sourceToNativeTranslation': [0, -.25, 0], 'width': 4, 'depth': 4,
                 'levelHeight': .25, 'nativePaint': {'heightLevels': [12] * 16}}
        face = {'first': .5, 'last': 2.5, 'constantAxis': 2, 'alongAxis': 0,
                'constant': 1.2, 'low': 2, 'high': 5.75, 'normal': [0, 0, 1]}
        model = {'id': 'wall', 'bounds': [-.5, 0, 0, .5, 3.75, 0], 'normals': [[0, 0, 1]]}
        runs, grid = module.border_runs(face, model, frame, 'face')
        self.assertEqual(grid['alignment'], 'gridEdges')
        self.assertEqual(len(runs), 1)
        anchor = runs[0]['primitiveSuggestions'][0]['anchorWorld']
        self.assertAlmostEqual(3 - anchor['y'], 1.75)
        self.assertAlmostEqual(1 - anchor['z'], 1.2)
        self.assertEqual(runs[0]['expectedNativeMaximumY'], 5.5)

    def test_original_stair_units_preserve_walking_plane_and_all_native_contacts(self):
        module = self.supplementary_module('build_stair_units')
        extraction = module.extraction
        kit = Path(__file__).resolve().parents[2] / 'apps/unys_3d_sources/modular-rebuild-20261011'
        route_root = Path('/Users/karim/Desktop/pokeMap Project/pokemon_nb2/.pokemap/authoring/routes-19-20/sources')
        corpus_root = Path('/Users/karim/Downloads/pokemon-black2-white2-models-sans-pokemon')
        if not (kit / 'reconstruction_recipe.json').is_file() or not route_root.is_dir() or not corpus_root.is_dir():
            self.skipTest('Local private source corpus or generated source recipe is unavailable')
        recipe = extraction.json.loads((kit / 'reconstruction_recipe.json').read_text())
        cases = [(route_root, 'rom-route19', True, 'unys-route-19', 1),
                 (corpus_root, '587455', False, 'first-map', 3)]
        for root, source_id, route, map_id, expected in cases:
            scene = extraction.load_scene(root, source_id, route)
            components = extraction.component_triangles(extraction.select_entries(scene['surfaces'], module.STAIR_MATERIALS[source_id]))
            self.assertEqual(len(components), expected)
            for index, component in enumerate(components):
                plane = module.walking_plane(component)
                qualified = module.native_ramp(plane, recipe['maps'][map_id], 'stairs-' + str(index))
                self.assertTrue(qualified['contactSamples'])
                self.assertLessEqual(qualified['maximumNativeHeightError'], .0009765625)
                if route:
                    self.assertEqual(qualified['ramp']['highLevel'], 23)
                    self.assertEqual(plane['bounds'][4], 6)
                    self.assertEqual(extraction.entries_bounds(component)[4], 6.25)
                elif index == 0:
                    self.assertEqual(qualified['ramp']['highLevel'], 36)

    def test_water_masks_keep_exact_source_base_and_upper_lake_absence(self):
        module = self.water_module()
        source = Path('/Users/karim/Desktop/pokeMap Project/pokemon_nb2/.pokemap/authoring/routes-19-20/sources')
        if not source.is_dir():
            self.skipTest('Local private source corpus is unavailable')
        scene = module.extraction.load_scene(source, 'rom-route19', True)
        frame = {'sourceToNativeTranslation': [17, -.25, 25], 'width': 68, 'depth': 43}
        base = module.cell_records(scene, frame, 'mizu_sita2')
        overlay = module.cell_records(scene, frame, 'ike01')
        self.assertAlmostEqual(sum(row['coverage'] for row in base), 574)
        self.assertAlmostEqual(sum(row['coverage'] for row in overlay), 234.880859375)
        self.assertEqual(sum(abs(row['coverage'] - 1) < 1e-7 for row in base), 560)
        base_cells = {(row['x'], row['z']) for row in base}
        self.assertTrue(all((row['x'], row['z']) not in base_cells for row in overlay if row['anchor'][1] == 5.5))
        self.assertTrue(all((row['x'], row['z']) in base_cells for row in overlay if row['anchor'][1] == .5))
        self.assertTrue(all(module.periodic_entries(row['entries'], 2) for row in overlay
                            if row['anchor'][1] == .5 and abs(row['coverage'] - 1) < 1e-7))
        self.assertTrue(any(not module.periodic_entries(row['entries'], 2) for row in overlay if row['anchor'][1] == 5.5))

    def test_water_partial_unit_uses_cell_pivot_without_changing_uv(self):
        module = self.water_module()
        extraction = module.extraction
        surface = extraction.Surface('sector', 'mesh', 'mizu_sita2', 'water.png', ['WRAP', 'WRAP'], 1, [], True)
        triangle = [[0, -2, 0, 0, 1, 1, 1, 1], [.5, -2, 0, .0625, 1, 1, 1, 1],
                    [0, -2, 1, 0, 1.125, 1, 1, 1]]
        with TemporaryDirectory() as directory:
            image = extraction.Image.new('RGBA', (1, 1), (0, 0, 255, 255))
            stream = module.BytesIO()
            image.save(stream, format='PNG')
            path = Path(directory) / 'water.glb'
            extraction.write_glb(path, [(surface, triangle)], {'water.png': stream.getvalue()})
            document, binary = extraction.read_glb(path.read_bytes())
            document.setdefault('extras', {})['nb2SourceUnit'] = {}
            path.write_bytes(extraction.glb_bytes(document, binary))
            geometry = extraction.unit_geometry([(surface, triangle)], [.5, -2, .5])
            model = module.reanchor_model({'path': str(path), **geometry}, [.5, -2, .5])
            document, binary = extraction.read_glb(path.read_bytes())
            primitive = document['meshes'][0]['primitives'][0]
            accessor = document['accessors'][primitive['attributes']['POSITION']]
            view = document['bufferViews'][accessor['bufferView']]
            start = view.get('byteOffset', 0) + accessor.get('byteOffset', 0)
            positions = [module.struct.unpack_from('<fff', binary, start + index * view.get('byteStride', 12))
                         for index in range(accessor['count'])]
            self.assertEqual(positions, [(-.5, 0, -.5), (0, 0, -.5), (-.5, 0, .5)])
            self.assertEqual(model['sourceBoundsCells'], [0, -2, 0, .5, -2, 1])
            self.assertEqual(model['bounds'], [-.5, 0, -.5, 0, 0, .5])
            accessor = document['accessors'][primitive['attributes']['TEXCOORD_0']]
            view = document['bufferViews'][accessor['bufferView']]
            start = view.get('byteOffset', 0) + accessor.get('byteOffset', 0)
            uvs = [module.struct.unpack_from('<ff', binary, start + index * view.get('byteStride', 8))
                   for index in range(accessor['count'])]
            self.assertEqual(uvs, [(0, 1), (.0625, 1), (0, 1.125)])

    def test_guardrail_cell_clipping_keeps_boundary_planes_once(self):
        module = self.supplementary_module('build_fence_units')
        extraction = module.extraction
        a, b, c, d = [[*position, 0, 0, 1, 1, 1] for position in
                      ([1, 0, 0], [1, 1, 0], [1, 1, 2], [1, 0, 2])]
        surface = extraction.Surface('sector', 'mesh', 'saku01a', 'fence.png', ['WRAP', 'WRAP'], 1,
                                     [[a, b, c], [a, c, d]], True)
        cells = module.cell_entries({'surfaces': [surface]},
            {'sourceToNativeTranslation': [0, 0, 0], 'width': 3, 'depth': 3})
        self.assertEqual({key[:2] for key in cells}, {(1, 0), (1, 1)})
        self.assertAlmostEqual(sum(module.area(entries) for entries in cells.values()), 2)

    def test_pavonnay_posts_remain_four_complete_source_objects(self):
        module = self.supplementary_module('build_fence_units')
        source = Path('/Users/karim/Downloads/pokemon-black2-white2-models-sans-pokemon')
        if not source.is_dir():
            self.skipTest('Local private source corpus is unavailable')
        scene = module.extraction.load_scene(source, '587455')
        frame = {'sourceToNativeTranslation': [24, 0, 16], 'width': 48, 'depth': 72}
        posts = [entries for key, entries in module.cell_entries(scene, frame).items() if key[2] == 'C12_saku02']
        self.assertEqual(len(posts), 4)
        self.assertEqual([len(entries) for entries in posts], [10, 10, 10, 10])
        self.assertEqual(sum(module.area(entries) for entries in posts),
                         module.area(module.extraction.select_entries(scene['surfaces'], ['C12_saku02'])))

    def test_pavonnay_lamps_planters_and_postbox_are_complete_compound_objects(self):
        module = self.supplementary_module('build_detail_units')
        source = Path('/Users/karim/Downloads/pokemon-black2-white2-models-sans-pokemon')
        if not source.is_dir():
            self.skipTest('Local private source corpus is unavailable')
        scene = module.extraction.load_scene(source, '587455')
        lamps = module.joined_objects(module.extraction.select_entries(scene['surfaces'], ['C12_ight', 'C12_l_hikari']))
        beds = module.joined_objects(module.extraction.select_entries(scene['surfaces'], ['C12_kadan01', 'C12_kadan02']))
        mailbox = module.joined_objects(module.extraction.select_entries(scene['surfaces'], ['c12_post01']))
        self.assertEqual(len(lamps), 5)
        self.assertEqual([len(entries) for entries in lamps], [204] * 5)
        self.assertEqual(len(beds), 7)
        self.assertEqual(sum(map(len, beds)), 382)
        self.assertEqual(len(mailbox), 1)
        self.assertEqual(len(mailbox[0]), 23)

    def test_pavonnay_water_keeps_202_base_only_cells_and_source_absolute_height(self):
        module = self.water_module()
        source = Path('/Users/karim/Downloads/pokemon-black2-white2-models-sans-pokemon')
        if not source.is_dir():
            self.skipTest('Local private source corpus is unavailable')
        scene = module.extraction.load_scene(source, '587455')
        frame = {'sourceToNativeTranslation': [24, 0, 16], 'width': 48, 'depth': 72}
        base, overlay = [module.cell_records(scene, frame, name) for name in ['mizu_sita2', 'ike01']]
        self.assertEqual(len(base), 256)
        self.assertEqual(len(overlay), 54)
        self.assertEqual({row['anchor'][1] for row in base}, {-2})
        self.assertEqual({row['anchor'][1] for row in overlay}, {.5})
        self.assertEqual(len({(row['x'], row['z']) for row in base} - {(row['x'], row['z']) for row in overlay}), 202)

    def test_relief_profiles_accept_source_extrusions_and_reject_cut_triangular_faces(self):
        module = self.supplementary_module('build_complete_relief')
        extraction = module.extraction
        a, b, c, d = [[*position, 0, 0, 1, 1, 1] for position in
                      ([0, 0, 0], [1, 0, 0], [1, 1, 1], [0, 1, 1])]
        surface = extraction.Surface('sector', 'mesh', 'gake01a_2', 'rock.png', ['WRAP', 'WRAP'], 1, [], True)
        entries = [(surface, [a, b, c]), (surface, [a, c, d])]
        self.assertEqual(module.profile_axis(entries), 0)
        self.assertIsNone(module.profile_axis(entries[:1]))

    def test_strict_relief_sampler_proof_detects_uv_and_vertex_color_differences(self):
        module = self.supplementary_module('build_complete_relief')
        extraction = module.extraction
        surface = extraction.Surface('sector', 'mesh', 'gake01a_2', 'rock.png', ['WRAP', 'WRAP'], 1, [], True)
        triangle = [[0, 0, 0, .125, .25, 1, 1, 1], [1, 0, 0, .625, .25, 1, 1, 1],
                    [0, 1, 1, .125, .75, 1, 1, 1]]
        entries = [(surface, triangle)]
        periodic = [(surface, [[*vertex[:3], vertex[3] + 1, vertex[4] + 2, *vertex[5:]] for vertex in triangle])]
        shifted = [(surface, [[*vertex[:3], vertex[3] + .25, *vertex[4:]] for vertex in triangle])]
        shaded = [(surface, [[*vertex[:5], .5, *vertex[6:]] for vertex in triangle])]
        self.assertAlmostEqual(module.appearance_error(entries, periodic, 0), 0)
        self.assertAlmostEqual(module.appearance_error(entries, shifted, 0), .25)
        self.assertAlmostEqual(module.appearance_error(entries, shaded, 0), .5)

    def test_complete_relief_covers_route_lower_banks_and_pavonnay_vertical_paving(self):
        module = self.supplementary_module('build_complete_relief')
        extraction = module.extraction
        source = Path('/Users/karim/Desktop/pokeMap Project/pokemon_nb2/.pokemap/authoring/routes-19-20/sources')
        if not source.is_dir():
            self.skipTest('Local private source corpus is unavailable')
        scene = extraction.load_scene(source, 'rom-route19', True)
        bins = module.cell_entries(scene, {'sourceToNativeTranslation': [17, -.25, 25]})
        bank = [(surface, triangle) for surface in scene['surfaces'] if surface.material == 'gake01a_2'
                for triangle in surface.triangles]
        self.assertAlmostEqual(sum(module.area(entries) for key, entries in bins.items() if key[3] == 'gake01a_2'), module.area(bank))
        self.assertTrue(all(max(extraction.entries_bounds(entries)[axis + 3] - extraction.entries_bounds(entries)[axis]
                                for axis in [0, 2]) <= 1.000001 for entries in bins.values()))
        pavonnay = Path('/Users/karim/Downloads/pokemon-black2-white2-models-sans-pokemon')
        if pavonnay.is_dir():
            scene = extraction.load_scene(pavonnay, '587455')
            paving = [triangle for surface in scene['surfaces'] if surface.material == 'C12_tile05'
                      for triangle in surface.triangles if module.selected_triangle(surface, triangle)]
            self.assertEqual(len(paving), 25)
            self.assertEqual(sum(abs(extraction.normal(triangle)[1]) < 1e-6 for triangle in paving), 13)


if __name__ == '__main__':
    unittest.main()

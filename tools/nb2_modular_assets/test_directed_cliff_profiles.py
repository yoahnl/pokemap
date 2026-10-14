import importlib.util
import contextlib
import io
import json
from pathlib import Path
import sys
import tempfile
from types import SimpleNamespace
import unittest


sys.dont_write_bytecode = True
TOOL = Path(__file__).with_name('build_directed_cliff_profiles.py')


class DirectedCliffProfilesTest(unittest.TestCase):
    def module(self):
        self.assertTrue(TOOL.is_file(), 'The directed cliff profile extractor is missing')
        specification = importlib.util.spec_from_file_location('directed_cliff_profiles', TOOL)
        module = importlib.util.module_from_spec(specification)
        specification.loader.exec_module(module)
        return module

    def scene(self, module, source_id):
        root = Path('/Users/karim/Downloads/pokemon-black2-white2-models-sans-pokemon')
        route = Path('/Users/karim/Desktop/pokeMap Project/pokemon_nb2/.pokemap/authoring/routes-19-20/sources')
        return module.extraction.load_scene(route if source_id == 'rom-route19' else root,
                                            source_id, source_id == 'rom-route19')

    def test_pavonnay_four_unit_profiles_keep_original_height_and_all_roles(self):
        module = self.module()
        scene = self.scene(module, '587455')
        units = module.profile_units(scene, 'pavonnay-four')
        self.assertEqual({unit['pieceRole'] for unit in units}, {'straight', 'outer', 'inner'})
        for unit in units:
            bounds = module.extraction.entries_bounds(unit['entries'])
            self.assertAlmostEqual(bounds[1], 5)
            self.assertAlmostEqual(bounds[4], 9)
            self.assertLessEqual(bounds[3] - bounds[0], 1.000001)
            self.assertLessEqual(bounds[5] - bounds[2], 1.000001)
            self.assertEqual(unit['support'][1], 9)

    def test_profiles_do_not_embed_the_lower_grass_floor(self):
        module = self.module()
        for source, family in [('587455', 'pavonnay-four'), ('rom-route19', 'route19-five')]:
            for unit in module.profile_units(self.scene(module, source), family):
                for surface, triangle in unit['entries']:
                    if surface.material == 'grass01ax':
                        self.assertTrue(all(abs(vertex[1] - unit['upperSurfaceHeight']) < 1e-6
                                            for vertex in triangle))

    def test_four_and_five_unit_corner_sockets_meet_the_straight_piece(self):
        module = self.module()
        for source, family in [('587455', 'pavonnay-four'), ('rom-route19', 'route19-five')]:
            with self.subTest(family=family):
                units = module.profile_units(self.scene(module, source), family)
                proof = module.socket_proof(units)
                self.assertEqual(set(proof), {'outerWest', 'outerNorth', 'innerEast', 'innerSouth',
                                              'straightRepeat'})
                self.assertLessEqual(max(proof.values()), 1e-6)

    def test_profile_vertices_keep_the_original_uv_and_color_attributes(self):
        module = self.module()
        scene = self.scene(module, '587455')
        for unit in module.profile_units(scene, 'pavonnay-four'):
            for surface, triangle in unit['entries']:
                self.assertTrue(any(all(module.extraction.point_in_triangle(vertex, original)
                                        for vertex in triangle) for original in surface.triangles))

    def test_socket_mismatch_is_reported_instead_of_hidden(self):
        module = self.module()
        scene = self.scene(module, '587455')
        units = module.profile_units(scene, 'pavonnay-four')
        inner = next(unit for unit in units if unit['pieceRole'] == 'inner')
        inner['entries'] = [(surface, [[vertex[0], vertex[1] + .25, *vertex[2:]]
                                      for vertex in triangle]) for surface, triangle in inner['entries']]
        self.assertGreater(module.socket_proof(units)['innerEast'], .1)

    def test_composed_inside_corner_matches_the_original_four_unit_corner(self):
        module = self.module()
        self.assertTrue(hasattr(module, 'compose_inner_profile'), 'Inside-corner composition is missing')
        scene = self.scene(module, '587455')
        units = module.profile_units(scene, 'pavonnay-four')
        straight = next(unit for unit in units if unit['pieceRole'] == 'straight')
        original = next(unit for unit in units if unit['pieceRole'] == 'inner')
        composed = module.compose_inner_profile(scene, straight, 'measured-inner')
        from build_fence_units import geometry_error
        self.assertLessEqual(geometry_error(composed['entries'], original['entries'], 0), 1e-6)

    def test_urban_four_and_eight_unit_profiles_keep_their_source_shape(self):
        module = self.module()
        scene = self.scene(module, '587455')
        for family, upper in [('pavonnay-urban-four', 5), ('pavonnay-eight', 9)]:
            with self.subTest(family=family):
                self.assertIn(family, module.PROFILES, 'The original-height profile is missing')
                units = module.profile_units(scene, family)
                self.assertEqual({unit['pieceRole'] for unit in units}, {'straight', 'outer', 'inner'})
                self.assertLessEqual(max(module.socket_proof(units).values()), 1e-6)
                for unit in units:
                    bounds = module.extraction.entries_bounds(unit['entries'])
                    self.assertAlmostEqual(bounds[1], 1.0625)
                    self.assertAlmostEqual(bounds[4], upper)
                    self.assertLessEqual(bounds[3] - bounds[0], 1.000001)
                    self.assertLessEqual(bounds[5] - bounds[2], 1.000001)

    def test_composed_corner_keeps_source_attributes_and_only_rotates_the_profile(self):
        module = self.module()
        self.assertTrue(hasattr(module, 'compose_inner_profile'), 'Inside-corner composition is missing')
        scene = self.scene(module, '587455')
        units = module.profile_units(scene, 'pavonnay-four')
        straight = next(unit for unit in units if unit['pieceRole'] == 'straight')
        composed = module.compose_inner_profile(scene, straight, 'measured-inner')
        x, _, z = straight['support']
        originals = [(surface, triangle) for surface, triangle in straight['entries']]
        originals.extend((surface, [[x + vertex[2] - z, vertex[1], z - vertex[0] + x, *vertex[3:]]
                                    for vertex in triangle]) for surface, triangle in straight['entries'])
        for surface, triangle in composed['entries']:
            self.assertTrue(any(candidate_surface is surface and all(
                module.extraction.point_in_triangle(vertex, original) for vertex in triangle)
                for candidate_surface, original in originals))
        self.assertEqual([part['quarterTurns'] for part in composed['sourceComposition']], [0, 1])
        self.assertTrue(composed['assemblySourceReferences'])

    def test_small_ledge_profiles_keep_measured_heights_and_continuous_sockets(self):
        module = self.module()
        for source, family, lower, upper in [
            ('587455', 'pavonnay-bank-half', .5, 1),
            ('rom-route19', 'route19-bank-half', .5, 1),
            ('rom-route19', 'route19-step-one', 1, 2),
        ]:
            with self.subTest(family=family):
                self.assertIn(family, module.PROFILES, 'Reusable small ledge profile is missing')
                units = module.profile_units(self.scene(module, source), family)
                self.assertEqual({unit['pieceRole'] for unit in units}, {'straight', 'outer', 'inner'})
                self.assertLessEqual(max(module.socket_proof(units).values()), 1e-6)
                for unit in units:
                    bounds = module.extraction.entries_bounds(unit['entries'])
                    self.assertAlmostEqual(bounds[1], lower)
                    self.assertAlmostEqual(bounds[4], upper)
                    self.assertLessEqual(bounds[3] - bounds[0], 1.000001)
                    self.assertLessEqual(bounds[5] - bounds[2], 1.000001)

    def test_measured_rear_and_shallow_profiles_preserve_continuous_sockets(self):
        module = self.module()
        for source, family, lower, upper in [
            ('587455', 'pavonnay-back-cap-quarter', 8.75, 9),
            ('587455', 'pavonnay-back-eight', 1.0625, 9),
            ('rom-route19', 'route19-step-one-narrow', 3, 4),
            ('rom-route19', 'route19-step-one-shallow', 1.125, 2),
        ]:
            with self.subTest(family=family):
                self.assertIn(family, module.PROFILES)
                units = module.profile_units(self.scene(module, source), family)
                self.assertEqual({unit['pieceRole'] for unit in units}, {'straight', 'outer', 'inner'})
                self.assertLessEqual(max(module.socket_proof(units).values()), 1e-6)
                for unit in units:
                    bounds = module.extraction.entries_bounds(unit['entries'])
                    self.assertAlmostEqual(bounds[1], lower)
                    self.assertAlmostEqual(bounds[4], upper)

    def test_rear_profiles_declare_their_rotation_and_preserve_source_attributes(self):
        module = self.module()
        scene = self.scene(module, '587455')
        for family in ['pavonnay-back-cap-quarter', 'pavonnay-back-eight']:
            self.assertIn(family, module.PROFILES)
            units = module.profile_units(scene, family)
            straight = units[0]
            self.assertEqual(straight['sourceNormalizationQuarterTurns'], 2)
            restored = module.entries_rotated_about_support(straight['entries'], straight['support'], 2)
            for surface, triangle in restored:
                self.assertTrue(any(all(module.extraction.point_in_triangle(vertex, original)
                                        for vertex in triangle) for original in surface.triangles))
            self.assertEqual(straight['authoredOrientation'], 'west')
            self.assertTrue(straight['sourceOriginalReferences'])
            for corner in units[1:]:
                self.assertTrue(corner['assemblySourceReferences'])

    def test_rounded_step_corner_keeps_authentic_diagonal_faces_and_continuous_sockets(self):
        module = self.module()
        self.assertIn('route19-step-one-rounded', module.PROFILES)
        units = module.profile_units(self.scene(module, 'rom-route19'), 'route19-step-one-rounded')
        self.assertEqual({unit['pieceRole'] for unit in units}, {'straight', 'inner', 'outer'})
        self.assertLessEqual(max(module.socket_proof(units).values()), 1e-6)
        outer = next(unit for unit in units if unit['pieceRole'] == 'outer')
        self.assertNotIn('sourceComposition', outer)
        diagonal_faces = 0
        for surface, triangle in outer['entries']:
            normal = module.extraction.normal(triangle)
            diagonal_faces += abs(normal[0]) > 1e-6 and abs(normal[2]) > 1e-6
            self.assertTrue(any(all(module.extraction.point_in_triangle(vertex, original)
                                    for vertex in triangle) for original in surface.triangles))
        self.assertEqual(diagonal_faces, 4)
        for unit in units:
            bounds = module.extraction.entries_bounds(unit['entries'])
            self.assertAlmostEqual(bounds[1], 2)
            self.assertAlmostEqual(bounds[4], 3)
            self.assertLessEqual(bounds[3]-bounds[0], 1.000001)
            self.assertLessEqual(bounds[5]-bounds[2], 1.000001)

    def test_rounded_step_corner_is_not_a_composed_square_corner(self):
        module = self.module()
        self.assertIn('route19-step-one-rounded', module.PROFILES)
        scene = self.scene(module, 'rom-route19')
        units = module.profile_units(scene, 'route19-step-one-rounded')
        straight = next(unit for unit in units if unit['pieceRole'] == 'straight')
        original = next(unit for unit in units if unit['pieceRole'] == 'outer')
        composed = module.compose_outer_profile(scene, straight, 'square-comparison')
        from source_triangle_match import source_triangles_match
        self.assertFalse(source_triangles_match(module.centered_entries(original),
                                               module.centered_entries(composed)))

    def test_classic_body_connects_to_the_original_rounded_corner_without_merging_uv_variants(self):
        module = self.module()
        scene = self.scene(module, 'rom-route19')
        classic = {unit['pieceRole']: unit for unit in module.profile_units(scene, 'route19-step-one')}
        rounded = {unit['pieceRole']: unit for unit in module.profile_units(scene, 'route19-step-one-rounded')}
        assembled = [classic['straight'], rounded['outer'], classic['inner']]
        self.assertLessEqual(max(module.socket_proof(assembled).values()), 1e-6)
        from source_triangle_match import source_triangles_match
        self.assertFalse(source_triangles_match(module.centered_entries(classic['straight']),
                                               module.centered_entries(rounded['straight'])))
        self.assertNotIn('sourceComposition', rounded['outer'])

    def test_socket_frame_uses_authored_support_instead_of_bounding_box_center(self):
        module = self.module()
        scene = self.scene(module, '587455')
        entries = module.extraction.clip_selected(
            module.extraction.select_entries(scene['surfaces'], ['gake1_1']),
            [4, 42, 5, 43],
        )
        unit = module.extraction.unit(
            scene['id'], 'half-bank', 'relief', entries, [4.5, 1, 42.5],
            ['gake1_1'], [1, .5, 1],
        )
        centered = module.centered_entries(unit)
        bounds = module.extraction.entries_bounds(centered)
        self.assertAlmostEqual(bounds[2], -.5)
        self.assertAlmostEqual(bounds[5], 0)

    def test_check_only_preserves_the_kit_and_rejects_modified_geometry(self):
        module = self.module()
        self.assertTrue(hasattr(module, 'check'), 'Read-only kit qualification is missing')
        with tempfile.TemporaryDirectory() as temporary:
            args = SimpleNamespace(
                corpus=Path('/Users/karim/Downloads/pokemon-black2-white2-models-sans-pokemon'),
                route_source=Path('/Users/karim/Desktop/pokeMap Project/pokemon_nb2/.pokemap/authoring/routes-19-20/sources'),
                nitro=Path('/Users/karim/Downloads/avelune-bw2-animation-source'),
                output=Path(temporary) / 'kit',
            )
            with contextlib.redirect_stdout(io.StringIO()):
                module.build(args)
            before = {path: module.extraction.digest(path)
                      for path in args.output.rglob('*') if path.is_file()}
            result = module.check(args)
            self.assertTrue(result['valid'])
            self.assertEqual(result['models'], 36)
            self.assertEqual(result['families'], 12)
            self.assertEqual(before, {path: module.extraction.digest(path)
                                     for path in args.output.rglob('*') if path.is_file()})
            manifest = json.loads((args.output / 'manifest.json').read_text())
            model = args.output / manifest['models'][-1]['file']
            model.write_bytes(model.read_bytes() + b'changed')
            with self.assertRaisesRegex(ValueError, 'Derived model hash'):
                module.check(args)


if __name__ == '__main__':
    unittest.main()

import json
from pathlib import Path
import unittest
import subprocess
import sys
from tempfile import TemporaryDirectory

from complete_articulated_rotor import complete_rotor
from source_conversion_fixtures import rotor_recipe
from rigidify_bw2_animation import GlbWriter, accessor_rows, read_glb
from test_articulated_rotor import wheel_fixture, world_triangles


class RotorProfileTest(unittest.TestCase):
    def test_cli_refuses_colliding_inputs_and_outputs_without_changing_source(self):
        with TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / 'source.glb'
            data = wheel_fixture()
            source.write_bytes(data)
            recipe = root / 'recipe.json'
            recipe.write_text(json.dumps(rotor_recipe()))
            for output, receipt in [(source, root / 'receipt.json'),
                                    (root / 'output.glb', source),
                                    (root / 'shared', root / 'shared')]:
                result = subprocess.run([sys.executable, '-B', str(Path(__file__).with_name('complete_articulated_rotor.py')),
                    '--recipe', str(recipe), '--source', str(source),
                    '--output', str(output), '--receipt', str(receipt)], capture_output=True)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(source.read_bytes(), data)
                self.assertFalse((root / 'output.glb').exists())
                self.assertFalse((root / 'shared').exists())

    def test_distinct_node_names_and_clip_use_the_same_operation(self):
        recipe = rotor_recipe()
        source = wheel_fixture()
        original, binary = read_glb(source)
        renamed = json.loads(json.dumps(original))
        names = {node['name']: f'part-{index}' for index, node in enumerate(renamed['nodes'])}
        for node in renamed['nodes']:
            node['name'] = names[node['name']]
        renamed['animations'][0]['name'] = 'original-rotor'
        second = {**recipe, 'id': 'original', 'clipName': 'original-rotor',
                  'parentNode': names[recipe['parentNode']],
                  'fixedNode': names[recipe['fixedNode']],
                  'rotorNodes': [names[name] for name in recipe['rotorNodes']],
                  'cabinNodes': [names[name] for name in recipe['cabinNodes']]}
        for document, profile in [(original, recipe), (renamed, second)]:
            before = GlbWriter(document, binary).finish()
            completed, receipt = complete_rotor(before, recipe=profile)
            after, data = read_glb(completed)
            self.assertEqual(receipt['cabins'], 16)
            self.assertEqual(receipt['recipeId'], profile['id'])
            self.assertEqual(world_triangles(document, binary, 0), world_triangles(after, data, 0))

    def test_missing_or_invalid_recipe_is_refused(self):
        with self.assertRaises(TypeError):
            complete_rotor(wheel_fixture())
        for recipe in [None, {}, {'schemaVersion': 1, 'id': 'bad'}]:
            with self.subTest(recipe=recipe), self.assertRaises(ValueError):
                complete_rotor(wheel_fixture(), recipe=recipe)

    def test_a_different_static_part_count_is_declared_by_data(self):
        recipe = rotor_recipe()
        recipe = {**recipe, 'id': 'smaller-rotor', 'staticCabinCount': 7}
        document, binary = read_glb(wheel_fixture())
        writer = GlbWriter(document, binary)
        for primitive in document['meshes'][1]['primitives'][:5]:
            primitive['attributes'] = {
                name: writer.rows(accessor_rows(document, writer.binary, index)[:42],
                                  'VEC3' if name == 'POSITION' else 'VEC2')
                for name, index in primitive['attributes'].items()
            }
        completed, receipt = complete_rotor(writer.finish(), recipe=recipe)
        after, data = read_glb(completed)
        self.assertEqual(receipt['cabins'], 14)
        self.assertEqual(world_triangles(document, writer.binary, 0), world_triangles(after, data, 0))

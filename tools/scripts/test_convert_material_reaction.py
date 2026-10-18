from copy import deepcopy
from hashlib import sha256
from io import BytesIO
from pathlib import Path
import json
import struct
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

from PIL import Image

sys.dont_write_bytecode = True
sys.path[:0] = [str(Path(__file__).resolve().parent), str(Path(__file__).resolve().parents[1] / 'source_units')]
from convert_material_reaction import HIDDEN_SCALE, attach_material_reaction, convert, require_recipe
from nitro_materials import nitro_affine
from rigidify_bw2_animation import GlbWriter, accessor_rows, read_glb
from test_nitro_materials import model_container, srt_container


def fixture():
    document = {'asset': {'version': '2.0'}, 'scene': 0,
                'scenes': [{'nodes': [0]}], 'nodes': [{'mesh': 0}],
                'meshes': [], 'materials': [{'pbrMetallicRoughness': {}}]}
    writer = GlbWriter(document, b'')
    positions = writer.rows([[-.5, 0, -.5], [.5, 0, -.5], [0, .4, .5]], 'VEC3')
    uv = writer.rows([[0, 0], [1, 0], [.5, 1]], 'VEC2')
    document['meshes'] = [{'primitives': [{'attributes': {'POSITION': positions,
        'TEXCOORD_0': uv}, 'material': 0}]}]
    base = writer.finish()
    reaction = deepcopy(document)
    reaction['materials'][0] = {'name': 'cloth',
        'pbrMetallicRoughness': {'baseColorTexture': {'index': 0}}, 'alphaMode': 'MASK'}
    reaction['textures'] = [{'source': 0}]
    reaction['images'] = [{'uri': 'source.png'}]
    png = BytesIO()
    Image.new('RGBA', (2, 2), (0, 128, 0, 255)).save(png, format='PNG')
    return base, GlbWriter(reaction, bytes(writer.binary)).finish(), png.getvalue()


class MaterialReactionTests(unittest.TestCase):
    def test_two_declared_reactions_preserve_explicit_clock_geometry_pixels_and_inputs(self):
        for material, model_name, clip_name, fps in [('cloth', 'banner', 'flutter', 30), ('mist', 'spray', 'splash', 48)]:
            with self.subTest(material=material), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                source = root / 'source'
                source.mkdir()
                base, reaction, png = fixture()
                model = model_container().replace(b'water'.ljust(16, bytes(1)), material.encode().ljust(16, bytes(1)))
                model = model.replace(b'pool'.ljust(16, bytes(1)), model_name.encode().ljust(16, bytes(1)))
                (source / 'arbitrary-model.bin').write_bytes(model)
                animation = srt_container(45, [(0x20000000, 4096), (0x20000000, 4096),
                    (0x20000000, 4096 << 16), (0x10000000, struct.pack('<' + 'h' * 45, *range(45))),
                    (0x20000000, 0)], material)
                animation = animation.replace(b'test'.ljust(16, bytes(1)), clip_name.encode().ljust(16, bytes(1)))
                (source / 'arbitrary-animation.bin').write_bytes(animation)
                base_path = root / 'base' / 'base.glb'
                base_path.parent.mkdir()
                base_path.write_bytes(base)
                decoder = root / 'decoder' / 'decoder'
                decoder.parent.mkdir()
                decoder.write_bytes(b'controlled synthetic decoder')
                declaration = {
                    'schemaVersion': 1, 'id': 'declared-reaction', 'label': 'Declared reaction',
                    'baseSha256': sha256(base).hexdigest(), 'decoderSha256': sha256(decoder.read_bytes()).hexdigest(),
                    'sourceModel': {'relativePath': 'arbitrary-model.bin', 'sha256': sha256(model).hexdigest(), 'name': model_name},
                    'sourceAnimation': {'relativePath': 'arbitrary-animation.bin', 'sha256': sha256(animation).hexdigest(),
                                        'clip': clip_name, 'material': material, 'frames': 45},
                    'decodedGlb': {'fileName': 'decoded.glb', 'sha256': sha256(reaction).hexdigest()},
                    'texture': {'fileName': 'effect.png', 'sha256': sha256(png).hexdigest()},
                    'frameRate': fps, 'frameRateEvidence': 'Explicit synthetic scheduler',
                    'sourceUnitsPerCell': 16, 'matrixMode': 0, 'outputFile': 'reaction.glb',
                    'provenance': {'kind': 'synthetic-format-resources'}}
                before = {file: file.read_bytes() for folder in [source, base_path.parent, decoder.parent]
                          for file in folder.rglob('*') if file.is_file()}

                def decode(arguments, **kwargs):
                    self.assertNotEqual(Path(arguments[0]), decoder)
                    self.assertEqual(Path(arguments[0]).read_bytes(), before[decoder])
                    self.assertEqual(Path(arguments[2]).read_bytes(), model)
                    output = Path(arguments[arguments.index('-o') + 1])
                    output.mkdir()
                    (output / 'decoded.glb').write_bytes(reaction)
                    (output / 'effect.png').write_bytes(png)
                    return subprocess.CompletedProcess(arguments, 0, '', '')

                with patch('convert_material_reaction.subprocess.run', side_effect=decode):
                    proof = convert(base_path, source, root / 'output', recipe=declaration, decoder=decoder)
                self.assertEqual(proof['conversionFrameRate'], fps)
                self.assertEqual(proof['durationSeconds'], 45 / fps)
                self.assertEqual(proof['sourceMaterial'], material)
                self.assertEqual(before, {file: file.read_bytes() for file in before})
                self.assertTrue((root / 'output/reaction.glb').is_file())
                self.assertFalse(list(root.glob('.material-reaction-*')))
                bad_source = deepcopy(declaration)
                bad_source['sourceAnimation']['clip'] = 'undeclared'
                with self.assertRaisesRegex(ValueError, 'does not match source bytes'):
                    convert(base_path, source, root / 'missing-clip', recipe=bad_source, decoder=decoder)
                bad_texture = deepcopy(declaration)
                bad_texture['texture']['sha256'] = 'f' * 64
                with patch('convert_material_reaction.subprocess.run', side_effect=decode), self.assertRaisesRegex(ValueError, 'digest changed'):
                    convert(base_path, source, root / 'bad-texture', recipe=bad_texture, decoder=decoder)
                self.assertFalse((root / 'bad-texture').exists())
                self.assertFalse(list(root.glob('.material-reaction-*')))
                for mutate in [lambda value: value.update({'fallbackProfile': 'hidden'}),
                               lambda value: value.update({'schemaVersion': True}),
                               lambda value: value.update({'frameRate': 0}),
                               lambda value: value.update({'sourceUnitsPerCell': float('nan')}),
                               lambda value: value['sourceModel'].update({'relativePath': '../escape'})]:
                    invalid = deepcopy(declaration)
                    mutate(invalid)
                    with self.assertRaises(ValueError):
                        require_recipe(invalid)

    def test_refuses_untranslated_source_reaction_animations(self):
        base, reaction, png = fixture()
        document, binary = read_glb(reaction)
        document['animations'] = [{'name': 'untranslated source motion'}]
        with self.assertRaisesRegex(ValueError, 'reaction source animation'):
            attach_material_reaction(base, GlbWriter(document, binary).finish(), png,
                [[1, 1, 0, 1, 0, 0]] * 3, 30, source_units_per_cell=16, matrix_mode=0, label='Synthetic reaction')

    def test_explicit_source_clock_keeps_45_frames_at_one_and_a_half_seconds(self):
        base, reaction, png = fixture()
        samples = [[1, 1, 0, 1, frame / 45, 0] for frame in range(45)]
        result, proof = attach_material_reaction(base, reaction, png, samples, 30, source_units_per_cell=16, matrix_mode=0, label='Synthetic reaction')
        document, binary = read_glb(result)
        visibility = document['animations'][0]['samplers'][0]
        visibility_times = accessor_rows(document, binary, visibility['input'])
        clip = document['extras']['aveluneMaterialAnimations']['clips'][0]
        self.assertEqual(proof['conversionFrameRate'], 30)
        self.assertEqual(proof['durationSeconds'], 1.5)
        self.assertAlmostEqual(visibility_times[1][0], 1 / 30)
        self.assertEqual(visibility_times[-1], [1.5])
        self.assertEqual(clip['durationSeconds'], 1.5)
        self.assertEqual(clip['tracks'][0]['times'], [frame / 30 for frame in range(45)] + [1.5])
    
    def test_base_geometry_and_pixels_remain_separate_from_original_reaction(self):
        base, reaction, png = fixture()
        samples = [[1, 1, 0, 1, 0, 0], [1, 1, 0, 1, 0.25, -0.125], [1, 1, 0, 1, 0, 0]]
        result, proof = attach_material_reaction(base, reaction, png, samples, 60, source_units_per_cell=16, matrix_mode=0, label='Synthetic reaction')
        before, binary = read_glb(base)
        after, target = read_glb(result)
        self.assertEqual(target[:len(binary)], binary)
        for key in ['materials', 'meshes', 'nodes', 'accessors', 'bufferViews']:
            self.assertEqual(after[key][:len(before[key])], before[key])
        self.assertEqual(after['nodes'][-1]['scale'], [HIDDEN_SCALE] * 3)
        self.assertEqual(after['materials'][-1]['alphaCutoff'], 0.5)
        animation = after['animations'][0]
        sampler = animation['samplers'][0]
        scales = accessor_rows(after, target, sampler['output'])
        self.assertEqual(scales[1], [1, 1, 1])
        for row in [scales[0], scales[-1]]:
            self.assertTrue(all((0 < value < 1e-08 for value in row)))
        clip = after['extras']['aveluneMaterialAnimations']['clips'][0]
        self.assertEqual(clip['nodeAnimationIndex'], 0)
        self.assertEqual(clip['tracks'][0]['transforms'], [nitro_affine(sample, 0, 2, 2) for sample in samples] + [nitro_affine(samples[0], 0, 2, 2)])
        self.assertEqual(proof['animationIndex'], 1)
        self.assertEqual(proof['addedTriangles'], 1)
        view = after['bufferViews'][after['images'][-1]['bufferView']]
        self.assertEqual(target[view['byteOffset']:view['byteOffset'] + view['byteLength']], png)
    
    def test_refuses_an_already_animated_base(self):
        base, reaction, png = fixture()
        document, binary = read_glb(base)
        document['animations'] = [{'name': 'existing'}]
        with self.assertRaisesRegex(ValueError, 'static base'):
            attach_material_reaction(GlbWriter(document, binary).finish(), reaction, png, [[1, 1, 0, 1, 0, 0]] * 3, 60, source_units_per_cell=16, matrix_mode=0, label='Synthetic reaction')
    
    def test_refuses_invalid_clock_and_samples(self):
        base, reaction, png = fixture()
        for fps, samples in [(0, [[1, 1, 0, 1, 0, 0]] * 3), (float('nan'), [[1, 1, 0, 1, 0, 0]] * 3), (60, [[1, 1, 0, 1, 0, 0]]), (60, [[1, 1, 0, 1, float('nan'), 0]] * 3)]:
            with self.assertRaises(ValueError):
                attach_material_reaction(base, reaction, png, samples, fps, source_units_per_cell=16, matrix_mode=0, label='Synthetic reaction')
    
    def test_refuses_a_source_hierarchy_transform(self):
        base, reaction, png = fixture()
        document, binary = read_glb(reaction)
        document['nodes'][0]['translation'] = [1, 0, 0]
        with self.assertRaisesRegex(ValueError, 'source transform'):
            attach_material_reaction(base, GlbWriter(document, binary).finish(), png, [[1, 1, 0, 1, 0, 0]] * 3, 60, source_units_per_cell=16, matrix_mode=0, label='Synthetic reaction')

if __name__ == '__main__':
    unittest.main()


from collections import defaultdict
from copy import deepcopy
from io import BytesIO
from hashlib import sha256
import json
from pathlib import Path
import sys
from tempfile import TemporaryDirectory
from types import SimpleNamespace
import unittest

from PIL import Image

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
sys.path.insert(0, str(Path(__file__).resolve().parent))
from material_animation import NitroSources, animated_material_document
from test_nitro_materials import model_container, srt_container
import struct


def fixture(material, texture, clip, model):
    image = BytesIO()
    Image.new('RGBA', (2, 3), (12, 78, 123, 255)).save(image, 'PNG')
    binary = image.getvalue()
    document = {
        'materials': [{'name': texture, 'pbrMetallicRoughness': {'baseColorTexture': {'index': 0}}}],
        'images': [{'bufferView': 0}], 'textures': [{'source': 0}],
        'bufferViews': [{'buffer': 0, 'byteOffset': 0, 'byteLength': len(binary)}],
        'meshes': [{'primitives': [{'material': 0}]}],
    }
    track = {'material': material, 'clip': clip, 'frames': 2,
             'samples': [[1, 1, 0, 1, 0, 0], [1, 1, 0, 1, .25, .5]],
             'source': {'sha256': 'a' * 64, 'origins': [{'path': 'animations/source.bin'}]}}
    sources = SimpleNamespace(by_material=defaultdict(list, {material: [track]}),
                              modes=lambda names, name: {0} if names == {model} and name == material else set())
    context = {'materials': {material: {'textures': [texture], 'groups': ['unrelated/sector']}}}
    binding = {material: {'sourceClip': clip, 'sourceModelNames': [model], 'matrixModeEvidence': 'exact_source_model'}}
    return document, binary, sources, context, binding


class ExplicitMaterialAnimationTest(unittest.TestCase):
    def test_pinned_format_sources_use_declared_models_without_filename_heuristics(self):
        for material, model, clip in [('liquid', 'basin', 'flow'), ('cloth', 'banner', 'flutter')]:
            with self.subTest(material=material), TemporaryDirectory() as temporary:
                root = Path(temporary)
                (root / 'nitro-original').mkdir()
                (root / 'witness').mkdir()
                model_bytes = model_container().replace(b'water'.ljust(16, b'\0'), material.encode().ljust(16, b'\0'))
                model_bytes = model_bytes.replace(b'pool'.ljust(16, b'\0'), model.encode().ljust(16, b'\0'))
                data = srt_container(3, [(0x20000000, 4096), (0x20000000, 4096),
                    (0x20000000, 4096 << 16), (0x10000000, struct.pack('<hhh', 0, -1024, -2048)),
                    (0x20000000, 0)], material)
                data = data.replace(b'test'.ljust(16, b'\0'), clip.encode().ljust(16, b'\0'))
                (root / 'nitro-original/source.dat').write_bytes(data)
                (root / 'witness/unrelated.bin').write_bytes(model_bytes)
                record = {'type': 'SRT0', 'tracks': [{'material': material}], 'name': clip,
                          'sha256': sha256(data).hexdigest(), 'extracted_files': ['source.dat'],
                          'origins': [{'path': 'synthetic-format-resource'}]}
                (root / 'animation-inventory.json').write_text(json.dumps({'animations': [record]}))
                sources = NitroSources(root, {material}, model_sources=[{
                    'relativePath': 'witness/unrelated.bin', 'sha256': sha256(model_bytes).hexdigest()}])
                document, binary, _, context, bindings = fixture(material, 'art.png', clip, model)
                animated, evidence, unsupported = animated_material_document(document, binary,
                    {'sourceMaterial': material}, context, sources, 30, bindings=bindings, clip_name='Declared')
                self.assertEqual(unsupported, [])
                self.assertEqual(evidence[0]['animationSha256'], sha256(data).hexdigest())
                self.assertEqual(animated['extras']['aveluneMaterialAnimations']['clips'][0]['durationSeconds'], .1)
                (root / 'witness/unrelated.bin').write_bytes(b'changed')
                with self.assertRaisesRegex(ValueError, 'digest changed'):
                    NitroSources(root, {material}, model_sources=[{
                        'relativePath': 'witness/unrelated.bin', 'sha256': sha256(model_bytes).hexdigest()}])

    def test_two_unrelated_datasets_use_only_declared_associations_and_cadence(self):
        for material, texture, clip, model, fps in [('liquid', 'cyan.png', 'flow', 'basin', 30),
                                                   ('cloth', 'amber.png', 'flutter', 'banner', 48)]:
            with self.subTest(material=material):
                document, binary, sources, context, bindings = fixture(material, texture, clip, model)
                before = deepcopy(document)
                result, evidence, unsupported = animated_material_document(
                    document, binary, {'sourceMaterial': material}, context, sources, fps,
                    bindings=bindings, clip_name='Declared animation')
                self.assertEqual(unsupported, [])
                self.assertEqual(evidence[0]['animation'], clip)
                self.assertEqual(evidence[0]['modelNames'], [model])
                animation = result['extras']['aveluneMaterialAnimations']['clips'][0]
                self.assertEqual(animation['name'], 'Declared animation')
                self.assertEqual(animation['tracks'][0]['times'], [0, 1 / fps, 2 / fps])
                self.assertEqual(document, before)

    def test_missing_explicit_clip_never_uses_ambient_or_model_naming(self):
        document, binary, sources, context, bindings = fixture('cloth', 'amber.png', 'flow', 'banner')
        bindings['cloth']['sourceClip'] = 'other'
        result, _, unsupported = animated_material_document(document, binary, {'sourceMaterial': 'cloth'},
            context, sources, 30, bindings=bindings, clip_name='Declared animation')
        self.assertIsNone(result)
        self.assertEqual(unsupported[0]['reason'], 'missing_or_ambiguous_declared_source_clip')

    def test_incomplete_bindings_and_ambiguous_modes_refuse(self):
        document, binary, sources, context, bindings = fixture('cloth', 'amber.png', 'flow', 'banner')
        with self.assertRaises(ValueError):
            animated_material_document(document, binary, {}, context, sources, 30,
                                       bindings={'cloth': {'sourceClip': 'flow'}}, clip_name='Declared animation')
        sources.modes = lambda names, name: {0, 2}
        result, _, unsupported = animated_material_document(document, binary, {'sourceMaterial': 'cloth'},
            context, sources, 30, bindings=bindings, clip_name='Declared animation')
        self.assertIsNone(result)
        self.assertEqual(unsupported[0]['reason'], 'missing_or_ambiguous_source_matrix_mode')


if __name__ == '__main__':
    unittest.main()

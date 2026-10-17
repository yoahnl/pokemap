from copy import deepcopy
from io import BytesIO
from pathlib import Path
import sys
import unittest

from PIL import Image

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))

from convert_bw2_grass_reaction import HIDDEN_SCALE, attach_original_grass_reaction
from read_bw2_nitro_animations import nitro_affine
from rigidify_bw2_animation import GlbWriter, accessor_rows, read_glb


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
    reaction['materials'][0] = {'name': 'ee_kusa_sp_lm1',
        'pbrMetallicRoughness': {'baseColorTexture': {'index': 0}}, 'alphaMode': 'MASK'}
    reaction['textures'] = [{'source': 0}]
    reaction['images'] = [{'uri': 'source.png'}]
    png = BytesIO()
    Image.new('RGBA', (2, 2), (0, 128, 0, 255)).save(png, format='PNG')
    return base, GlbWriter(reaction, bytes(writer.binary)).finish(), png.getvalue()


class GrassReactionTests(unittest.TestCase):
    def test_base_geometry_and_pixels_remain_separate_from_original_reaction(self):
        base, reaction, png = fixture()
        samples = [[1, 1, 0, 1, 0, 0], [1, 1, 0, 1, .25, -.125], [1, 1, 0, 1, 0, 0]]
        result, proof = attach_original_grass_reaction(base, reaction, png, samples, 60)
        before, binary = read_glb(base)
        after, target = read_glb(result)
        self.assertEqual(target[:len(binary)], binary)
        for key in ['materials', 'meshes', 'nodes', 'accessors', 'bufferViews']:
            self.assertEqual(after[key][:len(before[key])], before[key])
        self.assertEqual(after['nodes'][-1]['scale'], [HIDDEN_SCALE] * 3)
        self.assertEqual(after['materials'][-1]['alphaCutoff'], .5)
        animation = after['animations'][0]
        sampler = animation['samplers'][0]
        scales = accessor_rows(after, target, sampler['output'])
        self.assertEqual(scales[1], [1, 1, 1])
        for row in [scales[0], scales[-1]]:
            self.assertTrue(all(0 < value < 1e-8 for value in row))
        clip = after['extras']['aveluneMaterialAnimations']['clips'][0]
        self.assertEqual(clip['nodeAnimationIndex'], 0)
        self.assertEqual(clip['tracks'][0]['transforms'],
                         [nitro_affine(sample, 0, 2, 2) for sample in samples] + [nitro_affine(samples[0], 0, 2, 2)])
        self.assertEqual(proof['animationIndex'], 1)
        self.assertEqual(proof['addedTriangles'], 1)
        view = after['bufferViews'][after['images'][-1]['bufferView']]
        self.assertEqual(target[view['byteOffset']:view['byteOffset'] + view['byteLength']], png)

    def test_refuses_an_already_animated_base(self):
        base, reaction, png = fixture()
        document, binary = read_glb(base)
        document['animations'] = [{'name': 'existing'}]
        with self.assertRaisesRegex(ValueError, 'static base'):
            attach_original_grass_reaction(GlbWriter(document, binary).finish(), reaction,
                                          png, [[1, 1, 0, 1, 0, 0]] * 3, 60)

    def test_refuses_invalid_clock_and_samples(self):
        base, reaction, png = fixture()
        for fps, samples in [(0, [[1, 1, 0, 1, 0, 0]] * 3),
                             (float('nan'), [[1, 1, 0, 1, 0, 0]] * 3),
                             (60, [[1, 1, 0, 1, 0, 0]]),
                             (60, [[1, 1, 0, 1, float('nan'), 0]] * 3)]:
            with self.assertRaises(ValueError):
                attach_original_grass_reaction(base, reaction, png, samples, fps)

    def test_refuses_a_source_hierarchy_transform(self):
        base, reaction, png = fixture()
        document, binary = read_glb(reaction)
        document['nodes'][0]['translation'] = [1, 0, 0]
        with self.assertRaisesRegex(ValueError, 'source transform'):
            attach_original_grass_reaction(base, GlbWriter(document, binary).finish(),
                                          png, [[1, 1, 0, 1, 0, 0]] * 3, 60)


if __name__ == '__main__':
    unittest.main()

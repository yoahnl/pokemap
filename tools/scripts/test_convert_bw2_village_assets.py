from io import BytesIO
from pathlib import Path
import json
import os
import struct
import tempfile
import unittest
import zipfile

from PIL import Image

from convert_bw2_village_assets import convert_dae, emit_model, extract, path_atlas, read_archive


def texture(alpha=(255, 255)):
    image = Image.new('RGBA', (2, 1))
    image.putdata([(200, 100, 40, value) for value in alpha])
    result = BytesIO()
    image.save(result, format='PNG')
    return result.getvalue()


def source(colors='1 1 1 1 1 1 1 1 1 1 1 1', indices='0 1 2 3'):
    return f'''<COLLADA xmlns="http://www.collada.org/2005/11/COLLADASchema" version="1.4.1">
      <asset><up_axis>Y_UP</up_axis></asset>
      <library_images><image id="image"><init_from>art.png</init_from></image></library_images>
      <library_effects><effect id="effect"><profile_COMMON>
        <newparam sid="surface"><surface type="2D"><init_from>image</init_from></surface></newparam>
        <newparam sid="sampler"><sampler2D><source>surface</source><wrap_s>CLAMP</wrap_s><wrap_t>CLAMP</wrap_t></sampler2D></newparam>
        <technique><phong><diffuse><texture texture="sampler" texcoord="tc"/></diffuse></phong></technique>
      </profile_COMMON></effect></library_effects>
      <library_materials><material id="material"><instance_effect url="#effect"/></material></library_materials>
      <library_geometries><geometry id="geometry"><mesh>
        <source id="positions"><float_array id="positions-array" count="12">0 0 0 16 0 0 16 16 0 0 16 0</float_array><technique_common><accessor source="#positions-array" count="4" stride="3"/></technique_common></source>
        <source id="uvs"><float_array id="uvs-array" count="8">0 0 1 0 1 1 0 1</float_array><technique_common><accessor source="#uvs-array" count="4" stride="2"/></technique_common></source>
        <source id="colors"><float_array id="colors-array" count="12">{colors}</float_array><technique_common><accessor source="#colors-array" count="4" stride="3"/></technique_common></source>
        <vertices id="vertices"><input semantic="POSITION" source="#positions"/><input semantic="TEXCOORD" source="#uvs"/><input semantic="COLOR" source="#colors"/></vertices>
        <polylist material="art" count="1"><input semantic="VERTEX" source="#vertices" offset="0"/><vcount>4</vcount><p>{indices}</p></polylist>
      </mesh></geometry></library_geometries>
      <library_visual_scenes><visual_scene id="scene"><node id="node"><instance_geometry url="#geometry"><bind_material><technique_common><instance_material symbol="art" target="#material"><bind_vertex_input semantic="tc" input_semantic="TEXCOORD"/></instance_material></technique_common></bind_material></instance_geometry></node></visual_scene></library_visual_scenes>
      <scene><instance_visual_scene url="#scene"/></scene>
    </COLLADA>'''.encode()


def area(surfaces):
    total = 0
    for vertices in surfaces.values():
        for start in range(0, len(vertices), 3):
            a, b, c = vertices[start:start + 3]
            total += abs((b[0] - a[0]) * (c[1] - a[1]) - (c[0] - a[0]) * (b[1] - a[1])) / 2
    return total


class VillageConversionTest(unittest.TestCase):
    def test_path_atlas_only_reassembles_native_source_pixels(self):
        edge, center = Image.new('RGBA', (32, 16)), Image.new('RGBA', (16, 16))
        edge.putdata([(x, y, 80, 255) for y in range(16) for x in range(32)])
        center.putdata([(120, x, y, 255) for y in range(16) for x in range(16)])
        a, b = BytesIO(), BytesIO()
        edge.save(a, format='PNG')
        center.save(b, format='PNG')
        result = Image.open(BytesIO(path_atlas(a.getvalue(), b.getvalue())))
        self.assertEqual(result.size, (256, 16))
        self.assertTrue(set(result.get_flattened_data()).issubset(set(edge.get_flattened_data()) | set(center.get_flattened_data())))
        self.assertEqual(list(result.crop((240, 0, 256, 16)).get_flattened_data()), list(center.get_flattened_data()))

    def test_opaque_art_and_native_scale_are_preserved(self):
        result = convert_dae(source(), {'art.png': texture()})
        self.assertAlmostEqual(area(result['surfaces']), 1)
        self.assertEqual(len(next(iter(result['surfaces'].values()))), 6)
        self.assertEqual(result['textures']['art.png'], texture())

    def test_alpha_pixels_remain_authentic_without_geometry_tessellation(self):
        result = convert_dae(source(), {'art.png': texture((255, 0))})
        self.assertAlmostEqual(area(result['surfaces']), 1)
        self.assertEqual(result['textures']['art.png'], texture((255, 0)))
        self.assertEqual(result['outputTriangleCount'], 2)

    def test_native_vertex_shading_is_retained_in_vertex_attributes(self):
        result = convert_dae(source(colors=' '.join(['.5'] * 12)), {'art.png': texture()})
        self.assertTrue(all(vertex[5:8] == [.5, .5, .5] for vertices in result['surfaces'].values() for vertex in vertices))
        self.assertAlmostEqual(area(result['surfaces']), 1)

    def test_varying_vertex_shading_survives_conversion(self):
        result = convert_dae(source(colors='1 1 1 .5 .5 .5 .5 .5 .5 1 1 1'), {'art.png': texture()})
        colors = {tuple(vertex[5:8]) for vertices in result['surfaces'].values() for vertex in vertices}
        self.assertEqual(colors, {(1, 1, 1), (.5, .5, .5)})

    def test_non_shadow_partial_alpha_is_rejected(self):
        with self.assertRaisesRegex(ValueError, 'Partial alpha'):
            convert_dae(source(), {'art.png': texture((255, 127))})

    def test_animated_sources_are_rejected(self):
        data = source().replace(b'<asset>', b'<library_animations><animation id="animated"/></library_animations><asset>')
        with self.assertRaisesRegex(ValueError, 'Animated'):
            convert_dae(data, {'art.png': texture()})

    def test_controllers_require_explicit_static_geometry_selection(self):
        data = source().replace(b'<asset>', b'<library_controllers><controller id="skin"/></library_controllers><asset>')
        with self.assertRaisesRegex(ValueError, 'Controllers'):
            convert_dae(data, {'art.png': texture()})

    def test_self_crossing_source_polygons_are_rejected(self):
        with self.assertRaisesRegex(ValueError, 'convex'):
            convert_dae(source(indices='0 2 1 3'), {'art.png': texture()})

    def test_glb_has_embedded_mask_images_and_float_colors(self):
        result = convert_dae(source(), {'art.png': texture((255, 0))})
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'fixture.glb'
            metrics = emit_model(path, result)
            data = path.read_bytes()
        self.assertEqual(struct.unpack_from('<III', data), (0x46546C67, 2, len(data)))
        self.assertEqual(metrics['triangleCount'], sum(len(v) // 3 for v in result['surfaces'].values()))
        document = json.loads(data[20:20 + struct.unpack_from('<I', data, 12)[0]])
        self.assertEqual(document['materials'][0]['alphaMode'], 'MASK')
        self.assertEqual(document['materials'][0]['alphaCutoff'], .5)
        self.assertNotIn('uri', document['images'][0])
        index = document['meshes'][0]['primitives'][0]['attributes']['COLOR_0']
        self.assertEqual(document['accessors'][index]['type'], 'VEC4')
        self.assertEqual(document['accessors'][index]['componentType'], 5126)

    def test_native_mirror_sampler_is_preserved(self):
        data = source().replace(b'<wrap_s>CLAMP</wrap_s>', b'<wrap_s>MIRROR</wrap_s>')
        result = convert_dae(data, {'art.png': texture()})
        self.assertEqual(result['samplers']['art.png'], ['MIRROR', 'CLAMP'])

    def test_explicit_crossed_panels_are_double_sided_without_extra_triangles(self):
        result = convert_dae(source(), {'art.png': texture()}, [{'geometry': 'geometry', 'materials': {'art': 'material'}, 'doubleSided': True}])
        self.assertEqual(result['outputTriangleCount'], 2)
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'fixture.glb'
            emit_model(path, result)
            data = path.read_bytes()
        document = json.loads(data[20:20 + struct.unpack_from('<I', data, 12)[0]])
        self.assertTrue(document['materials'][0]['doubleSided'])

    def test_nonplanar_convex_quad_keeps_its_source_corners(self):
        data = source().replace(b'16 16 0 0 16 0', b'16 16 1 0 16 0')
        result = convert_dae(data, {'art.png': texture()})
        self.assertEqual(result['outputTriangleCount'], 2)
        self.assertTrue(any(vertex[2] == 1 / 16 for vertices in result['surfaces'].values() for vertex in vertices))

    def test_native_duplicate_corner_drops_only_the_empty_triangle(self):
        data = source().replace(b'16 16 0 0 16 0', b'16 16 0 16 16 0')
        result = convert_dae(data, {'art.png': texture()})
        self.assertEqual(result['outputTriangleCount'], 1)
        self.assertEqual(result['omitted'][0]['discardedTriangles'], 1)

    def test_archive_integrity_is_checked_before_decoding(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'source.zip').write_bytes(b'bad source')
            with self.assertRaisesRegex(ValueError, 'digest mismatch'):
                read_archive(root, {'local_path': 'source.zip', 'name': 'Fixture'}, '0' * 64)


@unittest.skipUnless(os.environ.get('AVELUNE_BW2_SOURCE_ROOT'), 'Optional read-only NB2 corpus not supplied')
class VillageCorpusTest(unittest.TestCase):
    def test_complete_selected_corpus_is_reproducible_and_self_contained(self):
        source_root = Path(os.environ['AVELUNE_BW2_SOURCE_ROOT'])
        with tempfile.TemporaryDirectory() as first, tempfile.TemporaryDirectory() as second:
            a, b = Path(first), Path(second)
            manifest = extract(source_root, a)
            extract(source_root, b)
            self.assertEqual(len(manifest['models']), 21)
            self.assertEqual(len(manifest['terrainTextures']), 14)
            self.assertEqual({path.name: path.read_bytes() for path in a.iterdir()}, {path.name: path.read_bytes() for path in b.iterdir()})
            for model in manifest['models']:
                data = (a / model['file']).read_bytes()
                json_length = struct.unpack_from('<I', data, 12)[0]
                document = json.loads(data[20:20 + json_length])
                binary = data[28 + json_length:]
                self.assertTrue(all(material['alphaMode'] in ('OPAQUE', 'MASK') for material in document['materials']))
                self.assertEqual(model['groundAnchor'], [0, 0, 0])
                self.assertAlmostEqual(model['bounds'][1], 0)
                with zipfile.ZipFile(source_root / model['source']['archive']) as archive:
                    source_images = {archive.read(name) for name in archive.namelist() if name.endswith('.png')}
                for image in document['images']:
                    view = document['bufferViews'][image['bufferView']]
                    embedded = binary[view['byteOffset']:view['byteOffset'] + view['byteLength']]
                    self.assertIn(embedded, source_images)


if __name__ == '__main__':
    unittest.main()

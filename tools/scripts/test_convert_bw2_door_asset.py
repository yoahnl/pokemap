import hashlib
import importlib.util
import json
import math
import os
from pathlib import Path
import struct
import tempfile
import unittest
import xml.etree.ElementTree as ET
import zipfile


SCRIPT = Path(__file__).with_name('convert_bw2_door_asset.py')
SOURCE = Path('/Users/karim/Downloads/pokemon-black2-white2-models-sans-pokemon')
NS = {'c': 'http://www.collada.org/2005/11/COLLADASchema'}
IDENTITY = '1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1'
PNG = bytes.fromhex('89504e470d0a1a0a0000000d49484452000000010000000108060000001f15c4890000000d49444154789c63f8ffffff7f0009fb03fd2a86e38a0000000049454e44ae426082')


def fixture():
    def source(identifier, values, stride=1, kind='float'):
        array = 'Name_array' if kind == 'Name' else 'float_array'
        return f'<source id="{identifier}"><{array} id="{identifier}-array" count="{len(values.split())}">{values}</{array}><technique_common><accessor source="#{identifier}-array" count="{len(values.split()) // stride}" stride="{stride}"/></technique_common></source>'

    def animation(identifier, matrices):
        return f'<animation id="{identifier}">{source(identifier + "-time", "0 0.25")}{source(identifier + "-matrix", matrices, 16)}{source(identifier + "-interpolation", "LINEAR LINEAR", kind="Name")}<sampler id="{identifier}-sampler"><input semantic="INPUT" source="#{identifier}-time"/><input semantic="OUTPUT" source="#{identifier}-matrix"/><input semantic="INTERPOLATION" source="#{identifier}-interpolation"/></sampler><channel source="#{identifier}-sampler" target="joint0/transform"/></animation>'

    translated = '1 0 0 2 0 1 0 0 0 0 1 0 0 0 0 1'
    turned = '0 0 -1 2 0 1 0 0 1 0 0 -1 0 0 0 1'
    return f'''<COLLADA xmlns="{NS['c']}" version="1.4.1">
<asset><up_axis>Y_UP</up_axis></asset>
<library_images><image id="image"><init_from>door.png</init_from></image></library_images>
<library_materials><material id="material"><instance_effect url="#effect"/></material></library_materials>
<library_effects><effect id="effect"><profile_COMMON><newparam sid="surface"><surface type="2D"><init_from>image</init_from></surface></newparam><newparam sid="sampler"><sampler2D><source>surface</source><wrap_s>CLAMP</wrap_s><wrap_t>CLAMP</wrap_t><minfilter>NEAREST</minfilter><magfilter>NEAREST</magfilter></sampler2D></newparam><technique sid="common"><phong><diffuse><texture texture="sampler" texcoord="tc"/></diffuse></phong></technique></profile_COMMON></effect></library_effects>
<library_geometries><geometry id="geometry"><mesh>
{source('positions', '2 0 0 2 16 0 18 16 0 18 0 0', 3)}
{source('texcoords', '0 0 0 1 1 1 1 0', 2)}
{source('normals', '0 0 -1 0 0 -1 0 0 -1 0 0 -1', 3)}
{source('colors', '1 1 1 1 1 1 1 1 1 1 1 1', 3)}
<vertices id="vertices"><input semantic="POSITION" source="#positions"/><input semantic="TEXCOORD" source="#texcoords"/><input semantic="NORMAL" source="#normals"/><input semantic="COLOR" source="#colors"/></vertices>
<polylist material="slot" count="1"><input semantic="VERTEX" source="#vertices" offset="0"/><vcount>4</vcount><p>0 1 2 3</p></polylist>
</mesh></geometry></library_geometries>
<library_controllers><controller id="controller"><skin source="#geometry"><bind_shape_matrix>1 0 0 0 0 1 0 3 0 0 1 0 0 0 0 1</bind_shape_matrix>
{source('joints', 'joint0', kind='Name')}{source('inverse', '1 0 0 -2 0 1 0 0 0 0 1 0 0 0 0 1', 16)}{source('weights', '1')}
<joints><input semantic="JOINT" source="#joints"/><input semantic="INV_BIND_MATRIX" source="#inverse"/></joints>
<vertex_weights count="4"><input semantic="JOINT" source="#joints" offset="0"/><input semantic="WEIGHT" source="#weights" offset="1"/><vcount>1 1 1 1</vcount><v>0 0 0 0 0 0 0 0</v></vertex_weights>
</skin></controller></library_controllers>
<library_animations>{animation('open', translated + ' ' + turned)}{animation('close', turned + ' ' + translated)}</library_animations>
<library_animation_clips><animation_clip id="op" name="door_op" end="0.25"><instance_animation url="#open"/></animation_clip><animation_clip id="cl" name="door_cl" end="0.25"><instance_animation url="#close"/></animation_clip></library_animation_clips>
<library_visual_scenes><visual_scene id="scene"><node id="joint0" sid="joint0" type="JOINT"><matrix sid="transform">{translated}</matrix></node><node id="mesh"><instance_controller url="#controller"><skeleton>#joint0</skeleton><bind_material><technique_common><instance_material symbol="slot" target="#material"><bind_vertex_input semantic="tc" input_semantic="TEXCOORD"/></instance_material></technique_common></bind_material></instance_controller></node></visual_scene></library_visual_scenes><scene><instance_visual_scene url="#scene"/></scene>
</COLLADA>'''.encode()


def read_glb(data):
    assert struct.unpack_from('<III', data) == (0x46546C67, 2, len(data))
    size, kind = struct.unpack_from('<II', data, 12)
    assert kind == 0x4E4F534A
    document = json.loads(data[20:20 + size])
    offset = 20 + size
    size, kind = struct.unpack_from('<II', data, offset)
    assert kind == 0x004E4942
    assert offset + 8 + size == len(data)
    return document, data[offset + 8:]


def accessor(document, binary, index):
    entry = document['accessors'][index]
    view = document['bufferViews'][entry['bufferView']]
    size = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}[entry['type']]
    format_code = {5126: 'f', 5123: 'H'}[entry['componentType']]
    stride = struct.calcsize('<' + format_code * size)
    return [struct.unpack_from('<' + format_code * size, binary, view['byteOffset'] + i * stride)
            for i in range(entry['count'])]


def transform(position, translation, rotation, scale):
    x, y, z, w = rotation
    scaled = [position[i] * scale[i] for i in range(3)]
    cross = [y * scaled[2] - z * scaled[1], z * scaled[0] - x * scaled[2], x * scaled[1] - y * scaled[0]]
    twice = [2 * v for v in cross]
    second = [y * twice[2] - z * twice[1], z * twice[0] - x * twice[2], x * twice[1] - y * twice[0]]
    return [scaled[i] + w * twice[i] + second[i] + translation[i] for i in range(3)]


def midpoint_rotation(a, b):
    a = [v / math.sqrt(sum(x * x for x in a)) for v in a]
    b = [v / math.sqrt(sum(x * x for x in b)) for v in b]
    dot = sum(x * y for x, y in zip(a, b))
    if dot < 0:
        b = [-v for v in b]
    result = [x + y for x, y in zip(a, b)]
    return [v / math.sqrt(sum(x * x for x in result)) for v in result]


if SCRIPT.exists():
    SPEC = importlib.util.spec_from_file_location('bw2_door', SCRIPT)
    DOOR = importlib.util.module_from_spec(SPEC)
    SPEC.loader.exec_module(DOOR)
else:
    DOOR = None


class ConverterPresenceTest(unittest.TestCase):
    def test_converter_exists(self):
        self.assertTrue(SCRIPT.exists(), 'The BW2 rigid door converter is missing')


@unittest.skipIf(DOOR is None, 'Converter implementation is missing')
class DoorConverterTest(unittest.TestCase):
    def test_rigid_conversion_applies_inverse_bind_and_bind_shape(self):
        data, receipt = DOOR.convert_dae(fixture(), {'door.png': PNG})
        document, binary = read_glb(data)
        self.assertNotIn('skins', document)
        self.assertEqual(document['nodes'][0]['scale'], [1 / 16] * 3)
        self.assertTrue(all('matrix' not in node and 'skin' not in node for node in document['nodes']))
        primitive = document['meshes'][0]['primitives'][0]
        positions = accessor(document, binary, primitive['attributes']['POSITION'])
        self.assertEqual(positions, [(0, 3, 0), (0, 19, 0), (16, 19, 0), (16, 3, 0)])
        self.assertEqual(accessor(document, binary, primitive['indices']), [(0,), (1,), (2,), (0,), (2,), (3,)])
        self.assertEqual(accessor(document, binary, primitive['attributes']['TEXCOORD_0']), [(0, 1), (0, 0), (1, 0), (1, 1)])
        image = document['bufferViews'][document['images'][0]['bufferView']]
        self.assertEqual(binary[image['byteOffset']:image['byteOffset'] + image['byteLength']], PNG)
        self.assertEqual(receipt['vertexCount'], 4)
        self.assertEqual(receipt['triangleCount'], 2)

    def test_both_clips_keep_distinct_names_durations_and_key_poses(self):
        data, receipt = DOOR.convert_dae(fixture(), {'door.png': PNG})
        document, binary = read_glb(data)
        self.assertEqual([a['name'] for a in document['animations']], ['door_op', 'door_cl'])
        self.assertEqual([c['durationSeconds'] for c in receipt['clips']], [0.25, 0.25])
        for animation in document['animations']:
            paths = {c['target']['path']: animation['samplers'][c['sampler']] for c in animation['channels']}
            self.assertEqual(set(paths), {'translation', 'rotation', 'scale'})
            for sampler in paths.values():
                self.assertEqual(sampler['interpolation'], 'LINEAR')
                self.assertEqual(accessor(document, binary, sampler['input']), [(0,), (0.25,)])
            values = {path: accessor(document, binary, sampler['output']) for path, sampler in paths.items()}
            first = transform((16, 19, 0), *(values[path][0] for path in ('translation', 'rotation', 'scale')))
            last = transform((16, 19, 0), *(values[path][1] for path in ('translation', 'rotation', 'scale')))
            expected = [(18, 19, 0), (2, 19, 15)]
            if animation['name'] == 'door_cl':
                expected.reverse()
            for actual, wanted in zip((first, last), expected):
                for a, b in zip(actual, wanted):
                    self.assertAlmostEqual(a, b, places=5)

    def test_unsupported_source_is_rejected(self):
        variants = [
            (b'<up_axis>Y_UP</up_axis>', b'<up_axis>Z_UP</up_axis>', 'Y_UP'),
            (b'<vcount>1 1 1 1</vcount>', b'<vcount>2 1 1 1</vcount>', 'one bone influence'),
            (b'LINEAR LINEAR', b'BEZIER LINEAR', 'LINEAR'),
            (b'joint0/transform', b'joint0/translation', 'matrix channel'),
            (b'0 0 -1 2 0 1 0 0 1 0 0 -1 0 0 0 1', b'1 0.2 0 2 0 1 0 0 0 0 1 -1 0 0 0 1', 'shear'),
            (b'0 0 -1 2 0 1 0 0 1 0 0 -1 0 0 0 1', b'-1 0 0 2 0 1 0 0 0 0 1 -1 0 0 0 1', 'reflection'),
            (b'<v>0 0 0 0 0 0 0 0</v>', b'<v>0 1 0 0 0 0 0 0</v>', 'weight'),
            (b'<node id="mesh">', b'<node id="mesh"><translate>1 0 0</translate>', 'controller node'),
        ]
        for before, after, message in variants:
            with self.subTest(message=message):
                with self.assertRaisesRegex(ValueError, message):
                    DOOR.convert_dae(fixture().replace(before, after), {'door.png': PNG})

    def test_unsupported_texture_binding_and_geometry_shapes_are_rejected(self):
        variants = [
            (b'input_semantic="TEXCOORD"', b'input_semantic="NORMAL"', 'texture coordinate binding'),
            (b'texcoord="tc"', b'texcoord="missing"', 'texture coordinate binding'),
            (b'</phong>', b'<transparent><color>1 1 1 0.5</color></transparent></phong>', 'transparent'),
            (b'<p>0 1 2 3</p>', b'<p>0 1 3 2</p>', 'convex'),
            (b'<p>0 1 2 3</p>', b'<p>0 1 2 2</p>', 'degenerate'),
        ]
        for before, after, message in variants:
            with self.subTest(message=message):
                with self.assertRaisesRegex(ValueError, message):
                    DOOR.convert_dae(fixture().replace(before, after), {'door.png': PNG})

    def test_unsupported_source_libraries_and_controllers_are_rejected(self):
        variants = [
            (b'</COLLADA>', b'<library_cameras><camera id="camera"/></library_cameras></COLLADA>'),
            (b'</skin></controller>', b'</skin><morph source="#geometry"/></controller>'),
        ]
        for before, after in variants:
            with self.subTest(after=after):
                with self.assertRaisesRegex(ValueError, 'Unsupported source'):
                    DOOR.convert_dae(fixture().replace(before, after), {'door.png': PNG})

    def test_source_times_that_collapse_in_float32_are_rejected(self):
        with self.assertRaisesRegex(ValueError, 'float32 key times'):
            DOOR.convert_dae(fixture().replace(b'0.25', b'1e-50'), {'door.png': PNG})

    def test_normals_follow_bind_shape_rotation_and_nonuniform_scale(self):
        source = fixture().replace(b'1 0 0 0 0 1 0 3 0 0 1 0 0 0 0 1', b'0 0 4 0 0 3 0 3 -2 0 0 0 0 0 0 1')
        data, _ = DOOR.convert_dae(source, {'door.png': PNG})
        document, binary = read_glb(data)
        normals = accessor(document, binary, document['meshes'][0]['primitives'][0]['attributes']['NORMAL'])
        for normal in normals:
            for actual, expected in zip(normal, (-1, 0, 0)):
                self.assertAlmostEqual(actual, expected, places=6)

    def test_original_source_preserves_every_sampled_key_and_reports_midpoint_delta(self):
        path = SOURCE / 'archives/doors/normal-door-1--582036.zip'
        if not path.exists():
            self.skipTest('Original local BW2 source archive is unavailable')
        with zipfile.ZipFile(path) as archive:
            source = archive.read('door_normal01.dae')
            texture = archive.read('door_n_01.png')
        data, receipt = DOOR.convert_dae(source, {'door_n_01.png': texture})
        document, binary = read_glb(data)
        positions = accessor(document, binary, document['meshes'][0]['primitives'][0]['attributes']['POSITION'])
        root = ET.fromstring(source)
        arrays = {s.get('id'): list(map(float, s.find('c:float_array', NS).text.split()))
                  for s in root.findall('.//c:library_animations/c:animation/c:source', NS)
                  if s.find('c:float_array', NS) is not None}
        for index, animation in enumerate(document['animations']):
            paths = {c['target']['path']: animation['samplers'][c['sampler']] for c in animation['channels']}
            values = {p: accessor(document, binary, s['output']) for p, s in paths.items()}
            times = accessor(document, binary, paths['rotation']['input'])
            self.assertEqual(len(times), 8)
            self.assertAlmostEqual(times[-1][0], 7 / 60, places=7)
            matrices = arrays[f'anim{index}-joint0-matrix']
            midpoint_errors = []
            for key in range(8):
                matrix = matrices[key * 16:key * 16 + 16]
                for position in positions:
                    actual = transform(position, *(values[p][key] for p in ('translation', 'rotation', 'scale')))
                    expected = [sum(matrix[row * 4 + col] * position[col] for col in range(3)) + matrix[row * 4 + 3] for row in range(3)]
                    for a, b in zip(actual, expected):
                        self.assertAlmostEqual(a / 16, b / 16, places=6)
                if key:
                    mixed = {path: [(a + b) / 2 for a, b in zip(values[path][key - 1], values[path][key])]
                             for path in ('translation', 'scale')}
                    mixed['rotation'] = midpoint_rotation(values['rotation'][key - 1], values['rotation'][key])
                    original = [(a + b) / 2 for a, b in zip(matrices[(key - 1) * 16:key * 16], matrix)]
                    for position in positions:
                        actual = transform(position, *(mixed[path] for path in ('translation', 'rotation', 'scale')))
                        expected = [sum(original[row * 4 + col] * position[col] for col in range(3)) + original[row * 4 + 3] for row in range(3)]
                        midpoint_errors.append(math.dist(actual, expected) / 16)
            self.assertLess(receipt['clips'][index]['maxKeyPositionErrorMapUnits'], 1e-6)
            self.assertGreater(receipt['clips'][index]['maxMidpointPositionErrorMapUnits'], 0.005)
            self.assertAlmostEqual(max(midpoint_errors), receipt['clips'][index]['maxMidpointPositionErrorMapUnits'], places=10)
            self.assertIn('slerp', receipt['animationInterpolation'])

    def test_extraction_is_repeatable_with_provenance_and_rejects_source_overlap(self):
        if not (SOURCE / 'archives/doors/normal-door-1--582036.zip').exists():
            self.skipTest('Original local BW2 source archive is unavailable')
        with tempfile.TemporaryDirectory() as temporary:
            first, second = Path(temporary) / 'first', Path(temporary) / 'second'
            receipt = DOOR.extract(SOURCE, first)
            DOOR.extract(SOURCE, second)
            self.assertEqual(receipt['archiveSha256'], hashlib.sha256((SOURCE / receipt['archive']).read_bytes()).hexdigest())
            self.assertEqual(receipt['outputSha256'], hashlib.sha256((first / receipt['output']).read_bytes()).hexdigest())
            for path in first.iterdir():
                self.assertEqual(path.read_bytes(), (second / path.name).read_bytes())
            self.assertEqual(json.loads((first / 'bw2_normal_door_1_provenance.json').read_text()), receipt)
            for target in (SOURCE, SOURCE / 'output', SOURCE.parent):
                with self.assertRaisesRegex(ValueError, 'outside the read-only source'):
                    DOOR.extract(SOURCE, target)
            output = Path(temporary) / 'symlink'
            output.mkdir()
            (output / 'bw2_normal_door_1.glb').symlink_to(first / receipt['output'])
            with self.assertRaisesRegex(ValueError, 'symlink'):
                DOOR.extract(SOURCE, output)

    def test_output_hardlinks_cannot_mutate_the_read_only_source(self):
        archive = SOURCE / 'archives/doors/normal-door-1--582036.zip'
        if not archive.exists():
            self.skipTest('Original local BW2 source archive is unavailable')
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / 'source'
            copied_archive = source / 'archives/doors/normal-door-1--582036.zip'
            copied_archive.parent.mkdir(parents=True)
            original = archive.read_bytes()
            copied_archive.write_bytes(original)
            output = root / 'output'
            output.mkdir()
            os.link(copied_archive, output / 'bw2_normal_door_1.glb')
            with self.assertRaisesRegex(ValueError, 'hardlink'):
                DOOR.extract(source, output)
            self.assertEqual(copied_archive.read_bytes(), original)
            self.assertEqual([path.name for path in output.iterdir()], ['bw2_normal_door_1.glb'])


if __name__ == '__main__':
    unittest.main()

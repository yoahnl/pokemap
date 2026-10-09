from copy import deepcopy
from pathlib import Path
import struct
import sys
import unittest

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))

from rigidify_bw2_animation import GlbWriter, accessor_rows, enrich_rigid_animation, node_worlds, point, read_glb, write_glb


def asset(animated=False, blended=False):
    document = {'asset': {'version': '2.0'}, 'scene': 0, 'scenes': [{'nodes': [0]}],
                'nodes': [{'mesh': 0}], 'meshes': [{'primitives': []}],
                'materials': [{'name': 'original', 'pbrMetallicRoughness': {'baseColorFactor': [.7, .8, .9, 1]}}],
                'buffers': [], 'bufferViews': [], 'accessors': []}
    binary = bytearray()

    def rows(values, width, component=5126, normalized=False):
        binary.extend(b'\0' * (-len(binary) % 4))
        fmt = 'f' if component == 5126 else 'B'
        data = struct.pack('<' + fmt * (len(values) * width), *(value for row in values for value in row))
        document['bufferViews'].append({'buffer': 0, 'byteOffset': len(binary), 'byteLength': len(data)})
        binary.extend(data)
        entry = {'bufferView': len(document['bufferViews']) - 1, 'componentType': component,
                 'count': len(values), 'type': 'SCALAR' if width == 1 else 'VEC' + str(width)}
        if normalized:
            entry['normalized'] = True
        document['accessors'].append(entry)
        return len(document['accessors']) - 1

    positions = [[2, 0, 0], [3, 0, 0], [2, 1, 0]] if animated else [[0, 0, 0], [.5, 0, 0], [0, .5, 0]]
    attributes = {'POSITION': rows(positions, 3), 'NORMAL': rows([[0, 0, 1]] * 3, 3),
                  'TEXCOORD_0': rows([[0, 0], [1, 0], [0, 1]], 2),
                  'COLOR_0': rows([[.25, .5, .75, 1]] * 3, 4)}
    if animated:
        attributes['JOINTS_0'] = rows([[0, 1, 0, 0]] * 3, 4, 5121)
        attributes['WEIGHTS_0'] = rows([[128, 127, 0, 0] if blended else [255, 0, 0, 0]] * 3, 4, 5121, True)
        document['nodes'] = [{'children': [1, 2]}, {'name': 'moving', 'translation': [2, 0, 0]}, {'mesh': 0, 'skin': 0}]
        document['skins'] = [{'joints': [1, 0]}]
        document['animations'] = [{'name': 'original movement',
                                  'samplers': [{'input': rows([[0], [1]], 1),
                                                'output': rows([[2, 0, 0], [3, 0, 0]], 3)}],
                                  'channels': [{'sampler': 0, 'target': {'node': 1, 'path': 'translation'}}]}]
    document['meshes'][0]['primitives'].append({'attributes': attributes, 'material': 0})
    document['buffers'] = [{'byteLength': len(binary)}]
    return write_glb(document, binary)


C = [.5, 0, 0, -1, 0, .5, 0, 0, 0, 0, .5, 0, 0, 0, 0, 1]


class RigidAnimationTests(unittest.TestCase):
    def test_rigid_conversion_preserves_neutral_geometry_uv_color_and_materials(self):
        original = asset()
        output, evidence = enrich_rigid_animation(original, asset(animated=True), C)
        current, binary = read_glb(original)
        document, result_binary = read_glb(output)
        self.assertNotIn('skins', document)
        self.assertEqual(document['materials'], current['materials'])
        self.assertTrue(evidence['currentBinaryPrefixPreserved'])
        self.assertLess(evidence['maximumNeutralPositionError'], 1e-6)
        worlds = node_worlds(document)
        node_index = next(index for index, node in enumerate(document['nodes']) if 'mesh' in node)
        primitive = document['meshes'][document['nodes'][node_index]['mesh']]['primitives'][0]
        vertices = accessor_rows(document, result_binary, primitive['attributes']['POSITION'])
        self.assertEqual([point(worlds[node_index], position) for position in vertices], [[0, 0, 0], [.5, 0, 0], [0, .5, 0]])
        initial = current['meshes'][0]['primitives'][0]['attributes']
        for attribute in ['TEXCOORD_0', 'COLOR_0']:
            self.assertEqual(accessor_rows(document, result_binary, primitive['attributes'][attribute]),
                             accessor_rows(current, binary, initial[attribute]))

    def test_original_absolute_joint_motion_is_retained_and_scaled_by_alignment(self):
        output, _ = enrich_rigid_animation(asset(), asset(animated=True), C)
        document, binary = read_glb(output)
        clip = document['animations'][0]
        target = clip['channels'][0]['target']['node']
        values = accessor_rows(document, binary, clip['samplers'][0]['output'])
        document['nodes'][target]['translation'] = values[1]
        worlds = node_worlds(document)
        primitive = document['meshes'][document['nodes'][target]['mesh']]['primitives'][0]
        vertex = accessor_rows(document, binary, primitive['attributes']['POSITION'])[0]
        self.assertEqual(point(worlds[target], vertex), [.5, 0, 0])

    def test_blended_skin_is_rejected(self):
        with self.assertRaisesRegex(ValueError, 'Blended'):
            enrich_rigid_animation(asset(), asset(animated=True, blended=True), C)

    def test_geometry_without_original_correspondence_is_rejected(self):
        wrong = deepcopy(C)
        wrong[3] = 100
        with self.assertRaisesRegex(ValueError, 'cannot be matched'):
            enrich_rigid_animation(asset(), asset(animated=True), wrong)

    def test_cyclic_or_shared_source_hierarchy_is_rejected(self):
        document, binary = read_glb(asset(animated=True))
        document['nodes'][1]['children'] = [0]
        with self.assertRaisesRegex(ValueError, 'cyclic'):
            enrich_rigid_animation(asset(), write_glb(document, binary), C)

    def test_composite_asset_static_door_requires_independent_original_geometry_proof(self):
        document, binary = read_glb(asset())
        writer = GlbWriter(document, binary)
        document['meshes'][0]['primitives'].append({'material': 0, 'attributes': {
            'POSITION': writer.rows([[2, 0, 0], [2.5, 0, 0], [2, .5, 0]], 'VEC3'),
            'NORMAL': writer.rows([[0, 0, 1]] * 3, 'VEC3'),
            'TEXCOORD_0': writer.rows([[0, 0], [1, 0], [0, 1]], 'VEC2'),
        }})
        composite = writer.finish()
        with self.assertRaisesRegex(ValueError, 'cannot be matched'):
            enrich_rigid_animation(composite, asset(animated=True), C)
        static_transform = [1, 0, 0, 2, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]
        output, evidence = enrich_rigid_animation(composite, asset(animated=True), C,
                                                 static_sources=[(asset(), static_transform)])
        self.assertEqual(evidence['triangleCount'], 2)
        self.assertEqual(evidence['verifiedStaticSourceCount'], 1)
        result, _ = read_glb(output)
        self.assertEqual(len(result['scenes'][0]['nodes']), 2)


if __name__ == '__main__':
    unittest.main()

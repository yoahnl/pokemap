from copy import deepcopy
import struct
import unittest

from tools.source_units.split_static_materials import glb_bytes, partition_static_glb, primitive_signature, read_glb


def fixture():
    binary = bytearray(b'\0' * 8)
    views, accessors, primitives, materials, images, textures = [], [], [], [], [], []
    for index, name in enumerate(['rock', 'grass']):
        attributes = {}
        for attribute, width in [('POSITION', 3), ('NORMAL', 3), ('TEXCOORD_0', 2), ('COLOR_0', 4)]:
            binary.extend(b'\0' * (-len(binary) % 4))
            payload = struct.pack('<' + 'f' * width * 3, *[value + index / 4 for value in range(width * 3)])
            attributes[attribute] = len(accessors)
            accessors.append({'bufferView': len(views), 'componentType': 5126, 'count': 3, 'type': f'VEC{width}'})
            views.append({'buffer': 0, 'byteOffset': len(binary), 'byteLength': len(payload), 'target': 34962})
            binary.extend(payload)
        primitives.append({'attributes': attributes, 'material': index, 'mode': 4})
        materials.append({'name': name + '.png@1@repeat-flip', 'extras': {'sourceMaterials': [name]},
                          'pbrMetallicRoughness': {'baseColorTexture': {'index': index}, 'metallicFactor': 0},
                          'extensions': {'KHR_materials_unlit': {}}, 'alphaMode': 'MASK', 'alphaCutoff': .25,
                          'doubleSided': True})
        binary.extend(b'\0' * (-len(binary) % 4))
        payload = b'original-texture-' + name.encode()
        images.append({'mimeType': 'image/png', 'bufferView': len(views)})
        views.append({'buffer': 0, 'byteOffset': len(binary), 'byteLength': len(payload)})
        binary.extend(payload)
        textures.append({'source': index, 'sampler': 0})
    document = {'asset': {'version': '2.0'}, 'scene': 0, 'scenes': [{'nodes': [0]}],
                'nodes': [{'mesh': 0}], 'meshes': [{'primitives': primitives}],
                'buffers': [{'byteLength': len(binary)}], 'bufferViews': views, 'accessors': accessors,
                'materials': materials, 'images': images, 'textures': textures,
                'samplers': [{'wrapS': 10497, 'wrapT': 33648, 'magFilter': 9728, 'minFilter': 9728}],
                'extensionsUsed': ['KHR_materials_unlit'], 'extras': {'original': True}}
    return document, bytes(binary)


class StaticMaterialPartitionTest(unittest.TestCase):
    def test_disjoint_components_keep_vertices_uv_color_alpha_sampler_and_image_bytes(self):
        document, binary = fixture()
        original = deepcopy(document)
        result = partition_static_glb(glb_bytes(document, binary), {'rock': 'border', 'grass': 'terrain'})
        self.assertEqual(document, original)
        self.assertEqual(set(result), {'border', 'terrain'})
        for kind, source_index in [('border', 0), ('terrain', 1)]:
            row = result[kind]
            target, payload = read_glb(glb_bytes(row['document'], row['binary']))
            self.assertEqual(row['sourcePrimitiveIndices'], [source_index])
            self.assertEqual(len(target['materials']), 1)
            self.assertEqual(len(target['images']), 1)
            self.assertEqual(len(target['accessors']), 4)
            self.assertLess(len(payload), len(binary))
            self.assertEqual(primitive_signature(document, binary, document['meshes'][0]['primitives'][source_index]),
                             primitive_signature(target, payload, target['meshes'][0]['primitives'][0]))

    def test_partition_is_deterministic(self):
        document, binary = fixture()
        data = glb_bytes(document, binary)
        self.assertEqual(partition_static_glb(data, {'rock': 'border', 'grass': 'terrain'}),
                         partition_static_glb(data, {'rock': 'border', 'grass': 'terrain'}))

    def test_index_accessor_bytes_are_kept(self):
        document, binary = fixture()
        payload = bytearray(binary)
        payload.extend(b'\0' * (-len(payload) % 4))
        offset = len(payload)
        payload.extend(struct.pack('<HHH', 2, 0, 1))
        document['accessors'].append({'bufferView': len(document['bufferViews']), 'componentType': 5123, 'count': 3, 'type': 'SCALAR'})
        document['meshes'][0]['primitives'][1]['indices'] = len(document['accessors']) - 1
        document['bufferViews'].append({'buffer': 0, 'byteOffset': offset, 'byteLength': 6, 'target': 34963})
        document['buffers'][0]['byteLength'] = len(payload)
        result = partition_static_glb(glb_bytes(document, payload), {'rock': 'border', 'grass': 'terrain'})['terrain']
        target, output = read_glb(glb_bytes(result['document'], result['binary']))
        self.assertEqual(primitive_signature(document, payload, document['meshes'][0]['primitives'][1]),
                         primitive_signature(target, output, target['meshes'][0]['primitives'][0]))

    def test_unclassified_material_is_rejected(self):
        document, binary = fixture()
        with self.assertRaisesRegex(ValueError, 'Unclassified'):
            partition_static_glb(glb_bytes(document, binary), {'rock': 'border'})

    def test_material_merging_two_families_is_rejected(self):
        document, binary = fixture()
        document['materials'][0]['extras']['sourceMaterials'].append('grass')
        with self.assertRaisesRegex(ValueError, 'different authoring families'):
            partition_static_glb(glb_bytes(document, binary), {'rock': 'border', 'grass': 'terrain'})

    def test_unqualified_transform_is_rejected(self):
        document, binary = fixture()
        document['nodes'][0]['translation'] = [0, 2, 0]
        with self.assertRaisesRegex(ValueError, 'identity mesh'):
            partition_static_glb(glb_bytes(document, binary), {'rock': 'border', 'grass': 'terrain'})

    def test_animated_input_is_rejected(self):
        document, binary = fixture()
        document['animations'] = [{'channels': []}]
        with self.assertRaisesRegex(ValueError, 'Animated'):
            partition_static_glb(glb_bytes(document, binary), {'rock': 'border', 'grass': 'terrain'})

    def test_external_image_is_rejected(self):
        document, binary = fixture()
        document['images'][0]['uri'] = 'original.png'
        with self.assertRaisesRegex(ValueError, 'embedded original PNG'):
            partition_static_glb(glb_bytes(document, binary), {'rock': 'border', 'grass': 'terrain'})

    def test_truncated_buffer_view_is_rejected(self):
        document, binary = fixture()
        document['bufferViews'][0]['byteLength'] = len(binary) + 100
        with self.assertRaisesRegex(ValueError, 'Buffer view exceeds'):
            partition_static_glb(glb_bytes(document, binary), {'rock': 'border', 'grass': 'terrain'})

    def test_additional_material_texture_is_rejected(self):
        document, binary = fixture()
        document['materials'][0]['normalTexture'] = {'index': 0}
        with self.assertRaisesRegex(ValueError, 'Additional material texture'):
            partition_static_glb(glb_bytes(document, binary), {'rock': 'border', 'grass': 'terrain'})


if __name__ == '__main__':
    unittest.main()


import math
from pathlib import Path
import struct
import sys
import unittest

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))

from read_bw2_nitro_animations import channel_samples, dictionary, interpolate, nitro_affine, read_srt, retarget_material_texture


def resource_dictionary(entries, width):
    count = len(entries)
    size = 16 + count * (4 + width + 16)
    output = bytearray(struct.pack('<BBH', 0, count, size) + bytes(8 + count * 4))
    output.extend(struct.pack('<HH', width, 4 + count * width))
    for data, _ in entries:
        output.extend(data)
    for _, name in entries:
        output.extend(name.encode().ljust(16, b'\0'))
    return bytes(output)


def srt_container(duration, components, material='water'):
    table_length = len(resource_dictionary([(bytes(40), material)], 40))
    offset = 8 + table_length
    channel_data, samples = bytearray(), bytearray()
    for flag, value in components:
        if isinstance(value, bytes):
            channel_data.extend(struct.pack('<II', duration | flag, offset + len(samples)))
            samples.extend(value)
        else:
            channel_data.extend(struct.pack('<II', duration | flag, value))
    animation = b'M\0AT' + struct.pack('<HBB', duration, 0, 0)
    animation += resource_dictionary([(bytes(channel_data), material)], 40) + samples
    animation_offset = 8 + len(resource_dictionary([(bytes(4), 'test')], 4))
    block = b'SRT0' + struct.pack('<I', animation_offset + len(animation))
    block += resource_dictionary([(struct.pack('<I', animation_offset), 'test')], 4) + animation
    return b'BTA0\xff\xfe\x01\0' + struct.pack('<IHHI', 20 + len(block), 16, 1, 20) + block


def model_container():
    material = resource_dictionary([(bytes(4), 'water')], 4)
    size = len(resource_dictionary([(bytes(4), 'old_tex')], 4))
    indices = 4 + len(material) + size * 2
    texture = resource_dictionary([(struct.pack('<HBB', indices, 1, 0), 'old_tex')], 4)
    palette = resource_dictionary([(struct.pack('<HBB', indices, 1, 0), 'old_pal')], 4)
    section = struct.pack('<HH', 4 + len(material), 4 + len(material) + size) + material + texture + palette + b'\0'
    model = bytearray(32)
    struct.pack_into('<I', model, 8, 32)
    model.extend(section)
    offset = 8 + len(resource_dictionary([(bytes(4), 'pool')], 4))
    block = b'MDL0' + struct.pack('<I', offset + len(model))
    block += resource_dictionary([(struct.pack('<I', offset), 'pool')], 4) + bytes(model)
    return b'BMD0\xff\xfe\x01\0' + struct.pack('<IHHI', 20 + len(block), 16, 1, 20) + block


class NitroAnimationTests(unittest.TestCase):
    def test_signed_scalar_sampling_and_step_interpolation(self):
        values = channel_samples(struct.pack('<hhh', -4096, 4096, 8192), 0, 5, 0x50000004, 0)
        self.assertEqual(values, [(0, -1), (2, 1), (4, 2)])
        self.assertEqual(interpolate(values, 1), (0,))
        self.assertEqual(interpolate(values, 3), (1.5,))
        self.assertEqual(interpolate(values, 10), (2,))

    def test_four_frame_fx32_samples(self):
        values = channel_samples(struct.pack('<iii', 4096, -8192, 12288), 0, 9, 0x80000008, 0)
        self.assertEqual(values, [(0, 1), (4, -2), (8, 3)])
        self.assertEqual(interpolate(values, 6), (.5,))

    def test_compressed_scalar_retains_dense_terminal_original_frame(self):
        values = channel_samples(struct.pack('<hhhh', 0, 4096, 8192, 12288), 0, 6, 0x50000004, 0)
        self.assertEqual(values, [(0, 0), (2, 1), (4, 2), (5, 3)])
        self.assertEqual(interpolate(values, 4.5), (2.5,))

    def test_packed_rotation_is_signed_q12(self):
        samples = [(0, (4096 << 16) | 0), (2, (0 << 16) | (-4096 & 0xffff))]
        self.assertEqual(interpolate(samples, 0, rotation=True), (0, 1))
        self.assertEqual(interpolate(samples, 1, rotation=True), (-.5, .5))
        self.assertEqual(interpolate(samples, 2, rotation=True), (-1, 0))

    def test_real_container_decodes_negative_translation_and_rotation(self):
        data = srt_container(3, [(0x20000000, 4096), (0x20000000, 4096),
                                 (0x20000000, 4096 << 16),
                                 (0x10000000, struct.pack('<hhh', 0, -1024, -2048)),
                                 (0x20000000, 0)])
        clip = read_srt(data)[0]
        self.assertEqual(clip['name'], 'test')
        self.assertEqual(clip['frames'], 3)
        self.assertEqual(clip['tracks'][0]['material'], 'water')
        self.assertEqual(clip['tracks'][0]['samples'][2], [1, 1, 0, 1, -.5, 0])

    def test_maya_translation_matches_original_sdk_normalized_uv_axis(self):
        self.assertEqual(nitro_affine([1, 1, 0, 1, .25, .5], 0), [1, 0, 0, 1, -.25, .5])

    def test_max_rotation_matches_original_sdk_square_and_non_square_uvs(self):
        self.assertEqual(nitro_affine([1, 1, 1, 0, 0, 0], 2), [0, 1, -1, 0, 1, 0])
        self.assertEqual(nitro_affine([1, 1, 1, 0, 0, 0], 2, 64, 32), [0, 1, -1, 0, .75, -.5])

    def test_maya_rotation_pixel_ratios_cancel_when_normalizing_uvs(self):
        self.assertEqual(nitro_affine([1, 1, 1, 0, 0, 0], 0, 64, 32), [0, -1, 1, 0, 0, 1])

    def test_unknown_matrix_modes_and_nonfinite_values_are_rejected(self):
        with self.assertRaisesRegex(ValueError, 'matrix mode'):
            nitro_affine([1, 1, 0, 1, 0, 0], 1)
        with self.assertRaisesRegex(ValueError, 'Nonfinite'):
            nitro_affine([1, 1, 0, 1, math.nan, 0], 0)

    def test_truncated_samples_and_invalid_container_are_rejected(self):
        with self.assertRaisesRegex(ValueError, 'outside'):
            channel_samples(b'\0', 0, 2, 0x10000002, 0)
        with self.assertRaisesRegex(ValueError, 'material animation'):
            read_srt(b'not a Nitro file')
        with self.assertRaisesRegex(ValueError, 'dictionary'):
            dictionary(b'\0\x01\xff\xff', 0, 4)

    def test_pattern_binding_retarget_preserves_geometry_and_other_source_bytes(self):
        data = model_container()
        result, changes = retarget_material_texture(data, 'pool', 'water', 'frame_02', 'frame_02_pl')
        mutable = {offset for change in changes for offset in range(change['offset'], change['offset'] + 16)}
        self.assertEqual(len(result), len(data))
        self.assertTrue(all(result[index] == value for index, value in enumerate(data) if index not in mutable))
        self.assertEqual([change['from'] for change in changes], ['old_tex', 'old_pal'])
        with self.assertRaisesRegex(ValueError, 'absent'):
            retarget_material_texture(data, 'pool', 'unknown', 'frame_02', 'frame_02_pl')


if __name__ == '__main__':
    unittest.main()

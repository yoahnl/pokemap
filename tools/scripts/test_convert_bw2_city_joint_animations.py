import json
from copy import deepcopy
from pathlib import Path
import struct
import tempfile
import unittest
from unittest.mock import Mock, patch

from convert_bw2_city_joint_animations import (
    attach_proven_child_clips, object_transform, read_glb, restore_joint_timeline,
    stage, stage_doors, stage_original, unique_source,
)
from convert_bw2_door_asset import point
from rigidify_bw2_animation import (
    GlbWriter, accessor_rows, enrich_rigid_animation, node_worlds,
    read_glb as read_chunks, write_glb,
)
from test_read_bw2_nitro_animations import resource_dictionary
from test_rigidify_bw2_animation import asset, C


def joint_container(name, frames, boundary, rate, values, extra_flags=()):
    count = 1 + len(extra_flags)
    offset = 20 + 2 * count
    sample_offset = offset + 20 + 4 * len(extra_flags)
    info = (boundary << 16) | ({1: 0, 2: 1, 4: 2}[rate] << 30)
    animation = b'J\0AC' + struct.pack('<HHIII', frames, count, 0, 0, 0)
    animation += struct.pack('<' + 'H' * count, offset,
                             *(offset + 20 + index * 4 for index in range(len(extra_flags))))
    animation += struct.pack('<HBBiIIi', 0x268, 0, 0, 0, info, sample_offset, 0)
    animation += b''.join(struct.pack('<HBB', flags, 0, index + 1)
                          for index, flags in enumerate(extra_flags))
    animation += struct.pack('<' + 'i' * len(values), *(int(value * 4096) for value in values))
    animation_offset = 8 + len(resource_dictionary([(bytes(4), name)], 4))
    block = b'JNT0' + struct.pack('<I', animation_offset + len(animation))
    block += resource_dictionary([(struct.pack('<I', animation_offset), name)], 4) + animation
    return b'BCA0\xff\xfe\x01\0' + struct.pack('<IHHI', 20 + len(block), 16, 1, 20) + block


def animated_proof(name, last_frame, last_value):
    document = {'asset': {'version': '2.0'}, 'nodes': [{'name': 'moving'}],
                'bufferViews': [], 'accessors': [], 'buffers': []}
    writer = GlbWriter(document, b'original geometry')
    times = writer.rows([[0], [last_frame / 60]], 'SCALAR')
    values = writer.rows([[0, 0, 0], [0, last_value, 0]], 'VEC3')
    constant_time = writer.rows([[0]], 'SCALAR')
    constant_pose = writer.rows([[0, 0, 0, 1]], 'VEC4')
    document['animations'] = [{'name': name, 'samplers': [
        {'input': times, 'output': values},
        {'input': constant_time, 'output': constant_pose},
    ], 'channels': [
        {'sampler': 0, 'target': {'node': 0, 'path': 'translation'}},
        {'sampler': 1, 'target': {'node': 0, 'path': 'rotation'}},
    ]}]
    return writer.finish()


def joint_model(names):
    table_size = len(resource_dictionary([(bytes(4), name) for name in names], 4))
    model = bytearray(64)
    model[23] = len(names)
    model.extend(resource_dictionary([
        (struct.pack('<I', 64 + table_size + index * 4), name)
        for index, name in enumerate(names)], 4))
    model.extend(struct.pack('<HH', 7, 0) * len(names))
    struct.pack_into('<I', model, 0, len(model))
    offset = 8 + len(resource_dictionary([(bytes(4), 'model')], 4))
    block = b'MDL0' + struct.pack('<I', offset + len(model))
    block += resource_dictionary([(struct.pack('<I', offset), 'model')], 4) + model
    return b'BMD0\xff\xfe\x01\0' + struct.pack('<IHHI', 20 + len(block), 16, 1, 20) + block


class CityJointAnimationTests(unittest.TestCase):
    def proof_with_tilted_cabin(self, last_frame=2, last_value=2):
        document, binary = read_chunks(animated_proof('wheel', last_frame, last_value))
        document['nodes'].insert(0, {
            'name': 'cabin', 'translation': [3, 4, 5],
            'rotation': [0, 0, .5003692038568004, .8658121388798565],
            'scale': [1.5, 1.5, 1],
        })
        for channel in document['animations'][0]['channels']:
            channel['target']['node'] = 1
        return write_glb(document, binary)

    def test_identity_rotation_overrides_tilted_cabin_without_changing_rest_pose(self):
        source = joint_container('wheel', 3, 3, 1, [0, 1, 2], extra_flags=[0x444])
        original = self.proof_with_tilted_cabin()
        output, evidence = restore_joint_timeline(
            original, source, 'wheel', joint_model(['moving', 'cabin']))
        before, before_binary = read_chunks(original)
        document, binary = read_chunks(output)
        clip = document['animations'][0]
        cabin_channels = [channel for channel in clip['channels'] if channel['target']['node'] == 0]
        self.assertEqual([channel['target']['path'] for channel in cabin_channels], ['rotation'])
        sampler = clip['samplers'][cabin_channels[0]['sampler']]
        self.assertEqual(accessor_rows(document, binary, sampler['output']), [[0, 0, 0, 1]])
        self.assertEqual(document['nodes'], before['nodes'])
        self.assertTrue(binary.startswith(before_binary))
        self.assertIn({'node': 0, 'joint': 1, 'name': 'cabin', 'path': 'rotation'},
                      evidence['restoredIdentityChannels'])

    def test_component_and_whole_joint_identity_flags_are_absolute(self):
        cases = [
            (0x482, {'translation': [0, 0, 0]}),
            (0x444, {'rotation': [0, 0, 0, 1]}),
            (0x284, {'scale': [1, 1, 1]}),
            (0x485, {'translation': [0, 0, 0], 'rotation': [0, 0, 0, 1], 'scale': [1, 1, 1]}),
        ]
        for flags, expected in cases:
            with self.subTest(flags=hex(flags)):
                source = joint_container('wheel', 3, 3, 1, [0, 1, 2], extra_flags=[flags])
                original = self.proof_with_tilted_cabin()
                output, _ = restore_joint_timeline(
                    original, source, 'wheel', joint_model(['moving', 'cabin']))
                document, binary = read_chunks(output)
                clip = document['animations'][0]
                actual = {channel['target']['path']: accessor_rows(
                    document, binary, clip['samplers'][channel['sampler']]['output'])[0]
                    for channel in clip['channels'] if channel['target']['node'] == 0}
                self.assertEqual(actual, expected)
                before, _ = read_chunks(original)
                self.assertEqual(document['nodes'], before['nodes'])

    def test_model_base_flags_retain_the_source_rest_transform(self):
        source = joint_container('wheel', 3, 3, 1, [0, 1, 2], extra_flags=[0x484])
        original = self.proof_with_tilted_cabin()
        output, evidence = restore_joint_timeline(
            original, source, 'wheel', joint_model(['moving', 'cabin']))
        document, _ = read_chunks(output)
        self.assertFalse(any(channel['target']['node'] == 0
                             for channel in document['animations'][0]['channels']))
        self.assertFalse(any(channel['joint'] == 1 for channel in evidence['restoredIdentityChannels']))
        before, _ = read_chunks(original)
        self.assertEqual(document['nodes'], before['nodes'])

    def test_native_dictionary_names_map_dense_scalar_tails_to_reordered_glb_nodes(self):
        source = joint_container('wheel', 6, 4, 2, [0, 10, 20, 99], extra_flags=[0x484])
        original = self.proof_with_tilted_cabin(5, -100)
        output, evidence = restore_joint_timeline(
            original, source, 'wheel', joint_model(['moving', 'cabin']))
        document, binary = read_chunks(output)
        clip = document['animations'][0]
        channel = next(channel for channel in clip['channels']
                       if channel['target'] == {'node': 1, 'path': 'translation'})
        sampler = clip['samplers'][channel['sampler']]
        poses = accessor_rows(document, binary, sampler['output'])
        self.assertEqual([pose[1] for pose in poses], [0, 5, 10, 15, 20, 99, 99])
        self.assertEqual(evidence['restoredScalarSamplers'], 1)

    def test_joint_target_mapping_rejects_unverified_model_domains(self):
        source = joint_container('wheel', 3, 3, 1, [0, 1, 2], extra_flags=[0x444])
        original = self.proof_with_tilted_cabin()
        with self.assertRaisesRegex(ValueError, 'node counts disagree'):
            restore_joint_timeline(original, source, 'wheel', joint_model(['moving']))
        with self.assertRaisesRegex(ValueError, 'Ambiguous native model joint names'):
            restore_joint_timeline(original, source, 'wheel', joint_model(['moving', 'moving']))
        document, binary = read_chunks(original)
        document['nodes'][1]['name'] = 'unrelated'
        with self.assertRaisesRegex(ValueError, 'Ambiguous original GLB joint target'):
            restore_joint_timeline(write_glb(document, binary), source, 'wheel',
                                   joint_model(['moving', 'cabin']))

    def test_identity_restoration_is_idempotent(self):
        source = joint_container('wheel', 3, 3, 1, [0, 1, 2], extra_flags=[0x444])
        model = joint_model(['moving', 'cabin'])
        once, _ = restore_joint_timeline(self.proof_with_tilted_cabin(), source, 'wheel', model)
        twice, evidence = restore_joint_timeline(once, source, 'wheel', model)
        self.assertEqual(twice, once)
        self.assertEqual(evidence['restoredIdentityChannels'], [])

    def composite_with_static_child(self):
        document, binary = read_chunks(asset())
        writer = GlbWriter(document, binary)
        attributes = document['meshes'][0]['primitives'][0]['attributes'].copy()
        attributes['POSITION'] = writer.rows([[2, 0, 0], [2.5, 0, 0], [2, .5, 0]], 'VEC3')
        document['meshes'][0]['primitives'].append({'material': 0, 'attributes': attributes})
        static_transform = [1, 0, 0, 2, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]
        return enrich_rigid_animation(writer.finish(), asset(animated=True), C,
                                      static_sources=[(asset(), static_transform)])[0]

    def child_with_two_clips(self):
        document, binary = read_chunks(asset(animated=True))
        first = document['animations'][0]
        first['name'] = 'door_open'
        second = deepcopy(first)
        second['name'] = 'door_close'
        document['animations'].append(second)
        return write_glb(document, binary)

    def test_child_clips_preserve_ambient_zero_and_replace_only_verified_static_leaf(self):
        base = self.composite_with_static_child()
        before, before_binary = read_chunks(base)
        alignment = [.5, 0, 0, 1, 0, .5, 0, 0, 0, 0, .5, 0, 0, 0, 0, 1]
        output, evidence = attach_proven_child_clips(base, self.child_with_two_clips(), alignment)
        after, binary = read_chunks(output)
        self.assertEqual(after['animations'][0], before['animations'][0])
        self.assertEqual([clip['name'] for clip in after['animations']],
                         ['original movement', 'door_open', 'door_close'])
        self.assertEqual(after['materials'], before['materials'])
        self.assertTrue(binary.startswith(before_binary))
        self.assertNotIn('skins', after)
        worlds = node_worlds(after)
        visible = [node for index, node in enumerate(after['nodes'])
                   if index in worlds and 'mesh' in node]
        self.assertEqual(len(visible), 2)
        self.assertEqual(evidence['addedClipIndices'], [1, 2])
        static = next(index for index, node in enumerate(before['nodes'])
                      if node.get('name') == 'Verified static source geometry')
        self.assertNotIn(static, worlds)

    def test_child_clip_graft_requires_unique_verified_leaf_and_original_geometry(self):
        base = self.composite_with_static_child()
        alignment = [.5, 0, 0, 100, 0, .5, 0, 0, 0, 0, .5, 0, 0, 0, 0, 1]
        with self.assertRaisesRegex(ValueError, 'cannot be matched'):
            attach_proven_child_clips(base, self.child_with_two_clips(), alignment)
        document, binary = read_chunks(base)
        document['nodes'].append({'name': 'Verified static source geometry', 'mesh': 0})
        with self.assertRaisesRegex(ValueError, 'exactly one verified'):
            attach_proven_child_clips(write_glb(document, binary), self.child_with_two_clips(), C)

    def test_source_selection_requires_one_digest_and_exact_resource_name(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / 'model.nsbmd').write_bytes(b'original')
            (root / 'model.001.nsbmd').write_bytes(b'original')
            (root / 'model_other.nsbmd').write_bytes(b'other')
            selected, checksum = unique_source(root, 'model', '.nsbmd')
            self.assertEqual(selected.name, 'model.nsbmd')
            self.assertEqual(len(checksum), 64)
            (root / 'model.002.nsbmd').write_bytes(b'different')
            with self.assertRaisesRegex(ValueError, 'unambiguous'):
                unique_source(root, 'model', '.nsbmd')

    def test_source_selection_does_not_accept_an_unverified_animation(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / 'model.nsbca').write_bytes(b'original')
            with self.assertRaisesRegex(ValueError, 'unambiguous'):
                unique_source(root, 'model', '.nsbca', '0' * 64)
            with self.assertRaisesRegex(ValueError, 'Unsafe'):
                unique_source(root, '../model', '.nsbca')

    def test_exact_map_hierarchy_scale_rotation_and_anchor_are_retained(self):
        dae = b'''<COLLADA xmlns="http://www.collada.org/2005/11/COLLADASchema">
          <library_visual_scenes><visual_scene>
            <node id="map"><matrix>1 0 0 512 0 1 0 0 0 0 1 0 0 0 0 1</matrix>
              <node id="object"><matrix>0 0 1 16 0 1 0 32 -1 0 0 48 0 0 0 1</matrix></node>
            </node>
          </visual_scene></library_visual_scenes></COLLADA>'''
        transform = object_transform(dae, 'map/object', [33, 2, 3])
        self.assertEqual(point(transform, [16, 32, 48]), [3, 2, -1])
        with self.assertRaisesRegex(ValueError, 'exactly one'):
            object_transform(dae, 'object', [0, 0, 0])

    def test_single_object_group_can_repeat_the_same_root_identifier(self):
        dae = b'''<COLLADA xmlns="http://www.collada.org/2005/11/COLLADASchema">
          <library_visual_scenes><visual_scene><node id="object"/></visual_scene>
          </library_visual_scenes></COLLADA>'''
        transform = object_transform(dae, 'object/object', [0, 0, 0])
        self.assertEqual(point(transform, [16, 32, 48]), [1, 2, 3])

    def test_staging_never_writes_beneath_read_only_map_archives(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            nitro = root / 'nitro'
            maps = root / 'maps'
            nitro.mkdir()
            maps.mkdir()
            candidates = root / 'candidates.json'
            candidates.write_text(json.dumps({'source': {}, 'models': []}))
            with self.assertRaisesRegex(ValueError, 'read-only'):
                stage(candidates, nitro, maps, root / 'apicula', maps / 'outputs', source_only=True)
            self.assertEqual(list(maps.iterdir()), [])

    def test_door_staging_never_overwrites_ambient_or_joint_source_stages(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            ambient = root / 'ambient' / 'index.json'
            joints = root / 'joints' / 'index.json'
            nitro = root / 'nitro'
            ambient.parent.mkdir()
            joints.parent.mkdir()
            nitro.mkdir()
            ambient.write_text('{}')
            joints.write_text('{}')
            for protected in (ambient.parent, joints.parent, nitro):
                with self.assertRaisesRegex(ValueError, 'read-only'):
                    stage_doors(ambient, joints, nitro, root / 'apicula', protected / 'outputs')
                self.assertFalse((protected / 'outputs').exists())

    def test_glb_reader_rejects_truncated_source_conversion(self):
        data = struct.pack('<IIIII', 0x46546c67, 2, 28, 0, 0x4e4f534a)
        with self.assertRaisesRegex(ValueError, 'header'):
            read_glb(data)

    def test_cached_proof_does_not_hide_a_changed_nitro_source(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            proof = root / 'original' / 'model' / 'model.glb'
            proof.parent.mkdir(parents=True)
            proof.write_bytes(b'old proof')
            with patch('convert_bw2_city_joint_animations.subprocess.run',
                       return_value=Mock(returncode=0, stdout='', stderr='')) as run:
                stage_original(root / 'apicula', root / 'changed.nsbmd',
                               root / 'animation.nsbca', root, 'model')
            run.assert_called_once()
            self.assertIn('--overwrite', run.call_args.args[0])

    def test_papeloa_dense_terminal_frames_are_restored_before_one_second_boundary(self):
        samples = [0, 1, 2, 3, 4, 5, 6, 7, 6, 5, 4, 3, 2, 1, .5, .25, .125, 0]
        source = joint_container('c14_boat', 60, 56, 4, samples)
        original = animated_proof('c14_boat', 55, 1)
        output, evidence = restore_joint_timeline(original, source, 'c14_boat', joint_model(['moving']))
        document, binary = read_chunks(output)
        sampler = document['animations'][0]['samplers'][0]
        times = accessor_rows(document, binary, sampler['input'])
        poses = accessor_rows(document, binary, sampler['output'])
        self.assertEqual(times[-1], [1])
        self.assertEqual(len(times), 61)
        self.assertEqual(poses[4], [0, 1, 0])
        self.assertEqual([pose[1] for pose in poses[56:60]], [.5, .25, .125, 0])
        self.assertEqual(poses[-1], poses[-2])
        self.assertEqual(evidence['frames'], 60)
        self.assertEqual(evidence['restoredScalarSamplers'], 1)

    def test_wheel_period_comes_from_113_native_frames_and_preserves_original_keys(self):
        source = joint_container('c04_fwheel_01', 113, 113, 1, list(range(113)))
        original = animated_proof('c04_fwheel_01', 112, 112)
        output, evidence = restore_joint_timeline(
            original, source, 'c04_fwheel_01', joint_model(['moving']))
        before, before_binary = read_chunks(original)
        document, binary = read_chunks(output)
        samplers = document['animations'][0]['samplers']
        times = accessor_rows(document, binary, samplers[0]['input'])
        poses = accessor_rows(document, binary, samplers[0]['output'])
        self.assertAlmostEqual(times[-1][0], 113 / 60, places=6)
        self.assertEqual(poses[-1], poses[-2])
        self.assertEqual(samplers[1], before['animations'][0]['samplers'][1])
        self.assertTrue(binary.startswith(before_binary))
        self.assertEqual(evidence['frames'], 113)
        self.assertEqual(evidence['restoredScalarSamplers'], 0)


if __name__ == '__main__':
    unittest.main()

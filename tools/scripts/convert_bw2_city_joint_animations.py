import argparse
from copy import deepcopy
import hashlib
from io import BytesIO
import json
from pathlib import Path
import re
import struct
import subprocess
import xml.etree.ElementTree as ET
import zipfile

from convert_bw2_door_asset import IDENTITY, matrix, multiply
from read_bw2_nitro_animations import blocks, dictionary, unpack


MAP_ARCHIVES = {
    'flocombe': 'icirrus-city--587492.zip',
    'maillard': 'nacrene-city--587500.zip',
    'meanville-02': 'nimbasa-city-area-2--587504.zip',
    'papeloa': 'humilau-city--587491.zip',
    'port-yoneuve': 'driftveil-city--587480.zip',
    'renouet': 'nuvema-town--587505.zip',
    'volucite-11': 'castelia-city-area-11--587468.zip',
}
NS = {'c': 'http://www.collada.org/2005/11/COLLADASchema'}
STATIC_ATTACHMENTS = {
    'c5_build_01': [('door_c05_build', 'door_door_c05_build')],
    't1_labo_01': [('door_t1_02', 'door_door_t1_02')],
}
PROVEN_CHILD_CLIPS = {
    'c5_build_01': ('door_c05_build', [
        ('door_c05_b_op', '730c635eed84d1830a22b3d2f00a5f4afc3500a02b20d7fc0fdc74208a573f90'),
        ('door_c05_b_cl', '4237d78e9a1c6367f1ca282b0b7715cf9b30e9ccbb9578fa8221167ab43db887'),
    ]),
}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def unique_source(root, name, suffix, expected=None):
    if not re.fullmatch(r'[A-Za-z0-9_-]+', name):
        raise ValueError('Unsafe Nitro resource name')
    candidates = [path for path in root.glob(name + '*' + suffix)
                  if path.name == name + suffix or re.fullmatch(
                      re.escape(name) + r'\.\d+' + re.escape(suffix), path.name)]
    groups = {}
    for path in candidates:
        value = digest(path.read_bytes())
        if expected is None or value == expected:
            groups.setdefault(value, []).append(path)
    if len(groups) != 1:
        raise ValueError('Expected one unambiguous Nitro source digest')
    value, paths = next(iter(groups.items()))
    return min(paths, key=lambda path: (len(path.name), path.name)), value


def read_glb(data):
    if len(data) < 28 or struct.unpack_from('<III', data) != (0x46546c67, 2, len(data)):
        raise ValueError('Invalid GLB header')
    length, kind = struct.unpack_from('<II', data, 12)
    if kind != 0x4e4f534a or length % 4 or 20 + length + 8 > len(data):
        raise ValueError('Invalid GLB JSON chunk')
    document = json.loads(data[20:20 + length])
    if not isinstance(document, dict):
        raise ValueError('Invalid GLB JSON document')
    binary_length, binary_kind = struct.unpack_from('<II', data, 20 + length)
    if binary_kind != 0x004e4942 or 28 + length + binary_length != len(data):
        raise ValueError('Invalid GLB binary chunk')
    return document


def object_transform(dae, source_group, anchor):
    root = ET.fromstring(dae)
    scene = root.find('c:library_visual_scenes/c:visual_scene', NS)
    if scene is None:
        raise ValueError('Missing source visual scene')
    parts = source_group.split('/')
    if len(parts) == 2 and parts[0] == parts[1]:
        parts = parts[:1]
    matches = []

    def visit(node, path, transform):
        name = node.get('id') or node.get('name')
        path = path + [name]
        transforms = node.findall('c:matrix', NS)
        if len(transforms) > 1 or any(node.find('c:' + kind, NS) is not None
                                     for kind in ('translate', 'rotate', 'scale', 'lookat', 'skew')):
            raise ValueError('Unsupported source object transform composition')
        transform = multiply(transform, matrix(transforms[0].text) if transforms else IDENTITY)
        if path == parts:
            matches.append(transform)
        for child in node.findall('c:node', NS):
            visit(child, path, transform)

    for node in scene.findall('c:node', NS):
        visit(node, [], IDENTITY)
    if len(matches) != 1 or len(anchor) != 3:
        raise ValueError('Source group must resolve exactly one native map object')
    scale = [value / 16 if row < 3 else value
             for row in range(4) for value in IDENTITY[row * 4:row * 4 + 4]]
    shift = IDENTITY.copy()
    shift[3], shift[7], shift[11] = [-float(value) for value in anchor]
    return multiply(shift, multiply(scale, matches[0]))


def source_map(record, map_root, source_group=None):
    archive_name = MAP_ARCHIVES[record['city']]
    source = map_root / archive_name
    archive_bytes = source.read_bytes()
    with zipfile.ZipFile(BytesIO(archive_bytes)) as archive:
        members = [name for name in archive.namelist() if name.endswith('.dae')]
        if len(members) != 1:
            raise ValueError('Expected exactly one authoritative map DAE')
        member = members[0]
        dae = archive.read(member)
    return object_transform(dae, source_group or record['sourceGroup'], record['sourceAnchorCells']), {
        'archive': str(source), 'archiveSha256': digest(archive_bytes),
        'member': member, 'memberSha256': digest(dae),
    }


def stage_original(apicula, source_model, source_animation, output_root, name):
    proof_folder = output_root / 'original' / name
    proof = proof_folder / (name + '.glb')
    proof_folder.parent.mkdir(parents=True, exist_ok=True)
    command = [str(apicula), 'convert', str(source_model)]
    if source_animation is not None:
        animations = source_animation if isinstance(source_animation, (list, tuple)) else [source_animation]
        command.extend(str(path) for path in animations)
    command.extend(['-o', str(proof_folder), '-f', 'glb', '--overwrite'])
    process = subprocess.run(command, capture_output=True, text=True)
    (output_root / (name + '.conversion.log')).write_text(process.stdout + process.stderr)
    if process.returncode:
        raise ValueError('Pinned apicula conversion failed')
    return proof


def joint_channels(data, name):
    if data[:4] != b'BCA0':
        raise ValueError('Expected Nitro joint animation')
    matches = [(block, struct.unpack('<I', entry)[0])
               for kind, block in blocks(data) if kind == b'JNT0'
               for entry, actual_name in dictionary(data, block + 8, 4) if actual_name == name]
    if len(matches) != 1:
        raise ValueError('Expected exactly one matching native joint clip')
    block, offset = matches[0]
    base = block + offset
    if data[base:base + 4] != b'J\0AC':
        raise ValueError('Invalid native joint clip signature')
    frames, count, clip_flags = unpack(data, base + 4, '<HHI')
    if frames < 1 or count > 512 or clip_flags & 2:
        raise ValueError('Unsupported native joint clip domain')
    joints = []
    for ordinal, track_offset in enumerate(unpack(data, base + 20, '<' + 'H' * count)):
        flags, _, index = unpack(data, base + track_offset, '<HBB')
        if index != ordinal:
            raise ValueError('Native joint ordering does not match original model nodes')
        cursor = base + track_offset + 4
        channels = {'identityPaths': [path for path, identity in (
            ('translation', 2), ('rotation', 0x40), ('scale', 0x200))
            if flags & 1 or flags & identity]}
        if not flags & 1:
            for path, active, constant_bits, constant_width in [
                ('translation', not flags & 6, [8, 16, 32], 4),
                ('rotation', not flags & 0xc0, [0x100], 4),
                ('scale', not flags & 0x600, [0x800, 0x1000, 0x2000], 8),
            ]:
                if not active:
                    continue
                curves = []
                for constant in constant_bits:
                    if flags & constant:
                        value = unpack(data, cursor, '<i')[0] / 4096 if path != 'rotation' else None
                        curves.append({'rate': 0, 'samples': [(0, value)]})
                        cursor += constant_width
                        continue
                    info, samples_offset = unpack(data, cursor, '<II')
                    cursor += 8
                    rate = 1 << (info >> 30)
                    boundary = (info >> 16) & 0x1fff
                    if rate > 4 or info & 0xffff or boundary > frames or boundary % rate:
                        raise ValueError('Unsupported native joint sampling domain')
                    if path == 'rotation':
                        if rate != 1 or boundary != frames:
                            raise ValueError('Undersampled joint rotations require native matrix evaluation')
                        curves.append({'rate': rate, 'samples': []})
                        continue
                    sample_frames = list(range(0, boundary, rate)) + list(range(boundary, frames))
                    fmt = '<h' if info & 0x20000000 else '<i'
                    width = struct.calcsize(fmt) * (2 if path == 'scale' else 1)
                    samples = [(frame, unpack(data, base + samples_offset + i * width, fmt)[0] / 4096)
                               for i, frame in enumerate(sample_frames)]
                    if not samples:
                        raise ValueError('Empty native joint scalar curve')
                    curves.append({'rate': rate, 'samples': samples})
                channels[path] = curves
        joints.append(channels)
    return frames, joints


def scalar_at(curve, frame):
    samples = curve['samples']
    if len(samples) == 1 or frame <= samples[0][0]:
        return samples[0][1]
    for i in range(1, len(samples)):
        right, value = samples[i]
        if frame <= right:
            left, previous = samples[i - 1]
            return previous + (value - previous) * (frame - left) / (right - left)
    return samples[-1][1]


def joint_node_map(document, original_model, joint_count):
    if original_model[:4] != b'BMD0':
        raise ValueError('Expected Nitro model for joint target mapping')
    models = [(block, unpack(entry, 0, '<I')[0])
              for kind, block in blocks(original_model) if kind == b'MDL0'
              for entry, _ in dictionary(original_model, block + 8, 4)]
    if len(models) != 1:
        raise ValueError('Expected exactly one original Nitro model')
    block, offset = models[0]
    base = block + offset
    names = [name for _, name in dictionary(original_model, base + 64, 4)]
    if len(names) != joint_count or unpack(original_model, base + 23, '<B')[0] != joint_count:
        raise ValueError('Native model and joint clip node counts disagree')
    if len(set(names)) != len(names):
        raise ValueError('Ambiguous native model joint names')
    indices = {name: index for index, name in enumerate(names)}
    return {index: indices[node['name']] for index, node in enumerate(document['nodes'])
            if node.get('name') in indices and 'skin' not in node}


def restore_joint_timeline(original_glb, original_nitro, name, original_model):
    from rigidify_bw2_animation import GlbWriter, accessor_rows, read_glb as read_chunks
    frames, joints = joint_channels(original_nitro, name)
    document, binary = read_chunks(original_glb)
    clips = [clip for clip in document.get('animations', []) if clip.get('name') == name]
    if len(clips) != 1:
        raise ValueError('Expected exactly one original GLB joint clip')
    clip = clips[0]
    node_joints = joint_node_map(document, original_model, len(joints))
    writer = GlbWriter(document, binary)
    used = {}
    targets = set()
    restored = 0
    for channel in clip['channels']:
        sampler_index = channel['sampler']
        node = channel['target']['node']
        path = channel['target']['path']
        if sampler_index in used or node not in node_joints or (node, path) in targets:
            raise ValueError('Ambiguous original GLB joint target')
        sampler = clip['samplers'][sampler_index]
        curves = joints[node_joints[node]].get(path, [])
        if path != 'rotation' and any(curve['rate'] > 1 for curve in curves):
            if len(curves) != 3:
                raise ValueError('Incomplete original joint vector channel')
            poses = [[scalar_at(curve, frame) for curve in curves] for frame in range(frames)]
            sampler['input'] = writer.rows([[frame / 60] for frame in range(frames)], 'SCALAR')
            sampler['output'] = writer.rows(poses, 'VEC3')
            sampler['interpolation'] = 'LINEAR'
            restored += 1
        used[sampler_index] = sampler
        targets.add((node, path))
    identities = {'translation': [0, 0, 0], 'rotation': [0, 0, 0, 1], 'scale': [1, 1, 1]}
    restored_identities = []
    for node, joint in node_joints.items():
        for path in joints[joint]['identityPaths']:
            if (node, path) in targets:
                continue
            if 'matrix' in document['nodes'][node]:
                raise ValueError('Native joint identity cannot target a matrix node')
            sampler_index = len(clip['samplers'])
            sampler = {
                'input': writer.rows([[0]], 'SCALAR'),
                'output': writer.rows([identities[path]], 'VEC4' if path == 'rotation' else 'VEC3'),
                'interpolation': 'LINEAR',
            }
            clip['samplers'].append(sampler)
            clip['channels'].append({'sampler': sampler_index, 'target': {'node': node, 'path': path}})
            used[sampler_index] = sampler
            restored_identities.append({'node': node, 'joint': joint,
                                        'name': document['nodes'][node]['name'], 'path': path})
    period = frames / 60
    binary = writer.binary
    variable = []
    for index, sampler in used.items():
        times = accessor_rows(document, binary, sampler['input'])
        poses = accessor_rows(document, binary, sampler['output'])
        if times[-1][0] > period + 1e-6:
            raise ValueError('Original sampler exceeds the native joint clip period')
        if len(times) > 1 and any(pose != poses[0] for pose in poses[1:]):
            variable.append((times[-1][0], index, times, poses))
    if not variable:
        raise ValueError('Native joint clip contains no variable used channel')
    previous_end, index, times, poses = max(variable, key=lambda item: (item[0], -item[1]))
    if previous_end < period - 1e-6:
        sampler = clip['samplers'][index]
        sampler['input'] = writer.rows(times + [[period]], 'SCALAR')
        sampler['output'] = writer.rows(poses + [poses[-1]], 'VEC4' if len(poses[-1]) == 4 else 'VEC3')
    return writer.finish(), {
        'frames': frames, 'periodSeconds': period, 'previousLastKeySeconds': previous_end,
        'periodBoundarySampler': index, 'restoredScalarSamplers': restored,
        'restoredIdentityChannels': restored_identities,
        'jointTargetPolicy': 'Original NSBMD object dictionary names mapped to Apicula GLB nodes',
        'identityReference': 'pret/pokeheartgold lib/asm/nnsys.s getJntSRTAnmResult_ 19016-19019, 19098-19107, 19162-19171, 19253-19262',
        'finalPosePolicy': 'Native dense tail restored before terminal hold boundary',
        'samplingReference': 'pret/pokeheartgold lib/asm/nnsys.s getTransData_ 19285-19381; NNSi_G3dAnmCalcNsBca 18784-18801',
        'conversionFramesPerSecond': 60, 'originalRuntimeCadenceVerified': False,
    }


def attach_proven_child_clips(current_glb, animated_child_glb, source_to_current):
    from rigidify_bw2_animation import enrich_rigid_animation, read_glb as read_chunks, write_glb
    current, binary = read_chunks(current_glb)
    leaves = [(index, node) for index, node in enumerate(current.get('nodes', []))
              if node.get('name') == 'Verified static source geometry' and 'mesh' in node]
    if len(leaves) != 1:
        raise ValueError('Expected exactly one verified static child leaf')
    leaf_index, leaf = leaves[0]
    scene = current['scenes'][current.get('scene', 0)]
    if leaf_index not in scene['nodes'] or leaf.get('children') or any(
            key in leaf for key in ('matrix', 'translation', 'rotation', 'scale', 'skin')):
        raise ValueError('Verified static child must be an untransformed scene root')
    if not current.get('animations') or any(
            channel['target']['node'] == leaf_index
            for clip in current['animations'] for channel in clip['channels']):
        raise ValueError('Static child is not independent from the ambient clips')
    child = deepcopy(current)
    child['nodes'] = [{'mesh': 0}]
    child['meshes'] = [deepcopy(current['meshes'][leaf['mesh']])]
    child['scenes'] = [{'nodes': [0]}]
    child['scene'] = 0
    child.pop('animations', None)
    converted, binding = enrich_rigid_animation(
        write_glb(child, binary), animated_child_glb, source_to_current)
    graft, extended_binary = read_chunks(converted)
    if not extended_binary.startswith(binary) or any(
            graft[key][:len(current.get(key, []))] != current.get(key, [])
            for key in ('accessors', 'bufferViews')):
        raise ValueError('Child conversion changed the existing geometry buffers')
    result = deepcopy(current)
    for key in ('buffers', 'bufferViews', 'accessors'):
        result[key] = graft[key]
    node_offset, mesh_offset = len(result['nodes']), len(result['meshes'])
    result['meshes'].extend(graft['meshes'])
    for node in graft['nodes']:
        copy = deepcopy(node)
        if 'mesh' in copy:
            copy['mesh'] += mesh_offset
        if 'children' in copy:
            copy['children'] = [index + node_offset for index in copy['children']]
        result['nodes'].append(copy)
    roots = result['scenes'][result.get('scene', 0)]['nodes']
    roots.remove(leaf_index)
    roots.extend(index + node_offset for index in graft['scenes'][graft.get('scene', 0)]['nodes'])
    first_added = len(result['animations'])
    existing_names = {clip.get('name') for clip in result['animations']}
    for clip in graft['animations']:
        if clip.get('name') in existing_names:
            raise ValueError('Child clip name collides with an existing ambient clip')
        existing_names.add(clip.get('name'))
        copy = deepcopy(clip)
        for channel in copy['channels']:
            channel['target']['node'] += node_offset
        result['animations'].append(copy)
    return write_glb(result, extended_binary), {
        'binding': binding, 'replacedStaticRoot': leaf_index,
        'addedClipIndices': list(range(first_added, len(result['animations']))),
        'ambientClipsPreserved': result['animations'][:first_added] == current['animations'],
        'defaultAmbientIndex': 0, 'automaticDoorPlayback': False,
        'currentBinaryPrefixPreserved': extended_binary.startswith(binary),
    }


def stage_doors(ambient_index, joint_index, nitro_root, apicula, output_root):
    from rigidify_bw2_animation import read_glb as read_chunks, write_glb
    ambient_index = ambient_index.resolve(strict=True)
    joint_index = joint_index.resolve(strict=True)
    nitro_root = nitro_root.resolve(strict=True)
    output_root = output_root.resolve()
    protected = [nitro_root, ambient_index.parent, joint_index.parent]
    if any(output_root == root or root in output_root.parents or output_root in root.parents
           for root in protected):
        raise ValueError('Door output must be outside read-only source roots')
    ambient = json.loads(ambient_index.read_text())
    joints = json.loads(joint_index.read_text())
    inventory = json.loads((nitro_root.parent / 'animation-inventory.json').read_text())
    source_sha = ambient['source']['rom_sha256']
    if any(document['source'].get('rom_sha256') != source_sha for document in (joints, inventory)):
        raise ValueError('Door sources must come from the same verified ROM')
    targets = {record['modelId']: record for record in ambient['entries']}
    output_root.mkdir(parents=True, exist_ok=True)
    result = {'schemaVersion': 1, 'source': ambient['source'], 'entries': [], 'refused': []}
    for joint in joints['converted']:
        if joint['clip'] not in PROVEN_CHILD_CLIPS:
            if joint['verifiedStaticAttachments']:
                result['refused'].append({'modelId': joint['modelId'],
                                         'reason': 'Generic door clips lack an exact original child association'})
            continue
        try:
            model_id = joint['modelId']
            if not re.fullmatch(r'[A-Za-z0-9_-]+', model_id):
                raise ValueError('Unsafe target model identifier')
            row = targets[model_id]
            current = Path(row['sourcePath']).read_bytes()
            if digest(current) != row['sha256After']:
                raise ValueError('Ambient GLB changed after its verified staging')
            model_name, clip_specs = PROVEN_CHILD_CLIPS[joint['clip']]
            attachments = joint['verifiedStaticAttachments']
            if len(attachments) != 1:
                raise ValueError('Expected one independently verified original child')
            attachment = attachments[0]
            model, model_sha = unique_source(
                nitro_root, model_name, '.nsbmd', attachment['originalModelSha256'])
            native_clips = []
            provenance = []
            for name, expected_sha in clip_specs:
                matches = [clip for clip in inventory['animations']
                           if clip['name'] == name and clip['sha256'] == expected_sha]
                if len(matches) != 1 or matches[0]['frames'] != 8:
                    raise ValueError('Original door clip inventory is ambiguous')
                native, actual_sha = unique_source(nitro_root, name, '.nsbca', expected_sha)
                frames, channels = joint_channels(native.read_bytes(), name)
                if frames != 8 or len(channels) != 3:
                    raise ValueError('Original door clip does not match its three rigid joints')
                native_clips.append(native)
                provenance.append({'name': name, 'originalAnimation': str(native),
                                   'originalAnimationSha256': actual_sha,
                                   'origins': matches[0]['origins'], 'originalFrames': frames})
            proof = stage_original(apicula, model, native_clips, output_root, model_name)
            original = proof.read_bytes()
            names = [clip.get('name') for clip in read_glb(original).get('animations', [])]
            if set(names) != {name for name, _ in clip_specs} or len(names) != 2:
                raise ValueError('Source conversion did not retain exactly both original door clips')
            document, binary = read_chunks(original)
            document['animations'].sort(key=lambda clip: [name for name, _ in clip_specs].index(clip['name']))
            original = write_glb(document, binary)
            for native, clip_provenance in zip(native_clips, provenance):
                original, timeline = restore_joint_timeline(
                    original, native.read_bytes(), clip_provenance['name'], model.read_bytes())
                clip_provenance['timelineRestoration'] = timeline
            encoded, binding = attach_proven_child_clips(current, original, attachment['sourceToCurrent'])
            document, binary = read_chunks(encoded)
            evidence = {'modelId': model_id, 'originalModel': str(model),
                        'originalModelSha256': model_sha, 'originalAnimatedGlb': str(proof),
                        'originalAnimatedGlbSha256': digest(proof.read_bytes()),
                        'verifiedChild': attachment, 'clips': provenance, 'rigidGeometry': binding,
                        'association': 'Exact DAE child model and named three-joint NSBCA pair',
                        'playbackPolicy': 'gameplay_trigger_required', 'defaultAmbientIndex': 0}
            document.setdefault('extras', {}).setdefault('aveluneAnimationSource', {})['childJointClips'] = evidence
            encoded = write_glb(document, binary)
            destination = output_root / 'models' / (model_id + '.glb')
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(encoded)
            result['entries'].append({'modelId': model_id, 'sourcePath': str(destination),
                                      'inputSha256': digest(current), 'sha256After': digest(encoded),
                                      'clips': [clip['name'] for clip in document['animations']],
                                      'recommendedAnimationIndex': 0, 'provenance': evidence})
        except (ValueError, KeyError, OSError) as error:
            result['refused'].append({'modelId': joint['modelId'], 'reason': str(error)})
    (output_root / 'door_animation_application.json').write_text(
        json.dumps(result, ensure_ascii=False, indent=2, allow_nan=False) + '\n')
    return result


def stage(candidates, nitro_root, map_root, apicula, output_root, source_only=False):
    candidates = candidates.resolve(strict=True)
    nitro_root = nitro_root.resolve(strict=True)
    map_root = map_root.resolve(strict=True)
    output_root = output_root.resolve()
    data = json.loads(candidates.read_text())
    protected = [nitro_root, map_root, *[
        Path(record['sourceGlb']).resolve(strict=True).parent.parent.parent
        for record in data['models']]]
    if any(output_root == root or root in output_root.parents or output_root in root.parents
           for root in protected):
        raise ValueError('Output must be outside read-only source roots')
    output_root.mkdir(parents=True, exist_ok=True)
    result = {
        'schemaVersion': 1, 'source': data['source'], 'sourceOnly': source_only,
        'timeline': {
            'sourceUnit': 'Nitro frame index',
            'conversionFramesPerSecond': 60,
            'conversionReference': 'apicula/src/convert/gltf/mod.rs:23 FRAME_LENGTH=1/60',
            'originalRuntimeCadenceVerified': False,
        },
        'converted': [], 'refused': [],
    }
    for record in data['models']:
        if 'fwheel' in record['sourceGroup']:
            continue
        try:
            if not re.fullmatch(r'[A-Za-z0-9_-]+', record['modelId']):
                raise ValueError('Unsafe target model identifier')
            if len(record['animations']) != 1:
                raise ValueError('Multiple native joint clips need explicit policy')
            clip = record['animations'][0]
            name = clip['name']
            source_model, model_sha = unique_source(nitro_root, name, '.nsbmd')
            source_animation, animation_sha = unique_source(
                nitro_root, name, '.nsbca', clip['sha256'])
            proof = stage_original(apicula, source_model, source_animation, output_root, name)
            document = read_glb(proof.read_bytes())
            if [animation.get('name') for animation in document.get('animations', [])] != [name]:
                raise ValueError('Source conversion did not retain the exact original clip')
            transform, provenance = source_map(record, map_root)
            static_sources = []
            static_provenance = []
            for static_name, child in STATIC_ATTACHMENTS.get(name, []):
                static_model, static_sha = unique_source(nitro_root, static_name, '.nsbmd')
                static_proof = stage_original(apicula, static_model, None, output_root, static_name)
                parts = record['sourceGroup'].split('/')
                if len(parts) == 2 and parts[0] == parts[1]:
                    parts = parts[:1]
                static_transform, static_map_source = source_map(
                    record, map_root, '/'.join(parts + [child]))
                static_sources.append((static_proof.read_bytes(), static_transform))
                static_provenance.append({
                    'originalModel': str(static_model), 'originalModelSha256': static_sha,
                    'originalGlb': str(static_proof), 'originalGlbSha256': digest(static_proof.read_bytes()),
                    'sourceToCurrent': static_transform, 'mapSource': static_map_source,
                })
            current = Path(record['sourceGlb']).read_bytes()
            item = {
                'city': record['city'], 'modelId': record['modelId'], 'sourceGroup': record['sourceGroup'],
                'originalModel': str(source_model), 'originalModelSha256': model_sha,
                'originalAnimation': str(source_animation), 'originalAnimationSha256': animation_sha,
                'originalAnimatedGlb': str(proof), 'originalAnimatedGlbSha256': digest(proof.read_bytes()),
                'currentGlb': record['sourceGlb'], 'currentGlbSha256': digest(current),
                'sourceToCurrent': transform, 'mapSource': provenance,
                'clip': name, 'originalFrames': clip['frames'],
                'verifiedStaticAttachments': static_provenance,
                'materialsAndTextures': 'Preserved from the current GLB; source GLB supplies only rigid binding and native joint curves',
                'automaticLoopRequested': False,
            }
            if not source_only:
                from rigidify_bw2_animation import enrich_rigid_animation
                restored_source, timeline = restore_joint_timeline(
                    proof.read_bytes(), source_animation.read_bytes(), name, source_model.read_bytes())
                if timeline['frames'] != clip['frames']:
                    raise ValueError('Candidate clip duration does not match native joint header')
                converted, evidence = enrich_rigid_animation(
                    current, restored_source, source_to_current=transform,
                    static_sources=static_sources)
                destination = output_root / 'models' / (record['modelId'] + '.glb')
                destination.parent.mkdir(parents=True, exist_ok=True)
                destination.write_bytes(converted)
                item.update({'output': str(destination), 'outputSha256': digest(converted),
                             'evidence': evidence, 'timelineRestoration': timeline})
            result['converted'].append(item)
        except (ValueError, KeyError, OSError) as error:
            result['refused'].append({'modelId': record['modelId'], 'reason': str(error)})
    (output_root / 'joint_animation_application.json').write_text(
        json.dumps(result, ensure_ascii=False, indent=2, allow_nan=False) + '\n')
    return result


def main():
    parser = argparse.ArgumentParser()
    sources = parser.add_mutually_exclusive_group(required=True)
    sources.add_argument('--candidate-index', type=Path)
    sources.add_argument('--door-clips-from', type=Path)
    parser.add_argument('--joint-index', type=Path)
    parser.add_argument('--nitro-root', type=Path, required=True)
    parser.add_argument('--map-root', type=Path)
    parser.add_argument('--apicula', type=Path, required=True)
    parser.add_argument('--output-root', type=Path, required=True)
    parser.add_argument('--source-only', action='store_true')
    args = parser.parse_args()
    if args.door_clips_from is not None:
        if args.joint_index is None or args.source_only:
            parser.error('Door staging requires --joint-index and cannot use --source-only')
        result = stage_doors(args.door_clips_from, args.joint_index, args.nitro_root,
                             args.apicula, args.output_root)
        print(json.dumps({'converted': len(result['entries']), 'refused': result['refused'],
                          'index': str(args.output_root / 'door_animation_application.json')}))
        return
    if args.map_root is None:
        parser.error('Joint staging requires --map-root')
    result = stage(args.candidate_index, args.nitro_root, args.map_root, args.apicula,
                   args.output_root, source_only=args.source_only)
    print(json.dumps({'converted': len(result['converted']), 'refused': result['refused'],
                      'index': str(args.output_root / 'joint_animation_application.json')}))


if __name__ == '__main__':
    main()

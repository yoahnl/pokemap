import argparse
from bisect import bisect_right
from collections import Counter, defaultdict
from copy import deepcopy
from hashlib import sha256
from io import BytesIO
import json
import math
from pathlib import Path
import re
import struct
import sys
import xml.etree.ElementTree as ET

from PIL import Image

from bw2_city_animation_sources import NAMESPACE, source_scene, material_texture, read_archive
from read_bw2_nitro_animations import nitro_affine, read_model_materials, read_srt, verified_source
from rigidify_bw2_animation import GlbWriter, accessor_rows
from convert_bw2_pattern_frames import decode_pattern_frames
from convert_bw2_city_joint_animations import restore_joint_timeline, source_map, stage_original, unique_source
from rigidify_bw2_animation import enrich_rigid_animation


AMBIENT_JOINT_CLIPS = {'c04_fwheel_01', 'c7_windmill_01', 'c14_boat', 'c03_ship_02',
                       'c2_build_01', 'c2_build_02', 'c2_build_03', 'c5_build_01', 't1_labo_01'}


def configure_joint_playback(document, name):
    ambient = name in AMBIENT_JOINT_CLIPS
    material_clips = document.get('extras', {}).get('aveluneMaterialAnimations', {}).get('clips', [])
    for clip in material_clips:
        if ambient:
            clip['nodeAnimationIndex'] = 0
        else:
            clip.pop('nodeAnimationIndex', None)
    return len(document['animations']) if material_clips else 0 if ambient else None


def read_glb(data):
    if len(data) < 28 or struct.unpack_from('<III', data) != (0x46546c67, 2, len(data)):
        raise ValueError('Invalid GLB header')
    length, kind = struct.unpack_from('<I4s', data, 12)
    if kind != b'JSON' or 20 + length + 8 > len(data):
        raise ValueError('Invalid GLB JSON chunk')
    document = json.loads(data[20:20 + length])
    size, kind = struct.unpack_from('<I4s', data, 20 + length)
    binary = data[28 + length:]
    if kind != b'BIN\0' or len(binary) != size:
        raise ValueError('Invalid GLB binary chunk')
    return document, binary


def glb_bytes(document, binary):
    encoded = json.dumps(document, separators=(',', ':'), allow_nan=False).encode()
    encoded += b' ' * (-len(encoded) % 4)
    binary += b'\0' * (-len(binary) % 4)
    return (struct.pack('<III', 0x46546c67, 2, 28 + len(encoded) + len(binary))
            + struct.pack('<I4s', len(encoded), b'JSON') + encoded
            + struct.pack('<I4s', len(binary), b'BIN\0') + binary)


def texture_size(document, binary, material_index):
    material = document['materials'][material_index]
    index = material['pbrMetallicRoughness']['baseColorTexture']['index']
    image = document['images'][document['textures'][index]['source']]
    view = document['bufferViews'][image['bufferView']]
    if view['buffer'] != 0:
        raise ValueError('External image buffer is unsupported')
    offset = view.get('byteOffset', 0)
    with Image.open(BytesIO(binary[offset:offset + view['byteLength']])) as image:
        return image.size


def model_names(groups):
    result = set()
    for group in groups:
        if match := re.search(r'/object_\d+_(.+)$', group):
            result.add(match[1])
        elif match := re.match(r'map_\d+_(\d+)_(\d+)', group):
            result.add(f'map{int(match[1]):02d}_{int(match[2]):02d}')
    return result


class NitroSources:
    def __init__(self, root, material_names):
        self.root = root
        self.inventory = json.loads((root / 'animation-inventory.json').read_text())
        self.by_material = defaultdict(list)
        self.models = {}
        self.raw_paths = defaultdict(list)
        self.global_modes = None
        for path in (root / 'nitro-original').glob('*.nsbmd'):
            self.raw_paths[path.stem].append(path)
        for record in self.inventory['animations']:
            if record['type'] != 'SRT0' or not any(track['material'] in material_names for track in record['tracks']):
                continue
            clips = read_srt(verified_source(root, record))
            clip = next(clip for clip in clips if clip['name'] == record['name'])
            for track in clip['tracks']:
                if track['material'] in material_names:
                    self.by_material[track['material']].append({**track, 'clip': clip['name'],
                                                               'frames': clip['frames'], 'source': record})

    def modes(self, names, material):
        result = set()
        for name in sorted(names):
            if name not in self.models:
                candidates = [path for stem, paths in self.raw_paths.items()
                              if stem == name or stem.startswith(name + '.')
                              for path in paths]
                self.models[name] = [model for path in candidates
                                     for model in read_model_materials(path.read_bytes())
                                     if model['name'] == name]
            result.update(model['textureMatrixMode'] for model in self.models[name]
                          if material in model['materials'])
        return result

    def shared_material_modes(self, material):
        if self.global_modes is None:
            self.global_modes = defaultdict(set)
            seen = set()
            for paths in self.raw_paths.values():
                for path in paths:
                    data = path.read_bytes()
                    digest = sha256(data).hexdigest()
                    if digest in seen:
                        continue
                    seen.add(digest)
                    for model in read_model_materials(data):
                        for name in model['materials']:
                            self.global_modes[name].add(model['textureMatrixMode'])
        return self.global_modes[material]


def source_material_context(source_root, record):
    data, _, provenance = read_archive(source_root, record, record['sha256'])
    tree = ET.fromstring(data)
    by_id = {node.get('id'): node for node in tree.iter() if node.get('id')}
    scene = by_id[tree.find('c:scene/c:instance_visual_scene', NAMESPACE).get('url')[1:]]
    result = defaultdict(lambda: {'textures': set(), 'groups': set()})

    def walk(node, trail):
        trail = trail + [node.get('id', node.get('name', ''))]
        object_name = next((name for name in trail if name.startswith('object_')), None)
        group = trail[0] + '/' + (object_name or (trail[1] if len(trail) > 1 else trail[0]))
        for instance in list(node.findall('c:instance_geometry', NAMESPACE)) + list(node.findall('c:instance_controller', NAMESPACE)):
            for binding in instance.findall('c:bind_material/c:technique_common/c:instance_material', NAMESPACE):
                material = by_id[binding.get('target')[1:]]
                name = material.get('name', material.get('id'))
                try:
                    texture, _ = material_texture(by_id, material)
                except ValueError as error:
                    if 'diffuse texture' not in str(error):
                        raise
                    texture = material.get('id') + '.png'
                result[name]['textures'].add(texture)
                result[name]['groups'].add(group)
        for child in node.findall('c:node', NAMESPACE):
            walk(child, trail)

    for node in scene.findall('c:node', NAMESPACE):
        walk(node, [])
    return {name: {key: sorted(values) for key, values in info.items()}
            for name, info in result.items()}, provenance


def source_contexts(project, source_root, catalog):
    result = []
    base = project / '.pokemap/authoring/unys-cities'
    records = {record['id']: record for record in json.loads((source_root / 'manifest.json').read_text())['assets']}
    for city in catalog['cities']:
        folder = base / city['id']
        if not (folder / 'assets_manifest.json').exists():
            continue
        manifest = json.loads((folder / 'assets_manifest.json').read_text())
        materials, provenance = source_material_context(source_root, records[city['sourceId']])
        result.append({'city': city['id'], 'mapId': 'unys-' + city['id'],
                       'models': {model['modelId']: model for model in manifest['models']},
                       'materials': materials, 'provenance': provenance,
                       'record': records[city['sourceId']], 'sourceRoot': source_root})
    folder = project / '.pokemap/authoring/pavonnay'
    if (folder / 'assets_manifest.json').exists():
        manifest = json.loads((folder / 'assets_manifest.json').read_text())
        materials, provenance = source_material_context(source_root, records[manifest['source']['assetId']])
        models = {model['modelId']: model for model in manifest['models']}
        water = project / '.pokemap/authoring/pavonnay-water/manifest.json'
        if water.exists():
            models.update({model['modelId']: model for model in json.loads(water.read_text())['models']})
        result.append({'city': 'pavonnay', 'mapId': 'first-map', 'models': models,
                       'materials': materials, 'provenance': provenance,
                       'record': records[manifest['source']['assetId']], 'sourceRoot': source_root})
    return result


def material_identity(material, recipe, context):
    if material.get('extras', {}).get('aveluneNitroMaterial') in context['materials']:
        return material['extras']['aveluneNitroMaterial']
    candidates = material_candidates(material, recipe, context)
    return candidates[0] if len(candidates) == 1 else None


def material_candidates(material, recipe, context):
    texture = material.get('name', '').split('@')[0]
    materials = context['materials']
    candidates = [name for name, info in materials.items() if texture in info['textures']]
    if recipe.get('sourceMaterial') in candidates:
        candidates = [recipe['sourceMaterial']]
    if len(candidates) > 1 and recipe.get('kind') == 'object' and recipe.get('sourceGroup'):
        candidates = [name for name in candidates if recipe['sourceGroup'] in materials[name]['groups']]
    return candidates


def point_in_source_triangle(position, uv, color, triangle):
    a, b, c = [vertex[:3] for vertex in triangle]
    ab, ac = [[q - p for p, q in zip(a, other)] for other in [b, c]]
    normal = [ab[1] * ac[2] - ab[2] * ac[1], ab[2] * ac[0] - ab[0] * ac[2], ab[0] * ac[1] - ab[1] * ac[0]]
    axes = [axis for axis in range(3) if axis != max(range(3), key=lambda axis: abs(normal[axis]))]
    x, y = axes
    determinant = ab[x] * ac[y] - ab[y] * ac[x]
    if abs(determinant) < 1e-10:
        return False
    ap = [q - p for p, q in zip(a, position)]
    u = (ap[x] * ac[y] - ap[y] * ac[x]) / determinant
    v = (ab[x] * ap[y] - ab[y] * ap[x]) / determinant
    weights = [1 - u - v, u, v]
    if min(weights) < -.00003:
        return False
    expected = [sum(weight * vertex[axis] for weight, vertex in zip(weights, triangle)) for axis in range(8)]
    return (max(abs(a - b) for a, b in zip(expected[:3], position)) <= .00003
            and max(abs(a - b) for a, b in zip(expected[3:5], uv)) <= .0001
            and max(abs(a - b) for a, b in zip(expected[5:8], color)) <= .0001)


def split_animated_materials(document, binary, recipe, context, sources, patterns=()):
    ambiguous = {}
    pattern_materials = {track['material'] for candidate in patterns if candidate['city'] == context.get('city')
                         for track in candidate['tracks']}
    for index, material in enumerate(document.get('materials', [])):
        candidates = material_candidates(material, recipe, context)
        if len(candidates) > 1 and any(name in pattern_materials or any(len({tuple(sample) for sample in track['samples']}) > 1
                                                                      for track in sources.by_material[name]) for name in candidates):
            ambiguous[index] = candidates
    if not ambiguous:
        return document, binary, []
    if 'surfaces' not in context:
        context['surfaces'] = source_scene(context['sourceRoot'], context['record'])[0]
    output = deepcopy(document)
    data = bytearray(binary)
    new_primitives, evidence = [], []
    anchor = recipe['sourceAnchorCells']
    for mesh in output['meshes']:
        new_primitives = []
        for primitive in mesh['primitives']:
            index = primitive['material']
            if index not in ambiguous:
                new_primitives.append(primitive)
                continue
            texture = document['materials'][index]['name'].split('@')[0]
            candidates = [(surface.material, triangle) for surface in context['surfaces']
                          if surface.texture == texture and surface.material in ambiguous[index]
                          and (not recipe.get('sourceGroup') or recipe.get('kind') != 'object'
                               or surface.group == recipe['sourceGroup'])
                          for triangle in surface.triangles]
            buckets = defaultdict(list)
            for material, triangle in candidates:
                lo = [math.floor(min(vertex[axis] for vertex in triangle) / 4) for axis in [0, 2]]
                hi = [math.floor(max(vertex[axis] for vertex in triangle) / 4) for axis in [0, 2]]
                for x in range(lo[0], hi[0] + 1):
                    for z in range(lo[1], hi[1] + 1):
                        buckets[x, z].append((material, triangle))
            attributes = {name: accessor_rows(document, binary, accessor) for name, accessor in primitive['attributes'].items()}
            indices = [row[0] for row in accessor_rows(document, binary, primitive['indices'])] if 'indices' in primitive else list(range(len(attributes['POSITION'])))
            groups = defaultdict(list)
            for start in range(0, len(indices), 3):
                triangle = indices[start:start + 3]
                position = [sum(attributes['POSITION'][vertex][axis] for vertex in triangle) / 3 + anchor[axis] for axis in range(3)]
                uv = [sum(attributes['TEXCOORD_0'][vertex][axis] for vertex in triangle) / 3 for axis in range(2)]
                color = [sum(attributes.get('COLOR_0', [[1, 1, 1]] * len(attributes['POSITION']))[vertex][axis] for vertex in triangle) / 3 for axis in range(3)]
                matches = {material for material, original in buckets[math.floor(position[0] / 4), math.floor(position[2] / 4)]
                           if point_in_source_triangle(position, uv, color, original)}
                if len(matches) != 1:
                    raise ValueError('Animated material triangles have ambiguous source geometry')
                groups[next(iter(matches))].extend(triangle)
            for material_name, subset in sorted(groups.items()):
                material = deepcopy(document['materials'][index])
                material.setdefault('extras', {})['aveluneNitroMaterial'] = material_name
                material['name'] += '#' + material_name
                output['materials'].append(material)
                data.extend(b'\0' * (-len(data) % 4))
                encoded = struct.pack('<' + 'I' * len(subset), *subset)
                output['bufferViews'].append({'buffer': 0, 'byteOffset': len(data), 'byteLength': len(encoded), 'target': 34963})
                data.extend(encoded)
                output['accessors'].append({'bufferView': len(output['bufferViews']) - 1, 'componentType': 5125,
                                            'count': len(subset), 'type': 'SCALAR'})
                copy = deepcopy(primitive)
                copy.update(material=len(output['materials']) - 1, indices=len(output['accessors']) - 1)
                new_primitives.append(copy)
                evidence.append({'oldMaterialIndex': index, 'sourceMaterial': material_name, 'triangles': len(subset) // 3})
        mesh['primitives'] = new_primitives
    output['buffers'][0]['byteLength'] = len(data)
    return output, bytes(data), evidence


def profile(track):
    return (track['frames'], tuple(tuple(sample) for sample in track['samples']))


def choose_track(material, candidates, names, zone_clips):
    if not candidates:
        return None, 'static_no_source_track'
    exact = [track for track in candidates if track['clip'] in names]
    zoned = [track for track in candidates if track['clip'] in zone_clips]
    ambient = [track for track in candidates if track['clip'] == 'area_ita_00'
               or re.fullmatch(r'out\d+(?:_h\d+)?_ita', track['clip'])]
    chosen = exact or zoned or ambient
    if not chosen:
        return None, 'unrelated_source_track'
    variants = defaultdict(list)
    for track in chosen:
        variants[profile(track)].append(track)
    if len(variants) > 1:
        common = [track for track in chosen if track['clip'] == 'area_ita_00']
        if not exact and not zoned and common and material.startswith(('sea_', 'ike', 'mizu_', 'shore', 'kawa')):
            return common[0], 'common_area_source'
        return None, 'ambiguous_source_clip'
    group = next(iter(variants.values()))
    track = min(group, key=lambda item: (item['clip'] != 'area_ita_00', item['clip']))
    return track, 'exact_model_source' if exact else 'zone_material_source' if zoned else 'equivalent_source_curves'


def city_zone_clips(context, sources):
    result = set()
    for material in context['materials']:
        candidates = sources.by_material[material]
        clips = {track['clip'] for track in candidates}
        if len(clips) == 1:
            clip = next(iter(clips))
            if re.fullmatch(r'out\d+(?:_h\d+)?_ita', clip):
                result.add(clip)
    return result


def animated_material_document(document, binary, recipe, context, sources, fps):
    output = deepcopy(document)
    tracks, evidence, unsupported = [], [], []
    zone_clips = city_zone_clips(context, sources)
    used_materials = {primitive['material'] for mesh in document.get('meshes', []) for primitive in mesh['primitives']}
    for index, material in enumerate(document.get('materials', [])):
        if used_materials and index not in used_materials:
            continue
        identity = material_identity(material, recipe, context)
        if identity is None:
            candidates = material_candidates(material, recipe, context)
            if any(any(len({tuple(sample) for sample in track['samples']}) > 1
                       for track in sources.by_material[name]) for name in candidates):
                unsupported.append({'materialIndex': index, 'reason': 'missing_or_ambiguous_source_material'})
            continue
        groups = context['materials'][identity]['groups']
        if recipe.get('sourceGroup') in groups:
            groups = [recipe['sourceGroup']]
        names = model_names(groups)
        source, association = choose_track(identity, sources.by_material[identity], names, zone_clips)
        if source is None:
            if association not in ('static_no_source_track', 'unrelated_source_track'):
                unsupported.append({'materialIndex': index, 'sourceMaterial': identity, 'reason': association})
            continue
        modes = sources.modes(names, identity)
        mode_evidence = 'exact_source_model'
        if not modes and (source['clip'] == 'area_ita_00' or source['clip'] in zone_clips):
            modes = sources.shared_material_modes(identity)
            mode_evidence = 'same_named_material_unique_mode_across_original_rom_models'
        if len(modes) != 1:
            unsupported.append({'materialIndex': index, 'sourceMaterial': identity,
                                'reason': 'missing_or_ambiguous_source_matrix_mode', 'modes': sorted(modes)})
            continue
        mode = next(iter(modes))
        width, height = texture_size(document, binary, index)
        transforms = [nitro_affine(sample, mode, width, height) for sample in source['samples']]
        if len({tuple(transform) for transform in transforms}) == 1:
            continue
        duration = source['frames'] / fps
        tracks.append({'materialIndex': index, 'durationSeconds': duration,
                       'times': [frame / fps for frame in range(source['frames'])] + [duration],
                       'transforms': transforms + [transforms[0]], 'interpolation': 'STEP'})
        material_source = {'material': identity, 'modelNames': sorted(names), 'matrixMode': mode, 'matrixModeEvidence': mode_evidence,
                           'uvCoordinateConvention': 'nitro_normalized_uv',
                           'sourceUvConversion': 'nitro_to_collada_v_flip_then_glb_v_flip',
                           'matrixConversion': 'original_sdk_normalized_uv',
                           'animation': source['clip'], 'animationSha256': source['source']['sha256'],
                           'origins': source['source']['origins'], 'association': association}
        evidence.append(material_source)
        output['materials'][index].setdefault('extras', {})['aveluneNitroMaterial'] = identity
    if not tracks:
        return None, evidence, unsupported
    clip = {'name': 'Ambiance originale NB2', 'durationSeconds': max(track['durationSeconds'] for track in tracks),
            'tracks': tracks}
    output.setdefault('extras', {})['aveluneMaterialAnimations'] = {'schemaVersion': 1, 'clips': [clip]}
    return output, evidence, unsupported


def repair_material_animation_transforms(document, binary, sources):
    output = deepcopy(document)
    metadata = output.get('extras', {}).get('aveluneAnimationSource', {})
    fps = metadata.get('frameRate')
    if not isinstance(fps, (int, float)) or not math.isfinite(fps) or fps <= 0:
        raise ValueError('Missing verified material conversion frame rate')
    proofs = {entry['material']: entry for entry in metadata.get('materials', []) if 'matrixMode' in entry}
    evidence = []
    for clip in output.get('extras', {}).get('aveluneMaterialAnimations', {}).get('clips', []):
        for track in clip['tracks']:
            material_index = track['materialIndex']
            identity = output['materials'][material_index].get('extras', {}).get('aveluneNitroMaterial')
            proof = proofs.get(identity)
            if proof is None or 'transforms' not in track:
                continue
            if proof['matrixMode'] != 0:
                raise ValueError('Material repair is scoped to verified Maya matrix mode')
            candidates = [source for source in sources.by_material[identity]
                          if source['clip'] == proof['animation'] and source['source']['sha256'] == proof['animationSha256']]
            if len(candidates) != 1:
                raise ValueError('Missing or ambiguous verified material animation source')
            source = candidates[0]
            width, height = texture_size(output, binary, material_index)
            transforms = []
            for time in track['times']:
                frame = round(time * fps)
                if abs(frame / fps - time) > 1e-7:
                    raise ValueError('Material timeline no longer matches the original conversion frames')
                transforms.append(nitro_affine(source['samples'][frame % source['frames']], 0, width, height))
            conjugated = [[a, -b, -c, d, c + tx, 1 - d - ty] for a, b, c, d, tx, ty in transforms]
            current = track['transforms']

            def matches(expected):
                return len(current) == len(expected) and all(len(row) == len(original)
                    and all(abs(a - b) < 1e-6 for a, b in zip(row, original)) for row, original in zip(current, expected))

            unchanged = matches(transforms)
            if not unchanged and not matches(conjugated):
                raise ValueError('Current UV transforms do not match the pinned source or its previous conjugation')
            track['transforms'] = transforms
            proof.update(uvCoordinateConvention='nitro_normalized_uv',
                         sourceUvConversion='nitro_to_collada_v_flip_then_glb_v_flip',
                         matrixConversion='original_sdk_normalized_uv')
            evidence.append({'materialIndex': material_index, 'material': identity, 'animation': source['clip'],
                             'animationSha256': proof['animationSha256'], 'changed': not unchanged,
                             'samples': len(transforms), 'timelinePreserved': True, 'patternBindingsPreserved': True})
    return output, evidence


def repair_joint_animation_clip(current_glb, original_glb, original_nitro, name, original_model):
    current, current_binary = read_glb(current_glb)
    restored, timeline = restore_joint_timeline(original_glb, original_nitro, name, original_model)
    source, source_binary = read_glb(restored)
    current_indices = [index for index, clip in enumerate(current.get('animations', [])) if clip.get('name') == name]
    source_clips = [clip for clip in source.get('animations', []) if clip.get('name') == name]
    if len(current_indices) != 1 or len(source_clips) != 1:
        raise ValueError('Repair requires one existing and one restored clip with the same name')
    output = deepcopy(current)
    animation = deepcopy(source_clips[0])
    for channel in animation['channels']:
        source_node = channel['target']['node']
        current_node = source_node + 1
        source_name = source['nodes'][source_node].get('name')
        if not source_name or current_node >= len(current['nodes']) or current['nodes'][current_node].get('name') != source_name:
            raise ValueError('Restored joint node alignment differs from the current rigid geometry')
        channel['target']['node'] = current_node
    writer = GlbWriter(output, current_binary)
    for sampler in animation['samplers']:
        for key in ('input', 'output'):
            index = sampler[key]
            sampler[key] = writer.rows(accessor_rows(source, source_binary, index), source['accessors'][index]['type'])
    animation_index = current_indices[0]
    output['animations'][animation_index] = animation
    return writer.finish(), {'animationIndex': animation_index, 'clip': name, 'timelineRestoration': timeline,
                             'currentBinaryPrefixPreserved': True, 'otherAnimationClipsPreserved': True,
                             'rigidGeometryPreserved': True}


def restore_papeloa_native_sea_animation(document, binary, instance, source_surfaces, source_textures, sources):
    native = [surface for surface in source_surfaces if surface.material == 'sea_mizu1_1']
    if not native or any(surface.wraps != ['WRAP', 'WRAP'] or abs(surface.opacity - 16 / 31) > 1e-7
                         for surface in native):
        raise ValueError('Native Papeloa sea material proof is missing')
    triangles = [triangle for surface in native for triangle in surface.triangles]
    for vertex in [vertex for triangle in triangles for vertex in triangle]:
        if abs(vertex[1] + 5.6875) > 1e-7:
            raise ValueError('Native Papeloa sea plane changed')
        if any(abs(value - round(value)) > 1e-7 for value in
               (vertex[3] - vertex[0] / 4, vertex[4] - vertex[2] / 4 - 1)):
            raise ValueError('Native Papeloa sea UV reference changed')
    texture_names = {surface.texture for surface in native}
    if len(texture_names) != 1:
        raise ValueError('Native Papeloa sea texture proof is ambiguous')
    native_texture_sha = sha256(source_textures[next(iter(texture_names))]).hexdigest()
    if instance.get('scale', 1) != 1 or instance.get('rotationDegrees', 0) != 0:
        raise ValueError('Native Papeloa sea instance transform changed')
    nodes = document.get('nodes', [])
    if len(nodes) != 1 or nodes[0].get('mesh') != 0 or any(key in nodes[0] for key in ('matrix', 'translation', 'rotation', 'scale')):
        raise ValueError('Native Papeloa sea node transform is unsupported')

    def inside_original(vertex, triangle):
        a, b, c = triangle
        determinant = (b[2] - c[2]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[2] - c[2])
        if abs(determinant) < 1e-10:
            return False
        u = ((b[2] - c[2]) * (vertex[0] - c[0]) + (c[0] - b[0]) * (vertex[2] - c[2])) / determinant
        v = ((c[2] - a[2]) * (vertex[0] - c[0]) + (a[0] - c[0]) * (vertex[2] - c[2])) / determinant
        return min(u, v, 1 - u - v) >= -1e-5

    targets = []
    for index, material in enumerate(document['materials']):
        factor = material.get('pbrMetallicRoughness', {}).get('baseColorFactor', [1, 1, 1, 1])
        if material.get('alphaMode') != 'BLEND' or abs(factor[3] - 16 / 31) > 1e-7:
            continue
        binding = material['pbrMetallicRoughness']['baseColorTexture']['index']
        texture = document['textures'][binding]
        image = document['images'][texture['source']]
        view = document['bufferViews'][image['bufferView']]
        start = view.get('byteOffset', 0)
        if sha256(binary[start:start + view['byteLength']]).hexdigest() != native_texture_sha:
            continue
        sampler = document['samplers'][texture['sampler']]
        if sampler.get('wrapS') != 10497 or sampler.get('wrapT') != 10497:
            raise ValueError('Native Papeloa sea WRAP sampler changed')
        primitives = [primitive for mesh in document['meshes'] for primitive in mesh['primitives']
                      if primitive['material'] == index]
        vertices = []
        for primitive in primitives:
            positions = accessor_rows(document, binary, primitive['attributes']['POSITION'])
            uvs = accessor_rows(document, binary, primitive['attributes']['TEXCOORD_0'])
            for position, uv in zip(positions, uvs):
                source_position = [position[axis] + instance['position'][key] - shift
                                   for axis, (key, shift) in enumerate(zip(('x', 'y', 'z'), (24, 5.25, 33)))]
                vertices.append((source_position, uv))
        if not vertices or any(abs(position[1] + 5.6875) > 1e-6 for position, _ in vertices):
            continue
        for position, uv in vertices:
            if not any(inside_original(position, triangle) for triangle in triangles):
                raise ValueError('Native sea target differs from the original source geometry')
            if any(abs(value - round(value)) > 1e-5 for value in
                   (uv[0] - position[0] / 4, uv[1] - position[2] / 4 - 1)):
                raise ValueError('Native sea target differs from the original source geometry UV')
        targets.append(index)
    if not targets:
        return None, {'materialIndices': [], 'addedTracks': 0}
    metadata = document.get('extras', {}).get('aveluneAnimationSource', {})
    if metadata.get('romSha256') != sources.inventory['source']['rom_sha256'] or metadata.get('frameRate') != 60:
        raise ValueError('Native Papeloa sea ROM or conversion timeline changed')
    candidates = [track for track in sources.by_material['sea_mizu1_1'] if track['clip'] == 'out58_ita'
                  and track['source']['sha256'] == '2c9a5c778f2f3ee0f3fa7b4c82e5586774e8f08e5769d5ed954b5b1b21071982']
    if len(candidates) != 1 or candidates[0]['frames'] != 240 or len(candidates[0]['samples']) != 240:
        raise ValueError('Pinned native Papeloa sea animation is missing')
    if sources.modes({'map24_04', 'map24_05'}, 'sea_mizu1_1') != {0}:
        raise ValueError('Native Papeloa sea matrix mode proof changed')
    clips = document['extras']['aveluneMaterialAnimations']['clips']
    if not clips or clips[0]['durationSeconds'] != 4:
        raise ValueError('Native sea requires the existing four-second ambient clip')
    source = candidates[0]
    output = deepcopy(document)
    clip = output['extras']['aveluneMaterialAnimations']['clips'][0]
    added = 0
    for index in targets:
        width, height = texture_size(document, binary, index)
        transforms = [nitro_affine(sample, 0, width, height) for sample in source['samples']]
        track = {'materialIndex': index, 'durationSeconds': 4, 'times': [frame / 60 for frame in range(241)],
                 'transforms': transforms + [transforms[0]], 'interpolation': 'STEP'}
        existing = [entry for entry in clip['tracks'] if entry['materialIndex'] == index]
        if existing:
            if existing != [track]:
                raise ValueError('Existing native sea track differs from the verified original')
        else:
            clip['tracks'].append(track)
            added += 1
        output['materials'][index].setdefault('extras', {})['aveluneNitroMaterial'] = 'sea_mizu1_1'
    proof = {'material': 'sea_mizu1_1', 'materialIndices': targets, 'modelNames': ['map24_04', 'map24_05'],
             'matrixMode': 0, 'matrixModeEvidence': 'exact_source_models', 'uvCoordinateConvention': 'nitro_normalized_uv',
             'sourceUvConversion': 'nitro_to_collada_v_flip_then_glb_v_flip', 'matrixConversion': 'original_sdk_normalized_uv',
             'animation': 'out58_ita', 'animationSha256': source['source']['sha256'], 'origins': source['source']['origins'],
             'association': 'authenticated_native_geometry_alpha_texture_uv', 'nativeAlpha': 16 / 31,
             'sourcePlaneHeight': -5.6875, 'worldPlaneHeight': -.4375, 'sourceWorldTranslation': [24, 5.25, 33]}
    materials = output['extras']['aveluneAnimationSource']['materials']
    if proof not in materials:
        materials.append(proof)
    return output, {'materialIndices': targets, 'addedTracks': added, 'sourceProof': proof,
                    'binaryPreserved': True, 'otherMaterialTracksPreserved': True, 'clipIndicesPreserved': True}


def fountain_speed_application_entry(model_id, source_path, source_bytes, instances, inventory):
    document, _ = read_glb(source_bytes)
    metadata = document.get('extras', {}).get('aveluneAnimationSource', {})
    allowed = {'fountain_01', 'c01fountain_01', 'c03_fountain_01'}
    proofs = [proof for proof in metadata.get('materials', [])
              if 'matrixMode' in proof and proof.get('animation') in allowed]
    if not proofs:
        return None
    if metadata.get('romSha256') != inventory['source']['rom_sha256']:
        raise ValueError('Fountain ROM provenance does not match the pinned inventory')
    native = {(record['name'], record['sha256']): record for record in inventory['animations']
              if record['type'] == 'SRT0' and record['name'] in allowed}
    animations = {}
    for proof in proofs:
        key = proof['animation'], proof['animationSha256']
        record = native.get(key)
        if record is None or proof['material'] not in {track['material'] for track in record['tracks']}:
            raise ValueError('Model metadata does not match an authenticated native fountain source')
        animations[key] = {'stem': key[0], 'sha256': key[1], 'durationFrames': record['frames']}
    if not instances or any(instance.get('animationSpeed', 1) not in (1, .5) for instance in instances):
        return None
    indices = {instance.get('animationIndex') for instance in instances}
    if len(indices) != 1:
        return None
    index = next(iter(indices))
    node_clips = document.get('animations', [])
    material_clips = document.get('extras', {}).get('aveluneMaterialAnimations', {}).get('clips', [])
    if not isinstance(index, int) or not len(node_clips) <= index < len(node_clips) + len(material_clips):
        return None
    active_materials = {document['materials'][track['materialIndex']].get('extras', {}).get('aveluneNitroMaterial')
                        for track in material_clips[index - len(node_clips)]['tracks']}
    if not active_materials.intersection(proof['material'] for proof in proofs):
        return None
    digest = sha256(source_bytes).hexdigest()
    return {'modelId': model_id, 'sourcePath': str(source_path), 'sourceSha256Before': digest, 'sha256After': digest,
            'byteLength': len(source_bytes), 'recommendedAnimationIndex': index, 'recommendedAnimationSpeed': .5,
            'clips': [clip.get('name') for clip in node_clips + material_clips],
            'provenance': {'nativeAnimations': list(animations.values()), 'nativeResourcesDeclareFps': False,
                           'originalGameCadenceProven': False, 'conversionFrameRateAssumption': metadata.get('frameRate'),
                           'speedPolicy': 'explicit_user_requested_fountain_half_speed',
                           'currentGlbByteForBytePreserved': True, 'currentPlaybackIndexPreserved': True}}


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2, allow_nan=False) + '\n')


def joint_candidates(project, nitro_root, output):
    inventory = json.loads((nitro_root / 'animation-inventory.json').read_text())
    by_name = defaultdict(list)
    for animation in inventory['animations']:
        if animation['type'] == 'JNT0':
            by_name[animation['name']].append(animation)
    result = []
    root = project / '.pokemap/authoring/unys-cities'
    for folder in sorted(root.iterdir()):
        path = folder / 'assets_manifest.json'
        if not path.is_file():
            continue
        manifest = json.loads(path.read_text())
        for model in manifest.get('models', []):
            names = model_names([model.get('sourceGroup', '')])
            matches = [animation for name in names for animation in by_name[name]]
            if matches:
                result.append({'city': folder.name, 'modelId': model['modelId'],
                               'sourceGroup': model['sourceGroup'], 'sourceAnchorCells': model['sourceAnchorCells'],
                               'sourceGlb': str(project / 'assets/models3d' / (model['modelId'] + '.glb')),
                               'animations': [{key: animation[key] for key in ('name', 'frames', 'sha256', 'extracted_files', 'origins')}
                                              for animation in matches]})
    write_json(output / 'joint-candidates.json', {'source': inventory['source'], 'models': result})
    return result


def pattern_candidates(contexts, inventory, output):
    result = []
    for context in contexts:
        for animation in inventory['animations']:
            if animation['type'] != 'PAT0':
                continue
            matches = [track for track in animation['tracks'] if track['material'] in context['materials']
                       and animation['name'] in model_names(context['materials'][track['material']]['groups'])
                       and len({(key['texture'], key['palette']) for key in track['keys']}) > 1]
            if matches:
                result.append({'city': context['city'], 'animation': animation['name'],
                               'frames': animation['frames'], 'sha256': animation['sha256'],
                               'extracted_files': animation['extracted_files'], 'origins': animation['origins'],
                               'tracks': matches})
    write_json(output / 'pattern-candidates.json', {'source': inventory['source'], 'candidates': result})
    return result


def visible_pixels_equal(a, b):
    with Image.open(BytesIO(a)) as left, Image.open(BytesIO(b)) as right:
        if left.size != right.size:
            return False
        a, b = left.convert('RGBA').tobytes(), right.convert('RGBA').tobytes()
        return all(a[index:index + 4] == b[index:index + 4] or a[index + 3] == b[index + 3] == 0
                   for index in range(0, len(a), 4))


def combine_pattern_transform_tracks(transform_track, pattern_track, fps):
    periods = [round(track['durationSeconds'] * fps) for track in (transform_track, pattern_track)]
    if any(period <= 0 or abs(period / fps - track['durationSeconds']) > 1e-7
           for period, track in zip(periods, (transform_track, pattern_track))):
        raise ValueError('Combined source periods must contain an integer number of Nitro frames')
    frames = math.lcm(*periods)
    if frames > 4096:
        raise ValueError('Combined original periods exceed the 4096-frame source limit')
    transforms, textures = [], []
    for frame in range(frames):
        ti = max(0, bisect_right(transform_track['times'], frame % periods[0] / fps) - 1)
        pi = max(0, bisect_right(pattern_track['times'], frame % periods[1] / fps) - 1)
        transforms.append(transform_track['transforms'][ti])
        textures.append(pattern_track['textureIndices'][pi])
    return {'materialIndex': transform_track['materialIndex'], 'durationSeconds': frames / fps,
            'times': [frame / fps for frame in range(frames)] + [frames / fps],
            'transforms': transforms + [transforms[0]], 'textureIndices': textures + [textures[0]],
            'interpolation': 'STEP'}


def add_pattern_animations(document, binary, recipe, context, patterns, nitro_root, apicula, output, fps):
    applicable = [candidate for candidate in patterns if candidate['city'] == context['city']]
    if not applicable:
        return None, binary, [], []
    result = deepcopy(document)
    data = bytearray(binary)
    evidence, refused = [], []
    clips = result.setdefault('extras', {}).get('aveluneMaterialAnimations', {}).get('clips', [])
    tracks = deepcopy(clips[0]['tracks']) if clips else []
    used = {primitive['material'] for mesh in result['meshes'] for primitive in mesh['primitives']}
    for index in sorted(used):
        material = result['materials'][index]
        identity = material_identity(material, recipe, context)
        matches = [(candidate, track) for candidate in applicable for track in candidate['tracks']
                   if track['material'] == identity]
        if not matches:
            continue
        if len(matches) != 1:
            refused.append({'materialIndex': index, 'reason': 'ambiguous_pattern_track'})
            continue
        candidate, track = matches[0]
        try:
            keys = track['keys']
            if not keys or keys[0]['frame'] != 0:
                raise ValueError('Original pattern has no initial key')
            decoded = decode_pattern_frames(nitro_root / 'nitro-original', apicula, output / 'pattern-frames', candidate, track)
            base_index = material['pbrMetallicRoughness']['baseColorTexture']['index']
            image = result['images'][result['textures'][base_index]['source']]
            view = result['bufferViews'][image['bufferView']]
            start = view.get('byteOffset', 0)
            original_png = bytes(data[start:start + view['byteLength']])
            if not any(visible_pixels_equal(original_png, frame['data']) for frame in decoded.values()):
                raise ValueError('Original animation palette does not match the current asset')
            if len({frame['sha256'] for frame in decoded.values()}) < 2:
                continue
            bindings = {}
            for pair, frame in decoded.items():
                if visible_pixels_equal(original_png, frame['data']):
                    bindings[pair] = base_index
                    continue
                png = frame['data']
                data.extend(b'\0' * (-len(data) % 4))
                result['bufferViews'].append({'buffer': 0, 'byteOffset': len(data), 'byteLength': len(png)})
                data.extend(png)
                result['images'].append({'bufferView': len(result['bufferViews']) - 1, 'mimeType': 'image/png'})
                binding = {'source': len(result['images']) - 1}
                if 'sampler' in result['textures'][base_index]:
                    binding['sampler'] = result['textures'][base_index]['sampler']
                result['textures'].append(binding)
                bindings[pair] = len(result['textures']) - 1
            duration = candidate['frames'] / fps
            texture_indices = [bindings[key['texture'], key['palette']] for key in keys]
            pattern = {'materialIndex': index, 'durationSeconds': duration,
                           'times': [key['frame'] / fps for key in keys] + [duration],
                           'transforms': [[1, 0, 0, 1, 0, 0]] * (len(keys) + 1),
                           'interpolation': 'STEP', 'textureIndices': texture_indices + [texture_indices[0]]}
            previous = next((entry for entry in tracks if entry['materialIndex'] == index), None)
            if previous is not None:
                pattern = combine_pattern_transform_tracks(previous, pattern, fps)
                tracks.remove(previous)
            tracks.append(pattern)
            material.setdefault('extras', {})['aveluneNitroMaterial'] = identity
            evidence.append({'material': identity, 'animation': candidate['animation'], 'frames': candidate['frames'],
                             'animationSha256': candidate['sha256'], 'origins': candidate['origins'],
                             'patternTextures': [{key: frame[key] for key in ('texture', 'palette', 'sha256', 'sourceModelSha256', 'bindingChanges', 'equivalentTexturePacks')}
                                                 for frame in decoded.values()]})
        except (ValueError, KeyError, StopIteration) as error:
            refused.append({'materialIndex': index, 'reason': str(error)})
    if not evidence:
        return None, binary, evidence, refused
    clip = {'name': 'Ambiance originale NB2', 'durationSeconds': max(track['durationSeconds'] for track in tracks), 'tracks': tracks}
    result['extras']['aveluneMaterialAnimations'] = {'schemaVersion': 1, 'clips': [clip]}
    result['buffers'][0]['byteLength'] = len(data)
    return result, bytes(data), evidence, refused


def merge_joint_animations(report, source_root, nitro_root, output, joint_index, fps):
    if fps != 60:
        raise ValueError('The pinned native joint converter requires the 60 Hz conversion timeline')
    candidates = json.loads((output / 'joint-candidates.json').read_text())
    joint_data = json.loads(joint_index.read_text())
    if joint_data['source'].get('rom_sha256') != report['source']['rom_sha256'] or joint_data.get('sourceOnly'):
        raise ValueError('Joint staging must be derived from the same verified ROM')
    records = deepcopy(joint_data['converted'])
    wheel = next((record for record in candidates['models'] if 'fwheel' in record['sourceGroup']), None)
    if wheel is not None:
        native = wheel['animations'][0]
        name = native['name']
        model, model_sha = unique_source(nitro_root / 'nitro-original', name, '.nsbmd')
        animation, animation_sha = unique_source(nitro_root / 'nitro-original', name, '.nsbca', native['sha256'])
        apicula = nitro_root / ('apicula-' + report['source']['tool_commit']) / 'target/release/apicula'
        proof = stage_original(apicula, model, animation, output, name)
        transform, map_source = source_map(wheel, source_root / 'archives/maps')
        records.append({'modelId': wheel['modelId'], 'city': wheel['city'], 'clip': name,
                        'currentGlb': wheel['sourceGlb'], 'currentGlbSha256': sha256(Path(wheel['sourceGlb']).read_bytes()).hexdigest(),
                        'originalModel': str(model), 'originalModelSha256': model_sha,
                        'originalAnimation': str(animation), 'originalAnimationSha256': animation_sha,
                        'originalAnimatedGlb': str(proof), 'originalAnimatedGlbSha256': sha256(proof.read_bytes()).hexdigest(),
                        'sourceToCurrent': transform, 'mapSource': map_source, 'verifiedStaticAttachments': []})
    rows = {row['modelId']: row for row in report['models']}
    if len({record['modelId'] for record in records}) != len(records):
        raise ValueError('Duplicate joint staging target')
    for record in records:
        row = rows[record['modelId']]
        original = Path(record['currentGlb']).read_bytes()
        proof = Path(record['originalAnimatedGlb']).read_bytes()
        source = Path(record['originalAnimation']).read_bytes()
        model_bytes = Path(record['originalModel']).read_bytes()
        checks = [(original, record['currentGlbSha256']), (proof, record['originalAnimatedGlbSha256']),
                  (source, record['originalAnimationSha256']), (model_bytes, record['originalModelSha256']),
                  (original, row['sourceSha256'])]
        if any(sha256(data).hexdigest() != expected for data, expected in checks):
            raise ValueError('Joint source or current project digest changed')
        restored, timeline = restore_joint_timeline(proof, source, record['clip'], model_bytes)
        attachments = []
        for static in record['verifiedStaticAttachments']:
            data = Path(static['originalGlb']).read_bytes()
            if sha256(data).hexdigest() != static['originalGlbSha256']:
                raise ValueError('Verified static attachment changed')
            attachments.append((data, static['sourceToCurrent']))
        base = Path(row['path']).read_bytes() if row['status'] == 'animated_material' else original
        encoded, evidence = enrich_rigid_animation(base, restored, source_to_current=record['sourceToCurrent'], static_sources=attachments)
        document, binary = read_glb(encoded)
        extras = document.setdefault('extras', {})
        material_clips = extras.get('aveluneMaterialAnimations', {}).get('clips', [])
        recommendation = configure_joint_playback(document, record['clip'])
        provenance = {key: value for key, value in record.items() if key not in ('currentGlb', 'output', 'outputSha256', 'evidence')}
        provenance.update(timelineRestoration=timeline, rigidGeometry=evidence,
                          playbackPolicy='verified_ambient_rotor_or_oscillation' if record['clip'] in AMBIENT_JOINT_CLIPS else 'gameplay_trigger_required')
        extras.setdefault('aveluneAnimationSource', {
            'romSha256': report['source']['rom_sha256'], 'gameCode': report['source']['game_code'],
            'frameRate': fps, 'frameRateEvidence': report['frameRateEvidence'], 'originalGlbSha256': row['sourceSha256'],
        })['joints'] = provenance
        encoded = glb_bytes(document, binary)
        destination = output / 'models' / (record['modelId'] + '.glb')
        destination.write_bytes(encoded)
        row.update(status='animated_joint_and_material' if material_clips else 'animated_joint',
                   path=str(destination), sha256=sha256(encoded).hexdigest(), byteLength=len(encoded),
                   jointProvenance=provenance, recommendedAnimationIndex=recommendation,
                   binaryPreserved=False, originalBinaryPrefixPreserved=binary[:len(read_glb(original)[1])] == read_glb(original)[1])
    report['jointRefusals'] = joint_data['refused']
    report['summary'] = dict(Counter(row['status'] for row in report['models']))


def audit_staged_coverage(project, source_root, nitro_root, catalog, report):
    contexts = source_contexts(project, source_root, catalog)
    sources = NitroSources(nitro_root, {name for context in contexts for name in context['materials']})
    models = {model['id']: model for model in json.loads((project / 'project.json').read_text())['models3d']}
    contexts_by_model = {model: (context, recipe) for context in contexts for model, recipe in context['models'].items()}
    records = []
    for row in report['models']:
        if row['status'] != 'static_source':
            continue
        context, recipe = contexts_by_model[row['modelId']]
        document, _ = read_glb((project / models[row['modelId']]['relativePath']).read_bytes())
        used = {primitive['material'] for mesh in document['meshes'] for primitive in mesh['primitives']}
        materials, kinds = [], set()
        for index in sorted(used):
            names = material_candidates(document['materials'][index], recipe, context)
            tracks = [track for name in names for track in sources.by_material[name]]
            variable = [track for track in tracks if len({tuple(sample) for sample in track['samples']}) > 1]
            kind = 'unassociated_variable_sources' if variable else 'constant_source_tracks' if tracks else 'no_source_track'
            kinds.add(kind)
            materials.append({'materialIndex': index, 'sourceMaterialCandidates': names, 'sourceIdentityExact': len(names) == 1,
                              'kind': kind, 'candidateClips': sorted({track['clip'] for track in tracks})})
        classification = ('unassociated_variable_sources' if 'unassociated_variable_sources' in kinds
                          else 'constant_source_tracks' if 'constant_source_tracks' in kinds else 'no_source_track')
        records.append({'modelId': row['modelId'], 'city': row['city'], 'placedInstances': row['placedInstances'],
                        'classification': classification, 'materials': materials})
    return {'schemaVersion': 1, 'source': report['source'], 'projectSha256': report['projectSha256'],
            'coverage': report['summary'], 'staticSourceClassifications': dict(Counter(row['classification'] for row in records)),
            'staticModels': records,
            'definition': 'Static means no variable ambient track was proven for this model; it does not assert absence of gameplay or unrelated source clips',
            'limits': ['Global or cutscene resources sharing material names are not sufficient evidence of an object animation',
                       'Door clips require exact component provenance and gameplay-triggered playback',
                       'The 60 Hz conversion timeline is not a measurement of original game scheduling']}


def canonical_door_index(data):
    result = deepcopy(data)
    for entry in result['entries']:
        entry['sourceSha256Before'] = entry['inputSha256']
    return result


def merge_staged_door_index(output, door_index):
    applications = json.loads((output / 'animation_application.json').read_text())
    report = json.loads((output / 'animation-assets.json').read_text())
    doors = canonical_door_index(json.loads(door_index.read_text()))
    if doors['source']['rom_sha256'] != applications['source']['rom_sha256']:
        raise ValueError('Door clips must come from the same verified ROM')
    entries = {entry['modelId']: entry for entry in applications['entries']}
    rows = {row['modelId']: row for row in report['models']}
    updates = []
    for patch in doors['entries']:
        current = entries[patch['modelId']]
        destination = Path(current['sourcePath'])
        if not destination.resolve().is_relative_to(output.resolve()):
            raise ValueError('Combined animation destination is outside its staging root')
        source = Path(patch['sourcePath']).read_bytes()
        if sha256(source).hexdigest() != patch['sha256After']:
            raise ValueError('Door source digest changed')
        if current['sha256After'] != patch['sourceSha256Before'] or sha256(destination.read_bytes()).hexdigest() != current['sha256After']:
            raise ValueError('Door augmentation does not match the frozen ambient asset')
        document, _ = read_glb(source)
        if [clip['name'] for clip in document['animations']] != patch['clips']:
            raise ValueError('Door clip indices changed')
        if patch['recommendedAnimationIndex'] != current['recommendedAnimationIndex']:
            raise ValueError('Door augmentation must preserve the ambient default')
        updates.append((patch, current, rows[patch['modelId']], destination, source))
    for patch, current, row, destination, source in updates:
        destination.write_bytes(source)
        current.update(sha256After=patch['sha256After'], clips=patch['clips'])
        current.setdefault('provenance', {})['eventClips'] = patch['provenance']
        row.update(sha256=patch['sha256After'], byteLength=len(source), eventProvenance=patch['provenance'])
        for asset in report['stagedAssets']:
            if asset['modelId'] == patch['modelId']:
                asset.update(sha256=patch['sha256After'], byteLength=len(source))
    applications['eventClipRefusals'] = doors['refused']
    report['eventClipRefusals'] = doors['refused']
    write_json(output / 'animation-assets.json', report)
    write_json(output / 'animation_application.json', applications)
    return applications


def run(project, source_root, nitro_root, output, catalog, fps, only, joint_index=None):
    if not math.isfinite(fps) or fps <= 0:
        raise ValueError('Playback frame rate must be positive and finite')
    protected = [project.resolve(), source_root.resolve(), nitro_root.resolve()]
    if any(output.resolve().is_relative_to(root) or root.is_relative_to(output.resolve()) for root in protected):
        raise ValueError('Staging must be separate from the source project and read-only source roots')
    project_document = json.loads((project / 'project.json').read_text())
    models = {model['id']: model for model in project_document['models3d']}
    joint_candidates(project, nitro_root, output)
    contexts = source_contexts(project, source_root, catalog)
    all_materials = {material for context in contexts for material in context['materials']}
    sources = NitroSources(nitro_root, all_materials)
    patterns = pattern_candidates(contexts, sources.inventory, output)
    results, staged, fingerprints = [], [], {}
    placements = defaultdict(list)
    for entry in project_document['maps']:
        path = project / entry['relativePath']
        data = path.read_bytes()
        fingerprints[entry['id']] = sha256(data).hexdigest()
        document = json.loads(data)
        for instance in document.get('spatialScene', {}).get('instances', []):
            placements[instance['modelId']].append({'mapId': entry['id'], 'instanceId': instance['id'],
                                                    'animationIndex': instance.get('animationIndex'),
                                                    'animationSpeed': instance.get('animationSpeed', 1)})
    for context in contexts:
        for model_id, recipe in context['models'].items():
            if model_id not in models or only and model_id not in only:
                continue
            model = models[model_id]
            path = project / model['relativePath']
            data = path.read_bytes()
            document, binary = read_glb(data)
            original_binary = binary
            try:
                document, binary, splitting = split_animated_materials(document, binary, recipe, context, sources, patterns)
            except ValueError as error:
                results.append({'modelId': model_id, 'city': context['city'], 'placedInstances': len(placements[model_id]),
                                'sourceSha256': sha256(data).hexdigest(), 'materials': [], 'unsupported': [{'reason': str(error)}],
                                'status': 'unsupported'})
                continue
            animated, evidence, unsupported = animated_material_document(document, binary, recipe, context, sources, fps)
            apicula = nitro_root / ('apicula-' + sources.inventory['source']['tool_commit']) / 'target/release/apicula'
            patterned, pattern_binary, pattern_evidence, pattern_refused = add_pattern_animations(
                animated or document, binary, recipe, context, patterns, nitro_root, apicula, output, fps)
            if patterned:
                animated, binary = patterned, pattern_binary
                evidence += pattern_evidence
            unsupported += pattern_refused
            row = {'modelId': model_id, 'city': context['city'], 'placedInstances': len(placements[model_id]),
                   'sourceSha256': sha256(data).hexdigest(), 'materials': evidence, 'unsupported': unsupported,
                   'status': 'animated_material' if animated else 'unsupported' if unsupported else 'static_source',
                   'materialSplitting': splitting}
            if animated:
                animated['extras']['aveluneAnimationSource'] = {
                    'romSha256': sources.inventory['source']['rom_sha256'],
                    'gameCode': sources.inventory['source']['game_code'], 'frameRate': fps,
                    'frameRateEvidence': 'Assumed 60 Hz Nitro timeline; original game scheduling not yet measured',
                    'originalGlbSha256': row['sourceSha256'], 'materials': evidence,
                }
                destination = output / 'models' / (model_id + '.glb')
                encoded = glb_bytes(animated, binary)
                destination.parent.mkdir(parents=True, exist_ok=True)
                destination.write_bytes(encoded)
                row.update(path=str(destination), sha256=sha256(encoded).hexdigest(), byteLength=len(encoded),
                           recommendedAnimationIndex=len(animated.get('animations', [])),
                           binaryPreserved=read_glb(encoded)[1] == original_binary,
                           originalBinaryPrefixPreserved=read_glb(encoded)[1][:len(original_binary)] == original_binary)
                staged.append({key: row[key] for key in ('modelId', 'path', 'sha256', 'byteLength', 'sourceSha256',
                                                       'recommendedAnimationIndex', 'binaryPreserved')})
            results.append(row)
    report = {'schemaVersion': 1, 'source': sources.inventory['source'], 'frameRate': fps,
              'frameRateEvidence': 'Assumed 60 Hz Nitro timeline; original game scheduling not yet measured',
              'projectSha256': sha256((project / 'project.json').read_bytes()).hexdigest(),
              'mapFingerprints': fingerprints, 'models': results, 'stagedAssets': staged,
              'summary': dict(Counter(row['status'] for row in results)),
              'patternCandidateCount': len(patterns),
              'limits': ['No project mutation performed', 'Original game playback speed and visuals require validation',
                         'Joint and pattern animations are audited separately from these material tracks']}
    if joint_index is not None:
        merge_joint_animations(report, source_root, nitro_root, output, joint_index, fps)
    staged = [{key: row[key] for key in ('modelId', 'path', 'sha256', 'byteLength', 'sourceSha256',
                                       'recommendedAnimationIndex', 'binaryPreserved')}
              for row in results if row['status'].startswith('animated_')]
    report['stagedAssets'] = staged
    report['limits'] = ['No project mutation performed', 'Original game playback speed and visuals require validation',
                        'Door clips require gameplay triggers and are not enabled as ambient loops']
    applications = [{'modelId': row['modelId'], 'sourcePath': row['path'],
                     'sourceSha256Before': row['sourceSha256'], 'sha256After': row['sha256'],
                     'recommendedAnimationIndex': row['recommendedAnimationIndex'],
                     'clips': [clip['name'] for clip in read_glb(Path(row['path']).read_bytes())[0].get('animations', [])]
                              + (['Ambiance originale NB2'] if row['materials'] else []),
                     'provenance': {'materials': row['materials'], 'joints': row.get('jointProvenance')}}
                    for row in results if row['status'].startswith('animated_')]
    recipes = {model_id: recipe for context in contexts for model_id, recipe in context['models'].items()}
    for entry in applications:
        instances = placements[entry['modelId']]
        if not instances or any(instance['animationSpeed'] not in (1, .5) for instance in instances):
            continue
        encoded = Path(entry['sourcePath']).read_bytes()
        document, _ = read_glb(encoded)
        node_count = len(document.get('animations', []))
        material_count = len(document.get('extras', {}).get('aveluneMaterialAnimations', {}).get('clips', []))
        index = entry['recommendedAnimationIndex']
        if not isinstance(index, int) or not node_count <= index < node_count + material_count:
            continue
        if recipes[entry['modelId']].get('kind') == 'water':
            provenance = {'speedPolicy': 'explicit_user_requested_water_half_speed',
                          'nativeResourcesDeclareFps': False, 'originalGameCadenceProven': False,
                          'conversionFrameRateAssumption': fps}
        else:
            proposed_instances = [{**instance, 'animationIndex': index} for instance in instances]
            fountain = fountain_speed_application_entry(entry['modelId'], Path(entry['sourcePath']), encoded,
                                                       proposed_instances, sources.inventory)
            if fountain is None:
                continue
            provenance = {key: value for key, value in fountain['provenance'].items()
                          if key not in ('currentGlbByteForBytePreserved', 'currentPlaybackIndexPreserved')}
        entry['recommendedAnimationSpeed'] = .5
        entry['provenance'].update(provenance)
        row = next(row for row in results if row['modelId'] == entry['modelId'])
        row.update(recommendedAnimationSpeed=.5, playbackSpeedProvenance=provenance)
    write_json(output / 'animation-assets.json', report)
    write_json(output / 'animation_application.json', {'schemaVersion': 1, 'entries': applications,
                                                     'coverage': report['summary'], 'source': report['source'],
                                                     'mapFingerprints': fingerprints})
    print(json.dumps({'output': str(output / 'animation-assets.json'), 'summary': report['summary'],
                      'stagedModels': len(staged), 'placedInstances': sum(row['placedInstances'] for row in results),
                      'unchangedBinary': all(asset['binaryPreserved'] for asset in staged)}, ensure_ascii=False))
    return report


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--project', type=Path, required=True)
    parser.add_argument('--source-root', type=Path, required=True)
    parser.add_argument('--nitro-root', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--catalog', type=Path, default=Path(__file__).with_name('bw2_city_animation_catalog.json'))
    parser.add_argument('--fps', type=float, default=60)
    parser.add_argument('--only')
    parser.add_argument('--joint-audit-only', action='store_true')
    parser.add_argument('--joint-index', type=Path)
    parser.add_argument('--door-index', type=Path)
    args = parser.parse_args()
    if args.door_index is not None:
        protected = [args.project.resolve(), args.source_root.resolve(), args.nitro_root.resolve()]
        if any(args.output.resolve().is_relative_to(root) or root.is_relative_to(args.output.resolve()) for root in protected):
            raise ValueError('Staging must be separate from read-only source roots')
        applications = merge_staged_door_index(args.output, args.door_index)
        print(json.dumps({'entries': len(applications['entries']), 'eventClipRefusals': applications['eventClipRefusals']}))
        return
    if args.joint_audit_only:
        records = joint_candidates(args.project, args.nitro_root, args.output)
        print(json.dumps({'jointCandidateModels': len(records), 'output': str(args.output / 'joint-candidates.json')}))
        return
    run(args.project, args.source_root, args.nitro_root, args.output,
        json.loads(args.catalog.read_text()), args.fps, set(args.only.split(',')) if args.only else None, args.joint_index)


if __name__ == '__main__':
    main()

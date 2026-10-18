from collections import defaultdict
from copy import deepcopy
from hashlib import sha256
from io import BytesIO
import json
import math
from pathlib import Path
import re
import struct
import sys

from PIL import Image

sys.dont_write_bytecode = True
REPOSITORY = Path(__file__).resolve().parents[2]
sys.path[:0] = [str(REPOSITORY / 'tools/scripts'), str(REPOSITORY / 'tools/source_geometry')]
from nitro_materials import nitro_affine, read_model_materials, read_srt


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


def source_material_context(source_root, record, *, policy):
    from city_geometry import source_scene
    surfaces, _, provenance = source_scene(source_root, record, policy=policy)
    materials = defaultdict(lambda: {'textures': set(), 'groups': set()})
    for surface in surfaces:
        materials[surface.material]['textures'].add(surface.texture)
        materials[surface.material]['groups'].add(surface.group)
    return {name: {key: sorted(values) for key, values in info.items()}
            for name, info in materials.items()}, provenance


def source_bytes(root, relative_path, expected_hash):
    if not isinstance(relative_path, str) or not relative_path or '\\' in relative_path:
        raise ValueError('Invalid source resource path')
    parts = relative_path.split('/')
    if any(part in ('', '.', '..') for part in parts) or Path(relative_path).is_absolute():
        raise ValueError('Source resource must be confined')
    if not isinstance(expected_hash, str) or re.fullmatch('[0-9a-f]{64}', expected_hash) is None:
        raise ValueError('Source resource requires a SHA-256 digest')
    root = Path(root).resolve(strict=True)
    path = root
    for part in parts:
        path = path / part
        if path.is_symlink():
            raise ValueError('Source resource cannot be a symbolic link')
    if not path.is_file():
        raise ValueError('Source resource must be a regular file')
    data = path.read_bytes()
    if sha256(data).hexdigest() != expected_hash:
        raise ValueError('Source resource digest changed')
    return data


class NitroSources:
    def __init__(self, root, material_names, *, model_sources, inventory_bytes=None):
        self.root = Path(root)
        inventory_path = self.root / 'animation-inventory.json'
        if inventory_path.is_symlink():
            raise ValueError('Animation inventory cannot be a symbolic link')
        self.inventory = json.loads(inventory_path.read_bytes() if inventory_bytes is None else inventory_bytes)
        self.by_material = defaultdict(list)
        self.models = []
        if not isinstance(model_sources, list) or len(model_sources) > 4096:
            raise ValueError('Explicit source model witnesses are required')
        for record in model_sources:
            if not isinstance(record, dict) or set(record) != {'relativePath', 'sha256'}:
                raise ValueError('Invalid source model witness')
            self.models.extend(read_model_materials(source_bytes(self.root, record['relativePath'], record['sha256'])))
        for record in self.inventory['animations']:
            if record['type'] != 'SRT0' or not any(track['material'] in material_names for track in record['tracks']):
                continue
            paths = record.get('extracted_files')
            if not isinstance(paths, list) or len(paths) != 1 or not isinstance(paths[0], str) or Path(paths[0]).name != paths[0]:
                raise ValueError('Animation requires one explicit extracted source file')
            clips = read_srt(source_bytes(self.root, 'nitro-original/' + paths[0], record['sha256']))
            matches = [clip for clip in clips if clip['name'] == record['name']]
            if len(matches) != 1:
                raise ValueError('Animation clip is missing or ambiguous')
            clip = matches[0]
            for track in clip['tracks']:
                if track['material'] in material_names:
                    self.by_material[track['material']].append({**track, 'clip': clip['name'],
                                                               'frames': clip['frames'], 'source': record})

    def modes(self, names, material):
        result = set()
        for name in names:
            matches = [model for model in self.models if model['name'] == name and material in model['materials']]
            if not matches:
                return set()
            result.update(model['textureMatrixMode'] for model in matches)
        return result


def require_bindings(value):
    if not isinstance(value, dict) or not value or len(value) > 1024:
        raise ValueError('Explicit animation bindings are required')
    for material, binding in value.items():
        if not isinstance(material, str) or not material or not isinstance(binding, dict) or set(binding) != {
                'sourceClip', 'sourceModelNames', 'matrixModeEvidence'}:
            raise ValueError('Invalid animation binding')
        if not isinstance(binding['sourceClip'], str) or not binding['sourceClip'] or binding['matrixModeEvidence'] != 'exact_source_model':
            raise ValueError('Animation binding requires an exact source clip and model witness')
        names = binding['sourceModelNames']
        if not isinstance(names, list) or not names or len(names) > 256 or any(
                not isinstance(name, str) or not name for name in names) or len(set(names)) != len(names):
            raise ValueError('Animation binding requires unique source model names')
    return value


def animated_material_document(document, binary, recipe, context, sources, fps, *, bindings, clip_name):
    require_bindings(bindings)
    if type(fps) not in (int, float) or not math.isfinite(fps) or fps <= 0 or fps > 1000:
        raise ValueError('Animation cadence must be explicit and positive')
    if not isinstance(clip_name, str) or not clip_name.strip():
        raise ValueError('Animation label is required')
    output = deepcopy(document)
    tracks, evidence, unsupported = [], [], []
    used_materials = {primitive['material'] for mesh in document.get('meshes', []) for primitive in mesh['primitives']}
    for index, material in enumerate(document.get('materials', [])):
        if used_materials and index not in used_materials:
            continue
        identity = material_identity(material, recipe, context)
        if identity is None or identity not in bindings:
            if any(sources.by_material[name] for name in material_candidates(material, recipe, context)):
                unsupported.append({'materialIndex': index, 'reason': 'missing_or_ambiguous_source_material_binding'})
            continue
        binding = bindings[identity]
        candidates = [track for track in sources.by_material[identity] if track['clip'] == binding['sourceClip']]
        if len(candidates) != 1:
            unsupported.append({'materialIndex': index, 'sourceMaterial': identity,
                                'reason': 'missing_or_ambiguous_declared_source_clip'})
            continue
        source = candidates[0]
        frames = source['frames']
        if type(frames) is not int or frames <= 0 or frames > 65535 or len(source['samples']) != frames:
            raise ValueError('Source animation timeline is invalid')
        names = set(binding['sourceModelNames'])
        modes = sources.modes(names, identity)
        if len(modes) != 1:
            unsupported.append({'materialIndex': index, 'sourceMaterial': identity,
                                'reason': 'missing_or_ambiguous_source_matrix_mode', 'modes': sorted(modes)})
            continue
        mode = next(iter(modes))
        width, height = texture_size(document, binary, index)
        transforms = [nitro_affine(sample, mode, width, height) for sample in source['samples']]
        if len({tuple(transform) for transform in transforms}) == 1:
            continue
        duration = frames / fps
        tracks.append({'materialIndex': index, 'durationSeconds': duration,
                       'times': [frame / fps for frame in range(frames)] + [duration],
                       'transforms': transforms + [transforms[0]], 'interpolation': 'STEP'})
        evidence.append({'material': identity, 'modelNames': sorted(names), 'matrixMode': mode,
                         'matrixModeEvidence': binding['matrixModeEvidence'],
                         'uvCoordinateConvention': 'nitro_normalized_uv',
                         'sourceUvConversion': 'nitro_to_collada_v_flip_then_glb_v_flip',
                         'matrixConversion': 'original_sdk_normalized_uv',
                         'animation': source['clip'], 'animationSha256': source['source']['sha256'],
                         'origins': source['source']['origins'], 'association': 'declared_source_clip'})
        output['materials'][index].setdefault('extras', {})['aveluneNitroMaterial'] = identity
    if not tracks:
        return None, evidence, unsupported
    clip = {'name': clip_name, 'durationSeconds': max(track['durationSeconds'] for track in tracks), 'tracks': tracks}
    output.setdefault('extras', {})['aveluneMaterialAnimations'] = {'schemaVersion': 1, 'clips': [clip]}
    return output, evidence, unsupported

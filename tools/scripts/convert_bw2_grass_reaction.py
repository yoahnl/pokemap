import argparse
from copy import deepcopy
from hashlib import sha256
from io import BytesIO
import json
import math
from pathlib import Path
import subprocess
import sys

from PIL import Image

sys.dont_write_bytecode = True

from read_bw2_nitro_animations import nitro_affine, read_model_materials, read_srt, verified_source
from rigidify_bw2_animation import GlbWriter, accessor_rows, read_glb

HIDDEN_SCALE = 1e-9


def attach_original_grass_reaction(base_glb, reaction_glb, png, samples, frame_rate):
    if not math.isfinite(frame_rate) or frame_rate <= 0 or len(samples) < 3:
        raise ValueError('Invalid reaction clock or sample count')
    if any(len(row) != 6 or not all(math.isfinite(value) for value in row) for row in samples):
        raise ValueError('Invalid original material samples')
    base, base_binary = read_glb(base_glb)
    reaction, reaction_binary = read_glb(reaction_glb)
    if base.get('animations') or base.get('extras', {}).get('aveluneMaterialAnimations'):
        raise ValueError('The grass reaction requires a static base')
    if any(any(key in node for key in ['matrix', 'translation', 'rotation', 'scale'])
           for node in reaction['nodes']):
        raise ValueError('Unverified reaction source transform')
    identity = [1 if index % 5 == 0 else 0 for index in range(16)]
    for skin in reaction.get('skins', []):
        if any(row != identity for row in accessor_rows(reaction, reaction_binary, skin['inverseBindMatrices'])):
            raise ValueError('Unverified reaction bind transform')
    if len(reaction['materials']) != 1 or len(reaction['meshes']) != 1:
        raise ValueError('Expected a single original grass effect')
    with Image.open(BytesIO(png)) as image:
        image.load()
        width, height = image.size
    output = deepcopy(base)
    writer = GlbWriter(output, base_binary)
    writer.binary.extend(b'\0' * (-len(writer.binary) % 4))
    image_offset = len(writer.binary)
    writer.binary.extend(png)
    image_view = len(output.setdefault('bufferViews', []))
    output['bufferViews'].append({'buffer': 0, 'byteOffset': image_offset, 'byteLength': len(png)})
    image_index = len(output.setdefault('images', []))
    output['images'].append({'bufferView': image_view, 'mimeType': 'image/png'})
    sampler_index = len(output.setdefault('samplers', []))
    sampler = reaction.get('samplers', [{}])[0]
    output['samplers'].append(deepcopy(sampler))
    texture_index = len(output.setdefault('textures', []))
    output['textures'].append({'source': image_index, 'sampler': sampler_index})
    material_index = len(output['materials'])
    material = deepcopy(reaction['materials'][0])
    material['pbrMetallicRoughness']['baseColorTexture']['index'] = texture_index
    if material.get('alphaMode') == 'MASK':
        material['alphaCutoff'] = material.get('alphaCutoff', .5)
    output['materials'].append(material)
    primitives = []
    triangles = 0
    for primitive in reaction['meshes'][0]['primitives']:
        if primitive.get('mode', 4) != 4 or primitive.get('material', 0) != 0:
            raise ValueError('Unsupported original reaction primitive')
        attributes = {key: accessor_rows(reaction, reaction_binary, index)
                      for key, index in primitive['attributes'].items()}
        if 'JOINTS_0' in attributes:
            if any(any(index != 0 for index in row) for row in attributes['JOINTS_0']):
                raise ValueError('The original effect has multiple joints')
            if any(row != [1, 0, 0, 0] for row in attributes['WEIGHTS_0']):
                raise ValueError('The original effect is not rigid')
        positions = attributes['POSITION']
        indices = [int(row[0]) for row in accessor_rows(reaction, reaction_binary, primitive['indices'])] if 'indices' in primitive else list(range(len(positions)))
        if len(indices) % 3:
            raise ValueError('Incomplete original reaction triangles')
        converted = {'material': material_index, 'attributes': {}}
        for key, values in attributes.items():
            if key in ['JOINTS_0', 'WEIGHTS_0']:
                continue
            rows = [values[index] for index in indices]
            if key == 'POSITION':
                rows = [[value / 16 for value in row] for row in rows]
            converted['attributes'][key] = writer.rows(rows, 'VEC' + str(len(rows[0])))
        primitives.append(converted)
        triangles += len(indices) // 3
    mesh_index = len(output['meshes'])
    output['meshes'].append({'name': 'Réaction originale NB2', 'primitives': primitives})
    node_index = len(output['nodes'])
    output['nodes'].append({'name': 'Réaction au passage', 'mesh': mesh_index, 'scale': [HIDDEN_SCALE] * 3})
    output['scenes'][output.get('scene', 0)]['nodes'].append(node_index)
    duration = len(samples) / frame_rate
    times = writer.rows([[0], [1 / frame_rate], [duration]], 'SCALAR')
    scales = writer.rows([[HIDDEN_SCALE] * 3, [1, 1, 1], [HIDDEN_SCALE] * 3], 'VEC3')
    output['animations'] = [{'name': 'Réaction · visibilité',
        'samplers': [{'input': times, 'output': scales, 'interpolation': 'STEP'}],
        'channels': [{'sampler': 0, 'target': {'node': node_index, 'path': 'scale'}}]}]
    transforms = [nitro_affine(sample, 0, width, height) for sample in samples]
    output.setdefault('extras', {})['aveluneMaterialAnimations'] = {'schemaVersion': 1, 'clips': [{
        'name': 'Réaction complète · source NB2', 'durationSeconds': duration, 'nodeAnimationIndex': 0,
        'tracks': [{'materialIndex': material_index, 'durationSeconds': duration,
                    'times': [frame / frame_rate for frame in range(len(samples))] + [duration],
                    'transforms': transforms + [transforms[0]], 'interpolation': 'STEP'}]}]}
    extensions = output.setdefault('extensionsUsed', [])
    for extension in reaction.get('extensionsUsed', []):
        if extension not in extensions:
            extensions.append(extension)
    result = writer.finish()
    return result, {'baseSha256': sha256(base_glb).hexdigest(),
        'originalReactionGlbSha256': sha256(reaction_glb).hexdigest(),
        'textureSha256': sha256(png).hexdigest(), 'frames': len(samples),
        'conversionFrameRate': frame_rate, 'durationSeconds': duration, 'animationIndex': 1,
        'idleEffectScale': HIDDEN_SCALE,
        'addedTriangles': triangles, 'baseBinaryPrefixPreserved': bytes(writer.binary[:len(base_binary)]) == base_binary,
        'originalPlaybackRateQualified': False, 'nativeGpuQualified': False}


def convert(base, source_root, output, frame_rate=60):
    base, source_root, output = base.resolve(strict=True), source_root.resolve(strict=True), output.resolve()
    if output.is_relative_to(source_root) or output.is_relative_to(base.parent):
        raise ValueError('Conversion output must stay outside its sources')
    inventory = json.loads((source_root / 'animation-inventory.json').read_text())
    records = [record for record in inventory['animations'] if record['name'] == 'short_grass_sp' and record['type'] == 'SRT0']
    if len(records) != 1:
        raise ValueError('Missing or ambiguous original grass reaction')
    record = records[0]
    animation_bytes = verified_source(source_root, record)
    clips = read_srt(animation_bytes)
    if len(clips) != 1 or len(clips[0]['tracks']) != 1 or clips[0]['frames'] != record['frames']:
        raise ValueError('The original reaction does not match its inventory')
    model = source_root / 'nitro-original/short_grass_sp.nsbmd'
    model_bytes = model.read_bytes()
    inspection = read_model_materials(model_bytes)
    if len(inspection) != 1 or inspection[0]['textureMatrixMode'] != 0 or inspection[0]['materials'] != [clips[0]['tracks'][0]['material']]:
        raise ValueError('Original grass model and animation disagree')
    decoder = source_root / 'apicula-3d4e91e14045392a49c89e86dab8cb936225588c/target/release/apicula'
    original = output.parent / 'original-short-grass'
    original.parent.mkdir(parents=True, exist_ok=True)
    run = subprocess.run([str(decoder), 'convert', str(model), '-o', str(original), '-f', 'glb', '--overwrite'], capture_output=True, text=True)
    original.with_suffix('.conversion.log').write_text(run.stdout + run.stderr)
    if run.returncode:
        raise ValueError('Pinned original grass conversion failed')
    reaction = (original / 'short_grass_sp.glb').read_bytes()
    png = (original / 'ee_kusa_sp.png').read_bytes()
    result, proof = attach_original_grass_reaction(base.read_bytes(), reaction, png, clips[0]['tracks'][0]['samples'], frame_rate)
    proof.update(sourceModelSha256=sha256(model_bytes).hexdigest(),
                 sourceAnimationSha256=record['sha256'], sourceOrigins=record['origins'],
                 romSha256=inventory['source']['rom_sha256'],
                 sourceMaterial=clips[0]['tracks'][0]['material'], sourceWrites=False)
    output.write_bytes(result)
    proof['outputSha256'] = sha256(result).hexdigest()
    output.with_suffix('.proof.json').write_text(json.dumps(proof, ensure_ascii=False, indent=2) + '\n')
    return proof


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--base', type=Path, required=True)
    parser.add_argument('--source-root', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--frame-rate', type=float, default=60)
    args = parser.parse_args()
    print(json.dumps(convert(args.base, args.source_root, args.output, args.frame_rate)))

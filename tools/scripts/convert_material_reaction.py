import argparse
from copy import deepcopy
from hashlib import sha256
from io import BytesIO
import json
import math
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

from PIL import Image

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'source_units'))
from extract_units import _identifier, _keys, _text
from material_animation import source_bytes
from nitro_materials import nitro_affine, read_model_materials, read_srt
from rigidify_bw2_animation import GlbWriter, accessor_rows, read_glb

HIDDEN_SCALE = 1e-9


def attach_material_reaction(base_glb, reaction_glb, png, samples, frame_rate, *, source_units_per_cell, matrix_mode, label):
    if type(frame_rate) not in (int, float) or not math.isfinite(frame_rate) or not 0 < frame_rate <= 1000 or not 3 <= len(samples) <= 65535:
        raise ValueError('Invalid reaction clock or sample count')
    if type(source_units_per_cell) not in (int, float) or not math.isfinite(source_units_per_cell) or source_units_per_cell <= 0:
        raise ValueError('Source units per cell must be explicit and positive')
    if type(matrix_mode) is not int or matrix_mode not in (0, 2) or not isinstance(label, str) or not label.strip():
        raise ValueError('Reaction presentation must be explicit')
    if any(len(row) != 6 or not all(math.isfinite(value) for value in row) for row in samples):
        raise ValueError('Invalid original material samples')
    base, base_binary = read_glb(base_glb)
    reaction, reaction_binary = read_glb(reaction_glb)
    if base.get('animations') or base.get('extras', {}).get('aveluneMaterialAnimations'):
        raise ValueError('The material reaction requires a static base')
    if reaction.get('animations') or reaction.get('extras', {}).get('aveluneMaterialAnimations'):
        raise ValueError('Untranslated reaction source animation')
    if any(any(key in node for key in ['matrix', 'translation', 'rotation', 'scale'])
           for node in reaction['nodes']):
        raise ValueError('Unverified reaction source transform')
    identity = [1 if index % 5 == 0 else 0 for index in range(16)]
    for skin in reaction.get('skins', []):
        if any(row != identity for row in accessor_rows(reaction, reaction_binary, skin['inverseBindMatrices'])):
            raise ValueError('Unverified reaction bind transform')
    if len(reaction['materials']) != 1 or len(reaction['meshes']) != 1:
        raise ValueError('Expected a single source material effect')
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
                rows = [[value / source_units_per_cell for value in row] for row in rows]
            converted['attributes'][key] = writer.rows(rows, 'VEC' + str(len(rows[0])))
        primitives.append(converted)
        triangles += len(indices) // 3
    mesh_index = len(output['meshes'])
    output['meshes'].append({'name': label, 'primitives': primitives})
    node_index = len(output['nodes'])
    output['nodes'].append({'name': label, 'mesh': mesh_index, 'scale': [HIDDEN_SCALE] * 3})
    output['scenes'][output.get('scene', 0)]['nodes'].append(node_index)
    duration = len(samples) / frame_rate
    times = writer.rows([[0], [1 / frame_rate], [duration]], 'SCALAR')
    scales = writer.rows([[HIDDEN_SCALE] * 3, [1, 1, 1], [HIDDEN_SCALE] * 3], 'VEC3')
    output['animations'] = [{'name': label + ' · visibility',
        'samplers': [{'input': times, 'output': scales, 'interpolation': 'STEP'}],
        'channels': [{'sampler': 0, 'target': {'node': node_index, 'path': 'scale'}}]}]
    transforms = [nitro_affine(sample, matrix_mode, width, height) for sample in samples]
    output.setdefault('extras', {})['aveluneMaterialAnimations'] = {'schemaVersion': 1, 'clips': [{
        'name': label, 'durationSeconds': duration, 'nodeAnimationIndex': 0,
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


def _digest(value):
    if not isinstance(value, str) or len(value) != 64 or any(character not in '0123456789abcdef' for character in value):
        raise ValueError('Material reaction requires pinned SHA-256 digests')


def _relative(value):
    _text(value)
    if Path(value).is_absolute() or '\\' in value or ':' in value or any(part in ('', '.', '..') for part in value.split('/')):
        raise ValueError('Material reaction resource must be confined')


def require_recipe(value):
    _keys(value, {'schemaVersion', 'id', 'label', 'baseSha256', 'decoderSha256', 'sourceModel',
                  'sourceAnimation', 'decodedGlb', 'texture', 'frameRate', 'frameRateEvidence',
                  'sourceUnitsPerCell', 'matrixMode', 'outputFile', 'provenance'})
    if type(value['schemaVersion']) is not int or value['schemaVersion'] != 1:
        raise ValueError('Unsupported material reaction recipe')
    if len(json.dumps(value, allow_nan=False).encode()) > 65536:
        raise ValueError('Material reaction recipe exceeds 64 KiB')
    _identifier(value['id'])
    _text(value['label'])
    _text(value['frameRateEvidence'])
    _digest(value['baseSha256'])
    _digest(value['decoderSha256'])
    model = value['sourceModel']
    _keys(model, {'relativePath', 'sha256', 'name'})
    _relative(model['relativePath'])
    _digest(model['sha256'])
    _text(model['name'])
    animation = value['sourceAnimation']
    _keys(animation, {'relativePath', 'sha256', 'clip', 'material', 'frames'})
    _relative(animation['relativePath'])
    _digest(animation['sha256'])
    _text(animation['clip'])
    _text(animation['material'])
    if type(animation['frames']) is not int or not 3 <= animation['frames'] <= 65535:
        raise ValueError('Material reaction requires a bounded source frame count')
    for key in ['decodedGlb', 'texture']:
        _keys(value[key], {'fileName', 'sha256'})
        _relative(value[key]['fileName'])
        if Path(value[key]['fileName']).name != value[key]['fileName']:
            raise ValueError('Decoded reaction resources must be flat files')
        _digest(value[key]['sha256'])
    for key in ['frameRate', 'sourceUnitsPerCell']:
        if type(value[key]) not in (int, float) or not math.isfinite(value[key]) or not 0 < value[key] <= 65536:
            raise ValueError('Material reaction cadence and units must be explicit and positive')
    if value['frameRate'] > 1000 or type(value['matrixMode']) is not int or value['matrixMode'] not in (0, 2):
        raise ValueError('Unsupported material reaction matrix mode or cadence')
    _relative(value['outputFile'])
    if Path(value['outputFile']).name != value['outputFile'] or not value['outputFile'].endswith('.glb'):
        raise ValueError('Material reaction output must be a flat GLB filename')
    if not isinstance(value['provenance'], dict):
        raise ValueError('Material reaction provenance must be an object')
    return value


def convert(base, source_root, output_root, *, recipe, decoder):
    require_recipe(recipe)
    base, source_root, decoder, output_root = map(Path, (base, source_root, decoder, output_root))
    if any(not path.is_absolute() for path in [base, source_root, decoder, output_root]):
        raise ValueError('Material reaction roots and files must be explicit absolute paths')
    source_root = source_root.resolve(strict=True)
    output = output_root.parent.resolve(strict=True) / output_root.name
    base_root, decoder_root = base.parent.resolve(strict=True), decoder.parent.resolve(strict=True)
    if output_root.name in ('', '.', '..') or output.exists() or output.is_symlink():
        raise ValueError('Material reaction output must be a new directory')
    if any(output == root or root in output.parents or output in root.parents for root in [source_root, base_root, decoder_root]):
        raise ValueError('Material reaction output must stay outside its sources')
    base_bytes = source_bytes(base_root, base.name, recipe['baseSha256'])
    model = recipe['sourceModel']
    model_bytes = source_bytes(source_root, model['relativePath'], model['sha256'])
    animation = recipe['sourceAnimation']
    animation_bytes = source_bytes(source_root, animation['relativePath'], animation['sha256'])
    decoder_bytes = source_bytes(decoder_root, decoder.name, recipe['decoderSha256'])
    clips = [clip for clip in read_srt(animation_bytes) if clip['name'] == animation['clip']]
    if len(clips) != 1 or clips[0]['frames'] != animation['frames'] or len(clips[0]['tracks']) != 1 or clips[0]['tracks'][0]['material'] != animation['material']:
        raise ValueError('Declared reaction clip, frame count or material does not match source bytes')
    models = [item for item in read_model_materials(model_bytes) if item['name'] == model['name']]
    if len(models) != 1 or models[0]['textureMatrixMode'] != recipe['matrixMode'] or models[0]['materials'] != [animation['material']]:
        raise ValueError('Declared reaction model and animation disagree')
    work = Path(tempfile.mkdtemp(prefix='.material-reaction-', dir=output.parent))
    staging = None
    try:
        executable = work / 'decoder'
        executable.write_bytes(decoder_bytes)
        executable.chmod(0o700)
        staged_model = work / Path(model['relativePath']).name
        if staged_model == executable:
            raise ValueError('Reaction model filename collides with the staged decoder')
        staged_model.write_bytes(model_bytes)
        decoded = work / 'decoded'
        run = subprocess.run([str(executable), 'convert', str(staged_model), '-o', str(decoded), '-f', 'glb'],
                             capture_output=True, text=True, timeout=60)
        if run.returncode:
            raise ValueError('Pinned material reaction decoder failed')
        reaction = source_bytes(decoded, recipe['decodedGlb']['fileName'], recipe['decodedGlb']['sha256'])
        png = source_bytes(decoded, recipe['texture']['fileName'], recipe['texture']['sha256'])
        result, proof = attach_material_reaction(base_bytes, reaction, png, clips[0]['tracks'][0]['samples'],
            recipe['frameRate'], source_units_per_cell=recipe['sourceUnitsPerCell'],
            matrix_mode=recipe['matrixMode'], label=recipe['label'])
        proof.update(recipeId=recipe['id'], recipeSha256=sha256(json.dumps(recipe, sort_keys=True, separators=(',', ':'), allow_nan=False).encode()).hexdigest(),
                     sourceModelSha256=model['sha256'], sourceAnimationSha256=animation['sha256'],
                     sourceMaterial=animation['material'], sourceClip=animation['clip'],
                     sourceUnitsPerCell=recipe['sourceUnitsPerCell'], sourceMatrixMode=recipe['matrixMode'],
                     decoderSha256=recipe['decoderSha256'], frameRateEvidence=recipe['frameRateEvidence'],
                     provenance=recipe['provenance'], sourceWrites=False, outputSha256=sha256(result).hexdigest())
        staging = Path(tempfile.mkdtemp(prefix='.material-reaction-', dir=output.parent))
        (staging / recipe['outputFile']).write_bytes(result)
        (staging / 'proof.json').write_text(json.dumps(proof, ensure_ascii=False, indent=2, allow_nan=False) + '\n')
        if output.exists() or output.is_symlink():
            raise ValueError('Material reaction output appeared during preparation')
        os.rename(staging, output)
        return proof
    finally:
        if staging is not None and staging.exists():
            shutil.rmtree(staging)
        shutil.rmtree(work)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--recipe', type=Path, required=True)
    parser.add_argument('--base', type=Path, required=True)
    parser.add_argument('--source-root', type=Path, required=True)
    parser.add_argument('--decoder', type=Path, required=True)
    parser.add_argument('--output-root', type=Path, required=True)
    args = parser.parse_args()
    data = args.recipe.read_bytes()
    if len(data) > 65536:
        raise ValueError('Material reaction recipe exceeds 64 KiB')
    print(json.dumps(convert(args.base, args.source_root, args.output_root,
                             recipe=json.loads(data), decoder=args.decoder), allow_nan=False))


if __name__ == '__main__':
    main()


from hashlib import sha256
from io import BytesIO
import json
from pathlib import Path
import subprocess
import struct

from PIL import Image

from convert_bw2_city_joint_animations import unique_source
from read_bw2_nitro_animations import blocks, dictionary, retarget_material_texture
from rigidify_bw2_animation import read_glb


def texture_pair_signatures(data, wanted_pairs=None):
    result = {}
    for kind, block in blocks(data):
        if kind != b'TEX0':
            continue
        textures = dictionary(data, block + struct.unpack_from('<H', data, block + 14)[0], 8)
        palettes = dictionary(data, block + struct.unpack_from('<I', data, block + 52)[0], 4)
        palette_offsets = {name: struct.unpack('<HH', raw)[0] * 8 for raw, name in palettes}
        for raw, texture in textures:
            if wanted_pairs is not None and not any(pair[0] == texture for pair in wanted_pairs):
                continue
            params = struct.unpack('<II', raw)[0]
            fmt = params >> 26 & 7
            bits = {1: 8, 2: 2, 3: 4, 4: 8, 6: 8, 7: 16}.get(fmt)
            if bits is None:
                continue
            width, height = 8 << (params >> 20 & 7), 8 << (params >> 23 & 7)
            offset = block + struct.unpack_from('<I', data, block + 20)[0] + (params & 0xffff) * 8
            size = width * height * bits // 8
            colors = {1: 32, 2: 4, 3: 16, 4: 256, 6: 8}.get(fmt, 0)
            texels = data[offset:offset + size]
            if len(texels) != size:
                raise ValueError('Truncated original Nitro texture')
            for palette, relative in palette_offsets.items():
                if wanted_pairs is not None and (texture, palette) not in wanted_pairs:
                    continue
                start = block + struct.unpack_from('<I', data, block + 56)[0] + relative
                colors_data = data[start:start + colors * 2]
                if len(colors_data) != colors * 2:
                    raise ValueError('Truncated original Nitro palette')
                signature = struct.pack('<I', params & 0x3fff0000) + texels + colors_data
                result[texture, palette] = sha256(signature).hexdigest()
    return result


def verified_texture_pack(nitro_root, pairs):
    variants, seen = {}, set()
    for path in sorted(nitro_root.glob('*.nsbtx')):
        data = path.read_bytes()
        digest = sha256(data).hexdigest()
        if digest in seen:
            continue
        seen.add(digest)
        signatures = texture_pair_signatures(data, set(pairs))
        if not all(pair in signatures for pair in pairs):
            continue
        key = tuple(signatures[pair] for pair in pairs)
        variants.setdefault(key, []).append({'path': str(path), 'sha256': digest})
    if len(variants) != 1:
        raise ValueError('Original pattern texture pack is missing or has ambiguous pixels')
    candidates = next(iter(variants.values()))
    return Path(candidates[0]['path']), candidates


def decode_pattern_frames(nitro_root, apicula, output, animation, track):
    model, model_sha = unique_source(nitro_root, animation['animation'], '.nsbmd')
    data = model.read_bytes()
    result = {}
    pairs = list(dict.fromkeys((key['texture'], key['palette']) for key in track['keys']))
    pack, equivalent_packs = verified_texture_pack(nitro_root, pairs)
    for index, (texture, palette) in enumerate(pairs):
        folder = output / animation['animation'] / track['material'] / f'{index:03d}'
        patched, changes = retarget_material_texture(data, animation['animation'], track['material'], texture, palette)
        input_path = folder / 'source.nsbmd'
        proof = folder / 'converted' / (animation['animation'] + '.glb')
        expected = sha256(patched).hexdigest()
        if input_path.exists() and sha256(input_path.read_bytes()).hexdigest() != expected:
            raise ValueError('Cached texture source changed')
        folder.mkdir(parents=True, exist_ok=True)
        input_path.write_bytes(patched)
        cache = folder / 'cache.json'
        expected_cache = {'derivedModelSha256': expected, 'texturePackSha256': equivalent_packs[0]['sha256']}
        cached = json.loads(cache.read_text()) if cache.exists() else {}
        image_cache = cached.get('images', {})
        valid_images = bool(image_cache) and all(Path(name).name == name and (proof.parent / name).exists()
                                                and sha256((proof.parent / name).read_bytes()).hexdigest() == value
                                                for name, value in image_cache.items())
        if not proof.exists() or any(cached.get(key) != value for key, value in expected_cache.items()) or cached.get('proofSha256') != sha256(proof.read_bytes()).hexdigest() or not valid_images:
            command = [str(apicula), 'convert', str(input_path), str(pack), '-o', str(proof.parent), '-f', 'glb', '--overwrite']
            run = subprocess.run(command, capture_output=True, text=True)
            (folder / 'conversion.log').write_text(run.stdout + run.stderr)
            if run.returncode:
                raise ValueError('Original pattern texture could not be decoded')
            images = {path.name: sha256(path.read_bytes()).hexdigest() for path in proof.parent.glob('*.png')}
            cache.write_text(json.dumps({**expected_cache, 'proofSha256': sha256(proof.read_bytes()).hexdigest(), 'images': images}) + '\n')
        document, binary = read_glb(proof.read_bytes())
        material = next(material for material in document['materials'] if material.get('name') == track['material'])
        texture_index = material['pbrMetallicRoughness']['baseColorTexture']['index']
        image = document['images'][document['textures'][texture_index]['source']]
        if 'uri' in image:
            name = image['uri']
            if Path(name).name != name or not name.endswith('.png'):
                raise ValueError('Original decoder image must be a local PNG member')
            png = (proof.parent / name).read_bytes()
        else:
            if image.get('mimeType') != 'image/png' or 'bufferView' not in image:
                raise ValueError('Decoded original texture is not PNG')
            view = document['bufferViews'][image['bufferView']]
            if view['buffer'] != 0:
                raise ValueError('External pattern image buffer')
            start = view.get('byteOffset', 0)
            png = binary[start:start + view['byteLength']]
        with Image.open(BytesIO(png)) as decoded:
            decoded.verify()
        destination = folder / 'frame.png'
        destination.write_bytes(png)
        result[texture, palette] = {'path': destination, 'data': png, 'sha256': sha256(png).hexdigest(),
                                   'sourceModelSha256': model_sha, 'derivedModelSha256': expected,
                                   'bindingChanges': changes, 'texture': texture, 'palette': palette,
                                   'equivalentTexturePacks': equivalent_packs}
    receipt = [{**record, 'path': str(record['path'])} for record in result.values()]
    for record in receipt:
        record.pop('data')
    target = output / animation['animation'] / track['material'] / 'frames.json'
    target.write_text(json.dumps({'animationSha256': animation['sha256'], 'frames': receipt}, indent=2) + '\n')
    return result

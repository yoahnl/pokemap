from collections import defaultdict
from copy import deepcopy
from hashlib import sha256
import json
import struct


def read_glb(data):
    if len(data) < 28 or struct.unpack_from('<III', data) != (0x46546C67, 2, len(data)):
        raise ValueError('Invalid GLB header')
    size, kind = struct.unpack_from('<I4s', data, 12)
    if kind != b'JSON' or 28 + size > len(data):
        raise ValueError('Invalid GLB JSON chunk')
    document = json.loads(data[20:20 + size])
    binary_size, kind = struct.unpack_from('<I4s', data, 20 + size)
    binary = data[28 + size:]
    if kind != b'BIN\0' or len(binary) != binary_size:
        raise ValueError('Invalid GLB binary chunk')
    return document, binary


def glb_bytes(document, binary):
    encoded = json.dumps(document, separators=(',', ':'), ensure_ascii=False, allow_nan=False).encode()
    encoded += b' ' * (-len(encoded) % 4)
    binary += b'\0' * (-len(binary) % 4)
    return (struct.pack('<III', 0x46546C67, 2, 28 + len(encoded) + len(binary))
            + struct.pack('<I4s', len(encoded), b'JSON') + encoded
            + struct.pack('<I4s', len(binary), b'BIN\0') + binary)


def embedded_view(document, binary, index):
    view = document['bufferViews'][index]
    if view['buffer'] != 0:
        raise ValueError('External buffer is unsupported')
    start, size = view.get('byteOffset', 0), view['byteLength']
    if start < 0 or size < 0 or start + size > document['buffers'][0]['byteLength']:
        raise ValueError('Buffer view exceeds the declared binary buffer')
    if start + size > len(binary):
        raise ValueError('Truncated buffer view')
    return binary[start:start + size]


def material_group(material, groups):
    names = material.get('extras', {}).get('sourceMaterials')
    if not names or any(name not in groups for name in names):
        raise ValueError('Unclassified original material')
    kinds = {groups[name] for name in names}
    if len(kinds) != 1:
        raise ValueError('A material merges different authoring families')
    return next(iter(kinds))


def primitive_signature(document, binary, primitive):
    attributes = {}
    indices = dict(primitive['attributes'])
    if 'indices' in primitive:
        indices['indices'] = primitive['indices']
    for name, index in sorted(indices.items()):
        accessor = deepcopy(document['accessors'][index])
        view_index = accessor.pop('bufferView')
        view = deepcopy(document['bufferViews'][view_index])
        payload = embedded_view(document, binary, view_index)
        view.pop('buffer')
        view.pop('byteOffset', None)
        attributes[name] = {'accessor': accessor, 'view': view, 'payloadSha256': sha256(payload).hexdigest()}
    material = deepcopy(document['materials'][primitive['material']])
    texture_index = material['pbrMetallicRoughness']['baseColorTexture'].pop('index')
    texture = deepcopy(document['textures'][texture_index])
    image = deepcopy(document['images'][texture.pop('source')])
    image_index = image.pop('bufferView')
    sampler = deepcopy(document['samplers'][texture.pop('sampler')]) if 'sampler' in texture else None
    return {'attributes': attributes, 'material': material, 'texture': texture, 'image': image,
            'imageSha256': sha256(embedded_view(document, binary, image_index)).hexdigest(),
            'sampler': sampler, 'mode': primitive.get('mode', 4)}


def compact_component(document, binary, selected):
    primitives = [deepcopy(document['meshes'][0]['primitives'][index]) for index in selected]
    material_ids = sorted({primitive['material'] for primitive in primitives})
    accessor_ids = sorted({index for primitive in primitives
                           for index in [*primitive['attributes'].values(),
                                         *([primitive['indices']] if 'indices' in primitive else [])]})
    materials = [deepcopy(document['materials'][index]) for index in material_ids]
    texture_ids = []
    for material in materials:
        if material.get('extensions', {}) != {'KHR_materials_unlit': {}}:
            raise ValueError('Only original unlit materials are qualified')
        pbr = material['pbrMetallicRoughness']
        if any(key.endswith('Texture') and key != 'baseColorTexture' for key in pbr):
            raise ValueError('Additional material texture is unsupported')
        if any(key.endswith('Texture') for key in material):
            raise ValueError('Additional material texture is unsupported')
        texture_ids.append(pbr['baseColorTexture']['index'])
    texture_ids = sorted(set(texture_ids))
    textures = [deepcopy(document['textures'][index]) for index in texture_ids]
    if any(texture.get('extensions') for texture in textures):
        raise ValueError('Texture extensions are unsupported')
    image_ids = sorted({texture['source'] for texture in textures})
    sampler_ids = sorted({texture['sampler'] for texture in textures if 'sampler' in texture})
    images = [deepcopy(document['images'][index]) for index in image_ids]
    if any('uri' in image or image.get('mimeType') != 'image/png' for image in images):
        raise ValueError('Only embedded original PNG textures are qualified')
    accessors = [deepcopy(document['accessors'][index]) for index in accessor_ids]
    if any('sparse' in accessor or 'bufferView' not in accessor for accessor in accessors):
        raise ValueError('Sparse or unbound accessors are unsupported')
    view_ids = sorted({accessor['bufferView'] for accessor in accessors}
                      | {image['bufferView'] for image in images})
    mappings = {kind: {old: new for new, old in enumerate(indices)} for kind, indices in
                [('material', material_ids), ('accessor', accessor_ids), ('texture', texture_ids),
                 ('image', image_ids), ('sampler', sampler_ids), ('view', view_ids)]}
    payload = bytearray()
    views = []
    for index in view_ids:
        payload.extend(b'\0' * (-len(payload) % 4))
        view = deepcopy(document['bufferViews'][index])
        view.update(buffer=0, byteOffset=len(payload))
        payload.extend(embedded_view(document, binary, index))
        views.append(view)
    for primitive in primitives:
        primitive['material'] = mappings['material'][primitive['material']]
        primitive['attributes'] = {name: mappings['accessor'][index] for name, index in primitive['attributes'].items()}
        if 'indices' in primitive:
            primitive['indices'] = mappings['accessor'][primitive['indices']]
    for accessor in accessors:
        accessor['bufferView'] = mappings['view'][accessor['bufferView']]
    for material in materials:
        texture = material['pbrMetallicRoughness']['baseColorTexture']
        texture['index'] = mappings['texture'][texture['index']]
    for texture in textures:
        texture['source'] = mappings['image'][texture['source']]
        if 'sampler' in texture:
            texture['sampler'] = mappings['sampler'][texture['sampler']]
    for image in images:
        image['bufferView'] = mappings['view'][image['bufferView']]
    component = {'asset': deepcopy(document['asset']), 'scene': 0, 'scenes': [{'nodes': [0]}],
                 'nodes': [{'mesh': 0}], 'meshes': [{'primitives': primitives}],
                 'buffers': [{'byteLength': len(payload)}], 'bufferViews': views,
                 'accessors': accessors, 'materials': materials, 'textures': textures,
                 'images': images, 'samplers': [deepcopy(document['samplers'][index]) for index in sampler_ids]}
    for key in ['extensionsUsed', 'extensionsRequired']:
        if key in document:
            component[key] = deepcopy(document[key])
    expected = [primitive_signature(document, binary, document['meshes'][0]['primitives'][index]) for index in selected]
    actual = [primitive_signature(component, payload, primitive) for primitive in component['meshes'][0]['primitives']]
    if actual != expected:
        raise ValueError('Component changed original vertices, materials or texture bytes')
    return component, bytes(payload)


def partition_static_glb(data, groups):
    document, binary = read_glb(data)
    if document.get('animations') or document.get('skins'):
        raise ValueError('Animated or skinned geometry requires a separate qualification')
    if len(document.get('meshes', [])) != 1 or document.get('nodes') != [{'mesh': 0}]:
        raise ValueError('Only one static identity mesh is qualified')
    if document.get('scenes') != [{'nodes': [0]}] or document.get('scene', 0) != 0:
        raise ValueError('Unexpected scene graph')
    if len(document.get('buffers', [])) != 1 or 'uri' in document['buffers'][0]:
        raise ValueError('Only one embedded binary buffer is qualified')
    if set(document.get('extensionsUsed', [])) - {'KHR_materials_unlit'}:
        raise ValueError('Unqualified GLB extension')
    selected = defaultdict(list)
    for index, primitive in enumerate(document['meshes'][0]['primitives']):
        if primitive.get('mode', 4) != 4 or primitive.get('targets') or primitive.get('extensions'):
            raise ValueError('Only static triangle primitives are qualified')
        kind = material_group(document['materials'][primitive['material']], groups)
        selected[kind].append(index)
    if not selected:
        raise ValueError('Empty geometry')
    result = {}
    for kind, indices in sorted(selected.items()):
        component, payload = compact_component(document, binary, indices)
        result[kind] = {'document': component, 'binary': payload, 'sourcePrimitiveIndices': indices,
                        'originalBytesPreserved': True}
    if sorted(index for row in result.values() for index in row['sourcePrimitiveIndices']) != list(range(len(document['meshes'][0]['primitives']))):
        raise ValueError('Partition dropped or duplicated an original primitive')
    return result


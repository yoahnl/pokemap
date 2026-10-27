import argparse
import hashlib
from io import BytesIO
import json
import math
from pathlib import Path
import struct

from PIL import Image


def require(condition, message):
    if not condition:
        raise ValueError(message)


def decode_glb(data):
    require(len(data) >= 28, 'Truncated GLB')
    require(struct.unpack_from('<III', data) == (0x46546C67, 2, len(data)), 'Invalid GLB header')
    offset = 12
    chunks = []
    while offset < len(data):
        require(offset + 8 <= len(data), 'Truncated GLB chunk')
        size, kind = struct.unpack_from('<II', data, offset)
        offset += 8
        require(size % 4 == 0 and offset + size <= len(data), 'Invalid GLB chunk bounds')
        chunks.append((kind, data[offset:offset + size]))
        offset += size
    require([kind for kind, _ in chunks] == [0x4E4F534A, 0x004E4942], 'Expected JSON and BIN chunks')
    document = json.loads(chunks[0][1])
    require(document['asset']['version'] == '2.0', 'Expected glTF 2.0')
    binary = chunks[1][1]
    require(len(document['buffers']) == 1 and 'uri' not in document['buffers'][0], 'External buffer')
    require(0 <= len(binary) - document['buffers'][0]['byteLength'] <= 3, 'Invalid buffer length')
    return document, binary


def accessor_rows(document, binary, index):
    accessor = document['accessors'][index]
    require('sparse' not in accessor, 'Sparse accessor')
    dimensions = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}
    formats = {5121: ('B', 1), 5123: ('H', 2), 5125: ('I', 4), 5126: ('f', 4)}
    require(accessor['type'] in dimensions, 'Unsupported accessor type')
    require(accessor['componentType'] in formats, 'Unsupported component type')
    dimension = dimensions[accessor['type']]
    code, width = formats[accessor['componentType']]
    view = document['bufferViews'][accessor['bufferView']]
    require(view['buffer'] == 0, 'External buffer view')
    start = view.get('byteOffset', 0)
    end = start + view['byteLength']
    require(start >= 0 and end <= document['buffers'][0]['byteLength'], 'Buffer view outside binary')
    offset = start + accessor.get('byteOffset', 0)
    stride = view.get('byteStride', dimension * width)
    require(accessor['count'] > 0 and stride >= dimension * width, 'Invalid accessor layout')
    require(offset >= start and offset + (accessor['count'] - 1) * stride + dimension * width <= end,
            'Accessor outside view')
    rows = [struct.unpack_from('<' + code * dimension, binary, offset + row * stride)
            for row in range(accessor['count'])]
    require(all(math.isfinite(value) for row in rows for value in row), 'Nonfinite geometry')
    if accessor['componentType'] == 5126:
        require(not accessor.get('normalized', False), 'Normalized float accessor')
    for label, operation in [('min', min), ('max', max)]:
        if label in accessor:
            observed = [operation(row[axis] for row in rows) for axis in range(dimension)]
            require(all(abs(a - b) <= 1e-5 for a, b in zip(observed, accessor[label])),
                    f'Incorrect accessor {label}')
    return rows


def subtract(a, b):
    return tuple(x - y for x, y in zip(a, b))


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def dot(a, b):
    return sum(x * y for x, y in zip(a, b))


def inspect_bytes(data):
    document, binary = decode_glb(data)
    require(not document.get('skins') and not document.get('animations'), 'Animated or skinned model')
    require(set(document.get('extensionsRequired', [])) <= {'KHR_materials_unlit'}, 'Unsupported required extension')
    require(len(document['nodes']) == 1 and len(document['meshes']) == 1, 'Expected one complete model')
    require(document['scenes'][document['scene']]['nodes'] == [0], 'Unexpected scene nodes')
    node = document['nodes'][0]
    require(node['mesh'] == 0 and not set(node) & {'skin', 'rotation', 'scale', 'matrix', 'children'},
            'Unsupported pilot node transform')
    translation = node.get('translation', [0, 0, 0])
    require(len(translation) == 3 and all(math.isfinite(v) for v in translation), 'Nonfinite translation')
    images = []
    for image in document['images']:
        require('uri' not in image and image['mimeType'] == 'image/png', 'Texture must be embedded PNG')
        view = document['bufferViews'][image['bufferView']]
        start = view.get('byteOffset', 0)
        content = binary[start:start + view['byteLength']]
        texture = Image.open(BytesIO(content))
        texture.load()
        require(max(texture.size) <= 512, 'Oversized pilot texture')
        require(texture.convert('RGBA').getextrema()[3] == (255, 255), 'Nonopaque pilot texture')
        images.append({'width': texture.width, 'height': texture.height, 'bytes': len(content),
                       'sha256': hashlib.sha256(content).hexdigest()})
    materials = document['materials']
    require(bool(materials), 'Missing materials')
    for material in materials:
        require(material.get('alphaMode', 'OPAQUE') == 'OPAQUE', 'Nonopaque pilot material')
        require(not set(material) & {'normalTexture', 'occlusionTexture', 'emissiveTexture', 'emissiveFactor'},
                'Unsupported visual dependency')
        pbr = material['pbrMetallicRoughness']
        require(set(pbr) <= {'baseColorTexture', 'baseColorFactor'}, 'Unsupported PBR dependency')
        require('baseColorTexture' in pbr, 'Missing base texture')
        texture = document['textures'][pbr['baseColorTexture']['index']]
        require(0 <= texture['source'] < len(images), 'Invalid texture source')
    mesh = document['meshes'][0]
    require('weights' not in mesh, 'Morph weights')
    primitives = []
    all_positions = []
    for primitive in mesh['primitives']:
        require(primitive.get('mode', 4) == 4 and 'targets' not in primitive, 'Nontriangle or morph primitive')
        attributes = primitive['attributes']
        require(set(attributes) == {'POSITION', 'NORMAL', 'TEXCOORD_0', 'COLOR_0'}, 'Missing or unexpected attributes')
        rows = {name: accessor_rows(document, binary, index) for name, index in attributes.items()}
        count = len(rows['POSITION'])
        require(all(len(values) == count for values in rows.values()), 'Mismatched attributes')
        require(all(len(v) == 3 for v in rows['POSITION'] + rows['NORMAL']), 'Wrong position or normal dimensions')
        require(all(len(v) == 2 for v in rows['TEXCOORD_0']), 'Wrong UV dimension')
        require(all(len(v) == 4 for v in rows['COLOR_0']), 'Wrong color dimension')
        require(all(abs(dot(n, n) - 1) <= 1e-5 for n in rows['NORMAL']), 'Unnormalized normals')
        require(all(0 <= value <= 1 for row in rows['TEXCOORD_0'] + rows['COLOR_0'] for value in row),
                'UV or color outside unit range')
        positions = [tuple(point[axis] + translation[axis] for axis in range(3)) for point in rows['POSITION']]
        indices = list(range(count))
        if 'indices' in primitive:
            index_accessor = document['accessors'][primitive['indices']]
            require(index_accessor['componentType'] in (5121, 5123, 5125), 'Noninteger indices')
            indices = [row[0] for row in accessor_rows(document, binary, primitive['indices'])]
        require(len(indices) % 3 == 0 and all(0 <= index < count for index in indices), 'Invalid triangle indices')
        triangles = [tuple(positions[index] for index in indices[start:start + 3])
                     for start in range(0, len(indices), 3)]
        for start, (a, b, c) in enumerate(triangles):
            normal = cross(subtract(b, a), subtract(c, a))
            length = math.sqrt(dot(normal, normal))
            require(length > 1e-8, 'Degenerate triangle')
            require(all(dot(normal, rows['NORMAL'][index]) / length > .9999
                        for index in indices[start * 3:start * 3 + 3]), 'Normal winding mismatch')
        material = materials[primitive['material']]
        primitives.append({'name': material['name'], 'triangles': triangles, 'normals': rows['NORMAL'],
                           'positions': positions, 'uvs': rows['TEXCOORD_0']})
        all_positions.extend(positions)
    bounds = [min(v[axis] for v in all_positions) for axis in range(3)]
    bounds += [max(v[axis] for v in all_positions) for axis in range(3)]
    return {'sha256': hashlib.sha256(data).hexdigest(), 'bytes': len(data), 'bounds': bounds,
            'triangles': sum(len(p['triangles']) for p in primitives), 'materials': [m['name'] for m in materials],
            'images': images, 'primitives': primitives}


def inspect_file(path):
    return inspect_bytes(Path(path).read_bytes())


def ray_z_hits(triangle, x, y):
    a, b, c = triangle
    determinant = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
    if abs(determinant) < 1e-10:
        return None
    u = ((b[1] - c[1]) * (x - c[0]) + (c[0] - b[0]) * (y - c[1])) / determinant
    v = ((c[1] - a[1]) * (x - c[0]) + (a[0] - c[0]) * (y - c[1])) / determinant
    if u < -1e-8 or v < -1e-8 or u + v > 1 + 1e-8:
        return None
    return u * a[2] + v * b[2] + (1 - u - v) * c[2]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('models', nargs='+', type=Path)
    args = parser.parse_args()
    results = []
    for path in args.models:
        result = inspect_file(path)
        result.pop('primitives')
        results.append({'path': str(path), **result})
    print(json.dumps(results, indent=2))


if __name__ == '__main__':
    main()

from collections import defaultdict
from copy import deepcopy
import itertools
import json
import math
import struct

from convert_bw2_door_asset import IDENTITY, compose, multiply, point


def read_glb(data):
    if len(data) < 28 or struct.unpack_from('<III', data) != (0x46546c67, 2, len(data)):
        raise ValueError('Invalid GLB header')
    length, tag = struct.unpack_from('<I4s', data, 12)
    if tag != b'JSON':
        raise ValueError('Invalid GLB JSON chunk')
    document = json.loads(data[20:20 + length])
    size, tag = struct.unpack_from('<I4s', data, 20 + length)
    binary = data[28 + length:]
    if tag != b'BIN\0' or size != len(binary):
        raise ValueError('Invalid GLB binary chunk')
    return document, binary


def write_glb(document, binary):
    encoded = json.dumps(document, separators=(',', ':'), allow_nan=False).encode()
    encoded += b' ' * (-len(encoded) % 4)
    binary = bytes(binary) + b'\0' * (-len(binary) % 4)
    return (struct.pack('<III', 0x46546c67, 2, 28 + len(encoded) + len(binary))
            + struct.pack('<I4s', len(encoded), b'JSON') + encoded
            + struct.pack('<I4s', len(binary), b'BIN\0') + binary)


def accessor_rows(document, binary, index):
    accessor = document['accessors'][index]
    if 'sparse' in accessor:
        raise ValueError('Sparse source accessor is unsupported')
    dimensions = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}
    kinds = {5120: 'b', 5121: 'B', 5122: 'h', 5123: 'H', 5125: 'I', 5126: 'f'}
    width, kind = dimensions[accessor['type']], kinds[accessor['componentType']]
    view = document['bufferViews'][accessor['bufferView']]
    if view['buffer'] != 0:
        raise ValueError('External source buffer is unsupported')
    size = struct.calcsize('<' + kind * width)
    stride = view.get('byteStride', size)
    offset = view.get('byteOffset', 0) + accessor.get('byteOffset', 0)
    if stride < size or offset < 0 or offset + (accessor['count'] - 1) * stride + size > len(binary):
        raise ValueError('Source accessor is outside its buffer')
    rows = [list(struct.unpack_from('<' + kind * width, binary, offset + i * stride))
            for i in range(accessor['count'])]
    if accessor.get('normalized'):
        limits = {5120: 127, 5121: 255, 5122: 32767, 5123: 65535}
        limit = limits[accessor['componentType']]
        rows = [[max(-1, value / limit) for value in row] for row in rows]
    return rows


def inverse(transform):
    rows = [transform[row * 4:(row + 1) * 4] + IDENTITY[row * 4:(row + 1) * 4]
            for row in range(4)]
    for column in range(4):
        pivot = max(range(column, 4), key=lambda row: abs(rows[row][column]))
        if abs(rows[pivot][column]) < 1e-10:
            raise ValueError('Singular source transform')
        rows[column], rows[pivot] = rows[pivot], rows[column]
        scale = rows[column][column]
        rows[column] = [value / scale for value in rows[column]]
        for row in range(4):
            if row != column:
                factor = rows[row][column]
                rows[row] = [a - factor * b for a, b in zip(rows[row], rows[column])]
    return [value for row in rows for value in row[4:]]


def node_local(node):
    if 'matrix' in node:
        return [node['matrix'][column * 4 + row] for row in range(4) for column in range(4)]
    return compose(node.get('translation', [0, 0, 0]), node.get('rotation', [0, 0, 0, 1]),
                   node.get('scale', [1, 1, 1]))


def node_worlds(document):
    result = {}

    def walk(index, parent, trail):
        if index in trail or index in result:
            raise ValueError('Source hierarchy is cyclic or has shared children')
        result[index] = multiply(parent, node_local(document['nodes'][index]))
        for child in document['nodes'][index].get('children', []):
            walk(child, result[index], trail | {index})

    for root in document['scenes'][document.get('scene', 0)]['nodes']:
        walk(root, IDENTITY, set())
    return result


class GlbWriter:
    def __init__(self, document, binary):
        self.document = document
        self.binary = bytearray(binary)

    def rows(self, rows, kind):
        width = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}[kind]
        values = [value for row in rows for value in row]
        if not rows or any(len(row) != width for row in rows) or not all(math.isfinite(value) for value in values):
            raise ValueError('Invalid generated accessor rows')
        data = struct.pack('<' + 'f' * len(values), *values)
        self.binary.extend(b'\0' * (-len(self.binary) % 4))
        view = {'buffer': 0, 'byteOffset': len(self.binary), 'byteLength': len(data)}
        self.binary.extend(data)
        views = self.document.setdefault('bufferViews', [])
        views.append(view)
        accessor = {'bufferView': len(views) - 1, 'componentType': 5126,
                    'count': len(rows), 'type': kind}
        if kind == 'VEC3' or kind == 'SCALAR':
            accessor['min'] = [min(row[index] for row in rows) for index in range(width)]
            accessor['max'] = [max(row[index] for row in rows) for index in range(width)]
        self.document.setdefault('accessors', []).append(accessor)
        return len(self.document['accessors']) - 1

    def finish(self):
        self.document['buffers'] = [{'byteLength': len(self.binary)}]
        return write_glb(self.document, self.binary)


def enrich_rigid_animation(current_glb, source_glb, source_to_current=None, tolerance=0.00003, static_sources=()):
    current, current_binary = read_glb(current_glb)
    source, source_binary = read_glb(source_glb)
    source_to_current = list(source_to_current or IDENTITY)
    if len(source_to_current) != 16 or not all(math.isfinite(value) for value in source_to_current):
        raise ValueError('Invalid source-to-current transform')
    if current.get('skins') or len(current['nodes']) != 1 or node_local(current['nodes'][0]) != IDENTITY:
        raise ValueError('Current asset must have one untransformed rigid mesh')
    if not source.get('animations'):
        raise ValueError('Original source has no joint animation')
    worlds = node_worlds(source)
    source_points = defaultdict(list)

    def bucket(position):
        return tuple(math.floor(value / tolerance) for value in position)

    for node_index, node in enumerate(source['nodes']):
        if 'mesh' not in node or 'skin' not in node:
            continue
        skin = source['skins'][node['skin']]
        for primitive in source['meshes'][node['mesh']]['primitives']:
            attributes = primitive['attributes']
            if not {'POSITION', 'JOINTS_0', 'WEIGHTS_0'} <= attributes.keys():
                raise ValueError('Original animated mesh has no rigid influence data')
            positions = accessor_rows(source, source_binary, attributes['POSITION'])
            joints = accessor_rows(source, source_binary, attributes['JOINTS_0'])
            weights = accessor_rows(source, source_binary, attributes['WEIGHTS_0'])
            indices = [row[0] for row in accessor_rows(source, source_binary, primitive['indices'])] if 'indices' in primitive else range(len(positions))
            for index in set(indices):
                active = [i for i, weight in enumerate(weights[index]) if weight > 1e-6]
                if len(active) != 1 or abs(weights[index][active[0]] - 1) > 1e-5:
                    raise ValueError('Blended skin geometry cannot become rigid nodes')
                joint = skin['joints'][int(joints[index][active[0]])]
                position = point(source_to_current, positions[index])
                source_points[bucket(position)].append((position, joint))
    for static_glb, transform in static_sources:
        static, static_binary = read_glb(static_glb)
        if len(transform) != 16 or not all(math.isfinite(value) for value in transform):
            raise ValueError('Invalid static source alignment')
        for mesh in static['meshes']:
            for primitive in mesh['primitives']:
                positions = accessor_rows(static, static_binary, primitive['attributes']['POSITION'])
                indices = [row[0] for row in accessor_rows(static, static_binary, primitive['indices'])] if 'indices' in primitive else range(len(positions))
                for index in set(indices):
                    position = point(transform, positions[index])
                    source_points[bucket(position)].append((position, -1))
    if not source_points:
        raise ValueError('No original rigid geometry found')
    output = deepcopy(current)
    writer = GlbWriter(output, current_binary)
    output['nodes'] = [{'name': 'Native source alignment', 'matrix': [source_to_current[row * 4 + column]
                                                                     for column in range(4) for row in range(4)],
                        'children': [node + 1 for node in source['scenes'][source.get('scene', 0)]['nodes']]}]
    for node in source['nodes']:
        copy = deepcopy(node)
        copy.pop('mesh', None)
        copy.pop('skin', None)
        if 'children' in copy:
            copy['children'] = [child + 1 for child in copy['children']]
        output['nodes'].append(copy)
    output['scenes'] = [{'nodes': [0]}]
    output['scene'] = 0
    output.pop('skins', None)
    output['meshes'] = []
    matched_vertices, triangle_count, maximum_error = 0, 0, 0
    mesh_groups = defaultdict(list)
    for mesh in current['meshes']:
        for primitive in mesh['primitives']:
            if primitive.get('mode', 4) != 4:
                raise ValueError('Only native triangle geometry is supported')
            attributes = {name: accessor_rows(current, current_binary, index)
                          for name, index in primitive['attributes'].items()}
            if any(len(rows) != len(attributes['POSITION']) for rows in attributes.values()):
                raise ValueError('Current primitive attribute counts disagree')
            indices = [row[0] for row in accessor_rows(current, current_binary, primitive['indices'])] if 'indices' in primitive else list(range(len(attributes['POSITION'])))
            if len(indices) % 3:
                raise ValueError('Invalid current triangle index count')
            bindings = {}
            for index in set(indices):
                position = attributes['POSITION'][index]
                matches = []
                key = bucket(position)
                for delta in itertools.product((-1, 0, 1), repeat=3):
                    for original, joint in source_points.get(tuple(a + b for a, b in zip(key, delta)), []):
                        error = max(abs(a - b) for a, b in zip(original, position))
                        if error <= tolerance:
                            matches.append((joint, error))
                if not matches:
                    raise ValueError('Current geometry cannot be matched to the original rigid model')
                bindings[index] = {joint for joint, _ in matches}
                maximum_error = max(maximum_error, min(error for _, error in matches))
                matched_vertices += 1
            groups = defaultdict(list)
            for start in range(0, len(indices), 3):
                triangle = indices[start:start + 3]
                candidates = set.intersection(*(bindings[index] for index in triangle))
                if len(candidates) != 1:
                    raise ValueError('Triangle has ambiguous or mixed rigid joint influences')
                groups[next(iter(candidates))].extend(triangle)
                triangle_count += 1
            for joint, indices in groups.items():
                world = multiply(source_to_current, worlds[joint]) if joint >= 0 else IDENTITY
                local = inverse(world)
                rows = {name: [attributes[name][index] for index in indices] for name in attributes}
                rows['POSITION'] = [point(local, position) for position in rows['POSITION']]
                if 'NORMAL' in rows:
                    normals = []
                    for normal in rows['NORMAL']:
                        transformed = [sum(world[row * 4 + column] * normal[row] for row in range(3)) for column in range(3)]
                        length = math.sqrt(sum(value * value for value in transformed))
                        if length < 1e-10:
                            raise ValueError('Degenerate current normal')
                        normals.append([value / length for value in transformed])
                    rows['NORMAL'] = normals
                converted = deepcopy(primitive)
                converted.pop('indices', None)
                converted['attributes'] = {name: writer.rows(values, 'VEC' + str(len(values[0])))
                                           for name, values in rows.items()}
                mesh_groups[joint].append(converted)
    for joint, primitives in sorted(mesh_groups.items()):
        output['meshes'].append({'primitives': primitives})
        if joint >= 0:
            output['nodes'][joint + 1]['mesh'] = len(output['meshes']) - 1
        else:
            output['nodes'].append({'name': 'Verified static source geometry', 'mesh': len(output['meshes']) - 1})
            output['scenes'][0]['nodes'].append(len(output['nodes']) - 1)
    output['animations'] = []
    for animation in source['animations']:
        copy = deepcopy(animation)
        for sampler in copy['samplers']:
            if sampler.get('interpolation', 'LINEAR') not in ('LINEAR', 'STEP'):
                raise ValueError('Unsupported joint curve interpolation')
            for key in ('input', 'output'):
                index = sampler[key]
                rows = accessor_rows(source, source_binary, index)
                sampler[key] = writer.rows(rows, source['accessors'][index]['type'])
        for channel in copy['channels']:
            channel['target']['node'] += 1
        output['animations'].append(copy)
    return writer.finish(), {'triangleCount': triangle_count, 'matchedVertices': matched_vertices,
                             'maximumNeutralPositionError': maximum_error,
                             'rigidMeshCount': len(output['meshes']), 'animations': len(output['animations']),
                             'currentBinaryPrefixPreserved': writer.binary[:len(current_binary)] == current_binary,
                             'sourceToCurrent': source_to_current, 'skinsRemoved': True,
                             'verifiedStaticSourceCount': len(static_sources)}

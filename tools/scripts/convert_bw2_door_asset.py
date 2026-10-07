import argparse
import hashlib
from io import BytesIO
import json
import math
from pathlib import Path
import struct
import xml.etree.ElementTree as ET
import zipfile

from PIL import Image


NAMESPACE = {'c': 'http://www.collada.org/2005/11/COLLADASchema'}
ARCHIVE = 'archives/doors/normal-door-1--582036.zip'
ARCHIVE_SHA256 = 'ab900935415b893115f50de6f647c20ce1f554a2bf7be2d3e1b77630e8f2917f'
SOURCE_MEMBERS = {
    'door_normal01.dae': '19fb0aa860ce6114594c22aad3b2eacc648c6b8cb92b0644395f7596f49912f1',
    'door_n_01.png': '64dab2d7238a5e492a8571128616e531691af4a6d3b98c6b3709c77cc05260c9',
}
OUTPUT = 'bw2_normal_door_1.glb'
PROVENANCE = 'bw2_normal_door_1_provenance.json'
IDENTITY = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def one(node, path, label):
    found = node.findall(path, NAMESPACE)
    if len(found) != 1:
        raise ValueError(f'Expected one {label}')
    return found[0]


def numbers(text):
    values = list(map(float, (text or '').split()))
    if not values or not all(math.isfinite(value) for value in values):
        raise ValueError('Source values must be finite and nonempty')
    return values


def matrix(text):
    values = numbers(text)
    if len(values) != 16 or any(abs(values[i] - IDENTITY[i]) > 1e-7 for i in (12, 13, 14, 15)):
        raise ValueError('Only affine 4 by 4 matrices are supported')
    return values


def multiply(a, b):
    return [sum(a[row * 4 + k] * b[k * 4 + col] for k in range(4))
            for row in range(4) for col in range(4)]


def point(transform, position):
    return [sum(transform[row * 4 + col] * position[col] for col in range(3)) + transform[row * 4 + 3]
            for row in range(3)]


def decompose(transform):
    matrix(' '.join(map(str, transform)))
    columns = [[transform[row * 4 + col] for row in range(3)] for col in range(3)]
    scales = [math.sqrt(sum(value * value for value in column)) for column in columns]
    if any(scale < 1e-8 for scale in scales):
        raise ValueError('Singular transforms are unsupported')
    columns = [[value / scales[i] for value in column] for i, column in enumerate(columns)]
    if any(abs(sum(columns[a][i] * columns[b][i] for i in range(3))) > 1e-6
           for a, b in ((0, 1), (0, 2), (1, 2))):
        raise ValueError('Transform shear cannot be represented by glTF TRS')
    a, b, c = columns
    determinant = a[0] * (b[1] * c[2] - b[2] * c[1]) - b[0] * (a[1] * c[2] - a[2] * c[1]) + c[0] * (a[1] * b[2] - a[2] * b[1])
    if determinant < 0:
        raise ValueError('Transform reflection is unsupported')
    r = [columns[col][row] for row in range(3) for col in range(3)]
    trace = r[0] + r[4] + r[8]
    if trace > 0:
        s = math.sqrt(trace + 1) * 2
        rotation = [(r[7] - r[5]) / s, (r[2] - r[6]) / s, (r[3] - r[1]) / s, s / 4]
    elif r[0] > r[4] and r[0] > r[8]:
        s = math.sqrt(1 + r[0] - r[4] - r[8]) * 2
        rotation = [s / 4, (r[1] + r[3]) / s, (r[2] + r[6]) / s, (r[7] - r[5]) / s]
    elif r[4] > r[8]:
        s = math.sqrt(1 + r[4] - r[0] - r[8]) * 2
        rotation = [(r[1] + r[3]) / s, s / 4, (r[5] + r[7]) / s, (r[2] - r[6]) / s]
    else:
        s = math.sqrt(1 + r[8] - r[0] - r[4]) * 2
        rotation = [(r[2] + r[6]) / s, (r[5] + r[7]) / s, s / 4, (r[3] - r[1]) / s]
    length = math.sqrt(sum(value * value for value in rotation))
    return [transform[3], transform[7], transform[11]], [value / length for value in rotation], scales


def compose(translation, rotation, scale):
    length = math.sqrt(sum(value * value for value in rotation))
    x, y, z, w = [value / length for value in rotation]
    r = [1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w),
         2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w),
         2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]
    return [r[row * 3 + col] * scale[col] if col < 3 else translation[row]
            for row in range(3) for col in range(4)] + [0, 0, 0, 1]


def slerp(a, b, amount):
    a = [value / math.sqrt(sum(v * v for v in a)) for value in a]
    b = [value / math.sqrt(sum(v * v for v in b)) for value in b]
    dot = sum(x * y for x, y in zip(a, b))
    if dot < 0:
        b, dot = [-value for value in b], -dot
    if dot > 0.9995:
        result = [(1 - amount) * x + amount * y for x, y in zip(a, b)]
    else:
        angle = math.acos(max(-1, min(1, dot)))
        result = [(math.sin((1 - amount) * angle) * x + math.sin(amount * angle) * y) / math.sin(angle)
                  for x, y in zip(a, b)]
    length = math.sqrt(sum(value * value for value in result))
    return [value / length for value in result]


def float32(values):
    try:
        result = list(struct.unpack('<' + 'f' * len(values), struct.pack('<' + 'f' * len(values), *values)))
    except (OverflowError, struct.error) as error:
        raise ValueError('Source values exceed the finite float32 profile') from error
    if not all(math.isfinite(value) for value in result):
        raise ValueError('Source values exceed the finite float32 profile')
    return result


def source_rows(source, width, names=False):
    array = one(source, 'c:Name_array' if names else 'c:float_array', 'source array')
    values = (array.text or '').split() if names else numbers(array.text)
    accessor = one(source, 'c:technique_common/c:accessor', 'source accessor')
    if (int(array.get('count')) != len(values) or int(accessor.get('stride', '1')) != width
            or int(accessor.get('offset', '0')) != 0 or int(accessor.get('count')) * width != len(values)
            or accessor.get('source') != '#' + array.get('id')):
        raise ValueError('Unsupported source accessor layout')
    return [values[start:start + width] for start in range(0, len(values), width)]


def inputs(node):
    entries = node.findall('c:input', NAMESPACE)
    result = {entry.get('semantic'): entry for entry in entries}
    if len(entries) != len(result):
        raise ValueError('Duplicate source input semantic')
    return result


def convert_dae(data, texture_members):
    root = ET.fromstring(data)
    if root.tag != '{' + NAMESPACE['c'] + '}COLLADA' or root.get('version') != '1.4.1':
        raise ValueError('Only COLLADA 1.4.1 is supported')
    allowed_libraries = {'asset', 'library_images', 'library_materials', 'library_effects', 'library_geometries',
                         'library_controllers', 'library_animations', 'library_animation_clips', 'library_visual_scenes', 'scene'}
    if len(root) != len(allowed_libraries) or {node.tag for node in root} != {'{' + NAMESPACE['c'] + '}' + tag for tag in allowed_libraries}:
        raise ValueError('Unsupported source libraries or duplicate library blocks')
    up = root.find('c:asset/c:up_axis', NAMESPACE)
    unit = root.find('c:asset/c:unit', NAMESPACE)
    if (up is not None and up.text != 'Y_UP') or (unit is not None and float(unit.get('meter', '1')) != 1):
        raise ValueError('Only the native Y_UP source coordinate system is supported')
    by_id = {node.get('id'): node for node in root.iter() if node.get('id')}
    if len(by_id) != sum(1 for node in root.iter() if node.get('id')):
        raise ValueError('Duplicate source identifiers')

    def reference(value):
        if not value or not value.startswith('#') or value[1:] not in by_id:
            raise ValueError('Unresolved local source reference')
        return by_id[value[1:]]

    scene_ref = one(root, 'c:scene/c:instance_visual_scene', 'visual scene instance')
    scene = one(root, 'c:library_visual_scenes/c:visual_scene', 'visual scene')
    if reference(scene_ref.get('url')) is not scene:
        raise ValueError('Unexpected active visual scene')
    nodes = scene.findall('c:node', NAMESPACE)
    if len(nodes) != 2 or scene.findall('.//c:node/c:node', NAMESPACE):
        raise ValueError('Only one root joint and one controller node are supported')
    joint = next((node for node in nodes if node.get('type') == 'JOINT'), None)
    controller_node = next((node for node in nodes if node is not joint), None)
    if joint is None or len(joint) != 1 or joint[0].tag != '{' + NAMESPACE['c'] + '}matrix' or joint[0].get('sid') != 'transform':
        raise ValueError('Only a root joint with one transform matrix is supported')
    if len(controller_node) != 1 or controller_node[0].tag != '{' + NAMESPACE['c'] + '}instance_controller':
        raise ValueError('Transforms on the controller node are unsupported')
    bind_pose = matrix(joint[0].text)
    bind_trs = decompose(bind_pose)
    instance = controller_node[0]
    if one(instance, 'c:skeleton', 'skeleton').text != '#' + joint.get('id'):
        raise ValueError('Unexpected skeleton reference')
    controller = one(root, 'c:library_controllers/c:controller', 'skin controller')
    if len(controller) != 1:
        raise ValueError('Unsupported source controller contents')
    if reference(instance.get('url')) is not controller:
        raise ValueError('Unexpected controller reference')
    skin = one(controller, 'c:skin', 'skin')
    shape = skin.find('c:bind_shape_matrix', NAMESPACE)
    bind_shape = matrix(shape.text) if shape is not None else IDENTITY
    decompose(bind_shape)
    joints = inputs(one(skin, 'c:joints', 'skin joint inputs'))
    if set(joints) != {'JOINT', 'INV_BIND_MATRIX'}:
        raise ValueError('Unsupported skin joint inputs')
    names = source_rows(reference(joints['JOINT'].get('source')), 1, names=True)
    if names != [[joint.get('sid')]] or joint.get('id') != joint.get('sid'):
        raise ValueError('Only one matching rigid joint is supported')
    inverses = source_rows(reference(joints['INV_BIND_MATRIX'].get('source')), 16)
    if len(inverses) != 1:
        raise ValueError('Only one inverse bind matrix is supported')
    inverse_bind = matrix(' '.join(map(str, inverses[0])))
    decompose(inverse_bind)
    if any(abs(a - b) > 1e-6 for a, b in zip(multiply(bind_pose, inverse_bind), IDENTITY)):
        raise ValueError('Joint bind pose and inverse bind matrix disagree')
    rigid_transform = multiply(inverse_bind, bind_shape)
    decompose(rigid_transform)
    mesh = one(root, 'c:library_geometries/c:geometry/c:mesh', 'geometry mesh')
    if reference(skin.get('source')) is not one(root, 'c:library_geometries/c:geometry', 'geometry'):
        raise ValueError('Unexpected skin geometry')
    vertex_node = one(mesh, 'c:vertices', 'vertex inputs')
    vertex_inputs = inputs(vertex_node)
    if set(vertex_inputs) != {'POSITION', 'TEXCOORD', 'NORMAL', 'COLOR'}:
        raise ValueError('Unsupported vertex inputs')
    values = {semantic: source_rows(reference(entry.get('source')), 2 if semantic == 'TEXCOORD' else 3)
              for semantic, entry in vertex_inputs.items()}
    count = len(values['POSITION'])
    if not 3 <= count <= 65535 or any(len(rows) != count for rows in values.values()):
        raise ValueError('Vertex attribute counts disagree or exceed the profile')
    if any(abs(value - 1) > 1e-6 for row in values['COLOR'] for value in row):
        raise ValueError('Nonwhite vertex shading cannot be discarded')
    weights = one(skin, 'c:vertex_weights', 'vertex weights')
    weight_inputs = inputs(weights)
    if (set(weight_inputs) != {'JOINT', 'WEIGHT'} or weight_inputs['JOINT'].get('offset') != '0'
            or weight_inputs['WEIGHT'].get('offset') != '1' or weight_inputs['JOINT'].get('source') != joints['JOINT'].get('source')):
        raise ValueError('Unsupported rigid weight layout')
    counts = list(map(int, one(weights, 'c:vcount', 'weight counts').text.split()))
    if int(weights.get('count')) != count or counts != [1] * count:
        raise ValueError('Every vertex must have exactly one bone influence')
    weight_values = source_rows(reference(weight_inputs['WEIGHT'].get('source')), 1)
    weight_indices = list(map(int, one(weights, 'c:v', 'weight indices').text.split()))
    if len(weight_indices) != count * 2:
        raise ValueError('Rigid weight indices disagree with vertex count')
    for joint_index, weight_index in zip(weight_indices[::2], weight_indices[1::2]):
        if joint_index != 0 or not 0 <= weight_index < len(weight_values) or abs(weight_values[weight_index][0] - 1) > 1e-6:
            raise ValueError('Only joint zero with weight one is supported')
    poly = one(mesh, 'c:polylist', 'polygon list')
    if any(node.tag not in {'{' + NAMESPACE['c'] + '}' + tag for tag in ('source', 'vertices', 'polylist')} for node in mesh):
        raise ValueError('Unsupported geometry primitive')
    poly_inputs = inputs(poly)
    if (set(poly_inputs) != {'VERTEX'} or poly_inputs['VERTEX'].get('source') != '#' + vertex_node.get('id')
            or poly_inputs['VERTEX'].get('offset') != '0'):
        raise ValueError('Only shared native vertex indices are supported')
    polygon_counts = list(map(int, one(poly, 'c:vcount', 'polygon counts').text.split()))
    polygon_indices = list(map(int, one(poly, 'c:p', 'polygon indices').text.split()))
    if (int(poly.get('count')) != len(polygon_counts) or any(c not in (3, 4) for c in polygon_counts)
            or sum(polygon_counts) != len(polygon_indices) or any(not 0 <= i < count for i in polygon_indices)):
        raise ValueError('Only native triangles and convex quads are supported')
    indices, cursor = [], 0
    for length in polygon_counts:
        polygon = polygon_indices[cursor:cursor + length]
        cursor += length
        if len(set(polygon)) != length:
            raise ValueError('Source polygon is degenerate')
        points = [values['POSITION'][index] for index in polygon]
        crosses = []
        for i in range(length):
            a, b, c = points[i - 1], points[i], points[(i + 1) % length]
            u, v = [b[k] - a[k] for k in range(3)], [c[k] - b[k] for k in range(3)]
            cross = [u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0]]
            magnitude = math.sqrt(sum(value * value for value in cross))
            if magnitude < 1e-8:
                raise ValueError('Source polygon is degenerate')
            crosses.append([value / magnitude for value in cross])
        if any(sum(a * b for a, b in zip(crosses[0], cross)) < 1 - 1e-6 for cross in crosses[1:]):
            raise ValueError('Only planar convex source polygons are supported')
        for i in range(1, length - 1):
            indices.extend((polygon[0], polygon[i], polygon[i + 1]))
    material_instance = one(instance, 'c:bind_material/c:technique_common/c:instance_material', 'material binding')
    if material_instance.get('symbol') != poly.get('material'):
        raise ValueError('Polygon material binding disagrees')
    material = one(root, 'c:library_materials/c:material', 'material')
    if reference(material_instance.get('target')) is not material:
        raise ValueError('Unexpected material reference')
    effect = reference(one(material, 'c:instance_effect', 'material effect').get('url'))
    profile = one(effect, 'c:profile_COMMON', 'material profile')
    if profile.findall('.//c:transparent', NAMESPACE) or profile.findall('.//c:transparency', NAMESPACE):
        raise ValueError('Source transparent materials are unsupported')
    texture = one(profile, 'c:technique/c:phong/c:diffuse/c:texture', 'diffuse texture')
    binding = one(material_instance, 'c:bind_vertex_input', 'texture coordinate binding')
    if (binding.get('semantic') != texture.get('texcoord') or binding.get('input_semantic') != 'TEXCOORD'
            or binding.get('input_set', '0') != '0'):
        raise ValueError('Unsupported texture coordinate binding')
    parameters = {entry.get('sid'): entry for entry in profile.findall('c:newparam', NAMESPACE)}
    if texture.get('texture') not in parameters:
        raise ValueError('Unresolved material texture sampler')
    sampler = one(parameters[texture.get('texture')], 'c:sampler2D', 'texture sampler')
    if any((sampler.find('c:' + name, NAMESPACE) is not None
            and sampler.find('c:' + name, NAMESPACE).text != expected)
           for name, expected in (('wrap_s', 'CLAMP'), ('wrap_t', 'CLAMP'), ('minfilter', 'NEAREST'), ('magfilter', 'NEAREST'), ('mipfilter', 'NEAREST'))):
        raise ValueError('Only the native nearest clamp texture sampler is supported')
    surface_id = one(sampler, 'c:source', 'sampler surface').text
    if surface_id not in parameters:
        raise ValueError('Unresolved material image surface')
    image_id = one(parameters[surface_id], 'c:surface/c:init_from', 'surface image').text
    image = reference('#' + image_id)
    texture_name = one(image, 'c:init_from', 'image member').text
    if texture_name not in texture_members or Path(texture_name).name != texture_name or not texture_name.endswith('.png'):
        raise ValueError('Expected an embedded local PNG texture member')
    texture_data = texture_members[texture_name]
    with Image.open(BytesIO(texture_data)) as image_data:
        if image_data.width > 4096 or image_data.height > 4096 or image_data.convert('RGBA').getextrema()[3] != (255, 255):
            raise ValueError('The source door texture must be opaque and at most 4096 pixels per axis')
    positions = [float32(point(rigid_transform, position)) for position in values['POSITION']]
    normals = []
    _, rigid_rotation, rigid_scale = decompose(rigid_transform)
    normal_transform = compose([0, 0, 0], rigid_rotation, [1 / value for value in rigid_scale])
    for normal in values['NORMAL']:
        transformed = point(normal_transform, normal)
        length = math.sqrt(sum(value * value for value in transformed))
        if length < 1e-8:
            raise ValueError('Source normals must be nonzero')
        normals.append([value / length for value in transformed])
    animations = root.findall('c:library_animations/c:animation', NAMESPACE)
    clips = root.findall('c:library_animation_clips/c:animation_clip', NAMESPACE)
    if len(animations) != 2 or len(clips) != 2 or {clip.get('name') for clip in clips} != {'door_op', 'door_cl'}:
        raise ValueError('Expected exactly the original door_op and door_cl clips')
    parsed_clips = []
    for clip in clips:
        animation = reference(one(clip, 'c:instance_animation', 'clip animation').get('url'))
        if animation not in animations or animation.findall('c:animation', NAMESPACE):
            raise ValueError('Nested or external source animations are unsupported')
        channel = one(animation, 'c:channel', 'matrix channel')
        if channel.get('target') != joint.get('id') + '/transform':
            raise ValueError('Only the original joint matrix channel is supported')
        animation_sampler = reference(channel.get('source'))
        sampler_inputs = inputs(animation_sampler)
        if set(sampler_inputs) != {'INPUT', 'OUTPUT', 'INTERPOLATION'}:
            raise ValueError('Unsupported animation sampler inputs')
        times = [row[0] for row in source_rows(reference(sampler_inputs['INPUT'].get('source')), 1)]
        matrices = source_rows(reference(sampler_inputs['OUTPUT'].get('source')), 16)
        interpolation = source_rows(reference(sampler_inputs['INTERPOLATION'].get('source')), 1, names=True)
        if len(times) < 2 or len(matrices) != len(times) or interpolation != [['LINEAR']] * len(times):
            raise ValueError('Only complete LINEAR matrix animation keys are supported')
        if (times[0] != 0 or any(b <= a for a, b in zip(times, times[1:])) or float(clip.get('start', '0')) != 0
                or abs(float(clip.get('end')) - times[-1]) > 1e-9):
            raise ValueError('Source key times and clip boundaries disagree')
        stored_times = float32(times)
        if any(b <= a for a, b in zip(stored_times, stored_times[1:])):
            raise ValueError('Source float32 key times collapse or cease to increase')
        keys = []
        for transform in matrices:
            trs = decompose(transform)
            if keys and sum(a * b for a, b in zip(keys[-1][1], trs[1])) < 0:
                trs = trs[0], [-value for value in trs[1]], trs[2]
            keys.append(tuple(float32(component) for component in trs))
        key_error, midpoint_error = 0, 0
        for i, trs in enumerate(keys):
            actual_transform = compose(*trs)
            for position in positions:
                key_error = max(key_error, math.dist(point(actual_transform, position), point(matrices[i], position)) / 16)
            if i:
                previous = keys[i - 1]
                midpoint_trs = ([sum(pair) / 2 for pair in zip(previous[0], trs[0])], slerp(previous[1], trs[1], 0.5),
                                [sum(pair) / 2 for pair in zip(previous[2], trs[2])])
                original_midpoint = [sum(pair) / 2 for pair in zip(matrices[i - 1], matrices[i])]
                converted_midpoint = compose(*midpoint_trs)
                for position in positions:
                    midpoint_error = max(midpoint_error, math.dist(point(converted_midpoint, position), point(original_midpoint, position)) / 16)
        parsed_clips.append({'name': clip.get('name'), 'sourceAnimationId': animation.get('id'), 'target': channel.get('target'),
                             'keyTimesSeconds': times, 'durationSeconds': times[-1], 'keyCount': len(times),
                             'maxKeyPositionErrorMapUnits': key_error, 'maxMidpointPositionErrorMapUnits': midpoint_error,
                             'keys': keys})
    if len({clip['sourceAnimationId'] for clip in parsed_clips}) != 2:
        raise ValueError('Each original clip must reference its own source animation')
    binary = bytearray()
    document = {
        'asset': {'version': '2.0', 'generator': 'PokeMap BW2 rigid door converter'},
        'extensionsUsed': ['KHR_materials_unlit'], 'extensionsRequired': ['KHR_materials_unlit'],
        'scene': 0, 'scenes': [{'nodes': [0]}],
        'nodes': [{'name': 'native_units_to_map_cells', 'scale': [1 / 16] * 3, 'children': [1]},
                  {'name': joint.get('id'), 'mesh': 0, 'translation': bind_trs[0], 'rotation': bind_trs[1], 'scale': bind_trs[2]}],
        'meshes': [{'name': 'door_normal01', 'primitives': []}], 'buffers': [], 'bufferViews': [], 'accessors': [],
        'materials': [{'name': texture_name, 'alphaMode': 'OPAQUE', 'extensions': {'KHR_materials_unlit': {}},
                       'pbrMetallicRoughness': {'baseColorTexture': {'index': 0}, 'baseColorFactor': [1, 1, 1, 1]}}],
        'samplers': [{'magFilter': 9728, 'minFilter': 9728, 'wrapS': 33071, 'wrapT': 33071}],
        'textures': [{'source': 0, 'sampler': 0}], 'images': [], 'animations': [],
    }

    def view(data, target=None):
        binary.extend(b'\0' * (-len(binary) % 4))
        entry = {'buffer': 0, 'byteOffset': len(binary), 'byteLength': len(data)}
        if target is not None:
            entry['target'] = target
        binary.extend(data)
        document['bufferViews'].append(entry)
        return len(document['bufferViews']) - 1

    def accessor(rows, kind, component=5126, target=None):
        flattened = [value for row in rows for value in row]
        entry = {'bufferView': view(struct.pack('<' + ('f' if component == 5126 else 'H') * len(flattened), *flattened), target),
                 'componentType': component, 'count': len(rows), 'type': kind}
        if kind in ('SCALAR', 'VEC3') and component == 5126:
            entry['min'] = [min(row[i] for row in rows) for i in range(len(rows[0]))]
            entry['max'] = [max(row[i] for row in rows) for i in range(len(rows[0]))]
        document['accessors'].append(entry)
        return len(document['accessors']) - 1

    document['images'].append({'bufferView': view(texture_data), 'mimeType': 'image/png'})
    document['meshes'][0]['primitives'].append({
        'mode': 4, 'material': 0, 'indices': accessor([[value] for value in indices], 'SCALAR', 5123, 34963),
        'attributes': {'POSITION': accessor(positions, 'VEC3', target=34962), 'NORMAL': accessor(normals, 'VEC3', target=34962),
                       'TEXCOORD_0': accessor([[u, 1 - v] for u, v in values['TEXCOORD']], 'VEC2', target=34962)},
    })
    for clip in parsed_clips:
        animation = {'name': clip['name'], 'channels': [], 'samplers': []}
        time_accessor = accessor([[value] for value in clip['keyTimesSeconds']], 'SCALAR')
        for i, path in enumerate(('translation', 'rotation', 'scale')):
            animation['samplers'].append({'input': time_accessor, 'output': accessor([key[i] for key in clip['keys']], 'VEC4' if i == 1 else 'VEC3'),
                                          'interpolation': 'LINEAR'})
            animation['channels'].append({'sampler': i, 'target': {'node': 1, 'path': path}})
        document['animations'].append(animation)
    document['buffers'] = [{'byteLength': len(binary)}]
    encoded = json.dumps(document, separators=(',', ':'), allow_nan=False).encode()
    encoded += b' ' * (-len(encoded) % 4)
    binary.extend(b'\0' * (-len(binary) % 4))
    length = 28 + len(encoded) + len(binary)
    glb = (struct.pack('<III', 0x46546C67, 2, length) + struct.pack('<II', len(encoded), 0x4E4F534A) + encoded
           + struct.pack('<II', len(binary), 0x004E4942) + binary)
    receipt = {
        'conversion': 'Root scale 1/16; native Y_UP axes and origin preserved; rigid mesh = inverse_bind_matrix * bind_shape_matrix * source_position; animated root joint retains source bind pose',
        'matrixStorage': 'COLLADA row-major values; translation at indices 3, 7, 11',
        'animationInterpolation': 'Original matrix keys decomposed exactly to TRS; glTF LINEAR uses quaternion slerp between keys and differs from COLLADA element-wise matrix interpolation',
        'uvConversion': '(u, 1-v), preserving the original embedded PNG bytes',
        'materialConversion': 'Opaque unlit diffuse texture, original nearest clamp sampler and white vertex color',
        'vertexCount': count, 'triangleCount': len(indices) // 3, 'textures': [texture_name],
        'bindPoseMatrix': bind_pose, 'inverseBindMatrix': inverse_bind, 'bindShapeMatrix': bind_shape,
        'clips': [{key: value for key, value in clip.items() if key != 'keys'} for clip in parsed_clips],
    }
    return glb, receipt


def extract(source_root, output_root):
    source_root = source_root.resolve(strict=True)
    output_root = output_root.resolve()
    if (source_root == output_root or source_root in output_root.parents or output_root in source_root.parents):
        raise ValueError('Output must be outside the read-only source directory')
    for filename in (OUTPUT, PROVENANCE):
        destination = output_root / filename
        if destination.is_symlink():
            raise ValueError(f'Output must not contain a symlink: {filename}')
        if destination.exists() and destination.stat().st_nlink != 1:
            raise ValueError(f'Output must not contain a hardlink: {filename}')
    archive_data = (source_root / ARCHIVE).read_bytes()
    if sha256(archive_data) != ARCHIVE_SHA256:
        raise ValueError('Unexpected source archive digest')
    with zipfile.ZipFile(BytesIO(archive_data)) as archive:
        if set(archive.namelist()) != set(SOURCE_MEMBERS) or len(archive.namelist()) != len(SOURCE_MEMBERS):
            raise ValueError('Unexpected source archive members')
        members = {name: archive.read(name) for name in SOURCE_MEMBERS}
    for name, expected in SOURCE_MEMBERS.items():
        if sha256(members[name]) != expected:
            raise ValueError(f'Unexpected source member digest: {name}')
    glb, conversion = convert_dae(members['door_normal01.dae'], {'door_n_01.png': members['door_n_01.png']})
    receipt = {
        'schemaVersion': 1, 'assetId': '582036',
        'sourceUrl': 'https://models.spriters-resource.com/ds_dsi/pokemonblack2white2/asset/582036/',
        'archive': ARCHIVE, 'archiveSha256': sha256(archive_data),
        'sourceMembers': [{'member': name, 'sha256': sha256(data)} for name, data in members.items()],
        'output': OUTPUT, 'outputSha256': sha256(glb), **conversion,
    }
    output_root.mkdir(parents=True, exist_ok=True)
    (output_root / OUTPUT).write_bytes(glb)
    (output_root / PROVENANCE).write_text(json.dumps(receipt, ensure_ascii=False, indent=2, allow_nan=False) + '\n')
    return receipt


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source-root', type=Path, required=True)
    parser.add_argument('--output-root', type=Path, required=True)
    args = parser.parse_args()
    receipt = extract(args.source_root, args.output_root)
    print(json.dumps({'output': str(args.output_root.resolve()), 'sha256': receipt['outputSha256'], 'clips': receipt['clips']}))


if __name__ == '__main__':
    main()

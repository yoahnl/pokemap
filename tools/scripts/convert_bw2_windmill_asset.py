import argparse
from collections import defaultdict
from io import BytesIO
import json
import math
from pathlib import Path
import struct
import xml.etree.ElementTree as ET
import zipfile

from PIL import Image

from convert_bw2_door_asset import NAMESPACE, IDENTITY, compose, decompose, float32, inputs, matrix, multiply, one, point, sha256, slerp, source_rows
from convert_bw2_village_assets import cross, material_texture, triangulate

ARCHIVE = 'archives/map-objects/windmill-with-reflection--582888.zip'
ARCHIVE_SHA256 = 'd038d4ff29f84f2b06e1429111e1c888085baa921918fd960ca7544b7e637b68'
OUTPUT = 'bw2_windmill.glb'
PROVENANCE = 'bw2_windmill_provenance.json'
MEMBERS = {'c7_windmill_01.dae', 'c7wind1.png', 'c7wind2.png', 'c7wind3.png', 'h_kage.png'}


def convert_dae(data, texture_members):
    root = ET.fromstring(data)
    if root.tag != '{' + NAMESPACE['c'] + '}COLLADA' or root.get('version') != '1.4.1':
        raise ValueError('Only native COLLADA 1.4.1 is supported')
    if root.findtext('c:asset/c:up_axis', default='Y_UP', namespaces=NAMESPACE) != 'Y_UP':
        raise ValueError('Only native Y_UP is supported')
    by_id = {node.get('id'): node for node in root.iter() if node.get('id')}
    if len(by_id) != sum(node.get('id') is not None for node in root.iter()):
        raise ValueError('Duplicate source identifiers')

    def reference(value):
        if not value or not value.startswith('#') or value[1:] not in by_id:
            raise ValueError('Unresolved local source reference')
        return by_id[value[1:]]

    scene = one(root, 'c:library_visual_scenes/c:visual_scene', 'visual scene')
    if reference(one(root, 'c:scene/c:instance_visual_scene', 'scene reference').get('url')) is not scene:
        raise ValueError('Unexpected active scene')
    nodes = scene.findall('c:node', NAMESPACE)
    if len(nodes) != 2:
        raise ValueError('Expected native root joint and controller')
    joint_root = by_id.get('joint0')
    if joint_root not in nodes or joint_root.get('type') != 'JOINT':
        raise ValueError('Expected native joint0 root')
    children = joint_root.findall('c:node', NAMESPACE)
    if [child.get('id') for child in children] != ['joint1', 'joint2', 'joint3']:
        raise ValueError('Expected three native rigid joint children')
    joint_nodes = [joint_root, *children]
    bind_poses = []
    for index, node in enumerate(joint_nodes):
        if node.get('type') != 'JOINT' or node.get('sid') != f'joint{index}' or (index and node.findall('c:node', NAMESPACE)):
            raise ValueError('Unsupported native joint hierarchy')
        transform = one(node, 'c:matrix', 'joint matrix')
        if transform.get('sid') != 'transform' or any(c.tag not in {'{' + NAMESPACE['c'] + '}matrix', '{' + NAMESPACE['c'] + '}node'} for c in node):
            raise ValueError('Only native joint transform matrices are supported')
        bind_poses.append(matrix(transform.text))
        decompose(bind_poses[-1])
    if bind_poses[0] != IDENTITY:
        raise ValueError('Native root bind pose must be identity')
    controller_node = next(node for node in nodes if node is not joint_root)
    if len(controller_node) != 1 or controller_node[0].tag != '{' + NAMESPACE['c'] + '}instance_controller':
        raise ValueError('Transforms on the controller node are unsupported')
    instance = controller_node[0]
    if one(instance, 'c:skeleton', 'skeleton').text != '#joint0':
        raise ValueError('Unexpected native skeleton')
    controller = one(root, 'c:library_controllers/c:controller', 'controller')
    if reference(instance.get('url')) is not controller or len(controller) != 1:
        raise ValueError('Unexpected source controller')
    skin = one(controller, 'c:skin', 'skin')
    shape = skin.find('c:bind_shape_matrix', NAMESPACE)
    bind_shape = matrix(shape.text) if shape is not None else IDENTITY
    decompose(bind_shape)
    joint_inputs = inputs(one(skin, 'c:joints', 'joint inputs'))
    if set(joint_inputs) != {'JOINT', 'INV_BIND_MATRIX'}:
        raise ValueError('Unsupported joint inputs')
    names = source_rows(reference(joint_inputs['JOINT'].get('source')), 1, names=True)
    if names != [[f'joint{i}'] for i in range(4)]:
        raise ValueError('Unexpected native joint names')
    inverse_binds = source_rows(reference(joint_inputs['INV_BIND_MATRIX'].get('source')), 16)
    if len(inverse_binds) != 4:
        raise ValueError('Expected four inverse binds')
    for bind, inverse in zip(bind_poses, inverse_binds):
        decompose(inverse)
        if max(abs(a - b) for a, b in zip(multiply(bind, inverse), IDENTITY)) > 1e-6:
            raise ValueError('Inverse bind disagrees with native bind pose')
    weights = one(skin, 'c:vertex_weights', 'weights')
    weight_inputs = inputs(weights)
    if set(weight_inputs) != {'JOINT', 'WEIGHT'} or weight_inputs['JOINT'].get('offset') != '0' or weight_inputs['WEIGHT'].get('offset') != '1':
        raise ValueError('Unsupported weight input layout')
    counts = list(map(int, one(weights, 'c:vcount', 'weight counts').text.split()))
    if counts != [1] * int(weights.get('count')):
        raise ValueError('Every vertex requires exactly one influence')
    weight_values = source_rows(reference(weight_inputs['WEIGHT'].get('source')), 1)
    values = list(map(int, one(weights, 'c:v', 'weight indices').text.split()))
    if len(values) != len(counts) * 2:
        raise ValueError('Weight count mismatch')
    vertex_joints = values[::2]
    if any(joint not in (1, 2, 3) or not 0 <= weight < len(weight_values) or abs(weight_values[weight][0] - 1) > 1e-6 for joint, weight in zip(vertex_joints, values[1::2])):
        raise ValueError('Every vertex requires a native joint with weight one')
    geometry = one(root, 'c:library_geometries/c:geometry', 'geometry')
    if reference(skin.get('source')) is not geometry:
        raise ValueError('Unexpected skin geometry')
    mesh = one(geometry, 'c:mesh', 'mesh')
    vertices = one(mesh, 'c:vertices', 'vertices')
    vertex_inputs = inputs(vertices)
    if set(vertex_inputs) != {'POSITION', 'NORMAL', 'COLOR', 'TEXCOORD'}:
        raise ValueError('Unsupported vertex inputs')
    attributes = {semantic: source_rows(reference(entry.get('source')), 2 if semantic == 'TEXCOORD' else 3) for semantic, entry in vertex_inputs.items()}
    if any(len(rows) != len(counts) for rows in attributes.values()) or any(not 0 <= color <= 1 for row in attributes['COLOR'] for color in row):
        raise ValueError('Vertex attributes require matching normalized colors')
    bindings = {entry.get('symbol'): entry for entry in instance.findall('c:bind_material/c:technique_common/c:instance_material', NAMESPACE)}
    surfaces = defaultdict(list)
    textures, texture_names, wraps, selected = {}, {}, {}, []
    omitted_reflection = omitted_shadow = source_triangles = 0
    reflected_static = defaultdict(int)
    local_positions = {i: [point(multiply(inverse_binds[i], bind_shape), row) for row in attributes['POSITION']] for i in (1, 2, 3)}
    for primitive in mesh.findall('c:polylist', NAMESPACE):
        primitive_inputs = inputs(primitive)
        if set(primitive_inputs) != {'VERTEX'} or primitive_inputs['VERTEX'].get('source') != '#' + vertices.get('id') or primitive_inputs['VERTEX'].get('offset') != '0':
            raise ValueError('Only shared native vertex indices are supported')
        lengths = list(map(int, one(primitive, 'c:vcount', 'polygon counts').text.split()))
        indices = list(map(int, one(primitive, 'c:p', 'polygon indices').text.split()))
        if len(lengths) != int(primitive.get('count')) or sum(lengths) != len(indices) or any(n not in (3, 4) for n in lengths) or any(not 0 <= i < len(counts) for i in indices):
            raise ValueError('Invalid native triangles or quads')
        binding = bindings[primitive.get('material')]
        material = reference(binding.get('target'))
        texture, sampler_wraps = material_texture(by_id, material)
        if texture not in texture_members or any(wrap not in ('CLAMP', 'WRAP') for wrap in sampler_wraps):
            raise ValueError('Only original local PNG and CLAMP/WRAP are supported')
        effect = reference(one(material, 'c:instance_effect', 'material effect').get('url'))
        profile = one(effect, 'c:profile_COMMON', 'material profile')
        diffuse = one(profile, 'c:technique/c:phong/c:diffuse/c:texture', 'diffuse')
        uv_binding = one(binding, 'c:bind_vertex_input', 'texture coordinate binding')
        if uv_binding.get('semantic') != diffuse.get('texcoord') or uv_binding.get('input_semantic') != 'TEXCOORD' or uv_binding.get('input_set', '0') != '0':
            raise ValueError('Unsupported texture coordinate binding')
        transparent = profile.find('.//c:transparent', NAMESPACE)
        if transparent is not None and (len(transparent) != 1 or transparent[0].tag != '{' + NAMESPACE['c'] + '}texture' or transparent[0].get('texture') != diffuse.get('texture')):
            raise ValueError('Unsupported translucent material')
        if profile.find('.//c:transparency', NAMESPACE) is not None:
            raise ValueError('Unsupported translucent material factor')
        cursor = 0
        kept = 0
        for length in lengths:
            polygon = indices[cursor:cursor + length]
            cursor += length
            joints = {vertex_joints[index] for index in polygon}
            if len(joints) != 1:
                raise ValueError('Unsupported cross-joint polygon')
            joint = joints.pop()
            source_triangles += length - 2
            if joint == 2:
                omitted_reflection += length - 2
                continue
            if material.get('id') in ('material3', 'material5'):
                if joint != 3 or any(attributes['POSITION'][index][1] >= 0 for index in polygon):
                    raise ValueError('Native reflected building must remain below ground')
                reflected_static[material.get('id')] += length - 2
                continue
            if texture == 'h_kage.png':
                omitted_shadow += length - 2
                continue
            png = texture_members[texture]
            with Image.open(BytesIO(png)) as image:
                if image.width > 4096 or image.height > 4096 or set(image.convert('RGBA').getchannel('A').get_flattened_data()) - {0, 255}:
                    raise ValueError('Native visible textures must not be translucent')
            material_key = material.get('id')
            textures[material_key], texture_names[material_key], wraps[material_key] = png, texture, sampler_wraps
            rows = [local_positions[joint][index] + [attributes['TEXCOORD'][index][0], 1 - attributes['TEXCOORD'][index][1]] + attributes['COLOR'][index] for index in polygon]
            for triangle in triangulate(rows, validate=True):
                surfaces[(joint, material_key)].extend(triangle)
                kept += 1
        if kept:
            selected.append({'material': material.get('id'), 'texture': texture, 'triangleCount': kept})
    if source_triangles != 256 or omitted_reflection != 70 or dict(reflected_static) != {'material3': 12, 'material5': 28} or omitted_shadow != 8 or sum(len(rows) // 3 for rows in surfaces.values()) != 138:
        raise ValueError('Unexpected native windmill geometry or omissions')
    binary = bytearray()
    document = {'asset': {'version': '2.0', 'generator': 'Avelune BW2 rigid windmill converter'}, 'extensionsUsed': ['KHR_materials_unlit'], 'extensionsRequired': ['KHR_materials_unlit'], 'scene': 0, 'scenes': [{'nodes': [0]}], 'nodes': [{'name': 'native_units_to_map_cells', 'scale': [1 / 16] * 3, 'children': [1]}], 'meshes': [], 'materials': [], 'textures': [], 'samplers': [], 'images': [], 'animations': [], 'buffers': [], 'bufferViews': [], 'accessors': []}
    node_indices = {0: 1, 1: 2, 3: 3}
    for joint in (0, 1, 3):
        translation, rotation, scale = decompose(bind_poses[joint])
        node = {'name': f'joint{joint}', 'translation': translation, 'rotation': rotation, 'scale': scale}
        if joint == 0:
            node['children'] = [2, 3]
        else:
            node['mesh'] = len(document['meshes'])
            document['meshes'].append({'name': f'joint{joint}', 'primitives': []})
        document['nodes'].append(node)

    def view(data, target=None):
        binary.extend(b'\0' * (-len(binary) % 4))
        entry = {'buffer': 0, 'byteOffset': len(binary), 'byteLength': len(data)}
        if target is not None:
            entry['target'] = target
        binary.extend(data)
        document['bufferViews'].append(entry)
        return len(document['bufferViews']) - 1

    def accessor(rows, kind, target=None):
        rows = [float32(row) for row in rows]
        flattened = [value for row in rows for value in row]
        entry = {'bufferView': view(struct.pack('<' + 'f' * len(flattened), *flattened), target), 'componentType': 5126, 'count': len(rows), 'type': kind}
        if kind in ('SCALAR', 'VEC3'):
            entry['min'] = [min(row[i] for row in rows) for i in range(len(rows[0]))]
            entry['max'] = [max(row[i] for row in rows) for i in range(len(rows[0]))]
        document['accessors'].append(entry)
        return len(document['accessors']) - 1

    material_indices = {}
    for material_key, png in sorted(textures.items()):
        texture = texture_names[material_key]
        index = len(document['materials'])
        material_indices[material_key] = index
        alpha = Image.open(BytesIO(png)).convert('RGBA').getextrema()[3]
        material = {'name': texture, 'alphaMode': 'OPAQUE' if alpha == (255, 255) else 'MASK', 'extensions': {'KHR_materials_unlit': {}}, 'pbrMetallicRoughness': {'baseColorTexture': {'index': index}, 'baseColorFactor': [1, 1, 1, 1]}}
        if material['alphaMode'] == 'MASK':
            material['alphaCutoff'] = .5
        document['materials'].append(material)
        document['images'].append({'bufferView': view(png), 'mimeType': 'image/png'})
        document['textures'].append({'source': index, 'sampler': index})
        document['samplers'].append({'magFilter': 9728, 'minFilter': 9728, 'wrapS': {'CLAMP': 33071, 'WRAP': 10497}[wraps[material_key][0]], 'wrapT': {'CLAMP': 33071, 'WRAP': 10497}[wraps[material_key][1]]})
    for (joint, texture), rows in sorted(surfaces.items()):
        normals = []
        for start in range(0, len(rows), 3):
            normal = cross(*rows[start:start + 3])
            length = math.sqrt(sum(value * value for value in normal))
            normals.extend([value / length for value in normal] for _ in range(3))
        primitive = {'mode': 4, 'material': material_indices[texture], 'attributes': {'POSITION': accessor([row[:3] for row in rows], 'VEC3', 34962), 'NORMAL': accessor(normals, 'VEC3', 34962), 'TEXCOORD_0': accessor([row[3:5] for row in rows], 'VEC2', 34962), 'COLOR_0': accessor([row[5:8] + [1] for row in rows], 'VEC4', 34962)}}
        document['meshes'][document['nodes'][node_indices[joint]]['mesh']]['primitives'].append(primitive)
    clip = one(root, 'c:library_animation_clips/c:animation_clip', 'native clip')
    if clip.get('name') != 'c7_windmill_01' or float(clip.get('start', '0')) != 0 or abs(float(clip.get('end')) - 119 / 60) > 1e-9:
        raise ValueError('Unexpected native windmill clip')
    animation_nodes = root.findall('c:library_animations/c:animation', NAMESPACE)
    clip_instances = clip.findall('c:instance_animation', NAMESPACE)
    if len(animation_nodes) != 4 or len(clip_instances) != 4 or {reference(entry.get('url')).get('id') for entry in clip_instances} != {a.get('id') for a in animation_nodes}:
        raise ValueError('Expected four original matrix animation channels')
    animation = {'name': clip.get('name'), 'channels': [], 'samplers': []}
    channel_receipts = []
    targets = set()
    for source_animation in animation_nodes:
        channel = one(source_animation, 'c:channel', 'matrix channel')
        target = channel.get('target')
        if target not in {f'joint{i}/transform' for i in range(4)} or target in targets:
            raise ValueError('Unsupported or duplicate native matrix channel')
        targets.add(target)
        joint = int(target[5])
        sampler_inputs = inputs(reference(channel.get('source')))
        if set(sampler_inputs) != {'INPUT', 'OUTPUT', 'INTERPOLATION'}:
            raise ValueError('Unsupported animation sampler')
        times = [row[0] for row in source_rows(reference(sampler_inputs['INPUT'].get('source')), 1)]
        matrices = source_rows(reference(sampler_inputs['OUTPUT'].get('source')), 16)
        interpolation = source_rows(reference(sampler_inputs['INTERPOLATION'].get('source')), 1, names=True)
        if len(times) != 120 or len(matrices) != 120 or interpolation != [['LINEAR']] * 120 or any(abs(time - i / 60) > 1e-9 for i, time in enumerate(times)):
            raise ValueError('Expected original 120 LINEAR keys at 60 Hz')
        keys = []
        for transform in matrices:
            trs = decompose(transform)
            if keys and sum(a * b for a, b in zip(keys[-1][1], trs[1])) < 0:
                trs = trs[0], [-value for value in trs[1]], trs[2]
            keys.append(tuple(float32(component) for component in trs))
        if joint == 2:
            continue
        key_error = midpoint_error = 0
        positions = [row[:3] for (j, _), rows in surfaces.items() if j == joint for row in rows]
        for i, trs in enumerate(keys):
            for position in positions:
                key_error = max(key_error, math.dist(point(compose(*trs), position), point(matrices[i], position)) / 16)
            if i:
                previous = keys[i - 1]
                midpoint = compose([sum(pair) / 2 for pair in zip(previous[0], trs[0])], slerp(previous[1], trs[1], .5), [sum(pair) / 2 for pair in zip(previous[2], trs[2])])
                original = [sum(pair) / 2 for pair in zip(matrices[i - 1], matrices[i])]
                for position in positions:
                    midpoint_error = max(midpoint_error, math.dist(point(midpoint, position), point(original, position)) / 16)
        time_accessor = accessor([[time] for time in times], 'SCALAR')
        for index, path in enumerate(('translation', 'rotation', 'scale')):
            animation['channels'].append({'sampler': len(animation['samplers']), 'target': {'node': node_indices[joint], 'path': path}})
            animation['samplers'].append({'input': time_accessor, 'output': accessor([key[index] for key in keys], 'VEC4' if index == 1 else 'VEC3'), 'interpolation': 'LINEAR'})
        channel_receipts.append({'sourceAnimationId': source_animation.get('id'), 'sourceTarget': target, 'keyCount': len(times), 'durationSeconds': times[-1], 'maxKeyPositionErrorMapUnits': key_error, 'maxMidpointPositionErrorMapUnits': midpoint_error})
    document['animations'].append(animation)
    document['buffers'] = [{'byteLength': len(binary)}]
    encoded = json.dumps(document, separators=(',', ':'), allow_nan=False).encode()
    encoded += b' ' * (-len(encoded) % 4)
    binary.extend(b'\0' * (-len(binary) % 4))
    glb = struct.pack('<III', 0x46546C67, 2, 28 + len(encoded) + len(binary)) + struct.pack('<II', len(encoded), 0x4E4F534A) + encoded + struct.pack('<II', len(binary), 0x004E4942) + binary
    bounds = {}
    for label, joints in (('visible', (1, 3)), ('building', (3,))):
        points = [point(bind_poses[joint], row[:3]) for (joint, _), rows in surfaces.items() if joint in joints for row in rows]
        bounds[label] = [min(p[axis] for p in points) / 16 for axis in range(3)] + [max(p[axis] for p in points) / 16 for axis in range(3)]
    return glb, {'triangleCount': 138, 'sourceTriangleCount': 256, 'scaleNativeUnitsToCells': 1 / 16, 'boundsCells': bounds, 'pivot': [0, 0, 0], 'clips': [{'index': 0, 'name': 'c7_windmill_01', 'durationSeconds': 119 / 60, 'keyCount': 120}], 'channels': channel_receipts, 'sourceBindPoses': bind_poses, 'sourceInverseBinds': inverse_binds, 'sourceBindShape': bind_shape, 'retainedMaterials': selected, 'omitted': [{'joint': 'joint2', 'reason': 'Native below-ground reflection', 'triangleCount': omitted_reflection}, {'material': 'material3', 'reason': 'Native below-ground roof reflection', 'triangleCount': reflected_static['material3']}, {'material': 'material5', 'reason': 'Native below-ground building reflection', 'triangleCount': reflected_static['material5']}, {'texture': 'h_kage.png', 'reason': 'Baked translucent shadow', 'triangleCount': omitted_shadow}], 'omittedAnimationChannels': ['anim0-joint2'], 'conversion': 'Rigid meshes split by native joint; inverse_bind * bind_shape positions; original Y_UP and origin; root scale 1/16; no skin', 'animationInterpolation': 'Original 60 Hz matrix keys decomposed to positive TRS; glTF LINEAR quaternion slerp midpoint deviation reported per retained channel', 'materialConversion': 'Original embedded PNG bytes, OPAQUE or MASK alphaCutoff .5, nearest CLAMP/WRAP, unlit, native vertex colors; backface culling', 'uvConversion': '(u,1-v)'}


def convert(source_root, output_root):
    source_root = source_root.resolve(strict=True)
    output_root = output_root.resolve()
    if source_root == output_root or source_root in output_root.parents or output_root in source_root.parents:
        raise ValueError('Output must be outside the read-only source root')
    for filename in (OUTPUT, PROVENANCE):
        destination = output_root / filename
        if destination.is_symlink() or (destination.exists() and destination.stat().st_nlink != 1):
            raise ValueError('Output must not alias another file')
    data = (source_root / ARCHIVE).read_bytes()
    if sha256(data) != ARCHIVE_SHA256:
        raise ValueError('Unexpected authoritative archive digest')
    with zipfile.ZipFile(BytesIO(data)) as archive:
        if len(archive.namelist()) != len(MEMBERS) or set(archive.namelist()) != MEMBERS:
            raise ValueError('Unexpected source archive members')
        members = {name: archive.read(name) for name in sorted(MEMBERS)}
    glb, receipt = convert_dae(members['c7_windmill_01.dae'], {name: value for name, value in members.items() if name.endswith('.png')})
    provenance = {'schemaVersion': 1, 'assetId': '582888', 'source': {'url': 'https://models.spriters-resource.com/ds_dsi/pokemonblack2white2/asset/582888/', 'archive': ARCHIVE, 'archiveSha256': sha256(data), 'members': [{'member': name, 'sha256': sha256(value)} for name, value in members.items()]}, 'output': OUTPUT, 'outputSha256': sha256(glb), **receipt}
    output_root.mkdir(parents=True, exist_ok=True)
    (output_root / OUTPUT).write_bytes(glb)
    (output_root / PROVENANCE).write_text(json.dumps(provenance, ensure_ascii=False, indent=2, allow_nan=False) + '\n')
    return provenance


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source-root', type=Path, required=True)
    parser.add_argument('--output-root', type=Path, required=True)
    args = parser.parse_args()
    receipt = convert(args.source_root, args.output_root)
    print(json.dumps({'output': str(args.output_root.resolve()), 'sha256': receipt['outputSha256'], 'boundsCells': receipt['boundsCells'], 'clips': receipt['clips']}))


if __name__ == '__main__':
    main()

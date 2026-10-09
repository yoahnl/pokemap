from collections import defaultdict
from dataclasses import dataclass
from hashlib import sha256 as digest
from io import BytesIO
import math
from pathlib import Path
from urllib.parse import unquote
import xml.etree.ElementTree as ET
import zipfile

from PIL import Image

from convert_bw2_door_asset import IDENTITY, NAMESPACE, inputs, matrix, multiply, point, source_rows

def sha256(data):
    return digest(data).hexdigest()

def local_reference(by_id, value):
    if not value or not value.startswith('#') or value[1:] not in by_id:
        raise ValueError('Unresolved local COLLADA reference')
    return by_id[value[1:]]


def material_texture(by_id, material):
    effect = local_reference(by_id, material.find('c:instance_effect', NAMESPACE).get('url'))
    profile = effect.find('c:profile_COMMON', NAMESPACE)
    texture = profile.find('.//c:diffuse/c:texture', NAMESPACE)
    if texture is None:
        raise ValueError('Every source material must have a diffuse texture')
    parameters = {node.get('sid'): node for node in profile.findall('c:newparam', NAMESPACE)}
    sampler = parameters[texture.get('texture')].find('c:sampler2D', NAMESPACE)
    source = sampler.findtext('c:source', namespaces=NAMESPACE)
    image_id = parameters[source].findtext('c:surface/c:init_from', namespaces=NAMESPACE)
    image = by_id[image_id]
    name = unquote(image.findtext('c:init_from', namespaces=NAMESPACE))
    if Path(name).name != name or not name.lower().endswith('.png'):
        raise ValueError('Only local archive PNG members are supported')
    wraps = [sampler.findtext('c:' + axis, default='WRAP', namespaces=NAMESPACE) for axis in ('wrap_s', 'wrap_t')]
    if any(value not in ('WRAP', 'CLAMP', 'MIRROR') for value in wraps):
        raise ValueError('Unsupported source texture wrap')
    return name, wraps


def cross(a, b, c):
    u, v = [b[i] - a[i] for i in range(3)], [c[i] - a[i] for i in range(3)]
    return [u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0]]


def triangulate(vertices, validate=False):
    if validate:
        distinct = []
        for vertex in vertices:
            if not distinct or any(abs(a - b) > 1e-8 for a, b in zip(distinct[-1][:3], vertex[:3])):
                distinct.append(vertex)
        if len(distinct) > 1 and all(abs(a - b) < 1e-8 for a, b in zip(distinct[0][:3], distinct[-1][:3])):
            distinct.pop()
        if len(distinct) < 3:
            return
        normals = [cross(distinct[i - 1], distinct[i], distinct[(i + 1) % len(distinct)]) for i in range(len(distinct))]
        lengths = [math.sqrt(sum(n * n for n in normal)) for normal in normals]
        if any(length < 1e-8 for length in lengths) or any(sum(a * b for a, b in zip(normals[0], normal)) / lengths[0] / length <= 0 for normal, length in zip(normals[1:], lengths[1:])):
            raise ValueError('Only convex source polygons are supported')
    for i in range(1, len(vertices) - 1):
        triangle = [vertices[0], vertices[i], vertices[i + 1]]
        if math.sqrt(sum(n * n for n in cross(*triangle))) > 1e-9:
            yield triangle


def read_archive(source_root, record, expected):
    path = source_root / record['local_path']
    data = path.read_bytes()
    if sha256(data) != expected:
        raise ValueError(f'Source archive digest mismatch: {record["name"]}')
    with zipfile.ZipFile(BytesIO(data)) as archive:
        members = archive.namelist()
        if len(set(members)) != len(members) or any(Path(name).name != name for name in members):
            raise ValueError('Only archives with unique flat members are supported')
        dae = [name for name in members if name.lower().endswith('.dae')]
        if len(dae) != 1:
            raise ValueError('Expected one COLLADA model per archive')
        textures = {name: archive.read(name) for name in members if name.lower().endswith('.png')}
        return archive.read(dae[0]), textures, {'assetId': record['id'], 'title': record['name'], 'archive': record['local_path'], 'archiveSha256': expected, 'sourceUrl': record['page_url'], 'member': dae[0], 'memberSha256': sha256(archive.read(dae[0])), 'textures': [{'member': name, 'sha256': sha256(value)} for name, value in sorted(textures.items())]}


@dataclass
class Surface:
    group: str
    geometry: str
    material: str
    texture: str
    wraps: list
    opacity: float
    triangles: list
    terrain: bool

    @property
    def vertices(self):
        return [vertex for triangle in self.triangles for vertex in triangle]

    @property
    def bounds(self):
        values = self.vertices
        return tuple(min(v[a] for v in values) for a in range(3)) + tuple(max(v[a] for v in values) for a in range(3))


def local_transform(node):
    result = list(IDENTITY)
    for child in node:
        kind = child.tag.rsplit('}', 1)[-1]
        if kind not in ('matrix', 'translate', 'scale', 'rotate'):
            continue
        values = [float(value) for value in child.text.split()]
        if kind == 'matrix':
            value = matrix(child.text)
        elif kind == 'translate':
            value = list(IDENTITY)
            value[3], value[7], value[11] = values
        elif kind == 'scale':
            value = list(IDENTITY)
            value[0], value[5], value[10] = values
        else:
            x, y, z, angle = values
            length = math.sqrt(x * x + y * y + z * z)
            if length < 1e-12:
                raise ValueError('Zero rotation axis')
            x, y, z = x / length, y / length, z / length
            c, s = math.cos(math.radians(angle)), math.sin(math.radians(angle))
            t = 1 - c
            value = [t*x*x+c, t*x*y-s*z, t*x*z+s*y, 0,
                     t*x*y+s*z, t*y*y+c, t*y*z-s*x, 0,
                     t*x*z-s*y, t*y*z+s*x, t*z*z+c, 0,
                     0, 0, 0, 1]
        result = multiply(result, value)
    return result


def material_opacity(by_id, material):
    effect = by_id[material.find('c:instance_effect', NAMESPACE).get('url')[1:]]
    transparent = effect.find('.//c:transparent', NAMESPACE)
    multiplier = effect.findtext('.//c:transparency/c:float', default='1', namespaces=NAMESPACE)
    if transparent is None:
        return max(0.0, min(1.0, float(multiplier)))
    color = transparent.findtext('c:color', namespaces=NAMESPACE)
    if color is None:
        return 1.0
    values = list(map(float, color.split()))
    mode = transparent.get('opaque', 'A_ONE')
    if mode == 'A_ONE':
        return max(0.0, min(1.0, values[3] * float(multiplier)))
    if mode == 'RGB_ZERO':
        return max(0.0, min(1.0, 1 - sum(values[:3]) / 3 * float(multiplier)))
    raise ValueError(f'Unsupported source opacity mode {mode}')


def source_scene(source_root, record):
    data, textures, provenance = read_archive(source_root, record, record['sha256'])
    tree = ET.fromstring(data)
    if tree.findall('.//c:animation', NAMESPACE):
        raise ValueError('Animated source needs a separate converter')
    if tree.findtext('c:asset/c:up_axis', default='Y_UP', namespaces=NAMESPACE) != 'Y_UP':
        raise ValueError('Only Y_UP sources are supported')
    by_id = {node.get('id'): node for node in tree.iter() if node.get('id')}
    if len(by_id) != sum(node.get('id') is not None for node in tree.iter()):
        raise ValueError('Duplicate source identifiers')
    scene = by_id[tree.find('c:scene/c:instance_visual_scene', NAMESPACE).get('url')[1:]]
    drawables, node_world, node_trails = [], {}, {}

    def walk(node, parent, trail):
        transform = multiply(parent, local_transform(node))
        trail = trail + [node]
        node_world[id(node)] = transform
        node_trails[id(node)] = trail
        for instance in list(node.findall('c:instance_geometry', NAMESPACE)) + list(node.findall('c:instance_controller', NAMESPACE)):
            referenced = by_id[instance.get('url')[1:]]
            skin = referenced.find('c:skin', NAMESPACE)
            geometry = by_id[skin.get('source')[1:]] if skin is not None else referenced
            bindings = {binding.get('symbol'): by_id[binding.get('target')[1:]] for binding in instance.findall('c:bind_material/c:technique_common/c:instance_material', NAMESPACE)}
            names = [part.get('id', part.get('name', '')) for part in trail]
            object_name = next((name for name in names if name.startswith('object_')), None)
            terrain = object_name is None and any(name.startswith('terrain') for name in names)
            group = (names[0] + '/' + object_name) if object_name else names[0] + '/' + (names[1] if len(names) > 1 else names[0])
            drawables.append((geometry, bindings, transform, group, terrain, node, skin))
        for child in node.findall('c:node', NAMESPACE):
            walk(child, transform, trail)

    for node in scene.findall('c:node', NAMESPACE):
        walk(node, IDENTITY, [])
    pose_errors = []
    for geometry, bindings, transform, group, terrain, node, skin in drawables:
        if skin is None:
            continue
        joints = {entry.get('semantic'): by_id[entry.get('source')[1:]] for entry in skin.findall('c:joints/c:input', NAMESPACE)}
        if not {'JOINT', 'INV_BIND_MATRIX'}.issubset(joints):
            raise ValueError('Skin has no bind pose')
        names = joints['JOINT'].findtext('c:Name_array', namespaces=NAMESPACE) or joints['JOINT'].findtext('c:IDREF_array', namespaces=NAMESPACE)
        inverses = source_rows(joints['INV_BIND_MATRIX'], 16)
        shape_text = skin.findtext('c:bind_shape_matrix', namespaces=NAMESPACE)
        shape = matrix(shape_text) if shape_text else IDENTITY
        ancestry = node_trails[id(node)]
        scope = next((ancestor for ancestor in ancestry if ancestor.get('id', '').startswith('object_')), ancestry[1] if len(ancestry) > 1 else ancestry[0])
        for joint_name, inverse in zip(names.split(), inverses):
            candidates = [part for part in scope.iter() if part.tag.endswith('}node') and joint_name in (part.get('sid'), part.get('name'), part.get('id'))]
            if not candidates:
                candidates = [part for part in ancestry[0].iter() if part.tag.endswith('}node') and joint_name in (part.get('sid'), part.get('name'), part.get('id'))]
            if not candidates:
                raise ValueError(f'Unresolved neutral-pose joint {joint_name} in {group}')
            errors = [max(abs(a-b) for a, b in zip(multiply(multiply(node_world[id(part)], matrix(' '.join(map(str, inverse)))), shape), transform)) for part in candidates]
            error = min(errors)
            if error > 0.001:
                raise ValueError(f'Non-neutral skin {geometry.get("id")} {joint_name}: {error}')
            pose_errors.append(error)
    surfaces, omitted = [], []
    image_cache = {}
    for geometry, bindings, transform, group, terrain, _, _ in drawables:
        mesh = geometry.find('c:mesh', NAMESPACE)
        vertices_node = mesh.find('c:vertices', NAMESPACE)
        for primitive in list(mesh.findall('c:polylist', NAMESPACE)) + list(mesh.findall('c:triangles', NAMESPACE)):
            material = bindings[primitive.get('material')]
            try:
                texture, wraps = material_texture(by_id, material)
            except ValueError as error:
                if 'diffuse texture' not in str(error):
                    raise
                effect = by_id[material.find('c:instance_effect', NAMESPACE).get('url')[1:]]
                text = effect.findtext('.//c:diffuse/c:color', default='1 1 1 1', namespaces=NAMESPACE)
                rgba = tuple(round(max(0, min(1, x)) * 255) for x in map(float, text.split()))
                texture, wraps = material.get('id') + '.png', ['CLAMP', 'CLAMP']
                output = BytesIO()
                Image.new('RGBA', (1, 1), rgba).save(output, format='PNG')
                textures[texture] = output.getvalue()
            if texture not in textures:
                raise ValueError(f'Missing archive texture {texture}')
            material_name = material.get('name', material.get('id'))
            if any(word in material_name.lower() for word in ('kage', 'shadow', 'h_test')):
                omitted.append({'geometry': geometry.get('id'), 'material': material_name, 'reason': 'Baked source shadow'})
                continue
            image_cache.setdefault(texture, Image.open(BytesIO(textures[texture])).convert('RGBA'))
            if max(image_cache[texture].size) > 4096:
                raise ValueError('Oversized source texture')
            vertex_inputs, primitive_inputs = inputs(vertices_node), inputs(primitive)
            sources, offsets = {}, {}
            for semantic, entry in vertex_inputs.items():
                if semantic == 'NORMAL':
                    continue
                sources[semantic] = source_rows(by_id[entry.get('source')[1:]], 2 if semantic == 'TEXCOORD' else 3)
                offsets[semantic] = int(primitive_inputs['VERTEX'].get('offset', '0'))
            for semantic, entry in primitive_inputs.items():
                if semantic == 'VERTEX':
                    continue
                if semantic == 'NORMAL':
                    continue
                if semantic not in ('POSITION', 'NORMAL', 'TEXCOORD', 'COLOR'):
                    raise ValueError(f'Unsupported primitive semantic {semantic}')
                sources[semantic] = source_rows(by_id[entry.get('source')[1:]], 2 if semantic == 'TEXCOORD' else 3)
                offsets[semantic] = int(entry.get('offset', '0'))
            if 'POSITION' not in sources:
                raise ValueError('Missing source positions')
            stride = max(int(entry.get('offset', '0')) for entry in primitive_inputs.values()) + 1
            counts_text = primitive.findtext('c:vcount', namespaces=NAMESPACE)
            counts = list(map(int, counts_text.split())) if counts_text else [3] * int(primitive.get('count'))
            indices = list(map(int, primitive.findtext('c:p', namespaces=NAMESPACE).split()))
            if sum(counts) * stride != len(indices):
                raise ValueError('Source index count mismatch')
            triangles, cursor = [], 0
            for count in counts:
                polygon = []
                for index in range(count):
                    values = {}
                    for semantic, rows in sources.items():
                        key = indices[cursor + index * stride + offsets[semantic]]
                        if not 0 <= key < len(rows):
                            raise ValueError('Source vertex index out of range')
                        values[semantic] = rows[key]
                    position = [v / 16 for v in point(transform, values['POSITION'])]
                    uv = values.get('TEXCOORD', [0, 0])
                    color = values.get('COLOR', [1, 1, 1])
                    polygon.append(position + [uv[0], 1 - uv[1]] + color)
                cursor += count * stride
                triangles.extend(triangulate(polygon, validate=False))
            if triangles:
                surfaces.append(Surface(group, geometry.get('id'), material_name, texture, wraps, material_opacity(by_id, material), triangles, terrain))
    provenance.update({'neutralPoseMatrixMaxError': max(pose_errors, default=0), 'drawableCount': len(drawables), 'omitted': omitted})
    return surfaces, textures, provenance

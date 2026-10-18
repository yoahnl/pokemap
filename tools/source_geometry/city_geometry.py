from collections import defaultdict
from dataclasses import dataclass
from io import BytesIO
import json
import math
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

from PIL import Image

from source_policy import matches, require_source_policy

REPOSITORY = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPOSITORY / 'tools/scripts'))
from convert_rigid_skin_asset import IDENTITY, NAMESPACE, matrix, multiply, point, source_rows
from convert_source_asset_pack import inputs, material_texture, read_archive, triangulate


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


def source_scene(source_root, record, archive_reader=None, *, policy):
    require_source_policy(policy)
    scene_policy = policy["scene"]
    data, textures, provenance = (archive_reader or read_archive)(source_root, record, record['sha256'])
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
            object_name = next((name for name in names if any(name.startswith(prefix) for prefix in scene_policy['objectNodePrefixes'])), None)
            terrain = object_name is None and any(any(name.startswith(prefix) for prefix in scene_policy['terrainNodePrefixes']) for name in names)
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
        scope = next((ancestor for ancestor in ancestry if any(ancestor.get('id', '').startswith(prefix) for prefix in scene_policy['objectNodePrefixes'])), ancestry[1] if len(ancestry) > 1 else ancestry[0])
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
            if matches(material_name, scene_policy['omittedMaterials']):
                omitted.append({'geometry': geometry.get('id'), 'material': material_name, 'reason': 'Explicit source material omission'})
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
                    position = [v / scene_policy['unitsPerCell'] for v in point(transform, values['POSITION'])]
                    uv = values.get('TEXCOORD', [0, 0])
                    color = values.get('COLOR', [1, 1, 1])
                    polygon.append(position + [uv[0], 1 - uv[1]] + color)
                cursor += count * stride
                triangles.extend(triangulate(polygon, validate=False))
            if triangles:
                surfaces.append(Surface(group, geometry.get('id'), material_name, texture, wraps, material_opacity(by_id, material), triangles, terrain))
    provenance.update({'neutralPoseMatrixMaxError': max(pose_errors, default=0), 'drawableCount': len(drawables), 'omitted': omitted})
    return surfaces, textures, provenance


def projected_area(triangle):
    a, b, c = triangle
    return abs((b[0]-a[0])*(c[2]-a[2]) - (b[2]-a[2])*(c[0]-a[0])) / 2


def barycentric(x, z, triangle):
    a, b, c = triangle
    determinant = (b[2]-c[2])*(a[0]-c[0]) + (c[0]-b[0])*(a[2]-c[2])
    if abs(determinant) < 1e-10:
        return None
    u = ((b[2]-c[2])*(x-c[0]) + (c[0]-b[0])*(z-c[2])) / determinant
    v = ((c[2]-a[2])*(x-c[0]) + (a[0]-c[0])*(z-c[2])) / determinant
    w = 1-u-v
    return (u, v, w) if min(u, v, w) >= -1e-7 else None


def interpolate(triangle, weights, index):
    return sum(vertex[index] * weight for vertex, weight in zip(triangle, weights))


def sample_texture(image, u, v, wraps):
    def coordinate(value, wrap, size):
        if wrap == 'WRAP':
            value %= 1
        elif wrap == 'MIRROR':
            value %= 2
            value = value if value <= 1 else 2 - value
        else:
            value = max(0, min(1, value))
        return min(size-1, max(0, math.floor(value * size)))
    return image.getpixel((coordinate(u, wraps[0], image.width), coordinate(v, wraps[1], image.height)))


def cell_triangles(surfaces, origin, width, depth):
    result = defaultdict(list)
    for surface in surfaces:
        for triangle in surface.triangles:
            if projected_area(triangle) < 1e-8:
                continue
            xs, zs = [v[0]-origin[0] for v in triangle], [v[2]-origin[2] for v in triangle]
            for z in range(max(0, math.floor(min(zs))), min(depth, math.ceil(max(zs)))):
                for x in range(max(0, math.floor(min(xs))), min(width, math.ceil(max(xs)))):
                    result[x, z].append((surface, triangle))
    return result


def union_rectangles(cells):
    by_row, active, result = defaultdict(list), {}, []
    for x, z in set(cells):
        by_row[z].append(x)
    for z in range(min(by_row, default=0), max(by_row, default=-1)+2):
        xs = sorted(by_row.get(z, []))
        runs = []
        for x in xs:
            if runs and x == runs[-1][1]+1:
                runs[-1] = (runs[-1][0], x)
            else:
                runs.append((x, x))
        for run in list(active):
            if run not in runs:
                start = active.pop(run)
                result.append({'x': run[0], 'z': start, 'width': run[1]-run[0]+1, 'depth': z-start})
        for run in runs:
            active.setdefault(run, z)
    return result


def connected_cells(walkable, levels, start):
    seen, queue = {start}, [start]
    for x, z in queue:
        for other in ((x+1,z), (x-1,z), (x,z+1), (x,z-1)):
            if other in walkable and other not in seen and abs(levels[other]-levels[x,z]) <= 0.01:
                seen.add(other)
                queue.append(other)
    return seen


def source_inventory(surfaces):
    summary = defaultdict(lambda: {'area': 0, 'horizontalArea': 0, 'y': set(), 'groups': set(), 'textures': set()})
    for surface in surfaces:
        if not surface.terrain:
            continue
        item = summary[surface.material]
        item['groups'].add(surface.group)
        item['textures'].add(surface.texture)
        for triangle in surface.triangles:
            area = projected_area(triangle)
            item['area'] += area
            heights = [v[1] for v in triangle]
            if max(heights)-min(heights) < 0.05:
                item['horizontalArea'] += area
                if area > 0.01:
                    item['y'].add(round(heights[0], 3))
    return {key: {**value, 'area': round(value['area'], 2), 'horizontalArea': round(value['horizontalArea'], 2), 'y': sorted(value['y']), 'groups': sorted(value['groups']), 'textures': sorted(value['textures'])} for key, value in summary.items()}

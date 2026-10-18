import argparse
from collections import defaultdict
import csv
from io import BytesIO
import json
import math
import re
import tempfile
from pathlib import Path
import struct
from urllib.parse import unquote
import xml.etree.ElementTree as ET
import zipfile

from PIL import Image

from convert_rigid_skin_asset import IDENTITY, NAMESPACE, inputs, matrix, multiply, point, sha256, source_rows


MAX_TRIANGLES = 60000


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


def clip_polygon(vertices, axis, boundary, keep_greater):
    result = []
    if not vertices:
        return result
    previous = vertices[-1]
    previous_inside = previous[axis] >= boundary - 1e-10 if keep_greater else previous[axis] <= boundary + 1e-10
    for vertex in vertices:
        inside = vertex[axis] >= boundary - 1e-10 if keep_greater else vertex[axis] <= boundary + 1e-10
        if inside != previous_inside:
            denominator = vertex[axis] - previous[axis]
            amount = (boundary - previous[axis]) / denominator
            result.append([a + (b - a) * amount for a, b in zip(previous, vertex)])
        if inside:
            result.append(vertex)
        previous, previous_inside = vertex, inside
    return result


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


def convert_dae(data, texture_members, selections=None, *, omitted_textures=(), units_per_cell=16):
    if type(units_per_cell) not in (int, float) or not math.isfinite(units_per_cell) or not .001 <= units_per_cell <= 65536:
        raise ValueError('Invalid source units per cell')
    root = ET.fromstring(data)
    if root.tag != '{' + NAMESPACE['c'] + '}COLLADA' or root.get('version') != '1.4.1':
        raise ValueError('Only COLLADA 1.4.1 is supported')
    if root.findall('.//c:animation', NAMESPACE):
        raise ValueError('Animated sources require a dedicated animation converter')
    if selections is None and root.findall('.//c:controller', NAMESPACE):
        raise ValueError('Controllers require explicit static geometry selections')
    up = root.findtext('c:asset/c:up_axis', default='Y_UP', namespaces=NAMESPACE)
    if up != 'Y_UP':
        raise ValueError('Only native Y_UP geometry is supported')
    by_id = {node.get('id'): node for node in root.iter() if node.get('id')}
    if len(by_id) != sum(node.get('id') is not None for node in root.iter()):
        raise ValueError('Duplicate source identifiers')
    instances = []
    if selections is None:
        scene = local_reference(by_id, root.find('c:scene/c:instance_visual_scene', NAMESPACE).get('url'))

        def walk(node, parent_transform):
            transform = parent_transform
            for child in node:
                tag = child.tag.rsplit('}', 1)[-1]
                if tag == 'matrix':
                    transform = multiply(transform, matrix(child.text))
                elif tag in ('translate', 'rotate', 'scale', 'lookat', 'skew', 'instance_controller', 'instance_node'):
                    raise ValueError('Unsupported node transform or controller')
            for instance in node.findall('c:instance_geometry', NAMESPACE):
                bindings = {entry.get('symbol'): local_reference(by_id, entry.get('target')) for entry in instance.findall('c:bind_material/c:technique_common/c:instance_material', NAMESPACE)}
                instances.append((local_reference(by_id, instance.get('url')), bindings, transform, None))
            for child in node.findall('c:node', NAMESPACE):
                walk(child, transform)

        for node in scene.findall('c:node', NAMESPACE):
            walk(node, IDENTITY)
    else:
        for selection in selections:
            geometry = by_id[selection['geometry']]
            if geometry.tag != '{' + NAMESPACE['c'] + '}geometry':
                raise ValueError('Static extraction must select a geometry')
            bindings = {symbol: by_id[material_id] for symbol, material_id in selection['materials'].items()}
            instances.append((geometry, bindings, IDENTITY, selection.get('region')))
    surfaces = defaultdict(list)
    textures, samplers, double_sided, omitted, chosen = {}, {}, {}, [], []
    raw_count = shaded_count = 0
    for geometry, bindings, transform, region in instances:
        mesh = geometry.find('c:mesh', NAMESPACE)
        if any(node.tag.rsplit('}', 1)[-1] not in ('source', 'vertices', 'polylist', 'triangles') for node in mesh):
            raise ValueError('Unsupported source geometry primitive')
        vertices_node = mesh.find('c:vertices', NAMESPACE)
        vertex_inputs = inputs(vertices_node)
        primitives = mesh.findall('c:polylist', NAMESPACE) + mesh.findall('c:triangles', NAMESPACE)
        for primitive_index, primitive in enumerate(primitives):
            two_sided = selections is not None and any(selection['geometry'] == geometry.get('id') and selection.get('doubleSided') is True for selection in selections)
            material = bindings[primitive.get('material')]
            texture_name, wraps = material_texture(by_id, material)
            if texture_name not in texture_members:
                raise ValueError(f'Missing texture member: {texture_name}')
            image = Image.open(BytesIO(texture_members[texture_name])).convert('RGBA')
            if max(image.size) > 4096:
                raise ValueError('Texture dimensions exceed the supported budget')
            alphas = {value for value, count in enumerate(image.getchannel('A').histogram()) if count}
            if texture_name in omitted_textures:
                omitted.append({'geometry': geometry.get('id'), 'primitive': primitive_index, 'texture': texture_name, 'reason': 'Source baked translucent ground shadow; excluded from the opaque rendering profile'})
                continue
            if not alphas.issubset({0, 255}):
                allow_partial_mask = selections is not None and any(selection['geometry'] == geometry.get('id') and selection.get('partialAlphaCutoff') == .5 for selection in selections)
                if not allow_partial_mask:
                    raise ValueError(f'Partial alpha is unsupported outside named source ground shadows: {texture_name}')
                omitted.append({'geometry': geometry.get('id'), 'primitive': primitive_index, 'texture': texture_name, 'reason': 'Source root texture mixes opaque roots with translucent ground shadow; native MASK .5 preserves opaque roots and discards the partial-alpha shadow', 'discardedAlphaValues': sorted(value for value in alphas if 0 < value < 128)})
            poly_inputs = inputs(primitive)
            if 'VERTEX' not in poly_inputs or poly_inputs['VERTEX'].get('source') != '#' + vertices_node.get('id'):
                raise ValueError('Unsupported polygon vertex binding')
            sources = {}
            offsets = {}
            for semantic, entry in vertex_inputs.items():
                stride = 2 if semantic == 'TEXCOORD' else 3
                sources[semantic] = source_rows(local_reference(by_id, entry.get('source')), stride)
                offsets[semantic] = int(poly_inputs['VERTEX'].get('offset', '0'))
            for semantic, entry in poly_inputs.items():
                if semantic == 'VERTEX':
                    continue
                if semantic not in ('POSITION', 'NORMAL', 'TEXCOORD', 'COLOR') or (semantic == 'TEXCOORD' and entry.get('set', '0') != '0'):
                    raise ValueError('Unsupported polygon attribute semantic')
                sources[semantic] = source_rows(local_reference(by_id, entry.get('source')), 2 if semantic == 'TEXCOORD' else 3)
                offsets[semantic] = int(entry.get('offset', '0'))
            if not {'POSITION', 'TEXCOORD'}.issubset(sources):
                raise ValueError('Source geometry requires positions and UVs')
            index_stride = max(int(entry.get('offset', '0')) for entry in poly_inputs.values()) + 1
            counts = list(map(int, primitive.findtext('c:vcount', namespaces=NAMESPACE).split())) if primitive.tag.endswith('polylist') else [3] * int(primitive.get('count'))
            indices = list(map(int, primitive.findtext('c:p', namespaces=NAMESPACE).split()))
            if len(counts) != int(primitive.get('count')) or sum(counts) * index_stride != len(indices) or any(count not in (3, 4) for count in counts):
                raise ValueError('Only source triangles and convex quads are supported')
            cursor = 0
            selected_polygons = []
            for polygon_index, count in enumerate(counts):
                polygon = []
                for vertex in range(count):
                    values = {}
                    for semantic, rows in sources.items():
                        index = indices[cursor + vertex * index_stride + offsets[semantic]]
                        if not 0 <= index < len(rows):
                            raise ValueError('Polygon index is out of range')
                        values[semantic] = rows[index]
                    color = values.get('COLOR', [1, 1, 1])
                    if any(not 0 <= value <= 1 for value in color):
                        raise ValueError('Vertex colors must be between zero and one')
                    polygon.append(point(transform, values['POSITION']) + [values['TEXCOORD'][0], 1 - values['TEXCOORD'][1]] + color)
                cursor += count * index_stride
                try:
                    source_triangles = list(triangulate(polygon, validate=True))
                except ValueError as error:
                    raise ValueError(f'{geometry.get("id")} primitive {primitive_index} polygon {polygon_index}: {error}') from error
                if len(source_triangles) < count - 2:
                    omitted.append({'geometry': geometry.get('id'), 'primitive': primitive_index, 'polygon': polygon_index, 'reason': 'Degenerate native fan triangles with zero visible area', 'discardedTriangles': count - 2 - len(source_triangles)})
                if region:
                    for axis in range(3):
                        polygon = clip_polygon(polygon, axis, region[axis], True)
                        polygon = clip_polygon(polygon, axis, region[axis + 3], False)
                    source_triangles = list(triangulate(polygon))
                if source_triangles:
                    selected_polygons.append(polygon_index)
                for triangle in source_triangles:
                    raw_count += 1
                    shaded = any(abs(value - 1) > 1e-6 for vertex in triangle for value in vertex[5:8])
                    shaded_count += int(shaded)
                    key = texture_name
                    if key in samplers and (samplers[key] != wraps or double_sided[key] != two_sided):
                        key = f'{material.get("id")}_{texture_name}'
                    textures[key] = texture_members[texture_name]
                    samplers[key] = wraps
                    double_sided[key] = two_sided
                    surfaces[key].extend([value / units_per_cell for value in vertex[:3]] + vertex[3:8] for vertex in triangle)
                    if raw_count > MAX_TRIANGLES:
                        raise ValueError('Output triangle complexity exceeds the supported budget')
            chosen.append({'geometry': geometry.get('id'), 'primitive': primitive_index, 'material': material.get('id'), 'texture': texture_name, 'polygons': selected_polygons, 'region': region, 'doubleSided': two_sided})
    surfaces = dict(surfaces)
    if not surfaces:
        raise ValueError('Empty geometry selection')
    return {'surfaces': surfaces, 'textures': textures, 'samplers': samplers, 'doubleSided': double_sided, 'omitted': omitted, 'selections': chosen, 'sourceTriangleCount': raw_count, 'outputTriangleCount': raw_count, 'shadedTriangleCount': shaded_count}


def emit_model(path, result):
    vertices = [vertex for surface in result['surfaces'].values() for vertex in surface]
    bounds = [min(v[a] for v in vertices) for a in range(3)] + [max(v[a] for v in vertices) for a in range(3)]
    anchor = [(bounds[0] + bounds[3]) / 2, bounds[1], (bounds[2] + bounds[5]) / 2]
    binary = bytearray()
    document = {
        'asset': {'version': '2.0', 'generator': 'Avelune source asset converter'},
        'extensionsUsed': ['KHR_materials_unlit'], 'extensionsRequired': ['KHR_materials_unlit'],
        'scene': 0, 'scenes': [{'nodes': [0]}], 'nodes': [{'mesh': 0}],
        'meshes': [{'primitives': []}], 'buffers': [], 'bufferViews': [], 'accessors': [],
        'materials': [], 'textures': [], 'images': [], 'samplers': [],
    }

    def view(data, target=None):
        binary.extend(b'\0' * (-len(binary) % 4))
        entry = {'buffer': 0, 'byteOffset': len(binary), 'byteLength': len(data)}
        if target is not None:
            entry['target'] = target
        binary.extend(data)
        document['bufferViews'].append(entry)
        return len(document['bufferViews']) - 1

    def accessor(rows, dimension):
        values = [value for row in rows for value in row]
        try:
            data = struct.pack('<' + 'f' * len(values), *values)
        except (OverflowError, struct.error) as error:
            raise ValueError('Nonfinite float32 geometry') from error
        decoded = struct.unpack('<' + 'f' * len(values), data)
        if not all(math.isfinite(value) for value in decoded):
            raise ValueError('Nonfinite float32 geometry')
        entry = {'bufferView': view(data, 34962), 'componentType': 5126, 'count': len(rows), 'type': f'VEC{dimension}'}
        if dimension == 3:
            entry['min'] = [min(decoded[a::dimension]) for a in range(dimension)]
            entry['max'] = [max(decoded[a::dimension]) for a in range(dimension)]
        document['accessors'].append(entry)
        return len(document['accessors']) - 1

    wraps = {'WRAP': 10497, 'CLAMP': 33071, 'MIRROR': 33648}
    for name, surface in sorted(result['surfaces'].items()):
        centered = [[vertex[a] - anchor[a] for a in range(3)] + vertex[3:] for vertex in surface]
        image_data = result['textures'][name]
        alpha_range = Image.open(BytesIO(image_data)).convert('RGBA').getextrema()[3]
        index = len(document['materials'])
        document['images'].append({'bufferView': view(image_data), 'mimeType': 'image/png'})
        document['samplers'].append({'magFilter': 9728, 'minFilter': 9728, 'wrapS': wraps[result['samplers'][name][0]], 'wrapT': wraps[result['samplers'][name][1]]})
        document['textures'].append({'source': index, 'sampler': index})
        material = {'name': name, 'alphaMode': 'OPAQUE' if alpha_range == (255, 255) else 'MASK', 'extensions': {'KHR_materials_unlit': {}}, 'pbrMetallicRoughness': {'baseColorTexture': {'index': index}, 'baseColorFactor': [1, 1, 1, 1]}}
        if material['alphaMode'] == 'MASK':
            material['alphaCutoff'] = .5
        if result['doubleSided'][name]:
            material['doubleSided'] = True
        document['materials'].append(material)
        normals = []
        for start in range(0, len(centered), 3):
            normal = cross(*centered[start:start + 3])
            length = math.sqrt(sum(value * value for value in normal))
            if length < 1e-8:
                raise ValueError('Degenerate output geometry')
            normals.extend([value / length for value in normal] for _ in range(3))
        document['meshes'][0]['primitives'].append({'mode': 4, 'material': index, 'attributes': {
            'POSITION': accessor([vertex[:3] for vertex in centered], 3),
            'NORMAL': accessor(normals, 3),
            'TEXCOORD_0': accessor([vertex[3:5] for vertex in centered], 2),
            'COLOR_0': accessor([vertex[5:8] + [1] for vertex in centered], 4),
        }})
    document['buffers'] = [{'byteLength': len(binary)}]
    encoded = json.dumps(document, separators=(',', ':')).encode()
    encoded += b' ' * (-len(encoded) % 4)
    binary.extend(b'\0' * (-len(binary) % 4))
    length = 28 + len(encoded) + len(binary)
    path.write_bytes(struct.pack('<III', 0x46546C67, 2, length) + struct.pack('<II', len(encoded), 0x4E4F534A) + encoded + struct.pack('<II', len(binary), 0x004E4942) + binary)
    return {
        'file': path.name, 'sha256': sha256(path.read_bytes()), 'sizeBytes': length,
        'bounds': [bounds[a] - anchor[a] for a in range(3)] + [bounds[a + 3] - anchor[a] for a in range(3)],
        'triangleCount': len(vertices) // 3, 'pivot': [0, 0, 0],
        'sourceAnchorCells': anchor, 'groundAnchor': [0, 0, 0],
        'suggestedSizeCells': [max(1, math.ceil(bounds[3] - bounds[0] - 1e-6)), max(1, math.ceil(bounds[5] - bounds[2] - 1e-6))],
        'textures': sorted(result['textures']),
        'footprintMeaning': 'Visual X/Z bounds only; gameplay collisions require a separately authored footprint',
    }


def read_archive(source_root, record, expected):
    source_root = source_root.resolve(strict=True)
    path = (source_root / record['local_path']).resolve(strict=True)
    if not path.is_relative_to(source_root) or not path.is_file():
        raise ValueError('Source archive escapes its declared corpus')
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


def path_atlas(edge_bytes, center_bytes):
    edge = Image.open(BytesIO(edge_bytes)).convert('RGBA').crop((0, 0, 16, 16))
    center = Image.open(BytesIO(center_bytes)).convert('RGBA')
    if center.size != (16, 16):
        raise ValueError('Path surface must be one native 16-pixel tile')
    edges = [edge, edge.transpose(Image.Transpose.ROTATE_270), edge.transpose(Image.Transpose.ROTATE_180), edge.transpose(Image.Transpose.ROTATE_90)]
    output = Image.new('RGBA', (256, 16))
    for mask in range(16):
        for y in range(16):
            for x in range(16):
                distances = (y, 15 - x, 15 - y, x)
                missing = [index for index in range(4) if not mask & (1 << index)]
                index = min(missing, key=lambda index: distances[index]) if missing else None
                pixel = edges[index].getpixel((x, y)) if index is not None and distances[index] < 8 else center.getpixel((x, y))
                output.putpixel((mask * 16 + x, y), pixel)
    result = BytesIO()
    output.save(result, format='PNG')
    return result.getvalue()


def require_pack_recipe(value):
    fields = {'schemaVersion', 'id', 'sourceUnitsPerCell', 'manifestFile', 'omittedTextures',
              'sources', 'models', 'textures', 'atlases', 'provenance'}
    if not isinstance(value, dict) or set(value) != fields or type(value['schemaVersion']) is not int or value['schemaVersion'] != 1:
        raise ValueError('Invalid source asset pack recipe')
    if len(json.dumps(value).encode()) > 2097152:
        raise ValueError('Source asset pack recipe exceeds 2 MiB')
    if type(value['sourceUnitsPerCell']) not in (int, float) or not math.isfinite(value['sourceUnitsPerCell']) or not .001 <= value['sourceUnitsPerCell'] <= 65536:
        raise ValueError('Invalid source units per cell')
    if not isinstance(value['omittedTextures'], list) or len(value['omittedTextures']) > 128:
        raise ValueError('Invalid explicit texture omissions')
    def text(item):
        if not isinstance(item, str) or not item or len(item) > 256:
            raise ValueError('Expected a bounded source asset identifier')
    def filename(item):
        text(item)
        if Path(item).name != item or item in {'.', '..'} or '\\' in item or ':' in item:
            raise ValueError('Expected a flat asset output filename')
    text(value['id'])
    filename(value['manifestFile'])
    for item in value['omittedTextures']:
        filename(item)
    expected = {
        'sources': {'id', 'sha256'},
        'models': {'sourceId', 'id', 'label', 'category', 'file', 'selections'},
        'textures': {'sourceId', 'id', 'label', 'material', 'file'},
        'atlases': {'id', 'label', 'file', 'edgeTextureId', 'centerTextureId'},
    }
    seen_ids, seen_files = set(), {value['manifestFile']}
    for collection, keys in expected.items():
        rows = value[collection]
        if not isinstance(rows, list) or len(rows) > 512 or collection == 'sources' and not rows:
            raise ValueError('Source pack collection exceeds its budget')
        local_ids = set()
        for row in rows:
            if not isinstance(row, dict) or set(row) != keys:
                raise ValueError('Unknown source asset recipe fields')
            for key, item in row.items():
                if key != 'selections':
                    text(item)
            if row['id'] in local_ids:
                raise ValueError('Duplicate source pack identity')
            local_ids.add(row['id'])
            if collection == 'sources':
                if re.fullmatch(r'[a-f0-9]{64}', row['sha256']) is None:
                    raise ValueError('Source archives require explicit SHA-256 pins')
                continue
            if row['id'] in seen_ids or row['file'] in seen_files:
                raise ValueError('Duplicate output asset identity or filename')
            seen_ids.add(row['id'])
            seen_files.add(row['file'])
            filename(row['file'])
            if collection != 'models' or row['selections'] is None:
                continue
            selections = row['selections']
            if not isinstance(selections, list) or not 1 <= len(selections) <= 128:
                raise ValueError('Invalid bounded source geometry selection')
            for selected in selections:
                if not isinstance(selected, dict) or not {'geometry', 'materials'} <= set(selected) or not set(selected) <= {'geometry', 'materials', 'region', 'partialAlphaCutoff', 'doubleSided'}:
                    raise ValueError('Unknown geometry selection operator')
                text(selected['geometry'])
                if not isinstance(selected['materials'], dict) or not selected['materials'] or len(selected['materials']) > 128:
                    raise ValueError('Invalid material bindings')
                for key, item in selected['materials'].items():
                    text(key)
                    text(item)
                if 'region' in selected:
                    region = selected['region']
                    if not isinstance(region, list) or len(region) != 6 or any(type(v) not in (int, float) or not math.isfinite(v) for v in region) or any(region[i] > region[i+3] for i in range(3)):
                        raise ValueError('Invalid geometry selection bounds')
                if 'partialAlphaCutoff' in selected and selected['partialAlphaCutoff'] != .5:
                    raise ValueError('Unsupported partial alpha policy')
                if 'doubleSided' in selected and type(selected['doubleSided']) is not bool:
                    raise ValueError('Invalid face visibility policy')
    source_ids = {row['id'] for row in value['sources']}
    texture_ids = {row['id'] for row in value['textures']}
    if any(row['sourceId'] not in source_ids for key in ('models', 'textures') for row in value[key]) or any(
            row[field] not in texture_ids for row in value['atlases'] for field in ('edgeTextureId', 'centerTextureId')):
        raise ValueError('Source asset recipe contains a dangling reference')
    return value


def extract(source_root, output_root, *, recipe):
    recipe = require_pack_recipe(recipe)
    source_root = source_root.resolve(strict=True)
    output_root = output_root.resolve()
    if source_root == output_root or source_root in output_root.parents or output_root in source_root.parents:
        raise ValueError('Output must be outside the read-only source directory')
    if output_root.exists() and (not output_root.is_dir() or any(output_root.iterdir())):
        raise ValueError('Output must be new or empty')
    with (source_root / 'catalogue.csv').open(encoding='utf-8-sig') as catalogue:
        rows = list(csv.DictReader(catalogue))
    records = {row['id']: row for row in rows}
    if len(records) != len(rows):
        raise ValueError('Ambiguous source archive identities')
    sources = {}
    for declared in recipe['sources']:
        if declared['id'] not in records:
            raise ValueError('Declared source archive is absent')
        sources[declared['id']] = read_archive(source_root, records[declared['id']], declared['sha256'])
    output_root.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='.source-pack-', dir=output_root.parent) as temporary:
        staging = Path(temporary)
        models = []
        for declared in recipe['models']:
            data, textures, provenance = sources[declared['sourceId']]
            result = convert_dae(data, textures, declared['selections'],
                                 omitted_textures=recipe['omittedTextures'],
                                 units_per_cell=recipe['sourceUnitsPerCell'])
            metrics = emit_model(staging / declared['file'], result)
            models.append({'id': declared['id'], 'label': declared['label'], 'category': declared['category'],
                **metrics, 'source': provenance, 'conversion': {
                    'sourceUnitsPerCell': recipe['sourceUnitsPerCell'], 'uv': '(u,1-v)',
                    'sourceTriangleCount': result['sourceTriangleCount'],
                    'shadedTriangleCount': result['shadedTriangleCount'],
                    'sourceSelections': result['selections'], 'omitted': result['omitted'],
                    'sourceTextureBytesPreserved': True}})
        terrain = []
        for declared in recipe['textures']:
            data, textures, provenance = sources[declared['sourceId']]
            tree = ET.fromstring(data)
            by_id = {node.get('id'): node for node in tree.iter() if node.get('id')}
            name, _ = material_texture(by_id, by_id[declared['material']])
            pixels = textures[name]
            (staging / declared['file']).write_bytes(pixels)
            raster = Image.open(BytesIO(pixels)).convert('RGBA')
            terrain.append({'id': declared['id'], 'label': declared['label'], 'file': declared['file'],
                'sha256': sha256(pixels), 'sizePx': list(raster.size), 'alphaRange': list(raster.getextrema()[3]),
                'sourceAssetId': declared['sourceId'], 'sourceUrl': provenance['sourceUrl'],
                'sourceArchive': provenance['archive'], 'sourceArchiveSha256': provenance['archiveSha256'],
                'member': name, 'material': declared['material'], 'conversion': 'Original texture bytes retained'})
        textures_by_id = {row['id']: row for row in terrain}
        atlases = []
        for declared in recipe['atlases']:
            references = [textures_by_id[declared[field]] for field in ('edgeTextureId', 'centerTextureId')]
            atlas = path_atlas(*[(staging / row['file']).read_bytes() for row in references])
            (staging / declared['file']).write_bytes(atlas)
            atlases.append({'id': declared['id'], 'label': declared['label'], 'file': declared['file'],
                'sha256': sha256(atlas), 'sizePx': [256, 16], 'cellSizePx': [16, 16], 'columns': 16,
                'rows': 1, 'sourceTextures': references, 'conversion': 'Native pixels selected by cardinal mask N=1 E=2 S=4 W=8'})
        manifest = {'schemaVersion': 1, 'models': models, 'terrainTextures': terrain,
            'smartTileAtlases': atlases, 'inspirations': [source[2] for source in sources.values()],
            'recipe': recipe, 'limitations': ['Geometry extraction does not infer gameplay collision or entrances',
                'Source animations are not executed or inferred']}
        (staging / recipe['manifestFile']).write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
        if output_root.exists() and any(output_root.iterdir()):
            raise ValueError('Output changed during source conversion')
        if output_root.exists():
            output_root.rmdir()
        staging.rename(output_root)
    return manifest


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source-root', type=Path, required=True)
    parser.add_argument('--output-root', type=Path, required=True)
    parser.add_argument('--recipe', type=Path, required=True)
    args = parser.parse_args()
    if args.recipe.stat().st_size > 2097152:
        raise ValueError('Source asset recipe exceeds 2 MiB')
    recipe = require_pack_recipe(json.loads(args.recipe.read_text()))
    result = extract(args.source_root, args.output_root, recipe=recipe)
    print(json.dumps({'output': str(args.output_root), 'models': len(result['models']),
                      'terrainTextures': len(result['terrainTextures']),
                      'triangles': sum(model['triangleCount'] for model in result['models'])}))


if __name__ == '__main__':
    main()

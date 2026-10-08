import argparse
from collections import defaultdict
import csv
from io import BytesIO
import json
import math
from pathlib import Path
import struct
from urllib.parse import unquote
import xml.etree.ElementTree as ET
import zipfile

from PIL import Image

from convert_bw2_door_asset import IDENTITY, NAMESPACE, inputs, matrix, multiply, point, sha256, source_rows


STATIC_ASSETS = (
    ('583129', 'floccesy_house', 'Maison de Valbois', 'Bâtiments', '28237b0b79951a95de20ffbe203caa98355062ec68775fd6adc6ac0d715f77cb'),
    ('583122', 'accumula_house', 'Maison d’Accumula', 'Bâtiments', '1a5395a9a09db7222b09628fa7a2d16bc4496c95a893f0657e4f1e80d44bbbb7'),
    ('583130', 'champion_house', 'Grande maison de Valbois', 'Bâtiments', 'ae26595a45b5933d2c907abd7fc60fb9a5976d8c6cda328247c15ac22e55986d'),
    ('582443', 'greenhouse', 'Serre', 'Bâtiments', '755dcf096aae5c467a662a260fe0b83e72e746e8a7153ab0bb7fc2d5cad3d5c2'),
    ('582551', 'sign_01', 'Panneau du village', 'Extérieurs', '245dd511bbda47f9d85d8d393c6fa10a3b93856ae0540c2afae4f5b776e0f7f8'),
    ('582552', 'sign_02', 'Panneau de randonnée', 'Extérieurs', 'd8164dd01d86d11391fd7f137a380dafec8db42e93b0c98fc36194117f6df0ce'),
    ('582937', 'fence', 'Clôture', 'Extérieurs', '95f26d143083ed08ab691cd0dd4b571fa0f74eb27077a39e2c7dac9475fef625'),
    ('582916', 'stump_01', 'Souche', 'Nature', 'f5e84be5b75a30025a05367417eca0dd93c817d3cfb43ba4d2aa91dedfa33ba2'),
    ('582917', 'stump_02', 'Souche creuse', 'Nature', 'f082963d548d18062063d40dc5d65fc96e38b5bf618cc146a9e0b2256b3122f0'),
    ('582933', 'plant_01', 'Jardinière', 'Intérieurs', '3f3d110aa5c4b1dd3b631e0c3c47d4c1eba6af4458b0fd97002b82ffb265e124'),
    ('582903', 'chair_04', 'Chaise', 'Intérieurs', 'f2119b9a9743baf267fc955009485cc9944aaf19c8c201576f5ca45b775bd5a6'),
    ('582904', 'table_04', 'Petite table', 'Intérieurs', 'e6b741862bb8ce3cf3b271057e03137412e882902f17597be9b5a49203ac36e5'),
    ('582543', 'center_table', 'Table du point de soin', 'Intérieurs', '12c53855c521feacfb24c0619158c4230fc09142944414f16cad823b8d40acda'),
    ('582785', 'vending_machine', 'Distributeur', 'Intérieurs', '22ed388055929ceaf1f0781efaa2bf5e919fc39685def45eb38a0fe74bfbaa9a'),
    ('582909', 'bookshelf_02', 'Bibliothèque', 'Intérieurs', '58538a6ca3dc9ca333d60b8ea2cdd619a8ae1d2eb2df419116367bda8c88ea54'),
    ('582479', 'desk_01', 'Bureau', 'Intérieurs', '6dd7b0e8036b5c62eacf49f855a006a3557c3e0b263906d8d239eda648edd5fd'),
    ('582747', 'table_01', 'Table en bois', 'Intérieurs', 'b2b02915005ee375add9b85b09071ab0888f8bcbb3aaf3b7a4d4409b58b59978'),
    ('582047', 'bed_01', 'Lit', 'Intérieurs', '3c718888aba4b186fef7da4cb5befeac76deb99f011a152ea4af7ea78716a99d'),
)
MAP_ASSETS = {
    '587518': ('archives/maps/pinwheel-forest--587518.zip', '9f60b7c8838ef777849bdfe3bf750327260fd40e95bd4bffd1ddb1d68103e076'),
    '587487': ('archives/maps/floccesy-town--587487.zip', '80fe6df6c3d8033c9683eade520cb397f19ad6307132d031737c7b5369dd98b3'),
    '583927': ('archives/interior-maps/accumula-town-house-2--583927.zip', 'a5c16e5229fca0678492a6baf373ff35b6e9aef2386801bcfef5961a3899bd4b'),
}
SHADOW_TEXTURES = {'h_kage.png', 'in40_kage.png', 'pc_kage.png', 'wf_tree_k.png', 'shadow.png'}
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


def convert_dae(data, texture_members, selections=None):
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
            if texture_name in SHADOW_TEXTURES:
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
                    surfaces[key].extend([value / 16 for value in vertex[:3]] + vertex[3:8] for vertex in triangle)
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
        'asset': {'version': '2.0', 'generator': 'Avelune BW2 native village asset converter'},
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


def extract(source_root, output_root):
    source_root = source_root.resolve(strict=True)
    output_root = output_root.resolve()
    if source_root == output_root or source_root in output_root.parents or output_root in source_root.parents:
        raise ValueError('Output must be outside the read-only source directory')
    output_root.mkdir(parents=True, exist_ok=True)
    if any(path.is_symlink() for path in output_root.iterdir()):
        raise ValueError('Output directory must not contain symbolic links')
    with (source_root / 'catalogue.csv').open(encoding='utf-8-sig') as catalogue:
        records = {row['id']: row for row in csv.DictReader(catalogue)}
    models = []
    for asset_id, key, label, category, expected in STATIC_ASSETS:
        data, textures, provenance = read_archive(source_root, records[asset_id], expected)
        result = convert_dae(data, textures)
        metrics = emit_model(output_root / f'bw2_{key}.glb', result)
        models.append({'id': f'bw2-{key.replace("_", "-")}', 'label': label, 'category': category, **metrics, 'source': provenance, 'conversion': {'axes': 'Y_UP; original source 16 units = one cell', 'uv': '(u,1-v)', 'alpha': 'Native binary PNG alpha preserved byte-for-byte; glTF MASK cutoff .5', 'vertexShading': 'Native vertex RGB retained exactly in float COLOR_0; original nearest WRAP/CLAMP/MIRROR samplers', 'sourceTriangleCount': result['sourceTriangleCount'], 'shadedTriangleCount': result['shadedTriangleCount'], 'sourceSelections': result['selections'], 'omitted': result['omitted']}})
    map_sources = {}
    for asset_id, (archive_path, expected) in MAP_ASSETS.items():
        data, textures, provenance = read_archive(source_root, records[asset_id], expected)
        map_sources[asset_id] = (data, textures, provenance)
    forest_data, forest_textures, forest_provenance = map_sources['587518']
    for key, label, selections in (
        ('pinwheel_tree', 'Arbre de la forêt', [{'geometry': f'map18_18-{index}', 'materials': {'defaultMaterial': material}, 'region': [192, 0, -192, 224, 80, -160], 'partialAlphaCutoff': .5, 'doubleSided': index == 18} for index, material in ((13, 'ki02c'), (14, 'ki02bx'), (15, 'ki02dx'), (18, 'ki02ax'))]),
        ('pinwheel_rock', 'Rocher de la forêt', [{'geometry': 'rock_02_14', 'materials': {'defaultMaterial': 'rock01'}}]),
    ):
        result = convert_dae(forest_data, forest_textures, selections)
        metrics = emit_model(output_root / f'bw2_{key}.glb', result)
        models.append({'id': f'bw2-{key.replace("_", "-")}', 'label': label, 'category': 'Nature', **metrics, 'source': forest_provenance, 'conversion': {'axes': 'Explicit native static geometry extraction, Y_UP, /16; source controllers and their invalid weights are not converted', 'uv': '(u,1-v)', 'alpha': 'Original PNG bytes; native glTF MASK cutoff .5', 'faceVisibility': 'Crossed vertical tree panels use doubleSided=true for camera orbit; no duplicate geometry', 'sourceSelections': result['selections'], 'omitted': result['omitted']}})
    room_data, room_textures, room_provenance = map_sources['583927']
    room = convert_dae(room_data, room_textures, [
        {'geometry': f'm_h02_00_00-{index}', 'materials': {'defaultMaterial': material}}
        for index, material in ((1, 'm_h02_02_lm1'), (2, 'm_h02_04_lm1'))
    ])
    models.append({'id': 'bw2-room-walls', 'label': 'Murs de la maison d’Accumula', 'category': 'Intérieurs',
                   **emit_model(output_root / 'bw2_room_walls.glb', room), 'source': room_provenance,
                   'conversion': {'axes': 'Explicit static wall geometry only, Y_UP, /16; no floor, furniture or controllers',
                                  'sourceSelections': room['selections'], 'omitted': room['omitted']}})
    terrain = []
    for asset_id, material_id, label in (
        ('587518', 'grass01ax', 'Herbe de la forêt'), ('587518', 'mori01s', 'Sol de forêt'),
        ('587518', 'michi02a', 'Chemin de forêt — surface'), ('587518', 'michi02b', 'Chemin de forêt — raccords'),
        ('587518', 'ue_grass00', 'Hautes herbes'), ('587518', 'yamagake01', 'Falaise de forêt'),
        ('587487', 'grass01ax', 'Herbe du village'), ('587487', 'michi01a', 'Chemin du village — surface'),
        ('587487', 'michi01b', 'Chemin du village — raccords'), ('587487', 'michi_isi', 'Pavage du village'),
        ('583927', 'm_h02_03_lm1', 'Tapis intérieur'), ('583927', 'm_h02_02_lm1', 'Mur intérieur — papier peint'),
        ('583927', 'm_h02_01_lm1', 'Sol intérieur — parquet'), ('583927', 'm_h02_04_lm1', 'Mur intérieur — soubassement'),
    ):
        data, textures, provenance = map_sources[asset_id]
        root = ET.fromstring(data)
        by_id = {node.get('id'): node for node in root.iter() if node.get('id')}
        name, _ = material_texture(by_id, by_id[material_id])
        output_name = f'bw2_terrain_{asset_id}_{material_id}.png'
        (output_root / output_name).write_bytes(textures[name])
        image = Image.open(BytesIO(textures[name])).convert('RGBA')
        terrain.append({'id': f'bw2-terrain-{asset_id}-{material_id}', 'label': label, 'file': output_name, 'sha256': sha256(textures[name]), 'sizePx': list(image.size), 'alphaRange': list(image.getextrema()[3]), 'sourceAssetId': asset_id, 'sourceUrl': provenance['sourceUrl'], 'sourceArchive': provenance['archive'], 'sourceArchiveSha256': provenance['archiveSha256'], 'member': name, 'material': material_id, 'conversion': 'Original texture bytes retained; atlas layout requires an authored SmartTile binding'})
    atlases = []
    for asset_id, edge_material, center_material, label in (
        ('587487', 'michi01a', 'michi01b', 'Chemins de Valbois'),
        ('587518', 'michi02a', 'michi02b', 'Sentiers de la forêt'),
    ):
        references = [next(texture for texture in terrain if texture['sourceAssetId'] == asset_id and texture['material'] == material) for material in (edge_material, center_material)]
        atlas = path_atlas(*[(output_root / texture['file']).read_bytes() for texture in references])
        name = f'bw2_path_atlas_{asset_id}.png'
        (output_root / name).write_bytes(atlas)
        atlases.append({'id': f'bw2-path-atlas-{asset_id}', 'label': label, 'file': name, 'sha256': sha256(atlas),
                       'sizePx': [256, 16], 'cellSizePx': [16, 16], 'columns': 16, 'rows': 1,
                       'sourceTextures': references, 'conversion': 'Only native source pixels: nearest-edge quadrant selection, cardinal mask N=1 E=2 S=4 W=8; no painted or interpolated pixels'})
    manifest = {'schemaVersion': 1, 'models': models, 'terrainTextures': terrain, 'smartTileAtlases': atlases, 'inspirations': [{'assetId': key, **value[2]} for key, value in map_sources.items()], 'limitations': ['Suggested footprints describe visible bounds, not collisions or entrances', 'Static module extraction deliberately excludes source skin controllers; no source animations are claimed', 'Requires Avelune MASK, COLOR_0, and native sampler wrapping support', 'Source translucent baked shadows are explicitly omitted', 'No complete source map is imported as a background or runtime dependency']}
    (output_root / 'bw2_village_assets_manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
    return manifest


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source-root', type=Path, required=True)
    parser.add_argument('--output-root', type=Path, required=True)
    args = parser.parse_args()
    result = extract(args.source_root, args.output_root)
    print(json.dumps({'output': str(args.output_root), 'models': len(result['models']), 'terrainTextures': len(result['terrainTextures']), 'triangles': sum(model['triangleCount'] for model in result['models'])}))


if __name__ == '__main__':
    main()

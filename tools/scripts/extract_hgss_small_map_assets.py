import argparse
from collections import defaultdict
import hashlib
import json
import math
from pathlib import Path
import struct

from PIL import Image


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def bounds(vertices):
    return [min(v[a] for v in vertices) for a in range(3)] + [
        max(v[a] for v in vertices) for a in range(3)
    ]


def select(node, textures, translation, region=None):
    surfaces = defaultdict(list)
    selections = []
    for surface in node['surfaces']:
        if surface['texture'] not in textures:
            continue
        if surface['color'] != [1.0, 1.0, 1.0, 1.0]:
            raise ValueError('Selected material must be opaque white')
        ids = []
        for i in range(0, len(surface['vertices']), 3):
            triangle = surface['vertices'][i:i + 3]
            if region and not all(
                region[a] - 1e-5 <= v[a] <= region[a + 3] + 1e-5
                for v in triangle for a in range(3)
            ):
                continue
            if any(v[5:] != [1.0, 1.0, 1.0, 1.0] for v in triangle):
                raise ValueError('Selected vertex color cannot be discarded')
            ids.append(i // 3)
            surfaces[surface['texture']].extend(
                [v[a] + translation[a] for a in range(3)] + v[3:5]
                for v in triangle
            )
        if ids:
            selections.append({
                'nodeId': node['id'], 'nodeName': node['name'],
                'geometryIds': node['sourceGeometryIds'],
                'materialId': surface['materialId'],
                'texture': surface['texture'], 'triangleIndices': ids,
                'translation': translation,
            })
    if not surfaces:
        raise ValueError(f'Empty geometry selection: {node["name"]}')
    return dict(surfaces), selections


def terrain(width, depth, path_start=7, path_end=9):
    surfaces = defaultdict(list)
    for z in range(depth):
        for x in range(width):
            if z in (6, 7):
                continue
            height = 2.0 if z < 6 else 0.0
            texture = 'road01.png' if path_start <= x < path_end else 'grass01gs.png'
            uv_scale = 0.5
            quad = [
                [x, height, z, x * uv_scale, z * uv_scale],
                [x, height, z + 1, x * uv_scale, (z + 1) * uv_scale],
                [x + 1, height, z + 1, (x + 1) * uv_scale, (z + 1) * uv_scale],
                [x + 1, height, z, (x + 1) * uv_scale, z * uv_scale],
            ]
            surfaces[texture].extend(quad[i] for i in (0, 1, 2, 0, 2, 3))
    return dict(surfaces)


def write_glb(path, surfaces, source_directory):
    binary = bytearray()
    document = {
        'asset': {'version': '2.0', 'generator': 'PokeMap HGSS small map extractor'},
        'extensionsUsed': ['KHR_materials_unlit'],
        'extensionsRequired': ['KHR_materials_unlit'],
        'scene': 0, 'scenes': [{'nodes': [0]}],
        'nodes': [{'mesh': 0}], 'meshes': [{'primitives': []}],
        'buffers': [], 'bufferViews': [], 'accessors': [],
        'materials': [], 'textures': [], 'images': [],
        'samplers': [{'magFilter': 9728, 'minFilter': 9728, 'wrapS': 10497, 'wrapT': 10497}],
    }

    def view(data, target=None):
        binary.extend(b'\0' * (-len(binary) % 4))
        entry = {'buffer': 0, 'byteOffset': len(binary), 'byteLength': len(data)}
        if target:
            entry['target'] = target
        binary.extend(data)
        document['bufferViews'].append(entry)
        return len(document['bufferViews']) - 1

    def accessor(values, dimensions):
        flattened = [value for row in values for value in row]
        if not all(math.isfinite(value) for value in flattened):
            raise ValueError('Nonfinite geometry')
        entry = {
            'bufferView': view(struct.pack('<' + 'f' * len(flattened), *flattened), 34962),
            'componentType': 5126, 'count': len(values), 'type': f'VEC{dimensions}',
        }
        if dimensions == 3:
            entry['min'] = [min(row[a] for row in values) for a in range(3)]
            entry['max'] = [max(row[a] for row in values) for a in range(3)]
        document['accessors'].append(entry)
        return len(document['accessors']) - 1

    all_vertices = []
    for texture, vertices in sorted(surfaces.items()):
        if not vertices or len(vertices) % 3:
            raise ValueError('A surface must contain complete triangles')
        texture_path = source_directory / texture
        with Image.open(texture_path) as image:
            if image.convert('RGBA').getextrema()[3] != (255, 255):
                raise ValueError(f'Nonopaque texture: {texture}')
        index = len(document['materials'])
        document['images'].append({'bufferView': view(texture_path.read_bytes()), 'mimeType': 'image/png'})
        document['textures'].append({'source': index, 'sampler': 0})
        document['materials'].append({
            'name': texture, 'alphaMode': 'OPAQUE',
            'extensions': {'KHR_materials_unlit': {}},
            'pbrMetallicRoughness': {
                'baseColorTexture': {'index': index}, 'baseColorFactor': [1, 1, 1, 1],
            },
        })
        normals = []
        for start in range(0, len(vertices), 3):
            a, b, c = vertices[start:start + 3]
            u = [b[i] - a[i] for i in range(3)]
            v = [c[i] - a[i] for i in range(3)]
            normal = [u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0]]
            length = math.sqrt(sum(n * n for n in normal))
            if length < 1e-8:
                raise ValueError('Degenerate source triangle')
            normals.extend([n / length for n in normal] for _ in range(3))
        document['meshes'][0]['primitives'].append({
            'mode': 4, 'material': index,
            'attributes': {
                'POSITION': accessor([v[:3] for v in vertices], 3),
                'TEXCOORD_0': accessor([v[3:5] for v in vertices], 2),
                'NORMAL': accessor(normals, 3),
            },
        })
        all_vertices.extend(vertices)
    document['buffers'] = [{'byteLength': len(binary)}]
    encoded = json.dumps(document, separators=(',', ':')).encode()
    encoded += b' ' * (-len(encoded) % 4)
    binary.extend(b'\0' * (-len(binary) % 4))
    length = 12 + 8 + len(encoded) + 8 + len(binary)
    path.write_bytes(
        struct.pack('<III', 0x46546C67, 2, length)
        + struct.pack('<II', len(encoded), 0x4E4F534A) + encoded
        + struct.pack('<II', len(binary), 0x004E4942) + binary
    )
    return {'file': path.name, 'sha256': digest(path), 'bounds': bounds(all_vertices),
            'triangleCount': len(all_vertices) // 3, 'pivot': [0, 0, 0],
            'textures': sorted(surfaces)}


def extract(source_directory, output_directory):
    source_directory = source_directory.resolve()
    output_directory = output_directory.resolve()
    if (source_directory == output_directory or source_directory in output_directory.parents
            or output_directory in source_directory.parents):
        raise ValueError('Output must be outside the read-only source directory')
    for filename in ('cliff_straight.glb', 'stairs.glb', 'house.glb', 'terrain.glb',
                     'layout.json', 'provenance.json'):
        if (output_directory / filename).is_symlink():
            raise ValueError(f'Output must not contain a symlink: {filename}')
    scene_path = source_directory / 'scene.json'
    provenance_path = source_directory.parent / 'provenance.json'
    source_provenance = json.loads(provenance_path.read_text())
    expected = {Path(f['path']).name: f['sha256'] for f in source_provenance['generatedFiles']}
    for filename in ('scene.json', 'grass01gs.png', 'road01.png', 'wall01_d.png',
                     'wall01_g.png', 'slope.png', 'as_h01.png', 'h_mado.png', 'r39_door1.png'):
        if digest(source_directory / filename) != expected[filename]:
            raise ValueError(f'Source provenance hash mismatch: {filename}')
    scene = json.loads(scene_path.read_text())
    nodes = {node['name']: node for node in scene['nodes']}
    cliff, cliff_selection = select(
        nodes['map09_07c'], {'wall01_d.png', 'wall01_g.png'},
        [-5, -1, 11], [5, 0.99, -11.01, 6, 2.01, -9.99],
    )
    stairs, stairs_selection = select(nodes['map09_07c'], {'slope.png'}, [-3, -1, 11])
    house, house_selection = select(nodes['as_h01.002'], {'as_h01.png', 'h_mado.png'}, [-2.940918125, -2.062500419743333, 17.35571142873609])
    door, door_selection = select(nodes['r39_door1.002'], {'r39_door1.png'}, [-2.940918125, -2.062500419743333, 17.35571142873609])
    for texture, vertices in door.items():
        house.setdefault(texture, []).extend(vertices)
    output_directory.mkdir(parents=True, exist_ok=True)
    entries = []
    for name, surfaces, selections, status in (
        ('cliff_straight', cliff, cliff_selection, 'Real adjacent source face, repeatable along X by translation of 1; not a complete cliff kit'),
        ('stairs', stairs, stairs_selection, 'Real staircase mesh with one unit rise over one unit depth; railings extend beyond nominal 2 unit width'),
        ('house', house, house_selection + door_selection, 'Real Olivine house and matching door, transparent baked shadow excluded'),
        ('terrain', terrain(16, 14), [], 'Authored planar terrain using unchanged HGSS grass and road textures; geometry is not extracted'),
    ):
        entry = write_glb(output_directory / f'{name}.glb', surfaces, source_directory)
        entry.update({'id': name, 'geometryStatus': status, 'sourceSelections': selections})
        entries.append(entry)
    placements = [{'model': 'terrain', 'position': [0, 0, 0]}]
    for z, height in ((6, 1), (7, 0)):
        placements.append({'model': 'stairs', 'position': [7, height, z]})
        placements.extend({'model': 'cliff_straight', 'position': [x, height, z]}
                          for x in range(16) if x not in (7, 8))
    placements.append({'model': 'house', 'position': [2, 2, 1]})
    layout = {
        'width': 16, 'depth': 14, 'units': 'one HGSS cell = source 16 units',
        'axes': 'Y_UP; X east, Z south', 'placements': placements,
        'playerSpawn': [8, 0, 11],
        'levels': [{'height': 2, 'rect': [0, 0, 16, 6]}, {'height': 0, 'rect': [0, 8, 16, 14]}],
        'ramps': [
            {'rect': [7.3125, 6, 8.6875, 7], 'heightNorth': 2, 'heightSouth': 1, 'direction': 'north'},
            {'rect': [7.3125, 7, 8.6875, 8], 'heightNorth': 1, 'heightSouth': 0, 'direction': 'north'},
        ],
        'blockedRects': [[0, 6, 7.3125, 8], [8.6875, 6, 16, 8], [2, 1, 6.244, 4.271]],
        'limitations': ['No house interior or door event', 'Map boundary is open geometry; navigation must enforce bounds',
                        'Only central staircase surface is walkable; railing peaks are not navigation height',
                        'Stair railings extend 0.1875 units outside the nominal 2 unit width and reach 0.125 above the upper floor'],
    }
    (output_directory / 'layout.json').write_text(json.dumps(layout, indent=2) + '\n')
    provenance = {
        'sources': [
            {'path': str(scene_path), 'sha256': digest(scene_path)},
            {'path': str(provenance_path), 'sha256': digest(provenance_path)},
        ],
        'upstream': {key: source_provenance[key] for key in ('sourceUrl', 'sourceTitle', 'sourceAuthor',
                     'archiveSha256', 'daePath', 'daeSha256', 'axes', 'uv')},
        'textures': [{'path': str(source_directory / texture), 'sha256': digest(source_directory / texture)}
                     for texture in sorted({texture for entry in entries for texture in entry['textures']})],
        'models': entries,
        'terrain': {'textureUvScalePerCell': 0.5, 'normal': 'up', 'heights': [0, 2],
                    'excludedRows': [6, 7], 'pathColumns': [7, 8]},
        'staircase': {'sourceFloorHeights': [1, 2], 'rise': 1, 'run': 1,
                      'localWalkableX': [0.3125, 1.6875], 'localWalkableZ': [0, 1],
                      'heightAtLocalZ': '1 - z', 'placements': [[7, 1, 6], [7, 0, 7]]},
        'omittedSurfaces': [{'nodeName': 'as_h01.002', 'texture': 'h_kage.png',
                             'reason': 'Source opacity 0.2903226; initial rendering contract is opaque only'}],
        'layoutSha256': digest(output_directory / 'layout.json'),
    }
    (output_directory / 'provenance.json').write_text(json.dumps(provenance, indent=2) + '\n')
    return provenance


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source-dir', type=Path, default=Path(__file__).resolve().parents[2] / 'apps/hgss_render_lab/assets/city/olivine')
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    result = extract(args.source_dir, args.output)
    print(json.dumps({'output': str(args.output), 'models': [
        {key: entry[key] for key in ('id', 'triangleCount', 'bounds')} for entry in result['models']
    ]}, indent=2))


if __name__ == '__main__':
    main()

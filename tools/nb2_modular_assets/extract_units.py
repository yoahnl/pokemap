import argparse
from collections import Counter, defaultdict
from hashlib import sha256
from io import BytesIO
import json
import math
from pathlib import Path
import sys

sys.dont_write_bytecode = True
REPOSITORY = Path(__file__).resolve().parents[2]
sys.path[:0] = [str(REPOSITORY / 'apps/unys_3d_sources'), str(REPOSITORY / 'tools/scripts')]

from PIL import Image
from build_routes import route_source
from city_geometry import Surface, barycentric, cell_triangles, interpolate, projected_area, source_scene, union_rectangles
from city_ground import floor_kind, ground_triangle, pixel_of, raster_tile
from city_models import component_triangles, entries_bounds, write_glb
from convert_bw2_village_assets import clip_polygon, cross, triangulate
from animate_bw2_cities import NitroSources, animated_material_document, glb_bytes, read_glb


TREE_MATERIALS = ['ki02c', 'ki03bx', 'ki03dx', 'ki03ax']
GRASS_MATERIALS = ['kusa_ec1', 'kusa_ec2', 'kusa_ec3']
GROUND_DECAL_MATERIALS = frozenset({'michi_hage', 'michi_hage02', 'michi_hibi', 'michi_isi',
                                  'ue_grass00', 'ue_grass01'})
SOURCE_HASHES = {
    'rom-route19': '449dccd89945e13858e09f5743421d083a24fa56db044bdc505a26c579c093ed',
    '587455': 'a7d2d797361a99f494a00326664a67bbc094d95f8d8e08e6f9caaf6744ab47ad',
}


def digest(path):
    return sha256(path.read_bytes()).hexdigest()


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False, allow_nan=False) + '\n')


def load_scene(root, source_id, route=False):
    records = json.loads((root / 'manifest.json').read_text())['assets']
    record = next(record for record in records if record['id'] == source_id)
    if record['sha256'] != SOURCE_HASHES[source_id]:
        raise ValueError(f'Pinned source archive changed: {source_id}')
    surfaces, textures, provenance = (route_source if route else source_scene)(root, record)
    return {'id': source_id, 'root': root, 'record': record, 'surfaces': surfaces,
            'textures': textures, 'provenance': provenance}


def select_entries(surfaces, materials, group=None, indices=None):
    return [(surface, triangle) for surface in surfaces
            if surface.material in materials and (group is None or surface.group == group)
            for index, triangle in enumerate(surface.triangles)
            if indices is None or index in indices.get(surface.material, [])]


def clip_selected(entries, bounds):
    result = []
    for surface, triangle in entries:
        polygon = triangle
        for axis, lower, upper in ((0, bounds[0], bounds[2]), (2, bounds[1], bounds[3])):
            polygon = clip_polygon(polygon, axis, lower, True)
            polygon = clip_polygon(polygon, axis, upper, False)
        result.extend((surface, triangle) for triangle in triangulate(polygon, validate=False))
    return result


def normal(triangle):
    value = cross(*triangle)
    length = math.sqrt(sum(axis * axis for axis in value))
    if length < 1e-10:
        raise ValueError('Degenerate source triangle')
    return [0.0 if abs(axis / length) < .0000005 else round(axis / length, 6) for axis in value]


def validate_unit(entries, specification):
    if not entries:
        raise ValueError('Empty source unit')
    materials = {surface.material for surface, _ in entries}
    if materials != set(specification['materials']):
        raise ValueError(f'Unexpected or missing source material: {sorted(materials)}')
    bounds = entries_bounds(entries)
    size = [bounds[axis + 3] - bounds[axis] for axis in range(3)]
    if any(actual > limit + 1e-6 for actual, limit in zip(size, specification['maxSize'])):
        raise ValueError(f'Unit bounds exceed family limit: {size}')
    if len(entries) > specification.get('maxTriangles', 300):
        raise ValueError('Unit contains more than a reusable source object')
    for _, triangle in entries:
        normal(triangle)
    return bounds


def unit_geometry(entries, support):
    bounds = entries_bounds(entries)
    anchor = [(bounds[0] + bounds[3]) / 2, bounds[1], (bounds[2] + bounds[5]) / 2]
    return {'sourceBoundsCells': bounds, 'sourceAnchorCells': anchor,
            'sourceSupportAnchor': support, 'supportAnchorLocal': [support[i] - anchor[i] for i in range(3)],
            'normals': [list(row) for row in sorted({tuple(normal(t)) for _, t in entries})]}


def source_support(surfaces, x, z, visual_y, city):
    hits = []
    for surface in surfaces:
        if floor_kind({'id': city}, surface) is None:
            continue
        for triangle in surface.triangles:
            if not ground_triangle({'id': city}, surface, triangle):
                continue
            weights = barycentric(x, z, triangle)
            if weights is not None and min(weights) >= -1e-6:
                height = interpolate(triangle, weights, 1)
                if height <= visual_y + 1e-6:
                    hits.append(height)
    if hits:
        return [x, max(hits), z], 'source_surface_sample'
    return [x, visual_y, z], 'visual_minimum_no_source_support_sample'


def unit(source_id, name, family, entries, support, materials, max_size, **extra):
    return {'id': name, 'sourceId': source_id, 'family': family, 'entries': entries,
            'support': support, 'materials': materials, 'maxSize': max_size, **extra}


def route_units(surfaces):
    first = 'map-route19-0/terrain-route19-0'
    second = 'map-route19-1/terrain-route19-1'
    tree = select_entries(surfaces, TREE_MATERIALS, first)
    tree = [(s, t) for s, t in tree if all(8.625 - 1e-6 <= v[0] <= 10.625 + 1e-6
            and -10.8125 - 1e-6 <= v[2] <= -8.8125 + 1e-6 for v in t)]
    result = [unit('rom-route19', 'bw2-tree-ki03', 'trees', tree, [9.625, 6, -9.8125], TREE_MATERIALS,
                   [2, 3.5, 2], collision={'kind': 'advised_trunk', 'sourceAuthored': False,
                   'centerLocalXZ': [0, 0], 'width': .5, 'depth': .5}),
              unit('rom-route19', 'bw2-tallgrass-three-layer', 'vegetation',
                   clip_selected(select_entries(surfaces, GRASS_MATERIALS, first), [11, 7, 12, 8]),
                   [11.5, 1, 7.5], GRASS_MATERIALS, [1, .5, 1],
                   orientation='fixed_source_horizontal_planes', collision={'kind': 'none'})]
    fence = select_entries(surfaces, ['saku01a'], first, {'saku01a': list(range(6, 12))})
    result.append(unit('rom-route19', 'bw2-fence-straight', 'fences',
                       clip_selected(fence, [12, 10.1875, 13, 10.8125]), [12.5, 1, 10.5],
                       ['saku01a'], [1, 1.2, .625], socketsSource=[[12, 1, 10.5], [13, 1, 10.5]]))
    corner = select_entries(surfaces, ['saku01a'], first, {'saku01a': list(range(6, 18))})
    result.append(unit('rom-route19', 'bw2-fence-corner', 'fences',
                       clip_selected(corner, [8, 10, 9, 11]), [8.5, 1, 10.5],
                       ['saku01a'], [1, 1.2, 1], socketsSource=[[9, 1, 10.5], [8.5, 1, 11]],
                       junction='original_overlapping_source_branches'))
    end = select_entries(surfaces, ['saku01a'], first, {'saku01a': list(range(6))})
    result.append(unit('rom-route19', 'bw2-fence-terminal', 'fences',
                       clip_selected(end, [2.1875, 4, 2.8125, 4.5]), [2.5, 1, 4.25],
                       ['saku01a'], [.625, 1.2, .5], socketsSource=[[2.5, 1, 4.5]],
                       termination='authentic_source_endpoint_without_invented_closed_cap'))
    profiles = [
        ('base-straight', 'gake01a', [8, 9], [13, -12.5, 14, -12], [13.5, 1, -12.25], [1, 1, .5]),
        ('base-corner', 'gake01a', [18, 19], None, [9.5, 1, -4.5], [1, 1, 1]),
        ('wall-straight', 'yamagake01', [34, 35], [13, -13, 14, -12], [13.5, 2, -12.5], [1, 3.75, .01]),
        ('wall-corner', 'yamagake01', [46, 47], None, [9.25, 2, -4.75], [.5, 3.75, .5]),
        ('cap-straight', 'gake1_1', [133, 134], [13, -13, 14, -12.5], [13.5, 5.75, -12.75], [1, .25, .5]),
        ('cap-corner', 'gake1_1', [222], None, [9.25, 5.4140625, -4.75], [.5, .6, .5]),
    ]
    for name, material, indices, bounds, support, size in profiles:
        entries = select_entries(surfaces, [material], first, {material: indices})
        if bounds:
            entries = clip_selected(entries, bounds)
        result.append(unit('rom-route19', 'bw2-cliff-' + name, 'relief', entries, support,
                           [material], size, supportMeaning='assembly_socket_not_walkable_ground',
                           seamPolicy='use_measured_source_profile_without_vertical_scaling'))
    flowers = clip_selected(select_entries(surfaces, ['hana01_1'], first), [10, 12, 11, 13])
    result.append(unit('rom-route19', 'bw2-flowers-hana01', 'vegetation', flowers,
                       [10.5, 1, 12.5], ['hana01_1'], [1, .2, 1], collision={'kind': 'none'}))
    water = clip_selected(select_entries(surfaces, ['ike01'], second), [20, -10, 21, -9])
    result.append(unit('rom-route19', 'bw2-water-ike01-cell', 'water', water,
                       [20.5, .5, -9.5], ['ike01'], [1, .01, 1],
                       supportMeaning='water_surface_level', collision={'kind': 'separately_authored_water_area'}))
    shore = select_entries(surfaces, ['shore01'], second, {'shore01': [0, 1]})
    result.append(unit('rom-route19', 'bw2-shore-straight', 'water',
                       clip_selected(shore, [17, -7.5, 18, -7.25]), [17.5, .5, -7.5],
                       ['shore01'], [1, .25, .25], supportMeaning='shore_water_edge_socket',
                       socketsSource=[[17, .5, -7.5], [18, .5, -7.5]]))
    result.append(unit('rom-route19', 'bw2-shore-corner', 'water',
                       select_entries(surfaces, ['shore01'], second, {'shore01': [2, 3]}),
                       [20, .5, -7.5], ['shore01'], [.75, .25, .75],
                       supportMeaning='shore_water_edge_socket', socketsSource=[[20, .5, -7.5], [20.5, .5, -8]]))
    ground_samples = [('grass-cell', 'grass01ax', [6, 4, 7, 5]),
                      ('path-center', 'michi01b', [7, 8, 8, 9]),
                      ('path-edge-west', 'michi01a', [4, 10, 5, 11]),
                      ('path-edge-north', 'michi01a', [6, 7, 7, 8]),
                      ('path-corner-east', 'michi01a', [9, 8, 10, 9]),
                      ('path-corner-west-irregular', 'michi01a', [4, 7, 5, 8])]
    for name, material, bounds in ground_samples:
        entries = clip_selected(select_entries(surfaces, [material], first), bounds)
        result.append(unit('rom-route19', 'bw2-ground-' + name, 'ground', entries,
                           [(bounds[0] + bounds[2]) / 2, 1, (bounds[1] + bounds[3]) / 2],
                           [material], [1, .01, 1], coverageMeaning='original_material_cell_or_partial_corner',
                           projectedCoverageCells=sum(projected_area(t) for _, t in entries),
                           collision={'kind': 'native_terrain_support'}))
    return result


def pavonnay_units(surfaces):
    result = []
    groups = defaultdict(list)
    for surface in surfaces:
        if not surface.terrain:
            groups[surface.group].extend((surface, t) for t in surface.triangles)
    names = {'object_01_sign03': 'sign03', 'object_02_out_dust01': 'bin', 'object_03_rock_02': 'rock-card',
             'object_01_plant_01': 'planter', 'object_04_sign02': 'sign02'}
    for group, entries in sorted(groups.items()):
        short = group.rsplit('/', 1)[-1]
        if short not in names:
            continue
        bounds = entries_bounds(entries)
        x, z = (bounds[0] + bounds[3]) / 2, (bounds[2] + bounds[5]) / 2
        support, evidence = source_support(surfaces, x, z, bounds[1], 'pavonnay')
        result.append(unit('587455', 'bw2-pavonnay-' + names[short], 'props', entries, support,
                           sorted({s.material for s, _ in entries}), [3, 2, 3], supportEvidence=evidence,
                           collision={'kind': 'separately_authored_footprint', 'sourceAuthored': False}))
    flower = select_entries(surfaces, ['kisetu_hana'], 'map_0280_1_22/terrain')
    result.append(unit('587455', 'bw2-pavonnay-seasonal-flower', 'vegetation', flower,
                       [.5, 1, 9.5], ['kisetu_hana'], [1, .2, 1], collision={'kind': 'none'}))
    posts = select_entries(surfaces, ['C12_saku02'], 'map_0279_1_23/terrain_1')
    component = component_triangles(posts)[0]
    bounds = entries_bounds(component)
    result.append(unit('587455', 'bw2-pavonnay-railing-post', 'fences', component,
                       [(bounds[0] + bounds[3]) / 2, 1, (bounds[2] + bounds[5]) / 2],
                       ['C12_saku02'], [.32, 1, .32]))
    rails = select_entries(surfaces, ['C12_saku01'], 'map_0279_1_23/terrain_1')
    rails = clip_selected(rails, [5.5, 38, 5.75, 39])
    result.append(unit('587455', 'bw2-pavonnay-railing-straight', 'fences', rails,
                       [5.625, 1, 38.5], ['C12_saku01'], [.25, 1, 1],
                       socketsSource=[[5.625, 1, 38], [5.625, 1, 39]]))
    fence_group = 'map_0280_1_22/terrain'
    fence = select_entries(surfaces, ['out_65_saku'], fence_group, {'out_65_saku': [0, 1, 4, 5, 16, 17]})
    result.append(unit('587455', 'bw2-pavonnay-fence-straight', 'fences',
                       clip_selected(fence, [-12, 12, -11.5, 13]), [-11.7, 1, 12.5],
                       ['out_65_saku'], [.5, 1.1, 1],
                       seamPolicy='source UV periods differ between layers; exact stroke phase requires source per-segment UV'))
    corner = select_entries(surfaces, ['out_65_saku'], fence_group,
                            {'out_65_saku': [0, 1, 4, 5, 6, 7, 8, 9, 16, 17, 18, 19]})
    result.append(unit('587455', 'bw2-pavonnay-fence-corner', 'fences',
                       clip_selected(corner, [-12, 9.75, -11, 10.75]), [-11.5, 1, 10.25],
                       ['out_65_saku'], [1, 1.1, 1]))
    result.append(unit('587455', 'bw2-pavonnay-fence-terminal', 'fences',
                       select_entries(surfaces, ['out_65_saku'], fence_group, {'out_65_saku': [2, 3]}),
                       [-11.779296875, 1, 16], ['out_65_saku'], [.2, 1.1, .01],
                       termination='original source cap card'))
    wall_group = 'map_0279_1_23/terrain_1'
    wall = clip_selected(select_entries(surfaces, ['c12_gake01'], wall_group, {'c12_gake01': [0, 1]}), [-14.6, 20, -14.4, 21])
    result.append(unit('587455', 'bw2-pavonnay-cliff-wall-straight', 'relief', wall,
                       [-14.5, 2.0625, 20.5], ['c12_gake01'], [.01, 2.6875, 1],
                       supportMeaning='assembly_socket_not_walkable_ground'))
    result.append(unit('587455', 'bw2-pavonnay-cliff-wall-corner', 'relief',
                       select_entries(surfaces, ['c12_gake01'], wall_group, {'c12_gake01': [4, 5]}),
                       [-14.75, 2.0625, 25.25], ['c12_gake01'], [.5, 2.6875, .5],
                       supportMeaning='assembly_socket_not_walkable_ground'))
    for name, material, bounds, low, high, support in [
        ('bank-straight', 'gake01a', [-14.5, 20, -14, 21], 1.06, 2.063, [-14.25, 1.0625, 20.5]),
        ('cap-straight', 'gake1_1', [-15, 20, -14.5, 21], 4.74, 5.1, [-14.75, 4.75, 20.5]),
        ('cap-corner', 'gake1_1', [-15, 25, -14.5, 25.5], 4.74, 5.1, [-14.75, 4.75, 25.25]),
    ]:
        entries = [(s, t) for s, t in select_entries(surfaces, [material], wall_group)
                   if min(v[1] for v in t) >= low and max(v[1] for v in t) <= high]
        entries = clip_selected(entries, bounds)
        result.append(unit('587455', 'bw2-pavonnay-cliff-' + name, 'relief', entries,
                           support, [material], [1, 1.01, 1], supportMeaning='assembly_socket_not_walkable_ground'))
    return result


def reference_rows(scene, entries):
    selected = defaultdict(set)
    originals = [(surface, index, triangle) for surface in scene['surfaces']
                 for index, triangle in enumerate(surface.triangles)]
    for surface, triangle in entries:
        for original_surface, index, original in originals:
            if original_surface is not surface:
                continue
            if triangle is original:
                selected[id(surface)].add(index)
                continue
            if all(point_in_triangle(vertex, original) for vertex in triangle):
                selected[id(surface)].add(index)
    return [{'group': surface.group, 'geometry': surface.geometry, 'material': surface.material,
             'texture': surface.texture, 'triangleIndices': sorted(selected[id(surface)])}
            for surface in scene['surfaces'] if id(surface) in selected]


def point_in_triangle(vertex, triangle):
    a, b, c = triangle
    axes = sorted(range(3), key=lambda axis: abs(normal(triangle)[axis]))[:2]
    x, y = axes
    ab, ac, ap = [[other[k] - a[k] for k in range(3)] for other in (b, c, vertex)]
    denominator = ab[x] * ac[y] - ab[y] * ac[x]
    if abs(denominator) < 1e-10:
        return False
    u = (ap[x] * ac[y] - ap[y] * ac[x]) / denominator
    v = (ab[x] * ap[y] - ab[y] * ap[x]) / denominator
    weights = [1 - u - v, u, v]
    return min(weights) >= -1e-6 and max(abs(vertex[axis] - sum(w * p[axis]
        for w, p in zip(weights, triangle))) for axis in range(8)) < 1e-5


def normalized_uv_entries(entries):
    shifts = {}
    for surface, _ in entries:
        if id(surface) in shifts:
            continue
        vertices = [v for s, t in entries if s is surface for v in t]
        shifts[id(surface)] = [math.floor(min(v[axis + 3] for v in vertices) + 1e-7)
                              if mode == 'WRAP' else 2 * math.floor(min(v[axis + 3] for v in vertices) / 2)
                              if mode == 'MIRROR' else 0 for axis, mode in enumerate(surface.wraps)]
    return [(surface, [[*v[:3], v[3] - shifts[id(surface)][0], v[4] - shifts[id(surface)][1], *v[5:]]
                       for v in triangle]) for surface, triangle in entries]


def texture_rows(scene, entries):
    result = []
    for name in sorted({surface.texture for surface, _ in entries}):
        data = scene['textures'][name]
        with Image.open(BytesIO(data)) as image:
            size = list(image.size)
        result.append({'member': name, 'sha256': sha256(data).hexdigest(), 'pixelSize': size})
    return result


def animation_context(scene):
    materials = defaultdict(lambda: {'textures': set(), 'groups': set()})
    for surface in scene['surfaces']:
        group = surface.group.replace('map-route19-0/', 'map_0000_1_21/').replace('map-route19-1/', 'map_0000_2_21/')
        materials[surface.material]['textures'].add(surface.texture)
        materials[surface.material]['groups'].add(group)
    return {'city': 'route-19' if scene['id'] == 'rom-route19' else 'pavonnay',
            'materials': {name: {key: sorted(values) for key, values in data.items()}
                          for name, data in materials.items()}, 'record': scene['record'],
            'sourceRoot': scene['root'], 'provenance': scene['provenance']}


def emit_unit(specification, scene, output, sources):
    bounds = validate_unit(specification['entries'], specification)
    path = output / 'models' / (specification['id'] + '.glb')
    path.parent.mkdir(parents=True, exist_ok=True)
    info = write_glb(path, normalized_uv_entries(specification['entries']), scene['textures'])
    document, binary = read_glb(path.read_bytes())
    materials = defaultdict(set)
    for surface, _ in specification['entries']:
        materials[surface.texture].add(surface.material)
    for material in document['materials']:
        names = sorted(materials[material['name'].split('@')[0]])
        material.setdefault('extras', {})['sourceMaterials'] = names
        if len(names) == 1:
            material['extras']['aveluneNitroMaterial'] = names[0]
    animated, evidence, unsupported = animated_material_document(document, binary, {}, animation_context(scene), sources, 60)
    if unsupported:
        raise ValueError(f'Unresolved source animation for {specification["id"]}: {unsupported}')
    document = animated or document
    if animated:
        document.setdefault('extras', {})['aveluneAnimationSource'] = {
            'romSha256': sources.inventory['source']['rom_sha256'],
            'gameCode': sources.inventory['source']['game_code'], 'frameRate': 60,
            'frameRateEvidence': 'Assumed Nitro 60 Hz; original game scheduling not measured',
            'materials': evidence}
    document.setdefault('extras', {})['nb2SourceUnit'] = {'id': specification['id'], 'family': specification['family']}
    encoded = glb_bytes(document, binary)
    path.write_bytes(encoded)
    geometry = unit_geometry(specification['entries'], specification['support'])
    attributes = {key: value for key, value in specification.items() if key not in
                  ('entries', 'support', 'maxSize', 'materials')}
    if specification['family'] == 'trees':
        attributes['collisionBounds'] = {'min': {'x': -.25, 'y': geometry['supportAnchorLocal'][1], 'z': -.25},
                                         'max': {'x': .25, 'y': geometry['supportAnchorLocal'][1] + 1, 'z': .25}}
        attributes['collisionBoundsEvidence'] = 'recommended narrow trunk; ROM collision not decoded'
    if 'socketsSource' in attributes:
        attributes['socketsLocal'] = [[point[i] - geometry['sourceAnchorCells'][i] for i in range(3)]
                                     for point in attributes['socketsSource']]
    if specification['family'] == 'relief':
        vertices = sorted({tuple(v[:3]) for _, t in specification['entries'] for v in t})
        attributes['seamProfile'] = {'sourceVertices': [list(v) for v in vertices],
                                    'localVertices': [[v[i] - geometry['sourceAnchorCells'][i] for i in range(3)] for v in vertices],
                                    'lowerHeight': bounds[1], 'upperHeight': bounds[4]}
    return {**attributes, **geometry, 'file': str(path.relative_to(output)),
            'path': str(path.resolve()), 'sha256': sha256(encoded).hexdigest(), 'byteLength': len(encoded),
            'triangleCount': len(specification['entries']), 'pivot': [0, 0, 0],
            'bounds': [bounds[i] - geometry['sourceAnchorCells'][i % 3] for i in range(6)],
            'sourceReferences': reference_rows(scene, specification['entries']),
            'textureSources': texture_rows(scene, specification['entries']),
            'materials': [{'name': name, 'texture': surface.texture, 'wraps': surface.wraps,
                           'opacity': surface.opacity, 'sourceTriangleCount': sum(s.material == name for s, _ in specification['entries'])}
                          for name, surface in sorted({s.material: s for s, _ in specification['entries']}.items())],
            'animation': {'status': 'original_material_track' if animated else 'static_no_associated_source_track',
                          'sourceEvidence': evidence, 'recommendedAnimationIndex': len(document.get('animations', [])) if animated else None},
            'supportEvidence': specification.get('supportEvidence', 'measured_source_ground_or_socket'),
            'collision': specification.get('collision', {'kind': 'separately_authored_footprint', 'sourceAuthored': False})}


def native_frame(project, scene):
    if scene['id'] == '587455':
        manifest = json.loads((project / '.pokemap/authoring/pavonnay/assets_manifest.json').read_text())
        return {'mapId': 'first-map', 'sourceToNativeTranslation': [value / manifest['sourceUnitsPerCell']
                for value in manifest['sourceWorldOffset']], 'levelHeight': .25, 'width': 48, 'depth': 72,
                'frameEvidence': 'source manifest world offset; authored height adjustments excluded'}
    summary = json.loads((project / '.pokemap/authoring/unys-cities/route-19/reconstruction.json').read_text())['summary']
    return {'mapId': 'unys-route-19', 'sourceToNativeTranslation': [-summary['sourceOrigin'][0],
            summary['sourceYOffset'], -summary['sourceOrigin'][2]], 'levelHeight': summary['levelHeight'],
            'width': summary['width'], 'depth': summary['height'],
            'frameEvidence': 'pinned source reconstruction origin and vertical offset'}


def placement(model, frame, source_anchor=None, evidence='source_unit_exact'):
    anchor = source_anchor or model['sourceAnchorCells']
    return {'modelId': model['id'], 'sourceAnchorCells': anchor,
            'position': {axis: anchor[i] + frame['sourceToNativeTranslation'][i] for i, axis in enumerate(('x', 'y', 'z'))},
            'rotationDegrees': 0, 'scale': 1, 'supportAnchorLocal': model['supportAnchorLocal'], 'evidence': evidence}


def source_areas(scene, frame):
    result = []
    city = 'route-19' if scene['id'] == 'rom-route19' else 'pavonnay'
    for surface in scene['surfaces']:
        kind = floor_kind({'id': city}, surface)
        if kind is None and surface.material not in GRASS_MATERIALS + ['hana01_1', 'kisetu_hana', 'ike01']:
            continue
        triangles = [triangle for triangle in surface.triangles if projected_area(triangle) > 1e-8
                     and (kind is None or ground_triangle({'id': city}, surface, triangle))]
        if not triangles:
            continue
        area_kind = kind or ('tallgrass' if surface.material in GRASS_MATERIALS else 'water' if surface.material == 'ike01' else 'decoration')
        result.append({'group': surface.group, 'geometry': surface.geometry, 'material': surface.material,
                       'kind': area_kind,
                       'texture': surface.texture, 'wraps': surface.wraps,
                       'projectedAreaCells': sum(projected_area(t) for t in triangles),
                       'sourceTriangles': triangles,
                       'nativeTranslation': frame['sourceToNativeTranslation'],
                       'purpose': 'native terrain/path/environment recipe; never place as a regional mesh'})
    return result


def paint_recipe(scene, frame):
    images = {name: Image.open(BytesIO(data)).convert('RGBA') for name, data in scene['textures'].items()}
    samples = defaultdict(list)
    coverage = defaultdict(float)
    mask_centers = set()
    translation = frame['sourceToNativeTranslation']
    city = 'route-19' if scene['id'] == 'rom-route19' else 'pavonnay'
    for surface in scene['surfaces']:
        kind = floor_kind({'id': city}, surface)
        for index, triangle in enumerate(surface.triangles):
            is_floor = (kind is not None and surface.material not in GROUND_DECAL_MATERIALS
                        and ground_triangle({'id': city}, surface, triangle))
            is_grass = surface.material == 'kusa_ec3'
            if not is_floor and not is_grass:
                continue
            bounds = entries_bounds([(surface, triangle)])
            left, right = math.floor(bounds[0] + translation[0]), math.ceil(bounds[3] + translation[0])
            top, bottom = math.floor(bounds[2] + translation[2]), math.ceil(bounds[5] + translation[2])
            for z in range(max(0, top), min(frame['depth'], bottom)):
                for x in range(max(0, left), min(frame['width'], right)):
                    sx, sz = x + .5 - translation[0], z + .5 - translation[2]
                    weights = barycentric(sx, sz, triangle)
                    inside = weights is not None and min(weights) >= -1e-6
                    if is_grass:
                        clipped = clip_selected([(surface, triangle)], [x - translation[0], z - translation[2],
                                                x + 1 - translation[0], z + 1 - translation[2]])
                        coverage[x, z] += sum(projected_area(t) for _, t in clipped)
                        if inside:
                            mask_centers.add((x, z))
                    if is_floor and inside and pixel_of(surface, triangle, weights, images)[3] > 127:
                        samples[x, z].append({'sourceHeight': interpolate(triangle, weights, 1),
                                              'material': surface.material, 'kind': kind, 'texture': surface.texture,
                                              'uv': [interpolate(triangle, weights, axis) for axis in (3, 4)],
                                              'group': surface.group, 'geometry': surface.geometry, 'triangleIndex': index})
    levels = [None] * (frame['width'] * frame['depth'])
    heights = [None] * len(levels)
    source_cells = []
    materials = defaultdict(set)
    errors = []
    for (x, z), candidates in sorted(samples.items(), key=lambda entry: (entry[0][1], entry[0][0])):
        selected = max(candidates, key=lambda entry: (entry['sourceHeight'], entry['kind'] == 'path'))
        height = selected['sourceHeight'] + translation[1]
        level = round(height / frame['levelHeight'])
        heights[z * frame['width'] + x] = height
        levels[z * frame['width'] + x] = level
        errors.append(abs(height - level * frame['levelHeight']))
        materials[selected['kind'], selected['material']].add((x, z))
        source_cells.append({'x': x, 'z': z, **selected})
    partial = [{'x': x, 'z': z, 'sourceCoverageRatio': round(area, 8)} for (x, z), area in sorted(coverage.items())
               if 1e-6 < area < 1 - 1e-6]
    mask = {'modelId': 'bw2-tallgrass-three-layer', 'cellMask': [{'x': x, 'z': z} for x, z in sorted(mask_centers)],
            'fullCoverageCells': [{'x': x, 'z': z} for (x, z), area in sorted(coverage.items()) if area >= 1 - 1e-6],
            'partialCoverageCells': partial, 'visualCellSpacing': 1,
            'sourceProjectedAreaCells': sum(coverage.values()),
            'policy': 'center-inside source geometry; partial source edges require explicit visual review',
            'sourceAuthoredCollision': False}
    return {'width': frame['width'], 'depth': frame['depth'], 'levelHeight': frame['levelHeight'],
            'heightLevels': levels, 'sourceNativeHeights': heights, 'sourceCellSamples': source_cells,
            'maxHeightQuantizationErrorCells': max(errors, default=0),
            'missingSupportCells': sum(value is None for value in levels),
            'negativeLevelCells': sum(value is not None and value < 0 for value in levels),
            'terrainAndPathMasks': [{'kind': kind, 'sourceMaterial': material,
                                    'cellMask': [{'x': x, 'z': z} for x, z in sorted(cells)],
                                    'rectangles': union_rectangles(cells)} for (kind, material), cells in sorted(materials.items())],
            'tallGrass': mask,
            'heightEvidence': 'highest opaque source support triangle at cell center; visual ground decals excluded',
            'limits': ['Cell-center masks retain source polygons separately; boundary coverage is explicitly partial',
                       'Ground decals retain source geometry and texture sampling but never define support height',
                       'Missing support is null, never silently filled; negative levels require native-authoring review']}


def object_recipe(scene, frame, models):
    result = []
    groups = defaultdict(list)
    for surface in scene['surfaces']:
        if not surface.terrain:
            groups[surface.group].extend((surface, triangle) for triangle in surface.triangles)
    shapes = {}
    for model in models:
        if model['family'] != 'props' or model['sourceId'] != scene['id']:
            continue
        group = model['sourceReferences'][0]['group']
        shapes[geometry_identity(groups[group], scene['textures'])] = model
    for group, entries in sorted(groups.items()):
        identity = geometry_identity(entries, scene['textures'])
        if identity not in shapes:
            continue
        bounds = entries_bounds(entries)
        anchor = [(bounds[0] + bounds[3]) / 2, bounds[1], (bounds[2] + bounds[5]) / 2]
        placed = placement(shapes[identity], frame, anchor, 'complete_source_object_geometry_and_uv_match')
        placed['sourceGroup'] = group
        result.append(placed)
    return result


def existing_object_recipe(project, scene, frame):
    if scene['id'] != '587455':
        return []
    manifest = json.loads((project / '.pokemap/authoring/pavonnay/assets_manifest.json').read_text())
    groups = defaultdict(list)
    for surface in scene['surfaces']:
        if not surface.terrain:
            groups[surface.group].extend((surface, triangle) for triangle in surface.triangles)
    catalog = {}
    for model in manifest['models']:
        if '-object-' not in model['modelId']:
            continue
        for group, entries in groups.items():
            bounds = entries_bounds(entries)
            anchor = [(bounds[0] + bounds[3]) / 2, bounds[1], (bounds[2] + bounds[5]) / 2]
            if len(entries) == model['triangleCount'] and max(abs(a - b) for a, b in zip(anchor, model['sourceAnchorCells'])) < 1e-6:
                catalog[geometry_identity(entries, scene['textures'])] = model
    result = []
    for group, entries in sorted(groups.items()):
        identity = geometry_identity(entries, scene['textures'])
        if identity not in catalog:
            continue
        model = catalog[identity]
        path = Path(model['path'])
        if digest(path) != model['sha256']:
            raise ValueError(f'Existing single-object source model changed: {model["modelId"]}')
        bounds = entries_bounds(entries)
        anchor = [(bounds[0] + bounds[3]) / 2, bounds[1], (bounds[2] + bounds[5]) / 2]
        result.append({'modelId': model['modelId'], 'path': str(path), 'sha256': model['sha256'],
                       'sourceGroup': group, 'sourceAnchorCells': anchor,
                       'position': {axis: anchor[i] + frame['sourceToNativeTranslation'][i] for i, axis in enumerate(('x', 'y', 'z'))},
                       'rotationDegrees': 0, 'scale': 1, 'triangleCount': len(entries),
                       'evidence': 'existing full single-object GLB matched to original source group; not reexported'})
    return result


def tree_environment_masks(placements, paint, prefix='bw2-tree-', blocks_movement=True):
    groups = defaultdict(list)
    for placed in placements:
        if not placed['modelId'].startswith(prefix):
            continue
        position = placed['position']
        x, z = math.floor(position['x']), math.floor(position['z'])
        if not (0 <= x < paint['width'] and 0 <= z < paint['depth']):
            continue
        level = paint['heightLevels'][z * paint['width'] + x]
        if level is None:
            continue
        offset = [round(position['x'] - x - .5, 8),
                  round(position['y'] - level * paint['levelHeight'], 8),
                  round(position['z'] - z - .5, 8)]
        groups[placed['modelId'], tuple(offset)].append({'x': x, 'z': z})
    return [{'modelId': model, 'cellMask': cells, 'targetsSpatialTerrain': True, 'cellSpacing': 1,
             'spatialOffset': {'x': offset[0], 'y': offset[1], 'z': offset[2]},
             'rotationDegrees': 0, 'scale': 1, 'blocksMovement': blocks_movement,
             'evidence': 'source centers and visual offsets preserved; trunk collision advice remains separate'}
            for (model, offset), cells in sorted(groups.items())]


def cliff_recipe(scene, frame):
    result = []
    for surface in scene['surfaces']:
        if 'gake' not in surface.material.lower():
            continue
        result.append({'group': surface.group, 'geometry': surface.geometry, 'material': surface.material,
                       'texture': surface.texture, 'wraps': surface.wraps, 'sourceTriangles': surface.triangles,
                       'nativeTranslation': frame['sourceToNativeTranslation'],
                       'normals': [normal(triangle) for triangle in surface.triangles],
                       'purpose': 'source face/profile oracle for native height edges and kit sockets; not a placeable regional asset'})
    return result


def native_texture_atlases(scene, frame, paint, output):
    city = {'id': 'route-19' if scene['id'] == 'rom-route19' else 'pavonnay'}
    surfaces = [Surface(s.group, s.geometry, s.material, s.texture, s.wraps, s.opacity,
                        [t for t in s.triangles if ground_triangle(city, s, t)], s.terrain)
                for s in scene['surfaces'] if floor_kind(city, s)]
    surfaces = [s for s in surfaces if s.triangles]
    translation = frame['sourceToNativeTranslation']
    cells = cell_triangles(surfaces, [-translation[0], 0, -translation[2]], frame['width'], frame['depth'])
    images = {name: Image.open(BytesIO(data)).convert('RGBA') for name, data in scene['textures'].items()}
    output_rows = []
    for kind in ('terrain', 'path'):
        variants = {}
        connections = []
        for (x, z), entries in sorted(cells.items(), key=lambda value: (value[0][1], value[0][0])):
            if not any(floor_kind(city, surface) == kind for surface, _ in entries):
                continue
            tile = raster_tile(entries, x - translation[0], z - translation[2], images, kind, city)
            if tile.getbbox() is None:
                continue
            identity = sha256(tile.tobytes()).hexdigest()
            if identity not in variants:
                variants[identity] = {'index': len(variants), 'image': tile,
                                      'sourceCell': {'x': x - translation[0], 'z': z - translation[2]},
                                      'sourceMaterials': sorted({s.material for s, _ in entries if floor_kind(city, s) == kind})}
            connections.append({'x': x, 'z': z, 'variantIndex': variants[identity]['index']})
        if not variants:
            continue
        columns = math.ceil(math.sqrt(len(variants)))
        rows = math.ceil(len(variants) / columns)
        atlas = Image.new('RGBA', (columns * 16, rows * 16))
        variant_rows = []
        for identity, variant in variants.items():
            index = variant['index']
            column, row = index % columns, index // columns
            atlas.paste(variant['image'], (column * 16, row * 16))
            variant_rows.append({'index': index, 'column': column, 'row': row, 'rgbaSha256': identity,
                                 'sourceCell': variant['sourceCell'], 'sourceMaterials': variant['sourceMaterials']})
        path = output / 'native-tiles' / frame['mapId'] / (kind + '-source-uv.png')
        path.parent.mkdir(parents=True, exist_ok=True)
        atlas.save(path)
        output_rows.append({'kind': kind, 'file': str(path.relative_to(output)), 'sha256': digest(path),
                            'tileSizePixels': 16, 'columns': columns, 'rows': rows, 'variantCount': len(variants),
                            'variants': variant_rows, 'sourceConnections': connections,
                            'generation': 'nearest sampling original textures through original source UV and vertex colors',
                            'usage': 'native SmartTile materials and path/terrain surfaces on 3D relief; never GLB cell placements',
                            'rulesStatus': 'exact source cell variants/connections supplied; generic neighbor-rule classification not inferred'})
    return output_rows


def grass_edge_units(scene, frame, paint, output, sources, models):
    if scene['id'] != 'rom-route19':
        return []
    first = 'map-route19-0/terrain-route19-0'
    common = clip_selected(select_entries(scene['surfaces'], GRASS_MATERIALS, first), [11, 7, 12, 8])
    common_model = next(model for model in models if model['id'] == 'bw2-tallgrass-three-layer')
    shapes = {geometry_identity(common, scene['textures']): common_model}
    placements = []
    translation = frame['sourceToNativeTranslation']
    cells = [{**cell, 'sourceCoverageRatio': 1} for cell in paint['tallGrass']['fullCoverageCells']]
    cells += paint['tallGrass']['partialCoverageCells']
    for cell in cells:
        x, z = cell['x'] - translation[0], cell['z'] - translation[2]
        entries = clip_selected(select_entries(scene['surfaces'], GRASS_MATERIALS), [x, z, x + 1, z + 1])
        identity = geometry_identity(entries, scene['textures'])
        bounds = entries_bounds(entries)
        anchor = [(bounds[0] + bounds[3]) / 2, bounds[1], (bounds[2] + bounds[5]) / 2]
        if identity not in shapes:
            support = [anchor[0], bounds[1] - .125, anchor[2]]
            role = 'edge' if cell['sourceCoverageRatio'] < 1 else 'uv-variant'
            specification = unit(scene['id'], 'bw2-tallgrass-' + role + '-' + identity[:12], 'vegetation', entries,
                                 support, GRASS_MATERIALS, [1, .5, 1], scopeMapId=frame['mapId'],
                                 orientation='fixed_source_horizontal_planes', collision={'kind': 'none'},
                                 purpose='source-clipped one-cell geometry and UV variant preserving all three layers')
            model = emit_unit(specification, scene, output, sources)
            shapes[identity] = model
            models.append(model)
        placed = placement(shapes[identity], frame, anchor, 'exact_one_cell_source_grass_geometry_and_uv')
        placed.update(cell={'x': cell['x'], 'z': cell['z']}, sourceCoverageRatio=cell['sourceCoverageRatio'])
        placements.append(placed)
    return placements


def tree_candidates(scene):
    for surface in scene['surfaces']:
        if surface.material != 'ki02c':
            continue
        for index in range(0, len(surface.triangles), 2):
            pair = [(surface, t) for t in surface.triangles[index:index + 2]]
            bounds = entries_bounds(pair)
            width, depth = bounds[3] - bounds[0], bounds[5] - bounds[2]
            if abs(width / 2 - round(width / 2)) > 1e-6 or abs(depth / 2 - round(depth / 2)) > 1e-6:
                raise ValueError('Tree repetition does not follow a measured two-cell source period')
            for z in range(round(depth / 2)):
                for x in range(round(width / 2)):
                    rectangle = [bounds[0] + 2 * x, bounds[2] + 2 * z, bounds[0] + 2 * x + 2, bounds[2] + 2 * z + 2]
                    candidates = select_entries(scene['surfaces'], TREE_MATERIALS, surface.group)
                    candidates = [(s, t) for s, t in candidates if min(v[1] for v in t) >= bounds[1] - 1e-6
                                  and max(v[1] for v in t) <= bounds[1] + 3.5]
                    entries = clip_selected(candidates, rectangle)
                    yield entries, rectangle, bounds[1], surface.group


def geometry_identity(entries, textures=None):
    bounds = entries_bounds(entries)
    anchor = [(bounds[0] + bounds[3]) / 2, bounds[1], (bounds[2] + bounds[5]) / 2]
    faces = defaultdict(list)
    for surface, triangle in normalized_uv_entries(entries):
        direction = tuple(normal(triangle))
        distance = round(sum(direction[i] * (triangle[0][i] - anchor[i]) for i in range(3)), 6)
        texture_identity = sha256(textures[surface.texture]).hexdigest() if textures is not None else surface.texture
        faces[(texture_identity, tuple(surface.wraps), surface.opacity, direction, distance)].extend(triangle)
    signature = []
    for key, vertices in sorted(faces.items()):
        phase = [math.floor(min(v[i + 3] for v in vertices) + 1e-7) if mode == 'WRAP'
                 else 2 * math.floor(min(v[i + 3] for v in vertices) / 2) if mode == 'MIRROR'
                 else 0 for i, mode in enumerate(key[1])]
        unique = {tuple(round(v[i] - anchor[i], 6) if i < 3 else round(v[i] - phase[i - 3], 6)
                        if i < 5 else round(v[i], 6) for i in range(8)) for v in vertices}
        unique = {tuple(0.0 if value == 0 else value for value in vertex) for vertex in unique}
        position_bounds = [min(v[i] for v in unique) for i in range(3)] + [max(v[i] for v in unique) for i in range(3)]
        extrema = [v for v in unique if sum(abs(v[i] - position_bounds[i]) < 1e-6 or abs(v[i] - position_bounds[i + 3]) < 1e-6 for i in range(3)) == 3]
        axes = sorted(range(3), key=lambda axis: abs(key[3][axis]))[:2]
        basis = None
        for a in extrema:
            for b in extrema:
                for c in extrema:
                    denominator = (b[axes[0]] - a[axes[0]]) * (c[axes[1]] - a[axes[1]]) - (b[axes[1]] - a[axes[1]]) * (c[axes[0]] - a[axes[0]])
                    if abs(denominator) > 1e-8:
                        basis = a, b, c, denominator
                        break
                if basis:
                    break
            if basis:
                break
        affine = basis is not None
        if basis:
            a, b, c, denominator = basis
            x, z = axes
            for v in unique:
                u = ((v[x] - a[x]) * (c[z] - a[z]) - (v[z] - a[z]) * (c[x] - a[x])) / denominator
                w = ((b[x] - a[x]) * (v[z] - a[z]) - (b[z] - a[z]) * (v[x] - a[x])) / denominator
                if any(abs(v[i] - ((1 - u - w) * a[i] + u * b[i] + w * c[i])) > 1e-5 for i in range(3, 8)):
                    affine = False
                    break
        area = sum(math.sqrt(sum(axis * axis for axis in cross(*vertices[i:i + 3]))) / 2
                   for i in range(0, len(vertices), 3))
        signature.append([key, round(area, 5), sorted(extrema) if affine else sorted(unique)])
    return sha256(json.dumps(signature, sort_keys=True).encode()).hexdigest()


def build(args):
    source_roots = [args.corpus_root.resolve(), args.route_source_root.resolve(), args.nitro_root.resolve(), args.project_root.resolve()]
    output = args.output_root.resolve()
    if any(output == root or output.is_relative_to(root) for root in source_roots):
        raise ValueError('Derived output must stay outside every read-only source/project root')
    previous_files = []
    if (output / 'manifest.json').exists():
        previous = json.loads((output / 'manifest.json').read_text())
        if previous.get('tool') != str(Path(__file__).resolve()):
            raise ValueError('Output directory belongs to another generator')
        previous_files = [output / model['file'] for model in previous['models']]
    scenes = [load_scene(args.route_source_root, 'rom-route19', True), load_scene(args.corpus_root, '587455')]
    sources = NitroSources(args.nitro_root, {s.material for scene in scenes for s in scene['surfaces']})
    hashes_before = {str(scene['root'] / scene['record']['local_path']): digest(scene['root'] / scene['record']['local_path']) for scene in scenes}
    models = []
    recipes = {}
    by_shape = {}
    texture_assets = []
    for scene in scenes:
        frame = native_frame(args.project_root, scene)
        specifications = route_units(scene['surfaces']) if scene['id'] == 'rom-route19' else pavonnay_units(scene['surfaces'])
        emitted = [emit_unit(specification, scene, output, sources) for specification in specifications]
        models.extend(emitted)
        samples = [placement(model, frame, evidence='catalog_source_sample_not_full_map_placement') for model in emitted]
        placements = object_recipe(scene, frame, emitted)
        by_shape.update({geometry_identity(specification['entries'], scene['textures']): model
                         for specification, model in zip(specifications, emitted) if specification['family'] == 'trees'})
        tree_count = 0
        tree_area = 0
        failures = []
        for entries, rectangle, height, group in tree_candidates(scene):
            shape = geometry_identity(entries, scene['textures'])
            if shape not in by_shape:
                bounds = entries_bounds(entries)
                x, z = (bounds[0] + bounds[3]) / 2, (bounds[2] + bounds[5]) / 2
                support, evidence = source_support(scene['surfaces'], x, z, height, 'route-19' if scene['id'] == 'rom-route19' else 'pavonnay')
                specification = unit(scene['id'], 'bw2-tree-source-' + shape[:12], 'trees', entries, support,
                                     TREE_MATERIALS, [2, 3.5, 2], supportEvidence=evidence,
                                     collision={'kind': 'advised_trunk', 'sourceAuthored': False,
                                                'centerLocalXZ': [0, 0], 'width': .5, 'depth': .5})
                try:
                    model = emit_unit(specification, scene, output, sources)
                except ValueError as error:
                    failures.append({'group': group, 'sourceBoundsXZ': rectangle, 'reason': str(error)})
                    continue
                by_shape[shape] = model
                models.append(model)
            model = by_shape[shape]
            bounds = entries_bounds(entries)
            anchor = [(bounds[0] + bounds[3]) / 2, bounds[1], (bounds[2] + bounds[5]) / 2]
            if not any(p['modelId'] == model['id'] and p['sourceAnchorCells'] == anchor for p in placements):
                placed = placement(model, frame, anchor, 'measured_source_repetition_geometry_and_uv_match')
                support, evidence = source_support(scene['surfaces'], anchor[0], anchor[2], height,
                                                  'route-19' if scene['id'] == 'rom-route19' else 'pavonnay')
                placed.update(sourceSupportAnchor=support, supportAnchorLocal=[support[i] - anchor[i] for i in range(3)], supportEvidence=evidence)
                placements.append(placed)
            tree_count += 1
            tree_area += 4
        source_tree_area = sum(projected_area(t) for s in scene['surfaces'] if s.material == 'ki02c' for t in s.triangles)
        paint = paint_recipe(scene, frame)
        paint['nativeTextureAtlases'] = native_texture_atlases(scene, frame, paint, output)
        paint['tallGrass']['edgePlacements'] = grass_edge_units(scene, frame, paint, output, sources, models)
        paint['tallGrass']['sourceExactEnvironmentMasks'] = tree_environment_masks(paint['tallGrass']['edgePlacements'], paint,
                                                                                 'bw2-tallgrass-', False)
        paint['tallGrass']['recommendedMaskPolicy'] = 'use sourceExactEnvironmentMasks including UV variants and both edge shapes; never paint full cards over partial edge cells'
        tree_masks = tree_environment_masks(placements, paint)
        covered_tree_mask_placements = sum(len(mask['cellMask']) for mask in tree_masks)
        recipes[frame['mapId']] = {**frame, 'placements': placements, 'catalogSourceSamples': samples,
            'existingSingleObjectResources': existing_object_recipe(args.project_root, scene, frame),
            'areas': source_areas(scene, frame),
            'strokes': fence_strokes(scene, frame), 'nativePaint': paint,
            'treeEnvironmentMasks': tree_masks, 'cliffSourceProfiles': cliff_recipe(scene, frame),
            'coverage': {'treeUnits': tree_count,
            'treeSourceProjectedAreaCells': source_tree_area, 'treeCoveredProjectedAreaCells': tree_area,
            'treeRejectedUnits': failures, 'treeCoverageRatio': tree_area / source_tree_area if source_tree_area else 0,
            'treeEnvironmentMaskPlacements': covered_tree_mask_placements,
            'treePlacementsRequiringExplicitSupport': tree_count - covered_tree_mask_placements,
            'supportCells': len(paint['sourceCellSamples']), 'missingSupportCells': paint['missingSupportCells'],
            'tallGrassCenterMaskCells': len(paint['tallGrass']['cellMask']),
            'tallGrassPartialEdgeCells': len(paint['tallGrass']['partialCoverageCells']),
            'scope': 'tree repetition exact; terrain cell-center and source boundaries qualified; full map visual acceptance pending'},
            'limits': ['Collision footprints are advised, not decoded from ROM collision data',
                       'Native terrain classification/height quantization and visual review remain separate gates',
                       'No water-drop source geometry is present in either source scene; none invented']}
        texture_names = {s.texture for s in scene['surfaces'] if floor_kind({'id': 'route-19' if scene['id'] == 'rom-route19' else 'pavonnay'}, s)
                         or s.material in GRASS_MATERIALS + ['hana01_1', 'kisetu_hana', 'ike01', 'shore01']
                         or 'gake' in s.material.lower()}
        texture_names.update(texture['member'] for model in models if model['sourceId'] == scene['id'] for texture in model['textureSources'])
        for name in sorted(texture_names):
            path = output / 'textures' / scene['id'] / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(scene['textures'][name])
            with Image.open(BytesIO(scene['textures'][name])) as image:
                size = list(image.size)
            texture_assets.append({'sourceId': scene['id'], 'member': name, 'file': str(path.relative_to(output)),
                                   'sha256': digest(path), 'pixelSize': size,
                                   'generation': 'unchanged original source PNG bytes'})
    unchanged = all(digest(Path(path)) == value for path, value in hashes_before.items())
    if not unchanged:
        raise ValueError('Read-only source archive changed during extraction')
    manifest = {'schemaVersion': 1, 'tool': str(Path(__file__).resolve()), 'toolSha256': digest(Path(__file__)),
                'sourceUnitsPerCell': 16, 'sourcesReadOnlyVerified': unchanged,
                'sources': [scene['provenance'] for scene in scenes], 'models': models,
                'sourceTextureAssets': texture_assets,
                'coverage': {key: recipe['coverage'] for key, recipe in recipes.items()},
                'qualityOrder': ['verify source hashes and triangle/material family selectors',
                                 'verify native support, cliff sockets, source pivots, narrow trunk bounds',
                                 'apply native terrain/path masks then fence strokes then environment masks',
                                 'reconstruct a small Route19 slice from blank with library modules only',
                                 'compare source and native renders at equal camera/scale before wider reconstruction'],
                'limits': ['No regional forest/detail/water GLB is produced',
                           'Static DAE node/joint animations are rejected by source_scene; material tracks use the pinned Nitro corpus',
                           'Animation frame rate remains an explicit 60 Hz assumption from the existing source converter']}
    write_json(output / 'manifest.json', manifest)
    write_json(output / 'reconstruction_recipe.json', {'schemaVersion': 1, 'maps': recipes})
    current_files = {model['file'] for model in models}
    for path in previous_files:
        resolved = path.resolve()
        if not resolved.is_relative_to(output / 'models'):
            raise ValueError('Previous generated file escapes the output models directory')
        if str(path.relative_to(output)) not in current_files and path.is_file():
            path.unlink()
    print(json.dumps({'output': str(output), 'models': len(models), 'families': dict(Counter(model['family'] for model in models)),
                      'maps': {key: {'placements': len(recipe['placements']), 'areas': len(recipe['areas']),
                                    'strokes': len(recipe['strokes']), 'coverage': recipe['coverage']}
                               for key, recipe in recipes.items()}}, ensure_ascii=False))


def fence_strokes(scene, frame):
    result = []
    for surface in scene['surfaces']:
        if surface.material in ('out_65_saku', 'C12_saku01'):
            pairs = {'out_65_saku': [(4, 5), (8, 9), (14, 15)], 'C12_saku01': [(2, 3), (4, 5), (6, 7)]}[surface.material]
            for first, second in pairs:
                triangle = surface.triangles[first]
                points = [triangle[0][:3], triangle[1][:3]]
                result.append({'family': 'fences', 'modelId': 'bw2-pavonnay-fence-straight' if surface.material == 'out_65_saku' else 'bw2-pavonnay-railing-straight',
                               'sourceGroup': surface.group, 'sourceMaterial': surface.material,
                               'sourceTriangleIndices': [first, second], 'sourcePoints': points,
                               'nativePoints': [[point[i] + frame['sourceToNativeTranslation'][i] for i in range(3)] for point in points],
                               'sourceTriangles': surface.triangles[first:second + 1],
                               'unitSpacingCells': 1,
                               'uvPolicy': 'source layer UV periods and phases are explicit; representative unit repetition is not exact for these strokes'})
            continue
        if surface.material != 'saku01a':
            continue
        for index in range(0, len(surface.triangles), 6):
            entries = [(surface, t) for t in surface.triangles[index:index + 6]]
            bounds = entries_bounds(entries)
            along_x = bounds[3] - bounds[0] > bounds[5] - bounds[2]
            center_x, center_z = (bounds[0] + bounds[3]) / 2, (bounds[2] + bounds[5]) / 2
            points = [[bounds[0], 1, center_z], [bounds[3], 1, center_z]] if along_x else [[center_x, 1, bounds[2]], [center_x, 1, bounds[5]]]
            result.append({'family': 'fences', 'modelId': 'bw2-fence-straight', 'sourceGroup': surface.group,
                           'sourceTriangleIndices': list(range(index, index + 6)), 'sourcePoints': points,
                           'nativePoints': [[p[i] + frame['sourceToNativeTranslation'][i] for i in range(3)] for p in points],
                           'unitSpacingCells': 1, 'uvRepeatsPerCell': 2,
                           'endpointPolicy': 'merge source junctions before expanding units; preserve original endpoints'})
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--corpus-root', type=Path, required=True)
    parser.add_argument('--route-source-root', type=Path, required=True)
    parser.add_argument('--nitro-root', type=Path, required=True)
    parser.add_argument('--project-root', type=Path, required=True)
    parser.add_argument('--output-root', type=Path, required=True)
    build(parser.parse_args())


if __name__ == '__main__':
    main()

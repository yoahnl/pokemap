import argparse
from collections import defaultdict
from hashlib import sha256
from io import BytesIO
import json
import math
import os
from pathlib import Path
import re
import shutil
import sys
import tempfile

from PIL import Image

sys.dont_write_bytecode = True
REPOSITORY = Path(__file__).resolve().parents[2]
sys.path[:0] = [str(REPOSITORY / 'tools/source_geometry'), str(REPOSITORY / 'tools/scripts'),
               str(Path(__file__).resolve().parent)]
from city_geometry import Surface, barycentric, cell_triangles, interpolate, projected_area, source_scene, union_rectangles
from city_ground import floor_kind, ground_triangle, pixel_of, raster_tile
from city_models import component_triangles, entries_bounds, write_glb
from convert_source_asset_pack import clip_polygon, cross, triangulate
from material_animation import NitroSources, animated_material_document, glb_bytes, read_glb, require_bindings, source_bytes
from source_policy import require_source_policy


def digest(path):
    return sha256(path.read_bytes()).hexdigest()

def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False, allow_nan=False) + '\n')

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

def unit(source_id, name, family, entries, support, materials, max_size, **extra):
    return {'id': name, 'sourceId': source_id, 'family': family, 'entries': entries,
            'support': support, 'materials': materials, 'maxSize': max_size, **extra}

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

def placement(model, frame, source_anchor=None, evidence='source_unit_exact'):
    anchor = source_anchor or model['sourceAnchorCells']
    return {'modelId': model['id'], 'sourceAnchorCells': anchor,
            'position': {axis: anchor[i] + frame['sourceToNativeTranslation'][i] for i, axis in enumerate(('x', 'y', 'z'))},
            'rotationDegrees': 0, 'scale': 1, 'supportAnchorLocal': model['supportAnchorLocal'], 'evidence': evidence}

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


def source_support(surfaces, x, z, visual_y, *, policy):
    city = {'sourcePolicy': policy}
    hits = []
    for surface in surfaces:
        if floor_kind(city, surface) is None:
            continue
        for triangle in surface.triangles:
            if not ground_triangle(city, surface, triangle):
                continue
            weights = barycentric(x, z, triangle)
            if weights is not None and min(weights) >= -1e-6:
                height = interpolate(triangle, weights, 1)
                if height <= visual_y + 1e-6:
                    hits.append(height)
    if not hits:
        raise ValueError('No declared source support surface at the requested point')
    return [x, max(hits), z]


def animation_context(scene):
    materials = defaultdict(lambda: {'textures': set(), 'groups': set()})
    for surface in scene['surfaces']:
        materials[surface.material]['textures'].add(surface.texture)
        materials[surface.material]['groups'].add(surface.group)
    return {'materials': {name: {key: sorted(values) for key, values in info.items()}
                          for name, info in materials.items()}}


def emit_unit(specification, scene, output, *, animation=None, sources=None):
    bounds = validate_unit(specification['entries'], specification)
    path = output / 'models' / (specification['id'] + '.glb')
    path.parent.mkdir(parents=True, exist_ok=True)
    write_glb(path, normalized_uv_entries(specification['entries']), scene['textures'])
    document, binary = read_glb(path.read_bytes())
    materials = defaultdict(set)
    for surface, _ in specification['entries']:
        materials[surface.texture].add(surface.material)
    for material in document['materials']:
        names = sorted(materials[material['name'].split('@')[0]])
        material.setdefault('extras', {})['sourceMaterials'] = names
        if len(names) == 1:
            material['extras']['aveluneNitroMaterial'] = names[0]
    evidence = []
    animated = None
    if animation is not None:
        animated, evidence, unsupported = animated_material_document(
            document, binary, {}, animation_context(scene), sources, animation['frameRate'],
            bindings=animation['bindings'], clip_name=animation['clipName'])
        if unsupported or animated is None:
            raise ValueError('Declared animation could not be resolved completely')
        document = animated
        document.setdefault('extras', {})['aveluneAnimationSource'] = {
            'inventorySha256': animation['inventorySha256'], 'frameRate': animation['frameRate'],
            'frameRateEvidence': animation['frameRateEvidence'], 'materials': evidence}
    document.setdefault('extras', {})['sourceUnit'] = {'id': specification['id'], 'family': specification['family']}
    encoded = glb_bytes(document, binary)
    path.write_bytes(encoded)
    geometry = unit_geometry(specification['entries'], specification['support'])
    attributes = {key: value for key, value in specification.items()
                  if key not in {'entries', 'support', 'maxSize', 'materials'}}
    attributes['socketsLocal'] = [[point[i] - geometry['sourceAnchorCells'][i] for i in range(3)]
                                  for point in specification.get('socketsSource', [])]
    return {**attributes, **geometry, 'file': str(path.relative_to(output)),
            'sha256': sha256(encoded).hexdigest(), 'byteLength': len(encoded),
            'triangleCount': len(specification['entries']), 'pivot': [0, 0, 0],
            'bounds': [bounds[i] - geometry['sourceAnchorCells'][i % 3] for i in range(6)],
            'sourceReferences': reference_rows(scene, specification['entries']),
            'textureSources': texture_rows(scene, specification['entries']),
            'materials': [{'name': name, 'texture': surface.texture, 'wraps': surface.wraps,
                           'opacity': surface.opacity,
                           'sourceTriangleCount': sum(s.material == name for s, _ in specification['entries'])}
                          for name, surface in sorted({s.material: s for s, _ in specification['entries']}.items())],
            'animation': {'status': 'declared_material_track' if animated else 'static',
                          'sourceEvidence': evidence,
                          'recommendedAnimationIndex': len(document.get('animations', [])) if animated else None}}


def _keys(value, required, optional=()):
    if not isinstance(value, dict) or not set(required) <= set(value) or not set(value) <= set(required) | set(optional):
        raise ValueError('Unknown or missing source unit recipe fields')


def _identifier(value):
    if not isinstance(value, str) or re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_.-]{0,127}', value) is None:
        raise ValueError('Expected a safe source unit identifier')


def _text(value):
    if not isinstance(value, str) or not value.strip() or len(value) > 4096:
        raise ValueError('Expected a bounded nonempty source description')


def _vector(value, size):
    if not isinstance(value, list) or len(value) != size or any(
            type(item) not in (int, float) or not math.isfinite(item) or abs(item) > 1000000 for item in value):
        raise ValueError('Expected a bounded finite source vector')


def _strings(value, *, nonempty=False):
    if not isinstance(value, list) or len(value) > 1024 or nonempty and not value:
        raise ValueError('Invalid source selection collection')
    for item in value:
        _text(item)
    if len(set(value)) != len(value):
        raise ValueError('Source selection values must be unique')


def require_recipe(value):
    _keys(value, {'schemaVersion', 'id', 'sources', 'units', 'provenance'})
    if type(value['schemaVersion']) is not int or value['schemaVersion'] != 1:
        raise ValueError('Unsupported source unit recipe version')
    if len(json.dumps(value, allow_nan=False).encode()) > 2097152:
        raise ValueError('Source unit recipe exceeds 2 MiB')
    _identifier(value['id'])
    if not isinstance(value['provenance'], dict):
        raise ValueError('Source provenance must be an object')
    if not isinstance(value['sources'], list) or not 1 <= len(value['sources']) <= 32:
        raise ValueError('Expected bounded explicit sources')
    if not isinstance(value['units'], list) or not 1 <= len(value['units']) <= 512:
        raise ValueError('Expected bounded explicit units')
    source_ids = set()
    for source in value['sources']:
        _keys(source, {'id', 'input', 'record', 'sourcePolicy', 'frame'}, {'sourceCrop'})
        _identifier(source['id'])
        _identifier(source['input'])
        if source['id'] in source_ids:
            raise ValueError('Duplicate source identity')
        source_ids.add(source['id'])
        record = source['record']
        _keys(record, {'id', 'name', 'local_path', 'sha256', 'page_url'})
        for item in record.values():
            _text(item)
        if re.fullmatch('[0-9a-f]{64}', record['sha256']) is None:
            raise ValueError('Source archive requires a SHA-256 digest')
        require_source_policy(source['sourcePolicy'])
        frame = source['frame']
        _keys(frame, {'mapId', 'sourceToNativeTranslation', 'width', 'depth', 'levelHeight'})
        _identifier(frame['mapId'])
        _vector(frame['sourceToNativeTranslation'], 3)
        if any(type(frame[key]) is not int or not 1 <= frame[key] <= 4096 for key in ['width', 'depth']):
            raise ValueError('Invalid native frame dimensions')
        if type(frame['levelHeight']) not in (int, float) or not math.isfinite(frame['levelHeight']) or frame['levelHeight'] <= 0:
            raise ValueError('Native level height must be positive')
        if 'sourceCrop' in source:
            crop = source['sourceCrop']
            _keys(crop, {'planes', 'reason'})
            _text(crop['reason'])
            if not isinstance(crop['planes'], list) or not 1 <= len(crop['planes']) <= 6:
                raise ValueError('Source crop must contain bounded planes')
            for plane in crop['planes']:
                _keys(plane, {'axis', 'boundary', 'keepGreater'})
                if type(plane['axis']) is not int or plane['axis'] not in (0, 1, 2) or type(plane['keepGreater']) is not bool:
                    raise ValueError('Invalid source crop plane')
                _vector([plane['boundary']], 1)
    unit_ids = set()
    for declaration in value['units']:
        _keys(declaration, {'id', 'sourceId', 'family', 'selection', 'clipBounds', 'support',
                            'maxSize', 'maxTriangles', 'collision', 'socketsSource', 'quarterTurns', 'corner', 'animation'})
        for key in ['id', 'sourceId', 'family']:
            _identifier(declaration[key])
        if declaration['id'] in unit_ids or declaration['sourceId'] not in source_ids:
            raise ValueError('Duplicate unit or unknown source')
        unit_ids.add(declaration['id'])
        _vector(declaration['maxSize'], 3)
        if any(item <= 0 for item in declaration['maxSize']) or type(declaration['maxTriangles']) is not int or not 1 <= declaration['maxTriangles'] <= 100000:
            raise ValueError('Invalid source unit geometry budget')
        selection = declaration['selection']
        _keys(selection, {'materials', 'groups', 'triangleIndices', 'allVerticesBounds'})
        _strings(selection['materials'], nonempty=True)
        _strings(selection['groups'])
        indices = selection['triangleIndices']
        if not isinstance(indices, dict) or not set(indices) <= set(selection['materials']):
            raise ValueError('Source triangle selectors must reference selected materials')
        for rows in indices.values():
            if not isinstance(rows, list) or len(rows) > 100000 or any(type(index) is not int or index < 0 for index in rows) or len(set(rows)) != len(rows):
                raise ValueError('Invalid source triangle indices')
        for bounds, size in [(selection['allVerticesBounds'], 6), (declaration['clipBounds'], 4)]:
            if bounds is not None:
                _vector(bounds, size)
                if any(bounds[axis] > bounds[axis + size // 2] for axis in range(size // 2)):
                    raise ValueError('Source selection bounds are reversed')
        support = declaration['support']
        if not isinstance(support, dict):
            raise ValueError('Explicit source support is required')
        if support.get('kind') == 'literal':
            _keys(support, {'kind', 'position'})
            _vector(support['position'], 3)
        elif support.get('kind') == 'sampleGround':
            _keys(support, {'kind', 'x', 'z', 'visualY'})
            _vector([support['x'], support['z'], support['visualY']], 3)
        else:
            raise ValueError('Unsupported source support operation')
        collision = declaration['collision']
        if not isinstance(collision, dict) or collision.get('kind') not in {'none', 'bounds', 'separately_authored_footprint'}:
            raise ValueError('Collision policy must be explicit')
        _keys(collision, {'kind', 'bounds'} if collision['kind'] == 'bounds' else {'kind'})
        if collision['kind'] == 'bounds':
            _vector(collision['bounds'], 6)
            if any(collision['bounds'][axis] > collision['bounds'][axis + 3] for axis in range(3)):
                raise ValueError('Collision bounds are reversed')
        if not isinstance(declaration['socketsSource'], list) or len(declaration['socketsSource']) > 256:
            raise ValueError('Invalid source socket collection')
        for point in declaration['socketsSource']:
            _vector(point, 3)
        if type(declaration['quarterTurns']) is not int or not 0 <= declaration['quarterTurns'] <= 3:
            raise ValueError('Invalid source rotation')
        if declaration['corner'] not in (None, 'inner', 'outer'):
            raise ValueError('Unsupported source corner operation')
        animation = declaration['animation']
        if animation is not None:
            _keys(animation, {'input', 'inventorySha256', 'frameRate', 'frameRateEvidence', 'modelSources', 'bindings', 'clipName'})
            _identifier(animation['input'])
            _text(animation['frameRateEvidence'])
            _text(animation['clipName'])
            if re.fullmatch('[0-9a-f]{64}', animation['inventorySha256']) is None or type(animation['frameRate']) not in (int, float) or not math.isfinite(animation['frameRate']) or not 0 < animation['frameRate'] <= 1000:
                raise ValueError('Invalid explicit source animation clock')
            require_bindings(animation['bindings'])
            if not isinstance(animation['modelSources'], list) or not animation['modelSources'] or len(animation['modelSources']) > 4096:
                raise ValueError('Explicit animation model witnesses are required')
            for model in animation['modelSources']:
                _keys(model, {'relativePath', 'sha256'})
                _text(model['relativePath'])
                if re.fullmatch('[0-9a-f]{64}', model['sha256']) is None:
                    raise ValueError('Invalid source model digest')
    return value


def load_scene(root, declaration):
    record = declaration['record']
    source_bytes(root, record['local_path'], record['sha256'])
    if 'sourceCrop' in declaration:
        from build_routes import route_source
        surfaces, textures, provenance = route_source(root, {**record, 'sourcePolicy': declaration['sourcePolicy'],
                                                           'sourceCrop': declaration['sourceCrop']})
    else:
        surfaces, textures, provenance = source_scene(root, record, policy=declaration['sourcePolicy'])
    return {'id': declaration['id'], 'root': root, 'record': record, 'surfaces': surfaces,
            'textures': textures, 'provenance': provenance, 'sourcePolicy': declaration['sourcePolicy']}


def selected_unit(scene, declaration):
    selection = declaration['selection']
    entries = [(surface, triangle) for surface in scene['surfaces']
               if surface.material in selection['materials'] and (not selection['groups'] or surface.group in selection['groups'])
               for index, triangle in enumerate(surface.triangles)
               if not selection['triangleIndices'] or index in selection['triangleIndices'].get(surface.material, [])]
    bounds = selection['allVerticesBounds']
    if bounds is not None:
        entries = [(surface, triangle) for surface, triangle in entries
                   if all(bounds[axis] - 1e-6 <= vertex[axis] <= bounds[axis + 3] + 1e-6
                          for vertex in triangle for axis in range(3))]
    if declaration['clipBounds'] is not None:
        entries = clip_selected(entries, declaration['clipBounds'])
    support = declaration['support']
    position = support['position'] if support['kind'] == 'literal' else source_support(
        scene['surfaces'], support['x'], support['z'], support['visualY'], policy=scene['sourcePolicy'])
    specification = unit(scene['id'], declaration['id'], declaration['family'], entries, position,
                         selection['materials'], declaration['maxSize'],
                         maxTriangles=declaration['maxTriangles'], collision=declaration['collision'],
                         socketsSource=declaration['socketsSource'])
    if declaration['corner'] is not None:
        from directed_profiles import compose_corner_profile
        specification = compose_corner_profile(scene, specification, declaration['id'], declaration['corner'])
    if declaration['quarterTurns']:
        from directed_profiles import entries_rotated_about_support
        specification['sourceOriginalReferences'] = reference_rows(scene, specification['entries'])
        specification['entries'] = entries_rotated_about_support(specification['entries'], position, declaration['quarterTurns'])
        cosine, sine = [(1, 0), (0, 1), (-1, 0), (0, -1)][declaration['quarterTurns']]
        specification['socketsSource'] = [[position[0] + cosine * (point[0] - position[0]) + sine * (point[2] - position[2]),
                                           point[1],
                                           position[2] - sine * (point[0] - position[0]) + cosine * (point[2] - position[2])]
                                          for point in specification['socketsSource']]
        specification['sourceNormalizationQuarterTurns'] = declaration['quarterTurns']
    return specification


def build_recipe(recipe, inputs, output_root):
    require_recipe(recipe)
    required = {source['input'] for source in recipe['sources']} | {
        unit['animation']['input'] for unit in recipe['units'] if unit['animation'] is not None}
    if set(inputs) != required:
        raise ValueError('Input roots must match explicit recipe aliases')
    if any(not Path(root).is_absolute() for root in inputs.values()):
        raise ValueError('Input roots must be explicit absolute directories')
    roots = {name: Path(root).resolve(strict=True) for name, root in inputs.items()}
    if any(not root.is_dir() for root in roots.values()):
        raise ValueError('Input roots must be directories')
    output_root = Path(output_root)
    output = output_root.parent.resolve(strict=True) / output_root.name
    if output_root.name in ('', '.', '..') or output.exists() or output.is_symlink():
        raise ValueError('Output must be a new directory')
    if any(output == root or root in output.parents or output in root.parents for root in roots.values()):
        raise ValueError('Output must stay separate from read-only source roots')
    scenes = {row['id']: load_scene(roots[row['input']], row) for row in recipe['sources']}
    specifications = [(row, selected_unit(scenes[row['sourceId']], row)) for row in recipe['units']]
    for row, specification in specifications:
        validate_unit(specification['entries'], specification)
    animation_sources = {}
    for row, _ in specifications:
        animation = row['animation']
        if animation is not None:
            root = roots[animation['input']]
            inventory_bytes = source_bytes(root, 'animation-inventory.json', animation['inventorySha256'])
            key = json.dumps(animation, sort_keys=True)
            if key not in animation_sources:
                animation_sources[key] = NitroSources(root, set(animation['bindings']),
                    model_sources=animation['modelSources'], inventory_bytes=inventory_bytes)
    staging = Path(tempfile.mkdtemp(prefix='.source-unit-', dir=output.parent))
    try:
        models = [emit_unit(specification, scenes[row['sourceId']], staging,
                            animation=row['animation'],
                            sources=animation_sources.get(json.dumps(row['animation'], sort_keys=True)))
                  for row, specification in specifications]
        manifest = {'schemaVersion': 1, 'recipeId': recipe['id'],
                    'recipeSha256': sha256(json.dumps(recipe, sort_keys=True, separators=(',', ':'), allow_nan=False).encode()).hexdigest(),
                    'models': models, 'frames': {row['id']: row['frame'] for row in recipe['sources']},
                    'sourceEvidence': {name: scene['provenance'] for name, scene in scenes.items()},
                    'provenance': recipe['provenance'], 'projectMutationPerformed': False}
        write_json(staging / 'manifest.json', manifest)
        if output.exists() or output.is_symlink():
            raise ValueError('Output appeared during preparation')
        os.rename(staging, output)
        return manifest
    finally:
        if staging.exists():
            shutil.rmtree(staging)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--recipe', required=True, type=Path)
    parser.add_argument('--input', required=True, action='append')
    parser.add_argument('--output-root', required=True, type=Path)
    args = parser.parse_args()
    inputs = {}
    for argument in args.input:
        alias, separator, root = argument.partition('=')
        _identifier(alias)
        if not separator or alias in inputs or not Path(root).is_absolute():
            raise ValueError('Inputs must use unique alias=absolute-directory bindings')
        inputs[alias] = Path(root)
    data = args.recipe.read_bytes()
    if len(data) > 2097152:
        raise ValueError('Source unit recipe exceeds 2 MiB')
    recipe = json.loads(data, parse_constant=lambda value: (_ for _ in ()).throw(ValueError('Nonfinite recipe value')))
    print(json.dumps(build_recipe(recipe, inputs, args.output_root), allow_nan=False))


if __name__ == '__main__':
    main()

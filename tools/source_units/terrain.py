from collections import Counter, defaultdict
from hashlib import sha256
from io import BytesIO
import json
import math
from pathlib import Path
import struct
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
import extract_units as extraction

from extract_units import *


def source_areas(scene, frame, *, area_kinds):
    result = []
    city = {'sourcePolicy': scene['sourcePolicy']}
    for surface in scene['surfaces']:
        kind = floor_kind(city, surface)
        if kind is None and surface.material not in area_kinds:
            continue
        triangles = [triangle for triangle in surface.triangles if projected_area(triangle) > 1e-8
                     and (kind is None or ground_triangle(city, surface, triangle))]
        if not triangles:
            continue
        area_kind = kind or area_kinds[surface.material]
        result.append({'group': surface.group, 'geometry': surface.geometry, 'material': surface.material,
                       'kind': area_kind,
                       'texture': surface.texture, 'wraps': surface.wraps,
                       'projectedAreaCells': sum(projected_area(t) for t in triangles),
                       'sourceTriangles': triangles,
                       'nativeTranslation': frame['sourceToNativeTranslation'],
                       'purpose': 'native terrain/path/environment recipe; never place as a regional mesh'})
    return result

def paint_recipe(scene, frame, *, decal_materials, grass_materials, grass_model_id):
    images = {name: Image.open(BytesIO(data)).convert('RGBA') for name, data in scene['textures'].items()}
    samples = defaultdict(list)
    coverage = defaultdict(float)
    mask_centers = set()
    translation = frame['sourceToNativeTranslation']
    city = {'sourcePolicy': scene['sourcePolicy']}
    for surface in scene['surfaces']:
        kind = floor_kind(city, surface)
        for index, triangle in enumerate(surface.triangles):
            is_floor = (kind is not None and surface.material not in decal_materials
                        and ground_triangle(city, surface, triangle))
            is_grass = surface.material in grass_materials
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
    mask = {'modelId': grass_model_id, 'cellMask': [{'x': x, 'z': z} for x, z in sorted(mask_centers)],
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

def object_recipe(scene, frame, models, *, family):
    result = []
    groups = defaultdict(list)
    for surface in scene['surfaces']:
        if not surface.terrain:
            groups[surface.group].extend((surface, triangle) for triangle in surface.triangles)
    shapes = {}
    for model in models:
        if model['family'] != family or model['sourceId'] != scene['id']:
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

def environment_masks(placements, paint, *, prefix, blocks_movement):
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

def relief_recipe(scene, frame, *, materials):
    result = []
    for surface in scene['surfaces']:
        if surface.material not in materials:
            continue
        result.append({'group': surface.group, 'geometry': surface.geometry, 'material': surface.material,
                       'texture': surface.texture, 'wraps': surface.wraps, 'sourceTriangles': surface.triangles,
                       'nativeTranslation': frame['sourceToNativeTranslation'],
                       'normals': [normal(triangle) for triangle in surface.triangles],
                       'purpose': 'source face/profile oracle for native height edges and kit sockets; not a placeable regional asset'})
    return result

def native_texture_atlases(scene, frame, paint, output):
    city = {'sourcePolicy': scene['sourcePolicy']}
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

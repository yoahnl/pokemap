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

def periodic_entries(entries, period, *, uv_offsets):
    if type(period) not in (int, float) or not math.isfinite(period) or period <= 0:
        raise ValueError('UV period must be positive')
    extraction._vector(uv_offsets, 2)
    return (all(abs(value - 1) < 1e-7 for _, triangle in entries for vertex in triangle for value in vertex[5:])
            and all(abs(vertex[axis] - vertex[position] / period - constant
                   - round(vertex[axis] - vertex[position] / period - constant)) < 1e-6
               for _, triangle in entries for vertex in triangle
               for axis, position, constant in ((3, 0, uv_offsets[0]), (4, 2, uv_offsets[1]))))

def cell_records(scene, frame, material):
    translation = frame['sourceToNativeTranslation']
    surfaces = [surface for surface in scene['surfaces'] if surface.material == material]
    cells = extraction.cell_triangles(surfaces, [-translation[0], 0, -translation[2]],
                                      frame['width'], frame['depth'])
    result = []
    for (x, z), entries in sorted(cells.items(), key=lambda row: (row[0][1], row[0][0])):
        source_x, source_z = x - translation[0], z - translation[2]
        clipped = extraction.clip_selected(entries, [source_x, source_z, source_x + 1, source_z + 1])
        area = sum(extraction.projected_area(triangle) for _, triangle in clipped)
        if area < 1e-8:
            continue
        bounds = extraction.entries_bounds(clipped)
        if bounds[4] - bounds[1] > 1e-6 or area > 1 + 1e-6:
            raise ValueError(f'Water cell mixes levels or overlaps source planes: {material} {x},{z}')
        anchor = [source_x + .5, bounds[1], source_z + .5]
        center_weights = [(surface, triangle, extraction.barycentric(anchor[0], anchor[2], triangle))
                          for surface, triangle in clipped]
        center_hit = next(((surface, triangle, weights) for surface, triangle, weights in center_weights
                           if weights is not None), None)
        result.append({'x': x, 'z': z, 'sourceCell': [source_x, source_z],
                       'anchor': anchor, 'entries': clipped, 'coverage': area,
                       'centerCovered': center_hit is not None,
                       'centerUv': [extraction.interpolate(center_hit[1], center_hit[2], axis)
                                    for axis in (3, 4)] if center_hit is not None else None})
    source_area = sum(extraction.projected_area(triangle) for surface in surfaces for triangle in surface.triangles)
    if abs(source_area - sum(row['coverage'] for row in result)) > 1e-6:
        raise ValueError(f'Water source coverage escapes the native map frame: {material}')
    return result

def identity(row, textures):
    bounds = extraction.entries_bounds(row['entries'])
    offset = [round((bounds[axis] + bounds[axis + 3]) / 2 - row['anchor'][axis], 8)
              for axis in (0, 2)]
    return sha256(json.dumps([extraction.geometry_identity(row['entries'], textures), offset]).encode()).hexdigest()

def reanchor_model(model, anchor):
    delta = [anchor[axis] - model['sourceAnchorCells'][axis] for axis in range(3)]
    path = Path(model['path'])
    document, original = extraction.read_glb(path.read_bytes())
    binary = bytearray(original)
    accessors = {primitive['attributes']['POSITION'] for mesh in document['meshes']
                 for primitive in mesh['primitives']}
    for index in accessors:
        accessor = document['accessors'][index]
        view = document['bufferViews'][accessor['bufferView']]
        if accessor['componentType'] != 5126 or accessor['type'] != 'VEC3' or 'sparse' in accessor:
            raise ValueError('Unexpected water POSITION encoding')
        start = view.get('byteOffset', 0) + accessor.get('byteOffset', 0)
        for vertex_index in range(accessor['count']):
            offset = start + vertex_index * view.get('byteStride', 12)
            values = struct.unpack_from('<fff', binary, offset)
            struct.pack_into('<fff', binary, offset, *(values[axis] - delta[axis] for axis in range(3)))
        for bound in ('min', 'max'):
            if bound in accessor:
                accessor[bound] = [accessor[bound][axis] - delta[axis] for axis in range(3)]
    document['extras']['sourceUnit']['anchorPolicy'] = 'source_cell_center_preserving_clipped_boundary_offset'
    encoded = extraction.glb_bytes(document, bytes(binary))
    path.write_bytes(encoded)
    return {**model, 'sourceAnchorCells': anchor,
            'supportAnchorLocal': [model['sourceSupportAnchor'][axis] - anchor[axis] for axis in range(3)],
            'bounds': [model['sourceBoundsCells'][axis] - anchor[axis % 3] for axis in range(6)],
            'sha256': sha256(encoded).hexdigest(), 'byteLength': len(encoded),
            'anchorPolicy': 'cell_center_for_native_smart_tile_parts'}

def model_part(model_id, offset_y, animation_index):
    return {'source': {'kind': 'model3d', 'modelId': model_id, 'scale': 1,
                       'offsetY': offset_y, 'animationIndex': animation_index, 'followTerrain': False},
            'channel': 'ground', 'drawOrder': 0}


def surface_pattern(layers, translation, *, pattern_id, label, width, depth, tags):
    extraction._identifier(pattern_id)
    extraction._text(label)
    extraction._vector(translation, 3)
    if any(value != round(value) for value in (translation[0], translation[2])):
        raise ValueError('Source phase origins must lie on the declared cell grid')
    if any(type(size) is not int or not 1 <= size <= 64 for size in (width, depth)):
        raise ValueError('Pattern dimensions must be bounded positive integers')
    if not isinstance(layers, list) or not 1 <= len(layers) <= 16:
        raise ValueError('A pattern requires explicit bounded layers')
    extraction._strings(tags)
    for layer in layers:
        extraction._keys(layer, {'phases', 'period', 'sourceY', 'animationIndex'})
        period = layer['period']
        if not isinstance(period, list) or len(period) != 2 or any(type(size) is not int or not 1 <= size <= 64 for size in period):
            raise ValueError('Pattern layer periods must be explicit')
        if not isinstance(layer['phases'], dict) or set(layer['phases']) != {(x, z) for z in range(period[1]) for x in range(period[0])}:
            raise ValueError('Pattern layer requires complete source phase coverage')
        for model in layer['phases'].values():
            extraction._identifier(model)
        extraction._vector([layer['sourceY']], 1)
        if layer['animationIndex'] is not None and (type(layer['animationIndex']) is not int or layer['animationIndex'] < 0):
            raise ValueError('Invalid pattern animation index')
    cells = []
    for z in range(depth):
        for x in range(width):
            parts = [model_part(layer['phases'][int(x - translation[0]) % layer['period'][0],
                                              int(z - translation[2]) % layer['period'][1]],
                                layer['sourceY'] + translation[1], layer['animationIndex']) for layer in layers]
            cells.append({'x': x, 'y': z, 'parts': parts})
    return {'id': pattern_id, 'name': label, 'usage': 'terrain', 'width': width, 'height': depth,
            'repeatMode': 'tiled', 'cells': cells, 'tags': tags}

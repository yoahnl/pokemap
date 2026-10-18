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

def rectangular_faces(scene, *, materials):
    groups = defaultdict(list)
    for surface in scene['surfaces']:
        if surface.material not in materials:
            continue
        for index, triangle in enumerate(surface.triangles):
            normal = extraction.normal(triangle)
            heights = sorted({round(vertex[1], 8) for vertex in triangle})
            if abs(normal[1]) > 1e-6 or max(abs(normal[0]), abs(normal[2])) < .999999 or len(heights) != 2:
                continue
            constant_axis = 0 if abs(normal[0]) > .9 else 2
            along_axis = 2 - constant_axis
            key = (surface.group, surface.material, constant_axis, round(triangle[0][constant_axis], 8),
                   heights[0], heights[1], tuple(normal), surface.texture)
            groups[key].append((surface, index, triangle))
    result = []
    for key, entries in sorted(groups.items()):
        group, material, constant_axis, constant, low, high, normal, texture = key
        along_axis = 2 - constant_axis
        intervals = sorted((min(vertex[along_axis] for vertex in triangle),
                            max(vertex[along_axis] for vertex in triangle), surface, index, triangle)
                           for surface, index, triangle in entries)
        runs = []
        for first, last, surface, index, triangle in intervals:
            if runs and first <= runs[-1]['last'] + 1e-7:
                runs[-1]['last'] = max(last, runs[-1]['last'])
                runs[-1]['entries'].append((surface, triangle))
                runs[-1]['indices'].append(index)
            else:
                runs.append({'first': first, 'last': last, 'entries': [(surface, triangle)], 'indices': [index]})
        for run in runs:
            actual_area = sum(math.sqrt(sum(axis * axis for axis in extraction.cross(*triangle))) / 2
                              for _, triangle in run['entries'])
            expected_area = (run['last'] - run['first']) * (high - low)
            if abs(actual_area - expected_area) > 1e-5:
                continue
            result.append({**run, 'group': group, 'material': material, 'texture': texture,
                           'constantAxis': constant_axis, 'alongAxis': along_axis, 'constant': constant,
                           'low': low, 'high': high, 'normal': list(normal), 'sourceArea': actual_area})
    return result

def profile_identity(face, scene):
    return (scene['id'], face['material'], round(face['high'] - face['low'], 8),
            sha256(scene['textures'][face['texture']]).hexdigest())

def clip_face(face, first, last):
    bounds = [0, 0, 0, 0]
    along_index, constant_index = face['alongAxis'] // 2, face['constantAxis'] // 2
    bounds[along_index] = first
    bounds[along_index + 2] = last
    bounds[constant_index] = face['constant'] - .001
    bounds[constant_index + 2] = face['constant'] + .001
    return extraction.clip_selected(face['entries'], bounds)

def slot_grid(face, frame):
    translation = frame['sourceToNativeTranslation']
    first, last = face['first'] + translation[face['alongAxis']], face['last'] + translation[face['alongAxis']]
    choices = []
    for offset, alignment in ((0, 'gridEdges'), (.5, 'cellCenters')):
        low, high = math.ceil(first + .5 - offset - 1e-7), math.floor(last - .5 - offset + 1e-7)
        if high < low:
            continue
        choices.append((first + last - 2 * first - (high - low + 1), offset, alignment, low, high))
    if not choices:
        return None
    _, offset, alignment, low, high = min(choices)
    constant = face['constant'] + translation[face['constantAxis']]
    constant_slot = math.floor(constant - offset + .5)
    slots = []
    for value in range(low, high + 1):
        x, z = (constant_slot, value) if face['constantAxis'] == 0 else (value, constant_slot)
        if not (0 <= x + offset < frame['width'] and 0 <= z + offset < frame['depth']):
            continue
        level = frame['nativePaint']['heightLevels'][math.floor(z + offset) * frame['width'] + math.floor(x + offset)]
        slots.append({'x': x, 'y': z, 'level': level,
                      'nativeTerrainY': (level or 0) * frame['levelHeight'],
                      'sourceAlongCenter': value + offset - translation[face['alongAxis']]})
    covered = len(slots)
    return {'alignment': alignment, 'offset': offset, 'slots': slots,
            'sourceLengthCells': face['last'] - face['first'], 'coveredFullUnitLengthCells': covered,
            'remainingLengthCells': face['last'] - face['first'] - covered,
            'sourceFirst': face['first'], 'sourceLast': face['last']}

def primitive(model, role, orientation, anchor):
    return {'id': role, 'sourceModelId': model['id'], 'role': role, 'weight': 1,
            'authoredOrientation': orientation,
            'transforms': {'allowFlipX': False, 'allowedQuarterTurns': [0, 1, 2, 3]},
            'anchorWorld': {'x': anchor[0], 'y': anchor[1], 'z': anchor[2]}}

def border_runs(face, model, frame, face_id, grid=None):
    grid = grid or slot_grid(face, frame)
    if grid is None:
        return [], None
    model_along = 0 if model['bounds'][3] - model['bounds'][0] > model['bounds'][5] - model['bounds'][2] else 2
    authored_turns = 0 if model_along == 0 else 1
    primary_turns = 0 if face['alongAxis'] == 0 else 1
    model_normal = model['normals'][0]
    options = []
    for side, side_turns in (('primary', 0), ('inverted', 2)):
        turns = (primary_turns + side_turns - authored_turns) % 4
        angle = -turns * math.pi / 2
        rotated = [math.cos(angle) * model_normal[0] + math.sin(angle) * model_normal[2],
                   -math.sin(angle) * model_normal[0] + math.cos(angle) * model_normal[2]]
        if max(abs(rotated[index] - face['normal'][axis]) for index, axis in enumerate((0, 2))) < 1e-6:
            options.append((side, turns, angle))
    if len(options) != 1:
        raise ValueError('Wall orientation cannot be represented by quarter turns')
    side, turns, angle = options[0]
    difference = [0, 0, 0]
    translation = frame['sourceToNativeTranslation']
    constant_slot = grid['slots'][0]['x' if face['constantAxis'] == 0 else 'y'] + grid['offset'] if grid['slots'] else 0
    difference[face['constantAxis']] = constant_slot - face['constant'] - translation[face['constantAxis']]
    anchor_x = math.cos(angle) * difference[0] - math.sin(angle) * difference[2]
    anchor_z = math.sin(angle) * difference[0] + math.cos(angle) * difference[2]
    groups = []
    for slot in grid['slots']:
        anchor_y = slot['nativeTerrainY'] - face['low'] - translation[1]
        if groups and abs(groups[-1]['anchor'][1] - anchor_y) < 1e-7:
            groups[-1]['slots'].append(slot)
        else:
            groups.append({'anchor': [anchor_x, anchor_y, anchor_z], 'slots': [slot]})
    output = []
    for index, group in enumerate(groups):
        nodes = group['slots']
        orientation = 'east' if model_along == 0 else 'south'
        output.append({'id': face_id + '-' + str(index), 'sourceModelId': model['id'],
            'template': 'connectedLine', 'lineSide': side, 'alignment': grid['alignment'],
            'strokes': [{'id': 'source-face', 'points': [{'x': node['x'], 'y': node['y']} for node in nodes], 'closed': False}] if len(nodes) > 1 else [],
            'singleUnitSlots': [{'x': node['x'], 'y': node['y']} for node in nodes] if len(nodes) == 1 else [],
            'primitiveSuggestions': [primitive(model, role, orientation, group['anchor'])
                                     for role in ('lineStraight', 'lineCap')],
            'sourceFootprintCells': len(nodes), 'rotationDegrees': -turns * 90,
            'expectedNativeMinimumY': face['low'] + translation[1],
            'expectedNativeMaximumY': face['high'] + translation[1],
            'readiness': 'straight_source_face_only_lineCorner_still_requires_a_verified_network_junction',
            'endpointPolicy': 'lineCap reuses the naturally open one-unit source wall plane; no invented closing face',
            'terrainDatumEvidence': 'anchorWorld.y calculated from recipe heightLevels at the actual native slot',
            'uvFidelity': 'representative original one-unit source UV; arbitrary source segment stretching is not reproduced'})
    return output, grid

def companion_band(face, scene, kind, *, material):
    if face['last'] - face['first'] < 1 - 1e-7:
        return None
    normal_component = face['normal'][face['constantAxis']]
    start = face['constant']
    end = start + normal_component * (.5 if kind == 'base' else -.5)
    bounds = [0, 0, 0, 0]
    along_index, constant_index = face['alongAxis'] // 2, face['constantAxis'] // 2
    midpoint = (face['first'] + face['last']) / 2
    bounds[along_index], bounds[along_index + 2] = midpoint - .5, midpoint + .5
    bounds[constant_index], bounds[constant_index + 2] = min(start, end), max(start, end)
    level = face['low'] if kind == 'base' else face['high']
    candidates = []
    for surface in scene['surfaces']:
        if surface.group != face['group'] or surface.material != material:
            continue
        for triangle in surface.triangles:
            normal = extraction.normal(triangle)
            if not .1 < normal[1] < .99 or abs(normal[face['alongAxis']]) > 1e-6:
                continue
            low, high = min(vertex[1] for vertex in triangle), max(vertex[1] for vertex in triangle)
            if ((kind == 'base' and high <= level + 1e-6 and low >= level - 1.001)
                    or (kind == 'crown' and low >= level - 1e-6 and high <= level + 1.001)):
                candidates.append((surface, triangle))
    entries = extraction.clip_selected(candidates, bounds)
    if not entries or abs(sum(extraction.projected_area(triangle) for _, triangle in entries) - .5) > 1e-6:
        return None
    normals = {tuple(extraction.normal(triangle)) for _, triangle in entries}
    if len(normals) != 1:
        return None
    band_bounds = extraction.entries_bounds(entries)
    if abs(band_bounds[face['constantAxis'] + 3] - band_bounds[face['constantAxis']] - .5) > 1e-6:
        return None
    return {'entries': entries, 'material': material, 'texture': entries[0][0].texture,
            'normal': list(next(iter(normals))), 'low': band_bounds[1], 'high': band_bounds[4],
            'constant': (band_bounds[face['constantAxis']] + band_bounds[face['constantAxis'] + 3]) / 2,
            'bounds': band_bounds}

def boundary_bevels(scene, faces, *, materials):
    planes = defaultdict(list)
    for surface in scene['surfaces']:
        if surface.material not in materials:
            continue
        for triangle in surface.triangles:
            normal = extraction.normal(triangle)
            if abs(normal[1]) > 1e-6 or min(abs(normal[0]), abs(normal[2])) < .1:
                continue
            distance = round(sum(normal[axis] * triangle[0][axis] for axis in range(3)), 5)
            planes[surface.group, surface.material, tuple(normal), distance].append((surface, triangle))
    result = []
    for key, entries in sorted(planes.items()):
        for component in extraction.component_triangles(entries):
            bounds = extraction.entries_bounds(component)
            if max(bounds[3] - bounds[0], bounds[5] - bounds[2]) > 1.001:
                continue
            contacts = []
            for index, face in enumerate(faces):
                if face['group'] != key[0] or face['material'] != key[1] or min(face['high'], bounds[4]) - max(face['low'], bounds[1]) < .1:
                    continue
                if any(abs(vertex[face['constantAxis']] - face['constant']) < 1e-6
                       and any(abs(vertex[face['alongAxis']] - endpoint) < 1e-6 for endpoint in (face['first'], face['last']))
                       for _, triangle in component for vertex in triangle):
                    contacts.append(index)
            if contacts:
                result.append({'entries': component, 'bounds': bounds, 'normal': list(key[2]),
                               'material': key[1], 'group': key[0], 'contacts': contacts})
    return result

def bevel_band(scene, bevel, kind, *, material):
    bounds, normal = bevel['bounds'], bevel['normal']
    footprint = [bounds[0], bounds[2], bounds[3], bounds[5]]
    if kind == 'base':
        for axis in (0, 2):
            index = axis // 2
            footprint[index if normal[axis] < 0 else index + 2] += -.5 if normal[axis] < 0 else .5
    level = bounds[1] if kind == 'base' else bounds[4]
    entries = []
    for surface in scene['surfaces']:
        if surface.group != bevel['group'] or surface.material != material:
            continue
        for triangle in surface.triangles:
            direction = extraction.normal(triangle)
            low, high = min(vertex[1] for vertex in triangle), max(vertex[1] for vertex in triangle)
            if not .1 < direction[1] < .99:
                continue
            if ((kind == 'base' and high <= level + 1e-6 and low >= level - 1.501)
                    or (kind == 'crown' and low >= level - 1.001 and high <= level + 1.501)):
                entries.append((surface, triangle))
    entries = extraction.clip_selected(entries, footprint)
    if not entries or sum(extraction.projected_area(triangle) for _, triangle in entries) < 1e-7:
        return None
    return entries

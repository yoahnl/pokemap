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

def cells_for_triangle(triangle, translation):
    bounds = extraction.entries_bounds([(None, triangle)])
    ranges = []
    for axis in (0, 2):
        low = bounds[axis] + translation[axis]
        high = bounds[axis + 3] + translation[axis]
        first = math.floor(low + 1e-8)
        last = first + 1 if abs(high - low) < 1e-8 else math.ceil(high - 1e-8)
        ranges.append(range(first, last))
    return [(x, z) for z in ranges[1] for x in ranges[0]]

def surface_height(entries, x, z):
    hits = []
    for surface, triangle in entries:
        if extraction.normal(triangle)[1] <= .2:
            continue
        weights = extraction.barycentric(x, z, triangle)
        if weights is not None and min(weights) >= -1e-7:
            hits.append(sum(weights[i] * triangle[i][1] for i in range(3)))
    return max(hits) if hits else None

def boundary_segments(entries, cell, translation):
    result = {}
    left = cell[0] - translation[0]
    top = cell[1] - translation[2]
    for name, axis, value, along in [('west', 0, left, 2), ('east', 0, left + 1, 2),
                                     ('north', 2, top, 0), ('south', 2, top + 1, 0)]:
        segments = set()
        origin = top if along == 2 else left
        for _, triangle in entries:
            points = sorted({(round(v[along] - origin, 9), round(v[1] + translation[1], 9))
                             for v in triangle if abs(v[axis] - value) < 1e-8})
            if len(points) == 2 and points[0] != points[1]:
                segments.add(tuple(points))
        result[name] = sorted(segments)
    return result

def selected_cells(center, radius, width, depth):
    x, z = center
    if radius < 0 or not 0 <= x < width or not 0 <= z < depth:
        raise ValueError('Cliff selection must be inside its map')
    return [(a, b) for b in range(max(0, z - radius), min(depth, z + radius + 1))
            for a in range(max(0, x - radius), min(width, x + radius + 1))]

def module_selection(center, radius, width, depth, complete):
    if complete:
        return [(x, z) for z in range(depth) for x in range(width)]
    return selected_cells(center, radius, width, depth)

def smart_tile_offset(dx, dz, source_turns):
    quarter_turns = (-source_turns) % 4
    cosine, sine = [(1, 0), (0, 1), (-1, 0), (0, -1)][quarter_turns]
    return quarter_turns, cosine * dx + sine * dz, -sine * dx + cosine * dz

def native_height_at(scene, x, z):
    for ramp in scene['navigation']['ramps']:
        if not (ramp['x'] <= x < ramp['x'] + ramp['width'] and
                ramp['z'] <= z < ramp['z'] + ramp['depth']):
            continue
        progress = {
            'north': lambda: 1 - (z - ramp['z']) / ramp['depth'],
            'south': lambda: (z - ramp['z']) / ramp['depth'],
            'east': lambda: (x - ramp['x']) / ramp['width'],
            'west': lambda: 1 - (x - ramp['x']) / ramp['width'],
        }[ramp['direction']]()
        level = ramp['lowLevel'] + (ramp['highLevel'] - ramp['lowLevel']) * min(1, max(0, progress))
        return level * scene['levelHeight']
    cell_x = min(scene['width'] - 1, max(0, math.floor(x)))
    cell_z = min(scene['depth'] - 1, max(0, math.floor(z)))
    return scene['heightLevels'][cell_z * scene['width'] + cell_x] * scene['levelHeight']

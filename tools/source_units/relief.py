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

from rotation import area, geometry_error, rotated_entries, shape, straight_axis


def profile_axis(entries):
    bounds = extraction.entries_bounds(entries)
    for axis in (0, 2):
        cross_axis = 2 - axis
        if abs(bounds[axis + 3] - bounds[axis] - 1) > 1e-6:
            continue
        planes = defaultdict(list)
        for surface, triangle in entries:
            normal = extraction.normal(triangle)
            if abs(normal[axis]) > 1e-6:
                break
            cross = extraction.cross(*triangle)
            length = math.sqrt(sum(value * value for value in cross))
            distance = round(sum(cross[index] / length * (triangle[0][index] - bounds[index])
                                 for index in range(3)), 6)
            planes[tuple(normal), distance].append((surface, triangle))
        else:
            qualified = True
            for plane in planes.values():
                plane_bounds = extraction.entries_bounds(plane)
                width = plane_bounds[axis + 3] - plane_bounds[axis]
                section = math.sqrt((plane_bounds[cross_axis + 3] - plane_bounds[cross_axis]) ** 2
                                    + (plane_bounds[4] - plane_bounds[1]) ** 2)
                if abs(width - 1) > 1e-6 or abs(area(plane) - section) > 1e-6:
                    qualified = False
                    break
            if qualified:
                return axis
    return None

def appearance_identity(entries, scene):
    return min((extraction.geometry_identity(rotated_entries(entries, turns), scene['textures']), turns)
               for turns in range(4))

def centered(entries):
    bounds = extraction.entries_bounds(entries)
    anchor = [(bounds[0] + bounds[3]) / 2, bounds[1], (bounds[2] + bounds[5]) / 2]
    return [(surface, [[*[vertex[axis] - anchor[axis] for axis in range(3)], *vertex[3:]]
                       for vertex in triangle]) for surface, triangle in extraction.normalized_uv_entries(entries)]

def weights_at(point, triangle):
    normal = extraction.normal(triangle)
    axes = sorted(range(3), key=lambda axis: abs(normal[axis]))[:2]
    x, z = axes
    a, b, c = triangle
    denominator = (b[x] - a[x]) * (c[z] - a[z]) - (b[z] - a[z]) * (c[x] - a[x])
    if abs(denominator) < 1e-12:
        return None
    u = ((point[x] - a[x]) * (c[z] - a[z]) - (point[z] - a[z]) * (c[x] - a[x])) / denominator
    v = ((b[x] - a[x]) * (point[z] - a[z]) - (b[z] - a[z]) * (point[x] - a[x])) / denominator
    weights = [1 - u - v, u, v]
    if min(weights) < -1e-6 or any(abs(point[axis] - sum(weight * vertex[axis]
        for weight, vertex in zip(weights, triangle))) > 1e-6 for axis in range(3)):
        return None
    return weights

def uv_value(value, mode):
    if mode == 'WRAP':
        return value % 1
    if mode == 'MIRROR':
        phase = value % 2
        return min(phase, 2 - phase)
    return min(1, max(0, value))

def appearance_error(entries, prototype, rotation):
    actual, expected = centered(entries), rotated_entries(centered(prototype), rotation // 90)
    maximum = 0
    for origin, destination in [(actual, expected), (expected, actual)]:
        for surface, triangle in origin:
            samples = [*triangle, [sum(vertex[axis] for vertex in triangle) / 3 for axis in range(8)]]
            for sample in samples:
                errors = []
                for other, target in destination:
                    if surface.texture != other.texture or surface.wraps != other.wraps or surface.opacity != other.opacity:
                        continue
                    weights = weights_at(sample, target)
                    if weights is None:
                        continue
                    interpolated = [sum(weight * vertex[axis] for weight, vertex in zip(weights, target))
                                    for axis in range(8)]
                    differences = [abs(sample[axis] - interpolated[axis]) for axis in range(5, 8)]
                    for axis, mode in enumerate(surface.wraps):
                        difference = abs(uv_value(sample[axis + 3], mode) - uv_value(interpolated[axis + 3], mode))
                        differences.append(min(difference, 1 - difference) if mode == 'WRAP' else difference)
                    errors.append(max(differences))
                if not errors:
                    raise ValueError('Source appearance has no corresponding prototype plane')
                maximum = max(maximum, min(errors))
    return maximum

def model_entries(model, scene):
    references = model['sourceReferences']
    entries = [(surface, triangle) for surface in scene['surfaces']
               for reference in references if all(getattr(surface, key) == reference[key]
                   for key in ('group', 'geometry', 'material', 'texture'))
               for index, triangle in enumerate(surface.triangles) if index in reference['triangleIndices']]
    bounds = model['sourceBoundsCells']
    entries = extraction.clip_selected(entries, [bounds[0], bounds[2], bounds[3], bounds[5]])
    result = []
    for surface, triangle in entries:
        polygon = extraction.clip_polygon(triangle, 1, bounds[1], True)
        polygon = extraction.clip_polygon(polygon, 1, bounds[4], False)
        result.extend((surface, piece) for piece in extraction.triangulate(polygon, validate=False)
                      if area([(surface, piece)]) > 1e-9)
    return result

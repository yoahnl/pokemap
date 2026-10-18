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

def area(entries):
    return sum(math.sqrt(sum(value * value for value in extraction.cross(*triangle))) / 2 for _, triangle in entries)

def rotated_entries(entries, turns, appearance=True):
    cosine, sine = [(1, 0), (0, 1), (-1, 0), (0, -1)][turns % 4]
    return [(surface, [[cosine * vertex[0] + sine * vertex[2], vertex[1],
                       -sine * vertex[0] + cosine * vertex[2],
                       *(vertex[3:5] if appearance else [0, 0]), *vertex[5:]] for vertex in triangle])
            for surface, triangle in entries]

def shape(entries, scene):
    candidates = [(extraction.geometry_identity(rotated_entries(entries, turns, False), scene['textures']), turns)
                  for turns in range(4)]
    return min(candidates)

def straight_axis(entries):
    bounds = extraction.entries_bounds(entries)
    sizes = [bounds[3] - bounds[0], bounds[5] - bounds[2]]
    axis = 0 if sizes[0] > sizes[1] else 2
    major = sizes[0 if axis == 0 else 1]
    minor = sizes[1 if axis == 0 else 0]
    if abs(major - 1) > 1e-6 or minor > .75:
        return None
    cross_axis = 2 if axis == 0 else 0
    for _, triangle in entries:
        direction = extraction.normal(triangle)
        if abs(direction[1]) < 1e-6 and abs(direction[cross_axis]) < 1e-6:
            return None
    return axis

def point_distance(point, triangle):
    a, b, c = [vertex[:3] for vertex in triangle]
    vector = lambda left, right: [left[axis] - right[axis] for axis in range(3)]
    dot = lambda left, right: sum(a * b for a, b in zip(left, right))
    ab, ac, ap = vector(b, a), vector(c, a), vector(point, a)
    denominator = dot(ab, ab) * dot(ac, ac) - dot(ab, ac) ** 2
    if denominator > 1e-14:
        u = (dot(ac, ac) * dot(ap, ab) - dot(ab, ac) * dot(ap, ac)) / denominator
        v = (dot(ab, ab) * dot(ap, ac) - dot(ab, ac) * dot(ap, ab)) / denominator
        if u >= -1e-8 and v >= -1e-8 and u + v <= 1 + 1e-8:
            projected = [a[axis] + u * ab[axis] + v * ac[axis] for axis in range(3)]
            return math.sqrt(dot(vector(point, projected), vector(point, projected)))
    distances = []
    for start, end in [(a, b), (b, c), (c, a)]:
        edge = vector(end, start)
        progress = min(1, max(0, dot(vector(point, start), edge) / dot(edge, edge))) if dot(edge, edge) else 0
        difference = vector(point, [start[axis] + progress * edge[axis] for axis in range(3)])
        distances.append(math.sqrt(dot(difference, difference)))
    return min(distances)

def geometry_error(entries, prototype, rotation):
    def centered(value):
        bounds = extraction.entries_bounds(value)
        anchor = [(bounds[0] + bounds[3]) / 2, bounds[1], (bounds[2] + bounds[5]) / 2]
        return [(surface, [[*[vertex[axis] - anchor[axis] for axis in range(3)], *vertex[3:]] for vertex in triangle])
                for surface, triangle in value]
    actual = centered(entries)
    expected = rotated_entries(centered(prototype), rotation // 90)
    return max(min(point_distance(vertex[:3], triangle) for _, triangle in destination)
               for origin, destination in [(actual, expected), (expected, actual)]
               for _, triangle in origin for vertex in triangle)

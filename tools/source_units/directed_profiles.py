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

from rotation import rotated_entries
from boundaries import boundary_segments


def entries_rotated_about_support(entries, support, turns):
    centered = [(surface, [[*[v[axis] - support[axis] for axis in range(3)], *v[3:]]
                           for v in triangle]) for surface, triangle in entries]
    return [(surface, [[*[v[axis] + support[axis] for axis in range(3)], *v[3:]]
                       for v in triangle]) for surface, triangle in rotated_entries(centered, turns)]

def clip_diagonal(entries, support, coefficients):
    def distance(vertex):
        return sum(coefficients[index] * (vertex[axis] - support[axis])
                   for index, axis in enumerate([0, 2]))
    result = []
    for surface, triangle in entries:
        polygon = []
        previous = triangle[-1]
        previous_distance = distance(previous)
        for current in triangle:
            current_distance = distance(current)
            if (previous_distance >= 0) != (current_distance >= 0):
                progress = previous_distance / (previous_distance - current_distance)
                polygon.append([previous[axis] + progress * (current[axis] - previous[axis])
                                for axis in range(len(previous))])
            if current_distance >= 0:
                polygon.append(current)
            previous, previous_distance = current, current_distance
        result.extend((surface, piece) for piece in extraction.triangulate(polygon)
                      if sum(value * value for value in extraction.cross(*piece)) > 1e-12)
    return result

def compose_inner_profile(scene, straight, name):
    return compose_corner_profile(scene, straight, name, 'inner')

def compose_outer_profile(scene, straight, name):
    return compose_corner_profile(scene, straight, name, 'outer')

def compose_corner_profile(scene, straight, name, role):
    support = straight['support']
    coefficients = {'inner': ([1, -1], [-1, -1]),
                    'outer': ([-1, 1], [1, 1])}[role]
    parts = [clip_diagonal(straight['entries'], support, value) for value in coefficients]
    rotated = [(surface, [[support[0] + vertex[2] - support[2], vertex[1],
                           support[2] - vertex[0] + support[0], *vertex[3:]]
                          for vertex in triangle]) for surface, triangle in parts[1]]
    entries = parts[0] + rotated
    original_parts = parts[0] + parts[1]
    if straight.get('sourceNormalizationQuarterTurns'):
        original_parts = entries_rotated_about_support(
            original_parts, support, -straight['sourceNormalizationQuarterTurns'])
    attributes = {key: value for key, value in straight.items() if key not in
                  {'id', 'sourceId', 'family', 'entries', 'support', 'materials', 'maxSize',
                   'pieceRole', 'authoredOrientation', 'cornerTurn', 'supportEvidence'}}
    return extraction.unit(scene['id'], name, straight['family'], entries, support,
        sorted({surface.material for surface, _ in entries}), straight['maxSize'],
        pieceRole=role, authoredOrientation='west' if role == 'inner' else 'south',
        cornerTurn='left' if role == 'inner' else 'right', **attributes,
        supportEvidence='two cropped source profiles joined by a quarter turn; no height or UV scaling',
        sourceComposition=[{'sourceProfileId': straight['id'], 'quarterTurns': turns,
                            'pivotSource': support, 'clipCoefficientsXZ': coefficients}
                           for turns, coefficients in enumerate(coefficients)],
        assemblySourceReferences=extraction.reference_rows(scene, original_parts))

def centered_entries(unit):
    anchor = unit['support']
    return [(surface, [[*[vertex[axis] - anchor[axis] for axis in range(3)], *vertex[3:]]
                       for vertex in triangle]) for surface, triangle in unit['entries']]

def segment_distance(point, segment):
    start, end = segment
    delta = [end[axis] - start[axis] for axis in range(2)]
    length = sum(value * value for value in delta)
    progress = min(1, max(0, sum((point[axis] - start[axis]) * delta[axis]
                                 for axis in range(2)) / length)) if length else 0
    return math.sqrt(sum((point[axis] - start[axis] - progress * delta[axis]) ** 2
                         for axis in range(2)))

def seam_error(first, second):
    if not first or not second:
        raise ValueError('Cliff socket has no source boundary')
    return max(min(segment_distance(point, candidate) for candidate in target)
               for origin, target in [(first, second), (second, first)]
               for segment in origin for point in [segment[0], segment[1],
                   [(segment[0][axis] + segment[1][axis]) / 2 for axis in range(2)]])

def socket_proof(units):
    pieces = {unit['pieceRole']: centered_entries(unit) for unit in units}
    edges = {role: boundary_segments(entries, [0, 0], [.5, 0, .5])
             for role, entries in pieces.items()}
    perpendicular = boundary_segments(rotated_entries(pieces['straight'], 1), [0, 0], [.5, 0, .5])
    return {
        'outerWest': seam_error(edges['outer']['west'], edges['straight']['east']),
        'outerNorth': seam_error(edges['outer']['north'], perpendicular['south']),
        'innerEast': seam_error(edges['inner']['east'], edges['straight']['west']),
        'innerSouth': seam_error(edges['inner']['south'], perpendicular['north']),
        'straightRepeat': seam_error(edges['straight']['east'], edges['straight']['west']),
    }

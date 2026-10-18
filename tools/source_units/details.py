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


def repeated_candidates(scene, *, marker_material, materials, period, height_range):
    extraction._text(marker_material)
    extraction._strings(materials, nonempty=True)
    extraction._vector(period, 2)
    extraction._vector(height_range, 2)
    if any(value <= 0 for value in period) or height_range[0] > height_range[1]:
        raise ValueError('Repeated source geometry requires a positive period and ordered heights')
    for surface in scene['surfaces']:
        if surface.material != marker_material:
            continue
        for index in range(0, len(surface.triangles), 2):
            pair = [(surface, triangle) for triangle in surface.triangles[index:index + 2]]
            bounds = extraction.entries_bounds(pair)
            repetitions = [(bounds[axis + 3] - bounds[axis]) / step for axis, step in zip((0, 2), period)]
            if any(abs(value - round(value)) > 1e-6 for value in repetitions):
                raise ValueError('Source geometry does not follow the declared repetition period')
            for z in range(round(repetitions[1])):
                for x in range(round(repetitions[0])):
                    rectangle = [bounds[0] + period[0] * x, bounds[2] + period[1] * z,
                                 bounds[0] + period[0] * (x + 1), bounds[2] + period[1] * (z + 1)]
                    selected = extraction.select_entries(scene['surfaces'], materials, surface.group)
                    selected = [(source, triangle) for source, triangle in selected
                                if min(vertex[1] for vertex in triangle) >= bounds[1] + height_range[0] - 1e-6
                                and max(vertex[1] for vertex in triangle) <= bounds[1] + height_range[1] + 1e-6]
                    yield extraction.clip_selected(selected, rectangle), rectangle, bounds[1], surface.group

def joined_objects(entries):
    components = extraction.component_triangles(entries)
    parents = list(range(len(components)))
    bounds = [extraction.entries_bounds(component) for component in components]
    def root(index):
        while parents[index] != index:
            index = parents[index]
        return index
    for left, first in enumerate(bounds):
        for right, second in enumerate(bounds[:left]):
            if all(first[axis] < second[axis + 3] + 1e-6 and second[axis] < first[axis + 3] + 1e-6 for axis in [0, 2]):
                parents[root(left)] = root(right)
    groups = defaultdict(list)
    for index, component in enumerate(components):
        groups[root(index)].extend(component)
    return list(groups.values())

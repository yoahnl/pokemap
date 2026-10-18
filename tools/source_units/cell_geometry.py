from collections import defaultdict
import math

import extract_units as extraction
from rotation import area


def cell_entries(scene, frame, *, materials, component_materials, omit_flat_materials):
    bins = defaultdict(list)
    translation = frame['sourceToNativeTranslation']
    for surface in scene['surfaces']:
        if not surface.terrain or surface.material not in materials or surface.material in component_materials:
            continue
        for triangle in surface.triangles:
            if surface.material in omit_flat_materials and max(vertex[1] for vertex in triangle) - min(vertex[1] for vertex in triangle) < 1e-8:
                continue
            bounds = extraction.entries_bounds([(surface, triangle)])
            ranges = []
            for axis in (0, 2):
                low, high = bounds[axis] + translation[axis], bounds[axis + 3] + translation[axis]
                first = math.floor(low + 1e-8)
                last = first + 1 if abs(high - low) < 1e-8 else math.ceil(high - 1e-8)
                ranges.append(range(first, last))
            for z in ranges[1]:
                for x in ranges[0]:
                    pieces = extraction.clip_selected([(surface, triangle)],
                        [x - translation[0], z - translation[2], x + 1 - translation[0], z + 1 - translation[2]])
                    bins[x, z, surface.material, -1].extend((source, piece) for source, piece in pieces
                                                          if area([(source, piece)]) > 1e-9)
    for material in component_materials:
        selected = extraction.select_entries(scene['surfaces'], [material])
        for index, entries in enumerate(extraction.component_triangles(selected)):
            bounds = extraction.entries_bounds(entries)
            x = math.floor((bounds[0] + bounds[3]) / 2 + translation[0])
            z = math.floor((bounds[2] + bounds[5]) / 2 + translation[2])
            bins[x, z, material, index] = entries
    return {key: entries for key, entries in bins.items() if entries}

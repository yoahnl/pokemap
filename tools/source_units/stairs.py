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

from city_models import ramp_from_contacts, ramp_landing_points


def walking_plane(entries):
    planes = defaultdict(list)
    for surface, triangle in entries:
        normal = extraction.normal(triangle)
        if .1 < normal[1] < .99 and min(abs(normal[0]), abs(normal[2])) < 1e-6:
            planes[tuple(normal)].append((surface, triangle))
    candidates = []
    for normal, triangles in planes.items():
        bounds = extraction.entries_bounds(triangles)
        area = sum(extraction.projected_area(triangle) for _, triangle in triangles)
        rectangle_area = (bounds[3] - bounds[0]) * (bounds[5] - bounds[2])
        along_axis = 0 if abs(normal[0]) > abs(normal[2]) else 2
        cross_axis = 2 - along_axis
        passage_width = bounds[cross_axis + 3] - bounds[cross_axis]
        if abs(area - rectangle_area) < 1e-6 and passage_width >= .5:
            candidates.append({'entries': triangles, 'bounds': bounds, 'normal': list(normal),
                               'projectedAreaCells': area, 'alongAxis': along_axis,
                               'passageWidthCells': passage_width})
    if len(candidates) != 1:
        raise ValueError('A staircase must have exactly one full rectangular source walking plane')
    return candidates[0]

def native_ramp(plane, frame, identity):
    bounds, normal = plane['bounds'], plane['normal']
    translation = frame['sourceToNativeTranslation']
    direction = ('east' if normal[0] < 0 else 'west') if plane['alongAxis'] == 0 else ('south' if normal[2] < 0 else 'north')
    candidate = {'id': identity, 'x': bounds[0] + translation[0], 'z': bounds[2] + translation[2],
                 'width': bounds[3] - bounds[0], 'depth': bounds[5] - bounds[2], 'direction': direction}
    levels = {(index % frame['width'], index // frame['width']): level
              for index, level in enumerate(frame['nativePaint']['heightLevels']) if level is not None}
    ramp = ramp_from_contacts(candidate, levels, frame['width'], frame['depth'])
    if ramp is None or ramp['direction'] != direction:
        raise ValueError('Original staircase contacts cannot be represented by native terrain ramp levels')
    errors = [abs(ramp[key] * frame['levelHeight'] - bounds[axis] - translation[1])
              for key, axis in (('lowLevel', 1), ('highLevel', 4))]
    if max(errors) > frame['levelHeight'] / 2:
        raise ValueError('Native quarter-height ramp diverges from the original walking plane')
    samples = []
    for negative_x, negative_z, positive_x, positive_z in ramp_landing_points(ramp):
        samples.append({'negative': {'x': negative_x, 'z': negative_z,
                                    'level': levels[(int(negative_x // 1), int(negative_z // 1))]},
                        'positive': {'x': positive_x, 'z': positive_z,
                                    'level': levels[(int(positive_x // 1), int(positive_z // 1))]}})
    return {'ramp': ramp, 'contactSamples': samples, 'maximumNativeHeightError': max(errors),
            'sourceWalkingPlane': {'bounds': bounds, 'normal': normal,
                'projectedAreaCells': plane['projectedAreaCells'], 'passageWidthCells': plane['passageWidthCells'],
                'triangles': [triangle for _, triangle in plane['entries']]},
            'supportPolicy': 'native ramp provides support over its exact rectangle; do not fill surrounding source void',
            'collisionPolicy': 'keep passage open; visual staircase bounding box is not a blocking collision',
            'readiness': 'source_walking_plane_and_all_native_landing_contacts_verified'}

import argparse
from hashlib import sha256
import json
import math
from pathlib import Path
import sys


sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
import extract_units as extraction
from build_fence_units import rotated_entries
from prepare_complete_cliff_modules import boundary_segments


PROFILES = {
    'pavonnay-four': {
        'source': '587455', 'lower': 5, 'upper': 9,
        'pieces': [('straight', (-14.5, -1.5), 'west', None),
                   ('outer', (-13.5, -1.5), 'south', 'right'),
                   ('inner', (-13.5, -2.5), 'west', 'left')],
    },
    'route19-five': {
        'source': 'rom-route19', 'lower': 1, 'upper': 6,
        'pieces': [('straight', (10.5, -7.5), 'west', None),
                   ('outer', (11.5, -7.5), 'south', 'right'),
                   ('inner', (9.5, -7.5), 'west', 'left')],
    },
    'pavonnay-urban-four': {
        'source': '587455', 'lower': 1.0625, 'upper': 5, 'height': 4,
        'pieces': [('straight', (-15.5, 25.5), 'west', None),
                   ('outer', (-14.5, 25.5), 'south', 'right')],
        'composeInner': True,
    },
    'pavonnay-eight': {
        'source': '587455', 'lower': 1.0625, 'upper': 9, 'height': 8,
        'pieces': [('straight', (-3.5, 3.5), 'west', None),
                   ('outer', (-.5, 3.5), 'south', 'right')],
        'composeInner': True,
    },
    'pavonnay-bank-half': {
        'source': '587455', 'lower': .5, 'upper': 1,
        'pieces': [('straight', (4.5, 42.5), 'west', None)],
        'materials': ['gake1_1'], 'composeInner': True, 'composeOuter': True,
    },
    'route19-bank-half': {
        'source': 'rom-route19', 'lower': .5, 'upper': 1,
        'pieces': [('straight', (11.5, -6.5), 'west', None)],
        'materials': ['gake1_1'], 'composeInner': True, 'composeOuter': True,
    },
    'route19-step-one': {
        'source': 'rom-route19', 'lower': 1, 'upper': 2,
        'pieces': [('straight', (-5.5, 13.5), 'west', None)],
        'materials': ['gake01a_2', 'gake1_0', 'gake1_1', 'grass01ax'],
        'composeInner': True, 'composeOuter': True,
    },
    'pavonnay-back-cap-quarter': {
        'source': '587455', 'lower': 8.75, 'upper': 9,
        'pieces': [('straight', (-23.5, -12.5), 'west', None)],
        'materials': ['gake1_1'], 'composeInner': True, 'composeOuter': True,
        'sourceNormalizationQuarterTurns': 2,
    },
    'pavonnay-back-eight': {
        'source': '587455', 'lower': 1.0625, 'upper': 9, 'height': 8,
        'pieces': [('straight', (-15.5, -12.5), 'west', None)],
        'materials': ['gake01a', 'gake1_1'], 'composeInner': True, 'composeOuter': True,
        'sourceNormalizationQuarterTurns': 2,
    },
    'route19-step-one-narrow': {
        'source': 'rom-route19', 'lower': 3, 'upper': 4,
        'pieces': [('straight', (-3.5, -1.5), 'west', None)],
        'materials': ['gake01a_2', 'gake1_1', 'grass01ax'],
        'composeInner': True, 'composeOuter': True,
    },
    'route19-step-one-shallow': {
        'source': 'rom-route19', 'lower': 1.125, 'upper': 2, 'height': 1,
        'pieces': [('straight', (.5, -.5), 'west', None)],
        'materials': ['gake01a_2', 'gake1_1', 'grass01ax'],
        'composeInner': True, 'composeOuter': True,
    },
    'route19-step-one-rounded': {
        'source': 'rom-route19', 'lower': 2, 'upper': 3,
        'pieces': [('straight', (5.5, -3.5), 'west', None),
                   ('outer', (6.5, -3.5), 'south', 'right')],
        'materials': ['gake01a_2', 'gake1_1', 'grass01ax'],
        'composeInner': True,
    },
}
MATERIALS = ['gake01a', 'yamagake01', 'c12_gake01', 'gake1_1', 'grass01ax']


def entries_rotated_about_support(entries, support, turns):
    centered = [(surface, [[*[v[axis] - support[axis] for axis in range(3)], *v[3:]]
                           for v in triangle]) for surface, triangle in entries]
    return [(surface, [[*[v[axis] + support[axis] for axis in range(3)], *v[3:]]
                       for v in triangle]) for surface, triangle in rotated_entries(centered, turns)]


def profile_units(scene, family):
    definition = PROFILES[family]
    if scene['id'] != definition['source']:
        raise ValueError('Cliff profile source identity differs from its measured definition')
    selected = extraction.select_entries(scene['surfaces'], definition.get('materials', MATERIALS))
    result = []
    for role, (x, z), orientation, turn in definition['pieces']:
        entries = extraction.clip_selected(selected, [x - .5, z - .5, x + .5, z + .5])
        entries = [(surface, triangle) for surface, triangle in entries
                   if surface.material != 'grass01ax'
                   or all(abs(vertex[1] - definition['upper']) < 1e-6 for vertex in triangle)]
        bounds = extraction.entries_bounds(entries)
        if abs(bounds[1] - definition['lower']) > 1e-6 or abs(bounds[4] - definition['upper']) > 1e-6:
            raise ValueError('Cliff profile height differs from the measured source')
        if role == 'straight' and any(abs(extraction.normal(triangle)[0]) > 1e-6
                                      for _, triangle in entries):
            raise ValueError('Straight cliff profile includes a neighboring diagonal face')
        support = [x, definition['upper'], z]
        normalization = definition.get('sourceNormalizationQuarterTurns', 0)
        source_attributes = {}
        if normalization:
            source_attributes = {
                'sourceNormalizationQuarterTurns': normalization,
                'sourceOriginalReferences': extraction.reference_rows(scene, entries),
            }
            entries = entries_rotated_about_support(entries, support, normalization)
        materials = sorted({surface.material for surface, _ in entries})
        result.append(extraction.unit(scene['id'], 'bw2-cliff-' + family + '-' + role, 'relief',
            entries, support, materials,
            [1, definition['upper'] - definition['lower'], 1], pieceRole=role,
            profileFamily=family, authoredOrientation=orientation, cornerTurn=turn,
            upperSurfaceHeight=definition['upper'], lowerSurfaceHeight=definition['lower'],
            supportMeaning='cliff_upper_contour_socket', maxTriangles=200,
            supportEvidence='original neutral pose geometry, UV and source vertex colors',
            groundCoverage='original upper grass only; lower floor remains native terrain',
            **source_attributes))
    if definition.get('composeInner'):
        result.append(compose_inner_profile(scene, result[0], 'bw2-cliff-' + family + '-inner'))
    if definition.get('composeOuter'):
        result.append(compose_outer_profile(scene, result[0], 'bw2-cliff-' + family + '-outer'))
    return result


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
    return extraction.unit(scene['id'], name, 'relief', entries, support,
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


def build(args):
    output = args.output.resolve()
    roots = [args.corpus.resolve(strict=True), args.route_source.resolve(strict=True),
             args.nitro.resolve(strict=True)]
    if output.exists() or any(output == root or output.is_relative_to(root) for root in roots):
        raise ValueError('Preserve previous preparations and original source folders')
    scenes = {'587455': extraction.load_scene(args.corpus, '587455'),
              'rom-route19': extraction.load_scene(args.route_source, 'rom-route19', True)}
    source_hashes = {str(scene['root'] / scene['record']['local_path']):
                     extraction.digest(scene['root'] / scene['record']['local_path'])
                     for scene in scenes.values()}
    prepared = []
    for family, definition in PROFILES.items():
        scene = scenes[definition['source']]
        units = profile_units(scene, family)
        seams = socket_proof(units)
        if max(seams.values()) > 1e-6:
            raise ValueError('Original cliff profile sockets do not meet: ' + json.dumps(seams))
        prepared.append((family, scene, units, seams))
    source_materials = {material for definition in PROFILES.values()
                        for material in definition.get('materials', MATERIALS)}
    sources = extraction.NitroSources(args.nitro, source_materials)
    models, families = [], []
    for family, scene, units, seams in prepared:
        emitted = [extraction.emit_unit(unit, scene, output, sources) for unit in units]
        for unit, model in zip(units, emitted):
            if 'sourceComposition' in unit:
                model['sourceReferences'] = unit['assemblySourceReferences']
                model['sourceReferenceInterpretation'] = 'original triangles before declared quarter-turn composition'
            elif 'sourceOriginalReferences' in unit:
                model['sourceReferences'] = unit['sourceOriginalReferences']
                model['sourceReferenceInterpretation'] = 'original triangles before declared source orientation normalization'
        models.extend(emitted)
        definition = PROFILES[family]
        families.append({'id': family, 'height': definition.get('height', definition['upper'] - definition['lower']),
                         'measuredVerticalSpan': definition['upper'] - definition['lower'],
                         'modelIds': [model['id'] for model in emitted], 'socketMaximumErrors': seams,
                         'endpointPolicy': 'open authentic profile; no invented closing face'})
    if any(extraction.digest(Path(path)) != expected for path, expected in source_hashes.items()):
        raise ValueError('Original source changed during extraction')
    result = {'schemaVersion': 1, 'tool': str(Path(__file__).resolve()),
              'toolSha256': sha256(Path(__file__).read_bytes()).hexdigest(),
              'sourcesReadOnlyVerified': True, 'sourceHashes': source_hashes,
              'families': families, 'models': models, 'nativeBrushQualified': False,
              'visibleRenderQualified': False,
              'limits': ['Stair endpoints and final native brush/render reviews remain to qualify.']}
    extraction.write_json(output / 'manifest.json', result)
    print(json.dumps({'output': str(output), 'modelCount': len(models), 'families': families}, ensure_ascii=False))


def check(args):
    output = args.output.resolve(strict=True)
    manifest = json.loads((output / 'manifest.json').read_text())
    if manifest['toolSha256'] != sha256(Path(__file__).read_bytes()).hexdigest():
        raise ValueError('Derived kit belongs to a different extractor revision')
    scenes = {'587455': extraction.load_scene(args.corpus, '587455'),
              'rom-route19': extraction.load_scene(args.route_source, 'rom-route19', True)}
    expected_sources = {str(scene['root'] / scene['record']['local_path']):
                        extraction.digest(scene['root'] / scene['record']['local_path'])
                        for scene in scenes.values()}
    if expected_sources != manifest['sourceHashes'] or not manifest['sourcesReadOnlyVerified']:
        raise ValueError('Original source hashes differ from the prepared kit')
    expected_ids = {'bw2-cliff-' + family + '-' + role
                    for family in PROFILES for role in ['straight', 'outer', 'inner']}
    models = {model['id']: model for model in manifest['models']}
    families = {family['id']: family for family in manifest['families']}
    if set(models) != expected_ids or len(models) != len(manifest['models']):
        raise ValueError('Derived kit model inventory differs from its profiles')
    if set(families) != set(PROFILES) or len(families) != len(manifest['families']):
        raise ValueError('Derived kit family inventory differs from its profiles')
    maximum_error = 0
    for family, definition in PROFILES.items():
        units = profile_units(scenes[definition['source']], family)
        seams = socket_proof(units)
        maximum_error = max(maximum_error, *seams.values())
        if max(seams.values()) > 1e-6 or seams != families[family]['socketMaximumErrors']:
            raise ValueError('Derived cliff sockets differ from their measured source')
        for unit in units:
            model = models[unit['id']]
            path = (output / model['file']).resolve(strict=True)
            if not path.is_relative_to(output):
                raise ValueError('Derived model path is outside the prepared kit')
            if extraction.digest(path) != model['sha256']:
                raise ValueError('Derived model hash differs: ' + unit['id'])
            geometry = extraction.unit_geometry(unit['entries'], unit['support'])
            if any(model[key] != value for key, value in geometry.items()):
                raise ValueError('Derived model anchors differ from their source')
    return {'valid': True, 'checkOnly': True, 'models': len(models), 'families': len(families),
            'maximumSocketError': maximum_error, 'sourcesReadOnlyVerified': True}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--corpus', type=Path, required=True)
    parser.add_argument('--route-source', type=Path, required=True)
    parser.add_argument('--nitro', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--check-only', action='store_true')
    args = parser.parse_args()
    if args.check_only:
        print(json.dumps(check(args)))
    else:
        build(args)


if __name__ == '__main__':
    main()

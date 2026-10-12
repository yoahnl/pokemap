import argparse
from collections import defaultdict
from hashlib import sha256
import json
import math
from pathlib import Path
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
import extract_units as extraction


MATERIALS = {'saku01a', 'out_65_saku', 'C12_saku01', 'C12_saku02', 'c12_tesuri', 'c12_tesuri02'}


def area(entries):
    return sum(math.sqrt(sum(value * value for value in extraction.cross(*triangle))) / 2 for _, triangle in entries)


def cell_entries(scene, frame):
    bins = defaultdict(list)
    translation = frame['sourceToNativeTranslation']
    for surface in scene['surfaces']:
        if not surface.terrain or surface.material not in MATERIALS or surface.material == 'C12_saku02':
            continue
        for triangle in surface.triangles:
            bounds = extraction.entries_bounds([(surface, triangle)])
            ranges = []
            for axis, limit in [(0, frame['width']), (2, frame['depth'])]:
                low, high = bounds[axis] + translation[axis], bounds[axis + 3] + translation[axis]
                first = math.floor(low + 1e-8)
                last = first + 1 if abs(high - low) < 1e-8 else math.ceil(high - 1e-8)
                ranges.append(range(first, last))
            for z in ranges[1]:
                for x in ranges[0]:
                    clipped = extraction.clip_selected([(surface, triangle)],
                        [x - translation[0], z - translation[2], x + 1 - translation[0], z + 1 - translation[2]])
                    clipped = [(value, piece) for value, piece in clipped
                               if math.sqrt(sum(axis * axis for axis in extraction.cross(*piece))) > 1e-9]
                    if clipped:
                        bins[x, z, surface.material, -1].extend(clipped)
    posts = [(surface, triangle) for surface in scene['surfaces'] if surface.terrain and surface.material == 'C12_saku02'
             for triangle in surface.triangles]
    for index, entries in enumerate(extraction.component_triangles(posts)):
        bounds = extraction.entries_bounds(entries)
        x = math.floor((bounds[0] + bounds[3]) / 2 + translation[0])
        z = math.floor((bounds[2] + bounds[5]) / 2 + translation[2])
        bins[x, z, 'C12_saku02', index] = entries
    return bins


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


def build(args):
    roots = [args.corpus_root.resolve(), args.route_source_root.resolve(), args.nitro_root.resolve(), args.project_root.resolve()]
    output = args.output_root.resolve()
    if any(output == root or output.is_relative_to(root) for root in roots):
        raise ValueError('Derived fence kit must remain outside source/project roots')
    scenes = [extraction.load_scene(args.route_source_root, 'rom-route19', True),
              extraction.load_scene(args.corpus_root, '587455')]
    main = json.loads((args.kit_root / 'manifest.json').read_text())
    main_models = {model['id']: model for model in main['models']}
    nitro = extraction.NitroSources(args.nitro_root, MATERIALS)
    models, maps = [], {}
    prototypes = {}
    for scene in scenes:
        source_path = scene['root'] / scene['record']['local_path']
        source_hash = extraction.digest(source_path)
        frame = extraction.native_frame(args.project_root, scene)
        source_units = extraction.route_units(scene['surfaces']) if scene['id'] == 'rom-route19' else extraction.pavonnay_units(scene['surfaces'])
        for specification in source_units:
            if specification['family'] != 'fences':
                continue
            identity, turns = shape(specification['entries'], scene)
            prototypes[scene['id'], identity] = {'model': main_models[specification['id']], 'turns': turns,
                                                'entries': specification['entries']}
        placements = []
        source_area = defaultdict(float)
        covered_area = defaultdict(float)
        outside_area = defaultdict(float)
        for surface in scene['surfaces']:
            if surface.terrain and surface.material in MATERIALS:
                source_area[surface.material] += area([(surface, triangle) for triangle in surface.triangles])
        for (x, z, material, component), entries in sorted(cell_entries(scene, frame).items()):
            measured = area(entries)
            if not 0 <= x < frame['width'] or not 0 <= z < frame['depth']:
                outside_area[material] += measured
                continue
            covered_area[material] += measured
            bounds = extraction.entries_bounds(entries)
            identity, turns = shape(entries, scene)
            prototype = prototypes.get((scene['id'], identity))
            if prototype is None:
                name = ('bw2-route19' if scene['id'] == 'rom-route19' else 'bw2-pavonnay') + '-guardrail-' + identity[:12]
                support, evidence = extraction.source_support(scene['surfaces'], (bounds[0] + bounds[3]) / 2,
                    (bounds[2] + bounds[5]) / 2, bounds[1], 'route-19' if scene['id'] == 'rom-route19' else 'pavonnay')
                specification = extraction.unit(scene['id'], name, 'fences', entries, support, [material], [1.001, 3.01, 1.001],
                    businessResourceId='nb2-guardrails-' + material.lower(), supportEvidence=evidence,
                    resourceRole='source_profile_or_compact_boundary_exception',
                    uvPolicy='authentic representative source-unit UV; arbitrary original per-face stretch/phase is not repeated',
                    collision={'kind': 'separately_authored_railing_footprint', 'sourceAuthored': False})
                model = extraction.emit_unit(specification, scene, output, nitro)
                model['authoredAxis'] = 'east' if straight_axis(entries) == 0 else 'south' if straight_axis(entries) == 2 else None
                models.append(model)
                prototype = {'model': model, 'turns': turns, 'entries': entries}
                prototypes[scene['id'], identity] = prototype
            model = prototype['model']
            rotation = ((prototype['turns'] - turns) % 4) * 90
            error = geometry_error(entries, prototype['entries'], rotation)
            if error > 1e-6:
                raise ValueError('Source geometry differs beyond measured clipping precision')
            anchor = [(bounds[0] + bounds[3]) / 2, bounds[1], (bounds[2] + bounds[5]) / 2]
            native = [anchor[axis] + frame['sourceToNativeTranslation'][axis] for axis in range(3)]
            axis = straight_axis(entries)
            prototype_axis = straight_axis(prototype['entries'])
            placement = {'modelId': model['id'], 'sourceMaterial': material, 'sourceCell': [x, z],
                'sourceAnchor': anchor, 'position': dict(zip(['x', 'y', 'z'], native)), 'rotationDegrees': rotation,
                'scale': 1, 'blocksMovement': False, 'animationIndex': model['animation']['recommendedAnimationIndex'],
                'sourceGeometryArea': measured, 'straightAxis': 'x' if axis == 0 else 'z' if axis == 2 else None,
                'authoredOrientation': 'east' if prototype_axis == 0 else 'south' if prototype_axis == 2 else None,
                'geometryIdentity': identity, 'sourceReferences': extraction.reference_rows(scene, entries),
                'shapeError': error, 'sourceUvIsRepresentative': True}
            placements.append(placement)
        for material, value in source_area.items():
            if abs(value - covered_area[material] - outside_area[material]) > 1e-6:
                raise ValueError('Source guardrail geometry was lost or duplicated while clipping cells: ' + material)
        if extraction.digest(source_path) != source_hash:
            raise ValueError('Read-only source archive changed')
        maps[frame['mapId']] = {**frame, 'placements': placements,
            'coverage': {material: {'sourceGeometryArea': value, 'coveredGeometryArea': covered_area[material],
                'outsideMapGeometryArea': outside_area[material],
                'maximumShapeError': max(item['shapeError'] for item in placements if item['sourceMaterial'] == material)}
                for material, value in sorted(source_area.items())},
            'sourcePlanes': [{'group': surface.group, 'geometry': surface.geometry, 'material': surface.material,
                'texture': surface.texture, 'triangles': surface.triangles} for surface in scene['surfaces']
                if surface.terrain and surface.material in MATERIALS]}
    extraction.write_json(output / 'manifest.json', {'schemaVersion': 1, 'tool': str(Path(__file__).resolve()),
        'toolSha256': extraction.digest(Path(__file__)), 'models': models, 'sources': [scene['provenance'] for scene in scenes],
        'sourcesReadOnlyVerified': True, 'businessFamilies': sorted(MATERIALS),
        'limits': ['The original representative source UV remains unchanged in each unit; repeated arbitrary source-face phases are not copied',
            'Only full straight axial cells qualify as native Borders; compact corners, slope changes and fractional ends remain exact model instances',
            'Original ROM collision is not decoded; rail geometry does not infer walkable support']})
    extraction.write_json(output / 'reconstruction_recipe.json', {'schemaVersion': 1, 'maps': maps})
    print(json.dumps({'newModels': len(models), 'maps': {map_id: {'placements': len(value['placements']),
        'straightCells': sum(item['straightAxis'] is not None for item in value['placements']), 'coverage': value['coverage']}
        for map_id, value in maps.items()}}))


def main():
    parser = argparse.ArgumentParser()
    for name in ['corpus-root', 'route-source-root', 'nitro-root', 'project-root', 'kit-root', 'output-root']:
        parser.add_argument('--' + name, type=Path, required=True)
    build(parser.parse_args())


if __name__ == '__main__':
    main()

import argparse
from collections import defaultdict
from hashlib import sha256
import json
from pathlib import Path
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
import extract_units as extraction
from build_fence_units import area, geometry_error, shape
from city_models import clip_entries
from build_water_tiles import reanchor_model


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


def candidates(scene, frame):
    if scene['id'] == '587455':
        for label, materials, size, joined in [
            ('lamp', ['C12_ight', 'C12_l_hikari'], [1, 4, 1], True),
            ('bench', ['nagaisu'], [2, 1, 1], True),
            ('postbox', ['c12_post01'], [1, 2, 1], True),
            ('planter-bed', ['C12_kadan01', 'C12_kadan02'], [2, 1, 2], True),
            ('window-flowers', ['c12_flower'], [4, 1, 1], True),
            ('vegetable-row', ['C12_saien04', 'C12_saien05'], [2, 2, 1], True),
            ('retaining-panel', ['C12_kabe01'], [3, 3, .01], False),
        ]:
            entries = extraction.select_entries(scene['surfaces'], materials)
            entries = [(surface, triangle) for surface, triangle in entries if surface.terrain]
            for component in joined_objects(entries) if joined else extraction.component_triangles(entries):
                yield label, 'props', component, size, None
    translation = frame['sourceToNativeTranslation']
    for material, family, label, max_height in [('shore01', 'water', 'shore', .3),
                                              ('dansa01a', 'relief', 'low-ledge', .3),
                                              ('hana01_1', 'vegetation', 'ground-flowers', .25),
                                              ('kisetu_hana', 'vegetation', 'seasonal-flowers', .25)]:
        entries = extraction.select_entries(scene['surfaces'], [material])
        for (x, z), component in clip_entries(entries, 1, [-translation[0], 0, -translation[2]]):
            component = [(surface, triangle) for surface, triangle in component
                         if area([(surface, triangle)]) > 1e-9]
            if component:
                yield label, family, component, [1.001, max_height, 1.001], [x, z]


def build(args):
    output = args.output_root.resolve()
    roots = [args.corpus_root.resolve(), args.route_source_root.resolve(), args.project_root.resolve(), args.nitro_root.resolve()]
    if any(output == root or output.is_relative_to(root) for root in roots):
        raise ValueError('Derived detail output must remain outside source/project roots')
    scenes = [extraction.load_scene(args.route_source_root, 'rom-route19', True),
              extraction.load_scene(args.corpus_root, '587455')]
    original = json.loads((args.kit_root / 'manifest.json').read_text())
    originals = {model['id']: model for model in original['models']}
    main_specs = {scene['id']: extraction.route_units(scene['surfaces']) if scene['id'] == 'rom-route19'
                  else extraction.pavonnay_units(scene['surfaces']) for scene in scenes}
    all_materials = {surface.material for scene in scenes for surface in scene['surfaces']}
    nitro = extraction.NitroSources(args.nitro_root, all_materials)
    models, maps = [], {}
    for scene in scenes:
        source_path = scene['root'] / scene['record']['local_path']
        source_hash = extraction.digest(source_path)
        frame = extraction.native_frame(args.project_root, scene)
        prototypes = {}
        for specification in main_specs[scene['id']]:
            if specification['family'] not in ['vegetation', 'water']:
                continue
            identity, turns = shape(specification['entries'], scene)
            if specification['family'] == 'vegetation':
                anchor = originals[specification['id']]['sourceAnchorCells']
                if any(abs(anchor[axis] + frame['sourceToNativeTranslation'][axis] - .5
                           - round(anchor[axis] + frame['sourceToNativeTranslation'][axis] - .5)) > 1e-7 for axis in [0, 2]):
                    continue
            prototypes[identity] = {'model': originals[specification['id']], 'entries': specification['entries'], 'turns': turns}
        placements, coverage = [], defaultdict(lambda: {'sourceGeometryArea': 0, 'coveredGeometryArea': 0,
                                                      'sourceTriangleCount': 0, 'placements': 0, 'maximumShapeError': 0})
        for label, family, entries, max_size, cell in candidates(scene, frame):
            bounds = extraction.entries_bounds(entries)
            identity, turns = shape(entries, scene)
            cell_anchor = [cell[0] + .5 - frame['sourceToNativeTranslation'][0], bounds[1],
                           cell[1] + .5 - frame['sourceToNativeTranslation'][2]] if cell else None
            if family == 'vegetation':
                dx, dz = (bounds[0] + bounds[3]) / 2 - cell_anchor[0], (bounds[2] + bounds[5]) / 2 - cell_anchor[2]
                cosine, sine = [(1, 0), (0, 1), (-1, 0), (0, -1)][turns]
                canonical_offset = [round(cosine * dx + sine * dz, 8), round(-sine * dx + cosine * dz, 8)]
                if any(abs(value) > 1e-8 for value in canonical_offset):
                    identity = sha256(json.dumps([identity, canonical_offset]).encode()).hexdigest()
            prototype = prototypes.get(identity)
            if prototype is None:
                name = ('bw2-route19' if scene['id'] == 'rom-route19' else 'bw2-pavonnay') + '-' + label + '-' + identity[:12]
                support, support_evidence = extraction.source_support(scene['surfaces'], (bounds[0] + bounds[3]) / 2,
                    (bounds[2] + bounds[5]) / 2, bounds[1], 'route-19' if scene['id'] == 'rom-route19' else 'pavonnay')
                materials = sorted({surface.material for surface, _ in entries})
                specification = extraction.unit(scene['id'], name, family, entries, support, materials, max_size,
                    businessResourceId='nb2-' + label, unitLabel=label, sourceGeometryCompleteObject=family == 'props',
                    supportEvidence=support_evidence, maxTriangles=300,
                    uvPolicy='authentic representative source-unit UV; source repeated phases remain a measured visual-fidelity limit',
                    collision={'kind': 'none' if family in ['water', 'vegetation'] else 'separately_authored_object_footprint',
                               'sourceAuthored': False})
                model = extraction.emit_unit(specification, scene, output, nitro)
                if family == 'vegetation':
                    model = reanchor_model(model, cell_anchor)
                models.append(model)
                prototype = {'model': model, 'entries': entries, 'turns': turns}
                prototypes[identity] = prototype
            model = prototype['model']
            rotation = ((prototype['turns'] - turns) % 4) * 90
            error = geometry_error(entries, prototype['entries'], rotation)
            if error > 1e-6:
                raise ValueError('Source detail geometry differs beyond clipping precision')
            anchor = cell_anchor if family == 'vegetation' else [(bounds[0] + bounds[3]) / 2, bounds[1], (bounds[2] + bounds[5]) / 2]
            native = [anchor[axis] + frame['sourceToNativeTranslation'][axis] for axis in range(3)]
            in_map = 0 <= native[0] < frame['width'] and 0 <= native[2] < frame['depth']
            placements.append({'modelId': model['id'], 'unitLabel': label, 'family': family,
                'position': dict(zip(['x', 'y', 'z'], native)), 'rotationDegrees': rotation, 'scale': 1,
                'animationIndex': model['animation']['recommendedAnimationIndex'], 'blocksMovement': False,
                'sourceAnchor': anchor, 'sourceBounds': bounds, 'sourceMaterials': sorted({surface.material for surface, _ in entries}),
                'sourceCell': cell,
                'inMap': in_map, 'sourceShapeError': error, 'sourceUvIsRepresentative': True,
                'sourceReferences': extraction.reference_rows(scene, entries),
                'sourceObjectGeometryComplete': family == 'props'})
            for material in sorted({surface.material for surface, _ in entries}):
                measure = area([(surface, triangle) for surface, triangle in entries if surface.material == material])
                coverage[material]['coveredGeometryArea'] += measure
                coverage[material]['maximumShapeError'] = max(error, coverage[material]['maximumShapeError'])
                coverage[material]['placements'] += 1
        for surface in scene['surfaces']:
            if surface.terrain and surface.material in coverage:
                coverage[surface.material]['sourceGeometryArea'] += area([(surface, triangle) for triangle in surface.triangles])
                coverage[surface.material]['sourceTriangleCount'] += len(surface.triangles)
        for material, value in coverage.items():
            if abs(value['sourceGeometryArea'] - value['coveredGeometryArea']) > 1e-6:
                raise ValueError('Detail source geometry was lost or duplicated: ' + material)
        if extraction.digest(source_path) != source_hash:
            raise ValueError('Read-only source changed')
        maps[frame['mapId']] = {**frame, 'placements': placements, 'coverage': dict(coverage),
            'limits': ['Source flower cards below terrain remain at their original absolute Y; they are not raised onto green terrain',
                'Off-map units remain source evidence only and must not create support outside the authored map']}
    extraction.write_json(output / 'manifest.json', {'schemaVersion': 1, 'tool': str(Path(__file__).resolve()),
        'toolSha256': extraction.digest(Path(__file__)), 'models': models, 'sources': [scene['provenance'] for scene in scenes],
        'sourcesReadOnlyVerified': True,
        'businessResources': sorted({model['businessResourceId'] for model in models}),
        'limits': ['The original source unit UVs are retained; repetitive arbitrary long-face phase is not copied',
            'Each lamp, bench, postbox and planter is a complete authentic source object, never a regional detail group']})
    extraction.write_json(output / 'reconstruction_recipe.json', {'schemaVersion': 1, 'maps': maps})
    print(json.dumps({'models': len(models), 'modelsByLabel': dict(extraction.Counter(model['unitLabel'] for model in models)),
        'maps': {map_id: {'placements': len(value['placements']), 'outsideMap': sum(not row['inMap'] for row in value['placements']),
                           'coverage': value['coverage']} for map_id, value in maps.items()}}))


def main():
    parser = argparse.ArgumentParser()
    for name in ['corpus-root', 'route-source-root', 'nitro-root', 'project-root', 'kit-root', 'output-root']:
        parser.add_argument('--' + name, type=Path, required=True)
    build(parser.parse_args())


if __name__ == '__main__':
    main()

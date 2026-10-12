import argparse
from collections import defaultdict
from hashlib import sha256
import json
from pathlib import Path
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
import extract_units as extraction
from city_models import ramp_from_contacts, ramp_landing_points


STAIR_MATERIALS = {'rom-route19': ['kaidan01a'], '587455': ['c12_step']}


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


def build(args):
    kit, output = args.kit_root.resolve(), args.output_root.resolve()
    if not output.is_relative_to(kit) or output == kit:
        raise ValueError('Stair supplement must stay in a dedicated derived-kit subdirectory')
    recipe = json.loads((kit / 'reconstruction_recipe.json').read_text())
    scenes = [extraction.load_scene(args.route_source_root, 'rom-route19', True),
              extraction.load_scene(args.corpus_root, '587455')]
    if any(output.is_relative_to(root.resolve()) for root in (args.route_source_root, args.corpus_root, args.nitro_root)):
        raise ValueError('Derived stair units cannot overwrite read-only source assets')
    sources = extraction.NitroSources(args.nitro_root, {'kaidan01a', 'c12_step'})
    hashes = {scene['id']: extraction.digest(scene['root'] / scene['record']['local_path']) for scene in scenes}
    models, maps = [], {}
    for scene in scenes:
        map_id = 'unys-route-19' if scene['id'] == 'rom-route19' else 'first-map'
        frame = recipe['maps'][map_id]
        source_entries = extraction.select_entries(scene['surfaces'], STAIR_MATERIALS[scene['id']])
        components = extraction.component_triangles(source_entries)
        prototypes, placements, ramps = {}, [], []
        for index, component in enumerate(components):
            plane = walking_plane(component)
            identity = extraction.geometry_identity(component, scene['textures'])
            name = 'bw2-' + ('route19' if scene['id'] == 'rom-route19' else 'pavonnay') + '-staircase-' + identity[:12]
            if identity not in prototypes:
                bounds = extraction.entries_bounds(component)
                low_vertices = {tuple(vertex[:3]) for _, triangle in plane['entries'] for vertex in triangle
                                if abs(vertex[1] - plane['bounds'][1]) < 1e-7}
                support = [sum(vertex[axis] for vertex in low_vertices) / len(low_vertices) for axis in range(3)]
                specification = extraction.unit(scene['id'], name, 'relief', component, support,
                    STAIR_MATERIALS[scene['id']], [6, 6, 4], purpose='single_connected_source_staircase',
                    supportMeaning='lower_walking_edge_midpoint_of_original_native_ramp',
                    collision={'kind': 'native_ramp_and_separate_side_rails', 'sourceAuthored': False},
                    sourceComponentIndex=index, sourceConnectedComponentTriangleCount=len(component))
                model = extraction.emit_unit(specification, scene, output, sources)
                prototypes[identity] = model
                models.append(model)
            model = prototypes[identity]
            geometry = extraction.unit_geometry(component, plane['bounds'][:3])
            placed = extraction.placement(model, frame, geometry['sourceAnchorCells'], 'single_connected_original_staircase')
            placed['sourceComponentIndex'] = index
            placed['sourceReferences'] = extraction.reference_rows(scene, component)
            placements.append(placed)
            ramps.append({'modelId': model['id'], 'sourceComponentIndex': index,
                          **native_ramp(plane, frame, 'nb2-source-stair-ramp-' + str(index))})
        maps[map_id] = {'sourceToNativeTranslation': frame['sourceToNativeTranslation'],
            'levelHeight': frame['levelHeight'], 'placements': placements, 'ramps': ramps,
            'coverage': {'sourceStairComponents': len(components), 'reusableModels': len(prototypes),
                         'sourceStairTriangles': len(source_entries),
                         'extractedStairTriangles': sum(len(component) for component in components),
                         'qualifiedRamps': len(ramps)},
            'excludedMaterials': ['out_65_dan_2 is a flat decorative ledge, not a staircase'] if scene['id'] == '587455' else [],
            'limits': ['Source render geometry is preserved; ROM gameplay collision is not decoded',
                       'Quarter-height contacts are measured against nativePaint heightLevels; exact source slope remains in the GLB',
                       'Pavonnay upper ramp requires native SpatialRamp.highLevel to accept 36',
                       'Landings outside the connected staircase stay original native terrain surfaces']}
    if any(extraction.digest(scene['root'] / scene['record']['local_path']) != hashes[scene['id']] for scene in scenes):
        raise ValueError('Read-only stair source archive changed')
    extraction.write_json(output / 'manifest.json', {'schemaVersion': 1, 'tool': str(Path(__file__).resolve()),
        'toolSha256': extraction.digest(Path(__file__)), 'sourceManifestSha256': extraction.digest(kit / 'manifest.json'),
        'sourcesReadOnlyVerified': True, 'sourceArchiveHashes': hashes, 'models': models})
    extraction.write_json(output / 'reconstruction_recipe.json', {'schemaVersion': 1, 'maps': maps,
        'assembly': 'place reusable staircase models at exact source anchors and apply qualified native ramp rectangles'})
    print(json.dumps({'output': str(output), 'reusableStairModels': len(models),
                      'maps': {map_id: frame['coverage'] for map_id, frame in maps.items()}}, ensure_ascii=False))


def main():
    parser = argparse.ArgumentParser()
    for name in ('kit-root', 'output-root', 'corpus-root', 'route-source-root', 'nitro-root'):
        parser.add_argument('--' + name, type=Path, required=True)
    build(parser.parse_args())


if __name__ == '__main__':
    main()

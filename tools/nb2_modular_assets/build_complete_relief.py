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
from build_fence_units import area, geometry_error, rotated_entries, shape, straight_axis


MATERIALS = {'yamagake01', 'c12_gake01', 'gake01a', 'gake01a_2', 'gake1_0', 'gake1_1', 'C12_tile05'}


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


def selected_triangle(surface, triangle):
    return surface.terrain and surface.material in MATERIALS and not (
        surface.material in {'gake1_1', 'C12_tile05'}
        and max(vertex[1] for vertex in triangle) - min(vertex[1] for vertex in triangle) < 1e-8)


def cell_entries(scene, frame):
    bins = defaultdict(list)
    translation = frame['sourceToNativeTranslation']
    for surface in scene['surfaces']:
        for triangle in surface.triangles:
            if not selected_triangle(surface, triangle):
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
                    bins[x, z, surface.group, surface.material].extend(
                        (source, piece) for source, piece in pieces if area([(source, piece)]) > 1e-9)
    return {key: entries for key, entries in bins.items() if entries}


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


def build(args):
    output = args.output_root.resolve()
    roots = [args.corpus_root.resolve(), args.route_source_root.resolve(), args.nitro_root.resolve(), args.project_root.resolve()]
    if any(output == root or output.is_relative_to(root) for root in roots):
        raise ValueError('Derived relief output must remain outside every source/project root')
    scenes = [extraction.load_scene(args.route_source_root, 'rom-route19', True),
              extraction.load_scene(args.corpus_root, '587455')]
    scene_by_id = {scene['id']: scene for scene in scenes}
    existing = []
    for relative in ['manifest.json', 'relief/manifest.json']:
        existing.extend(model for model in json.loads((args.kit_root / relative).read_text())['models']
                        if model['family'] == 'relief')
    fixed_hashes = {model['path']: extraction.digest(Path(model['path'])) for model in existing}
    nitro = extraction.NitroSources(args.nitro_root, MATERIALS)
    strict, repeated = {}, {}
    for model in existing:
        scene = scene_by_id[model['sourceId']]
        entries = model_entries(model, scene)
        if not entries:
            raise ValueError('Existing reusable relief source cannot be reconstructed')
        identity, turns = appearance_identity(entries, scene)
        strict[scene['id'], identity] = {'model': model, 'entries': entries, 'turns': turns}
        if straight_axis(entries) is not None:
            identity, turns = shape(entries, scene)
            repeated[scene['id'], identity] = {'model': model, 'entries': entries, 'turns': turns}
    previous = json.loads((output / 'manifest.json').read_text()) if (output / 'manifest.json').is_file() else {}
    cached = {model['id']: model for model in previous.get('models', [])}
    models, maps = [], {}
    for scene in scenes:
        frame = extraction.native_frame(args.project_root, scene)
        source_path = scene['root'] / scene['record']['local_path']
        source_hash = extraction.digest(source_path)
        placements, coverage, outside = [], defaultdict(lambda: {'sourceGeometryArea': 0, 'coveredGeometryArea': 0,
            'outsideMapGeometryArea': 0, 'sourceTriangleCount': 0, 'sourceUnitCount': 0,
            'strictAppearanceUnitCount': 0, 'representativeProfileUnitCount': 0, 'maximumShapeError': 0,
            'maximumStrictSamplerAttributeError': 0}), []
        for surface in scene['surfaces']:
            selected = [(surface, triangle) for triangle in surface.triangles if selected_triangle(surface, triangle)]
            if selected:
                coverage[surface.material]['sourceTriangleCount'] += len(selected)
                coverage[surface.material]['sourceGeometryArea'] += area(selected)
        for (x, z, group, material), entries in sorted(cell_entries(scene, frame).items()):
            bounds = extraction.entries_bounds(entries)
            measured = area(entries)
            if not 0 <= x < frame['width'] or not 0 <= z < frame['depth']:
                coverage[material]['outsideMapGeometryArea'] += measured
                outside.append({'sourceCell': [x, z], 'sourceGroup': group, 'material': material,
                                'geometryArea': measured, 'bounds': bounds})
                continue
            identity, turns = appearance_identity(entries, scene)
            prototype = strict.get((scene['id'], identity))
            representative = False
            if prototype is None and straight_axis(entries) is not None:
                geometry_identity, geometry_turns = shape(entries, scene)
                prototype = repeated.get((scene['id'], geometry_identity))
                if prototype:
                    turns = geometry_turns
                    representative = True
            if prototype is None:
                name = 'bw2-' + ('route19' if scene['id'] == 'rom-route19' else 'pavonnay') + '-relief-exact-' + identity[:12]
                model = cached.get(name)
                if model:
                    if model['sourceBoundsCells'] != bounds or extraction.digest(Path(model['path'])) != model['sha256']:
                        raise ValueError('Existing supplementary model changed')
                else:
                    support = [(bounds[0] + bounds[3]) / 2, bounds[1], (bounds[2] + bounds[5]) / 2]
                    specification = extraction.unit(scene['id'], name, 'relief', entries, support, [material],
                        [1.001, 12, 1.001], businessResourceId='nb2-relief-' + material.lower(),
                        purpose='authentic_one_cell_source_profile_or_compact_irregular_junction',
                        supportMeaning='visual_source_geometry_not_a_walkable_support_claim',
                        uvPolicy='original_source_UV_and_vertex_RGB_preserved_modulo_identical_sampler_period',
                        collision={'kind': 'native_terrain_boundary_not_visual_bbox', 'sourceAuthored': False})
                    model = extraction.emit_unit(specification, scene, output, nitro)
                model['authoredAxis'] = 'east' if profile_axis(entries) == 0 else 'south' if profile_axis(entries) == 2 else None
                models.append(model)
                prototype = {'model': model, 'entries': entries, 'turns': turns}
                strict[scene['id'], identity] = prototype
            model = prototype['model']
            rotation = ((prototype['turns'] - turns) % 4) * 90
            error = geometry_error(entries, prototype['entries'], rotation)
            sampler_error = appearance_error(entries, prototype['entries'], rotation) if not representative else None
            if error > 1e-6 or (sampler_error is not None and sampler_error > 1e-5):
                raise ValueError('Strict source unit differs geometrically or in source sampler attributes')
            anchor = [(bounds[0] + bounds[3]) / 2, bounds[1], (bounds[2] + bounds[5]) / 2]
            native = [anchor[axis] + frame['sourceToNativeTranslation'][axis] for axis in range(3)]
            axis, authored = profile_axis(entries), profile_axis(prototype['entries'])
            placements.append({'modelId': model['id'], 'sourceMaterial': material, 'sourceGroup': group,
                'sourceCell': [x, z], 'sourceAnchor': anchor, 'sourceBounds': bounds,
                'position': dict(zip(['x', 'y', 'z'], native)), 'rotationDegrees': rotation, 'scale': 1,
                'animationIndex': model['animation']['recommendedAnimationIndex'], 'blocksMovement': False,
                'straightAxis': 'x' if axis == 0 else 'z' if axis == 2 else None,
                'authoredOrientation': 'east' if authored == 0 else 'south' if authored == 2 else None,
                'sourceGeometryArea': measured, 'geometryIdentity': identity,
                'sourceReferences': extraction.reference_rows(scene, entries), 'shapeError': error,
                'sourceUvIsRepresentative': representative, 'strictSamplerAttributeError': sampler_error})
            row = coverage[material]
            row['coveredGeometryArea'] += measured
            row['sourceUnitCount'] += 1
            row['representativeProfileUnitCount' if representative else 'strictAppearanceUnitCount'] += 1
            row['maximumShapeError'] = max(error, row['maximumShapeError'])
            row['maximumStrictSamplerAttributeError'] = max(sampler_error or 0, row['maximumStrictSamplerAttributeError'])
        for material, row in coverage.items():
            if abs(row['sourceGeometryArea'] - row['coveredGeometryArea'] - row['outsideMapGeometryArea']) > 1e-6:
                raise ValueError('Relief source geometry was lost or duplicated: ' + material)
        if extraction.digest(source_path) != source_hash:
            raise ValueError('Read-only source archive changed')
        maps[frame['mapId']] = {**frame, 'placements': placements, 'coverage': dict(sorted(coverage.items())),
            'outsideMapUnits': outside, 'sourcePlanes': [{'group': surface.group, 'geometry': surface.geometry,
                'material': surface.material, 'texture': surface.texture,
                'triangles': [triangle for triangle in surface.triangles if selected_triangle(surface, triangle)]}
                for surface in scene['surfaces'] if any(selected_triangle(surface, triangle) for triangle in surface.triangles)]}
    if any(extraction.digest(Path(path)) != value for path, value in fixed_hashes.items()):
        raise ValueError('Previously imported model bytes changed')
    extraction.write_json(output / 'manifest.json', {'schemaVersion': 1, 'tool': str(Path(__file__).resolve()),
        'toolSha256': extraction.digest(Path(__file__)), 'models': models, 'sources': [scene['provenance'] for scene in scenes],
        'sourcesReadOnlyVerified': True, 'previouslyImportedModelSha256Unchanged': fixed_hashes,
        'limits': ['Only previously qualified repeating straight profiles may use authentic representative UVs; every such source placement is marked',
            'All irregular units preserve original source UV and vertex RGB modulo sampler periods, verified on source planes',
            'Horizontal gake1_1 and C12_tile05 floors remain the native surface recipe responsibility',
            'This recipe replaces the preceding cliff recipe completely; applying both would duplicate geometry',
            'A visual rock component never establishes collision or fills null walkable support']})
    extraction.write_json(output / 'reconstruction_recipe.json', {'schemaVersion': 1,
        'replaces': 'relief/manifest.json.maps source assembly', 'maps': maps})
    print(json.dumps({'models': len(models), 'maps': {map_id: {'placements': len(value['placements']),
        'outsideMapUnits': len(value['outsideMapUnits']), 'coverage': value['coverage']} for map_id, value in maps.items()}}))


def main():
    parser = argparse.ArgumentParser()
    for name in ['corpus-root', 'route-source-root', 'nitro-root', 'project-root', 'kit-root', 'output-root']:
        parser.add_argument('--' + name, type=Path, required=True)
    build(parser.parse_args())


if __name__ == '__main__':
    main()

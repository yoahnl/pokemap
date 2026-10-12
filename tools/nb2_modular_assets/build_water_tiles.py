import argparse
from collections import defaultdict
from hashlib import sha256
from io import BytesIO
import json
from pathlib import Path
import struct
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
import extract_units as extraction
from build_semantic_tiles import affine_uv, pattern_image


MATERIALS = {'mizu_sita2': ('base', 8), 'ike01': ('overlay', 2)}
BUSINESS_ID = 'nb2-route19-water'


def periodic_entries(entries, period):
    return (all(abs(value - 1) < 1e-7 for _, triangle in entries for vertex in triangle for value in vertex[5:])
            and all(abs(vertex[axis] - vertex[position] / period - constant
                   - round(vertex[axis] - vertex[position] / period - constant)) < 1e-6
               for _, triangle in entries for vertex in triangle
               for axis, position, constant in ((3, 0, 0), (4, 2, 1))))


def cell_records(scene, frame, material):
    translation = frame['sourceToNativeTranslation']
    surfaces = [surface for surface in scene['surfaces'] if surface.material == material]
    cells = extraction.cell_triangles(surfaces, [-translation[0], 0, -translation[2]],
                                      frame['width'], frame['depth'])
    result = []
    for (x, z), entries in sorted(cells.items(), key=lambda row: (row[0][1], row[0][0])):
        source_x, source_z = x - translation[0], z - translation[2]
        clipped = extraction.clip_selected(entries, [source_x, source_z, source_x + 1, source_z + 1])
        area = sum(extraction.projected_area(triangle) for _, triangle in clipped)
        if area < 1e-8:
            continue
        bounds = extraction.entries_bounds(clipped)
        if bounds[4] - bounds[1] > 1e-6 or area > 1 + 1e-6:
            raise ValueError(f'Water cell mixes levels or overlaps source planes: {material} {x},{z}')
        anchor = [source_x + .5, bounds[1], source_z + .5]
        center_weights = [(surface, triangle, extraction.barycentric(anchor[0], anchor[2], triangle))
                          for surface, triangle in clipped]
        center_hit = next(((surface, triangle, weights) for surface, triangle, weights in center_weights
                           if weights is not None), None)
        result.append({'x': x, 'z': z, 'sourceCell': [source_x, source_z],
                       'anchor': anchor, 'entries': clipped, 'coverage': area,
                       'centerCovered': center_hit is not None,
                       'centerUv': [extraction.interpolate(center_hit[1], center_hit[2], axis)
                                    for axis in (3, 4)] if center_hit is not None else None})
    source_area = sum(extraction.projected_area(triangle) for surface in surfaces for triangle in surface.triangles)
    if abs(source_area - sum(row['coverage'] for row in result)) > 1e-6:
        raise ValueError(f'Water source coverage escapes the native map frame: {material}')
    return result


def identity(row, textures):
    bounds = extraction.entries_bounds(row['entries'])
    offset = [round((bounds[axis] + bounds[axis + 3]) / 2 - row['anchor'][axis], 8)
              for axis in (0, 2)]
    return sha256(json.dumps([extraction.geometry_identity(row['entries'], textures), offset]).encode()).hexdigest()


def reanchor_model(model, anchor):
    delta = [anchor[axis] - model['sourceAnchorCells'][axis] for axis in range(3)]
    path = Path(model['path'])
    document, original = extraction.read_glb(path.read_bytes())
    binary = bytearray(original)
    accessors = {primitive['attributes']['POSITION'] for mesh in document['meshes']
                 for primitive in mesh['primitives']}
    for index in accessors:
        accessor = document['accessors'][index]
        view = document['bufferViews'][accessor['bufferView']]
        if accessor['componentType'] != 5126 or accessor['type'] != 'VEC3' or 'sparse' in accessor:
            raise ValueError('Unexpected water POSITION encoding')
        start = view.get('byteOffset', 0) + accessor.get('byteOffset', 0)
        for vertex_index in range(accessor['count']):
            offset = start + vertex_index * view.get('byteStride', 12)
            values = struct.unpack_from('<fff', binary, offset)
            struct.pack_into('<fff', binary, offset, *(values[axis] - delta[axis] for axis in range(3)))
        for bound in ('min', 'max'):
            if bound in accessor:
                accessor[bound] = [accessor[bound][axis] - delta[axis] for axis in range(3)]
    document['extras']['nb2SourceUnit']['anchorPolicy'] = 'source_cell_center_preserving_clipped_boundary_offset'
    encoded = extraction.glb_bytes(document, bytes(binary))
    path.write_bytes(encoded)
    return {**model, 'sourceAnchorCells': anchor,
            'supportAnchorLocal': [model['sourceSupportAnchor'][axis] - anchor[axis] for axis in range(3)],
            'bounds': [model['sourceBoundsCells'][axis] - anchor[axis % 3] for axis in range(6)],
            'sha256': sha256(encoded).hexdigest(), 'byteLength': len(encoded),
            'anchorPolicy': 'cell_center_for_native_smart_tile_parts'}


def model_part(model_id, offset_y, animation_index):
    return {'source': {'kind': 'model3d', 'modelId': model_id, 'scale': 1,
                       'offsetY': offset_y, 'animationIndex': animation_index, 'followTerrain': False},
            'channel': 'ground', 'drawOrder': 0}


def water_pattern(base_phases, overlay_phases, translation):
    cells = []
    for z in range(8):
        for x in range(8):
            source_x, source_z = x - translation[0], z - translation[2]
            base = base_phases[int(source_x) % 8, int(source_z) % 8]
            overlay = overlay_phases[int(source_x) % 2, int(source_z) % 2]
            cells.append({'x': x, 'y': z, 'parts': [model_part(base, -2 + translation[1], 0),
                                                   model_part(overlay, .5 + translation[1], 0)]})
    return {'id': BUSINESS_ID, 'name': 'Eau NB2 — fond et surface originale', 'usage': 'terrain',
            'width': 8, 'height': 8, 'repeatMode': 'tiled', 'cells': cells,
            'tags': ['water', 'source-original', 'internal-uv-phases']}


def build(args):
    roots = [args.route_source_root.resolve(), args.nitro_root.resolve(), args.project_root.resolve()]
    output = args.output_root.resolve()
    if any(output == root or output.is_relative_to(root) for root in roots):
        raise ValueError('Water output must remain outside read-only source/project roots')
    if (output / 'manifest.json').exists():
        previous = json.loads((output / 'manifest.json').read_text())
        if previous.get('tool') != str(Path(__file__).resolve()):
            raise ValueError('Output belongs to another generator')
    scene = extraction.load_scene(args.route_source_root, 'rom-route19', True)
    frame = extraction.native_frame(args.project_root, scene)
    source_path = scene['root'] / scene['record']['local_path']
    source_hash = extraction.digest(source_path)
    sources = extraction.NitroSources(args.nitro_root, set(MATERIALS))
    models, components, coverage = [], {}, {}
    phases = defaultdict(dict)
    for material, (role, period) in MATERIALS.items():
        shapes = {}
        rows = cell_records(scene, frame, material)
        components[role] = []
        for row in rows:
            full = abs(row['coverage'] - 1) < 1e-7
            periodic = full and periodic_entries(row['entries'], period)
            source_x, source_z = row['sourceCell']
            phase = [int(source_x) % period, int(source_z) % period] if periodic else None
            shape = (sha256(json.dumps([role, phase]).encode()).hexdigest() if periodic
                     else identity(row, scene['textures']))
            if shape not in shapes:
                name = (f'bw2-water-{role}-phase-{phase[0]}-{phase[1]}' if periodic
                        else f'bw2-water-{role}-source-{shape[:12]}')
                specification = extraction.unit('rom-route19', name, 'water', row['entries'], row['anchor'],
                    [material], [1, .01, 1], supportMeaning='visual_water_plane_not_walkable_ground',
                    resourceRole='internal_pattern_component', businessResourceId=BUSINESS_ID,
                    userVisible=False, uvPeriodCells=period if periodic else None,
                    sourcePhase=phase, sourceCoverageRatio=row['coverage'],
                    collision={'kind': 'separately_authored_water_area', 'sourceAuthored': False})
                model = reanchor_model(extraction.emit_unit(specification, scene, output, sources), row['anchor'])
                document, _ = extraction.read_glb(Path(model['path']).read_bytes())
                for clip in document.get('extras', {}).get('aveluneMaterialAnimations', {}).get('clips', []):
                    if any(any(abs(value - expected) > 1e-7 for value, expected in zip(transform[:4], [1, 0, 0, 1]))
                           for track in clip['tracks'] for transform in track['transforms']):
                        raise ValueError('Water UV integer normalization cannot preserve a non-translation animation')
                shapes[shape] = model
                models.append(model)
            model = shapes[shape]
            if periodic:
                phases[role][tuple(phase)] = model['id']
            native_y = row['anchor'][1] + frame['sourceToNativeTranslation'][1]
            components[role].append({'x': row['x'], 'z': row['z'], 'modelId': model['id'],
                'sourceCell': row['sourceCell'], 'sourcePlaneY': row['anchor'][1], 'nativePlaneY': native_y,
                'sourceCoverageRatio': row['coverage'], 'sourceCenterCovered': row['centerCovered'],
                'sourceCenterUv': row['centerUv'], 'sourcePhase': phase,
                'animationIndex': model['animation']['recommendedAnimationIndex'],
                'position': {'x': row['x'] + .5, 'y': native_y, 'z': row['z'] + .5},
                'rotationDegrees': 0, 'scale': 1,
                'sourceReferences': extraction.reference_rows(scene, row['entries'])})
        coverage[role] = {'sourceProjectedAreaCells': sum(row['coverage'] for row in rows),
                          'coveredProjectedAreaCells': sum(row['coverage'] for row in rows),
                          'fullCells': sum(abs(row['coverage'] - 1) < 1e-7 for row in rows),
                          'partialCells': sum(abs(row['coverage'] - 1) >= 1e-7 for row in rows),
                          'unitComponents': len(shapes), 'periodicPhases': len(phases[role]),
                          'sourceTexture': extraction.texture_rows(scene, rows[0]['entries'])[0]}
    if len(phases['base']) != 64 or len(phases['overlay']) != 4:
        raise ValueError('Original water phase grid is incomplete')
    base_by_cell = {(row['x'], row['z']): row for row in components['base']}
    stacks = []
    for overlay in components['overlay']:
        base = base_by_cell.get((overlay['x'], overlay['z']))
        baseline = overlay['nativePlaneY']
        parts = ([model_part(base['modelId'], base['nativePlaneY'], base['animationIndex'])] if base else [])
        parts.append(model_part(overlay['modelId'], overlay['nativePlaneY'], overlay['animationIndex']))
        stacks.append({'x': overlay['x'], 'z': overlay['z'], 'nativeAnchorY': baseline,
                       'basePresent': base is not None, 'parts': parts,
                       'baseCoverageRatio': base['sourceCoverageRatio'] if base else 0,
                       'overlayCoverageRatio': overlay['sourceCoverageRatio']})
    textures = []
    for material, (role, period) in MATERIALS.items():
        surface = next(surface for surface in scene['surfaces'] if surface.material == material)
        path = output / 'textures' / surface.texture
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(scene['textures'][surface.texture])
        image = extraction.Image.open(BytesIO(scene['textures'][surface.texture])).convert('RGBA')
        mapping = {'periodCells': period, 'uvMatrix': [[1 / period, 0, 0], [0, 1 / period, 1]],
                   'area': {'wraps': surface.wraps}}
        atlas_path = output / 'native-tiles' / (role + '-native-uv-period.png')
        atlas_path.parent.mkdir(parents=True, exist_ok=True)
        pattern_image(image, mapping, frame['sourceToNativeTranslation']).save(atlas_path)
        textures.append({'sourceMaterial': material, 'file': str(path.relative_to(output)),
                         'sha256': extraction.digest(path), 'pixelSize': list(image.size),
                         'opacity': surface.opacity, 'uvMatrix': mapping['uvMatrix'],
                         'periodCells': period, 'nativePhaseAtlas': str(atlas_path.relative_to(output)),
                         'nativePhaseAtlasSha256': extraction.digest(atlas_path),
                         'nativePhaseAtlasUsage': 'source-UV reference; overlay animation remains in GLB material tracks'})
    unchanged = extraction.digest(source_path) == source_hash
    if not unchanged:
        raise ValueError('Read-only source archive changed')
    manifest = {'schemaVersion': 1, 'tool': str(Path(__file__).resolve()), 'toolSha256': extraction.digest(Path(__file__)),
                'businessResources': [{'id': BUSINESS_ID, 'family': 'water', 'componentIds': [model['id'] for model in models]}],
                'sourcesReadOnlyVerified': unchanged, 'sources': [scene['provenance']],
                'models': models, 'sourceTextureAssets': textures, 'coverage': coverage,
                'limits': ['The upper lake has small original non-periodic UV warps and no mizu_sita2 base',
                           'Each fractional boundary remains one clipped cell, never a regional water mesh',
                           'Water visual planes do not declare walkable floor or decoded ROM collision',
                           'Original material animation uses the existing explicit 60 Hz assumption']}
    recipe = {'schemaVersion': 1, 'mapId': frame['mapId'], 'sourceToNativeTranslation': frame['sourceToNativeTranslation'],
              'width': frame['width'], 'depth': frame['depth'], 'businessResourceId': BUSINESS_ID,
              'periodicLowBasinPattern': water_pattern(phases['base'], phases['overlay'], frame['sourceToNativeTranslation']),
              'patternContract': {'nativeAnchorY': .5 + frame['sourceToNativeTranslation'][1],
                  'baseOffsetY': -2 + frame['sourceToNativeTranslation'][1],
                  'overlayOffsetY': .5 + frame['sourceToNativeTranslation'][1], 'followTerrain': False,
                  'phaseX': 0, 'phaseY': 0,
                  'usage': 'only fully covered low-basin cells; source map phase at native origin is baked into pattern order',
                  'exceptions': 'use exactCellStacks for upper lake and fractional boundaries'},
              'components': components, 'exactCellStacks': stacks,
              'sourcePlanes': [{'group': surface.group, 'geometry': surface.geometry, 'material': surface.material,
                                'texture': surface.texture, 'opacity': surface.opacity, 'wraps': surface.wraps,
                                'sourceTriangles': surface.triangles,
                                'sourceUvAffines': [affine_uv(triangle) for triangle in surface.triangles]}
                               for surface in scene['surfaces'] if surface.material in MATERIALS],
              'coverage': coverage, 'qualityOrder': ['check source hashes and full/partial projected coverage',
                  'paint blocked water masks using original base presence and source UV phase',
                  'place both low-basin visual planes at -2.25 and .25 without a green fallback',
                  'keep upper lake overlay at 5.25 without an invented base',
                  'compare original material-animation frames and source view before acceptance']}
    extraction.write_json(output / 'manifest.json', manifest)
    extraction.write_json(output / 'reconstruction_recipe.json', recipe)
    print(json.dumps({'output': str(output), 'businessResources': 1, 'models': len(models), 'coverage': coverage,
                      'overlayStacksWithBase': sum(row['basePresent'] for row in stacks),
                      'overlayStacksWithoutBase': sum(not row['basePresent'] for row in stacks)}, ensure_ascii=False))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--route-source-root', type=Path, required=True)
    parser.add_argument('--nitro-root', type=Path, required=True)
    parser.add_argument('--project-root', type=Path, required=True)
    parser.add_argument('--output-root', type=Path, required=True)
    build(parser.parse_args())


if __name__ == '__main__':
    main()

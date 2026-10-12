import argparse
from copy import copy
from hashlib import sha256
import json
from pathlib import Path
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
import extract_units as extraction
from build_water_tiles import cell_records, model_part, periodic_entries


def build(args):
    output = args.output_root.resolve()
    roots = [args.corpus_root.resolve(), args.route_source_root.resolve(), args.project_root.resolve(), args.nitro_root.resolve()]
    if any(output == root or output.is_relative_to(root) for root in roots):
        raise ValueError('Derived recipe must remain outside source and project roots')
    scene = extraction.load_scene(args.corpus_root, '587455')
    route = extraction.load_scene(args.route_source_root, 'rom-route19', True)
    frame = extraction.native_frame(args.project_root, scene)
    manifest_path = args.water_root / 'manifest.json'
    manifest = json.loads(manifest_path.read_text())
    source_hashes = [extraction.digest(value['root'] / value['record']['local_path']) for value in [scene, route]]
    models = {}
    for model in manifest['models']:
        phase = model.get('sourcePhase')
        if phase is not None:
            role = 'base' if model['materials'][0]['name'] == 'mizu_sita2' else 'overlay'
            models[role, tuple(phase)] = model
    sources = extraction.NitroSources(args.nitro_root, {'mizu_sita2', 'ike01'})
    components, coverage, proofs = {}, {}, {}
    reused = {}
    for material, role, period in [('mizu_sita2', 'base', 8), ('ike01', 'overlay', 2)]:
        rows = cell_records(scene, frame, material)
        components[role] = []
        for row in rows:
            if abs(row['coverage'] - 1) > 1e-7 or not periodic_entries(row['entries'], period):
                raise ValueError('Pavonnay water is not the qualified full periodic source plane')
            phase = tuple(int(value) % period for value in row['sourceCell'])
            model = models[role, phase]
            source_bounds = model['sourceBoundsCells']
            source_entries = extraction.clip_selected(extraction.select_entries(route['surfaces'], [material]),
                [source_bounds[0], source_bounds[2], source_bounds[3], source_bounds[5]])
            opacity_error = abs(row['entries'][0][0].opacity - source_entries[0][0].opacity)
            if opacity_error > 1e-7:
                raise ValueError('Source water opacity differs beyond converter float precision')
            surfaces = {}
            for surface, _ in row['entries']:
                surfaces[id(surface)] = copy(surface)
                surfaces[id(surface)].opacity = source_entries[0][0].opacity
            comparable = [(surfaces[id(surface)], triangle) for surface, triangle in row['entries']]
            if extraction.geometry_identity(comparable, scene['textures']) != extraction.geometry_identity(source_entries, route['textures']):
                raise ValueError(f'Reused source water phase differs: {role} {phase}')
            if model['id'] not in reused:
                data = Path(model['path']).read_bytes()
                if sha256(data).hexdigest() != model['sha256']:
                    raise ValueError('Existing water GLB hash differs')
                document, binary = extraction.read_glb(data)
                animated, evidence, unsupported = extraction.animated_material_document(document, binary, {},
                    extraction.animation_context(scene), sources, 60)
                if unsupported or animated is None:
                    raise ValueError('Pavonnay source material animation is not qualified')
                if animated['extras']['aveluneMaterialAnimations'] != document['extras']['aveluneMaterialAnimations']:
                    raise ValueError('Pavonnay material track differs from the reused Route source clip')
                reused[model['id']] = model
                proofs[model['id']] = {'geometryUvTextureIdentity': True, 'nitroMaterialTrackIdentical': True,
                                      'sha256': model['sha256'], 'sourceAnimationEvidence': evidence,
                                      'opacityConverterPrecisionError': opacity_error}
            y = row['anchor'][1] + frame['sourceToNativeTranslation'][1]
            components[role].append({'x': row['x'], 'z': row['z'], 'modelId': model['id'],
                'sourceCell': row['sourceCell'], 'sourcePlaneY': row['anchor'][1], 'nativePlaneY': y,
                'sourceCoverageRatio': 1, 'sourceCenterCovered': True, 'sourceCenterUv': row['centerUv'],
                'sourcePhase': list(phase), 'animationIndex': 0,
                'position': {'x': row['x'] + .5, 'y': y, 'z': row['z'] + .5},
                'rotationDegrees': 0, 'scale': 1, 'sourceReferences': extraction.reference_rows(scene, row['entries'])})
        coverage[role] = {'sourceProjectedAreaCells': len(rows), 'coveredProjectedAreaCells': len(rows),
                          'fullCells': len(rows), 'partialCells': 0, 'periodicPhases': len({tuple(row['sourcePhase']) for row in components[role]}),
                          'sourceTexture': extraction.texture_rows(scene, rows[0]['entries'])[0]}
    layers = {role: {(row['x'], row['z']): row for row in rows} for role, rows in components.items()}
    stacks = []
    for x, z in sorted(set(layers['base']) | set(layers['overlay']), key=lambda point: (point[1], point[0])):
        base, overlay = layers['base'].get((x, z)), layers['overlay'].get((x, z))
        stacks.append({'x': x, 'z': z, 'basePresent': base is not None, 'overlayPresent': overlay is not None,
            'nativeAnchorY': (overlay or base)['nativePlaneY'],
            'baseCoverageRatio': 1 if base else 0, 'overlayCoverageRatio': 1 if overlay else 0,
            'parts': [model_part(row['modelId'], row['nativePlaneY'], 0) for row in [base, overlay] if row]})
    pattern = []
    for z in range(8):
        for x in range(8):
            sx, sz = x - frame['sourceToNativeTranslation'][0], z - frame['sourceToNativeTranslation'][2]
            pattern.append({'x': x, 'y': z, 'parts': [model_part(models['base', (int(sx) % 8, int(sz) % 8)]['id'], -2, 0),
                model_part(models['overlay', (int(sx) % 2, int(sz) % 2)]['id'], .5, 0)]})
    unchanged = source_hashes == [extraction.digest(value['root'] / value['record']['local_path']) for value in [scene, route]]
    if not unchanged:
        raise ValueError('Read-only source archive changed')
    recipe = {'schemaVersion': 1, 'mapId': frame['mapId'], 'businessResourceId': 'nb2-pavonnay-water',
        **frame, 'components': components, 'exactCellStacks': stacks, 'coverage': coverage,
        'periodicLowBasinPattern': {'id': 'nb2-pavonnay-water', 'name': 'Eau NB2 · Pavonnay', 'usage': 'terrain',
            'width': 8, 'height': 8, 'repeatMode': 'tiled', 'cells': pattern, 'tags': ['water', 'source-original']},
        'patternContract': {'baseOffsetY': -2, 'overlayOffsetY': .5, 'baseAnimationIndex': 0,
            'overlayAnimationIndex': 0, 'followTerrain': False, 'phaseX': 0, 'phaseY': 0,
            'usage': 'two-part pattern only where both source planes exist; exactCellStacks retains 202 base-only cells'},
        'sourcePlanes': [{'group': surface.group, 'geometry': surface.geometry, 'material': surface.material,
            'texture': surface.texture, 'opacity': surface.opacity, 'wraps': surface.wraps,
            'sourceTriangles': surface.triangles} for surface in scene['surfaces'] if surface.material in ['ike01', 'mizu_sita2']],
        'limits': ['Source water planes are visual only; no invented green bed or walkable terrain support',
            'Original Nitro material clip uses the existing explicit 60 Hz assumption']}
    extraction.write_json(output / 'reconstruction_recipe.json', recipe)
    extraction.write_json(output / 'manifest.json', {'schemaVersion': 1, 'tool': str(Path(__file__).resolve()),
        'toolSha256': extraction.digest(Path(__file__)), 'models': list(reused.values()), 'reusedExistingGlbs': True,
        'newGlbCount': 0, 'sourcesReadOnlyVerified': unchanged, 'sources': [scene['provenance'], route['provenance']],
        'reusedPhaseProofs': proofs, 'coverage': coverage})
    print(json.dumps({'modelsReused': len(reused), 'newGlbs': 0, 'coverage': coverage, 'stacks': len(stacks)}))


def main():
    parser = argparse.ArgumentParser()
    for name in ['corpus-root', 'route-source-root', 'nitro-root', 'project-root', 'water-root', 'output-root']:
        parser.add_argument('--' + name, type=Path, required=True)
    build(parser.parse_args())


if __name__ == '__main__':
    main()

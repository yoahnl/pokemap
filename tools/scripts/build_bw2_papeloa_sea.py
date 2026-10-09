import argparse
from hashlib import sha256
from io import BytesIO
import json
from pathlib import Path
import shlex
import sys

from PIL import Image

sys.dont_write_bytecode = True
REPOSITORY = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPOSITORY / 'apps/unys_3d_sources'))

from city_geometry import source_scene
from convert_bw2_village_assets import emit_model


SOURCE_ID = '587491'
ARCHIVE_SHA256 = '8d8c7969c9f15520f500a082c65cd63e40be1e725fc76c897fe8a3ab0a69eb1c'
DAE_SHA256 = '04dfae473e31e138b379c1105ef50309a015724963a1310a4158bf8acd6c90d3'
TEXTURE_SHA256 = '5a351fae0341c32dc563b2fd3c1e91bccaccc2a11e020c922752927d7637cc0e'
SOURCE_ORIGIN = (-24, 0, -33)
WORLD_HEIGHT = -2.0625
MODULE_SIZES = ((16, 16), (8, 16), (16, 2), (8, 2))
ANIMATION_SHA256 = '2c9a5c778f2f3ee0f3fa7b4c82e5586774e8f08e5769d5ed954b5b1b21071982'
ANIMATION_FRAME_RATE = 60
ANIMATION_SPEED = .5
SURFACE_HEIGHT = -.4375
FOOTPRINT_EPSILON = 1e-8


def polygon_area(polygon):
    return sum(a[0] * b[1] - b[0] * a[1] for a, b in zip(polygon, polygon[1:] + polygon[:1])) / 2


def clean_footprint(polygon):
    result = []
    for point in polygon:
        if not result or max(abs(a - b) for a, b in zip(point, result[-1])) > FOOTPRINT_EPSILON:
            result.append(point)
    if len(result) > 1 and max(abs(a - b) for a, b in zip(result[0], result[-1])) <= FOOTPRINT_EPSILON:
        result.pop()
    if len(result) < 3 or abs(polygon_area(result)) <= FOOTPRINT_EPSILON:
        return []
    return result if polygon_area(result) > 0 else result[::-1]


def split_footprint(polygon, a, b):
    def side(point):
        return (b[0] - a[0]) * (point[1] - a[1]) - (b[1] - a[1]) * (point[0] - a[0])

    inside, outside = [], []
    previous = polygon[-1]
    previous_side = side(previous)
    for current in polygon:
        current_side = side(current)
        if (previous_side < 0 < current_side) or (current_side < 0 < previous_side):
            t = previous_side / (previous_side - current_side)
            intersection = tuple(x + t * (y - x) for x, y in zip(previous, current))
            inside.append(intersection)
            outside.append(intersection)
        if current_side >= 0:
            inside.append(current)
        if current_side <= 0:
            outside.append(current)
        previous, previous_side = current, current_side
    return clean_footprint(inside), clean_footprint(outside)


def subtract_footprints(polygon, exclusions):
    initial = clean_footprint(polygon)
    pieces = [initial] if initial else []
    for exclusion in exclusions:
        triangle = clean_footprint(exclusion)
        if not triangle:
            continue
        lower = [min(point[axis] for point in triangle) for axis in (0, 1)]
        upper = [max(point[axis] for point in triangle) for axis in (0, 1)]
        result = []
        for piece in pieces:
            if any(max(point[axis] for point in piece) <= lower[axis] or
                   min(point[axis] for point in piece) >= upper[axis] for axis in (0, 1)):
                result.append(piece)
                continue
            remaining = piece
            for a, b in zip(triangle, triangle[1:] + triangle[:1]):
                remaining, outside = split_footprint(remaining, a, b)
                if outside:
                    result.append(outside)
                if not remaining:
                    break
        pieces = result
    return pieces


def sea_surface_footprints(surfaces):
    selected = [surface for surface in surfaces if surface.material == 'sea_mizu1_1'
                or surface.material.startswith(('out58_ragu', 'out58_zan', 'sea_zanami'))
                or surface.material in ('sea_simi_1', 'sea_jimen')]
    masks = [clean_footprint([(v[0] - SOURCE_ORIGIN[0], v[2] - SOURCE_ORIGIN[2]) for v in triangle])
             for surface in selected for triangle in surface.triangles]
    return [mask for mask in masks if mask], sorted({surface.material for surface in selected})


def sea_surface_geometry(polygons, texture_name, texture_bytes, transform):
    vertices = []
    for polygon in polygons:
        for index in range(1, len(polygon) - 1):
            triangle = (polygon[0], polygon[index + 1], polygon[index])
            if abs(polygon_area(list(triangle))) <= FOOTPRINT_EPSILON:
                continue
            for x, z in triangle:
                x, z = round(x, 8), round(z, 8)
                source_x, source_z = x + SOURCE_ORIGIN[0], z + SOURCE_ORIGIN[2]
                uv = [row[0] * source_x + row[1] * source_z + row[2] for row in transform]
                vertices.append([x, 0, z, *uv, 1, 1, 1])
    if not vertices:
        raise ValueError('Sea surface clipping produced no drawable geometry')
    return {'surfaces': {texture_name: vertices}, 'textures': {texture_name: texture_bytes},
            'samplers': {texture_name: ['WRAP', 'WRAP']}, 'doubleSided': {texture_name: False}}


def surface_uv_transform(surfaces):
    if not surfaces or any(surface.wraps != ['WRAP', 'WRAP'] for surface in surfaces):
        raise ValueError('Source sea requires original WRAP samplers')
    a, b, c = surfaces[0].triangles[0]
    dx1, dz1 = b[0] - a[0], b[2] - a[2]
    dx2, dz2 = c[0] - a[0], c[2] - a[2]
    determinant = dx1 * dz2 - dx2 * dz1
    if abs(determinant) < 1e-8:
        raise ValueError('Source sea has no horizontal UV reference')
    transform = []
    for channel in (3, 4):
        du1, du2 = b[channel] - a[channel], c[channel] - a[channel]
        gradient_x = (du1 * dz2 - du2 * dz1) / determinant
        gradient_z = (dx1 * du2 - dx2 * du1) / determinant
        transform.append([gradient_x, gradient_z, a[channel] - gradient_x * a[0] - gradient_z * a[2]])
    for surface in surfaces:
        for triangle in surface.triangles:
            for vertex in triangle:
                if abs(vertex[1] - a[1]) > 1e-8:
                    raise ValueError('Source sea reference is not horizontal')
                for channel, coefficients in enumerate(transform):
                    delta = coefficients[0] * vertex[0] + coefficients[1] * vertex[2] + coefficients[2] - vertex[channel + 3]
                    if abs(delta - round(delta)) > 1e-8:
                        raise ValueError('Source sea UV phase changes across sectors')
    if transform != [[.25, 0, 0], [0, .25, 1]]:
        raise ValueError('Source sea no longer uses its verified four-cell UV repeat')
    return transform


def module_geometry(width, depth, texture_name, texture_bytes, transform):
    if (width, depth) not in MODULE_SIZES:
        raise ValueError('Unsupported Papeloa sea module dimensions')
    vertices = []
    for x, z in ((0, 0), (0, depth), (width, depth), (width, 0)):
        source_x, source_z = x + SOURCE_ORIGIN[0], z + SOURCE_ORIGIN[2]
        uv = [row[0] * source_x + row[1] * source_z + row[2] for row in transform]
        vertices.append([x, 0, z, *uv, 1, 1, 1])
    return {'surfaces': {texture_name: [vertices[i] for i in (0, 1, 2, 0, 2, 3)]},
            'textures': {texture_name: texture_bytes}, 'samplers': {texture_name: ['WRAP', 'WRAP']},
            'doubleSided': {texture_name: False}}


def placements():
    instances = []
    for row, z in enumerate(range(0, 82, 16)):
        for column, x in enumerate(range(0, 56, 16)):
            width, depth = min(16, 56 - x), min(16, 82 - z)
            instances.append({'id': f'unys-papeloa-sea-backing-c{column}-r{row}',
                              'modelId': f'unys-papeloa-sea-backing-{width}x{depth}',
                              'position': {'x': x + width / 2, 'y': WORLD_HEIGHT, 'z': z + depth / 2},
                              'rotationDegrees': 0, 'scale': 1, 'blocksMovement': False})
    return instances


def build(source_root, output_root):
    source_root = source_root.resolve(strict=True)
    output_root = output_root.resolve()
    if output_root == source_root or source_root in output_root.parents or output_root in source_root.parents:
        raise ValueError('Output must be separate from the original source root')
    records = json.loads((source_root / 'manifest.json').read_text())['assets']
    record = next(record for record in records if str(record['id']) == SOURCE_ID)
    if record['sha256'] != ARCHIVE_SHA256:
        raise ValueError('Original Papeloa archive fingerprint changed')
    surfaces, textures, provenance = source_scene(source_root, record)
    sea = [surface for surface in surfaces if surface.material == 'sea_mizu1_1']
    transform = surface_uv_transform(sea)
    if provenance['memberSha256'] != DAE_SHA256:
        raise ValueError('Original Papeloa COLLADA fingerprint changed')
    texture_names = {surface.texture for surface in sea}
    if len(texture_names) != 1:
        raise ValueError('Original sea planes require one shared texture')
    texture_name = texture_names.pop()
    texture_bytes = textures[texture_name]
    if sha256(texture_bytes).hexdigest() != TEXTURE_SHA256:
        raise ValueError('Original Papeloa sea texture fingerprint changed')
    with Image.open(BytesIO(texture_bytes)) as image:
        if image.size != (32, 32) or image.convert('RGBA').getextrema()[3] != (255, 255):
            raise ValueError('Original sea texture must be opaque and 32 by 32 pixels')
    output_root.mkdir(parents=True, exist_ok=True)
    if any(path.is_symlink() for path in output_root.iterdir()):
        raise ValueError('Output folder cannot contain symbolic links')
    (output_root / texture_name).write_bytes(texture_bytes)
    models = []
    for width, depth in MODULE_SIZES:
        path = output_root / f'sea_backing_{width}x{depth}.glb'
        metrics = emit_model(path, module_geometry(width, depth, texture_name, texture_bytes, transform))
        models.append({'modelId': f'unys-papeloa-sea-backing-{width}x{depth}',
                       'name': f'Papeloa · mer de fond · {width} × {depth}', 'sourcePath': str(path),
                       'declaredMediaType': 'model/gltf-binary', 'sha256': metrics['sha256'],
                       'byteLength': metrics['sizeBytes'], 'bounds': metrics['bounds'],
                       'triangleCount': metrics['triangleCount']})
    instances = placements()
    script = Path(__file__).resolve()
    plan = {'formatVersion': 1, 'mapId': 'unys-papeloa', 'mapSize': [56, 82], 'sourceOrigin': SOURCE_ORIGIN,
            'source': {'assetId': SOURCE_ID, 'title': provenance['title'], 'sourceUrl': provenance['sourceUrl'],
                       'archive': provenance['archive'], 'archiveSha256': ARCHIVE_SHA256,
                       'member': provenance['member'], 'memberSha256': DAE_SHA256,
                       'material': 'sea_mizu1_1', 'sourceGeometries': [surface.geometry for surface in sea],
                       'texture': texture_name, 'textureSha256': TEXTURE_SHA256,
                       'sourceOpacity': [surface.opacity for surface in sea], 'sourceUvTransform': transform},
            'backing': {'worldHeight': WORLD_HEIGHT, 'referenceSeabedWorldHeight': -2,
                        'seabedClearance': .0625, 'alphaMode': 'OPAQUE', 'baseColorFactor': [1, 1, 1, 1],
                        'textureBytesChanged': False, 'collision': False,
                        'uvRepeatCells': [4, 4], 'nativeOriginUv': [-6, -7.25]},
            'models': models,
            'import': {'actionId': 'model3d.import_batch',
                       'binding': 'Stage each models.sourcePath with pokemap_artifact_stage, then bind the returned artifactHandle to its modelId and name.'},
            'placementAction': {'actionId': 'map3d.instance.upsert_batch',
                                'parameters': {'mapId': 'unys-papeloa', 'instances': instances}},
            'evidence': {'instanceCount': len(instances), 'uniqueModelTriangles': 8,
                         'placedTriangles': 48, 'coveredCellCount': 56 * 82,
                         'coverageBounds': [0, WORLD_HEIGHT, 0, 56, WORLD_HEIGHT, 82],
                         'sourceUvVertexCount': sum(len(triangle) for surface in sea for triangle in surface.triangles),
                         'uvPhasePreservedAtEveryModuleBoundary': True,
                         'generator': str(script), 'generatorSha256': sha256(script.read_bytes()).hexdigest(),
                         'projectMutationPerformed': False, 'visualReview': 'pending'}}
    (output_root / 'sea_plan.json').write_text(json.dumps(plan, ensure_ascii=False, indent=2) + '\n')
    command = ' '.join(shlex.quote(str(value)) for value in
                       ('python3', script, '--source-root', source_root, '--output-root', output_root))
    (output_root / 'rebuild.sh').write_text('#!/bin/sh\nset -eu\n' + command + '\n')
    return plan


def animated_sea_document(document, binary, context, sources):
    from animate_bw2_cities import animated_material_document

    if document.get('animations') or document.get('extras', {}).get('aveluneMaterialAnimations'):
        raise ValueError('Sea animation staging requires the pinned static modules')
    animated, evidence, unsupported = animated_material_document(
        document, binary, {'sourceMaterial': 'sea_mizu1_1'}, context, sources, ANIMATION_FRAME_RATE)
    if unsupported or animated is None or len(evidence) != 1:
        raise ValueError('Original Papeloa sea material animation is not unambiguous')
    proof = evidence[0]
    if (proof['material'] != 'sea_mizu1_1' or proof['animation'] != 'out58_ita'
            or proof['animationSha256'] != ANIMATION_SHA256 or proof['matrixMode'] != 0
            or proof['matrixModeEvidence'] != 'exact_source_model'):
        raise ValueError('Sea animation must use the pinned Papeloa source and matrix mode')
    clip = animated['extras']['aveluneMaterialAnimations']['clips'][0]
    track = clip['tracks'][0]
    if (len(clip['tracks']) != 1 or track['durationSeconds'] != 4 or len(track['times']) != 241
            or track['interpolation'] != 'STEP'):
        raise ValueError('Sea animation no longer matches the 240-frame native timeline')
    return animated, evidence


def stage_animation(source_root, project, nitro_root, sea_plan_path, output_root):
    from animate_bw2_cities import NitroSources, glb_bytes, read_glb, source_material_context
    from convert_bw2_city_joint_animations import unique_source

    source_root = source_root.resolve(strict=True)
    project = project.resolve(strict=True)
    nitro_root = nitro_root.resolve(strict=True)
    sea_plan_path = sea_plan_path.resolve(strict=True)
    output_root = output_root.resolve()
    for protected in (source_root, nitro_root, sea_plan_path.parent):
        if output_root == protected or protected in output_root.parents or output_root in protected.parents:
            raise ValueError('Animation output must be separate from read-only sources and the consumed sea plan')
    if output_root == project or output_root in project.parents:
        raise ValueError('Animation output cannot replace the project root')
    if project in output_root.parents and project / '.pokemap/authoring' not in output_root.parents:
        raise ValueError('Project staging must remain inside its authoring folder')
    plan_bytes = sea_plan_path.read_bytes()
    plan = json.loads(plan_bytes)
    if (plan['source']['archiveSha256'] != ARCHIVE_SHA256 or plan['source']['memberSha256'] != DAE_SHA256
            or plan['source']['textureSha256'] != TEXTURE_SHA256
            or plan['backing']['nativeOriginUv'] != [-6, -7.25]
            or plan['backing']['worldHeight'] != WORLD_HEIGHT):
        raise ValueError('Static sea plan no longer matches the pinned Papeloa coverage')
    expected_ids = {f'unys-papeloa-sea-backing-{w}x{d}' for w, d in MODULE_SIZES}
    if len(plan['models']) != 4 or {row['modelId'] for row in plan['models']} != expected_ids:
        raise ValueError('Animation staging requires exactly the four original sea modules')
    manifest_path = project / 'project.json'
    manifest_bytes = manifest_path.read_bytes()
    manifest = json.loads(manifest_bytes)
    definitions = {model['id']: model for model in manifest['models3d']}
    map_path = (project / next(row['relativePath'] for row in manifest['maps'] if row['id'] == 'unys-papeloa')).resolve(strict=True)
    if project not in map_path.parents:
        raise ValueError('Papeloa map is outside the project root')
    map_bytes = map_path.read_bytes()
    instances = json.loads(map_bytes)['spatialScene']['instances']
    existing_water = [row for row in instances if row['modelId'].startswith('unys-papeloa-water-')
                      and row.get('animationIndex') is not None]
    if not existing_water or any(row.get('animationIndex') != 0 or row.get('animationSpeed') != ANIMATION_SPEED
                                 or row.get('animationLoop') is not True for row in existing_water):
        raise ValueError('Existing Papeloa water playback differs from the requested shared policy')
    records = json.loads((source_root / 'manifest.json').read_text())['assets']
    record = next(row for row in records if str(row['id']) == SOURCE_ID)
    if record['sha256'] != ARCHIVE_SHA256:
        raise ValueError('Original Papeloa archive fingerprint changed')
    materials, provenance = source_material_context(source_root, record)
    if provenance['memberSha256'] != DAE_SHA256:
        raise ValueError('Original Papeloa COLLADA fingerprint changed')
    context = {'materials': materials}
    sources = NitroSources(nitro_root, {'sea_mizu1_1'})
    native = [row for row in sources.by_material['sea_mizu1_1']
              if row['clip'] == 'out58_ita' and row['source']['sha256'] == ANIMATION_SHA256]
    if len(native) != 1 or native[0]['frames'] != 240:
        raise ValueError('Pinned native Papeloa sea animation is missing or changed')
    sources.by_material['sea_mizu1_1'] = native
    channel_flags = [{key: channel.get(key) for key in ('channel', 'flags', 'encoded_count', 'distinct_values')}
                     for track in native[0]['source']['tracks'] if track['material'] == 'sea_mizu1_1'
                     for channel in track['channels']]
    staged, fingerprints = [], {}
    for row in existing_water:
        path = (project / definitions[row['modelId']]['relativePath']).resolve(strict=True)
        if project not in path.parents:
            raise ValueError('Existing water model is outside the project root')
        current = path.read_bytes()
        document, binary = read_glb(current)
        extras = document.get('extras', {})
        metadata = extras.get('aveluneAnimationSource', {})
        clips = extras.get('aveluneMaterialAnimations', {}).get('clips', [])
        proofs = [proof for proof in metadata.get('materials', []) if 'matrixMode' in proof]
        if (metadata.get('frameRate') != ANIMATION_FRAME_RATE or len(clips) != 1 or not proofs
                or any(proof['animation'] != 'out58_ita' or proof['animationSha256'] != ANIMATION_SHA256
                       or proof['matrixMode'] != 0 for proof in proofs)
                or any(track['durationSeconds'] != 4 or len(track['times']) != 241
                       or track.get('interpolation') != 'STEP' for track in clips[0]['tracks'])):
            raise ValueError('Existing Papeloa water timeline differs from the pinned native sea cycle')
        fingerprints[path] = sha256(current).hexdigest()
    for row in plan['models']:
        model = definitions[row['modelId']]
        path = (project / model['relativePath']).resolve(strict=True)
        if project not in path.parents:
            raise ValueError('Sea model is outside the project root')
        current = path.read_bytes()
        if sha256(current).hexdigest() != row['sha256']:
            raise ValueError('Active sea model differs from the pinned static module')
        document, binary = read_glb(current)
        animated, evidence = animated_sea_document(document, binary, context, sources)
        model_sources = []
        for name in evidence[0]['modelNames']:
            original, fingerprint = unique_source(nitro_root / 'nitro-original', name, '.nsbmd')
            model_sources.append({'name': name, 'path': str(original), 'sha256': fingerprint, 'matrixMode': 0})
        animated['extras']['aveluneAnimationSource'] = {
            'romSha256': sources.inventory['source']['rom_sha256'], 'gameCode': sources.inventory['source']['game_code'],
            'frameRate': ANIMATION_FRAME_RATE,
            'frameRateEvidence': 'Assumed 60 Hz Nitro timeline; original game scheduling not yet measured',
            'originalGameCadenceProven': False, 'originalGlbSha256': row['sha256'], 'materials': evidence,
            'nativeChannelFlags': channel_flags, 'nativeModelSources': model_sources,
            'seaCoverage': {'worldHeight': WORLD_HEIGHT, 'uvRepeatCells': [4, 4], 'nativeOriginUv': [-6, -7.25],
                            'sourceMaterial': 'sea_mizu1_1', 'staticPlanSha256': sha256(plan_bytes).hexdigest(),
                            'sourceTextureSha256': TEXTURE_SHA256, 'geometryAndTextureBytesPreserved': True,
                            'uvPhasePreservedAtEveryModuleBoundary': True,
                            'playbackSpeed': ANIMATION_SPEED, 'effectiveLoopSeconds': 8,
                            'existingWaterTimeline': {'instanceCount': len(existing_water), 'frameRate': ANIMATION_FRAME_RATE,
                                                     'durationSeconds': 4, 'sourceAnimationSha256': ANIMATION_SHA256,
                                                     'animationIndex': 0, 'animationLoop': True, 'animationSpeed': ANIMATION_SPEED},
                            'speedPolicy': 'explicit_artistic_water_playback_half_speed_original_game_cadence_unmeasured'}}
        encoded = glb_bytes(animated, binary)
        staged.append((row, current, path, encoded, evidence))
        fingerprints[path] = sha256(current).hexdigest()
    if manifest_path.read_bytes() != manifest_bytes or map_path.read_bytes() != map_bytes or any(
            sha256(path.read_bytes()).hexdigest() != fingerprint for path, fingerprint in fingerprints.items()):
        raise ValueError('Project changed during sea animation staging')
    output_root.mkdir(parents=True, exist_ok=True)
    if any(path.is_symlink() for path in output_root.rglob('*')):
        raise ValueError('Animation output cannot contain symbolic links')
    entries = []
    for row, current, path, encoded, evidence in staged:
        destination = output_root / 'models' / f"{row['modelId']}.glb"
        destination.parent.mkdir(exist_ok=True)
        destination.write_bytes(encoded)
        entries.append({'modelId': row['modelId'], 'sourcePath': str(destination),
                        'sourceSha256Before': sha256(current).hexdigest(), 'sha256After': sha256(encoded).hexdigest(),
                        'byteLength': len(encoded), 'recommendedAnimationIndex': 0,
                        'recommendedAnimationSpeed': ANIMATION_SPEED, 'recommendedAnimationLoop': True,
                        'clips': ['Ambiance originale NB2'], 'provenance': {'materials': evidence,
                        'sourceAnimationSha256': ANIMATION_SHA256, 'geometryMaterialAppearanceTexturesPreserved': True,
                        'nativeOriginUv': [-6, -7.25], 'uvRepeatCells': [4, 4],
                        'speedPolicy': 'explicit_artistic_water_playback_half_speed_original_game_cadence_unmeasured'}})
    application = {'schemaVersion': 1, 'source': sources.inventory['source'],
                   'mapFingerprints': {'unys-papeloa': sha256(map_bytes).hexdigest()}, 'entries': entries,
                   'coverage': {'models': 4, 'waterModels': 4, 'waterInstances': sum(
                       row['modelId'] in expected_ids for row in instances), 'existingWaterInstances': len(existing_water)},
                   'limits': ['Original game scheduling is unmeasured', 'Visual QA and canonical application are separate steps']}
    (output_root / 'animation_application.json').write_text(json.dumps(application, indent=2) + '\n')
    command = ' '.join(shlex.quote(str(value)) for value in ('python3', Path(__file__).resolve(),
        '--source-root', source_root, '--output-root', output_root, '--animation-project', project,
        '--nitro-root', nitro_root, '--sea-plan', sea_plan_path))
    (output_root / 'rebuild.sh').write_text('#!/bin/sh\nset -eu\n' + command + '\n')
    return application


def stage_surface(source_root, project, nitro_root, output_root):
    from animate_bw2_cities import NitroSources, glb_bytes, read_glb, source_material_context

    source_root = source_root.resolve(strict=True)
    project = project.resolve(strict=True)
    nitro_root = nitro_root.resolve(strict=True)
    output_root = output_root.resolve()
    for protected in (source_root, nitro_root):
        if output_root == protected or protected in output_root.parents or output_root in protected.parents:
            raise ValueError('Surface output must be separate from read-only source roots')
    if output_root == project or output_root in project.parents or (
            project in output_root.parents and project / '.pokemap/authoring' not in output_root.parents):
        raise ValueError('Project surface staging must remain inside its authoring folder')
    manifest_bytes = (project / 'project.json').read_bytes()
    manifest = json.loads(manifest_bytes)
    map_path = (project / next(row['relativePath'] for row in manifest['maps'] if row['id'] == 'unys-papeloa')).resolve(strict=True)
    if project not in map_path.parents:
        raise ValueError('Papeloa map is outside the project root')
    map_bytes = map_path.read_bytes()
    instances = json.loads(map_bytes)['spatialScene']['instances']
    if sum(row['modelId'].startswith('unys-papeloa-sea-backing-') for row in instances) != 24:
        raise ValueError('Surface completion requires the existing 24 sea backing modules')
    definitions = {model['id']: model for model in manifest['models3d']}
    geometry_fingerprints = {}
    for model_id in sorted({row['modelId'] for row in instances if row['modelId'].startswith('unys-papeloa-water-')}):
        path = (project / definitions[model_id]['relativePath']).resolve(strict=True)
        if project not in path.parents:
            raise ValueError('Native water model is outside the project root')
        document, binary = read_glb(path.read_bytes())
        structure = json.dumps({key: document.get(key) for key in ('nodes', 'meshes', 'accessors', 'bufferViews')},
                               sort_keys=True, separators=(',', ':')).encode()
        geometry_fingerprints[model_id] = sha256(structure + binary).hexdigest()
    records = json.loads((source_root / 'manifest.json').read_text())['assets']
    record = next(row for row in records if str(row['id']) == SOURCE_ID)
    if record['sha256'] != ARCHIVE_SHA256:
        raise ValueError('Original Papeloa archive fingerprint changed')
    surfaces, textures, provenance = source_scene(source_root, record)
    sea = [surface for surface in surfaces if surface.material == 'sea_mizu1_1']
    transform = surface_uv_transform(sea)
    opacity = {surface.opacity for surface in sea}
    texture_names = {surface.texture for surface in sea}
    if (provenance['memberSha256'] != DAE_SHA256 or opacity != {.516129017} or len(texture_names) != 1
            or any(abs(vertex[1] + 5.25 - SURFACE_HEIGHT) > 1e-8
                   for surface in sea for triangle in surface.triangles for vertex in triangle)):
        raise ValueError('Original sea surface height, alpha or source fingerprint changed')
    texture_name = texture_names.pop()
    texture_bytes = textures[texture_name]
    if sha256(texture_bytes).hexdigest() != TEXTURE_SHA256:
        raise ValueError('Original sea texture fingerprint changed')
    masks, excluded_materials = sea_surface_footprints(surfaces)
    polygons = subtract_footprints([(0, 0), (56, 0), (56, 82), (0, 82)], masks)
    geometry = sea_surface_geometry(polygons, texture_name, texture_bytes, transform)
    materials, _ = source_material_context(source_root, record)
    sources = NitroSources(nitro_root, {'sea_mizu1_1'})
    pinned = [row for row in sources.by_material['sea_mizu1_1']
              if row['clip'] == 'out58_ita' and row['source']['sha256'] == ANIMATION_SHA256]
    if len(pinned) != 1:
        raise ValueError('Pinned Papeloa sea surface animation is missing')
    sources.by_material['sea_mizu1_1'] = pinned
    if (project / 'project.json').read_bytes() != manifest_bytes or map_path.read_bytes() != map_bytes:
        raise ValueError('Project changed during sea surface staging')
    output_root.mkdir(parents=True, exist_ok=True)
    if any(path.is_symlink() for path in output_root.rglob('*')):
        raise ValueError('Surface output cannot contain symbolic links')
    model_id = 'unys-papeloa-sea-surface-completion'
    path = output_root / 'sea_surface_completion.glb'
    metrics = emit_model(path, geometry)
    document, binary = read_glb(path.read_bytes())
    document['materials'][0]['alphaMode'] = 'BLEND'
    document['materials'][0]['pbrMetallicRoughness']['baseColorFactor'] = [1, 1, 1, next(iter(opacity))]
    animated, evidence = animated_sea_document(document, binary, {'materials': materials}, sources)
    animated['extras']['aveluneAnimationSource'] = {
        'romSha256': sources.inventory['source']['rom_sha256'], 'gameCode': sources.inventory['source']['game_code'],
        'frameRate': ANIMATION_FRAME_RATE,
        'frameRateEvidence': 'Assumed 60 Hz Nitro timeline; original game scheduling not yet measured',
        'originalGameCadenceProven': False, 'materials': evidence,
        'seaSurfaceCompletion': {'worldHeight': SURFACE_HEIGHT, 'nativeAlpha': next(iter(opacity)),
                                'sourceArchiveSha256': ARCHIVE_SHA256, 'sourceDaeSha256': DAE_SHA256,
                                'sourceTextureSha256': TEXTURE_SHA256, 'nativeOriginUv': [-6, -7.25],
                                'excludedMaterials': excluded_materials, 'exclusionTriangleCount': len(masks),
                                'clipEpsilonCellsSquared': FOOTPRINT_EPSILON,
                                'difference': 'map_bounds_minus_native_deep_sea_and_shallow_water_footprints',
                                'playbackSpeed': ANIMATION_SPEED, 'effectiveLoopSeconds': 8}}
    encoded = glb_bytes(animated, binary)
    path.write_bytes(encoded)
    anchor = metrics['sourceAnchorCells']
    instance = {'id': model_id, 'modelId': model_id, 'position': {'x': anchor[0], 'y': SURFACE_HEIGHT, 'z': anchor[2]},
                'rotationDegrees': 0, 'scale': 1, 'blocksMovement': False,
                'animationIndex': 0, 'animationLoop': True, 'animationSpeed': ANIMATION_SPEED}
    model = {'modelId': model_id, 'name': 'Papeloa · surface de mer native complétée', 'sourcePath': str(path),
             'declaredMediaType': 'model/gltf-binary', 'sha256': sha256(encoded).hexdigest(), 'byteLength': len(encoded),
             'bounds': metrics['bounds'], 'triangleCount': metrics['triangleCount']}
    plan = {'formatVersion': 1, 'mapId': 'unys-papeloa', 'mapSize': [56, 82], 'sourceOrigin': SOURCE_ORIGIN,
            'source': {'assetId': SOURCE_ID, 'archiveSha256': ARCHIVE_SHA256, 'memberSha256': DAE_SHA256,
                       'texture': texture_name, 'textureSha256': TEXTURE_SHA256,
                       'material': 'sea_mizu1_1', 'sourceOpacity': next(iter(opacity)),
                       'sourceUvTransform': transform, 'animation': 'out58_ita', 'animationSha256': ANIMATION_SHA256},
            'surface': {'worldHeight': SURFACE_HEIGHT, 'alphaMode': 'BLEND', 'collision': False,
                        'baseColorFactor': [1, 1, 1, next(iter(opacity))], 'nativeOriginUv': [-6, -7.25],
                        'uvRepeatCells': [4, 4], 'animationIndex': 0, 'animationLoop': True, 'animationSpeed': ANIMATION_SPEED},
            'models': [model], 'placementAction': {'actionId': 'map3d.instance.upsert_batch',
                                                  'parameters': {'mapId': 'unys-papeloa', 'instances': [instance]}},
            'import': {'actionId': 'model3d.import_batch'},
            'evidence': {'instanceCount': 1, 'triangleCount': metrics['triangleCount'], 'convexPieceCount': len(polygons),
                         'surfaceAreaCellsSquared': sum(polygon_area(polygon) for polygon in polygons),
                         'exclusionTriangleCount': len(masks), 'excludedMaterials': excluded_materials,
                         'clipEpsilonCellsSquared': FOOTPRINT_EPSILON,
                         'sharedVertexCanonicalizationCells': 1e-8,
                         'nativeDeepSeaAndShallowWaterFootprintsExcluded': True,
                         'existingOpaqueBackingModelsAnd24InstancesPreserved': True,
                         'projectMapSha256Before': sha256(map_bytes).hexdigest(), 'projectMutationPerformed': False,
                         'nativeWaterGeometryFingerprints': geometry_fingerprints,
                         'visualReview': 'pending', 'originalGameCadenceProven': False}}
    (output_root / 'sea_plan.json').write_text(json.dumps(plan, ensure_ascii=False, indent=2) + '\n')
    command = ' '.join(shlex.quote(str(value)) for value in ('python3', Path(__file__).resolve(),
        '--source-root', source_root, '--output-root', output_root, '--surface-project', project, '--nitro-root', nitro_root))
    (output_root / 'rebuild.sh').write_text('#!/bin/sh\nset -eu\n' + command + '\n')
    return plan


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source-root', type=Path, required=True)
    parser.add_argument('--output-root', type=Path, required=True)
    parser.add_argument('--animation-project', type=Path)
    parser.add_argument('--nitro-root', type=Path)
    parser.add_argument('--sea-plan', type=Path)
    parser.add_argument('--surface-project', type=Path)
    arguments = parser.parse_args()
    animation_arguments = (arguments.animation_project, arguments.nitro_root, arguments.sea_plan)
    if arguments.surface_project:
        if arguments.animation_project or arguments.sea_plan or not arguments.nitro_root:
            parser.error('Surface staging requires only --surface-project and --nitro-root')
        plan = stage_surface(arguments.source_root, arguments.surface_project, arguments.nitro_root, arguments.output_root)
        print(json.dumps(plan['evidence'], ensure_ascii=False))
    elif any(animation_arguments):
        if not all(animation_arguments):
            parser.error('Animation staging requires --animation-project, --nitro-root, and --sea-plan')
        application = stage_animation(arguments.source_root, arguments.animation_project, arguments.nitro_root,
                                      arguments.sea_plan, arguments.output_root)
        print(json.dumps(application['coverage'], ensure_ascii=False))
    else:
        plan = build(arguments.source_root, arguments.output_root)
        print(json.dumps({'models': len(plan['models']), **plan['evidence']}, ensure_ascii=False))


if __name__ == '__main__':
    main()

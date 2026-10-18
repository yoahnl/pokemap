import argparse
import re
import math
from hashlib import sha256
from io import BytesIO
import json
from pathlib import Path
import shlex
import sys
from PIL import Image
sys.dont_write_bytecode = True
REPOSITORY = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPOSITORY / 'tools/source_geometry'))
sys.path.insert(0, str(REPOSITORY / 'tools/source_units'))
from city_geometry import source_scene
from source_policy import require_source_policy
from convert_source_asset_pack import emit_model
FOOTPRINT_EPSILON = 1e-08


def require_water_recipe(value):
    fields = {'sourceModelNames', 'sourceModelFiles', 'sourcePolicy', 'id', 'MODULE_SIZES', 'modulePrefix', 'ANIMATION_SHA256', 'surfaceOpacity', 'material', 'uvRepeatCells', 'sourceToNativeY', 'moduleCellSize', 'uvTransform', 'SURFACE_HEIGHT', 'SOURCE_ID', 'DAE_SHA256', 'ARCHIVE_SHA256', 'mapId', 'excludedMaterialPrefixes', 'WORLD_HEIGHT', 'schemaVersion', 'ANIMATION_SPEED', 'TEXTURE_SHA256', 'surfaceModelId', 'clip', 'label', 'waterPrefix', 'textureSize', 'referenceSeabedWorldHeight', 'width', 'nativeOriginUv', 'animationFrameCount', 'durationSeconds', 'ANIMATION_FRAME_RATE', 'SOURCE_ORIGIN', 'excludedMaterials', 'depth'}
    if not isinstance(value, dict) or set(value) != fields or type(value['schemaVersion']) is not int or value['schemaVersion'] != 1:
        raise ValueError('Invalid periodic water recipe')
    require_source_policy(value['sourcePolicy'])
    names, files = value['sourceModelNames'], value['sourceModelFiles']
    if not isinstance(names, list) or not names or len(names) > 256 or len(set(names)) != len(names) or any(not isinstance(name, str) or not name for name in names):
        raise ValueError('Water requires explicit unique source model names')
    if not isinstance(files, list) or len(files) > 256 or any(not isinstance(row, dict) or set(row) != {'relativePath', 'sha256'} for row in files):
        raise ValueError('Water requires explicit source model witnesses')
    for row in files:
        path = row['relativePath']
        if not isinstance(path, str) or Path(path).is_absolute() or '\\' in path or any(part in ('', '.', '..') for part in path.split('/')) or not isinstance(row['sha256'], str) or re.fullmatch('[0-9a-f]{64}', row['sha256']) is None:
            raise ValueError('Invalid water source model witness')
    for key in ('id', 'mapId', 'modulePrefix', 'waterPrefix', 'surfaceModelId', 'label', 'material', 'clip', 'SOURCE_ID'):
        if not isinstance(value[key], str) or not value[key] or value[key] != value[key].strip():
            raise ValueError('Water recipe requires non-empty identifiers')
    for key in ('ARCHIVE_SHA256', 'DAE_SHA256', 'TEXTURE_SHA256', 'ANIMATION_SHA256'):
        if not isinstance(value[key], str) or re.fullmatch(r'[0-9a-f]{64}', value[key]) is None:
            raise ValueError('Water recipe requires pinned SHA-256 digests')
    for key in ('width', 'depth', 'moduleCellSize', 'animationFrameCount'):
        if type(value[key]) is not int or not 1 <= value[key] <= 4096:
            raise ValueError('Water recipe dimensions or frame count are invalid')
    for key in ('WORLD_HEIGHT', 'SURFACE_HEIGHT', 'ANIMATION_FRAME_RATE', 'ANIMATION_SPEED', 'sourceToNativeY', 'surfaceOpacity', 'durationSeconds', 'referenceSeabedWorldHeight'):
        if type(value[key]) not in (int, float) or not math.isfinite(value[key]):
            raise ValueError('Water recipe numerical policy is invalid')
    if value['ANIMATION_SPEED'] <= 0 or value['ANIMATION_FRAME_RATE'] <= 0 or value['durationSeconds'] <= 0 or not 0 <= value['surfaceOpacity'] <= 1:
        raise ValueError('Water recipe playback or opacity is invalid')
    if value['animationFrameCount'] != value['durationSeconds'] * value['ANIMATION_FRAME_RATE']:
        raise ValueError('Water recipe timeline does not match the declared cadence')
    for key, size in [('SOURCE_ORIGIN', 3), ('nativeOriginUv', 2), ('uvRepeatCells', 2), ('textureSize', 2)]:
        if not isinstance(value[key], list) or len(value[key]) != size or any(type(item) not in (int, float) or not math.isfinite(item) for item in value[key]):
            raise ValueError('Water recipe vector is invalid')
    if any(type(item) is not int or item <= 0 for item in value['textureSize']):
        raise ValueError('Water recipe texture size is invalid')
    sizes = value['MODULE_SIZES']
    if not isinstance(sizes, list) or not sizes or any(not isinstance(size, list) or len(size) != 2 or any(type(n) is not int or n <= 0 for n in size) for size in sizes):
        raise ValueError('Water recipe module sizes are invalid')
    if len({tuple(size) for size in sizes}) != len(sizes):
        raise ValueError('Water recipe module sizes must be unique')
    needed = {(min(value['moduleCellSize'], value['width'] - x), min(value['moduleCellSize'], value['depth'] - z)) for z in range(0, value['depth'], value['moduleCellSize']) for x in range(0, value['width'], value['moduleCellSize'])}
    if needed != {tuple(size) for size in sizes}:
        raise ValueError('Water recipe modules do not exactly cover the map dimensions')
    if not isinstance(value['uvTransform'], list) or len(value['uvTransform']) != 2 or any(not isinstance(row, list) or len(row) != 3 or any(type(n) not in (int, float) or not math.isfinite(n) for n in row) for row in value['uvTransform']):
        raise ValueError('Water recipe UV transform is invalid')
    for key in ('excludedMaterialPrefixes', 'excludedMaterials'):
        if not isinstance(value[key], list) or any(not isinstance(item, str) or not item for item in value[key]):
            raise ValueError('Water recipe exclusion selectors are invalid')
    for key in ('mapId', 'modulePrefix', 'waterPrefix', 'surfaceModelId'):
        if re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_.-]{0,127}', value[key]) is None:
            raise ValueError('Water recipe identifier is unsafe')
    if any(item <= 0 for item in value['uvRepeatCells']):
        raise ValueError('Water recipe UV periods must be positive')
    expected_uv = [row[0] * value['SOURCE_ORIGIN'][0] + row[1] * value['SOURCE_ORIGIN'][2] + row[2] for row in value['uvTransform']]
    if any(abs(a - b) > 1e-8 for a, b in zip(expected_uv, value['nativeOriginUv'])):
        raise ValueError('Water recipe native UV origin differs from its transform')
    return json.loads(json.dumps(value, allow_nan=False))

def polygon_area(polygon):
    return sum((a[0] * b[1] - b[0] * a[1] for a, b in zip(polygon, polygon[1:] + polygon[:1]))) / 2

def clean_footprint(polygon):
    result = []
    for point in polygon:
        if not result or max((abs(a - b) for a, b in zip(point, result[-1]))) > FOOTPRINT_EPSILON:
            result.append(point)
    if len(result) > 1 and max((abs(a - b) for a, b in zip(result[0], result[-1]))) <= FOOTPRINT_EPSILON:
        result.pop()
    if len(result) < 3 or abs(polygon_area(result)) <= FOOTPRINT_EPSILON:
        return []
    return result if polygon_area(result) > 0 else result[::-1]

def split_footprint(polygon, a, b):

    def side(point):
        return (b[0] - a[0]) * (point[1] - a[1]) - (b[1] - a[1]) * (point[0] - a[0])
    inside, outside = ([], [])
    previous = polygon[-1]
    previous_side = side(previous)
    for current in polygon:
        current_side = side(current)
        if previous_side < 0 < current_side or current_side < 0 < previous_side:
            t = previous_side / (previous_side - current_side)
            intersection = tuple((x + t * (y - x) for x, y in zip(previous, current)))
            inside.append(intersection)
            outside.append(intersection)
        if current_side >= 0:
            inside.append(current)
        if current_side <= 0:
            outside.append(current)
        previous, previous_side = (current, current_side)
    return (clean_footprint(inside), clean_footprint(outside))

def subtract_footprints(polygon, exclusions):
    initial = clean_footprint(polygon)
    pieces = [initial] if initial else []
    for exclusion in exclusions:
        triangle = clean_footprint(exclusion)
        if not triangle:
            continue
        lower = [min((point[axis] for point in triangle)) for axis in (0, 1)]
        upper = [max((point[axis] for point in triangle)) for axis in (0, 1)]
        result = []
        for piece in pieces:
            if any((max((point[axis] for point in piece)) <= lower[axis] or min((point[axis] for point in piece)) >= upper[axis] for axis in (0, 1))):
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

def sea_surface_footprints(surfaces, *, recipe):
    selected = [surface for surface in surfaces if surface.material == recipe['material'] or surface.material.startswith(tuple(recipe['excludedMaterialPrefixes'])) or surface.material in recipe['excludedMaterials']]
    masks = [clean_footprint([(v[0] - recipe['SOURCE_ORIGIN'][0], v[2] - recipe['SOURCE_ORIGIN'][2]) for v in triangle]) for surface in selected for triangle in surface.triangles]
    return ([mask for mask in masks if mask], sorted({surface.material for surface in selected}))

def sea_surface_geometry(polygons, texture_name, texture_bytes, transform, *, recipe):
    vertices = []
    for polygon in polygons:
        for index in range(1, len(polygon) - 1):
            triangle = (polygon[0], polygon[index + 1], polygon[index])
            if abs(polygon_area(list(triangle))) <= FOOTPRINT_EPSILON:
                continue
            for x, z in triangle:
                x, z = (round(x, 8), round(z, 8))
                source_x, source_z = (x + recipe['SOURCE_ORIGIN'][0], z + recipe['SOURCE_ORIGIN'][2])
                uv = [row[0] * source_x + row[1] * source_z + row[2] for row in transform]
                vertices.append([x, 0, z, *uv, 1, 1, 1])
    if not vertices:
        raise ValueError('Sea surface clipping produced no drawable geometry')
    return {'surfaces': {texture_name: vertices}, 'textures': {texture_name: texture_bytes}, 'samplers': {texture_name: ['WRAP', 'WRAP']}, 'doubleSided': {texture_name: False}}

def surface_uv_transform(surfaces, *, recipe):
    if not surfaces or any((surface.wraps != ['WRAP', 'WRAP'] for surface in surfaces)):
        raise ValueError('Source sea requires original WRAP samplers')
    a, b, c = surfaces[0].triangles[0]
    dx1, dz1 = (b[0] - a[0], b[2] - a[2])
    dx2, dz2 = (c[0] - a[0], c[2] - a[2])
    determinant = dx1 * dz2 - dx2 * dz1
    if abs(determinant) < 1e-08:
        raise ValueError('Source sea has no horizontal UV reference')
    transform = []
    for channel in (3, 4):
        du1, du2 = (b[channel] - a[channel], c[channel] - a[channel])
        gradient_x = (du1 * dz2 - du2 * dz1) / determinant
        gradient_z = (dx1 * du2 - dx2 * du1) / determinant
        transform.append([gradient_x, gradient_z, a[channel] - gradient_x * a[0] - gradient_z * a[2]])
    for surface in surfaces:
        for triangle in surface.triangles:
            for vertex in triangle:
                if abs(vertex[1] - a[1]) > 1e-08:
                    raise ValueError('Source sea reference is not horizontal')
                for channel, coefficients in enumerate(transform):
                    delta = coefficients[0] * vertex[0] + coefficients[1] * vertex[2] + coefficients[2] - vertex[channel + 3]
                    if abs(delta - round(delta)) > 1e-08:
                        raise ValueError('Source sea UV phase changes across sectors')
    if transform != recipe['uvTransform']:
        raise ValueError('Source sea no longer uses its verified four-cell UV repeat')
    return transform

def module_geometry(width, depth, texture_name, texture_bytes, transform, *, recipe):
    if (width, depth) not in {tuple(size) for size in recipe['MODULE_SIZES']}:
        raise ValueError('Unsupported source sea module dimensions')
    vertices = []
    for x, z in ((0, 0), (0, depth), (width, depth), (width, 0)):
        source_x, source_z = (x + recipe['SOURCE_ORIGIN'][0], z + recipe['SOURCE_ORIGIN'][2])
        uv = [row[0] * source_x + row[1] * source_z + row[2] for row in transform]
        vertices.append([x, 0, z, *uv, 1, 1, 1])
    return {'surfaces': {texture_name: [vertices[i] for i in (0, 1, 2, 0, 2, 3)]}, 'textures': {texture_name: texture_bytes}, 'samplers': {texture_name: ['WRAP', 'WRAP']}, 'doubleSided': {texture_name: False}}

def placements(*, recipe):
    recipe = require_water_recipe(recipe)
    instances = []
    for row, z in enumerate(range(0, recipe['depth'], recipe['moduleCellSize'])):
        for column, x in enumerate(range(0, recipe['width'], recipe['moduleCellSize'])):
            width, depth = (min(recipe['moduleCellSize'], recipe['width'] - x), min(recipe['moduleCellSize'], recipe['depth'] - z))
            instances.append({'id': f"{recipe['modulePrefix']}c{column}-r{row}", 'modelId': f"{recipe['modulePrefix']}{width}x{depth}", 'position': {'x': x + width / 2, 'y': recipe['WORLD_HEIGHT'], 'z': z + depth / 2}, 'rotationDegrees': 0, 'scale': 1, 'blocksMovement': False})
    return instances

def build(source_root, output_root, *, recipe):
    recipe = require_water_recipe(recipe)
    source_root = source_root.resolve(strict=True)
    output_root = output_root.resolve()
    if output_root == source_root or source_root in output_root.parents or output_root in source_root.parents:
        raise ValueError('Output must be separate from the original source root')
    records = json.loads((source_root / 'manifest.json').read_text())['assets']
    record = next((record for record in records if str(record['id']) == recipe['SOURCE_ID']))
    if record['sha256'] != recipe['ARCHIVE_SHA256']:
        raise ValueError('Original source archive fingerprint changed')
    surfaces, textures, provenance = source_scene(source_root, record, policy=recipe['sourcePolicy'])
    sea = [surface for surface in surfaces if surface.material == recipe['material']]
    transform = surface_uv_transform(sea, recipe=recipe)
    if provenance['memberSha256'] != recipe['DAE_SHA256']:
        raise ValueError('Original source COLLADA fingerprint changed')
    texture_names = {surface.texture for surface in sea}
    if len(texture_names) != 1:
        raise ValueError('Original sea planes require one shared texture')
    texture_name = texture_names.pop()
    texture_bytes = textures[texture_name]
    if sha256(texture_bytes).hexdigest() != recipe['TEXTURE_SHA256']:
        raise ValueError('Original source sea texture fingerprint changed')
    with Image.open(BytesIO(texture_bytes)) as image:
        if image.size != tuple(recipe['textureSize']) or image.convert('RGBA').getextrema()[3] != (255, 255):
            raise ValueError('Original sea texture must be opaque with the declared pixel dimensions')
    output_root.mkdir(parents=True, exist_ok=True)
    if any((path.is_symlink() for path in output_root.iterdir())):
        raise ValueError('Output folder cannot contain symbolic links')
    (output_root / texture_name).write_bytes(texture_bytes)
    models = []
    for width, depth in recipe['MODULE_SIZES']:
        path = output_root / f'sea_backing_{width}x{depth}.glb'
        metrics = emit_model(path, module_geometry(width, depth, texture_name, texture_bytes, transform, recipe=recipe))
        models.append({'modelId': f"{recipe['modulePrefix']}{width}x{depth}", 'name': f"{recipe['label']} · {width} × {depth}", 'sourcePath': str(path), 'declaredMediaType': 'model/gltf-binary', 'sha256': metrics['sha256'], 'byteLength': metrics['sizeBytes'], 'bounds': metrics['bounds'], 'triangleCount': metrics['triangleCount']})
    instances = placements(recipe=recipe)
    script = Path(__file__).resolve()
    plan = {'formatVersion': 2, 'recipe': recipe, 'mapId': recipe['mapId'], 'mapSize': [recipe['width'], recipe['depth']], 'sourceOrigin': recipe['SOURCE_ORIGIN'], 'source': {'assetId': recipe['SOURCE_ID'], 'title': provenance['title'], 'sourceUrl': provenance['sourceUrl'], 'archive': provenance['archive'], 'archiveSha256': recipe['ARCHIVE_SHA256'], 'member': provenance['member'], 'memberSha256': recipe['DAE_SHA256'], 'material': recipe['material'], 'sourceGeometries': [surface.geometry for surface in sea], 'texture': texture_name, 'textureSha256': recipe['TEXTURE_SHA256'], 'sourceOpacity': [surface.opacity for surface in sea], 'sourceUvTransform': transform}, 'backing': {'worldHeight': recipe['WORLD_HEIGHT'], 'referenceSeabedWorldHeight': recipe['referenceSeabedWorldHeight'], 'seabedClearance': recipe['referenceSeabedWorldHeight'] - recipe['WORLD_HEIGHT'], 'alphaMode': 'OPAQUE', 'baseColorFactor': [1, 1, 1, 1], 'textureBytesChanged': False, 'collision': False, 'uvRepeatCells': recipe['uvRepeatCells'], 'nativeOriginUv': recipe['nativeOriginUv']}, 'models': models, 'import': {'actionId': 'model3d.import_batch', 'binding': 'Stage each models.sourcePath with pokemap_artifact_stage, then bind the returned artifactHandle to its modelId and name.'}, 'placementAction': {'actionId': 'map3d.instance.upsert_batch', 'parameters': {'mapId': recipe['mapId'], 'instances': instances}}, 'evidence': {'instanceCount': len(instances), 'uniqueModelTriangles': len(recipe['MODULE_SIZES']) * 2, 'placedTriangles': len(instances) * 2, 'coveredCellCount': recipe['width'] * recipe['depth'], 'coverageBounds': [0, recipe['WORLD_HEIGHT'], 0, recipe['width'], recipe['WORLD_HEIGHT'], recipe['depth']], 'sourceUvVertexCount': sum((len(triangle) for surface in sea for triangle in surface.triangles)), 'uvPhasePreservedAtEveryModuleBoundary': True, 'generator': str(script), 'generatorSha256': sha256(script.read_bytes()).hexdigest(), 'projectMutationPerformed': False, 'visualReview': 'pending'}}
    (output_root / 'sea_plan.json').write_text(json.dumps(plan, ensure_ascii=False, indent=2) + '\n')
    recipe_path = output_root / 'water_recipe.json'
    recipe_path.write_text(json.dumps(recipe, indent=2) + '\n')
    command = ' '.join((shlex.quote(str(value)) for value in ('python3', script, '--recipe', recipe_path, '--source-root', source_root, '--output-root', output_root)))
    (output_root / 'rebuild.sh').write_text('#!/bin/sh\nset -eu\n' + command + '\n')
    return plan

def animated_sea_document(document, binary, context, sources, *, recipe):
    from material_animation import animated_material_document
    if document.get('animations') or document.get('extras', {}).get('aveluneMaterialAnimations'):
        raise ValueError('Sea animation staging requires the pinned static modules')
    animated, evidence, unsupported = animated_material_document(document, binary, {'sourceMaterial': recipe['material']}, context, sources, recipe['ANIMATION_FRAME_RATE'], bindings={recipe['material']: {
        'sourceClip': recipe['clip'], 'sourceModelNames': recipe['sourceModelNames'],
        'matrixModeEvidence': 'exact_source_model'}}, clip_name=recipe['label'])
    if unsupported or animated is None or len(evidence) != 1:
        raise ValueError('Original source sea material animation is not unambiguous')
    proof = evidence[0]
    if proof['material'] != recipe['material'] or proof['animation'] != recipe['clip'] or proof['animationSha256'] != recipe['ANIMATION_SHA256'] or (proof['matrixMode'] != 0) or (proof['matrixModeEvidence'] != 'exact_source_model'):
        raise ValueError('Sea animation must use the pinned source and matrix mode')
    clip = animated['extras']['aveluneMaterialAnimations']['clips'][0]
    track = clip['tracks'][0]
    if len(clip['tracks']) != 1 or track['durationSeconds'] != recipe['durationSeconds'] or len(track['times']) != recipe['animationFrameCount'] + 1 or (track['interpolation'] != 'STEP'):
        raise ValueError('Sea animation no longer matches the declared source timeline')
    clip['name'] = recipe['label']
    return (animated, evidence)

def stage_animation(source_root, project, nitro_root, sea_plan_path, output_root, *, recipe):
    recipe = require_water_recipe(recipe)
    from material_animation import NitroSources, glb_bytes, read_glb, source_material_context, source_bytes
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
    if plan.get('formatVersion') != 2 or plan.get('recipe') != recipe:
        raise ValueError('Static water plan differs from the selected recipe')
    if plan['source']['archiveSha256'] != recipe['ARCHIVE_SHA256'] or plan['source']['memberSha256'] != recipe['DAE_SHA256'] or plan['source']['textureSha256'] != recipe['TEXTURE_SHA256'] or (plan['backing']['nativeOriginUv'] != recipe['nativeOriginUv']) or (plan['backing']['worldHeight'] != recipe['WORLD_HEIGHT']):
        raise ValueError('Static sea plan no longer matches the pinned source coverage')
    expected_ids = {f"{recipe['modulePrefix']}{w}x{d}" for w, d in recipe['MODULE_SIZES']}
    if len(plan['models']) != len(recipe['MODULE_SIZES']) or {row['modelId'] for row in plan['models']} != expected_ids:
        raise ValueError('Animation staging requires exactly the declared source modules')
    manifest_path = project / 'project.json'
    manifest_bytes = manifest_path.read_bytes()
    manifest = json.loads(manifest_bytes)
    definitions = {model['id']: model for model in manifest['models3d']}
    map_path = (project / next((row['relativePath'] for row in manifest['maps'] if row['id'] == recipe['mapId']))).resolve(strict=True)
    if project not in map_path.parents:
        raise ValueError('source map is outside the project root')
    map_bytes = map_path.read_bytes()
    instances = json.loads(map_bytes)['spatialScene']['instances']
    existing_water = [row for row in instances if row['modelId'].startswith(recipe['waterPrefix']) and row.get('animationIndex') is not None]
    if not existing_water or any((row.get('animationIndex') != 0 or row.get('animationSpeed') != recipe['ANIMATION_SPEED'] or row.get('animationLoop') is not True for row in existing_water)):
        raise ValueError('Existing source water playback differs from the requested shared policy')
    records = json.loads((source_root / 'manifest.json').read_text())['assets']
    record = next((row for row in records if str(row['id']) == recipe['SOURCE_ID']))
    if record['sha256'] != recipe['ARCHIVE_SHA256']:
        raise ValueError('Original source archive fingerprint changed')
    materials, provenance = source_material_context(source_root, record, policy=recipe['sourcePolicy'])
    if provenance['memberSha256'] != recipe['DAE_SHA256']:
        raise ValueError('Original source COLLADA fingerprint changed')
    context = {'materials': materials}
    sources = NitroSources(nitro_root, {recipe['material']}, model_sources=recipe['sourceModelFiles'])
    native = [row for row in sources.by_material[recipe['material']] if row['clip'] == recipe['clip'] and row['source']['sha256'] == recipe['ANIMATION_SHA256']]
    if len(native) != 1 or native[0]['frames'] != recipe['animationFrameCount']:
        raise ValueError('Pinned native source sea animation is missing or changed')
    sources.by_material[recipe['material']] = native
    channel_flags = [{key: channel.get(key) for key in ('channel', 'flags', 'encoded_count', 'distinct_values')} for track in native[0]['source']['tracks'] if track['material'] == recipe['material'] for channel in track['channels']]
    staged, fingerprints = ([], {})
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
        if metadata.get('frameRate') != recipe['ANIMATION_FRAME_RATE'] or len(clips) != 1 or (not proofs) or any((proof['animation'] != recipe['clip'] or proof['animationSha256'] != recipe['ANIMATION_SHA256'] or proof['matrixMode'] != 0 for proof in proofs)) or any((track['durationSeconds'] != recipe['durationSeconds'] or len(track['times']) != recipe['animationFrameCount'] + 1 or track.get('interpolation') != 'STEP' for track in clips[0]['tracks'])):
            raise ValueError('Existing source water timeline differs from the pinned native sea cycle')
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
        animated, evidence = animated_sea_document(document, binary, context, sources, recipe=recipe)
        model_sources = []
        for witness in recipe['sourceModelFiles']:
            source_bytes(nitro_root, witness['relativePath'], witness['sha256'])
            model_sources.append({**witness, 'modelNames': evidence[0]['modelNames'], 'matrixMode': 0})
        animated['extras']['aveluneAnimationSource'] = {'romSha256': sources.inventory['source']['rom_sha256'], 'gameCode': sources.inventory['source']['game_code'], 'frameRate': recipe['ANIMATION_FRAME_RATE'], 'frameRateEvidence': f"Declared {recipe['ANIMATION_FRAME_RATE']} Hz source timeline; original game scheduling unmeasured", 'originalGameCadenceProven': False, 'originalGlbSha256': row['sha256'], 'materials': evidence, 'nativeChannelFlags': channel_flags, 'nativeModelSources': model_sources, 'seaCoverage': {'worldHeight': recipe['WORLD_HEIGHT'], 'uvRepeatCells': recipe['uvRepeatCells'], 'nativeOriginUv': recipe['nativeOriginUv'], 'sourceMaterial': recipe['material'], 'staticPlanSha256': sha256(plan_bytes).hexdigest(), 'sourceTextureSha256': recipe['TEXTURE_SHA256'], 'geometryAndTextureBytesPreserved': True, 'uvPhasePreservedAtEveryModuleBoundary': True, 'playbackSpeed': recipe['ANIMATION_SPEED'], 'effectiveLoopSeconds': recipe['durationSeconds'] / recipe['ANIMATION_SPEED'], 'existingWaterTimeline': {'instanceCount': len(existing_water), 'frameRate': recipe['ANIMATION_FRAME_RATE'], 'durationSeconds': recipe['durationSeconds'], 'sourceAnimationSha256': recipe['ANIMATION_SHA256'], 'animationIndex': 0, 'animationLoop': True, 'animationSpeed': recipe['ANIMATION_SPEED']}, 'speedPolicy': 'explicit_playback_multiplier_original_game_cadence_unmeasured'}}
        encoded = glb_bytes(animated, binary)
        staged.append((row, current, path, encoded, evidence))
        fingerprints[path] = sha256(current).hexdigest()
    if manifest_path.read_bytes() != manifest_bytes or map_path.read_bytes() != map_bytes or any((sha256(path.read_bytes()).hexdigest() != fingerprint for path, fingerprint in fingerprints.items())):
        raise ValueError('Project changed during sea animation staging')
    output_root.mkdir(parents=True, exist_ok=True)
    if any((path.is_symlink() for path in output_root.rglob('*'))):
        raise ValueError('Animation output cannot contain symbolic links')
    entries = []
    for row, current, path, encoded, evidence in staged:
        destination = output_root / 'models' / f"{row['modelId']}.glb"
        destination.parent.mkdir(exist_ok=True)
        destination.write_bytes(encoded)
        entries.append({'modelId': row['modelId'], 'sourcePath': str(destination), 'sourceSha256Before': sha256(current).hexdigest(), 'sha256After': sha256(encoded).hexdigest(), 'byteLength': len(encoded), 'recommendedAnimationIndex': 0, 'recommendedAnimationSpeed': recipe['ANIMATION_SPEED'], 'recommendedAnimationLoop': True, 'clips': [recipe['label']], 'provenance': {'materials': evidence, 'sourceAnimationSha256': recipe['ANIMATION_SHA256'], 'geometryMaterialAppearanceTexturesPreserved': True, 'nativeOriginUv': recipe['nativeOriginUv'], 'uvRepeatCells': recipe['uvRepeatCells'], 'speedPolicy': 'explicit_playback_multiplier_original_game_cadence_unmeasured'}})
    application = {'schemaVersion': 1, 'source': sources.inventory['source'], 'mapFingerprints': {recipe['mapId']: sha256(map_bytes).hexdigest()}, 'entries': entries, 'coverage': {'models': len(recipe['MODULE_SIZES']), 'waterModels': len(recipe['MODULE_SIZES']), 'waterInstances': sum((row['modelId'] in expected_ids for row in instances)), 'existingWaterInstances': len(existing_water)}, 'limits': ['Original game scheduling is unmeasured', 'Visual QA and canonical application are separate steps']}
    (output_root / 'animation_application.json').write_text(json.dumps(application, indent=2) + '\n')
    recipe_path = output_root / 'water_recipe.json'
    recipe_path.write_text(json.dumps(recipe, indent=2) + '\n')
    command = ' '.join((shlex.quote(str(value)) for value in ('python3', Path(__file__).resolve(), '--source-root', source_root, '--output-root', output_root, '--animation-project', project, '--recipe', recipe_path, '--nitro-root', nitro_root, '--sea-plan', sea_plan_path)))
    (output_root / 'rebuild.sh').write_text('#!/bin/sh\nset -eu\n' + command + '\n')
    return application

def stage_surface(source_root, project, nitro_root, output_root, *, recipe):
    recipe = require_water_recipe(recipe)
    from material_animation import NitroSources, glb_bytes, read_glb, source_material_context
    source_root = source_root.resolve(strict=True)
    project = project.resolve(strict=True)
    nitro_root = nitro_root.resolve(strict=True)
    output_root = output_root.resolve()
    for protected in (source_root, nitro_root):
        if output_root == protected or protected in output_root.parents or output_root in protected.parents:
            raise ValueError('Surface output must be separate from read-only source roots')
    if output_root == project or output_root in project.parents or (project in output_root.parents and project / '.pokemap/authoring' not in output_root.parents):
        raise ValueError('Project surface staging must remain inside its authoring folder')
    manifest_bytes = (project / 'project.json').read_bytes()
    manifest = json.loads(manifest_bytes)
    map_path = (project / next((row['relativePath'] for row in manifest['maps'] if row['id'] == recipe['mapId']))).resolve(strict=True)
    if project not in map_path.parents:
        raise ValueError('source map is outside the project root')
    map_bytes = map_path.read_bytes()
    instances = json.loads(map_bytes)['spatialScene']['instances']
    if sum((row['modelId'].startswith(recipe['modulePrefix']) for row in instances)) != len(placements(recipe=recipe)):
        raise ValueError('Surface completion requires the declared sea backing modules')
    definitions = {model['id']: model for model in manifest['models3d']}
    geometry_fingerprints = {}
    for model_id in sorted({row['modelId'] for row in instances if row['modelId'].startswith(recipe['waterPrefix'])}):
        path = (project / definitions[model_id]['relativePath']).resolve(strict=True)
        if project not in path.parents:
            raise ValueError('Native water model is outside the project root')
        document, binary = read_glb(path.read_bytes())
        structure = json.dumps({key: document.get(key) for key in ('nodes', 'meshes', 'accessors', 'bufferViews')}, sort_keys=True, separators=(',', ':')).encode()
        geometry_fingerprints[model_id] = sha256(structure + binary).hexdigest()
    records = json.loads((source_root / 'manifest.json').read_text())['assets']
    record = next((row for row in records if str(row['id']) == recipe['SOURCE_ID']))
    if record['sha256'] != recipe['ARCHIVE_SHA256']:
        raise ValueError('Original source archive fingerprint changed')
    surfaces, textures, provenance = source_scene(source_root, record, policy=recipe['sourcePolicy'])
    sea = [surface for surface in surfaces if surface.material == recipe['material']]
    transform = surface_uv_transform(sea, recipe=recipe)
    opacity = {surface.opacity for surface in sea}
    texture_names = {surface.texture for surface in sea}
    if provenance['memberSha256'] != recipe['DAE_SHA256'] or opacity != {recipe['surfaceOpacity']} or len(texture_names) != 1 or any((abs(vertex[1] + recipe['sourceToNativeY'] - recipe['SURFACE_HEIGHT']) > 1e-08 for surface in sea for triangle in surface.triangles for vertex in triangle)):
        raise ValueError('Original sea surface height, alpha or source fingerprint changed')
    texture_name = texture_names.pop()
    texture_bytes = textures[texture_name]
    if sha256(texture_bytes).hexdigest() != recipe['TEXTURE_SHA256']:
        raise ValueError('Original sea texture fingerprint changed')
    masks, excluded_materials = sea_surface_footprints(surfaces, recipe=recipe)
    polygons = subtract_footprints([(0, 0), (recipe['width'], 0), (recipe['width'], recipe['depth']), (0, recipe['depth'])], masks)
    geometry = sea_surface_geometry(polygons, texture_name, texture_bytes, transform, recipe=recipe)
    materials, _ = source_material_context(source_root, record, policy=recipe['sourcePolicy'])
    sources = NitroSources(nitro_root, {recipe['material']}, model_sources=recipe['sourceModelFiles'])
    pinned = [row for row in sources.by_material[recipe['material']] if row['clip'] == recipe['clip'] and row['source']['sha256'] == recipe['ANIMATION_SHA256']]
    if len(pinned) != 1:
        raise ValueError('Pinned source sea surface animation is missing')
    sources.by_material[recipe['material']] = pinned
    if (project / 'project.json').read_bytes() != manifest_bytes or map_path.read_bytes() != map_bytes:
        raise ValueError('Project changed during sea surface staging')
    output_root.mkdir(parents=True, exist_ok=True)
    if any((path.is_symlink() for path in output_root.rglob('*'))):
        raise ValueError('Surface output cannot contain symbolic links')
    model_id = recipe['surfaceModelId']
    path = output_root / 'sea_surface_completion.glb'
    metrics = emit_model(path, geometry)
    document, binary = read_glb(path.read_bytes())
    document['materials'][0]['alphaMode'] = 'BLEND'
    document['materials'][0]['pbrMetallicRoughness']['baseColorFactor'] = [1, 1, 1, next(iter(opacity))]
    animated, evidence = animated_sea_document(document, binary, {'materials': materials}, sources, recipe=recipe)
    animated['extras']['aveluneAnimationSource'] = {'romSha256': sources.inventory['source']['rom_sha256'], 'gameCode': sources.inventory['source']['game_code'], 'frameRate': recipe['ANIMATION_FRAME_RATE'], 'frameRateEvidence': f"Declared {recipe['ANIMATION_FRAME_RATE']} Hz source timeline; original game scheduling unmeasured", 'originalGameCadenceProven': False, 'materials': evidence, 'seaSurfaceCompletion': {'worldHeight': recipe['SURFACE_HEIGHT'], 'nativeAlpha': next(iter(opacity)), 'sourceArchiveSha256': recipe['ARCHIVE_SHA256'], 'sourceDaeSha256': recipe['DAE_SHA256'], 'sourceTextureSha256': recipe['TEXTURE_SHA256'], 'nativeOriginUv': recipe['nativeOriginUv'], 'excludedMaterials': excluded_materials, 'exclusionTriangleCount': len(masks), 'clipEpsilonCellsSquared': FOOTPRINT_EPSILON, 'difference': 'map_bounds_minus_native_deep_sea_and_shallow_water_footprints', 'playbackSpeed': recipe['ANIMATION_SPEED'], 'effectiveLoopSeconds': recipe['durationSeconds'] / recipe['ANIMATION_SPEED']}}
    encoded = glb_bytes(animated, binary)
    path.write_bytes(encoded)
    anchor = metrics['sourceAnchorCells']
    instance = {'id': model_id, 'modelId': model_id, 'position': {'x': anchor[0], 'y': recipe['SURFACE_HEIGHT'], 'z': anchor[2]}, 'rotationDegrees': 0, 'scale': 1, 'blocksMovement': False, 'animationIndex': 0, 'animationLoop': True, 'animationSpeed': recipe['ANIMATION_SPEED']}
    model = {'modelId': model_id, 'name': recipe['label'], 'sourcePath': str(path), 'declaredMediaType': 'model/gltf-binary', 'sha256': sha256(encoded).hexdigest(), 'byteLength': len(encoded), 'bounds': metrics['bounds'], 'triangleCount': metrics['triangleCount']}
    plan = {'formatVersion': 2, 'recipe': recipe, 'mapId': recipe['mapId'], 'mapSize': [recipe['width'], recipe['depth']], 'sourceOrigin': recipe['SOURCE_ORIGIN'], 'source': {'assetId': recipe['SOURCE_ID'], 'archiveSha256': recipe['ARCHIVE_SHA256'], 'memberSha256': recipe['DAE_SHA256'], 'texture': texture_name, 'textureSha256': recipe['TEXTURE_SHA256'], 'material': recipe['material'], 'sourceOpacity': next(iter(opacity)), 'sourceUvTransform': transform, 'animation': recipe['clip'], 'animationSha256': recipe['ANIMATION_SHA256']}, 'surface': {'worldHeight': recipe['SURFACE_HEIGHT'], 'alphaMode': 'BLEND', 'collision': False, 'baseColorFactor': [1, 1, 1, next(iter(opacity))], 'nativeOriginUv': recipe['nativeOriginUv'], 'uvRepeatCells': recipe['uvRepeatCells'], 'animationIndex': 0, 'animationLoop': True, 'animationSpeed': recipe['ANIMATION_SPEED']}, 'models': [model], 'placementAction': {'actionId': 'map3d.instance.upsert_batch', 'parameters': {'mapId': recipe['mapId'], 'instances': [instance]}}, 'import': {'actionId': 'model3d.import_batch'}, 'evidence': {'instanceCount': 1, 'triangleCount': metrics['triangleCount'], 'convexPieceCount': len(polygons), 'surfaceAreaCellsSquared': sum((polygon_area(polygon) for polygon in polygons)), 'exclusionTriangleCount': len(masks), 'excludedMaterials': excluded_materials, 'clipEpsilonCellsSquared': FOOTPRINT_EPSILON, 'sharedVertexCanonicalizationCells': 1e-08, 'nativeDeepSeaAndShallowWaterFootprintsExcluded': True, 'existingOpaqueBackingModelsAndInstancesPreserved': True, 'projectMapSha256Before': sha256(map_bytes).hexdigest(), 'projectMutationPerformed': False, 'nativeWaterGeometryFingerprints': geometry_fingerprints, 'visualReview': 'pending', 'originalGameCadenceProven': False}}
    (output_root / 'sea_plan.json').write_text(json.dumps(plan, ensure_ascii=False, indent=2) + '\n')
    recipe_path = output_root / 'water_recipe.json'
    recipe_path.write_text(json.dumps(recipe, indent=2) + '\n')
    command = ' '.join((shlex.quote(str(value)) for value in ('python3', Path(__file__).resolve(), '--source-root', source_root, '--output-root', output_root, '--surface-project', project, '--recipe', recipe_path, '--nitro-root', nitro_root)))
    (output_root / 'rebuild.sh').write_text('#!/bin/sh\nset -eu\n' + command + '\n')
    return plan

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--recipe', type=Path, required=True)
    parser.add_argument('--source-root', type=Path, required=True)
    parser.add_argument('--output-root', type=Path, required=True)
    parser.add_argument('--animation-project', type=Path)
    parser.add_argument('--nitro-root', type=Path)
    parser.add_argument('--sea-plan', type=Path)
    parser.add_argument('--surface-project', type=Path)
    arguments = parser.parse_args()
    recipe = require_water_recipe(json.loads(arguments.recipe.read_text()))
    animation_arguments = (arguments.animation_project, arguments.nitro_root, arguments.sea_plan)
    if arguments.surface_project:
        if arguments.animation_project or arguments.sea_plan or (not arguments.nitro_root):
            parser.error('Surface staging requires only --surface-project and --nitro-root')
        plan = stage_surface(arguments.source_root, arguments.surface_project, arguments.nitro_root, arguments.output_root, recipe=recipe)
        print(json.dumps(plan['evidence'], ensure_ascii=False))
    elif any(animation_arguments):
        if not all(animation_arguments):
            parser.error('Animation staging requires --animation-project, --nitro-root, and --sea-plan')
        application = stage_animation(arguments.source_root, arguments.animation_project, arguments.nitro_root, arguments.sea_plan, arguments.output_root, recipe=recipe)
        print(json.dumps(application['coverage'], ensure_ascii=False))
    else:
        plan = build(arguments.source_root, arguments.output_root, recipe=recipe)
        print(json.dumps({'models': len(plan['models']), **plan['evidence']}, ensure_ascii=False))
if __name__ == '__main__':
    main()

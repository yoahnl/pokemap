import argparse
from collections import defaultdict
from copy import deepcopy
from hashlib import sha256
from io import BytesIO
import json
import math
from pathlib import Path

from PIL import Image

from city_geometry import REPOSITORY, Surface, barycentric, cell_triangles, interpolate, source_inventory, source_scene
from city_ground import build_ground, ground_triangle, native_palette, pixel_of
from city_models import apply_source_support_corridors, build_models, fit_ramp_contacts, navigation, ramp_contacts_valid


def selected_cities(catalog, only, lot):
    requested = set(only.split(',')) if only else None
    cities = [city for city in catalog['cities'] if (requested is None or city['id'] in requested) and (lot is None or city['lot'] == lot)]
    if requested and requested - {city['id'] for city in cities}:
        raise ValueError('Unknown city selection')
    return cities


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n')


def palette_chunks(draft, maximum_materials=2048):
    if len(draft['allowedMaterialIds']) <= maximum_materials:
        return [draft]
    result = []
    members = draft['allowedMaterialIds']
    for start in range(0, len(members), maximum_materials):
        selected = members[start:start+maximum_materials]
        allowed = set(selected)
        chunk = deepcopy(draft)
        index = len(result)+1
        chunk['id'] += f'-part-{index}'
        chunk['targetPresetId'] += f'-part-{index}'
        chunk['name'] += f' · {index}'
        chunk['allowedMaterialIds'] = selected
        chunk['materials'] = [item for item in draft['materials'] if item['id'] in allowed]
        chunk['rules'] = [item for item in draft['rules'] if item['centerMatch']['materialId'] in allowed]
        chunk['coverageProfile']['requiredScenarios'] = [item for item in draft['coverageProfile']['requiredScenarios'] if item['centerMaterialId'] in allowed]
        chunk['defaultMaterialId'] = draft['defaultMaterialId'] if draft['defaultMaterialId'] in allowed else selected[0]
        if index > 1:
            chunk['atlases'] = []
        result.append(chunk)
    return result


def apply_source_terrain_ramps(city, surfaces, provenance, origin, ground, nav):
    ramps = list(nav['ramps'])
    for index, policy in enumerate(city.get('sourceTerrainRamps', [])):
        if provenance['archiveSha256'] != policy['archiveSha256'] or provenance['memberSha256'] != policy['memberSha256']:
            raise ValueError('Terrain ramp source identity changed')
        if origin != policy['expectedOrigin'] or ground['levelHeight'] != policy['expectedLevelHeight'] or ground['offsetY'] != policy['expectedOffsetY']:
            raise ValueError('Terrain ramp native coordinate basis changed')
        limits = policy['sourceBounds']
        selected = [(surface, triangle) for surface in surfaces
                    if (surface.group, surface.geometry, surface.material) == (policy['group'], policy['geometry'], policy['material'])
                    for triangle in surface.triangles
                    if all(limits[axis]-.000001 <= vertex[axis] <= limits[axis+3]+.000001
                           for vertex in triangle for axis in range(3))]
        if len(selected) != policy['triangleCount']:
            raise ValueError('Terrain ramp source triangles changed')
        vertices = [vertex for _, triangle in selected for vertex in triangle]
        bounds = [min(v[axis] for v in vertices) for axis in range(3)]+[max(v[axis] for v in vertices) for axis in range(3)]
        if any(abs(actual-expected) > 1e-6 for actual, expected in zip(bounds, policy['sourceBounds'])):
            raise ValueError('Terrain ramp source bounds changed')
        gradient = policy['plane']
        if any(abs(vertex[1]-(gradient[0]*vertex[0]+gradient[1]*vertex[2]+gradient[2])) > 1e-6 for vertex in vertices):
            raise ValueError('Terrain ramp is no longer planar')
        direction = ('east' if gradient[0] > 0 else 'west') if abs(gradient[0]) > abs(gradient[1]) else ('south' if gradient[1] > 0 else 'north')
        candidate = {'id': f'source-terrain-ramp-{index}', 'x': bounds[0]-origin[0], 'z': bounds[2]-origin[2],
                     'width': bounds[3]-bounds[0], 'depth': bounds[5]-bounds[2], 'direction': direction,
                     'lowLevel': round((bounds[1]+ground['offsetY'])/ground['levelHeight']),
                     'highLevel': round((bounds[4]+ground['offsetY'])/ground['levelHeight'])}
        ramp = fit_ramp_contacts(candidate, ground['levels'], ground['width'],
                                 ground['depth'], ground['levelHeight'],
                                 (bounds[1]+ground['offsetY'], bounds[4]+ground['offsetY']))
        if ramp is None:
            raise ValueError('Terrain ramp has no native landing contacts')
        if any(max(ramp['x'], area['x']) < min(ramp['x']+ramp['width'], area['x']+area['width'])
               and max(ramp['z'], area['z']) < min(ramp['z']+ramp['depth'], area['z']+area['depth'])
               for area in nav['blockedAreas']):
            raise ValueError('Terrain ramp crosses an authored blocker')
        ramps.append(ramp)
    if not all(ramp_contacts_valid(ramp, ramps, ground['levels'], ground['width'], ground['depth']) for ramp in ramps):
        raise ValueError('Terrain ramp landing contacts are inconsistent')
    return {**nav, 'ramps': ramps}


def quantization_navigation_evidence(ground, navigation):
    def inside(cell, area):
        x, z = cell[0]+.5, cell[1]+.5
        return area['x'] <= x < area['x']+area['width'] and area['z'] <= z < area['z']+area['depth']

    excluded = [*navigation['blockedAreas'], *navigation['ramps']]
    free = {cell for cell in ground['levels'] if not any(inside(cell, area) for area in excluded)}
    lost, flattened, unsafe = [], [], []
    for cell in sorted(free):
        for neighbor in [(cell[0]+1, cell[1]), (cell[0], cell[1]+1)]:
            if neighbor not in free:
                continue
            source_delta = abs(ground['logicalHeights'][cell]-ground['logicalHeights'][neighbor])
            native_delta = abs(ground['levels'][cell]-ground['levels'][neighbor])*ground['levelHeight']
            entry = {'cells': [cell, neighbor], 'sourceDelta': source_delta, 'nativeDelta': native_delta}
            if source_delta <= .250001 and native_delta > .250001:
                lost.append(entry)
            if source_delta > .250001 and native_delta <= .250001:
                flattened.append(entry)
                if source_delta > 1.000001:
                    unsafe.append(entry)
    return {'smallTransitionsLost': len(lost), 'smallTransitionsLostSamples': lost[:8],
            'sourceTransitionsFlattened': len(flattened), 'sourceTransitionsFlattenedSamples': flattened[:8],
            'largeSourceStepsFlattened': len(unsafe), 'largeSourceStepsFlattenedSamples': unsafe[:8]}


def inventory(source_root, output_root, cities):
    records = {record['id']: record for record in json.loads((source_root / 'manifest.json').read_text())['assets']}
    index = []
    for city in cities:
        record = records[city['sourceId']]
        surfaces, textures, provenance = source_scene(source_root, record)
        vertices = [vertex for surface in surfaces for vertex in surface.vertices]
        bounds = [min(v[a] for v in vertices) for a in range(3)] + [max(v[a] for v in vertices) for a in range(3)]
        materials = source_inventory(surfaces)
        folder = output_root / city['id']
        write_json(folder / 'source_inventory.json', {'city': city, 'bounds': bounds, 'materials': materials, 'provenance': provenance})
        candidates = [(name, info) for name, info in materials.items() if info['horizontalArea'] > 0.5]
        columns, size = 8, 128
        contact = Image.new('RGB', (columns * size, max(1, math.ceil(len(candidates)/columns)) * (size+24)), '#202733')
        from PIL import ImageDraw
        draw = ImageDraw.Draw(contact)
        for i, (name, info) in enumerate(candidates):
            image = Image.open(BytesIO(textures[info['textures'][0]])).convert('RGBA')
            scale = min((size-8)/image.width, (size-8)/image.height)
            thumbnail = image.resize((max(1, round(image.width*scale)), max(1, round(image.height*scale))), Image.Resampling.NEAREST)
            x, y = (i % columns)*size, (i // columns)*(size+24)
            contact.paste(thumbnail, (x+4, y+4), thumbnail)
            draw.text((x+4, y+size), name[:20], fill='white')
        contact.save(folder / 'source_materials.png')
        index.append({**city, 'bounds': bounds, 'surfaceCount': len(surfaces), 'sourceMaterials': len(materials), 'neutralPoseMatrixMaxError': provenance['neutralPoseMatrixMaxError']})
        print(json.dumps({'city': city['id'], 'extent': [round(bounds[a+3]-bounds[a], 2) for a in range(3)], 'surfaces': len(surfaces), 'neutralPoseError': provenance['neutralPoseMatrixMaxError']}), flush=True)
    write_json(output_root / 'inventory_index.json', {'cities': index})


def map_groups(catalog):
    root_id = 'unys-native-cities'
    groups = [{'id':root_id, 'name':'Unys — villes reconstruites', 'type':'special', 'sortOrder':1}]
    names = ['Premières villes', 'Côte et montagnes', 'Volucité et Port Yoneuve', 'Méanville et Parsemille',
             'Janusia et Entrelasque', 'Retour dans l’est d’Unys', 'Zones exclusives']
    for index, name in enumerate(names, 1):
        groups.append({'id':f'unys-lot-{index}', 'name':f'{index:02d} — {name}', 'type':'special', 'parentGroupId':root_id, 'sortOrder':index})
    for key, name, lot in [('volucite','Volucité',3), ('meanville','Méanville',4)]:
        groups.append({'id':'unys-group-'+key, 'name':name, 'type':'city', 'parentGroupId':f'unys-lot-{lot}', 'sortOrder':0})
    return groups


def apply_spawn_policy(city, ground, origin, width, depth, nav, surfaces, textures,
                       provenance, instances=()):
    policy = city.get('spawnPolicy')
    if policy is None:
        return nav, None
    if policy['kind'] != 'source_pedestrian_square':
        raise ValueError('Unknown source spawn policy')
    if any(abs(a-b) > .000001 for a, b in zip(origin, policy['expectedOrigin'])):
        raise ValueError('Source spawn origin changed')
    if any(provenance.get(key) != value
           for key, value in policy['sourceEvidence'].items()):
        raise ValueError('Source spawn provenance changed')
    x, z = policy['sourcePoint'][0]-origin[0], policy['sourcePoint'][1]-origin[2]
    if any(abs(value-math.floor(value)-.5) > .000001 for value in (x, z)):
        raise ValueError('Source spawn must resolve to a native cell center')
    cx, cz = math.floor(x), math.floor(z)
    left, top, right, bottom = cx-1, cz-1, cx+2, cz+2
    if left < 0 or top < 0 or right > width or bottom > depth:
        raise ValueError('Source spawn clearance is outside the native map')
    if any(instance['blocksMovement'] for instance in instances):
        raise ValueError('Source spawn clearance needs canonical model collision verification')
    for area in [*nav['blockedAreas'], *nav['ramps']]:
        if (left < area['x']+area['width'] and right > area['x']
                and top < area['z']+area['depth'] and bottom > area['z']):
            raise ValueError('Source spawn clearance intersects authored collision or relief')
    expected_height = policy['supportSourceHeight']
    expected_native = policy['expectedNativeHeight']
    allowed_materials = set(policy['supportMaterials'])
    cells = [(px, pz) for pz in range(top, bottom) for px in range(left, right)]
    for cell in cells:
        if (cell not in ground['levels']
                or ground['materials'].get(cell) not in allowed_materials
                or abs(ground['sourceHeights'][cell]-expected_height) > .000001
                or abs(ground['levels'][cell]*ground['levelHeight']-expected_native) > .000001):
            raise ValueError('Source spawn native support changed within its clearance')
    candidates = []
    for surface in surfaces:
        triangles = [triangle for triangle in surface.triangles
                     if ground_triangle(city, surface, triangle)]
        if triangles:
            candidates.append(Surface(surface.group, surface.geometry, surface.material,
                                      surface.texture, surface.wraps, surface.opacity,
                                      triangles, True))
    entries = cell_triangles(candidates, origin, width, depth)
    images = {surface.texture: Image.open(BytesIO(textures[surface.texture])).convert('RGBA')
              for surface in candidates}
    samples = 0
    for px, pz in cells:
        for iy in range(16):
            for ix in range(16):
                sx, sz = px+origin[0]+(ix+.5)/16, pz+origin[2]+(iy+.5)/16
                hits = []
                for surface, triangle in entries.get((px, pz), []):
                    weights = barycentric(sx, sz, triangle)
                    if weights is None:
                        continue
                    rgba = pixel_of(surface, triangle, weights, images)
                    if rgba[3] >= 128:
                        hits.append((interpolate(triangle, weights, 1), surface, rgba))
                if not hits:
                    raise ValueError('Source spawn has no opaque source support')
                height, surface, rgba = max(hits, key=lambda hit: hit[0])
                if surface.material not in allowed_materials or abs(height-expected_height) > .000001:
                    raise ValueError('Source spawn source support changed within its clearance')
                if rgba[3] != 255:
                    raise ValueError('Source spawn support is not fully opaque')
                samples += 1
    spawn = {'x': x, 'z': z}
    return {**nav, 'spawn': spawn}, {'kind': policy['kind'], 'sourcePoint': policy['sourcePoint'],
                                    'nativeSpawn': spawn, 'nativeHeight': expected_native,
                                    'nativeClearanceCells': len(cells), 'opaqueSourceSamples': samples,
                                    'sourceEvidence': policy['sourceEvidence']}


def build_city(city, source_root, record, folder, source_reader=None):
    folder.mkdir(parents=True, exist_ok=True)
    surfaces, textures, provenance = (source_reader or source_scene)(source_root, record)
    vertices = [vertex for surface in surfaces for vertex in surface.vertices]
    bounds = [min(v[a] for v in vertices) for a in range(3)] + [max(v[a] for v in vertices) for a in range(3)]
    origin = [math.floor(bounds[0])-1, 0, math.floor(bounds[2])-1]
    width, depth = math.ceil(bounds[3]-origin[0])+1, math.ceil(bounds[5]-origin[2])+1
    if width>256 or depth>256:
        raise ValueError('City sector exceeds native map dimensions')
    ground = build_ground(city, surfaces, textures, origin, width, depth, folder)
    models, instances, footprints, obstacles, stairs, omitted = build_models(city, surfaces, textures, origin, ground, folder)
    nav, nav_evidence = navigation(ground, origin, width, depth, footprints, obstacles, stairs, surfaces, textures,
                                  city.get('nativeRampOmissions'))
    nav = apply_source_terrain_ramps(city, surfaces, provenance, origin, {**ground, 'width': width, 'depth': depth}, nav)
    ground, nav, nav_evidence = apply_source_support_corridors(city, ground, origin, width, depth, nav,
                                                            nav_evidence, surfaces, textures, provenance)
    nav, spawn_evidence = apply_spawn_policy(city, ground, origin, width, depth, nav,
                                            surfaces, textures, provenance, instances)
    if spawn_evidence is not None:
        nav_evidence = {**nav_evidence, 'spawnPolicy': spawn_evidence}
    nav_evidence = {**nav_evidence, 'heightQuantization': quantization_navigation_evidence(ground, nav)}
    map_id, prefix = 'unys-'+city['id'], 'unys-'+city['id']
    group_id = 'unys-group-'+city['cityGroup'] if city.get('cityGroup') else f'unys-lot-{city["lot"]}'
    actions, images = [], []

    def action(action_id, parameters):
        actions.append({'actionId':action_id,'parameters':parameters})

    def image_asset(path, key, name):
        data = path.read_bytes()
        with Image.open(path) as image:
            width, height = image.size
        asset_id, tileset_id = prefix+'-image-'+key, prefix+'-tileset-'+key
        logical = 'assets/tilesets/unys/'+city['id']+'/'+path.name
        images.append({'assetId':asset_id,'path':str(path),'mediaType':'image/png','logicalPath':logical,'sha256':sha256(data).hexdigest()})
        action('tileset.upsert', {'tileset':{'id':tileset_id,'name':name,'relativePath':logical,
                'source':{'kind':'regular_atlas','assetId':asset_id,'pixelWidth':width,'pixelHeight':height,
                          'tileWidth':16,'tileHeight':16,'tileProperties':[]}, 'scope':'global','sortOrder':0,'isWorldTileset':False,
                'elementGroups':[],'paletteEntries':[]}})
        return tileset_id, (width, height)

    action('map.create', {'mapId':map_id,'name':city['name'],'width':width,'height':depth,'groupId':group_id,'role':'exterior'})
    action('map3d.terrain.configure_height', {'mapId':map_id,'levelHeight':ground['levelHeight']})
    atlas_id = prefix+'-ground-atlas'
    tileset_id, _ = image_asset(ground['atlasPath'],'ground',city['name']+' — terrains et chemins originaux')
    for usage in ('terrain','path'):
        draft = native_palette(city, ground, atlas_id, tileset_id, usage)
        if draft is None:
            continue
        if usage == 'path':
            draft['atlases'] = []
        cells_by_material = defaultdict(list)
        for (x,z), index in ground['cells'][usage].items():
            cells_by_material[index].append({'x':x,'y':z})
        chunks = palette_chunks(draft)
        for part, chunk in enumerate(chunks, 1):
            action('smart_tile.preset.draft.upsert', {'draft':chunk})
            action('smart_tile.preset.publish', {'draftId':chunk['id']})
            layer_id = prefix+'-'+usage+(f'-{part}' if len(chunks) > 1 else '')
            layer_name = 'Terrains' if usage == 'terrain' else 'Chemins et places'
            action('smart_tile.layer.create', {'mapId':map_id,'presetId':chunk['targetPresetId'],'layerId':layer_id,
                                             'name':layer_name+(f' · {part}' if len(chunks) > 1 else ''),'insertIndex':0})
            allowed = set(chunk['allowedMaterialIds'])
            action('smart_tile.cell.paint_batch', {'mapId':map_id,'layerId':layer_id,
                   'strokes':[{'materialId':f'{prefix}-{usage}-{index}','cells':cells} for index,cells in sorted(cells_by_material.items())
                              if f'{prefix}-{usage}-{index}' in allowed]})
    action('map3d.terrain.set_levels', {'mapId':map_id,'cells':[{'x':x,'z':z,'level':level} for (x,z),level in sorted(ground['levels'].items())]})
    cliff = next((surface for surface in surfaces if 'gake' in surface.material.lower() and not any(word in surface.material.lower() for word in ('sea','mizu'))), None)
    if cliff is None:
        cliff = next((surface for surface in surfaces if 'yuka' in surface.material.lower()), None)
    if cliff is not None:
        image = Image.open(BytesIO(textures[cliff.texture])).convert('RGBA')
        if image.width%16 == 0 and image.height%16 == 0:
            path = folder/'cliff_texture.png'
            path.write_bytes(textures[cliff.texture])
            cliff_tileset, size = image_asset(path,'cliff',city['name']+' — falaise originale')
            cliff_atlas = prefix+'-cliff-atlas'
            action('smart_tile.atlas.upsert',{'atlas':{'id':cliff_atlas,'name':city['name']+' — falaise','tilesetId':cliff_tileset,
                    'cellWidth':16,'cellHeight':16,'columns':size[0]//16,'rows':size[1]//16}})
            action('map3d.terrain.configure_appearance',{'mapId':map_id,'cliffFrame':{'atlasId':cliff_atlas,'column':0,'row':0,
                                                                                 'columnSpan':size[0]//16,'rowSpan':size[1]//16}})
    action('map3d.navigation.configure',{'mapId':map_id,'navigation':nav})
    action('entity.create',{'mapId':map_id,'entity':{'id':prefix+'-start','name':'Départ de la visite','kind':'spawn',
           'pos':{'x':math.floor(nav['spawn']['x']),'y':math.floor(nav['spawn']['z'])},'size':{'width':1,'height':1},
           'spawn':{'spawnKey':'','role':'player_start','facing':'south','categoryTag':''},'blocksMovement':False,'properties':{}}})
    for instance in instances:
        action('map3d.instance.upsert',{'mapId':map_id,'instance':instance})
    summary = {**city,'mapId':map_id,'groupId':group_id,'width':width,'height':depth,'sourceOrigin':origin,
               'sourceYOffset':ground['offsetY'],'levelHeight':ground['levelHeight'],'nativeFloorCells':ground['sourceFloorCellCount'],
               'terrainCells':len(ground['cells']['terrain']),'pathCells':len(ground['cells']['path']),
               'paletteVariants':len(ground['tiles']),'modelCount':len(models),'instanceCount':len(instances),
               'sourceTriangleCount':sum(len(surface.triangles) for surface in surfaces),'modularTriangleCount':sum(model['triangleCount'] for model in models),
               'sourceMaterialHistogram':ground['sourceMaterialHistogram'],'maxHeightQuantizationError':ground['maxHeightQuantizationError'],
               'logicalHeightAdjustedCells':ground['heightPolicyChangedCells'],'sourceFloorOmissions':ground['omittedSourceTriangles'],
               'navigation':nav_evidence,'rampCount':len(nav['ramps']),'actions':len(actions),'visualReview':'pending','deviceValidation':'deferred_by_user'}
    asset_city = {key:value for key,value in city.items() if key != 'nativeSupport'}
    write_json(folder/'assets_manifest.json',{'city':asset_city,'images':images,'models':models})
    write_json(folder/'actions.json',actions)
    write_json(folder/'reconstruction.json',{'summary':summary,'source':provenance,'omitted':[*omitted,*ground['omittedSourceTriangles']],
               'proofLimits':['Draft reconstruction; original story and interiors are excluded.',
                              'Collision footprints are reconstructed from source contact geometry, not extracted original game collision data.',
                              'Native relief has one height per cell; quantization is measured against logical source heights after the explicit catalog policies, with adjusted cells and source omissions recorded separately.',
                              'No physical iOS or Android test was requested for this lot.']
                             + ([city['nativeSupport']['proofLimit']] if city.get('nativeSupport') else [])})
    print(json.dumps({'built':city['id'],'mapSize':[width,depth],'groundCells':len(ground['levels']),'variants':len(ground['tiles']),
                      'models':len(models),'instances':len(instances),'ramps':len(nav['ramps']),'actions':len(actions),'heightError':ground['maxHeightQuantizationError']}),flush=True)
    return summary


def build(source_root, output_root, catalog, cities):
    records = {record['id']:record for record in json.loads((source_root/'manifest.json').read_text())['assets']}
    summaries = {}
    index_path = output_root/'index.json'
    if index_path.exists():
        summaries = {city['id']:city for city in json.loads(index_path.read_text())['cities']}
    for city in catalog['cities']:
        completed = output_root / city['id'] / 'reconstruction.json'
        if completed.exists():
            summary = json.loads(completed.read_text())['summary']
            if summary['id'] != city['id'] or summary['sourceId'] != city['sourceId']:
                raise ValueError('A completed city recipe has a conflicting source identity')
            summaries[city['id']] = summary
    for city in cities:
        summaries[city['id']] = build_city(city,source_root,records[city['sourceId']],output_root/city['id'])
        write_json(index_path,{'formatVersion':1,'groups':map_groups(catalog),'cities':[summaries[row['id']] for row in catalog['cities'] if row['id'] in summaries]})


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source-root', type=Path, required=True)
    parser.add_argument('--project-root', type=Path, required=True)
    parser.add_argument('--only')
    parser.add_argument('--lot', type=int)
    parser.add_argument('--inventory', action='store_true')
    arguments = parser.parse_args()
    arguments.source_root = arguments.source_root.resolve(strict=True)
    arguments.project_root = arguments.project_root.resolve(strict=True)
    if not (arguments.project_root / 'project.json').is_file():
        raise ValueError('An existing native project root is required')
    if arguments.source_root == arguments.project_root or arguments.source_root in arguments.project_root.parents or arguments.project_root in arguments.source_root.parents:
        raise ValueError('The read-only source corpus and project must be separate')
    catalog = json.loads(Path(__file__).with_name('city_catalog.json').read_text())
    cities = selected_cities(catalog, arguments.only, arguments.lot)
    output_root = arguments.project_root / '.pokemap/authoring/unys-cities'
    if arguments.inventory:
        inventory(arguments.source_root, output_root, cities)
    else:
        build(arguments.source_root, output_root, catalog, cities)


if __name__ == '__main__':
    main()

from collections import Counter, defaultdict
from hashlib import sha256
from io import BytesIO
import math
import re

from PIL import Image

from city_geometry import barycentric, cell_triangles, interpolate, projected_area, sample_texture


EXTRA_FLOORS = {
    'amaillide': {'jimen2', 'miti', 'miti2', 'yuka', 'yuka_2', 'hibi', 'michi_hage', 'michi_hibi'},
    'ondes-sur-mer': {'c13_gawa01', 'c13_yogore1'},
    'arpentieres': {'out57_futa'},
    'vaguelone': {'out18_dan01', 'gake_futa'},
    'papeloa': set(),
    'entrelasque': {'tg_02_2'},
    'renouet': {'t01wd1'},
    'arabelle': {'t02_ki_sita', 't02_kiwa', 't02hibi', 'gake_futa'},
    'flocombe': {'sp_marsh', 'sp_marsh2', 'sp_o11m', 'sp_o11m2', 'sp_o11m4', 'sp_o11m5', 'gake_futa'},
    'rotombourg': {'ou34_tile01', 'gake_futa'},
    'ville-noire': {'bc_jimen01'},
}


def floor_kind(city, surface):
    name = surface.material.lower()
    if not surface.terrain or any(word in name for word in ('kage', 'shadow', 'yuki', 'ochiba', 'kusa_ec', 'kaidan', 'marsh_hana')):
        return None
    if city.get('sourceFloorMaterials') is not None and surface.material not in city['sourceFloorMaterials']:
        return None
    selection = next((entry for entry in city.get('sourceHorizontalFloors', [])
                      if entry['material'] == surface.material), None)
    if selection is not None:
        return selection.get('kind', 'path')
    if name in EXTRA_FLOORS.get(city['id'], set()):
        return 'path' if any(word in name for word in ('yuka', 'miti', 'hibi', 'hage', 'wd1', 'tile')) else 'terrain'
    if re.search(r'grass|jimen|zimen|_soil|_dirt|^siba|^gra_w|gra_w_|w_gra|out\d+_?kusa01', name):
        return 'terrain'
    if re.search(r'michi|mchi|miti|road|tile|yuka|yuk\d|hashi(?!ra)|hasi(?!ra)|sanbashi|_strip|c3_line|c3_center', name):
        return 'path'
    if name in {'gake1_1', 'gake1_0', 'gake_futa', 'c8_gake1_w', 'c3_bayblock2', 'c3_bayyuka2'}:
        return 'terrain'
    return None


def is_water(surface):
    name = surface.material.lower()
    return any(word in name for word in ('mizu', 'ike01', 'kawa', 'asase', 'ragu', 'zanami', '_zan', 'simi')) or name.startswith('sea_gake') or (name.startswith('out58_gake') and surface.bounds[4] < -5)


def ground_triangle(city, surface, triangle):
    if floor_kind(city, surface) is None or is_water(surface):
        return False
    area = projected_area(triangle)
    if area < 1e-8:
        return False
    selection = next((entry for entry in city.get('sourceHorizontalFloors', [])
                      if entry['material'] == surface.material), None)
    if selection is not None:
        heights = [vertex[1] for vertex in triangle]
        tolerance = selection.get('sourceHeightTolerance', .050001)
        return max(heights)-min(heights) <= tolerance and any(
            all(abs(height-target) <= tolerance for height in heights) for target in selection['sourceHeights'])
    a, b, c = triangle
    ab, ac = [b[i]-a[i] for i in range(3)], [c[i]-a[i] for i in range(3)]
    cross = [ab[1]*ac[2]-ab[2]*ac[1], ab[2]*ac[0]-ab[0]*ac[2], ab[0]*ac[1]-ab[1]*ac[0]]
    length = math.sqrt(sum(v*v for v in cross))
    if abs(cross[1]) / length < 0.45:
        return False
    if city['id'].startswith('volucite') and max(v[1] for v in triangle) > 1.75:
        return False
    return True


def blend(destination, source):
    alpha = source[3] / 255
    output_alpha = alpha + destination[3] / 255 * (1-alpha)
    if output_alpha < 1e-8:
        return (0, 0, 0, 0)
    rgb = [round((source[i]*alpha + destination[i]*destination[3]/255*(1-alpha))/output_alpha) for i in range(3)]
    return tuple(rgb) + (round(output_alpha*255),)


def pixel_of(surface, triangle, weights, images):
    rgba = sample_texture(images[surface.texture], interpolate(triangle, weights, 3), interpolate(triangle, weights, 4), surface.wraps)
    return tuple(round(rgba[i] * max(0, min(1, interpolate(triangle, weights, i+5)))) for i in range(3)) + (round(rgba[3]*surface.opacity),)


def raster_tile(entries, source_x, source_z, images, kind, city, resolution=16):
    pixels = [(0, 0, 0, 0)] * (resolution*resolution)
    for py in range(resolution):
        z = source_z + (py+.5)/resolution
        for px in range(resolution):
            x = source_x + (px+.5)/resolution
            color = (0, 0, 0, 0)
            hits = []
            for surface, triangle in entries:
                if kind == 'terrain' and floor_kind(city, surface) != 'terrain':
                    continue
                weights = barycentric(x, z, triangle)
                if weights is not None:
                    hits.append((interpolate(triangle, weights, 1), floor_kind(city, surface) == 'path', surface, triangle, weights))
            for _, is_path, surface, triangle, weights in sorted(hits, key=lambda hit: hit[:2]):
                pixel = pixel_of(surface, triangle, weights, images)
                if kind == 'path' and not is_path:
                    color = color[:3] + (round(color[3] * (1-pixel[3]/255)),)
                else:
                    color = blend(color, pixel)
            pixels[py*resolution+px] = color
    image = Image.new('RGBA', (resolution, resolution))
    image.putdata(pixels)
    return image


def floor_hits_at_cell(entries, x, z, images):
    hits = []
    for surface, triangle in entries:
        weights = barycentric(x, z, triangle)
        if weights is not None and pixel_of(surface, triangle, weights, images)[3] >= 128:
            hits.append((interpolate(triangle, weights, 1), surface))
    return hits


def floor_at_cell(entries, x, z, images):
    hits = floor_hits_at_cell(entries, x, z, images)
    return max(hits, key=lambda hit: hit[0]) if hits else None


def logical_floor_height(city, hits):
    height, winner = max(hits, key=lambda hit: hit[0])
    policy = city.get('groundHeightPolicy')
    if policy is None:
        return height
    if policy['kind'] == 'overlapping_supports':
        if winner.material not in policy['overlayMaterials']:
            return height
        supports = [y for y, surface in hits if surface.material in policy['supportMaterials']
                    and 0 <= height-y <= policy['maxHeightDelta']+.000001]
        return max(supports) if supports else height
    supports = [y for y, surface in hits
                if surface.material == policy['supportMaterial']
                and abs(y-policy['supportSourceHeight']) < .000001]
    if not supports:
        return height
    if policy['kind'] == 'overlapping_support':
        if winner.material not in policy['overlayMaterials']:
            return height
        nearby = [y for y in supports if 0 <= height-y <= policy['maxHeightDelta']+.000001]
        return min(nearby) if nearby else height
    if policy['kind'] == 'source_material_plane':
        return max(policy['logicalHeight'],
                   max((y for y, surface in hits
                        if surface.material != policy['supportMaterial']
                        or abs(y-policy['supportSourceHeight']) >= .000001),
                       default=policy['logicalHeight']))
    raise ValueError('Unknown source ground height policy')


def ground_omission_index(city, surface, triangle):
    bounds = [min(v[a] for v in triangle) for a in range(3)] + [max(v[a] for v in triangle) for a in range(3)]
    for index, omission in enumerate(city.get('groundTriangleOmissions', [])):
        if (surface.group == omission['group'] and surface.geometry == omission['geometry']
                and surface.material == omission['material']
                and all(abs(a-b) < .000001 for a, b in zip(bounds, omission['sourceBounds']))):
            return index
    return None


def quantize_heights(heights):
    minimum, maximum = min(heights.values()), max(heights.values())
    level_height = .25 if maximum-minimum <= 7.75+.000001 else .5
    while True:
        offset_y = -math.floor(minimum/level_height+.000001)*level_height
        levels = {cell: max(0, math.floor(round((height+offset_y)/level_height, 8)+.5)) for cell, height in heights.items()}
        if max(levels.values()) <= 32:
            return level_height, offset_y, levels
        level_height *= 2
        if level_height > 16:
            raise ValueError('Ground height exceeds native level budget')


def build_ground(city, surfaces, textures, origin, width, depth, folder):
    images = {name: Image.open(BytesIO(data)).convert('RGBA') for name, data in textures.items()}
    candidates = []
    omissions = [{**omission, 'matchedTriangles': 0}
                 for omission in city.get('groundTriangleOmissions', [])]
    from city_geometry import Surface
    for surface in surfaces:
        triangles = []
        for triangle in surface.triangles:
            omission = ground_omission_index(city, surface, triangle)
            if omission is not None:
                omissions[omission]['matchedTriangles'] += 1
            elif ground_triangle(city, surface, triangle):
                triangles.append(triangle)
        if triangles:
            candidates.append(Surface(surface.group, surface.geometry, surface.material, surface.texture, surface.wraps, surface.opacity, triangles, True))
    if any(omission['matchedTriangles'] != omission['triangleCount'] for omission in omissions):
        raise ValueError('Source ground omission triangle count does not match its provenance')
    entries = cell_triangles(candidates, origin, width, depth)
    heights, logical_heights, placement_heights, materials = {}, {}, {}, {}
    for (x, z), triangles in entries.items():
        hits = floor_hits_at_cell(triangles, x+.5+origin[0], z+.5+origin[2], images)
        if hits:
            hit = max(hits, key=lambda entry: entry[0])
            heights[x,z], materials[x,z] = hit[0], hit[1].material
            logical_heights[x,z] = logical_floor_height(city, hits)
            placement_heights[x,z] = hit[0]
            policy = city.get('groundHeightPolicy')
            if (policy and policy['kind'] == 'source_material_plane'
                    and hit[1].material == policy['supportMaterial']
                    and abs(hit[0]-policy['supportSourceHeight']) < .000001):
                placement_heights[x,z] = logical_heights[x,z]
    if not heights:
        raise ValueError(f'No native ground identified for {city["id"]}')
    level_height, offset_y, levels = quantize_heights(logical_heights)
    if city.get('nativeHeightOffset') is not None:
        offset_y = city['nativeHeightOffset']
        if not math.isfinite(offset_y):
            raise ValueError('Native height offset must be finite')
        levels = {cell: math.floor(round((height+offset_y)/level_height, 8)+.5)
                  for cell, height in logical_heights.items()}
        if min(levels.values()) < 0 or max(levels.values()) > 32:
            raise ValueError('Native height offset exceeds the level budget')
    terrain_base = next((surface for surface in candidates if floor_kind(city, surface) == 'terrain' and 'grass' in surface.material.lower()), candidates[0])
    base = images[terrain_base.texture].resize((16, 16), Image.Resampling.NEAREST)
    if base.getchannel('A').getextrema()[0] < 255:
        opaque = Image.new('RGBA', base.size, (0, 0, 0, 255))
        opaque.alpha_composite(base)
        base = opaque
    tiles, by_digest, cells, tile_info = [], {}, {'terrain': {}, 'path': {}}, []
    preview = Image.new('RGBA', (width*16, depth*16))

    def register(tile, kind, family):
        digest = sha256(tile.tobytes()).hexdigest()
        key = (kind, digest)
        if key not in by_digest:
            by_digest[key] = len(tiles)
            tiles.append(tile)
            tile_info.append({'kind': kind, 'family': family, 'sha256': digest})
        return by_digest[key]

    for cell, triangles in sorted(entries.items(), key=lambda item: (item[0][1], item[0][0])):
        if cell not in heights:
            continue
        x, z = cell
        terrain = raster_tile(triangles, x+origin[0], z+origin[2], images, 'terrain', city)
        path = raster_tile(triangles, x+origin[0], z+origin[2], images, 'path', city)
        if terrain.getchannel('A').getextrema()[1] == 0:
            terrain = base.copy()
        cells['terrain'][cell] = register(terrain, 'terrain', materials[cell])
        if path.getchannel('A').getextrema()[1] > 0:
            cells['path'][cell] = register(path, 'path', materials[cell])
        composed = terrain.copy()
        composed.alpha_composite(path)
        preview.paste(composed, (x*16, z*16))
    columns = min(64, max(1, math.ceil(math.sqrt(len(tiles)))))
    atlas = Image.new('RGBA', (columns*16, max(1, math.ceil(len(tiles)/columns))*16))
    for index, image in enumerate(tiles):
        atlas.paste(image, ((index % columns)*16, (index // columns)*16))
    atlas_path = folder / 'ground_atlas.png'
    atlas.save(atlas_path)
    preview.save(folder / 'native_ground_plan.png')
    errors = [abs(levels[cell]*level_height-offset_y-height) for cell,height in logical_heights.items()]
    return {'tiles': tile_info, 'columns': columns, 'rows': atlas.height//16, 'atlasPath': atlas_path, 'cells': cells,
            'levels': levels, 'offsetY': offset_y, 'levelHeight': level_height, 'sourceHeights': heights, 'materials': materials,
            'logicalHeights': logical_heights, 'placementHeights': placement_heights,
            'omittedSourceTriangles': omissions,
            'heightPolicyChangedCells': sum(abs(heights[cell]-height) > .000001 for cell,height in logical_heights.items()),
            'placementPolicyChangedCells': sum(abs(heights[cell]-height) > .000001 for cell,height in placement_heights.items()),
            'sourceMaterialHistogram': dict(Counter(materials.values())), 'maxHeightQuantizationError': max(errors), 'sourceFloorCellCount': len(heights)}


def native_palette(city, ground, atlas_id, tileset_id, usage):
    prefix = 'unys-' + city['id']
    members = [(index, tile) for index, tile in enumerate(ground['tiles']) if tile['kind'] == usage]
    if not members:
        return None
    materials, rules, scenarios = [], [], []
    signature = {name: {'kind': 'any'} for name in ('northEdge', 'eastEdge', 'southEdge', 'westEdge', 'northWestCorner', 'northEastCorner', 'southEastCorner', 'southWestCorner')}
    counts = Counter(ground['cells'][usage].values())
    default_index = max((index for index, _ in members), key=lambda index: (counts[index], -index))
    for index, tile in members:
        material_id = f'{prefix}-{usage}-{index}'
        family = tile['family']
        materials.append({'id': material_id, 'name': family + f' · {index+1}', 'connectionGroupId': prefix + '-' + family,
                          **({'terrainType': 'grass'} if usage == 'terrain' and 'grass' in family.lower() else {}), 'sortOrder': index})
        frame = {'atlasId': atlas_id, 'column': index % ground['columns'], 'row': index // ground['columns']}
        rules.append({'id': material_id + '-rule', 'centerMatch': {'kind': 'material', 'materialId': material_id}, 'signature': signature,
                      'candidates': [{'id': material_id+'-frame', 'label': family, 'weight': 1,
                                      'parts': [{'source': {'kind': 'frame', 'frame': frame}, 'channel': 'ground', 'frameSampling': 'tessellated',
                                                 'footprintWidth': 1, 'footprintHeight': 1, 'anchorX': 0, 'anchorY': 0, 'drawOrder': 0}]}]})
        scenarios.append({'id': material_id+'-coverage', 'centerMaterialId': material_id, 'signature': {name: None for name in signature}})
    return {'id': prefix + '-draft-' + usage, 'targetPresetId': prefix + '-preset-' + usage,
            'name': city['name'] + (' — terrains' if usage == 'terrain' else ' — chemins et places'), 'usage': usage,
            'lastStage': 'publish', 'primaryAtlasId': atlas_id, 'atlases': [{'id': atlas_id, 'name': city['name'] + ' — sol original',
             'tilesetId': tileset_id, 'cellWidth': 16, 'cellHeight': 16, 'columns': ground['columns'], 'rows': ground['rows']}],
            'materials': materials, 'defaultMaterialId': f'{prefix}-{usage}-{default_index}', 'allowedMaterialIds': [item['id'] for item in materials],
            'topology': 'cardinal_4', 'templateHint': 'free', 'boundaryPolicy': 'empty', 'coveragePolicy': 'complete',
            'coverageProfile': {'mode': 'explicit', 'requiredScenarios': scenarios},
            'transformPolicy': {'allowHFlip': False, 'allowVFlip': False, 'allowQuarterTurns': False, 'preferUntransformed': True},
            'rules': rules, 'tags': ['NB2', city['name'], 'Source originale', 'Reconstruction native']}

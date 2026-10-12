from collections import defaultdict
from hashlib import sha256
from io import BytesIO
import json
import math
import struct

from city_geometry import Surface, barycentric, cell_triangles, connected_cells, interpolate, projected_area, union_rectangles
from city_ground import floor_kind, ground_triangle, is_water, pixel_of
from convert_bw2_village_assets import clip_polygon, emit_model, triangulate


def category(surface):
    name = surface.material.lower()
    if is_water(surface):
        return 'water'
    if any(word in name for word in ('ki02', 'ki03', 'ki04', 'mori', 'tree', 'bc_ha')):
        return 'forest'
    if any(word in name for word in ('kaidan', '_dan01')):
        return 'stairs'
    if any(word in name for word in ('buill', 'buil', 'building', 'house', 'gate', 'tg_')):
        return 'building'
    return 'details'


def component_triangles(entries):
    parents = list(range(len(entries)))
    owners = {}

    def root(index):
        while parents[index] != index:
            parents[index] = parents[parents[index]]
            index = parents[index]
        return index

    for index, (_, triangle) in enumerate(entries):
        for vertex in triangle:
            key = tuple(round(v, 3) for v in vertex[:3])
            if key in owners:
                parents[root(index)] = root(owners[key])
            owners[key] = index
    result = defaultdict(list)
    for index, entry in enumerate(entries):
        result[root(index)].append(entry)
    return list(result.values())


def clip_entries(entries, side, origin):
    buckets = defaultdict(list)
    for surface, triangle in entries:
        left = math.floor((min(v[0] for v in triangle)-origin[0])/side)
        right = math.floor((max(v[0] for v in triangle)-origin[0]-1e-7)/side)
        top = math.floor((min(v[2] for v in triangle)-origin[2])/side)
        bottom = math.floor((max(v[2] for v in triangle)-origin[2]-1e-7)/side)
        if right < left:
            right = left
        if bottom < top:
            bottom = top
        for z in range(top, bottom+1):
            for x in range(left, right+1):
                polygon = triangle
                for axis, lo, hi in ((0, origin[0]+x*side, origin[0]+(x+1)*side), (2, origin[2]+z*side, origin[2]+(z+1)*side)):
                    polygon = clip_polygon(polygon, axis, lo, True)
                    polygon = clip_polygon(polygon, axis, hi, False)
                for clipped in triangulate(polygon, validate=False):
                    buckets[x,z].append((surface, clipped))
    return sorted(buckets.items())


def entries_bounds(entries):
    vertices = [vertex for _, triangle in entries for vertex in triangle]
    return [min(v[a] for v in vertices) for a in range(3)] + [max(v[a] for v in vertices) for a in range(3)]


def ramp_cross_segments(ramp, extra_boundaries=()):
    along_z = ramp['direction'] in ('north','south')
    start = ramp['x'] if along_z else ramp['z']
    stop = start+(ramp['width'] if along_z else ramp['depth'])
    boundaries = sorted({start,stop,*range(math.ceil(start),math.floor(stop)+1),
                         *(value for value in extra_boundaries if start < value < stop)})
    return [(a,b) for a,b in zip(boundaries,boundaries[1:]) if b>a]


def ramp_landing_points(ramp, extra_boundaries=()):
    along_z = ramp['direction'] in ('north','south')
    epsilon = .000001
    for start,stop in ramp_cross_segments(ramp,extra_boundaries):
        inset = min(epsilon,(stop-start)/4)
        for cross in (start+inset,(start+stop)/2,stop-inset):
            nx = cross if along_z else ramp['x']-epsilon
            nz = ramp['z']-epsilon if along_z else cross
            px = nx if along_z else ramp['x']+ramp['width']+epsilon
            pz = ramp['z']+ramp['depth']+epsilon if along_z else nz
            yield nx,nz,px,pz


def ramp_from_contacts(candidate, levels, width, depth):
    along_z = candidate['direction'] in ('north','south')
    negative, positive = [], []
    for nx,nz,px,pz in ramp_landing_points(candidate):
        if min(nx,nz)<0 or px>=width or pz>=depth:
            return None
        negative_cell = math.floor(nx),math.floor(nz)
        positive_cell = math.floor(px),math.floor(pz)
        if negative_cell not in levels or positive_cell not in levels:
            return None
        negative.append(levels[negative_cell])
        positive.append(levels[positive_cell])
    if len(set(negative)) != 1 or len(set(positive)) != 1 or negative[0] == positive[0]:
        return None
    low, high = min(negative[0],positive[0]), max(negative[0],positive[0])
    direction = ('north' if negative[0]>positive[0] else 'south') if along_z else ('west' if negative[0]>positive[0] else 'east')
    return {**candidate,'lowLevel':low,'highLevel':high,'direction':direction}


def fit_ramp_contacts(candidate, levels, width, depth, level_height, height_bounds):
    along_z = candidate['direction'] in ('north','south')
    axis,extent = ('z','depth') if along_z else ('x','width')
    start,stop = candidate[axis],candidate[axis]+candidate[extent]
    starts,stops = {start},{stop}
    if math.ceil(start)-start > .0001:
        starts.add(math.ceil(start)+.000002)
    if stop-math.floor(stop) > .0001:
        stops.add(math.floor(stop)-.000002)
    fitted = []
    for lower in sorted(starts):
        for upper in sorted(stops):
            if lower < start or upper > stop or upper-lower < .25:
                continue
            axial = {**candidate,axis:lower,extent:upper-lower}
            runs = []
            for left,right in ramp_cross_segments(axial):
                cross_axis,cross_extent = ('x','width') if along_z else ('z','depth')
                section = {**axial,cross_axis:left,cross_extent:right-left}
                ramp = ramp_from_contacts(section,levels,width,depth)
                pair = (ramp['lowLevel'],ramp['highLevel'],ramp['direction']) if ramp else None
                if runs and runs[-1][2] == pair and pair is not None:
                    runs[-1] = runs[-1][0],right,pair
                else:
                    runs.append((left,right,pair))
            for left,right,pair in runs:
                if pair is None or right-left < .5:
                    continue
                section = {**axial,cross_axis:left,cross_extent:right-left}
                ramp = ramp_from_contacts(section,levels,width,depth)
                errors = [abs(ramp['lowLevel']*level_height-height_bounds[0]),
                          abs(ramp['highLevel']*level_height-height_bounds[1])]
                if max(errors) <= level_height/2+.250001:
                    fitted.append((ramp,sum(errors)))
    if not fitted:
        return None
    return min(fitted,key=lambda entry:(-ramp_passage_width(entry[0]),-entry[0][extent],
                                       entry[1],entry[0]['x'],entry[0]['z']))[0]


def ramp_contacts_valid(ramp, ramps, levels, width, depth):
    def level_at(x, z):
        for neighbor in ramps:
            if neighbor['x'] <= x < neighbor['x']+neighbor['width'] and neighbor['z'] <= z < neighbor['z']+neighbor['depth']:
                progress = {'north':1-(z-neighbor['z'])/neighbor['depth'],
                            'south':(z-neighbor['z'])/neighbor['depth'],
                            'west':1-(x-neighbor['x'])/neighbor['width'],
                            'east':(x-neighbor['x'])/neighbor['width']}[neighbor['direction']]
                return neighbor['lowLevel']+(neighbor['highLevel']-neighbor['lowLevel'])*max(0,min(1,progress))
        return levels.get((math.floor(x),math.floor(z)),0)

    along_z = ramp['direction'] in ('north','south')
    negative_high = ramp['direction'] in ('north','west')
    boundaries = [value for neighbor in ramps for value in
                  ((neighbor['x'],neighbor['x']+neighbor['width']) if along_z else
                   (neighbor['z'],neighbor['z']+neighbor['depth']))]
    for nx,nz,px,pz in ramp_landing_points(ramp,boundaries):
        if min(nx,nz)<0 or px>=width or pz>=depth:
            return False
        if (math.floor(nx),math.floor(nz)) not in levels or (math.floor(px),math.floor(pz)) not in levels:
            return False
        if abs(level_at(nx,nz)-(ramp['highLevel'] if negative_high else ramp['lowLevel']))>.0001:
            return False
        if abs(level_at(px,pz)-(ramp['lowLevel'] if negative_high else ramp['highLevel']))>.0001:
            return False
    return True


def ramp_passage_width(ramp):
    return ramp['width'] if ramp['direction'] in ('north', 'south') else ramp['depth']


def apply_source_support_corridors(city, ground, origin, width, depth, nav, nav_evidence,
                                  surfaces, textures, provenance):
    policy = city.get('nativeSupport')
    if policy is None:
        return ground, nav, nav_evidence
    if policy['kind'] != 'opaque_source_corridors':
        raise ValueError('Unknown source support policy')
    if len(origin) != 3 or len(policy['expectedOrigin']) != 3 or any(
            abs(a-b) > .000001 for a, b in zip(origin, policy['expectedOrigin'])):
        raise ValueError('Source support origin changed')
    if not policy['sourceEvidence'] or any(provenance.get(key) != value
            for key, value in policy['sourceEvidence'].items()):
        raise ValueError('Source support provenance changed')
    from PIL import Image
    images = {}
    for name in {surface.texture for surface in surfaces if surface.material == policy['material']}:
        with Image.open(BytesIO(textures[name])) as image:
            images[name] = image.convert('RGBA')
    levels = dict(ground['levels'])
    supplemental, supports, bands = [], {}, []
    step, offset = ground['levelHeight'], ground['offsetY']
    if not math.isfinite(step) or step <= 0 or not math.isfinite(offset):
        raise ValueError('Source support height configuration is invalid')
    for corridor in policy['corridors']:
        bounds = corridor['sourceBounds']
        if len(bounds) != 4 or not all(math.isfinite(value) for value in bounds):
            raise ValueError('Source support bounds are invalid')
        native = [bounds[0]-origin[0], bounds[1]-origin[2],
                  bounds[2]-origin[0], bounds[3]-origin[2]]
        if any(abs(value-round(value)) > .000001 for value in native):
            raise ValueError('Source support bounds must follow native cells')
        left, top, right, bottom = [round(value) for value in native]
        if not (0 <= left < right <= width and 0 <= top < bottom <= depth):
            raise ValueError('Source support bounds are outside the map')
        direction = corridor['direction']
        if direction not in ('north', 'south', 'east', 'west'):
            raise ValueError('Source support direction is invalid')
        selected = [surface for surface in surfaces if surface.terrain
                    and surface.material == policy['material']
                    and surface.group == corridor['group']
                    and surface.geometry == corridor['geometry']]
        if not selected:
            raise ValueError('Source support surface identity is absent')
        entries = cell_triangles(selected, origin, width, depth)

        def hit_at(x, z):
            hits = []
            for surface, triangle in entries.get((math.floor(x), math.floor(z)), []):
                weights = barycentric(x+origin[0], z+origin[2], triangle)
                if weights is not None:
                    alpha = pixel_of(surface, triangle, weights, images)[3]
                    if alpha >= 128:
                        hits.append((interpolate(triangle, weights, 1), triangle, alpha))
            if not hits:
                raise ValueError('Source support has no opaque source surface')
            hit = max(hits, key=lambda entry: entry[0])
            if hit[2] != 255:
                raise ValueError('Source support is not fully opaque')
            return hit

        center_x, center_z = (left+right)/2, (top+bottom)/2
        _, triangle, _ = hit_at(center_x, center_z)
        a, b, c = triangle
        determinant = (b[0]-a[0])*(c[2]-a[2])-(c[0]-a[0])*(b[2]-a[2])
        if abs(determinant) < 1e-8:
            raise ValueError('Source support plane is vertical')
        gradient_x = ((b[1]-a[1])*(c[2]-a[2])-(c[1]-a[1])*(b[2]-a[2]))/determinant
        gradient_z = ((b[0]-a[0])*(c[1]-a[1])-(c[0]-a[0])*(b[1]-a[1]))/determinant
        intercept = a[1]-gradient_x*a[0]-gradient_z*a[2]
        along_z = direction in ('north', 'south')
        if abs(gradient_x if along_z else gradient_z) > .000001:
            raise ValueError('Source support plane is not aligned with its corridor')
        start_x, start_z = (center_x, top) if along_z else (left, center_z)
        stop_x, stop_z = (center_x, bottom) if along_z else (right, center_z)
        heights = [gradient_x*(x+origin[0])+gradient_z*(z+origin[2])+intercept+offset
                   for x, z in ((start_x, start_z), (stop_x, stop_z))]
        negative, positive = [round(height/step) for height in heights]
        high, low = max(negative, positive), min(negative, positive)
        if low < 0 or high > 32 or high == low or ((negative > positive) != (direction in ('north', 'west'))):
            raise ValueError('Source support plane does not match its native direction or levels')
        ramp = {'id': corridor['id'], 'x': left, 'z': top, 'width': right-left,
                'depth': bottom-top, 'direction': direction, 'lowLevel': low, 'highLevel': high}
        errors = []
        for z in range(top, bottom):
            for x in range(left, right):
                if (x, z) in supports:
                    raise ValueError('Source support corridors overlap')
                level = round((hit_at(x+.5, z+.5)[0]+offset)/step)
                if not 0 <= level <= 32:
                    raise ValueError('Source support center level is outside native bounds')
                supports[x, z] = level
                for iy in range(16):
                    for ix in range(16):
                        px, pz = x+(ix+.5)/16, z+(iy+.5)/16
                        source_height = hit_at(px, pz)[0]+offset
                        progress = ((pz-top)/(bottom-top) if along_z else (px-left)/(right-left))
                        if direction in ('north', 'west'):
                            progress = 1-progress
                        native_height = (low+(high-low)*progress)*step
                        errors.append(abs(native_height-source_height))
        if max(errors) > .250001:
            raise ValueError('Source support source height error exceeds one native step')
        supplemental.append(ramp)
        bands.append({'rampId': ramp['id'], 'sourceGroup': corridor['group'],
                      'sourceGeometry': corridor['geometry'], 'material': policy['material'],
                      'sourceBounds': bounds, 'sourcePlane': [gradient_x, gradient_z, intercept],
                      'opaqueSamples': len(errors), 'maxSourceHeightError': max(errors)})
    if not supplemental:
        raise ValueError('Source support policy has no corridors')
    ramps = nav['ramps']+supplemental
    if len(ramps) > 256 or len({ramp['id'] for ramp in ramps}) != len(ramps):
        raise ValueError('Source support ramp identities or native count are invalid')
    for index, ramp in enumerate(ramps):
        for other in ramps[index+1:]:
            if (ramp['x'] < other['x']+other['width'] and ramp['x']+ramp['width'] > other['x']
                    and ramp['z'] < other['z']+other['depth'] and ramp['z']+ramp['depth'] > other['z']):
                raise ValueError('Source support ramps overlap')
    levels.update(supports)
    if not all(ramp_contacts_valid(ramp, ramps, levels, width, depth) for ramp in ramps):
        raise ValueError('Source support ramp contacts are invalid')
    blocked = {(x, z) for area in nav['blockedAreas']
               for z in range(area['z'], area['z']+area['depth'])
               for x in range(area['x'], area['x']+area['width'])}
    removed = blocked & supports.keys()
    blocked -= supports.keys()
    areas = union_rectangles(blocked)
    if len(areas) > 4096:
        raise ValueError('Source support collision rectangles exceed native bounds')
    walkable = set(levels)-blocked
    remaining, components = set(walkable), []
    while remaining:
        component = connected_cells(walkable, levels, min(remaining))
        components.append(component)
        remaining -= component
    evidence = {'kind': policy['kind'], 'sourceEvidence': policy['sourceEvidence'],
                'bands': bands, 'opaqueSamples': sum(band['opaqueSamples'] for band in bands),
                'maxSourceHeightError': max(band['maxSourceHeightError'] for band in bands),
                'changedLevels': [{'x': x, 'z': z, 'level': level} for (x, z), level in sorted(supports.items())
                                  if ground['levels'].get((x, z), 0) != level],
                'newFloorSupportCells': len(supports.keys()-ground['levels'].keys()),
                'removedBlockedCells': [list(cell) for cell in sorted(removed)],
                'proofLimit': policy['proofLimit']}
    return ({**ground, 'levels': levels}, {**nav, 'ramps': ramps, 'blockedAreas': areas},
            {**nav_evidence, 'walkableCells': len(walkable), 'blockedCells': len(blocked),
             'largestFlatComponentCells': max(map(len, components)), 'flatComponents': len(components),
             'sourceSupport': evidence})


def write_glb(path, entries, textures):
    surfaces, images, samplers, double_sided, opacity = defaultdict(list), {}, {}, {}, {}
    for surface, triangle in entries:
        key = surface.texture + f'@{surface.opacity:.7f}@' + '-'.join(surface.wraps)
        surfaces[key].extend(triangle)
        images[key] = textures[surface.texture]
        samplers[key], double_sided[key], opacity[key] = surface.wraps, True, surface.opacity
    result = {'surfaces': dict(surfaces), 'textures': images, 'samplers': samplers, 'doubleSided': double_sided,
              'sourceTriangleCount': len(entries), 'outputTriangleCount': len(entries),
              'shadedTriangleCount': sum(any(abs(value-1)>1e-6 for vertex in triangle for value in vertex[5:8]) for _,triangle in entries)}
    info = emit_model(path, result)
    data = path.read_bytes()
    json_length = struct.unpack_from('<I', data, 12)[0]
    document = json.loads(data[20:20+json_length].rstrip(b' \0'))
    binary = data[20+json_length+8:]
    for material, key in zip(document['materials'], sorted(result['surfaces'])):
        if opacity[key] < .99999:
            material['alphaMode'] = 'BLEND'
            material.pop('alphaCutoff', None)
            material['pbrMetallicRoughness']['baseColorFactor'] = [1, 1, 1, opacity[key]]
    document['meshes'][0]['primitives'].sort(key=lambda primitive: document['materials'][primitive['material']].get('alphaMode') == 'BLEND')
    payload = json.dumps(document, separators=(',', ':')).encode()
    payload += b' ' * (-len(payload) % 4)
    binary += b'\0' * (-len(binary) % 4)
    output = struct.pack('<III', 0x46546C67, 2, 12+8+len(payload)+8+len(binary)) + struct.pack('<I4s', len(payload), b'JSON') + payload + struct.pack('<I4s', len(binary), b'BIN\0') + binary
    path.write_bytes(output)
    info['sha256'], info['byteLength'] = sha256(output).hexdigest(), len(output)
    return info


def residual_groups(city, surfaces, origin):
    objects, residual, omitted = defaultdict(list), defaultdict(list), []
    for surface in surfaces:
        if any(word in surface.material.lower() for word in ('kisetu_yuki', 'ochiba', 'bc_kumo')):
            omitted.append({'geometry': surface.geometry, 'material': surface.material, 'reason': 'Seasonal or sky overlay outside the chosen summer layout'})
            continue
        selected = []
        for triangle in surface.triangles:
            if ground_triangle(city, surface, triangle):
                continue
            if floor_kind(city, surface) is not None and any(word in surface.material.lower() for word in ('gake', 'futa')) and not is_water(surface):
                continue
            selected.append((surface, triangle))
        if not selected:
            continue
        if not surface.terrain:
            objects[surface.group].extend(selected)
        else:
            residual[category(surface)].extend(selected)
    result = [(key, 'object', entries) for key, entries in sorted(objects.items())]
    for kind, entries in sorted(residual.items()):
        if kind in ('building', 'stairs'):
            for index, component in enumerate(component_triangles(entries)):
                result.append((kind+f'-{index:03d}', kind, component))
        else:
            side = city.get('residualChunkSizes', {}).get(kind, 16 if kind == 'water' else 8)
            if not isinstance(side, int) or isinstance(side, bool) or not 1 <= side <= 32:
                raise ValueError('A residual chunk side must be an integer between 1 and 32')
            for (x,z), component in clip_entries(entries, side, origin):
                result.append((kind+f'-{x}-{z}', kind, component))
    return result, omitted


def build_models(city, surfaces, textures, origin, ground, folder):
    groups, omitted = residual_groups(city, surfaces, origin)
    placement_heights = ground.get('placementHeights', ground['sourceHeights'])
    models, instances, object_footprints, obstacle_entries, stair_entries = [], [], [], [], []
    by_digest = {}
    model_folder = folder / 'models'
    model_folder.mkdir(exist_ok=True)
    for index, (source_group, kind, entries) in enumerate(groups):
        if len(entries) > 60000:
            raise ValueError('A modular source group exceeds the triangle budget')
        path = model_folder / f'{index:04d}-{kind}.glb'
        info = write_glb(path, entries, textures)
        if info['sha256'] in by_digest:
            model_id = by_digest[info['sha256']]
            path.unlink()
        else:
            model_id = f'unys-{city["id"]}-{kind}-{index:04d}'
            by_digest[info['sha256']] = model_id
            label = source_group.rsplit('/',1)[-1].replace('object_', '').replace('_',' ')
            models.append({'modelId': model_id, 'name': city['name']+' · '+label, 'path': str(path),
                           'mediaType': 'model/gltf-binary', 'sha256': info['sha256'], 'sourceGroup': source_group, 'kind': kind,
                           'triangleCount': len(entries), 'sourceAnchorCells': info['sourceAnchorCells']})
        anchor = info['sourceAnchorCells']
        source_cell = (math.floor(anchor[0]-origin[0]), math.floor(anchor[2]-origin[2]))
        height_adjustment = 0
        if source_cell in placement_heights and kind != 'water':
            height_adjustment = ground['levels'][source_cell]*ground['levelHeight']-ground['offsetY']-placement_heights[source_cell]
        if kind == 'forest' and any(any(word in surface.material.lower() for word in ('ki02c','ki04c')) for surface,_ in entries):
            root_bounds = entries_bounds([(surface,triangle) for surface,triangle in entries if any(word in surface.material.lower() for word in ('ki02c','ki04c'))])
            gaps = [anchor[1]-height for (x,z),height in placement_heights.items()
                    if root_bounds[0] <= x+.5+origin[0] <= root_bounds[3] and root_bounds[2] <= z+.5+origin[2] <= root_bounds[5]
                    and 0 <= anchor[1]-height < .3]
            if gaps:
                height_adjustment -= min(gaps)
        instance = {'id': f'unys-{city["id"]}-instance-{index:04d}', 'modelId': model_id,
                    'position': {'x': anchor[0]-origin[0], 'y': anchor[1]+ground['offsetY']+height_adjustment, 'z': anchor[2]-origin[2]},
                    'rotationDegrees': 0, 'scale': 1, 'blocksMovement': False}
        instances.append(instance)
        if kind == 'stairs':
            stair_entries.extend(entries)
        elif kind not in ('water', 'forest'):
            obstacle_entries.extend(entries)
        if kind == 'object':
            bounds = entries_bounds(entries)
            name = source_group.lower()
            if any(word in name for word in ('house', 'pc_01', 'shop', 'gym', 'center', 'tower', 'ctower', 't01_', 't02_')):
                object_footprints.append(bounds)
    return models, instances, object_footprints, obstacle_entries, stair_entries, omitted


def navigation(ground, origin, width, depth, object_footprints, obstacle_entries, stair_entries, forest_surfaces=None, textures=None, ramp_omissions=None):
    from city_geometry import cell_triangles, connected_cells
    placement_heights = ground.get('placementHeights', ground['sourceHeights'])
    floor_cells = set(ground['levels'])
    blocked = {(x,z) for z in range(depth) for x in range(width)} - floor_cells
    if forest_surfaces and textures:
        from io import BytesIO
        from PIL import Image
        from city_ground import pixel_of
        from city_geometry import cell_triangles
        roots = [surface for surface in forest_surfaces if any(word in surface.material.lower() for word in ('ki02c','ki04c'))]
        root_images = {surface.texture:Image.open(BytesIO(textures[surface.texture])).convert('RGBA') for surface in roots}
        root_cells = cell_triangles(roots,origin,width,depth)
        for cell,entries in root_cells.items():
            if cell not in placement_heights:
                continue
            x,z = cell
            for surface,triangle in entries:
                weights = barycentric(x+.5+origin[0],z+.5+origin[2],triangle)
                if weights is not None and abs(interpolate(triangle,weights,1)-placement_heights[cell]) < .35 and pixel_of(surface,triangle,weights,root_images)[3] >= 128:
                    blocked.add(cell)
                    break
    for bounds in object_footprints:
        inset = min(.75, (bounds[3]-bounds[0])/5, (bounds[5]-bounds[2])/5)
        for z in range(max(0, math.floor(bounds[2]-origin[2]+inset)), min(depth, math.ceil(bounds[5]-origin[2]-inset))):
            for x in range(max(0, math.floor(bounds[0]-origin[0]+inset)), min(width, math.ceil(bounds[3]-origin[0]-inset))):
                if bounds[0]+inset <= x+.5+origin[0] <= bounds[3]-inset and bounds[2]+inset <= z+.5+origin[2] <= bounds[5]-inset:
                    blocked.add((x,z))
    for surface, triangle in obstacle_entries:
        name = surface.material.lower()
        if any(word in name for word in ('hana', 'kusa', 'h_')):
            continue
        bounds = entries_bounds([(surface,triangle)])
        if bounds[4]-bounds[1] < .35:
            continue
        for z in range(max(0, math.floor(bounds[2]-origin[2]-.15)), min(depth, math.ceil(bounds[5]-origin[2]+.15))):
            for x in range(max(0, math.floor(bounds[0]-origin[0]-.15)), min(width, math.ceil(bounds[3]-origin[0]+.15))):
                cell = x,z
                if cell not in placement_heights:
                    continue
                height = placement_heights[cell]
                if bounds[1] > height+.7 or bounds[4] < height+.25:
                    continue
                point_x, point_z = x+.5+origin[0], z+.5+origin[2]
                weights = barycentric(point_x, point_z, triangle)
                if weights is not None:
                    y = interpolate(triangle, weights, 1)
                    if height+.15 < y < height+1.2:
                        blocked.add(cell)
                elif bounds[0]-.15 <= point_x <= bounds[3]+.15 and bounds[2]-.15 <= point_z <= bounds[5]+.15 and (bounds[3]-bounds[0] < .25 or bounds[5]-bounds[2] < .25):
                    blocked.add(cell)
    ramps, omitted_ramps, decorative_stairs = [], [], []
    source_omissions, matched_omissions = ramp_omissions or [], set()
    for index, component in enumerate(component_triangles(stair_entries)):
        bounds = entries_bounds(component)
        if bounds[4]-bounds[1] < .2:
            continue
        vertices = [v for _,tri in component for v in tri]
        low = [v for v in vertices if v[1] <= bounds[1]+.13]
        high = [v for v in vertices if v[1] >= bounds[4]-.13]
        if not low or not high:
            continue
        delta_x = sum(v[0] for v in high)/len(high)-sum(v[0] for v in low)/len(low)
        delta_z = sum(v[2] for v in high)/len(high)-sum(v[2] for v in low)/len(low)
        direction = ('east' if delta_x>0 else 'west') if abs(delta_x)>abs(delta_z) else ('south' if delta_z>0 else 'north')
        x, z = bounds[0]-origin[0], bounds[2]-origin[2]
        ramp_width, ramp_depth = max(.25,bounds[3]-bounds[0]), max(.25,bounds[5]-bounds[2])
        low_level = max(0,round((bounds[1]+ground['offsetY'])/ground['levelHeight']))
        high_level = max(0,round((bounds[4]+ground['offsetY'])/ground['levelHeight']))
        if high_level <= low_level or high_level > 32:
            continue
        if not (0 <= x and 0 <= z and x+ramp_width <= width and z+ramp_depth <= depth):
            continue
        candidate = {'id':f'ramp-{index}', 'x':x, 'z':z, 'width':ramp_width, 'depth':ramp_depth,
                     'direction':direction, 'lowLevel':low_level, 'highLevel':high_level}
        omitted = False
        for omission_index, omission in enumerate(source_omissions):
            if not all((surface.group, surface.geometry, surface.material) ==
                       (omission['group'], omission['geometry'], omission['material']) for surface, _ in component):
                continue
            expected_bounds = omission['sourceBounds']
            if len(expected_bounds) != 6:
                raise ValueError('Native ramp omission no longer matches the inspected source component')
            if any(abs(actual-expected) > 1e-6 for actual, expected in zip(bounds, expected_bounds)):
                continue
            if omission_index in matched_omissions or len(component) != omission['triangleCount']:
                raise ValueError('Native ramp omission no longer matches the inspected source component')
            matched_omissions.add(omission_index)
            omitted_ramps.append({'candidate':candidate,'reason':omission['reason'],'sourceComponent':omission})
            omitted = True
            break
        if omitted:
            continue
        if ramp_passage_width(candidate) < .5:
            decorative_stairs.append({'candidate':candidate,'reason':'Stair side is narrower than a half-cell passage across the ascent'})
            continue
        ramp = fit_ramp_contacts(candidate,ground['levels'],width,depth,ground['levelHeight'],
                                 (bounds[1]+ground['offsetY'],bounds[4]+ground['offsetY']))
        if ramp is None:
            omitted_ramps.append({'candidate':candidate,'reason':'No two uniform native terrain contacts at the decorative mesh bounds'})
            continue
        ramps.append(ramp)
    if len(matched_omissions) != len(source_omissions):
        raise ValueError('Native ramp omission is absent from the inspected source stair components')
    prioritized = sorted(ramps,key=lambda ramp:(-ramp_passage_width(ramp),-ramp['width']*ramp['depth'],ramp['id']))
    ramps = []
    for ramp in prioritized:
        neighbors = ramps+[ramp]
        if not all(ramp_contacts_valid(neighbor,neighbors,ground['levels'],width,depth) for neighbor in neighbors):
            omitted_ramps.append({'candidate':ramp,'reason':'Ramp contacts intersect another ramp at a different native height'})
            continue
        ramps.append(ramp)
    for ramp in ramps:
        for cz in range(math.floor(ramp['z']), math.ceil(ramp['z']+ramp['depth'])):
            for cx in range(math.floor(ramp['x']), math.ceil(ramp['x']+ramp['width'])):
                blocked.discard((cx,cz))
    walkable = floor_cells-blocked
    if not walkable:
        raise ValueError('No traversable native floor after authored collision')
    remaining, components = set(walkable), []
    while remaining:
        start = min(remaining, key=lambda p: (p[1],p[0]))
        connected = connected_cells(walkable, ground['levels'], start)
        components.append(connected)
        remaining -= connected
    largest = max(components, key=len)
    center = width/2, depth/2
    spawn = min(largest, key=lambda p: (p[0]-center[0])**2+(p[1]-center[1])**2)
    return ({'spawn': {'x':spawn[0]+.5,'z':spawn[1]+.5}, 'allowDiagonalMovement':False,
             'ramps':ramps, 'blockedAreas':union_rectangles(blocked)},
            {'walkableCells':len(walkable),'largestFlatComponentCells':len(largest),'flatComponents':len(components),'blockedCells':len(blocked),
             'omittedRampCandidates':omitted_ramps,'decorativeStairComponents':decorative_stairs})

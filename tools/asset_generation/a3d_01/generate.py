import argparse
from collections import defaultdict
from hashlib import sha256
from io import BytesIO
import json
import math
from pathlib import Path
import random
import struct
import sys

from PIL import Image, ImageDraw


REPOSITORY = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPOSITORY / 'tools' / 'scripts'))
from convert_source_asset_pack import emit_model


def clamp(value, low=0, high=255):
    return max(low, min(high, value))


def png_bytes(image):
    stream = BytesIO()
    image.save(stream, format='PNG', optimize=False, compress_level=9)
    return stream.getvalue()


def texture(kind, rgb, size, seed):
    rng = random.Random(seed)
    image = Image.new('RGB', (size, size))
    pixels = image.load()
    for y in range(size):
        for x in range(size):
            noise = rng.randrange(-3, 4)
            if kind == 'wood':
                noise += round(5 * math.sin(x * .23 + 1.4 * math.sin(y * .055)))
            elif kind == 'roof':
                noise += round(5 * math.cos(x / size * 2 * math.pi))
            elif kind == 'glass':
                noise = round(8 * (1 - y / size))
            pixels[x, y] = tuple(clamp(c + noise) for c in rgb)
    draw = ImageDraw.Draw(image)
    if kind == 'wood':
        for x in range(10, size, 23):
            draw.line([(x, 0), (x + 2, size // 3), (x - 1, size)], fill=tuple(clamp(c - 14) for c in rgb), width=1)
    if kind == 'plaster':
        for _ in range(28):
            x, y = rng.randrange(size), rng.randrange(size)
            draw.ellipse((x, y, x + rng.randrange(2, 7), y + 1), fill=tuple(clamp(c - 6) for c in rgb))
    if kind == 'roof':
        draw.line((0, size - 3, size, size - 3), fill=tuple(clamp(c - 17) for c in rgb), width=3)
        draw.line((0, 1, size, 1), fill=tuple(clamp(c + 8) for c in rgb), width=1)
    if kind == 'foliage':
        for _ in range(145):
            x, y = rng.randrange(-8, size), rng.randrange(-8, size)
            width, height = rng.randrange(5, 13), rng.randrange(3, 9)
            delta = rng.choice([-14, -9, 7, 13, 20])
            draw.polygon([(x, y + height / 2), (x + width / 3, y), (x + width, y + height / 3), (x + width * .75, y + height), (x + width * .2, y + height)], fill=tuple(clamp(c + delta) for c in rgb))
    return png_bytes(image)


class Mesh:
    def __init__(self):
        self.surfaces = defaultdict(list)

    def triangle(self, material, a, b, c, uv=None, color=(1, 1, 1)):
        if len(color) != 3 or any(not math.isfinite(value) or not 0 <= value <= 1 for value in color):
            raise ValueError('Vertex colors must be finite values between zero and one')
        uv = uv or [(0, 1), (1, 1), (.5, 0)]
        for point, texel in zip((a, b, c), uv):
            self.surfaces[material].append([*point, *texel, *color])

    def quad(self, material, a, b, c, d, color=(1, 1, 1), uv=None):
        uv = uv or [(0, 1), (1, 1), (1, 0), (0, 0)]
        self.triangle(material, a, b, c, uv[:3], color)
        self.triangle(material, a, c, d, [uv[0], uv[2], uv[3]], color)

    def box(self, material, bounds, color=(1, 1, 1), omit=()):
        x0, y0, z0, x1, y1, z1 = bounds
        faces = {
            'front': [(x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)],
            'back': [(x1, y0, z0), (x0, y0, z0), (x0, y1, z0), (x1, y1, z0)],
            'left': [(x0, y0, z0), (x0, y0, z1), (x0, y1, z1), (x0, y1, z0)],
            'right': [(x1, y0, z1), (x1, y0, z0), (x1, y1, z0), (x1, y1, z1)],
            'top': [(x0, y1, z1), (x1, y1, z1), (x1, y1, z0), (x0, y1, z0)],
            'bottom': [(x0, y0, z0), (x1, y0, z0), (x1, y0, z1), (x0, y0, z1)],
        }
        for name, points in faces.items():
            if name not in omit:
                self.quad(material, *points, color=color)

    def beam(self, material, start, end, radius0, radius1, segments=6):
        direction = [end[i] - start[i] for i in range(3)]
        length = math.sqrt(sum(v * v for v in direction))
        axis = [v / length for v in direction]
        reference = (1, 0, 0) if abs(axis[0]) < .8 else (0, 0, 1)
        u = [axis[1] * reference[2] - axis[2] * reference[1], axis[2] * reference[0] - axis[0] * reference[2], axis[0] * reference[1] - axis[1] * reference[0]]
        magnitude = math.sqrt(sum(v * v for v in u))
        u = [v / magnitude for v in u]
        v = [axis[1] * u[2] - axis[2] * u[1], axis[2] * u[0] - axis[0] * u[2], axis[0] * u[1] - axis[1] * u[0]]
        rings = []
        for center, radius in ((start, radius0), (end, radius1)):
            rings.append([tuple(center[k] + radius * (u[k] * math.cos(i * math.tau / segments) + v[k] * math.sin(i * math.tau / segments)) for k in range(3)) for i in range(segments)])
        for i in range(segments):
            j = (i + 1) % segments
            self.quad(material, rings[0][i], rings[0][j], rings[1][j], rings[1][i])
            self.triangle(material, end, rings[1][i], rings[1][j])
            self.triangle(material, start, rings[0][j], rings[0][i])


def roof(mesh, xmin, xmax, ridge_z, ridge_y, end_z, end_y, columns, rows, thickness=.12):
    front = end_z > ridge_z
    for col in range(columns):
        x0 = xmin + (xmax - xmin) * col / columns
        x1 = xmin + (xmax - xmin) * (col + 1) / columns
        for row in range(rows):
            t0, t1 = row / rows, (row + 1) / rows
            z0, z1 = ridge_z + (end_z - ridge_z) * t0, ridge_z + (end_z - ridge_z) * t1
            y0, y1 = ridge_y + (end_y - ridge_y) * t0, ridge_y + (end_y - ridge_y) * t1
            tint = .946 + ((col * 7 + row * 3) % 7) * .009
            for section in range(3):
                u0, u1 = section / 3, (section + 1) / 3
                a, b = x0 + (x1 - x0) * u0, x0 + (x1 - x0) * u1
                bump0, bump1 = .047 * math.sin(u0 * math.pi), .047 * math.sin(u1 * math.pi)
                points = [(a, y0 + bump0, z0), (a, y1 + bump0, z1), (b, y1 + bump1, z1), (b, y0 + bump1, z0)]
                if not front:
                    points.reverse()
                mesh.quad('roof', *points, color=(tint, tint, tint))
                if row == rows - 1:
                    edge = [(a, y1 - thickness, z1), (b, y1 - thickness, z1), (b, y1 + bump1, z1), (a, y1 + bump0, z1)]
                    if not front:
                        edge.reverse()
                    mesh.quad('roof', *edge, color=(.88, .88, .88))
    underside = [(xmin, end_y - thickness, end_z), (xmin, ridge_y - thickness, ridge_z), (xmax, ridge_y - thickness, ridge_z), (xmax, end_y - thickness, end_z)]
    if not front:
        underside.reverse()
    mesh.quad('timber', *underside)
    for x, reverse in ((xmin, True), (xmax, False)):
        points = [(x, ridge_y - thickness, ridge_z), (x, end_y - thickness, end_z), (x, end_y, end_z), (x, ridge_y, ridge_z)]
        if reverse != front:
            points.reverse()
        mesh.quad('timber', *points)


def front_window(mesh, rect, z, mullion=True):
    x0, y0, x1, y1 = rect
    mesh.quad('h_mado', (x0, y0, z), (x1, y0, z), (x1, y1, z), (x0, y1, z))
    thickness = .065
    for bounds in [(x0 - thickness, y0 - thickness, z - .03, x0, y1 + thickness, z + .055), (x1, y0 - thickness, z - .03, x1 + thickness, y1 + thickness, z + .055), (x0, y0 - thickness, z - .03, x1, y0, z + .055), (x0, y1, z - .03, x1, y1 + thickness, z + .055)]:
        mesh.box('timber', bounds, omit=('back',))
    if mullion:
        x = (x0 + x1) / 2
        y = (y0 + y1) / 2
        mesh.box('timber', (x - .022, y0, z + .005, x + .022, y1, z + .058), omit=('back',))
        mesh.box('timber', (x0, y - .022, z + .005, x1, y + .022, z + .058), omit=('back',))


def house_mesh(parameters):
    mesh = Mesh()
    x0, y0, z0, x1, y1, front = parameters['wallBounds']
    left, bottom, recess, right, lintel, _ = parameters['doorOpening']
    mesh.box('plaster', (x0, y0, z0, x0 + .15, y1, front), omit=('bottom',))
    mesh.box('plaster', (x1 - .15, y0, z0, x1, y1, front), omit=('bottom',))
    mesh.box('plaster', (x0 + .15, y0, z0, x1 - .15, y1, z0 + .15), omit=('bottom',))
    mesh.box('plaster', (x0 + .15, y0, front - .15, left, y1, front), omit=('bottom',))
    mesh.box('plaster', (right, y0, front - .15, x1 - .15, y1, front), omit=('bottom',))
    mesh.box('plaster', (left, lintel, front - .15, right, y1, front))
    mesh.box('timber', (left - .09, bottom, recess, left, lintel + .1, front + .06), omit=('bottom',))
    mesh.box('timber', (right, bottom, recess, right + .09, lintel + .1, front + .06), omit=('bottom',))
    mesh.box('timber', (left, lintel, recess, right, lintel + .1, front + .06))
    mesh.quad('timber', (x0, y0 + .002, front), (x1, y0 + .002, front), (x1, y0 + .002, z0), (x0, y0 + .002, z0), color=(.7, .7, .7))
    for x in (x0 + .06, x1 - .06):
        mesh.box('timber', (x - .07, y0, front - .025, x + .07, y1 + .04, front + .11), omit=('bottom', 'back'))
        mesh.box('timber', (x - .07, y0, z0 - .045, x + .07, y1 + .04, z0 + .1), omit=('bottom', 'front'))
    for level, height in ((.34, .16), (2.26, .17), (3.83, .18)):
        if level < lintel:
            for a, b in ((x0, left - .09), (right + .09, x1)):
                mesh.box('timber', (a, level, front - .02, b, level + height, front + .07), omit=('back',))
        else:
            mesh.box('timber', (x0, level, front - .02, x1, level + height, front + .07), omit=('back',))
        mesh.box('timber', (x0 - .035, level, z0, x0 + .05, level + height, front), omit=('right',))
        mesh.box('timber', (x1 - .05, level, z0, x1 + .035, level + height, front), omit=('left',))
    for index, rectangle in enumerate(parameters['windows']):
        front_window(mesh, rectangle, 1.46875 if index < 2 else 1.4375)
    for x in (-1.35, 1.35):
        mesh.box('timber', (x - .055, 2.5, front, x + .055, 3.83, front + .055), omit=('back',))
    for side in (-1, 1):
        wallx = side * 2.49
        midz = -.32
        for y in (1.05, 2.93):
            points = [(wallx, y - .36, midz - .39), (wallx, y - .36, midz + .39), (wallx, y + .36, midz + .39), (wallx, y + .36, midz - .39)]
            if side > 0:
                points.reverse()
            mesh.quad('h_mado', *points)
            for z in (midz - .43, midz + .43):
                mesh.box('timber', (wallx - .055, y - .43, z - .035, wallx + .055, y + .43, z + .035))
            for level in (y - .4, y + .4, y):
                mesh.box('timber', (wallx - .06, level - .025, midz - .43, wallx + .06, level + .025, midz + .43))
    for side in (-1, 1):
        x = side * 2.45
        points = [(x, 3.94, z0), (x, 3.94, front), (x, parameters['roofRidgeY'] - .12, parameters['roofRidgeZ'])]
        if side > 0:
            points.reverse()
        mesh.triangle('plaster', *points)
    for endz in (-2.375, 2.125):
        roof(mesh, -2.875, 2.875, parameters['roofRidgeZ'], parameters['roofRidgeY'], endz, parameters['roofEaveY'], parameters['roofColumns'], parameters['roofRows'])
    roof(mesh, -2.49, 2.49, 1.39, 2.51, 2.02, 2.05, 12, 2, .085)
    mesh.beam('roof', (-2.875, 5.48, -.25), (2.875, 5.48, -.25), .135, .135, 8)
    return mesh


def crown(mesh, center, radius, segments, rings, rng, tint):
    points = []
    for ring in range(1, rings):
        theta = math.pi * ring / rings
        row = []
        for i in range(segments):
            phi = math.tau * i / segments + .10 * math.sin(ring * 2)
            variation = rng.uniform(.93, 1.015)
            row.append((center[0] + radius[0] * math.sin(theta) * math.cos(phi) * variation, center[1] + radius[1] * math.cos(theta) * variation, center[2] + radius[2] * math.sin(theta) * math.sin(phi) * variation))
        points.append(row)
    top, bottom = (center[0], center[1] + radius[1], center[2]), (center[0], center[1] - radius[1], center[2])
    for i in range(segments):
        j = (i + 1) % segments
        mesh.triangle('foliage', top, points[0][j], points[0][i], color=(tint, tint, tint))
        mesh.triangle('foliage', bottom, points[-1][i], points[-1][j], color=(tint * .92, tint * .92, tint * .92))
        for ring in range(len(points) - 1):
            shade = tint * (1 - ring * .025)
            mesh.quad('foliage', points[ring][i], points[ring][j], points[ring + 1][j], points[ring + 1][i], color=(shade, shade, shade))


def tree_mesh(parameters, seed):
    mesh = Mesh()
    rng = random.Random(seed)
    base, top = parameters['trunkBase'], parameters['trunkTop']
    mesh.beam('bark', base, top, parameters['trunkRadius'], .11, 7)
    for endpoint in ((-.65, 1.65, -1.34), (.69, 1.69, -1.30), (.07, 1.58, -.63)):
        mesh.beam('bark', (.03, .74, -1.24), endpoint, .10, .055, 5)
    for i in range(4):
        angle = math.tau * i / 4 + .25
        endpoint = (base[0] + .39 * math.cos(angle), .025, base[2] + .39 * math.sin(angle))
        mesh.beam('bark', (0, .24, base[2]), endpoint, .095, .025, 4)
    for vertex in mesh.surfaces['bark']:
        vertex[1] = max(0, vertex[1])
    for index, item in enumerate(parameters['crowns']):
        crown(mesh, item['center'], item['radius'], parameters['segments'], parameters['rings'], rng, min(1, .93 + index * .014))
    return mesh


def write_preserved_model(path, mesh, textures):
    result = {'surfaces': dict(mesh.surfaces), 'textures': textures, 'samplers': {name: ('CLAMP', 'CLAMP') for name in textures}, 'doubleSided': {name: False for name in textures}}
    receipt = emit_model(path, result)
    content = path.read_bytes()
    json_length = struct.unpack_from('<I', content, 12)[0]
    document = json.loads(content[20:20 + json_length])
    binary = bytearray(content[28 + json_length:])
    anchor = receipt['sourceAnchorCells']
    for primitive in document['meshes'][0]['primitives']:
        accessor = document['accessors'][primitive['attributes']['POSITION']]
        view = document['bufferViews'][accessor['bufferView']]
        start = view.get('byteOffset', 0) + accessor.get('byteOffset', 0)
        for index in range(accessor['count']):
            point = struct.unpack_from('<fff', binary, start + index * 12)
            struct.pack_into('<fff', binary, start + index * 12, *(point[axis] + anchor[axis] for axis in range(3)))
        values = [struct.unpack_from('<fff', binary, start + index * 12) for index in range(accessor['count'])]
        accessor['min'] = [min(point[axis] for point in values) for axis in range(3)]
        accessor['max'] = [max(point[axis] for point in values) for axis in range(3)]
    document['asset']['generator'] = 'Avelune A3D-01 native-coordinate asset recipe'
    encoded = json.dumps(document, separators=(',', ':')).encode()
    encoded += b' ' * (-len(encoded) % 4)
    length = 28 + len(encoded) + len(binary)
    path.write_bytes(struct.pack('<III', 0x46546C67, 2, length) + struct.pack('<II', len(encoded), 0x4E4F534A) + encoded + struct.pack('<II', len(binary), 0x004E4942) + binary)
    positions = [row[:3] for values in mesh.surfaces.values() for row in values]
    bounds = [min(row[axis] for row in positions) for axis in range(3)] + [max(row[axis] for row in positions) for axis in range(3)]
    return {**receipt, 'sha256': sha256(path.read_bytes()).hexdigest(), 'sizeBytes': path.stat().st_size, 'bounds': bounds, 'dimensions': [bounds[axis + 3] - bounds[axis] for axis in range(3)], 'materialCount': len(mesh.surfaces), 'materials': sorted(mesh.surfaces), 'exportAnchorRestored': anchor, 'pivot': [0, 0, 0], 'normalMode': 'flat geometric face normals', 'alphaMode': 'OPAQUE', 'textures': [{'material': name, 'file': f'{path.stem}_{name}.png', 'sha256': sha256(data).hexdigest(), 'sizeBytes': len(data), 'dimensions': list(Image.open(BytesIO(data)).size)} for name, data in sorted(textures.items())]}


def validate_parameters(parameters):
    if parameters.get('schemaVersion') != 1 or type(parameters.get('seed')) is not int:
        raise ValueError('Expected schemaVersion 1 and an integer seed')
    filenames = []
    for name in ('house', 'tree'):
        configuration = parameters.get(name)
        if not isinstance(configuration, dict):
            raise ValueError(f'Missing {name} parameters')
        filename = configuration.get('file')
        if not isinstance(filename, str) or Path(filename).name != filename or not filename.endswith('.glb') or filename in filenames:
            raise ValueError('Model filenames must be unique plain GLB names')
        filenames.append(filename)
        size = configuration.get('textureSize')
        if type(size) is not int or not 1 <= size <= 512:
            raise ValueError('Texture dimensions must be between 1 and 512')
        for key, value in configuration.items():
            if key.endswith('Rgb') and (not isinstance(value, list) or len(value) != 3 or any(type(component) is not int or not 0 <= component <= 255 for component in value)):
                raise ValueError(f'Invalid RGB color: {key}')
        bounds = configuration.get('allowedBounds')
        validate_coordinates(bounds, 6)
        if any(bounds[axis] >= bounds[axis + 3] for axis in range(3)):
            raise ValueError('Allowed bounds must have positive dimensions')
    house, tree = parameters['house'], parameters['tree']
    for key in ('wallBounds', 'doorOpening'):
        values = house.get(key)
        validate_coordinates(values, 6)
        if any(values[axis] >= values[axis + 3] for axis in range(3)):
            raise ValueError(f'{key} must have positive dimensions')
    for key in ('roofRidgeY', 'roofEaveY', 'roofRidgeZ'):
        validate_coordinates([house.get(key)], 1)
    for key, maximum in (('roofColumns', 32), ('roofRows', 16)):
        if type(house.get(key)) is not int or not 1 <= house[key] <= maximum:
            raise ValueError(f'Invalid {key}')
    if not isinstance(house.get('windows'), list) or len(house['windows']) != 4:
        raise ValueError('The source contract requires four front windows')
    for rectangle in house['windows']:
        validate_coordinates(rectangle, 4)
        if rectangle[0] >= rectangle[2] or rectangle[1] >= rectangle[3]:
            raise ValueError('Window rectangles must have positive dimensions')
    for key in ('trunkBase', 'trunkTop'):
        validate_coordinates(tree.get(key), 3)
    validate_coordinates([tree.get('trunkRadius')], 1)
    if tree['trunkRadius'] <= 0 or tree['trunkBase'] == tree['trunkTop']:
        raise ValueError('Trunk must have positive radius and length')
    for key, minimum, maximum in (('segments', 3, 16), ('rings', 2, 8)):
        if type(tree.get(key)) is not int or not minimum <= tree[key] <= maximum:
            raise ValueError(f'Invalid {key}')
    if not isinstance(tree.get('crowns'), list) or not 3 <= len(tree['crowns']) <= 8:
        raise ValueError('Expected three to eight foliage masses')
    for crown_parameters in tree['crowns']:
        validate_coordinates(crown_parameters.get('center'), 3)
        validate_coordinates(crown_parameters.get('radius'), 3)
        if any(value <= 0 for value in crown_parameters['radius']):
            raise ValueError('Crown radii must be positive')


def validate_coordinates(values, count):
    if not isinstance(values, list) or len(values) != count or any(type(value) not in (int, float) or not math.isfinite(value) for value in values):
        raise ValueError(f'Expected {count} finite coordinates')


def generate(parameters, output):
    validate_parameters(parameters)
    output = Path(output)
    house = parameters['house']
    tree = parameters['tree']
    seed = parameters['seed']
    house_textures = {name: texture(kind, house[rgb], house['textureSize'], seed + index) for index, (name, kind, rgb) in enumerate([('plaster', 'plaster', 'plasterRgb'), ('timber', 'wood', 'timberRgb'), ('roof', 'roof', 'roofRgb'), ('h_mado', 'glass', 'glassRgb')])}
    tree_textures = {name: texture(kind, tree[rgb], tree['textureSize'], seed + index + 100) for index, (name, kind, rgb) in enumerate([('bark', 'wood', 'barkRgb'), ('foliage', 'foliage', 'foliageRgb')])}
    prepared = ((house, house_mesh(house), house_textures), (tree, tree_mesh(tree, seed), tree_textures))
    for configuration, mesh, _ in prepared:
        positions = [vertex[:3] for surface in mesh.surfaces.values() for vertex in surface]
        if not positions:
            raise ValueError('Empty pilot geometry')
        bounds = [min(point[axis] for point in positions) for axis in range(3)]
        bounds += [max(point[axis] for point in positions) for axis in range(3)]
        limits = configuration['allowedBounds']
        if any(bounds[axis] < limits[axis] - 1e-6 or bounds[axis + 3] > limits[axis + 3] + 1e-6 for axis in range(3)):
            raise ValueError(f'{configuration["file"]} exceeds its native placement envelope: {bounds}')
        for surface in mesh.surfaces.values():
            if len(surface) % 3:
                raise ValueError('Incomplete triangle geometry')
            for vertex in surface:
                try:
                    converted = struct.unpack('<8f', struct.pack('<8f', *vertex))
                except (OverflowError, struct.error) as error:
                    raise ValueError('Nonfinite float32 geometry') from error
                if not all(math.isfinite(value) for value in converted):
                    raise ValueError('Nonfinite float32 geometry')
            for start in range(0, len(surface), 3):
                a, b, c = (vertex[:3] for vertex in surface[start:start + 3])
                u, v = ([b[axis] - a[axis] for axis in range(3)], [c[axis] - a[axis] for axis in range(3)])
                normal = [u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0]]
                if math.sqrt(sum(value * value for value in normal)) < 1e-8:
                    raise ValueError('Degenerate output geometry')
    output.mkdir(parents=True, exist_ok=True)
    assets = []
    for configuration, mesh, textures in prepared:
        destination = output / configuration['file']
        receipt = write_preserved_model(destination, mesh, textures)
        for name, data in textures.items():
            (output / f'{destination.stem}_{name}.png').write_bytes(data)
        assets.append(receipt)
    manifest = {'schemaVersion': 1, 'seed': seed, 'parametersSha256': sha256(json.dumps(parameters, sort_keys=True, separators=(',', ':')).encode()).hexdigest(), 'assets': assets}
    (output / 'assets.json').write_text(json.dumps(manifest, indent=2) + '\n')
    return manifest


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--parameters', type=Path, default=Path(__file__).with_name('parameters.json'))
    parser.add_argument('--output', type=Path, required=True)
    arguments = parser.parse_args()
    parameters = json.loads(arguments.parameters.read_text())
    print(json.dumps(generate(parameters, arguments.output), indent=2))


if __name__ == '__main__':
    main()

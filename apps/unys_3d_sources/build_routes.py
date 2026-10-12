import argparse
from copy import deepcopy
from hashlib import sha256
from pathlib import Path
import json
import subprocess
import sys
import xml.etree.ElementTree as ET
import zipfile

from PIL import Image

from build_cities import build_city, write_json
from city_geometry import NAMESPACE, Surface, source_scene
from convert_bw2_village_assets import clip_polygon, triangulate


ROOT = Path(__file__).resolve().parents[2]
NS = NAMESPACE['c']
ROUTES = [
    {'id': 'route-19', 'name': 'Route 19', 'sourceId': 'rom-route19', 'lot': 1, 'cityGroup': 'routes-depart'},
    {'id': 'route-20', 'name': 'Route 20', 'sourceId': '587546', 'lot': 1, 'cityGroup': 'routes-depart'},
]


def route_source(source_root, record):
    surfaces, textures, provenance = source_scene(source_root, record)
    if record['id'] != 'rom-route19':
        return surfaces, textures, provenance
    clipped = []
    for surface in surfaces:
        triangles = []
        for triangle in surface.triangles:
            polygon = clip_polygon(triangle, 0, -16, True)
            if len(polygon) >= 3:
                triangles.extend(triangulate(polygon))
        if triangles:
            clipped.append(Surface(surface.group, surface.geometry, surface.material, surface.texture,
                                   surface.wraps, surface.opacity, triangles, surface.terrain))
    return clipped, textures, {**provenance, 'sourceCrop': {'minX': -16,
        'reason': 'Exclude the Aspertia mountain landscape west of the Route 19 matrix sectors'}}


def combine_sectors(folder):
    ET.register_namespace('', NS)
    trees = [ET.parse(folder / (name + '.dae')).getroot() for name in ('map01_21', 'map02_21')]
    result = ET.Element('{' + NS + '}COLLADA', version='1.4.1')
    result.append(deepcopy(trees[0].find('c:asset', NAMESPACE)))
    libraries = {}
    visual = ET.Element('{' + NS + '}visual_scene', id='route19-scene', name='Route 19')
    omitted = []
    for index, tree in enumerate(trees):
        prefix = f'sector{index}-'
        names = {node.get('id'): prefix + node.get('id') for node in tree.iter() if node.get('id')}
        materials = {node.get('id'): node.get('name') for node in tree.findall('c:library_materials/c:material', NAMESPACE)}
        scene = tree.find('c:library_visual_scenes/c:visual_scene', NAMESPACE)
        bindings = {node.get('symbol'): materials[node.get('target')[1:]] for node in scene.findall('.//c:instance_material', NAMESPACE)}
        for mesh in tree.findall('c:library_geometries/c:geometry/c:mesh', NAMESPACE):
            for primitive in list(mesh):
                name = bindings.get(primitive.get('material'), '')
                if name.startswith('C12_') or name == 'c12_air':
                    omitted.append({'sector': index, 'material': name, 'reason': 'Aspertia mountain backdrop outside Route 19'})
                    mesh.remove(primitive)
        for node in tree.iter():
            for key, value in list(node.attrib.items()):
                if key == 'id':
                    node.set(key, names[value])
                elif value.startswith('#') and value[1:] in names:
                    node.set(key, '#' + names[value[1:]])
            if node.tag.endswith('}Name_array') and node.text:
                node.text = ' '.join(names.get(name, name) for name in node.text.split())
            elif node.tag.endswith('}skeleton') and node.text and node.text.strip().startswith('#'):
                node.text = '#' + names[node.text.strip()[1:]]
            elif node.tag.endswith('}init_from') and node.text and node.text.strip() in names:
                node.text = names[node.text.strip()]
        root = ET.SubElement(visual, '{' + NS + '}node', id=f'map-route19-{index}')
        ET.SubElement(root, '{' + NS + '}translate').text = f'{index * 512} 0 0'
        terrain = ET.SubElement(root, '{' + NS + '}node', id=f'terrain-route19-{index}')
        for node in list(scene):
            terrain.append(node)
        for library in tree:
            tag = library.tag.rsplit('}', 1)[-1]
            if tag in ('asset', 'scene', 'library_visual_scenes'):
                continue
            target = libraries.setdefault(tag, ET.Element(library.tag))
            for child in library:
                target.append(child)
    for library in libraries.values():
        result.append(library)
    container = ET.SubElement(result, '{' + NS + '}library_visual_scenes')
    container.append(visual)
    scene = ET.SubElement(result, '{' + NS + '}scene')
    ET.SubElement(scene, '{' + NS + '}instance_visual_scene', url='#route19-scene')
    return ET.tostring(result, encoding='utf-8', xml_declaration=True), omitted


def prepare_sources(project, corpus, nitro):
    evidence = project / '.pokemap/authoring/routes-19-20'
    output = evidence / 'sources'
    output.mkdir(parents=True, exist_ok=True)
    inventory = json.loads((nitro / 'animation-inventory.json').read_text())
    original = nitro / 'nitro-original'
    apicula = nitro / ('apicula-' + inventory['source']['tool_commit']) / 'target/release/apicula'
    folder = evidence / 'rom-route19-spring'
    sources = [original / 'map01_21.nsbmd', original / 'map02_21.nsbmd', original / 'dansa01a.205.nsbtx']
    decoded = subprocess.run([str(apicula), 'convert', *map(str, sources), '-o', str(folder), '-f', 'dae', '--overwrite'], capture_output=True, text=True)
    if decoded.returncode or 'matching texture' in decoded.stdout + decoded.stderr:
        raise ValueError(decoded.stdout + decoded.stderr)
    corpus_records = json.loads((corpus / 'manifest.json').read_text())['assets']
    aspertia = next(record for record in corpus_records if record['name'] == 'Aspertia City')
    surfaces, textures, _ = source_scene(corpus, aspertia)
    from io import BytesIO
    ground = next(surface for surface in surfaces if surface.material == 'grass01ax')
    expected = Image.open(BytesIO(textures[ground.texture])).convert('RGBA')
    actual = Image.open(folder / 'grass01ax.png').convert('RGBA')
    if expected.size != actual.size or expected.tobytes() != actual.tobytes():
        raise ValueError('Route 19 texture bank does not match the approved Aspertia ground')
    dae, omitted = combine_sectors(folder)
    archive = output / 'route19-rom.zip'
    with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED) as target:
        target.writestr('Route 19.dae', dae)
        for image in sorted(folder.glob('*.png')):
            target.write(image, image.name)
    route19 = {'id': 'rom-route19', 'name': 'Route 19 — original ROM sectors', 'local_path': archive.name,
               'sha256': sha256(archive.read_bytes()).hexdigest(),
               'page_url': 'https://www.pokebip.com/page/jeux-video/pokemon-noir-2-blanc-2/guide-des-lieux/route-19'}
    route20 = deepcopy(next(record for record in corpus_records if record['id'] == '587546'))
    source = corpus / route20['local_path']
    data = source.read_bytes()
    if sha256(data).hexdigest() != route20['sha256']:
        raise ValueError('Route 20 source archive digest changed')
    destination = output / source.name
    destination.write_bytes(data)
    route20['local_path'] = destination.name
    write_json(output / 'manifest.json', {'assets': [route19, route20]})
    write_json(evidence / 'route19-provenance.json', {'source': inventory['source'],
               'terrainSources': [{'path': str(source), 'sha256': sha256(source.read_bytes()).hexdigest()} for source in sources],
               'sectorOffsetsDsUnits': [[0, 0, 0], [512, 0, 0]],
               'groundPixelsEqualToAspertia': True, 'omittedBackdrop': omitted,
               'originalObjectPlacements': 'Not decoded; props are placed separately from the visual reference',
               'combinedArchiveSha256': route19['sha256']})
    return output, [route19, route20]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--project-root', type=Path, required=True)
    parser.add_argument('--source-root', type=Path, required=True)
    parser.add_argument('--nitro-root', type=Path, required=True)
    parser.add_argument('--only', choices=['route-19', 'route-20'])
    options = parser.parse_args()
    project = options.project_root.resolve(strict=True)
    if json.loads((project / 'project.json').read_text())['settings']['dimension'] != 'threeD':
        raise ValueError('An existing three-dimensional project is required')
    sources, records = prepare_sources(project, options.source_root.resolve(strict=True), options.nitro_root.resolve(strict=True))
    evidence = project / '.pokemap/authoring/unys-cities'
    index_path = evidence / 'index.json'
    index = json.loads(index_path.read_text())
    recipes = {row['id']: row for row in index['cities']}
    for route, record in zip(ROUTES, records):
        if options.only and options.only != route['id']:
            continue
        folder = evidence / route['id']
        recipes[route['id']] = build_city(route, sources, record, folder, source_reader=route_source)
    index['cities'] = list(recipes.values())
    group = {'id': 'unys-group-routes-depart', 'name': 'Routes 19 et 20', 'type': 'route', 'sortOrder': 8}
    if not any(row['id'] == group['id'] for row in index['groups']):
        index['groups'].append(group)
    write_json(index_path, index)
    write_json(project / '.pokemap/authoring/routes-19-20/route_catalog.json', {'cities': ROUTES})


if __name__ == '__main__':
    main()

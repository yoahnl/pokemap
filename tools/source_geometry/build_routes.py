import argparse
from copy import deepcopy
from hashlib import sha256
from io import BytesIO
from pathlib import Path, PurePosixPath
import json
import math
import subprocess
import xml.etree.ElementTree as ET
import zipfile

from PIL import Image

from build_cities import build_city, validate_source_id, write_json
from city_geometry import NAMESPACE, Surface, source_scene
from convert_source_asset_pack import clip_polygon, triangulate
from source_policy import matches, policy_for_asset, read_source_policy, validate_selector


NS = NAMESPACE['c']


def relative_path(value):
    if not isinstance(value, str) or not value or PurePosixPath(value).is_absolute() or '\\' in value or ':' in value or any(
            part in {'', '.', '..'} for part in value.split('/')):
        raise ValueError('Expected a confined source preparation path')
    return value


def route_source(source_root, record):
    surfaces, textures, provenance = source_scene(source_root, record, policy=record['sourcePolicy'])
    crop = record.get('sourceCrop')
    if crop is None:
        return surfaces, textures, provenance
    if not isinstance(crop, dict) or set(crop) != {'planes', 'reason'} or not isinstance(crop['planes'], list) or not 1 <= len(crop['planes']) <= 6:
        raise ValueError('Invalid bounded source crop')
    for plane in crop['planes']:
        if set(plane) != {'axis', 'boundary', 'keepGreater'} or type(plane['axis']) is not int or plane['axis'] not in (0, 1, 2) or type(plane['keepGreater']) is not bool or type(plane['boundary']) not in (int, float) or not math.isfinite(plane['boundary']):
            raise ValueError('Invalid clipping plane')
    clipped = []
    for surface in surfaces:
        triangles = []
        for triangle in surface.triangles:
            polygon = triangle
            for plane in crop['planes']:
                polygon = clip_polygon(polygon, plane['axis'], plane['boundary'], plane['keepGreater'])
            if len(polygon) >= 3:
                triangles.extend(triangulate(polygon))
        if triangles:
            clipped.append(Surface(surface.group, surface.geometry, surface.material, surface.texture,
                                   surface.wraps, surface.opacity, triangles, surface.terrain))
    return clipped, textures, {**provenance, 'sourceCrop': deepcopy(crop)}


def combine_sectors(folder, recipe):
    ET.register_namespace('', NS)
    sectors = recipe['sectors']
    if not isinstance(sectors, list) or not 1 <= len(sectors) <= 32:
        raise ValueError('Expected bounded decoded source sectors')
    validate_selector(recipe['omittedMaterials'])
    trees = [ET.parse(folder / relative_path(sector['daeFile'])).getroot() for sector in sectors]
    result = ET.Element('{' + NS + '}COLLADA', version='1.4.1')
    result.append(deepcopy(trees[0].find('c:asset', NAMESPACE)))
    libraries = {}
    visual = ET.Element('{' + NS + '}visual_scene', id=recipe['sceneId'], name=recipe['sceneName'])
    omitted = []
    for index, (tree, sector) in enumerate(zip(trees, sectors)):
        prefix = sector['idPrefix']
        offset = sector['translation']
        if not isinstance(prefix, str) or not prefix or not isinstance(offset, list) or len(offset) != 3 or any(type(value) not in (int, float) or not math.isfinite(value) for value in offset):
            raise ValueError('Invalid source sector identity or translation')
        names = {node.get('id'): prefix + node.get('id') for node in tree.iter() if node.get('id')}
        materials = {node.get('id'): node.get('name', node.get('id')) for node in tree.findall('c:library_materials/c:material', NAMESPACE)}
        scene = tree.find('c:library_visual_scenes/c:visual_scene', NAMESPACE)
        bindings = {node.get('symbol'): materials[node.get('target')[1:]] for node in scene.findall('.//c:instance_material', NAMESPACE)}
        for mesh in tree.findall('c:library_geometries/c:geometry/c:mesh', NAMESPACE):
            for primitive in list(mesh):
                if matches(bindings.get(primitive.get('material'), ''), recipe['omittedMaterials']):
                    omitted.append({'sector': index, 'material': bindings[primitive.get('material')], 'reason': recipe['omissionReason']})
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
        root = ET.SubElement(visual, '{' + NS + '}node', id=sector['rootNodeId'])
        ET.SubElement(root, '{' + NS + '}translate').text = ' '.join(map(str, offset))
        terrain = ET.SubElement(root, '{' + NS + '}node', id=sector['terrainNodeId'])
        for node in list(scene):
            terrain.append(node)
        for library in tree:
            tag = library.tag.rsplit('}', 1)[-1]
            if tag in ('asset', 'scene', 'library_visual_scenes'):
                continue
            target = libraries.setdefault(tag, ET.Element(library.tag))
            target.extend(list(library))
    for library in libraries.values():
        result.append(library)
    ET.SubElement(result, '{' + NS + '}library_visual_scenes').append(visual)
    scene = ET.SubElement(result, '{' + NS + '}scene')
    ET.SubElement(scene, '{' + NS + '}instance_visual_scene', url='#' + recipe['sceneId'])
    return ET.tostring(result, encoding='utf-8', xml_declaration=True), omitted


def prepare_sources(output_root, corpus, raw_root, decoder, recipe, policy):
    folder = output_root / relative_path(recipe['decodedDirectory'])
    folder.mkdir(parents=True, exist_ok=False)
    sources = [(raw_root / relative_path(path)).resolve(strict=True) for path in recipe['rawFiles']]
    if not 1 <= len(sources) <= 64 or any(not path.is_relative_to(raw_root) or not path.is_file() for path in sources):
        raise ValueError('Invalid source decoder inputs')
    decoded = subprocess.run([str(decoder), 'convert', *map(str, sources), '-o', str(folder), '-f', 'dae'], capture_output=True, text=True)
    if decoded.returncode or 'matching texture' in decoded.stdout + decoded.stderr:
        raise ValueError(decoded.stdout + decoded.stderr)
    records = json.loads((corpus / 'manifest.json').read_text())['assets']
    reference = [row for row in records if row['id'] == recipe['referenceAssetId']]
    if len(reference) != 1:
        raise ValueError('Source texture reference is absent or ambiguous')
    surfaces, textures, _ = source_scene(corpus, reference[0], policy=policy)
    selected = [surface for surface in surfaces if surface.material == recipe['referenceMaterial']]
    if not selected:
        raise ValueError('Source reference material is absent')
    expected = Image.open(BytesIO(textures[selected[0].texture])).convert('RGBA')
    actual = Image.open(folder / relative_path(recipe['decodedTexture'])).convert('RGBA')
    if expected.size != actual.size or expected.tobytes() != actual.tobytes():
        raise ValueError('Decoded texture differs from the declared source reference')
    dae, omitted = combine_sectors(folder, recipe['combinedScene'])
    output = output_root / relative_path(recipe['sourceDirectory'])
    output.mkdir(parents=True, exist_ok=False)
    archive = output / relative_path(recipe['archiveName'])
    with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED) as target:
        target.writestr(relative_path(recipe['memberName']), dae)
        for texture in sorted(folder.glob('*.png')):
            target.write(texture, texture.name)
    combined = {**recipe['combinedRecord'], 'local_path': archive.name,
                'sha256': sha256(archive.read_bytes()).hexdigest()}
    selected_records = [combined]
    for source_id in recipe['copySourceIds']:
        matches_source = [row for row in records if row['id'] == source_id]
        if len(matches_source) != 1:
            raise ValueError('Copied source is absent or ambiguous')
        record = deepcopy(matches_source[0])
        source = (corpus / relative_path(record['local_path'])).resolve(strict=True)
        if not source.is_relative_to(corpus):
            raise ValueError('Source archive escapes its corpus')
        data = source.read_bytes()
        if sha256(data).hexdigest() != record['sha256']:
            raise ValueError('Source archive digest changed')
        (output / source.name).write_bytes(data)
        record['local_path'] = source.name
        selected_records.append(record)
    write_json(output / 'manifest.json', {'assets': selected_records})
    write_json(output_root / 'source-preparation.json', {
        'rawInputs': [{'path': str(path.relative_to(raw_root)), 'sha256': sha256(path.read_bytes()).hexdigest()} for path in sources],
        'combinedArchiveSha256': combined['sha256'], 'omitted': omitted,
        'texturePixelsEqualToReference': True})
    return output, selected_records


def main():
    parser = argparse.ArgumentParser()
    for name in ('project-root', 'source-root', 'raw-root', 'decoder', 'recipe', 'source-policy', 'output-root'):
        parser.add_argument('--' + name, type=Path, required=True)
    parser.add_argument('--only')
    options = parser.parse_args()
    project = options.project_root.resolve(strict=True)
    if json.loads((project / 'project.json').read_text())['settings']['dimension'] != 'threeD':
        raise ValueError('An existing three-dimensional project is required')
    recipe = json.loads(options.recipe.read_text())
    if recipe.get('schemaVersion') != 1 or len(recipe['routes']) > 256:
        raise ValueError('Invalid source preparation recipe')
    for route in recipe['routes']:
        validate_source_id(route['id'])
    if len({route['id'] for route in recipe['routes']}) != len(recipe['routes']):
        raise ValueError('Duplicate source output identifiers')
    policy = read_source_policy(options.source_policy)
    output = options.output_root.resolve()
    corpus, raw = options.source_root.resolve(strict=True), options.raw_root.resolve(strict=True)
    if output.exists() or any(output == root or output.is_relative_to(root) or root.is_relative_to(output) for root in (project, corpus, raw)):
        raise ValueError('Expected a new output outside project and source roots')
    output.mkdir(parents=True)
    sources, records = prepare_sources(output, corpus, raw, options.decoder.resolve(strict=True), recipe['preparation'], policy)
    indexed = {row['id']: row for row in records}
    summaries = []
    for route in recipe['routes']:
        if options.only and options.only != route['id']:
            continue
        route['sourcePolicy'] = policy_for_asset(policy, route.pop('sourcePolicyOverrides', {}))
        summaries.append(build_city(route, sources, indexed[route['sourceId']], output / route['id'], source_reader=route_source))
    if options.only and not summaries:
        raise ValueError('Unknown route selection')
    write_json(output / 'index.json', {'formatVersion': 1, 'groups': recipe['groups'], 'cities': summaries})


if __name__ == '__main__':
    main()

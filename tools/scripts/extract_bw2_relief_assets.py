import argparse
import hashlib
import json
from pathlib import Path
import tempfile
import xml.etree.ElementTree as ET
import zipfile

from PIL import Image

from extract_hgss_small_map_assets import write_glb


NAMESPACE = {'c': 'http://www.collada.org/2005/11/COLLADASchema'}
HOUSE_ARCHIVE = 'archives/buildings/construction-house-1--583154.zip'
HOUSE_SHA256 = '85e6222d586d687392a521dd841b2614d975db809275ec5e88ad59e6fd939394'
HOUSE_DAE_SHA256 = 'b4de3daa8f82137968f12e3ba62a91ba3fcd04aa2eec040a60bb81e690176be9'
CLIFF_ARCHIVE = 'archives/maps/route-20--587546.zip'
CLIFF_MEMBER = 'Route 20_texture_0018.png'
CLIFF_SHA256 = 'a5407e520b5fad3bcfc11476f4ecd56f4a5948e3d0ad3619ac283c3b48ff966e'


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def require_hash(data, expected, label):
    if sha256(data) != expected:
        raise ValueError(f'Unexpected source digest: {label}')


def house_surfaces(data):
    require_hash(data, HOUSE_DAE_SHA256, 'd7_inaba_01.dae')
    root = ET.fromstring(data)
    nodes = root.findall('.//c:visual_scene/c:node', NAMESPACE)
    if len(nodes) != 1 or nodes[0].get('name') != 'd7_inaba_01':
        raise ValueError('Unexpected house scene')
    if [node.tag.rsplit('}', 1)[-1] for node in nodes[0]] != ['instance_geometry']:
        raise ValueError('House transforms or controllers are unsupported')
    mesh = root.find('.//c:geometry/c:mesh', NAMESPACE)
    sources = {}
    for source in mesh.findall('c:source', NAMESPACE):
        values = list(map(float, source.find('c:float_array', NAMESPACE).text.split()))
        stride = int(source.find('.//c:accessor', NAMESPACE).get('stride'))
        sources[source.get('id')] = [values[start:start + stride] for start in range(0, len(values), stride)]
    inputs = {item.get('semantic'): item.get('source')[1:] for item in mesh.find('c:vertices', NAMESPACE)}
    selections = {0: ('material2', 'h_mado.png'), 1: ('material0', 'door001.png'), 3: ('material3', 'yane001.png')}
    surfaces = {}
    provenance = []
    for index, polylist in enumerate(mesh.findall('c:polylist', NAMESPACE)):
        if index not in selections:
            continue
        material, texture = selections[index]
        if polylist.get('material') != material:
            raise ValueError('Unexpected native material')
        poly_inputs = polylist.findall('c:input', NAMESPACE)
        if len(poly_inputs) != 1 or poly_inputs[0].get('semantic') != 'VERTEX' or poly_inputs[0].get('offset') != '0':
            raise ValueError('Unexpected polygon index layout')
        counts = list(map(int, polylist.find('c:vcount', NAMESPACE).text.split()))
        indices = list(map(int, polylist.find('c:p', NAMESPACE).text.split()))
        if sum(counts) != len(indices) or any(count not in (3, 4) for count in counts):
            raise ValueError('Only native triangles and convex quads are supported')
        vertices = []
        cursor = 0
        for count in counts:
            polygon = indices[cursor:cursor + count]
            cursor += count
            for triangle in range(1, count - 1):
                for vertex in (polygon[0], polygon[triangle], polygon[triangle + 1]):
                    color = sources[inputs['COLOR']][vertex]
                    if any(abs(channel - 1) > 1e-6 for channel in color):
                        raise ValueError('Native vertex shading cannot be discarded')
                    x, y, z = sources[inputs['POSITION']][vertex]
                    u, v = sources[inputs['TEXCOORD']][vertex]
                    vertices.append([x / 16, (y - 6) / 16, z / 16, u, 1 - v])
        surfaces[texture] = vertices
        provenance.append({'polylist': index, 'material': material, 'texture': texture, 'triangles': len(vertices) // 3})
    if sum(len(vertices) // 3 for vertices in surfaces.values()) != 76:
        raise ValueError('Unexpected house triangle count')
    return surfaces, provenance


def extract(source_root, output_root):
    output_root.mkdir(parents=True, exist_ok=True)
    house_bytes = (source_root / HOUSE_ARCHIVE).read_bytes()
    require_hash(house_bytes, HOUSE_SHA256, HOUSE_ARCHIVE)
    with zipfile.ZipFile(source_root / CLIFF_ARCHIVE) as archive:
        cliff_bytes = archive.read(CLIFF_MEMBER)
    require_hash(cliff_bytes, CLIFF_SHA256, CLIFF_MEMBER)
    cliff_path = output_root / 'bw2_route20_cliff.png'
    cliff_path.write_bytes(cliff_bytes)
    with Image.open(cliff_path) as image:
        if image.size != (16, 32) or image.convert('RGBA').getextrema()[3] != (255, 255):
            raise ValueError('Cliff texture must be opaque 16 by 32')
    with zipfile.ZipFile(source_root / HOUSE_ARCHIVE) as archive:
        dae = archive.read('d7_inaba_01.dae')
        surfaces, selections = house_surfaces(dae)
        with tempfile.TemporaryDirectory(prefix='avelune-bw2-') as temporary:
            texture_directory = Path(temporary)
            for name in surfaces:
                (texture_directory / name).write_bytes(archive.read(name))
            house_path = output_root / 'bw2_construction_house.glb'
            metrics = write_glb(house_path, surfaces, texture_directory)
    receipt = {
        'schemaVersion': 1,
        'house': {
            'assetId': '583154',
            'sourceUrl': 'https://models.spriters-resource.com/ds_dsi/pokemonblack2white2/asset/583154/',
            'archive': HOUSE_ARCHIVE, 'archiveSha256': HOUSE_SHA256,
            'member': 'd7_inaba_01.dae', 'memberSha256': HOUSE_DAE_SHA256,
            'conversion': 'Source axes preserved; Y vertical inferred from geometry; (x,y-6,z)/16; UV (u,1-v)',
            'selections': selections,
            'omitted': {'polylist': 2, 'texture': 'h_kage.png', 'reason': 'Baked translucent ground shadow'},
            'output': house_path.name, 'outputSha256': sha256(house_path.read_bytes()),
            'metrics': metrics,
        },
        'cliff': {
            'assetId': '587546',
            'sourceUrl': 'https://models.spriters-resource.com/ds_dsi/pokemonblack2white2/asset/587546/',
            'archive': CLIFF_ARCHIVE, 'archiveSha256': sha256((source_root / CLIFF_ARCHIVE).read_bytes()),
            'member': CLIFF_MEMBER, 'memberSha256': CLIFF_SHA256,
            'material': 'yamagake01', 'sourceGeometry': 'map04_20-18',
            'output': cliff_path.name,
            'usage': 'Original opaque texture applied to native Avelune height-block walls; source map geometry is not imported',
        },
    }
    (output_root / 'bw2_relief_provenance.json').write_text(json.dumps(receipt, ensure_ascii=False, indent=2) + '\n')
    return receipt


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source-root', type=Path, required=True)
    parser.add_argument('--output-root', type=Path, required=True)
    args = parser.parse_args()
    receipt = extract(args.source_root.resolve(strict=True), args.output_root.resolve())
    print(json.dumps({'output': str(args.output_root), 'houseSha256': receipt['house']['outputSha256'], 'triangles': 76}))


if __name__ == '__main__':
    main()

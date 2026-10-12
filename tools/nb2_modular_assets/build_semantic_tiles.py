import argparse
from collections import Counter, defaultdict
from hashlib import sha256
from io import BytesIO
import json
from pathlib import Path
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
import extract_units as extraction
from city_geometry import sample_texture


SLOTS = [('northEdge', 0, -1), ('eastEdge', 1, 0), ('southEdge', 0, 1),
         ('westEdge', -1, 0), ('northWestCorner', -1, -1),
         ('northEastCorner', 1, -1), ('southEastCorner', 1, 1), ('southWestCorner', -1, 1)]
MATERIALS = {
    'grass01ax': ('nb2-grass', 'Herbe NB2', 'terrain'),
    'out65_zimen1': ('nb2-compacted-earth', 'Terre tassée NB2', 'terrain'),
    'michi01a': ('nb2-earth-path', 'Chemin de terre NB2', 'path'),
    'michi01b': ('nb2-earth-path', 'Chemin de terre NB2', 'path'),
    'C12_tile': ('nb2-light-paving', 'Dalles claires NB2', 'path'),
    'C12_tile02': ('nb2-stone-paving', 'Pavés NB2', 'path'),
    'C12_tile02_b': ('nb2-dark-stone-paving', 'Pavés sombres NB2', 'path'),
    'C12_tile06': ('nb2-grey-square-paving', 'Dalles grises NB2', 'path'),
    'C12_tile06_b': ('nb2-grey-square-paving', 'Dalles grises NB2', 'path'),
    'C12_tile07': ('nb2-cream-square-paving', 'Dalles crème NB2', 'path'),
    'C12_tile07_b': ('nb2-cream-square-paving', 'Dalles crème NB2', 'path'),
}
UNIFORM_SOURCES = {'grass01ax': 4, 'out65_zimen1': 4, 'michi01b': 1,
                   'C12_tile': 2, 'C12_tile02': 2, 'C12_tile02_b': 2,
                   'C12_tile06': 2, 'C12_tile07': 2}
MOTIFS = extraction.GROUND_DECAL_MATERIALS
PROFILES = {'gake1_0', 'gake1_1', 'C12_tile03', 'C12_tile04', 'C12_tile05'}


def blob_mask(mask):
    result = mask & 15
    for bit, first, second in ((16, 1, 8), (32, 1, 2), (64, 4, 2), (128, 4, 8)):
        if mask & bit and mask & first and mask & second:
            result |= bit
    return result


def connectivity(cells, x, z):
    return blob_mask(sum(1 << index for index, (_, dx, dz) in enumerate(SLOTS)
                         if (x + dx, z + dz) in cells))


def affine_uv(triangle):
    x, z = triangle[0][0], triangle[0][2]
    ax, az = triangle[1][0] - x, triangle[1][2] - z
    bx, bz = triangle[2][0] - x, triangle[2][2] - z
    denominator = ax * bz - az * bx
    if abs(denominator) < 1e-9:
        return None
    result = []
    for axis in (3, 4):
        first, second = triangle[1][axis] - triangle[0][axis], triangle[2][axis] - triangle[0][axis]
        a = (first * bz - az * second) / denominator
        b = (ax * second - first * bx) / denominator
        result.append([a, b, triangle[0][axis] - a * x - b * z])
    return result


def periodic_source(areas, period):
    candidates = []
    for area in areas:
        for index, triangle in enumerate(area['sourceTriangles']):
            matrix = affine_uv(triangle)
            if matrix is None:
                continue
            error = max(abs(matrix[0][0] - 1 / period), abs(matrix[0][1]),
                        abs(matrix[1][0]), abs(matrix[1][1] - 1 / period))
            if error <= .002:
                candidates.append((error, area['group'], index, area, matrix))
    if not candidates:
        return None
    _, _, index, area, matrix = min(candidates, key=lambda row: row[:3])
    return {'area': area, 'triangleIndex': index, 'uvMatrix': matrix,
            'periodCells': period, 'regularSourceTriangleCount': len(candidates)}


def pattern_image(image, mapping, translation):
    period = mapping['periodCells']
    matrix = mapping['uvMatrix']
    result = extraction.Image.new('RGBA', (period * 16, period * 16))
    for y in range(result.height):
        z = (y + .5) / 16 - translation[2]
        for x in range(result.width):
            source_x = (x + .5) / 16 - translation[0]
            u, v = [a * source_x + b * z + c for a, b, c in matrix]
            result.putpixel((x, y), sample_texture(image, u, v, mapping['area']['wraps']))
    return result


def preset(material, atlas_id, period, preset_id, name):
    return {'id': preset_id, 'name': name, 'usage': material[2],
            'defaultMaterialId': material[0], 'allowedMaterialIds': [material[0]],
            'topology': 'uniform', 'templateHint': 'simple', 'coveragePolicy': 'complete',
            'coverageProfile': {'mode': 'template'}, 'transformPolicy': {},
            'rules': [{'id': 'surface', 'centerMatch': {'kind': 'material', 'materialId': material[0]},
                       'candidates': [{'id': 'source-period', 'weight': 1, 'parts': [
                           {'source': {'kind': 'frame', 'frame': {'atlasId': atlas_id, 'column': 0, 'row': 0,
                            'columnSpan': period, 'rowSpan': period}}, 'frameSampling': 'tessellated'}]}]}]}


def source_path_tiles(areas, source_materials, frame, images):
    surfaces = [extraction.Surface(area['group'], area['geometry'], area['material'], area['texture'],
                                  area['wraps'], 1,
                                  [[[*vertex[:5], 1, 1, 1] for vertex in triangle]
                                   for triangle in area['sourceTriangles']], True)
                for area in areas if area['material'] in source_materials]
    translation = frame['sourceToNativeTranslation']
    cells = extraction.cell_triangles(surfaces, [-translation[0], 0, -translation[2]], frame['width'], frame['depth'])
    city = {'id': 'route-19' if frame['mapId'] == 'unys-route-19' else 'pavonnay'}
    return {cell: extraction.raster_tile(entries, cell[0] - translation[0], cell[1] - translation[2], images,
                                        'path', city) for cell, entries in cells.items()}


def uniform_coverage(name, material, frame, kit, pattern):
    atlas = next(row for row in frame['nativePaint']['nativeTextureAtlases'] if row['kind'] == material[2])
    image = extraction.Image.open(kit / atlas['file']).convert('RGBA')
    variants = {row['index']: row for row in atlas['variants']}
    connections = {(row['x'], row['z']): row['variantIndex'] for row in atlas['sourceConnections']}
    period = pattern.width // 16
    counts = Counter()
    review = []
    for sample in frame['nativePaint']['sourceCellSamples']:
        if sample['material'] != name:
            continue
        x, z = sample['x'], sample['z']
        variant = variants.get(connections.get((x, z)))
        if variant is None:
            status = 'missing_source_atlas_sample'
        elif variant['sourceMaterials'] != [name]:
            status = 'mixed_source_materials'
        else:
            left, top = variant['column'] * 16, variant['row'] * 16
            original = image.crop((left, top, left + 16, top + 16))
            left, top = x % period * 16, z % period * 16
            proposed = pattern.crop((left, top, left + 16, top + 16))
            if original.tobytes() == proposed.tobytes():
                status = 'exact_source_pixels'
            elif original.getchannel('A').getextrema() != (255, 255):
                status = 'fractional_source_geometry_or_alpha'
            else:
                status = 'local_source_uv_or_vertex_shading'
        counts[status] += 1
        if status != 'exact_source_pixels':
            review.append({'x': x, 'z': z, 'reason': status})
    return {'sourcePrimaryCells': sum(counts.values()), 'counts': dict(counts),
            'reviewCells': review, 'gate': 'pixel equality against original full UV atlas, before artist acceptance'}


def path_analysis(tiles, material_id, output):
    coverage = {cell: sum(pixel[3] / 255 for pixel in image.get_flattened_data()) / 256
                for cell, image in tiles.items()}
    mask = {cell for cell, value in coverage.items() if value >= .5}
    observed = defaultdict(list)
    for x, z in sorted(mask, key=lambda cell: (cell[1], cell[0])):
        image = tiles[x, z]
        observed[connectivity(mask, x, z)].append({'x': x, 'z': z,
            'rgbaSha256': sha256(image.tobytes()).hexdigest(),
            'alphaSha256': sha256(image.getchannel('A').tobytes()).hexdigest(),
            'sourceCoverageRatio': coverage[x, z]})
    rows = []
    rules = []
    canonical = sorted({blob_mask(mask) for mask in range(256)})
    atlas_id = material_id + '-source-prototypes'
    prototype_image = extraction.Image.new('RGBA', (8 * 16, 6 * 16))
    for index, mask_value in enumerate(canonical):
        examples = observed.get(mask_value, [])
        signature = {name: {'kind': 'same' if mask_value & (1 << index) else 'different'}
                     for index, (name, _, _) in enumerate(SLOTS)}
        rule = {'id': 'blob-' + str(mask_value), 'centerMatch': {'kind': 'material', 'materialId': material_id},
                'signature': signature, 'candidates': []}
        if examples:
            counts = Counter(row['rgbaSha256'] for row in examples)
            alpha_counts = Counter(row['alphaSha256'] for row in examples)
            identity = sorted(counts, key=lambda key: (-counts[key], key))[0]
            selected = next(row for row in examples if row['rgbaSha256'] == identity)
            prototype_image.paste(tiles[selected['x'], selected['z']], (index % 8 * 16, index // 8 * 16))
            rule['candidates'] = [{'id': 'source-prototype', 'weight': 1, 'parts': [
                {'source': {'kind': 'frame', 'frame': {'atlasId': atlas_id,
                 'column': index % 8, 'row': index // 8}}}]}]
            rows.append({'mask': mask_value, 'cellCount': len(examples), 'rgbaVariants': len(counts),
                         'alphaContourVariants': len(alpha_counts), 'modalVariantCellCount': counts[identity],
                         'status': 'observed_exact_single_visual' if len(counts) == 1 else 'ambiguous_source_geometry_or_uv',
                         'prototypeSourceCell': {'x': selected['x'], 'z': selected['z']},
                         'examples': examples})
        rules.append(rule)
    path = output / (atlas_id + '.png')
    prototype_image.save(path)
    return {'materialId': material_id, 'threshold': .5, 'thresholdEvidence': 'proposed grid quantization; original fractional coverage retained',
            'prototypeAtlas': {'file': str(path.relative_to(output)), 'sha256': extraction.digest(path),
                               'atlas': {'id': atlas_id, 'name': material_id, 'tilesetId': atlas_id + '-tileset',
                                         'cellWidth': 16, 'cellHeight': 16, 'columns': 8, 'rows': 6},
                               'cellOrder': canonical, 'missingCellsAreTransparentPlaceholders': True},
            'paintMask': [{'x': x, 'z': z} for x, z in sorted(mask)],
            'fractionalBoundaryCells': [{'x': x, 'z': z, 'sourceCoverageRatio': value}
                                       for (x, z), value in sorted(coverage.items()) if 0 < value < 1],
            'observedMaskCount': len(observed), 'missingMasks': [mask for mask in canonical if mask not in observed],
            'cases': rows, 'draftRules': rules,
            'status': 'draft_source_prototypes_only_not_publishable_as_complete_blob47',
            'policy': 'one deterministic prototype per observed signature; no weighted selection of incompatible corners'}


def build(kit, output):
    if output == kit or not output.is_relative_to(kit):
        raise ValueError('Semantic proposals must stay in a child directory of the derived kit')
    manifest_path, recipe_path = kit / 'manifest.json', kit / 'reconstruction_recipe.json'
    manifest, recipe = json.loads(manifest_path.read_text()), json.loads(recipe_path.read_text())
    output.mkdir(parents=True, exist_ok=True)
    material_rows = {value[0]: {'id': value[0], 'name': value[1], 'connectionGroupId': value[0]}
                     for value in MATERIALS.values()}
    maps = {}
    for map_id, frame in recipe['maps'].items():
        source_id = 'rom-route19' if map_id == 'unys-route-19' else '587455'
        textures = {row['member']: kit / row['file'] for row in manifest['sourceTextureAssets'] if row['sourceId'] == source_id}
        images = {name: extraction.Image.open(path).convert('RGBA') for name, path in textures.items()}
        grouped = defaultdict(list)
        for area in frame['areas']:
            grouped[area['material']].append(area)
        uniforms = []
        for name, period in UNIFORM_SOURCES.items():
            mapping = periodic_source(grouped[name], period)
            if mapping is None:
                continue
            material = MATERIALS[name]
            preset_id = 'nb2-source-' + name.lower().replace('_', '-') + '-' + map_id
            atlas_id = preset_id + '-atlas'
            path = output / (preset_id + '.png')
            image = pattern_image(images[mapping['area']['texture']], mapping, frame['sourceToNativeTranslation'])
            image.save(path)
            uniforms.append({'sourceMaterial': name, 'file': str(path.relative_to(output)), 'sha256': extraction.digest(path),
                             'sourceTexture': str(textures[mapping['area']['texture']]),
                             'sourceTextureSha256': extraction.digest(textures[mapping['area']['texture']]),
                             'sourceGroup': mapping['area']['group'], 'sourceTriangleIndex': mapping['triangleIndex'],
                             'sourceUvMatrix': mapping['uvMatrix'], 'periodCells': period,
                             'regularSourceTriangleCount': mapping['regularSourceTriangleCount'],
                             'reconstructionCoverage': uniform_coverage(name, material, frame, kit, image),
                             'atlas': {'id': atlas_id, 'name': material[1], 'tilesetId': preset_id + '-tileset',
                                       'cellWidth': 16, 'cellHeight': 16, 'columns': period, 'rows': period},
                             'preset': preset(material, atlas_id, period, preset_id, material[1]),
                             'status': 'reusable_source_period_prototype_visual_review_required',
                             'limits': ['No random candidates; source period sampled into a native tessellated frame',
                                        'Local UV stretch, source vertex shading and polygon boundaries are separate exceptions']})
        paint = defaultdict(list)
        unclassified = defaultdict(list)
        for sample in frame['nativePaint']['sourceCellSamples']:
            target = MATERIALS.get(sample['material'])
            cell = {'x': sample['x'], 'z': sample['z']}
            if target:
                paint[target[0]].append(cell)
            else:
                unclassified[sample['material']].append(cell)
        motifs = []
        for name in sorted(MOTIFS):
            for area in grouped[name]:
                surface = extraction.Surface(area['group'], area['geometry'], name, area['texture'], area['wraps'], 1,
                                             area['sourceTriangles'], True)
                for entries in extraction.component_triangles([(surface, triangle) for triangle in surface.triangles]):
                    bounds = extraction.entries_bounds(entries)
                    motifs.append({'sourceMaterial': name, 'sourceGroup': area['group'], 'sourceBounds': bounds,
                                   'sourceTriangles': [triangle for _, triangle in entries],
                                   'texture': str(textures[area['texture']]),
                                   'nativeTranslation': frame['sourceToNativeTranslation'],
                                   'role': 'reusable_motif_source_not_path_connectivity',
                                   'status': 'fixed_source_rotation_and_phase_require_pattern_or_card_authoring'})
        analyses = []
        families = [('nb2-earth-path', {'michi01a', 'michi01b'})] if map_id == 'unys-route-19' else [
            ('nb2-pavonnay-paving-outline', set(name for name in MATERIALS if name.startswith('C12_')))]
        for material_id, source_materials in families:
            analyses.append(path_analysis(source_path_tiles(frame['areas'], source_materials, frame, images), material_id, output))
        maps[map_id] = {'uniformResources': uniforms,
                       'semanticPaint': [{'materialId': key, 'cellMask': cells} for key, cells in sorted(paint.items())],
                       'nativePathTopology': analyses, 'motifs': motifs,
                       'profileMaterials': [{'sourceMaterial': name, 'cellMask': cells,
                                            'role': 'relief_face_cap_or_kerb_not_walkable_uniform_surface'}
                                           for name, cells in sorted(unclassified.items()) if name in PROFILES],
                       'unclassifiedPaint': [{'sourceMaterial': name, 'cellMask': cells} for name, cells in sorted(unclassified.items())],
                       'limits': ['Semantic paint changes only original supported cell centers; never fills null support',
                                  'Blob quantization does not preserve every off-grid curve; source polygons remain the fidelity oracle',
                                  'Prototype neighbor rules remain draft until missing and ambiguous forms receive qualified art']}
    document = {'schemaVersion': 1, 'tool': str(Path(__file__).resolve()), 'toolSha256': extraction.digest(Path(__file__)),
                'sourceManifestSha256': extraction.digest(manifest_path), 'sourceRecipeSha256': extraction.digest(recipe_path),
                'materials': list(material_rows.values()), 'maps': maps,
                'nativeMaskBits': {name: 1 << index for index, (name, _, _) in enumerate(SLOTS)},
                'status': 'semantic_source_analysis_and_reusable_resource_proposals_not_project_publication'}
    extraction.write_json(output / 'semantic_smart_tiles.json', document)
    print(json.dumps({'output': str(output.resolve()), 'materials': len(material_rows),
                      'maps': {key: {'uniformPresets': len(value['uniformResources']), 'motifs': len(value['motifs']),
                                    'pathObservedMasks': [row['observedMaskCount'] for row in value['nativePathTopology']]}
                               for key, value in maps.items()}}))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--kit-root', type=Path, required=True)
    parser.add_argument('--output-root', type=Path, required=True)
    args = parser.parse_args()
    build(args.kit_root.resolve(strict=True), args.output_root.resolve())


if __name__ == '__main__':
    main()

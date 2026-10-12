import argparse
from collections import Counter, defaultdict
from io import BytesIO
import json
from pathlib import Path
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
import extract_units as extraction
from build_complete_relief import selected_triangle
from build_fence_units import area


def load(path):
    return json.loads(path.read_text())


def placement_key(placement):
    return (placement['modelId'], *(round(placement['position'][axis], 7) for axis in ['x', 'y', 'z']),
            placement['rotationDegrees'] % 360)


def assigned_units(document, map_id):
    proof = document['sourceProof']['maps'][map_id]
    result = list(proof['explicitPlacements'])
    for feature in proof['features']:
        result.extend(feature['expectedPlacements'])
    return result


def reference_keys(placements):
    return {(row['group'], row['geometry'], row['material'], index) for placement in placements
            for row in placement['sourceReferences'] for index in row['triangleIndices']}


def build(args):
    kit, output = args.kit_root.resolve(), args.output_path.resolve()
    roots = [args.corpus_root.resolve(), args.route_source_root.resolve()]
    if any(output == root or output.is_relative_to(root) for root in roots):
        raise ValueError('Crosswalk output must remain outside read-only source roots')
    files = ['manifest.json', 'reconstruction_recipe.json', 'structure-actions.json',
        'fences/reconstruction_recipe.json', 'fence-actions.json', 'details/reconstruction_recipe.json', 'detail-actions.json',
        'relief-complete/manifest.json', 'relief-complete/reconstruction_recipe.json', 'cliff-actions.json',
        'relief-patterns/native-relief-pattern-actions.json', 'relief-patterns/canonical-proof.json',
        'fence-patterns/native-fence-pattern-actions.json', 'fence-patterns/canonical-proof.json',
        'detail-patterns/native-detail-pattern-actions.json', 'detail-patterns/canonical-proof.json',
        'native-surfaces/native-surface-actions.json', 'native-surfaces/canonical-proof.json',
        'floor-details/manifest.json', 'floor-details/native-floor-detail-actions.json', 'floor-details/canonical-proof.json',
        'flora/native-flora-actions.json', 'flora/canonical-proof.json', 'stairs/reconstruction_recipe.json']
    documents = {name: load(kit / name) for name in files}
    hashes = {name: extraction.digest(kit / name) for name in files}
    main = documents['reconstruction_recipe.json']
    structure = documents['structure-actions.json']['sourceProof']
    surface = documents['native-surfaces/native-surface-actions.json']['proof']
    floor = documents['floor-details/manifest.json']['coverage']
    flora = documents['flora/native-flora-actions.json']['proof']
    patterns = documents['relief-patterns/native-relief-pattern-actions.json']['proof']
    for kind in ['relief', 'fence', 'detail']:
        bundle = kind + '-patterns/native-' + kind + '-pattern-actions.json'
        proof = kind + '-patterns/canonical-proof.json'
        if documents[proof]['actionFileSha256'] != hashes[bundle]:
            raise ValueError('Canonical pattern proof does not match frozen actions: ' + kind)
    scenes = [extraction.load_scene(args.route_source_root, 'rom-route19', True),
              extraction.load_scene(args.corpus_root, '587455')]
    maps, blockers = {}, []
    for scene in scenes:
        map_id = 'unys-route-19' if scene['id'] == 'rom-route19' else 'first-map'
        city = 'route-19' if scene['id'] == 'rom-route19' else 'pavonnay'
        frame = main['maps'][map_id]
        expected = {}
        for family, recipe_name, action_name in [
            ('fences', 'fences/reconstruction_recipe.json', 'fence-actions.json'),
            ('details', 'details/reconstruction_recipe.json', 'detail-actions.json'),
            ('relief', 'relief-complete/reconstruction_recipe.json', 'cliff-actions.json')]:
            source_placements = documents[recipe_name]['maps'][map_id]['placements']
            if family == 'details':
                source_placements = [placement for placement in source_placements if placement['family'] != 'vegetation']
            actual = assigned_units(documents[action_name], map_id)
            if Counter(placement_key(placement) for placement in source_placements) != Counter(placement_key(placement) for placement in actual):
                raise ValueError('Extraction is not assigned to native actions: ' + family + ' ' + map_id)
            expected[family] = {'placements': source_placements, 'references': reference_keys(source_placements),
                'actionBundle': action_name, 'sourceRecipe': recipe_name}
        flora_placements = [placement for placement in documents['details/reconstruction_recipe.json']['maps'][map_id]['placements']
                            if placement['family'] == 'vegetation']
        flora_references = reference_keys(flora_placements)
        if Counter(placement_key(placement) for placement in flora_placements) != Counter(
                placement_key(placement) for placement in flora['maps'][map_id]['sourcePlacements']):
            raise ValueError('Source flora is not assigned to native Paths')
        delegated = documents['cliff-actions.json']['sourceProof']['maps'][map_id]['explicitPlacements']
        if Counter(placement_key(placement) for placement in delegated) != Counter(
                placement_key(placement) for placement in patterns['maps'][map_id]['sourcePlacements']):
            raise ValueError('Cliff exceptions are not assigned to native Terrain patterns')
        if not documents['flora/canonical-proof.json']['projection'][map_id]['exactSourcePositions']:
            raise ValueError('Native flora source transform proof failed')
        if not documents['relief-patterns/canonical-proof.json']['projection'][map_id]['exactSourcePositions']:
            raise ValueError('Native cliff source transform proof failed')
        for kind, action_name in [('fence', 'fence-actions.json'), ('detail', 'detail-actions.json')]:
            evidence = documents[action_name]['sourceProof']['maps'][map_id]
            autonomous = Counter(placement_key(value) for value in evidence['autonomousPlacements'])
            delegated = Counter(placement_key(value) for value in evidence['explicitPlacements']) - autonomous
            pattern = documents[kind + '-patterns/native-' + kind + '-pattern-actions.json']['proof']['maps'][map_id]
            if delegated != Counter(placement_key(value) for value in pattern['sourcePlacements']):
                raise ValueError('Compact source network is not assigned to native Paths: ' + kind)
            if not documents[kind + '-patterns/canonical-proof.json']['projection'][map_id]['exactSourcePositions']:
                raise ValueError('Native network source transform proof failed: ' + kind)
        restored = {item['sourceGroup']: item for item in structure['maps'][map_id]['restoredObjects'] if item.get('sourceGroup')}
        floor_materials = set(floor['sourceMaterialCells']) if map_id == 'first-map' else set()
        source_rows = []
        owner_counts = Counter()
        unknown = []
        object_groups = set()
        for source in scene['surfaces']:
            with extraction.Image.open(BytesIO(scene['textures'][source.texture])) as image:
                alpha = image.convert('RGBA').getchannel('A').getextrema()
            owners = defaultdict(list)
            for index, triangle in enumerate(source.triangles):
                reference = (source.group, source.geometry, source.material, index)
                if area([(source, triangle)]) < 1e-10:
                    owner = 'source_degenerate_triangle'
                elif alpha[1] == 0 or source.opacity == 0:
                    owner = 'source_fully_transparent_visibility_skip'
                elif not source.terrain and source.group in restored:
                    owner = 'complete_source_object_structure'
                    object_groups.add(source.group)
                elif source.material in extraction.TREE_MATERIALS:
                    owner = 'trees_environment_or_owned_source_exception'
                elif source.material in extraction.GRASS_MATERIALS:
                    owner = 'tallgrass_native_path_three_source_planes'
                elif source.material in {'mizu_sita2', 'ike01'}:
                    owner = 'water_native_terrain_original_animated_planes'
                elif reference in expected['fences']['references']:
                    owner = 'fences_native_borders_or_path_source_parts'
                elif reference in expected['details']['references']:
                    owner = 'complete_props_or_shores_native_borders_and_paths'
                elif reference in flora_references:
                    owner = 'flowers_native_path_source_planes'
                elif selected_triangle(source, triangle) and reference in expected['relief']['references']:
                    owner = 'relief_native_borders_or_terrain_source_parts'
                elif source.material in {'kaidan01a', 'c12_step'}:
                    owner = 'complete_stair_source_and_native_navigation_ramp'
                elif source.material in floor_materials:
                    owner = 'floor_details_native_path_absolute_y'
                elif extraction.ground_triangle({'id': city}, source, triangle):
                    owner = 'ground_native_terrain_and_path_texture_projection'
                else:
                    owner = 'unassigned_visible_source_geometry'
                    unknown.append({'group': source.group, 'geometry': source.geometry,
                        'material': source.material, 'triangleIndex': index,
                        'bounds': extraction.entries_bounds([(source, triangle)]), 'geometryArea': area([(source, triangle)])})
                owners[owner].append(index)
                owner_counts[owner] += 1
            for owner, indices in owners.items():
                triangles = [source.triangles[index] for index in indices]
                source_rows.append({'sourceGroup': source.group, 'sourceGeometry': source.geometry,
                    'sourceMaterial': source.material, 'sourceTexture': source.texture,
                    'sourceTextureSha256': extraction.sha256(scene['textures'][source.texture]).hexdigest(),
                    'sourceTriangleIndices': indices, 'sourceTriangleCount': len(indices),
                    'sourceGeometryArea': area([(source, triangle) for triangle in triangles]),
                    'sourceBounds': extraction.entries_bounds([(source, triangle) for triangle in triangles]),
                    'consumer': owner, 'stage': 'canonical_fixture_verified_candidate_not_applied_to_NB2'})
        if len(object_groups) != len(restored):
            raise ValueError('A restored source object has no source group')
        source_triangle_count = sum(len(source.triangles) for source in scene['surfaces'])
        if sum(owner_counts.values()) != source_triangle_count:
            raise ValueError('Crosswalk does not partition all source triangles exactly once')
        native = structure['maps'][map_id]
        expected_tree_count = frame['coverage']['treeUnits']
        if native['environmentTreeCount'] + len(native['explicitUnsupportedTrees']) != expected_tree_count:
            raise ValueError('Source trees are not all assigned')
        maps[map_id] = {'sourceId': scene['id'], 'sourceProvenance': scene['provenance'],
            'sourceToNativeTranslation': frame['sourceToNativeTranslation'], 'sourceTriangleCount': source_triangle_count,
            'sourceTriangleCountScope': 'drawables retained by source_scene inside the approved source crop',
            'excludedSourceDrawables': scene['provenance'].get('omitted', []),
            'sourceCrop': scene['provenance'].get('sourceCrop'),
            'sourceGroups': sorted({source.group for source in scene['surfaces']}),
            'consumerTriangleCounts': dict(sorted(owner_counts.items())), 'sourceRows': source_rows,
            'unassignedVisibleSourceGeometry': unknown,
            'nativeAssignmentCounts': {'trees': expected_tree_count, 'environmentTrees': native['environmentTreeCount'],
                'sourceTreesWithoutClassifiedSupport': len(native['explicitUnsupportedTrees']),
                'restoredSourceObjectGroups': len(object_groups), 'stairSourceObjects': len(native['stairs']),
                'fenceUnits': len(expected['fences']['placements']), 'detailUnits': len(expected['details']['placements']),
                'flowerPlaneUnits': len(flora_placements), 'reliefUnits': len(expected['relief']['placements']),
                'reliefNativeBorderUnits': documents['cliff-actions.json']['sourceProof']['canonicalInMemoryVerification']['maps'][map_id]['nativeBorderModels'],
                'reliefNativeTerrainParts': patterns['maps'][map_id]['originalSourceUnits'],
                'fenceNativeBorderUnits': documents['fence-actions.json']['sourceProof']['canonicalInMemoryVerification']['maps'][map_id]['nativeBorderModels'],
                'fenceNativePathParts': documents['fence-patterns/native-fence-pattern-actions.json']['proof']['maps'][map_id]['originalSourceUnits'],
                'detailNativeBorderUnits': documents['detail-actions.json']['sourceProof']['canonicalInMemoryVerification']['maps'][map_id]['nativeBorderModels'],
                'detailNativePathParts': documents['detail-patterns/native-detail-pattern-actions.json']['proof']['maps'][map_id]['originalSourceUnits'],
                'completeAutonomousDetailProps': len(documents['detail-actions.json']['sourceProof']['maps'][map_id]['autonomousPlacements']),
                'waterBaseAndOverlayPlanes': surface['waterMaps'][map_id]['originalPlaneInstances']},
            'removedRegionalSourceInstanceIds': native['removedInstanceIds'],
            'preservedInstanceIds': native['preservedInstanceIds'],
            'sourceSupport': {'classifiedSourceCells': native['sourceSupportCells'],
                'unclassifiedSourceCells': native['unqualifiedSupportCells'],
                'sourceFloorDoesNotEqualNullClassifier': True,
                'maximumTerrainHeightError': native['maximumTerrainError'],
                'floorDetailSupportGaps': floor['heightGaps'] if map_id == 'first-map' else []},
            'limits': ['Every source triangle has one explicit consumer or a proved fully transparent skip; this is an assignment crosswalk, not artistic acceptance',
                'Source_scene excludes baked shadow drawables explicitly listed in excludedSourceDrawables; shadow fidelity is not proved or counted as native replacement',
                'Native ground texture projection samples original UV and contours; quarter-height terrain quantization is separately measured',
                'Representative source-unit UV limits remain explicit in fences/details and marked repeating straight relief profiles',
                'Visual models do not decode ROM collisions; native navigation and collision remain separate authored authority']}
        blockers.extend({'mapId': map_id, **value} for value in unknown)
    if any(extraction.digest(kit / file) != value for file, value in hashes.items()):
        raise ValueError('A source action bundle changed during crosswalk generation')
    extraction.write_json(output, {'schemaVersion': 1, 'stage': 'canonical_fixture_verified_candidate_not_applied_to_NB2',
        'tool': str(Path(__file__).resolve()), 'toolSha256': extraction.digest(Path(__file__)),
        'sourceBundleSha256': hashes, 'maps': maps, 'unassignedVisibleSourceGeometry': blockers,
        'readyForParentReview': not blockers,
        'qualityOrder': ['source contour and support', 'native relief and navigation', 'original terrain and path textures',
            'native Borders', 'native ENV and source objects', 'native animated water and source flower planes',
            'equal-scale visual comparison', 'Studio editability review', 'Player traversal and collision review']})
    print(json.dumps({'output': str(output), 'visibleGeometryGaps': len(blockers), 'maps': {map_id: {
        'sourceTriangles': value['sourceTriangleCount'], 'consumers': value['consumerTriangleCounts'],
        'nativeAssignmentCounts': value['nativeAssignmentCounts']} for map_id, value in maps.items()}}))
    if blockers:
        raise ValueError('Visible source geometry has no native replacement')


def main():
    parser = argparse.ArgumentParser()
    for name in ['corpus-root', 'route-source-root', 'kit-root', 'output-path']:
        parser.add_argument('--' + name, type=Path, required=True)
    build(parser.parse_args())


if __name__ == '__main__':
    main()

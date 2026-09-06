import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  const initial = ProjectManifest(name: 'Region test', maps: [
    ProjectMapEntry(id: 'town', name: 'Town', relativePath: 'maps/town.json')
  ], tilesets: []);
  const actions = RegionalMapActions();
  final region = ProjectRegionDefinition(id: 'west', label: 'West');
  final point = ProjectRegionPointOfInterest(
      id: 'town-poi',
      regionId: 'west',
      label: 'Town',
      u: 0.2,
      v: 0.8,
      mapIds: const ['town']);

  test('semantic region and POI CRUD preserves explicit empty catalogue', () {
    final withRegion = actions.upsertRegion(initial, region: region);
    final withPoint = actions.upsertPoint(withRegion, point: point);
    expect(
        () => actions.deleteRegion(withPoint, regionId: 'west'),
        throwsA(isA<MapAuthoringException>()
            .having((e) => e.code, 'code', 'regional_map.region_referenced')));
    final cleared = actions.deleteRegion(
        actions.deletePoint(withPoint, pointId: point.id),
        regionId: region.id);
    expect(cleared.regionalMap, isNotNull);
    expect(cleared.regionalMap!.regions, isEmpty);
    expect(cleared.maps, initial.maps);
  });

  test('catalog region and POI are discoverable canonical resources', () {
    final project = actions.upsertPoint(
        actions.upsertRegion(initial, region: region),
        point: point);
    final snapshot = fixture(project);
    final registry = AuthoringResourceKindRegistry.canonical();
    for (final kind in ['regionalMap', 'regionalMapRegion', 'regionalMapPoi']) {
      expect(registry.queryableResourceKindIds, contains(kind));
      final page = const ProjectQueryService().query(
          snapshot,
          AuthoringQueryRequest(
              resourceKind: kind,
              operation: AuthoringQueryOperation.list,
              view: AuthoringQueryView.detail));
      expect(page.items, hasLength(1));
      expect(page.items.single['resourceKind'], kind);
    }
    expect(
        RegionalMapActions.descriptors.map((d) => d.id),
        containsAll([
          'regionalMap.region.upsert',
          'regionalMap.region.delete',
          'regionalMap.poi.upsert',
          'regionalMap.poi.delete'
        ]));
  });

  test('missing and incompatible images are authoring diagnostics', () {
    final project = actions.upsertRegion(initial,
        region: ProjectRegionDefinition(
            id: 'west', label: 'West', imagePath: 'assets/map.png'));
    const gate = RegionalMapAuthoringGate();
    expect(
        gate
            .inspect(project: project, assets: AssetCatalog(records: []))
            .single
            .code,
        'regional_map.image_missing');
    final wrong = AssetRecord(
        id: 'regional-image',
        logicalPath: 'assets/map.png',
        artifact: ContentArtifactRef.fromBytes([1, 2], mediaType: 'audio/ogg'));
    expect(
        gate
            .inspect(project: project, assets: AssetCatalog(records: [wrong]))
            .single
            .code,
        'regional_map.image_type_invalid');
    final right = AssetRecord(
        id: 'regional-image',
        logicalPath: 'assets/map.png',
        artifact: ContentArtifactRef.fromBytes([1, 2], mediaType: 'image/png'));
    expect(
        gate.inspect(project: project, assets: AssetCatalog(records: [right])),
        isEmpty);
    expect(deriveAssetUsages(manifest: project, maps: [], asset: right),
        contains(r'project:$.regionalMap.regions[0].imagePath'));
  });

  test('reference query discovers POI map and image dependencies', () {
    final asset = AssetRecord(
        id: 'regional-image',
        logicalPath: 'assets/map.png',
        artifact: ContentArtifactRef.fromBytes([1, 2], mediaType: 'image/png'));
    final project = actions.upsertPoint(
        actions.upsertRegion(initial,
            region: ProjectRegionDefinition(
                id: 'west', label: 'West', imagePath: asset.logicalPath)),
        point: point);
    final index = ProjectReferenceIndex.fromSnapshot(
        fixture(project, assets: AssetCatalog(records: [asset])));
    expect(
        index.edges
            .where((edge) => edge.owner.kind == 'regionalMapPoi')
            .map((edge) => edge.target.kind),
        containsAll(['sourceMap', 'regionalMapRegion']));
    expect(
        index.edges.any((edge) =>
            edge.target.kind == 'asset' && edge.target.id == asset.id),
        isTrue);
    expect(index.diagnostics.where((d) => d.code.startsWith('regional_map.')),
        isEmpty);
  });

  for (final spawnId in ['arrival-entity', 'arrival-key']) {
    test('destination $spawnId references its canonical spawn entity', () {
      final project = actions.upsertPoint(
        actions.upsertRegion(initial, region: region),
        point: ProjectRegionPointOfInterest.fromJson({
          ...point.toJson(),
          'destination': {'mapId': 'town', 'spawnId': spawnId},
        }),
      );
      final index =
          ProjectReferenceIndex.fromSnapshot(fixture(project, maps: const [
        MapData(
          id: 'town',
          name: 'Town',
          size: GridSize(width: 3, height: 3),
          layers: [],
          entities: [
            MapEntity(
                id: 'arrival-entity',
                kind: MapEntityKind.spawn,
                pos: GridPos(x: 0, y: 0),
                spawn: MapEntitySpawnData(spawnKey: 'arrival-key'))
          ],
        ),
      ]));
      final target = ProjectReferenceKey.fromNarrativeKey(
          const NarrativeDependencyKey.mapSource(
        mapId: 'town',
        sourceKind: 'entity',
        sourceId: 'arrival-entity',
      ));
      final impact =
          ProjectReferenceImpactAnalyzer(index).deletionImpact(target);
      expect(impact.runtimeBlocking, isTrue);
      expect(
          impact.directDependents,
          contains(
              ProjectReferenceKey(kind: 'regionalMapPoi', id: 'town-poi')));
      expect(impact.affectedEdges.single.path,
          'regionalMap.pointsOfInterest[town-poi].destination.spawnId');
      expect(impact.affectedEdges.single.resolution,
          NarrativeDependencyResolution.resolved);
      expect(target.toJson(), {
        'kind': 'sourceMap',
        'id': 'arrival-entity',
        'scope': 'map',
        'parentId': 'town',
        'sourceKind': 'entity'
      });
    });
  }
}

ProjectSnapshot fixture(ProjectManifest project,
        {AssetCatalog? assets, List<MapData> maps = const []}) =>
    ProjectSnapshot(
        projectHandle: const ProjectHandle('regional-project'),
        revision: 'sha256:${'1' * 64}',
        manifest: project,
        maps: maps,
        resourceFingerprints: {
          if (assets != null) assetCatalogResourceIdentity: 'sha256:${'2' * 64}'
        },
        resourceBytes: {
          if (assets != null)
            assetCatalogResourceIdentity:
                utf8.encode(jsonEncode(assets.toJson()))
        });

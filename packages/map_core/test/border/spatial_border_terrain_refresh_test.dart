import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'spatial_border_face_ground_test.dart'
    show spatialCliffFixture, spatialTestSurface;

const _operations = SpatialMapOperations();

void main() {
  test('support edits never move Border-owned modules behind their receipt',
      () {
    final fixture = _materialized();
    final edited = _operations.upsertTerrainSurfaces(fixture.map, [
      spatialTestSurface('plateau', height: 2, left: 1, top: 1, size: 4),
    ], pinBorderOwnedInstances: true);
    expect(_borderInstances(edited), _borderInstances(fixture.map));
    expect(_storedOutputMatchesReceipt(edited), isTrue);
  });

  test('default support edits keep their historical reanchoring', () {
    final fixture = _materialized();
    final edited = _operations.upsertTerrainSurfaces(fixture.map, [
      spatialTestSurface('plateau', height: 2, left: 1, top: 1, size: 4),
    ]);
    expect(_borderInstances(edited), isNot(_borderInstances(fixture.map)));
  });

  test('a modified support rematerializes only its dependent Border', () {
    final fixture = _materialized();
    final edited = _operations.upsertTerrainSurfaces(fixture.map, [
      spatialTestSurface('plateau', height: 2, left: 1, top: 1, size: 4),
    ], pinBorderOwnedInstances: true);
    final refreshed = refreshSpatialBordersForTerrainChange(
      manifest: fixture.project,
      before: fixture.map,
      after: edited,
    );
    expect(refreshed.refreshed, ['border/fence']);
    expect(refreshed.stale, isEmpty);
    expect(
      _borderInstances(refreshed.map).map((instance) => instance.position.y),
      everyElement(2.0),
    );
    expect(_storedOutputMatchesReceipt(refreshed.map), isTrue);
    expect(_staleCodes(fixture.project, refreshed.map), isEmpty);
  });

  test('added and removed supports under the contour are detected', () {
    final bare = _materialized(withPlateau: false);
    final added = _operations.upsertTerrainSurfaces(bare.map, [
      spatialTestSurface('plateau', height: 1, left: 1, top: 1, size: 4),
    ], pinBorderOwnedInstances: true);
    final afterAdd = refreshSpatialBordersForTerrainChange(
      manifest: bare.project,
      before: bare.map,
      after: added,
    );
    expect(afterAdd.refreshed, ['border/fence']);
    expect(_staleCodes(bare.project, afterAdd.map), isEmpty);

    final removed = _operations.deleteTerrainSurfaces(afterAdd.map, [
      'plateau',
    ], pinBorderOwnedInstances: true);
    final afterRemove = refreshSpatialBordersForTerrainChange(
      manifest: bare.project,
      before: afterAdd.map,
      after: removed,
    );
    expect(afterRemove.refreshed, ['border/fence']);
    expect(
      _borderInstances(afterRemove.map),
      _borderInstances(bare.map),
    );
  });

  test('an unrelated support leaves the Border and its receipt untouched', () {
    final fixture = _materialized(far: true);
    final edited = _operations.upsertTerrainSurfaces(fixture.map, [
      spatialTestSurface('far', height: 3, left: 5, top: 5, size: 1),
    ], pinBorderOwnedInstances: true);
    final refreshed = refreshSpatialBordersForTerrainChange(
      manifest: fixture.project,
      before: fixture.map,
      after: edited,
    );
    expect(refreshed.refreshed, isEmpty);
    expect(refreshed.stale, isEmpty);
    expect(_feature(refreshed.map).materialization,
        _feature(fixture.map).materialization);
  });

  test('existing receipts keep their fingerprints', () {
    final fixture = _materialized(far: true);
    final withoutFar = _operations.deleteTerrainSurfaces(fixture.map, ['far']);
    final resolved = resolveSpatialBorderFeature(
      manifest: fixture.project,
      map: withoutFar,
      layerId: 'border',
      featureId: 'fence',
    );
    expect(
      resolved.result.materialization!.receipt,
      _feature(fixture.map).materialization!.receipt,
    );
  });
}

({ProjectManifest project, MapData map}) _materialized({
  bool withPlateau = true,
  bool far = false,
}) {
  final fixture = spatialCliffFixture(
    geometry: BorderRegionGeometry(
      width: 6,
      height: 6,
      cells: [
        for (var z = 0; z < 6; z++)
          for (var x = 0; x < 6; x++) x >= 1 && x <= 4 && z >= 1 && z <= 4,
      ],
    ),
    levels: List.filled(36, 0),
    surfaces: SpatialTerrainSurfaceSet(
      surfaces: [
        if (withPlateau)
          spatialTestSurface('plateau', height: 1, left: 1, top: 1, size: 4),
        if (far) spatialTestSurface('far', height: 1, left: 5, top: 5, size: 1),
      ],
    ),
  );
  final map = applySpatialBorderFeaturePreview(
    fixture.map,
    manifest: fixture.project,
    proposedResult: resolveSpatialBorderFeature(
      manifest: fixture.project,
      map: fixture.map,
      layerId: 'border',
      featureId: 'fence',
    ),
  );
  return (project: fixture.project, map: map);
}

BorderFeature _feature(MapData map) =>
    map.layers.whereType<BorderLayer>().single.content.features.single;

List<SpatialModelInstance> _borderInstances(MapData map) {
  final ids = _feature(map).generatedPlacementIds.toSet();
  return [
    for (final instance in map.spatialScene!.instances)
      if (ids.contains(instance.id)) instance,
  ];
}

bool _storedOutputMatchesReceipt(MapData map) {
  final materialization = _feature(map).materialization!;
  final instances = {
    for (final instance in map.spatialScene!.instances) instance.id: instance,
  };
  final fingerprint = 'sha256:${narrativeEventCanonicalSha256({
    'placements': [
      for (final placement in materialization.spatialPlacements)
        {
          'slotKey': placement.slotKey,
          'primitiveId': placement.primitiveId,
          'instanceId': placement.instanceId,
        },
    ],
    'instances': [
      for (final placement in materialization.spatialPlacements)
        instances[placement.instanceId]!.toJson(),
    ],
  })}';
  return fingerprint == materialization.receipt.outputFingerprint;
}

Set<String> _staleCodes(ProjectManifest project, MapData map) => {
      for (final diagnostic in diagnoseSpatialBorderFeature(
        manifest: project,
        map: map,
        layerId: 'border',
        featureId: 'fence',
      ).diagnostics)
        if (diagnostic.code == 'border.spatial.materialization_stale')
          diagnostic.code,
    };

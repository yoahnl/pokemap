import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'spatial_border_face_ground_test.dart'
    show spatialCliffFixture, spatialTestSurface;
import '../support/spatial_border_ground_surface_fixture.dart'
    show spatialBorderFixture;

const _operations = SpatialMapOperations();

void main() {
  test('model-attached stairs do not lift native Border terrain support', () {
    final fixture = _stairFixture(attached: true);
    final before = jsonEncode(fixture.map.toJson());
    final scene = fixture.map.spatialScene!;
    final resolved = resolveSpatialBorderFeature(
      manifest: fixture.project,
      map: fixture.map,
      layerId: 'border',
      featureId: 'fence',
    );
    expect(scene.worldHeightAt(2.5, 2.5), 1.5);
    expect(resolved.result.canApply, isTrue);
    expect(
      resolved.modelInstances.map((instance) => instance.position.y),
      everyElement(1.0),
    );
    expect(jsonEncode(fixture.map.toJson()), before);
    final applied = applySpatialBorderFeaturePreview(
      fixture.map,
      manifest: fixture.project,
      proposedResult: resolved,
    );
    expect(applied.spatialScene!.navigation, scene.navigation);
    expect(
      applied.spatialScene!.instances.singleWhere(
        (instance) => instance.id == 'stairs',
      ),
      scene.instances.single,
    );
    expect(_staleCodes(fixture.project, applied), isEmpty);
  });

  test('unattached terrain ramps remain valid Border supports', () {
    final fixture = _stairFixture(attached: false);
    final resolved = resolveSpatialBorderFeature(
      manifest: fixture.project,
      map: fixture.map,
      layerId: 'border',
      featureId: 'fence',
    );
    expect(resolved.result.canApply, isTrue);
    expect(resolved.modelInstances.map((instance) => instance.position.y), [
      1.5,
      .5,
    ]);
  });

  test(
    'historical stair-anchored receipts remain readable and fresh without rewriting',
    () {
      final fixture = _stairFixture(attached: true);
      final source = SpatialBorderResolutionContext.fromMap(fixture.map);
      final historical = resolveSpatialBorderFeatureInContext(
        manifest: fixture.project,
        context: SpatialBorderResolutionContext(
          mapId: source.mapId,
          size: source.size,
          layers: source.layers,
          instances: source.instances,
          worldHeightAt: fixture.map.spatialScene!.worldHeightAt,
          fingerprintContext: source.fingerprintContext,
          groundModeledAt: source.groundModeledAt,
          paintsFirstLayerInFront: source.paintsFirstLayerInFront,
        ),
        layerId: 'border',
        featureId: 'fence',
      );
      final original = _feature(fixture.map);
      final saved = upsertBorderFeature(
        fixture.map.copyWith(
          spatialScene: fixture.map.spatialScene!.copyWith(
            instances: [...source.instances, ...historical.modelInstances],
          ),
        ),
        layerId: 'border',
        feature: BorderFeature(
          id: original.id,
          name: original.name,
          blueprintId: original.blueprintId,
          seed: original.seed,
          geometry: original.geometry,
          overrides: original.overrides,
          keepOutRegions: original.keepOutRegions,
          materialization: historical.result.materialization,
        ),
      );
      final bytes = jsonEncode(saved.toJson());
      final reopened = MapData.fromJson(
        jsonDecode(bytes) as Map<String, dynamic>,
      );
      MapValidator.validate(reopened, projectDialogueContext: fixture.project);
      expect(
        _feature(reopened).materialization!.receipt,
        historical.result.materialization!.receipt,
      );
      expect(_staleCodes(fixture.project, reopened), isEmpty);
      expect(jsonEncode(reopened.toJson()), bytes);
      final moved = reopened.spatialScene!.instances
          .map(
            (instance) => instance.id == historical.modelInstances.first.id
                ? instance.copyWith(
                    position: Model3dVector3(
                      x: instance.position.x,
                      y: 9,
                      z: instance.position.z,
                    ),
                  )
                : instance,
          )
          .toList();
      expect(
        _staleCodes(
          fixture.project,
          reopened.copyWith(
            spatialScene: reopened.spatialScene!.copyWith(instances: moved),
          ),
        ),
        isNotEmpty,
      );
    },
  );

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

({ProjectManifest project, MapData map}) _stairFixture({
  required bool attached,
}) {
  final fixture = spatialBorderFixture();
  final map = updateBorderFeatureGeometry(
    fixture.map,
    layerId: 'border',
    featureId: 'fence',
    geometry: BorderStrokeGeometry(
      strokes: [
        BorderStroke(
          id: 'edge',
          points: const [GridPos(x: 2, y: 2), GridPos(x: 2, y: 3)],
          closed: false,
        ),
      ],
    ),
  );
  return (
    project: fixture.project,
    map: map.copyWith(
      spatialScene: MapSpatialScene(
        width: 6,
        depth: 6,
        heightLevels: [
          for (var z = 0; z < 6; z++)
            for (var x = 0; x < 6; x++)
              z <= 1
                  ? 2
                  : attached && z < 4
                  ? 1
                  : 0,
        ],
        instances: [
          if (attached)
            SpatialModelInstance(
              id: 'stairs',
              modelId: 'unit',
              position: Model3dVector3(x: 2, y: 1, z: 2),
              blocksMovement: false,
            ),
        ],
        navigation: SpatialNavigationProfile(
          ramps: [
            SpatialRamp(
              id: 'stairs',
              x: 2,
              z: 2,
              width: 1,
              depth: 2,
              lowLevel: 0,
              highLevel: 2,
              direction: SpatialRampDirection.north,
              surfaceInstanceId: attached ? 'stairs' : null,
            ),
          ],
        ),
      ),
    ),
  );
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

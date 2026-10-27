import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_scene_decoration.dart';
import 'package:map_render_3d/src/spatial_ground.dart';

import '../../map_core/test/support/spatial_border_ground_surface_fixture.dart';

void main() {
  Future<Uint8List> load(String _) async => Uint8List(0);
  test('one applied 70-part native contour keeps IDs and sequence across render batches', () {
    final fixture = sequenceFixture(count: 70);
    final feature =
        (fixture.map.layers.single as BorderLayer).content.features.single;
    final border = ExteriorDecorationBorder(
      id: feature.id,
      layerId: 'border',
      originX: -32,
      originZ: -8,
      width: 96,
      depth: 8,
      feature: feature,
    );
    final playable = fixture.map.copyWith(
      size: const GridSize(width: 32, height: 8),
      spatialScene: MapSpatialScene(width: 32, depth: 8),
      layers: [],
    );
    final definition = MapExteriorDecoration(
      mapId: playable.id,
      playableWidth: 32,
      playableDepth: 8,
      west: 32,
      east: 32,
      north: 8,
      sectors: [
        for (var i = 0; i < 3; i++)
          ExteriorDecorationSector(
            id: 's$i',
            originX: -32 + i * 32,
            originZ: -8,
            scene: MapSpatialScene(width: 32, depth: 8),
          ),
      ],
      borders: [border],
    );
    final native = resolveExteriorDecorationBorder(
      manifest: fixture.project,
      decoration: definition,
      border: border,
      playableMap: playable,
    );
    final applied = applyExteriorDecorationBorderResolution(border, native);
    final document = MapExteriorDecoration(
      mapId: playable.id,
      playableWidth: 32,
      playableDepth: 8,
      west: 32,
      east: 32,
      north: 8,
      sectors: definition.sectors,
      borders: [applied],
    );
    final source = SpatialSceneDecoration(
      ownerMapId: playable.id,
      decoration: document,
      offset: Offset.zero,
      project: fixture.project,
      loadGroundImage: load,
      loadModel: load,
    );
    final projections = projectSpatialDecorations(
      decorations: [source],
      playableBounds: const [Rect.fromLTWH(0, 0, 32, 8)],
      nativeMaps: [(map: playable, offset: Offset.zero)],
    );
    final batches = projections
        .where((projection) => !projection.renderTerrainBase)
        .toList();
    expect(batches, hasLength(3));
    final instances = {
      for (final projection in batches)
        for (final instance in projection.map.spatialScene!.instances)
          instance.id: (
            instance.modelId,
            instance.position.x + projection.offset.dx,
            instance.position.y,
            instance.position.z + projection.offset.dy,
          ),
    };
    expect(instances, {
      for (final instance in native.modelInstances)
        instance.id: (
          instance.modelId,
          instance.position.x - 32,
          instance.position.y,
          instance.position.z - 8,
        ),
    });
    expect(
      batches.every(
        (batch) =>
            batch.map.spatialScene!.width <= 32 &&
            batch.map.spatialScene!.depth <= 32,
      ),
      isTrue,
    );
    expect(
      batches.every(
        (batch) =>
            batch.excludedCells.length ==
            batch.sector.scene.width * batch.sector.scene.depth,
      ),
      isTrue,
    );
    final repeated = projectSpatialDecorations(
      decorations: [source],
      playableBounds: const [Rect.fromLTWH(0, 0, 32, 8)],
      nativeMaps: [(map: playable, offset: Offset.zero)],
      previous: {for (final p in projections) p.key: p},
    );
    expect(repeated.map((p) => p.key), projections.map((p) => p.key));
    for (var i = 0; i < projections.length; i++) {
      expect(repeated[i].map, same(projections[i].map));
      expect(repeated[i].sector, same(projections[i].sector));
      expect(repeated[i].borderGround, same(projections[i].borderGround));
    }
  });

  test('logical native ground surfaces feed sector plans without re-resolving the contour', () {
    final fixture = surfaceFixture();
    final feature =
        (fixture.map.layers.single as BorderLayer).content.features.single;
    final border = ExteriorDecorationBorder(
      id: feature.id,
      layerId: 'border',
      originX: -8,
      originZ: -8,
      width: 8,
      depth: 8,
      feature: feature,
    );
    final playable = fixture.map.copyWith(layers: []);
    final sector = ExteriorDecorationSector(
      id: 'native',
      originX: -8,
      originZ: -8,
      scene: fixture.map.spatialScene!,
    );
    final definition = MapExteriorDecoration(
      mapId: playable.id,
      playableWidth: playable.size.width,
      playableDepth: playable.size.height,
      west: 8,
      north: 8,
      sectors: [sector],
      borders: [border],
    );
    final native = resolveExteriorDecorationBorder(
      manifest: fixture.project,
      decoration: definition,
      border: border,
      playableMap: playable,
    );
    final applied = applyExteriorDecorationBorderResolution(border, native);
    final document = MapExteriorDecoration(
      mapId: playable.id,
      playableWidth: playable.size.width,
      playableDepth: playable.size.height,
      west: 8,
      north: 8,
      sectors: [sector],
      borders: [applied],
    );
    final source = SpatialSceneDecoration(
      ownerMapId: playable.id,
      decoration: document,
      offset: Offset.zero,
      project: fixture.project,
      loadGroundImage: load,
      loadModel: load,
    );
    final projections = projectSpatialDecorations(
      decorations: [source],
      playableBounds: const [],
      nativeMaps: [(map: playable, offset: Offset.zero)],
    );
    final projected = projections.firstWhere(
      (projection) => projection.renderTerrainBase,
    );
    expect(projected.borderGround.surfaces, isNotEmpty);
    final hidden = native.modelInstances.first;
    final model = fixture.project.models3d.firstWhere(
      (model) => model.id == hidden.modelId,
    );
    final bounds = spatialDecorationModelFootprint(
      hidden,
      model,
      const Offset(-8, -8),
    );
    final masked = projectSpatialDecorations(
      decorations: [source],
      playableBounds: [
        Rect.fromCenter(center: bounds.center, width: .01, height: .01),
      ],
      nativeMaps: [(map: playable, offset: Offset.zero)],
      previous: {
        for (final projection in projections) projection.key: projection,
      },
    );
    final maskedGround = masked
        .firstWhere((projection) => projection.renderTerrainBase)
        .borderGround;
    expect(
      maskedGround.surfaces.length,
      projected.borderGround.surfaces.length - 2,
    );
    expect(maskedGround, isNot(same(projected.borderGround)));

    final plan = SpatialGroundPlan(
      projected.map,
      fixture.project,
      additionalBorders: projected.borderGround,
    );
    expect(plan.resolve(0), isNotEmpty);
    final original = applySpatialBorderFeaturePreview(
      fixture.map,
      manifest: fixture.project,
      proposedResult: resolveSpatialBorderFeature(
        manifest: fixture.project,
        map: fixture.map,
        layerId: 'border',
        featureId: feature.id,
      ),
    );
    final reference = SpatialGroundPlan(original, fixture.project);
    expect(
      plan.resolve(0).map((item) => (item.height, item.visual.sourceRect)),
      reference.resolve(0).map((item) => (item.height, item.visual.sourceRect)),
    );
  });
}

Map<String, Object?> sequenceRecordJson({int length = 6}) {
  final fixture = spatialBorderFixture(
    straightOnly: true,
    includeCorner: false,
  );
  final raw = encodeBorderBlueprintRecordJson(
    fixture.project.borderCatalog.records.single,
    formatVersion: 11,
  );
  for (final definition in [
    (raw['draft'] as Map)['definition'] as Map,
    (raw['latestPublished'] as Map)['definition'] as Map,
  ]) {
    final body = Map<String, Object?>.from(
      (definition['primitives'] as List).last as Map,
    );
    definition['sequenceLength'] = length;
    definition['primitives'] = [
      for (var phase = 0; phase < length; phase++)
        for (final role in ['body', 'start', 'end'])
          {
            ...body,
            'id': 'phase-$phase-$role',
            'sequenceIndex': phase,
            'sourceModelId': 'unit-$phase',
            'role': role == 'body' ? 'lineStraight' : 'lineCap',
            'authoredOrientation': role == 'end' ? 'west' : 'east',
            'transforms': {
              'allowFlipX': false,
              'allowedQuarterTurns': [0, 1],
            },
          },
    ];
  }
  return raw;
}

({ProjectManifest project, MapData map}) sequenceFixture({
  int count = 13,
  bool vertical = false,
  bool reverse = false,
}) {
  final base = spatialBorderFixture(straightOnly: true, includeCorner: false);
  final record = decodeBorderBlueprintRecordJson(
    sequenceRecordJson(),
    formatVersion: 12,
  );
  final project = base.project.copyWith(
    borderCatalog: ProjectBorderCatalog(formatVersion: 12, records: [record]),
    models3d: [
      for (var phase = 0; phase < 6; phase++)
        ProjectModel3dEntry.fromJson({
          ...base.project.models3d.single.toJson(),
          'id': 'unit-$phase',
          'sourceAssetId': 'model3d_unit-$phase',
          'relativePath': 'assets/models3d/unit-$phase.glb',
        }),
    ],
  );
  final points = [
    for (var index = 0; index < count; index++)
      GridPos(x: 4 + (vertical ? 0 : index), y: 4 + (vertical ? index : 0)),
  ];
  final map = updateBorderFeatureGeometry(
    base.map.copyWith(
      size: const GridSize(width: 64, height: 64),
      spatialScene: MapSpatialScene(width: 64, depth: 64),
    ),
    layerId: 'border',
    featureId: 'fence',
    geometry: BorderStrokeGeometry(
      strokes: [
        BorderStroke(
          id: 'line',
          points: reverse ? points.reversed.toList() : points,
          closed: false,
        ),
      ],
    ),
  );
  return (project: project, map: map);
}

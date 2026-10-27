import 'dart:convert';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/spatial_border_ground_surface_fixture.dart';
import 'border/spatial_border_sequence_test.dart' show sequenceFixture, phases;
import 'border/spatial_border_corner_sequence_test.dart'
    show cornerSequenceJson;

BorderFeature featureOf(MapData map) =>
    (map.layers.single as BorderLayer).content.features.single;

void main() {
  test(
    'logical Border application rejects a preview resolved for older geometry',
    () {
      final fixture = spatialBorderFixture();
      final border = ExteriorDecorationBorder(
        id: 'fence',
        layerId: 'border',
        originX: -6,
        originZ: 0,
        width: 6,
        depth: 6,
        feature: featureOf(fixture.map),
      );
      final decoration = MapExteriorDecoration(
        mapId: 'map',
        playableWidth: 6,
        playableDepth: 6,
        west: 6,
        borders: [border],
      );
      final preview = resolveExteriorDecorationBorder(
        manifest: fixture.project,
        decoration: decoration,
        border: border,
        playableMap: fixture.map,
      );
      final edited = updateBorderFeatureGeometry(
        fixture.map,
        layerId: 'border',
        featureId: 'fence',
        geometry: BorderStrokeGeometry(
          strokes: [
            BorderStroke(
              id: 'line',
              closed: false,
              points: const [
                GridPos(x: 1, y: 1),
                GridPos(x: 2, y: 1),
                GridPos(x: 3, y: 1),
                GridPos(x: 4, y: 1),
              ],
            ),
          ],
        ),
      );
      final changed = ExteriorDecorationBorder(
        id: 'fence',
        layerId: 'border',
        originX: -6,
        originZ: 0,
        width: 6,
        depth: 6,
        feature: featureOf(edited),
      );
      expect(
        () => applyExteriorDecorationBorderResolution(changed, preview),
        throwsA(isA<ValidationException>()),
      );
    },
  );
  test(
    'closed contour keeps global corner ownership across sector boundaries',
    () {
      final fixture = spatialBorderFixture();
      final record = decodeBorderBlueprintRecordJson(
        cornerSequenceJson(cornerJoinCells: 1),
        formatVersion: 13,
      );
      final project = fixture.project.copyWith(
        borderCatalog: ProjectBorderCatalog(
          formatVersion: 13,
          records: [record],
        ),
      );
      final geometry = BorderStrokeGeometry(
        strokes: [
          BorderStroke(
            id: 'loop',
            closed: true,
            points: [
              for (var x = 28; x <= 36; x++) GridPos(x: x, y: 1),
              for (var z = 2; z <= 5; z++) GridPos(x: 36, y: z),
              for (var x = 35; x >= 28; x--) GridPos(x: x, y: 5),
              for (var z = 4; z >= 2; z--) GridPos(x: 28, y: z),
            ],
          ),
        ],
      );
      final source = updateBorderFeatureGeometry(
        fixture.map.copyWith(
          size: const GridSize(width: 64, height: 8),
          spatialScene: MapSpatialScene(width: 64, depth: 8),
        ),
        layerId: 'border',
        featureId: 'fence',
        geometry: geometry,
      );
      final border = ExteriorDecorationBorder(
        id: 'fence',
        layerId: 'border',
        originX: -32,
        originZ: -8,
        width: 64,
        depth: 8,
        feature: featureOf(source),
      );
      final decoration = MapExteriorDecoration(
        mapId: 'map',
        playableWidth: 32,
        playableDepth: 8,
        west: 32,
        north: 8,
        borders: [border],
        sectors: [
          for (var index = 0; index < 2; index++)
            ExteriorDecorationSector(
              id: 's$index',
              originX: -32 + index * 32,
              originZ: -8,
              scene: MapSpatialScene(width: 32, depth: 8),
            ),
        ],
      );
      final playable = fixture.map.copyWith(
        size: const GridSize(width: 32, height: 8),
        spatialScene: MapSpatialScene(width: 32, depth: 8),
        layers: [],
      );
      final expected = resolveSpatialBorderFeature(
        manifest: project,
        map: source,
        layerId: 'border',
        featureId: 'fence',
      );
      final actual = resolveExteriorDecorationBorder(
        manifest: project,
        decoration: decoration,
        border: border,
        playableMap: playable,
      );
      expect(actual.result.canApply, isTrue);
      expect(actual.modelInstances, expected.modelInstances);
      expect(
        actual.result.materialization!.spatialPlacements,
        expected.result.materialization!.spatialPlacements,
      );
      expect(
        actual.result.materialization!.spatialPlacements.where(
          (placement) => placement.primitiveId.contains('lineCorner'),
        ),
        hasLength(4),
      );
      expect(
        actual.modelInstances.map((instance) => instance.id).toSet(),
        hasLength(actual.modelInstances.length),
      );
    },
  );
  test('MapData adapter keeps native resolution and receipt identity', () {
    final fixture = spatialBorderFixture();
    final original = resolveSpatialBorderFeature(
      manifest: fixture.project,
      map: fixture.map,
      layerId: 'border',
      featureId: 'fence',
    );
    final contextual = resolveSpatialBorderFeatureInContext(
      manifest: fixture.project,
      context: SpatialBorderResolutionContext.fromMap(fixture.map),
      layerId: 'border',
      featureId: 'fence',
    );
    expect(contextual.modelInstances, original.modelInstances);
    expect(contextual.result.materialization, original.result.materialization);
    expect(
      contextual.result.materialization!.receipt.inputFingerprint,
      original.result.materialization!.receipt.inputFingerprint,
    );
  });

  test(
    'one native sequence crosses sectors without restarting or duplicate slots',
    () {
      final fixture = sequenceFixture(count: 70);
      final border = ExteriorDecorationBorder(
        id: 'fence',
        layerId: 'border',
        originX: -32,
        originZ: -8,
        width: 96,
        depth: 8,
        feature: featureOf(fixture.map),
      );
      final sectors = [
        for (var index = 0; index < 3; index++)
          ExteriorDecorationSector(
            id: 's$index',
            originX: -32 + index * 32,
            originZ: -8,
            scene: MapSpatialScene(
              width: 32,
              depth: 8,
              heightLevels: List.filled(256, index),
            ),
          ),
      ];
      final decoration = MapExteriorDecoration(
        mapId: 'map',
        playableWidth: 32,
        playableDepth: 8,
        west: 32,
        east: 32,
        north: 8,
        sectors: sectors,
        borders: [border],
      );
      final playable = fixture.map.copyWith(
        size: const GridSize(width: 32, height: 8),
        spatialScene: MapSpatialScene(width: 32, depth: 8),
        layers: [],
      );
      final resolved = resolveExteriorDecorationBorder(
        manifest: fixture.project,
        decoration: decoration,
        border: border,
        playableMap: playable,
      );
      expect(resolved.result.canApply, isTrue);
      expect(resolved.modelInstances, hasLength(70));
      expect(
        resolved.modelInstances.map((instance) => instance.id).toSet(),
        hasLength(70),
      );
      expect(phases(resolved), [
        for (var index = 0; index < 70; index++) index % 6,
      ]);
      final reference = fixture.map.copyWith(
        size: const GridSize(width: 96, height: 8),
        spatialScene: MapSpatialScene(
          width: 96,
          depth: 8,
          heightLevels: List.generate(96 * 8, (index) => (index % 96) ~/ 32),
        ),
      );
      final whole = resolveSpatialBorderFeature(
        manifest: fixture.project,
        map: reference,
        layerId: 'border',
        featureId: 'fence',
      );
      expect(resolved.modelInstances, whole.modelInstances);
      expect(
        resolved.result.materialization!.spatialPlacements,
        whole.result.materialization!.spatialPlacements,
      );
      final applied = applyExteriorDecorationBorderResolution(border, resolved);
      expect(
        ExteriorDecorationBorder.fromJson(
          jsonDecode(jsonEncode(applied.toJson())),
        ),
        applied,
      );
      expect(applied.instances, resolved.modelInstances);
      expect(
        applied.resourceReferenceIds,
        containsAll(['fence', 'unit-0', 'unit-5']),
      );
    },
  );

  test(
    'logical 384 terrain is sampled only at actual native contour dependencies',
    () {
      final fixture = spatialBorderFixture();
      final border = ExteriorDecorationBorder(
        id: 'fence',
        layerId: 'border',
        originX: -64,
        originZ: -64,
        width: 384,
        depth: 384,
        feature: featureOf(fixture.map),
      );
      final decoration = MapExteriorDecoration(
        mapId: 'map',
        playableWidth: 256,
        playableDepth: 256,
        west: 64,
        east: 64,
        north: 64,
        south: 64,
        borders: [border],
      );
      final playable = fixture.map.copyWith(
        size: const GridSize(width: 256, height: 256),
        spatialScene: MapSpatialScene(width: 256, depth: 256),
        layers: [],
      );
      final context = createExteriorDecorationBorderContext(
        decoration: decoration,
        border: border,
        playableMap: playable,
      );
      final resolved = resolveSpatialBorderFeatureInContext(
        manifest: fixture.project,
        context: context,
        layerId: 'border',
        featureId: 'fence',
      );
      expect(resolved.result.canApply, isTrue);
      expect(
        (context.fingerprintContext()['samples'] as List).length,
        lessThanOrEqualTo(5),
      );
      expect(
        () => MapSpatialScene(width: 384, depth: 384),
        throwsFormatException,
      );
    },
  );

  test(
    'unrelated sector heights do not invalidate a logical contour receipt',
    () {
      final fixture = spatialBorderFixture();
      final border = ExteriorDecorationBorder(
        id: 'fence',
        layerId: 'border',
        originX: -8,
        originZ: -8,
        width: 8,
        depth: 8,
        feature: featureOf(fixture.map),
      );
      MapExteriorDecoration document(int unrelated, int touched) =>
          MapExteriorDecoration(
            mapId: 'map',
            playableWidth: 8,
            playableDepth: 8,
            west: 8,
            north: 8,
            east: 8,
            borders: [border],
            sectors: [
              ExteriorDecorationSector(
                id: 'needed',
                originX: -8,
                originZ: -8,
                scene: MapSpatialScene(
                  width: 8,
                  depth: 8,
                  heightLevels: List.filled(64, touched),
                ),
              ),
              ExteriorDecorationSector(
                id: 'unrelated',
                originX: 8,
                originZ: 0,
                scene: MapSpatialScene(
                  width: 8,
                  depth: 8,
                  heightLevels: List.filled(64, unrelated),
                ),
              ),
            ],
          );
      final playable = fixture.map.copyWith(
        size: const GridSize(width: 8, height: 8),
        spatialScene: MapSpatialScene(width: 8, depth: 8),
        layers: [],
      );
      SpatialBorderResolutionResult run(MapExteriorDecoration value) =>
          resolveExteriorDecorationBorder(
            manifest: fixture.project,
            decoration: value,
            border: border,
            playableMap: playable,
          );
      final original = run(document(0, 1));
      expect(
        run(document(3, 1)).result.materialization!.receipt.inputFingerprint,
        original.result.materialization!.receipt.inputFingerprint,
      );
      expect(
        run(document(0, 2)).result.materialization!.receipt.inputFingerprint,
        isNot(original.result.materialization!.receipt.inputFingerprint),
      );
    },
  );

  test('native ground semantics project from one whole applied context', () {
    final fixture = surfaceFixture();
    final resolved = resolveSpatialBorderFeature(
      manifest: fixture.project,
      map: fixture.map,
      layerId: 'border',
      featureId: 'fence',
    );
    final applied = applySpatialBorderFeaturePreview(
      fixture.map,
      manifest: fixture.project,
      proposedResult: resolved,
    );
    final context = SpatialBorderResolutionContext.fromMap(applied);
    expect(
      resolveSpatialBorderGroundMaskCellsByLayerInContext(
        manifest: fixture.project,
        context: context,
      ),
      resolveSpatialBorderGroundMaskCellsByLayer(
        manifest: fixture.project,
        map: applied,
      ),
    );
    expect(
      resolveSpatialBorderGroundReplacementsByLayerInContext(
        manifest: fixture.project,
        context: context,
      ),
      resolveSpatialBorderGroundReplacementsByLayer(
        manifest: fixture.project,
        map: applied,
      ),
    );
    final direct = resolveSpatialBorderGroundSurfaces(
      manifest: fixture.project,
      map: applied,
    );
    final contextual = resolveSpatialBorderGroundSurfacesInContext(
      manifest: fixture.project,
      context: context,
    );
    expect(contextual, hasLength(direct.length));
    expect(contextual, isNotEmpty);
    for (var index = 0; index < direct.length; index++) {
      expect(contextual[index].height, direct[index].height);
      expect(contextual[index].footprints, direct[index].footprints);
    }
  });

  test(
    'logical Border documents reject wrong ownership actor data and future schemas',
    () {
      final fixture = spatialBorderFixture();
      final border = ExteriorDecorationBorder(
        id: 'fence',
        layerId: 'border',
        originX: -8,
        originZ: -8,
        width: 8,
        depth: 8,
        feature: featureOf(fixture.map),
      );
      expect(
        () => ExteriorDecorationBorder.fromJson({
          ...border.toJson(),
          'schemaVersion': 2,
        }),
        throwsFormatException,
      );
      expect(
        () => ExteriorDecorationBorder.fromJson({
          ...border.toJson(),
          'events': [],
        }),
        throwsFormatException,
      );
      expect(
        () => ExteriorDecorationBorder(
          id: 'other',
          layerId: 'border',
          originX: -8,
          originZ: -8,
          width: 8,
          depth: 8,
          feature: border.feature,
        ),
        throwsFormatException,
      );
      expect(
        () => ExteriorDecorationBorder(
          id: 'fence',
          layerId: 'border',
          originX: -8,
          originZ: -8,
          width: 385,
          depth: 8,
          feature: border.feature,
        ),
        throwsFormatException,
      );
      expect(
        () => MapExteriorDecoration(
          mapId: 'map',
          playableWidth: 8,
          playableDepth: 8,
          borders: [border],
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'logical Border JSON rejects unknown fields on otherwise valid owned instances',
    () {
      final fixture = spatialBorderFixture();
      final result = resolveSpatialBorderFeature(
        manifest: fixture.project,
        map: fixture.map,
        layerId: 'border',
        featureId: 'fence',
      );
      final applied = applySpatialBorderFeaturePreview(
        fixture.map,
        manifest: fixture.project,
        proposedResult: result,
      );
      final border = ExteriorDecorationBorder(
        id: 'fence',
        layerId: 'border',
        originX: -6,
        originZ: 0,
        width: 6,
        depth: 6,
        feature: featureOf(applied),
        instances: applied.spatialScene!.instances,
      );
      final json = border.toJson();
      (json['instances'] as List).first['events'] = [];
      expect(
        () => ExteriorDecorationBorder.fromJson(json),
        throwsFormatException,
      );
    },
  );
}

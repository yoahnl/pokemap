import 'dart:math' as math;

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/spatial_border_ground_surface_fixture.dart';
export '../support/spatial_border_ground_surface_fixture.dart'
    show spatialBorderFixture, borderSpatialTransforms;

void main() {
  test('inverted repeated shore units preserve all 36 source poses', () {
    final cases = [
      (
        x: 28,
        z: 58,
        count: 3,
        vertical: false,
        authored: 1,
        rotation: -90.0,
        dx: 0.0,
        dz: .125,
        level: 2,
        y: .25,
      ),
      (
        x: 32,
        z: 60,
        count: 3,
        vertical: false,
        authored: 1,
        rotation: -90.0,
        dx: 0.0,
        dz: .125,
        level: 2,
        y: .25,
      ),
      (
        x: 35,
        z: 61,
        count: 2,
        vertical: true,
        authored: 1,
        rotation: -180.0,
        dx: -.125,
        dz: 0.0,
        level: 2,
        y: .25,
      ),
      (
        x: 28,
        z: 20,
        count: 7,
        vertical: false,
        authored: 0,
        rotation: -180.0,
        dx: 0.0,
        dz: -.125,
        level: 1,
        y: 0.0,
      ),
      (
        x: 29,
        z: 16,
        count: 2,
        vertical: true,
        authored: 0,
        rotation: -270.0,
        dx: .125,
        dz: 0.0,
        level: 1,
        y: 0.0,
      ),
      (
        x: 35,
        z: 21,
        count: 3,
        vertical: true,
        authored: 0,
        rotation: -270.0,
        dx: .125,
        dz: 0.0,
        level: 1,
        y: 0.0,
      ),
      (
        x: 36,
        z: 24,
        count: 4,
        vertical: false,
        authored: 0,
        rotation: -180.0,
        dx: 0.0,
        dz: -.125,
        level: 1,
        y: 0.0,
      ),
      (
        x: 37,
        z: 14,
        count: 3,
        vertical: true,
        authored: 0,
        rotation: -270.0,
        dx: .125,
        dz: 0.0,
        level: 1,
        y: 0.0,
      ),
      (
        x: 41,
        z: 16,
        count: 9,
        vertical: false,
        authored: 0,
        rotation: -180.0,
        dx: 0.0,
        dz: -.125,
        level: 1,
        y: 0.0,
      ),
    ];
    var units = 0;
    for (final source in cases) {
      final fixture = repeatedUnitBorderFixture(authoredTurns: source.authored);
      final points = [
        for (var index = 0; index < source.count; index++)
          GridPos(
            x: source.x + (source.vertical ? 0 : index),
            y: source.z + (source.vertical ? index : 0),
          ),
      ];
      final map = updateBorderFeatureGeometry(
        fixture.map.copyWith(
          size: const GridSize(width: 64, height: 64),
          spatialScene: MapSpatialScene(
            width: 64,
            depth: 64,
            levelHeight: .25,
            heightLevels: List.filled(4096, source.level),
          ),
        ),
        layerId: 'border',
        featureId: 'fence',
        geometry: BorderStrokeGeometry(
          alignment: BorderStrokeAlignment.cellCenters,
          strokes: [BorderStroke(id: 'line', points: points, closed: false)],
        ),
      );
      final feature =
          (map.layers.single as BorderLayer).content.features.single;
      final prepared = upsertBorderFeature(
        map,
        layerId: 'border',
        feature: decodeBorderFeatureJson({
          ...encodeBorderFeatureJson(feature, formatVersion: 4),
          'spatialOffsetWorld': {'x': source.dx, 'y': 0, 'z': source.dz},
        }, formatVersion: 4),
      );
      final result = resolve(fixture.project, prepared);
      expect(result.result.canApply, isTrue);
      expect(result.modelInstances, hasLength(source.count));
      for (var index = 0; index < source.count; index++) {
        final instance = result.modelInstances[index];
        expect(
          instance.position,
          Model3dVector3(
            x: points[index].x + .5 + source.dx,
            y: source.y,
            z: points[index].y + .5 + source.dz,
          ),
        );
        expect(instance.rotationDegrees, source.rotation);
      }
      final placements = result.result.materialization!.spatialPlacements;
      expect(placements.first.primitiveId, 'positive');
      expect(placements.last.primitiveId, 'negative');
      final applied = applySpatialBorderFeaturePreview(
        prepared,
        manifest: fixture.project,
        proposedResult: result,
      );
      validateSpatialMapStructure(applied);
      final reopened = MapData.fromJson(applied.toJson());
      expect(reopened, applied);
      expect(
        resolve(fixture.project, reopened).modelInstances,
        result.modelInstances,
      );
      expect(
        diagnoseSpatialBorderFeature(
          manifest: fixture.project,
          map: reopened,
          layerId: 'border',
          featureId: 'fence',
        ).hasErrors,
        isFalse,
      );
      units += source.count;
    }
    expect(units, 36);
  });

  test('inverted repeated unit anchors use the effective model pivot', () {
    final fixture = repeatedUnitBorderFixture(usePivotAnchor: true);
    final source = fixture.project.borderCatalog.records.single;
    final raw = encodeBorderBlueprintRecordJson(source, formatVersion: 5);
    final primitives =
        (raw['latestPublished'] as Map)['definition']['primitives'] as List;
    primitives[0]['anchorWorld'] = {'x': 0, 'y': 0, 'z': 0};
    final project = fixture.project.copyWith(
      borderCatalog: ProjectBorderCatalog(
        formatVersion: 5,
        records: [decodeBorderBlueprintRecordJson(raw, formatVersion: 5)],
      ),
    );
    expect(resolve(project, fixture.map).result.canApply, isTrue);
    primitives[0]['anchorWorld'] = {'x': 0, 'y': .25, 'z': 0};
    final different = project.copyWith(
      borderCatalog: ProjectBorderCatalog(
        formatVersion: 5,
        records: [decodeBorderBlueprintRecordJson(raw, formatVersion: 5)],
      ),
    );
    expect(resolve(different, fixture.map).result.canApply, isFalse);
  });

  test(
    'inverted repeated units retain explicit transforms limits and stale receipts',
    () {
      final fixture = repeatedUnitBorderFixture();
      final preview = resolve(fixture.project, fixture.map);
      expect(preview.result.canApply, isTrue);
      final body = preview.result.materialization!.spatialPlacements[1];
      final overridden = updateBorderFeatureOverrides(
        fixture.map,
        layerId: 'border',
        featureId: 'fence',
        overrides: [
          BorderSlotOverride(
            slotKey: body.slotKey,
            variationSalt: BorderSignedInt64.zero,
            suppressed: false,
            locked: false,
            transformOverride: BorderSpriteTransform(
              quarterTurns: 0,
              flipX: false,
            ),
          ),
        ],
      );
      expect(
        resolve(fixture.project, overridden).modelInstances[1].rotationDegrees,
        0,
      );
      final restricted = encodeBorderBlueprintRecordJson(
        fixture.project.borderCatalog.records.single,
        formatVersion: 5,
      );
      ((restricted['latestPublished'] as Map)['definition']['primitives']
              as List)
          .first['transforms']['allowedQuarterTurns'] = [
        0,
      ];
      final restrictedProject = fixture.project.copyWith(
        borderCatalog: ProjectBorderCatalog(
          formatVersion: 5,
          records: [
            decodeBorderBlueprintRecordJson(restricted, formatVersion: 5),
          ],
        ),
      );
      expect(
        resolve(
          restrictedProject,
          fixture.map,
        ).result.diagnostics.map((value) => value.code),
        contains('border.spatial.orientation_missing'),
      );
      expect(
        () => applySpatialBorderFeaturePreview(
          overridden,
          manifest: fixture.project,
          proposedResult: preview,
        ),
        throwsA(isA<ValidationException>()),
      );
      final applied = applySpatialBorderFeaturePreview(
        fixture.map,
        manifest: fixture.project,
        proposedResult: preview,
      );
      final raised = applied.copyWith(
        spatialScene: applied.spatialScene!.copyWith(
          heightLevels: List.filled(36, 5),
        ),
      );
      expect(
        diagnoseSpatialBorderFeature(
          manifest: fixture.project,
          map: raised,
          layerId: 'border',
          featureId: 'fence',
        ).diagnostics.map((value) => value.code),
        contains('border.spatial.materialization_stale'),
      );
      final regenerated = resolve(fixture.project, raised);
      expect(
        regenerated.modelInstances.map((value) => value.position.y),
        everyElement(4.75),
      );
      final feature =
          (fixture.map.layers.single as BorderLayer).content.features.single;
      final outside = upsertBorderFeature(
        fixture.map,
        layerId: 'border',
        feature: decodeBorderFeatureJson({
          ...encodeBorderFeatureJson(feature, formatVersion: 4),
          'spatialOffsetWorld': {'x': -100, 'y': 0, 'z': 0},
        }, formatVersion: 4),
      );
      expect(
        resolve(
          fixture.project,
          outside,
        ).result.diagnostics.map((value) => value.code),
        contains('border.spatial.anchor_outside_map'),
      );
      final cells = List<bool>.filled(36, false)..[1 * 6 + 2] = true;
      final keepOut = updateBorderFeatureKeepOutRegions(
        fixture.map,
        layerId: 'border',
        featureId: 'fence',
        keepOutRegions: [
          BorderKeepOutRegion(
            id: 'gap',
            region: BorderRegionGeometry(width: 6, height: 6, cells: cells),
          ),
        ],
      );
      expect(resolve(fixture.project, keepOut).modelInstances, hasLength(2));
    },
  );

  for (final malformed in [
    'single cap',
    'same cap orientation',
    'different model',
    'different height anchor',
    'different planar anchor',
    'corner',
    'flip',
    'unrestricted geometry',
  ]) {
    test('inverted repeated units reject $malformed without mutation', () {
      final fixture = repeatedUnitBorderFixture();
      final raw = encodeBorderBlueprintRecordJson(
        fixture.project.borderCatalog.records.single,
        formatVersion: 5,
      );
      final definition = (raw['latestPublished'] as Map)['definition'] as Map;
      final primitives = definition['primitives'] as List;
      switch (malformed) {
        case 'single cap':
          primitives.removeLast();
        case 'same cap orientation':
          primitives[2]['authoredOrientation'] =
              primitives[1]['authoredOrientation'];
        case 'different model':
          primitives[2]['sourceModelId'] = 'other';
        case 'different height anchor':
          primitives[2]['anchorWorld']['y'] = .5;
        case 'different planar anchor':
          primitives[2]['anchorWorld']['z'] = .5;
        case 'corner':
          primitives[2]['role'] = 'lineCorner';
        case 'flip':
          primitives[2]['transforms']['allowFlipX'] = true;
        case 'unrestricted geometry':
          definition['straightOnly'] = false;
      }
      final project = fixture.project.copyWith(
        models3d: [
          ...fixture.project.models3d,
          if (malformed == 'different model')
            ProjectModel3dEntry(
              id: 'other',
              name: 'Other',
              sourceAssetId: 'other-source',
              relativePath: 'assets/models3d/other.glb',
              inspection: fixture.project.models3d.single.inspection,
            ),
        ],
        borderCatalog: ProjectBorderCatalog(
          formatVersion: 5,
          records: [decodeBorderBlueprintRecordJson(raw, formatVersion: 5)],
        ),
      );
      final before = fixture.map.toJson();
      final result = resolve(project, fixture.map);
      expect(result.result.canApply, isFalse);
      expect(
        result.result.diagnostics.map((value) => value.code),
        contains('border.spatial.line_side_inversion_unsupported'),
      );
      expect(
        applySpatialBorderFeaturePreview(
          fixture.map,
          manifest: project,
          proposedResult: result,
        ),
        same(fixture.map),
      );
      expect(fixture.map.toJson(), before);
    });
  }

  test('inverted repeated units reject turns closed strokes and regions', () {
    final fixture = repeatedUnitBorderFixture();
    final points = const [
      GridPos(x: 1, y: 1),
      GridPos(x: 2, y: 1),
      GridPos(x: 2, y: 2),
    ];
    for (final geometry in [
      BorderStrokeGeometry(
        strokes: [BorderStroke(id: 'line', points: points, closed: false)],
      ),
      BorderStrokeGeometry(
        strokes: [
          BorderStroke(
            id: 'line',
            points: [...points, const GridPos(x: 1, y: 2)],
            closed: true,
          ),
        ],
      ),
      BorderRegionGeometry(width: 6, height: 6, cells: List.filled(36, true)),
    ]) {
      final feature =
          (fixture.map.layers.single as BorderLayer).content.features.single;
      final map = fixture.map.copyWith(
        layers: [
          MapLayer.border(
            id: 'border',
            name: 'Border',
            content: BorderLayerContent(
              formatVersion: 4,
              features: [
                BorderFeature(
                  id: feature.id,
                  name: feature.name,
                  blueprintId: feature.blueprintId,
                  seed: feature.seed,
                  geometry: geometry,
                  lineSide: BorderLineSide.inverted,
                  overrides: const [],
                  keepOutRegions: const [],
                ),
              ],
            ),
          ),
        ],
      );
      final result = resolve(fixture.project, map);
      expect(result.result.canApply, isFalse);
      expect(
        result.result.diagnostics.map((value) => value.code),
        contains('border.spatial.line_side_inversion_unsupported'),
      );
    }
  });

  for (var quarterTurns = 0; quarterTurns < 4; quarterTurns++) {
    test('primary asymmetric fence sockets join for L $quarterTurns', () {
      final fixture = asymmetricFenceFixture(quarterTurns: quarterTurns);
      final resolved = resolve(fixture.project, fixture.map);
      expect(resolved.result.canApply, isTrue);
      expect(resolved.modelInstances, hasLength(5));
      final sockets = <List<Model3dVector3>>[];
      for (final placement
          in resolved.result.materialization!.spatialPlacements) {
        final instance = resolved.modelInstances.singleWhere(
          (instance) => instance.id == placement.instanceId,
        );
        final local = switch (placement.primitiveId) {
          'lineStraight' => const [(-.5, -.125, 0.0), (.5, -.125, 0.0)],
          'lineCorner' => const [(.5, -.125, 0.0), (0.0, -.125, .5)],
          _ => const [(0.0, -.125, .25)],
        };
        final angle = instance.rotationDegrees * math.pi / 180;
        sockets.add([
          for (final point in local)
            Model3dVector3(
              x:
                  instance.position.x +
                  math.cos(angle) * point.$1 +
                  math.sin(angle) * point.$3,
              y: instance.position.y + point.$2,
              z:
                  instance.position.z -
                  math.sin(angle) * point.$1 +
                  math.cos(angle) * point.$3,
            ),
        ]);
      }
      for (var index = 1; index < sockets.length; index++) {
        final gap = [
          for (final first in sockets[index - 1])
            for (final second in sockets[index])
              math.max(
                math.max(
                  (first.x - second.x).abs(),
                  (first.y - second.y).abs(),
                ),
                (first.z - second.z).abs(),
              ),
        ].reduce(math.min);
        expect(gap, closeTo(0, 1e-10));
      }
      expect(
        sockets.expand((points) => points).map((point) => point.y),
        everyElement(fixture.map.spatialScene!.worldHeightAt(2.5, 2.5)),
      );
    });

    test(
      'inverted native L $quarterTurns is rejected without changing map',
      () {
        final fixture = asymmetricFenceFixture(
          quarterTurns: quarterTurns,
          lineSide: BorderLineSide.inverted,
        );
        final before = fixture.map.toJson();
        final resolved = resolve(fixture.project, fixture.map);
        expect(resolved.result.canApply, isFalse);
        expect(resolved.result.materialization, isNull);
        expect(resolved.modelInstances, isEmpty);
        final diagnostic = resolved.result.diagnostics.singleWhere(
          (diagnostic) =>
              diagnostic.code ==
              'border.spatial.line_side_inversion_unsupported',
        );
        expect(diagnostic.severity, BorderDiagnosticSeverity.error);
        expect(
          diagnostic.suggestedAction,
          'border.action.use_primary_line_side',
        );
        expect(
          applySpatialBorderFeaturePreview(
            fixture.map,
            manifest: fixture.project,
            proposedResult: resolved,
          ),
          same(fixture.map),
        );
        expect(fixture.map.toJson(), before);
        expect(
          diagnoseSpatialBorderFeature(
            manifest: fixture.project,
            map: fixture.map,
            layerId: 'border',
            featureId: 'fence',
          ).diagnostics,
          contains(diagnostic),
        );
      },
    );
  }

  test(
    'inverted native straight fence rejects its reversed endpoint ports',
    () {
      final fixture = asymmetricFenceFixture(
        quarterTurns: 0,
        lineSide: BorderLineSide.inverted,
        straightOnly: true,
      );
      final result = resolve(fixture.project, fixture.map);
      expect(result.result.canApply, isFalse);
      expect(
        result.result.diagnostics.map((diagnostic) => diagnostic.code),
        contains('border.spatial.line_side_inversion_unsupported'),
      );
      expect(result.modelInstances, isEmpty);
    },
  );

  test(
    'native receipt ignores unrelated features models and classifications',
    () {
      final fixture = spatialBorderFixture();
      final resolved = resolve(fixture.project, fixture.map);
      var map = applySpatialBorderFeaturePreview(
        fixture.map,
        manifest: fixture.project,
        proposedResult: resolved,
      );
      final own = (map.layers.single as BorderLayer).content.features.single;
      map = upsertBorderFeature(
        map,
        layerId: 'border',
        feature: BorderFeature(
          id: 'other',
          name: 'Other',
          blueprintId: own.blueprintId,
          seed: own.seed,
          geometry: BorderStrokeGeometry(
            strokes: [
              BorderStroke(
                id: 'other',
                points: const [
                  GridPos(x: 1, y: 4),
                  GridPos(x: 2, y: 4),
                  GridPos(x: 3, y: 4),
                ],
                closed: false,
              ),
            ],
          ),
          overrides: const [],
          keepOutRegions: const [],
        ),
      );
      map = applySpatialBorderFeaturePreview(
        map,
        manifest: fixture.project,
        proposedResult: resolveSpatialBorderFeature(
          manifest: fixture.project,
          map: map,
          layerId: 'border',
          featureId: 'other',
        ),
      );
      map = map.copyWith(
        spatialScene: map.spatialScene!.copyWith(
          instances: [
            ...map.spatialScene!.instances,
            SpatialModelInstance(
              id: 'prop',
              modelId: 'unit',
              position: Model3dVector3(x: 4.5, y: .5, z: 4.5),
            ),
          ],
        ),
      );
      final published =
          fixture.project.borderCatalog.records.single.latestPublished!;
      final changed = fixture.project.copyWith(
        borderCatalog: ProjectBorderCatalog(
          formatVersion: 5,
          records: [
            ...fixture.project.borderCatalog.records,
            BorderBlueprintRecord(
              id: 'unrelated',
              draft: fixture.project.borderCatalog.records.single.draft,
              latestPublished: published,
            ),
          ],
        ),
        models3d: [
          ...fixture.project.models3d,
          ProjectModel3dEntry.fromJson({
            ...fixture.project.models3d.single.toJson(),
            'id': 'unrelated',
            'name': 'Unrelated',
            'sourceAssetId': 'unrelated-source',
            'relativePath': 'assets/models3d/unrelated.glb',
          }),
        ],
        resourceLibraryCatalog: ResourceLibraryCatalog(
          entries: [
            ResourceLibraryEntry(
              resourceKind: 'model3d',
              resourceId: 'unrelated',
              familyId: 'props',
            ),
          ],
        ),
      );
      expect(
        resolve(changed, map).result.materialization!.receipt.inputFingerprint,
        resolved.result.materialization!.receipt.inputFingerprint,
      );
      expect(
        diagnoseSpatialBorderFeature(
          manifest: changed,
          map: map,
          layerId: 'border',
          featureId: 'fence',
        ).diagnostics.where(
          (d) => d.code == 'border.spatial.materialization_stale',
        ),
        isEmpty,
      );
    },
  );

  test('native receipt tracks terrain geometry and world offsets', () {
    final fixture = spatialBorderFixture();
    final resolved = resolve(fixture.project, fixture.map);
    final applied = applySpatialBorderFeaturePreview(
      fixture.map,
      manifest: fixture.project,
      proposedResult: resolved,
    );
    final own = (applied.layers.single as BorderLayer).content.features.single;
    final shifted = upsertBorderFeature(
      applied,
      layerId: 'border',
      feature: BorderFeature(
        id: own.id,
        name: own.name,
        blueprintId: own.blueprintId,
        seed: own.seed,
        geometry: own.geometry,
        spatialOffsetWorld: Model3dVector3(x: .125, y: -.1875, z: .25),
        lineSide: own.lineSide,
        overrides: own.overrides,
        keepOutRegions: own.keepOutRegions,
        materialization: own.materialization,
      ),
    );
    final relief = applied.copyWith(
      spatialScene: applied.spatialScene!.copyWith(
        heightLevels: List.filled(36, 2),
      ),
    );
    final geometry = updateBorderFeatureGeometry(
      applied,
      layerId: 'border',
      featureId: 'fence',
      geometry: BorderStrokeGeometry(
        strokes: [
          BorderStroke(
            id: 'line',
            points: const [
              GridPos(x: 1, y: 1),
              GridPos(x: 2, y: 1),
              GridPos(x: 3, y: 1),
            ],
            closed: false,
          ),
        ],
      ),
    );
    for (final changed in [shifted, relief, geometry]) {
      expect(
        resolve(
          fixture.project,
          changed,
        ).result.materialization!.receipt.inputFingerprint,
        isNot(resolved.result.materialization!.receipt.inputFingerprint),
      );
      expect(
        diagnoseSpatialBorderFeature(
          manifest: fixture.project,
          map: changed,
          layerId: 'border',
          featureId: 'fence',
        ).diagnostics.map((d) => d.code),
        contains('border.spatial.materialization_stale'),
      );
    }
  });

  test(
    'native feature world offsets follow primitive rotation and retain ownership on regeneration',
    () {
      final fixture = spatialBorderFixture(
        anchor: Model3dVector3(x: .1, y: .2, z: .3),
      );
      final base = resolve(fixture.project, fixture.map);
      final original =
          (fixture.map.layers.single as BorderLayer).content.features.single;
      final offset = Model3dVector3(x: .25, y: -1.1875, z: -.5);
      final feature = BorderFeature(
        id: original.id,
        name: original.name,
        blueprintId: original.blueprintId,
        seed: original.seed,
        geometry: original.geometry,
        lineSide: original.lineSide,
        spatialOffsetWorld: offset,
        overrides: original.overrides,
        keepOutRegions: original.keepOutRegions,
      );
      var map = upsertBorderFeature(
        fixture.map,
        layerId: 'border',
        feature: feature,
      );
      final resolved = resolve(fixture.project, map);
      expect(resolved.result.canApply, isTrue);
      expect(
        resolved.modelInstances.map((value) => value.id),
        base.modelInstances.map((value) => value.id),
      );
      for (var i = 0; i < resolved.modelInstances.length; i++) {
        final actual = resolved.modelInstances[i],
            before = base.modelInstances[i];
        expect(actual.position.x, closeTo(before.position.x + offset.x, 1e-10));
        expect(actual.position.y, closeTo(before.position.y + offset.y, 1e-10));
        expect(actual.position.z, closeTo(before.position.z + offset.z, 1e-10));
        expect(actual.rotationDegrees, before.rotationDegrees);
      }
      expect(
        resolved.modelInstances
            .map((value) => value.rotationDegrees)
            .toSet()
            .length,
        greaterThan(1),
      );
      map = applySpatialBorderFeaturePreview(
        map,
        manifest: fixture.project,
        proposedResult: resolved,
      );
      expect(MapData.fromJson(map.toJson()), map);
      expect(toggleBorderFeatureLineSide(feature).spatialOffsetWorld, offset);
      expect(
        (updateBorderFeatureSeed(
                  map,
                  layerId: 'border',
                  featureId: feature.id,
                  seed: BorderSignedInt64.zero,
                ).layers.single
                as BorderLayer)
            .content
            .features
            .single
            .spatialOffsetWorld,
        offset,
      );
      final updated = updateBorderFeatureKeepOutRegions(
        map,
        layerId: 'border',
        featureId: feature.id,
        keepOutRegions: [],
      );
      expect(
        (updated.layers.single as BorderLayer)
            .content
            .features
            .single
            .spatialOffsetWorld,
        offset,
      );
      expect(
        resolve(fixture.project, updated).result.materialization,
        resolved.result.materialization,
      );
      final json = encodeBorderFeatureJson(feature, formatVersion: 4);
      expect(decodeBorderFeatureJson(json, formatVersion: 4), feature);
      expect(
        () => encodeBorderFeatureJson(feature, formatVersion: 3),
        throwsFormatException,
      );
      final badJson = {
        ...json,
        'spatialOffsetWorld': {'x': '1', 'y': 0, 'z': 0},
      };
      expect(
        () => decodeBorderFeatureJson(badJson, formatVersion: 4),
        throwsFormatException,
      );
      final twoD = MapData(
        id: 'flat',
        name: 'Flat',
        size: fixture.map.size,
        layers: const [],
      );
      expect(
        () => upsertBorderFeature(
          addBorderLayer(twoD, id: 'border', name: 'Border'),
          layerId: 'border',
          feature: feature,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => MapValidator.validate(
          twoD.copyWith(
            layers: [
              MapLayer.border(
                id: 'border',
                name: 'Border',
                content: BorderLayerContent(
                  formatVersion: 4,
                  features: [feature],
                ),
              ),
            ],
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      json['spatialOffsetWorld'] = {'x': -100, 'y': 0, 'z': 0};
      final outside = upsertBorderFeature(
        fixture.map,
        layerId: 'border',
        feature: decodeBorderFeatureJson(json, formatVersion: 4),
      );
      expect(
        resolve(
          fixture.project,
          outside,
        ).result.diagnostics.map((value) => value.code),
        contains('border.spatial.anchor_outside_map'),
      );
    },
  );

  test(
    'straight-only native profiles publish body and ends without a corner',
    () {
      final fixture = spatialBorderFixture(
        straightOnly: true,
        includeCorner: false,
      );
      final record = fixture.project.borderCatalog.records.single;
      final json = encodeBorderBlueprintRecordJson(record, formatVersion: 5);
      expect(
        (json['draft'] as Map)['definition'],
        containsPair('straightOnly', true),
      );
      expect(
        (json['latestPublished'] as Map)['definition'],
        containsPair('straightOnly', true),
      );
      expect(decodeBorderBlueprintRecordJson(json, formatVersion: 5), record);
      expect(
        validateSpatialBorderBlueprint(
          blueprintId: record.id,
          definition: record.latestPublished!.definition,
          manifest: fixture.project,
        ).hasErrors,
        isFalse,
      );
      final ordinary = spatialBorderFixture(includeCorner: false);
      expect(
        validateSpatialBorderBlueprint(
          blueprintId: record.id,
          definition: ordinary
              .project
              .borderCatalog
              .records
              .single
              .latestPublished!
              .definition,
          manifest: ordinary.project,
        ).diagnostics.map((value) => value.code),
        contains('border.spatial.required_roles_missing'),
      );
      final complete = spatialBorderFixture();
      final restrictedComplete = spatialBorderFixture(straightOnly: true);
      expect(
        computeBorderPublicationCandidateFingerprint(
          blueprintId: record.id,
          definition: complete
              .project
              .borderCatalog
              .records
              .single
              .latestPublished!
              .definition,
          resolverVersion: borderResolverVersion,
        ),
        isNot(
          computeBorderPublicationCandidateFingerprint(
            blueprintId: record.id,
            definition: restrictedComplete
                .project
                .borderCatalog
                .records
                .single
                .latestPublished!
                .definition,
            resolverVersion: borderResolverVersion,
          ),
        ),
      );
      (json['draft'] as Map)['definition']['straightOnly'] = 'true';
      expect(
        () => decodeBorderBlueprintRecordJson(json, formatVersion: 5),
        throwsFormatException,
      );
      expect(
        () => BorderBlueprintDraftDefinition(
          name: 'Invalid',
          previewSeed: BorderSignedInt64.zero,
          template: BorderBlueprintTemplate.masonryLine,
          straightOnly: true,
          primitives: record.draft.definition.primitives,
          defaults: record.draft.definition.defaults,
          sortOrder: 0,
        ),
        throwsA(isA<ValidationException>()),
      );
    },
  );

  test(
    'straight-only geometry rejects turns and regions even when a corner exists',
    () {
      for (final includeCorner in [false, true]) {
        final fixture = spatialBorderFixture(
          straightOnly: true,
          includeCorner: includeCorner,
        );
        expect(
          resolve(
            fixture.project,
            fixture.map,
          ).result.diagnostics.map((value) => value.code),
          contains('border.spatial.straight_only_geometry_required'),
        );
        expect(
          () => MapValidator.validate(
            fixture.map,
            projectDialogueContext: fixture.project,
          ),
          throwsA(
            isA<ValidationException>().having(
              (error) => error.code,
              'code',
              'border.spatial.straight_only_geometry_required',
            ),
          ),
        );
        final straight = updateBorderFeatureGeometry(
          fixture.map,
          layerId: 'border',
          featureId: 'fence',
          geometry: BorderStrokeGeometry(
            strokes: [
              BorderStroke(
                id: 'line',
                points: const [
                  GridPos(x: 1, y: 1),
                  GridPos(x: 2, y: 1),
                  GridPos(x: 3, y: 1),
                ],
                closed: false,
              ),
            ],
          ),
        );
        final resolved = resolve(fixture.project, straight);
        expect(resolved.result.canApply, isTrue);
        expect(resolved.modelInstances, hasLength(3));
        final applied = applySpatialBorderFeaturePreview(
          straight,
          manifest: fixture.project,
          proposedResult: resolved,
        );
        expect(MapData.fromJson(applied.toJson()), applied);
        final region = updateBorderFeatureGeometry(
          straight,
          layerId: 'border',
          featureId: 'fence',
          geometry: BorderRegionGeometry(
            width: 6,
            height: 6,
            cells: List<bool>.filled(36, false)..[7] = true,
          ),
        );
        final failed = resolve(fixture.project, region);
        expect(
          failed.result.diagnostics.map((value) => value.code),
          contains('border.spatial.straight_only_geometry_required'),
        );
        expect(failed.modelInstances, isEmpty);
        expect(
          applySpatialBorderFeaturePreview(
            region,
            manifest: fixture.project,
            proposedResult: failed,
          ),
          same(region),
        );
      }
    },
  );

  test('native primitives and ownership have strict sprite-free codecs', () {
    final fixture = spatialBorderFixture();
    final record = fixture.project.borderCatalog.records.single;
    final json = encodeBorderBlueprintRecordJson(record, formatVersion: 5);
    expect(decodeBorderBlueprintRecordJson(json, formatVersion: 5), record);
    expect(json.toString(), contains('sourceModelId'));
    for (final key in [
      'sourceElementId',
      'currentMetrics',
      'publishedMetrics',
      'visualSnapshotId',
      'anchorPx',
    ]) {
      expect(json.toString(), isNot(contains(key)));
    }
    expect(
      () => encodeBorderBlueprintRecordJson(record, formatVersion: 4),
      throwsFormatException,
    );
    expect(
      () => BorderPrimitiveDraft(
        id: 'bad',
        sourceElementId: 'sprite',
        sourceModelId: 'unit',
        role: BorderPrimitiveRole.lineStraight,
        weight: 1,
        transforms: borderSpatialTransforms(),
      ),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => BorderPrimitiveDraft(
        id: 'bad',
        sourceModelId: 'unit',
        role: BorderPrimitiveRole.lineStraight,
        weight: 1,
        anchorPx: const BorderPixelPos(x: 0, y: 0),
        transforms: borderSpatialTransforms(),
      ),
      throwsA(isA<ValidationException>()),
    );
    final candidateFingerprint = computeBorderPublicationCandidateFingerprint(
      blueprintId: record.id,
      definition: record.latestPublished!.definition,
      resolverVersion: borderResolverVersion,
    );
    expect(candidateFingerprint, startsWith('sha256:'));
    final changed = spatialBorderFixture(
      anchor: Model3dVector3(x: .1, y: .2, z: .3),
    );
    expect(
      computeBorderPublicationCandidateFingerprint(
        blueprintId: record.id,
        definition: changed
            .project
            .borderCatalog
            .records
            .single
            .latestPublished!
            .definition,
        resolverVersion: borderResolverVersion,
      ),
      isNot(candidateFingerprint),
    );
  });

  test(
    'native straight corner caps use deterministic slots and terrain height',
    () {
      final fixture = spatialBorderFixture();
      final resolved = resolve(fixture.project, fixture.map);
      expect(resolved.result.diagnostics, isEmpty);
      expect(resolved.modelInstances, hasLength(5));
      expect(
        resolved.modelInstances.map((instance) => instance.rotationDegrees),
        [-0.0, -0.0, -0.0, -90.0, -270.0],
      );
      final applied = applySpatialBorderFeaturePreview(
        fixture.map,
        manifest: fixture.project,
        proposedResult: resolved,
      );
      expect(applied.version, ProjectVersion.v9);
      expect(applied.placedElements, isEmpty);
      expect(MapData.fromJson(applied.toJson()), applied);
      expect(
        applied.spatialScene!.instances.every(
          (instance) => instance.position.y == 1,
        ),
        isTrue,
      );
      expect(
        resolve(fixture.project, applied).result.materialization,
        resolved.result.materialization,
      );
      expect(
        diagnoseSpatialBorderFeature(
          manifest: fixture.project,
          map: applied,
          layerId: 'border',
          featureId: 'fence',
        ).diagnostics,
        isEmpty,
      );
      MapValidator.validate(applied, projectDialogueContext: fixture.project);
    },
  );

  test(
    'local stroke edits preserve foreign instances and other feature outputs',
    () {
      final fixture = spatialBorderFixture();
      var map = applySpatialBorderFeaturePreview(
        fixture.map,
        manifest: fixture.project,
        proposedResult: resolve(fixture.project, fixture.map),
      );
      final foreign = SpatialModelInstance(
        id: 'foreign',
        modelId: 'unit',
        position: Model3dVector3.zero,
      );
      map = map.copyWith(
        spatialScene: map.spatialScene!.copyWith(
          instances: [...map.spatialScene!.instances, foreign],
        ),
      );
      final before = {
        for (final instance in map.spatialScene!.instances)
          instance.id: instance,
      };
      map = updateBorderFeatureGeometry(
        map,
        layerId: 'border',
        featureId: 'fence',
        geometry: BorderStrokeGeometry(
          strokes: [
            BorderStroke(
              id: 'line',
              points: const [
                GridPos(x: 1, y: 1),
                GridPos(x: 2, y: 1),
                GridPos(x: 3, y: 1),
                GridPos(x: 3, y: 2),
              ],
              closed: false,
            ),
          ],
        ),
      );
      final result = applySpatialBorderFeaturePreview(
        map,
        manifest: fixture.project,
        proposedResult: resolve(fixture.project, map),
      );
      expect(result.spatialScene!.instances, contains(foreign));
      for (final instance in result.spatialScene!.instances.where(
        (instance) => instance.position.z == 1.5,
      )) {
        expect(instance, before[instance.id]);
      }
      final removed = removeBorderFeature(
        result,
        layerId: 'border',
        featureId: 'fence',
      );
      expect(removed.spatialScene!.instances, [foreign]);
      expect(MapData.fromJson(removed.toJson()), removed);
      expect(
        removeMapLayer(result, layerId: 'border').spatialScene!.instances,
        [foreign],
      );
    },
  );

  test('region contours and holes reuse the native line roles', () {
    final fixture = spatialBorderFixture();
    final cells = List<bool>.filled(36, false);
    for (var y = 1; y < 4; y++) {
      for (var x = 1; x < 4; x++) {
        cells[y * 6 + x] = !(x == 2 && y == 2);
      }
    }
    final map = updateBorderFeatureGeometry(
      fixture.map,
      layerId: 'border',
      featureId: 'fence',
      geometry: BorderRegionGeometry(width: 6, height: 6, cells: cells),
    );
    final result = resolve(fixture.project, map);
    expect(result.result.diagnostics, isEmpty);
    expect(result.modelInstances, hasLength(16));
    final applied = applySpatialBorderFeaturePreview(
      map,
      manifest: fixture.project,
      proposedResult: result,
    );
    expect(MapData.fromJson(applied.toJson()), applied);
  });

  test('local region edits preserve unchanged boundary slot identities', () {
    final fixture = spatialBorderFixture();
    final cells = List<bool>.filled(36, false);
    for (var y = 1; y < 3; y++) {
      for (var x = 1; x < 4; x++) {
        cells[y * 6 + x] = true;
      }
    }
    var map = updateBorderFeatureGeometry(
      fixture.map,
      layerId: 'border',
      featureId: 'fence',
      geometry: BorderRegionGeometry(width: 6, height: 6, cells: cells),
    );
    map = applySpatialBorderFeaturePreview(
      map,
      manifest: fixture.project,
      proposedResult: resolve(fixture.project, map),
    );
    final before = map.spatialScene!.instances
        .where((instance) => instance.position.z == 1)
        .toList();
    expect(before, hasLength(4));
    cells[3 * 6 + 2] = true;
    map = updateBorderFeatureGeometry(
      map,
      layerId: 'border',
      featureId: 'fence',
      geometry: BorderRegionGeometry(width: 6, height: 6, cells: cells),
    );
    final result = resolve(fixture.project, map);
    expect(result.result.canApply, isTrue);
    expect(
      result.modelInstances.where((instance) => instance.position.z == 1),
      before,
    );
  });

  test(
    'model metadata and relief changes invalidate previews and regenerate anchors',
    () {
      final fixture = spatialBorderFixture(
        anchor: Model3dVector3(x: .1, y: 0, z: 0),
      );
      final preview = resolve(fixture.project, fixture.map);
      final changed = fixture.project.copyWith(
        models3d: [fixture.project.models3d.single.copyWith(scale: 2)],
      );
      expect(
        () => applySpatialBorderFeaturePreview(
          fixture.map,
          manifest: changed,
          proposedResult: preview,
        ),
        throwsA(isA<ValidationException>()),
      );
      final map = applySpatialBorderFeaturePreview(
        fixture.map,
        manifest: fixture.project,
        proposedResult: preview,
      );
      expect(
        diagnoseSpatialBorderFeature(
          manifest: changed,
          map: map,
          layerId: 'border',
          featureId: 'fence',
        ).diagnostics.map((diagnostic) => diagnostic.code),
        contains('border.spatial.materialization_stale'),
      );
      final next = applySpatialBorderFeaturePreview(
        map,
        manifest: changed,
        proposedResult: resolve(changed, map),
      );
      expect(next.spatialScene!.instances.first.position.x, closeTo(1.3, 1e-8));
      expect(
        diagnoseSpatialBorderFeature(
          manifest: changed,
          map: next,
          layerId: 'border',
          featureId: 'fence',
        ).diagnostics,
        isEmpty,
      );
      final relief = fixture.map.copyWith(
        spatialScene: fixture.map.spatialScene!.copyWith(
          heightLevels: List.filled(36, 2),
        ),
      );
      expect(
        () => applySpatialBorderFeaturePreview(
          relief,
          manifest: fixture.project,
          proposedResult: preview,
        ),
        throwsA(isA<ValidationException>()),
      );
    },
  );

  test(
    'locked native transforms survive regeneration without duplicated transform data',
    () {
      final fixture = spatialBorderFixture();
      var map = applySpatialBorderFeaturePreview(
        fixture.map,
        manifest: fixture.project,
        proposedResult: resolve(fixture.project, fixture.map),
      );
      final placement = (map.layers.single as BorderLayer)
          .content
          .features
          .single
          .materialization!
          .spatialPlacements[1];
      map = updateBorderFeatureOverrides(
        map,
        layerId: 'border',
        featureId: 'fence',
        overrides: [
          BorderSlotOverride(
            slotKey: placement.slotKey,
            variationSalt: BorderSignedInt64.zero,
            suppressed: false,
            locked: true,
            lockedInstanceId: placement.instanceId,
          ),
        ],
      );
      final exact = map.spatialScene!.instances[1].copyWith(
        position: Model3dVector3(x: 2.2, y: 1.4, z: 1.6),
        rotationDegrees: 12,
        scale: 1.2,
      );
      map = map.copyWith(
        spatialScene: map.spatialScene!.copyWith(
          instances: [
            for (final instance in map.spatialScene!.instances)
              if (instance.id == exact.id) exact else instance,
          ],
        ),
      );
      final result = applySpatialBorderFeaturePreview(
        map,
        manifest: fixture.project,
        proposedResult: resolve(fixture.project, map),
      );
      expect(result.spatialScene!.instances, contains(exact));
      expect(MapData.fromJson(result.toJson()), result);
      expect(
        encodeBorderFeatureJson(
          (result.layers.single as BorderLayer).content.features.single,
          formatVersion: 4,
        ).toString(),
        isNot(contains('rotationDegrees')),
      );
    },
  );

  test(
    'native ownership unknown sources keepouts and scope guards fail closed',
    () {
      final fixture = spatialBorderFixture();
      final private = fixture.project.copyWith(
        resourceLibraryCatalog: ResourceLibraryCatalog(
          entries: [
            ResourceLibraryEntry(
              resourceKind: 'model3d',
              resourceId: 'unit',
              mapId: 'other',
            ),
          ],
        ),
      );
      expect(
        resolve(
          private,
          fixture.map,
        ).result.diagnostics.map((diagnostic) => diagnostic.code),
        contains('border.spatial.resource_scope_conflict'),
      );
      expect(
        resolve(
          fixture.project.copyWith(models3d: []),
          fixture.map,
        ).result.canApply,
        isFalse,
      );
      final applied = applySpatialBorderFeaturePreview(
        fixture.map,
        manifest: fixture.project,
        proposedResult: resolve(fixture.project, fixture.map),
      );
      final corrupt = applied.copyWith(
        spatialScene: applied.spatialScene!.copyWith(instances: []),
      );
      expect(
        resolve(
          fixture.project,
          corrupt,
        ).result.diagnostics.map((diagnostic) => diagnostic.code),
        contains('border.spatial.ownership_invalid'),
      );
      expect(() => MapData.fromJson(corrupt.toJson()), throwsFormatException);
      final cells = List<bool>.filled(36, false)..[1 * 6 + 2] = true;
      final keepOut = updateBorderFeatureKeepOutRegions(
        fixture.map,
        layerId: 'border',
        featureId: 'fence',
        keepOutRegions: [
          BorderKeepOutRegion(
            id: 'gate',
            region: BorderRegionGeometry(width: 6, height: 6, cells: cells),
          ),
        ],
      );
      expect(resolve(fixture.project, keepOut).modelInstances, hasLength(4));
    },
  );
}

SpatialBorderResolutionResult resolve(ProjectManifest project, MapData map) =>
    resolveSpatialBorderFeature(
      manifest: project,
      map: map,
      layerId: 'border',
      featureId: 'fence',
    );

({ProjectManifest project, MapData map}) repeatedUnitBorderFixture({
  int authoredTurns = 0,
  Model3dVector3? anchor,
  bool usePivotAnchor = false,
}) {
  if (!usePivotAnchor) anchor ??= Model3dVector3(x: 0, y: .25, z: 0);
  final fixture = spatialBorderFixture(
    straightOnly: true,
    includeCorner: false,
  );
  final record = fixture.project.borderCatalog.records.single;
  final definition = record.latestPublished!.definition;
  final directions = [
    BorderPrimitiveOrientation.east,
    BorderPrimitiveOrientation.south,
    BorderPrimitiveOrientation.west,
    BorderPrimitiveOrientation.north,
  ];
  final capTurns = [(2 - authoredTurns + 4) % 4, (3 - authoredTurns + 4) % 4]
    ..sort();
  final primitives = [
    BorderPublishedPrimitive(
      id: 'body',
      sourceModelId: 'unit',
      role: BorderPrimitiveRole.lineStraight,
      weight: 1,
      authoredOrientation: directions[authoredTurns],
      anchorWorld: anchor,
      transforms: borderSpatialTransforms(),
    ),
    for (final positive in [true, false])
      BorderPublishedPrimitive(
        id: positive ? 'positive' : 'negative',
        sourceModelId: 'unit',
        role: BorderPrimitiveRole.lineCap,
        weight: 1,
        authoredOrientation:
            directions[(authoredTurns + (positive ? 0 : 2)) % 4],
        anchorWorld: anchor,
        transforms: BorderTransformPolicy(
          allowFlipX: false,
          allowedQuarterTurns: capTurns,
        ),
      ),
  ];
  final published = BorderBlueprintPublishedDefinition(
    name: definition.name,
    previewSeed: definition.previewSeed,
    template: definition.template,
    straightOnly: true,
    primitives: primitives,
    defaults: definition.defaults,
    sortOrder: definition.sortOrder,
  );
  final project = fixture.project.copyWith(
    borderCatalog: ProjectBorderCatalog(
      formatVersion: 5,
      records: [
        BorderBlueprintRecord(
          id: record.id,
          draft: record.draft,
          latestPublished: BorderBlueprintRevision(
            revision: 1,
            definition: published,
          ),
        ),
      ],
    ),
  );
  final old =
      (fixture.map.layers.single as BorderLayer).content.features.single;
  final map = upsertBorderFeature(
    fixture.map,
    layerId: 'border',
    feature: BorderFeature(
      id: old.id,
      name: old.name,
      blueprintId: old.blueprintId,
      seed: old.seed,
      lineSide: BorderLineSide.inverted,
      geometry: BorderStrokeGeometry(
        alignment: BorderStrokeAlignment.cellCenters,
        strokes: [
          BorderStroke(
            id: 'line',
            closed: false,
            points: const [
              GridPos(x: 1, y: 1),
              GridPos(x: 2, y: 1),
              GridPos(x: 3, y: 1),
            ],
          ),
        ],
      ),
      overrides: const [],
      keepOutRegions: const [],
    ),
  );
  return (project: project, map: map);
}

({ProjectManifest project, MapData map}) asymmetricFenceFixture({
  required int quarterTurns,
  BorderLineSide lineSide = BorderLineSide.primary,
  bool straightOnly = false,
}) {
  final fixture = spatialBorderFixture(straightOnly: straightOnly);
  final record = fixture.project.borderCatalog.records.single;
  final source = record.latestPublished!.definition;
  final primitives = [
    for (final role in [
      BorderPrimitiveRole.lineCap,
      BorderPrimitiveRole.lineStraight,
      BorderPrimitiveRole.lineCorner,
    ])
      BorderPublishedPrimitive(
        id: role.name,
        sourceModelId: 'unit',
        role: role,
        weight: 1,
        transforms: borderSpatialTransforms(),
        authoredOrientation: switch (role) {
          BorderPrimitiveRole.lineCap => BorderPrimitiveOrientation.south,
          BorderPrimitiveRole.lineCorner => BorderPrimitiveOrientation.north,
          _ => BorderPrimitiveOrientation.east,
        },
        anchorWorld: Model3dVector3(
          x: 0,
          y: -.125,
          z: role == BorderPrimitiveRole.lineCap ? -.25 : 0,
        ),
      ),
  ];
  final project = fixture.project.copyWith(
    borderCatalog: ProjectBorderCatalog(
      formatVersion: 5,
      records: [
        BorderBlueprintRecord(
          id: record.id,
          draft: record.draft,
          latestPublished: BorderBlueprintRevision(
            revision: 1,
            definition: BorderBlueprintPublishedDefinition(
              name: source.name,
              previewSeed: source.previewSeed,
              template: source.template,
              straightOnly: straightOnly,
              primitives: primitives,
              defaults: source.defaults,
              sortOrder: source.sortOrder,
            ),
          ),
        ),
      ],
    ),
  );
  final original =
      (fixture.map.layers.single as BorderLayer).content.features.single;
  final geometry = original.geometry as BorderStrokeGeometry;
  final points = straightOnly
      ? geometry.strokes.single.points.take(3)
      : geometry.strokes.single.points;
  final rotated = [
    for (final point in points)
      switch (quarterTurns) {
        0 => point,
        1 => GridPos(x: 6 - point.y, y: point.x),
        2 => GridPos(x: 6 - point.x, y: 6 - point.y),
        _ => GridPos(x: point.y, y: 6 - point.x),
      },
  ];
  final map = upsertBorderFeature(
    fixture.map,
    layerId: 'border',
    feature: BorderFeature(
      id: original.id,
      name: original.name,
      blueprintId: original.blueprintId,
      seed: original.seed,
      lineSide: lineSide,
      geometry: BorderStrokeGeometry(
        strokes: [BorderStroke(id: 'line', points: rotated, closed: false)],
      ),
      overrides: original.overrides,
      keepOutRegions: original.keepOutRegions,
    ),
  );
  return (project: project, map: map);
}

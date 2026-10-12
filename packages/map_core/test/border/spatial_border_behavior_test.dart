import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'spatial_border_resolution_test.dart' show spatialBorderFixture;

void main() {
  test('spatial primitive behavior round trips and generates exact poses', () {
    final fixture = spatialBorderFixture();
    final project = behaviorProject(fixture.project, {
      'animationIndex': 0,
      'animationLoop': false,
      'animationSpeed': .5,
      'blocksMovement': false,
    });
    final wire = encodeProjectBorderCatalogJson(project.borderCatalog);
    expect(decodeProjectBorderCatalogJson(wire), project.borderCatalog);
    final baseline = resolve(fixture.project, fixture.map);
    final generated = resolve(project, fixture.map);
    expect(generated.result.canApply, isTrue);
    expect(
      generated.modelInstances.map(pose),
      baseline.modelInstances.map(pose),
    );
    for (final instance in generated.modelInstances) {
      expect(instance.animationIndex, 0);
      expect(instance.animationLoop, isFalse);
      expect(instance.animationSpeed, .5);
      expect(instance.blocksMovement, isFalse);
    }
    final saved = applySpatialBorderFeaturePreview(
      fixture.map,
      manifest: project,
      proposedResult: generated,
    );
    final restored = MapData.fromJson(jsonDecode(jsonEncode(saved.toJson())));
    final regenerated = resolve(project, restored);
    expect(regenerated.modelInstances, generated.modelInstances);
    expect(
      diagnoseSpatialBorderFeature(
        manifest: project,
        map: restored,
        layerId: 'border',
        featureId: 'fence',
      ).hasErrors,
      isFalse,
    );
  });

  test(
    'model clip zero never starts without an explicit primitive selection',
    () {
      final fixture = spatialBorderFixture();
      final project = behaviorProject(fixture.project, const {});
      final generated = resolve(project, fixture.map);
      expect(generated.result.canApply, isTrue);
      for (final instance in generated.modelInstances) {
        expect(instance.animationIndex, isNull);
        expect(instance.animationLoop, isTrue);
        expect(instance.animationSpeed, 1);
        expect(instance.blocksMovement, isTrue);
      }
    },
  );

  test(
    'clearing an explicit clip regenerates stationary instances with exact poses',
    () {
      final fixture = spatialBorderFixture();
      final animated = behaviorProject(fixture.project, {'animationIndex': 0});
      final preview = resolve(animated, fixture.map);
      final map = applySpatialBorderFeaturePreview(
        fixture.map,
        manifest: animated,
        proposedResult: preview,
      );
      final cleared = behaviorProject(animated, {'animationIndex': null});
      final regenerated = resolve(cleared, map);
      expect(
        regenerated.modelInstances.map(pose),
        preview.modelInstances.map(pose),
      );
      expect(
        regenerated.modelInstances.map((instance) => instance.animationIndex),
        everyElement(isNull),
      );
    },
  );

  test(
    'sprite primitives retain their strict wire and reject spatial behavior',
    () {
      final metrics = BorderPrimitiveAssetMetrics(
        assetFingerprint: 'sprite-source',
        pixelSize: const GridSize(width: 1, height: 1),
        opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
        defaultAnchorPx: BorderPixelPos(x: 0, y: 0),
        occupancyMaskRle: encodeBorderRleMask([true]),
      );
      BorderPrimitiveDraft sprite(Map<String, Object?> settings) =>
          BorderPrimitiveDraft(
            id: 'sprite',
            sourceElementId: 'element',
            role: BorderPrimitiveRole.lineStraight,
            weight: 1,
            anchorPx: metrics.defaultAnchorPx,
            currentMetrics: metrics,
            transforms: borderTransforms,
            animationIndex: settings['animationIndex'] as int?,
            animationLoop: settings['animationLoop'] as bool? ?? true,
            animationSpeed: settings['animationSpeed'] as double? ?? 1,
            blocksMovement: settings['blocksMovement'] as bool? ?? true,
          );
      final fixture = spatialBorderFixture();
      final definition =
          fixture.project.borderCatalog.records.single.draft.definition;
      final record = BorderBlueprintRecord(
        id: 'sprite',
        draft: BorderBlueprintDraft(
          baseRevision: 0,
          definition: BorderBlueprintDraftDefinition(
            name: 'Sprite',
            previewSeed: definition.previewSeed,
            template: definition.template,
            primitives: [sprite(const {})],
            defaults: definition.defaults,
            sortOrder: 0,
          ),
        ),
      );
      final wire = encodeBorderBlueprintRecordJson(record, formatVersion: 5);
      final primitive =
          (((wire['draft'] as Map)['definition'] as Map)['primitives'] as List)
                  .single
              as Map;
      expect(primitive.keys.toSet(), {
        'id',
        'sourceElementId',
        'role',
        'weight',
        'anchorPx',
        'transforms',
        'currentMetrics',
      });
      expect(decodeBorderBlueprintRecordJson(wire, formatVersion: 5), record);
      for (final settings in <Map<String, Object?>>[
        {'animationIndex': 0},
        {'animationLoop': false},
        {'animationSpeed': .5},
        {'blocksMovement': false},
      ]) {
        expect(() => sprite(settings), throwsA(isA<ValidationException>()));
        expect(
          () => BorderPublishedPrimitive(
            id: 'sprite',
            sourceElementId: 'element',
            visualSnapshotId: 'snapshot',
            role: BorderPrimitiveRole.lineStraight,
            weight: 1,
            anchorPx: metrics.defaultAnchorPx,
            publishedMetrics: metrics,
            transforms: borderTransforms,
            animationIndex: settings['animationIndex'] as int?,
            animationLoop: settings['animationLoop'] as bool? ?? true,
            animationSpeed: settings['animationSpeed'] as double? ?? 1,
            blocksMovement: settings['blocksMovement'] as bool? ?? true,
          ),
          throwsA(isA<ValidationException>()),
        );
        final invalidWire =
            jsonDecode(jsonEncode(wire)) as Map<String, dynamic>;
        final invalidPrimitive =
            (((invalidWire['draft'] as Map)['definition'] as Map)['primitives']
                        as List)
                    .single
                as Map;
        invalidPrimitive.addAll(settings);
        expect(
          () => decodeBorderBlueprintRecordJson(invalidWire, formatVersion: 5),
          throwsA(isA<FormatException>()),
        );
      }
    },
  );

  test('both native primitive constructors reject invalid playback', () {
    for (final setting in [
      (index: -1, speed: 1.0),
      (index: 0, speed: 0.0),
      (index: 0, speed: 17.0),
      (index: 0, speed: double.infinity),
    ]) {
      expect(
        () => BorderPrimitiveDraft(
          id: 'unit',
          sourceModelId: 'unit',
          role: BorderPrimitiveRole.lineStraight,
          weight: 1,
          transforms: borderTransforms,
          animationIndex: setting.index,
          animationSpeed: setting.speed,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => BorderPublishedPrimitive(
          id: 'unit',
          sourceModelId: 'unit',
          role: BorderPrimitiveRole.lineStraight,
          weight: 1,
          transforms: borderTransforms,
          animationIndex: setting.index,
          animationSpeed: setting.speed,
        ),
        throwsA(isA<ValidationException>()),
      );
    }
  });

  for (final setting in <Map<String, Object?>>[
    {'animationIndex': 0},
    {'animationLoop': false},
    {'animationSpeed': .5},
    {'blocksMovement': false},
  ]) {
    test(
      'primitive ${setting.keys.single} invalidates exact materialization',
      () {
        final fixture = spatialBorderFixture();
        final original = behaviorProject(fixture.project, const {});
        final preview = resolve(original, fixture.map);
        final applied = applySpatialBorderFeaturePreview(
          fixture.map,
          manifest: original,
          proposedResult: preview,
        );
        final changed = behaviorProject(fixture.project, setting);
        expect(changed.borderCatalog, isNot(original.borderCatalog));
        final regenerated = resolve(changed, applied);
        expect(
          regenerated.result.materialization!.receipt.inputFingerprint,
          isNot(preview.result.materialization!.receipt.inputFingerprint),
        );
        expect(
          diagnoseSpatialBorderFeature(
            manifest: changed,
            map: applied,
            layerId: 'border',
            featureId: 'fence',
          ).diagnostics.map((item) => item.code),
          contains('border.spatial.materialization_stale'),
        );
        expect(
          () => applySpatialBorderFeaturePreview(
            fixture.map,
            manifest: changed,
            proposedResult: preview,
          ),
          throwsA(isA<ValidationException>()),
        );
      },
    );
  }

  for (final setting in <Map<String, Object?>>[
    {'animationIndex': -1},
    {'animationIndex': 0.0},
    {'animationLoop': 'true'},
    {'animationSpeed': 0},
    {'animationSpeed': 17},
    {'animationSpeed': double.nan},
    {'blocksMovement': 'false'},
  ]) {
    test(
      'spatial primitive rejects invalid ${setting.keys.single} ${setting.values.single}',
      () {
        final fixture = spatialBorderFixture();
        for (final section in ['draft', 'latestPublished']) {
          final wire = behaviorRecordWire(fixture.project, const {});
          for (final primitive
              in ((wire[section] as Map)['definition'] as Map)['primitives']
                  as List) {
            (primitive as Map).addAll(setting);
          }
          expect(
            () => decodeBorderBlueprintRecordJson(wire, formatVersion: 5),
            throwsA(isA<FormatException>()),
          );
        }
      },
    );
  }

  test(
    'publication and resolution reject a clip absent from the selected model',
    () {
      final fixture = spatialBorderFixture();
      final project = behaviorProject(fixture.project, {'animationIndex': 1});
      final definition =
          project.borderCatalog.records.single.latestPublished!.definition;
      final diagnostics = validateSpatialBorderBlueprint(
        blueprintId: 'fence',
        definition: definition,
        manifest: project,
      );
      expect(diagnostics.hasErrors, isTrue);
      expect(
        diagnostics.diagnostics.map((item) => item.code),
        contains('border.spatial.animation_missing'),
      );
      final result = resolve(project, fixture.map);
      expect(result.result.canApply, isFalse);
      expect(result.modelInstances, isEmpty);
    },
  );
}

List<Object?> pose(SpatialModelInstance instance) => [
  instance.id,
  instance.modelId,
  instance.position,
  instance.rotationDegrees,
  instance.scale,
];

final borderTransforms = BorderTransformPolicy(
  allowFlipX: false,
  allowedQuarterTurns: const [0, 1, 2, 3],
);

SpatialBorderResolutionResult resolve(ProjectManifest project, MapData map) =>
    resolveSpatialBorderFeature(
      manifest: project,
      map: map,
      layerId: 'border',
      featureId: 'fence',
    );

Map<String, Object?> behaviorRecordWire(
  ProjectManifest project,
  Map<String, Object?> settings,
) {
  final wire = encodeBorderBlueprintRecordJson(
    project.borderCatalog.records.single,
    formatVersion: 5,
  );
  for (final section in ['draft', 'latestPublished']) {
    for (final primitive
        in ((wire[section] as Map)['definition'] as Map)['primitives']
            as List) {
      (primitive as Map).addAll(settings);
    }
  }
  return wire;
}

ProjectManifest behaviorProject(
  ProjectManifest project,
  Map<String, Object?> settings,
) {
  final model = project.models3d.single;
  return project.copyWith(
    models3d: [
      ProjectModel3dEntry(
        id: model.id,
        name: model.name,
        sourceAssetId: model.sourceAssetId,
        relativePath: model.relativePath,
        scale: model.scale,
        pivot: model.pivot,
        collisionBounds: model.collisionBounds,
        inspection: Model3dInspection(
          bounds: model.inspection.bounds,
          meshCount: model.inspection.meshCount,
          triangleCount: model.inspection.triangleCount,
          animations: [
            Model3dAnimation(index: 0, name: 'Shore', durationSeconds: 4),
          ],
        ),
      ),
    ],
    borderCatalog: ProjectBorderCatalog(
      formatVersion: 5,
      records: [
        decodeBorderBlueprintRecordJson(
          behaviorRecordWire(project, settings),
          formatVersion: 5,
        ),
      ],
    ),
  );
}

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/spatial_border_ground_surface_fixture.dart';

Map<String, Object?> cornerSequenceJson({int cornerJoinCells = 0}) {
  final fixture = spatialBorderFixture();
  final raw = encodeBorderBlueprintRecordJson(
    fixture.project.borderCatalog.records.single,
    formatVersion: 5,
  );
  for (final key in ['draft', 'latestPublished']) {
    final definition = (raw[key] as Map)['definition'] as Map;
    final original = (definition['primitives'] as List).cast<Map>();
    definition['sequenceLength'] = 2;
    definition['primitives'] = [
      for (var phase = 0; phase < 2; phase++)
        for (final primitive in original)
          {
            ...primitive,
            'id': 'phase-$phase-${primitive['role']}',
            'sequenceIndex': phase,
            if (primitive['role'] == 'lineCorner' && cornerJoinCells != 0)
              'cornerJoinCells': cornerJoinCells,
          },
    ];
  }
  return raw;
}

void main() {
  test('unrelated packs keep the original empty border representation', () {
    expect(ResourcePackCatalog().borderCatalog.formatVersion, 1);
    for (final version in [1, 5, 10, 11, 12, 13]) {
      final pack = ResourcePackCatalog(
        borderCatalog: ProjectBorderCatalog(formatVersion: version),
      );
      expect(
        ResourcePackCatalog.fromJson(pack.toJson()).borderCatalog.formatVersion,
        version,
      );
    }
    final future = ResourcePackCatalog().toJson();
    (future['borderCatalog'] as Map)['formatVersion'] = 14;
    expect(() => ResourcePackCatalog.fromJson(future), throwsFormatException);
  });
  test(
    'corner sequences use an explicit format without promoting old sequences',
    () {
      final record = decodeBorderBlueprintRecordJson(
        cornerSequenceJson(),
        formatVersion: 13,
      );
      expect(record.latestPublished!.definition.straightOnly, isFalse);
      expect(record.latestPublished!.definition.sequenceLength, 2);
      expect(minimumBorderCatalogFormatVersionForRecord(record), 13);
      final encoded = encodeBorderBlueprintRecordJson(
        record,
        formatVersion: 13,
      );
      expect(
        decodeBorderBlueprintRecordJson(encoded, formatVersion: 13),
        record,
      );
      expect(
        () => encodeBorderBlueprintRecordJson(record, formatVersion: 12),
        throwsFormatException,
      );
      expect(
        () => decodeBorderBlueprintRecordJson(
          cornerSequenceJson(),
          formatVersion: 12,
        ),
        throwsFormatException,
      );
      final old = spatialBorderFixture().project.borderCatalog.records.single;
      expect(minimumBorderCatalogFormatVersionForRecord(old), 5);
    },
  );

  test(
    'native corner traversal preserves the motif phase through every node',
    () {
      final fixture = spatialBorderFixture();
      final record = decodeBorderBlueprintRecordJson(
        cornerSequenceJson(),
        formatVersion: 13,
      );
      final project = fixture.project.copyWith(
        borderCatalog: ProjectBorderCatalog(
          formatVersion: 13,
          records: [record],
        ),
      );
      final report = validateSpatialBorderBlueprint(
        blueprintId: record.id,
        definition: record.latestPublished!.definition,
        manifest: project,
      );
      expect(report.hasErrors, isFalse, reason: report.toString());
      final result = resolveSpatialBorderFeature(
        manifest: project,
        map: fixture.map,
        layerId: 'border',
        featureId: 'fence',
      );
      expect(
        result.result.canApply,
        isTrue,
        reason: result.result.diagnosticReport.toString(),
      );
      final placements = result.result.materialization!.spatialPlacements;
      expect(placements.map((p) => p.primitiveId), [
        'phase-0-lineCap',
        'phase-1-lineStraight',
        'phase-0-lineCorner',
        'phase-1-lineStraight',
        'phase-0-lineCap',
      ]);
      final applied = applySpatialBorderFeaturePreview(
        fixture.map,
        manifest: project,
        proposedResult: result,
      );
      expect(
        applied.spatialScene!.heightLevels,
        fixture.map.spatialScene!.heightLevels,
      );
      expect(
        applied.spatialScene!.navigation,
        fixture.map.spatialScene!.navigation,
      );
      expect(MapData.fromJson(applied.toJson()), applied);
    },
  );

  test('publication rejects a missing corner in one motif phase', () {
    final raw = cornerSequenceJson();
    final definition = (raw['latestPublished'] as Map)['definition'] as Map;
    (definition['primitives'] as List).removeWhere(
      (p) => (p as Map)['id'] == 'phase-1-lineCorner',
    );
    final record = decodeBorderBlueprintRecordJson(raw, formatVersion: 13);
    final project = spatialBorderFixture().project;
    final report = validateSpatialBorderBlueprint(
      blueprintId: record.id,
      definition: record.latestPublished!.definition,
      manifest: project,
    );
    expect(report.hasErrors, isTrue);
    expect(
      report.diagnostics.map((d) => d.code),
      contains('border.spatial.sequence_corner_missing'),
    );
  });

  test('each directed corner phase must cover every orientation', () {
    final raw = cornerSequenceJson();
    final definition = (raw['latestPublished'] as Map)['definition'] as Map;
    definition['followContourDirection'] = true;
    final primitives = (definition['primitives'] as List).cast<Map>();
    final corners = primitives
        .where((primitive) => primitive['role'] == 'lineCorner')
        .toList();
    for (final corner in corners) {
      corner['cornerTurn'] = 'right';
      primitives.add({
        ...corner,
        'id': '${corner['id']}-left',
        'cornerTurn': 'left',
        if (corner['sequenceIndex'] == 1)
          'transforms': {
            'allowFlipX': false,
            'allowedQuarterTurns': [0],
          },
      });
    }
    final record = decodeBorderBlueprintRecordJson(raw, formatVersion: 13);
    final report = validateSpatialBorderBlueprint(
      blueprintId: record.id,
      definition: record.latestPublished!.definition,
      manifest: spatialBorderFixture().project,
    );
    expect(report.hasErrors, isTrue);
    expect(
      report.diagnostics.map((diagnostic) => diagnostic.code),
      contains('border.spatial.sequence_orientation_missing'),
    );
  });

  test('wide corners replace only their adjacent straight slots', () {
    final raw = cornerSequenceJson();
    for (final key in ['draft', 'latestPublished']) {
      final definition = (raw[key] as Map)['definition'] as Map;
      for (final primitive in (definition['primitives'] as List).cast<Map>()) {
        if (primitive['role'] == 'lineCorner') primitive['cornerJoinCells'] = 1;
      }
    }
    final record = decodeBorderBlueprintRecordJson(raw, formatVersion: 13);
    final fixture = spatialBorderFixture();
    final project = fixture.project.copyWith(
      borderCatalog: ProjectBorderCatalog(formatVersion: 13, records: [record]),
    );
    final resolved = resolveSpatialBorderFeature(
      manifest: project,
      map: fixture.map,
      layerId: 'border',
      featureId: 'fence',
    );
    expect(resolved.result.canApply, isTrue);
    expect(
      resolved.result.materialization!.spatialPlacements.map(
        (p) => p.primitiveId,
      ),
      ['phase-0-lineCap', 'phase-0-lineCorner', 'phase-0-lineCap'],
    );
    final applied = applySpatialBorderFeaturePreview(
      fixture.map,
      manifest: project,
      proposedResult: resolved,
    );
    expect(
      applied.spatialScene!.navigation,
      fixture.map.spatialScene!.navigation,
    );
    expect(MapData.fromJson(applied.toJson()), applied);
    expect(
      () => encodeBorderBlueprintRecordJson(record, formatVersion: 12),
      throwsFormatException,
    );
    expect(
      decodeBorderBlueprintRecordJson(
        encodeBorderBlueprintRecordJson(record, formatVersion: 13),
        formatVersion: 13,
      ),
      record,
    );
  });

  for (final points in [
    [
      const GridPos(x: 1, y: 1),
      const GridPos(x: 2, y: 1),
      const GridPos(x: 2, y: 2),
      const GridPos(x: 2, y: 3),
    ],
    [
      const GridPos(x: 0, y: 1),
      const GridPos(x: 1, y: 1),
      const GridPos(x: 2, y: 1),
      const GridPos(x: 2, y: 2),
      const GridPos(x: 3, y: 2),
      const GridPos(x: 4, y: 2),
    ],
  ]) {
    test(
      'wide corners reject caps or nearby angles instead of removing them (${points.length})',
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
        final map = updateBorderFeatureGeometry(
          fixture.map,
          layerId: 'border',
          featureId: 'fence',
          geometry: BorderStrokeGeometry(
            strokes: [BorderStroke(id: 'line', points: points, closed: false)],
          ),
        );
        final result = resolveSpatialBorderFeature(
          manifest: project,
          map: map,
          layerId: 'border',
          featureId: 'fence',
        );
        expect(result.result.canApply, isFalse);
        expect(result.modelInstances, isEmpty);
        expect(
          result.result.diagnostics.map((d) => d.code),
          contains('border.spatial.corner_join_conflict'),
        );
      },
    );
  }

  test(
    'wide corners preserve explicit slot edits by rejecting conflicting reservations',
    () {
      final fixture = spatialBorderFixture();
      final oldRecord = decodeBorderBlueprintRecordJson(
        cornerSequenceJson(),
        formatVersion: 13,
      );
      final oldProject = fixture.project.copyWith(
        borderCatalog: ProjectBorderCatalog(
          formatVersion: 13,
          records: [oldRecord],
        ),
      );
      final original = resolveSpatialBorderFeature(
        manifest: oldProject,
        map: fixture.map,
        layerId: 'border',
        featureId: 'fence',
      );
      final slot =
          original.result.materialization!.spatialPlacements[1].slotKey;
      final map = updateBorderFeatureOverrides(
        fixture.map,
        layerId: 'border',
        featureId: 'fence',
        overrides: [
          BorderSlotOverride(
            slotKey: slot,
            variationSalt: BorderSignedInt64.fromInt(9),
            suppressed: false,
            locked: false,
          ),
        ],
      );
      final record = decodeBorderBlueprintRecordJson(
        cornerSequenceJson(cornerJoinCells: 1),
        formatVersion: 13,
      );
      final project = oldProject.copyWith(
        borderCatalog: ProjectBorderCatalog(
          formatVersion: 13,
          records: [record],
        ),
      );
      final result = resolveSpatialBorderFeature(
        manifest: project,
        map: map,
        layerId: 'border',
        featureId: 'fence',
      );
      expect(result.result.canApply, isFalse);
      expect(
        result.result.diagnostics.map((d) => d.code),
        contains('border.spatial.corner_join_override_conflict'),
      );
      expect(result.modelInstances, isEmpty);
    },
  );

  test('corner join lengths require portable bounded integer corner data', () {
    for (final value in <Object?>[-1, 9, 1.0, '1', null]) {
      final raw = cornerSequenceJson();
      final definition = (raw['draft'] as Map)['definition'] as Map;
      ((definition['primitives'] as List)[2] as Map)['cornerJoinCells'] = value;
      expect(
        () => decodeBorderBlueprintRecordJson(raw, formatVersion: 13),
        throwsFormatException,
        reason: '$value',
      );
    }
    final raw = cornerSequenceJson(cornerJoinCells: 1);
    expect(
      () => decodeBorderBlueprintRecordJson(raw, formatVersion: 12),
      throwsFormatException,
    );
    final record = decodeBorderBlueprintRecordJson(raw, formatVersion: 13);
    expect(
      reconstructResourcePackBorderDraft(record.latestPublished!)
          .definition
          .primitives
          .where((p) => p.role == BorderPrimitiveRole.lineCorner)
          .map((p) => p.cornerJoinCells),
      everyElement(1),
    );
  });

  test(
    'wide corner reservations wrap closed contours without resetting phases',
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
      final map = updateBorderFeatureGeometry(
        fixture.map,
        layerId: 'border',
        featureId: 'fence',
        geometry: BorderStrokeGeometry(
          strokes: [
            BorderStroke(
              id: 'loop',
              closed: true,
              points: [
                for (var x = 1; x < 5; x++) GridPos(x: x, y: 1),
                for (var y = 1; y < 5; y++) GridPos(x: 5, y: y),
                for (var x = 5; x > 1; x--) GridPos(x: x, y: 5),
                for (var y = 5; y > 1; y--) GridPos(x: 1, y: y),
              ],
            ),
          ],
        ),
      );
      final result = resolveSpatialBorderFeature(
        manifest: project,
        map: map,
        layerId: 'border',
        featureId: 'fence',
      );
      expect(result.result.canApply, isTrue);
      final placements = result.result.materialization!.spatialPlacements;
      expect(placements, hasLength(8));
      expect(
        placements.where((p) => p.primitiveId.contains('lineCorner')),
        hasLength(4),
      );
      expect(
        placements.map((p) => p.primitiveId),
        everyElement(startsWith('phase-0-')),
      );
    },
  );

  test(
    'regenerating a wide corner removes only its previous owned neighbors',
    () {
      final fixture = spatialBorderFixture();
      final oldRecord = decodeBorderBlueprintRecordJson(
        cornerSequenceJson(),
        formatVersion: 13,
      );
      final oldProject = fixture.project.copyWith(
        borderCatalog: ProjectBorderCatalog(
          formatVersion: 13,
          records: [oldRecord],
        ),
      );
      final oldResult = resolveSpatialBorderFeature(
        manifest: oldProject,
        map: fixture.map,
        layerId: 'border',
        featureId: 'fence',
      );
      final oldMap = applySpatialBorderFeaturePreview(
        fixture.map,
        manifest: oldProject,
        proposedResult: oldResult,
      );
      final foreign = SpatialModelInstance(
        id: 'foreign',
        modelId: 'unit',
        position: Model3dVector3(x: 5, y: 1, z: 5),
      );
      final map = oldMap.copyWith(
        spatialScene: oldMap.spatialScene!.copyWith(
          instances: [...oldMap.spatialScene!.instances, foreign],
        ),
      );
      final record = decodeBorderBlueprintRecordJson(
        cornerSequenceJson(cornerJoinCells: 1),
        formatVersion: 13,
      );
      final project = oldProject.copyWith(
        borderCatalog: ProjectBorderCatalog(
          formatVersion: 13,
          records: [record],
        ),
      );
      final result = resolveSpatialBorderFeature(
        manifest: project,
        map: map,
        layerId: 'border',
        featureId: 'fence',
      );
      expect(result.result.canApply, isTrue);
      final applied = applySpatialBorderFeaturePreview(
        map,
        manifest: project,
        proposedResult: result,
      );
      expect(applied.spatialScene!.instances, hasLength(4));
      expect(
        applied.spatialScene!.instances.singleWhere((i) => i.id == 'foreign'),
        foreign,
      );
      expect(
        applied.spatialScene!.heightLevels,
        map.spatialScene!.heightLevels,
      );
      expect(applied.spatialScene!.navigation, map.spatialScene!.navigation);
      expect(
        resolveSpatialBorderFeature(
          manifest: project,
          map: applied,
          layerId: 'border',
          featureId: 'fence',
        ).result.materialization,
        result.result.materialization,
      );
    },
  );

  test('suppressing a wide corner restores its neighboring straight slots', () {
    final fixture = spatialBorderFixture();
    final record = decodeBorderBlueprintRecordJson(
      cornerSequenceJson(cornerJoinCells: 1),
      formatVersion: 13,
    );
    final project = fixture.project.copyWith(
      borderCatalog: ProjectBorderCatalog(formatVersion: 13, records: [record]),
    );
    final original = resolveSpatialBorderFeature(
      manifest: project,
      map: fixture.map,
      layerId: 'border',
      featureId: 'fence',
    );
    final slot = original.result.materialization!.spatialPlacements[1].slotKey;
    final map = updateBorderFeatureOverrides(
      fixture.map,
      layerId: 'border',
      featureId: 'fence',
      overrides: [
        BorderSlotOverride(
          slotKey: slot,
          variationSalt: BorderSignedInt64.fromInt(0),
          suppressed: true,
          locked: false,
        ),
      ],
    );
    final result = resolveSpatialBorderFeature(
      manifest: project,
      map: map,
      layerId: 'border',
      featureId: 'fence',
    );
    expect(result.result.canApply, isTrue);
    expect(
      result.result.materialization!.spatialPlacements.map(
        (p) => p.primitiveId,
      ),
      [
        'phase-0-lineCap',
        'phase-1-lineStraight',
        'phase-1-lineStraight',
        'phase-0-lineCap',
      ],
    );
  });
}

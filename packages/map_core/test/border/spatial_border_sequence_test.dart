import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/spatial_border_ground_surface_fixture.dart';

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

SpatialBorderResolutionResult sequenceResolve(
  ProjectManifest project,
  MapData map,
) => resolveSpatialBorderFeature(
  manifest: project,
  map: map,
  layerId: 'border',
  featureId: 'fence',
);

List<int> phases(
  SpatialBorderResolutionResult result, {
  bool vertical = false,
}) {
  final instances = result.modelInstances.toList()
    ..sort(
      (a, b) => (vertical ? a.position.z : a.position.x).compareTo(
        vertical ? b.position.z : b.position.x,
      ),
    );
  return instances.map((i) => int.parse(i.modelId.split('-').last)).toList();
}

BorderFeature featureOf(MapData map) =>
    (map.layers.single as BorderLayer).content.features.single;

MapData eraseAt(MapData map, int x) {
  final geometry = BorderStrokeEditingDraft.begin(
    baseGeometry: featureOf(map).geometry as BorderStrokeGeometry,
    mode: BorderStrokeEditingMode.erase,
    preserveTraversal: false,
    pointerDown: GridPos(x: x, y: 4),
  ).previewGeometry!;
  return updateBorderFeatureGeometry(
    map,
    layerId: 'border',
    featureId: 'fence',
    geometry: geometry,
  );
}

void main() {
  test('portable lineage offsets preserve exact modular phase arithmetic', () {
    final fixture = sequenceFixture(count: 3);
    final geometry = featureOf(fixture.map).geometry as BorderStrokeGeometry;
    final points = geometry.strokes.single.points;
    final changed = updateBorderFeatureGeometry(fixture.map, layerId: 'border', featureId: 'fence',
      geometry: BorderStrokeGeometry(strokes: [BorderStroke(id: buildBorderPreservedStrokeIdV1(
        authoredStrokeId: 'line', sourceEdgeOffset: 9007199254740990, wrapLength: null, orderedPoints: points),
        points: points, closed: false)]));
    final result = sequenceResolve(fixture.project, changed);
    expect(result.result.canApply, isTrue);
    expect(phases(result), [0, 1, 2]);
  });

  test('default erase retains authored traversal for directed consumers', () {
    final fixture = sequenceFixture(reverse: true);
    final geometry = featureOf(fixture.map).geometry as BorderStrokeGeometry;
    final draft = BorderStrokeEditingDraft.begin(
      baseGeometry: geometry,
      mode: BorderStrokeEditingMode.erase,
      pointerDown: const GridPos(x: 8, y: 4),
    );
    expect(draft.preserveTraversal, isTrue);
    expect(draft.sample(const GridPos(x: 8, y: 4)).preserveTraversal, isTrue);
    final fragment = draft.previewGeometry!.strokes.first;
    expect(fragment.points.first.x, 16);
    expect(fragment.points.last.x, 9);
    expect(resolveBorderStrokeLineageIdentityV1(fragment).sourceEdgeOffset, 0);
    expect(
      resolveBorderStrokeLineageIdentityV1(fragment).preserveTraversal,
      isTrue,
    );
  });

  test('raw reverse traversal retains canonical phases after erasure', () {
    final fixture = sequenceFixture(reverse: true);
    final erased = eraseAt(fixture.map, 8);
    final result = sequenceResolve(fixture.project, erased);
    expect(result.result.canApply, isTrue);
    for (final instance in result.modelInstances) {
      expect(instance.modelId, 'unit-${(instance.position.x.floor() - 4) % 6}');
    }
  });

  test('catalog mutation promotes cyclic definitions to format12', () {
    final fixture = sequenceFixture();
    expect(
      minimumBorderCatalogFormatVersionForRecords(
        fixture.project.borderCatalog.records,
      ),
      12,
    );
  });

  test(
    'format12 retains authored cycle in draft and published definitions',
    () {
      final raw = sequenceRecordJson();
      final record = decodeBorderBlueprintRecordJson(raw, formatVersion: 12);
      final encoded = encodeBorderBlueprintRecordJson(
        record,
        formatVersion: 12,
      );
      expect(
        decodeBorderBlueprintRecordJson(encoded, formatVersion: 12),
        record,
      );
      final restored = reconstructResourcePackBorderDraft(
        record.latestPublished!,
      );
      expect(restored.definition, record.draft.definition);
    },
  );

  test(
    'project and portable catalog roundtrips preserve the complete sequence',
    () {
      final fixture = sequenceFixture();
      expect(
        ProjectManifest.fromJson(fixture.project.toJson()),
        fixture.project,
      );
      final portable = encodeResourcePackBorderCatalog(
        fixture.project.borderCatalog,
      );
      final restored = decodeResourcePackBorderCatalog(
        Map<String, dynamic>.from(portable),
      );
      expect(restored, fixture.project.borderCatalog);
    },
  );

  test(
    'source cycle covers arbitrary node counts and cardinal traversal directions',
    () {
      for (final count in [2, 6, 7, 12, 13, 18]) {
        for (final vertical in [false, true]) {
          for (final reverse in [false, true]) {
            final fixture = sequenceFixture(
              count: count,
              vertical: vertical,
              reverse: reverse,
            );
            final result = sequenceResolve(fixture.project, fixture.map);
            expect(result.result.canApply, isTrue);
            expect(phases(result, vertical: vertical), [
              for (var i = 0; i < count; i++) i % 6,
            ]);
            expect(
              result.modelInstances.map((i) => i.rotationDegrees),
              everyElement(vertical ? -90.0 : 0.0),
            );
          }
        }
      }
    },
  );

  test('publication rejects a missing phase and missing cap orientation', () {
    final fixture = sequenceFixture();
    for (final orientationOnly in [false, true]) {
      final raw = sequenceRecordJson();
      final definition = (raw['latestPublished'] as Map)['definition'] as Map;
      definition['primitives'] = (definition['primitives'] as List)
          .where(
            (p) => orientationOnly
                ? (p as Map)['id'] != 'phase-3-end'
                : (p as Map)['sequenceIndex'] != 3,
          )
          .toList();
      final record = decodeBorderBlueprintRecordJson(raw, formatVersion: 12);
      expect(
        validateSpatialBorderBlueprint(
          blueprintId: 'fence',
          definition: record.latestPublished!.definition,
          manifest: fixture.project,
        ).hasErrors,
        isTrue,
      );
    }
  });

  test('cycle fields require format12 and valid portable integer values', () {
    expect(
      () => decodeBorderBlueprintRecordJson(
        sequenceRecordJson(),
        formatVersion: 11,
      ),
      throwsFormatException,
    );
    final record = decodeBorderBlueprintRecordJson(
      sequenceRecordJson(),
      formatVersion: 12,
    );
    expect(
      () => encodeBorderBlueprintRecordJson(record, formatVersion: 11),
      throwsFormatException,
    );
    for (final invalid in [0, -1, 1.5, true, null, 9007199254740992]) {
      final raw = sequenceRecordJson();
      ((raw['draft'] as Map)['definition'] as Map)['sequenceLength'] = invalid;
      expect(
        () => decodeBorderBlueprintRecordJson(raw, formatVersion: 12),
        throwsFormatException,
      );
    }
    for (final invalid in [-1, 6, 1.5, true, null, 9007199254740992]) {
      final raw = sequenceRecordJson();
      final definition = (raw['draft'] as Map)['definition'] as Map;
      (definition['primitives'] as List).first['sequenceIndex'] = invalid;
      expect(
        () => decodeBorderBlueprintRecordJson(raw, formatVersion: 12),
        throwsFormatException,
      );
    }
  });

  test('publication fingerprint and typed equality include cycle fields', () {
    final six = decodeBorderBlueprintRecordJson(
      sequenceRecordJson(),
      formatVersion: 12,
    );
    final sevenJson = sequenceRecordJson();
    ((sevenJson['latestPublished'] as Map)['definition']
            as Map)['sequenceLength'] =
        7;
    final seven = decodeBorderBlueprintRecordJson(sevenJson, formatVersion: 12);
    String fingerprint(BorderBlueprintRecord record) =>
        computeBorderPublicationCandidateFingerprint(
          blueprintId: 'fence',
          definition: record.latestPublished!.definition,
          resolverVersion: 1,
          canonicalGalleryVersion: 1,
        );
    expect(
      six.latestPublished!.definition,
      isNot(seven.latestPublished!.definition),
    );
    expect(fingerprint(six), isNot(fingerprint(seven)));
    final shiftedJson = sequenceRecordJson();
    final first =
        ((((shiftedJson['latestPublished'] as Map)['definition']
                        as Map)['primitives'])
                    as List)
                .first
            as Map;
    first['sequenceIndex'] = 1;
    final shifted = decodeBorderBlueprintRecordJson(
      shiftedJson,
      formatVersion: 12,
    );
    expect(fingerprint(six), isNot(fingerprint(shifted)));
  });

  test('suppression does not advance the phase of surviving source nodes', () {
    final fixture = sequenceFixture();
    final original = sequenceResolve(fixture.project, fixture.map);
    final slot = original.result.materialization!.spatialPlacements[2].slotKey;
    final changed = updateBorderFeatureOverrides(
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
    final result = sequenceResolve(fixture.project, changed);
    expect(result.result.canApply, isTrue);
    expect(phases(result), [
      for (var index = 0; index < 13; index++)
        if (index != 2) index % 6,
    ]);
  });

  test(
    'erased fragments and repeated erasures retain the original phase lineage',
    () {
      final fixture = sequenceFixture(count: 18);
      final once = eraseAt(fixture.map, 8);
      final twice = eraseAt(once, 14);
      for (final map in [once, twice]) {
        final result = sequenceResolve(fixture.project, map);
        expect(result.result.canApply, isTrue);
        for (final instance in result.modelInstances) {
          final sourceIndex = instance.position.x.floor() - 4;
          expect(instance.modelId, 'unit-${sourceIndex % 6}');
        }
      }
    },
  );

  test(
    'resizing an erased source fragment retains its nonzero phase offset',
    () {
      final fixture = sequenceFixture();
      final erased = eraseAt(fixture.map, 4);
      final content = (erased.layers.single as BorderLayer).content;
      final resize = resizeBorderLayerContent(
        content: content,
        oldMapSize: erased.size,
        newMapSize: const GridSize(width: 10, height: 64),
        tileSizePx: const GridSize(width: 1, height: 1),
        layerId: 'border',
      );
      expect(resize.canApply, isTrue);
      final map = erased.copyWith(
        size: const GridSize(width: 10, height: 64),
        spatialScene: MapSpatialScene(width: 10, depth: 64),
        layers: [
          MapLayer.border(
            id: 'border',
            name: 'Fence',
            content: resize.content!,
          ),
        ],
      );
      final result = sequenceResolve(fixture.project, map);
      expect(result.result.canApply, isTrue);
      expect(phases(result), [1, 2, 3, 4, 5]);
    },
  );

  test(
    'translation changes placement coordinates without restarting the cycle',
    () {
      final fixture = sequenceFixture();
      final source = featureOf(fixture.map).geometry as BorderStrokeGeometry;
      final translated = BorderStrokeGeometry(
        strokes: [
          for (final stroke in source.strokes)
            BorderStroke(
              id: stroke.id,
              points: [
                for (final p in stroke.points) GridPos(x: p.x + 3, y: p.y + 2),
              ],
              closed: false,
            ),
        ],
      );
      final moved = moveSpatialBorderFeature(
        fixture.map,
        manifest: fixture.project,
        layerId: 'border',
        featureId: 'fence',
        geometry: translated,
        dx: 3,
        dz: 2,
      );
      final result = sequenceResolve(fixture.project, moved);
      expect(result.result.canApply, isTrue);
      expect(phases(result), [for (var i = 0; i < 13; i++) i % 6]);
      expect(result.modelInstances.first.position.x, 7.5);
      expect(result.modelInstances.first.position.z, 6.5);
    },
  );

  test(
    'sequence inversion and phase-incompatible replacements are rejected',
    () {
      final fixture = sequenceFixture();
      final feature = featureOf(fixture.map);
      final inverted = decodeBorderFeatureJson({
        ...encodeBorderFeatureJson(feature, formatVersion: 4),
        'lineSide': 'inverted',
      }, formatVersion: 4);
      final map = upsertBorderFeature(
        fixture.map,
        layerId: 'border',
        feature: inverted,
      );
      final result = sequenceResolve(fixture.project, map);
      expect(result.result.canApply, isFalse);
      expect(
        result.result.diagnostics.map((d) => d.code),
        contains('border.spatial.line_side_inversion_unsupported'),
      );
      final normal = sequenceResolve(fixture.project, fixture.map);
      final slot = normal.result.materialization!.spatialPlacements[2].slotKey;
      final replaced = updateBorderFeatureOverrides(
        fixture.map,
        layerId: 'border',
        featureId: 'fence',
        overrides: [
          BorderSlotOverride(
            slotKey: slot,
            variationSalt: BorderSignedInt64.fromInt(0),
            suppressed: false,
            locked: false,
            replacementPrimitiveId: 'phase-4-body',
          ),
        ],
      );
      expect(
        sequenceResolve(fixture.project, replaced).result.canApply,
        isFalse,
      );
    },
  );
}

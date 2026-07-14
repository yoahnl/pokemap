import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Border primitives', () {
    test('draft weights include zero through one thousand', () {
      expect(_draftPrimitive(weight: 0).weight, 0);
      expect(_draftPrimitive(weight: 1000).weight, 1000);

      for (final weight in <int>[-1, 1001]) {
        expect(
          () => _draftPrimitive(weight: weight),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('published weights exclude zero and retain snapshot identity', () {
      expect(_publishedPrimitive(weight: 1).weight, 1);
      expect(_publishedPrimitive(weight: 1000).weight, 1000);
      expect(_publishedPrimitive().visualSnapshotId, _snapshotId);

      for (final weight in <int>[0, 1001]) {
        expect(
          () => _publishedPrimitive(weight: weight),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('draft and published primitives have value semantics', () {
      expect(_draftPrimitive(), _draftPrimitive());
      expect(_publishedPrimitive(), _publishedPrimitive());
    });
  });

  group('Border ground definitions', () {
    test('V1 Surface role completeness has an explicit stable order', () {
      expect(
        standardSurfaceVariantRoleOrder.map((role) => role.name),
        const <String>[
          'isolated',
          'endNorth',
          'endEast',
          'endSouth',
          'endWest',
          'horizontal',
          'vertical',
          'cornerNE',
          'cornerSE',
          'cornerSW',
          'cornerNW',
          'innerCornerNE',
          'innerCornerSE',
          'innerCornerSW',
          'innerCornerNW',
          'teeNorth',
          'teeEast',
          'teeSouth',
          'teeWest',
          'cross',
        ],
      );
    });

    test('draft ground requires a positive inner edge band', () {
      expect(
        BorderGroundDraft(
          sourceSurfacePresetId: 'water',
          edgeBandCells: 1,
        ).edgeBandCells,
        1,
      );
      expect(
        () => BorderGroundDraft(
          sourceSurfacePresetId: 'water',
          edgeBandCells: 0,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('published ground freezes a total role-to-snapshot map', () {
      final snapshots = _surfaceSnapshots();
      final ground = BorderPublishedGround(
        sourceSurfacePresetId: 'water',
        edgeBandCells: 2,
        visualSnapshotIdsByRole: snapshots,
      );

      snapshots[SurfaceVariantRole.isolated] = 'changed';

      expect(
        ground.visualSnapshotIdsByRole[SurfaceVariantRole.isolated],
        _snapshotId,
      );
      expect(
        () => ground.visualSnapshotIdsByRole.clear(),
        throwsUnsupportedError,
      );
      expect(
        ground,
        BorderPublishedGround(
          sourceSurfacePresetId: 'water',
          edgeBandCells: 2,
          visualSnapshotIdsByRole: _surfaceSnapshots(),
        ),
      );
    });

    test('published ground rejects missing V1 roles and non-positive bands',
        () {
      final incomplete = _surfaceSnapshots()..remove(SurfaceVariantRole.cross);

      expect(
        () => BorderPublishedGround(
          sourceSurfacePresetId: 'water',
          edgeBandCells: 1,
          visualSnapshotIdsByRole: incomplete,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => BorderPublishedGround(
          sourceSurfacePresetId: 'water',
          edgeBandCells: 0,
          visualSnapshotIdsByRole: _surfaceSnapshots(),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('dangling cross-catalog references remain loadable in models', () {
      final draftPrimitive = _draftPrimitive(
        sourceElementId: 'missing-element',
      );
      final publishedPrimitive = _publishedPrimitive(
        sourceElementId: 'missing-element',
        visualSnapshotId: 'missing-snapshot',
      );
      final draftGround = BorderGroundDraft(
        sourceSurfacePresetId: 'missing-surface',
        edgeBandCells: 1,
      );
      final publishedGround = BorderPublishedGround(
        sourceSurfacePresetId: 'missing-surface',
        edgeBandCells: 1,
        visualSnapshotIdsByRole: _surfaceSnapshots(
          snapshotId: 'missing-snapshot',
        ),
      );

      expect(draftPrimitive.sourceElementId, 'missing-element');
      expect(publishedPrimitive.sourceElementId, 'missing-element');
      expect(publishedPrimitive.visualSnapshotId, 'missing-snapshot');
      expect(draftGround.sourceSurfacePresetId, 'missing-surface');
      expect(
        publishedGround.visualSnapshotIdsByRole[SurfaceVariantRole.isolated],
        'missing-snapshot',
      );
    });

    test('primitive, ground, definition, and record IDs reject empty values',
        () {
      for (final createInvalid in <Object Function()>[
        () => _draftPrimitive(id: ''),
        () => _draftPrimitive(sourceElementId: ''),
        () => _publishedPrimitive(sourceElementId: ''),
        () => _publishedPrimitive(visualSnapshotId: ''),
        () => BorderGroundDraft(
              sourceSurfacePresetId: '',
              edgeBandCells: 1,
            ),
        () => BorderPublishedGround(
              sourceSurfacePresetId: '',
              edgeBandCells: 1,
              visualSnapshotIdsByRole: _surfaceSnapshots(),
            ),
        () => BorderPublishedGround(
              sourceSurfacePresetId: 'surface',
              edgeBandCells: 1,
              visualSnapshotIdsByRole: _surfaceSnapshots()
                ..[SurfaceVariantRole.isolated] = '',
            ),
        () =>
            BorderBlueprintDefinition<BorderPrimitiveDraft, BorderGroundDraft>(
              name: '',
              previewSeed: BorderSignedInt64.zero,
              template: BorderBlueprintTemplate.organicEdge,
              primitives: const <BorderPrimitiveDraft>[],
              defaults: _defaults(),
              sortOrder: 0,
            ),
        () => BorderBlueprintRecord(
              id: '',
              draft: BorderBlueprintDraft(
                baseRevision: 0,
                definition: _draftDefinition(),
              ),
            ),
      ]) {
        expect(createInvalid, throwsA(isA<ValidationException>()));
      }
    });

    test('record IDs must be nonblank and already trimmed', () {
      for (final id in <String>[' ', ' coast', 'coast ']) {
        expect(
          () => BorderBlueprintRecord(
            id: id,
            draft: BorderBlueprintDraft(
              baseRevision: 0,
              definition: _draftDefinition(),
            ),
          ),
          throwsA(isA<ValidationException>()),
          reason: '"$id"',
        );
      }
    });
  });

  group('Border blueprint draft and revision', () {
    test('definition freezes primitives and compares their order', () {
      final primitives = <BorderPrimitiveDraft>[
        _draftPrimitive(id: 'large'),
        _draftPrimitive(id: 'filler', role: BorderPrimitiveRole.filler),
      ];
      final definition = _draftDefinition(primitives: primitives);

      primitives.clear();

      expect(definition.primitives, hasLength(2));
      expect(() => definition.primitives.clear(), throwsUnsupportedError);
      expect(
        definition,
        _draftDefinition(
          primitives: <BorderPrimitiveDraft>[
            _draftPrimitive(id: 'large'),
            _draftPrimitive(id: 'filler', role: BorderPrimitiveRole.filler),
          ],
        ),
      );
      expect(
        definition,
        isNot(
          _draftDefinition(
            primitives: definition.primitives.reversed.toList(),
          ),
        ),
      );
    });

    test('definition equality is symmetric across generic instantiations', () {
      final narrow = _draftDefinition();
      final equalNarrow = _draftDefinition();
      final wide = BorderBlueprintDefinition<Object, Object>(
        name: narrow.name,
        previewSeed: narrow.previewSeed,
        template: narrow.template,
        primitives: <Object>[...narrow.primitives],
        defaults: narrow.defaults,
        ground: narrow.ground,
        categoryId: narrow.categoryId,
        sortOrder: narrow.sortOrder,
      );

      expect(narrow, equalNarrow);
      expect(narrow.hashCode, equalNarrow.hashCode);
      expect(narrow == wide, isFalse);
      expect(wide == narrow, isFalse);
    });

    test('record retains its draft and optional latest published revision', () {
      final draft = BorderBlueprintDraft(
        baseRevision: 1,
        definition: _draftDefinition(),
      );
      final published = BorderBlueprintRevision(
        revision: 1,
        definition: _publishedDefinition(),
      );
      final record = BorderBlueprintRecord(
        id: 'coast',
        draft: draft,
        latestPublished: published,
      );

      expect(record.draft, draft);
      expect(record.latestPublished, published);
      expect(record.isDeprecated, isFalse);
      expect(
        record,
        BorderBlueprintRecord(
          id: 'coast',
          draft: BorderBlueprintDraft(
            baseRevision: 1,
            definition: _draftDefinition(),
          ),
          latestPublished: BorderBlueprintRevision(
            revision: 1,
            definition: _publishedDefinition(),
          ),
        ),
      );
      expect(
        BorderBlueprintRecord(
          id: 'new-border',
          draft: BorderBlueprintDraft(
            baseRevision: 0,
            definition: _draftDefinition(),
          ),
        ).latestPublished,
        isNull,
      );
      expect(
        record,
        isNot(
          BorderBlueprintRecord(
            id: 'coast',
            draft: draft,
            latestPublished: published,
            isDeprecated: true,
          ),
        ),
      );
    });

    test('revision counters enforce draft and published domains', () {
      expect(
        () => BorderBlueprintDraft(
          baseRevision: -1,
          definition: _draftDefinition(),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => BorderBlueprintRevision(
          revision: 0,
          definition: _publishedDefinition(),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('preview seed supports the signed 64-bit boundaries', () {
      expect(
        _draftDefinition(previewSeed: BorderSignedInt64.minimum).previewSeed,
        BorderSignedInt64.minimum,
      );
      expect(
        _draftDefinition(previewSeed: BorderSignedInt64.maximum).previewSeed,
        BorderSignedInt64.maximum,
      );
    });
  });
}

const String _snapshotId =
    'border-snapshot-sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

BorderPrimitiveAssetMetrics _metrics() {
  return BorderPrimitiveAssetMetrics(
    assetFingerprint: 'asset-fingerprint',
    pixelSize: const GridSize(width: 16, height: 16),
    opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 16, height: 16),
    defaultAnchorPx: const BorderPixelPos(x: 8, y: 15),
    occupancyMaskRle: 'not-decoded-here',
  );
}

BorderTransformPolicy _transforms() {
  return BorderTransformPolicy(
    allowFlipX: true,
    allowedQuarterTurns: <int>[0, 2],
  );
}

BorderPrimitiveDraft _draftPrimitive({
  String id = 'large',
  String? sourceElementId,
  BorderPrimitiveRole role = BorderPrimitiveRole.structureLarge,
  int weight = 500,
}) {
  return BorderPrimitiveDraft(
    id: id,
    sourceElementId: sourceElementId ?? 'element-$id',
    role: role,
    weight: weight,
    anchorPx: const BorderPixelPos(x: 8, y: 15),
    transforms: _transforms(),
    currentMetrics: _metrics(),
  );
}

BorderPublishedPrimitive _publishedPrimitive({
  int weight = 500,
  String sourceElementId = 'element-large',
  String visualSnapshotId = _snapshotId,
}) {
  return BorderPublishedPrimitive(
    id: 'large',
    sourceElementId: sourceElementId,
    visualSnapshotId: visualSnapshotId,
    role: BorderPrimitiveRole.structureLarge,
    weight: weight,
    anchorPx: const BorderPixelPos(x: 8, y: 15),
    transforms: _transforms(),
    publishedMetrics: _metrics(),
  );
}

BorderGenerationParams _defaults() {
  return BorderGenerationParams(
    irregularityPermille: 500,
    detailDensityPermille: 500,
    variationPermille: 500,
    maxOverlapPx: 2,
    gapTolerancePx: 1,
    depthRows: 2,
  );
}

BorderBlueprintDefinition<BorderPrimitiveDraft, BorderGroundDraft>
    _draftDefinition({
  List<BorderPrimitiveDraft>? primitives,
  Object previewSeed = 42,
}) {
  return BorderBlueprintDefinition<BorderPrimitiveDraft, BorderGroundDraft>(
    name: 'Rocky coast',
    previewSeed: _signedInt64(previewSeed),
    template: BorderBlueprintTemplate.organicEdge,
    primitives: primitives ?? <BorderPrimitiveDraft>[_draftPrimitive()],
    defaults: _defaults(),
    ground: BorderGroundDraft(
      sourceSurfacePresetId: 'water',
      edgeBandCells: 2,
    ),
    categoryId: 'nature',
    sortOrder: 10,
  );
}

BorderBlueprintDefinition<BorderPublishedPrimitive, BorderPublishedGround>
    _publishedDefinition() {
  return BorderBlueprintDefinition<BorderPublishedPrimitive,
      BorderPublishedGround>(
    name: 'Rocky coast',
    previewSeed: BorderSignedInt64.fromInt(42),
    template: BorderBlueprintTemplate.organicEdge,
    primitives: <BorderPublishedPrimitive>[_publishedPrimitive()],
    defaults: _defaults(),
    ground: BorderPublishedGround(
      sourceSurfacePresetId: 'water',
      edgeBandCells: 2,
      visualSnapshotIdsByRole: _surfaceSnapshots(),
    ),
    categoryId: 'nature',
    sortOrder: 10,
  );
}

BorderSignedInt64 _signedInt64(Object value) => switch (value) {
      BorderSignedInt64() => value,
      int() => BorderSignedInt64.fromInt(value),
      _ => throw ArgumentError.value(value, 'value'),
    };

Map<SurfaceVariantRole, String> _surfaceSnapshots({
  String snapshotId = _snapshotId,
}) {
  return <SurfaceVariantRole, String>{
    for (final role in standardSurfaceVariantRoleOrder) role: snapshotId,
  };
}

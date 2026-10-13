import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'spatial_border_resolution_test.dart' show spatialBorderFixture;

void main() {
  test('spatial Borders retain the jump contract and bind their receipt', () {
    final fixture = spatialBorderFixture();
    final record = fixture.project.borderCatalog.records.single;
    final before = resolveSpatialBorderFeature(
      manifest: fixture.project,
      map: fixture.map,
      layerId: 'border',
      featureId: 'fence',
    );
    expect(before.result.canApply, isTrue);
    final raw =
        jsonDecode(
              jsonEncode(
                encodeBorderBlueprintRecordJson(record, formatVersion: 5),
              ),
            )
            as Map<String, dynamic>;
    for (final branch in ['draft', 'latestPublished']) {
      final candidate = jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
      _definition(candidate, branch)['jumpBehavior'] = _jump();
      expect(
        minimumBorderCatalogFormatVersionForRecord(
          decodeBorderBlueprintRecordJson(candidate, formatVersion: 6),
        ),
        6,
        reason: branch,
      );
    }
    _definition(raw, 'latestPublished')['jumpBehavior'] = _jump();
    final updated = decodeBorderBlueprintRecordJson(raw, formatVersion: 6);
    final project = fixture.project.copyWith(
      borderCatalog: ProjectBorderCatalog(formatVersion: 6, records: [updated]),
    );
    final after = resolveSpatialBorderFeature(
      manifest: project,
      map: fixture.map,
      layerId: 'border',
      featureId: 'fence',
    );
    expect(after.result.canApply, isTrue);
    expect(
      after.result.materialization!.receipt.components.blueprint,
      isNot(before.result.materialization!.receipt.components.blueprint),
    );
    expect(after.modelInstances, before.modelInstances);
  });

  test('draft and published Border retain their directed jump property', () {
    final raw = _withJump();
    final record = decodeBorderBlueprintRecordJson(raw, formatVersion: 6);
    expect(encodeBorderBlueprintRecordJson(record, formatVersion: 6), raw);
    expect(_definition(raw, 'draft')['jumpBehavior'], _jump());
    expect(_definition(raw, 'latestPublished')['jumpBehavior'], _jump());
  });

  test('jump property cannot be silently written into an older format', () {
    final record = decodeBorderBlueprintRecordJson(
      _withJump(),
      formatVersion: 6,
    );
    expect(
      () => encodeBorderBlueprintRecordJson(record, formatVersion: 5),
      throwsFormatException,
    );
    expect(
      () => decodeBorderBlueprintRecordJson(_withJump(), formatVersion: 5),
      throwsFormatException,
    );
  });

  test('jump property has a closed typed and bounded wire contract', () {
    final malformed = <Map<String, Object?>>[
      {..._jump(), 'extra': true},
      {..._jump()}..remove('side'),
      {..._jump(), 'side': 'south'},
      {..._jump(), 'side': null},
      {..._jump(), 'distanceCells': 1},
      {..._jump(), 'distanceCells': 3},
      {..._jump(), 'distanceCells': 2.0},
      {..._jump(), 'durationMs': 0},
      {..._jump(), 'durationMs': 60001},
      {..._jump(), 'durationMs': '640'},
      {..._jump(), 'peakHeightPx': 0},
      {..._jump(), 'peakHeightPx': 1025},
      {..._jump(), 'peakHeightPx': true},
    ];
    for (final jump in malformed) {
      final raw = _withJump();
      _definition(raw, 'draft')['jumpBehavior'] = jump;
      expect(
        () => decodeBorderBlueprintRecordJson(raw, formatVersion: 6),
        throwsFormatException,
        reason: '$jump',
      );
    }
  });

  test(
    'catalog promotion sees jump properties in both retained definitions',
    () {
      for (final branch in ['draft', 'latestPublished']) {
        final raw = _recordJson();
        _definition(raw, branch)['jumpBehavior'] = _jump();
        final record = decodeBorderBlueprintRecordJson(raw, formatVersion: 6);
        final catalog = ProjectBorderCatalog(
          formatVersion: minimumBorderCatalogFormatVersionForRecord(record),
          records: [record],
        );
        expect(catalog.formatVersion, 6, reason: branch);
        expect(
          decodeProjectBorderCatalogJson(
            encodeProjectBorderCatalogJson(catalog),
          ),
          catalog,
        );
      }
    },
  );

  test('ordinary Border wire data and catalog version stay unchanged', () {
    final raw = _recordJson();
    final record = decodeBorderBlueprintRecordJson(raw, formatVersion: 2);
    expect(encodeBorderBlueprintRecordJson(record, formatVersion: 2), raw);
    expect(minimumBorderCatalogFormatVersionForRecord(record), 2);
  });

  test('jump property changes equality and collision freshness inputs', () {
    final ordinary = decodeBorderBlueprintRecordJson(
      _recordJson(),
      formatVersion: 6,
    );
    final variants =
        [
              _withJump(),
              _withJump(jump: {..._jump(), 'side': 'primary'}),
              _withJump(jump: {..._jump(), 'durationMs': 641}),
              _withJump(jump: {..._jump(), 'peakHeightPx': 31}),
            ]
            .map(
              (raw) => decodeBorderBlueprintRecordJson(raw, formatVersion: 6),
            )
            .toList();
    final inputs = [ordinary, ...variants]
        .map(
          (record) => computeBorderNonVisualInputFingerprints(
            _request(record),
          ).blueprint,
        )
        .toSet();
    expect(inputs, hasLength(5));
    expect(variants.every((record) => record != ordinary), isTrue);
  });

  test('publication evidence binds the Border jump settings', () {
    final records = [
      _recordJson(),
      _withJump(),
      _withJump(jump: {..._jump(), 'side': 'primary'}),
      _withJump(jump: {..._jump(), 'durationMs': 641}),
      _withJump(jump: {..._jump(), 'peakHeightPx': 31}),
    ].map((raw) => decodeBorderBlueprintRecordJson(raw, formatVersion: 6));
    final fingerprints = records
        .map(
          (record) => computeBorderPublicationCandidateFingerprint(
            blueprintId: record.id,
            resolverVersion: borderResolverVersion,
            definition: record.latestPublished!.definition,
          ),
        )
        .toSet();
    expect(fingerprints, hasLength(5));
  });
}

Map<String, Object?> _jump() => {
  'side': 'inverted',
  'distanceCells': 2,
  'durationMs': 640,
  'peakHeightPx': 30,
};

Map<String, dynamic> _withJump({Map<String, Object?>? jump}) {
  final raw = _recordJson();
  for (final branch in ['draft', 'latestPublished']) {
    _definition(raw, branch)['jumpBehavior'] = jump ?? _jump();
  }
  return raw;
}

Map<String, dynamic> _definition(Map<String, dynamic> record, String branch) =>
    (record[branch] as Map<String, dynamic>)['definition']
        as Map<String, dynamic>;

Map<String, dynamic> _recordJson() =>
    jsonDecode(
          jsonEncode(
            encodeBorderBlueprintRecordJson(_record(), formatVersion: 2),
          ),
        )
        as Map<String, dynamic>;

BorderBlueprintRecord _record() {
  final metrics = BorderPrimitiveAssetMetrics(
    assetFingerprint: 'asset-ledge',
    pixelSize: const GridSize(width: 32, height: 32),
    opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 32, height: 32),
    defaultAnchorPx: const BorderPixelPos(x: 16, y: 32),
    occupancyMaskRle: encodeBorderRleMask(List.filled(1024, true)),
  );
  final transforms = BorderTransformPolicy(
    allowFlipX: false,
    allowedQuarterTurns: [0],
  );
  final defaults = BorderGenerationParams(
    irregularityPermille: 0,
    detailDensityPermille: 0,
    variationPermille: 0,
    maxOverlapPx: 0,
    gapTolerancePx: 0,
    depthRows: 1,
  );
  return BorderBlueprintRecord(
    id: 'ledge',
    draft: BorderBlueprintDraft(
      baseRevision: 1,
      definition: BorderBlueprintDraftDefinition(
        name: 'Ledge',
        previewSeed: BorderSignedInt64.zero,
        template: BorderBlueprintTemplate.connectedLine,
        defaults: defaults,
        sortOrder: 0,
        primitives: [
          BorderPrimitiveDraft(
            id: 'body',
            sourceElementId: 'ledge-body',
            role: BorderPrimitiveRole.lineStraight,
            weight: 1,
            anchorPx: const BorderPixelPos(x: 16, y: 32),
            transforms: transforms,
            currentMetrics: metrics,
          ),
        ],
      ),
    ),
    latestPublished: BorderBlueprintRevision(
      revision: 1,
      definition: BorderBlueprintPublishedDefinition(
        name: 'Ledge',
        previewSeed: BorderSignedInt64.zero,
        template: BorderBlueprintTemplate.connectedLine,
        defaults: defaults,
        sortOrder: 0,
        primitives: [
          BorderPublishedPrimitive(
            id: 'body',
            sourceElementId: 'ledge-body',
            visualSnapshotId:
                'border-snapshot-sha256:${List.filled(64, 'a').join()}',
            role: BorderPrimitiveRole.lineStraight,
            weight: 1,
            anchorPx: const BorderPixelPos(x: 16, y: 32),
            transforms: transforms,
            publishedMetrics: metrics,
          ),
        ],
      ),
    ),
  );
}

BorderResolutionRequest _request(BorderBlueprintRecord record) =>
    BorderResolutionRequest(
      mapSize: const GridSize(width: 6, height: 6),
      tileSizePx: const GridSize(width: 32, height: 32),
      blueprintId: record.id,
      blueprintRevision: record.latestPublished,
      feature: BorderFeature(
        id: 'ledge-feature',
        name: 'Ledge',
        blueprintId: record.id,
        seed: BorderSignedInt64.zero,
        geometry: BorderStrokeGeometry(
          strokes: [
            BorderStroke(
              id: 'edge',
              closed: false,
              points: const [GridPos(x: 2, y: 2), GridPos(x: 3, y: 2)],
            ),
          ],
        ),
        overrides: const [],
        keepOutRegions: const [],
      ),
      visualSnapshots: const [],
      resolverVersion: borderResolverVersion,
    );

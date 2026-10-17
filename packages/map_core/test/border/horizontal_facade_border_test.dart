import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../fixtures/border/post_and_rail_line_fixture.dart';

BorderBlueprintTemplate get _template => BorderBlueprintTemplate.values
    .singleWhere((template) => template.name == 'horizontalFacade');

void main() {
  test('horizontal facade is a discoverable distinct template', () {
    expect(
      BorderBlueprintTemplate.values.map((value) => value.name),
      contains('horizontalFacade'),
    );
  });

  test('horizontal runs preserve sprite orientation at both endpoints', () {
    final result = resolveBorderFeature(_request());
    expect(result.canApply, isTrue, reason: '${result.diagnostics}');
    expect(result.materialization!.placements.length, 5);
    for (final placement in result.materialization!.placements) {
      expect(placement.transform.quarterTurns, 0);
      expect(placement.transform.flipX, isFalse);
    }
    expect(result.materialization!.placements.map((p) => p.primitiveId), [
      'cap',
      'straight',
      'straight',
      'straight',
      'cap',
    ]);
  });

  test('separate horizontal runs preserve an opening', () {
    final result = resolveBorderFeature(
      _request(
        strokes: [
          _stroke('left', [
            const GridPos(x: 1, y: 3),
            const GridPos(x: 2, y: 3),
          ]),
          _stroke('right', [
            const GridPos(x: 5, y: 3),
            const GridPos(x: 6, y: 3),
          ]),
        ],
      ),
    );
    expect(result.canApply, isTrue, reason: '${result.diagnostics}');
    expect(result.materialization!.placements.map((p) => p.anchorCell.x), [
      1,
      2,
      5,
      6,
    ]);
  });

  for (final entry in <String, List<GridPos>>{
    'vertical': [const GridPos(x: 2, y: 1), const GridPos(x: 2, y: 2)],
    'corner': [
      const GridPos(x: 1, y: 1),
      const GridPos(x: 2, y: 1),
      const GridPos(x: 2, y: 2),
    ],
  }.entries) {
    test('rejects ${entry.key} geometry before materialization', () {
      final result = resolveBorderFeature(
        _request(strokes: [_stroke('invalid', entry.value)]),
      );
      expect(result.canApply, isFalse);
      expect(result.materialization, isNull);
      expect(
        result.diagnostics.map((d) => d.code),
        contains('border.resolution.horizontal_facade_stroke_required'),
      );
    });
  }

  test('oblique points are rejected by the shared stroke contract', () {
    expect(
      () => _stroke('oblique', [
        const GridPos(x: 1, y: 1),
        const GridPos(x: 2, y: 2),
      ]),
      throwsA(isA<ValidationException>()),
    );
  });

  test('facade requires no corner and no inverted gallery', () {
    expect(
      borderTemplateRequiredPrimitiveRoles(template: _template, depthRows: 1),
      {BorderPrimitiveRole.lineCap, BorderPrimitiveRole.lineStraight},
    );
    expect(borderTemplateSupportsLineSide(_template), isFalse);
    expect(borderTemplateRequiresInvertedCanonicalGallery(_template), isFalse);
    expect(borderCanonicalGalleryCasesForTemplate(_template), [
      BorderCanonicalGalleryCase.longEdge,
      BorderCanonicalGalleryCase.endpoint,
      BorderCanonicalGalleryCase.opening,
    ]);
    expect(
      borderCanonicalGalleryCasesForTemplate(
        BorderBlueprintTemplate.connectedLine,
      ),
      containsAll([
        BorderCanonicalGalleryCase.sharpCorner,
        BorderCanonicalGalleryCase.sBend,
      ]),
    );
  });

  test('canonical facade gallery resolves the three supported cases', () {
    final request = _request();
    final gallery = resolveBorderCanonicalGallery(
      blueprintId: request.blueprintId,
      blueprintRevision: request.blueprintRevision!,
      visualSnapshots: request.visualSnapshots,
      tileSizePx: request.tileSizePx,
    );
    expect(
      gallery.allCasesResolved,
      isTrue,
      reason: '${gallery.resolutionDiagnostics.diagnostics}',
    );
    expect(gallery.cases.length, 3);
    for (final item in gallery.cases) {
      expect(item.invertedResolverResult, isNull);
      expect(
        item.publicationSample.coverageChecks.map(
          (c) => c.longestContiguousGapPx,
        ),
        everyElement(0),
      );
    }
  });

  test('facade rejects inverted side and automatic rotation overrides', () {
    for (final request in [
      _withFeature(lineSide: BorderLineSide.inverted),
      _withFeature(parameters: fenceParameters()),
    ]) {
      final result = resolveBorderFeature(request);
      expect(result.canApply, isFalse);
      expect(result.materialization, isNull);
      expect(
        result.diagnostics.map((d) => d.code),
        contains('border.resolution.horizontal_facade_orientation_required'),
      );
    }
  });

  test(
    'facade rejects mirrored overrides even when the source allows them',
    () {
      final base = resolveBorderFeature(_request(permissiveTransforms: true));
      expect(base.canApply, isTrue);
      final slot = base.materialization!.placements.first.slotKey;
      final result = resolveBorderFeature(
        _withFeature(
          overrides: [
            BorderSlotOverride(
              slotKey: slot,
              variationSalt: BorderSignedInt64.zero,
              suppressed: false,
              locked: false,
              transformOverride: BorderSpriteTransform(
                quarterTurns: 0,
                flipX: true,
              ),
            ),
          ],
        ),
      );
      expect(result.canApply, isFalse);
      expect(result.materialization, isNull);
      expect(
        result.diagnostics.map((d) => d.code),
        contains('border.resolution.horizontal_facade_orientation_required'),
      );
    },
  );

  test('facade catalog round trips only with its explicit format version', () {
    final revision = _request().blueprintRevision!;
    final definition = revision.definition;
    final record = BorderBlueprintRecord(
      id: 'facade',
      draft: BorderBlueprintDraft(
        baseRevision: revision.revision,
        definition: BorderBlueprintDraftDefinition(
          name: definition.name,
          previewSeed: definition.previewSeed,
          template: definition.template,
          primitives: [
            for (final p in definition.primitives)
              BorderPrimitiveDraft(
                id: p.id,
                sourceElementId: p.sourceElementId,
                role: p.role,
                weight: p.weight,
                anchorPx: p.anchorPx,
                transforms: p.transforms,
                currentMetrics: p.publishedMetrics,
              ),
          ],
          defaults: definition.defaults,
          sortOrder: definition.sortOrder,
        ),
      ),
      latestPublished: revision,
    );
    expect(minimumBorderCatalogFormatVersionForRecord(record), 11);
    final encoded = encodeBorderBlueprintRecordJson(record, formatVersion: 11);
    expect(decodeBorderBlueprintRecordJson(encoded, formatVersion: 11), record);
    expect(
      () => encodeBorderBlueprintRecordJson(record, formatVersion: 10),
      throwsFormatException,
    );
    expect(
      () => decodeBorderBlueprintRecordJson(encoded, formatVersion: 10),
      throwsFormatException,
    );
  });

  for (final relink in [false, true]) {
    test('facade ${relink ? 'relink' : 'preview apply'} promotes a V1 layer', () {
      final base = _request();
      final bare = BorderFeature(id: base.feature.id, name: base.feature.name,
          blueprintId: relink ? 'legacy' : base.blueprintId,
          seed: base.feature.seed, geometry: base.feature.geometry,
          overrides: const [], keepOutRegions: const []);
      final map = MapData(id: 'facade-map', name: 'Facade', size: base.mapSize,
          layers: [BorderLayer(id: 'border', name: 'Facades',
              content: BorderLayerContent(formatVersion: 1, features: [bare]))]);
      final MapData updated;
      if (relink) {
        final preview = prepareBorderFeatureRelink(map: map, layerId: 'border',
            featureId: bare.id, targetBlueprintId: base.blueprintId,
            targetBlueprintRevision: base.blueprintRevision!,
            visualSnapshots: base.visualSnapshots, tileSizePx: base.tileSizePx,
            resolverVersion: base.resolverVersion);
        expect(preview.canApplyResolvedRelink, isTrue);
        updated = applyBorderFeatureRelinkPreview(map, preview: preview);
      } else {
        final request = BorderResolutionRequest(mapSize: base.mapSize,
            tileSizePx: base.tileSizePx, blueprintId: base.blueprintId,
            blueprintRevision: base.blueprintRevision, feature: bare,
            visualSnapshots: base.visualSnapshots, resolverVersion: base.resolverVersion);
        final result = resolveBorderFeature(request);
        expect(result.canApply, isTrue);
        updated = applyBorderFeaturePreview(map, expectedMapId: map.id,
            layerId: 'border', featureId: bare.id,
            expectedBaseFeatureFingerprint: computeBorderFeatureEditFingerprint(bare),
            proposedRequest: request, proposedResult: result);
      }
      expect(updated.layers.whereType<BorderLayer>().single.content.formatVersion, 2);
      expect(updated.layers.whereType<BorderLayer>().single.content.features.single.materialization,
          isNotNull);
    });
  }
}

BorderStroke _stroke(String id, List<GridPos> points) =>
    BorderStroke(id: id, points: points, closed: false);

BorderResolutionRequest _withFeature({
  BorderLineSide lineSide = BorderLineSide.primary,
  BorderGenerationParams? parameters,
  List<BorderSlotOverride> overrides = const [],
}) {
  final base = _request(permissiveTransforms: true);
  return BorderResolutionRequest(
    mapSize: base.mapSize,
    tileSizePx: base.tileSizePx,
    blueprintId: base.blueprintId,
    blueprintRevision: base.blueprintRevision,
    resolverVersion: base.resolverVersion,
    visualSnapshots: base.visualSnapshots,
    feature: BorderFeature(
      id: base.feature.id,
      name: base.feature.name,
      blueprintId: base.blueprintId,
      seed: base.feature.seed,
      geometry: base.feature.geometry,
      lineSide: lineSide,
      paramsOverride: parameters,
      overrides: overrides,
      keepOutRegions: const [],
    ),
  );
}

BorderResolutionRequest _request({
  List<BorderStroke>? strokes,
  bool permissiveTransforms = false,
}) => PostAndRailLineFixture(
  template: _template,
  strokes: strokes,
  tileSizePx: const GridSize(width: 32, height: 32),
  parameters: BorderGenerationParams(
    irregularityPermille: 0,
    detailDensityPermille: 0,
    variationPermille: 0,
    maxOverlapPx: 0,
    gapTolerancePx: 0,
    depthRows: 1,
    allowAutoRotation: false,
  ),
  primitives: [
    fencePrimitive(
      id: 'cap',
      fingerprintCharacter: 'a',
      role: BorderPrimitiveRole.lineCap,
      width: 32,
      height: 32,
      allowedQuarterTurns: permissiveTransforms ? [0, 1, 2, 3] : [0],
      allowFlipX: permissiveTransforms,
    ),
    fencePrimitive(
      id: 'straight',
      fingerprintCharacter: 'b',
      role: BorderPrimitiveRole.lineStraight,
      width: 32,
      height: 32,
      allowedQuarterTurns: permissiveTransforms ? [0, 1, 2, 3] : [0],
      allowFlipX: permissiveTransforms,
    ),
  ],
).request;

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('V3 appends the stone-chain template and grid-edge alignment', () {
    expect(
      borderBlueprintTemplateV1WireName(
        BorderBlueprintTemplate.stoneChainLine,
      ),
      'stoneChainLine',
    );
    expect(
      borderStrokeAlignmentV1WireName(BorderStrokeAlignment.gridEdges),
      'gridEdges',
    );
    expect(ProjectBorderCatalog.formatVersionV3, 3);
    expect(BorderLayerContent.formatVersionV3, 3);
  });

  test('V4 appends primitive orientation only to the catalog format', () {
    expect(
      borderPrimitiveOrientationV1WireName(
        BorderPrimitiveOrientation.west,
      ),
      'west',
    );
    expect(ProjectBorderCatalog.formatVersionV4, 4);
    expect(
      ProjectBorderCatalog.latestSupportedFormatVersion,
      ProjectBorderCatalog.formatVersionV4,
    );
    expect(BorderLayerContent.latestSupportedFormatVersion, 3);
  });

  test('catalog accepts 1 through 4 and rejects 0 and 5', () {
    for (final version in <int>[1, 2, 3, 4]) {
      expect(
        () => ProjectBorderCatalog(formatVersion: version),
        returnsNormally,
      );
    }
    for (final version in <int>[0, 5]) {
      expect(
        () => ProjectBorderCatalog(formatVersion: version),
        throwsA(isA<ValidationException>()),
      );
    }
  });

  test('layer content remains limited to versions 1 through 3', () {
    for (final version in <int>[1, 2, 3]) {
      expect(
        () => BorderLayerContent(formatVersion: version),
        returnsNormally,
      );
      expect(
        decodeBorderLayerContentJson(<String, Object?>{
          'formatVersion': version,
          'features': <Object?>[],
        }).formatVersion,
        version,
      );
    }
    for (final version in <int>[0, 4]) {
      expect(
        () => BorderLayerContent(formatVersion: version),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeBorderLayerContentJson(<String, Object?>{
          'formatVersion': version,
          'features': <Object?>[],
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            startsWith(r'$.formatVersion:'),
          ),
        ),
      );
    }
  });

  test('cardinal draft or published orientation promotes catalog to V4', () {
    expect(
      minimumBorderCatalogFormatVersionForRecord(_record()),
      ProjectBorderCatalog.formatVersionV1,
    );

    for (final orientation in <BorderPrimitiveOrientation>[
      BorderPrimitiveOrientation.east,
      BorderPrimitiveOrientation.south,
      BorderPrimitiveOrientation.west,
      BorderPrimitiveOrientation.north,
    ]) {
      expect(
        minimumBorderCatalogFormatVersionForRecord(
          _record(draftOrientation: orientation),
        ),
        ProjectBorderCatalog.formatVersionV4,
        reason: 'draft ${orientation.name}',
      );
      expect(
        minimumBorderCatalogFormatVersionForRecord(
          _record(publishedOrientation: orientation),
        ),
        ProjectBorderCatalog.formatVersionV4,
        reason: 'published ${orientation.name}',
      );
    }
  });

  test('grid-edge geometry is V3-only and cell centers keep the V1 shape', () {
    final stroke = BorderStroke(
      id: 'edge',
      points: const <GridPos>[GridPos(x: 0, y: 0), GridPos(x: 1, y: 0)],
      closed: false,
    );
    final gridEdges = BorderStrokeGeometry(
      strokes: <BorderStroke>[stroke],
      alignment: BorderStrokeAlignment.gridEdges,
    );

    for (final version in <int>[1, 2]) {
      expect(
        () => encodeBorderFeatureGeometryJson(
          gridEdges,
          formatVersion: version,
          path: r'$.geometry',
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains(r'$.geometry.alignment'),
          ),
        ),
      );
    }

    final encoded = encodeBorderFeatureGeometryJson(
      gridEdges,
      formatVersion: 3,
    );
    expect(encoded['alignment'], 'gridEdges');
    expect(
      decodeBorderFeatureGeometryJson(encoded, formatVersion: 3),
      gridEdges,
    );

    final legacy = BorderStrokeGeometry(strokes: <BorderStroke>[stroke]);
    expect(
      encodeBorderFeatureGeometryJson(legacy, formatVersion: 3),
      isNot(contains('alignment')),
    );
  });
}

BorderBlueprintRecord _record({
  BorderPrimitiveOrientation draftOrientation =
      BorderPrimitiveOrientation.legacyAxis,
  BorderPrimitiveOrientation publishedOrientation =
      BorderPrimitiveOrientation.legacyAxis,
}) {
  final metrics = BorderPrimitiveAssetMetrics(
    assetFingerprint: 'asset-sha256:format-version',
    pixelSize: const GridSize(width: 1, height: 1),
    opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
    defaultAnchorPx: const BorderPixelPos(x: 0, y: 0),
    occupancyMaskRle: 'border-rle-v1:1:1:1',
  );
  final transforms = BorderTransformPolicy(
    allowFlipX: false,
    allowedQuarterTurns: const <int>[0],
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
    id: 'format-version',
    draft: BorderBlueprintDraft(
      baseRevision: 1,
      definition: BorderBlueprintDraftDefinition(
        name: 'Format version',
        previewSeed: BorderSignedInt64.zero,
        template: BorderBlueprintTemplate.organicEdge,
        primitives: <BorderPrimitiveDraft>[
          BorderPrimitiveDraft(
            id: 'draft',
            sourceElementId: 'element',
            role: BorderPrimitiveRole.structureLarge,
            authoredOrientation: draftOrientation,
            weight: 1,
            anchorPx: const BorderPixelPos(x: 0, y: 0),
            transforms: transforms,
            currentMetrics: metrics,
          ),
        ],
        defaults: defaults,
        sortOrder: 0,
      ),
    ),
    latestPublished: BorderBlueprintRevision(
      revision: 1,
      definition: BorderBlueprintPublishedDefinition(
        name: 'Format version',
        previewSeed: BorderSignedInt64.zero,
        template: BorderBlueprintTemplate.organicEdge,
        primitives: <BorderPublishedPrimitive>[
          BorderPublishedPrimitive(
            id: 'published',
            sourceElementId: 'element',
            visualSnapshotId: 'snapshot',
            role: BorderPrimitiveRole.structureLarge,
            authoredOrientation: publishedOrientation,
            weight: 1,
            anchorPx: const BorderPixelPos(x: 0, y: 0),
            transforms: transforms,
            publishedMetrics: metrics,
          ),
        ],
        defaults: defaults,
        sortOrder: 0,
      ),
    ),
  );
}

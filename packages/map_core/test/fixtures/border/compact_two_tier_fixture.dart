import 'package:map_core/map_core.dart';

import 'two_tier_stone_chain_fixture.dart';

const GridSize compactTwoTierTileSize = GridSize(width: 32, height: 32);

List<BorderPublishedPrimitive> compactTwoTierPublishedPrimitives() =>
    twoTierStoneChainPublishedPrimitives();

List<BorderPublishedPrimitive> compactTwoTierNeckPublishedPrimitives() =>
    List<BorderPublishedPrimitive>.unmodifiable(
      compactTwoTierPublishedPrimitives().map((primitive) {
        final anchor = _compactTwoTierNeckAnchor(primitive);
        final metrics = primitive.publishedMetrics;
        return BorderPublishedPrimitive(
          id: primitive.id,
          sourceElementId: primitive.sourceElementId,
          visualSnapshotId: primitive.visualSnapshotId,
          role: primitive.role,
          authoredOrientation: primitive.authoredOrientation,
          weight: primitive.weight,
          anchorPx: anchor,
          transforms: primitive.transforms,
          publishedMetrics: BorderPrimitiveAssetMetrics(
            assetFingerprint: metrics.assetFingerprint,
            pixelSize: metrics.pixelSize,
            opaqueBounds: metrics.opaqueBounds,
            defaultAnchorPx: anchor,
            occupancyMaskRle: metrics.occupancyMaskRle,
          ),
        );
      }),
    );

List<BorderVisualSnapshot> compactTwoTierSnapshots(
  List<BorderPublishedPrimitive> primitives,
) => List<BorderVisualSnapshot>.unmodifiable(<BorderVisualSnapshot>[
  for (final primitive in primitives)
    BorderVisualSnapshot(
      id: primitive.visualSnapshotId,
      contentFingerprint: primitive.visualSnapshotId.substring(
        'border-snapshot-sha256:'.length,
      ),
      frames: <BorderVisualFrameSnapshot>[
        BorderVisualFrameSnapshot(
          relativeAssetPath: 'assets/borders/snapshots/${primitive.id}.png',
          sourceRectPx: BorderPixelRect(
            x: 0,
            y: 0,
            width: compactTwoTierTileSize.width,
            height: compactTwoTierTileSize.height,
          ),
          durationMs: 100,
        ),
      ],
    ),
]);

BorderBlueprintRevision compactTwoTierRevision(
  List<BorderPublishedPrimitive> primitives,
) => BorderBlueprintRevision(
  revision: 1,
  definition: BorderBlueprintPublishedDefinition(
    name: 'Synthetic compact two-tier border',
    previewSeed: BorderSignedInt64.fromInt(240420260718),
    template: BorderBlueprintTemplate.stoneChainLine,
    primitives: primitives,
    defaults: BorderGenerationParams(
      irregularityPermille: 180,
      detailDensityPermille: 0,
      variationPermille: 1000,
      maxOverlapPx: 8,
      gapTolerancePx: 0,
      depthRows: 2,
      allowAutoRotation: false,
    ),
    sortOrder: 3,
  ),
);

BorderResolutionRequest compactTwoTierRequest({
  required String featureId,
  required BorderStrokeGeometry geometry,
  BorderLineSide lineSide = BorderLineSide.primary,
  GridSize mapSize = const GridSize(width: 16, height: 12),
}) {
  final primitives = compactTwoTierPublishedPrimitives();
  return BorderResolutionRequest(
    mapSize: mapSize,
    tileSizePx: compactTwoTierTileSize,
    blueprintId: 'border-blueprint-4',
    blueprintRevision: compactTwoTierRevision(primitives),
    feature: BorderFeature(
      id: featureId,
      name: featureId,
      blueprintId: 'border-blueprint-4',
      seed: BorderSignedInt64.fromInt(240420260718),
      geometry: geometry,
      lineSide: lineSide,
      overrides: const <BorderSlotOverride>[],
      keepOutRegions: const <BorderKeepOutRegion>[],
    ),
    visualSnapshots: compactTwoTierSnapshots(primitives),
    resolverVersion: borderResolverVersion,
  );
}

BorderResolutionRequest compactTwoTierNeckRequest({
  required String featureId,
  required BorderStrokeGeometry geometry,
  required BorderLineSide lineSide,
  required bool allowAutoRotation,
  int? maxOverlapPx,
  GridSize mapSize = const GridSize(width: 16, height: 12),
}) {
  final primitives = compactTwoTierNeckPublishedPrimitives();
  final revision = compactTwoTierRevision(primitives);
  final defaults = revision.definition.defaults;
  return BorderResolutionRequest(
    mapSize: mapSize,
    tileSizePx: compactTwoTierTileSize,
    blueprintId: 'border-blueprint-4',
    blueprintRevision: revision,
    feature: BorderFeature(
      id: featureId,
      name: featureId,
      blueprintId: 'border-blueprint-4',
      seed: BorderSignedInt64.fromInt(240420260718),
      geometry: geometry,
      lineSide: lineSide,
      paramsOverride: BorderGenerationParams(
        irregularityPermille: defaults.irregularityPermille,
        detailDensityPermille: defaults.detailDensityPermille,
        variationPermille: defaults.variationPermille,
        maxOverlapPx: maxOverlapPx ?? defaults.maxOverlapPx,
        gapTolerancePx: defaults.gapTolerancePx,
        depthRows: defaults.depthRows,
        allowAutoRotation: allowAutoRotation,
      ),
      overrides: const <BorderSlotOverride>[],
      keepOutRegions: const <BorderKeepOutRegion>[],
    ),
    visualSnapshots: compactTwoTierSnapshots(primitives),
    resolverVersion: borderResolverVersion,
  );
}

BorderPixelPos _compactTwoTierNeckAnchor(BorderPublishedPrimitive primitive) {
  if (primitive.role == BorderPrimitiveRole.structureLarge) {
    return switch (primitive.authoredOrientation) {
      BorderPrimitiveOrientation.north => const BorderPixelPos(x: 16, y: 9),
      BorderPrimitiveOrientation.east => const BorderPixelPos(x: 22, y: 16),
      BorderPrimitiveOrientation.south => const BorderPixelPos(x: 16, y: 22),
      BorderPrimitiveOrientation.west => const BorderPixelPos(x: 9, y: 16),
      BorderPrimitiveOrientation.legacyAxis => primitive.anchorPx,
    };
  }
  return switch (primitive.authoredOrientation) {
    BorderPrimitiveOrientation.north => const BorderPixelPos(x: 16, y: 31),
    BorderPrimitiveOrientation.east => const BorderPixelPos(x: 0, y: 16),
    BorderPrimitiveOrientation.south => const BorderPixelPos(x: 16, y: 0),
    BorderPrimitiveOrientation.west => const BorderPixelPos(x: 31, y: 16),
    BorderPrimitiveOrientation.legacyAxis => primitive.anchorPx,
  };
}

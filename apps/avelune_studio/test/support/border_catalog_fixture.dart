import 'package:map_core/map_core.dart';

ProjectBorderCatalog testBorderCatalog({
  BorderBlueprintTemplate template = BorderBlueprintTemplate.connectedLine,
}) {
  final roles = template == BorderBlueprintTemplate.stoneChainLine
      ? [BorderPrimitiveRole.structureLarge]
      : [
          BorderPrimitiveRole.lineCap,
          BorderPrimitiveRole.lineStraight,
          BorderPrimitiveRole.lineCorner,
        ];
  final primitives = <BorderPublishedPrimitive>[
    for (final role in roles)
      BorderPublishedPrimitive(
        id: role.name,
        sourceElementId: 'test-border',
        visualSnapshotId: 'border-snapshot-sha256:${'a' * 64}',
        role: role,
        weight: 1,
        anchorPx: const BorderPixelPos(x: 7, y: 7),
        transforms: BorderTransformPolicy(
          allowedQuarterTurns: const [0, 1, 2, 3],
          allowFlipX: true,
        ),
        publishedMetrics: BorderPrimitiveAssetMetrics(
          assetFingerprint: 'test-border',
          pixelSize: const GridSize(width: 16, height: 16),
          opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 16, height: 16),
          defaultAnchorPx: const BorderPixelPos(x: 7, y: 7),
          occupancyMaskRle: encodeBorderRleMask(List.filled(256, true)),
        ),
      ),
  ];
  final definition = BorderBlueprintPublishedDefinition(
    name: 'Muret de test',
    previewSeed: BorderSignedInt64.zero,
    template: template,
    primitives: primitives,
    defaults: BorderGenerationParams(
      irregularityPermille: 0,
      detailDensityPermille: 0,
      variationPermille: 0,
      maxOverlapPx: 0,
      gapTolerancePx: 0,
      depthRows: 1,
    ),
    sortOrder: 0,
  );
  return ProjectBorderCatalog(
    formatVersion: template == BorderBlueprintTemplate.stoneChainLine
        ? ProjectBorderCatalog.formatVersionV3
        : ProjectBorderCatalog.formatVersionV2,
    records: [
      BorderBlueprintRecord(
        id: 'muret',
        draft: BorderBlueprintDraft(
          baseRevision: 1,
          definition: BorderBlueprintDraftDefinition(
            name: 'Muret de test',
            previewSeed: BorderSignedInt64.zero,
            template: template,
            primitives: const [],
            defaults: definition.defaults,
            sortOrder: 0,
          ),
        ),
        latestPublished: BorderBlueprintRevision(
          revision: 1,
          definition: definition,
        ),
      ),
    ],
    visualSnapshots: [
      BorderVisualSnapshot(
        id: 'border-snapshot-sha256:${'a' * 64}',
        contentFingerprint: 'a' * 64,
        frames: [
          BorderVisualFrameSnapshot(
            relativeAssetPath: 'assets/borders/snapshots/${'a' * 64}.png',
            sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 16, height: 16),
            durationMs: 100,
          ),
        ],
      ),
    ],
  );
}

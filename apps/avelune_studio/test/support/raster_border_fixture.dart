import 'package:map_core/map_core_domain.dart';

ProjectManifest rasterBorderProject(BorderPrimitiveAssetMetrics metrics) =>
    ProjectManifest(
      name: 'Bordure raster',
      maps: const [],
      settings: const ProjectSettings(tileWidth: 32, tileHeight: 32),
      tilesets: const [
        ProjectTilesetEntry(
          id: 'atlas',
          name: 'Planche',
          relativePath: 'tile.png',
        ),
      ],
      elements: const [
        ProjectElementEntry(
          id: 'sprite',
          name: 'Pièce de bordure',
          tilesetId: 'atlas',
          categoryId: 'border',
          frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))],
        ),
      ],
      borderCatalog: ProjectBorderCatalog(
        formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
        records: [
          BorderBlueprintRecord(
            id: 'raster',
            draft: BorderBlueprintDraft(
              baseRevision: 0,
              definition: BorderBlueprintDraftDefinition(
                name: 'Clôture raster',
                template: BorderBlueprintTemplate.connectedLine,
                previewSeed: BorderSignedInt64.zero,
                primitives: [
                  BorderPrimitiveDraft(
                    id: 'straight',
                    sourceElementId: 'sprite',
                    role: BorderPrimitiveRole.lineStraight,
                    weight: 1,
                    anchorPx: metrics.defaultAnchorPx,
                    currentMetrics: metrics,
                    transforms: BorderTransformPolicy(
                      allowFlipX: false,
                      allowedQuarterTurns: const [0],
                    ),
                  ),
                ],
                defaults: BorderGenerationParams(
                  irregularityPermille: 0,
                  detailDensityPermille: 0,
                  variationPermille: 0,
                  maxOverlapPx: 0,
                  gapTolerancePx: 0,
                  depthRows: 1,
                ),
                sortOrder: 0,
              ),
            ),
          ),
        ],
      ),
    );

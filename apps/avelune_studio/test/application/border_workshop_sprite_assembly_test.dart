import 'package:avelune_studio/features/resources/application/border_workshop_assembly.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  test(
    'the 2D sample keeps the published visual snapshots and fresh geometry',
    () {
      final (project, record) = _fixture();
      final preview = buildBorderWorkshopAssembly(
        project,
        record,
        draft: false,
      );
      final map = preview.map!;
      final feature = map.layers
          .whereType<BorderLayer>()
          .single
          .content
          .features
          .single;
      final snapshot = project.borderCatalog.visualSnapshots.single;
      final materialization = feature.materialization!;
      final readiness = assessBorderMaterializationFreshness(
        BorderResolutionRequest(
          mapSize: map.size,
          tileSizePx: const GridSize(width: 16, height: 16),
          blueprintId: record.id,
          blueprintRevision: record.latestPublished,
          feature: feature,
          visualSnapshots: [snapshot],
          resolverVersion: borderResolverVersion,
        ),
        materialization: materialization,
        snapshotIntegrity: {
          snapshot.id: BorderVisualSnapshotIntegrity(
            snapshotId: snapshot.id,
            metadataValid: true,
            filesPresent: true,
            contentFingerprintMatches: true,
          ),
        },
      );
      expect(preview.issue, isNull);
      expect(readiness.state, BorderMaterializationState.fresh);
      expect(materialization.placements, isNotEmpty);
      expect(
        materialization.placements
            .map((piece) => piece.visualSnapshotId)
            .toSet(),
        {snapshot.id},
      );
      expect(
        preview.pieces.fold(0, (total, piece) => total + piece.placements!),
        materialization.placements.length,
      );
      expect(preview.pieces.map((piece) => piece.name).toSet(), {'Planche'});

      final draft = buildBorderWorkshopAssembly(project, record, draft: true);
      expect(draft.issue, BorderWorkshopIssue.spriteDraft);
      expect(draft.map, isNull);
      expect(draft.pieces.map((piece) => piece.name).toSet(), {'Planche'});
    },
  );
}

(ProjectManifest, BorderBlueprintRecord) _fixture() {
  final fingerprint = 'a' * 64;
  final bounds = BorderPixelRect(x: 0, y: 0, width: 16, height: 16);
  final snapshot = BorderVisualSnapshot(
    id: 'border-snapshot-sha256:$fingerprint',
    contentFingerprint: fingerprint,
    frames: [
      BorderVisualFrameSnapshot(
        relativeAssetPath:
            'assets/borders/snapshots/$fingerprint/frame_0000.png',
        sourceRectPx: bounds,
        durationMs: 100,
      ),
    ],
  );
  const anchor = BorderPixelPos(x: 8, y: 8);
  final metrics = BorderPrimitiveAssetMetrics(
    assetFingerprint: 'planche',
    pixelSize: const GridSize(width: 16, height: 16),
    opaqueBounds: bounds,
    defaultAnchorPx: anchor,
    occupancyMaskRle: encodeBorderRleMask(List.filled(16 * 16, true)),
  );
  final defaults = BorderGenerationParams(
    irregularityPermille: 0,
    detailDensityPermille: 0,
    variationPermille: 0,
    maxOverlapPx: 0,
    gapTolerancePx: 0,
    depthRows: 1,
  );
  final transforms = BorderTransformPolicy(
    allowFlipX: true,
    allowedQuarterTurns: [0, 1, 2, 3],
  );
  const roles = [
    BorderPrimitiveRole.lineCap,
    BorderPrimitiveRole.lineStraight,
    BorderPrimitiveRole.lineCorner,
  ];
  final record = BorderBlueprintRecord(
    id: 'garden-fence',
    draft: BorderBlueprintDraft(
      baseRevision: 2,
      definition: BorderBlueprintDraftDefinition(
        name: 'Clôture du jardin',
        previewSeed: BorderSignedInt64.zero,
        template: BorderBlueprintTemplate.connectedLine,
        defaults: defaults,
        sortOrder: 0,
        primitives: [
          for (final role in roles)
            BorderPrimitiveDraft(
              id: role.name,
              sourceElementId: 'plank',
              role: role,
              weight: 1,
              anchorPx: anchor,
              transforms: transforms,
              currentMetrics: metrics,
            ),
        ],
      ),
    ),
    latestPublished: BorderBlueprintRevision(
      revision: 2,
      definition: BorderBlueprintPublishedDefinition(
        name: 'Clôture du jardin',
        previewSeed: BorderSignedInt64.zero,
        template: BorderBlueprintTemplate.connectedLine,
        defaults: defaults,
        sortOrder: 0,
        primitives: [
          for (final role in roles)
            BorderPublishedPrimitive(
              id: role.name,
              sourceElementId: 'plank',
              visualSnapshotId: snapshot.id,
              role: role,
              weight: 1,
              anchorPx: anchor,
              transforms: transforms,
              publishedMetrics: metrics,
            ),
        ],
      ),
    ),
  );
  return (
    ProjectManifest(
      name: 'Recette bordure 2D',
      maps: [],
      tilesets: [],
      elements: const [
        ProjectElementEntry(
          id: 'plank',
          name: 'Planche',
          tilesetId: 'sheet',
          categoryId: 'decor',
          frames: [
            TilesetVisualFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 16, height: 16),
            ),
          ],
        ),
      ],
      borderCatalog: ProjectBorderCatalog(
        formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
        records: [record],
        visualSnapshots: [snapshot],
      ),
    ),
    record,
  );
}

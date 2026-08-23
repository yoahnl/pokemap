import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_studio/application/border_project_element_asset_service.dart';
import 'package:map_editor/src/features/border_studio/application/border_publication_candidate_builder.dart';
import 'package:map_editor/src/features/border_studio/application/border_studio_publication_coordinator.dart';

void main() {
  test(
    'ERW connected-line primitives reject legacy anchors and certify center anchors',
    () async {
      final rootPath = Platform.environment['POKEMAP_ERW_ROOT'];
      if (rootPath == null || rootPath.trim().isEmpty) {
        markTestSkipped('POKEMAP_ERW_ROOT is not configured.');
        return;
      }
      final root = Directory(rootPath);
      final source = File('${root.path}/Props/Static props/fence-straight.png');
      expect(source.existsSync(), isTrue, reason: source.path);
      final baseManifest = _manifest();
      const roles = <(String, String, BorderPrimitiveRole, BorderPixelPos)>[
        (
          'border-primitive-1',
          'element_0_2',
          BorderPrimitiveRole.lineCap,
          BorderPixelPos(x: 22, y: 30),
        ),
        (
          'border-primitive-2',
          'element_1_2',
          BorderPrimitiveRole.lineStraight,
          BorderPixelPos(x: 16, y: 31),
        ),
        (
          'border-primitive-3',
          'element_1_4',
          BorderPrimitiveRole.lineCorner,
          BorderPixelPos(x: 11, y: 31),
        ),
      ];
      const service = BorderProjectElementAssetService();

      Future<List<BorderPrimitiveDraft>> preparePrimitives({
        required bool centered,
      }) async {
        final primitives = <BorderPrimitiveDraft>[];
        for (final (id, sourceElementId, role, legacyAnchor) in roles) {
          primitives.add(
            (await service.prepare(
              manifest: baseManifest,
              projectRootPath: root.path,
              template: BorderBlueprintTemplate.connectedLine,
              sourceElementId: sourceElementId,
              primitiveId: id,
              role: role,
              weight: 1000,
              transforms: BorderTransformPolicy(
                allowFlipX: true,
                allowedQuarterTurns: const <int>[0, 1, 2, 3],
              ),
              anchorPx: centered
                  ? const BorderPixelPos(x: 16, y: 16)
                  : legacyAnchor,
            )).primitive,
          );
        }
        return primitives;
      }

      final disconnected = _record(await preparePrimitives(centered: false));
      final disconnectedPreview = await _coordinator.prepare(
        manifest: _withRecord(baseManifest, disconnected),
        projectRootPath: root.path,
        draftRecord: disconnected,
      );
      expect(disconnectedPreview.canPublish, isFalse);
      expect(
        disconnectedPreview.diagnostics.diagnostics.map(
          (diagnostic) => diagnostic.code,
        ),
        contains('border.publication.connected_line_disconnected'),
      );

      final centered = _record(await preparePrimitives(centered: true));
      final centeredPreview = await _coordinator.prepare(
        manifest: _withRecord(baseManifest, centered),
        projectRootPath: root.path,
        draftRecord: centered,
      );
      expect(
        centeredPreview.canPublish,
        isTrue,
        reason: centeredPreview.diagnostics.diagnostics
            .map((diagnostic) => '${diagnostic.code}:${diagnostic.parameters}')
            .join('\n'),
      );
      expect(centeredPreview.diagnostics.hasErrors, isFalse);
      expect(
        centeredPreview
            .candidate
            .nextManifest
            .borderCatalog
            .records
            .single
            .latestPublished!
            .definition
            .primitives
            .map((primitive) => primitive.anchorPx),
        everyElement(const BorderPixelPos(x: 16, y: 16)),
      );
      final sBend = centeredPreview.canonicalGalleryReport.samples.singleWhere(
        (sample) => sample.galleryCase == BorderCanonicalGalleryCase.sBend,
      );
      expect(
        sBend.coverageChecks.map((check) => check.longestContiguousGapPx),
        everyElement(lessThanOrEqualTo(1)),
      );
      expect(
        sBend.coverageChecks.map((check) => check.maximumPairwiseOverlapPx),
        everyElement(lessThanOrEqualTo(8)),
      );
    },
  );
}

final _coordinator = BorderStudioPublicationCoordinator(
  prepareProjectElementAsset: const BorderProjectElementAssetService().prepare,
  buildCandidate: const BorderPublicationCandidateBuilder().build,
  resolveCanonicalGallery:
      ({
        required blueprintId,
        required blueprintRevision,
        required visualSnapshots,
        required tileSizePx,
        required resolverVersion,
      }) => BorderStudioCanonicalGalleryResolution.fromCore(
        resolveBorderCanonicalGallery(
          blueprintId: blueprintId,
          blueprintRevision: blueprintRevision,
          visualSnapshots: visualSnapshots,
          tileSizePx: tileSizePx,
          resolverVersion: resolverVersion,
        ),
      ),
  publishRequest: (_) async => throw StateError('not used'),
);

ProjectManifest _manifest() => const ProjectManifest(
  name: 'ERW connected-line certification',
  version: ProjectVersion.v7,
  maps: <ProjectMapEntry>[],
  settings: ProjectSettings(tileWidth: 32, tileHeight: 32),
  tilesets: <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'erw-fence',
      name: 'ERW fence-straight',
      relativePath: 'Props/Static props/fence-straight.png',
    ),
  ],
  elements: <ProjectElementEntry>[
    ProjectElementEntry(
      id: 'element_0_2',
      name: 'Cap',
      tilesetId: 'erw-fence',
      categoryId: 'border',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 2)),
      ],
    ),
    ProjectElementEntry(
      id: 'element_1_2',
      name: 'Straight',
      tilesetId: 'erw-fence',
      categoryId: 'border',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 2)),
      ],
    ),
    ProjectElementEntry(
      id: 'element_1_4',
      name: 'Corner',
      tilesetId: 'erw-fence',
      categoryId: 'border',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 4)),
      ],
    ),
  ],
);

BorderBlueprintRecord _record(List<BorderPrimitiveDraft> primitives) =>
    BorderBlueprintRecord(
      id: 'border-blueprint-1',
      draft: BorderBlueprintDraft(
        baseRevision: 0,
        definition: BorderBlueprintDraftDefinition(
          name: 'ERW - Cloture droite',
          previewSeed: BorderSignedInt64.fromInt(23),
          template: BorderBlueprintTemplate.connectedLine,
          primitives: primitives,
          defaults: BorderGenerationParams(
            irregularityPermille: 750,
            detailDensityPermille: 700,
            variationPermille: 700,
            maxOverlapPx: 8,
            gapTolerancePx: 1,
            depthRows: 1,
            allowAutoRotation: true,
          ),
          sortOrder: 0,
        ),
      ),
    );

ProjectManifest _withRecord(
  ProjectManifest manifest,
  BorderBlueprintRecord record,
) => ProjectManifest.fromJson(<String, dynamic>{
  ...manifest.toJson(),
  'borderCatalog': encodeProjectBorderCatalogJson(
    ProjectBorderCatalog(
      formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
      records: <BorderBlueprintRecord>[record],
    ),
  ),
});

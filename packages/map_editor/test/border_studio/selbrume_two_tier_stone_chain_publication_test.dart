import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_studio/application/border_project_element_asset_service.dart';
import 'package:map_editor/src/features/border_studio/application/border_publication_candidate_builder.dart';
import 'package:map_editor/src/features/border_studio/application/border_publication_transaction.dart';
import 'package:map_editor/src/features/border_studio/application/border_studio_publication_coordinator.dart';
import 'package:map_editor/src/features/border_studio/application/ports/border_asset_snapshot_store.dart';
import 'package:path/path.dart' as p;

void main() {
  test('Selbrume two-tier cliff prepares all 24 real directional sprites',
      () async {
    final projectRoot = p.normalize(
      p.join(Directory.current.path, '..', '..', 'selbrume'),
    );
    final projectFile = File(p.join(projectRoot, 'project.json'));
    final projectBytesBefore = await projectFile.readAsBytes();
    final projectJson =
        jsonDecode(utf8.decode(projectBytesBefore)) as Map<String, Object?>;
    final manifest = ProjectManifest.fromJson(projectJson);
    final expectedAssets = _expectedAssets();

    expect(
      manifest.borderCatalog.formatVersion,
      ProjectBorderCatalog.formatVersionV4,
    );
    final historicalRecord2 =
        manifest.borderCatalog.recordById('border-blueprint-2');
    final historicalRecord3 =
        manifest.borderCatalog.recordById('border-blueprint-3');
    expect(historicalRecord2, isNotNull);
    expect(historicalRecord3, isNotNull);
    expect(historicalRecord2!.latestPublished!.revision, 5);
    expect(historicalRecord3!.latestPublished!.revision, 14);

    final tileset = manifest.tilesets.singleWhere(
      (entry) => entry.id == 'ts_selbrume_cliff_two_tier_v2',
    );
    expect(
      tileset.relativePath,
      'assets/tilesets/falaises_selbrume_deux_etages_v2.png',
    );
    final elementsById = <String, ProjectElementEntry>{
      for (final element in manifest.elements) element.id: element,
    };
    for (final expected in expectedAssets) {
      final element = elementsById[expected.elementId];
      expect(element, isNotNull, reason: expected.elementId);
      expect(element!.tilesetId, tileset.id);
      expect(element.presetKind, ElementPresetKind.cliff);
      expect(element.collisionProfile, isNull);
      expect(element.frames, hasLength(1));
      expect(element.frames.single.tilesetId, isEmpty);
      expect(element.frames.single.source.x, expected.atlasX);
      expect(element.frames.single.source.y, expected.atlasY);
      expect(element.frames.single.source.width, 1);
      expect(element.frames.single.source.height, 1);
    }

    final persistedRecord =
        manifest.borderCatalog.recordById('border-blueprint-4');
    expect(persistedRecord, isNotNull);
    final persistedRevision = persistedRecord!.latestPublished?.revision;
    expect(persistedRevision, 4);
    expect(persistedRecord.draft.baseRevision, 4);
    expect(persistedRecord.isDeprecated, isFalse);
    if (persistedRecord.latestPublished case final published?) {
      expect(published.definition.primitives, hasLength(24));
      final publishedSnapshotIds = published.definition.primitives
          .map((primitive) => primitive.visualSnapshotId)
          .toSet();
      expect(publishedSnapshotIds, hasLength(24));
      expect(
        publishedSnapshotIds,
        everyElement(
          isIn(
            manifest.borderCatalog.visualSnapshots
                .map((snapshot) => snapshot.id),
          ),
        ),
      );
    }
    final firstPublication = _firstPublicationFixture(
      manifest,
      persistedRecord,
    );
    final publicationManifest = firstPublication.manifest;
    final record = firstPublication.record;
    final definition = record.draft.definition;
    expect(definition.name, 'Falaises Selbrume — deux étages');
    expect(definition.template, BorderBlueprintTemplate.stoneChainLine);
    expect(definition.defaults, _twoTierDefaults());
    expect(definition.ground, isNull);
    expect(definition.sortOrder, 3);
    expect(definition.primitives, hasLength(24));
    expect(
      definition.primitives.map((primitive) => primitive.id),
      orderedEquals(expectedAssets.map((asset) => asset.primitiveId)),
    );

    final primitivesByElementId = <String, BorderPrimitiveDraft>{
      for (final primitive in definition.primitives)
        primitive.sourceElementId: primitive,
    };
    expect(primitivesByElementId, hasLength(24));
    const cardinalOrientations = <BorderPrimitiveOrientation>{
      BorderPrimitiveOrientation.north,
      BorderPrimitiveOrientation.east,
      BorderPrimitiveOrientation.south,
      BorderPrimitiveOrientation.west,
    };
    for (final role in const <BorderPrimitiveRole>[
      BorderPrimitiveRole.structureLarge,
      BorderPrimitiveRole.structureMedium,
    ]) {
      final rolePrimitives = definition.primitives
          .where((primitive) => primitive.role == role)
          .toList(growable: false);
      expect(rolePrimitives, hasLength(12));
      expect(
        rolePrimitives
            .map((primitive) => primitive.authoredOrientation)
            .toSet(),
        cardinalOrientations,
      );
      for (final orientation in cardinalOrientations) {
        expect(
          rolePrimitives.where(
            (primitive) => primitive.authoredOrientation == orientation,
          ),
          hasLength(3),
        );
      }
    }

    const assetService = BorderProjectElementAssetService();
    for (final expected in expectedAssets) {
      final primitive = primitivesByElementId[expected.elementId];
      expect(primitive, isNotNull, reason: expected.elementId);
      expect(primitive!.role, expected.role);
      expect(primitive.authoredOrientation, expected.orientation);
      expect(primitive.weight, 1000);
      expect(primitive.anchorPx, expected.anchorPx);
      expect(primitive.transforms.allowFlipX, isFalse);
      expect(
        primitive.transforms.allowedQuarterTurns,
        orderedEquals(const <int>[0, 1, 2, 3]),
      );
      final refreshed = await assetService.reanalyze(
        manifest: publicationManifest,
        projectRootPath: projectRoot,
        primitive: primitive,
      );
      expect(
        refreshed.primitive.currentMetrics,
        primitive.currentMetrics,
        reason: '${primitive.id} must persist its current real-source metrics.',
      );
      expect(refreshed.primitive.anchorPx, expected.anchorPx);
    }

    final historicalSnapshotIds = <String>{
      for (final snapshot in publicationManifest.borderCatalog.visualSnapshots)
        snapshot.id,
    };
    BorderPublicationRequest? publicationRequest;
    final coordinator = BorderStudioPublicationCoordinator(
      prepareProjectElementAsset: assetService.prepare,
      buildCandidate: const BorderPublicationCandidateBuilder().build,
      resolveCanonicalGallery: ({
        required blueprintId,
        required blueprintRevision,
        required visualSnapshots,
        required tileSizePx,
        required resolverVersion,
      }) =>
          BorderStudioCanonicalGalleryResolution.fromCore(
        resolveBorderCanonicalGallery(
          blueprintId: blueprintId,
          blueprintRevision: blueprintRevision,
          visualSnapshots: visualSnapshots,
          tileSizePx: tileSizePx,
          resolverVersion: resolverVersion,
        ),
      ),
      publishRequest: (request) async {
        publicationRequest = request;
        return BorderPublicationResult(
          manifest: request.nextManifest,
          diagnostics: const BorderDiagnosticsReport.empty(),
          snapshotFinalize: BorderAssetSnapshotFinalizeResult(
            createdRelativePaths: <String>[
              for (final file in request.files) file.relativePath,
            ],
            deduplicatedRelativePaths: const <String>[],
          ),
        );
      },
    );

    final preview = await coordinator.prepare(
      manifest: publicationManifest,
      projectRootPath: projectRoot,
      draftRecord: record,
    );
    expect(
      preview.diagnostics.diagnostics,
      isEmpty,
      reason: _diagnostics(preview.diagnostics),
    );
    expect(
      preview.canonicalGalleryCases.map((item) => item.galleryCase),
      orderedEquals(const <BorderCanonicalGalleryCase>[
        BorderCanonicalGalleryCase.longEdge,
        BorderCanonicalGalleryCase.sharpCorner,
        BorderCanonicalGalleryCase.endpoint,
        BorderCanonicalGalleryCase.sBend,
        BorderCanonicalGalleryCase.closedLoop,
      ]),
    );
    final canonicalShapes = <String>[];
    for (final galleryCase in preview.canonicalGalleryCases) {
      final geometry = galleryCase.geometry as BorderStrokeGeometry;
      canonicalShapes.addAll(
        geometry.strokes.map(
          (stroke) => '${galleryCase.galleryCase.name}:${stroke.id}',
        ),
      );
      expect(
        galleryCase.resolution.canApply,
        isTrue,
        reason: '${galleryCase.galleryCase.name} primary:\n'
            '${_diagnostics(galleryCase.resolution.diagnosticReport)}',
      );
      expect(galleryCase.invertedResolution, isNotNull);
      expect(
        galleryCase.invertedResolution!.canApply,
        isTrue,
        reason: '${galleryCase.galleryCase.name} inverted:\n'
            '${_diagnostics(galleryCase.invertedResolution!.diagnosticReport)}',
      );
      expect(galleryCase.publicationSample.coverageChecks, hasLength(2));
      expect(
          galleryCase.publicationSample.primaryStoneChainEvidence, isNotNull);
      expect(
        galleryCase.publicationSample.invertedStoneChainEvidence,
        isNotNull,
      );
      for (final evidence in <BorderPublicationStoneChainEvidence>[
        galleryCase.publicationSample.primaryStoneChainEvidence!,
        galleryCase.publicationSample.invertedStoneChainEvidence!,
      ]) {
        expect(
            evidence.minimumCrossRowInterlockPixels, greaterThanOrEqualTo(8));
        expect(evidence.minimumVisibleFaceDepthPx, greaterThanOrEqualTo(12));
        expect(
          evidence.medianVisibleFaceDepthPx,
          inInclusiveRange(22, 27),
        );
        expect(evidence.alignedJointRatioPermille, lessThanOrEqualTo(250));
      }
    }
    expect(
      canonicalShapes,
      orderedEquals(const <String>[
        'longEdge:horizontal',
        'longEdge:vertical',
        'sharpCorner:convexL',
        'sharpCorner:concaveL',
        'endpoint:primary',
        'sBend:primary',
        'closedLoop:primary',
      ]),
    );

    final candidate = preview.candidate;
    final replayFixture = _firstPublicationFixture(
      candidate.nextManifest,
      candidate.nextManifest.borderCatalog.recordById('border-blueprint-4')!,
    );
    expect(replayFixture.manifest, publicationManifest);
    expect(replayFixture.record, record);
    expect(
      candidate.nextManifest.borderCatalog.formatVersion,
      ProjectBorderCatalog.formatVersionV4,
    );
    expect(
      candidate.nextManifest.borderCatalog.recordById('border-blueprint-2'),
      historicalRecord2,
    );
    expect(
      candidate.nextManifest.borderCatalog.recordById('border-blueprint-3'),
      historicalRecord3,
    );
    final newSnapshots = candidate.nextManifest.borderCatalog.visualSnapshots
        .where((snapshot) => !historicalSnapshotIds.contains(snapshot.id))
        .toList(growable: false);
    expect(newSnapshots, hasLength(24));
    expect(
      newSnapshots.map((snapshot) => snapshot.id).toSet(),
      hasLength(24),
    );
    expect(candidate.files, hasLength(24));
    expect(
      candidate.files.map((file) => file.relativePath).toSet(),
      hasLength(24),
    );
    for (final snapshot in newSnapshots) {
      expect(snapshot.frames, hasLength(1));
      expect(snapshot.frames.single.sourceRectPx.width, 32);
      expect(snapshot.frames.single.sourceRectPx.height, 32);
    }
    for (final file in candidate.files) {
      final image = img.decodePng(file.bytes);
      expect(image, isNotNull, reason: file.relativePath);
      expect((image!.width, image.height), (32, 32));
    }

    final publication = await coordinator.publish(
      preview: preview,
      currentManifest: publicationManifest,
      currentDraftRecord: record,
      acknowledgedWarningCodes: const <String>{},
    );
    expect(publicationRequest, isNotNull);
    expect(publication.snapshotFinalize.createdRelativePaths, hasLength(24));
    expect(publication.snapshotFinalize.deduplicatedRelativePaths, isEmpty);
    expect(
      publication.manifest.borderCatalog.recordById('border-blueprint-2'),
      historicalRecord2,
    );
    expect(
      publication.manifest.borderCatalog.recordById('border-blueprint-3'),
      historicalRecord3,
    );
    final published =
        publication.manifest.borderCatalog.recordById('border-blueprint-4')!;
    expect(published.latestPublished!.revision, 1);
    expect(published.draft.baseRevision, 1);
    expect(published.latestPublished!.definition.primitives, hasLength(24));

    expect(await projectFile.readAsBytes(), orderedEquals(projectBytesBefore));
  });
}

final class _FirstPublicationFixture {
  const _FirstPublicationFixture({
    required this.manifest,
    required this.record,
  });

  final ProjectManifest manifest;
  final BorderBlueprintRecord record;
}

_FirstPublicationFixture _firstPublicationFixture(
  ProjectManifest manifest,
  BorderBlueprintRecord persistedRecord,
) {
  final publishedSnapshotIds = <String>{
    for (final primitive
        in persistedRecord.latestPublished?.definition.primitives ??
            const <BorderPublishedPrimitive>[])
      primitive.visualSnapshotId,
  };
  final draftOnlyRecord = BorderBlueprintRecord(
    id: persistedRecord.id,
    draft: BorderBlueprintDraft(
      baseRevision: 0,
      definition: persistedRecord.draft.definition,
    ),
    isDeprecated: persistedRecord.isDeprecated,
  );
  final firstPublicationManifest = replaceProjectBorderCatalog(
    manifest,
    ProjectBorderCatalog(
      formatVersion: manifest.borderCatalog.formatVersion,
      records: <BorderBlueprintRecord>[
        for (final record in manifest.borderCatalog.records)
          if (record.id == draftOnlyRecord.id) draftOnlyRecord else record,
      ],
      visualSnapshots: <BorderVisualSnapshot>[
        for (final snapshot in manifest.borderCatalog.visualSnapshots)
          if (!publishedSnapshotIds.contains(snapshot.id)) snapshot,
      ],
    ),
  );
  return _FirstPublicationFixture(
    manifest: firstPublicationManifest,
    record: draftOnlyRecord,
  );
}

final class _ExpectedAsset {
  const _ExpectedAsset({
    required this.primitiveId,
    required this.elementId,
    required this.role,
    required this.orientation,
    required this.anchorPx,
    required this.atlasX,
    required this.atlasY,
  });

  final String primitiveId;
  final String elementId;
  final BorderPrimitiveRole role;
  final BorderPrimitiveOrientation orientation;
  final BorderPixelPos anchorPx;
  final int atlasX;
  final int atlasY;
}

List<_ExpectedAsset> _expectedAssets() {
  const orientations = <({
    String wire,
    BorderPrimitiveOrientation orientation,
    BorderPixelPos topAnchor,
    BorderPixelPos faceAnchor,
  })>[
    (
      wire: 'n',
      orientation: BorderPrimitiveOrientation.north,
      topAnchor: BorderPixelPos(x: 16, y: 9),
      faceAnchor: BorderPixelPos(x: 16, y: 31),
    ),
    (
      wire: 'e',
      orientation: BorderPrimitiveOrientation.east,
      topAnchor: BorderPixelPos(x: 22, y: 16),
      faceAnchor: BorderPixelPos(x: 0, y: 16),
    ),
    (
      wire: 's',
      orientation: BorderPrimitiveOrientation.south,
      topAnchor: BorderPixelPos(x: 16, y: 22),
      faceAnchor: BorderPixelPos(x: 16, y: 0),
    ),
    (
      wire: 'w',
      orientation: BorderPrimitiveOrientation.west,
      topAnchor: BorderPixelPos(x: 9, y: 16),
      faceAnchor: BorderPixelPos(x: 31, y: 16),
    ),
  ];
  final result = <_ExpectedAsset>[];
  for (final tier in const <String>['top', 'face']) {
    for (final orientation in orientations) {
      for (var variant = 1; variant <= 3; variant += 1) {
        final index = result.length;
        final suffix = variant.toString().padLeft(2, '0');
        result.add(
          _ExpectedAsset(
            primitiveId: 'selbrume-cliff-$tier-${orientation.wire}-$suffix',
            elementId: 'el_selbrume_cliff_${tier}_${orientation.wire}_$suffix',
            role: tier == 'top'
                ? BorderPrimitiveRole.structureLarge
                : BorderPrimitiveRole.structureMedium,
            orientation: orientation.orientation,
            anchorPx:
                tier == 'top' ? orientation.topAnchor : orientation.faceAnchor,
            atlasX: index % 6,
            atlasY: index ~/ 6,
          ),
        );
      }
    }
  }
  return List<_ExpectedAsset>.unmodifiable(result);
}

BorderGenerationParams _twoTierDefaults() => BorderGenerationParams(
      irregularityPermille: 180,
      detailDensityPermille: 0,
      variationPermille: 1000,
      maxOverlapPx: 8,
      gapTolerancePx: 0,
      depthRows: 2,
      allowAutoRotation: false,
    );

String _diagnostics(BorderDiagnosticsReport report) => report.diagnostics
    .map(
      (diagnostic) => '${diagnostic.severity.name}: ${diagnostic.code} '
          '${diagnostic.parameters}',
    )
    .join('\n');

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_studio/application/border_asset_snapshot_service.dart';
import 'package:map_editor/src/features/border_studio/application/border_project_element_asset_service.dart';
import 'package:map_editor/src/features/border_studio/application/border_publication_candidate_builder.dart';
import 'package:map_editor/src/features/border_studio/application/border_publication_transaction.dart';
import 'package:map_editor/src/features/border_studio/application/border_studio_publication_coordinator.dart';
import 'package:map_editor/src/features/border_studio/application/ports/border_asset_snapshot_store.dart';

void main() {
  group('BorderStudioPublicationCoordinator', () {
    test('freshly prepares every weighted primitive before building', () async {
      final target = _record(
        primitives: <BorderPrimitiveDraft>[
          _primitive(id: 'large', sourceElementId: 'element-large'),
          _primitive(
            id: 'disabled',
            sourceElementId: 'element-disabled',
            weight: 0,
          ),
        ],
      );
      final manifest = _manifest(
        record: target,
        elements: <ProjectElementEntry>[
          _element('element-large'),
          _element('element-disabled'),
        ],
      );
      final preparedIds = <String>[];
      Map<String, BorderAssetSnapshotPreparation>? candidatePreparations;
      final coordinator = BorderStudioPublicationCoordinator(
        prepareProjectElementAsset: ({
          required manifest,
          required projectRootPath,
          required sourceElementId,
          required primitiveId,
          required role,
          required weight,
          required transforms,
          anchorPx,
        }) async {
          preparedIds.add(primitiveId);
          return _preparedProjectElement(
            primitive: target.draft.definition.primitives.firstWhere(
              (primitive) => primitive.id == primitiveId,
            ),
          );
        },
        buildCandidate: ({
          required manifest,
          required draftRecord,
          required primitiveSnapshotsByPrimitiveId,
          groundSnapshotsByRole = const {},
        }) {
          candidatePreparations = primitiveSnapshotsByPrimitiveId;
          return const BorderPublicationCandidateBuilder().build(
            manifest: manifest,
            draftRecord: draftRecord,
            primitiveSnapshotsByPrimitiveId: primitiveSnapshotsByPrimitiveId,
            groundSnapshotsByRole: groundSnapshotsByRole,
          );
        },
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
        publishRequest: (_) => throw StateError('must not publish in prepare'),
      );

      final preview = await coordinator.prepare(
        manifest: manifest,
        projectRootPath: '/project',
        draftRecord: target,
      );

      expect(preparedIds, <String>['large']);
      expect(candidatePreparations!.keys, <String>{'large'});
      expect(preview.canonicalGalleryCases, hasLength(6));
      expect(preview.diagnostics.hasErrors, isFalse);
      expect(preview.canPublish, isTrue);
    });

    test('prepares masonry through the same publication flow', () async {
      final target = _record(
        template: BorderBlueprintTemplate.masonryLine,
        primitives: <BorderPrimitiveDraft>[
          _primitive(
            id: 'block',
            sourceElementId: 'element-block',
            allowFlipX: true,
          ),
        ],
      );
      final manifest = _manifest(
        record: target,
        elements: <ProjectElementEntry>[_element('element-block')],
      );
      BorderPublicationRequest? request;
      final coordinator = BorderStudioPublicationCoordinator(
        prepareProjectElementAsset: ({
          required manifest,
          required projectRootPath,
          required sourceElementId,
          required primitiveId,
          required role,
          required weight,
          required transforms,
          anchorPx,
        }) async =>
            _preparedProjectElement(
          primitive: target.draft.definition.primitives.single,
        ),
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
        publishRequest: (value) async {
          request = value;
          return BorderPublicationResult(
            manifest: value.nextManifest,
            diagnostics: const BorderDiagnosticsReport.empty(),
            snapshotFinalize: BorderAssetSnapshotFinalizeResult(
              createdRelativePaths: const <String>[],
              deduplicatedRelativePaths: const <String>[],
            ),
          );
        },
      );

      final preview = await coordinator.prepare(
        manifest: manifest,
        projectRootPath: '/project',
        draftRecord: target,
      );
      expect(
        preview.diagnostics.hasErrors,
        isFalse,
        reason: preview.diagnostics.diagnostics
            .map((diagnostic) => diagnostic.code)
            .join(', '),
      );
      final result = await coordinator.publish(
        preview: preview,
        currentManifest: manifest,
        currentDraftRecord: target,
        acknowledgedWarningCodes: preview.warningCodes,
      );

      expect(preview.canonicalGalleryCases, hasLength(3));
      expect(
        preview.canonicalGalleryCases.first.mapSize,
        const GridSize(width: 12, height: 10),
      );
      expect(
        preview.canonicalGalleryCases.first.geometry,
        isA<BorderStrokeGeometry>(),
      );
      expect(request!.canonicalGalleryReport, preview.canonicalGalleryReport);
      expect(
        result.manifest.borderCatalog.records.single.latestPublished!.definition
            .template,
        BorderBlueprintTemplate.masonryLine,
      );
    });

    test('prepares and publishes a fence from its generic gallery', () async {
      final target = _record(
        template: BorderBlueprintTemplate.postAndRailLine,
        primitives: <BorderPrimitiveDraft>[
          _primitive(
            id: 'post',
            sourceElementId: 'element-post',
            role: BorderPrimitiveRole.post,
          ),
          _primitive(
            id: 'span',
            sourceElementId: 'element-span',
            role: BorderPrimitiveRole.span,
          ),
        ],
      );
      final manifest = _manifest(
        record: target,
        elements: <ProjectElementEntry>[
          _element('element-post'),
          _element('element-span'),
        ],
      );
      BorderPublicationRequest? request;
      final coordinator = BorderStudioPublicationCoordinator(
        prepareProjectElementAsset: ({
          required manifest,
          required projectRootPath,
          required sourceElementId,
          required primitiveId,
          required role,
          required weight,
          required transforms,
          anchorPx,
        }) async =>
            _preparedProjectElement(
          primitive: target.draft.definition.primitives.firstWhere(
            (primitive) => primitive.id == primitiveId,
          ),
        ),
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
        publishRequest: (value) async {
          request = value;
          return BorderPublicationResult(
            manifest: value.nextManifest,
            diagnostics: const BorderDiagnosticsReport.empty(),
            snapshotFinalize: BorderAssetSnapshotFinalizeResult(
              createdRelativePaths: const <String>[],
              deduplicatedRelativePaths: const <String>[],
            ),
          );
        },
      );

      final preview = await coordinator.prepare(
        manifest: manifest,
        projectRootPath: '/project',
        draftRecord: target,
      );
      final result = await coordinator.publish(
        preview: preview,
        currentManifest: manifest,
        currentDraftRecord: target,
        acknowledgedWarningCodes: preview.warningCodes,
      );

      expect(preview.canonicalGalleryCases, hasLength(4));
      expect(
        preview.canonicalGalleryCases.last.galleryCase,
        BorderCanonicalGalleryCase.opening,
      );
      expect(request!.canonicalGalleryReport, preview.canonicalGalleryReport);
      expect(
        result.manifest.borderCatalog.records.single.latestPublished!.definition
            .template,
        BorderBlueprintTemplate.postAndRailLine,
      );
    });

    test('projects both connected-line sides and both corner turn senses',
        () async {
      final target = _record(
        template: BorderBlueprintTemplate.connectedLine,
        primitives: <BorderPrimitiveDraft>[
          _primitive(
            id: 'cap',
            sourceElementId: 'element-cap',
            role: BorderPrimitiveRole.lineCap,
            allowFlipX: true,
          ),
          _primitive(
            id: 'straight',
            sourceElementId: 'element-straight',
            role: BorderPrimitiveRole.lineStraight,
            allowFlipX: true,
          ),
          _primitive(
            id: 'corner',
            sourceElementId: 'element-corner',
            role: BorderPrimitiveRole.lineCorner,
            allowFlipX: true,
          ),
        ],
      );
      final manifest = _manifest(
        record: target,
        elements: <ProjectElementEntry>[
          _element('element-cap'),
          _element('element-straight'),
          _element('element-corner'),
        ],
      );
      final coordinator = BorderStudioPublicationCoordinator(
        prepareProjectElementAsset: ({
          required manifest,
          required projectRootPath,
          required sourceElementId,
          required primitiveId,
          required role,
          required weight,
          required transforms,
          anchorPx,
        }) async =>
            _preparedProjectElement(
          primitive: target.draft.definition.primitives.firstWhere(
            (primitive) => primitive.id == primitiveId,
          ),
        ),
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
        publishRequest: (_) => throw StateError('must not publish in prepare'),
      );

      final preview = await coordinator.prepare(
        manifest: manifest,
        projectRootPath: '/project',
        draftRecord: target,
      );

      expect(preview.canonicalGalleryCases, hasLength(5));
      for (final galleryCase in preview.canonicalGalleryCases) {
        expect(galleryCase.resolution.canApply, isTrue);
        expect(galleryCase.invertedResolution?.canApply, isTrue);
        expect(
          galleryCase.resolution.materialization!.placements
              .map((placement) => placement.transform.flipX),
          everyElement(isFalse),
        );
        expect(
          galleryCase.invertedResolution!.materialization!.placements
              .map((placement) => placement.transform.flipX),
          everyElement(isTrue),
        );
      }
      final corner = preview.canonicalGalleryCases.singleWhere(
        (galleryCase) =>
            galleryCase.galleryCase == BorderCanonicalGalleryCase.sharpCorner,
      );
      expect(
        (corner.geometry as BorderStrokeGeometry)
            .strokes
            .map((stroke) => stroke.id),
        orderedEquals(<String>['leftTurn', 'rightTurn']),
      );
    });

    test('forwards every injected ground snapshot role to the candidate',
        () async {
      final target = _record(
        ground: BorderGroundDraft(
          sourceSmartTilePresetId: 'shore',
          edgeBandCells: 1,
        ),
      );
      final manifest = _manifest(
        record: target,
        smartTilePreset: _smartTilePreset('shore'),
      );
      final ground = <BorderGroundVariantRole, BorderAssetSnapshotPreparation>{
        for (final role in standardBorderGroundVariantRoleOrder)
          role: _preparation(
            digit: 'b',
            sourceElementId: 'shore',
            assetFingerprint: 'surface-${role.name}',
          ),
      };
      Map<BorderGroundVariantRole, BorderAssetSnapshotPreparation>? forwarded;
      final coordinator = BorderStudioPublicationCoordinator(
        prepareProjectElementAsset: _unexpectedPreparation,
        buildCandidate: ({
          required manifest,
          required draftRecord,
          required primitiveSnapshotsByPrimitiveId,
          groundSnapshotsByRole = const {},
        }) {
          forwarded = groundSnapshotsByRole;
          return const BorderPublicationCandidateBuilder().build(
            manifest: manifest,
            draftRecord: draftRecord,
            primitiveSnapshotsByPrimitiveId: primitiveSnapshotsByPrimitiveId,
            groundSnapshotsByRole: groundSnapshotsByRole,
          );
        },
        resolveCanonicalGallery: _resolvePassingGallery,
        publishRequest: (_) => throw StateError('must not publish in prepare'),
      );

      await coordinator.prepare(
        manifest: manifest,
        projectRootPath: '/project',
        draftRecord: target,
        groundSnapshotsByRole: ground,
      );

      expect(forwarded, ground);
      expect(forwarded!.keys, standardBorderGroundVariantRoleOrder);
    });

    test('rejects every current-source fingerprint divergence before build',
        () async {
      final target = _record(
        primitives: <BorderPrimitiveDraft>[
          _primitive(id: 'one', sourceElementId: 'element-one'),
          _primitive(id: 'two', sourceElementId: 'element-two'),
        ],
      );
      final manifest = _manifest(
        record: target,
        elements: <ProjectElementEntry>[
          _element('element-one'),
          _element('element-two'),
        ],
      );
      var buildCount = 0;
      final coordinator = BorderStudioPublicationCoordinator(
        prepareProjectElementAsset: ({
          required manifest,
          required projectRootPath,
          required sourceElementId,
          required primitiveId,
          required role,
          required weight,
          required transforms,
          anchorPx,
        }) async {
          final primitive = target.draft.definition.primitives.firstWhere(
            (candidate) => candidate.id == primitiveId,
          );
          return _preparedProjectElement(
            primitive: primitive,
            assetFingerprint: primitiveId == 'two'
                ? 'changed-on-disk'
                : primitive.currentMetrics.assetFingerprint,
          );
        },
        buildCandidate: ({
          required manifest,
          required draftRecord,
          required primitiveSnapshotsByPrimitiveId,
          groundSnapshotsByRole = const {},
        }) {
          buildCount += 1;
          throw StateError('must reject before candidate build');
        },
        resolveCanonicalGallery: _resolvePassingGallery,
        publishRequest: (_) => throw StateError('must not publish'),
      );

      await expectLater(
        coordinator.prepare(
          manifest: manifest,
          projectRootPath: '/project',
          draftRecord: target,
        ),
        throwsA(
          isA<BorderStudioPublicationCoordinatorException>()
              .having(
            (error) => error.code,
            'code',
            BorderStudioPublicationCoordinatorErrorCode.sourceAssetDiverged,
          )
              .having(
            (error) => error.primitiveIds,
            'primitiveIds',
            <String>['two'],
          ).having(
            (error) => error.diagnostics.hasErrors,
            'hasErrors',
            isTrue,
          ),
        ),
      );
      expect(buildCount, 0);
    });

    test('rejects changed current metrics even when the fingerprint matches',
        () async {
      final target = _record(
        primitives: <BorderPrimitiveDraft>[
          _primitive(id: 'large', sourceElementId: 'element-large'),
        ],
      );
      final primitive = target.draft.definition.primitives.single;
      final manifest = _manifest(
        record: target,
        elements: <ProjectElementEntry>[_element('element-large')],
      );
      var buildCount = 0;
      final changedMetrics = BorderPrimitiveAssetMetrics(
        assetFingerprint: primitive.currentMetrics.assetFingerprint,
        pixelSize: primitive.currentMetrics.pixelSize,
        opaqueBounds: primitive.currentMetrics.opaqueBounds,
        defaultAnchorPx: const BorderPixelPos(x: 0, y: 0),
        occupancyMaskRle: primitive.currentMetrics.occupancyMaskRle,
      );
      final coordinator = BorderStudioPublicationCoordinator(
        prepareProjectElementAsset: ({
          required manifest,
          required projectRootPath,
          required sourceElementId,
          required primitiveId,
          required role,
          required weight,
          required transforms,
          anchorPx,
        }) async =>
            _preparedProjectElement(
          primitive: primitive,
          metrics: changedMetrics,
        ),
        buildCandidate: ({
          required manifest,
          required draftRecord,
          required primitiveSnapshotsByPrimitiveId,
          groundSnapshotsByRole = const {},
        }) {
          buildCount += 1;
          throw StateError('must reject before candidate build');
        },
        resolveCanonicalGallery: _resolvePassingGallery,
        publishRequest: (_) => throw StateError('must not publish'),
      );

      await expectLater(
        coordinator.prepare(
          manifest: manifest,
          projectRootPath: '/project',
          draftRecord: target,
        ),
        throwsA(
          isA<BorderStudioPublicationCoordinatorException>().having(
            (error) => error.code,
            'code',
            BorderStudioPublicationCoordinatorErrorCode.sourceAssetDiverged,
          ),
        ),
      );
      expect(buildCount, 0);
    });

    test('publishes the exact prepared session after warning acceptance',
        () async {
      final target = _record(
        primitives: <BorderPrimitiveDraft>[
          _primitive(id: 'large', sourceElementId: 'element-large'),
        ],
      );
      final manifest = _manifest(
        record: target,
        elements: <ProjectElementEntry>[_element('element-large')],
      );
      BorderPublicationRequest? publishedRequest;
      var publishCount = 0;
      final coordinator = BorderStudioPublicationCoordinator(
        prepareProjectElementAsset: ({
          required manifest,
          required projectRootPath,
          required sourceElementId,
          required primitiveId,
          required role,
          required weight,
          required transforms,
          anchorPx,
        }) async =>
            _preparedProjectElement(
          primitive: target.draft.definition.primitives.single,
        ),
        buildCandidate: const BorderPublicationCandidateBuilder().build,
        resolveCanonicalGallery: ({
          required blueprintId,
          required blueprintRevision,
          required visualSnapshots,
          required tileSizePx,
          required resolverVersion,
        }) {
          final passing = _resolvePassingGallery(
            blueprintId: blueprintId,
            blueprintRevision: blueprintRevision,
            visualSnapshots: visualSnapshots,
            tileSizePx: tileSizePx,
            resolverVersion: resolverVersion,
          );
          return BorderStudioCanonicalGalleryResolution(
            report: passing.report,
            cases: passing.cases,
            resolutionDiagnostics: BorderDiagnosticsReport(
              diagnostics: <BorderDiagnostic>[
                _warning(blueprintId),
              ],
            ),
          );
        },
        publishRequest: (request) async {
          publishCount += 1;
          publishedRequest = request;
          return BorderPublicationResult(
            manifest: request.nextManifest,
            diagnostics: const BorderDiagnosticsReport.empty(),
            snapshotFinalize: BorderAssetSnapshotFinalizeResult(
              createdRelativePaths: const <String>[],
              deduplicatedRelativePaths: const <String>[],
            ),
          );
        },
      );
      final preview = await coordinator.prepare(
        manifest: manifest,
        projectRootPath: '/project',
        draftRecord: target,
      );

      expect(preview.warningCodes, <String>{'border.gallery.review'});
      expect(preview.canPublish, isTrue);
      await expectLater(
        coordinator.publish(
          preview: preview,
          currentManifest: manifest,
          currentDraftRecord: target,
          acknowledgedWarningCodes: const <String>{},
        ),
        throwsA(
          isA<BorderStudioPublicationCoordinatorException>().having(
            (error) => error.code,
            'code',
            BorderStudioPublicationCoordinatorErrorCode.warningsNotAcknowledged,
          ),
        ),
      );
      expect(publishCount, 0);

      final result = await coordinator.publish(
        preview: preview,
        currentManifest: manifest,
        currentDraftRecord: target,
        acknowledgedWarningCodes: const <String>{'border.gallery.review'},
      );

      expect(publishCount, 1);
      expect(publishedRequest!.previousManifest, same(manifest));
      expect(
        publishedRequest!.nextManifest,
        same(preview.candidate.nextManifest),
      );
      expect(
        publishedRequest!.canonicalGalleryReport,
        same(preview.canonicalGalleryReport),
      );
      expect(publishedRequest!.files, preview.candidate.files);
      expect(
        publishedRequest!.acceptedWarningCodes,
        <String>{'border.gallery.review'},
      );
      expect(result.manifest, same(preview.candidate.nextManifest));
    });

    test('rejects a stale prepared session without invoking publication',
        () async {
      final target = _record(
        primitives: <BorderPrimitiveDraft>[
          _primitive(id: 'large', sourceElementId: 'element-large'),
        ],
      );
      final manifest = _manifest(
        record: target,
        elements: <ProjectElementEntry>[_element('element-large')],
      );
      var publishCount = 0;
      final coordinator = BorderStudioPublicationCoordinator(
        prepareProjectElementAsset: ({
          required manifest,
          required projectRootPath,
          required sourceElementId,
          required primitiveId,
          required role,
          required weight,
          required transforms,
          anchorPx,
        }) async =>
            _preparedProjectElement(
          primitive: target.draft.definition.primitives.single,
        ),
        buildCandidate: const BorderPublicationCandidateBuilder().build,
        resolveCanonicalGallery: _resolvePassingGallery,
        publishRequest: (_) async {
          publishCount += 1;
          throw StateError('must not publish stale preview');
        },
      );
      final preview = await coordinator.prepare(
        manifest: manifest,
        projectRootPath: '/project',
        draftRecord: target,
      );
      final changed = _record(
        previewSeed: BorderSignedInt64.fromInt(99),
        primitives: target.draft.definition.primitives,
      );

      await expectLater(
        coordinator.publish(
          preview: preview,
          currentManifest: manifest,
          currentDraftRecord: changed,
          acknowledgedWarningCodes: const <String>{},
        ),
        throwsA(
          isA<BorderStudioPublicationCoordinatorException>().having(
            (error) => error.code,
            'code',
            BorderStudioPublicationCoordinatorErrorCode.stalePreview,
          ),
        ),
      );
      expect(publishCount, 0);
    });
  });
}

Future<BorderPreparedProjectElementAsset> _unexpectedPreparation({
  required ProjectManifest manifest,
  required String projectRootPath,
  required String sourceElementId,
  required String primitiveId,
  required BorderPrimitiveRole role,
  required int weight,
  required BorderTransformPolicy transforms,
  BorderPixelPos? anchorPx,
}) =>
    throw StateError('no primitive should be prepared');

BorderStudioCanonicalGalleryResolution _resolvePassingGallery({
  required String blueprintId,
  required BorderBlueprintRevision blueprintRevision,
  required Iterable<BorderVisualSnapshot> visualSnapshots,
  required GridSize tileSizePx,
  required int resolverVersion,
}) {
  final definition = blueprintRevision.definition;
  final report = BorderPublicationGalleryReport(
    resolverVersion: resolverVersion,
    canonicalGalleryVersion: borderCanonicalGalleryVersion,
    candidateFingerprint: computeBorderPublicationCandidateFingerprint(
      blueprintId: blueprintId,
      definition: definition,
      resolverVersion: resolverVersion,
    ),
    samples: <BorderPublicationGallerySample>[
      for (final galleryCase
          in borderCanonicalGalleryCasesForTemplate(definition.template))
        BorderPublicationGallerySample(
          galleryCase: galleryCase,
          coverageChecks: <BorderPublicationCoverageCheck>[
            for (final component in borderCanonicalCoverageComponentsForCase(
              template: definition.template,
              galleryCase: galleryCase,
            ))
              BorderPublicationCoverageCheck(
                component: component,
                longestContiguousGapPx: 0,
                maximumPairwiseOverlapPx: 0,
                gapTolerancePx: definition.defaults.gapTolerancePx,
                maxOverlapPx: definition.defaults.maxOverlapPx,
              ),
          ],
          structuralRuns: const <BorderPublicationStructuralRun>[],
        ),
    ],
  );
  return BorderStudioCanonicalGalleryResolution(
    report: report,
    cases: <BorderStudioCanonicalGalleryCasePreview>[
      for (var index = 0; index < report.samples.length; index += 1)
        BorderStudioCanonicalGalleryCasePreview(
          galleryCase: report.samples[index].galleryCase,
          mapSize: const GridSize(width: 1, height: 1),
          geometry: BorderRegionGeometry(
            width: 1,
            height: 1,
            cells: const <bool>[true],
          ),
          resolution: _successfulResolution(
            snapshotId: definition.primitives.isEmpty
                ? 'border-snapshot-sha256:${'f' * 64}'
                : definition.primitives.first.visualSnapshotId,
            primitiveId: definition.primitives.isEmpty
                ? 'ground-only'
                : definition.primitives.first.id,
            revision: blueprintRevision.revision,
          ),
          publicationSample: report.samples[index],
        ),
    ],
    resolutionDiagnostics: const BorderDiagnosticsReport.empty(),
  );
}

BorderResolutionResult _successfulResolution({
  required String snapshotId,
  required String primitiveId,
  required int revision,
}) {
  const fingerprint =
      'sha256:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';
  final components = BorderInputFingerprints(
    blueprint: fingerprint,
    geometryAndSeed: fingerprint,
    parameters: fingerprint,
    overrides: fingerprint,
    keepOutRegions: fingerprint,
    mapContext: fingerprint,
    visualSnapshots: fingerprint,
  );
  final placement = BorderResolvedPlacement(
    id: 'placement',
    slotKey: 'slot',
    primitiveId: primitiveId,
    visualSnapshotId: snapshotId,
    anchorCell: const GridPos(x: 0, y: 0),
    topLeftWorldPx: const BorderPixelPos(x: 0, y: 0),
    opaqueWorldBoundsPx: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
    transform: BorderSpriteTransform(quarterTurns: 0, flipX: false),
    drawBand: BorderDrawBand.structure,
    stableOrderKey: BorderStableOrderKey(
      drawBandIndex: borderDrawBandV1Index(BorderDrawBand.structure),
      anchorRowMajor: 0,
      passIndex: 0,
      rank: 0,
      ordinalLocal: 0,
      slotKey: 'slot',
    ),
  );
  return BorderResolutionResult(
    materialization: BorderMaterialization(
      receipt: BorderResolutionReceipt(
        resolverVersion: 1,
        blueprintRevision: revision,
        components: components,
        inputFingerprint: fingerprint,
        outputFingerprint: fingerprint,
      ),
      ground: const <BorderResolvedGroundCell>[],
      placements: <BorderResolvedPlacement>[placement],
    ),
    diagnosticReport: const BorderDiagnosticsReport.empty(),
  );
}

BorderPreparedProjectElementAsset _preparedProjectElement({
  required BorderPrimitiveDraft primitive,
  String? assetFingerprint,
  BorderPrimitiveAssetMetrics? metrics,
}) {
  final preparation = _preparation(
    digit: primitive.id == 'two' ? 'b' : 'a',
    sourceElementId: primitive.sourceElementId,
    assetFingerprint:
        assetFingerprint ?? primitive.currentMetrics.assetFingerprint,
    metrics: metrics,
  );
  return BorderPreparedProjectElementAsset(
    sourceElement: _element(primitive.sourceElementId),
    primitive: BorderPrimitiveDraft(
      id: primitive.id,
      sourceElementId: primitive.sourceElementId,
      role: primitive.role,
      weight: primitive.weight,
      anchorPx: primitive.anchorPx,
      transforms: primitive.transforms,
      currentMetrics: preparation.metrics,
    ),
    preparation: preparation,
  );
}

ProjectManifest _manifest({
  required BorderBlueprintRecord record,
  List<ProjectElementEntry> elements = const <ProjectElementEntry>[],
  ProjectSmartTilePreset? smartTilePreset,
}) {
  return ProjectManifest(
    name: 'Coordinator project',
    version: ProjectVersion.v6,
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    elements: elements,
    smartTileCatalog: smartTilePreset == null
        ? const ProjectSmartTileCatalog.empty()
        : ProjectSmartTileCatalog(
            materials: const <ProjectSmartTileMaterial>[
              ProjectSmartTileMaterial(
                id: 'ground',
                name: 'Ground',
                connectionGroupId: 'ground',
              ),
            ],
            presets: <ProjectSmartTilePreset>[smartTilePreset],
          ),
    borderCatalog: ProjectBorderCatalog(
      records: <BorderBlueprintRecord>[record],
    ),
  );
}

BorderBlueprintRecord _record({
  BorderBlueprintTemplate template = BorderBlueprintTemplate.organicEdge,
  BorderSignedInt64? previewSeed,
  List<BorderPrimitiveDraft> primitives = const <BorderPrimitiveDraft>[],
  BorderGroundDraft? ground,
}) {
  return BorderBlueprintRecord(
    id: 'coast',
    draft: BorderBlueprintDraft(
      baseRevision: 0,
      definition: BorderBlueprintDraftDefinition(
        name: 'Coast',
        previewSeed: previewSeed ?? BorderSignedInt64.fromInt(7),
        template: template,
        primitives: primitives,
        defaults: _params(),
        ground: ground,
        sortOrder: 0,
      ),
    ),
  );
}

BorderPrimitiveDraft _primitive({
  required String id,
  required String sourceElementId,
  BorderPrimitiveRole role = BorderPrimitiveRole.structureLarge,
  int weight = 100,
  bool allowFlipX = false,
}) {
  return BorderPrimitiveDraft(
    id: id,
    sourceElementId: sourceElementId,
    role: role,
    weight: weight,
    anchorPx: const BorderPixelPos(x: 1, y: 1),
    transforms: BorderTransformPolicy(
      allowFlipX: allowFlipX,
      allowedQuarterTurns: const <int>[0, 1, 2, 3],
    ),
    currentMetrics: _metrics('source-$id'),
  );
}

BorderAssetSnapshotPreparation _preparation({
  required String digit,
  required String sourceElementId,
  required String assetFingerprint,
  BorderPrimitiveAssetMetrics? metrics,
}) {
  final fingerprint = digit * 64;
  final relativePath = 'assets/borders/snapshots/$fingerprint/frame_0000.png';
  return BorderAssetSnapshotPreparation(
    sourceElementId: sourceElementId,
    snapshot: BorderVisualSnapshot(
      id: 'border-snapshot-sha256:$fingerprint',
      contentFingerprint: fingerprint,
      frames: <BorderVisualFrameSnapshot>[
        BorderVisualFrameSnapshot(
          relativeAssetPath: relativePath,
          sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 2, height: 2),
          durationMs: 100,
        ),
      ],
    ),
    metrics: metrics ?? _metrics(assetFingerprint),
    files: <BorderSnapshotFilePayload>[
      BorderSnapshotFilePayload(
        relativePath: relativePath,
        bytes: Uint8List.fromList(<int>[digit.codeUnitAt(0)]),
      ),
    ],
  );
}

BorderPrimitiveAssetMetrics _metrics(String fingerprint) {
  return BorderPrimitiveAssetMetrics(
    assetFingerprint: fingerprint,
    pixelSize: const GridSize(width: 2, height: 2),
    opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 2, height: 2),
    defaultAnchorPx: const BorderPixelPos(x: 1, y: 1),
    occupancyMaskRle: encodeBorderRleMask(const <bool>[true, true, true, true]),
  );
}

ProjectElementEntry _element(String id) {
  return ProjectElementEntry(
    id: id,
    name: id,
    tilesetId: 'tileset',
    categoryId: 'border',
    frames: const <TilesetVisualFrame>[
      TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
    ],
  );
}

ProjectSmartTilePreset _smartTilePreset(String id) {
  return ProjectSmartTilePreset(
    id: id,
    name: id,
    usage: SmartTileUsage.terrain,
    topology: SmartTileTopology.uniform,
    status: SmartTilePresetStatus.published,
    coveragePolicy: SmartTileCoveragePolicy.sparse,
    coverageProfile: const SmartTileCoverageProfile(
      mode: SmartTileCoverageMode.explicit,
    ),
    transformPolicy: const SmartTileTransformPolicy(),
    defaultMaterialId: 'ground',
    allowedMaterialIds: const <String>['ground'],
  );
}

BorderGenerationParams _params() => BorderGenerationParams(
      irregularityPermille: 250,
      detailDensityPermille: 500,
      variationPermille: 300,
      maxOverlapPx: 4,
      gapTolerancePx: 1,
      depthRows: 1,
    );

BorderDiagnostic _warning(String blueprintId) => BorderDiagnostic(
      code: 'border.gallery.review',
      severity: BorderDiagnosticSeverity.warning,
      phase: BorderDiagnosticPhase.publication,
      scope: BorderDiagnosticScope.blueprint,
      blueprintId: blueprintId,
      suggestedAction: 'border.action.review',
    );

import 'dart:collection';

import 'package:map_core/map_core.dart';

import 'border_asset_snapshot_service.dart';
import 'border_project_element_asset_service.dart';
import 'border_publication_candidate_builder.dart';
import 'border_publication_transaction.dart';

const String borderStudioPublicationSourceAssetDivergedDiagnosticCode =
    'border.studio.publication.source_asset_diverged';

enum BorderStudioPublicationCoordinatorErrorCode {
  sourceAssetDiverged,
  validationFailed,
  warningsNotAcknowledged,
  stalePreview,
}

final class BorderStudioPublicationCoordinatorException implements Exception {
  BorderStudioPublicationCoordinatorException({
    required this.code,
    required this.userMessage,
    BorderDiagnosticsReport? diagnostics,
    Iterable<String> primitiveIds = const <String>[],
    Iterable<String> unacknowledgedWarningCodes = const <String>[],
  })  : diagnostics = diagnostics ?? const BorderDiagnosticsReport.empty(),
        primitiveIds = List<String>.unmodifiable(
          primitiveIds.toList(growable: false)..sort(),
        ),
        unacknowledgedWarningCodes = List<String>.unmodifiable(
          unacknowledgedWarningCodes.toList(growable: false)..sort(),
        );

  final BorderStudioPublicationCoordinatorErrorCode code;
  final String userMessage;
  final BorderDiagnosticsReport diagnostics;
  final List<String> primitiveIds;
  final List<String> unacknowledgedWarningCodes;

  @override
  String toString() =>
      'BorderStudioPublicationCoordinatorException.${code.name}: '
      '$userMessage';
}

typedef BorderStudioPrepareProjectElementAsset
    = Future<BorderPreparedProjectElementAsset> Function({
  required ProjectManifest manifest,
  required String projectRootPath,
  required String sourceElementId,
  required String primitiveId,
  required BorderPrimitiveRole role,
  required int weight,
  required BorderTransformPolicy transforms,
  BorderPixelPos? anchorPx,
});

typedef BorderStudioBuildPublicationCandidate = BorderPublicationCandidate
    Function({
  required ProjectManifest manifest,
  required BorderBlueprintRecord draftRecord,
  required Map<String, BorderAssetSnapshotPreparation>
      primitiveSnapshotsByPrimitiveId,
  Map<BorderGroundVariantRole, BorderAssetSnapshotPreparation>
      groundSnapshotsByRole,
});

typedef BorderStudioResolveCanonicalGallery
    = BorderStudioCanonicalGalleryResolution Function({
  required String blueprintId,
  required BorderBlueprintRevision blueprintRevision,
  required Iterable<BorderVisualSnapshot> visualSnapshots,
  required GridSize tileSizePx,
  required int resolverVersion,
});

typedef BorderStudioPublishRequest = Future<BorderPublicationResult> Function(
  BorderPublicationRequest request,
);

/// Editor-facing projection of the pure-core canonical gallery result.
///
/// Keeping the three payloads explicit lets the workspace render real cases,
/// show resolver diagnostics, and pass the exact publication report without
/// retaining an opaque orchestration object.
final class BorderStudioCanonicalGalleryResolution {
  BorderStudioCanonicalGalleryResolution({
    required this.report,
    required Iterable<BorderStudioCanonicalGalleryCasePreview> cases,
    required this.resolutionDiagnostics,
  }) : cases =
            List<BorderStudioCanonicalGalleryCasePreview>.unmodifiable(cases);

  factory BorderStudioCanonicalGalleryResolution.fromCore(
    BorderCanonicalGalleryResult result,
  ) =>
      BorderStudioCanonicalGalleryResolution(
        report: result.report,
        cases: <BorderStudioCanonicalGalleryCasePreview>[
          for (final item in result.cases)
            BorderStudioCanonicalGalleryCasePreview(
              galleryCase: item.galleryCase,
              mapSize: item.mapSize,
              geometry: item.geometry,
              resolution: item.resolverResult,
              invertedResolution: item.invertedResolverResult,
              publicationSample: item.publicationSample,
            ),
        ],
        resolutionDiagnostics: result.resolutionDiagnostics,
      );

  final BorderPublicationGalleryReport report;
  final List<BorderStudioCanonicalGalleryCasePreview> cases;
  final BorderDiagnosticsReport resolutionDiagnostics;
}

/// Renderable subset of one core canonical case.
final class BorderStudioCanonicalGalleryCasePreview {
  const BorderStudioCanonicalGalleryCasePreview({
    required this.galleryCase,
    required this.mapSize,
    required this.geometry,
    required this.resolution,
    this.invertedResolution,
    required this.publicationSample,
  });

  final BorderCanonicalGalleryCase galleryCase;
  final GridSize mapSize;
  final BorderFeatureGeometry geometry;
  final BorderResolutionResult resolution;

  /// Opposite-side rendering for templates supporting [BorderLineSide].
  final BorderResolutionResult? invertedResolution;
  final BorderPublicationGallerySample publicationSample;
}

/// One immutable preview session. Publication consumes these exact prepared
/// bytes and gallery evidence; it never silently rebuilds them.
final class BorderStudioPublicationPreview {
  BorderStudioPublicationPreview({
    required this.previousManifest,
    required this.draftRecord,
    required this.candidate,
    required this.resolverVersion,
    required this.canonicalGalleryReport,
    required Iterable<BorderStudioCanonicalGalleryCasePreview>
        canonicalGalleryCases,
    required this.resolutionDiagnostics,
    required this.diagnostics,
  }) : canonicalGalleryCases =
            List<BorderStudioCanonicalGalleryCasePreview>.unmodifiable(
          canonicalGalleryCases,
        );

  final ProjectManifest previousManifest;
  final BorderBlueprintRecord draftRecord;
  final BorderPublicationCandidate candidate;
  final int resolverVersion;
  final BorderPublicationGalleryReport canonicalGalleryReport;
  final List<BorderStudioCanonicalGalleryCasePreview> canonicalGalleryCases;
  final BorderDiagnosticsReport resolutionDiagnostics;
  final BorderDiagnosticsReport diagnostics;

  bool get canPublish => !diagnostics.hasErrors;

  Set<String> get warningCodes => UnmodifiableSetView<String>(
        <String>{
          for (final diagnostic in diagnostics.diagnostics)
            if (diagnostic.severity == BorderDiagnosticSeverity.warning)
              diagnostic.code,
        },
      );
}

/// Prepares and publishes one V1 border blueprint revision.
///
/// This application service owns no UI state and performs no runtime solving.
/// It freshly reads every weighted primitive, builds one immutable candidate,
/// resolves the template's real canonical cases, then publishes that exact
/// session.
final class BorderStudioPublicationCoordinator {
  const BorderStudioPublicationCoordinator({
    required BorderStudioPrepareProjectElementAsset prepareProjectElementAsset,
    required BorderStudioBuildPublicationCandidate buildCandidate,
    required BorderStudioResolveCanonicalGallery resolveCanonicalGallery,
    required BorderStudioPublishRequest publishRequest,
    this.resolverVersion = borderResolverVersion,
  })  : _prepareProjectElementAsset = prepareProjectElementAsset,
        _buildCandidate = buildCandidate,
        _resolveCanonicalGallery = resolveCanonicalGallery,
        _publishRequest = publishRequest;

  final BorderStudioPrepareProjectElementAsset _prepareProjectElementAsset;
  final BorderStudioBuildPublicationCandidate _buildCandidate;
  final BorderStudioResolveCanonicalGallery _resolveCanonicalGallery;
  final BorderStudioPublishRequest _publishRequest;
  final int resolverVersion;

  Future<BorderStudioPublicationPreview> prepare({
    required ProjectManifest manifest,
    required String projectRootPath,
    required BorderBlueprintRecord draftRecord,
    Map<BorderGroundVariantRole, BorderAssetSnapshotPreparation> groundSnapshotsByRole =
        const <BorderGroundVariantRole, BorderAssetSnapshotPreparation>{},
  }) async {
    final preparations = <String, BorderAssetSnapshotPreparation>{};
    final divergenceDiagnostics = <BorderDiagnostic>[];
    final weightedPrimitives = draftRecord.draft.definition.primitives
        .where((primitive) => primitive.weight > 0)
        .toList(growable: false);
    for (final primitive in weightedPrimitives) {
      final prepared = await _prepareProjectElementAsset(
        manifest: manifest,
        projectRootPath: projectRootPath,
        sourceElementId: primitive.sourceElementId,
        primitiveId: primitive.id,
        role: primitive.role,
        weight: primitive.weight,
        transforms: primitive.transforms,
        anchorPx: primitive.anchorPx,
      );
      final currentFingerprint = prepared.preparation.metrics.assetFingerprint;
      final authoredFingerprint = primitive.currentMetrics.assetFingerprint;
      final provenanceMatches =
          prepared.preparation.sourceElementId == primitive.sourceElementId &&
              prepared.primitive.id == primitive.id &&
              prepared.primitive.sourceElementId == primitive.sourceElementId;
      final metricsMatch =
          prepared.preparation.metrics == primitive.currentMetrics &&
              prepared.primitive.currentMetrics == prepared.preparation.metrics;
      if (!provenanceMatches ||
          !metricsMatch ||
          currentFingerprint != authoredFingerprint) {
        divergenceDiagnostics.add(
          _diagnostic(
            code: borderStudioPublicationSourceAssetDivergedDiagnosticCode,
            blueprintId: draftRecord.id,
            primitiveId: primitive.id,
            parameters: <String, Object?>{
              'sourceElementId': primitive.sourceElementId,
              'authoredFingerprint': authoredFingerprint,
              'currentFingerprint': currentFingerprint,
              'metricsMatch': metricsMatch,
            },
            suggestedAction: 'border.action.reanalyze_source_asset',
          ),
        );
        continue;
      }
      preparations[primitive.id] = prepared.preparation;
    }
    if (divergenceDiagnostics.isNotEmpty) {
      final diagnostics = BorderDiagnosticsReport(
        diagnostics: divergenceDiagnostics,
      );
      throw BorderStudioPublicationCoordinatorException(
        code: BorderStudioPublicationCoordinatorErrorCode.sourceAssetDiverged,
        userMessage:
            'Un ou plusieurs assets ont changé. Réanalysez-les avant de publier.',
        diagnostics: diagnostics,
        primitiveIds: <String>[
          for (final diagnostic in divergenceDiagnostics)
            diagnostic.parameters['primitiveId']! as String,
        ],
      );
    }

    final candidate = _buildCandidate(
      manifest: manifest,
      draftRecord: draftRecord,
      primitiveSnapshotsByPrimitiveId: preparations,
      groundSnapshotsByRole: groundSnapshotsByRole,
    );
    final publishedRecord =
        candidate.nextManifest.borderCatalog.recordById(draftRecord.id);
    final revision = publishedRecord?.latestPublished;
    if (revision == null) {
      throw StateError('Publication candidate did not create a revision');
    }
    final gallery = _resolveCanonicalGallery(
      blueprintId: draftRecord.id,
      blueprintRevision: revision,
      visualSnapshots: candidate.nextManifest.borderCatalog.visualSnapshots,
      tileSizePx: GridSize(
        width: manifest.settings.tileWidth,
        height: manifest.settings.tileHeight,
      ),
      resolverVersion: resolverVersion,
    );
    final readiness = assessBorderPublicationReadiness(
      blueprintId: draftRecord.id,
      definition: revision.definition,
      resolverVersion: resolverVersion,
      project: candidate.nextManifest,
      visualSnapshots: candidate.nextManifest.borderCatalog.visualSnapshots,
      snapshotIntegrity: candidate.snapshotIntegrity,
      canonicalGalleryReport: gallery.report,
    );
    final diagnostics = BorderDiagnosticsReport(
      diagnostics: <BorderDiagnostic>{
        ...gallery.resolutionDiagnostics.diagnostics,
        ...readiness.diagnosticReport.diagnostics,
      },
    );
    return BorderStudioPublicationPreview(
      previousManifest: manifest,
      draftRecord: draftRecord,
      candidate: candidate,
      resolverVersion: resolverVersion,
      canonicalGalleryReport: gallery.report,
      canonicalGalleryCases: gallery.cases,
      resolutionDiagnostics: gallery.resolutionDiagnostics,
      diagnostics: diagnostics,
    );
  }

  Future<BorderPublicationResult> publish({
    required BorderStudioPublicationPreview preview,
    required ProjectManifest currentManifest,
    required BorderBlueprintRecord currentDraftRecord,
    required Set<String> acknowledgedWarningCodes,
  }) async {
    if (currentManifest != preview.previousManifest ||
        currentDraftRecord != preview.draftRecord) {
      throw BorderStudioPublicationCoordinatorException(
        code: BorderStudioPublicationCoordinatorErrorCode.stalePreview,
        userMessage:
            'Le projet ou le blueprint a changé. Regénérez la galerie avant de publier.',
      );
    }
    if (preview.diagnostics.hasErrors) {
      throw BorderStudioPublicationCoordinatorException(
        code: BorderStudioPublicationCoordinatorErrorCode.validationFailed,
        userMessage:
            'La galerie contient des erreurs bloquantes et ne peut pas être publiée.',
        diagnostics: preview.diagnostics,
      );
    }
    final unacknowledged = preview.warningCodes
        .where((code) => !acknowledgedWarningCodes.contains(code))
        .toList(growable: false)
      ..sort();
    if (unacknowledged.isNotEmpty) {
      throw BorderStudioPublicationCoordinatorException(
        code:
            BorderStudioPublicationCoordinatorErrorCode.warningsNotAcknowledged,
        userMessage:
            'Acceptez explicitement chaque avertissement avant de publier.',
        diagnostics: preview.diagnostics,
        unacknowledgedWarningCodes: unacknowledged,
      );
    }
    return _publishRequest(
      BorderPublicationRequest(
        previousManifest: preview.previousManifest,
        nextManifest: preview.candidate.nextManifest,
        blueprintId: preview.draftRecord.id,
        resolverVersion: preview.resolverVersion,
        snapshotIntegrity: preview.candidate.snapshotIntegrity,
        canonicalGalleryReport: preview.canonicalGalleryReport,
        files: preview.candidate.files,
        acceptedWarningCodes: acknowledgedWarningCodes,
      ),
    );
  }
}

BorderDiagnostic _diagnostic({
  required String code,
  required String blueprintId,
  required String primitiveId,
  required Map<String, Object?> parameters,
  required String suggestedAction,
}) =>
    BorderDiagnostic(
      code: code,
      severity: BorderDiagnosticSeverity.error,
      phase: BorderDiagnosticPhase.publication,
      scope: BorderDiagnosticScope.primitive,
      blueprintId: blueprintId,
      parameters: <String, Object?>{
        'primitiveId': primitiveId,
        ...parameters,
      },
      suggestedAction: suggestedAction,
    );

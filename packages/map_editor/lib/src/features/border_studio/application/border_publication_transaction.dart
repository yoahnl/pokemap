import 'dart:collection';

import 'package:map_core/map_core.dart';

import 'border_asset_snapshot_service.dart';
import 'ports/border_asset_snapshot_store.dart';

enum BorderPublicationTransactionErrorCode {
  validationFailed,
  warningsNotAcknowledged,
  publishedButMemoryRefreshFailed,
}

final class BorderPublicationTransactionException implements Exception {
  BorderPublicationTransactionException({
    required this.code,
    required this.userMessage,
    BorderDiagnosticsReport? diagnostics,
    List<String> unacknowledgedWarningCodes = const <String>[],
    this.manifestCommitted = false,
    this.cause,
  })  : diagnostics = diagnostics ?? const BorderDiagnosticsReport.empty(),
        unacknowledgedWarningCodes = List<String>.unmodifiable(
          unacknowledgedWarningCodes,
        );

  final BorderPublicationTransactionErrorCode code;
  final String userMessage;
  final BorderDiagnosticsReport diagnostics;
  final List<String> unacknowledgedWarningCodes;
  final bool manifestCommitted;
  final Object? cause;

  @override
  String toString() =>
      'BorderPublicationTransactionException.${code.name}: $userMessage';
}

final class BorderPublicationRequest {
  BorderPublicationRequest({
    required this.previousManifest,
    required this.nextManifest,
    required this.blueprintId,
    required this.resolverVersion,
    required Map<String, BorderVisualSnapshotIntegrity> snapshotIntegrity,
    required this.canonicalGalleryReport,
    required List<BorderSnapshotFilePayload> files,
    Set<String> acceptedWarningCodes = const <String>{},
  })  : snapshotIntegrity = UnmodifiableMapView(
          Map<String, BorderVisualSnapshotIntegrity>.from(snapshotIntegrity),
        ),
        files = List<BorderSnapshotFilePayload>.unmodifiable(files),
        acceptedWarningCodes = Set<String>.unmodifiable(
          acceptedWarningCodes,
        ) {
    if (blueprintId.isEmpty || blueprintId != blueprintId.trim()) {
      throw ArgumentError.value(
        blueprintId,
        'blueprintId',
        'must be nonblank and already trimmed',
      );
    }
    if (resolverVersion < 1) {
      throw RangeError.range(resolverVersion, 1, null, 'resolverVersion');
    }
  }

  final ProjectManifest previousManifest;
  final ProjectManifest nextManifest;
  final String blueprintId;
  final int resolverVersion;
  final Map<String, BorderVisualSnapshotIntegrity> snapshotIntegrity;
  final BorderPublicationGalleryReport canonicalGalleryReport;
  final List<BorderSnapshotFilePayload> files;
  final Set<String> acceptedWarningCodes;
}

final class BorderPublicationResult {
  const BorderPublicationResult({
    required this.manifest,
    required this.diagnostics,
    required this.snapshotFinalize,
    this.stagingCleanupPending = false,
  });

  final ProjectManifest manifest;
  final BorderDiagnosticsReport diagnostics;
  final BorderAssetSnapshotFinalizeResult snapshotFinalize;
  final bool stagingCleanupPending;
}

abstract interface class BorderPublicationCandidateValidator {
  BorderDiagnosticsReport validate(BorderPublicationRequest request);
}

/// Disk replacement must be atomic. [applyInMemory] is invoked only after the
/// disk replacement succeeds and must be a synchronous, non-throwing adapter
/// to `EditorNotifier.applyInMemoryProjectManifest`.
abstract interface class BorderPublicationManifestPort {
  Future<void> atomicallyReplace(ProjectManifest manifest);

  void applyInMemory(ProjectManifest manifest);
}

/// Pure-core publication validation plus the temporary BORD-02A template gate.
final class CoreBorderPublicationCandidateValidator
    implements BorderPublicationCandidateValidator {
  const CoreBorderPublicationCandidateValidator({
    this.enabledTemplates = const <BorderBlueprintTemplate>{
      BorderBlueprintTemplate.organicEdge,
    },
  });

  final Set<BorderBlueprintTemplate> enabledTemplates;

  @override
  BorderDiagnosticsReport validate(BorderPublicationRequest request) {
    final transitionDiagnostics = _transitionDiagnostics(request);
    if (transitionDiagnostics.isNotEmpty) {
      return BorderDiagnosticsReport(diagnostics: transitionDiagnostics);
    }

    final record = request.nextManifest.borderCatalog.recordById(
      request.blueprintId,
    )!;
    final revision = record.latestPublished!;
    final readiness = assessBorderPublicationReadiness(
      blueprintId: request.blueprintId,
      definition: revision.definition,
      resolverVersion: request.resolverVersion,
      project: request.nextManifest,
      visualSnapshots: request.nextManifest.borderCatalog.visualSnapshots,
      snapshotIntegrity: request.snapshotIntegrity,
      canonicalGalleryReport: request.canonicalGalleryReport,
    );
    final diagnostics = <BorderDiagnostic>[
      ...readiness.diagnosticReport.diagnostics,
    ];
    if (!enabledTemplates.contains(revision.definition.template)) {
      diagnostics.add(
        _publicationDiagnostic(
          code: 'border.publication.template_not_enabled_in_editor',
          blueprintId: request.blueprintId,
          parameters: <String, Object?>{
            'template': revision.definition.template.name,
          },
          suggestedAction: 'border.action.wait_for_line_solver',
        ),
      );
    }
    return BorderDiagnosticsReport(diagnostics: diagnostics);
  }
}

final class BorderPublicationTransaction {
  const BorderPublicationTransaction({
    required this.snapshotStore,
    required this.manifestPort,
    this.candidateValidator = const CoreBorderPublicationCandidateValidator(),
    this.snapshotService = const BorderAssetSnapshotService(),
  });

  final BorderAssetSnapshotStore snapshotStore;
  final BorderPublicationManifestPort manifestPort;
  final BorderPublicationCandidateValidator candidateValidator;
  final BorderAssetSnapshotService snapshotService;

  Future<BorderPublicationResult> publish(
    BorderPublicationRequest request,
  ) async {
    final stage = await snapshotStore.stage(request.files);
    late BorderDiagnosticsReport diagnostics;
    late BorderAssetSnapshotFinalizeResult finalized;
    try {
      final candidateDiagnostics = candidateValidator.validate(request);
      final payloadDiagnostics = _snapshotPayloadDiagnostics(
        request,
        snapshotService,
      );
      diagnostics = BorderDiagnosticsReport(
        diagnostics: <BorderDiagnostic>[
          ...candidateDiagnostics.diagnostics,
          ...payloadDiagnostics,
        ],
      );
      if (diagnostics.hasErrors) {
        throw BorderPublicationTransactionException(
          code: BorderPublicationTransactionErrorCode.validationFailed,
          userMessage:
              'La révision contient des erreurs bloquantes et n’a pas été publiée.',
          diagnostics: diagnostics,
        );
      }

      final unacknowledged = <String>{
        for (final diagnostic in diagnostics.diagnostics)
          if (diagnostic.severity == BorderDiagnosticSeverity.warning &&
              !request.acceptedWarningCodes.contains(diagnostic.code))
            diagnostic.code,
      }.toList(growable: false)
        ..sort();
      if (unacknowledged.isNotEmpty) {
        throw BorderPublicationTransactionException(
          code: BorderPublicationTransactionErrorCode.warningsNotAcknowledged,
          userMessage:
              'Chaque avertissement doit être accepté explicitement avant publication.',
          diagnostics: diagnostics,
          unacknowledgedWarningCodes: unacknowledged,
        );
      }

      finalized = await snapshotStore.finalize(stage);
      await manifestPort.atomicallyReplace(request.nextManifest);
    } catch (error, stackTrace) {
      try {
        await snapshotStore.discard(stage);
      } catch (_) {
        // Preserve the original pre-commit failure. Cleanup can be retried
        // from the project-local staging directory.
      }
      Error.throwWithStackTrace(error, stackTrace);
    }

    Object? memoryRefreshError;
    StackTrace? memoryRefreshStackTrace;
    try {
      manifestPort.applyInMemory(request.nextManifest);
    } catch (error, stackTrace) {
      memoryRefreshError = error;
      memoryRefreshStackTrace = stackTrace;
    }

    var stagingCleanupPending = false;
    try {
      await snapshotStore.discard(stage);
    } catch (_) {
      stagingCleanupPending = true;
    }

    if (memoryRefreshError != null) {
      final exception = BorderPublicationTransactionException(
        code: BorderPublicationTransactionErrorCode
            .publishedButMemoryRefreshFailed,
        userMessage:
            'La publication est enregistrée sur le disque, mais l’éditeur doit recharger le projet.',
        diagnostics: diagnostics,
        manifestCommitted: true,
        cause: memoryRefreshError,
      );
      Error.throwWithStackTrace(exception, memoryRefreshStackTrace!);
    }

    return BorderPublicationResult(
      manifest: request.nextManifest,
      diagnostics: diagnostics,
      snapshotFinalize: finalized,
      stagingCleanupPending: stagingCleanupPending,
    );
  }
}

List<BorderDiagnostic> _snapshotPayloadDiagnostics(
  BorderPublicationRequest request,
  BorderAssetSnapshotService snapshotService,
) {
  final previousSnapshots =
      request.previousManifest.borderCatalog.visualSnapshots;
  final nextSnapshots = request.nextManifest.borderCatalog.visualSnapshots;
  final appendedSnapshots = nextSnapshots.length < previousSnapshots.length
      ? const <BorderVisualSnapshot>[]
      : nextSnapshots.skip(previousSnapshots.length).toList(growable: false);
  final validation = snapshotService.validatePreparedPayloads(
    snapshots: appendedSnapshots,
    files: request.files,
  );
  return <BorderDiagnostic>[
    for (final issue in validation.issues)
      _publicationDiagnostic(
        code: switch (issue.code) {
          BorderSnapshotPayloadIssueCode.missingFile =>
            'border.publication.snapshot_file_missing',
          BorderSnapshotPayloadIssueCode.unexpectedFile ||
          BorderSnapshotPayloadIssueCode.duplicateFile =>
            'border.publication.snapshot_file_set_invalid',
          BorderSnapshotPayloadIssueCode.metadataMismatch ||
          BorderSnapshotPayloadIssueCode.invalidImage ||
          BorderSnapshotPayloadIssueCode.contentFingerprintMismatch =>
            'border.publication.snapshot_content_mismatch',
        },
        blueprintId: request.blueprintId,
        parameters: <String, Object?>{
          'issue': issue.code.name,
          if (issue.snapshotId != null) 'snapshotId': issue.snapshotId,
          if (issue.relativePath != null) 'relativePath': issue.relativePath,
        },
        suggestedAction: 'border.action.reanalyze_snapshot_assets',
      ),
  ];
}

List<BorderDiagnostic> _transitionDiagnostics(
  BorderPublicationRequest request,
) {
  final diagnostics = <BorderDiagnostic>[];
  try {
    ProjectValidator.validate(request.nextManifest);
  } catch (error) {
    diagnostics.add(
      _publicationDiagnostic(
        code: 'border.publication.project_manifest_invalid',
        blueprintId: request.blueprintId,
        parameters: <String, Object?>{'reason': error.toString()},
        suggestedAction: 'border.action.fix_project_validation',
      ),
    );
    return diagnostics;
  }

  final expectedProject = request.previousManifest.copyWith(
    version: request.nextManifest.version,
    borderCatalog: request.nextManifest.borderCatalog,
  );
  if (expectedProject != request.nextManifest) {
    diagnostics.add(
      _publicationDiagnostic(
        code: 'border.publication.unrelated_manifest_mutation',
        blueprintId: request.blueprintId,
        suggestedAction: 'border.action.retry_from_current_project',
      ),
    );
  }

  final previousRecord = request.previousManifest.borderCatalog.recordById(
    request.blueprintId,
  );
  final nextRecord = request.nextManifest.borderCatalog.recordById(
    request.blueprintId,
  );
  if (previousRecord == null || nextRecord == null) {
    diagnostics.add(
      _publicationDiagnostic(
        code: 'border.publication.blueprint_record_missing',
        blueprintId: request.blueprintId,
        suggestedAction: 'border.action.restore_blueprint_draft',
      ),
    );
    return diagnostics;
  }

  final nextRevision = nextRecord.latestPublished;
  final expectedRevision = (previousRecord.latestPublished?.revision ?? 0) + 1;
  if (nextRevision == null || nextRevision.revision != expectedRevision) {
    diagnostics.add(
      _publicationDiagnostic(
        code: 'border.publication.revision_sequence_invalid',
        blueprintId: request.blueprintId,
        parameters: <String, Object?>{
          'expectedRevision': expectedRevision,
          'actualRevision': nextRevision?.revision,
        },
        suggestedAction: 'border.action.rebuild_publication_candidate',
      ),
    );
  }
  if (nextRecord.draft.baseRevision != expectedRevision) {
    diagnostics.add(
      _publicationDiagnostic(
        code: 'border.publication.draft_base_revision_invalid',
        blueprintId: request.blueprintId,
        parameters: <String, Object?>{
          'expectedRevision': expectedRevision,
          'actualRevision': nextRecord.draft.baseRevision,
        },
        suggestedAction: 'border.action.rebuild_publication_candidate',
      ),
    );
  }
  if (previousRecord.isDeprecated != nextRecord.isDeprecated) {
    diagnostics.add(
      _publicationDiagnostic(
        code: 'border.publication.availability_changed',
        blueprintId: request.blueprintId,
        suggestedAction: 'border.action.use_blueprint_availability_command',
      ),
    );
  }

  final previousOthers = <BorderBlueprintRecord>[
    for (final record in request.previousManifest.borderCatalog.records)
      if (record.id != request.blueprintId) record,
  ];
  final nextOthers = <BorderBlueprintRecord>[
    for (final record in request.nextManifest.borderCatalog.records)
      if (record.id != request.blueprintId) record,
  ];
  if (!_orderedEquals(previousOthers, nextOthers)) {
    diagnostics.add(
      _publicationDiagnostic(
        code: 'border.publication.unrelated_blueprint_mutation',
        blueprintId: request.blueprintId,
        suggestedAction: 'border.action.retry_from_current_project',
      ),
    );
  }

  final previousSnapshots =
      request.previousManifest.borderCatalog.visualSnapshots;
  final nextSnapshots = request.nextManifest.borderCatalog.visualSnapshots;
  if (nextSnapshots.length < previousSnapshots.length ||
      !_orderedEquals(
        previousSnapshots,
        nextSnapshots.take(previousSnapshots.length).toList(growable: false),
      )) {
    diagnostics.add(
      _publicationDiagnostic(
        code: 'border.publication.existing_snapshot_mutated',
        blueprintId: request.blueprintId,
        suggestedAction: 'border.action.restore_immutable_snapshots',
      ),
    );
  }
  return diagnostics;
}

BorderDiagnostic _publicationDiagnostic({
  required String code,
  required String blueprintId,
  Map<String, Object?> parameters = const <String, Object?>{},
  required String suggestedAction,
}) {
  return BorderDiagnostic(
    code: code,
    severity: BorderDiagnosticSeverity.error,
    phase: BorderDiagnosticPhase.publication,
    scope: BorderDiagnosticScope.blueprint,
    blueprintId: blueprintId,
    parameters: parameters,
    suggestedAction: suggestedAction,
  );
}

bool _orderedEquals<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

@immutable
final class NarrativeEventMigrationPreview {
  const NarrativeEventMigrationPreview({
    required this.projectPath,
    required this.projectRevision,
    required this.project,
    required this.plan,
  });

  final String projectPath;
  final String projectRevision;
  final ProjectManifest project;
  final NarrativeEventMigrationPlan plan;

  bool get canCommit => plan.canApply && receipt != null;
  NarrativeEventMigrationReceipt? get receipt => plan.receiptProposal;
  int get legacyItemCount => plan.items.length;
  int get proposedEventCount => plan.recordsProposed.length;
  int get proposedClaimCount => plan.claimsProposed.length;
  int get choiceCount => receipt?.sourceChoices.length ?? 0;
  EventSystemMode get modeBefore =>
      project.eventRegistry?.mode ?? EventSystemMode.legacyOnly;
  EventSystemMode get modeAfter => modeBefore;

  NarrativeEventRegistry get registryAfter {
    if (!canCommit) {
      throw StateError('Only a ready migration preview has a next registry.');
    }
    final before = project.eventRegistry;
    return NarrativeEventRegistry(
      schemaVersion: 1,
      mode: before?.mode ?? EventSystemMode.legacyOnly,
      records: [
        ...?before?.records,
        ...plan.recordsProposed,
      ],
      legacyClaims: [
        ...?before?.legacyClaims,
        ...plan.claimsProposed,
      ],
    );
  }
}

enum NarrativeEventMigrationPersistenceStatus {
  clear,
  committed,
  recovered,
  compensated,
  noOp,
  blocked,
  rejected,
  staleRevision,
  recoveryRequired,
  ioFailure,
}

enum NarrativeEventMigrationInspectionStatus {
  clear,
  recoveryRequired,
  committed,
  blocked,
}

enum NarrativeEventMigrationJournalState {
  prepared,
  committed,
  recovered,
  compensated,
}

enum NarrativeEventMigrationWriteCheckpoint {
  afterBackupWritten,
  afterReceiptWritten,
  afterJournalPrepared,
  afterProjectRenamed,
  afterJournalCommitted,
}

typedef NarrativeEventMigrationFaultInjector = Future<void> Function(
  NarrativeEventMigrationWriteCheckpoint checkpoint,
);

@immutable
final class NarrativeEventMigrationCommitRequest {
  NarrativeEventMigrationCommitRequest({required this.preview}) {
    if (!preview.canCommit) {
      throw ArgumentError.value(preview.plan.status, 'preview');
    }
  }

  final NarrativeEventMigrationPreview preview;
}

/// Explicit transition for a project that has no legacy Event source left.
///
/// This is deliberately separate from migration preview/commit: I4 preserves
/// the runtime mode, while a creator must opt into V2 after reviewing that the
/// project has no legacy ownership to retain.
@immutable
final class NarrativeEventV2ModeActivationRequest {
  NarrativeEventV2ModeActivationRequest({
    required String projectPath,
    required String expectedProjectRevision,
    required this.targetMode,
  })  : projectPath = _requiredIdentity(projectPath, 'projectPath'),
        expectedProjectRevision = _requiredIdentity(
          expectedProjectRevision,
          'expectedProjectRevision',
        ) {
    if (targetMode == EventSystemMode.legacyOnly) {
      throw ArgumentError.value(targetMode, 'targetMode');
    }
  }

  final String projectPath;
  final String expectedProjectRevision;
  final EventSystemMode targetMode;
}

@immutable
final class NarrativeEventMigrationCompensationRequest {
  const NarrativeEventMigrationCompensationRequest({
    required this.projectPath,
    required this.receiptId,
  });

  final String projectPath;
  final String receiptId;
}

@immutable
final class NarrativeEventMigrationPersistenceResult {
  const NarrativeEventMigrationPersistenceResult({
    required this.status,
    required this.code,
    required this.message,
    this.journalPath,
    this.receiptPath,
  });

  final NarrativeEventMigrationPersistenceStatus status;
  final String code;
  final String message;
  final String? journalPath;
  final String? receiptPath;

  bool get succeeded =>
      status == NarrativeEventMigrationPersistenceStatus.committed ||
      status == NarrativeEventMigrationPersistenceStatus.recovered ||
      status == NarrativeEventMigrationPersistenceStatus.compensated ||
      status == NarrativeEventMigrationPersistenceStatus.noOp;
}

@immutable
final class NarrativeEventMigrationInspection {
  const NarrativeEventMigrationInspection({
    required this.status,
    required this.code,
    required this.message,
    this.journalPath,
  });

  final NarrativeEventMigrationInspectionStatus status;
  final String code;
  final String message;
  final String? journalPath;
}

String _requiredIdentity(String value, String field) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(value, field, 'must not be empty');
  }
  return trimmed;
}

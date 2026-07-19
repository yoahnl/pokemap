import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

/// Immutable persistence request for one validated Narrative Studio mutation.
///
/// [before] is the compare-and-swap baseline and [after] is the exact manifest
/// that may be persisted. Both are captured from [mutation] so callers cannot
/// accidentally combine a mutation with unrelated project snapshots.
@immutable
final class NarrativeAuthoringTransaction {
  const NarrativeAuthoringTransaction._({
    required this.projectPath,
    required this.operationId,
    required this.before,
    required this.after,
    required this.mutation,
  });

  factory NarrativeAuthoringTransaction.fromMutation({
    required String projectPath,
    required String operationId,
    required NarrativeAssetMutationResult mutation,
  }) {
    return NarrativeAuthoringTransaction._(
      projectPath: _requiredIdentity(projectPath, 'projectPath'),
      operationId: _requiredIdentity(operationId, 'operationId'),
      before: mutation.before,
      after: mutation.after,
      mutation: mutation,
    );
  }

  final String projectPath;
  final String operationId;
  final ProjectManifest before;
  final ProjectManifest after;
  final NarrativeAssetMutationResult mutation;

  bool get isApplicable => mutation.isApplicable;
}

enum NarrativeAuthoringPersistenceStatus {
  committed,
  persistenceFailed,
  recoveryRequired,
}

/// Infrastructure-neutral outcome returned by the atomic persistence port.
@immutable
final class NarrativeAuthoringPersistenceResult {
  const NarrativeAuthoringPersistenceResult({
    required this.status,
    required this.code,
    required this.message,
  });

  const NarrativeAuthoringPersistenceResult.committed({
    this.code = 'committed',
    this.message = 'The narrative mutation was persisted.',
  }) : status = NarrativeAuthoringPersistenceStatus.committed;

  final NarrativeAuthoringPersistenceStatus status;
  final String code;
  final String message;

  bool get succeeded => status == NarrativeAuthoringPersistenceStatus.committed;
}

enum NarrativeAuthoringTransactionStatus {
  rejected,
  noChange,
  busy,
  committed,
  persistenceFailed,
  recoveryRequired,
}

/// Product-facing outcome of the validate -> persist transaction boundary.
@immutable
final class NarrativeAuthoringTransactionResult {
  const NarrativeAuthoringTransactionResult({
    required this.status,
    required this.code,
    required this.message,
    required this.transaction,
    this.persistenceResult,
    this.persistenceError,
    this.persistenceStackTrace,
  });

  final NarrativeAuthoringTransactionStatus status;
  final String code;
  final String message;
  final NarrativeAuthoringTransaction transaction;
  final NarrativeAuthoringPersistenceResult? persistenceResult;
  final Object? persistenceError;
  final StackTrace? persistenceStackTrace;

  bool get succeeded => status == NarrativeAuthoringTransactionStatus.committed;
}

String _requiredIdentity(String value, String field) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(value, field, 'must not be empty');
  }
  return trimmed;
}

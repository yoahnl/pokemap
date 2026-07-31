import '../contracts/authoring_receipt.dart';
import '../contracts/authoring_request.dart';
import '../contracts/json_contract_support.dart';
import 'change_set.dart';

/// Fully frozen output of one pure planning pass.
final class AuthoringPlan {
  AuthoringPlan({
    required String planId,
    required String receiptId,
    required this.request,
    required String baseRevision,
    required this.seed,
    required DateTime createdAt,
    required DateTime expiresAt,
    required this.changeSet,
    Map<String, Object?> preview = const {},
    Map<String, Object?> referenceImpact = const {},
    Iterable<AuthoringArtifactRef> artifacts = const [],
  })  : planId = _nonBlank(planId, 'planId'),
        receiptId = _nonBlank(receiptId, 'receiptId'),
        baseRevision = _revision(baseRevision, 'baseRevision'),
        createdAt = createdAt.toUtc(),
        expiresAt = expiresAt.toUtc(),
        preview = freezeContractJsonObject(preview, field: 'preview'),
        referenceImpact = freezeContractJsonObject(
          referenceImpact,
          field: 'referenceImpact',
        ),
        artifacts = _sortedArtifacts(artifacts) {
    if (!this.expiresAt.isAfter(this.createdAt)) {
      throw ArgumentError.value(
        expiresAt,
        'expiresAt',
        'must be after createdAt',
      );
    }
    if (seed < 0) {
      throw ArgumentError.value(seed, 'seed', 'must not be negative');
    }
  }

  final String planId;
  final String receiptId;
  final AuthoringRequest request;
  final String baseRevision;
  final int seed;
  final DateTime createdAt;
  final DateTime expiresAt;
  final AuthoringChangeSet changeSet;
  final Map<String, Object?> preview;
  final Map<String, Object?> referenceImpact;
  final List<AuthoringArtifactRef> artifacts;

  String get projectedRevision => changeSet.projectedRevision;

  AuthoringReceipt toPlannedReceipt() {
    return AuthoringReceipt(
      receiptId: receiptId,
      requestId: request.requestId,
      actionId: request.actionId,
      actionVersion: request.actionVersion,
      status: AuthoringReceiptStatus.planned,
      beforeRevision: baseRevision,
      afterRevision: projectedRevision,
      createdAtUtc: createdAt.toIso8601String(),
      diff: changeSet.diff,
      artifacts: artifacts,
      extensions: {
        'planId': planId,
        'seed': seed,
        if (preview.isNotEmpty) 'preview': preview,
        if (referenceImpact.isNotEmpty) 'referenceImpact': referenceImpact,
      },
    );
  }

  Map<String, Object?> toJson() => {
        'planId': planId,
        'receiptId': receiptId,
        'requestId': request.requestId,
        'actionId': request.actionId,
        'actionVersion': request.actionVersion,
        'workspaceHandle': request.workspaceHandle,
        'baseRevision': baseRevision,
        'projectedRevision': projectedRevision,
        'seed': seed,
        'createdAtUtc': createdAt.toIso8601String(),
        'expiresAtUtc': expiresAt.toIso8601String(),
        'changeSet': changeSet.toJson(),
        'preview': preview,
        'referenceImpact': referenceImpact,
        'artifacts': [for (final artifact in artifacts) artifact.toJson()],
      };
}

/// Pure action-specific output before it is assigned an opaque plan identity.
final class AuthoringMutationDraft {
  AuthoringMutationDraft({
    required this.changeSet,
    Map<String, Object?> preview = const {},
    Map<String, Object?> referenceImpact = const {},
    Iterable<AuthoringArtifactRef> artifacts = const [],
  })  : preview = freezeContractJsonObject(preview, field: 'preview'),
        referenceImpact = freezeContractJsonObject(
          referenceImpact,
          field: 'referenceImpact',
        ),
        artifacts = _sortedArtifacts(artifacts);

  final AuthoringChangeSet changeSet;
  final Map<String, Object?> preview;
  final Map<String, Object?> referenceImpact;
  final List<AuthoringArtifactRef> artifacts;
}

List<AuthoringArtifactRef> _sortedArtifacts(
  Iterable<AuthoringArtifactRef> artifacts,
) {
  final byId = <String, AuthoringArtifactRef>{};
  for (final artifact in artifacts) {
    if (byId.containsKey(artifact.id)) {
      throw ArgumentError.value(
        artifact.id,
        'artifacts',
        'artifact identities must be unique',
      );
    }
    byId[artifact.id] = artifact;
  }
  return List.unmodifiable(
    byId.values.toList()..sort((left, right) => left.id.compareTo(right.id)),
  );
}

String _nonBlank(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized != value) {
    throw ArgumentError.value(value, field, 'must be nonblank and trimmed');
  }
  return normalized;
}

String _revision(String value, String field) {
  final normalized = _nonBlank(value, field);
  if (!RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(normalized)) {
    throw ArgumentError.value(
      value,
      field,
      'must be a lowercase SHA-256 fingerprint',
    );
  }
  return normalized;
}

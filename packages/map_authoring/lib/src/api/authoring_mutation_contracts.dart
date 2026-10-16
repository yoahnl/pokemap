import '../contracts/action_descriptor.dart';
import '../contracts/artifact_ref.dart';
import '../contracts/authoring_receipt.dart';
import '../contracts/json_contract_support.dart';
import '../history/authoring_history.dart';
import '../history/history_store.dart';
import '../parity/full_authoring_parity.dart';
import '../transactions/authoring_plan.dart';
import 'authoring_result_projection.dart';

final class AuthoringMutationCommandDescriptor {
  const AuthoringMutationCommandDescriptor({
    required this.id,
    required this.summary,
  });

  final String id;
  final String summary;

  Map<String, Object?> toJson() => {'id': id, 'summary': summary};
}

/// Protocol-neutral mutation catalog for direct Dart consumers.
final class AuthoringMutationDescription {
  AuthoringMutationDescription({
    required Iterable<AuthoringMutationCommandDescriptor> commands,
    required Iterable<AuthoringActionDescriptor> actions,
    required this.fullParity,
  })  : commands = List.unmodifiable(commands),
        actions = List.unmodifiable(actions);

  static const schemaVersion = 1;
  static const protocol = 'pokemap.authoring.mutation.v1';

  final List<AuthoringMutationCommandDescriptor> commands;
  final List<AuthoringActionDescriptor> actions;
  final AuthoringFullParityCatalog fullParity;

  bool get readOnly => false;
  String get multiFileGuarantee => 'recoverable';

  Map<String, Object?> toJson() => freezeContractJsonObject(
        {
          'schemaVersion': schemaVersion,
          'protocol': protocol,
          'readOnly': readOnly,
          'commands': [for (final command in commands) command.toJson()],
          'actions': [for (final action in actions) action.toJson()],
          'multiFileGuarantee': multiFileGuarantee,
          'fullParity': fullParity.toJson(),
        },
        field: 'describeMutations',
      );
}

/// Typed result of securely staging one local file.
final class AuthoringArtifactStageResult {
  const AuthoringArtifactStageResult({
    required this.reference,
    required this.deduplicated,
  });

  final ContentArtifactRef reference;
  final bool deduplicated;

  Map<String, Object?> toJson() => freezeContractJsonObject(
        {
          'artifactHandle': reference.handle,
          'digest': reference.digest,
          'mediaType': reference.mediaType,
          'byteLength': reference.byteLength,
          'deduplicated': deduplicated,
        },
        field: 'stageArtifact',
      );
}

/// Typed result of one immutable planning pass.
final class AuthoringMutationPlanResult {
  const AuthoringMutationPlanResult({
    required this.plan,
    required this.snapshotRevision,
    required this.receipt,
    this.publicProjection,
  });

  final Map<String, Object?>? publicProjection;
  final AuthoringPlan plan;
  final String snapshotRevision;
  final AuthoringReceipt receipt;

  String get planId => plan.planId;
  bool get applicable => plan.applicable;
  String? get nonApplicableReason => plan.nonApplicableReason;

  Map<String, Object?> toJson() {
    if (publicProjection != null && authoringProjectionFits(publicProjection)) {
      return freezeContractJsonObject(publicProjection!, field: 'mutationPlan');
    }
    final full = <String, Object?>{
      'planId': planId,
      'applicable': applicable,
      if (nonApplicableReason != null)
        'nonApplicableReason': nonApplicableReason,
      'snapshotRevision': snapshotRevision,
      'plan': plan.toJson(),
      'receipt': receipt.toJson()
    };
    return freezeContractJsonObject(
        authoringProjectionFits(full)
            ? full
            : compactUnavailablePlanResult(
                plan: plan,
                receipt: receipt,
                snapshotRevision: snapshotRevision),
        field: 'mutationPlan');
  }
}

final class AuthoringMutationConfirmationResult {
  const AuthoringMutationConfirmationResult({
    required this.planId,
    required this.confirmationToken,
    required this.expiresInSeconds,
  });

  final String planId;
  final String confirmationToken;
  final int expiresInSeconds;

  Map<String, Object?> toJson() => Map.unmodifiable({
        'planId': planId,
        'confirmationToken': confirmationToken,
        'expiresInSeconds': expiresInSeconds,
      });
}

final class AuthoringSnapshotRefreshDiagnostic {
  const AuthoringSnapshotRefreshDiagnostic();
  String get code => 'snapshot.refresh_unavailable';
  String get message =>
      'The mutation is committed. Reload the project before continuing; do not replay the mutation.';
  Map<String, Object?> toJson() => {'code': code, 'message': message};
}

final class AuthoringMutationResult {
  AuthoringMutationResult(
      {required this.receipt,
      required this.snapshotRevision,
      this.diagnostic,
      this.publicProjection}) {
    if ((snapshotRevision == null) != (diagnostic != null)) {
      throw ArgumentError(
          'An unknown snapshot revision requires a refresh diagnostic.');
    }
  }

  final AuthoringReceipt receipt;
  final String? snapshotRevision;
  final AuthoringSnapshotRefreshDiagnostic? diagnostic;
  final Map<String, Object?>? publicProjection;

  Map<String, Object?> toJson() {
    if (publicProjection != null && authoringProjectionFits(publicProjection)) {
      return freezeContractJsonObject(publicProjection!,
          field: 'mutationReceipt');
    }
    final full = <String, Object?>{
      'receipt': receipt.toJson(),
      'snapshotRevision': snapshotRevision,
      if (diagnostic != null) 'diagnostic': diagnostic!.toJson()
    };
    return freezeContractJsonObject(
        authoringProjectionFits(full)
            ? full
            : compactUnavailableMutationResult(
                receipt: receipt,
                snapshotRevision: snapshotRevision,
                diagnostic: diagnostic?.toJson()),
        field: 'mutationReceipt');
  }
}

final class AuthoringMutationHistoryResult {
  const AuthoringMutationHistoryResult(this.page, {this.publicProjection});

  final Map<String, Object?>? publicProjection;

  final AuthoringHistoryPage page;

  List<AuthoringHistoryEntry> get entries => page.entries;
  AuthoringHistoryCursor? get nextCursor => page.nextCursor;

  Map<String, Object?> toJson() {
    if (publicProjection != null && authoringProjectionFits(publicProjection)) {
      return freezeContractJsonObject(publicProjection!,
          field: 'mutationHistory');
    }
    final full = <String, Object?>{
      'entries': [for (final entry in entries) entry.toJson()],
      if (nextCursor != null) 'nextCursor': nextCursor!.wireValue
    };
    return freezeContractJsonObject(
        authoringProjectionFits(full)
            ? full
            : compactUnavailableHistoryResult(page),
        field: 'mutationHistory');
  }
}

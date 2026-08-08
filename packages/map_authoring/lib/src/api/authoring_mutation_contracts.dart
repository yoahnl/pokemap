import '../contracts/action_descriptor.dart';
import '../contracts/artifact_ref.dart';
import '../contracts/authoring_receipt.dart';
import '../contracts/json_contract_support.dart';
import '../history/authoring_history.dart';
import '../history/history_store.dart';
import '../parity/full_authoring_parity.dart';
import '../transactions/authoring_plan.dart';

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
  });

  final AuthoringPlan plan;
  final String snapshotRevision;
  final AuthoringReceipt receipt;

  String get planId => plan.planId;
  bool get applicable => plan.applicable;
  String? get nonApplicableReason => plan.nonApplicableReason;

  Map<String, Object?> toJson() => freezeContractJsonObject(
        {
          'planId': planId,
          'applicable': applicable,
          if (nonApplicableReason case final reason?)
            'nonApplicableReason': reason,
          'snapshotRevision': snapshotRevision,
          'plan': plan.toJson(),
          'receipt': receipt.toJson(),
        },
        field: 'mutationPlan',
      );
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

final class AuthoringMutationResult {
  const AuthoringMutationResult({
    required this.receipt,
    required this.snapshotRevision,
  });

  final AuthoringReceipt receipt;
  final String snapshotRevision;

  Map<String, Object?> toJson() => freezeContractJsonObject(
        {
          'receipt': receipt.toJson(),
          'snapshotRevision': snapshotRevision,
        },
        field: 'mutationReceipt',
      );
}

final class AuthoringMutationHistoryResult {
  const AuthoringMutationHistoryResult(this.page);

  final AuthoringHistoryPage page;

  List<AuthoringHistoryEntry> get entries => page.entries;
  AuthoringHistoryCursor? get nextCursor => page.nextCursor;

  Map<String, Object?> toJson() => freezeContractJsonObject(
        {
          'entries': [for (final entry in entries) entry.toJson()],
          if (nextCursor case final next?) 'nextCursor': next.wireValue,
        },
        field: 'mutationHistory',
      );
}

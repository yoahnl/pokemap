import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart' show immutable;

import '../models/new_game_draft.dart';
import '../models/new_game_seed.dart';

enum NewGameSeedCommitStatus { committed, replayed, rejected, conflict, failed }

enum NewGameSeedCommitReceiptStatus { committed, rejected }

enum NewGameSeedCommitIssueCode {
  staleProjectRevision,
  staleDraftRevision,
  draftIncomplete,
  operationConflict,
  tokenAlreadyUsed,
  seedBuildFailed,
}

@immutable
final class NewGameSeedCommitToken {
  NewGameSeedCommitToken({
    required String projectRevision,
    required String slotId,
    required this.draftRevision,
  }) : projectRevision = _requiredIdentity(projectRevision, 'projectRevision'),
       slotId = _requiredIdentity(slotId, 'slotId') {
    if (draftRevision < 0) {
      throw ArgumentError.value(
        draftRevision,
        'draftRevision',
        'must not be negative',
      );
    }
  }

  final String projectRevision;
  final String slotId;
  final int draftRevision;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NewGameSeedCommitToken &&
          other.projectRevision == projectRevision &&
          other.slotId == slotId &&
          other.draftRevision == draftRevision;

  @override
  int get hashCode => Object.hash(projectRevision, slotId, draftRevision);

  @override
  String toString() =>
      'NewGameSeedCommitToken(projectRevision: $projectRevision, '
      'slotId: $slotId, draftRevision: $draftRevision)';
}

@immutable
final class NewGameSeedCommitIssue {
  NewGameSeedCommitIssue({
    required this.code,
    required this.field,
    Map<String, String> arguments = const <String, String>{},
  }) : arguments = Map<String, String>.unmodifiable(arguments);

  final NewGameSeedCommitIssueCode code;
  final String field;
  final Map<String, String> arguments;

  String get diagnosticCode => switch (code) {
    NewGameSeedCommitIssueCode.staleProjectRevision =>
      'new_game.seed_commit_stale_project',
    NewGameSeedCommitIssueCode.staleDraftRevision =>
      'new_game.seed_commit_stale_draft',
    NewGameSeedCommitIssueCode.draftIncomplete =>
      'new_game.seed_commit_draft_incomplete',
    NewGameSeedCommitIssueCode.operationConflict =>
      'new_game.seed_commit_operation_conflict',
    NewGameSeedCommitIssueCode.tokenAlreadyUsed =>
      'new_game.seed_commit_token_already_used',
    NewGameSeedCommitIssueCode.seedBuildFailed => 'new_game.seed_commit_failed',
  };

  Map<String, dynamic> toJson() => <String, dynamic>{
    'code': code.name,
    'diagnosticCode': diagnosticCode,
    'field': field,
    if (arguments.isNotEmpty) 'arguments': arguments,
  };

  @override
  String toString() =>
      'NewGameSeedCommitIssue(code: ${code.name}, field: $field)';
}

@immutable
final class NewGameSeedCommitReceipt {
  NewGameSeedCommitReceipt._({
    required this.operationId,
    required this.token,
    required this.draftId,
    required this.status,
    required this.seed,
    required _NewGameDraftSnapshot draftSnapshot,
    required List<NewGameSeedCommitIssue> issues,
  }) : _draftSnapshot = draftSnapshot,
       issues = List<NewGameSeedCommitIssue>.unmodifiable(issues);

  final int schemaVersion = 1;
  final String operationId;
  final NewGameSeedCommitToken token;
  final String draftId;
  final NewGameSeedCommitReceiptStatus status;
  final NewGameSeed? seed;
  final List<NewGameSeedCommitIssue> issues;
  final _NewGameDraftSnapshot _draftSnapshot;

  @override
  String toString() =>
      'NewGameSeedCommitReceipt(operationId: $operationId, '
      'status: ${status.name}, draftId: $draftId, '
      'issueCount: ${issues.length})';
}

@immutable
final class NewGameSeedCommitJournal {
  NewGameSeedCommitJournal._(
    Map<String, NewGameSeedCommitReceipt> receipts,
    Map<NewGameSeedCommitToken, String> operationIdsByToken,
  ) : receipts = Map<String, NewGameSeedCommitReceipt>.unmodifiable(receipts),
      _operationIdsByToken = Map<NewGameSeedCommitToken, String>.unmodifiable(
        operationIdsByToken,
      );

  factory NewGameSeedCommitJournal.empty() => NewGameSeedCommitJournal._(
    const <String, NewGameSeedCommitReceipt>{},
    const <NewGameSeedCommitToken, String>{},
  );

  final Map<String, NewGameSeedCommitReceipt> receipts;
  final Map<NewGameSeedCommitToken, String> _operationIdsByToken;

  NewGameSeedCommitReceipt? receiptForOperation(String operationId) =>
      receipts[operationId.trim()];

  NewGameSeedCommitReceipt? receiptForToken(NewGameSeedCommitToken token) {
    final operationId = _operationIdsByToken[token];
    return operationId == null ? null : receipts[operationId];
  }

  NewGameSeedCommitJournal _record(NewGameSeedCommitReceipt receipt) =>
      NewGameSeedCommitJournal._(
        <String, NewGameSeedCommitReceipt>{
          ...receipts,
          receipt.operationId: receipt,
        },
        <NewGameSeedCommitToken, String>{
          ..._operationIdsByToken,
          receipt.token: receipt.operationId,
        },
      );
}

@immutable
final class NewGameSeedCommitResult {
  NewGameSeedCommitResult._({
    required this.status,
    required this.journal,
    required this.receipt,
    required List<NewGameSeedCommitIssue> issues,
  }) : issues = List<NewGameSeedCommitIssue>.unmodifiable(issues);

  final NewGameSeedCommitStatus status;
  final NewGameSeedCommitJournal journal;
  final NewGameSeedCommitReceipt? receipt;
  final List<NewGameSeedCommitIssue> issues;

  NewGameSeed? get seed => receipt?.seed;
}

typedef NewGameSeedBuilder =
    NewGameSeed Function({
      required String operationId,
      required NewGameSeedCommitToken token,
      required NewGameDraft draft,
    });

NewGameSeed buildNewGameSeed({
  required String operationId,
  required NewGameSeedCommitToken token,
  required NewGameDraft draft,
}) => NewGameSeed(
  operationId: operationId,
  projectRevision: token.projectRevision,
  slotId: token.slotId,
  saveId: _deterministicSaveId(
    operationId: operationId,
    projectRevision: token.projectRevision,
    slotId: token.slotId,
    draftId: draft.draftId,
  ),
  draftId: draft.draftId,
  draftRevision: token.draftRevision,
  playerName: draft.playerName,
  avatarCharacterId: draft.avatarCharacterId,
  pronounSet: draft.pronounSet,
  starterOptionId: draft.starterOptionId,
  variables: draft.variables,
);

String _deterministicSaveId({
  required String operationId,
  required String projectRevision,
  required String slotId,
  required String draftId,
}) {
  final bytes = sha256
      .convert(
        utf8.encode(
          jsonEncode(<String>[operationId, projectRevision, slotId, draftId]),
        ),
      )
      .bytes
      .take(16)
      .toList(growable: false);
  bytes[6] = (bytes[6] & 0x0f) | 0x50;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}

NewGameSeedCommitResult commitNewGameDraft({
  required NewGameSeedCommitJournal journal,
  required String operationId,
  required String currentProjectRevision,
  required int expectedDraftRevision,
  required NewGameDraft draft,
  NewGameSeedBuilder? seedBuilder,
}) {
  final normalizedOperationId = _requiredIdentity(operationId, 'operationId');
  final token = NewGameSeedCommitToken(
    projectRevision: currentProjectRevision,
    slotId: draft.slotId,
    draftRevision: expectedDraftRevision,
  );
  final existingOperation = journal.receiptForOperation(normalizedOperationId);
  if (existingOperation != null) {
    if (existingOperation.token == token &&
        existingOperation.draftId == draft.draftId &&
        existingOperation._draftSnapshot.matches(draft)) {
      return NewGameSeedCommitResult._(
        status: NewGameSeedCommitStatus.replayed,
        journal: journal,
        receipt: existingOperation,
        issues: const <NewGameSeedCommitIssue>[],
      );
    }
    return _conflict(
      journal: journal,
      receipt: existingOperation,
      code: NewGameSeedCommitIssueCode.operationConflict,
      field: 'operationId',
    );
  }
  final existingToken = journal.receiptForToken(token);
  if (existingToken != null) {
    return _conflict(
      journal: journal,
      receipt: existingToken,
      code: NewGameSeedCommitIssueCode.tokenAlreadyUsed,
      field: 'commitToken',
    );
  }
  if (draft.projectRevision != token.projectRevision) {
    return _reject(
      journal: journal,
      operationId: normalizedOperationId,
      token: token,
      draft: draft,
      issues: <NewGameSeedCommitIssue>[
        NewGameSeedCommitIssue(
          code: NewGameSeedCommitIssueCode.staleProjectRevision,
          field: 'projectRevision',
          arguments: <String, String>{
            'expected': token.projectRevision,
            'actual': draft.projectRevision,
          },
        ),
      ],
    );
  }
  if (draft.revision != token.draftRevision) {
    return _reject(
      journal: journal,
      operationId: normalizedOperationId,
      token: token,
      draft: draft,
      issues: <NewGameSeedCommitIssue>[
        NewGameSeedCommitIssue(
          code: NewGameSeedCommitIssueCode.staleDraftRevision,
          field: 'draftRevision',
          arguments: <String, String>{
            'expected': token.draftRevision.toString(),
            'actual': draft.revision.toString(),
          },
        ),
      ],
    );
  }
  final draftIssues = draft.validate();
  if (draftIssues.isNotEmpty) {
    return _reject(
      journal: journal,
      operationId: normalizedOperationId,
      token: token,
      draft: draft,
      issues: draftIssues
          .map(
            (issue) => NewGameSeedCommitIssue(
              code: NewGameSeedCommitIssueCode.draftIncomplete,
              field: issue.field,
              arguments: <String, String>{
                ...issue.arguments,
                'draftDiagnosticCode': issue.diagnosticCode,
              },
            ),
          )
          .toList(growable: false),
    );
  }

  late final NewGameSeed seed;
  try {
    seed = (seedBuilder ?? buildNewGameSeed)(
      operationId: normalizedOperationId,
      token: token,
      draft: draft,
    );
  } on Object {
    return NewGameSeedCommitResult._(
      status: NewGameSeedCommitStatus.failed,
      journal: journal,
      receipt: null,
      issues: <NewGameSeedCommitIssue>[
        NewGameSeedCommitIssue(
          code: NewGameSeedCommitIssueCode.seedBuildFailed,
          field: 'seed',
        ),
      ],
    );
  }
  if (!_matches(seed, normalizedOperationId, token, draft)) {
    return NewGameSeedCommitResult._(
      status: NewGameSeedCommitStatus.failed,
      journal: journal,
      receipt: null,
      issues: <NewGameSeedCommitIssue>[
        NewGameSeedCommitIssue(
          code: NewGameSeedCommitIssueCode.seedBuildFailed,
          field: 'seed',
        ),
      ],
    );
  }
  final receipt = NewGameSeedCommitReceipt._(
    operationId: normalizedOperationId,
    token: token,
    draftId: draft.draftId,
    status: NewGameSeedCommitReceiptStatus.committed,
    seed: seed,
    draftSnapshot: _NewGameDraftSnapshot.from(draft),
    issues: const <NewGameSeedCommitIssue>[],
  );
  return NewGameSeedCommitResult._(
    status: NewGameSeedCommitStatus.committed,
    journal: journal._record(receipt),
    receipt: receipt,
    issues: const <NewGameSeedCommitIssue>[],
  );
}

NewGameSeedCommitResult _reject({
  required NewGameSeedCommitJournal journal,
  required String operationId,
  required NewGameSeedCommitToken token,
  required NewGameDraft draft,
  required List<NewGameSeedCommitIssue> issues,
}) {
  final receipt = NewGameSeedCommitReceipt._(
    operationId: operationId,
    token: token,
    draftId: draft.draftId,
    status: NewGameSeedCommitReceiptStatus.rejected,
    seed: null,
    draftSnapshot: _NewGameDraftSnapshot.from(draft),
    issues: issues,
  );
  return NewGameSeedCommitResult._(
    status: NewGameSeedCommitStatus.rejected,
    journal: journal._record(receipt),
    receipt: receipt,
    issues: issues,
  );
}

NewGameSeedCommitResult _conflict({
  required NewGameSeedCommitJournal journal,
  required NewGameSeedCommitReceipt receipt,
  required NewGameSeedCommitIssueCode code,
  required String field,
}) {
  final issue = NewGameSeedCommitIssue(code: code, field: field);
  return NewGameSeedCommitResult._(
    status: NewGameSeedCommitStatus.conflict,
    journal: journal,
    receipt: receipt,
    issues: <NewGameSeedCommitIssue>[issue],
  );
}

bool _matches(
  NewGameSeed seed,
  String operationId,
  NewGameSeedCommitToken token,
  NewGameDraft draft,
) =>
    seed.operationId == operationId &&
    seed.projectRevision == token.projectRevision &&
    seed.slotId == token.slotId &&
    seed.draftId == draft.draftId &&
    seed.draftRevision == token.draftRevision &&
    seed.playerName == draft.playerName &&
    seed.avatarCharacterId == draft.avatarCharacterId &&
    seed.pronounSet == draft.pronounSet &&
    seed.starterOptionId == draft.starterOptionId &&
    _mapEquals(seed.variables, draft.variables);

bool _mapEquals(Map<Object?, Object?> left, Map<Object?, Object?> right) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (!right.containsKey(entry.key) || right[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

@immutable
final class _NewGameDraftSnapshot {
  _NewGameDraftSnapshot.from(NewGameDraft draft)
    : draftId = draft.draftId,
      projectRevision = draft.projectRevision,
      slotId = draft.slotId,
      revision = draft.revision,
      playerName = draft.playerName,
      avatarCharacterId = draft.avatarCharacterId,
      pronounSetName = draft.pronounSet.name,
      starterOptionId = draft.starterOptionId,
      variables = Map.unmodifiable(draft.variables);

  final String draftId;
  final String projectRevision;
  final String slotId;
  final int revision;
  final String playerName;
  final String? avatarCharacterId;
  final String pronounSetName;
  final String? starterOptionId;
  final Map<String, Object?> variables;

  bool matches(NewGameDraft draft) =>
      draft.draftId == draftId &&
      draft.projectRevision == projectRevision &&
      draft.slotId == slotId &&
      draft.revision == revision &&
      draft.playerName == playerName &&
      draft.avatarCharacterId == avatarCharacterId &&
      draft.pronounSet.name == pronounSetName &&
      draft.starterOptionId == starterOptionId &&
      _mapEquals(variables, draft.variables);
}

String _requiredIdentity(String value, String name) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, name, 'must not be empty');
  }
  return normalized;
}

import '../contracts/authoring_receipt.dart';
import '../contracts/resource_ref.dart';
import '../ports/idempotency_store.dart';
import '../security/authoring_permission.dart';
import '../transactions/change_set.dart';

final class AuthoringHistoryException implements Exception {
  const AuthoringHistoryException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'AuthoringHistoryException($code): $message';
}

enum AuthoringHistoryKind {
  mutation('mutation'),
  undo('undo'),
  redo('redo'),
  revert('revert');

  const AuthoringHistoryKind(this.wireName);

  final String wireName;

  static AuthoringHistoryKind fromWireName(String value) {
    return AuthoringHistoryKind.values.firstWhere(
      (kind) => kind.wireName == value,
      orElse: () => throw const FormatException('Unknown history kind.'),
    );
  }
}

final class AuthoringHistoryContext {
  AuthoringHistoryContext({
    this.kind = AuthoringHistoryKind.mutation,
    String? targetEntryId,
    String? expectedHeadEntryId,
  })  : targetEntryId = targetEntryId == null
            ? null
            : safeAuthoringSecurityIdentifier(
                targetEntryId,
                'targetEntryId',
              ),
        expectedHeadEntryId = expectedHeadEntryId == null
            ? null
            : safeAuthoringSecurityIdentifier(
                expectedHeadEntryId,
                'expectedHeadEntryId',
              ) {
    if ((kind == AuthoringHistoryKind.mutation) !=
        (this.targetEntryId == null)) {
      throw ArgumentError(
        'Only undo, redo, and revert history require a target entry.',
      );
    }
    final requiresHead = kind == AuthoringHistoryKind.redo ||
        kind == AuthoringHistoryKind.revert;
    if (requiresHead != (this.expectedHeadEntryId != null)) {
      throw ArgumentError(
        'Redo and revert history require an expected current head.',
      );
    }
  }

  factory AuthoringHistoryContext.fromExtensions(
    Map<String, Object?> extensions,
  ) {
    final raw = extensions['history'];
    if (raw == null) return AuthoringHistoryContext();
    if (raw is! Map) throw const FormatException('Invalid history context.');
    final json = Map<String, Object?>.from(raw);
    const keys = {'kind', 'targetEntryId', 'expectedHeadEntryId'};
    if (json.keys.any((key) => !keys.contains(key)) ||
        json['kind'] is! String) {
      throw const FormatException('Invalid history context.');
    }
    try {
      return AuthoringHistoryContext(
        kind: AuthoringHistoryKind.fromWireName(json['kind']! as String),
        targetEntryId: json['targetEntryId'] as String?,
        expectedHeadEntryId: json['expectedHeadEntryId'] as String?,
      );
    } on TypeError {
      throw const FormatException('Invalid history context.');
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final AuthoringHistoryKind kind;
  final String? targetEntryId;
  final String? expectedHeadEntryId;

  Map<String, Object?> toJson() => {
        'kind': kind.wireName,
        if (targetEntryId != null) 'targetEntryId': targetEntryId,
        if (expectedHeadEntryId != null)
          'expectedHeadEntryId': expectedHeadEntryId,
      };
}

final class AuthoringHistoryResourceChange {
  AuthoringHistoryResourceChange({
    required this.resource,
    required String storageKey,
    required String? beforeRevision,
    required String? afterRevision,
    required String? beforeBlobId,
    required String? afterBlobId,
  })  : storageKey = _storageKey(storageKey),
        beforeRevision = _optionalFingerprint(
          beforeRevision,
          'beforeRevision',
        ),
        afterRevision = _optionalFingerprint(afterRevision, 'afterRevision'),
        beforeBlobId = _optionalFingerprint(beforeBlobId, 'beforeBlobId'),
        afterBlobId = _optionalFingerprint(afterBlobId, 'afterBlobId') {
    if ((this.beforeRevision == null) != (this.beforeBlobId == null) ||
        (this.afterRevision == null) != (this.afterBlobId == null) ||
        (this.beforeRevision == null && this.afterRevision == null)) {
      throw ArgumentError(
        'History revisions and retained blob identities must agree.',
      );
    }
  }

  factory AuthoringHistoryResourceChange.fromJson(Map<String, dynamic> json) {
    const keys = {
      'resource',
      'storageKey',
      'beforeRevision',
      'afterRevision',
      'beforeBlobId',
      'afterBlobId',
    };
    if (json.keys.any((key) => !keys.contains(key)) ||
        json['resource'] is! Map) {
      throw const FormatException('Invalid history resource change.');
    }
    try {
      return AuthoringHistoryResourceChange(
        resource: AuthoringResourceRef.fromJson(
          Map<String, dynamic>.from(json['resource'] as Map),
        ),
        storageKey: _requiredString(json['storageKey']),
        beforeRevision: _optionalString(json['beforeRevision']),
        afterRevision: _optionalString(json['afterRevision']),
        beforeBlobId: _optionalString(json['beforeBlobId']),
        afterBlobId: _optionalString(json['afterBlobId']),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final AuthoringResourceRef resource;
  final String storageKey;
  final String? beforeRevision;
  final String? afterRevision;
  final String? beforeBlobId;
  final String? afterBlobId;

  Iterable<String> get retainedBlobIds sync* {
    if (beforeBlobId != null) yield beforeBlobId!;
    if (afterBlobId != null) yield afterBlobId!;
  }

  Map<String, Object?> toJson() => {
        'resource': resource.toJson(),
        'storageKey': storageKey,
        'beforeRevision': beforeRevision,
        'afterRevision': afterRevision,
        'beforeBlobId': beforeBlobId,
        'afterBlobId': afterBlobId,
      };
}

final class AuthoringHistoryEntry {
  AuthoringHistoryEntry({
    required String entryId,
    required String projectId,
    required String actorId,
    required String planId,
    required String operationId,
    required this.kind,
    String? targetEntryId,
    required this.receipt,
    required DateTime committedAt,
    required Iterable<AuthoringHistoryResourceChange> changes,
    String? nonUndoableReason,
  })  : entryId = safeAuthoringSecurityIdentifier(entryId, 'entryId'),
        projectId = safeAuthoringSecurityIdentifier(projectId, 'projectId'),
        actorId = safeAuthoringSecurityIdentifier(actorId, 'actorId'),
        planId = safeAuthoringSecurityIdentifier(planId, 'planId'),
        operationId = safeAuthoringSecurityIdentifier(
          operationId,
          'operationId',
        ),
        targetEntryId = targetEntryId == null
            ? null
            : safeAuthoringSecurityIdentifier(
                targetEntryId,
                'targetEntryId',
              ),
        committedAt = committedAt.toUtc(),
        changes = _sortedChanges(changes),
        nonUndoableReason =
            nonUndoableReason == null ? null : _reason(nonUndoableReason) {
    if (this.entryId != receipt.receiptId || this.changes.isEmpty) {
      throw ArgumentError(
        'History identity and retained changes must match the receipt.',
      );
    }
    if ((kind == AuthoringHistoryKind.mutation) !=
        (this.targetEntryId == null)) {
      throw ArgumentError('History target does not match its kind.');
    }
    final receiptContext = AuthoringHistoryContext.fromExtensions(
      receipt.extensions,
    );
    if (receiptContext.kind != kind ||
        receiptContext.targetEntryId != this.targetEntryId) {
      throw ArgumentError('History context must match its frozen receipt.');
    }
    final receiptResources = {
      for (final resource in receipt.affectedResources)
        '${resource.kind}\u0000${resource.id}',
    };
    final changedResources = {
      for (final change in this.changes)
        '${change.resource.kind}\u0000${change.resource.id}',
    };
    if (receiptResources.length != changedResources.length ||
        !receiptResources.containsAll(changedResources)) {
      throw ArgumentError('History changes must match receipt resources.');
    }
  }

  factory AuthoringHistoryEntry.fromJson(Map<String, dynamic> json) {
    const keys = {
      'schemaVersion',
      'entryId',
      'projectId',
      'actorId',
      'planId',
      'operationId',
      'kind',
      'targetEntryId',
      'receipt',
      'committedAtUtc',
      'changes',
      'nonUndoableReason',
    };
    if (json['schemaVersion'] != 1 ||
        json.keys.any((key) => !keys.contains(key)) ||
        json['receipt'] is! Map ||
        json['changes'] is! List) {
      throw const FormatException('Invalid history entry schema.');
    }
    try {
      return AuthoringHistoryEntry(
        entryId: _requiredString(json['entryId']),
        projectId: _requiredString(json['projectId']),
        actorId: _requiredString(json['actorId']),
        planId: _requiredString(json['planId']),
        operationId: _requiredString(json['operationId']),
        kind: AuthoringHistoryKind.fromWireName(
          _requiredString(json['kind']),
        ),
        targetEntryId: _optionalString(json['targetEntryId']),
        receipt: AuthoringReceipt.fromJson(
          Map<String, dynamic>.from(json['receipt'] as Map),
        ),
        committedAt: _requiredDate(json['committedAtUtc']),
        changes: (json['changes'] as List).map((raw) {
          if (raw is! Map) throw const FormatException();
          return AuthoringHistoryResourceChange.fromJson(
            Map<String, dynamic>.from(raw),
          );
        }),
        nonUndoableReason: _optionalString(json['nonUndoableReason']),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final String entryId;
  final String projectId;
  final String actorId;
  final String planId;
  final String operationId;
  final AuthoringHistoryKind kind;
  final String? targetEntryId;
  final AuthoringReceipt receipt;
  final DateTime committedAt;
  final List<AuthoringHistoryResourceChange> changes;
  final String? nonUndoableReason;

  AuthoringHistoryEntry markNonUndoable(String reason) {
    return AuthoringHistoryEntry(
      entryId: entryId,
      projectId: projectId,
      actorId: actorId,
      planId: planId,
      operationId: operationId,
      kind: kind,
      targetEntryId: targetEntryId,
      receipt: receipt,
      committedAt: committedAt,
      changes: changes,
      nonUndoableReason: nonUndoableReason ?? reason,
    );
  }

  Map<String, Object?> toJson() => {
        'schemaVersion': 1,
        'entryId': entryId,
        'projectId': projectId,
        'actorId': actorId,
        'planId': planId,
        'operationId': operationId,
        'kind': kind.wireName,
        if (targetEntryId != null) 'targetEntryId': targetEntryId,
        'receipt': receipt.toJson(),
        'committedAtUtc': committedAt.toIso8601String(),
        'changes': [for (final change in changes) change.toJson()],
        if (nonUndoableReason != null) 'nonUndoableReason': nonUndoableReason,
      };
}

final class AuthoringCommittedMutation {
  AuthoringCommittedMutation({
    required this.scope,
    required String planId,
    required String operationId,
    required this.receipt,
    required Iterable<AuthoringResourceChange> changes,
  })  : planId = safeAuthoringSecurityIdentifier(planId, 'planId'),
        operationId = safeAuthoringSecurityIdentifier(
          operationId,
          'operationId',
        ),
        changes = List.unmodifiable(changes) {
    if (this.changes.isEmpty ||
        receipt.status == AuthoringReceiptStatus.planned) {
      throw ArgumentError('A committed mutation requires applied changes.');
    }
  }

  final AuthoringIdempotencyScope scope;
  final String planId;
  final String operationId;
  final AuthoringReceipt receipt;
  final List<AuthoringResourceChange> changes;
}

abstract interface class AuthoringTransactionCommitHook {
  Future<void> record(AuthoringCommittedMutation mutation);
}

/// Optional durable guard consulted before a pending transaction is resumed.
abstract interface class AuthoringTransactionRecoveryGuard {
  Future<void> requireRecoveryAllowed({
    required AuthoringReceipt intendedReceipt,
    required AuthoringIdempotencyScope scope,
  });
}

List<AuthoringHistoryResourceChange> _sortedChanges(
  Iterable<AuthoringHistoryResourceChange> changes,
) {
  final result = changes.toList()
    ..sort((left, right) {
      final resourceOrder = '${left.resource.kind}\u0000${left.resource.id}'
          .compareTo('${right.resource.kind}\u0000${right.resource.id}');
      return resourceOrder != 0
          ? resourceOrder
          : left.storageKey.compareTo(right.storageKey);
    });
  final resources = <String>{};
  final storageKeys = <String>{};
  for (final change in result) {
    if (!resources.add('${change.resource.kind}\u0000${change.resource.id}') ||
        !storageKeys.add(change.storageKey)) {
      throw ArgumentError('History changes must be unique.');
    }
  }
  return List.unmodifiable(result);
}

String _storageKey(String value) {
  final segments = value.split('/');
  if (value.trim() != value ||
      value.isEmpty ||
      value.startsWith('/') ||
      value.contains(r'\') ||
      value.contains('\u0000') ||
      segments.any(
          (segment) => segment.isEmpty || segment == '.' || segment == '..') ||
      segments.first == '.pokemap') {
    throw ArgumentError.value(value, 'storageKey', 'must be project-relative');
  }
  return value;
}

String? _optionalFingerprint(String? value, String field) {
  if (value != null && !_fingerprintPattern.hasMatch(value)) {
    throw ArgumentError.value(value, field, 'must be a SHA-256 fingerprint');
  }
  return value;
}

String _reason(String value) {
  if (!RegExp(r'^[a-z][a-z0-9_.-]*$').hasMatch(value)) {
    throw ArgumentError.value(value, 'reason', 'must be a stable safe code');
  }
  return value;
}

String _requiredString(Object? value) {
  if (value is! String || value.isEmpty) throw const FormatException();
  return value;
}

String? _optionalString(Object? value) {
  if (value == null) return null;
  return _requiredString(value);
}

DateTime _requiredDate(Object? value) {
  if (value is! String) throw const FormatException();
  final parsed = DateTime.tryParse(value);
  if (parsed == null || !parsed.isUtc) throw const FormatException();
  return parsed;
}

final RegExp _fingerprintPattern = RegExp(r'^sha256:[0-9a-f]{64}$');

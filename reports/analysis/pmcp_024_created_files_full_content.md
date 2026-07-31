# PMCP-024 — Created Files Full Content

This appendix reproduces every file created by PMCP-024 exactly as it stood immediately before the lot commit. The Evidence Pack and this appendix are reporting artifacts and are intentionally not self-reproduced.

## `packages/map_authoring/lib/src/history/authoring_history.dart`

~~~~~~~~dart
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
~~~~~~~~

## `packages/map_authoring/lib/src/history/history_store.dart`

~~~~~~~~dart
import '../contracts/authoring_receipt.dart';
import '../ports/idempotency_store.dart';
import 'authoring_history.dart';
import 'content_blob_store.dart';

final class AuthoringHistoryCursor {
  AuthoringHistoryCursor._(this.wireValue);

  factory AuthoringHistoryCursor.fromWireValue(String value) {
    if (value.length < 16 ||
        value.length > 2048 ||
        !RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value)) {
      throw const AuthoringHistoryException(
        'history.cursor_invalid',
        'The history cursor is invalid.',
      );
    }
    return AuthoringHistoryCursor._(value);
  }

  final String wireValue;

  @override
  String toString() =>
      'history-cursor:${wireValue.substring(0, wireValue.length.clamp(0, 12))}';
}

final class AuthoringHistoryPage {
  const AuthoringHistoryPage({required this.entries, this.nextCursor});

  final List<AuthoringHistoryEntry> entries;
  final AuthoringHistoryCursor? nextCursor;
}

abstract interface class AuthoringHistoryStore {
  Future<void> append(AuthoringHistoryEntry entry);

  Future<AuthoringHistoryEntry?> get({
    required String projectId,
    required String entryId,
  });

  Future<AuthoringHistoryPage> list({
    required String projectId,
    required int limit,
    AuthoringHistoryCursor? cursor,
  });

  Future<AuthoringHistoryEntry> markNonUndoable({
    required String projectId,
    required String entryId,
    required String reason,
  });
}

/// Idempotent transaction commit hook that retains bytes before history entry.
final class AuthoringHistoryRecorder
    implements
        AuthoringTransactionCommitHook,
        AuthoringTransactionRecoveryGuard {
  const AuthoringHistoryRecorder({
    required AuthoringHistoryStore store,
    required AuthoringContentBlobStore blobs,
  })  : _store = store,
        _blobs = blobs;

  final AuthoringHistoryStore _store;
  final AuthoringContentBlobStore _blobs;

  @override
  Future<void> record(AuthoringCommittedMutation mutation) async {
    final retained = <AuthoringHistoryResourceChange>[];
    for (final change in mutation.changes) {
      final before = change.beforeBytes == null
          ? null
          : await _blobs.put(change.beforeBytes!);
      final after = change.afterBytes == null
          ? null
          : await _blobs.put(change.afterBytes!);
      retained.add(
        AuthoringHistoryResourceChange(
          resource: change.resource,
          storageKey: change.storageKey,
          beforeRevision: change.beforeRevision,
          afterRevision: change.afterRevision,
          beforeBlobId: before?.id,
          afterBlobId: after?.id,
        ),
      );
    }
    final context = AuthoringHistoryContext.fromExtensions(
      mutation.receipt.extensions,
    );
    await _store.append(
      AuthoringHistoryEntry(
        entryId: mutation.receipt.receiptId,
        projectId: mutation.scope.projectId,
        actorId: mutation.scope.actorId,
        planId: mutation.planId,
        operationId: mutation.operationId,
        kind: context.kind,
        targetEntryId: context.targetEntryId,
        receipt: mutation.receipt,
        committedAt: DateTime.parse(mutation.receipt.createdAtUtc).toUtc(),
        changes: retained,
      ),
    );
  }

  @override
  Future<void> requireRecoveryAllowed({
    required AuthoringReceipt intendedReceipt,
    required AuthoringIdempotencyScope scope,
  }) async {
    final context = AuthoringHistoryContext.fromExtensions(
      intendedReceipt.extensions,
    );
    final expectedHead = context.expectedHeadEntryId;
    if (expectedHead == null) return;
    final page = await _store.list(projectId: scope.projectId, limit: 1);
    if (page.entries.isEmpty || page.entries.single.entryId != expectedHead) {
      final isRedo = context.kind == AuthoringHistoryKind.redo;
      throw AuthoringHistoryException(
        isRedo ? 'history.redo_branch_diverged' : 'history.head_stale',
        isRedo
            ? 'Redo is unsafe because the project history has diverged.'
            : 'The current history head differs from the expected head.',
      );
    }
  }
}
~~~~~~~~

## `packages/map_authoring/lib/src/history/file_history_store.dart`

~~~~~~~~dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../security/authoring_permission.dart';
import '../support/authoring_fingerprint.dart';
import 'authoring_history.dart';
import 'history_store.dart';

final class AuthoringHistoryStoreException implements Exception {
  const AuthoringHistoryStoreException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'AuthoringHistoryStoreException($code): $message';
}

/// Locked, hash-chained JSONL history with snapshot-bound pagination.
final class FileAuthoringHistoryStore implements AuthoringHistoryStore {
  FileAuthoringHistoryStore._(this._projectRoot);

  static Future<FileAuthoringHistoryStore> open({
    required String projectRoot,
  }) async {
    try {
      final directory = Directory(projectRoot);
      if ((await directory.stat()).type != FileSystemEntityType.directory) {
        throw const AuthoringHistoryStoreException(
          'history.project_directory_required',
          'The history project root is not a directory.',
        );
      }
      return FileAuthoringHistoryStore._(
        await directory.resolveSymbolicLinks(),
      );
    } on AuthoringHistoryStoreException {
      rethrow;
    } on Object {
      throw const AuthoringHistoryStoreException(
        'history.project_unavailable',
        'The history project root is unavailable.',
      );
    }
  }

  final String _projectRoot;

  static final Map<String, Future<void>> _inProcessLocks = {};

  @override
  Future<void> append(AuthoringHistoryEntry entry) {
    return _guard(() async {
      await _withLock(() async {
        final file = await _historyFile();
        final state = await _readState(file);
        final key = _entryKey(entry.projectId, entry.entryId);
        final existing = state.entries[key];
        if (existing != null) {
          if (canonicalAuthoringJson(existing.entry.toJson()) ==
              canonicalAuthoringJson(entry.toJson())) {
            return;
          }
          throw const AuthoringHistoryStoreException(
            'history.identity_conflict',
            'The history entry identity is already in use.',
          );
        }
        await _appendEvent(
          file,
          state,
          type: 'append',
          payload: {'entry': entry.toJson()},
        );
      });
    });
  }

  @override
  Future<AuthoringHistoryEntry?> get({
    required String projectId,
    required String entryId,
  }) {
    final safeProject = safeAuthoringSecurityIdentifier(
      projectId,
      'projectId',
    );
    final safeEntry = safeAuthoringSecurityIdentifier(entryId, 'entryId');
    return _guard(() async {
      return _withLock(() async {
        final state = await _readState(await _historyFile());
        return state.entries[_entryKey(safeProject, safeEntry)]?.entry;
      });
    });
  }

  @override
  Future<AuthoringHistoryPage> list({
    required String projectId,
    required int limit,
    AuthoringHistoryCursor? cursor,
  }) {
    final safeProject = safeAuthoringSecurityIdentifier(
      projectId,
      'projectId',
    );
    if (limit < 1 || limit > 100) {
      throw const AuthoringHistoryException(
        'history.limit_invalid',
        'History page size must be between 1 and 100.',
      );
    }
    return _guard(() async {
      return _withLock(() async {
        final state = await _readState(await _historyFile());
        final projectEntries = state.entries.values
            .where((stored) => stored.entry.projectId == safeProject)
            .toList()
          ..sort((left, right) => right.sequence.compareTo(left.sequence));
        final decoded = cursor == null
            ? null
            : _decodeCursor(cursor, expectedProjectId: safeProject);
        final snapshotMax = decoded?.snapshotMaxSequence ??
            (projectEntries.isEmpty ? 0 : projectEntries.first.sequence);
        final beforeSequence = decoded?.beforeSequence ?? (snapshotMax + 1);
        final eligible = projectEntries
            .where(
              (stored) =>
                  stored.sequence <= snapshotMax &&
                  stored.sequence < beforeSequence,
            )
            .toList(growable: false);
        final page = eligible.take(limit).toList(growable: false);
        final hasMore = eligible.length > page.length;
        return AuthoringHistoryPage(
          entries: List.unmodifiable(page.map((stored) => stored.entry)),
          nextCursor: hasMore
              ? _encodeCursor(
                  projectId: safeProject,
                  snapshotMaxSequence: snapshotMax,
                  beforeSequence: page.last.sequence,
                )
              : null,
        );
      });
    });
  }

  @override
  Future<AuthoringHistoryEntry> markNonUndoable({
    required String projectId,
    required String entryId,
    required String reason,
  }) {
    final safeProject = safeAuthoringSecurityIdentifier(
      projectId,
      'projectId',
    );
    final safeEntry = safeAuthoringSecurityIdentifier(entryId, 'entryId');
    if (!RegExp(r'^[a-z][a-z0-9_.-]*$').hasMatch(reason)) {
      throw ArgumentError.value(reason, 'reason', 'must be a stable code');
    }
    return _guard(() async {
      return _withLock(() async {
        final file = await _historyFile();
        final state = await _readState(file);
        final stored = state.entries[_entryKey(safeProject, safeEntry)];
        if (stored == null) {
          throw const AuthoringHistoryException(
            'history.entry_missing',
            'The requested history entry is unavailable.',
          );
        }
        if (stored.entry.nonUndoableReason != null) return stored.entry;
        await _appendEvent(
          file,
          state,
          type: 'markNonUndoable',
          payload: {
            'projectId': safeProject,
            'entryId': safeEntry,
            'reason': reason,
          },
        );
        return stored.entry.markNonUndoable(reason);
      });
    });
  }

  Future<void> _appendEvent(
    File file,
    _HistoryState state, {
    required String type,
    required Map<String, Object?> payload,
  }) async {
    final sequence = state.lastSequence + 1;
    final previousDigest = state.lastDigest;
    final event = _HistoryEvent(
      sequence: sequence,
      previousDigest: previousDigest,
      type: type,
      payload: payload,
      digest: _eventDigest(
        sequence: sequence,
        previousDigest: previousDigest,
        type: type,
        payload: payload,
      ),
    );
    final writer = await file.open(mode: FileMode.append);
    try {
      await writer.writeString('${jsonEncode(event.toJson())}\n');
      await writer.flush();
    } finally {
      await writer.close();
    }
  }

  Future<_HistoryState> _readState(File file) async {
    if (!await file.exists()) return _HistoryState.empty();
    final content = await file.readAsString();
    if (content.isEmpty) return _HistoryState.empty();
    final lines = content.split('\n');
    if (lines.last.isEmpty) lines.removeLast();
    if (lines.any((line) => line.isEmpty)) throw const FormatException();
    final entries = <String, _StoredHistoryEntry>{};
    var lastSequence = 0;
    String? lastDigest;
    for (final line in lines) {
      final decoded = jsonDecode(line);
      if (decoded is! Map) throw const FormatException();
      final event = _HistoryEvent.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      if (event.sequence != lastSequence + 1 ||
          event.previousDigest != lastDigest ||
          event.digest !=
              _eventDigest(
                sequence: event.sequence,
                previousDigest: event.previousDigest,
                type: event.type,
                payload: event.payload,
              )) {
        throw const FormatException();
      }
      if (event.type == 'append') {
        final rawEntry = event.payload['entry'];
        if (event.payload.length != 1 || rawEntry is! Map) {
          throw const FormatException();
        }
        final entry = AuthoringHistoryEntry.fromJson(
          Map<String, dynamic>.from(rawEntry),
        );
        final key = _entryKey(entry.projectId, entry.entryId);
        if (entries.containsKey(key)) throw const FormatException();
        entries[key] = _StoredHistoryEntry(
          entry: entry,
          sequence: event.sequence,
        );
      } else if (event.type == 'markNonUndoable') {
        if (event.payload.keys.toSet().difference(
              const {'projectId', 'entryId', 'reason'},
            ).isNotEmpty ||
            event.payload.length != 3) {
          throw const FormatException();
        }
        final projectId = event.payload['projectId'];
        final entryId = event.payload['entryId'];
        final reason = event.payload['reason'];
        if (projectId is! String || entryId is! String || reason is! String) {
          throw const FormatException();
        }
        final stored = entries[_entryKey(projectId, entryId)];
        if (stored == null || stored.entry.nonUndoableReason != null) {
          throw const FormatException();
        }
        entries[_entryKey(projectId, entryId)] = _StoredHistoryEntry(
          entry: stored.entry.markNonUndoable(reason),
          sequence: stored.sequence,
        );
      } else {
        throw const FormatException();
      }
      lastSequence = event.sequence;
      lastDigest = event.digest;
    }
    return _HistoryState(
      entries: entries,
      lastSequence: lastSequence,
      lastDigest: lastDigest,
    );
  }

  Future<T> _withLock<T>(Future<T> Function() operation) async {
    final previous = _inProcessLocks[_projectRoot] ?? Future<void>.value();
    final completion = Completer<void>();
    _inProcessLocks[_projectRoot] = completion.future;
    await previous;
    try {
      late final RandomAccessFile lock;
      try {
        final root = await _authoringRoot();
        lock = await File(_join(root.path, 'history.lock')).open(
          mode: FileMode.append,
        );
        await lock.lock(FileLock.exclusive);
      } on AuthoringHistoryStoreException {
        rethrow;
      } on Object {
        throw const AuthoringHistoryStoreException(
          'history.store_io',
          'The history store lock failed safely.',
        );
      }
      try {
        return await operation();
      } finally {
        try {
          await lock.unlock();
        } on Object {
          // Closing still releases the OS lock.
        }
        await lock.close();
      }
    } finally {
      completion.complete();
      if (identical(_inProcessLocks[_projectRoot], completion.future)) {
        _inProcessLocks.remove(_projectRoot);
      }
    }
  }

  Future<File> _historyFile() async {
    final file = File(_join((await _authoringRoot()).path, 'history.jsonl'));
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type != FileSystemEntityType.notFound &&
        type != FileSystemEntityType.file) {
      throw const AuthoringHistoryStoreException(
        'history.store_path_invalid',
        'The history store path is unsafe.',
      );
    }
    return file;
  }

  Future<Directory> _authoringRoot() async {
    var current = Directory(_projectRoot);
    for (final segment in const ['.pokemap', 'authoring']) {
      final next = Directory(_join(current.path, segment));
      final type = await FileSystemEntity.type(next.path, followLinks: false);
      if (type == FileSystemEntityType.notFound) {
        await next.create();
      } else if (type != FileSystemEntityType.directory) {
        throw const AuthoringHistoryStoreException(
          'history.store_path_invalid',
          'The history store directory is unsafe.',
        );
      }
      current = next;
    }
    return current;
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on AuthoringHistoryException {
      rethrow;
    } on AuthoringHistoryStoreException {
      rethrow;
    } on FormatException {
      throw const AuthoringHistoryStoreException(
        'history.store_corrupt',
        'The history store failed strict verification.',
      );
    } on Object {
      throw const AuthoringHistoryStoreException(
        'history.store_io',
        'The history store failed safely.',
      );
    }
  }
}

final class _HistoryState {
  const _HistoryState({
    required this.entries,
    required this.lastSequence,
    required this.lastDigest,
  });

  factory _HistoryState.empty() => const _HistoryState(
        entries: {},
        lastSequence: 0,
        lastDigest: null,
      );

  final Map<String, _StoredHistoryEntry> entries;
  final int lastSequence;
  final String? lastDigest;
}

final class _StoredHistoryEntry {
  const _StoredHistoryEntry({required this.entry, required this.sequence});

  final AuthoringHistoryEntry entry;
  final int sequence;
}

final class _HistoryEvent {
  _HistoryEvent({
    required this.sequence,
    required this.previousDigest,
    required this.type,
    required Map<String, Object?> payload,
    required this.digest,
  }) : payload = Map.unmodifiable(payload);

  factory _HistoryEvent.fromJson(Map<String, dynamic> json) {
    const keys = {
      'schemaVersion',
      'sequence',
      'previousDigest',
      'type',
      'payload',
      'digest',
    };
    if (json['schemaVersion'] != 1 ||
        json.keys.any((key) => !keys.contains(key)) ||
        json['sequence'] is! int ||
        (json['previousDigest'] != null && json['previousDigest'] is! String) ||
        json['type'] is! String ||
        json['payload'] is! Map ||
        json['digest'] is! String) {
      throw const FormatException();
    }
    return _HistoryEvent(
      sequence: json['sequence'] as int,
      previousDigest: json['previousDigest'] as String?,
      type: json['type'] as String,
      payload: Map<String, Object?>.from(json['payload'] as Map),
      digest: json['digest'] as String,
    );
  }

  final int sequence;
  final String? previousDigest;
  final String type;
  final Map<String, Object?> payload;
  final String digest;

  Map<String, Object?> toJson() => {
        'schemaVersion': 1,
        'sequence': sequence,
        'previousDigest': previousDigest,
        'type': type,
        'payload': payload,
        'digest': digest,
      };
}

final class _DecodedHistoryCursor {
  const _DecodedHistoryCursor({
    required this.snapshotMaxSequence,
    required this.beforeSequence,
  });

  final int snapshotMaxSequence;
  final int beforeSequence;
}

AuthoringHistoryCursor _encodeCursor({
  required String projectId,
  required int snapshotMaxSequence,
  required int beforeSequence,
}) {
  final payload = <String, Object?>{
    'schemaVersion': 1,
    'projectId': projectId,
    'snapshotMaxSequence': snapshotMaxSequence,
    'beforeSequence': beforeSequence,
  };
  final envelope = {
    'payload': payload,
    'digest': computeAuthoringJsonFingerprint(
      payload,
      logicalName: 'authoring-history-cursor.json',
    ),
  };
  return AuthoringHistoryCursor.fromWireValue(
    base64UrlEncode(utf8.encode(jsonEncode(envelope))).replaceAll('=', ''),
  );
}

_DecodedHistoryCursor _decodeCursor(
  AuthoringHistoryCursor cursor, {
  required String expectedProjectId,
}) {
  try {
    final value = cursor.wireValue;
    final padded =
        value.padRight(value.length + ((4 - value.length % 4) % 4), '=');
    final decoded = jsonDecode(utf8.decode(base64Url.decode(padded)));
    if (decoded is! Map || decoded['payload'] is! Map) {
      throw const FormatException();
    }
    final envelope = Map<String, dynamic>.from(decoded);
    final payload = Map<String, Object?>.from(envelope['payload'] as Map);
    const keys = {
      'schemaVersion',
      'projectId',
      'snapshotMaxSequence',
      'beforeSequence',
    };
    if (payload['schemaVersion'] != 1 ||
        payload.keys.any((key) => !keys.contains(key)) ||
        payload['projectId'] != expectedProjectId ||
        payload['snapshotMaxSequence'] is! int ||
        payload['beforeSequence'] is! int ||
        envelope['digest'] !=
            computeAuthoringJsonFingerprint(
              payload,
              logicalName: 'authoring-history-cursor.json',
            )) {
      throw const FormatException();
    }
    final snapshot = payload['snapshotMaxSequence'] as int;
    final before = payload['beforeSequence'] as int;
    if (snapshot < 0 || before < 1 || before > snapshot + 1) {
      throw const FormatException();
    }
    return _DecodedHistoryCursor(
      snapshotMaxSequence: snapshot,
      beforeSequence: before,
    );
  } on Object {
    throw const AuthoringHistoryException(
      'history.cursor_invalid',
      'The history cursor is invalid.',
    );
  }
}

String _eventDigest({
  required int sequence,
  required String? previousDigest,
  required String type,
  required Map<String, Object?> payload,
}) {
  return computeAuthoringJsonFingerprint(
    {
      'schemaVersion': 1,
      'sequence': sequence,
      'previousDigest': previousDigest,
      'type': type,
      'payload': payload,
    },
    logicalName: 'authoring-history-event.json',
  );
}

String _entryKey(String projectId, String entryId) =>
    '$projectId\u0000$entryId';

String _join(String first, String second) =>
    [first, second].join(Platform.pathSeparator);
~~~~~~~~

## `packages/map_authoring/lib/src/history/content_blob_store.dart`

~~~~~~~~dart
import 'dart:async';
import 'dart:io';

import '../support/authoring_fingerprint.dart';

final class AuthoringContentBlobStoreException implements Exception {
  const AuthoringContentBlobStoreException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'AuthoringContentBlobStoreException($code): $message';
}

final class AuthoringContentBlobRef {
  AuthoringContentBlobRef({required String id, required this.byteLength})
      : id = _blobId(id) {
    if (byteLength < 0) {
      throw ArgumentError.value(byteLength, 'byteLength', 'must be >= 0');
    }
  }

  final String id;
  final int byteLength;
}

abstract interface class AuthoringContentBlobStore {
  Future<AuthoringContentBlobRef> put(Iterable<int> bytes);

  Future<List<int>?> get(String id);

  Future<bool> contains(String id);

  Future<List<String>> listIds();

  Future<int> prune({required Set<String> retainIds});
}

/// Content-addressed retained payloads shared by history entries.
final class FileAuthoringContentBlobStore implements AuthoringContentBlobStore {
  FileAuthoringContentBlobStore._(this._projectRoot);

  static Future<FileAuthoringContentBlobStore> open({
    required String projectRoot,
  }) async {
    try {
      final directory = Directory(projectRoot);
      if ((await directory.stat()).type != FileSystemEntityType.directory) {
        throw const AuthoringContentBlobStoreException(
          'history.blob_project_required',
          'The history blob project root is not a directory.',
        );
      }
      return FileAuthoringContentBlobStore._(
        await directory.resolveSymbolicLinks(),
      );
    } on AuthoringContentBlobStoreException {
      rethrow;
    } on Object {
      throw const AuthoringContentBlobStoreException(
        'history.blob_project_unavailable',
        'The history blob project root is unavailable.',
      );
    }
  }

  final String _projectRoot;

  static final Map<String, Future<void>> _inProcessLocks = {};

  @override
  Future<AuthoringContentBlobRef> put(Iterable<int> values) {
    final bytes = values.toList(growable: false);
    if (bytes.any((value) => value < 0 || value > 255)) {
      throw ArgumentError.value(values, 'bytes', 'must contain bytes');
    }
    final id = _contentId(bytes);
    return _guard(() async {
      return _withLock(() async {
        final file = await _blobFile(id);
        if (await file.exists()) {
          final existing = await file.readAsBytes();
          if (_contentId(existing) != id || !_bytesEqual(existing, bytes)) {
            throw const AuthoringContentBlobStoreException(
              'history.blob_corrupt',
              'A retained history blob failed verification.',
            );
          }
          return AuthoringContentBlobRef(id: id, byteLength: bytes.length);
        }
        final temporary = File('${file.path}.tmp');
        if (await temporary.exists()) await temporary.delete();
        final writer = await temporary.open(mode: FileMode.write);
        try {
          await writer.writeFrom(bytes);
          await writer.flush();
        } finally {
          await writer.close();
        }
        if (_contentId(await temporary.readAsBytes()) != id) {
          await temporary.delete();
          throw const AuthoringContentBlobStoreException(
            'history.blob_corrupt',
            'A retained history blob failed verification.',
          );
        }
        await temporary.rename(file.path);
        return AuthoringContentBlobRef(id: id, byteLength: bytes.length);
      });
    });
  }

  @override
  Future<List<int>?> get(String id) {
    final safeId = _blobId(id);
    return _guard(() async {
      return _withLock(() async {
        final file = await _blobFile(safeId);
        if (!await file.exists()) return null;
        final bytes = await file.readAsBytes();
        if (_contentId(bytes) != safeId) {
          throw const AuthoringContentBlobStoreException(
            'history.blob_corrupt',
            'A retained history blob failed verification.',
          );
        }
        return List<int>.unmodifiable(bytes);
      });
    });
  }

  @override
  Future<bool> contains(String id) async => await get(id) != null;

  @override
  Future<List<String>> listIds() {
    return _guard(() async {
      return _withLock(() async {
        final root = await _blobRoot();
        final ids = <String>[];
        await for (final entity in root.list(followLinks: false)) {
          if (entity is! File || !entity.path.endsWith('.blob')) {
            throw const AuthoringContentBlobStoreException(
              'history.blob_path_invalid',
              'The history blob directory contains an unsafe entry.',
            );
          }
          final name = entity.uri.pathSegments.last;
          ids.add(_blobId('sha256:${name.substring(0, name.length - 5)}'));
        }
        ids.sort();
        return List.unmodifiable(ids);
      });
    });
  }

  @override
  Future<int> prune({required Set<String> retainIds}) {
    final retained = retainIds.map(_blobId).toSet();
    return _guard(() async {
      return _withLock(() async {
        final root = await _blobRoot();
        var removed = 0;
        await for (final entity in root.list(followLinks: false)) {
          if (entity is! File || !entity.path.endsWith('.blob')) continue;
          final name = entity.uri.pathSegments.last;
          final id = _blobId('sha256:${name.substring(0, name.length - 5)}');
          if (!retained.contains(id)) {
            await entity.delete();
            removed++;
          }
        }
        return removed;
      });
    });
  }

  Future<File> _blobFile(String id) async {
    final root = await _blobRoot();
    final file = File(_join(root.path, '${id.substring(7)}.blob'));
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type != FileSystemEntityType.notFound &&
        type != FileSystemEntityType.file) {
      throw const AuthoringContentBlobStoreException(
        'history.blob_path_invalid',
        'A retained history blob path is unsafe.',
      );
    }
    return file;
  }

  Future<Directory> _blobRoot() async {
    var current = Directory(_projectRoot);
    for (final segment in const ['.pokemap', 'authoring', 'blobs']) {
      final next = Directory(_join(current.path, segment));
      final type = await FileSystemEntity.type(next.path, followLinks: false);
      if (type == FileSystemEntityType.notFound) {
        await next.create();
      } else if (type != FileSystemEntityType.directory) {
        throw const AuthoringContentBlobStoreException(
          'history.blob_path_invalid',
          'The history blob directory is unsafe.',
        );
      }
      current = next;
    }
    return current;
  }

  Future<T> _withLock<T>(Future<T> Function() operation) async {
    final previous = _inProcessLocks[_projectRoot] ?? Future<void>.value();
    final completion = Completer<void>();
    _inProcessLocks[_projectRoot] = completion.future;
    await previous;
    try {
      late final RandomAccessFile lock;
      try {
        final authoringRoot = (await _blobRoot()).parent;
        lock = await File(_join(authoringRoot.path, 'blobs.lock')).open(
          mode: FileMode.append,
        );
        await lock.lock(FileLock.exclusive);
      } on AuthoringContentBlobStoreException {
        rethrow;
      } on Object {
        throw const AuthoringContentBlobStoreException(
          'history.blob_io',
          'The history blob lock failed safely.',
        );
      }
      try {
        return await operation();
      } finally {
        try {
          await lock.unlock();
        } on Object {
          // Closing still releases the OS lock.
        }
        await lock.close();
      }
    } finally {
      completion.complete();
      if (identical(_inProcessLocks[_projectRoot], completion.future)) {
        _inProcessLocks.remove(_projectRoot);
      }
    }
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on AuthoringContentBlobStoreException {
      rethrow;
    } on Object {
      throw const AuthoringContentBlobStoreException(
        'history.blob_io',
        'The history blob store failed safely.',
      );
    }
  }
}

String _contentId(List<int> bytes) => computeAuthoringBytesFingerprint(
      bytes,
      logicalName: 'authoring-history-blob',
    );

String _blobId(String value) {
  if (!RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(value)) {
    throw ArgumentError.value(value, 'id', 'must be a SHA-256 blob identity');
  }
  return value;
}

bool _bytesEqual(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

String _join(String first, String second) =>
    [first, second].join(Platform.pathSeparator);
~~~~~~~~

## `packages/map_authoring/lib/src/history/undo_service.dart`

~~~~~~~~dart
import 'dart:convert';

import '../contracts/action_descriptor.dart';
import '../contracts/authoring_diff.dart';
import '../contracts/authoring_receipt.dart';
import '../contracts/authoring_request.dart';
import '../contracts/resource_ref.dart';
import '../ports/idempotency_store.dart';
import '../ports/transaction_file_gateway.dart';
import '../security/authoring_permission.dart';
import '../security/authorization_policy.dart';
import '../security/confirmation_token.dart';
import '../security/secure_mutation_executor.dart';
import '../support/authoring_fingerprint.dart';
import '../transactions/action_planner.dart';
import '../transactions/authoring_plan.dart';
import '../transactions/change_set.dart';
import '../transactions/journaled_transaction.dart';
import '../workspace/project_snapshot.dart';
import 'authoring_history.dart';
import 'content_blob_store.dart';
import 'history_store.dart';

final class AuthoringUndoability {
  const AuthoringUndoability({required this.undoable, this.reason});

  final bool undoable;
  final String? reason;
}

/// Frozen secure-apply context returned by history mutation planning.
final class AuthoringPreparedHistoryMutation {
  const AuthoringPreparedHistoryMutation({
    required this.actor,
    required this.projectId,
    required this.action,
    required this.plan,
    required this.currentProjectRevision,
    required this.scope,
    required this.operationId,
    this.precondition,
  });

  final AuthoringActor actor;
  final String projectId;
  final AuthoringActionDescriptor action;
  final AuthoringPlan plan;
  final String currentProjectRevision;
  final AuthoringIdempotencyScope scope;
  final String operationId;
  final AuthoringTransactionPrecondition? precondition;
}

/// Plans undo and redo as ordinary authorized forward transactions.
final class AuthoringUndoService {
  const AuthoringUndoService({
    required AuthoringHistoryStore history,
    required AuthoringContentBlobStore blobs,
    required TransactionFileGateway gateway,
    required AuthoringActionPlanner planner,
    required AuthoringAuthorizationPolicy policy,
    required SecureAuthoringMutationExecutor executor,
    required AuthoringPlanTokenFactory tokenFactory,
  })  : _history = history,
        _blobs = blobs,
        _gateway = gateway,
        _planner = planner,
        _policy = policy,
        _executor = executor,
        _tokenFactory = tokenFactory;

  final AuthoringHistoryStore _history;
  final AuthoringContentBlobStore _blobs;
  final TransactionFileGateway _gateway;
  final AuthoringActionPlanner _planner;
  final AuthoringAuthorizationPolicy _policy;
  final SecureAuthoringMutationExecutor _executor;
  final AuthoringPlanTokenFactory _tokenFactory;

  Future<AuthoringUndoability> inspectUndoability({
    required String projectId,
    required String entryId,
  }) async {
    final entry = await _requireEntry(projectId, entryId);
    final reason = entry.nonUndoableReason;
    if (reason != null) {
      return AuthoringUndoability(undoable: false, reason: reason);
    }
    for (final change in entry.changes) {
      for (final blobId in change.retainedBlobIds) {
        if (!await _blobs.contains(blobId)) {
          const missingReason = 'history.blob_missing';
          await _history.markNonUndoable(
            projectId: projectId,
            entryId: entryId,
            reason: missingReason,
          );
          return const AuthoringUndoability(
            undoable: false,
            reason: missingReason,
          );
        }
      }
    }
    return const AuthoringUndoability(undoable: true);
  }

  Future<AuthoringPreparedHistoryMutation> planUndo({
    required AuthoringActor actor,
    required String projectId,
    required String entryId,
    required ProjectSnapshot snapshot,
    required String workspaceHandle,
    required String idempotencyKey,
  }) async {
    final action = _historyAction('history.undo', 'Undo a history entry');
    final requestId = _validatedToken('request_');
    final request = _request(
      requestId: requestId,
      action: action,
      snapshot: snapshot,
      workspaceHandle: workspaceHandle,
      idempotencyKey: idempotencyKey,
      kind: AuthoringHistoryKind.undo,
      targetEntryId: entryId,
    );
    _authorizePlanning(actor, projectId, action, request);
    final entry = await _requireUndoable(projectId, entryId);
    final changeSet = await _reverseChangeSet(entry);
    return _prepare(
      actor: actor,
      projectId: projectId,
      action: action,
      request: request,
      snapshot: snapshot,
      changeSet: changeSet,
    );
  }

  Future<AuthoringPreparedHistoryMutation> planRedo({
    required AuthoringActor actor,
    required String projectId,
    required String entryId,
    required ProjectSnapshot snapshot,
    required String workspaceHandle,
    required String idempotencyKey,
  }) async {
    final action = _historyAction('history.redo', 'Redo a history entry');
    final requestId = _validatedToken('request_');
    final authorizationProbe = _request(
      requestId: requestId,
      action: action,
      snapshot: snapshot,
      workspaceHandle: workspaceHandle,
      idempotencyKey: idempotencyKey,
      kind: AuthoringHistoryKind.redo,
      targetEntryId: entryId,
      expectedHeadEntryId: List.filled(160, 'x').join(),
    );
    _authorizePlanning(actor, projectId, action, authorizationProbe);
    final latest = (await _history.list(projectId: projectId, limit: 1))
        .entries
        .firstOrNull;
    if (latest == null ||
        latest.kind != AuthoringHistoryKind.undo ||
        latest.targetEntryId != entryId) {
      throw const AuthoringHistoryException(
        'history.redo_branch_diverged',
        'Redo is unsafe because the project history has diverged.',
      );
    }
    final request = _request(
      requestId: requestId,
      action: action,
      snapshot: snapshot,
      workspaceHandle: workspaceHandle,
      idempotencyKey: idempotencyKey,
      kind: AuthoringHistoryKind.redo,
      targetEntryId: entryId,
      expectedHeadEntryId: latest.entryId,
    );
    final entry = await _requireUndoable(projectId, entryId);
    final changeSet = await _forwardChangeSet(entry);
    return _prepare(
      actor: actor,
      projectId: projectId,
      action: action,
      request: request,
      snapshot: snapshot,
      changeSet: changeSet,
      precondition: () => _requireHistoryHead(
        projectId: projectId,
        entryId: latest.entryId,
        conflictCode: 'history.redo_branch_diverged',
        conflictMessage:
            'Redo is unsafe because the project history has diverged.',
      ),
    );
  }

  Future<AuthoringReceipt> apply(
    AuthoringPreparedHistoryMutation prepared, {
    AuthoringConfirmationToken? confirmationToken,
  }) {
    return _executor.apply(
      actor: prepared.actor,
      projectId: prepared.projectId,
      action: prepared.action,
      plan: prepared.plan,
      currentProjectRevision: prepared.currentProjectRevision,
      scope: prepared.scope,
      operationId: prepared.operationId,
      confirmationToken: confirmationToken,
      precondition: prepared.precondition,
    );
  }

  Future<AuthoringHistoryEntry> _requireEntry(
    String projectId,
    String entryId,
  ) async {
    final entry = await _history.get(
      projectId: projectId,
      entryId: entryId,
    );
    if (entry == null) {
      throw const AuthoringHistoryException(
        'history.entry_missing',
        'The requested history entry does not exist.',
      );
    }
    return entry;
  }

  Future<AuthoringHistoryEntry> _requireUndoable(
    String projectId,
    String entryId,
  ) async {
    final undoability = await inspectUndoability(
      projectId: projectId,
      entryId: entryId,
    );
    if (!undoability.undoable) {
      throw AuthoringHistoryException(
        undoability.reason ?? 'history.non_undoable',
        'The requested history entry is not undoable.',
      );
    }
    return _requireEntry(projectId, entryId);
  }

  Future<AuthoringChangeSet> _reverseChangeSet(
    AuthoringHistoryEntry entry,
  ) async {
    final changes = <AuthoringResourceChange>[];
    for (final retained in entry.changes) {
      final currentRevision =
          await _gateway.readResourceRevision(retained.storageKey);
      if (currentRevision != retained.afterRevision) {
        throw const AuthoringHistoryException(
          'history.resource_changed',
          'A resource changed after the selected history entry.',
        );
      }
      changes.add(
        await _buildChange(
          entry,
          retained,
          expectedCurrentRevision: retained.afterRevision,
          targetRevision: retained.beforeRevision,
          targetBlobId: retained.beforeBlobId,
        ),
      );
    }
    return AuthoringChangeSet(
      changes: changes,
      diff: AuthoringDiff(entry.receipt.diff.entries.map(_invertDiffEntry)),
    );
  }

  Future<AuthoringChangeSet> _forwardChangeSet(
    AuthoringHistoryEntry entry,
  ) async {
    final changes = <AuthoringResourceChange>[];
    for (final retained in entry.changes) {
      final currentRevision =
          await _gateway.readResourceRevision(retained.storageKey);
      if (currentRevision != retained.beforeRevision) {
        throw const AuthoringHistoryException(
          'history.resource_changed',
          'A resource changed after the undo transaction.',
        );
      }
      changes.add(
        await _buildChange(
          entry,
          retained,
          expectedCurrentRevision: retained.beforeRevision,
          targetRevision: retained.afterRevision,
          targetBlobId: retained.afterBlobId,
        ),
      );
    }
    return AuthoringChangeSet(
      changes: changes,
      diff: entry.receipt.diff,
    );
  }

  Future<AuthoringResourceChange> _buildChange(
    AuthoringHistoryEntry entry,
    AuthoringHistoryResourceChange retained, {
    required String? expectedCurrentRevision,
    required String? targetRevision,
    required String? targetBlobId,
  }) async {
    final current = await _gateway.readResource(retained.storageKey);
    final target = targetBlobId == null ? null : await _blobs.get(targetBlobId);
    if (targetBlobId != null && target == null) {
      await _history.markNonUndoable(
        projectId: entry.projectId,
        entryId: entry.entryId,
        reason: 'history.blob_missing',
      );
      throw const AuthoringHistoryException(
        'history.blob_missing',
        'A retained history payload is unavailable.',
      );
    }
    try {
      return AuthoringResourceChange(
        resource: _resourceWithoutRevision(retained.resource),
        storageKey: retained.storageKey,
        beforeBytes: current,
        afterBytes: target,
        beforeRevision: expectedCurrentRevision,
        afterRevision: targetRevision,
      );
    } on ArgumentError {
      throw const AuthoringHistoryException(
        'history.blob_revision_mismatch',
        'A retained payload does not match its recorded resource revision.',
      );
    }
  }

  Future<AuthoringPreparedHistoryMutation> _prepare({
    required AuthoringActor actor,
    required String projectId,
    required AuthoringActionDescriptor action,
    required AuthoringRequest request,
    required ProjectSnapshot snapshot,
    required AuthoringChangeSet changeSet,
    AuthoringTransactionPrecondition? precondition,
  }) async {
    final plan = await _planner.plan(
      request: request,
      snapshot: snapshot,
      build: (_) => AuthoringMutationDraft(
        changeSet: changeSet,
        preview: const {'historyForwardTransaction': true},
      ),
    );
    return AuthoringPreparedHistoryMutation(
      actor: actor,
      projectId: projectId,
      action: action,
      plan: plan,
      currentProjectRevision: snapshot.revision,
      scope: AuthoringIdempotencyScope(
        actorId: actor.actorId,
        projectId: projectId,
        actionId: action.id,
        actionVersion: action.version,
        key: request.idempotencyKey!,
      ),
      operationId: _validatedToken('operation_'),
      precondition: precondition,
    );
  }

  Future<void> _requireHistoryHead({
    required String projectId,
    required String entryId,
    required String conflictCode,
    required String conflictMessage,
  }) async {
    final page = await _history.list(projectId: projectId, limit: 1);
    if (page.entries.isEmpty || page.entries.single.entryId != entryId) {
      throw AuthoringHistoryException(conflictCode, conflictMessage);
    }
  }

  AuthoringRequest _request({
    required String requestId,
    required AuthoringActionDescriptor action,
    required ProjectSnapshot snapshot,
    required String workspaceHandle,
    required String idempotencyKey,
    required AuthoringHistoryKind kind,
    required String targetEntryId,
    String? expectedHeadEntryId,
  }) {
    return AuthoringRequest(
      requestId: requestId,
      actionId: action.id,
      actionVersion: action.version,
      workspaceHandle: workspaceHandle,
      parameters: {
        'targetEntryId': targetEntryId,
        if (expectedHeadEntryId != null)
          'expectedHeadEntryId': expectedHeadEntryId,
      },
      expectedRevision: snapshot.revision,
      idempotencyKey: idempotencyKey,
      extensions: {
        'history': AuthoringHistoryContext(
          kind: kind,
          targetEntryId: targetEntryId,
          expectedHeadEntryId: expectedHeadEntryId,
        ).toJson(),
      },
    );
  }

  void _authorizePlanning(
    AuthoringActor actor,
    String projectId,
    AuthoringActionDescriptor action,
    AuthoringRequest request,
  ) {
    _policy.authorize(
      AuthoringAuthorizationRequest(
        actor: actor,
        projectId: projectId,
        operation: AuthoringSecurityOperation.plan,
        actionId: action.id,
        actionVersion: action.version,
        riskLevel: action.riskLevel,
        requestBytes:
            utf8.encode(canonicalAuthoringJson(request.toJson())).length,
        touchedResources: 0,
      ),
    );
  }

  String _validatedToken(String prefix) {
    final value = _tokenFactory(prefix);
    if (!value.startsWith(prefix) || value.length <= prefix.length) {
      throw ArgumentError.value(
        value,
        'tokenFactory',
        'must return an opaque token beginning with $prefix',
      );
    }
    return value;
  }
}

AuthoringActionDescriptor _historyAction(String id, String summary) =>
    AuthoringActionDescriptor(
      id: id,
      version: 1,
      summary: summary,
      inputSchemaId: 'schema.$id.input.v1',
      outputSchemaId: 'schema.authoringReceipt.v1',
      riskLevel: AuthoringRiskLevel.medium,
      requiredPermissions: const [AuthoringPermission.projectWrite],
      guarantees: const [
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable,
      ],
    );

AuthoringResourceRef _resourceWithoutRevision(AuthoringResourceRef source) =>
    AuthoringResourceRef(
      kind: source.kind,
      id: source.id,
      extensions: source.extensions,
    );

AuthoringDiffEntry _invertDiffEntry(AuthoringDiffEntry source) {
  final operation = switch (source.operation) {
    AuthoringDiffOperation.add => AuthoringDiffOperation.remove,
    AuthoringDiffOperation.remove => AuthoringDiffOperation.add,
    AuthoringDiffOperation.link => AuthoringDiffOperation.unlink,
    AuthoringDiffOperation.unlink => AuthoringDiffOperation.link,
    AuthoringDiffOperation.replace => AuthoringDiffOperation.replace,
    AuthoringDiffOperation.move => AuthoringDiffOperation.move,
  };
  return _diffEntry(
    operation: operation,
    resource: source.resource,
    path: source.path,
    hasBefore: source.hasAfter,
    before: source.after,
    hasAfter: source.hasBefore,
    after: source.before,
    extensions: source.extensions,
  );
}

AuthoringDiffEntry _diffEntry({
  required AuthoringDiffOperation operation,
  required AuthoringResourceRef resource,
  required String path,
  required bool hasBefore,
  required Object? before,
  required bool hasAfter,
  required Object? after,
  required Map<String, Object?> extensions,
}) {
  if (hasBefore && hasAfter) {
    return AuthoringDiffEntry(
      operation: operation,
      resource: resource,
      path: path,
      before: before,
      after: after,
      extensions: extensions,
    );
  }
  if (hasBefore) {
    return AuthoringDiffEntry(
      operation: operation,
      resource: resource,
      path: path,
      before: before,
      extensions: extensions,
    );
  }
  if (hasAfter) {
    return AuthoringDiffEntry(
      operation: operation,
      resource: resource,
      path: path,
      after: after,
      extensions: extensions,
    );
  }
  return AuthoringDiffEntry(
    operation: operation,
    resource: resource,
    path: path,
    extensions: extensions,
  );
}
~~~~~~~~

## `packages/map_authoring/lib/src/history/revision_revert_service.dart`

~~~~~~~~dart
import 'dart:convert';

import '../contracts/action_descriptor.dart';
import '../contracts/authoring_diff.dart';
import '../contracts/authoring_receipt.dart';
import '../contracts/authoring_request.dart';
import '../contracts/resource_ref.dart';
import '../ports/idempotency_store.dart';
import '../ports/transaction_file_gateway.dart';
import '../security/authoring_permission.dart';
import '../security/authorization_policy.dart';
import '../security/confirmation_token.dart';
import '../security/secure_mutation_executor.dart';
import '../support/authoring_fingerprint.dart';
import '../transactions/action_planner.dart';
import '../transactions/authoring_plan.dart';
import '../transactions/change_set.dart';
import '../workspace/project_snapshot.dart';
import 'authoring_history.dart';
import 'content_blob_store.dart';
import 'history_store.dart';
import 'undo_service.dart';

/// Plans a forward transaction that restores one retained historical state.
final class AuthoringRevisionRevertService {
  const AuthoringRevisionRevertService({
    required AuthoringHistoryStore history,
    required AuthoringContentBlobStore blobs,
    required TransactionFileGateway gateway,
    required AuthoringActionPlanner planner,
    required AuthoringAuthorizationPolicy policy,
    required SecureAuthoringMutationExecutor executor,
    required AuthoringPlanTokenFactory tokenFactory,
  })  : _history = history,
        _blobs = blobs,
        _gateway = gateway,
        _planner = planner,
        _policy = policy,
        _executor = executor,
        _tokenFactory = tokenFactory;

  final AuthoringHistoryStore _history;
  final AuthoringContentBlobStore _blobs;
  final TransactionFileGateway _gateway;
  final AuthoringActionPlanner _planner;
  final AuthoringAuthorizationPolicy _policy;
  final SecureAuthoringMutationExecutor _executor;
  final AuthoringPlanTokenFactory _tokenFactory;

  Future<AuthoringPreparedHistoryMutation> planRevert({
    required AuthoringActor actor,
    required String projectId,
    required String targetEntryId,
    required String expectedHeadEntryId,
    required ProjectSnapshot snapshot,
    required String workspaceHandle,
    required String idempotencyKey,
  }) async {
    final action = _revertAction();
    final request = AuthoringRequest(
      requestId: _validatedToken('request_'),
      actionId: action.id,
      actionVersion: action.version,
      workspaceHandle: workspaceHandle,
      parameters: {
        'targetEntryId': targetEntryId,
        'expectedHeadEntryId': expectedHeadEntryId,
      },
      expectedRevision: snapshot.revision,
      idempotencyKey: idempotencyKey,
      extensions: {
        'history': AuthoringHistoryContext(
          kind: AuthoringHistoryKind.revert,
          targetEntryId: targetEntryId,
          expectedHeadEntryId: expectedHeadEntryId,
        ).toJson(),
      },
    );
    _policy.authorize(
      AuthoringAuthorizationRequest(
        actor: actor,
        projectId: projectId,
        operation: AuthoringSecurityOperation.plan,
        actionId: action.id,
        actionVersion: action.version,
        riskLevel: action.riskLevel,
        requestBytes:
            utf8.encode(canonicalAuthoringJson(request.toJson())).length,
        touchedResources: 0,
      ),
    );

    final headPage = await _history.list(projectId: projectId, limit: 1);
    if (headPage.entries.isEmpty ||
        headPage.entries.single.entryId != expectedHeadEntryId) {
      throw const AuthoringHistoryException(
        'history.head_stale',
        'The current history head differs from the expected head.',
      );
    }
    final target = await _requireTarget(projectId, targetEntryId);
    final changeSet = await _buildRevertChangeSet(target);
    final plan = await _planner.plan(
      request: request,
      snapshot: snapshot,
      build: (_) => AuthoringMutationDraft(
        changeSet: changeSet,
        preview: const {'historyForwardTransaction': true},
      ),
    );
    return AuthoringPreparedHistoryMutation(
      actor: actor,
      projectId: projectId,
      action: action,
      plan: plan,
      currentProjectRevision: snapshot.revision,
      scope: AuthoringIdempotencyScope(
        actorId: actor.actorId,
        projectId: projectId,
        actionId: action.id,
        actionVersion: action.version,
        key: idempotencyKey,
      ),
      operationId: _validatedToken('operation_'),
      precondition: () => _requireHistoryHead(
        projectId: projectId,
        expectedHeadEntryId: expectedHeadEntryId,
      ),
    );
  }

  Future<AuthoringReceipt> apply(
    AuthoringPreparedHistoryMutation prepared, {
    AuthoringConfirmationToken? confirmationToken,
  }) {
    return _executor.apply(
      actor: prepared.actor,
      projectId: prepared.projectId,
      action: prepared.action,
      plan: prepared.plan,
      currentProjectRevision: prepared.currentProjectRevision,
      scope: prepared.scope,
      operationId: prepared.operationId,
      confirmationToken: confirmationToken,
      precondition: prepared.precondition,
    );
  }

  Future<void> _requireHistoryHead({
    required String projectId,
    required String expectedHeadEntryId,
  }) async {
    final page = await _history.list(projectId: projectId, limit: 1);
    if (page.entries.isEmpty ||
        page.entries.single.entryId != expectedHeadEntryId) {
      throw const AuthoringHistoryException(
        'history.head_stale',
        'The current history head differs from the expected head.',
      );
    }
  }

  Future<AuthoringHistoryEntry> _requireTarget(
    String projectId,
    String entryId,
  ) async {
    final entry = await _history.get(
      projectId: projectId,
      entryId: entryId,
    );
    if (entry == null) {
      throw const AuthoringHistoryException(
        'history.entry_missing',
        'The requested history entry does not exist.',
      );
    }
    if (entry.nonUndoableReason != null) {
      throw AuthoringHistoryException(
        entry.nonUndoableReason!,
        'The selected history state is no longer retained.',
      );
    }
    for (final change in entry.changes) {
      for (final blobId in change.retainedBlobIds) {
        if (!await _blobs.contains(blobId)) {
          await _history.markNonUndoable(
            projectId: projectId,
            entryId: entryId,
            reason: 'history.blob_missing',
          );
          throw const AuthoringHistoryException(
            'history.blob_missing',
            'A retained history payload is unavailable.',
          );
        }
      }
    }
    return entry;
  }

  Future<AuthoringChangeSet> _buildRevertChangeSet(
    AuthoringHistoryEntry target,
  ) async {
    final changes = <AuthoringResourceChange>[];
    final diff = <AuthoringDiffEntry>[];
    for (final retained in target.changes) {
      final currentRevision =
          await _gateway.readResourceRevision(retained.storageKey);
      if (currentRevision == retained.afterRevision) continue;
      final current = await _gateway.readResource(retained.storageKey);
      final targetBytes = retained.afterBlobId == null
          ? null
          : await _blobs.get(retained.afterBlobId!);
      if (retained.afterBlobId != null && targetBytes == null) {
        await _history.markNonUndoable(
          projectId: target.projectId,
          entryId: target.entryId,
          reason: 'history.blob_missing',
        );
        throw const AuthoringHistoryException(
          'history.blob_missing',
          'A retained history payload is unavailable.',
        );
      }
      final resource = AuthoringResourceRef(
        kind: retained.resource.kind,
        id: retained.resource.id,
        extensions: retained.resource.extensions,
      );
      try {
        changes.add(
          AuthoringResourceChange(
            resource: resource,
            storageKey: retained.storageKey,
            beforeBytes: current,
            afterBytes: targetBytes,
            beforeRevision: currentRevision,
            afterRevision: retained.afterRevision,
          ),
        );
      } on ArgumentError {
        throw const AuthoringHistoryException(
          'history.blob_revision_mismatch',
          'A retained payload does not match its recorded resource revision.',
        );
      }
      diff.add(
        _revisionDiff(
          resource,
          beforeRevision: currentRevision,
          afterRevision: retained.afterRevision,
        ),
      );
    }
    if (changes.isEmpty) {
      throw const AuthoringHistoryException(
        'history.revert_noop',
        'The project already matches the selected retained state.',
      );
    }
    return AuthoringChangeSet(changes: changes, diff: AuthoringDiff(diff));
  }

  String _validatedToken(String prefix) {
    final value = _tokenFactory(prefix);
    if (!value.startsWith(prefix) || value.length <= prefix.length) {
      throw ArgumentError.value(
        value,
        'tokenFactory',
        'must return an opaque token beginning with $prefix',
      );
    }
    return value;
  }
}

AuthoringActionDescriptor _revertAction() => AuthoringActionDescriptor(
      id: 'history.revert',
      version: 1,
      summary: 'Revert resources to a retained history state',
      inputSchemaId: 'schema.history.revert.input.v1',
      outputSchemaId: 'schema.authoringReceipt.v1',
      riskLevel: AuthoringRiskLevel.medium,
      requiredPermissions: const [AuthoringPermission.projectWrite],
      guarantees: const [
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable,
      ],
    );

AuthoringDiffEntry _revisionDiff(
  AuthoringResourceRef resource, {
  required String? beforeRevision,
  required String? afterRevision,
}) {
  if (beforeRevision == null) {
    return AuthoringDiffEntry(
      operation: AuthoringDiffOperation.add,
      resource: resource,
      path: r'$',
      after: afterRevision,
    );
  }
  if (afterRevision == null) {
    return AuthoringDiffEntry(
      operation: AuthoringDiffOperation.remove,
      resource: resource,
      path: r'$',
      before: beforeRevision,
    );
  }
  return AuthoringDiffEntry(
    operation: AuthoringDiffOperation.replace,
    resource: resource,
    path: r'$',
    before: beforeRevision,
    after: afterRevision,
  );
}
~~~~~~~~

## `packages/map_authoring/lib/src/transactions/batch_executor.dart`

~~~~~~~~dart
import '../contracts/authoring_diff.dart';
import '../contracts/resource_ref.dart';
import '../support/authoring_fingerprint.dart';
import 'change_set.dart';

final class AuthoringBatchException implements Exception {
  const AuthoringBatchException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'AuthoringBatchException($code): $message';
}

/// Pure deterministic composition for independently planned mutations.
final class AuthoringBatchExecutor {
  const AuthoringBatchExecutor();

  AuthoringChangeSet combine(Iterable<AuthoringChangeSet> changeSets) {
    final inputs = changeSets.toList(growable: false);
    if (inputs.isEmpty) {
      throw const AuthoringBatchException(
        'batch.empty',
        'A mutation batch must contain at least one change set.',
      );
    }

    final changesByResource = <String, AuthoringResourceChange>{};
    final changesByStorageKey = <String, AuthoringResourceChange>{};
    final diffSignatureByResource = <String, String>{};
    final diffByIdentity = <String, AuthoringDiffEntry>{};
    for (final input in inputs) {
      final currentDiffByResource = <String, List<AuthoringDiffEntry>>{};
      for (final entry in input.diff.entries) {
        currentDiffByResource
            .putIfAbsent(_resourceKey(entry.resource), () => [])
            .add(entry);
      }
      for (final change in input.changes) {
        final resourceKey = _resourceKey(change.resource);
        final resourceOverlap = changesByResource[resourceKey];
        final storageOverlap = changesByStorageKey[change.storageKey];
        final diffSignature = canonicalAuthoringJson([
          for (final entry in currentDiffByResource[resourceKey]!)
            entry.toJson(),
        ]);
        if ((resourceOverlap != null &&
                !_sameChange(resourceOverlap, change)) ||
            (storageOverlap != null && !_sameChange(storageOverlap, change)) ||
            (diffSignatureByResource[resourceKey] != null &&
                diffSignatureByResource[resourceKey] != diffSignature)) {
          throw const AuthoringBatchException(
            'batch.overlap_conflict',
            'A batch contains incompatible overlapping resource changes.',
          );
        }
        changesByResource[resourceKey] = change;
        changesByStorageKey[change.storageKey] = change;
        diffSignatureByResource[resourceKey] = diffSignature;
      }
      for (final entry in input.diff.entries) {
        final identity = canonicalAuthoringJson(entry.toJson());
        diffByIdentity[identity] = entry;
      }
    }

    return AuthoringChangeSet(
      changes: changesByResource.values,
      diff: AuthoringDiff(diffByIdentity.values),
    );
  }
}

String _resourceKey(AuthoringResourceRef resource) =>
    '${resource.kind}\u0000${resource.id}';

bool _sameChange(
  AuthoringResourceChange left,
  AuthoringResourceChange right,
) {
  return _resourceKey(left.resource) == _resourceKey(right.resource) &&
      canonicalAuthoringJson(left.resource.toJson()) ==
          canonicalAuthoringJson(right.resource.toJson()) &&
      left.storageKey == right.storageKey &&
      left.beforeRevision == right.beforeRevision &&
      left.afterRevision == right.afterRevision &&
      _sameBytes(left.beforeBytes, right.beforeBytes) &&
      _sameBytes(left.afterBytes, right.afterBytes);
}

bool _sameBytes(List<int>? left, List<int>? right) {
  if (identical(left, right)) return true;
  if (left == null || right == null || left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
~~~~~~~~

## `packages/map_authoring/lib/src/registry/mutation_registry.dart`

~~~~~~~~dart
import '../contracts/action_descriptor.dart';

enum MutationContractProof {
  plan,
  dryRun,
  staleCas,
  idempotency,
  recovery,
  authorization,
  receipt,
  undo,
  nonUndoablePolicy,
}

final class MutationContractEvidence {
  MutationContractEvidence({
    required Iterable<MutationContractProof> proofs,
    String? nonUndoableReason,
  })  : proofs = Set.unmodifiable(proofs),
        nonUndoableReason = nonUndoableReason == null
            ? null
            : _stableReason(nonUndoableReason) {
    if (this.proofs.contains(MutationContractProof.nonUndoablePolicy) !=
        (this.nonUndoableReason != null)) {
      throw ArgumentError(
        'A non-undoable policy proof and its stable reason are inseparable.',
      );
    }
    if (this.proofs.contains(MutationContractProof.undo) &&
        this.proofs.contains(MutationContractProof.nonUndoablePolicy)) {
      throw ArgumentError(
        'A mutation cannot be both undoable and explicitly non-undoable.',
      );
    }
  }

  static const Set<MutationContractProof> mandatoryCore = {
    MutationContractProof.plan,
    MutationContractProof.dryRun,
    MutationContractProof.staleCas,
    MutationContractProof.idempotency,
    MutationContractProof.recovery,
    MutationContractProof.authorization,
    MutationContractProof.receipt,
  };

  final Set<MutationContractProof> proofs;
  final String? nonUndoableReason;
}

final class MutationRegistryException implements Exception {
  const MutationRegistryException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'MutationRegistryException($code): $message';
}

/// Admission gate preventing partially safe mutation actions from shipping.
final class AuthoringMutationRegistry {
  final Map<String, _RegisteredMutation> _registered = {};

  void register({
    required AuthoringActionDescriptor descriptor,
    required MutationContractEvidence evidence,
  }) {
    final missing = MutationContractEvidence.mandatoryCore
        .difference(evidence.proofs)
        .toList()
      ..sort((left, right) => left.name.compareTo(right.name));
    if (missing.isNotEmpty) {
      throw MutationRegistryException(
        'mutation.contract_incomplete',
        'Mutation evidence is missing: ${missing.map((item) => item.name).join(', ')}.',
      );
    }
    if (!evidence.proofs.contains(MutationContractProof.undo) &&
        !evidence.proofs.contains(MutationContractProof.nonUndoablePolicy)) {
      throw const MutationRegistryException(
        'mutation.undo_policy_missing',
        'Mutation evidence must prove undo or an explicit non-undoable policy.',
      );
    }
    if (descriptor.riskLevel == AuthoringRiskLevel.readOnly) {
      throw const MutationRegistryException(
        'mutation.read_only_descriptor',
        'A mutation cannot use a read-only action descriptor.',
      );
    }
    final key = '${descriptor.id}@${descriptor.version}';
    if (_registered.containsKey(key)) {
      throw const MutationRegistryException(
        'mutation.already_registered',
        'The mutation action version is already registered.',
      );
    }
    _registered[key] = _RegisteredMutation(descriptor, evidence);
  }

  List<AuthoringActionDescriptor> get actions => List.unmodifiable(
        _registered.values.map((entry) => entry.descriptor).toList()
          ..sort((left, right) {
            final idOrder = left.id.compareTo(right.id);
            return idOrder != 0
                ? idOrder
                : left.version.compareTo(right.version);
          }),
      );

  MutationContractEvidence? evidenceFor(String actionId, int version) =>
      _registered['$actionId@$version']?.evidence;
}

final class _RegisteredMutation {
  const _RegisteredMutation(this.descriptor, this.evidence);

  final AuthoringActionDescriptor descriptor;
  final MutationContractEvidence evidence;
}

String _stableReason(String value) {
  if (!RegExp(r'^[a-z][a-z0-9_.-]*$').hasMatch(value)) {
    throw ArgumentError.value(
      value,
      'nonUndoableReason',
      'must be a stable safe code',
    );
  }
  return value;
}
~~~~~~~~

## `packages/map_authoring/test/history/undo_redo_contract_test.dart`

~~~~~~~~dart
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/transaction_test_fixture.dart';

void main() {
  group('AuthoringUndoService', () {
    test('undo and redo are new secure CAS-checked idempotent transactions',
        () async {
      final harness = await _HistoryHarness.create();
      addTearDown(harness.dispose);
      final original = await harness.applyOriginal();

      final undoPlan = await harness.undo.planUndo(
        actor: harness.actor,
        projectId: harness.projectId,
        entryId: original.receiptId,
        snapshot: harness.snapshot(original.afterRevision!),
        workspaceHandle: 'workspace:history',
        idempotencyKey: 'idem-history-undo',
      );
      final undoReceipt = await harness.undo.apply(undoPlan);
      final undoReplay = await harness.undo.apply(undoPlan);
      expect(undoReplay.toJson(), undoReceipt.toJson());
      await harness.expectBeforeState();

      final redoPlan = await harness.undo.planRedo(
        actor: harness.actor,
        projectId: harness.projectId,
        entryId: original.receiptId,
        snapshot: harness.snapshot(undoReceipt.afterRevision!),
        workspaceHandle: 'workspace:history',
        idempotencyKey: 'idem-history-redo',
      );
      final redoReceipt = await harness.undo.apply(redoPlan);
      expect(redoReceipt.status, AuthoringReceiptStatus.applied);
      await harness.expectAfterState();

      final history = await harness.history.list(
        projectId: harness.projectId,
        limit: 10,
      );
      expect(
        history.entries.map((entry) => entry.kind),
        [
          AuthoringHistoryKind.redo,
          AuthoringHistoryKind.undo,
          AuthoringHistoryKind.mutation,
        ],
      );
      expect(history.entries[1].targetEntryId, original.receiptId);
      expect(history.entries[0].targetEntryId, original.receiptId);
    });

    test('refuses external changes and persists pruned-blob non-undoability',
        () async {
      final changed = await _HistoryHarness.create();
      addTearDown(changed.dispose);
      final original = await changed.applyOriginal();
      await File(
        _join(changed.base.projectDirectory.path, 'data', 'a.json'),
      ).writeAsString('{"external":true}');

      await expectLater(
        () => changed.undo.planUndo(
          actor: changed.actor,
          projectId: changed.projectId,
          entryId: original.receiptId,
          snapshot: changed.snapshot(original.afterRevision!),
          workspaceHandle: 'workspace:history',
          idempotencyKey: 'idem-history-conflict',
        ),
        _throwsHistory('history.resource_changed'),
      );

      final pruned = await _HistoryHarness.create();
      addTearDown(pruned.dispose);
      final prunedOriginal = await pruned.applyOriginal();
      await pruned.blobs.prune(retainIds: const {});
      final undoability = await pruned.undo.inspectUndoability(
        projectId: pruned.projectId,
        entryId: prunedOriginal.receiptId,
      );
      expect(undoability.undoable, isFalse);
      expect(undoability.reason, 'history.blob_missing');
      expect(
        (await pruned.history.get(
          projectId: pruned.projectId,
          entryId: prunedOriginal.receiptId,
        ))!
            .nonUndoableReason,
        'history.blob_missing',
      );
    });

    test('cannot apply an undo without project write permission', () async {
      final harness = await _HistoryHarness.create();
      addTearDown(harness.dispose);
      final original = await harness.applyOriginal();
      final readOnlyActor = AuthoringActor(actorId: harness.actor.actorId);
      final plan = await harness.undo.planUndo(
        actor: readOnlyActor,
        projectId: harness.projectId,
        entryId: original.receiptId,
        snapshot: harness.snapshot(original.afterRevision!),
        workspaceHandle: 'workspace:history',
        idempotencyKey: 'idem-history-denied',
      );

      await expectLater(
        () => harness.undo.apply(plan),
        throwsA(
          isA<AuthoringAuthorizationException>().having(
            (error) => error.code,
            'code',
            'authorization.permission_denied',
          ),
        ),
      );
      await harness.expectAfterState();
    });

    test('invalidates a redo when a branch appears after planning', () async {
      final harness = await _HistoryHarness.create();
      addTearDown(harness.dispose);
      final original = await harness.applyOriginal();
      final undoPlan = await harness.undo.planUndo(
        actor: harness.actor,
        projectId: harness.projectId,
        entryId: original.receiptId,
        snapshot: harness.snapshot(original.afterRevision!),
        workspaceHandle: 'workspace:history',
        idempotencyKey: 'idem-history-pre-redo',
      );
      final undoReceipt = await harness.undo.apply(undoPlan);
      final redoPlan = await harness.undo.planRedo(
        actor: harness.actor,
        projectId: harness.projectId,
        entryId: original.receiptId,
        snapshot: harness.snapshot(undoReceipt.afterRevision!),
        workspaceHandle: 'workspace:history',
        idempotencyKey: 'idem-history-racing-redo',
      );
      await harness.history.append(
        _divergentEntry(harness.projectId, 'redo'),
      );

      await expectLater(
        () => harness.undo.apply(redoPlan),
        _throwsHistory('history.redo_branch_diverged'),
      );
      await harness.expectBeforeState();
    });

    test('recovery also refuses a redo after a divergent branch', () async {
      var interruptRedo = false;
      final harness = await _HistoryHarness.create(
        faultInjector: (context) {
          if (interruptRedo &&
              context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterReservation) {
            throw const AuthoringTransactionSimulatedCrash();
          }
        },
      );
      addTearDown(harness.dispose);
      final original = await harness.applyOriginal();
      final undoPlan = await harness.undo.planUndo(
        actor: harness.actor,
        projectId: harness.projectId,
        entryId: original.receiptId,
        snapshot: harness.snapshot(original.afterRevision!),
        workspaceHandle: 'workspace:history',
        idempotencyKey: 'idem-history-recovery-undo',
      );
      final undoReceipt = await harness.undo.apply(undoPlan);
      final redoPlan = await harness.undo.planRedo(
        actor: harness.actor,
        projectId: harness.projectId,
        entryId: original.receiptId,
        snapshot: harness.snapshot(undoReceipt.afterRevision!),
        workspaceHandle: 'workspace:history',
        idempotencyKey: 'idem-history-recovery-redo',
      );
      interruptRedo = true;
      await expectLater(
        () => harness.undo.apply(redoPlan),
        throwsA(isA<AuthoringTransactionSimulatedCrash>()),
      );
      await harness.history.append(
        _divergentEntry(harness.projectId, 'recovery'),
      );
      final recovery = AuthoringRecoveryService(
        gateway: harness.base.gateway,
        idempotency: harness.base.ledger,
        clock: () => harness.base.now,
        commitHook: harness.recorder,
      );

      await expectLater(
        () => recovery.resume(redoPlan.operationId),
        _throwsHistory('history.redo_branch_diverged'),
      );
      await harness.expectBeforeState();
    });

    test('recovery completes a redo while its expected head is unchanged',
        () async {
      var interruptRedo = false;
      final harness = await _HistoryHarness.create(
        faultInjector: (context) {
          if (interruptRedo &&
              context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterReservation) {
            throw const AuthoringTransactionSimulatedCrash();
          }
        },
      );
      addTearDown(harness.dispose);
      final original = await harness.applyOriginal();
      final undoPlan = await harness.undo.planUndo(
        actor: harness.actor,
        projectId: harness.projectId,
        entryId: original.receiptId,
        snapshot: harness.snapshot(original.afterRevision!),
        workspaceHandle: 'workspace:history',
        idempotencyKey: 'idem-history-positive-recovery-undo',
      );
      final undoReceipt = await harness.undo.apply(undoPlan);
      final redoPlan = await harness.undo.planRedo(
        actor: harness.actor,
        projectId: harness.projectId,
        entryId: original.receiptId,
        snapshot: harness.snapshot(undoReceipt.afterRevision!),
        workspaceHandle: 'workspace:history',
        idempotencyKey: 'idem-history-positive-recovery-redo',
      );
      interruptRedo = true;
      await expectLater(
        () => harness.undo.apply(redoPlan),
        throwsA(isA<AuthoringTransactionSimulatedCrash>()),
      );
      final recovery = AuthoringRecoveryService(
        gateway: harness.base.gateway,
        idempotency: harness.base.ledger,
        clock: () => harness.base.now,
        commitHook: harness.recorder,
      );

      final receipt = await recovery.resume(redoPlan.operationId);
      expect(receipt.status, AuthoringReceiptStatus.recovered);
      await harness.expectAfterState();
      expect(
        (await harness.history.list(
          projectId: harness.projectId,
          limit: 1,
        ))
            .entries
            .single
            .kind,
        AuthoringHistoryKind.redo,
      );
    });
  });

  group('AuthoringRevisionRevertService', () {
    test('revert is forward-only, head-checked, and invalidates redo',
        () async {
      final harness = await _HistoryHarness.create();
      addTearDown(harness.dispose);
      final original = await harness.applyOriginal();

      await expectLater(
        () => harness.revert.planRevert(
          actor: harness.actor,
          projectId: harness.projectId,
          targetEntryId: original.receiptId,
          expectedHeadEntryId: 'receipt-stale',
          snapshot: harness.snapshot(original.afterRevision!),
          workspaceHandle: 'workspace:history',
          idempotencyKey: 'idem-stale-revert',
        ),
        _throwsHistory('history.head_stale'),
      );

      final undoPlan = await harness.undo.planUndo(
        actor: harness.actor,
        projectId: harness.projectId,
        entryId: original.receiptId,
        snapshot: harness.snapshot(original.afterRevision!),
        workspaceHandle: 'workspace:history',
        idempotencyKey: 'idem-before-revert',
      );
      final undoReceipt = await harness.undo.apply(undoPlan);
      final head = (await harness.history.list(
        projectId: harness.projectId,
        limit: 1,
      ))
          .entries
          .single;

      final revertPlan = await harness.revert.planRevert(
        actor: harness.actor,
        projectId: harness.projectId,
        targetEntryId: original.receiptId,
        expectedHeadEntryId: head.entryId,
        snapshot: harness.snapshot(undoReceipt.afterRevision!),
        workspaceHandle: 'workspace:history',
        idempotencyKey: 'idem-history-revert',
      );
      await harness.revert.apply(revertPlan);
      await harness.expectAfterState();

      await expectLater(
        () => harness.undo.planRedo(
          actor: harness.actor,
          projectId: harness.projectId,
          entryId: original.receiptId,
          snapshot: harness.snapshot(revertPlan.plan.projectedRevision),
          workspaceHandle: 'workspace:history',
          idempotencyKey: 'idem-diverged-redo',
        ),
        _throwsHistory('history.redo_branch_diverged'),
      );
      expect(
        (await harness.history.list(
          projectId: harness.projectId,
          limit: 1,
        ))
            .entries
            .single
            .kind,
        AuthoringHistoryKind.revert,
      );
    });

    test('refuses a revert when the head changes after planning', () async {
      final harness = await _HistoryHarness.create();
      addTearDown(harness.dispose);
      final original = await harness.applyOriginal();
      final undoPlan = await harness.undo.planUndo(
        actor: harness.actor,
        projectId: harness.projectId,
        entryId: original.receiptId,
        snapshot: harness.snapshot(original.afterRevision!),
        workspaceHandle: 'workspace:history',
        idempotencyKey: 'idem-history-pre-racing-revert',
      );
      final undoReceipt = await harness.undo.apply(undoPlan);
      final head = (await harness.history.list(
        projectId: harness.projectId,
        limit: 1,
      ))
          .entries
          .single;
      final revertPlan = await harness.revert.planRevert(
        actor: harness.actor,
        projectId: harness.projectId,
        targetEntryId: original.receiptId,
        expectedHeadEntryId: head.entryId,
        snapshot: harness.snapshot(undoReceipt.afterRevision!),
        workspaceHandle: 'workspace:history',
        idempotencyKey: 'idem-history-racing-revert',
      );
      await harness.history.append(
        _divergentEntry(harness.projectId, 'revert'),
      );

      await expectLater(
        () => harness.revert.apply(revertPlan),
        _throwsHistory('history.head_stale'),
      );
      await harness.expectBeforeState();
    });
  });
}

AuthoringHistoryEntry _divergentEntry(String projectId, String suffix) {
  final resource = AuthoringResourceRef(kind: 'fixture', id: 'branch-$suffix');
  final before = _fingerprint(suffix.codeUnitAt(0));
  final after = _fingerprint(suffix.codeUnitAt(0) + 1);
  final receipt = AuthoringReceipt(
    receiptId: 'receipt-divergent-$suffix',
    requestId: 'request-divergent-$suffix',
    actionId: 'fixture.branch',
    actionVersion: 1,
    status: AuthoringReceiptStatus.applied,
    beforeRevision: before,
    afterRevision: after,
    createdAtUtc: DateTime.utc(2026, 7, 31, 15).toIso8601String(),
    diff: AuthoringDiff([
      AuthoringDiffEntry(
        operation: AuthoringDiffOperation.replace,
        resource: resource,
        path: r'$.value',
        before: 0,
        after: 1,
      ),
    ]),
  );
  return AuthoringHistoryEntry(
    entryId: receipt.receiptId,
    projectId: projectId,
    actorId: 'actor-divergent',
    planId: 'plan-divergent-$suffix',
    operationId: 'operation-divergent-$suffix',
    kind: AuthoringHistoryKind.mutation,
    receipt: receipt,
    committedAt: DateTime.utc(2026, 7, 31, 15),
    changes: [
      AuthoringHistoryResourceChange(
        resource: resource,
        storageKey: 'data/branch-$suffix.json',
        beforeRevision: before,
        afterRevision: after,
        beforeBlobId: _fingerprint(suffix.codeUnitAt(0) + 2),
        afterBlobId: _fingerprint(suffix.codeUnitAt(0) + 3),
      ),
    ],
  );
}

String _fingerprint(int seed) =>
    'sha256:${seed.toRadixString(16).padLeft(64, '0').substring(0, 64)}';

final class _HistoryHarness {
  _HistoryHarness._({
    required this.base,
    required this.history,
    required this.blobs,
    required this.actor,
    required this.recorder,
    required this.executor,
    required this.undo,
    required this.revert,
  });

  static Future<_HistoryHarness> create({
    AuthoringTransactionFaultInjector? faultInjector,
  }) async {
    final base = await TransactionTestHarness.create();
    final history = await FileAuthoringHistoryStore.open(
      projectRoot: base.projectDirectory.path,
    );
    final blobs = await FileAuthoringContentBlobStore.open(
      projectRoot: base.projectDirectory.path,
    );
    final recorder = AuthoringHistoryRecorder(store: history, blobs: blobs);
    final transaction = JournaledAuthoringTransaction(
      plans: base.planStore,
      gateway: base.gateway,
      idempotency: base.ledger,
      clock: () => base.now,
      commitHook: recorder,
      faultInjector: faultInjector,
    );
    final confirmations = AuthoringConfirmationStore(clock: () => base.now);
    final policy = AuthoringAuthorizationPolicy(
      confirmations: confirmations,
      clock: () => base.now,
    );
    final audit = await FileAuthoringAuditLog.open(
      projectRoot: base.projectDirectory.path,
    );
    var auditId = 0;
    final executor = SecureAuthoringMutationExecutor(
      transaction: transaction,
      policy: policy,
      auditLog: audit,
      clock: () => base.now,
      auditIdFactory: () => 'audit-history-${auditId++}',
    );
    var token = 0;
    String tokenFactory(String prefix) => '$prefix${token++}';
    final planner = AuthoringActionPlanner(
      store: base.planStore,
      tokenFactory: tokenFactory,
      seedFactory: () => 9001,
    );
    final actor = AuthoringActor(
      actorId: base.scope.actorId,
      permissions: const [
        AuthoringPermissionScope.projectRead,
        AuthoringPermissionScope.projectWrite,
      ],
    );
    final undo = AuthoringUndoService(
      history: history,
      blobs: blobs,
      gateway: base.gateway,
      planner: planner,
      policy: policy,
      executor: executor,
      tokenFactory: tokenFactory,
    );
    final revert = AuthoringRevisionRevertService(
      history: history,
      blobs: blobs,
      gateway: base.gateway,
      planner: planner,
      policy: policy,
      executor: executor,
      tokenFactory: tokenFactory,
    );
    return _HistoryHarness._(
      base: base,
      history: history,
      blobs: blobs,
      actor: actor,
      recorder: recorder,
      executor: executor,
      undo: undo,
      revert: revert,
    );
  }

  final TransactionTestHarness base;
  final FileAuthoringHistoryStore history;
  final FileAuthoringContentBlobStore blobs;
  final AuthoringActor actor;
  final AuthoringHistoryRecorder recorder;
  final SecureAuthoringMutationExecutor executor;
  final AuthoringUndoService undo;
  final AuthoringRevisionRevertService revert;

  String get projectId => base.scope.projectId;

  Future<AuthoringReceipt> applyOriginal() {
    return executor.apply(
      actor: actor,
      projectId: projectId,
      action: _fixtureAction(),
      plan: base.plan,
      currentProjectRevision: base.currentProjectRevision,
      scope: base.scope,
      operationId: base.operationId,
    );
  }

  ProjectSnapshot snapshot(String revision) => ProjectSnapshot(
        projectHandle: const ProjectHandle('project-history'),
        revision: revision,
        manifest: ProjectManifest(
          name: 'History Fixture',
          maps: const [],
          tilesets: const [],
        ),
        maps: const [],
        resourceFingerprints: {'project': revision},
      );

  Future<void> expectBeforeState() async {
    expect(await base.readA(), TransactionTestHarness.beforeA);
    expect(await base.readB(), TransactionTestHarness.beforeB);
    expect(await base.readCreated(), isNull);
    expect(await base.readDeleted(), TransactionTestHarness.beforeDeleted);
  }

  Future<void> expectAfterState() async {
    expect(await base.readA(), TransactionTestHarness.afterA);
    expect(await base.readB(), TransactionTestHarness.afterB);
    expect(await base.readCreated(), TransactionTestHarness.afterCreated);
    expect(await base.readDeleted(), isNull);
  }

  Future<void> dispose() => base.dispose();
}

AuthoringActionDescriptor _fixtureAction() => AuthoringActionDescriptor(
      id: 'fixture.multiWrite',
      version: 1,
      summary: 'History fixture mutation',
      inputSchemaId: 'schema.fixture.input.v1',
      outputSchemaId: 'schema.fixture.output.v1',
      riskLevel: AuthoringRiskLevel.low,
      requiredPermissions: const [AuthoringPermission.projectWrite],
      guarantees: const [
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable,
      ],
    );

Matcher _throwsHistory(String code) => throwsA(
      isA<AuthoringHistoryException>().having(
        (error) => error.code,
        'code',
        code,
      ),
    );

String _join(String first, String second, String third) =>
    [first, second, third].join(Platform.pathSeparator);
~~~~~~~~

## `packages/map_authoring/test/history/history_retention_test.dart`

~~~~~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import '../support/transaction_test_fixture.dart';

void main() {
  group('FileAuthoringHistoryStore', () {
    test('paginates a stable newest-first snapshot with opaque cursors',
        () async {
      final project = await Directory.systemTemp.createTemp('pokemap_history_');
      addTearDown(() => project.delete(recursive: true));
      final store = await FileAuthoringHistoryStore.open(
        projectRoot: project.path,
      );
      for (var index = 0; index < 5; index++) {
        await store.append(_entry(index));
      }

      final first = await store.list(projectId: 'project-history', limit: 2);
      expect(first.entries.map((entry) => entry.entryId),
          ['receipt-4', 'receipt-3']);
      expect(first.nextCursor, isNotNull);
      expect(first.nextCursor.toString(), startsWith('history-cursor:'));

      await store.append(_entry(5));
      final transported = AuthoringHistoryCursor.fromWireValue(
        first.nextCursor!.wireValue,
      );
      final wire = transported.wireValue;
      final tampered = AuthoringHistoryCursor.fromWireValue(
        '${wire.substring(0, wire.length - 1)}${wire.endsWith('A') ? 'B' : 'A'}',
      );
      await expectLater(
        () => store.list(
          projectId: 'project-history',
          limit: 2,
          cursor: tampered,
        ),
        _throwsHistory('history.cursor_invalid'),
      );
      await expectLater(
        () => store.list(
          projectId: 'project-other',
          limit: 2,
          cursor: transported,
        ),
        _throwsHistory('history.cursor_invalid'),
      );
      final second = await store.list(
        projectId: 'project-history',
        limit: 2,
        cursor: transported,
      );
      final third = await store.list(
        projectId: 'project-history',
        limit: 2,
        cursor: second.nextCursor,
      );

      expect(second.entries.map((entry) => entry.entryId),
          ['receipt-2', 'receipt-1']);
      expect(third.entries.map((entry) => entry.entryId), ['receipt-0']);
      expect(third.nextCursor, isNull);
      expect(
        [...first.entries, ...second.entries, ...third.entries]
            .map((entry) => entry.entryId),
        isNot(contains('receipt-5')),
      );

      final reopened = await FileAuthoringHistoryStore.open(
        projectRoot: project.path,
      );
      expect(
        (await reopened.list(projectId: 'project-history', limit: 10))
            .entries
            .first
            .entryId,
        'receipt-5',
      );
    });

    test('non-undoable reason is durable and first reason remains stable',
        () async {
      final project = await Directory.systemTemp.createTemp('pokemap_history_');
      addTearDown(() => project.delete(recursive: true));
      final store = await FileAuthoringHistoryStore.open(
        projectRoot: project.path,
      );
      await store.append(_entry(1));
      await store.markNonUndoable(
        projectId: 'project-history',
        entryId: 'receipt-1',
        reason: 'history.blob_missing',
      );
      await store.markNonUndoable(
        projectId: 'project-history',
        entryId: 'receipt-1',
        reason: 'history.other_reason',
      );

      final reopened = await FileAuthoringHistoryStore.open(
        projectRoot: project.path,
      );
      expect(
        (await reopened.get(
          projectId: 'project-history',
          entryId: 'receipt-1',
        ))!
            .nonUndoableReason,
        'history.blob_missing',
      );
    });
  });

  group('FileAuthoringContentBlobStore', () {
    test('deduplicates identical bytes and makes pruning explicit', () async {
      final project = await Directory.systemTemp.createTemp('pokemap_blobs_');
      addTearDown(() => project.delete(recursive: true));
      final store = await FileAuthoringContentBlobStore.open(
        projectRoot: project.path,
      );
      final bytes = utf8.encode('{"same":true}');

      final first = await store.put(bytes);
      final second = await store.put(List<int>.from(bytes));
      expect(second.id, first.id);
      expect(await store.listIds(), [first.id]);
      expect(await store.get(first.id), bytes);

      expect(await store.prune(retainIds: const {}), 1);
      expect(await store.get(first.id), isNull);
      expect(await store.listIds(), isEmpty);
    });
  });

  test('recovery records one exact history entry after a hook interruption',
      () async {
    final harness = await TransactionTestHarness.create();
    addTearDown(harness.dispose);
    final history = await FileAuthoringHistoryStore.open(
      projectRoot: harness.projectDirectory.path,
    );
    final blobs = await FileAuthoringContentBlobStore.open(
      projectRoot: harness.projectDirectory.path,
    );
    final recorder = AuthoringHistoryRecorder(store: history, blobs: blobs);
    final transaction = JournaledAuthoringTransaction(
      plans: harness.planStore,
      gateway: harness.gateway,
      idempotency: harness.ledger,
      clock: () => harness.now,
      commitHook: _RecordThenFailOnce(recorder),
    );

    await expectLater(
      () => transaction.apply(
        planId: harness.plan.planId,
        request: harness.plan.request,
        currentProjectRevision: harness.currentProjectRevision,
        scope: harness.scope,
        operationId: harness.operationId,
      ),
      throwsA(isA<StateError>()),
    );
    expect(
      (await history.list(projectId: harness.scope.projectId, limit: 10))
          .entries,
      hasLength(1),
    );

    final recovery = AuthoringRecoveryService(
      gateway: harness.gateway,
      idempotency: harness.ledger,
      clock: () => harness.now,
      commitHook: recorder,
    );
    final recovered = await recovery.resume(harness.operationId);
    final entries =
        (await history.list(projectId: harness.scope.projectId, limit: 10))
            .entries;
    expect(recovered.status, AuthoringReceiptStatus.recovered);
    expect(entries, hasLength(1));
    expect(entries.single.receipt.status, AuthoringReceiptStatus.applied);
    expect(await blobs.listIds(), isNotEmpty);
  });
}

final class _RecordThenFailOnce implements AuthoringTransactionCommitHook {
  _RecordThenFailOnce(this._delegate);

  final AuthoringTransactionCommitHook _delegate;
  var _failed = false;

  @override
  Future<void> record(AuthoringCommittedMutation mutation) async {
    await _delegate.record(mutation);
    if (!_failed) {
      _failed = true;
      throw StateError('Simulated interruption after history persistence.');
    }
  }
}

AuthoringHistoryEntry _entry(int index) {
  final resource = AuthoringResourceRef(kind: 'fixture', id: 'item-$index');
  final before = _fingerprint(index + 1);
  final after = _fingerprint(index + 101);
  final receipt = AuthoringReceipt(
    receiptId: 'receipt-$index',
    requestId: 'request-$index',
    actionId: 'fixture.history',
    actionVersion: 1,
    status: AuthoringReceiptStatus.applied,
    beforeRevision: before,
    afterRevision: after,
    createdAtUtc: DateTime.utc(2026, 7, 31, 14, index).toIso8601String(),
    diff: AuthoringDiff([
      AuthoringDiffEntry(
        operation: AuthoringDiffOperation.replace,
        resource: resource,
        path: r'$.value',
        before: index,
        after: index + 1,
      ),
    ]),
  );
  return AuthoringHistoryEntry(
    entryId: receipt.receiptId,
    projectId: 'project-history',
    actorId: 'actor-history',
    planId: 'plan-$index',
    operationId: 'operation-$index',
    kind: AuthoringHistoryKind.mutation,
    receipt: receipt,
    committedAt: DateTime.utc(2026, 7, 31, 14, index),
    changes: [
      AuthoringHistoryResourceChange(
        resource: resource,
        storageKey: 'data/item-$index.json',
        beforeRevision: before,
        afterRevision: after,
        beforeBlobId: _fingerprint(index + 201),
        afterBlobId: _fingerprint(index + 301),
      ),
    ],
  );
}

String _fingerprint(int seed) =>
    'sha256:${seed.toRadixString(16).padLeft(64, '0').substring(0, 64)}';

Matcher _throwsHistory(String code) => throwsA(
      isA<AuthoringHistoryException>().having(
        (error) => error.code,
        'code',
        code,
      ),
    );
~~~~~~~~

## `packages/map_authoring/test/contract_kit/mutation_gate_test.dart`

~~~~~~~~dart
import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  group('AuthoringMutationRegistry', () {
    test('rejects every missing mandatory contract proof', () {
      const core = {
        MutationContractProof.plan,
        MutationContractProof.dryRun,
        MutationContractProof.staleCas,
        MutationContractProof.idempotency,
        MutationContractProof.recovery,
        MutationContractProof.authorization,
        MutationContractProof.receipt,
      };
      for (final missing in core) {
        final registry = AuthoringMutationRegistry();
        expect(
          () => registry.register(
            descriptor: _descriptor('fixture.${missing.name}'),
            evidence: MutationContractEvidence(
              proofs: {
                ...core.where((proof) => proof != missing),
                MutationContractProof.undo,
              },
            ),
          ),
          _throwsGate('mutation.contract_incomplete'),
        );
      }
    });

    test('requires either undo proof or an explicit non-undoable policy', () {
      final registry = AuthoringMutationRegistry();
      expect(
        () => registry.register(
          descriptor: _descriptor('fixture.noUndoPolicy'),
          evidence: MutationContractEvidence(
            proofs: MutationContractEvidence.mandatoryCore,
          ),
        ),
        _throwsGate('mutation.undo_policy_missing'),
      );

      registry.register(
        descriptor: _descriptor('fixture.undoable'),
        evidence: MutationContractEvidence(
          proofs: {
            ...MutationContractEvidence.mandatoryCore,
            MutationContractProof.undo,
          },
        ),
      );
      registry.register(
        descriptor: _descriptor('fixture.explicitlyNonUndoable'),
        evidence: MutationContractEvidence(
          proofs: {
            ...MutationContractEvidence.mandatoryCore,
            MutationContractProof.nonUndoablePolicy,
          },
          nonUndoableReason: 'history.external_side_effect',
        ),
      );
      expect(
        registry.actions.map((action) => action.id),
        ['fixture.explicitlyNonUndoable', 'fixture.undoable'],
      );
    });
  });

  group('AuthoringBatchExecutor', () {
    test('combines non-overlapping changes deterministically', () {
      const executor = AuthoringBatchExecutor();
      final a = _changeSet('a', 0, 1);
      final b = _changeSet('b', 5, 6);

      expect(
        jsonEncode(executor.combine([a, b]).toJson()),
        jsonEncode(executor.combine([b, a]).toJson()),
      );
      expect(executor.combine([a, b]).changes, hasLength(2));
    });

    test('deduplicates identical overlap and rejects incompatible overlap', () {
      const executor = AuthoringBatchExecutor();
      final original = _changeSet('same', 0, 1);
      final identical = _changeSet('same', 0, 1);
      final conflict = _changeSet('same', 0, 2);
      final semanticConflict = AuthoringChangeSet(
        changes: original.changes,
        diff: AuthoringDiff([
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.replace,
            resource: original.changes.single.resource,
            path: r'$.otherValue',
            before: 0,
            after: 1,
          ),
        ]),
      );

      expect(executor.combine([original, identical]).changes, hasLength(1));
      expect(
        () => executor.combine([original, conflict]),
        throwsA(
          isA<AuthoringBatchException>().having(
            (error) => error.code,
            'code',
            'batch.overlap_conflict',
          ),
        ),
      );
      expect(
        () => executor.combine([original, semanticConflict]),
        throwsA(
          isA<AuthoringBatchException>().having(
            (error) => error.code,
            'code',
            'batch.overlap_conflict',
          ),
        ),
      );
    });
  });
}

AuthoringActionDescriptor _descriptor(String id) => AuthoringActionDescriptor(
      id: id,
      version: 1,
      summary: 'Mutation gate fixture',
      inputSchemaId: 'schema.fixture.input.v1',
      outputSchemaId: 'schema.fixture.output.v1',
      riskLevel: AuthoringRiskLevel.medium,
      requiredPermissions: const [AuthoringPermission.projectWrite],
      guarantees: const [
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.revisionChecked,
      ],
    );

AuthoringChangeSet _changeSet(String id, int before, int after) {
  final resource = AuthoringResourceRef(kind: 'fixture', id: id);
  return AuthoringChangeSet(
    changes: [
      AuthoringResourceChange(
        resource: resource,
        storageKey: 'data/$id.json',
        beforeBytes: utf8.encode('{"value":$before}'),
        afterBytes: utf8.encode('{"value":$after}'),
      ),
    ],
    diff: AuthoringDiff([
      AuthoringDiffEntry(
        operation: AuthoringDiffOperation.replace,
        resource: resource,
        path: r'$.value',
        before: before,
        after: after,
      ),
    ]),
  );
}

Matcher _throwsGate(String code) => throwsA(
      isA<MutationRegistryException>().having(
        (error) => error.code,
        'code',
        code,
      ),
    );
~~~~~~~~

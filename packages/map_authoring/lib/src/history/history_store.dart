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

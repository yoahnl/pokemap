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

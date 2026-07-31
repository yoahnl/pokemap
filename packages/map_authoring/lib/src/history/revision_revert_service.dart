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

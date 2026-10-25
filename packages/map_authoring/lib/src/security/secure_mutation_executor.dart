import '../history/authoring_history.dart';
import '../transactions/file_idempotency_store.dart';
import '../transactions/idempotency_ledger.dart';
import '../support/authoring_fingerprint.dart';
import '../contracts/action_descriptor.dart';
import '../contracts/authoring_receipt.dart';
import '../ports/idempotency_store.dart';
import '../transactions/authoring_plan.dart';
import '../transactions/journaled_transaction.dart';
import '../transactions/transaction_journal.dart';
import 'audit_log.dart';
import 'audit_record.dart';
import 'authoring_permission.dart';
import 'authorization_policy.dart';
import 'confirmation_token.dart';
import 'output_redaction.dart';
import 'resource_pack_bulk_capability.dart';

/// Mandatory authorization and audit boundary around transaction apply.
final class SecureAuthoringMutationExecutor {
  const SecureAuthoringMutationExecutor({
    required JournaledAuthoringTransaction transaction,
    required AuthoringAuthorizationPolicy policy,
    required AuthoringAuditLog auditLog,
    required DateTime Function() clock,
    required String Function() auditIdFactory,
    AuthoringOutputRedactor redactor = const AuthoringOutputRedactor(),
  })  : _transaction = transaction,
        _policy = policy,
        _auditLog = auditLog,
        _clock = clock,
        _auditIdFactory = auditIdFactory,
        _redactor = redactor;

  final JournaledAuthoringTransaction _transaction;
  final AuthoringAuthorizationPolicy _policy;
  final AuthoringAuditLog _auditLog;
  final DateTime Function() _clock;
  final String Function() _auditIdFactory;
  final AuthoringOutputRedactor _redactor;

  Future<AuthoringReceipt?> inspectDurableReplay({
    required AuthoringActor actor,
    required String projectId,
    required String planId,
    required String operationId,
    required Future<AuthoringOperationReplayLookup?> Function() lookup,
    required Future<AuthoringHistoryEntry?> Function(String entryId)
        readHistory,
    required AuthoringActionDescriptor Function(String actionId) resolveAction,
  }) async {
    AuthoringOperationReplayLookup? found;
    AuthoringActionDescriptor? action;
    AuthoringReceipt? receipt;
    try {
      found = await lookup();
      if (found == null) return null;
      action = resolveAction(found.scope.actionId);
      final record = found.completed;
      if (record == null) {
        throw AuthoringIdempotencyException(
            code: 'idempotency.recovery_required',
            message: 'A durable reservation requires transaction recovery.');
      }
      receipt = record.receipt!;
      final history = await readHistory(receipt.receiptId);
      if (found.scope.actorId != actor.actorId ||
          found.scope.projectId != projectId ||
          found.operationId != operationId ||
          record.operationId != operationId ||
          record.status != AuthoringIdempotencyStatus.completed ||
          receipt.status == AuthoringReceiptStatus.planned ||
          receipt.extensions['planId'] != planId ||
          receipt.extensions['operationId'] != operationId ||
          record.scope.storageKey != found.scope.storageKey ||
          record.payloadFingerprint != found.payloadFingerprint ||
          action.id != found.scope.actionId ||
          action.version != found.scope.actionVersion ||
          receipt.actionId != action.id ||
          receipt.actionVersion != action.version ||
          history == null ||
          history.actorId != actor.actorId ||
          history.projectId != projectId ||
          history.planId != planId ||
          history.operationId != operationId ||
          !_matchesCanonicalHistoryReceipt(receipt, history.receipt) ||
          (action.id == 'resource_pack.import' &&
              history.bulkCapability == null)) {
        throw const AuthoringAuthorizationException(
            code: 'authorization.replay_context_mismatch',
            message:
                'The durable ledger, canonical history and requested replay disagree.');
      }
      final capability = history.bulkCapability;
      if (capability != null) {
        capability.requireBinding(
            actorId: actor.actorId,
            projectId: projectId,
            planId: planId,
            operationId: operationId,
            actionId: action.id,
            actionVersion: action.version,
            diff: receipt.diff,
            actualInventory: [
              for (final change in history.changes)
                ResourcePackBulkInventoryEntry(
                    resource: change.resource,
                    storageKey: change.storageKey,
                    beforeRevision: change.beforeRevision,
                    afterRevision: change.afterRevision,
                    role: capability.roleFor(change.storageKey))
            ]);
      }
      final authorized = _policy.authorize(AuthoringAuthorizationRequest(
          actor: actor,
          projectId: projectId,
          operation: AuthoringSecurityOperation.apply,
          actionId: action.id,
          actionVersion: action.version,
          riskLevel: action.riskLevel,
          requestBytes: 0,
          touchedResources: 0,
          additionalPermissions: action.requiredPermissions
              .map(_securityPermissionForDescriptor)));
      await _appendReplayAudit(
          actor: actor,
          projectId: projectId,
          planId: planId,
          action: action,
          receipt: receipt,
          decision: AuthoringAuditDecision.succeeded,
          details: {
            'idempotentReplay': true,
            'touchedResources': 0,
            'confirmationConsumed': false,
            'requiredPermissions': [
              for (final permission in authorized.requiredPermissions)
                permission.wireName
            ]
          });
      await _transaction.cleanupCompletedReplay(
          scope: found.scope,
          planId: planId,
          operationId: operationId,
          receipt: receipt);
      return receipt;
    } on Object catch (error, stack) {
      await _appendReplayAudit(
          actor: actor,
          projectId: projectId,
          planId: planId,
          action: action,
          receipt: receipt,
          decision: AuthoringAuditDecision.denied,
          error: error);
      Error.throwWithStackTrace(error, stack);
    }
  }

  Future<void> _appendReplayAudit(
      {required AuthoringActor actor,
      required String projectId,
      required String planId,
      required AuthoringActionDescriptor? action,
      required AuthoringReceipt? receipt,
      required AuthoringAuditDecision decision,
      Object? error,
      Map<String, Object?> details = const {}}) {
    final safeError = error == null ? null : _redactor.redactError(error);
    return _auditLog.append(AuthoringAuditRecord(
        auditId: _auditIdFactory(),
        actorId: actor.actorId,
        projectId: projectId,
        operation: AuthoringSecurityOperation.apply,
        decision: decision,
        requestId: receipt?.requestId ?? 'durable-replay',
        actionId: action?.id ?? 'authoring.replay',
        actionVersion: action?.version ?? 1,
        riskLevel: action?.riskLevel ?? AuthoringRiskLevel.high,
        planId: planId,
        receiptId: receipt?.receiptId,
        code: safeError?.code ?? 'mutation.succeeded',
        timestamp: _clock().toUtc(),
        details: {
          ...details,
          if (safeError != null) 'error': safeError.toJson()
        },
        redactor: _redactor));
  }

  Future<AuthoringReceipt> apply({
    required AuthoringActor actor,
    required String projectId,
    required AuthoringActionDescriptor action,
    required AuthoringPlan plan,
    required String currentProjectRevision,
    required AuthoringIdempotencyScope scope,
    required String operationId,
    AuthoringConfirmationToken? confirmationToken,
    AuthoringTransactionPrecondition? precondition,
    void Function()? beforeReservation,
    void Function()? preparationCheck,
  }) async {
    late final AuthoringAuthorizationDecision authorization;
    AuthoringReceipt? replay;
    try {
      _requireContextMatches(
        actor: actor,
        projectId: projectId,
        action: action,
        plan: plan,
        scope: scope,
      );
      replay = await _transaction.inspectReplay(
        scope: scope,
        plan: plan,
      );
      if (replay != null) {
        authorization = _policy.authorize(
          AuthoringAuthorizationRequest(
            actor: actor,
            projectId: projectId,
            operation: AuthoringSecurityOperation.apply,
            actionId: plan.request.actionId,
            actionVersion: plan.request.actionVersion,
            riskLevel: action.riskLevel,
            requestBytes: plan.authorizationRequestBytes,
            touchedResources: 0,
            additionalPermissions: action.requiredPermissions
                .map(_securityPermissionForDescriptor),
          ),
        );
      } else {
        try {
          plan.bulkCapability?.requirePlan(plan,
              actorId: actor.actorId,
              projectId: projectId,
              operationId: operationId);
        } on ArgumentError {
          throw const AuthoringAuthorizationException(
              code: 'authorization.bulk_context_mismatch',
              message:
                  'The internal bulk capability differs from the frozen plan.');
        }
        final binding = AuthoringConfirmationBinding.forPlan(
          actorId: actor.actorId,
          projectId: projectId,
          plan: plan,
        );
        authorization = _policy.authorize(
          AuthoringAuthorizationRequest(
            actor: actor,
            projectId: projectId,
            operation: AuthoringSecurityOperation.apply,
            actionId: plan.request.actionId,
            actionVersion: plan.request.actionVersion,
            riskLevel: action.riskLevel,
            requestBytes: plan.authorizationRequestBytes,
            touchedResources: plan.changeSet.changes.length,
            planId: plan.planId,
            operationId: operationId,
            bulkCapability: plan.bulkCapability,
            diffFingerprint: binding.diffFingerprint,
            destructive: plan.changeSet.changes.any(
              (change) => change.beforePayload != null,
            ),
            confirmationToken: confirmationToken,
            additionalPermissions: action.requiredPermissions
                .map(_securityPermissionForDescriptor),
          ),
        );
      }
    } on Object catch (error, stackTrace) {
      await _appendAudit(
        actor: actor,
        projectId: projectId,
        action: action,
        plan: plan,
        decision: AuthoringAuditDecision.denied,
        error: error,
      );
      Error.throwWithStackTrace(error, stackTrace);
    }

    if (replay != null) {
      await _appendAudit(
        actor: actor,
        projectId: projectId,
        action: action,
        plan: plan,
        decision: AuthoringAuditDecision.succeeded,
        receipt: replay,
        details: {
          'confirmationConsumed': false,
          'idempotentReplay': true,
          'requiredPermissions': [
            for (final permission in authorization.requiredPermissions)
              permission.wireName,
          ],
          'touchedResources': 0,
        },
      );
      await _transaction.cleanupCompletedReplay(
          scope: scope,
          planId: plan.planId,
          operationId: operationId,
          receipt: replay);
      return replay;
    }

    late final AuthoringReceipt receipt;
    try {
      receipt = await _transaction.apply(
        planId: plan.planId,
        request: plan.request,
        currentProjectRevision: currentProjectRevision,
        scope: scope,
        operationId: operationId,
        precondition: precondition,
        beforeReservation: beforeReservation,
        preparationCheck: preparationCheck,
      );
    } on Object catch (error, stackTrace) {
      await _appendAudit(
        actor: actor,
        projectId: projectId,
        action: action,
        plan: plan,
        decision: AuthoringAuditDecision.failed,
        error: error,
      );
      Error.throwWithStackTrace(error, stackTrace);
    }

    // Audit persistence is part of the secure boundary. If it fails after the
    // durable transaction commits, the caller receives the audit error and can
    // safely replay through the idempotency key without reapplying bytes.
    await _appendAudit(
      actor: actor,
      projectId: projectId,
      action: action,
      plan: plan,
      decision: AuthoringAuditDecision.succeeded,
      receipt: receipt,
      details: {
        'confirmationConsumed': authorization.confirmationConsumed,
        'requiredPermissions': [
          for (final permission in authorization.requiredPermissions)
            permission.wireName,
        ],
        'touchedResources': plan.changeSet.changes.length,
      },
    );
    return receipt;
  }

  Future<int> prepareFinalizedJournals({required Future<void> Function(AuthoringTransactionJournal) requireHistory}) =>
      _transaction.prepareFinalizedJournals(requireHistory: requireHistory);

  Future<void> cleanupRecoveredMutation({required AuthoringIdempotencyScope scope,required String planId,required String operationId,required AuthoringReceipt receipt}) => _transaction.cleanupCompletedReplay(scope:scope,planId:planId,operationId:operationId,receipt:receipt);

  Future<void> auditMutationOutcome({
    required AuthoringActor actor,
    required String projectId,
    required AuthoringActionDescriptor action,
    required AuthoringPlan plan,
    required AuthoringAuditDecision decision,
    AuthoringReceipt? receipt,
    Object? error,
    Map<String, Object?> details = const {},
  }) =>
      _appendAudit(
          actor: actor,
          projectId: projectId,
          action: action,
          plan: plan,
          decision: decision,
          receipt: receipt,
          error: error,
          details: details);

  Future<void> _appendAudit({
    required AuthoringActor actor,
    required String projectId,
    required AuthoringActionDescriptor action,
    required AuthoringPlan plan,
    required AuthoringAuditDecision decision,
    AuthoringReceipt? receipt,
    Object? error,
    Map<String, Object?> details = const {},
  }) {
    final safeError = error == null ? null : _redactor.redactError(error);
    return _auditLog.append(
      AuthoringAuditRecord(
        auditId: _auditIdFactory(),
        actorId: actor.actorId,
        projectId: projectId,
        operation: AuthoringSecurityOperation.apply,
        decision: decision,
        requestId: plan.request.requestId,
        actionId: plan.request.actionId,
        actionVersion: plan.request.actionVersion,
        riskLevel: action.riskLevel,
        planId: plan.planId,
        receiptId: receipt?.receiptId,
        code: safeError?.code ?? 'mutation.succeeded',
        timestamp: _clock().toUtc(),
        details: {
          ...details,
          if (safeError != null) 'error': safeError.toJson(),
        },
        redactor: _redactor,
      ),
    );
  }
}

void _requireContextMatches({
  required AuthoringActor actor,
  required String projectId,
  required AuthoringActionDescriptor action,
  required AuthoringPlan plan,
  required AuthoringIdempotencyScope scope,
}) {
  if (scope.actorId != actor.actorId ||
      scope.projectId != projectId ||
      scope.actionId != plan.request.actionId ||
      scope.actionVersion != plan.request.actionVersion ||
      action.id != plan.request.actionId ||
      action.version != plan.request.actionVersion) {
    throw const AuthoringAuthorizationException(
      code: 'authorization.context_mismatch',
      message: 'The actor, project, action, plan, and durable scope disagree.',
    );
  }
}

AuthoringPermissionScope _securityPermissionForDescriptor(
  AuthoringPermission permission,
) {
  return switch (permission) {
    AuthoringPermission.projectRead => AuthoringPermissionScope.projectRead,
    AuthoringPermission.projectWrite => AuthoringPermissionScope.projectWrite,
    AuthoringPermission.projectDestructive =>
      AuthoringPermissionScope.projectDestructive,
    AuthoringPermission.assetRead => AuthoringPermissionScope.assetRead,
    AuthoringPermission.assetWrite => AuthoringPermissionScope.assetWrite,
    AuthoringPermission.renderRun => AuthoringPermissionScope.renderRun,
    AuthoringPermission.playtestRun => AuthoringPermissionScope.playtestRun,
    AuthoringPermission.playtestControl =>
      AuthoringPermissionScope.playtestControl,
    AuthoringPermission.importRun => AuthoringPermissionScope.importRun,
    AuthoringPermission.exportRun => AuthoringPermissionScope.exportRun,
    AuthoringPermission.migrationRun => AuthoringPermissionScope.migrationRun,
    AuthoringPermission.networkExternal =>
      AuthoringPermissionScope.networkExternal,
    AuthoringPermission.processExecute =>
      AuthoringPermissionScope.processExecute,
    AuthoringPermission.secretUse => AuthoringPermissionScope.secretUse,
    AuthoringPermission.recoveryApply => AuthoringPermissionScope.recoveryApply,
  };
}

bool _matchesCanonicalHistoryReceipt(
  AuthoringReceipt receipt,
  AuthoringReceipt historical,
) {
  if (canonicalAuthoringJson(receipt.toJson()) ==
      canonicalAuthoringJson(historical.toJson())) {
    return true;
  }
  if (receipt.status != AuthoringReceiptStatus.recovered ||
      historical.status != AuthoringReceiptStatus.applied ||
      receipt.extensions['recoveryOutcome'] != 'resumed') {
    return false;
  }
  final normalized = Map<String, Object?>.from(receipt.toJson());
  final extensions = Map<String, Object?>.from(receipt.extensions)
    ..remove('recoveryOutcome');
  normalized['status'] = historical.status.name;
  normalized['createdAtUtc'] = historical.createdAtUtc;
  if (extensions.isEmpty) {
    normalized.remove('extensions');
  } else {
    normalized['extensions'] = extensions;
  }
  return canonicalAuthoringJson(normalized) ==
      canonicalAuthoringJson(historical.toJson());
}

import 'dart:convert';

import '../contracts/action_descriptor.dart';
import '../contracts/authoring_receipt.dart';
import '../ports/idempotency_store.dart';
import '../support/authoring_fingerprint.dart';
import '../transactions/authoring_plan.dart';
import '../transactions/journaled_transaction.dart';
import 'audit_log.dart';
import 'audit_record.dart';
import 'authoring_permission.dart';
import 'authorization_policy.dart';
import 'confirmation_token.dart';
import 'output_redaction.dart';

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
  }) async {
    late final AuthoringAuthorizationDecision authorization;
    try {
      _requireContextMatches(
        actor: actor,
        projectId: projectId,
        action: action,
        plan: plan,
        scope: scope,
      );
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
          requestBytes: utf8
              .encode(
                canonicalAuthoringJson(plan.request.toJson()),
              )
              .length,
          touchedResources: plan.changeSet.changes.length,
          planId: plan.planId,
          diffFingerprint: binding.diffFingerprint,
          destructive: plan.changeSet.changes.any(
            (change) => change.beforeBytes != null,
          ),
          confirmationToken: confirmationToken,
          additionalPermissions:
              action.requiredPermissions.map(_securityPermissionForDescriptor),
        ),
      );
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

    late final AuthoringReceipt receipt;
    try {
      receipt = await _transaction.apply(
        planId: plan.planId,
        request: plan.request,
        currentProjectRevision: currentProjectRevision,
        scope: scope,
        operationId: operationId,
        precondition: precondition,
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

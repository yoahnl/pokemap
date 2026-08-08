import 'dart:convert';

import '../contracts/action_descriptor.dart';
import '../contracts/authoring_receipt.dart';
import 'audit_log.dart';
import 'audit_record.dart';
import 'authoring_permission.dart';
import 'authorization_policy.dart';
import 'output_redaction.dart';

typedef AuthoringRecoveryRunner = Future<AuthoringReceipt> Function(
  String operationId,
);

/// Mandatory authorization and audit boundary around transaction recovery.
final class SecureAuthoringRecoveryExecutor {
  const SecureAuthoringRecoveryExecutor({
    required AuthoringRecoveryRunner recover,
    required AuthoringAuthorizationPolicy policy,
    required AuthoringAuditLog auditLog,
    required DateTime Function() clock,
    required String Function() auditIdFactory,
    AuthoringOutputRedactor redactor = const AuthoringOutputRedactor(),
  })  : _recover = recover,
        _policy = policy,
        _auditLog = auditLog,
        _clock = clock,
        _auditIdFactory = auditIdFactory,
        _redactor = redactor;

  final AuthoringRecoveryRunner _recover;
  final AuthoringAuthorizationPolicy _policy;
  final AuthoringAuditLog _auditLog;
  final DateTime Function() _clock;
  final String Function() _auditIdFactory;
  final AuthoringOutputRedactor _redactor;

  Future<AuthoringReceipt> recover({
    required AuthoringActor actor,
    required String projectId,
    required String operationId,
  }) async {
    late final AuthoringAuthorizationDecision authorization;
    try {
      authorization = _policy.authorize(
        AuthoringAuthorizationRequest(
          actor: actor,
          projectId: projectId,
          operation: AuthoringSecurityOperation.recover,
          actionId: 'transaction.recover',
          actionVersion: 1,
          riskLevel: AuthoringRiskLevel.high,
          requestBytes: utf8.encode(operationId).length,
          touchedResources: 0,
        ),
      );
    } on Object catch (error, stackTrace) {
      await _appendAudit(
        actor: actor,
        projectId: projectId,
        operationId: operationId,
        decision: AuthoringAuditDecision.denied,
        error: error,
      );
      Error.throwWithStackTrace(error, stackTrace);
    }

    late final AuthoringReceipt receipt;
    try {
      receipt = await _recover(operationId);
    } on Object catch (error, stackTrace) {
      await _appendAudit(
        actor: actor,
        projectId: projectId,
        operationId: operationId,
        decision: AuthoringAuditDecision.failed,
        error: error,
      );
      Error.throwWithStackTrace(error, stackTrace);
    }

    await _appendAudit(
      actor: actor,
      projectId: projectId,
      operationId: operationId,
      decision: AuthoringAuditDecision.succeeded,
      receipt: receipt,
      details: {
        'requiredPermissions': [
          for (final permission in authorization.requiredPermissions)
            permission.wireName,
        ],
      },
    );
    return receipt;
  }

  Future<void> _appendAudit({
    required AuthoringActor actor,
    required String projectId,
    required String operationId,
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
        operation: AuthoringSecurityOperation.recover,
        decision: decision,
        requestId: operationId,
        actionId: 'transaction.recover',
        actionVersion: 1,
        riskLevel: AuthoringRiskLevel.high,
        receiptId: receipt?.receiptId,
        code: safeError?.code ?? 'recovery.succeeded',
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

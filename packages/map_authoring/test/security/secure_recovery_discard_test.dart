import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  for (final outcome in ['succeeded', 'denied', 'failed', 'precondition']) {
    test('discard preparation audits $outcome without recovery or receipt',
        () async {
      final audit = _Audit();
      var calls = 0;
      final now = DateTime.utc(2026, 10, 25);
      final executor = SecureAuthoringRecoveryExecutor(
        recover: (_) async => throw StateError('Recovery must not run'),
        discardPreparation: (operationId) async {
          calls++;
          if (outcome == 'failed') {
            throw const AuthoringRecoveryException(
                'recovery.incomplete_preparation_required',
                'Preparation is not incomplete.');
          }
          return AuthoringIncompletePreparationDiscardResult.alreadyAbsent(
              operationId: operationId);
        },
        policy: AuthoringAuthorizationPolicy(
            confirmations: AuthoringConfirmationStore(clock: () => now),
            clock: () => now),
        auditLog: audit,
        clock: () => now,
        auditIdFactory: () => 'discard-audit',
      );
      final result = executor.discardPreparation(
        actor: AuthoringActor(
            actorId: 'fixture',
            permissions: outcome == 'denied'
                ? const []
                : const [AuthoringPermissionScope.recoveryApply]),
        projectId: 'project-fixture',
        operationId: 'operation-fixture',
        beforeDiscard: () {
          if (outcome == 'precondition') throw StateError('Inactive project');
        },
      );
      if (outcome == 'succeeded') {
        expect((await result).discarded, isFalse);
      } else {
        await expectLater(result, throwsA(isA<Object>()));
      }
      expect(calls, outcome == 'denied' || outcome == 'precondition' ? 0 : 1);
      expect(audit.records, hasLength(1));
      final record = audit.records.single;
      expect(record.actionId, 'transaction.discard_preparation');
      expect(record.operation, AuthoringSecurityOperation.recover);
      expect(record.receiptId, isNull);
      expect(
          record.decision.name, outcome == 'precondition' ? 'failed' : outcome);
      if (outcome == 'succeeded') {
        expect(record.details['requiredPermissions'], ['recovery.apply']);
        expect(record.details['disposition'], 'alreadyAbsent');
        expect(record.details['projectDataChanged'], isFalse);
      }
    });
  }
}

final class _Audit implements AuthoringAuditLog {
  final records = <AuthoringAuditRecord>[];
  @override
  Future<void> append(AuthoringAuditRecord record) async => records.add(record);
  @override
  Future<List<AuthoringAuditRecord>> readAll() async =>
      List.unmodifiable(records);
}

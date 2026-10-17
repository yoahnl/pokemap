import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import '../domains/assets/resource_pack_import_fixture.dart';
import '../transactions/bulk_transaction_checkpoint_test.dart'
    show BulkTransactionFixture;

void main() {
  test('resumed replay normalizes only status date and recoveryOutcome',
      () async {
    final fixture = await NativeResourcePackImportFixture.create();
    final small = BulkTransactionFixture(1);
    try {
      final plan = await fixture.plan(await fixture.prepare());
      final applied =
          await fixture.apply(plan, operationId: 'normalization-operation');
      final projectId = fixture.preparer.scope.projectId;
      final store = FileIdempotencyStore(
          filePath:
              '${fixture.root.path}/.pokemap/authoring/idempotency.jsonl');
      final found = (await store.lookupOperation(
          actorId: 'local_cli',
          projectId: projectId,
          operationId: 'normalization-operation',
          now: DateTime.now()))!;
      final history =
          await FileAuthoringHistoryStore.open(projectRoot: fixture.root.path);
      final audit =
          await FileAuthoringAuditLog.open(projectRoot: fixture.root.path);
      final executor = SecureAuthoringMutationExecutor(
          transaction: small.transaction(),
          policy: AuthoringAuthorizationPolicy(
              confirmations: AuthoringConfirmationStore(clock: DateTime.now),
              clock: DateTime.now),
          auditLog: audit,
          clock: DateTime.now,
          auditIdFactory: () =>
              'normalization-${DateTime.now().microsecondsSinceEpoch}');
      final resumed = {
        ...applied.receipt.toJson(),
        'status': 'recovered',
        'createdAtUtc': DateTime.parse(applied.receipt.createdAtUtc)
            .add(Duration(seconds: 1))
            .toIso8601String(),
        'extensions': {
          ...applied.receipt.extensions,
          'recoveryOutcome': 'resumed'
        }
      };
      final actions = MapMutationDispatcher.canonical();
      Future<AuthoringReceipt?> inspect(Map<String, Object?> value) =>
          executor.inspectDurableReplay(
              actor: AuthoringActor(
                  actorId: 'local_cli',
                  permissions: AuthoringPermissionScope.values),
              projectId: projectId,
              planId: plan.planId,
              operationId: 'normalization-operation',
              resolveAction: actions.descriptor,
              readHistory: (id) =>
                  history.get(projectId: projectId, entryId: id),
              lookup: () async => AuthoringOperationReplayLookup(
                  scope: found.scope,
                  operationId: found.operationId,
                  payloadFingerprint: found.payloadFingerprint,
                  completed: AuthoringIdempotencyRecord(
                      scope: found.scope,
                      payloadFingerprint: found.payloadFingerprint,
                      operationId: found.operationId,
                      status: AuthoringIdempotencyStatus.completed,
                      createdAt: found.completed!.createdAt,
                      expiresAt: found.completed!.expiresAt,
                      receipt: AuthoringReceipt.fromJson(
                          Map<String, dynamic>.from(value)))));
      final accepted = await inspect(resumed);
      expect(accepted!.receiptId, applied.receipt.receiptId);
      expect(accepted.status, AuthoringReceiptStatus.recovered);
      for (final changed in [
        {...resumed, 'requestId': 'tampered-request'},
        {
          ...resumed,
          'extensions': {
            ...resumed['extensions'] as Map,
            'unrelated': 'tampered'
          }
        },
        {
          ...resumed,
          'extensions': {
            ...resumed['extensions'] as Map,
            'recoveryOutcome': 'compensated'
          }
        },
      ]) {
        await expectLater(
            inspect(changed),
            throwsA(isA<AuthoringAuthorizationException>().having((e) => e.code,
                'code', 'authorization.replay_context_mismatch')));
      }
    } finally {
      await small.plans.dispose();
      await fixture.dispose();
    }
  });
}

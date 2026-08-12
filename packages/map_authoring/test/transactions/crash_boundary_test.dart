import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import '../support/transaction_test_fixture.dart';

void main() {
  group('JournaledAuthoringTransaction', () {
    test('applies update create and delete once then replays exact receipt',
        () async {
      final harness = await TransactionTestHarness.create();
      addTearDown(harness.dispose);

      final first = await harness.apply();
      final retry = await harness.apply();

      expect(first.status, AuthoringReceiptStatus.applied);
      expect(retry.toJson(), first.toJson());
      expect(await harness.readA(), TransactionTestHarness.afterA);
      expect(await harness.readB(), TransactionTestHarness.afterB);
      expect(await harness.readCreated(), TransactionTestHarness.afterCreated);
      expect(await harness.readDeleted(), isNull);
      expect(await harness.readJournal(), isNull);

      final replayWithoutPlan = JournaledAuthoringTransaction(
        plans: AuthoringPlanStore(clock: () => harness.now),
        gateway: await LocalTransactionFileGateway.open(
          projectRoot: harness.projectDirectory.path,
        ),
        idempotency: AuthoringIdempotencyLedger(
          store: FileIdempotencyStore(filePath: harness.ledgerPath),
          clock: () => harness.now,
        ),
        clock: () => harness.now,
      );
      final durableReplay = await replayWithoutPlan.apply(
        planId: 'plan_no_longer_in_memory',
        request: AuthoringRequest(
          requestId: 'req-after-restart',
          actionId: harness.plan.request.actionId,
          actionVersion: harness.plan.request.actionVersion,
          workspaceHandle: 'workspace:reopened',
          parameters: harness.plan.request.parameters,
          expectedRevision: harness.plan.request.expectedRevision,
          idempotencyKey: harness.plan.request.idempotencyKey,
        ),
        currentProjectRevision: 'sha256:${List.filled(64, 'f').join()}',
        scope: harness.scope,
        operationId: 'operation-after-restart',
      );
      expect(durableReplay.toJson(), first.toJson());
    });

    test('cleanup failure never turns a durable commit into a failed apply',
        () async {
      final harness = await TransactionTestHarness.create();
      addTearDown(harness.dispose);
      final gateway = _DeleteFailingGateway(harness.gateway);
      final transaction = JournaledAuthoringTransaction(
        plans: harness.planStore,
        gateway: gateway,
        idempotency: harness.ledger,
        clock: () => harness.now,
      );

      final receipt = await transaction.apply(
        planId: harness.plan.planId,
        request: harness.plan.request,
        currentProjectRevision: harness.currentProjectRevision,
        scope: harness.scope,
        operationId: harness.operationId,
      );
      final replay = await transaction.apply(
        planId: harness.plan.planId,
        request: harness.plan.request,
        currentProjectRevision: harness.currentProjectRevision,
        scope: harness.scope,
        operationId: 'operation-cleanup-retry',
      );

      expect(receipt.status, AuthoringReceiptStatus.applied);
      expect(replay.toJson(), receipt.toJson());
      expect(gateway.deleteAttempts, 2);
      expect(await harness.readA(), TransactionTestHarness.afterA);
      expect(await harness.readJournal(), isNull);
    });

    for (final checkpoint in [
      AuthoringTransactionCheckpoint.afterJournalPreparing,
      AuthoringTransactionCheckpoint.afterPayloadsStaged,
      AuthoringTransactionCheckpoint.afterJournalStaged,
    ]) {
      test('$checkpoint leaves an unreserved discardable intent', () async {
        var crashed = false;
        final harness = await TransactionTestHarness.create(
          faultInjector: (context) {
            if (!crashed && context.checkpoint == checkpoint) {
              crashed = true;
              throw const AuthoringTransactionSimulatedCrash();
            }
          },
        );
        addTearDown(harness.dispose);

        await expectLater(
            harness.apply,
            throwsA(
              isA<AuthoringTransactionSimulatedCrash>(),
            ));

        final recovery = await harness.reopenRecovery();
        final inspection = (await recovery.inspect()).single;
        expect(inspection.disposition,
            AuthoringRecoveryDisposition.unreservedIntent);
        expect(await harness.readA(), TransactionTestHarness.beforeA);
        expect(await harness.readB(), TransactionTestHarness.beforeB);
        expect(await recovery.discardUnreserved(harness.operationId), isTrue);
        expect(await recovery.inspect(), isEmpty);
      });
    }

    for (final checkpoint in [
      AuthoringTransactionCheckpoint.afterReservation,
      AuthoringTransactionCheckpoint.afterJournalPrepared,
      AuthoringTransactionCheckpoint.afterResourcePromoted,
      AuthoringTransactionCheckpoint.afterResourceJournaled,
      AuthoringTransactionCheckpoint.afterJournalCommitted,
    ]) {
      test('$checkpoint resumes idempotently after service reconstruction',
          () async {
        var crashed = false;
        final harness = await TransactionTestHarness.create(
          faultInjector: (context) {
            final firstResourceBoundary =
                context.promotionIndex == null || context.promotionIndex == 0;
            if (!crashed &&
                context.checkpoint == checkpoint &&
                firstResourceBoundary) {
              crashed = true;
              throw const AuthoringTransactionSimulatedCrash();
            }
          },
        );
        addTearDown(harness.dispose);

        await expectLater(
          harness.apply,
          throwsA(isA<AuthoringTransactionSimulatedCrash>()),
        );
        if (checkpoint ==
                AuthoringTransactionCheckpoint.afterResourcePromoted ||
            checkpoint ==
                AuthoringTransactionCheckpoint.afterResourceJournaled) {
          expect(await harness.readA(), TransactionTestHarness.afterA);
          expect(await harness.readB(), TransactionTestHarness.beforeB);
        }

        final recovery = await harness.reopenRecovery();
        expect(
          (await recovery.inspect()).single.disposition,
          AuthoringRecoveryDisposition.resumable,
        );
        final recovered = await recovery.resume(harness.operationId);
        final repeated = await recovery.resume(harness.operationId);

        expect(recovered.status, AuthoringReceiptStatus.recovered);
        expect(repeated.toJson(), recovered.toJson());
        expect(await harness.readA(), TransactionTestHarness.afterA);
        expect(await harness.readB(), TransactionTestHarness.afterB);
        expect(
          await harness.readCreated(),
          TransactionTestHarness.afterCreated,
        );
        expect(await harness.readDeleted(), isNull);
        expect(
          (await harness.readJournal())?.status,
          AuthoringTransactionStatus.committed,
        );
      });
    }

    test('rejects stale touched resources before journal or reservation',
        () async {
      final harness = await TransactionTestHarness.create();
      addTearDown(harness.dispose);
      await harness.writeExternalB(utf8.encode('{"external":true}'));

      await expectLater(
        harness.apply,
        throwsA(isA<AuthoringRevisionConflict>()),
      );

      expect(await harness.readJournal(), isNull);
      expect(
          await FileIdempotencyStore(filePath: harness.ledgerPath)
              .read(harness.scope),
          isNull);
      expect(await harness.readA(), TransactionTestHarness.beforeA);
      expect(await harness.readB(), utf8.encode('{"external":true}'));
    });

    test('rejects an apply request that differs from the frozen plan',
        () async {
      final harness = await TransactionTestHarness.create();
      addTearDown(harness.dispose);
      final mismatched = AuthoringRequest(
        requestId: 'req-mismatch',
        actionId: harness.plan.request.actionId,
        actionVersion: harness.plan.request.actionVersion,
        workspaceHandle: harness.plan.request.workspaceHandle,
        parameters: const {'fixture': false},
        expectedRevision: harness.plan.request.expectedRevision,
        idempotencyKey: harness.plan.request.idempotencyKey,
      );

      await expectLater(
        () => harness.transaction.apply(
          planId: harness.plan.planId,
          request: mismatched,
          currentProjectRevision: harness.currentProjectRevision,
          scope: harness.scope,
          operationId: harness.operationId,
        ),
        throwsA(
          isA<JournaledAuthoringTransactionException>().having(
            (error) => error.code,
            'code',
            'transaction.request_plan_mismatch',
          ),
        ),
      );
      expect(await harness.readJournal(), isNull);
      expect(
        await FileIdempotencyStore(filePath: harness.ledgerPath)
            .read(harness.scope),
        isNull,
      );
    });

    test('second CAS blocks an external edit immediately before promotion',
        () async {
      late TransactionTestHarness harness;
      var changed = false;
      harness = await TransactionTestHarness.create(
        faultInjector: (context) async {
          if (!changed &&
              context.checkpoint ==
                  AuthoringTransactionCheckpoint.beforeResourcePromotion &&
              context.promotionIndex == 0) {
            changed = true;
            await harness.writeExternalA(
              utf8.encode('{"external":"late"}'),
            );
          }
        },
      );
      addTearDown(harness.dispose);

      await expectLater(
        harness.apply,
        throwsA(
          isA<TransactionFileGatewayException>().having(
            (error) => error.code,
            'code',
            'transaction.revision_conflict',
          ),
        ),
      );

      final inspection =
          (await (await harness.reopenRecovery()).inspect()).single;
      expect(inspection.disposition, AuthoringRecoveryDisposition.blocked);
      expect(await harness.readA(), utf8.encode('{"external":"late"}'));
      expect(await harness.readB(), TransactionTestHarness.beforeB);
    });

    test('rejects symlink parents and path-like operation identifiers',
        () async {
      final harness = await TransactionTestHarness.create();
      addTearDown(harness.dispose);
      final external = await Directory.systemTemp.createTemp(
        'pokemap_transaction_external_',
      );
      addTearDown(() => external.delete(recursive: true));
      await File('${external.path}${Platform.pathSeparator}outside.json')
          .writeAsString('{"outside":true}');
      await Link(
        '${harness.projectDirectory.path}${Platform.pathSeparator}linked',
      ).create(external.path);

      await expectLater(
        () => harness.gateway.readResource('linked/outside.json'),
        throwsA(isA<TransactionFileGatewayException>()),
      );
      await expectLater(
        () => harness.gateway.readJournal('../escape'),
        throwsA(
          isA<TransactionFileGatewayException>().having(
            (error) => error.code,
            'code',
            'transaction.operation_id_invalid',
          ),
        ),
      );
      expect(
        await File('${external.path}${Platform.pathSeparator}outside.json')
            .readAsString(),
        '{"outside":true}',
      );
    });
  });
}

final class _DeleteFailingGateway implements TransactionFileGateway {
  _DeleteFailingGateway(this.delegate);

  final TransactionFileGateway delegate;
  int deleteAttempts = 0;
  int failuresRemaining = 1;

  @override
  Future<void> deleteTransaction(String operationId) async {
    deleteAttempts += 1;
    if (failuresRemaining > 0) {
      failuresRemaining -= 1;
      throw const TransactionFileGatewayException(
        'transaction.cleanup_failed',
        'Injected cleanup failure.',
      );
    }
    return delegate.deleteTransaction(operationId);
  }

  @override
  Future<List<AuthoringTransactionJournal>> listJournals() =>
      delegate.listJournals();

  @override
  Future<void> promoteStaged({
    required String operationId,
    required String storageKey,
    required TransactionPayloadKind kind,
    required String? expectedCurrentRevision,
  }) =>
      delegate.promoteStaged(
        operationId: operationId,
        storageKey: storageKey,
        kind: kind,
        expectedCurrentRevision: expectedCurrentRevision,
      );

  @override
  Future<AuthoringTransactionJournal?> readJournal(String operationId) =>
      delegate.readJournal(operationId);

  @override
  Future<List<int>?> readResource(String storageKey) =>
      delegate.readResource(storageKey);

  @override
  Future<String?> readResourceRevision(String storageKey) =>
      delegate.readResourceRevision(storageKey);

  @override
  Future<TransactionStagedPayload> readStagedPayload({
    required String operationId,
    required String storageKey,
    required TransactionPayloadKind kind,
  }) =>
      delegate.readStagedPayload(
        operationId: operationId,
        storageKey: storageKey,
        kind: kind,
      );

  @override
  Future<void> stagePayload({
    required String operationId,
    required String storageKey,
    required TransactionPayloadKind kind,
    required List<int>? bytes,
  }) =>
      delegate.stagePayload(
        operationId: operationId,
        storageKey: storageKey,
        kind: kind,
        bytes: bytes,
      );

  @override
  Future<T> withExclusiveWriteLock<T>(Future<T> Function() operation) =>
      delegate.withExclusiveWriteLock(operation);

  @override
  Future<void> writeJournal(AuthoringTransactionJournal journal) =>
      delegate.writeJournal(journal);
}

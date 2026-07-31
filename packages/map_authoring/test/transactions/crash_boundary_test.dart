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
      expect(
        (await harness.readJournal())?.status,
        AuthoringTransactionStatus.committed,
      );

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

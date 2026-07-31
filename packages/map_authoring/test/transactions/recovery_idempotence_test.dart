import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import '../support/transaction_test_fixture.dart';

void main() {
  group('AuthoringRecoveryService', () {
    test('compensates a partial promotion in reverse and closes idempotency',
        () async {
      var crashed = false;
      final harness = await TransactionTestHarness.create(
        faultInjector: (context) {
          if (!crashed &&
              context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterResourcePromoted &&
              context.promotionIndex == 0) {
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

      final recovery = await harness.reopenRecovery();
      final receipt = await recovery.compensate(harness.operationId);
      final replay = await harness.apply();

      expect(receipt.status, AuthoringReceiptStatus.recovered);
      expect(receipt.extensions['recoveryOutcome'], 'compensated');
      expect(replay.toJson(), receipt.toJson());
      expect(await harness.readA(), TransactionTestHarness.beforeA);
      expect(await harness.readB(), TransactionTestHarness.beforeB);
      expect(await harness.readCreated(), isNull);
      expect(
        await harness.readDeleted(),
        TransactionTestHarness.beforeDeleted,
      );
      expect(
        (await harness.readJournal())?.status,
        AuthoringTransactionStatus.compensated,
      );
    });

    test('compensation refuses a promoted resource changed by another writer',
        () async {
      final harness = await _crashAfterFirstPromotion();
      addTearDown(harness.dispose);
      final external = utf8.encode('{"external":"after-promotion"}');
      await harness.writeExternalA(external);
      final recovery = await harness.reopenRecovery();

      await expectLater(
        () => recovery.compensate(harness.operationId),
        throwsA(isA<AuthoringRecoveryException>()),
      );

      expect(await harness.readA(), external);
      expect(await harness.readB(), TransactionTestHarness.beforeB);
      expect(
        (await recovery.inspect()).single.disposition,
        AuthoringRecoveryDisposition.blocked,
      );
    });

    test('forward recovery refuses an unpromoted resource changed externally',
        () async {
      final harness = await _crashAfterFirstPromotion();
      addTearDown(harness.dispose);
      final external = utf8.encode('{"external":"before-promotion"}');
      await harness.writeExternalB(external);
      final recovery = await harness.reopenRecovery();

      await expectLater(
        () => recovery.resume(harness.operationId),
        throwsA(isA<AuthoringRecoveryException>()),
      );

      expect(await harness.readA(), TransactionTestHarness.afterA);
      expect(await harness.readB(), external);
    });

    test('committed journal finalizes a pending ledger exactly once', () async {
      var crashed = false;
      final harness = await TransactionTestHarness.create(
        faultInjector: (context) {
          if (!crashed &&
              context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterJournalCommitted) {
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

      final recovery = await harness.reopenRecovery();
      final first = await recovery.resume(harness.operationId);
      final second = await recovery.resume(harness.operationId);

      expect(first.status, AuthoringReceiptStatus.recovered);
      expect(second.toJson(), first.toJson());
      expect((await recovery.inspect()).single.disposition,
          AuthoringRecoveryDisposition.completed);
    });

    test('committed but unreceipted create and delete can be compensated',
        () async {
      var crashed = false;
      final harness = await TransactionTestHarness.create(
        faultInjector: (context) {
          if (!crashed &&
              context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterJournalCommitted) {
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
      expect(await harness.readCreated(), TransactionTestHarness.afterCreated);
      expect(await harness.readDeleted(), isNull);

      final receipt = await (await harness.reopenRecovery())
          .compensate(harness.operationId);

      expect(receipt.extensions['recoveryOutcome'], 'compensated');
      expect(await harness.readCreated(), isNull);
      expect(
        await harness.readDeleted(),
        TransactionTestHarness.beforeDeleted,
      );
    });

    test('unreserved preparation can be discarded only while targets match',
        () async {
      var crashed = false;
      final harness = await TransactionTestHarness.create(
        faultInjector: (context) {
          if (!crashed &&
              context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterJournalStaged) {
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
      final recovery = await harness.reopenRecovery();
      await harness.writeExternalA(utf8.encode('{"external":true}'));

      await expectLater(
        () => recovery.discardUnreserved(harness.operationId),
        throwsA(isA<AuthoringRecoveryException>()),
      );
      expect(
        (await recovery.inspect()).single.disposition,
        AuthoringRecoveryDisposition.blocked,
      );
    });

    test('corrupt staged payload blocks recovery before any promotion',
        () async {
      var crashed = false;
      final harness = await TransactionTestHarness.create(
        faultInjector: (context) {
          if (!crashed &&
              context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterJournalPrepared) {
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
      final operationDirectory = Directory(
        [
          harness.projectDirectory.path,
          '.pokemap',
          'authoring',
          'transactions',
          harness.operationId,
        ].join(Platform.pathSeparator),
      );
      final stagedAfter = operationDirectory
          .listSync()
          .whereType<File>()
          .firstWhere((file) => file.path.endsWith('.after.bin'));
      await stagedAfter.writeAsString('corrupt');

      final recovery = await harness.reopenRecovery();
      expect(
        (await recovery.inspect()).single.disposition,
        AuthoringRecoveryDisposition.blocked,
      );
      await expectLater(
        () => recovery.resume(harness.operationId),
        throwsA(isA<AuthoringRecoveryException>()),
      );
      expect(await harness.readA(), TransactionTestHarness.beforeA);
      expect(await harness.readB(), TransactionTestHarness.beforeB);
    });
  });
}

Future<TransactionTestHarness> _crashAfterFirstPromotion() async {
  var crashed = false;
  final harness = await TransactionTestHarness.create(
    faultInjector: (context) {
      if (!crashed &&
          context.checkpoint ==
              AuthoringTransactionCheckpoint.afterResourcePromoted &&
          context.promotionIndex == 0) {
        crashed = true;
        throw const AuthoringTransactionSimulatedCrash();
      }
    },
  );
  await expectLater(
    harness.apply,
    throwsA(isA<AuthoringTransactionSimulatedCrash>()),
  );
  return harness;
}

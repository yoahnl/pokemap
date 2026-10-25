import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import '../support/transaction_test_fixture.dart';

void main() {
  test('explicit preparation retires only verified finalized journals', () async {
    final fixture = await _completedWithStaleJournal(
      AuthoringTransactionStatus.preparing,
    );
    final harness = fixture.$1;
    addTearDown(harness.dispose);
    final journal = (await harness.readJournal())!.copyWith(
      status: AuthoringTransactionStatus.committed,
      finalReceipt: fixture.$2,
    );
    await harness.gateway.writeJournal(journal);
    final ledgerBefore = await File(harness.ledgerPath).readAsBytes();
    var historyChecks = 0;
    expect(await harness.transaction.prepareFinalizedJournals(
      requireHistory: (observed) async {
        historyChecks++;
        expect(observed.toJson(), journal.toJson());
      },
    ), 1);
    expect(historyChecks, 1);
    expect(await harness.gateway.listJournals(), isEmpty);
    expect(await File(harness.ledgerPath).readAsBytes(), ledgerBefore);
    expect(await harness.readA(), TransactionTestHarness.afterA);
    expect(await harness.transaction.prepareFinalizedJournals(
      requireHistory: (_) async => fail('No history should be inspected twice.'),
    ), 0);
  });

  for (final failure in ['pending', 'otherPending', 'receipt', 'history']) {
    test('explicit preparation preserves $failure recovery evidence', () async {
      final fixture = await _completedWithStaleJournal(
        AuthoringTransactionStatus.preparing,
      );
      final harness = fixture.$1;
      addTearDown(harness.dispose);
      final original = (await harness.readJournal())!;
      final journal = failure == 'pending' ? original : original.copyWith(
        status: AuthoringTransactionStatus.committed,
        finalReceipt: failure == 'receipt' ? AuthoringReceipt.fromJson({
          ...fixture.$2.toJson(),
          'extensions': {...fixture.$2.extensions, 'foreignCompletion': true},
        }) : fixture.$2,
      );
      await harness.gateway.writeJournal(journal);
      final pending = failure == 'otherPending'
          ? AuthoringTransactionJournal.fromJson({
              ...original.toJson(), 'operationId': 'zz-pending',
            }) : null;
      if (pending != null) await harness.gateway.writeJournal(pending);
      final ledgerBefore = await File(harness.ledgerPath).readAsBytes();
      var historyChecks = 0;
      await expectLater(harness.transaction.prepareFinalizedJournals(
        requireHistory: (_) async {
          historyChecks++;
          if (failure == 'history') {
            throw StateError('Retained history is unavailable.');
          }
        },
      ), throwsA(failure == 'history' ? isA<StateError>() :
          isA<JournaledAuthoringTransactionException>().having(
            (error) => error.code, 'code', failure.endsWith('Pending') || failure == 'pending'
                ? 'transaction.preparation_recovery_required'
                : 'transaction.preparation_receipt_required')));
      expect(historyChecks, failure == 'history' || pending != null ? 1 : 0);
      expect((await harness.readJournal())!.toJson(), journal.toJson());
      if (pending != null) {
        expect((await harness.gateway.readJournal(pending.operationId))!.toJson(), pending.toJson());
      }
      expect(await File(harness.ledgerPath).readAsBytes(), ledgerBefore);
      expect(await harness.readA(), TransactionTestHarness.afterA);
    });
  }

  for (final status in [
    AuthoringTransactionStatus.preparing,
    AuthoringTransactionStatus.staged,
    AuthoringTransactionStatus.prepared,
    AuthoringTransactionStatus.promoting,
  ]) {
    test('completed replay cleans stale ${status.name} journal without writes',
        () async {
      final fixture = await _completedWithStaleJournal(status);
      final harness = fixture.$1;
      addTearDown(harness.dispose);
      final ledgerBefore = await File(harness.ledgerPath).readAsBytes();
      await _cleanup(harness, fixture.$2);
      expect(await harness.readJournal(), isNull);
      expect(await harness.readA(), TransactionTestHarness.afterA);
      expect(await harness.readB(), TransactionTestHarness.afterB);
      expect(await harness.readCreated(), TransactionTestHarness.afterCreated);
      expect(await harness.readDeleted(), isNull);
      expect(await File(harness.ledgerPath).readAsBytes(), ledgerBefore);
    });
  }

  test('completed replay preserves stale journal when a resource changed',
      () async {
    final fixture = await _completedWithStaleJournal(
      AuthoringTransactionStatus.preparing,
    );
    final harness = fixture.$1;
    addTearDown(harness.dispose);
    final external = utf8.encode('{"external":true}');
    await harness.writeExternalA(external);
    final before = (await harness.readJournal())!.toJson();
    await _cleanup(harness, fixture.$2);
    expect((await harness.readJournal())!.toJson(), before);
    expect(await harness.readA(), external);
  });

  test('completed replay preserves stale journal with a different intent',
      () async {
    final fixture = await _completedWithStaleJournal(
      AuthoringTransactionStatus.preparing,
    );
    final harness = fixture.$1;
    addTearDown(harness.dispose);
    final json = (await harness.readJournal())!.toJson();
    json['intendedReceipt'] = {
      ...fixture.$2.toJson(),
      'receiptId': 'different-receipt',
    };
    await harness.gateway.writeJournal(
      AuthoringTransactionJournal.fromJson(json),
    );
    await _cleanup(harness, fixture.$2);
    expect((await harness.readJournal())!.toJson(), json);
  });

  test('completed replay preserves stale journal with a different final receipt',
      () async {
    final fixture = await _completedWithStaleJournal(
      AuthoringTransactionStatus.preparing,
    );
    final harness = fixture.$1;
    addTearDown(harness.dispose);
    final mismatched = AuthoringReceipt.fromJson({
      ...fixture.$2.toJson(),
      'receiptId': 'different-receipt',
    });
    final before = (await harness.readJournal())!.toJson();
    await _cleanup(harness, mismatched);
    expect((await harness.readJournal())!.toJson(), before);
  });
}

Future<(TransactionTestHarness, AuthoringReceipt)> _completedWithStaleJournal(
  AuthoringTransactionStatus status,
) async {
  late final TransactionTestHarness harness;
  AuthoringTransactionJournal? original;
  harness = await TransactionTestHarness.create(faultInjector: (context) async {
    if (context.checkpoint ==
        AuthoringTransactionCheckpoint.afterJournalPreparing) {
      original = await harness.readJournal();
    }
  });
  final receipt = await harness.apply();
  expect(await harness.readJournal(), isNull);
  await harness.gateway.writeJournal(original!.copyWith(status: status));
  final recovery = await harness.reopenRecovery();
  expect((await recovery.inspect()).single.disposition,
      AuthoringRecoveryDisposition.blocked);
  return (harness, receipt);
}

Future<void> _cleanup(
  TransactionTestHarness harness,
  AuthoringReceipt receipt,
) =>
    harness.transaction.cleanupCompletedReplay(
      scope: harness.scope,
      planId: harness.plan.planId,
      operationId: harness.operationId,
      receipt: receipt,
    );

import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import '../support/transaction_test_fixture.dart';

void main() {
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

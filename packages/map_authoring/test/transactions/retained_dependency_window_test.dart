import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import '../support/transaction_test_fixture.dart';

void main() {
  test('an external writer can change a retained file after precondition',
      () async {
    final original = utf8.encode('{"reference":"created"}');
    final changed = utf8.encode('{"reference":"other"}');
    late TransactionTestHarness harness;
    late File retained;
    var preconditionPassed = false;
    var changedBeforePromotion = false;
    harness = await TransactionTestHarness.create();
    addTearDown(harness.dispose);
    retained = File.fromUri(
      harness.projectDirectory.uri.resolve('data/retained.json'),
    );
    await retained.writeAsBytes(original);
    expect(
      harness.plan.changeSet.changes.map((change) => change.storageKey),
      isNot(contains('data/retained.json')),
    );
    final transaction = JournaledAuthoringTransaction(
      plans: harness.planStore,
      gateway: harness.gateway,
      idempotency: harness.ledger,
      clock: () => harness.now,
      faultInjector: (context) async {
        if (context.checkpoint ==
                AuthoringTransactionCheckpoint.beforeResourcePromotion &&
            context.storageKey == 'data/created.json') {
          expect(preconditionPassed, isTrue);
          await retained.writeAsBytes(changed);
          changedBeforePromotion = true;
        }
      },
    );

    final receipt = await transaction.apply(
      planId: harness.plan.planId,
      request: harness.plan.request,
      currentProjectRevision: harness.currentProjectRevision,
      scope: harness.scope,
      operationId: harness.operationId,
      precondition: () async {
        expect(await retained.readAsBytes(), original);
        preconditionPassed = true;
      },
    );

    expect(preconditionPassed, isTrue);
    expect(changedBeforePromotion, isTrue);
    expect(receipt.status, AuthoringReceiptStatus.applied);
    expect(await retained.readAsBytes(), changed);
    expect(await harness.readCreated(), TransactionTestHarness.afterCreated);
  });
}

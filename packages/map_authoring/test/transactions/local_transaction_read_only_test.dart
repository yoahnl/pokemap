import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import '../support/transaction_test_fixture.dart';

void main() {
  for (final prefix in ['', '.pokemap', '.pokemap/authoring']) {
    test('absent journals preserve the existing $prefix directory tree', () async {
      final root = await Directory.systemTemp.createTemp('journal-read-only-');
      addTearDown(() => root.delete(recursive: true));
      if (prefix.isNotEmpty) {
        await Directory('${root.path}/$prefix').create(recursive: true);
      }
      final gateway = await LocalTransactionFileGateway.open(projectRoot: root.path);
      final before = await _inventory(root);

      expect(await gateway.listJournals(), isEmpty);
      expect(await gateway.readJournal('missing-operation'), isNull);
      expect(await gateway.listJournals(), isEmpty);

      expect(await _inventory(root), before);
    });
  }

  test('an absent transaction namespace remains absent after journal reads', () async {
    final root = await Directory.systemTemp.createTemp('journal-read-only-');
    addTearDown(() => root.delete(recursive: true));
    await Directory('${root.path}/.pokemap/authoring/transactions').create(recursive: true);
    final gateway = await LocalTransactionFileGateway.open(projectRoot: root.path, transactionNamespace: 'catalog');
    final before = await _inventory(root);

    expect(await gateway.readJournal('missing-operation'), isNull);
    expect(await gateway.listJournals(), isEmpty);

    expect(await _inventory(root), before);
  });

  test('existing pending journals remain readable without any inventory change', () async {
    final harness = await TransactionTestHarness.create(faultInjector: (context) {
      if (context.checkpoint == AuthoringTransactionCheckpoint.afterJournalPrepared) {
        throw const AuthoringTransactionSimulatedCrash();
      }
    });
    addTearDown(harness.dispose);
    await expectLater(harness.apply(), throwsA(isA<AuthoringTransactionSimulatedCrash>()));
    final before = await _inventory(harness.projectDirectory);

    final listed = await harness.gateway.listJournals();
    final journal = await harness.gateway.readJournal(harness.operationId);
    expect(listed.single.operationId, harness.operationId);
    expect(journal!.status, AuthoringTransactionStatus.prepared);
    expect(await harness.gateway.readJournal('missing-operation'), isNull);

    expect(await _inventory(harness.projectDirectory), before);
  });

  for (final kind in ['file', 'symlink']) {
    test('unsafe $kind journal ancestors still fail closed without writes', () async {
      final root = await Directory.systemTemp.createTemp('journal-read-only-');
      addTearDown(() => root.delete(recursive: true));
      if (kind == 'file') {
        await File('${root.path}/.pokemap').writeAsString('keep');
      } else {
        await Directory('${root.path}/foreign').create();
        await Link('${root.path}/.pokemap').create('${root.path}/foreign');
      }
      final before = await _inventory(root);
      final gateway = await LocalTransactionFileGateway.open(projectRoot: root.path);

      await expectLater(gateway.listJournals(), throwsA(isA<TransactionFileGatewayException>()));
      await expectLater(gateway.readJournal('missing-operation'), throwsA(isA<TransactionFileGatewayException>()));

      expect(await _inventory(root), before);
    });
  }
}

Future<Map<String, String>> _inventory(Directory root) async => {
  await for (final entity in root.list(recursive: true, followLinks: false))
    entity.path.substring(root.path.length): entity is File
        ? base64Encode(await entity.readAsBytes())
        : entity is Link ? 'link:${await entity.target()}' : 'directory',
};

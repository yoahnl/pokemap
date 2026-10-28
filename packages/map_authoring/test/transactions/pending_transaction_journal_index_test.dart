import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';
import 'package:map_authoring/src/support/authoring_performance_observer.dart';

void main() {
  test('pending index growth rejects capacity before replacing a valid index',
      () async {
    final qa =
        Directory('/Users/karim/Library/Caches/AveluneQA/surf-v1/authoring');
    await qa.create(recursive: true);
    final root = await qa.createTemp('index-capacity-');
    addTearDown(() => root.delete(recursive: true));
    final gateway =
        await LocalTransactionFileGateway.open(projectRoot: root.path);
    await gateway.preparePendingJournalIndex();
    const maximum = 1024 * 1024;
    final base = utf8
        .encode(jsonEncode({'schemaVersion': 1, 'operationIds': []}))
        .length;
    final count = (maximum - base + 1) ~/ 123;
    final ids = [
      for (var i = 0; i < count; i++)
        '${i.toString().padLeft(8, '0')}${'x' * 112}'
    ];
    final bytes =
        utf8.encode(jsonEncode({'schemaVersion': 1, 'operationIds': ids}));
    expect(bytes.length, lessThanOrEqualTo(maximum));
    final index = File(
        '${root.path}/.pokemap/authoring/transactions/pending-journals.json');
    await index.writeAsBytes(bytes);
    await expectLater(
        gateway.writeJournal(_journal('new-${'y' * 116}')),
        throwsA(isA<TransactionFileGatewayException>().having(
            (error) => error.code,
            'code',
            'transaction.pending_index_capacity')));
    expect(await index.readAsBytes(), bytes);
  });

  test(
      'interrupted transaction retirement preserves indexed intent and staged payloads',
      () async {
    final qa =
        Directory('/Users/karim/Library/Caches/AveluneQA/surf-v1/authoring');
    await qa.create(recursive: true);
    final root = await qa.createTemp('retirement-');
    addTearDown(() => root.delete(recursive: true));
    final gateway =
        await LocalTransactionFileGateway.open(projectRoot: root.path);
    await gateway.preparePendingJournalIndex();
    await gateway.writeJournal(_journal('active', committed: true));
    await gateway.stagePayload(
        operationId: 'active',
        storageKey: 'data.json',
        kind: TransactionPayloadKind.after,
        bytes: [1, 2, 3]);
    final operationPath = '${root.path}/.pokemap/authoring/transactions/active';
    await expectLater(
        IOOverrides.runWithIOOverrides(
            () => gateway.deleteTransaction('active'),
            _RetirementCrash(operationPath)),
        throwsA(anything));
    expect(
        await Directory(
                '${root.path}/.pokemap/authoring/transactions/.retiring-active')
            .exists(),
        isTrue);
    expect((await gateway.listPendingJournals()).single.operationId, 'active');
    final staged = await gateway.readStagedPayload(
        operationId: 'active',
        storageKey: 'data.json',
        kind: TransactionPayloadKind.after);
    expect(await staged.payload!.readBytes(), [1, 2, 3]);
    await staged.payload!.release();
    await File(
            '${root.path}/.pokemap/authoring/transactions/pending-journals.json')
        .delete();
    await expectLater(
        gateway.listPendingJournals(),
        throwsA(isA<TransactionFileGatewayException>().having(
            (error) => error.code,
            'code',
            'transaction.pending_index_preparation_required')));
    await gateway.preparePendingJournalIndex();
    expect((await gateway.listPendingJournals()).single.operationId, 'active');
    await gateway.deleteTransaction('active');
    expect(await gateway.listPendingJournals(), isEmpty);
    expect(
        await Directory(
                '${root.path}/.pokemap/authoring/transactions/.retiring-active')
            .exists(),
        isFalse);
  });

  test('an inherited lock token expires before later asynchronous work runs',
      () async {
    final qa =
        Directory('/Users/karim/Library/Caches/AveluneQA/surf-v1/authoring');
    await qa.create(recursive: true);
    final root = await qa.createTemp('lock-lifetime-');
    addTearDown(() => root.delete(recursive: true));
    final first =
        await LocalTransactionFileGateway.open(projectRoot: root.path);
    final second =
        await LocalTransactionFileGateway.open(projectRoot: root.path);
    final trigger = Completer<void>();
    late Future<void> child;
    var entered = false;
    await first.withExclusiveWriteLock(() async {
      child = Future<void>(() async {
        await trigger.future;
        await first.withExclusiveWriteLock(() async {
          entered = true;
        });
      });
    });
    await second.withExclusiveWriteLock(() async {
      trigger.complete();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(entered, isFalse);
    });
    await child;
    expect(entered, isTrue);
  });

  for (final retained in [0, 2000]) {
    test(
        'pending journal reads ignore $retained retained finalized journals after explicit preparation',
        () async {
      final qa =
          Directory('/Users/karim/Library/Caches/AveluneQA/surf-v1/authoring');
      await qa.create(recursive: true);
      final root = await qa.createTemp('pending-');
      addTearDown(() => root.delete(recursive: true));
      final initial =
          await LocalTransactionFileGateway.open(projectRoot: root.path);
      await initial.preparePendingJournalIndex();
      for (var index = 0; index < retained; index++) {
        final journal = _journal('old-$index', committed: true);
        final file = File(
            '${root.path}/.pokemap/authoring/transactions/old-$index/journal.json');
        await file.parent.create(recursive: true);
        await file.writeAsString(jsonEncode(journal.toJson()));
      }
      final observer = _Observer();
      final gateway = await LocalTransactionFileGateway.open(
          projectRoot: root.path, performanceObserver: observer);
      await (gateway as dynamic).preparePendingJournalIndex();
      observer.counts.clear();
      expect(await (gateway as dynamic).listPendingJournals(), isEmpty);
      expect(observer.counts['json.decode'] ?? 0, lessThanOrEqualTo(1));
      await gateway.writeJournal(_journal('active'));
      observer.counts.clear();
      final pending = await (gateway as dynamic).listPendingJournals() as List;
      expect(pending.map((journal) => journal.operationId), ['active']);
      expect(observer.counts['json.decode'] ?? 0, lessThanOrEqualTo(3));
      await gateway.writeJournal(_journal('active', committed: true));
      expect(
          (await gateway.listPendingJournals()).single.operationId, 'active');
      await gateway.deleteTransaction('active');
      expect(await (gateway as dynamic).listPendingJournals(), isEmpty);
    });
  }
  test(
      'concurrent journal writers inside one filesystem lock retain both reservations',
      () async {
    final qa =
        Directory('/Users/karim/Library/Caches/AveluneQA/surf-v1/authoring');
    await qa.create(recursive: true);
    final root = await qa.createTemp('concurrent-');
    addTearDown(() => root.delete(recursive: true));
    final first =
        await LocalTransactionFileGateway.open(projectRoot: root.path);
    final second =
        await LocalTransactionFileGateway.open(projectRoot: root.path);
    await first.preparePendingJournalIndex();
    await first.withExclusiveWriteLock(() => Future.wait([
          first.writeJournal(_journal('first')),
          second.writeJournal(_journal('second')),
        ]));
    expect(
        (await first.listPendingJournals())
            .map((journal) => journal.operationId),
        ['first', 'second']);
  });

  test(
      'a durable reservation restores the journal intent after publication interruption',
      () async {
    final qa =
        Directory('/Users/karim/Library/Caches/AveluneQA/surf-v1/authoring');
    await qa.create(recursive: true);
    final root = await qa.createTemp('reserved-');
    addTearDown(() => root.delete(recursive: true));
    final gateway =
        await LocalTransactionFileGateway.open(projectRoot: root.path);
    await gateway.preparePendingJournalIndex();
    final journal = _journal('reserved');
    final file = File(
        '${root.path}/.pokemap/authoring/transactions/reserved/journal-reservation.json');
    await file.parent.create();
    await file.writeAsString(jsonEncode(journal.toJson()));
    await File(
            '${root.path}/.pokemap/authoring/transactions/pending-journals.json')
        .writeAsString(jsonEncode({
      'schemaVersion': 1,
      'operationIds': ['reserved']
    }));
    expect((await gateway.listPendingJournals()).single.toJson(),
        journal.toJson());
    expect((await gateway.readJournal('reserved'))!.toJson(), journal.toJson());
    await gateway.deleteTransaction('reserved');
    expect(await gateway.listPendingJournals(), isEmpty);
  });

  test('an unknown reservation without durable intent fails closed', () async {
    final qa =
        Directory('/Users/karim/Library/Caches/AveluneQA/surf-v1/authoring');
    await qa.create(recursive: true);
    final root = await qa.createTemp('missing-reservation-');
    addTearDown(() => root.delete(recursive: true));
    final gateway =
        await LocalTransactionFileGateway.open(projectRoot: root.path);
    await gateway.preparePendingJournalIndex();
    final index = File(
        '${root.path}/.pokemap/authoring/transactions/pending-journals.json');
    final bytes = utf8.encode(jsonEncode({
      'schemaVersion': 1,
      'operationIds': ['unknown']
    }));
    await index.writeAsBytes(bytes);
    await expectLater(
        gateway.listPendingJournals(),
        throwsA(isA<TransactionFileGatewayException>().having(
            (error) => error.code,
            'code',
            'transaction.pending_journal_missing')));
    expect(await index.readAsBytes(), bytes);
  });

  test('legacy terminal journals remain active until finalization is verified',
      () async {
    final qa =
        Directory('/Users/karim/Library/Caches/AveluneQA/surf-v1/authoring');
    await qa.create(recursive: true);
    final root = await qa.createTemp('terminal-reservation-');
    addTearDown(() => root.delete(recursive: true));
    final file = File(
        '${root.path}/.pokemap/authoring/transactions/terminal/journal.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(
        jsonEncode(_journal('terminal', committed: true).toJson()));
    final gateway =
        await LocalTransactionFileGateway.open(projectRoot: root.path);
    await gateway.preparePendingJournalIndex();
    expect((await gateway.listPendingJournals()).single.status,
        AuthoringTransactionStatus.committed);
  });

  test('explicit legacy preparation preserves an existing pending journal',
      () async {
    final qa =
        Directory('/Users/karim/Library/Caches/AveluneQA/surf-v1/authoring');
    await qa.create(recursive: true);
    final root = await qa.createTemp('legacy-pending-');
    addTearDown(() => root.delete(recursive: true));
    final file = File(
        '${root.path}/.pokemap/authoring/transactions/pending/journal.json');
    await file.parent.create(recursive: true);
    final bytes = utf8.encode(jsonEncode(_journal('pending').toJson()));
    await file.writeAsBytes(bytes);
    final gateway =
        await LocalTransactionFileGateway.open(projectRoot: root.path);
    await (gateway as dynamic).preparePendingJournalIndex();
    final pending = await (gateway as dynamic).listPendingJournals() as List;
    expect(pending.single.operationId, 'pending');
    expect(await file.readAsBytes(), bytes);
  });
}

AuthoringTransactionJournal _journal(String operation,
    {bool committed = false}) {
  final resource = AuthoringResourceRef(kind: 'project', id: 'project');
  final before = 'sha256:${'0' * 64}';
  final after = 'sha256:${'1' * 64}';
  final receipt = AuthoringReceipt(
      receiptId: 'receipt',
      requestId: 'request',
      actionId: 'fixture.write',
      actionVersion: 1,
      status: AuthoringReceiptStatus.applied,
      createdAtUtc: '2026-10-28T00:00:00.000Z',
      beforeRevision: AuthoringRevisionSet(
              [AuthoringResourceRevision(resource: resource, revision: before)])
          .fingerprint,
      afterRevision: AuthoringRevisionSet(
              [AuthoringResourceRevision(resource: resource, revision: after)])
          .fingerprint,
      diff: AuthoringDiff([
        AuthoringDiffEntry(
            operation: AuthoringDiffOperation.replace,
            resource: resource,
            path: '/',
            before: false,
            after: true)
      ]));
  return AuthoringTransactionJournal(
      operationId: operation,
      planId: 'plan',
      scope: AuthoringIdempotencyScope(
          actorId: 'actor',
          projectId: 'project',
          actionId: 'fixture.write',
          actionVersion: 1,
          key: operation),
      status: committed
          ? AuthoringTransactionStatus.committed
          : AuthoringTransactionStatus.prepared,
      createdAt: DateTime.utc(2026, 10, 28),
      updatedAt: DateTime.utc(2026, 10, 28),
      entries: [
        AuthoringTransactionJournalEntry(
            resource: resource,
            storageKey: 'project.json',
            beforeRevision: before,
            afterRevision: after)
      ],
      intendedReceipt: receipt,
      finalReceipt: committed ? receipt : null);
}

final class _Observer implements AuthoringPerformanceObserver {
  final counts = <String, int>{};
  @override
  void incrementCounter(String name, {int by = 1}) =>
      counts.update(name, (value) => value + by, ifAbsent: () => by);
  @override
  AuthoringPerformanceSpan? startSpan(String name) => null;
}

final class _RetirementCrash extends IOOverrides {
  _RetirementCrash(this.operationPath);
  final String operationPath;
  @override
  Directory createDirectory(String path) {
    final directory = super.createDirectory(path);
    return path == operationPath ? _RetirementDirectory(directory) : directory;
  }
}

final class _RetirementDirectory implements Directory {
  _RetirementDirectory(this.directory);
  final Directory directory;
  @override
  String get path => directory.path;
  @override
  Future<Directory> rename(String newPath) async {
    await directory.rename(newPath);
    throw StateError('simulated crash after atomic retirement');
  }

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) =>
      directory.delete(recursive: recursive);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

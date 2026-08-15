import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import '../support/transaction_test_fixture.dart';

void main() {
  group('FileAuthoringHistoryStore', () {
    test('paginates a stable newest-first snapshot with opaque cursors',
        () async {
      final project = await Directory.systemTemp.createTemp('pokemap_history_');
      addTearDown(() => project.delete(recursive: true));
      final store = await FileAuthoringHistoryStore.open(
        projectRoot: project.path,
      );
      for (var index = 0; index < 5; index++) {
        await store.append(_entry(index));
      }

      final first = await store.list(projectId: 'project-history', limit: 2);
      expect(first.entries.map((entry) => entry.entryId),
          ['receipt-4', 'receipt-3']);
      expect(first.nextCursor, isNotNull);
      expect(first.nextCursor.toString(), startsWith('history-cursor:'));

      await store.append(_entry(5));
      final transported = AuthoringHistoryCursor.fromWireValue(
        first.nextCursor!.wireValue,
      );
      final wire = transported.wireValue;
      final tampered = AuthoringHistoryCursor.fromWireValue(
        '${wire.substring(0, wire.length - 1)}${wire.endsWith('A') ? 'B' : 'A'}',
      );
      await expectLater(
        () => store.list(
          projectId: 'project-history',
          limit: 2,
          cursor: tampered,
        ),
        _throwsHistory('history.cursor_invalid'),
      );
      await expectLater(
        () => store.list(
          projectId: 'project-other',
          limit: 2,
          cursor: transported,
        ),
        _throwsHistory('history.cursor_invalid'),
      );
      final second = await store.list(
        projectId: 'project-history',
        limit: 2,
        cursor: transported,
      );
      final third = await store.list(
        projectId: 'project-history',
        limit: 2,
        cursor: second.nextCursor,
      );

      expect(second.entries.map((entry) => entry.entryId),
          ['receipt-2', 'receipt-1']);
      expect(third.entries.map((entry) => entry.entryId), ['receipt-0']);
      expect(third.nextCursor, isNull);
      expect(
        [...first.entries, ...second.entries, ...third.entries]
            .map((entry) => entry.entryId),
        isNot(contains('receipt-5')),
      );

      final reopened = await FileAuthoringHistoryStore.open(
        projectRoot: project.path,
      );
      expect(
        (await reopened.list(projectId: 'project-history', limit: 10))
            .entries
            .first
            .entryId,
        'receipt-5',
      );
    });

    test('non-undoable reason is durable and first reason remains stable',
        () async {
      final project = await Directory.systemTemp.createTemp('pokemap_history_');
      addTearDown(() => project.delete(recursive: true));
      final store = await FileAuthoringHistoryStore.open(
        projectRoot: project.path,
      );
      await store.append(_entry(1));
      await store.markNonUndoable(
        projectId: 'project-history',
        entryId: 'receipt-1',
        reason: 'history.blob_missing',
      );
      await store.markNonUndoable(
        projectId: 'project-history',
        entryId: 'receipt-1',
        reason: 'history.other_reason',
      );

      final reopened = await FileAuthoringHistoryStore.open(
        projectRoot: project.path,
      );
      expect(
        (await reopened.get(
          projectId: 'project-history',
          entryId: 'receipt-1',
        ))!
            .nonUndoableReason,
        'history.blob_missing',
      );
    });

    test('reuses a validated append index and detects external changes',
        () async {
      final project = await Directory.systemTemp.createTemp('pokemap_history_');
      addTearDown(() => project.delete(recursive: true));
      final seed = await FileAuthoringHistoryStore.open(
        projectRoot: project.path,
      );
      await seed.append(_entry(0));
      var fullReads = 0;
      final store = await FileAuthoringHistoryStore.open(
        projectRoot: project.path,
        onFullRead: () => fullReads += 1,
      );

      await store.append(_entry(1));
      await store.append(_entry(2));
      expect(fullReads, 1);

      final file = File(
        [
          project.path,
          '.pokemap',
          'authoring',
          'history.jsonl',
        ].join(Platform.pathSeparator),
      );
      await file.writeAsString('{"corrupt":true}\n', mode: FileMode.append);
      await expectLater(
        () => store.append(_entry(3)),
        throwsA(
          isA<AuthoringHistoryStoreException>().having(
            (error) => error.code,
            'code',
            'history.store_corrupt',
          ),
        ),
      );
      expect(fullReads, 2);
    });

    test('offloads large history verification through the executor', () async {
      final project = await Directory.systemTemp.createTemp('pokemap_history_');
      addTearDown(() => project.delete(recursive: true));
      final seed = await FileAuthoringHistoryStore.open(
        projectRoot: project.path,
      );
      await seed.append(_entry(0));
      final worker = _CountingHistoryDecodeWorker();
      final executor = FileAuthoringHistoryDecodeExecutor(
        offloadThresholdBytes: 0,
        workerRunner: worker.run,
      );
      final reopened = await FileAuthoringHistoryStore.open(
        projectRoot: project.path,
        decodeExecutor: executor,
      );

      await reopened.append(_entry(1));

      expect(worker.calls, 1);
      expect(executor.diagnostics.localOperations, 0);
      expect(executor.diagnostics.workerOperations, 1);
      expect(executor.diagnostics.workerFailures, 0);
      expect(
        (await reopened.list(projectId: 'project-history', limit: 10))
            .entries
            .map((entry) => entry.entryId),
        ['receipt-1', 'receipt-0'],
      );
    });
  });

  group('FileAuthoringContentBlobStore', () {
    test('deduplicates identical bytes and makes pruning explicit', () async {
      final project = await Directory.systemTemp.createTemp('pokemap_blobs_');
      addTearDown(() => project.delete(recursive: true));
      final store = await FileAuthoringContentBlobStore.open(
        projectRoot: project.path,
      );
      final bytes = utf8.encode('{"same":true}');

      final first = await store.put(bytes);
      final second = await store.put(List<int>.from(bytes));
      expect(second.id, first.id);
      expect(await store.listIds(), [first.id]);
      expect(await store.get(first.id), bytes);

      expect(await store.prune(retainIds: const {}), 1);
      expect(await store.get(first.id), isNull);
      expect(await store.listIds(), isEmpty);
    });
  });

  test('recovery records one exact history entry after a hook interruption',
      () async {
    final harness = await TransactionTestHarness.create();
    addTearDown(harness.dispose);
    final history = await FileAuthoringHistoryStore.open(
      projectRoot: harness.projectDirectory.path,
    );
    final blobs = await FileAuthoringContentBlobStore.open(
      projectRoot: harness.projectDirectory.path,
    );
    final recorder = AuthoringHistoryRecorder(store: history, blobs: blobs);
    final transaction = JournaledAuthoringTransaction(
      plans: harness.planStore,
      gateway: harness.gateway,
      idempotency: harness.ledger,
      clock: () => harness.now,
      commitHook: _RecordThenFailOnce(recorder),
    );

    await expectLater(
      () => transaction.apply(
        planId: harness.plan.planId,
        request: harness.plan.request,
        currentProjectRevision: harness.currentProjectRevision,
        scope: harness.scope,
        operationId: harness.operationId,
      ),
      throwsA(isA<StateError>()),
    );
    expect(
      (await history.list(projectId: harness.scope.projectId, limit: 10))
          .entries,
      hasLength(1),
    );

    final recovery = AuthoringRecoveryService(
      gateway: harness.gateway,
      idempotency: harness.ledger,
      clock: () => harness.now,
      commitHook: recorder,
    );
    final recovered = await recovery.resume(harness.operationId);
    final entries =
        (await history.list(projectId: harness.scope.projectId, limit: 10))
            .entries;
    expect(recovered.status, AuthoringReceiptStatus.recovered);
    expect(entries, hasLength(1));
    expect(entries.single.receipt.status, AuthoringReceiptStatus.applied);
    expect(await blobs.listIds(), isNotEmpty);
  });
}

final class _RecordThenFailOnce implements AuthoringTransactionCommitHook {
  _RecordThenFailOnce(this._delegate);

  final AuthoringTransactionCommitHook _delegate;
  var _failed = false;

  @override
  Future<void> record(AuthoringCommittedMutation mutation) async {
    await _delegate.record(mutation);
    if (!_failed) {
      _failed = true;
      throw StateError('Simulated interruption after history persistence.');
    }
  }
}

final class _CountingHistoryDecodeWorker {
  var calls = 0;

  Future<T> run<T>(T Function() operation) async {
    calls++;
    return operation();
  }
}

AuthoringHistoryEntry _entry(int index) {
  final resource = AuthoringResourceRef(kind: 'fixture', id: 'item-$index');
  final before = _fingerprint(index + 1);
  final after = _fingerprint(index + 101);
  final receipt = AuthoringReceipt(
    receiptId: 'receipt-$index',
    requestId: 'request-$index',
    actionId: 'fixture.history',
    actionVersion: 1,
    status: AuthoringReceiptStatus.applied,
    beforeRevision: before,
    afterRevision: after,
    createdAtUtc: DateTime.utc(2026, 7, 31, 14, index).toIso8601String(),
    diff: AuthoringDiff([
      AuthoringDiffEntry(
        operation: AuthoringDiffOperation.replace,
        resource: resource,
        path: r'$.value',
        before: index,
        after: index + 1,
      ),
    ]),
  );
  return AuthoringHistoryEntry(
    entryId: receipt.receiptId,
    projectId: 'project-history',
    actorId: 'actor-history',
    planId: 'plan-$index',
    operationId: 'operation-$index',
    kind: AuthoringHistoryKind.mutation,
    receipt: receipt,
    committedAt: DateTime.utc(2026, 7, 31, 14, index),
    changes: [
      AuthoringHistoryResourceChange(
        resource: resource,
        storageKey: 'data/item-$index.json',
        beforeRevision: before,
        afterRevision: after,
        beforeBlobId: _fingerprint(index + 201),
        afterBlobId: _fingerprint(index + 301),
      ),
    ],
  );
}

String _fingerprint(int seed) =>
    'sha256:${seed.toRadixString(16).padLeft(64, '0').substring(0, 64)}';

Matcher _throwsHistory(String code) => throwsA(
      isA<AuthoringHistoryException>().having(
        (error) => error.code,
        'code',
        code,
      ),
    );

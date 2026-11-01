import 'dart:io';
import 'dart:async';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/transactions/authoring_payload.dart';
import 'package:test/test.dart';
import '../support/transaction_test_fixture.dart';

void main() {
  Future<List<File>> staged(TransactionTestHarness h) async => (await Directory(
          '${h.projectDirectory.path}/.pokemap/authoring/transactions/${h.operationId}')
      .list()
      .where((e) =>
          e is File &&
          (e.path.endsWith('.before.bin') || e.path.endsWith('.after.bin')))
      .cast<File>()
      .toList());
  Future<void> corrupt(TransactionTestHarness h) async {
    for (final file in await staged(h)) {
      final bytes = await file.readAsBytes();
      if (bytes.isNotEmpty) {
        bytes[0] ^= 1;
        await file.writeAsBytes(bytes, flush: true);
      }
    }
  }

  Future<void> expectPromoted(TransactionTestHarness h) async {
    expect(await h.readA(), TransactionTestHarness.afterA);
    expect(await h.readB(), TransactionTestHarness.afterB);
    expect(await h.readCreated(), TransactionTestHarness.afterCreated);
    expect(await h.readDeleted(), isNull);
  }

  Future<void> expectHistory(
      TransactionTestHarness h,
      FileAuthoringHistoryStore history,
      FileAuthoringContentBlobStore blobs) async {
    final entry = (await history.list(projectId: h.scope.projectId, limit: 1))
        .entries
        .single;
    for (final change in h.plan.changeSet.changes) {
      final saved =
          entry.changes.singleWhere((e) => e.storageKey == change.storageKey);
      for (final pair in [
        (saved.beforeBlobId, change.beforePayload),
        (saved.afterBlobId, change.afterPayload)
      ]) {
        if (pair.$2 == null) {
          expect(pair.$1, isNull);
          continue;
        }
        final payload = await blobs.get(pair.$1!);
        expect(await payload!.readBytes(), await pair.$2!.readBytes());
        await payload.release();
      }
    }
  }

  Future<AuthoringReceipt> apply(
          TransactionTestHarness h, JournaledAuthoringTransaction tx) =>
      tx.apply(
          planId: h.plan.planId,
          request: h.plan.request,
          currentProjectRevision: h.currentProjectRevision,
          scope: h.scope,
          operationId: h.operationId);

  test(
      'history receives original owned inline images after physical staging checks',
      () async {
    final h = await TransactionTestHarness.create();
    addTearDown(h.dispose);
    final history = await FileAuthoringHistoryStore.open(
        projectRoot: h.projectDirectory.path);
    final blobs = await FileAuthoringContentBlobStore.open(
        projectRoot: h.projectDirectory.path);
    final recorder = AuthoringHistoryRecorder(store: history, blobs: blobs);
    var calls = 0;
    var finalizing = false;
    var finalReads = 0;
    var finalPresentReads = 0;
    final gateway = _Gateway(h.gateway, (value, key, kind) {
      if (finalizing) {
        finalReads++;
        if (value.payload != null) finalPresentReads++;
      }
      return value;
    });
    final hook = _Hook((mutation) async {
      calls++;
      expect(finalReads, h.plan.changeSet.changes.length * 2);
      expect(finalPresentReads, 6);
      for (final change in mutation.changes) {
        final original = h.plan.changeSet.changes
            .singleWhere((e) => e.storageKey == change.storageKey);
        expect(identical(change.beforePayload, original.beforePayload), isTrue);
        expect(identical(change.afterPayload, original.afterPayload), isTrue);
      }
      await corrupt(h);
      await recorder.record(mutation);
    });
    final tx = JournaledAuthoringTransaction(
        plans: h.planStore,
        gateway: gateway,
        idempotency: h.ledger,
        clock: () => h.now,
        commitHook: hook,
        faultInjector: (c) {
          if (c.checkpoint ==
              AuthoringTransactionCheckpoint.afterJournalCommitted) {
            finalizing = true;
          }
        });
    final receipt = await apply(h, tx);
    expect(calls, 1);
    await expectPromoted(h);
    await expectHistory(h, history, blobs);
    expect((await apply(h, tx)).toJson(), receipt.toJson());
    expect(calls, 1);
  });

  test(
      'corruption at committed checkpoint still requires finalization and leaves promoted bytes intact',
      () async {
    final h = await TransactionTestHarness.create();
    addTearDown(h.dispose);
    final history = await FileAuthoringHistoryStore.open(
        projectRoot: h.projectDirectory.path);
    final blobs = await FileAuthoringContentBlobStore.open(
        projectRoot: h.projectDirectory.path);
    final tx = JournaledAuthoringTransaction(
        plans: h.planStore,
        gateway: h.gateway,
        idempotency: h.ledger,
        clock: () => h.now,
        commitHook: AuthoringHistoryRecorder(store: history, blobs: blobs),
        faultInjector: (c) async {
          if (c.checkpoint ==
              AuthoringTransactionCheckpoint.afterJournalCommitted) {
            await corrupt(h);
          }
        });
    await expectLater(
        apply(h, tx),
        throwsA(isA<JournaledAuthoringTransactionException>().having(
            (e) => e.code, 'code', 'transaction.finalization_required')));
    await expectPromoted(h);
    expect(
        (await history.list(projectId: h.scope.projectId, limit: 10)).entries,
        isEmpty);
  });

  for (final mismatch in ['presence', 'key', 'revision', 'length']) {
    test('final staging $mismatch mismatch cannot be hidden by inline handoff',
        () async {
      final h = await TransactionTestHarness.create();
      addTearDown(h.dispose);
      var finalizing = false;
      final gateway = _Gateway(h.gateway, (value, key, kind) {
        if (!finalizing ||
            key != 'data/a.json' ||
            kind != TransactionPayloadKind.before) {
          return value;
        }
        if (mismatch == 'presence') {
          return TransactionStagedPayload(storageKey: key, bytes: null);
        }
        if (mismatch == 'key') {
          return TransactionStagedPayload.withPayload(
              storageKey: 'data/wrong.json', payload: value.payload);
        }
        final bytes = TransactionTestHarness.beforeA.toList();
        if (mismatch == 'length') {
          bytes.add(0);
        } else {
          bytes[0] ^= 1;
        }
        return TransactionStagedPayload(storageKey: key, bytes: bytes);
      });
      var hookCalled = false;
      final tx = JournaledAuthoringTransaction(
          plans: h.planStore,
          gateway: gateway,
          idempotency: h.ledger,
          clock: () => h.now,
          commitHook: _Hook((_) async {
            hookCalled = true;
          }),
          faultInjector: (c) {
            if (c.checkpoint ==
                AuthoringTransactionCheckpoint.afterJournalCommitted) {
              finalizing = true;
            }
          });
      await expectLater(
          apply(h, tx),
          throwsA(isA<JournaledAuthoringTransactionException>().having(
              (e) => e.code, 'code', 'transaction.finalization_required')));
      expect(hookCalled, isFalse);
      await expectPromoted(h);
    });
  }

  for (final failure in ['none', 'mismatch', 'hook']) {
    test('captured staging leases release once after $failure handoff',
        () async {
      final h = await TransactionTestHarness.create();
      addTearDown(h.dispose);
      var finalizing = false;
      final releases = <String, int>{};
      final gateway = _Gateway(h.gateway, (value, key, kind) async {
        if (!finalizing || value.payload == null) return value;
        final source = value.payload!;
        final id = '$key:${kind.name}';
        releases[id] = 0;
        final captured = await AuthoringPayload.verifiedSource(
            storageKey: source.storageKey,
            byteLength: source.byteLength,
            rawSha256: source.rawSha256,
            resourceRevision: source.resourceRevision,
            openRead: source.openRead,
            release: () async {
              releases[id] = releases[id]! + 1;
              await source.release();
            });
        return TransactionStagedPayload.withPayload(
            storageKey: failure == 'mismatch' && key == 'data/a.json'
                ? 'data/wrong.json'
                : key,
            payload: captured);
      });
      final tx = JournaledAuthoringTransaction(
          plans: h.planStore,
          gateway: gateway,
          idempotency: h.ledger,
          clock: () => h.now,
          faultInjector: (c) {
            if (c.checkpoint ==
                AuthoringTransactionCheckpoint.afterJournalCommitted) {
              finalizing = true;
            }
          },
          commitHook: _Hook((mutation) async {
            if (failure == 'hook') throw StateError('hook failure');
          }));
      if (failure == 'none') {
        await apply(h, tx);
        expect(releases, hasLength(6));
      } else {
        await expectLater(apply(h, tx),
            throwsA(isA<JournaledAuthoringTransactionException>()));
        expect(releases, isNotEmpty);
      }
      expect(releases.values, everyElement(1));
      await expectPromoted(h);
    });
  }

  test('stored plan payloads keep the verified staging fallback', () async {
    final h = await TransactionTestHarness.create();
    addTearDown(h.dispose);
    final changes = <AuthoringResourceChange>[];
    for (final change in h.plan.changeSet.changes) {
      Future<AuthoringPayload?> stored(AuthoringPayload? value) async =>
          value == null
              ? null
              : AuthoringPayload.verifiedSource(
                  storageKey: value.storageKey,
                  byteLength: value.byteLength,
                  rawSha256: value.rawSha256,
                  resourceRevision: value.resourceRevision,
                  openRead: value.openRead);
      changes.add(AuthoringResourceChange.withPayloads(
          resource: change.resource,
          storageKey: change.storageKey,
          beforePayload: await stored(change.beforePayload),
          afterPayload: await stored(change.afterPayload),
          beforeRevision: change.beforeRevision,
          afterRevision: change.afterRevision));
    }
    final plan = AuthoringPlan(
        planId: h.plan.planId,
        receiptId: h.plan.receiptId,
        request: h.plan.request,
        baseRevision: h.plan.baseRevision,
        seed: h.plan.seed,
        createdAt: h.plan.createdAt,
        expiresAt: h.plan.expiresAt,
        changeSet:
            AuthoringChangeSet(changes: changes, diff: h.plan.changeSet.diff));
    final plans = AuthoringPlanStore(clock: () => h.now)..save(plan);
    final history = await FileAuthoringHistoryStore.open(
        projectRoot: h.projectDirectory.path);
    final blobs = await FileAuthoringContentBlobStore.open(
        projectRoot: h.projectDirectory.path);
    final recorder = AuthoringHistoryRecorder(store: history, blobs: blobs);
    var called = false;
    final tx = JournaledAuthoringTransaction(
        plans: plans,
        gateway: h.gateway,
        idempotency: h.ledger,
        clock: () => h.now,
        commitHook: _Hook((mutation) async {
          called = true;
          for (final change in mutation.changes) {
            final original = plan.changeSet.changes
                .singleWhere((e) => e.storageKey == change.storageKey);
            for (final pair in [
              (change.beforePayload, original.beforePayload),
              (change.afterPayload, original.afterPayload)
            ]) {
              if (pair.$1 != null) {
                expect(pair.$1!.isInline, isFalse);
                expect(identical(pair.$1, pair.$2), isFalse);
              }
            }
          }
          await recorder.record(mutation);
        }));
    await apply(h, tx);
    expect(called, isTrue);
    await expectPromoted(h);
    await expectHistory(h, history, blobs);
  });

  test(
      'recovery without the plan retains its staging sources and exact history bytes',
      () async {
    final h = await TransactionTestHarness.create();
    addTearDown(h.dispose);
    final history = await FileAuthoringHistoryStore.open(
        projectRoot: h.projectDirectory.path);
    final blobs = await FileAuthoringContentBlobStore.open(
        projectRoot: h.projectDirectory.path);
    final tx = JournaledAuthoringTransaction(
        plans: h.planStore,
        gateway: h.gateway,
        idempotency: h.ledger,
        clock: () => h.now,
        faultInjector: (c) {
          if (c.checkpoint ==
              AuthoringTransactionCheckpoint.afterJournalCommitted) {
            throw const AuthoringTransactionSimulatedCrash();
          }
        });
    await expectLater(
        apply(h, tx), throwsA(isA<AuthoringTransactionSimulatedCrash>()));
    final recorder = AuthoringHistoryRecorder(store: history, blobs: blobs);
    var called = false;
    final recovery = AuthoringRecoveryService(
        gateway: h.gateway,
        idempotency: h.ledger,
        clock: () => h.now,
        commitHook: _Hook((mutation) async {
          called = true;
          for (final change in mutation.changes) {
            for (final p in [change.beforePayload, change.afterPayload]) {
              if (p != null) expect(p.isInline, isFalse);
            }
          }
          await recorder.record(mutation);
        }));
    await recovery.resume(h.operationId);
    expect(called, isTrue);
    await expectPromoted(h);
    await expectHistory(h, history, blobs);
  });
}

class _Hook implements AuthoringTransactionCommitHook {
  _Hook(this.body);
  final Future<void> Function(AuthoringCommittedMutation) body;
  @override
  Future<void> record(AuthoringCommittedMutation mutation) => body(mutation);
}

class _Gateway
    implements TransactionFileGateway, StreamingTransactionFileGateway {
  _Gateway(this.delegate, this.transform);
  final LocalTransactionFileGateway delegate;
  final FutureOr<TransactionStagedPayload> Function(
      TransactionStagedPayload, String, TransactionPayloadKind) transform;
  @override
  Future<T> withExclusiveWriteLock<T>(Future<T> Function() operation) =>
      delegate.withExclusiveWriteLock(operation);
  @override
  Future<List<int>?> readResource(String key) => delegate.readResource(key);
  @override
  Future<String?> readResourceRevision(String key) =>
      delegate.readResourceRevision(key);
  @override
  Future<void> stagePayload(
          {required String operationId,
          required String storageKey,
          required TransactionPayloadKind kind,
          required List<int>? bytes}) =>
      delegate.stagePayload(
          operationId: operationId,
          storageKey: storageKey,
          kind: kind,
          bytes: bytes);
  @override
  Future<void> stageAuthoringPayload(
          {required String operationId,
          required String storageKey,
          required TransactionPayloadKind kind,
          required AuthoringPayload? payload}) =>
      delegate.stageAuthoringPayload(
          operationId: operationId,
          storageKey: storageKey,
          kind: kind,
          payload: payload);
  @override
  Future<AuthoringPayload?> captureResourcePayload(String key) =>
      delegate.captureResourcePayload(key);
  @override
  Future<TransactionStagedPayload> readStagedPayload(
          {required String operationId,
          required String storageKey,
          required TransactionPayloadKind kind}) async =>
      transform(
          await delegate.readStagedPayload(
              operationId: operationId, storageKey: storageKey, kind: kind),
          storageKey,
          kind);
  @override
  Future<void> promoteStaged(
          {required String operationId,
          required String storageKey,
          required TransactionPayloadKind kind,
          required String? expectedCurrentRevision}) =>
      delegate.promoteStaged(
          operationId: operationId,
          storageKey: storageKey,
          kind: kind,
          expectedCurrentRevision: expectedCurrentRevision);
  @override
  Future<void> writeJournal(AuthoringTransactionJournal journal) =>
      delegate.writeJournal(journal);
  @override
  Future<AuthoringTransactionJournal?> readJournal(String id) =>
      delegate.readJournal(id);
  @override
  Future<List<AuthoringTransactionJournal>> listJournals() =>
      delegate.listJournals();
  @override
  Future<void> deleteTransaction(String id) => delegate.deleteTransaction(id);
}

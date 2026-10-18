import 'dart:io';

import 'package:map_authoring/src/catalog_storage/catalog_editing_session.dart';
import 'package:map_authoring/src/catalog_storage/catalog_storage_store.dart';
import 'package:map_authoring/src/history/authoring_history.dart';
import 'package:map_authoring/src/history/history_store.dart';
import 'package:map_authoring/src/transactions/journaled_transaction.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory directory;
  late CatalogStorageStore store;
  late CatalogEditingSession session;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('catalog-editing-');
    store = await CatalogStorageStore.open(projectRoot: directory.path);
    await store.publish(
        CatalogStorageBuilder().build([
          _unit('a', 'before'),
          _unit('b', 'untouched'),
        ]),
        expectedRootRevision: null);
    session = await _open(store);
  });

  tearDown(() async {
    await session.close();
    await directory.delete(recursive: true);
  });

  test('a unit edit commits only head bytes into canonical history', () async {
    final old = await session.retention.openSnapshot();
    addTearDown(old.close);
    final planned = await session
        .planPatch(upserts: [_unit('a', 'after')], idempotencyKey: 'change-a');
    expect(planned.plan.changeSet.changes, hasLength(1));
    final change = planned.plan.changeSet.changes.single;
    expect(change.storageKey, CatalogStorageStore.headStorageKey);
    expect(change.beforePayload!.byteLength, lessThan(4096));
    expect(change.afterPayload!.byteLength, lessThan(4096));
    final receipt = await session.apply(planned);
    expect(planned.plan.appliedPayloadReleased, isTrue);
    expect(
        (await session.snapshot.lookup(_key('a')))!.payload['name'], 'after');
    expect((await old.snapshot.lookup(_key('a')))!.payload['name'], 'before');
    final history = await session.history.list(projectId: 'game', limit: 10);
    expect(history.entries.single.entryId, receipt.receiptId);
    expect(history.entries.single.changes.single.resource.kind, 'catalogHead');
    expect((await session.apply(planned)).toJson(), receipt.toJson());
  });

  test('undo and redo survive reopening without decoding a project', () async {
    final planned = await session
        .planPatch(upserts: [_unit('a', 'after')], idempotencyKey: 'change-a');
    final receipt = await session.apply(planned);
    await session.close();
    session = await _open(store);
    await session.undo(entryId: receipt.receiptId, idempotencyKey: 'undo-a');
    expect(
        (await session.snapshot.lookup(_key('a')))!.payload['name'], 'before');
    await session.close();
    session = await _open(store);
    await session.redo(entryId: receipt.receiptId, idempotencyKey: 'redo-a');
    expect(
        (await session.snapshot.lookup(_key('a')))!.payload['name'], 'after');
    final history = await session.history.list(projectId: 'game', limit: 10);
    expect(history.entries.map((entry) => entry.kind), [
      AuthoringHistoryKind.redo,
      AuthoringHistoryKind.undo,
      AuthoringHistoryKind.mutation,
    ]);
  });

  for (final checkpoint in AuthoringTransactionCheckpoint.values) {
    test('restart reconciles ${checkpoint.name} through canonical recovery',
        () async {
      await session.close();
      session = await _open(store, faultInjector: (context) {
        if (context.checkpoint == checkpoint) {
          throw const AuthoringTransactionSimulatedCrash();
        }
      });
      final plan = await session
          .planPatch(upserts: [_unit('a', 'after')], idempotencyKey: 'crash-a');
      await expectLater(session.apply(plan),
          throwsA(isA<AuthoringTransactionSimulatedCrash>()));
      await session.close();
      session = await _open(store);
      await session.retention.collect(projectId: 'game',
          history: session.history, blobs: session.blobs);
      await (await store.openRoot(plan.root)).snapshot.validate();
      await expectLater(
          session.planPatch(
              upserts: [_unit('b', 'blocked')], idempotencyKey: 'blocked'),
          throwsA(isA<CatalogStorageException>().having(
              (error) => error.code, 'code', 'catalog.recovery_required')));
      final recovered = await session.reconcile(plan.operationId);
      final reserved = checkpoint.index >=
          AuthoringTransactionCheckpoint.afterReservation.index;
      expect((await session.snapshot.lookup(_key('a')))!.payload['name'],
          reserved ? 'after' : 'before');
      expect(recovered != null, reserved);
      expect(await store.gateway.listJournals(), isEmpty);
      await session.snapshot.validate();
      final next = await session.planPatch(
          upserts: [_unit('b', 'unblocked')], idempotencyKey: 'unblocked');
      await session.apply(next);
    });
  }

  test('a stale session cannot publish its prepared head', () async {
    final other = await _open(store);
    try {
      final stale = await session
          .planPatch(upserts: [_unit('a', 'stale')], idempotencyKey: 'stale');
      final fresh = await other
          .planPatch(upserts: [_unit('a', 'fresh')], idempotencyKey: 'fresh');
      await other.apply(fresh);
      await expectLater(
          session.apply(stale), throwsA(isA<CatalogStorageException>()));
      final observed = await session.openSnapshot();
      try {
        expect((await observed.snapshot.lookup(_key('a')))!.payload['name'],
            'fresh');
      } finally {
        await observed.close();
      }
    } finally {
      await other.close();
    }
  });

  test('a new branch rejects redo without overwriting the new unit', () async {
    final plan = await session
        .planPatch(upserts: [_unit('a', 'after')], idempotencyKey: 'after');
    final receipt = await session.apply(plan);
    await session.undo(entryId: receipt.receiptId, idempotencyKey: 'undo');
    await session.apply(await session
        .planPatch(upserts: [_unit('b', 'branch')], idempotencyKey: 'branch'));
    await expectLater(
        session.redo(entryId: receipt.receiptId, idempotencyKey: 'redo'),
        throwsA(isA<AuthoringHistoryException>().having(
            (error) => error.code, 'code', 'history.redo_branch_diverged')));
    expect(
        (await session.snapshot.lookup(_key('b')))!.payload['name'], 'branch');
  });

  test(
      'managed catalogs refuse direct publication and project identity aliases',
      () async {
    await expectLater(
        store.publish(
            CatalogStorageBuilder().build([
              _unit('a', 'bypass'),
            ]),
            expectedRootRevision: session.snapshot.root.sha256),
        throwsA(isA<CatalogStorageException>().having(
            (error) => error.code, 'code', 'catalog.editing_required')));
    await expectLater(
        CatalogEditingSession.open(
            store: store, projectId: 'another-game', actorId: 'editor'),
        throwsA(isA<CatalogStorageException>()));
    await expectLater(
        store.openSnapshot(),
        throwsA(isA<CatalogStorageException>()
            .having((error) => error.code, 'code', 'catalog.lease_required')));
  });

  for (final afterAppend in [false, true]) {
    test('history finalization failure afterAppend=$afterAppend is recoverable',
        () async {
      final durableHistory = session.history;
      await session.close();
      session = await CatalogEditingSession.open(
          store: store,
          projectId: 'game',
          actorId: 'editor',
          history: _FailHistory(durableHistory, afterAppend: afterAppend));
      final planned = await session.planPatch(
          upserts: [_unit('a', 'after')], idempotencyKey: 'history-fault');
      await expectLater(
          session.apply(planned),
          throwsA(isA<JournaledAuthoringTransactionException>().having(
              (error) => error.code,
              'code',
              'transaction.finalization_required')));
      await session.close();
      session = await _open(store);
      await session.reconcile(planned.operationId);
      expect(
          (await session.snapshot.lookup(_key('a')))!.payload['name'], 'after');
      final entries = await session.history.list(projectId: 'game', limit: 10);
      expect(entries.entries, hasLength(1));
      await session.undo(
          entryId: entries.entries.single.entryId,
          idempotencyKey: 'undo-finalized');
      expect((await session.snapshot.lookup(_key('a')))!.payload['name'],
          'before');
    });
  }

  test(
      'borrowed snapshots expire on refresh and independent readers retain old data',
      () async {
    final borrowed = session.snapshot;
    final retained = await session.openSnapshot();
    try {
      await session.apply(await session
          .planPatch(upserts: [_unit('a', 'after')], idempotencyKey: 'after'));
      await expectLater(
          borrowed.lookup(_key('a')),
          throwsA(isA<CatalogStorageException>()
              .having((error) => error.code, 'code', 'catalog.lease_closed')));
      expect((await retained.snapshot.lookup(_key('a')))!.payload['name'],
          'before');
      final current = session.snapshot;
      await session.close();
      await expectLater(
          current.lookup(_key('a')),
          throwsA(isA<CatalogStorageException>()
              .having((error) => error.code, 'code', 'catalog.lease_closed')));
    } finally {
      await retained.close();
    }
  });

  test('invalid identities are rejected before binding a new catalog',
      () async {
    final fresh =
        await Directory.systemTemp.createTemp('catalog-invalid-identity-');
    try {
      final freshStore =
          await CatalogStorageStore.open(projectRoot: fresh.path);
      await freshStore.publish(
          CatalogStorageBuilder().build([_unit('a', 'before')]),
          expectedRootRevision: null);
      for (final identities in [
        ('invalid/actor', 'game'),
        ('editor', 'invalid/project'),
        ('a@b', 'game'),
        ('editor', 'a@b'),
      ]) {
        await expectLater(
            CatalogEditingSession.open(
                store: freshStore,
                actorId: identities.$1,
                projectId: identities.$2),
            throwsA(anything));
        expect(await File('${fresh.path}/catalog/IDENTITY.json').exists(),
            isFalse);
      }
    } finally {
      await fresh.delete(recursive: true);
    }
  });

  test('opening an empty store cannot prevent its initial publication',
      () async {
    final fresh =
        await Directory.systemTemp.createTemp('catalog-empty-session-');
    try {
      final freshStore =
          await CatalogStorageStore.open(projectRoot: fresh.path);
      await expectLater(
          _open(freshStore), throwsA(isA<CatalogStorageException>()));
      expect(
          await File('${fresh.path}/catalog/IDENTITY.json').exists(), isFalse);
      await freshStore.publish(
          CatalogStorageBuilder().build([_unit('a', 'initial')]),
          expectedRootRevision: null);
    } finally {
      await fresh.delete(recursive: true);
    }
  });

  test('concurrent retries keep one coherent live snapshot and history entry',
      () async {
    final planned = await session.planPatch(
        upserts: [_unit('a', 'after')], idempotencyKey: 'concurrent');
    final receipts =
        await Future.wait([session.apply(planned), session.apply(planned)]);
    expect(receipts.first.toJson(), receipts.last.toJson());
    expect(
        (await session.snapshot.lookup(_key('a')))!.payload['name'], 'after');
    expect((await session.history.list(projectId: 'game', limit: 10)).entries,
        hasLength(1));
  });

  test(
      'compensation restores the complete previous generation after head promotion',
      () async {
    await session.close();
    session = await _open(store, faultInjector: (context) {
      if (context.checkpoint ==
          AuthoringTransactionCheckpoint.afterResourcePromoted) {
        throw const AuthoringTransactionSimulatedCrash();
      }
    });
    final planned = await session.planPatch(
        upserts: [_unit('a', 'after')], idempotencyKey: 'compensate');
    await expectLater(session.apply(planned),
        throwsA(isA<AuthoringTransactionSimulatedCrash>()));
    await session.reconcile(planned.operationId, compensate: true);
    expect(
        (await session.snapshot.lookup(_key('a')))!.payload['name'], 'before');
    await session.snapshot.validate();
    expect(await store.gateway.listJournals(), isEmpty);
  });

  test('an invalid undo key cannot leak a preparation lease', () async {
    final receipt = await session.apply(await session
        .planPatch(upserts: [_unit('a', 'after')], idempotencyKey: 'after'));
    final leases = Directory('${directory.path}/catalog/leases');
    final before = (await leases.list().toList()).length;
    await expectLater(
        session.undo(entryId: receipt.receiptId, idempotencyKey: ''),
        throwsA(anything));
    expect((await leases.list().toList()).length, before);
  });

  test('reconciliation invalidates a discarded plan before garbage collection',
      () async {
    await session.close();
    session = await _open(store, faultInjector: (context) {
      if (context.checkpoint ==
          AuthoringTransactionCheckpoint.afterJournalPreparing) {
        throw const AuthoringTransactionSimulatedCrash();
      }
    });
    final planned = await session.planPatch(
        upserts: [_unit('a', 'discarded')], idempotencyKey: 'discarded');
    await expectLater(session.apply(planned),
        throwsA(isA<AuthoringTransactionSimulatedCrash>()));
    await session.reconcile(planned.operationId);
    final collected = await session.retention.collect(
        projectId: 'game', history: session.history, blobs: session.blobs);
    expect(collected.deletedObjects, greaterThan(0));
    await expectLater(
        session.apply(planned),
        throwsA(isA<CatalogStorageException>()
            .having((error) => error.code, 'code', 'catalog.plan_unknown')));
    final observed = await session.openSnapshot();
    try {
      await observed.snapshot.validate();
      expect((await observed.snapshot.lookup(_key('a')))!.payload['name'],
          'before');
    } finally {
      await observed.close();
    }
  });
}

final class _FailHistory implements AuthoringHistoryStore {
  _FailHistory(this.delegate, {required this.afterAppend});
  final AuthoringHistoryStore delegate;
  final bool afterAppend;

  @override
  Future<void> append(AuthoringHistoryEntry entry) async {
    if (afterAppend) await delegate.append(entry);
    throw StateError('injected history failure');
  }

  @override
  Future<AuthoringHistoryEntry?> get(
          {required String projectId, required String entryId}) =>
      delegate.get(projectId: projectId, entryId: entryId);

  @override
  Future<AuthoringHistoryPage> list(
          {required String projectId,
          required int limit,
          AuthoringHistoryCursor? cursor}) =>
      delegate.list(projectId: projectId, limit: limit, cursor: cursor);

  @override
  Future<AuthoringHistoryEntry> markNonUndoable(
          {required String projectId,
          required String entryId,
          required String reason}) =>
      delegate.markNonUndoable(
          projectId: projectId, entryId: entryId, reason: reason);
}

Future<CatalogEditingSession> _open(CatalogStorageStore store,
        {AuthoringTransactionFaultInjector? faultInjector}) =>
    CatalogEditingSession.open(
        store: store,
        projectId: 'game',
        actorId: 'editor',
        faultInjector: faultInjector);

CatalogDefinitionKey _key(String id) =>
    CatalogDefinitionKey(CatalogDefinitionKind.values.first, id);

CatalogDefinitionUnit _unit(String id, String name) =>
    CatalogDefinitionUnit(key: _key(id), payload: {'name': name});

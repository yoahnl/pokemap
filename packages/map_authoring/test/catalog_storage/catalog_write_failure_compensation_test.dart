import 'dart:io';

import 'package:map_authoring/src/catalog_storage/catalog_editing_session.dart';
import 'package:map_authoring/src/catalog_storage/catalog_storage_store.dart';
import 'package:map_authoring/src/ports/transaction_file_gateway.dart';
import 'package:map_authoring/src/transactions/file_idempotency_store.dart';
import 'package:map_authoring/src/transactions/idempotency_ledger.dart';
import 'package:map_authoring/src/transactions/journaled_transaction.dart';
import 'package:map_authoring/src/transactions/recovery_service.dart';
import 'package:map_authoring/src/transactions/transaction_journal.dart';
import 'package:map_authoring/src/ports/idempotency_store.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory directory;
  late CatalogStorageStore store;
  late AuthoringIdempotencyLedger ledger;
  late CatalogEditingSession session;

  Future<CatalogEditingSession> open(
          {AuthoringTransactionFaultInjector? faultInjector}) =>
      CatalogEditingSession.open(
          store: store,
          projectId: 'game',
          actorId: 'editor',
          idempotency: ledger,
          faultInjector: faultInjector);

  Future<void> setCatalogWritable(bool writable) async {
    final result = await Process.run(
        'chmod', [writable ? 'u+w' : 'a-w', '${directory.path}/catalog']);
    expect(result.exitCode, 0);
  }

  Future<List<int>> headBytes() =>
      File('${directory.path}/${CatalogStorageStore.headStorageKey}')
          .readAsBytes();

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('catalog-write-failure-');
    store = await CatalogStorageStore.open(projectRoot: directory.path);
    await store.publish(CatalogStorageBuilder().build([_unit('a', 'before')]),
        expectedRootRevision: null);
    ledger = AuthoringIdempotencyLedger(
        store: FileIdempotencyStore(
            filePath:
                '${directory.path}/.pokemap/authoring/idempotency.jsonl'));
    session = await open();
    await session.apply(await session
        .planPatch(upserts: [_unit('a', 'warm')], idempotencyKey: 'warm'));
  });

  tearDown(() async {
    await setCatalogWritable(true);
    await session.close();
    await directory.delete(recursive: true);
  });

  test('a write refused before head promotion is rolled back', () async {
    final before = await headBytes();
    final plan = await session
        .planPatch(upserts: [_unit('a', 'blocked')], idempotencyKey: 'blocked');
    await setCatalogWritable(false);

    await expectLater(
        session.apply(plan),
        throwsA(isA<TransactionFileGatewayException>()
            .having((error) => error.code, 'code', 'transaction.io')));

    expect(await headBytes(), before);
    expect(await store.gateway.listJournals(), isEmpty);
    final record = await ledger.recordForRecovery(plan.scope);
    expect(record!.status, AuthoringIdempotencyStatus.completed);
    expect(record.receipt!.extensions['recoveryOutcome'], 'compensated');
    await setCatalogWritable(true);
    final next = await session
        .planPatch(upserts: [_unit('a', 'saved')], idempotencyKey: 'retry');
    await session.apply(next);
    expect(
        (await session.snapshot.lookup(_key('a')))!.payload['name'], 'saved');
  });

  test('an ordinary failure before head promotion is rolled back', () async {
    await session.close();
    session = await open(faultInjector: (context) {
      if (context.checkpoint ==
          AuthoringTransactionCheckpoint.beforeResourcePromotion) {
        throw const FileSystemException('No space left on device');
      }
    });
    final before = await headBytes();
    final plan = await session
        .planPatch(upserts: [_unit('a', 'full')], idempotencyKey: 'full');

    await expectLater(session.apply(plan), throwsA(anything));

    expect(await headBytes(), before);
    expect(await store.gateway.listJournals(), isEmpty);
    expect(
        (await ledger.recordForRecovery(plan.scope))!
            .receipt!
            .extensions['recoveryOutcome'],
        'compensated');
  });

  test('a failure after head promotion stays resumable', () async {
    await session.close();
    session = await open(faultInjector: (context) {
      if (context.checkpoint ==
          AuthoringTransactionCheckpoint.afterResourcePromoted) {
        throw const FileSystemException('Interrupted after promotion');
      }
    });
    final plan = await session
        .planPatch(upserts: [_unit('a', 'promoted')], idempotencyKey: 'late');

    await expectLater(session.apply(plan), throwsA(anything));

    final journal = await store.gateway.readJournal(plan.operationId);
    expect(journal, isNotNull);
    expect(journal!.status, isNot(AuthoringTransactionStatus.compensated));
    expect(await store.readHead(), plan.root);
    expect((await session.recovery.inspect()).single.disposition,
        AuthoringRecoveryDisposition.resumable);
    await session.close();
    session = await open();
    await session.reconcile(plan.operationId);
    expect((await session.snapshot.lookup(_key('a')))!.payload['name'],
        'promoted');
    expect(await store.gateway.listJournals(), isEmpty);
  });

  test('a finalized leftover journal no longer blocks new edits', () async {
    await session.close();
    session = await open(faultInjector: (context) {
      if (context.checkpoint ==
          AuthoringTransactionCheckpoint.beforeResourcePromotion) {
        throw const AuthoringTransactionSimulatedCrash();
      }
    });
    final plan = await session
        .planPatch(upserts: [_unit('a', 'left')], idempotencyKey: 'left');
    await expectLater(session.apply(plan),
        throwsA(isA<AuthoringTransactionSimulatedCrash>()));
    await session.recovery.compensate(plan.operationId);
    expect((await store.gateway.readJournal(plan.operationId))!.status,
        AuthoringTransactionStatus.compensated);
    await session.close();
    session = await open();

    final next = await session
        .planPatch(upserts: [_unit('a', 'free')], idempotencyKey: 'free');
    await session.apply(next);
    expect((await session.snapshot.lookup(_key('a')))!.payload['name'], 'free');
  });

  test('an unfinished leftover journal still blocks new edits', () async {
    await session.close();
    session = await open(faultInjector: (context) {
      if (context.checkpoint ==
          AuthoringTransactionCheckpoint.beforeResourcePromotion) {
        throw const AuthoringTransactionSimulatedCrash();
      }
    });
    final plan = await session
        .planPatch(upserts: [_unit('a', 'held')], idempotencyKey: 'held');
    await expectLater(session.apply(plan),
        throwsA(isA<AuthoringTransactionSimulatedCrash>()));
    await session.close();
    session = await open();

    await expectLater(
        session
            .planPatch(upserts: [_unit('a', 'other')], idempotencyKey: 'other'),
        throwsA(isA<CatalogStorageException>().having(
            (error) => error.code, 'code', 'catalog.recovery_required')));
  });
}

CatalogDefinitionKey _key(String id) =>
    CatalogDefinitionKey(CatalogDefinitionKind.values.first, id);

CatalogDefinitionUnit _unit(String id, String name) =>
    CatalogDefinitionUnit(key: _key(id), payload: {'name': name});

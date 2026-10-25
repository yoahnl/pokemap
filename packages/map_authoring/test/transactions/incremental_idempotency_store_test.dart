import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/src/contracts/authoring_diff.dart';
import 'package:map_authoring/src/contracts/authoring_receipt.dart';
import 'package:map_authoring/src/ports/idempotency_store.dart';
import 'package:map_authoring/src/transactions/file_idempotency_store.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late String path;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('incremental-idempotency-');
    path = '${root.path}/.pokemap/authoring/idempotency.jsonl';
  });
  tearDown(() => root.delete(recursive: true));

  test(
      'cold operation lookup and repeated scopes never replay unrelated history',
      () async {
    var fullReads = 0;
    var store = FileIdempotencyStore(
        filePath: path, incrementalWrites: true, onFullRead: () => fullReads++);
    final first = _record('key-first', 'different-operation-first');
    await store.reserve(first);
    await store
        .complete(_record('key-first', first.operationId, completed: true));
    for (var index = 0; index < 900; index++) {
      await store.reserve(_record('unrelated-$index', 'operation-$index'));
    }
    store = FileIdempotencyStore(
        filePath: path, incrementalWrites: true, onFullRead: () => fullReads++);
    final found = await store.lookupOperation(
        actorId: 'actor',
        projectId: 'project',
        operationId: first.operationId,
        now: DateTime.utc(2026));
    expect(found!.scope.storageKey, first.scope.storageKey);
    expect(found.completed!.receipt!.receiptId, 'receipt');
    expect(
        await store.lookupOperation(
            actorId: 'actor',
            projectId: 'project',
            operationId: 'never-used',
            now: DateTime.utc(2026)),
        isNull);
    await store.reserve(_record('second-key', 'second-operation'));
    expect(fullReads, 0);
  });

  test(
      'nonempty legacy storage requires explicit preparation and retains pending identities',
      () async {
    final legacy = FileIdempotencyStore(filePath: path);
    final record = _record('old-key', 'old-operation');
    await legacy.reserve(record);
    var fullReads = 0;
    final local = FileIdempotencyStore(
        filePath: path, incrementalWrites: true, onFullRead: () => fullReads++);
    await expectLater(
        local.reserve(_record('new-key', 'new-operation')),
        throwsA(isA<IdempotencyStoreException>().having((error) => error.code,
            'code', 'idempotency.preparation_required')));
    expect(fullReads, 0);
    await local.prepareIncrementalStorage();
    final reopened = FileIdempotencyStore(
        filePath: path, incrementalWrites: true, onFullRead: () => fullReads++);
    final replay = await reopened.lookupOperation(
        actorId: 'actor',
        projectId: 'project',
        operationId: 'old-operation',
        now: DateTime.utc(2026));
    expect(replay!.scope.storageKey, record.scope.storageKey);
    expect((await reopened.reserve(record)).acquired, isFalse);
    expect(replay.completed, isNull);
    expect(fullReads, 1);
  });

  test('explicit preparation indexes reservations from earlier scoped storage',
      () async {
    final scope = AuthoringIdempotencyScope(
        actorId: 'actor',
        projectId: 'project',
        actionId: 'map.atmosphere.set',
        actionVersion: 1,
        key: 'older-key');
    final record = AuthoringIdempotencyRecord(
        scope: scope,
        payloadFingerprint: 'sha256:${'a' * 64}',
        operationId: 'older-operation',
        status: AuthoringIdempotencyStatus.pending,
        createdAt: DateTime.utc(2026));
    await (await FileIdempotencyStore.forScope(filePath: path, scope: scope))
        .reserve(record);
    await Directory('${File(path).parent.path}/idempotency-operations')
        .delete(recursive: true);
    var fullReads = 0;
    final local = FileIdempotencyStore(
        filePath: path, incrementalWrites: true, onFullRead: () => fullReads++);
    await expectLater(
        local.lookupOperation(
            actorId: 'actor',
            projectId: 'project',
            operationId: 'older-operation',
            now: DateTime.utc(2026)),
        throwsA(isA<IdempotencyStoreException>().having((error) => error.code,
            'code', 'idempotency.preparation_required')));
    expect(fullReads, 0);
    await local.prepareIncrementalStorage();
    final reopened = FileIdempotencyStore(
        filePath: path, incrementalWrites: true, onFullRead: () => fullReads++);
    final found = await reopened.lookupOperation(
        actorId: 'actor',
        projectId: 'project',
        operationId: 'older-operation',
        now: DateTime.utc(2026));
    expect(found!.scope.storageKey, scope.storageKey);
    expect(found.completed, isNull);
    expect(fullReads, 1);
  });

  test('same operation cannot reserve a different durable scope', () async {
    final store = FileIdempotencyStore(filePath: path, incrementalWrites: true);
    await store.reserve(_record('first-key', 'operation'));
    await expectLater(
        store.reserve(_record('second-key', 'operation')),
        throwsA(isA<IdempotencyStoreException>().having(
            (error) => error.code, 'code', 'idempotency.operation_ambiguous')));
    expect(await store.read(_record('second-key', 'operation').scope), isNull);
  });
  test('explicit pruning expires completed scopes and preserves pending work',
      () async {
    final store = FileIdempotencyStore(filePath: path, incrementalWrites: true);
    await store.reserve(_record('completed', 'completed-operation'));
    await store
        .complete(_record('completed', 'completed-operation', completed: true));
    await store.reserve(_record('pending', 'pending-operation'));
    expect(await store.pruneExpired(DateTime.utc(2028)), 1);
    expect(await store.read(_record('completed', 'completed-operation').scope),
        isNull);
    expect(
        (await store.read(_record('pending', 'pending-operation').scope))!
            .status,
        AuthoringIdempotencyStatus.pending);
    expect(
        (await store.reserve(_record('completed', 'new-operation'))).acquired,
        isTrue);
  });

  test('a changed frozen ledger requires another explicit preparation',
      () async {
    final legacy = FileIdempotencyStore(filePath: path);
    await legacy.reserve(_record('old', 'old-operation'));
    final local = FileIdempotencyStore(filePath: path, incrementalWrites: true);
    await local.prepareIncrementalStorage();
    await File(path).writeAsString(
        '${jsonEncode({
              'schemaVersion': 1,
              'event': 'put',
              'record': _record('other', 'other-operation').toJson()
            })}\n',
        mode: FileMode.append,
        flush: true);
    await expectLater(
        local.read(_record('new', 'new-operation').scope),
        throwsA(isA<IdempotencyStoreException>().having((error) => error.code,
            'code', 'idempotency.preparation_required')));
    await local.prepareIncrementalStorage();
    final replay = await local.lookupOperation(
        actorId: 'actor',
        projectId: 'project',
        operationId: 'other-operation',
        now: DateTime.utc(2026));
    expect(replay!.scope.storageKey,
        _record('other', 'other-operation').scope.storageKey);
  });

  test(
      'corrupt operation pointers fail closed without modifying the reservation',
      () async {
    final store = FileIdempotencyStore(filePath: path, incrementalWrites: true);
    final record = _record('key', 'operation');
    await store.reserve(record);
    final directory =
        Directory('${File(path).parent.path}/idempotency-operations');
    final pointer = await directory
        .list()
        .where((entry) => entry.path.endsWith('.jsonl'))
        .single;
    await File(pointer.path).writeAsString('{}\n', flush: true);
    await expectLater(
        FileIdempotencyStore(filePath: path, incrementalWrites: true)
            .lookupOperation(
                actorId: 'actor',
                projectId: 'project',
                operationId: 'operation',
                now: DateTime.utc(2026)),
        throwsA(isA<IdempotencyStoreException>().having(
            (error) => error.code, 'code', 'idempotency.store_corrupt')));
    expect((await store.read(record.scope))!.operationId, 'operation');
  });
}

AuthoringIdempotencyRecord _record(String key, String operation,
    {bool completed = false}) {
  final scope = AuthoringIdempotencyScope(
      actorId: 'actor',
      projectId: 'project',
      actionId: 'pokemon.documents.write',
      actionVersion: 1,
      key: key);
  return AuthoringIdempotencyRecord(
      scope: scope,
      payloadFingerprint: 'sha256:${'a' * 64}',
      operationId: operation,
      status: completed
          ? AuthoringIdempotencyStatus.completed
          : AuthoringIdempotencyStatus.pending,
      createdAt: DateTime.utc(2026),
      expiresAt: completed ? DateTime.utc(2027) : null,
      receipt: completed
          ? AuthoringReceipt(
              receiptId: 'receipt',
              requestId: 'request',
              actionId: scope.actionId,
              actionVersion: 1,
              status: AuthoringReceiptStatus.applied,
              createdAtUtc: DateTime.utc(2026).toIso8601String(),
              diff: AuthoringDiff([]))
          : null);
}

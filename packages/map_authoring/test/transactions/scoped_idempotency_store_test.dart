import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late String path;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('scoped-ledger-');
    final parent = Directory('${root.path}/.pokemap/authoring');
    await parent.create(recursive: true);
    path = '${parent.path}/idempotency.jsonl';
  });
  tearDown(() => root.delete(recursive: true));

  test('new action scope never reads or modifies the legacy ledger', () async {
    final legacy = File(path);
    await legacy.writeAsString('unrelated legacy data\n');
    final before = await legacy.readAsBytes();
    var legacyReads = 0;
    final global = FileIdempotencyStore(
      filePath: path,
      onFullRead: () => legacyReads++,
    );
    expect(await global.read(_scope()), isNull);
    expect(legacyReads, 0);
    expect(await legacy.readAsBytes(), before);
  });

  test('global recovery reads and completes the same scoped reservation',
      () async {
    await File(path).writeAsString('unrelated legacy data\n');
    var legacyReads = 0;
    final global =
        FileIdempotencyStore(filePath: path, onFullRead: () => legacyReads++);
    final scope = _scope();
    final targeted =
        await FileIdempotencyStore.forScope(filePath: path, scope: scope);
    expect((await global.reserve(_record(scope))).acquired, isTrue);
    expect((await targeted.reserve(_record(scope))).acquired, isFalse);
    expect(
        (await global.read(scope))!.status, AuthoringIdempotencyStatus.pending);
    await global.complete(_record(scope, completed: true));
    final reopened =
        FileIdempotencyStore(filePath: path, onFullRead: () => legacyReads++);
    expect((await reopened.read(scope))!.receipt!.receiptId, 'receipt');
    final replay = await targeted.lookupOperation(
        actorId: scope.actorId,
        projectId: scope.projectId,
        operationId: 'operation',
        now: DateTime.utc(2026));
    expect(replay!.completed!.receipt!.receiptId, 'receipt');
    expect(legacyReads, 0);
    expect(await File(path).readAsString(), 'unrelated legacy data\n');
  });

  test('old actions cannot use shards and retain their legacy path', () async {
    final old = _scope(actionId: 'characterStudio.character.update');
    await expectLater(FileIdempotencyStore.forScope(filePath: path, scope: old),
        throwsArgumentError);
    final global = FileIdempotencyStore(filePath: path);
    expect((await global.reserve(_record(old))).acquired, isTrue);
    expect((await global.read(old))!.operationId, 'operation');
    expect(await File(path).exists(), isTrue);
    expect(
        await Directory('${File(path).parent.path}/idempotency-scopes')
            .exists(),
        isFalse);
  });

  test('a scoped store refuses a different idempotency key', () async {
    final scoped =
        await FileIdempotencyStore.forScope(filePath: path, scope: _scope());
    await expectLater(
        scoped.read(_scope(key: 'other')),
        throwsA(isA<IdempotencyStoreException>().having(
            (error) => error.code, 'code', 'idempotency.scope_mismatch')));
  });

  test('a shard relocated from another scope is rejected without mutation',
      () async {
    final directory = Directory('${File(path).parent.path}/idempotency-scopes');
    final first =
        await FileIdempotencyStore.forScope(filePath: path, scope: _scope());
    await first.reserve(_record(_scope()));
    final firstPath = (await directory
            .list()
            .where((entry) => entry.path.endsWith('.jsonl'))
            .toList())
        .single
        .path;
    final other = await FileIdempotencyStore.forScope(
        filePath: path, scope: _scope(key: 'other'));
    await other.reserve(_record(_scope(key: 'other')));
    final otherPath = (await directory
            .list()
            .where((entry) =>
                entry.path.endsWith('.jsonl') && entry.path != firstPath)
            .toList())
        .single
        .path;
    final bytes = await File(otherPath).readAsBytes();
    await File(firstPath).writeAsBytes(bytes);
    await expectLater(
        FileIdempotencyStore(filePath: path).read(_scope()),
        throwsA(isA<IdempotencyStoreException>().having(
            (error) => error.code, 'code', 'idempotency.scope_mismatch')));
    expect(await File(firstPath).readAsBytes(), bytes);
  });

  for (final kind in ['directory', 'shard', 'lock']) {
    test('scoped and global access fail closed for a $kind symlink', () async {
      final scope = _scope();
      final scoped =
          await FileIdempotencyStore.forScope(filePath: path, scope: scope);
      await scoped.reserve(_record(scope));
      final directory =
          Directory('${File(path).parent.path}/idempotency-scopes');
      final shard = (await directory
              .list()
              .where((entry) => entry.path.endsWith('.jsonl'))
              .toList())
          .single
          .path;
      final outside = await Directory.systemTemp.createTemp('scoped-outside-');
      addTearDown(() => outside.delete(recursive: true));
      final sentinel = File('${outside.path}/sentinel');
      await sentinel.writeAsString('preserved');
      final String linkedPath;
      if (kind == 'directory') {
        linkedPath = directory.path;
        await directory.rename('${directory.path}-preserved');
        await Link(linkedPath).create(outside.path);
      } else {
        linkedPath = kind == 'shard' ? shard : '$shard.lock';
        await File(linkedPath).delete();
        await Link(linkedPath).create(sentinel.path);
      }
      final failure = throwsA(isA<IdempotencyStoreException>()
          .having((error) => error.code, 'code', 'idempotency.path_unsafe'));
      await expectLater(
          FileIdempotencyStore.forScope(filePath: path, scope: scope), failure);
      await expectLater(
          FileIdempotencyStore(filePath: path).read(scope), failure);
      expect(await sentinel.readAsString(), 'preserved');
    });
  }
}

AuthoringIdempotencyScope _scope(
        {String key = 'key',
        String actionId = 'characterStudio.contactShadow.set'}) =>
    AuthoringIdempotencyScope(
      actorId: 'actor',
      projectId: 'project',
      actionId: actionId,
      actionVersion: 1,
      key: key,
    );

AuthoringIdempotencyRecord _record(AuthoringIdempotencyScope scope,
        {bool completed = false}) =>
    AuthoringIdempotencyRecord(
      scope: scope,
      payloadFingerprint: 'sha256:${'a' * 64}',
      operationId: 'operation',
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
          : null,
    );

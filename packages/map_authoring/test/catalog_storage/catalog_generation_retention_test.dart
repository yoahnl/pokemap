import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/src/catalog_storage/catalog_editing_session.dart';
import 'package:map_authoring/src/catalog_storage/catalog_generation_retention.dart';
import 'package:map_authoring/src/catalog_storage/catalog_storage_store.dart';
import 'package:map_authoring/src/history/content_blob_store.dart';
import 'package:map_authoring/src/history/file_history_store.dart';
import 'package:map_authoring/src/transactions/authoring_payload.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory directory;
  late CatalogStorageStore store;
  late CatalogGenerationRetention retention;
  late FileAuthoringHistoryStore history;
  late FileAuthoringContentBlobStore blobs;
  final readers = <LeasedCatalogSnapshot>[];
  final sessions = <CatalogEditingSession>[];

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('catalog-retention-');
    store = await CatalogStorageStore.open(projectRoot: directory.path);
    retention = CatalogGenerationRetention(store: store);
    history = await FileAuthoringHistoryStore.open(projectRoot: directory.path);
    blobs =
        await FileAuthoringContentBlobStore.open(projectRoot: directory.path);
    await store.publish(_build('old'), expectedRootRevision: null);
  });

  tearDown(() async {
    for (final session in sessions.reversed) {
      await session.close();
    }
    sessions.clear();
    for (final reader in readers.reversed) {
      await reader.close();
    }
    readers.clear();
    await directory.delete(recursive: true);
  });

  Future<CatalogCollectionResult> collect() =>
      retention.collect(projectId: 'game', history: history, blobs: blobs);

  test('collection rejects incompatible project identities before binding',
      () async {
    for (final projectId in ['a@b', 'a/b', 'a' * 161]) {
      await expectLater(
          retention.collect(
              projectId: projectId, history: history, blobs: blobs),
          throwsA(anything));
      expect(await File('${directory.path}/catalog/IDENTITY.json').exists(),
          isFalse);
    }
  });

  test('concurrent projects isolate identical edit identities and collection',
      () async {
    final otherDirectory =
        await Directory.systemTemp.createTemp('catalog-other-project-');
    CatalogEditingSession? other;
    try {
      final otherStore =
          await CatalogStorageStore.open(projectRoot: otherDirectory.path);
      await otherStore.publish(_build('old'), expectedRootRevision: null);
      final local = await CatalogEditingSession.open(
          store: store, projectId: 'game', actorId: 'author');
      sessions.add(local);
      other = await CatalogEditingSession.open(
          store: otherStore, projectId: 'game', actorId: 'author');
      final plans = await Future.wait([
        local.planPatch(upserts: [_unit('local')], idempotencyKey: 'same-key'),
        other.planPatch(upserts: [_unit('other')], idempotencyKey: 'same-key'),
      ]);
      final receipts =
          await Future.wait([local.apply(plans[0]), other.apply(plans[1])]);
      expect((await local.snapshot.lookup(_key))!.payload['name'], 'local');
      expect((await other.snapshot.lookup(_key))!.payload['name'], 'other');
      final otherObjects = await _objects(otherDirectory);
      await collect();
      await local.undo(entryId: receipts[0].receiptId, idempotencyKey: 'undo');
      expect(await _objects(otherDirectory), otherObjects);
      expect((await other.snapshot.lookup(_key))!.payload['name'], 'other');
      await other.undo(entryId: receipts[1].receiptId, idempotencyKey: 'undo');
      expect((await other.snapshot.lookup(_key))!.payload['name'], 'old');
    } finally {
      await other?.close();
      await otherDirectory.delete(recursive: true);
    }
  });

  test('a live reader retains its generation until explicitly closed',
      () async {
    final old = await retention.openSnapshot();
    readers.add(old);
    await store.publish(_build('new'), expectedRootRevision: old.rootRevision);
    final first = await collect();
    expect(first.deletedObjects, 0);
    expect((await old.snapshot.lookup(_key))!.payload['name'], 'old');
    await old.close();
    final second = await collect();
    expect(second.deletedObjects, 3);
    expect(second.deletedBytes, greaterThan(0));
    await expectLater(
        old.snapshot.lookup(_key), throwsA(isA<CatalogStorageException>()));
    final current = await retention.openSnapshot();
    readers.add(current);
    expect((await current.snapshot.lookup(_key))!.payload['name'], 'new');
  });

  test(
      'canonical history retains generations for undo and redo after collection',
      () async {
    final session = await CatalogEditingSession.open(
        store: store, projectId: 'game', actorId: 'author');
    sessions.add(session);
    final plan = await session
        .planPatch(upserts: [_unit('new')], idempotencyKey: 'edit');
    final receipt = await session.apply(plan);
    final orphan = _build('orphan');
    await store.gateway.withExclusiveWriteLock(
        () => store.publishObjectsUnderLock(orphan.objects));
    final result = await collect();
    expect(result.deletedObjects, 3);
    await session.undo(entryId: receipt.receiptId, idempotencyKey: 'undo');
    expect((await session.snapshot.lookup(_key))!.payload['name'], 'old');
    await collect();
    await session.redo(entryId: receipt.receiptId, idempotencyKey: 'redo');
    expect((await session.snapshot.lookup(_key))!.payload['name'], 'new');
  });

  test('a wrong history project cannot erase another identity generations',
      () async {
    final session = await CatalogEditingSession.open(
        store: store, projectId: 'game', actorId: 'author');
    sessions.add(session);
    final plan = await session
        .planPatch(upserts: [_unit('new')], idempotencyKey: 'edit');
    await session.apply(plan);
    final before = await _objects(directory);
    await expectLater(
        retention.collect(projectId: 'other', history: history, blobs: blobs),
        throwsA(isA<CatalogStorageException>()));
    expect(await _objects(directory), before);
  });

  test('a valid but incorrect historical head fails before deleting anything',
      () async {
    final session = await CatalogEditingSession.open(
        store: store, projectId: 'game', actorId: 'author');
    sessions.add(session);
    final plan = await session
        .planPatch(upserts: [_unit('new')], idempotencyKey: 'edit');
    await session.apply(plan);
    final before = await _objects(directory);
    final wrong = CatalogStorageStore.encodeHead(session.snapshot.root);
    await expectLater(
        retention.collect(
            projectId: 'game',
            history: history,
            blobs: _WrongBlobs(blobs, wrong)),
        throwsA(anything));
    expect(await _objects(directory), before);
  });

  test('corrupt leases and reachable objects stop collection before deletion',
      () async {
    final orphan = _build('orphan');
    await store.gateway.withExclusiveWriteLock(
        () => store.publishObjectsUnderLock(orphan.objects));
    final reader = await retention.openSnapshot();
    readers.add(reader);
    final record =
        File('${directory.path}/catalog/leases/${reader.lease.id}.json');
    final original = await record.readAsBytes();
    await record.writeAsString('{}');
    final before = await _objects(directory);
    await expectLater(collect(), throwsA(anything));
    expect(await _objects(directory), before);
    await record.writeAsBytes(original);
    final rootFile = File(
        '${directory.path}/catalog/objects/${reader.snapshot.root.sha256}.json');
    final rootBytes = await rootFile.readAsBytes();
    await rootFile.writeAsString('{}');
    await expectLater(collect(), throwsA(anything));
    expect(await _objects(directory), before);
    await rootFile.writeAsBytes(rootBytes);
  });

  test('symlinks in the object inventory are never followed or removed',
      () async {
    final outside = await Directory.systemTemp.createTemp('catalog-outside-');
    try {
      final target = File('${outside.path}/proof');
      await target.writeAsString('preserve');
      await Link('${directory.path}/catalog/objects/${'f' * 64}.json')
          .create(target.path);
      await expectLater(collect(), throwsA(anything));
      expect(await target.readAsString(), 'preserve');
    } finally {
      await outside.delete(recursive: true);
    }
  });

  test(
      'another process reader is protected and a terminated reader is reclaimed',
      () async {
    final child = await Process.start('dart',
        ['run', 'test/support/catalog_lease_process.dart', directory.path]);
    final errors = child.stderr.transform(utf8.decoder).join();
    var exited = false;
    try {
      final line = await child.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .first
          .timeout(const Duration(seconds: 30));
      final ready = jsonDecode(line) as Map;
      expect(ready['pid'], child.pid);
      final before = await store.readHead();
      await store.publish(_build('new'), expectedRootRevision: before!.sha256);
      final first = await collect();
      expect(first.deletedObjects, 0);
      child.stdin.writeln('exit');
      await child.stdin.flush();
      expect(await child.exitCode.timeout(const Duration(seconds: 15)), 0);
      exited = true;
      expect(await errors, isEmpty);
      final result = await collect();
      expect(result.reclaimedLeases, 1);
      expect(result.deletedObjects, 3);
    } finally {
      if (!exited) {
        child.stdin.writeln('exit');
        await child.stdin.flush();
        await child.exitCode.timeout(const Duration(seconds: 15));
      }
    }
  });
}

final _key = CatalogDefinitionKey(CatalogDefinitionKind.element, 'decor');
CatalogDefinitionUnit _unit(String name) =>
    CatalogDefinitionUnit(key: _key, payload: {'id': 'decor', 'name': name});
CatalogStorageBuild _build(String name) =>
    CatalogStorageBuilder().build([_unit(name)]);
Future<List<String>> _objects(Directory directory) async =>
    (await Directory('${directory.path}/catalog/objects')
        .list(followLinks: false)
        .map((entry) => entry.path)
        .toList())
      ..sort();

final class _WrongBlobs implements AuthoringContentBlobStore {
  _WrongBlobs(this.delegate, this.bytes);
  final AuthoringContentBlobStore delegate;
  final List<int> bytes;
  @override
  Future<AuthoringPayload?> get(String id) async =>
      AuthoringPayload.inline(bytes,
          storageKey: CatalogStorageStore.headStorageKey);
  @override
  Future<AuthoringContentBlobRef> put(Iterable<int> bytes) =>
      delegate.put(bytes);
  @override
  Future<bool> contains(String id) => delegate.contains(id);
  @override
  Future<List<String>> listIds() => delegate.listIds();
  @override
  Future<int> prune({required Set<String> retainIds}) =>
      delegate.prune(retainIds: retainIds);
}

import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/src/catalog_storage/catalog_storage_store.dart';
import 'package:map_authoring/src/ports/project_file_reader.dart';
import 'package:map_authoring/src/ports/transaction_file_gateway.dart';
import 'package:map_authoring/src/transactions/local_transaction_file_gateway.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory project;
  late CatalogStorageStore store;

  setUp(() async {
    project = await Directory.systemTemp.createTemp('catalog-storage-');
    store = await CatalogStorageStore.open(projectRoot: project.path);
  });

  tearDown(() async {
    await project.delete(recursive: true);
  });

  test('publishes a generation and reopens a pinned definition', () async {
    expect(await store.openSnapshot(), isNull);
    final build = _build('old');
    final published = await store.publish(build, expectedRootRevision: null);
    expect(published.rootRevision, build.root.sha256);
    final reopened = await store.openSnapshot();
    expect(reopened!.rootRevision, build.root.sha256);
    expect((await reopened.snapshot.lookup(_key('a')))!.payload['name'], 'old');
    expect(await _stagingDirectories(project), isEmpty);
  });

  test('publishes immutable units under an existing lock without changing head',
      () async {
    final old = await store.publish(_build('old'), expectedRootRevision: null);
    final next = _build('new');
    await store.gateway.withExclusiveWriteLock(() async {
      await store.publishObjectsUnderLock(next.objects);
      expect(await store.readHead(), old.snapshot.root);
      final pinned = await store.openRoot(next.root);
      expect((await pinned.snapshot.lookup(_key('a')))!.payload['name'], 'new');
      expect(await store.readObject(next.root), next.objects[next.root.sha256]);
    });
    expect((await store.openSnapshot())!.rootRevision, old.rootRevision);
    expect(CatalogStorageStore.encodeHead(next.root).length, lessThan(4096));
  });

  test('an old snapshot never observes the new head', () async {
    final old = await store.publish(_build('old'), expectedRootRevision: null);
    final next = await store.publish(_build('new'),
        expectedRootRevision: old.rootRevision);
    expect(next.rootRevision, isNot(old.rootRevision));
    expect((await old.snapshot.lookup(_key('a')))!.payload['name'], 'old');
    expect((await next.snapshot.lookup(_key('a')))!.payload['name'], 'new');
    expect((await store.openSnapshot())!.rootRevision, next.rootRevision);
  });

  test('a stale writer cannot publish or stage any new generation', () async {
    final old = await store.publish(_build('old'), expectedRootRevision: null);
    final filesBefore = await _files(project);
    await expectLater(
      store.publish(_build('new'), expectedRootRevision: null),
      throwsA(isA<CatalogStorageException>()
          .having((error) => error.code, 'code', 'catalog.revision_conflict')),
    );
    expect(await _files(project), filesBefore);
    expect((await store.openSnapshot())!.rootRevision, old.rootRevision);
  });

  test('two local instances serialize compare and swap', () async {
    final other = await CatalogStorageStore.open(projectRoot: project.path);
    final outcomes = await Future.wait([
      _outcome(store.publish(_build('one'), expectedRootRevision: null)),
      _outcome(other.publish(_build('two'), expectedRootRevision: null)),
    ]);
    expect(outcomes.whereType<PublishedCatalogSnapshot>(), hasLength(1));
    expect(outcomes.whereType<CatalogStorageException>(), hasLength(1));
    expect((await store.openSnapshot())!.rootRevision,
        outcomes.whereType<PublishedCatalogSnapshot>().single.rootRevision);
  });

  test('identical ids and revisions remain isolated between projects',
      () async {
    final otherRoot =
        await Directory.systemTemp.createTemp('catalog-isolated-');
    try {
      final other = await CatalogStorageStore.open(projectRoot: otherRoot.path);
      final one =
          await store.publish(_build('one'), expectedRootRevision: null);
      final two =
          await other.publish(_build('two'), expectedRootRevision: null);
      expect((await one.snapshot.lookup(_key('a')))!.payload['name'], 'one');
      expect((await two.snapshot.lookup(_key('a')))!.payload['name'], 'two');
    } finally {
      await otherRoot.delete(recursive: true);
    }
  });

  test('all failed promotions leave either old or complete new generation',
      () async {
    final nextBuild = _build('new');
    final previousBuild = _build('old');
    final promotions = nextBuild.objects.keys
            .where((hash) => !previousBuild.objects.containsKey(hash))
            .length +
        1;
    for (var failAt = 1; failAt <= promotions; failAt++) {
      final root = await Directory.systemTemp.createTemp('catalog-fault-');
      try {
        final local = await CatalogStorageStore.open(projectRoot: root.path);
        final previous =
            await local.publish(_build('old'), expectedRootRevision: null);
        final gateway = _FaultGateway(
            await LocalTransactionFileGateway.open(projectRoot: root.path),
            failAfterPromotion: failAt);
        final faulty = CatalogStorageStore(
          projectRoot: root.path,
          reader: const LocalProjectFileReader(),
          gateway: gateway,
        );
        await expectLater(
          faulty.publish(nextBuild,
              expectedRootRevision: previous.rootRevision),
          throwsA(isA<StateError>()),
        );
        final observed = (await local.openSnapshot())!;
        expect(
            observed.rootRevision,
            gateway.promotedHead
                ? nextBuild.root.sha256
                : previous.rootRevision);
        await observed.snapshot.validate();
        expect((await observed.snapshot.lookup(_key('a')))!.payload['name'],
            gateway.promotedHead ? 'new' : 'old');
        expect((await previous.snapshot.lookup(_key('a')))!.payload['name'],
            'old');
        expect(await _stagingDirectories(root), isEmpty);
      } finally {
        await root.delete(recursive: true);
      }
    }
  });

  test('read head rejects malformed or oversized input', () async {
    final head = File('${project.path}/catalog/HEAD.json');
    await head.parent.create(recursive: true);
    await head.writeAsString('{}');
    await expectLater(
        store.openSnapshot(), throwsA(isA<CatalogStorageException>()));
    await head.writeAsString('x' * 4097);
    await expectLater(
        store.openSnapshot(),
        throwsA(isA<CatalogStorageException>()
            .having((error) => error.code, 'code', 'catalog.read_limit')));
  });

  test('publication rejects symlink parents and never writes outside project',
      () async {
    final outside = await Directory.systemTemp.createTemp('catalog-outside-');
    try {
      await Link('${project.path}/catalog').create(outside.path);
      await expectLater(
          store.publish(_build('new'), expectedRootRevision: null),
          throwsA(anything));
      expect(await outside.list().toList(), isEmpty);
    } finally {
      await outside.delete(recursive: true);
    }
  });

  test('a corrupt published object is rejected without a replacement head',
      () async {
    final build = _build('old');
    final previous = await store.publish(build, expectedRootRevision: null);
    final object =
        File('${project.path}/catalog/objects/${build.root.sha256}.json');
    await object.writeAsString('{}');
    await expectLater(store.openSnapshot(), throwsA(anything));
    await expectLater(
        store.publish(build, expectedRootRevision: previous.rootRevision),
        throwsA(anything));
    expect(
        jsonDecode(await File('${project.path}/catalog/HEAD.json')
            .readAsString())['root']['sha256'],
        build.root.sha256);
  });

  test('opening and lookup read bounded units instead of the whole catalog',
      () async {
    final build = CatalogStorageBuilder().build([
      for (var i = 0; i < 300; i++)
        CatalogDefinitionUnit(
            key: _key('entry-${i.toString().padLeft(4, '0')}'),
            payload: {'name': 'unit-$i', 'padding': 'x' * 1000}),
    ]);
    await store.publish(build, expectedRootRevision: null);
    final reader = _CountingReader();
    final observed = CatalogStorageStore(
      projectRoot: project.path,
      reader: reader,
      gateway:
          await LocalTransactionFileGateway.open(projectRoot: project.path),
    );
    final opened = (await observed.openSnapshot())!;
    expect(reader.paths, hasLength(2));
    expect(reader.paths.first, CatalogStorageStore.headStorageKey);
    reader.paths.clear();
    final unit = await opened.snapshot.lookup(_key('entry-0249'));
    expect(unit!.payload['name'], 'unit-249');
    expect(reader.paths, hasLength(3));
    expect(reader.paths, isNot(contains(CatalogStorageStore.headStorageKey)));
    reader.paths.clear();
    final page = await opened.snapshot.page(limit: 3);
    expect(page.items, hasLength(3));
    expect(reader.paths, hasLength(1));
    final unitHashes = {
      for (final entry in build.objects.entries)
        if ((jsonDecode(utf8.decode(entry.value)) as Map)['type'] == 'unit')
          'catalog/objects/${entry.key}.json',
    };
    expect(reader.paths.where(unitHashes.contains), isEmpty);
  });

  test('opening rejects a resource larger than its declared size', () async {
    final build = _build('old');
    await store.publish(build, expectedRootRevision: null);
    final file =
        File('${project.path}/catalog/objects/${build.root.sha256}.json');
    await file.writeAsString(' ', mode: FileMode.append);
    await expectLater(
        store.openSnapshot(),
        throwsA(isA<CatalogStorageException>()
            .having((error) => error.code, 'code', 'catalog.read_limit')));
  });

  test('head cannot supply an external path as an object address', () async {
    final head = File('${project.path}/catalog/HEAD.json');
    await head.parent.create(recursive: true);
    await head.writeAsString(jsonEncode({
      'schemaVersion': 1,
      'root': {'sha256': '../../outside.json', 'byteLength': 10},
    }));
    await expectLater(
        store.openSnapshot(),
        throwsA(isA<CatalogStorageException>()
            .having((error) => error.code, 'code', 'catalog.head_invalid')));
  });

  test('head symlinks cannot be read or replaced', () async {
    final outside = await Directory.systemTemp.createTemp('catalog-head-link-');
    try {
      await Directory('${project.path}/catalog').create();
      final target = File('${outside.path}/HEAD.json');
      await target.writeAsString('{}');
      await Link('${project.path}/catalog/HEAD.json').create(target.path);
      await expectLater(store.openSnapshot(), throwsA(anything));
      await expectLater(
          store.publish(_build('new'), expectedRootRevision: null),
          throwsA(anything));
      expect(await target.readAsString(), '{}');
    } finally {
      await outside.delete(recursive: true);
    }
  });

  test('head rejects numeric version aliases and duplicate keys', () async {
    final build = _build('old');
    await store.publish(build, expectedRootRevision: null);
    final head = File('${project.path}/catalog/HEAD.json');
    for (final invalid in [
      '{"schemaVersion":1.0,"root":${jsonEncode(build.root.toJson())}}',
      '{"schemaVersion":2,"schemaVersion":1,"root":${jsonEncode(build.root.toJson())}}',
    ]) {
      await head.writeAsString(invalid);
      await expectLater(
          store.openSnapshot(),
          throwsA(isA<CatalogStorageException>()
              .having((error) => error.code, 'code', 'catalog.head_invalid')));
    }
  });

  test('a cleanup failure after head promotion leaves the new generation valid',
      () async {
    final old = await store.publish(_build('old'), expectedRootRevision: null);
    final gateway = _FaultGateway(
      await LocalTransactionFileGateway.open(projectRoot: project.path),
      failAfterPromotion: -1,
      failCleanupAfterHead: true,
    );
    final faulty = CatalogStorageStore(
      projectRoot: project.path,
      reader: const LocalProjectFileReader(),
      gateway: gateway,
    );
    final build = _build('new');
    await expectLater(
        faulty.publish(build, expectedRootRevision: old.rootRevision),
        throwsA(isA<StateError>()));
    final reopened = (await store.openSnapshot())!;
    expect(reopened.rootRevision, build.root.sha256);
    await reopened.snapshot.validate();
    expect((await old.snapshot.lookup(_key('a')))!.payload['name'], 'old');
  });

  test('stricter store admission fails before staging any objects', () async {
    final restricted = CatalogStorageStore(
      projectRoot: project.path,
      reader: const LocalProjectFileReader(),
      gateway:
          await LocalTransactionFileGateway.open(projectRoot: project.path),
      limits: CatalogStorageLimits(maxUnitBytes: 30),
    );
    await expectLater(
        restricted.publish(_build('old'), expectedRootRevision: null),
        throwsA(isA<FormatException>()));
    expect(await _files(project), isEmpty);
    expect(await _stagingDirectories(project), isEmpty);
  });

  test('head replacement between bounded read and revision check is stale',
      () async {
    final old = await store.publish(_build('old'), expectedRootRevision: null);
    final head = File('${project.path}/catalog/HEAD.json');
    final oldHead = await head.readAsBytes();
    final next = await store.publish(_build('new'),
        expectedRootRevision: old.rootRevision);
    final nextHead = await head.readAsBytes();
    await head.writeAsBytes(oldHead);
    var replaced = false;
    final gateway = _FaultGateway(
      await LocalTransactionFileGateway.open(projectRoot: project.path),
      failAfterPromotion: -1,
      beforeReadRevision: (path) async {
        if (path == CatalogStorageStore.headStorageKey && !replaced) {
          replaced = true;
          await head.writeAsBytes(nextHead);
        }
      },
    );
    final faulty = CatalogStorageStore(
        projectRoot: project.path,
        reader: const LocalProjectFileReader(),
        gateway: gateway);
    await expectLater(
        faulty.publish(_build('third'), expectedRootRevision: old.rootRevision),
        throwsA(isA<CatalogStorageException>().having(
            (error) => error.code, 'code', 'catalog.revision_conflict')));
    expect((await store.openSnapshot())!.rootRevision, next.rootRevision);
  });

  test('a head directory is corrupt rather than an absent generation',
      () async {
    await Directory('${project.path}/catalog/HEAD.json')
        .create(recursive: true);
    await expectLater(
        store.openSnapshot(),
        throwsA(isA<CatalogStorageException>().having(
            (error) => error.code, 'code', 'catalog.head_unavailable')));
  });

  test('head and catalog aliases inside the project are rejected', () async {
    await store.publish(_build('old'), expectedRootRevision: null);
    final head = File('${project.path}/catalog/HEAD.json');
    final relocated = await head.rename('${project.path}/internal-head.json');
    await Link(head.path).create(relocated.path);
    await expectLater(
        store.openSnapshot(), throwsA(isA<CatalogStorageException>()));
    await Link(head.path).delete();
    await relocated.rename(head.path);
    await Directory('${project.path}/catalog')
        .rename('${project.path}/internal-catalog');
    await Link('${project.path}/catalog')
        .create('${project.path}/internal-catalog');
    await expectLater(
        store.openSnapshot(), throwsA(isA<CatalogStorageException>()));
  });

  test('corruption during object publication cannot replace the old head',
      () async {
    final old = await store.publish(_build('old'), expectedRootRevision: null);
    var corrupted = false;
    final gateway = _FaultGateway(
      await LocalTransactionFileGateway.open(projectRoot: project.path),
      failAfterPromotion: -1,
      afterPromotion: (path) async {
        if (path.startsWith('catalog/objects/') && !corrupted) {
          corrupted = true;
          final file = File('${project.path}/$path');
          final bytes = await file.readAsBytes();
          bytes[bytes.length - 1] ^= 1;
          await file.writeAsBytes(bytes);
        }
      },
    );
    final faulty = CatalogStorageStore(
        projectRoot: project.path,
        reader: const LocalProjectFileReader(),
        gateway: gateway);
    await expectLater(
        faulty.publish(_build('new'), expectedRootRevision: old.rootRevision),
        throwsA(isA<CatalogStorageException>()
            .having((error) => error.code, 'code', 'catalog.object_corrupt')));
    expect((await store.openSnapshot())!.rootRevision, old.rootRevision);
    expect((await old.snapshot.lookup(_key('a')))!.payload['name'], 'old');
    expect(await _stagingDirectories(project), isEmpty);
  });
}

CatalogDefinitionKey _key(String id) =>
    CatalogDefinitionKey(CatalogDefinitionKind.values.first, id);

CatalogStorageBuild _build(String name) => CatalogStorageBuilder().build([
      CatalogDefinitionUnit(key: _key('a'), payload: {'name': name}),
      CatalogDefinitionUnit(key: _key('b'), payload: {'name': '$name-b'}),
    ]);

Future<Object> _outcome(Future<Object> operation) async {
  try {
    return await operation;
  } on Object catch (error) {
    return error;
  }
}

Future<List<String>> _files(Directory root) async {
  if (!await Directory('${root.path}/catalog').exists()) return [];
  return (await Directory('${root.path}/catalog')
      .list(recursive: true, followLinks: false)
      .where((entity) => entity is File)
      .map((entity) => entity.path.substring(root.path.length))
      .toList())
    ..sort();
}

Future<List<String>> _stagingDirectories(Directory root) async {
  final transactions =
      Directory('${root.path}/.pokemap/authoring/transactions');
  if (!await transactions.exists()) return [];
  return transactions
      .list(followLinks: false)
      .where((entry) => entry is Directory)
      .map((entry) => entry.path)
      .toList();
}

final class _FaultGateway implements TransactionFileGateway {
  _FaultGateway(this.delegate,
      {required this.failAfterPromotion,
      this.failCleanupAfterHead = false,
      this.beforeReadRevision,
      this.afterPromotion});
  final TransactionFileGateway delegate;
  final int failAfterPromotion;
  final bool failCleanupAfterHead;
  final Future<void> Function(String)? beforeReadRevision;
  final Future<void> Function(String)? afterPromotion;
  int promotions = 0;
  bool promotedHead = false;

  @override
  Future<T> withExclusiveWriteLock<T>(Future<T> Function() operation) =>
      delegate.withExclusiveWriteLock(operation);

  @override
  Future<String?> readResourceRevision(String storageKey) async {
    await beforeReadRevision?.call(storageKey);
    return delegate.readResourceRevision(storageKey);
  }

  @override
  Future<void> deleteTransaction(String operationId) async {
    if (promotedHead && failCleanupAfterHead) {
      throw StateError('injected cleanup failure');
    }
    await delegate.deleteTransaction(operationId);
  }

  @override
  Future<void> promoteStaged({
    required String operationId,
    required String storageKey,
    required TransactionPayloadKind kind,
    required String? expectedCurrentRevision,
  }) async {
    await delegate.promoteStaged(
      operationId: operationId,
      storageKey: storageKey,
      kind: kind,
      expectedCurrentRevision: expectedCurrentRevision,
    );
    await afterPromotion?.call(storageKey);
    promotions++;
    promotedHead = storageKey == 'catalog/HEAD.json';
    if (promotions == failAfterPromotion) throw StateError('injected failure');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      switch (invocation.memberName) {
        #listJournals => delegate.listJournals(),
        #readResource =>
          delegate.readResource(invocation.positionalArguments[0] as String),
        #stagePayload => delegate.stagePayload(
            operationId: invocation.namedArguments[#operationId] as String,
            storageKey: invocation.namedArguments[#storageKey] as String,
            kind: invocation.namedArguments[#kind] as TransactionPayloadKind,
            bytes: invocation.namedArguments[#bytes] as List<int>?),
        _ => super.noSuchMethod(invocation),
      };
}

final class _CountingReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final paths = <String>[];
  final delegate = const LocalProjectFileReader();

  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);

  @override
  Future<ProjectResourceProbe> probeResource({
    required String projectRoot,
    required String relativePath,
  }) =>
      delegate.probeResource(
          projectRoot: projectRoot, relativePath: relativePath);

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) =>
      throw StateError('unbounded reads are forbidden');

  @override
  bool get supportsStreamingResources => true;

  @override
  Stream<List<int>> openRead({
    required String projectRoot,
    required String relativePath,
  }) {
    paths.add(relativePath);
    return delegate.openRead(
        projectRoot: projectRoot, relativePath: relativePath);
  }
}

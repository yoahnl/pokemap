import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/transactions/authoring_payload.dart';
import 'package:map_authoring/src/support/authoring_performance_observer.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late CatalogStorageStore store;

  setUp(() async {
    final home = Platform.environment['HOME'] ?? Directory.systemTemp.path;
    final qa = Directory(Platform.environment['AVELUNE_QA_ROOT'] ??
        '$home/Library/Caches/AveluneQA/catalog-immutable-publication-tests');
    root = await (await qa.create(recursive: true)).createTemp('catalog-');
    store = await CatalogStorageStore.open(projectRoot: root.path);
  });

  tearDown(() => root.delete(recursive: true));

  for (final interrupted in [false, true]) {
    test(
        'a changed immutable stream leaves no activated content, interrupted=$interrupted',
        () async {
      final old =
          await store.publish(_build('old'), expectedRootRevision: null);
      final gateway =
          await LocalTransactionFileGateway.open(projectRoot: root.path);
      const path = 'assets/immutable.bin';
      final expected = AuthoringPayload.inline([1, 2, 3], storageKey: path);
      var opens = 0;
      final payload = await AuthoringPayload.verifiedSource(
          storageKey: path,
          byteLength: expected.byteLength,
          rawSha256: expected.rawSha256,
          openRead: () async* {
            if (opens++ == 0) {
              yield [1, 2, 3];
            } else if (interrupted) {
              yield [1];
              throw StateError('injected stream interruption');
            } else {
              yield [3, 2, 1];
            }
          });
      await expectLater(gateway.withExclusiveWriteLock(() async {
        try {
          await gateway.publishImmutableResource(
              operationId: 'immutable-failure', payload: payload);
        } finally {
          await gateway.deleteTransaction('immutable-failure');
        }
      }),
          throwsA(isA<TransactionFileGatewayException>()
              .having((error) => error.code, 'code', 'transaction.io')));
      expect(await File('${root.path}/$path').exists(), isFalse);
      expect(opens, 2);
      expect(await store.readHead(), old.snapshot.root);
      expect(await _staging(root), isEmpty);
    });
  }

  test('an immutable resource is idempotent and rejects replacement', () async {
    final metrics = _Metrics();
    final gateway = await LocalTransactionFileGateway.open(
        projectRoot: root.path, performanceObserver: metrics);
    const path = 'assets/immutable.bin';
    final payload = AuthoringPayload.inline([1, 2, 3], storageKey: path);
    await gateway.withExclusiveWriteLock(() async {
      try {
        await gateway.publishImmutableResource(
            operationId: 'immutable-first', payload: payload);
        await gateway.publishImmutableResource(
            operationId: 'immutable-first', payload: payload);
        await expectLater(
            gateway.publishImmutableResource(
                operationId: 'immutable-first',
                payload: AuthoringPayload.inline([3, 2, 1], storageKey: path)),
            throwsA(isA<TransactionFileGatewayException>().having(
                (error) => error.code,
                'code',
                'transaction.immutable_conflict')));
      } finally {
        await gateway.deleteTransaction('immutable-first');
      }
    });
    expect(await File('${root.path}/$path').readAsBytes(), [1, 2, 3]);
    expect(metrics.bytes, 3);
    expect(await _staging(root), isEmpty);
  });

  test('immutable objects are durably written once before head publication',
      () async {
    final old = await store.publish(_build('old'), expectedRootRevision: null);
    final next = _build('new');
    final metrics = _Metrics();
    final gateway = await LocalTransactionFileGateway.open(
        projectRoot: root.path, performanceObserver: metrics);
    final measured = CatalogStorageStore(
        projectRoot: root.path,
        reader: const LocalProjectFileReader(),
        gateway: gateway);
    await gateway.withExclusiveWriteLock(() =>
        measured.publishObjectsUnderLock(next.objects, maxConcurrentWrites: 8));
    expect(await store.readHead(), old.snapshot.root);
    await (await store.openRoot(next.root)).snapshot.validate();
    expect(metrics.bytes,
        next.objects.values.fold<int>(0, (sum, bytes) => sum + bytes.length));
    expect(await _staging(root), isEmpty);
    final before = metrics.bytes;
    await gateway.withExclusiveWriteLock(() =>
        measured.publishObjectsUnderLock(next.objects, maxConcurrentWrites: 8));
    expect(metrics.bytes, before);
  });

  test('a corrupt immutable object is preserved and the head stays unchanged',
      () async {
    final old = await store.publish(_build('old'), expectedRootRevision: null);
    final next = _build('new');
    final entry = next.objects.entries.first;
    final file = File('${root.path}/catalog/objects/${entry.key}.json');
    final corrupt = List<int>.filled(entry.value.length, 0);
    await file.writeAsBytes(corrupt, flush: true);
    await expectLater(
        store.gateway.withExclusiveWriteLock(() => store
            .publishObjectsUnderLock(next.objects, maxConcurrentWrites: 8)),
        throwsA(isA<CatalogStorageException>()
            .having((error) => error.code, 'code', 'catalog.object_corrupt')));
    expect(await store.readHead(), old.snapshot.root);
    expect(await file.readAsBytes(), corrupt);
    expect(await _staging(root), isEmpty);
  });

  test(
      'immutable publication rejects a symlink target without altering its destination',
      () async {
    final old = await store.publish(_build('old'), expectedRootRevision: null);
    final next = _build('new');
    final entry = next.objects.entries.first;
    final outside = File('${root.path}/unrelated');
    await outside.writeAsString('preserved', flush: true);
    await Link('${root.path}/catalog/objects/${entry.key}.json')
        .create(outside.path);
    await expectLater(
        store.gateway.withExclusiveWriteLock(() => store
            .publishObjectsUnderLock(next.objects, maxConcurrentWrites: 8)),
        throwsA(isA<TransactionFileGatewayException>()));
    expect(await outside.readAsString(), 'preserved');
    expect(await store.readHead(), old.snapshot.root);
  }, skip: Platform.isWindows ? 'Requires local symlink support' : false);
}

CatalogStorageBuild _build(String value) => CatalogStorageBuilder().build([
      for (var i = 0; i < 12; i++)
        CatalogDefinitionUnit(
            key: CatalogDefinitionKey(
                CatalogDefinitionKind.workspaceState, 'test_$i'),
            payload: {'value': '$value-$i'}),
    ]);

Future<List<FileSystemEntity>> _staging(Directory root) async {
  final directory = Directory('${root.path}/.pokemap/authoring/transactions');
  return await directory.exists()
      ? directory.list().where((entry) => entry is Directory).toList()
      : [];
}

class _Metrics implements AuthoringPerformanceObserver {
  int bytes = 0;
  @override
  void incrementCounter(String name, {int by = 1}) {
    if (name ==
        AuthoringPerformanceCounterName
            .gatewayStagedPayloadCompletedWriteInputBytes) {
      bytes += by;
    }
  }

  @override
  AuthoringPerformanceSpan? startSpan(String name) => null;
}

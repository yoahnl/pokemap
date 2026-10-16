import 'dart:io';
import 'dart:isolate';
import 'dart:async';
import 'dart:convert';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/src/deterministic_zip_encoder.dart';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

void main() {
  late Directory sandbox;
  late Directory sources;
  late LocalResourcePackStore store;
  var now = DateTime.utc(2026, 10, 16);
  var serial = 0;
  const scope = FileBackedPayloadScope(sessionId: 'one', projectId: 'project');
  const other = FileBackedPayloadScope(sessionId: 'two', projectId: 'project');
  const otherProject =
      FileBackedPayloadScope(sessionId: 'one', projectId: 'other');

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('pack-store-test-');
    sources = await Directory('${sandbox.path}/sources').create();
    now = DateTime.utc(2026, 10, 16);
    serial = 0;
    store = LocalResourcePackStore(
      cacheDirectory: '${sandbox.path}/cache',
      allowedSourceRoots: [sources.path],
      policy:
          const ResourcePackSecurityPolicy(maxChunkBytes: 3, maxCacheBytes: 20),
      clock: () => now,
      tokenFactory: (prefix) => '$prefix-${serial++}',
    );
  });
  tearDown(() async {
    await store.close();
    await sandbox.delete(recursive: true);
  });

  Future<File> source(String name, List<int> bytes) =>
      File('${sources.path}/$name').writeAsBytes(bytes);

  test('stages a stable private snapshot with a raw digest and bounded reads',
      () async {
    final file = await source('pack', [1, 2, 3, 4, 5]);
    final lease = await store.stageFile(scope: scope, sourcePath: file.path);
    expect(lease.payload.byteLength, 5);
    expect(lease.payload.rawSha256, sha256.convert([1, 2, 3, 4, 5]).toString());
    expect(lease.payload.handle, isNot(contains(sandbox.path)));
    await file.writeAsBytes([9]);
    expect(
        await store.withSource(
            scope: scope,
            handle: lease.payload.handle,
            read: (reader) => reader.readAtSync(0, 3)),
        [1, 2, 3]);
    expect(
        await store.withSource(
            scope: scope,
            handle: lease.payload.handle,
            read: (reader) => reader.length),
        5);
    expect(
        () => store.withSource(
            scope: scope,
            handle: lease.payload.handle,
            read: (reader) => reader.readAtSync(0, 4)),
        throwsA(isA<FileBackedPayloadException>()));
  });

  test('checks both session and stable project identity on every access',
      () async {
    final lease = await store.stageFile(
        scope: scope, sourcePath: (await source('pack', [1])).path);
    for (final owner in [other, otherProject]) {
      await expectLater(
          store.retain(scope: owner, handle: lease.payload.handle),
          throwsA(isA<FileBackedPayloadException>()));
      await expectLater(
          store.withSource(
              scope: owner,
              handle: lease.payload.handle,
              read: (s) => s.length),
          throwsA(isA<FileBackedPayloadException>()));
      await expectLater(store.release(scope: owner, leaseId: lease.leaseId),
          throwsA(isA<FileBackedPayloadException>()));
    }
  });

  test(
      'leases are independent, release is idempotent, TTL starts at last release',
      () async {
    final lease = await store.stageFile(
        scope: scope, sourcePath: (await source('pack', [1])).path);
    final pinned = await store.retain(
        scope: scope,
        handle: lease.payload.handle,
        purpose: FileBackedPayloadPurpose.history);
    expect(pinned.leaseId, isNot(lease.leaseId));
    expect(await store.release(scope: scope, leaseId: lease.leaseId), isTrue);
    expect(await store.release(scope: scope, leaseId: lease.leaseId), isFalse);
    now = now.add(const Duration(days: 2));
    await store.collectExpired();
    expect(
        await store.withSource(
            scope: scope, handle: lease.payload.handle, read: (s) => s.length),
        1);
    await store.release(scope: scope, leaseId: pinned.leaseId);
    now = now.add(const Duration(hours: 24) - Duration(microseconds: 1));
    await store.collectExpired();
    expect(store.cachedBytes, 1);
    now = now.add(const Duration(microseconds: 1));
    await store.collectExpired();
    expect(store.cachedBytes, 0);
    await expectLater(store.retain(scope: scope, handle: lease.payload.handle),
        throwsA(isA<FileBackedPayloadException>()));
  });

  test('exact picker authorization does not authorize a sibling or replacement',
      () async {
    final external = await Directory('${sandbox.path}/external').create();
    final chosen = await File('${external.path}/chosen').writeAsBytes([1, 2]);
    final sibling = await File('${external.path}/sibling').writeAsBytes([1, 2]);
    await store.authorizeSourceFile(chosen.path);
    await store.stageFile(scope: scope, sourcePath: chosen.path);
    await expectLater(store.stageFile(scope: scope, sourcePath: sibling.path),
        throwsA(isA<FileBackedPayloadException>()));
    await chosen.writeAsBytes([3, 4]);
    await expectLater(store.stageFile(scope: scope, sourcePath: chosen.path),
        throwsA(isA<FileBackedPayloadException>()));
  });

  test(
      'rejects links escaping a root and links retargeted after picker authorization',
      () async {
    final outside = await File('${sandbox.path}/outside').writeAsBytes([1]);
    final inside = await source('inside', [2]);
    final link = await Link('${sources.path}/link').create(outside.path);
    await expectLater(store.stageFile(scope: scope, sourcePath: link.path),
        throwsA(isA<FileBackedPayloadException>()));
    await store.authorizeSourceFile(link.path);
    await link.delete();
    await link.create(inside.path);
    await expectLater(store.stageFile(scope: scope, sourcePath: link.path),
        throwsA(isA<FileBackedPayloadException>()));
  });

  test('refuses source growth and same-size replacement during a chunked copy',
      () async {
    for (final bytes in [
      [1, 2, 3, 4, 5, 6, 7],
      [9, 9, 9, 9, 9, 9]
    ]) {
      final file = await source('mutable', [1, 2, 3, 4, 5, 6]);
      var changed = false;
      await expectLater(
          store.stageFile(
              scope: scope,
              sourcePath: file.path,
              onProgress: (copied) {
                if (!changed) {
                  changed = true;
                  file.writeAsBytesSync(bytes);
                }
              }),
          throwsA(isA<FileBackedPayloadException>()));
      expect(store.cachedBytes, 0);
      expect(store.reservedBytes, 0);
    }
  });

  test(
      'reserves the session budget before concurrent staging and cleans failures',
      () async {
    final first = store.stage(
        scope: scope, chunks: Stream.value(List.filled(12, 1)), byteLength: 12);
    final second = store.stage(
        scope: otherProject,
        chunks: Stream.value(List.filled(12, 2)),
        byteLength: 12);
    final outcomes = await Future.wait([
      first.then<Object>((v) => v, onError: (Object e) => e),
      second.then<Object>((v) => v, onError: (Object e) => e)
    ]);
    expect(outcomes.whereType<FileBackedPayloadLease>(), hasLength(1));
    expect(outcomes.whereType<FileBackedPayloadException>(), hasLength(1));
    expect(store.cachedBytes, 12);
    expect(store.reservedBytes, 0);
    await expectLater(
        store.stage(scope: scope, chunks: Stream.value([1, 2]), byteLength: 1),
        throwsA(isA<FileBackedPayloadException>()));
    expect(store.cachedBytes, 12);
    expect(store.reservedBytes, 0);
  });

  test('stream acquisition verifies declared digest and cleans cancellation',
      () async {
    await expectLater(
        store.stage(
            scope: scope,
            chunks: Stream.value([1, 2]),
            byteLength: 2,
            expectedRawSha256: '0' * 64),
        throwsA(isA<FileBackedPayloadException>()));
    await expectLater(
        store.stage(
            scope: scope,
            chunks: Stream.value([1, 2]),
            byteLength: 2,
            checkCancelled: () => throw StateError('cancelled')),
        throwsStateError);
    expect(store.cachedBytes, 0);
    expect(store.reservedBytes, 0);
  });

  test('plan, job, history and recovery leases each pin their shared snapshot',
      () async {
    final owner = await store.stage(
        scope: scope, chunks: Stream.value([1]), byteLength: 1);
    final pins = [
      for (final purpose in FileBackedPayloadPurpose.values)
        await store.retain(
            scope: scope, handle: owner.payload.handle, purpose: purpose)
    ];
    await store.release(scope: scope, leaseId: owner.leaseId);
    for (final pin in pins) {
      now = now.add(const Duration(days: 2));
      await store.collectExpired();
      expect(store.cachedBytes, 1);
      await store.release(scope: scope, leaseId: pin.leaseId);
    }
    now = now.add(const Duration(days: 1));
    await store.collectExpired();
    expect(store.cachedBytes, 0);
  });

  test(
      'invalid bytes and upstream failures leave no partial file or reservation',
      () async {
    await expectLater(
        store.stage(scope: scope, chunks: Stream.value([-1]), byteLength: 1),
        throwsA(isA<FileBackedPayloadException>()));
    await expectLater(
        store.stage(
            scope: scope,
            chunks: Stream.error(StateError('upstream')),
            byteLength: 1),
        throwsStateError);
    expect(store.cachedBytes, 0);
    expect(store.reservedBytes, 0);
    expect(
        await Directory('${sandbox.path}/cache')
            .list(recursive: true)
            .where((file) => file is File)
            .toList(),
        isEmpty);
  });

  test(
      'a failing stream cancellation releases its reservation and leaves the store reusable',
      () async {
    late StreamController<List<int>> chunks;
    chunks = StreamController<List<int>>(
        onListen: () => chunks.add([-1]),
        onCancel: () => Future<void>.error(StateError('cancel-failure')));
    try {
      await expectLater(
          store.stage(scope: scope, chunks: chunks.stream, byteLength: 1),
          throwsA(isA<StateError>()
              .having((error) => error.message, 'message', 'cancel-failure')));
      expect(store.reservedBytes, 0);
      expect(store.cachedBytes, 0);
      expect(await _diskBytes('${sandbox.path}/cache'), 0);
      final lease = await store.stage(
          scope: scope,
          chunks: Stream.value(List.filled(20, 1)),
          byteLength: 20);
      expect(lease.payload.byteLength, 20);
      expect(store.cachedBytes, 20);
      expect(store.reservedBytes, 0);
      expect(
          await store.withSource(
              scope: scope,
              handle: lease.payload.handle,
              read: (source) => source.readAtSync(0, 3)),
          [1, 1, 1]);
    } finally {
      await chunks.close();
    }
  });

  test('admits exact byte and cache boundaries without lifting signed limits',
      () async {
    final lease = await store.stage(
        scope: scope, chunks: Stream.value(List.filled(20, 1)), byteLength: 20);
    expect(lease.payload.byteLength, 20);
    await expectLater(
        store.stage(scope: scope, chunks: Stream.value([1]), byteLength: 1),
        throwsA(isA<FileBackedPayloadException>()));
    expect(store.cachedBytes, 20);
    await expectLater(
        store.stage(
            scope: scope,
            chunks: const Stream.empty(),
            byteLength: ResourcePackSecurityPolicy.maxArchiveBytesV1 + 1),
        throwsA(isA<FileBackedPayloadException>()));
  });
  test('keeps active readers alive through expiration collection', () async {
    final lease = await store.stage(
        scope: scope, chunks: Stream.value([1, 2]), byteLength: 2);
    final pending = store.withSource(
        scope: scope,
        handle: lease.payload.handle,
        read: (reader) async {
          await store.release(scope: scope, leaseId: lease.leaseId);
          now = now.add(const Duration(days: 2));
          await store.collectExpired();
          expect(store.cachedBytes, 2);
          return reader.readAtSync(0, 2);
        });
    expect(await pending, [1, 2]);
    await store.collectExpired();
    expect(store.cachedBytes, 0);
  });
  test('opens a verified source in a real worker without exposing its path',
      () async {
    final lease = await store.stage(
        scope: scope, chunks: Stream.value([1, 2, 3]), byteLength: 3);
    expect(
        await store.withSourceInIsolate(
            scope: scope,
            handle: lease.payload.handle,
            read: (reader) => reader.readAtSync(0, 3).reduce((a, b) => a + b)),
        6);
  });
  test('refuses a cache inside a native project before any native write',
      () async {
    final project = await Directory('${sandbox.path}/native').create();
    await File('${project.path}/project.json').writeAsString('{}');
    final before =
        await project.list(recursive: true).map((file) => file.path).toList();
    final invalid = LocalResourcePackStore(
        cacheDirectory: '${project.path}/cache',
        allowedSourceRoots: [sources.path]);
    await expectLater(
        invalid.stage(scope: scope, chunks: Stream.value([1]), byteLength: 1),
        throwsA(isA<FileBackedPayloadException>()));
    expect(
        await project.list(recursive: true).map((file) => file.path).toList(),
        before);
    await invalid.close();
  });
  test(
      'refuses missing caches through aliases of native project roots and asset directories before any creation',
      () async {
    final project = await Directory('${sandbox.path}/native').create();
    await File('${project.path}/project.json').writeAsString('{}');
    final assets = await Directory('${project.path}/assets').create();
    final before =
        await project.list(recursive: true).map((file) => file.path).toList();
    for (final (name, target) in [
      ('root', project.path),
      ('assets', assets.path)
    ]) {
      final alias = await Link('${sandbox.path}/external-$name').create(target);
      final invalid = LocalResourcePackStore(
          cacheDirectory: '${alias.path}/missing/cache',
          allowedSourceRoots: [sources.path]);
      await expectLater(
          invalid.stage(scope: scope, chunks: Stream.value([1]), byteLength: 1),
          throwsA(isA<FileBackedPayloadException>().having(
              (error) => error.code,
              'code',
              'resource_pack.cache_inside_project')));
      expect(
          await project.list(recursive: true).map((file) => file.path).toList(),
          before);
      expect(await Directory('$target/missing').exists(), isFalse);
      expect(invalid.cachedBytes, 0);
      expect(invalid.reservedBytes, 0);
      await invalid.close();
    }
  });
  test(
      'resolves a safe cache ancestor alias and keeps the resulting snapshot private',
      () async {
    final external =
        await Directory('${sandbox.path}/safe-cache-root').create();
    final alias =
        await Link('${sandbox.path}/safe-cache-alias').create(external.path);
    final safe = LocalResourcePackStore(
        cacheDirectory: '${alias.path}/new/cache',
        allowedSourceRoots: [sources.path]);
    final lease = await safe.stage(
        scope: scope, chunks: Stream.value([1, 2]), byteLength: 2);
    expect(
        await safe.withSource(
            scope: scope,
            handle: lease.payload.handle,
            read: (reader) => reader.readAtSync(0, 2)),
        [1, 2]);
    expect(await Directory('${external.path}/new/cache').exists(), isTrue);
    await safe.release(scope: scope, leaseId: lease.leaseId);
    await safe.close();
  });
  test(
      'staging and worker inspection leave an existing native project unchanged',
      () async {
    final project = await Directory('${sandbox.path}/native').create();
    await File('${project.path}/project.json')
        .writeAsString('{"name":"Existing"}');
    await File('${project.path}/unchanged.bin').writeAsBytes([7, 8, 9]);
    Future<Map<String, String>> inventory() async => {
          for (final file in await project
              .list(recursive: true)
              .where((file) => file is File)
              .cast<File>()
              .toList())
            file.path: sha256.convert(await file.readAsBytes()).toString(),
        };
    final before = await inventory();
    final packStore = LocalResourcePackStore(
        cacheDirectory: '${sandbox.path}/inspection-cache',
        allowedSourceRoots: [sources.path],
        policy: const ResourcePackSecurityPolicy(maxChunkBytes: 7));
    final file = await source('valid.aveluneassets', _minimalPack());
    final lease =
        await packStore.stageFile(scope: scope, sourcePath: file.path);
    final result = await packStore.withSourceInIsolate(
        scope: scope,
        handle: lease.payload.handle,
        read: (source) => const ResourcePackInspector(
                policy: ResourcePackSecurityPolicy(maxChunkBytes: 7))
            .inspectSourceSync(source));
    expect(result.resourceCount, 0);
    expect(await inventory(), before);
    await packStore.release(scope: scope, leaseId: lease.leaseId);
    await packStore.close();
  });

  group('store service shutdown', () {
    test(
        'released and unreleased owners are removed before a fresh store admits its budget',
        () async {
      for (final releaseOwner in [true, false]) {
        final cache = '${sandbox.path}/shutdown-$releaseOwner';
        LocalResourcePackStore create() => LocalResourcePackStore(
            cacheDirectory: cache,
            allowedSourceRoots: const [],
            policy: const ResourcePackSecurityPolicy(maxCacheBytes: 4));
        final first = create();
        final lease = await first.stage(
            scope: scope, chunks: Stream.value([1, 2, 3, 4]), byteLength: 4);
        final history = await first.retain(
            scope: scope,
            handle: lease.payload.handle,
            purpose: FileBackedPayloadPurpose.history);
        expect(history.leaseId, isNot(lease.leaseId));
        if (releaseOwner) {
          await first.release(scope: scope, leaseId: lease.leaseId);
        }
        final closing = first.close();
        expect(identical(closing, first.close()), isTrue);
        await closing;
        expect(first.cachedBytes, 0);
        expect(first.reservedBytes, 0);
        expect(await _diskBytes(cache), 0);
        final second = create();
        await second.stage(
            scope: scope, chunks: Stream.value([5, 6, 7, 8]), byteLength: 4);
        expect(second.cachedBytes, 4);
        expect(await _diskBytes(cache), 4);
        await second.close();
      }
    });
    test('waits for an active source reader before deleting its backing file',
        () async {
      final lease = await store.stage(
          scope: scope, chunks: Stream.value([1, 2, 3]), byteLength: 3);
      final entered = Completer<void>();
      final resume = Completer<void>();
      final reading = store.withSource(
          scope: scope,
          handle: lease.payload.handle,
          read: (reader) async {
            entered.complete();
            await resume.future;
            return reader.readAtSync(0, 3);
          });
      await entered.future;
      var finished = false;
      final closing = store.close().then((_) {
        finished = true;
      });
      await Future<void>.delayed(Duration.zero);
      expect(finished, isFalse);
      expect(await _diskBytes('${sandbox.path}/cache'), 3);
      resume.complete();
      expect(await reading, [1, 2, 3]);
      await closing;
      expect(await _diskBytes('${sandbox.path}/cache'), 0);
    });
    test('waits for a worker source reader before deleting its backing file',
        () async {
      final lease = await store.stage(
          scope: scope, chunks: Stream.value([1, 2, 3]), byteLength: 3);
      final started = ReceivePort();
      final reading = store.withSourceInIsolate(
          scope: scope,
          handle: lease.payload.handle,
          read: _workerReadAfterSignal(started.sendPort));
      await started.first;
      var finished = false;
      final closing = store.close().then((_) {
        finished = true;
      });
      await Future<void>.delayed(Duration.zero);
      expect(finished, isFalse);
      expect(await reading, 3);
      await closing;
      expect(await _diskBytes('${sandbox.path}/cache'), 0);
      started.close();
    });
    test(
        'cancels a stalled payload stream and drains its writer before cleanup',
        () async {
      final listened = Completer<void>();
      final stream = StreamController<List<int>>(onListen: listened.complete);
      final staging = store
          .stage(scope: scope, chunks: stream.stream, byteLength: 6)
          .then<Object>((lease) => lease, onError: (Object error) => error);
      await listened.future;
      stream.add([1, 2, 3]);
      await Future<void>.delayed(Duration.zero);
      await store.close().timeout(const Duration(seconds: 5));
      expect(await staging, isA<FileBackedPayloadException>());
      await stream.close();
      expect(store.cachedBytes, 0);
      expect(store.reservedBytes, 0);
      expect(await _diskBytes('${sandbox.path}/cache'), 0);
    });
    test('drains an in-flight file copy without deleting its selected source',
        () async {
      final file = await source('copy-source', [1, 2, 3, 4, 5, 6, 7, 8, 9]);
      final progressed = Completer<void>();
      final staging = store.stageFile(
          scope: scope,
          sourcePath: file.path,
          onProgress: (_) {
            if (!progressed.isCompleted) progressed.complete();
          });
      final failed =
          expectLater(staging, throwsA(isA<FileBackedPayloadException>()));
      await progressed.future;
      final closing = store.close();
      await failed;
      await closing;
      expect(await file.readAsBytes(), [1, 2, 3, 4, 5, 6, 7, 8, 9]);
      expect(store.cachedBytes, 0);
      expect(store.reservedBytes, 0);
      expect(await _diskBytes('${sandbox.path}/cache'), 0);
    });
    test('refuses reentrant close before changing the live service state',
        () async {
      final lease = await store.stage(
          scope: scope, chunks: Stream.value([1, 2]), byteLength: 2);
      await store.withSource(
          scope: scope,
          handle: lease.payload.handle,
          read: (source) {
            expect(
                () => store.close(),
                throwsA(isA<FileBackedPayloadException>().having(
                    (error) => error.code,
                    'code',
                    'resource_pack.close_reentrant')));
            expect(source.readAtSync(0, 2), [1, 2]);
          });
      final file = await source('reentrant-copy', [1, 2, 3, 4]);
      await store.stageFile(
          scope: scope,
          sourcePath: file.path,
          onProgress: (_) {
            expect(() => store.close(),
                throwsA(isA<FileBackedPayloadException>()));
          });
      expect(store.cachedBytes, 6);
      await store.close();
      expect(store.cachedBytes, 0);
    });
    test(
        'preserves outer ownership through nested callbacks from another store',
        () async {
      final second = LocalResourcePackStore(
          cacheDirectory: '${sandbox.path}/nested-store',
          allowedSourceRoots: const []);
      try {
        final firstLease = await store.stage(
            scope: scope, chunks: Stream.value([1, 2]), byteLength: 2);
        final secondLease = await second.stage(
            scope: other, chunks: Stream.value([3, 4]), byteLength: 2);
        await store.withSource(
            scope: scope,
            handle: firstLease.payload.handle,
            read: (firstSource) async {
              await second.withSource(
                  scope: other,
                  handle: secondLease.payload.handle,
                  read: (secondSource) async {
                    Object? rejected;
                    try {
                      await store
                          .close()
                          .timeout(const Duration(milliseconds: 200));
                    } catch (error) {
                      rejected = error;
                    }
                    expect(
                        rejected,
                        isA<FileBackedPayloadException>().having(
                            (error) => error.code,
                            'code',
                            'resource_pack.close_reentrant'));
                    expect(firstSource.readAtSync(0, 2), [1, 2]);
                    expect(secondSource.readAtSync(0, 2), [3, 4]);
                  });
            });
        expect(
            await store.withSource(
                scope: scope,
                handle: firstLease.payload.handle,
                read: (source) => source.readAtSync(0, 2)),
            [1, 2]);
        expect(
            await second.withSource(
                scope: other,
                handle: secondLease.payload.handle,
                read: (source) => source.readAtSync(0, 2)),
            [3, 4]);
        await store.close();
        await second.close();
        expect(await _diskBytes('${sandbox.path}/cache'), 0);
        expect(await _diskBytes('${sandbox.path}/nested-store'), 0);
      } finally {
        await second.close();
      }
    });
    test('never deletes a live sibling store sharing the cache root', () async {
      final cache = '${sandbox.path}/shared-cache';
      final first = LocalResourcePackStore(
          cacheDirectory: cache, allowedSourceRoots: const []);
      final second = LocalResourcePackStore(
          cacheDirectory: cache, allowedSourceRoots: const []);
      await first.stage(
          scope: scope, chunks: Stream.value([1, 2, 3]), byteLength: 3);
      final lease = await second.stage(
          scope: other, chunks: Stream.value([4, 5]), byteLength: 2);
      await first.close();
      expect(await _diskBytes(cache), 2);
      expect(
          await second.withSource(
              scope: other,
              handle: lease.payload.handle,
              read: (source) => source.readAtSync(0, 2)),
          [4, 5]);
      await first.close();
      expect(await _diskBytes(cache), 2);
      await second.close();
      expect(await _diskBytes(cache), 0);
    });
  });
  test('a reused token cannot leak accounting or partial files', () async {
    final invalid = LocalResourcePackStore(
        cacheDirectory: '${sandbox.path}/invalid-cache',
        allowedSourceRoots: [sources.path],
        tokenFactory: (_) => 'same');
    await expectLater(
        invalid.stage(scope: scope, chunks: Stream.value([1]), byteLength: 1),
        throwsA(isA<FileBackedPayloadException>()));
    expect(invalid.cachedBytes, 0);
    expect(invalid.reservedBytes, 0);
    expect(
        await Directory('${sandbox.path}/invalid-cache')
            .list(recursive: true)
            .where((file) => file is File)
            .toList(),
        isEmpty);
    await invalid.close();
  });
  test(
      'source callbacks cannot retain an open descriptor and corruption is refused',
      () async {
    final lease = await store.stage(
        scope: scope, chunks: Stream.value([1, 2]), byteLength: 2);
    final captured = await store.withSource(
        scope: scope, handle: lease.payload.handle, read: (s) => s);
    expect(() => captured.readAtSync(0, 1),
        throwsA(isA<FileBackedPayloadException>()));
    final stage = (await Directory('${sandbox.path}/cache')
            .list(recursive: true)
            .where((f) => f is File)
            .toList())
        .single as File;
    await stage.writeAsBytes([3, 4]);
    await expectLater(
        store.withSource(
            scope: scope, handle: lease.payload.handle, read: (s) => s.length),
        throwsA(isA<FileBackedPayloadException>()));
  });
}

List<int> _minimalPack() {
  final bytes = utf8.encode(jsonEncode(ResourcePackCatalog().toJson()));
  final catalog = ResourcePackInventoryFile(
      path: 'catalog.json',
      byteLength: bytes.length,
      mediaType: 'application/json',
      rawSha256: sha256.convert(bytes).toString());
  final manifest = ResourcePackManifest.fromJson({
    'format': 'avelune.asset-pack',
    'formatVersion': 1,
    'pack': {
      'id': 'original',
      'version': '1.0.0',
      'name': 'Original',
      'description': '',
      'universeId': 'original',
      'authors': ['Original'],
      'provenance': 'Original'
    },
    'compatibility': {
      'resourceLibraryCatalogVersion': 2,
      'smartTileCatalogVersion': 7,
      'borderCatalogVersion': 10,
      'requiredCapabilities': <String>[],
      'tileWidth': 2,
      'tileHeight': 2
    },
    'content': {
      'catalog': catalog.toJson(),
      'files': <Object?>[],
      'treeSha256': resourcePackTreeSha256(catalog, const [])
    },
  });
  return DeterministicZipEncoder.encode([
    MapEntry('catalog.json', bytes),
    MapEntry(
        'manifest.json', const ResourcePackManifestCodec().encodeUtf8(manifest))
  ]);
}

Future<int> _diskBytes(String path) async {
  final directory = Directory(path);
  if (!await directory.exists()) return 0;
  var total = 0;
  await for (final file in directory
      .list(recursive: true)
      .where((entity) => entity is File)
      .cast<File>()) {
    total += await file.length();
  }
  return total;
}

int Function(RandomAccessPackageSource) _workerReadAfterSignal(
        SendPort started) =>
    (source) {
      started.send(true);
      sleep(const Duration(milliseconds: 150));
      return source.readAtSync(0, 3).length;
    };

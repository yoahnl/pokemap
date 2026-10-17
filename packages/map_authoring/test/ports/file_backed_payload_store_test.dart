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

  test('observes real store bytes through the existing local API observer',
      () async {
    final observer = _ByteObserver();
    addTearDown(observer.close);
    final project =
        await Directory('${sandbox.path}/observed-project').create();
    await File('${project.path}/project.json').writeAsString(jsonEncode(
      ProjectManifest(name: 'Observed', maps: [], tilesets: []).toJson(),
    ));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [project.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final opened = await ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
    ).openProject(project.path);
    final api = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: ProjectSnapshotLoader(handles: handles),
      resourcePackSourceRoots: [sources.path],
      performanceObserver: observer,
    );
    await api.attachProject(
      projectRootPath: project.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    try {
      final observed = api.resourcePackPayloadStore(opened.projectHandle);
      final file = await source('observed-source', [1, 2, 3, 4, 5, 6, 7]);
      await observed.authorizeSourceFile(file.path);
      final lease =
          await observed.stageFile(scope: scope, sourcePath: file.path);
      final bytes = await observed.withSource(
        scope: scope,
        handle: lease.payload.handle,
        read: (reader) =>
            [...reader.readAtSync(0, 2), ...reader.readAtSync(5, 2)],
      );
      expect(bytes, [1, 2, 6, 7]);
      expect(observer.resourcePackCounters, {
        'io.resourcePack.authorize.readBytes': 7,
        'io.resourcePack.stageSource.readBytes': 7,
        'io.resourcePack.stagePrivate.completedWriteInputBytes': 7,
        'io.resourcePack.postCopyVerify.readBytes': 7,
        'io.resourcePack.stageVerify.readBytes': 7,
        'io.resourcePack.consumerReadAt.returnedBytes': 4,
      });
      await observed.release(scope: scope, leaseId: lease.leaseId);
    } finally {
      await api.detachWorkspace(opened.workspaceHandle);
      handles.closeWorkspace(opened.workspaceHandle);
    }
  });

  Future<_ByteObserver> observeStore() async {
    await store.close();
    final observer = _ByteObserver();
    addTearDown(observer.close);
    store = LocalResourcePackStore(
      cacheDirectory: '${sandbox.path}/cache',
      allowedSourceRoots: [sources.path],
      performanceObserver: observer,
      policy:
          const ResourcePackSecurityPolicy(maxChunkBytes: 3, maxCacheBytes: 20),
      clock: () => now,
      tokenFactory: (prefix) => '$prefix-${serial++}',
    );
    return observer;
  }

  test('counts completed private writes while a real stream is backpressured',
      () async {
    final observer = await observeStore();
    final firstWritten = Completer<void>();
    final continueInput = Completer<void>();
    final failure = StateError('source interrupted after its final input');
    Stream<List<int>> input() async* {
      yield [1, 2, 3];
      expect(
          observer.counters[
              'io.resourcePack.stagePrivate.completedWriteInputBytes'],
          3);
      firstWritten.complete();
      await continueInput.future;
      yield [4, 5];
      throw failure;
    }

    final staging = store.stage(scope: scope, chunks: input(), byteLength: 5);
    await firstWritten.future;
    expect(store.reservedBytes, 5);
    expect(store.cachedBytes, 0);
    expect(
        observer
            .counters['io.resourcePack.stagePrivate.completedWriteInputBytes'],
        3);
    final rejected = expectLater(staging, throwsA(same(failure)));
    continueInput.complete();
    await rejected;
    expect(
        observer
            .counters['io.resourcePack.stagePrivate.completedWriteInputBytes'],
        5);
    expect(
        observer.counters.containsKey('io.resourcePack.stageSource.readBytes'),
        isFalse);
    expect(store.reservedBytes, 0);
    expect(store.cachedBytes, 0);
    expect(await _diskBytes('${sandbox.path}/cache'), 0);
  });

  test(
      'aggregates worker verification and actual reads without sending observer',
      () async {
    final observer = await observeStore();
    final lease = await store.stage(
        scope: scope, chunks: Stream.value([1, 2, 3, 4, 5]), byteLength: 5);
    observer.counters.clear();
    final value = await store.withSourceInIsolate(
      scope: scope,
      handle: lease.payload.handle,
      read: _readWorkerPair,
    );
    expect(value, [1, 2]);
    expect(observer.resourcePackCounters, {
      'io.resourcePack.workerVerify.readBytes': 5,
      'io.resourcePack.workerConsumerReadAt.returnedBytes': 2,
    });
  });

  test('aggregates distinct worker sources once per pre and post verification',
      () async {
    final observer = await observeStore();
    final first = await store.stage(
        scope: scope, chunks: Stream.value([1, 2, 3, 4, 5]), byteLength: 5);
    final second = await store.stage(
        scope: scope, chunks: Stream.value([8, 9, 10]), byteLength: 3);
    observer.counters.clear();
    final value = await store.withSourcesInIsolate(
      scope: scope,
      handles: [
        first.payload.handle,
        second.payload.handle,
        first.payload.handle
      ],
      read: _readWorkerSources,
    );
    expect(value, [1, 2, 9]);
    expect(observer.resourcePackCounters, {
      'io.resourcePack.workerVerify.readBytes': 16,
      'io.resourcePack.workerConsumerReadAt.returnedBytes': 3,
    });
  });

  for (final failure in ['consumer', 'corruption']) {
    test(
        'marks failed worker observation incomplete for $failure without changing error',
        () async {
      final observer = await observeStore();
      final lease = await store.stage(
          scope: scope, chunks: Stream.value([1, 2, 3, 4, 5]), byteLength: 5);
      observer.counters.clear();
      if (failure == 'corruption') {
        final files = await Directory('${sandbox.path}/cache')
            .list(recursive: true)
            .where((file) => file is File)
            .cast<File>()
            .toList();
        await files.single.writeAsBytes([5, 4, 3, 2, 1]);
      }
      await expectLater(
        store.withSourceInIsolate(
          scope: scope,
          handle: lease.payload.handle,
          read: failure == 'consumer' ? _failWorkerRead : _readWorkerPair,
        ),
        throwsA(isA<FileBackedPayloadException>().having(
            (error) => error.code,
            'code',
            failure == 'consumer'
                ? 'original.worker_probe'
                : 'resource_pack.stage_corrupt')),
      );
      expect(
          observer
              .counters['io.resourcePack.workerCoverage.incompleteOperations'],
          1);
      expect(
          observer.counters
              .containsKey('io.resourcePack.workerVerify.readBytes'),
          isFalse);
      expect(
          observer.counters.containsKey(
              'io.resourcePack.workerConsumerReadAt.returnedBytes'),
          isFalse);
      expect(store.cachedBytes, 5);
      expect(store.reservedBytes, 0);
    });
  }

  test(
      'marks multi-source failed worker observation incomplete without changing error',
      () async {
    final observer = await observeStore();
    final lease = await store.stage(
        scope: scope, chunks: Stream.value([1, 2, 3, 4, 5]), byteLength: 5);
    observer.counters.clear();
    await expectLater(
      store.withSourcesInIsolate(
          scope: scope,
          handles: [lease.payload.handle, lease.payload.handle],
          read: _failWorkerSources),
      throwsA(isA<FileBackedPayloadException>()
          .having((error) => error.code, 'code', 'original.worker_probe')),
    );
    expect(
        observer
            .counters['io.resourcePack.workerCoverage.incompleteOperations'],
        1);
    expect(
        observer.counters.containsKey('io.resourcePack.workerVerify.readBytes'),
        isFalse);
    expect(
        observer.counters
            .containsKey('io.resourcePack.workerConsumerReadAt.returnedBytes'),
        isFalse);
    expect(store.cachedBytes, 5);
  });

  test('absent observer keeps the same archive bytes and lease behavior',
      () async {
    final observer = _ByteObserver();
    addTearDown(observer.close);
    final observed = LocalResourcePackStore(
      cacheDirectory: '${sandbox.path}/observed-cache',
      allowedSourceRoots: [sources.path],
      performanceObserver: observer,
      policy: const ResourcePackSecurityPolicy(maxChunkBytes: 7),
    );
    final ordinary = LocalResourcePackStore(
      cacheDirectory: '${sandbox.path}/ordinary-cache',
      allowedSourceRoots: [sources.path],
      policy: const ResourcePackSecurityPolicy(maxChunkBytes: 7),
    );
    addTearDown(observed.close);
    addTearDown(ordinary.close);
    final bytes = _minimalPack();
    final file = await source('same-pack', bytes);
    final inspections = <ResourcePackInspection>[];
    for (final local in [ordinary, observed]) {
      final lease = await local.stageFile(scope: scope, sourcePath: file.path);
      expect(lease.payload.rawSha256, sha256.convert(bytes).toString());
      expect(lease.payload.byteLength, bytes.length);
      final pin =
          local.retainForJob(scope: scope, handle: lease.payload.handle);
      await local.release(scope: scope, leaseId: lease.leaseId);
      inspections.add(await local.withSourceInIsolate(
          scope: scope, handle: pin.payload.handle, read: _inspectWorkerPack));
      expect(local.cachedBytes, bytes.length);
      await local.release(scope: scope, leaseId: pin.leaseId);
      await local.close();
      expect(local.cachedBytes, 0);
    }
    expect(inspections.map((value) => value.archiveRawSha256).toSet(),
        {sha256.convert(bytes).toString()});
    expect(inspections.map((value) => value.resourceCount), [0, 0]);
    expect(
        observer
            .counters['io.resourcePack.stagePrivate.completedWriteInputBytes'],
        bytes.length);
  });

  test(
      'licence staging validates bounded UTF8 during copy before publishing a payload',
      () async {
    final valid = await source('split-utf8', utf8.encode('é😀'));
    final lease =
        await store.stageLicenseFile(scope: scope, sourcePath: valid.path);
    expect(lease.payload.byteLength, 6);
    for (final bytes in [
      [255],
      [0xf0, 0x9f],
      [0xc0, 0xaf]
    ]) {
      final file = await source('invalid', bytes);
      await expectLater(
          store.stageLicenseFile(scope: scope, sourcePath: file.path),
          throwsA(isA<FileBackedPayloadException>().having(
              (error) => error.code,
              'code',
              'resource_pack.license_invalid_utf8')));
      expect(store.cachedBytes, 6);
      expect(store.reservedBytes, 0);
    }
    final bounded = LocalResourcePackStore(
        cacheDirectory: '${sandbox.path}/bounded',
        allowedSourceRoots: [sources.path],
        policy: const ResourcePackSecurityPolicy(maxFileBytes: 3));
    var copied = 0;
    try {
      await expectLater(
          bounded.stageLicenseFile(
              scope: scope,
              sourcePath: valid.path,
              onProgress: (length) {
                copied = length;
              }),
          throwsA(isA<FileBackedPayloadException>()));
      expect(copied, 0);
      expect(bounded.cachedBytes, 0);
      expect(bounded.reservedBytes, 0);
    } finally {
      await bounded.close();
    }
  });

  test(
    'immediate job pin survives owner release and expiry until settlement',
    () async {
      final owner = await store.stageFile(
        scope: scope,
        sourcePath: (await source('queued', [1, 2, 3])).path,
      );
      final pin = store.retainForJob(
        scope: scope,
        handle: owner.payload.handle,
      );
      await store.release(scope: scope, leaseId: owner.leaseId);
      now = now.add(Duration(days: 1));
      await store.collectExpired();
      expect(
        await store.withSource(
          scope: scope,
          handle: pin.payload.handle,
          read: (source) => source.readAtSync(0, 3),
        ),
        [1, 2, 3],
      );
      expect(
        () => store.retainForJob(scope: other, handle: pin.payload.handle),
        throwsA(isA<FileBackedPayloadException>()),
      );
      await store.release(scope: scope, leaseId: pin.leaseId);
      now = now.add(Duration(days: 1));
      await store.collectExpired();
      await expectLater(
        store.withSource(
          scope: scope,
          handle: pin.payload.handle,
          read: (source) => source.length,
        ),
        throwsA(isA<FileBackedPayloadException>()),
      );
    },
  );

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

final class _ByteObserver implements AuthoringPerformanceObserver {
  final counters = <String, int>{};
  final _notSendable = ReceivePort();
  Map<String, int> get resourcePackCounters => {
        for (final entry in counters.entries)
          if (entry.key.startsWith('io.resourcePack.')) entry.key: entry.value,
      };
  @override
  AuthoringPerformanceSpan? startSpan(String name) => null;
  @override
  void incrementCounter(String name, {int by = 1}) {
    counters.update(name, (value) => value + by, ifAbsent: () => by);
  }

  void close() => _notSendable.close();
}

List<int> _readWorkerPair(RandomAccessPackageSource source) =>
    source.readAtSync(0, 2);
List<int> _readWorkerSources(Map<String, RandomAccessPackageSource> sources) {
  final readers = sources.values.toList();
  return [...readers[0].readAtSync(0, 2), ...readers[1].readAtSync(1, 1)];
}

List<int> _failWorkerRead(RandomAccessPackageSource source) {
  source.readAtSync(0, 1);
  throw FileBackedPayloadException(
      'original.worker_probe', 'original worker failure');
}

ResourcePackInspection _inspectWorkerPack(RandomAccessPackageSource source) =>
    const ResourcePackInspector(
            policy: ResourcePackSecurityPolicy(maxChunkBytes: 7))
        .inspectSourceSync(source);

List<int> _failWorkerSources(Map<String, RandomAccessPackageSource> sources) =>
    _failWorkerRead(sources.values.first);

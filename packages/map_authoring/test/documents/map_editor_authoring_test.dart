import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_authoring/src/transactions/journaled_transaction.dart';
import 'package:map_authoring/src/transactions/local_transaction_file_gateway.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late WorkspacePolicy policy;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('editor_state_');
    root = Directory(await root.resolveSymbolicLinks());
    await Directory('${root.path}/maps').create();
    await File('${root.path}/maps/shore.json')
        .writeAsString('map must not be decoded');
    await File('${root.path}/project.json')
        .writeAsString('project must not be decoded');
    policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path],
        fileReader: const LocalProjectFileReader());
  });
  tearDown(() => root.delete(recursive: true));

  test('first and repeated lock saves only touch the selected bounded document',
      () async {
    final blocked = <String>[];
    for (final relative in [
      'project.json',
      'maps/shore.json',
      'maps/unrelated.json',
      '.pokemap/authoring/history.jsonl',
      '.pokemap/authoring/audit.jsonl',
      '.pokemap/authoring/idempotency.jsonl',
      '.pokemap/authoring/transactions/foreign/journal.json'
    ]) {
      final file = File('${root.path}/$relative');
      await file.parent.create(recursive: true);
      if (!await file.exists()) await file.writeAsString('x' * 2000000);
      blocked.add(file.path);
    }
    final outside = Zone.current;
    final attempts = <String>[];
    await IOOverrides.runZoned(() async {
      for (var i = 0; i < 3; i++) {
        final service = LocalMapEditorAuthoring(policy: policy);
        final before =
            await service.inspect(projectRoot: root.path, mapId: 'shore');
        final state =
            MapEditorState(lockedElements: {'model:mist_$i', 'decor:mist_$i'});
        final result = await service.set(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision: before.revision,
            state: state,
            operationId: 'lock_$i');
        final reopened = await LocalMapEditorAuthoring(policy: policy)
            .inspect(projectRoot: root.path, mapId: 'shore');
        expect(reopened.state, state);
        expect(reopened.revision, result.afterRevision);
      }
    }, createFile: (path) {
      final file = outside.run(() => File(path));
      return blocked.contains(file.path)
          ? _UnreadableFile(file, attempts)
          : file;
    });
    expect(attempts, isEmpty);
    expect(await File('${root.path}/maps/shore.editor.json').length(),
        lessThan(1024));
  });

  test('replay is idempotent and stale writers and undo preserve newer edits',
      () async {
    final service = LocalMapEditorAuthoring(policy: policy);
    final before =
        await service.inspect(projectRoot: root.path, mapId: 'shore');
    final state = MapEditorState(lockedElements: {'model:mist'});
    final result = await service.set(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: before.revision,
        state: state,
        operationId: 'lock');
    final replay = await service.set(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: before.revision,
        state: state,
        operationId: 'lock');
    expect(replay.receipt.receiptId, result.receipt.receiptId);
    await expectLater(
        service.set(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision: before.revision,
            state: MapEditorState(),
            operationId: 'stale'),
        throwsFormatException);
    final changed = await service.set(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: result.afterRevision,
        state: state.copyWith(lockedFamilies: {'effect'}),
        operationId: 'family');
    await expectLater(
        service.undo(
            projectRoot: root.path,
            mapId: 'shore',
            mutation: result,
            operationId: 'stale_undo'),
        throwsFormatException);
    final undone = await service.undo(
        projectRoot: root.path,
        mapId: 'shore',
        mutation: changed,
        operationId: 'undo_family');
    expect(undone.afterState, state);
  });

  test('interrupted promotion requires recovery and resumes the same intent',
      () async {
    final service = LocalMapEditorAuthoring(policy: policy);
    final before =
        await service.inspect(projectRoot: root.path, mapId: 'shore');
    final state = MapEditorState(lockedElements: {'model:mist'});
    final crash = LocalMapEditorAuthoring(
        policy: policy,
        faultInjector: (context) {
          if (context.checkpoint ==
              AuthoringTransactionCheckpoint.afterResourcePromoted) {
            throw const AuthoringTransactionSimulatedCrash();
          }
        });
    await expectLater(
        crash.set(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision: before.revision,
            state: state,
            operationId: 'resume'),
        throwsA(anything));
    final afterCrash =
        await service.inspect(projectRoot: root.path, mapId: 'shore');
    await expectLater(
        service.set(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision: afterCrash.revision,
            state: MapEditorState(),
            operationId: 'pending'),
        throwsA(anything));
    final recovered = await service.set(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: before.revision,
        state: state,
        operationId: 'resume');
    expect(recovered.afterState, state);
    final undone = await service.undo(
        projectRoot: root.path,
        mapId: 'shore',
        mutation: recovered,
        operationId: 'undo');
    expect(undone.afterState, MapEditorState());
    expect(await File('${root.path}/maps/shore.editor.json').exists(), isFalse);
  });

  test('unknown future or corrupted documents preserve original bytes',
      () async {
    final service = LocalMapEditorAuthoring(policy: policy);
    final before =
        await service.inspect(projectRoot: root.path, mapId: 'shore');
    final file = File('${root.path}/maps/shore.editor.json');
    for (final raw in [
      'invalid',
      '{"schemaVersion":2,"mapId":"shore","state":{}}',
      jsonEncode(
          MapEditorDocument(mapId: 'other', state: MapEditorState()).toJson()),
      'x' * 65537
    ]) {
      await file.writeAsString(raw);
      await expectLater(
          service.set(
              projectRoot: root.path,
              mapId: 'shore',
              expectedRevision: before.revision,
              state: MapEditorState(lockedElements: {'model:mist'}),
              operationId: 'invalid_${raw.length}'),
          throwsA(anything));
      expect(await file.readAsString(), raw);
    }
  });

  test('cold worker preserves locks replay conflicts and receipt undo',
      () async {
    final service = LocalMapEditorAuthoring(policy: policy, runInWorker: true);
    final before =
        await service.inspect(projectRoot: root.path, mapId: 'shore');
    final originalMap =
        await File('${root.path}/maps/shore.json').readAsBytes();
    final state = MapEditorState(lockedElements: {'model:mist'});
    final result = await service.set(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: before.revision,
        state: state,
        operationId: 'worker_first');
    final reopened = await LocalMapEditorAuthoring(policy: policy)
        .inspect(projectRoot: root.path, mapId: 'shore');
    expect(reopened.state, state);
    expect(reopened.revision, result.afterRevision);
    final replay = await service.set(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: before.revision,
        state: state,
        operationId: 'worker_first');
    expect(replay.receipt.receiptId, result.receipt.receiptId);
    await expectLater(
        service.set(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision: before.revision,
            state: MapEditorState(),
            operationId: 'worker_stale'),
        throwsFormatException);
    final undo = await service.undo(
        projectRoot: root.path,
        mapId: 'shore',
        mutation: result,
        operationId: 'worker_undo');
    expect(undo.afterState, MapEditorState());
    expect(await File('${root.path}/maps/shore.editor.json').exists(), isFalse);
    expect(
        await File('${root.path}/maps/shore.json').readAsBytes(), originalMap);
  });

  test(
      'worker resumes an interrupted promotion and preserves unsupported bytes',
      () async {
    final direct = LocalMapEditorAuthoring(policy: policy);
    final before = await direct.inspect(projectRoot: root.path, mapId: 'shore');
    final state = MapEditorState(lockedElements: {'decor:mist'});
    final crash = LocalMapEditorAuthoring(
        policy: policy,
        faultInjector: (context) {
          if (context.checkpoint ==
              AuthoringTransactionCheckpoint.afterResourcePromoted) {
            throw const AuthoringTransactionSimulatedCrash();
          }
        });
    await expectLater(
        crash.set(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision: before.revision,
            state: state,
            operationId: 'worker_resume'),
        throwsA(anything));
    final worker = LocalMapEditorAuthoring(policy: policy, runInWorker: true);
    final result = await worker.set(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: before.revision,
        state: state,
        operationId: 'worker_resume');
    expect(result.afterState, state);
    final file = File('${root.path}/maps/shore.editor.json');
    const future = '{"schemaVersion":2,"mapId":"shore","state":{}}';
    await file.writeAsString(future);
    await expectLater(
        worker.set(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision: result.afterRevision,
            state: MapEditorState(),
            operationId: 'worker_future'),
        throwsFormatException);
    expect(await file.readAsString(), future);
  });
  for (final secondWorker in [false, true]) {
    test('worker shares host project queue with secondWorker=$secondWorker',
        () async {
      final worker = LocalMapEditorAuthoring(policy: policy, runInWorker: true);
      final other =
          LocalMapEditorAuthoring(policy: policy, runInWorker: secondWorker);
      final before =
          await worker.inspect(projectRoot: root.path, mapId: 'shore');
      final entered = Completer<void>();
      final release = Completer<void>();
      final held = withLocalProjectWriteQueue(root.path, () async {
        entered.complete();
        await release.future;
      });
      await entered.future;
      var completed = 0;
      Future<bool> attempt(LocalMapEditorAuthoring service, String id) async {
        try {
          await service.set(
              projectRoot: root.path,
              mapId: 'shore',
              expectedRevision: before.revision,
              state: MapEditorState(lockedElements: {'model:$id'}),
              operationId: id);
          return true;
        } on Object catch (error) {
          expect(error.toString(), contains('revision'));
          return false;
        } finally {
          completed++;
        }
      }

      final first = attempt(worker, 'worker_queued');
      final second = attempt(other, 'other_queued');
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(completed, 0);
      expect(
          await File('${root.path}/maps/shore.editor.json').exists(), isFalse);
      release.complete();
      await held;
      expect(
          (await Future.wait([first, second])).where((value) => value).length,
          1);
      final reopened =
          await worker.inspect(projectRoot: root.path, mapId: 'shore');
      expect(reopened.state.lockedElements, hasLength(1));
    });
  }
  test('worker diagnostics count real I/O and exclude unrelated content',
      () async {
    final port = ReceivePort();
    final report = port.first;
    final service = LocalMapEditorAuthoring(
        policy: policy, runInWorker: true, diagnosticsPort: port.sendPort);
    final direct = LocalMapEditorAuthoring(policy: policy);
    final before = await direct.inspect(projectRoot: root.path, mapId: 'shore');
    await service.set(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: before.revision,
        state: MapEditorState(lockedElements: {'model:mist'}),
        operationId: 'traced_worker');
    final trace = await report as Map;
    port.close();
    final rows = (trace['rows'] as List).cast<Map>();
    expect(rows.where((row) => row['operation'] == 'write'), isNotEmpty);
    expect(rows.where((row) => row['operation'] == 'flush'), isNotEmpty);
    final reads = rows.where((row) => [
          'read',
          'streamDelivered',
          'list',
          'listRecursive'
        ].contains(row['operation']));
    expect(
        reads.where((row) =>
            row['path'] == 'project.json' ||
            row['path'] == '.pokemap/authoring/history.jsonl' ||
            row['path'] == '.pokemap/authoring/idempotency.jsonl' ||
            (row['path'] as String).startsWith('assets/')),
        isEmpty);
    expect(reads.where((row) => row['path'] == 'maps/shore.json'), isEmpty);
  });
}

final class _UnreadableFile implements File {
  _UnreadableFile(this.delegate, this.attempts);
  final File delegate;
  final List<String> attempts;
  Never deny() {
    attempts.add(path);
    throw StateError('Unrelated file read: $path');
  }

  @override
  String get path => delegate.path;
  @override
  Uri get uri => delegate.uri;
  @override
  bool get isAbsolute => delegate.isAbsolute;
  @override
  File get absolute => delegate.absolute;
  @override
  Directory get parent => delegate.parent;
  @override
  Future<Uint8List> readAsBytes() async => deny();
  @override
  Future<String> readAsString({Encoding encoding = utf8}) async => deny();
  @override
  Stream<List<int>> openRead([int? start, int? end]) => deny();
  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) async =>
      deny();
  @override
  Future<bool> exists() => delegate.exists();
  @override
  Future<FileStat> stat() => delegate.stat();
  @override
  Future<String> resolveSymbolicLinks() => delegate.resolveSymbolicLinks();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_authoring/src/transactions/journaled_transaction.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late WorkspacePolicy policy;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('visual_authoring_');
    root = Directory(await root.resolveSymbolicLinks());
    await Directory('${root.path}/maps').create();
    await File('${root.path}/maps/shore.json').writeAsString('opaque map');
    await File('${root.path}/project.json').writeAsString('opaque project');
    policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path],
        fileReader: const LocalProjectFileReader());
  });
  tearDown(() => root.delete(recursive: true));

  test(
      'cold worker saves keep bounded IO with unrelated files and preserve undo',
      () async {
    final counts = <List<Map<String, int>>>[];
    for (final unrelated in [0, 9]) {
      final directory =
          await Directory('${root.path}/worker_$unrelated').create();
      await File('${directory.path}/project.json')
          .writeAsString('opaque project');
      for (var i = 0; i < unrelated; i++) {
        await File('${directory.path}/foreign_$i.json')
            .writeAsString('x' * 32768);
      }
      final workerPolicy = await WorkspacePolicy.create(
          allowedRootPaths: [directory.path],
          fileReader: const LocalProjectFileReader());
      final port = ReceivePort();
      final traces = StreamIterator<dynamic>(port);
      final measurements = <Map<String, int>>[];
      try {
        final observer = LocalVisualSettingsAuthoring(policy: workerPolicy);
        VisualSettingsMutation? last;
        for (final (i, enabled) in <bool?>[true, false, null].indexed) {
          final snapshot = await observer.inspect(projectRoot: directory.path);
          final settings = SpatialVisualPatch.fromJson(
              {if (enabled != null) ...{'weatherEnabled': enabled, 'weatherKind': 'rain', 'weatherSoundEnabled': enabled, 'weatherRainVolume': .8, 'weatherWindVolume': .4, 'timeMode': enabled ? 'real' : 'cycle', 'weatherMode': enabled ? 'real' : 'automatic', 'weatherSequence': ['clear', 'rain'], 'weatherIntervalSeconds': 600}});
          final worker = LocalVisualSettingsAuthoring(
              policy: workerPolicy,
              runInWorker: true,
              diagnosticsPort: port.sendPort);
          last = await worker.set(
              projectRoot: directory.path,
              expectedRevision: snapshot.revision,
              settings: settings,
              operationId: 'worker_$i');
          expect((await observer.inspect(projectRoot: directory.path)).settings,
              settings);
          expect(await traces.moveNext(), isTrue);
          final rows = (traces.current as Map)['rows'] as List;
          expect(rows.where((raw) {
            final path = (raw as Map)['path'] as String;
            return (path == 'project.json' && (raw['bytes'] as int) > 0) ||
                path.startsWith('foreign_') ||
                path.startsWith('assets/') ||
                path.startsWith('maps/');
          }), isEmpty);
          final operations = <String, int>{};
          var bytesWritten = 0;
          for (final row in rows.cast<Map>()) {
            final operation = row['operation'] as String;
            operations[operation] =
                (operations[operation] ?? 0) + (row['calls'] as int);
            if (operation == 'write') bytesWritten += row['bytes'] as int;
          }
          expect(bytesWritten, lessThan(100000));
          measurements.add(operations);
        }
        await LocalVisualSettingsAuthoring(
                policy: workerPolicy, runInWorker: true)
            .undo(
                projectRoot: directory.path,
                mutation: last!,
                operationId: 'worker_undo');
        expect(
            (await observer.inspect(projectRoot: directory.path))
                .settings
                .values[SpatialVisualParameter.weatherEnabled],
            false);
      } finally {
        await traces.cancel();
        port.close();
      }
      counts.add(measurements);
    }
    expect(counts[1], counts[0]);
  });

  test('cold project and map saves ignore large unrelated content and history',
      () async {
    final blocked = <String>{};
    for (final relative in [
      'project.json',
      'maps/shore.json',
      'maps/unrelated.json',
      '.pokemap/authoring/history.jsonl',
      '.pokemap/authoring/audit.jsonl',
      '.pokemap/authoring/idempotency.jsonl'
    ]) {
      final file = File('${root.path}/$relative');
      await file.parent.create(recursive: true);
      if (!await file.exists()) await file.writeAsString('x' * 2000000);
      blocked.add(file.path);
    }
    final outside = Zone.current;
    final attempts = <String>[];
    await IOOverrides.runZoned(() async {
      for (final mapId in <String?>[null, 'shore']) {
        for (var i = 0; i < 3; i++) {
          final service = LocalVisualSettingsAuthoring(policy: policy);
          final before = mapId == null
              ? await service.inspect(projectRoot: root.path)
              : await service.inspect(projectRoot: root.path, mapId: mapId);
          final profile = SpatialVisualPatch.fromJson({
            'pitchDegrees': 34 + i,
            'depthOfFieldEnabled': i == 0,
            'haloStrength': i * .5
          });
          final changed = mapId == null
              ? await service.set(
                  projectRoot: root.path,
                  expectedRevision: before.revision,
                  settings: profile,
                  operationId: 'project_$i')
              : await service.set(
                  projectRoot: root.path,
                  mapId: mapId,
                  expectedRevision: before.revision,
                  settings: profile,
                  operationId: 'map_$i');
          expect(changed.afterSettings, profile);
          final reopened = mapId == null
              ? await LocalVisualSettingsAuthoring(policy: policy)
                  .inspect(projectRoot: root.path)
              : await LocalVisualSettingsAuthoring(policy: policy)
                  .inspect(projectRoot: root.path, mapId: mapId);
          expect(reopened.settings, profile);
        }
      }
    }, createFile: (path) {
      final file = outside.run(() => File(path));
      return blocked.contains(path) ? _UnreadableFile(file, attempts) : file;
    });
    expect(attempts, isEmpty);
    expect(await File('${root.path}/project.visual.json').length(),
        lessThan(1024));
    expect(await File('${root.path}/maps/shore.visual.json').length(),
        lessThan(1024));
  });

  test(
      'revision conflicts preserve the current settings and targeted undo removes an absent document',
      () async {
    final store = LocalVisualSettingsAuthoring(policy: policy);
    final empty = await store.inspect(projectRoot: root.path);
    final mutation = await store.set(
        projectRoot: root.path,
        expectedRevision: empty.revision,
        settings: SpatialVisualPatch.fromJson({'pitchDegrees': 34}),
        operationId: 'first');
    await expectLater(
        store.set(
            projectRoot: root.path,
            expectedRevision: empty.revision,
            settings: SpatialVisualPatch(),
            operationId: 'stale'),
        throwsA(anything));
    expect((await store.inspect(projectRoot: root.path)).settings,
        mutation.afterSettings);
    await store.undo(
        projectRoot: root.path, mutation: mutation, operationId: 'undo');
    expect(await File('${root.path}/project.visual.json').exists(), isFalse);
  });

  test(
      'unknown outcomes recover only their scoped intent and replay idempotently',
      () async {
    final store = LocalVisualSettingsAuthoring(policy: policy);
    final empty = await store.inspect(projectRoot: root.path);
    final profile = SpatialVisualPatch.fromJson({'fieldOfViewDegrees': 16.4});
    final interrupted = LocalVisualSettingsAuthoring(
        policy: policy,
        faultInjector: (context) {
          if (context.checkpoint ==
              AuthoringTransactionCheckpoint.afterResourcePromoted) {
            throw const AuthoringTransactionSimulatedCrash();
          }
        });
    await expectLater(
        interrupted.set(
            projectRoot: root.path,
            expectedRevision: empty.revision,
            settings: profile,
            operationId: 'recover'),
        throwsA(anything));
    final recovered = await store.set(
        projectRoot: root.path,
        expectedRevision: empty.revision,
        settings: profile,
        operationId: 'recover');
    final replay = await store.set(
        projectRoot: root.path,
        expectedRevision: empty.revision,
        settings: profile,
        operationId: 'recover');
    expect(replay.receipt.receiptId, recovered.receipt.receiptId);
    expect((await store.inspect(projectRoot: root.path)).settings, profile);
  });

  test('future or corrupt visual documents remain byte-identical on refusal',
      () async {
    final store = LocalVisualSettingsAuthoring(policy: policy);
    final before = await store.inspect(projectRoot: root.path);
    final file = File('${root.path}/project.visual.json');
    for (final raw in ['invalid', '{"schemaVersion":99,"profile":{}}']) {
      await file.writeAsString(raw);
      await expectLater(
          store.set(
              projectRoot: root.path,
              expectedRevision: before.revision,
              settings: SpatialVisualPatch(),
              operationId: 'bad_${raw.length}'),
          throwsA(anything));
      expect(await file.readAsString(), raw);
    }
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

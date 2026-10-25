import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
              AuthoringTransactionCheckpoint.afterResourcePromoted)
            throw const AuthoringTransactionSimulatedCrash();
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

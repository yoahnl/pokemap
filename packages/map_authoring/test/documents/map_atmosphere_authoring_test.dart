import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:map_authoring/src/transactions/journaled_transaction.dart';
import 'package:map_authoring/src/transactions/local_transaction_file_gateway.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('semantic atmosphere catalog declares bounded depth of field', () {
    final extensions = LocalMapAtmosphereAuthoring.descriptor.extensions;
    expect(extensions['effects'], contains('depthOfFieldEnabled'));
    expect(extensions['settingsFields'], containsAll(['depthOfFieldStrength', 'depthOfFieldFocusRange']));
    expect(extensions['depthOfFieldFocusRange'], {'minimum': 2, 'maximum': 40, 'unit': 'worldCells', 'meaning': 'fullSharpZoneDepthExtent'});
  });

  late Directory root;
  late WorkspacePolicy policy;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('atmosphere_local_');
    root = Directory(await root.resolveSymbolicLinks());
    await Directory('${root.path}/maps').create();
    await File('${root.path}/maps/shore.json')
        .writeAsString('map content must not be decoded');
    await File('${root.path}/project.json')
        .writeAsString('project content must not be decoded');
    policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path],
        fileReader: const LocalProjectFileReader());
  });
  tearDown(() => root.delete(recursive: true));
  test(
      'scoped atmosphere and map lifecycle use the same interprocess writer lock',
      () async {
    final outside = Zone.current;
    final paths = <String>[];
    await IOOverrides.runZoned(() async {
      for (final namespace in <String?>[null, 'atmosphere_shore']) {
        final gateway = await LocalTransactionFileGateway.open(
            projectRoot: root.path,
            expectedProjectRoot: root.path,
            transactionNamespace: namespace);
        await gateway.withExclusiveWriteLock(() async {});
      }
    }, createFile: (path) {
      final file = outside.run(() => File(path));
      return path.endsWith('/write.lock')
          ? _RecordingLockFile(file, paths)
          : file;
    });
    expect(paths, hasLength(2));
    expect(paths.toSet(),
        {'${root.path}/.pokemap/authoring/transactions/write.lock'});
  });
  test(
      'a second process cannot enter a scoped writer while lifecycle holds the project lock',
      () async {
    final script = File('${root.path}/lock-probe.dart');
    await script.writeAsString('''import 'dart:io';
import 'package:map_authoring/src/transactions/local_transaction_file_gateway.dart';
Future<void> main(List<String> args) async {
  final gateway=await LocalTransactionFileGateway.open(projectRoot:args.single,expectedProjectRoot:args.single,transactionNamespace:'atmosphere_probe');
  try {await gateway.withExclusiveWriteLock(() async {stdout.write('entered');});}
  catch(error) {stdout.write('blocked');}
}
''');
    final gateway = await LocalTransactionFileGateway.open(
        projectRoot: root.path, expectedProjectRoot: root.path);
    await gateway.withExclusiveWriteLock(() async {
      final result = await Process.run(Platform.resolvedExecutable, [
        '--packages=${File('.dart_tool/package_config.json').absolute.path}',
        script.path,
        root.path
      ]);
      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(result.stdout, 'blocked');
    });
    final result = await Process.run(Platform.resolvedExecutable, [
      '--packages=${File('.dart_tool/package_config.json').absolute.path}',
      script.path,
      root.path
    ]);
    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(result.stdout, 'entered');
  },
      skip: Platform.environment['POKEMAP_ATMOSPHERE_LOCK_PROCESS'] != '1'
          ? 'Local interprocess verification; ordinary regression asserts the shared lock path.'
          : false);
  test('each cold first save persists only the small selected atmosphere',
      () async {
    var operation = 0;
    for (final settings in [
      SpatialAtmosphereSettings.fromJson({'depthOfFieldEnabled': true, 'depthOfFieldStrength': .65, 'depthOfFieldFocusRange': 18}),
      SpatialAtmosphereSettings(waterAnimated: true),
      SpatialAtmosphereSettings(windowsLit: true),
      SpatialAtmosphereSettings(fireflies: true),
      SpatialAtmosphereSettings(halosEnabled: true, haloStrength: 1.4),
      SpatialAtmosphereSettings(depthFogEnabled: true, fogOpacity: .32, fogStart: 39, fogEnd: 49)
    ]) {
      final service = LocalMapAtmosphereAuthoring(policy: policy);
      final before =
          await service.inspect(projectRoot: root.path, mapId: 'shore');
      final changed = await service.set(
          projectRoot: root.path,
          mapId: 'shore',
          expectedRevision: before.revision,
          settings: settings,
          operationId: 'save_${operation++}');
      expect(changed.afterSettings, settings);
      final reopened = await LocalMapAtmosphereAuthoring(policy: policy)
          .inspect(projectRoot: root.path, mapId: 'shore');
      expect(reopened.settings, settings);
      expect(reopened.revision, changed.afterRevision);
      expect((await File('${root.path}/maps/shore.atmosphere.json').length()),
          lessThan(1024));
    }
    expect(await File('${root.path}/project.json').readAsString(),
        'project content must not be decoded');
    expect(await File('${root.path}/maps/shore.json').readAsString(),
        'map content must not be decoded');
  });
  test('cold saves ignore unrelated content and accumulated global history',
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
      for (var i = 0; i < 6; i++) {
        final service = LocalMapAtmosphereAuthoring(policy: policy);
        final before =
            await service.inspect(projectRoot: root.path, mapId: 'shore');
        await service.set(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision: before.revision,
            settings: SpatialAtmosphereSettings.fromJson({
                ...SpatialAtmosphereSettings(
                waterAnimated: i == 0, windowsLit: i == 1, fireflies: i == 2,
                halosEnabled: i == 3, depthFogEnabled: i == 4,
                haloStrength: 1.4, fogOpacity: .32).toJson(),
                'depthOfFieldEnabled': i == 5,
                'depthOfFieldStrength': .65,
                'depthOfFieldFocusRange': 18}),
            operationId: 'bounded_$i');
      }
    }, createFile: (path) {
      final file = outside.run(() => File(path));
      return blocked.contains(file.path)
          ? _UnreadableFile(file, attempts)
          : file;
    });
    expect(attempts, isEmpty);
  });
  test(
      'receipt undo reads one history entry without legacy or unrelated entry reads',
      () async {
    final service = LocalMapAtmosphereAuthoring(policy: policy);
    final before =
        await service.inspect(projectRoot: root.path, mapId: 'shore');
    final mutation = await service.set(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: before.revision,
        settings: SpatialAtmosphereSettings(fireflies: true),
        operationId: 'seed_undo');
    final metadata = Directory('${root.path}/.pokemap/authoring');
    for (final name in [
      'history.jsonl',
      'history-entries/receipt_document_${'a' * 32}.json'
    ]) {
      final file = File('${metadata.path}/$name');
      await file.parent.create(recursive: true);
      await file.writeAsString('unrelated invalid history');
    }
    final outside = Zone.current;
    final attempts = <String>[];
    await IOOverrides.runZoned(() async {
      final undone = await LocalMapAtmosphereAuthoring(policy: policy)
          .undoReceipt(
              projectRoot: root.path,
              mapId: 'shore',
              receiptId: mutation.receipt.receiptId,
              expectedRevision: mutation.afterRevision,
              operationId: 'targeted_undo');
      expect(undone.afterSettings, SpatialAtmosphereSettings());
      expect(await File('${root.path}/maps/shore.atmosphere.json').exists(),
          isFalse);
      expect((undone.receipt.extensions['history'] as Map)['kind'], 'undo');
    }, createFile: (path) {
      final file = outside.run(() => File(path));
      return path.endsWith('/history.jsonl') ||
              path.endsWith('receipt_document_${'a' * 32}.json')
          ? _UnreadableFile(file, attempts)
          : file;
    });
    expect(attempts, isEmpty);
  });
  test('replay is exact and an operation identity cannot change its payload',
      () async {
    final service = LocalMapAtmosphereAuthoring(policy: policy);
    final initial =
        await service.inspect(projectRoot: root.path, mapId: 'shore');
    final first = await service.set(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: initial.revision,
        settings: SpatialAtmosphereSettings(fireflies: true),
        operationId: 'replay');
    final bytes =
        await File('${root.path}/maps/shore.atmosphere.json').readAsBytes();
    final replay = await LocalMapAtmosphereAuthoring(policy: policy).set(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: initial.revision,
        settings: SpatialAtmosphereSettings(fireflies: true),
        operationId: 'replay');
    expect(replay.receipt.receiptId, first.receipt.receiptId);
    expect(await File('${root.path}/maps/shore.atmosphere.json').readAsBytes(),
        bytes);
    await expectLater(
        service.set(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision: initial.revision,
            settings: SpatialAtmosphereSettings(),
            operationId: 'replay'),
        throwsA(anything));
  });
  test(
      'stale writes and a race under the writer lock preserve the competing file',
      () async {
    final service = LocalMapAtmosphereAuthoring(policy: policy);
    final before =
        await service.inspect(projectRoot: root.path, mapId: 'shore');
    final external = utf8.encode(jsonEncode(SpatialAtmosphereDocument(
            mapId: 'shore',
            settings: SpatialAtmosphereSettings(windowsLit: true))
        .toJson()));
    await expectLater(
        service.set(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision: before.revision,
            settings: SpatialAtmosphereSettings(fireflies: true),
            operationId: 'race',
            precondition: () => File('${root.path}/maps/shore.atmosphere.json')
                .writeAsBytes(external, flush: true)),
        throwsA(anything));
    expect(await File('${root.path}/maps/shore.atmosphere.json').readAsBytes(),
        external);
    await expectLater(
        service.set(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision: before.revision,
            settings: SpatialAtmosphereSettings(fireflies: true),
            operationId: 'stale'),
        throwsA(anything));
  });
  test('recovery resumes only the reserved map operation and undo is targeted',
      () async {
    final service = LocalMapAtmosphereAuthoring(policy: policy);
    final before =
        await service.inspect(projectRoot: root.path, mapId: 'shore');
    final crash = LocalMapAtmosphereAuthoring(
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
            settings: SpatialAtmosphereSettings(fireflies: true),
            operationId: 'resume'),
        throwsA(anything));
    await expectLater(
        service.set(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision:
                (await service.inspect(projectRoot: root.path, mapId: 'shore'))
                    .revision,
            settings: SpatialAtmosphereSettings(windowsLit: true),
            operationId: 'blocked_pending'),
        throwsA(anything));
    final recovered = await service.set(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: before.revision,
        settings: SpatialAtmosphereSettings(fireflies: true),
        operationId: 'resume');
    expect(recovered.afterSettings.fireflies, isTrue);
    final undo = await service.undo(
        projectRoot: root.path,
        mapId: 'shore',
        mutation: recovered,
        operationId: 'undo');
    expect(undo.afterSettings, SpatialAtmosphereSettings());
  });
  test(
      'corrupted future mismatched and symlink documents cannot be overwritten',
      () async {
    final file = File('${root.path}/maps/shore.atmosphere.json');
    final service = LocalMapAtmosphereAuthoring(policy: policy);
    final revision =
        (await service.inspect(projectRoot: root.path, mapId: 'shore'))
            .revision;
    for (final raw in [
      'invalid',
      '{"schemaVersion":3,"mapId":"shore","settings":{}}',
      jsonEncode(SpatialAtmosphereDocument(
              mapId: 'another', settings: SpatialAtmosphereSettings())
          .toJson()),
      'x' * 65537
    ]) {
      await file.writeAsString(raw);
      await expectLater(
          service.set(
              projectRoot: root.path,
              mapId: 'shore',
              expectedRevision: revision,
              settings: SpatialAtmosphereSettings(fireflies: true),
              operationId: 'invalid_${raw.length}'),
          throwsA(anything));
      expect(await file.readAsString(), raw);
    }
    await file.delete();
    final outside =
        await Directory.systemTemp.createTemp('atmosphere_outside_');
    try {
      final target = File('${outside.path}/target.json');
      await target.writeAsString('preserve');
      await Link(file.path).create(target.path);
      await expectLater(service.inspect(projectRoot: root.path, mapId: 'shore'),
          throwsA(anything));
      expect(await target.readAsString(), 'preserve');
    } finally {
      await outside.delete(recursive: true);
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

final class _RecordingLockFile implements File {
  _RecordingLockFile(this.file, this.paths);
  final File file;
  final List<String> paths;
  @override
  String get path => file.path;
  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) {
    paths.add(path);
    return file.open(mode: mode);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

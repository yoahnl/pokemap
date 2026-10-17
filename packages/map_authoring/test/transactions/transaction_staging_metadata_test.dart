import 'dart:async';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late LocalTransactionFileGateway gateway;
  const bytes = [1, 2, 3, 4];
  final epoch = DateTime.utc(2026);

  setUp(() async {
    root =
        await Directory.systemTemp.createTemp('transaction-staging-metadata-');
    root = Directory(await root.resolveSymbolicLinks());
    await File('${root.path}/project.json').writeAsBytes(bytes);
    gateway = await LocalTransactionFileGateway.open(projectRoot: root.path);
  });
  tearDown(() async => root.delete(recursive: true));

  Future<void> stage(Future<FileStat> Function(String, FileStat) observe) =>
      IOOverrides.runZoned(
        () => gateway.stagePayload(
          operationId: 'metadata-test',
          storageKey: 'project.json',
          kind: TransactionPayloadKind.before,
          bytes: bytes,
        ),
        stat: (path) async {
          final actual = await Zone.root.run(() => FileStat.stat(path));
          return path.endsWith('.before.payload.tmp')
              ? observe(path, actual)
              : actual;
        },
      );

  Matcher error(String code) => throwsA(isA<TransactionFileGatewayException>()
      .having((e) => e.code, 'code', code));

  test('stable staging preserves its exact frozen bytes', () async {
    await stage((_, actual) async => actual);
    final payload = await gateway.readStagedPayload(
        operationId: 'metadata-test',
        storageKey: 'project.json',
        kind: TransactionPayloadKind.before);
    expect(await payload.payload!.readBytes(), bytes);
    await payload.payload!.release();
  });

  test('rechecks a transient metadata change against the frozen payload',
      () async {
    var calls = 0;
    await stage((_, actual) async => _Stat(actual,
        changed: epoch.add(Duration(seconds: ++calls == 1 ? 0 : 1))));
    expect(calls, 4);
    final payload = await gateway.readStagedPayload(
        operationId: 'metadata-test',
        storageKey: 'project.json',
        kind: TransactionPayloadKind.before);
    expect(await payload.payload!.readBytes(), bytes);
    await payload.payload!.release();
  });

  test('rejects metadata that never stabilizes after three inspections',
      () async {
    var calls = 0;
    await expectLater(
        stage((_, actual) async =>
            _Stat(actual, changed: epoch.add(Duration(seconds: ++calls)))),
        error('transaction.resource_changed_during_read'));
    expect(calls, 6);
  });

  test(
      'rejects changed content even when its size and modified time are restored',
      () async {
    var calls = 0;
    await expectLater(stage((path, actual) async {
      calls++;
      if (calls == 2) {
        await File(path).writeAsBytes([9, 2, 3, 4], flush: true);
      }
      return _Stat(actual,
          changed: epoch.add(Duration(seconds: calls == 1 ? 0 : 1)),
          modified: epoch);
    }), error('transaction.stage_corrupt'));
    expect(await File('${root.path}/project.json').readAsBytes(), bytes);
  });

  test('does not retry a changed data modification time', () async {
    var calls = 0;
    await expectLater(
        stage((_, actual) async => _Stat(actual,
            changed: epoch,
            modified: epoch.add(Duration(seconds: ++calls == 1 ? 0 : 1)))),
        error('transaction.resource_changed_during_read'));
    expect(calls, 2);
  });

  test('does not retry a changed file size', () async {
    var calls = 0;
    await expectLater(
        stage((_, actual) async => _Stat(actual,
            changed: epoch,
            size: ++calls == 1 ? bytes.length : bytes.length + 1)),
        error('transaction.resource_changed_during_read'));
    expect(calls, 2);
  });

  for (final changedField in ['mode', 'type']) {
    test('does not retry a changed staged file $changedField', () async {
      var calls = 0;
      await expectLater(stage((_, actual) async {
        final second = ++calls != 1;
        return _Stat(actual,
            changed: epoch.add(Duration(seconds: second ? 1 : 0)),
            mode: changedField == 'mode' && second
                ? actual.mode ^ 2
                : actual.mode,
            type: changedField == 'type' && second
                ? FileSystemEntityType.directory
                : actual.type);
      }), error('transaction.resource_changed_during_read'));
      expect(calls, 2);
    });
  }

  test(
      'rechecks metadata on a staged payload before reading its descriptor content',
      () async {
    await gateway.stagePayload(
        operationId: 'metadata-test',
        storageKey: 'project.json',
        kind: TransactionPayloadKind.before,
        bytes: bytes);
    var calls = 0;
    final payload = await IOOverrides.runZoned(
        () => gateway.readStagedPayload(
            operationId: 'metadata-test',
            storageKey: 'project.json',
            kind: TransactionPayloadKind.before), stat: (path) async {
      final actual = await Zone.root.run(() => FileStat.stat(path));
      return path.endsWith('.before.bin')
          ? _Stat(actual,
              changed: epoch.add(Duration(seconds: ++calls == 1 ? 0 : 1)))
          : actual;
    });
    expect(calls, 4);
    expect(await payload.payload!.readBytes(), bytes);
    await payload.payload!.release();
  });

  test(
      'rechecks metadata of its owned promotion temporary before atomic replacement',
      () async {
    const after = [4, 3, 2, 1];
    await gateway.stagePayload(
        operationId: 'metadata-test',
        storageKey: 'project.json',
        kind: TransactionPayloadKind.after,
        bytes: after);
    final revision = await gateway.readResourceRevision('project.json');
    var calls = 0;
    await IOOverrides.runZoned(
        () => gateway.promoteStaged(
            operationId: 'metadata-test',
            storageKey: 'project.json',
            kind: TransactionPayloadKind.after,
            expectedCurrentRevision: revision), stat: (path) async {
      final actual = await Zone.root.run(() => FileStat.stat(path));
      return path.contains('/project.json.pokemap-metadata-test-') &&
              !path.endsWith('.tmp')
          ? _Stat(actual,
              changed: epoch.add(Duration(seconds: ++calls == 1 ? 0 : 1)))
          : actual;
    });
    expect(calls, 4);
    expect(await File('${root.path}/project.json').readAsBytes(), after);
  });

  for (final tamper in [false, true]) {
    test(
        'verifies the exact promoted content after metadata changes, tamper=$tamper',
        () async {
      const after = [4, 3, 2, 1];
      await gateway.stagePayload(
          operationId: 'metadata-test',
          storageKey: 'project.json',
          kind: TransactionPayloadKind.after,
          bytes: after);
      final revision = await gateway.readResourceRevision('project.json');
      var calls = 0;
      final operation = IOOverrides.runZoned(
          () => gateway.promoteStaged(
              operationId: 'metadata-test',
              storageKey: 'project.json',
              kind: TransactionPayloadKind.after,
              expectedCurrentRevision: revision), stat: (path) async {
        final actual = await Zone.root.run(() => FileStat.stat(path));
        if (path != '${root.path}/project.json') return actual;
        calls++;
        if (tamper && calls == 4) {
          await File(path).writeAsBytes([9, 3, 2, 1], flush: true);
        }
        return _Stat(actual,
            changed: epoch.add(Duration(seconds: calls < 4 ? 0 : 1)),
            modified: epoch);
      });
      if (tamper) {
        await expectLater(operation, error('transaction.promotion_unverified'));
      } else {
        await operation;
        expect(await File('${root.path}/project.json').readAsBytes(), after);
      }
      expect(calls, 6);
    });
  }

  test('keeps strict concurrent-change rejection on live project resources',
      () async {
    var calls = 0;
    await expectLater(
        IOOverrides.runZoned(
          () => gateway.readResourceRevision('project.json'),
          stat: (path) async {
            final actual = await Zone.root.run(() => FileStat.stat(path));
            return path == '${root.path}/project.json'
                ? _Stat(actual, changed: epoch.add(Duration(seconds: ++calls)))
                : actual;
          },
        ),
        error('transaction.resource_changed_during_read'));
    expect(calls, 2);
  });
}

final class _Stat implements FileStat {
  _Stat(this.source,
      {required this.changed,
      DateTime? modified,
      int? size,
      int? mode,
      FileSystemEntityType? type})
      : modified = modified ?? source.modified,
        size = size ?? source.size,
        mode = mode ?? source.mode,
        type = type ?? source.type;
  final FileStat source;
  @override
  final DateTime changed;
  @override
  final DateTime modified;
  @override
  final int size;
  @override
  DateTime get accessed => source.accessed;
  @override
  final FileSystemEntityType type;
  @override
  final int mode;
  @override
  String modeString() => source.modeString();
}

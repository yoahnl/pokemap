import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../dev/save_disk_trace.dart';

void main() {
  late Directory fixture;
  late IOOverrides? previousOverrides;

  setUp(() async {
    fixture = Directory(
      '/Users/karim/Library/Caches/AveluneQA/studio-project-lifecycle/trace-test-$pid',
    );
    if (await fixture.exists()) {
      throw StateError('Trace fixture already exists.');
    }
    await fixture.create(recursive: true);
    previousOverrides = IOOverrides.current;
  });

  tearDown(() async {
    IOOverrides.global = previousOverrides;
    await fixture.delete(recursive: true);
  });

  test(
    'adds completed async timings without changing counts or bytes',
    () async {
      final trace = SaveDiskTrace(fixture.path)..arm();
      await trace.run(() async {
        final file = File('${fixture.path}/value');
        final writer = await file.open(mode: FileMode.write);
        await writer.writeFrom([1, 2, 3]);
        await writer.flush();
        await writer.close();
        expect(await file.exists(), isTrue);
        expect((await file.stat()).size, 3);
        expect(await file.readAsBytes(), [1, 2, 3]);
        final reader = await file.open();
        expect(await reader.read(3), [1, 2, 3]);
        await reader.close();
        expect(await file.openRead().expand((chunk) => chunk).toList(), [
          1,
          2,
          3,
        ]);
        await file.rename('${fixture.path}/renamed');
        expect(await Directory(fixture.path).list().length, 1);
      });
      final rows = (trace.snapshot()['rows']! as List)
          .cast<Map<String, Object>>();
      Map<String, Object> row(String operation) => rows.singleWhere(
        (row) => row['path'] == 'value' && row['operation'] == operation,
      );
      expect(row('write')['calls'], 1);
      expect(row('write')['bytes'], 3);
      expect(row('read')['calls'], 4);
      expect(row('read')['bytes'], 9);
      expect(row('streamDelivered')['calls'], 1);
      expect(row('streamDelivered')['bytes'], 3);
      for (final operation in [
        'write',
        'read',
        'flush',
        'exists',
        'stat',
        'rename',
        'openRead',
        'open:${FileMode.write}',
        'open:${FileMode.read}',
      ]) {
        final value = row(operation);
        expect(value['timedCalls'], value['calls'], reason: operation);
        expect(value['elapsedUs'], isNonNegative, reason: operation);
        expect(
          value['maxElapsedUs'],
          lessThanOrEqualTo(value['elapsedUs'] as int),
        );
      }
      final listing = rows.singleWhere((row) => row['operation'] == 'list');
      expect(listing['calls'], 1);
      expect(listing['timedCalls'], 1);
    },
  );

  test('times failed reads without counting completed bytes', () async {
    final trace = SaveDiskTrace(fixture.path)..arm();
    await trace.run(() async {
      await expectLater(
        File('${fixture.path}/missing').readAsBytes(),
        throwsA(isA<FileSystemException>()),
      );
    });
    final row = (trace.snapshot()['rows']! as List)
        .cast<Map<String, Object>>()
        .single;
    expect(row['calls'], 0);
    expect(row['bytes'], 0);
    expect(row['timedCalls'], 1);
    expect(row['elapsedUs'], isNonNegative);
  });
}

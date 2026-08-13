import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('writes bounded reversible map history scaling evidence', () async {
    await Directory('build/test').create(recursive: true);
    final directory = await Directory(
      'build/test',
    ).createTemp('map_history_delta_cli_');
    addTearDown(() => directory.delete(recursive: true));
    final output = File('${directory.path}/result.json');

    final result = await Process.run('dart', <String>[
      'run',
      'benchmark/map_history_delta_scaling.dart',
      '--warmups',
      '0',
      '--samples',
      '2',
      '--entries',
      '500',
      '--operations',
      '100',
      '--tile-extent',
      '128',
      '--output',
      output.path,
    ], workingDirectory: Directory.current.path);

    expect(result.exitCode, 0, reason: '${result.stderr}');
    final receipt =
        jsonDecode(await output.readAsString()) as Map<String, Object?>;
    expect(receipt['benchmark'], 'map_history_delta_scaling');
    expect(receipt['entries'], 500);
    expect(receipt['operations'], 100);
    expect(receipt['tileExtent'], 128);
    expect(receipt['changedValues'], 1);
    expect(receipt['tileChangedValues'], 2);
    expect(
      receipt['deltaRetainedBytes']! as int,
      lessThan(receipt['legacySnapshotRetainedBytes']! as int),
    );
    expect(
      receipt['tileDeltaRetainedBytes']! as int,
      lessThan(receipt['tileLegacySnapshotRetainedBytes']! as int),
    );
    expect(receipt['largeHistoryOperationP95BudgetUs'], 50000);
    expect(
      receipt['historyRetainedBytes']! as int,
      lessThanOrEqualTo(receipt['historyBudgetBytes']! as int),
    );
    final rows = (receipt['results']! as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(rows.map((row) => row['operation']), <Object?>[
      'construct',
      'undo',
      'redo',
      'tile_construct',
      'tile_undo',
      'tile_redo',
    ]);
    for (final row in rows) {
      expect(row['samplesUs'], hasLength(2));
      expect(row['p50Us'], isA<int>());
      expect(row['p95Us'], isA<int>());
      expect(row['p99Us'], isA<int>());
      expect(row['maxUs'], isA<int>());
      expect(row['p95Us'], lessThan(50000));
    }
    final longSession = Map<String, Object?>.from(
      receipt['longSession']! as Map,
    );
    expect(longSession['historyEntries'], greaterThan(0));
    expect(
      longSession['historyRetainedBytes']! as int,
      lessThanOrEqualTo(longSession['historyBudgetBytes']! as int),
    );
  });
}

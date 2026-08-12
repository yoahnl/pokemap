import 'package:flutter_test/flutter_test.dart';

import '../test_driver/support/fine_mask_performance_contract.dart';

void main() {
  test('accepts a complete fine-mask performance receipt', () {
    expect(
      () => validateFineMaskPerformanceReceipt(
        _receipt(),
        requireProvenance: true,
      ),
      returnsNormally,
    );
  });

  test('rejects persistence work during pointer moves', () {
    final receipt = _receipt();
    final rows = receipt['results']! as List<Map<String, Object?>>;
    final move = rows.first['moveInstrumentation']! as Map<String, Object?>;
    final counters = move['counters']! as Map<String, Object?>;
    counters['base64.encode'] = 1;

    expect(
      () =>
          validateFineMaskPerformanceReceipt(receipt, requireProvenance: true),
      throwsFormatException,
    );
  });

  test('rejects an incomplete extent matrix', () {
    final receipt = _receipt();
    final rows = receipt['results']! as List<Map<String, Object?>>;
    rows.removeLast();

    expect(
      () =>
          validateFineMaskPerformanceReceipt(receipt, requireProvenance: true),
      throwsFormatException,
    );
  });

  test('rejects missing repeated-open post-GC evidence', () {
    final receipt = _receipt()..remove('soakMemory');

    expect(
      () =>
          validateFineMaskPerformanceReceipt(receipt, requireProvenance: true),
      throwsFormatException,
    );
  });
}

Map<String, dynamic> _receipt() => <String, dynamic>{
  'schemaVersion': 2,
  'target': 'integration_test/editor_fine_mask_journey_test.dart',
  'executionMode': 'flutter-profile',
  'commit': '0123456789abcdef0123456789abcdef01234567',
  'treeState': 'clean',
  'sdk': 'Dart 3',
  'toolchain': <String, Object?>{
    'dart': 'Dart 3',
    'flutter': <String, Object?>{'frameworkRevision': 'flutter-sha'},
    'flame': '1.0.0',
  },
  'pointerMovesPerExtent': 30,
  'soakCycles': 3,
  'soakMemory': _memory(heapAfterGcBytes: 2560),
  'soakHeapGrowthBudgetBytes': 32 * 1024 * 1024,
  'soakHeapStable': true,
  'memory': _memory(heapAfterGcBytes: 2048),
  'results': <Map<String, Object?>>[
    for (final extent in const <int>[64, 256, 512, 1024]) _row(extent),
  ],
};

Map<String, Object?> _memory({required int heapAfterGcBytes}) =>
    <String, Object?>{
      'allocatedBytes': 1024,
      'allocationCount': 10,
      'heapBeforeGcBytes': 4096,
      'heapAfterGcBytes': heapAfterGcBytes,
      'heapCapacityAfterGcBytes': 8192,
      'externalAfterGcBytes': 0,
      'forcedGarbageCollection': true,
      'garbageCollectionTimestampMicros': 42,
    };

Map<String, Object?> _row(int extent) {
  final move = _instrumentation();
  final commit = _instrumentation();
  final total = _instrumentation();
  (move['spans']! as Map<String, Object?>)['mask.pointer_move'] = _metrics(30);
  (commit['spans']! as Map<String, Object?>)['mask.commit'] = _metrics(1);
  final commitCounters = commit['counters']! as Map<String, Object?>;
  commitCounters['base64.encode'] = 3;
  commitCounters['base64.decode'] = 1;
  final totalSpans = total['spans']! as Map<String, Object?>;
  totalSpans['mask.readback'] = _metrics(1);
  totalSpans['mask.build'] = _metrics(2);
  totalSpans['mask.paint'] = _metrics(2);
  return <String, Object?>{
    'extent': extent,
    'pointerMoveCount': 30,
    'moveInstrumentation': move,
    'commitInstrumentation': commit,
    'extentInstrumentation': total,
    'frameMetrics': <String, Object?>{
      'samplesUs': List<int>.filled(30, 1000),
      'p50Us': 1000,
      'p95Us': 1000,
      'p99Us': 1000,
      'maxUs': 1000,
    },
  };
}

Map<String, Object?> _instrumentation() => <String, Object?>{
  'spans': <String, Object?>{},
  'counters': <String, Object?>{
    for (final name in const <String>[
      'filesystem.read',
      'filesystem.write',
      'filesystem.metadata',
      'json.encode',
      'json.decode',
      'base64.encode',
      'base64.decode',
    ])
      name: 0,
  },
};

Map<String, Object?> _metrics(int count) => <String, Object?>{
  'count': count,
  'samplesUs': List<int>.filled(count, 100),
  'p50Us': 100,
  'p95Us': 100,
  'p99Us': 100,
  'maxUs': 100,
};

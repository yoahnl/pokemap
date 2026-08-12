import 'package:flutter_test/flutter_test.dart';

import '../test_driver/performance_driver.dart' as performance_driver;

void main() {
  test('accepts unrelated V2 journey receipts without PERF-000C telemetry', () {
    expect(
      () => performance_driver.validatePerformanceResponse(<String, dynamic>{
        'schemaVersion': 2,
        'target': 'integration_test/editor_codec_offload_journey_test.dart',
      }),
      returnsNormally,
    );
  });

  test('rejects an incomplete PERF-000C canvas matrix', () {
    expect(
      () => performance_driver.validatePerformanceResponse(<String, dynamic>{
        'schemaVersion': 2,
        'target': 'integration_test/editor_canvas_projection_journey_test.dart',
        'results': const <Object?>[],
        'placementResults': const <Object?>[],
      }),
      throwsFormatException,
    );
  });

  test('requires PERF-000B telemetry for the editor project journey', () {
    expect(
      () => performance_driver.validatePerformanceResponse(<String, dynamic>{
        'schemaVersion': 2,
        'target': 'integration_test/editor_project_journey_test.dart',
      }),
      throwsFormatException,
    );
  });

  test('rejects persistence counters in measured pointer phases', () {
    final instrumentation = _instrumentation();
    expect(
      () => performance_driver.validatePerformanceResponse(<String, dynamic>{
        'schemaVersion': 2,
        'target': 'integration_test/editor_project_journey_test.dart',
        'instrumentation': instrumentation,
        'results': <Map<String, Object?>>[
          _phase(
            'pointer-collision-drag',
            spanName: 'pointer_to_dispatch',
            spanCount: 90,
            filesystemRead: 1,
          ),
          _phase(
            'collision-paint-1000',
            spanName: 'mutation.local',
            spanCount: 1000,
          ),
        ],
      }),
      throwsFormatException,
    );
  });

  test('accepts a complete PERF-000C project journey receipt', () {
    expect(
      () => performance_driver.validatePerformanceResponse(
        _validProjectReceipt(),
      ),
      returnsNormally,
    );
  });

  test('rejects missing VM allocation evidence', () {
    final receipt = _validProjectReceipt();
    receipt.remove('memory');

    expect(
      () => performance_driver.validatePerformanceResponse(receipt),
      throwsFormatException,
    );
  });

  test('rejects an incomplete collision and mask matrix', () {
    final receipt = _validProjectReceipt();
    final results = receipt['results']! as List<Map<String, Object?>>;
    results.removeWhere(
      (phase) => phase['phase'] == 'mask-roundtrip-1024x1024',
    );

    expect(
      () => performance_driver.validatePerformanceResponse(receipt),
      throwsFormatException,
    );
  });

  test('rejects a failed interactive latency budget', () {
    final receipt = _validProjectReceipt();
    final results = receipt['results']! as List<Map<String, Object?>>;
    results[0] = <String, Object?>{...results[0], 'p95Us': 16000};

    expect(
      () => performance_driver.validatePerformanceResponse(receipt),
      throwsFormatException,
    );
  });
}

Map<String, dynamic> _validProjectReceipt() => <String, dynamic>{
  'schemaVersion': 2,
  'target': 'integration_test/editor_project_journey_test.dart',
  'memory': <String, Object?>{
    'allocatedBytes': 1024,
    'allocationCount': 10,
    'heapBeforeGcBytes': 4096,
    'heapAfterGcBytes': 2048,
    'heapCapacityAfterGcBytes': 8192,
    'externalAfterGcBytes': 0,
    'forcedGarbageCollection': true,
    'garbageCollectionTimestampMicros': 42,
  },
  'instrumentation': _instrumentation(),
  'results': <Map<String, Object?>>[
    <String, Object?>{
      ..._phase('tile-placement-90', spanName: 'mutation.local', spanCount: 90),
      'p95Us': 15000,
    },
    _phase(
      'pointer-collision-drag',
      spanName: 'pointer_to_dispatch',
      spanCount: 90,
      spanP95Us: 7000,
    ),
    for (final strokeCount in const <int>[1, 10, 100, 1000])
      _phase(
        'collision-paint-$strokeCount',
        spanName: 'mutation.local',
        spanCount: strokeCount,
      ),
    _canonicalPlacementPhase(),
    for (final extent in const <int>[64, 256, 512, 1024]) _maskPhase(extent),
  ],
};

Map<String, Object?> _canonicalPlacementPhase() {
  final instrumentation = _instrumentation();
  final spans = instrumentation['spans']! as Map<String, Object?>;
  for (final name in const <String>['snapshot', 'plan', 'apply']) {
    spans[name] = <String, Object?>{'count': 1, 'p95Us': 1};
  }
  return <String, Object?>{
    'phase': 'canonical-element-placement',
    'instrumentation': instrumentation,
  };
}

Map<String, Object?> _maskPhase(int extent) {
  final instrumentation = _instrumentation();
  final counters = instrumentation['counters']! as Map<String, Object?>;
  counters['base64.encode'] = 10;
  counters['base64.decode'] = 10;
  return <String, Object?>{
    'phase': 'mask-roundtrip-${extent}x$extent',
    'p50Us': 1,
    'p95Us': 2,
    'p99Us': 3,
    'instrumentation': instrumentation,
  };
}

Map<String, Object?> _phase(
  String name, {
  required String spanName,
  required int spanCount,
  int spanP95Us = 0,
  int filesystemRead = 0,
}) {
  final instrumentation = _instrumentation();
  final spans = instrumentation['spans']! as Map<String, Object?>;
  spans[spanName] = <String, Object?>{'count': spanCount, 'p95Us': spanP95Us};
  final counters = instrumentation['counters']! as Map<String, Object?>;
  counters['filesystem.read'] = filesystemRead;
  return <String, Object?>{'phase': name, 'instrumentation': instrumentation};
}

Map<String, Object?> _instrumentation() => <String, Object?>{
  'schemaVersion': 1,
  'spans': <String, Object?>{
    for (final name in const <String>[
      'pointer_to_dispatch',
      'mutation.local',
      'state.publish',
      'canvas.build',
      'canvas.paint',
      'snapshot',
      'plan',
      'apply',
      'save.queue',
      'save.encode',
    ])
      name: <String, Object?>{'count': 0},
  },
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
  'droppedSampleCount': 0,
};

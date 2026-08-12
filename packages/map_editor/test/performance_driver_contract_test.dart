import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/services/fine_mask_performance_telemetry.dart';

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

  test('rejects canvas rows without raw samples', () {
    final receipt = _validCanvasReceipt();
    final results = receipt['results']! as List<Map<String, Object?>>;
    results.first.remove('samplesUs');

    expect(
      () => performance_driver.validatePerformanceResponse(receipt),
      throwsFormatException,
    );
  });

  test('rejects canvas percentiles that do not match raw samples', () {
    final receipt = _validCanvasReceipt();
    final results = receipt['results']! as List<Map<String, Object?>>;
    results.first['p95Us'] = 1;

    expect(
      () => performance_driver.validatePerformanceResponse(receipt),
      throwsFormatException,
    );
  });

  test('rejects a canvas receipt whose declared gate hides a regression', () {
    final receipt = _validCanvasReceipt(sampleUs: 20000);

    expect(
      () => performance_driver.validatePerformanceResponse(receipt),
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
            spanName: 'pointer.pre_dispatch',
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

  test('rejects missing Flutter frame latency evidence', () {
    final receipt = _validProjectReceipt();
    receipt.remove('frameMetrics');

    expect(
      () => performance_driver.validatePerformanceResponse(receipt),
      throwsFormatException,
    );
  });

  test('rejects project hot-path spans without raw samples', () {
    final receipt = _validProjectReceipt();
    final results = receipt['results']! as List<Map<String, Object?>>;
    final pointer = results.singleWhere(
      (row) => row['phase'] == 'pointer-collision-drag',
    );
    final instrumentation = pointer['instrumentation']! as Map<String, Object?>;
    final spans = instrumentation['spans']! as Map<String, Object?>;
    final metrics = spans['pointer.to_state_publish']! as Map<String, Object?>;
    metrics.remove('samplesUs');

    expect(
      () => performance_driver.validatePerformanceResponse(receipt),
      throwsFormatException,
    );
  });

  test('rejects falsified project hot-path percentiles', () {
    final receipt = _validProjectReceipt();
    final results = receipt['results']! as List<Map<String, Object?>>;
    final pointer = results.singleWhere(
      (row) => row['phase'] == 'pointer-collision-drag',
    );
    final instrumentation = pointer['instrumentation']! as Map<String, Object?>;
    final spans = instrumentation['spans']! as Map<String, Object?>;
    final metrics = spans['pointer.to_state_publish']! as Map<String, Object?>;
    metrics['p95Us'] = 1;

    expect(
      () => performance_driver.validatePerformanceResponse(receipt),
      throwsFormatException,
    );
  });

  test('rejects ambiguous frame and canvas measurement scopes', () {
    final project = _validProjectReceipt();
    final frameMetrics = project['frameMetrics']! as Map<String, Object?>;
    frameMetrics.remove('scope');
    expect(
      () => performance_driver.validatePerformanceResponse(project),
      throwsFormatException,
    );

    final projectMeasurement = _validProjectReceipt();
    projectMeasurement.remove('measurementScope');
    expect(
      () => performance_driver.validatePerformanceResponse(projectMeasurement),
      throwsFormatException,
    );

    final canvas = _validCanvasReceipt();
    canvas.remove('measurementScope');
    expect(
      () => performance_driver.validatePerformanceResponse(canvas),
      throwsFormatException,
    );
  });

  test('rejects debug, dirty and unavailable provenance', () {
    for (final mutation in <void Function(Map<String, dynamic>)>[
      (receipt) => receipt['executionMode'] = 'flutter-debug',
      (receipt) => receipt['treeState'] = 'dirty',
      (receipt) => receipt['commit'] = 'unavailable',
      (receipt) => receipt['sdk'] = 'unavailable',
      (receipt) => receipt['architecture'] = 'unavailable',
      (receipt) => receipt['toolchain'] = <String, Object?>{},
      (receipt) => (receipt['toolchain']! as Map<String, Object?>)['flame'] =
          'unavailable',
    ]) {
      final receipt = _validProjectReceipt();
      mutation(receipt);
      expect(
        () => performance_driver.validatePerformanceResponse(receipt),
        throwsFormatException,
      );
    }
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

  test('rejects a duplicated collision matrix row', () {
    final receipt = _validProjectReceipt();
    final results = receipt['results']! as List<Map<String, Object?>>;
    results.add(
      _phase(
        'collision-paint-1024x1024-1000',
        spanName: 'mutation.local',
        spanCount: 1000,
      ),
    );

    expect(
      () => performance_driver.validatePerformanceResponse(receipt),
      throwsFormatException,
    );
  });

  test('rejects a failed interactive latency budget', () {
    final receipt = _validProjectReceipt();
    final results = receipt['results']! as List<Map<String, Object?>>;
    results[0] = <String, Object?>{
      ...results[0],
      'samplesUs': List<int>.filled(90, 16000),
      'p50Us': 16000,
      'p95Us': 16000,
      'p99Us': 16000,
      'maxUs': 16000,
    };

    expect(
      () => performance_driver.validatePerformanceResponse(receipt),
      throwsFormatException,
    );
  });

  test('accepts a complete real fine-mask journey receipt', () {
    expect(
      () => performance_driver.validatePerformanceResponse(
        _validFineMaskReceipt(),
      ),
      returnsNormally,
    );
  });

  test('rejects base64 work during fine-mask pointer moves', () {
    final receipt = _validFineMaskReceipt();
    final rows = receipt['results']! as List<Map<String, Object?>>;
    final move = rows.first['moveInstrumentation']! as Map<String, Object?>;
    final counters = move['counters']! as Map<String, Object?>;
    counters['base64.encode'] = 1;

    expect(
      () => performance_driver.validatePerformanceResponse(receipt),
      throwsFormatException,
    );
  });
}

Map<String, dynamic> _validFineMaskReceipt() => <String, dynamic>{
  'schemaVersion': 2,
  'target': 'integration_test/editor_fine_mask_journey_test.dart',
  'executionMode': 'flutter-profile',
  'commit': '0123456789abcdef0123456789abcdef01234567',
  'treeState': 'clean',
  'architecture': 'arm64',
  'sdk': 'Dart 3',
  'toolchain': <String, Object?>{
    'dart': 'Dart 3',
    'flutter': <String, Object?>{'frameworkRevision': 'flutter-sha'},
    'flame': '1.0.0',
  },
  'pointerMovesPerExtent': 30,
  'performanceBudgets': <String, Object?>{
    'schemaVersion': FineMaskPerformanceBudget.schemaVersion,
    'fineMask1024PointerMoveP95Us':
        FineMaskPerformanceBudget.pointerMove1024P95Us,
    'fineMask1024PaintP95Us': FineMaskPerformanceBudget.paint1024P95Us,
    'frameTimingPolicy': FineMaskPerformanceBudget.frameTimingPolicy,
  },
  'soakCycles': 3,
  'soakMemory': _memory(),
  'soakHeapGrowthBudgetBytes': 32 * 1024 * 1024,
  'soakHeapStable': true,
  'memory': _memory(),
  'results': <Map<String, Object?>>[
    for (final extent in const <int>[64, 256, 512, 1024]) _fineMaskRow(extent),
  ],
};

Map<String, Object?> _fineMaskRow(int extent) {
  final move = _instrumentation();
  final moveSpans = move['spans']! as Map<String, Object?>;
  moveSpans['mask.pointer_move'] = _spanMetrics(30, 10);
  final commit = _instrumentation();
  final commitSpans = commit['spans']! as Map<String, Object?>;
  commitSpans['mask.commit'] = _spanMetrics(1, 20);
  final commitCounters = commit['counters']! as Map<String, Object?>;
  commitCounters['base64.encode'] = 3;
  commitCounters['base64.decode'] = 1;
  final total = _instrumentation();
  final totalSpans = total['spans']! as Map<String, Object?>;
  totalSpans['mask.readback'] = _spanMetrics(1, 100);
  totalSpans['mask.build'] = _spanMetrics(31, 20);
  totalSpans['mask.paint'] = _spanMetrics(31, 30);
  return <String, Object?>{
    'extent': extent,
    'pointerMoveCount': 30,
    'moveInstrumentation': move,
    'commitInstrumentation': commit,
    'extentInstrumentation': total,
    'frameMetrics': <String, Object?>{
      'scope': 'flutter.frame_total',
      'policy': FineMaskPerformanceBudget.frameTimingPolicy,
      'samplesUs': List<int>.filled(31, 1000),
      'p50Us': 1000,
      'p95Us': 1000,
      'p99Us': 1000,
      'maxUs': 1000,
    },
  };
}

Map<String, Object?> _spanMetrics(int count, int sampleUs) => <String, Object?>{
  'count': count,
  'samplesUs': List<int>.filled(count, sampleUs),
  'p50Us': sampleUs,
  'p95Us': sampleUs,
  'p99Us': sampleUs,
  'maxUs': sampleUs,
};

Map<String, dynamic> _validCanvasReceipt({int sampleUs = 100}) {
  final results = <Map<String, Object?>>[
    for (final mode in const <String>[
      'standard',
      'smart',
      'shadows',
      'combined',
    ])
      for (final extent in const <int>[128, 256, 512, 1024])
        _canvasRow(
          mode: mode,
          extent: extent,
          placedElementCount: mode == 'shadows' || mode == 'combined' ? 2 : 0,
          sampleUs: sampleUs,
        ),
  ];
  return <String, dynamic>{
    'schemaVersion': 2,
    'target': 'integration_test/editor_canvas_projection_journey_test.dart',
    'sampleCountPerModeAndExtent': 90,
    'executionMode': 'flutter-profile',
    'commit': '0123456789abcdef0123456789abcdef01234567',
    'treeState': 'clean',
    'architecture': 'arm64',
    'sdk': 'Dart 3',
    'toolchain': <String, Object?>{
      'dart': 'Dart 3',
      'flutter': <String, Object?>{'frameworkRevision': 'flutter-sha'},
      'flame': '1.0.0',
    },
    'memory': _memory(),
    'measurementScope': <String, Object?>{
      'metric': 'canvas.paint_recording',
      'includesGpuRaster': false,
      'includesLayoutAndComposition': false,
    },
    'results': results,
    'placementResults': <Map<String, Object?>>[
      for (final count in const <int>[100, 1000, 10000])
        _canvasRow(
          mode: 'shadows',
          extent: 1024,
          placedElementCount: count,
          sampleUs: sampleUs,
        ),
    ],
    'performanceGates': <String, Object?>{
      'combined1024P95BudgetUs': 8000,
      'repaintP95BudgetUs': 16670,
      'combined1024To128P95RatioBudget': 1.5,
      'standard1024P95ObservationCeilingUs': 4000,
      'combined1024P95Pass': true,
      'repaintP95Pass': true,
      'combinedScaleRatioPass': true,
      'standardControlPass': true,
    },
  };
}

Map<String, Object?> _canvasRow({
  required String mode,
  required int extent,
  required int placedElementCount,
  required int sampleUs,
}) => <String, Object?>{
  'mode': mode,
  'extent': extent,
  'placedElementCount': placedElementCount,
  'samplesUs': List<int>.filled(90, sampleUs),
  'p50Us': sampleUs,
  'p95Us': sampleUs,
  'p99Us': sampleUs,
  'maxUs': sampleUs,
};

Map<String, Object?> _memory() => <String, Object?>{
  'allocatedBytes': 1024,
  'allocationCount': 10,
  'heapBeforeGcBytes': 4096,
  'heapAfterGcBytes': 2048,
  'heapCapacityAfterGcBytes': 8192,
  'externalAfterGcBytes': 0,
  'forcedGarbageCollection': true,
  'garbageCollectionTimestampMicros': 42,
};

Map<String, dynamic> _validProjectReceipt() => <String, dynamic>{
  'schemaVersion': 2,
  'target': 'integration_test/editor_project_journey_test.dart',
  'executionMode': 'flutter-profile',
  'commit': '0123456789abcdef0123456789abcdef01234567',
  'treeState': 'clean',
  'architecture': 'arm64',
  'sdk': 'Dart 3',
  'toolchain': <String, Object?>{
    'dart': 'Dart 3',
    'flutter': <String, Object?>{'frameworkRevision': 'flutter-sha'},
    'flame': '1.0.0',
  },
  'memory': _memory(),
  'instrumentation': _instrumentation(),
  'measurementScope': <String, Object?>{
    'pointerLatencyMetric': 'pointer.to_state_publish',
    'canvasPaintMetric': 'canvas.paint_recording',
    'frameMetric': 'flutter.frame_total',
    'framePolicy': 'observation',
  },
  'frameMetrics': <String, Object?>{
    'scope': 'flutter.frame_total',
    'policy': 'observation',
    'frameCount': 90,
    'frameSpanSamplesMicroseconds': List<int>.filled(90, 1000),
    'frameSpanP50Us': 1000,
    'frameSpanP95Us': 1000,
    'frameSpanP99Us': 1000,
  },
  'results': <Map<String, Object?>>[
    <String, Object?>{
      ..._phase('tile-placement-90', spanName: 'mutation.local', spanCount: 90),
      'samplesUs': List<int>.filled(90, 15000),
      'p50Us': 15000,
      'p95Us': 15000,
      'p99Us': 15000,
      'maxUs': 15000,
    },
    _phase(
      'pointer-collision-drag',
      spanName: 'pointer.to_state_publish',
      spanCount: 90,
      spanP95Us: 7000,
      additionalSpanCounts: const <String, int>{'pointer.pre_dispatch': 90},
    ),
    for (final extent in const <int>[128, 256, 512, 1024])
      for (final strokeCount in const <int>[1, 10, 100, 1000])
        _phase(
          'collision-paint-${extent}x$extent-$strokeCount',
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
    spans[name] = _spanMetrics(1, 1);
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
    'samplesUs': const <int>[1, 1, 1, 1, 1, 2, 2, 2, 3, 3],
    'p50Us': 1,
    'p95Us': 3,
    'p99Us': 3,
    'maxUs': 3,
    'instrumentation': instrumentation,
  };
}

Map<String, Object?> _phase(
  String name, {
  required String spanName,
  required int spanCount,
  int spanP95Us = 0,
  int filesystemRead = 0,
  Map<String, int> additionalSpanCounts = const <String, int>{},
}) {
  final instrumentation = _instrumentation();
  final spans = instrumentation['spans']! as Map<String, Object?>;
  spans[spanName] = _spanMetrics(spanCount, spanP95Us);
  for (final entry in additionalSpanCounts.entries) {
    spans[entry.key] = _spanMetrics(entry.value, spanP95Us);
  }
  final counters = instrumentation['counters']! as Map<String, Object?>;
  counters['filesystem.read'] = filesystemRead;
  return <String, Object?>{'phase': name, 'instrumentation': instrumentation};
}

Map<String, Object?> _instrumentation() => <String, Object?>{
  'schemaVersion': 1,
  'coverage': 'instrumented editor and authoring application boundaries only',
  'spans': <String, Object?>{
    for (final name in const <String>[
      'pointer.pre_dispatch',
      'pointer.to_state_publish',
      'mutation.local',
      'state.publish',
      'canvas.prepare',
      'canvas.future_builder_body',
      'canvas.paint_recording',
      'mask.readback',
      'mask.pointer_move',
      'mask.commit',
      'mask.build',
      'mask.paint',
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

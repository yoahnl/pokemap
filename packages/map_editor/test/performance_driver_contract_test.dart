import 'package:flutter_test/flutter_test.dart';

import '../test_driver/performance_driver.dart' as performance_driver;

void main() {
  test('accepts legacy V2 journey receipts without PERF-000B telemetry', () {
    expect(
      () => performance_driver.validatePerformanceResponse(<String, dynamic>{
        'schemaVersion': 2,
        'target': 'integration_test/editor_canvas_projection_journey_test.dart',
      }),
      returnsNormally,
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
            spanCount: 1,
            filesystemRead: 1,
          ),
          _phase(
            'collision-paint-100',
            spanName: 'mutation.local',
            spanCount: 100,
          ),
        ],
      }),
      throwsFormatException,
    );
  });
}

Map<String, Object?> _phase(
  String name, {
  required String spanName,
  required int spanCount,
  int filesystemRead = 0,
}) {
  final instrumentation = _instrumentation();
  final spans = instrumentation['spans']! as Map<String, Object?>;
  spans[spanName] = <String, Object?>{'count': spanCount};
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

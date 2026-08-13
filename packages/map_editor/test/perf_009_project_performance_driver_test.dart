import 'package:flutter_test/flutter_test.dart';

import '../test_driver/perf_009_project_performance_driver.dart';

void main() {
  test('accepts the split buffered project contract', () {
    expect(
      () => validatePerf009BufferedProjectPhases(_validData()),
      returnsNormally,
    );
  });

  test('rejects canonical persistence inside local placement', () {
    final data = _validData();
    final placement = _phaseByName(data, 'canonical-element-placement');
    final spans = _spans(placement);
    spans['snapshot'] = _metrics(1);

    expect(
      () => validatePerf009BufferedProjectPhases(data),
      throwsFormatException,
    );
  });

  test('rejects a missing canonical publication phase', () {
    final data = _validData();
    final results = data['results']! as List<Map<String, Object?>>;
    results.removeWhere(
      (phase) => phase['phase'] == 'canonical-element-publication',
    );

    expect(
      () => validatePerf009BufferedProjectPhases(data),
      throwsFormatException,
    );
  });

  test('rejects the pre-buffer tile placement span count', () {
    final data = _validData();
    final placement = _phaseByName(data, 'tile-placement-90');
    _spans(placement)['mutation.local'] = _metrics(90);

    expect(
      () => validatePerf009BufferedProjectPhases(data),
      throwsFormatException,
    );
  });

  test('rejects the pre-buffer collision span count', () {
    final data = _validData();
    final collision = _phaseByName(data, 'collision-paint-128x128-10');
    _spans(collision)['mutation.local'] = _metrics(10);

    expect(
      () => validatePerf009BufferedProjectPhases(data),
      throwsFormatException,
    );
  });
}

Map<String, dynamic> _validData() => <String, dynamic>{
  'target': 'integration_test/editor_project_journey_test.dart',
  'results': <Map<String, Object?>>[
    _phase('tile-placement-90', <String, Map<String, Object?>>{
      'mutation.local': _metrics(154),
    }),
    for (final extent in const <int>[128, 256, 512, 1024])
      for (final strokeCount in const <int>[1, 10, 100, 1000])
        _phase(
          'collision-paint-${extent}x$extent-$strokeCount',
          <String, Map<String, Object?>>{
            'mutation.local': _metrics(strokeCount + 1),
          },
        ),
    _phase(
      'canonical-element-placement',
      <String, Map<String, Object?>>{
        'snapshot': _metrics(0),
        'plan': _metrics(0),
        'apply': _metrics(0),
      },
    ),
    _phase(
      'canonical-element-publication',
      <String, Map<String, Object?>>{
        'snapshot': _metrics(2),
        'plan': _metrics(1),
        'apply': _metrics(1),
      },
    ),
  ],
};

Map<String, Object?> _phase(
  String name,
  Map<String, Map<String, Object?>> requiredSpans,
) => <String, Object?>{
  'phase': name,
  'instrumentation': <String, Object?>{
    'spans': <String, Object?>{...requiredSpans},
    'counters': <String, Object?>{
      'filesystem.read': 0,
      'filesystem.write': 0,
      'filesystem.metadata': 0,
      'json.encode': 0,
      'json.decode': 0,
      'base64.encode': 0,
      'base64.decode': 0,
    },
  },
};

Map<String, Object?> _metrics(int count) {
  final samples = List<int>.generate(count, (index) => index + 1);
  if (samples.isEmpty) {
    return <String, Object?>{
      'count': 0,
      'samplesUs': const <int>[],
      'p50Us': 0,
      'p95Us': 0,
      'p99Us': 0,
      'maxUs': 0,
    };
  }
  return <String, Object?>{
    'count': count,
    'samplesUs': samples,
    'p50Us': _percentile(samples, 0.50),
    'p95Us': _percentile(samples, 0.95),
    'p99Us': _percentile(samples, 0.99),
    'maxUs': samples.last,
  };
}

Map<String, Object?> _phaseByName(Map<String, dynamic> data, String name) {
  final results = data['results']! as List<Map<String, Object?>>;
  return results.singleWhere((phase) => phase['phase'] == name);
}

Map<String, Object?> _spans(Map<String, Object?> phase) {
  final instrumentation = phase['instrumentation']! as Map<String, Object?>;
  return instrumentation['spans']! as Map<String, Object?>;
}

int _percentile(List<int> sorted, double percentile) {
  final index = (percentile * sorted.length).ceil() - 1;
  return sorted[index.clamp(0, sorted.length - 1)];
}

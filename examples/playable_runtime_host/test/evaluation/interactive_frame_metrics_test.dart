import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_loader/src/evaluation/interactive/interactive_frame_metrics.dart';

void main() {
  test('collector reports separate percentiles and frame budget rates', () {
    final collector = InteractiveFrameMetricsCollector();
    collector.recordDurations(
      build: const Duration(milliseconds: 8),
      raster: const Duration(milliseconds: 7),
      frameSpan: const Duration(milliseconds: 10),
    );
    collector.recordDurations(
      build: const Duration(milliseconds: 1),
      raster: const Duration(milliseconds: 30),
      frameSpan: const Duration(milliseconds: 40),
    );
    collector.recordDurations(
      build: const Duration(milliseconds: 4),
      raster: const Duration(milliseconds: 20),
      frameSpan: const Duration(milliseconds: 20),
    );
    collector.recordDurations(
      build: const Duration(milliseconds: 2),
      raster: const Duration(milliseconds: 5),
      frameSpan: const Duration(milliseconds: 12),
    );

    final snapshot = collector.snapshot();
    expect(snapshot.frameCount, 4);
    expect(snapshot.buildP50Milliseconds, 2);
    expect(snapshot.buildP95Milliseconds, 8);
    expect(snapshot.buildP99Milliseconds, 8);
    expect(snapshot.rasterP50Milliseconds, 7);
    expect(snapshot.rasterP95Milliseconds, 30);
    expect(snapshot.frameSpanP50Milliseconds, 12);
    expect(snapshot.frameSpanP95Milliseconds, 40);
    expect(snapshot.framesOver16Point67Milliseconds, 2);
    expect(snapshot.framesOver16Point67Rate, 0.5);
    expect(snapshot.framesOver33Point3Milliseconds, 1);
    expect(snapshot.framesOver33Point3Rate, 0.25);
  });

  test('unsorted samples are copied and ranked without mutating input', () {
    final build = <int>[9000, 1000, 5000];
    final raster = <int>[4000, 8000, 2000];
    final spans = <int>[12000, 3000, 7000];

    final snapshot = InteractiveFrameMetricsSnapshot.fromMicrosecondSamples(
      buildMicroseconds: build,
      rasterMicroseconds: raster,
      frameSpanMicroseconds: spans,
    );

    expect(build, <int>[9000, 1000, 5000]);
    expect(snapshot.buildP50Milliseconds, 5);
    expect(snapshot.rasterP50Milliseconds, 4);
    expect(snapshot.frameSpanP95Milliseconds, 12);
  });

  test('collector reset isolates consecutive runs', () {
    final collector = InteractiveFrameMetricsCollector()
      ..recordDurations(
        build: const Duration(milliseconds: 4),
        raster: const Duration(milliseconds: 7),
      )
      ..reset();

    expect(
      collector.snapshot().toJson(),
      <String, Object?>{
        'schemaVersion': 2,
        'frameCount': 0,
        'averageBuildMilliseconds': 0,
        'averageRasterMilliseconds': 0,
        'maxBuildMilliseconds': 0,
        'maxRasterMilliseconds': 0,
        'buildP50Milliseconds': 0,
        'buildP95Milliseconds': 0,
        'buildP99Milliseconds': 0,
        'rasterP50Milliseconds': 0,
        'rasterP95Milliseconds': 0,
        'rasterP99Milliseconds': 0,
        'frameSpanP50Milliseconds': 0,
        'frameSpanP95Milliseconds': 0,
        'frameSpanP99Milliseconds': 0,
        'framesOver16Point67Milliseconds': 0,
        'framesOver16Point67Rate': 0,
        'framesOver33Point3Milliseconds': 0,
        'framesOver33Point3Rate': 0,
        'buildSamplesMicroseconds': <int>[],
        'rasterSamplesMicroseconds': <int>[],
        'frameSpanSamplesMicroseconds': <int>[],
      },
    );
  });

  test('JSON parser rejects malformed and unknown frame metric schemas', () {
    expect(
      () => InteractiveFrameMetricsSnapshot.fromJson(
        const <String, Object?>{'schemaVersion': 99},
      ),
      throwsFormatException,
    );
    expect(
      () => InteractiveFrameMetricsSnapshot.fromJson(
        const <String, Object?>{'schemaVersion': 2, 'frameCount': 'one'},
      ),
      throwsFormatException,
    );
  });

  test('JSON round trip preserves raw frame samples', () {
    final source = InteractiveFrameMetricsSnapshot.fromMicrosecondSamples(
      buildMicroseconds: const <int>[1000, 9000],
      rasterMicroseconds: const <int>[2000, 8000],
      frameSpanMicroseconds: const <int>[3000, 12000],
    );

    final restored = InteractiveFrameMetricsSnapshot.fromJson(source.toJson());

    expect(restored.toJson(), source.toJson());
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_loader/src/evaluation/interactive/interactive_frame_metrics.dart';

void main() {
  test('collector reports frame count and worst frame durations', () {
    final collector = InteractiveFrameMetricsCollector();
    collector.recordDurations(
      build: const Duration(milliseconds: 4),
      raster: const Duration(milliseconds: 7),
    );
    collector.recordDurations(
      build: const Duration(milliseconds: 6),
      raster: const Duration(milliseconds: 5),
    );

    final snapshot = collector.snapshot();
    expect(snapshot.frameCount, 2);
    expect(snapshot.maxBuildMilliseconds, 6);
    expect(snapshot.maxRasterMilliseconds, 7);
    expect(snapshot.averageBuildMilliseconds, 5);
    expect(snapshot.averageRasterMilliseconds, 6);
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
        'frameCount': 0,
        'averageBuildMilliseconds': 0,
        'averageRasterMilliseconds': 0,
        'maxBuildMilliseconds': 0,
        'maxRasterMilliseconds': 0,
      },
    );
  });
}

import 'package:flutter/scheduler.dart';

final class InteractiveFrameMetricsSnapshot {
  const InteractiveFrameMetricsSnapshot({
    required this.frameCount,
    required this.averageBuildMilliseconds,
    required this.averageRasterMilliseconds,
    required this.maxBuildMilliseconds,
    required this.maxRasterMilliseconds,
  });

  final int frameCount;
  final double averageBuildMilliseconds;
  final double averageRasterMilliseconds;
  final double maxBuildMilliseconds;
  final double maxRasterMilliseconds;

  Map<String, Object?> toJson() => <String, Object?>{
        'frameCount': frameCount,
        'averageBuildMilliseconds': averageBuildMilliseconds,
        'averageRasterMilliseconds': averageRasterMilliseconds,
        'maxBuildMilliseconds': maxBuildMilliseconds,
        'maxRasterMilliseconds': maxRasterMilliseconds,
      };
}

/// Aggregates Flutter frame timings only while an interactive run is active.
///
/// The collector never records the collision overlays: the interactive host
/// keeps both collision visualizations disabled independently of this class.
final class InteractiveFrameMetricsCollector {
  int _frameCount = 0;
  int _totalBuildMicroseconds = 0;
  int _totalRasterMicroseconds = 0;
  int _maxBuildMicroseconds = 0;
  int _maxRasterMicroseconds = 0;
  bool _recording = false;

  void start() {
    if (_recording) {
      throw StateError('Interactive frame metrics are already recording.');
    }
    final binding = SchedulerBinding.instance;
    reset();
    binding.addTimingsCallback(_onTimings);
    _recording = true;
  }

  void stop() {
    if (!_recording) return;
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _recording = false;
  }

  void reset() {
    if (_recording) {
      throw StateError('Cannot reset frame metrics while recording.');
    }
    _frameCount = 0;
    _totalBuildMicroseconds = 0;
    _totalRasterMicroseconds = 0;
    _maxBuildMicroseconds = 0;
    _maxRasterMicroseconds = 0;
  }

  void recordDurations({
    required Duration build,
    required Duration raster,
  }) {
    _frameCount += 1;
    _totalBuildMicroseconds += build.inMicroseconds;
    _totalRasterMicroseconds += raster.inMicroseconds;
    if (build.inMicroseconds > _maxBuildMicroseconds) {
      _maxBuildMicroseconds = build.inMicroseconds;
    }
    if (raster.inMicroseconds > _maxRasterMicroseconds) {
      _maxRasterMicroseconds = raster.inMicroseconds;
    }
  }

  InteractiveFrameMetricsSnapshot snapshot() {
    return InteractiveFrameMetricsSnapshot(
      frameCount: _frameCount,
      averageBuildMilliseconds:
          _frameCount == 0 ? 0 : _totalBuildMicroseconds / _frameCount / 1000,
      averageRasterMilliseconds:
          _frameCount == 0 ? 0 : _totalRasterMicroseconds / _frameCount / 1000,
      maxBuildMilliseconds: _maxBuildMicroseconds / 1000,
      maxRasterMilliseconds: _maxRasterMicroseconds / 1000,
    );
  }

  void _onTimings(List<FrameTiming> timings) {
    if (!_recording) return;
    for (final timing in timings) {
      recordDurations(
        build: timing.buildDuration,
        raster: timing.rasterDuration,
      );
    }
  }
}

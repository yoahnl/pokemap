import 'package:flutter/scheduler.dart';

final class InteractiveFrameMetricsSnapshot {
  InteractiveFrameMetricsSnapshot._({
    required this.frameCount,
    required this.averageBuildMilliseconds,
    required this.averageRasterMilliseconds,
    required this.maxBuildMilliseconds,
    required this.maxRasterMilliseconds,
    required this.buildP50Milliseconds,
    required this.buildP95Milliseconds,
    required this.buildP99Milliseconds,
    required this.rasterP50Milliseconds,
    required this.rasterP95Milliseconds,
    required this.rasterP99Milliseconds,
    required this.frameSpanP50Milliseconds,
    required this.frameSpanP95Milliseconds,
    required this.frameSpanP99Milliseconds,
    required this.framesOver16Point67Milliseconds,
    required this.framesOver16Point67Rate,
    required this.framesOver33Point3Milliseconds,
    required this.framesOver33Point3Rate,
    required List<int> buildSamplesMicroseconds,
    required List<int> rasterSamplesMicroseconds,
    required List<int> frameSpanSamplesMicroseconds,
  })  : buildSamplesMicroseconds = List<int>.unmodifiable(
          buildSamplesMicroseconds,
        ),
        rasterSamplesMicroseconds = List<int>.unmodifiable(
          rasterSamplesMicroseconds,
        ),
        frameSpanSamplesMicroseconds = List<int>.unmodifiable(
          frameSpanSamplesMicroseconds,
        );

  static const schemaVersion = 2;

  factory InteractiveFrameMetricsSnapshot.fromMicrosecondSamples({
    required List<int> buildMicroseconds,
    required List<int> rasterMicroseconds,
    required List<int> frameSpanMicroseconds,
  }) {
    if (buildMicroseconds.length != rasterMicroseconds.length ||
        buildMicroseconds.length != frameSpanMicroseconds.length) {
      throw const FormatException(
        'Frame metric sample collections must have equal lengths.',
      );
    }
    if (<List<int>>[
      buildMicroseconds,
      rasterMicroseconds,
      frameSpanMicroseconds,
    ].any((samples) => samples.any((sample) => sample < 0))) {
      throw const FormatException('Frame metric samples cannot be negative.');
    }

    final builds = List<int>.of(buildMicroseconds);
    final rasters = List<int>.of(rasterMicroseconds);
    final spans = List<int>.of(frameSpanMicroseconds);
    final sortedBuilds = List<int>.of(builds)..sort();
    final sortedRasters = List<int>.of(rasters)..sort();
    final sortedSpans = List<int>.of(spans)..sort();
    final count = builds.length;
    final over16 = spans.where((sample) => sample > 16670).length;
    final over33 = spans.where((sample) => sample > 33300).length;

    return InteractiveFrameMetricsSnapshot._(
      frameCount: count,
      averageBuildMilliseconds: _averageMilliseconds(builds),
      averageRasterMilliseconds: _averageMilliseconds(rasters),
      maxBuildMilliseconds: _maxMilliseconds(builds),
      maxRasterMilliseconds: _maxMilliseconds(rasters),
      buildP50Milliseconds: _percentileMilliseconds(sortedBuilds, 0.50),
      buildP95Milliseconds: _percentileMilliseconds(sortedBuilds, 0.95),
      buildP99Milliseconds: _percentileMilliseconds(sortedBuilds, 0.99),
      rasterP50Milliseconds: _percentileMilliseconds(sortedRasters, 0.50),
      rasterP95Milliseconds: _percentileMilliseconds(sortedRasters, 0.95),
      rasterP99Milliseconds: _percentileMilliseconds(sortedRasters, 0.99),
      frameSpanP50Milliseconds: _percentileMilliseconds(sortedSpans, 0.50),
      frameSpanP95Milliseconds: _percentileMilliseconds(sortedSpans, 0.95),
      frameSpanP99Milliseconds: _percentileMilliseconds(sortedSpans, 0.99),
      framesOver16Point67Milliseconds: over16,
      framesOver16Point67Rate: count == 0 ? 0 : over16 / count,
      framesOver33Point3Milliseconds: over33,
      framesOver33Point3Rate: count == 0 ? 0 : over33 / count,
      buildSamplesMicroseconds: builds,
      rasterSamplesMicroseconds: rasters,
      frameSpanSamplesMicroseconds: spans,
    );
  }

  factory InteractiveFrameMetricsSnapshot.fromJson(
    Map<String, Object?> json,
  ) {
    if (json['schemaVersion'] != schemaVersion) {
      throw const FormatException(
        'Unsupported interactive frame metrics schema.',
      );
    }
    const requiredKeys = <String>{
      'schemaVersion',
      'frameCount',
      'averageBuildMilliseconds',
      'averageRasterMilliseconds',
      'maxBuildMilliseconds',
      'maxRasterMilliseconds',
      'buildP50Milliseconds',
      'buildP95Milliseconds',
      'buildP99Milliseconds',
      'rasterP50Milliseconds',
      'rasterP95Milliseconds',
      'rasterP99Milliseconds',
      'frameSpanP50Milliseconds',
      'frameSpanP95Milliseconds',
      'frameSpanP99Milliseconds',
      'framesOver16Point67Milliseconds',
      'framesOver16Point67Rate',
      'framesOver33Point3Milliseconds',
      'framesOver33Point3Rate',
      'buildSamplesMicroseconds',
      'rasterSamplesMicroseconds',
      'frameSpanSamplesMicroseconds',
    };
    if (json.keys.toSet().difference(requiredKeys).isNotEmpty ||
        requiredKeys.difference(json.keys.toSet()).isNotEmpty) {
      throw const FormatException(
        'Interactive frame metrics fields do not match schema V2.',
      );
    }
    final frameCount = json['frameCount'];
    if (frameCount is! int || frameCount < 0) {
      throw const FormatException('frameCount must be a non-negative integer.');
    }
    final snapshot = InteractiveFrameMetricsSnapshot.fromMicrosecondSamples(
      buildMicroseconds: _integerSamples(
        json['buildSamplesMicroseconds'],
        'buildSamplesMicroseconds',
      ),
      rasterMicroseconds: _integerSamples(
        json['rasterSamplesMicroseconds'],
        'rasterSamplesMicroseconds',
      ),
      frameSpanMicroseconds: _integerSamples(
        json['frameSpanSamplesMicroseconds'],
        'frameSpanSamplesMicroseconds',
      ),
    );
    if (snapshot.frameCount != frameCount) {
      throw const FormatException('frameCount does not match raw samples.');
    }
    for (final key in requiredKeys.difference(const <String>{
      'schemaVersion',
      'frameCount',
      'buildSamplesMicroseconds',
      'rasterSamplesMicroseconds',
      'frameSpanSamplesMicroseconds',
    })) {
      final declared = json[key];
      final computed = snapshot.toJson()[key];
      if (declared is! num ||
          declared.toDouble() != (computed! as num).toDouble()) {
        throw FormatException('$key does not match raw samples.');
      }
    }
    return snapshot;
  }

  final int frameCount;
  final double averageBuildMilliseconds;
  final double averageRasterMilliseconds;
  final double maxBuildMilliseconds;
  final double maxRasterMilliseconds;
  final double buildP50Milliseconds;
  final double buildP95Milliseconds;
  final double buildP99Milliseconds;
  final double rasterP50Milliseconds;
  final double rasterP95Milliseconds;
  final double rasterP99Milliseconds;
  final double frameSpanP50Milliseconds;
  final double frameSpanP95Milliseconds;
  final double frameSpanP99Milliseconds;
  final int framesOver16Point67Milliseconds;
  final double framesOver16Point67Rate;
  final int framesOver33Point3Milliseconds;
  final double framesOver33Point3Rate;
  final List<int> buildSamplesMicroseconds;
  final List<int> rasterSamplesMicroseconds;
  final List<int> frameSpanSamplesMicroseconds;

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': schemaVersion,
        'frameCount': frameCount,
        'averageBuildMilliseconds': averageBuildMilliseconds,
        'averageRasterMilliseconds': averageRasterMilliseconds,
        'maxBuildMilliseconds': maxBuildMilliseconds,
        'maxRasterMilliseconds': maxRasterMilliseconds,
        'buildP50Milliseconds': buildP50Milliseconds,
        'buildP95Milliseconds': buildP95Milliseconds,
        'buildP99Milliseconds': buildP99Milliseconds,
        'rasterP50Milliseconds': rasterP50Milliseconds,
        'rasterP95Milliseconds': rasterP95Milliseconds,
        'rasterP99Milliseconds': rasterP99Milliseconds,
        'frameSpanP50Milliseconds': frameSpanP50Milliseconds,
        'frameSpanP95Milliseconds': frameSpanP95Milliseconds,
        'frameSpanP99Milliseconds': frameSpanP99Milliseconds,
        'framesOver16Point67Milliseconds': framesOver16Point67Milliseconds,
        'framesOver16Point67Rate': framesOver16Point67Rate,
        'framesOver33Point3Milliseconds': framesOver33Point3Milliseconds,
        'framesOver33Point3Rate': framesOver33Point3Rate,
        'buildSamplesMicroseconds': buildSamplesMicroseconds,
        'rasterSamplesMicroseconds': rasterSamplesMicroseconds,
        'frameSpanSamplesMicroseconds': frameSpanSamplesMicroseconds,
      };
}

/// Aggregates Flutter frame timings only while an interactive run is active.
///
/// Build, raster and full-frame spans stay separate. Adding build and raster
/// durations would double-count pipelined work and is intentionally forbidden.
final class InteractiveFrameMetricsCollector {
  final List<int> _buildMicroseconds = <int>[];
  final List<int> _rasterMicroseconds = <int>[];
  final List<int> _frameSpanMicroseconds = <int>[];
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
    _buildMicroseconds.clear();
    _rasterMicroseconds.clear();
    _frameSpanMicroseconds.clear();
  }

  void recordDurations({
    required Duration build,
    required Duration raster,
    Duration? frameSpan,
  }) {
    if (build.isNegative ||
        raster.isNegative ||
        frameSpan?.isNegative == true) {
      throw const FormatException('Frame durations cannot be negative.');
    }
    _buildMicroseconds.add(build.inMicroseconds);
    _rasterMicroseconds.add(raster.inMicroseconds);
    _frameSpanMicroseconds.add(
      frameSpan?.inMicroseconds ??
          (build > raster ? build.inMicroseconds : raster.inMicroseconds),
    );
  }

  InteractiveFrameMetricsSnapshot snapshot() =>
      InteractiveFrameMetricsSnapshot.fromMicrosecondSamples(
        buildMicroseconds: _buildMicroseconds,
        rasterMicroseconds: _rasterMicroseconds,
        frameSpanMicroseconds: _frameSpanMicroseconds,
      );

  void _onTimings(List<FrameTiming> timings) {
    if (!_recording) return;
    for (final timing in timings) {
      recordDurations(
        build: timing.buildDuration,
        raster: timing.rasterDuration,
        frameSpan: timing.totalSpan,
      );
    }
  }
}

List<int> _integerSamples(Object? value, String field) {
  if (value is! List || value.any((sample) => sample is! int)) {
    throw FormatException('$field must contain integer microseconds.');
  }
  return List<int>.unmodifiable(value.cast<int>());
}

double _averageMilliseconds(List<int> samples) => samples.isEmpty
    ? 0
    : samples.reduce((left, right) => left + right) / samples.length / 1000;

double _maxMilliseconds(List<int> samples) => samples.isEmpty
    ? 0
    : samples.reduce((left, right) => left > right ? left : right) / 1000;

double _percentileMilliseconds(List<int> sortedSamples, double percentile) {
  if (sortedSamples.isEmpty) return 0;
  final index = (percentile * sortedSamples.length).ceil() - 1;
  return sortedSamples[index.clamp(0, sortedSamples.length - 1)] / 1000;
}

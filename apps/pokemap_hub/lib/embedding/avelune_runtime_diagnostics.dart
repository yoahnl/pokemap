import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class AveluneFrameDistribution {
  const AveluneFrameDistribution({
    this.count = 0,
    this.meanMs,
    this.p50Ms,
    this.p95Ms,
    this.p99Ms,
    this.maxMs,
  });

  factory AveluneFrameDistribution.fromMicroseconds(List<int> values) {
    if (values.isEmpty) return const AveluneFrameDistribution();
    final sorted = List<int>.of(values)..sort();
    double percentile(double fraction) =>
        sorted[(sorted.length * fraction).ceil() - 1] / 1000;
    return AveluneFrameDistribution(
      count: sorted.length,
      meanMs:
          sorted.fold<double>(0, (sum, value) => sum + value) /
          sorted.length /
          1000,
      p50Ms: percentile(.5),
      p95Ms: percentile(.95),
      p99Ms: percentile(.99),
      maxMs: sorted.last / 1000,
    );
  }

  final int count;
  final double? meanMs, p50Ms, p95Ms, p99Ms, maxMs;

  Map<String, Object?> toJson() => {
    'count': count,
    'meanMs': meanMs,
    'p50Ms': p50Ms,
    'p95Ms': p95Ms,
    'p99Ms': p99Ms,
    'maxMs': maxMs,
  };
}

class AveluneFrameBudget {
  const AveluneFrameBudget._({
    required this.framesPerSecond,
    this.intervalCount = 0,
    this.overruns = 0,
    this.longestRun = 0,
    this.totalExcessMs = 0,
  });

  factory AveluneFrameBudget.fromIntervals(
    List<int> values, {
    required int framesPerSecond,
  }) {
    if (framesPerSecond <= 0) {
      throw ArgumentError.value(framesPerSecond, 'framesPerSecond');
    }
    final budget = 1000000 / framesPerSecond;
    var overruns = 0, run = 0, longestRun = 0;
    var excess = 0.0;
    for (final interval in values) {
      if (interval > budget.ceil()) {
        overruns++;
        run++;
        longestRun = math.max(longestRun, run);
        excess += interval - budget;
      } else {
        run = 0;
      }
    }
    return AveluneFrameBudget._(
      framesPerSecond: framesPerSecond,
      intervalCount: values.length,
      overruns: overruns,
      longestRun: longestRun,
      totalExcessMs: excess / 1000,
    );
  }

  final int framesPerSecond, intervalCount, overruns, longestRun;
  final double totalExcessMs;
  double? get overrunFraction =>
      intervalCount == 0 ? null : overruns / intervalCount;

  Map<String, Object?> toJson() => {
    'framesPerSecond': framesPerSecond,
    'timestampThresholdUs': (1000000 / framesPerSecond).ceil(),
    'intervalCount': intervalCount,
    'overruns': overruns,
    'overrunFraction': overrunFraction,
    'longestRun': longestRun,
    'totalExcessMs': totalExcessMs,
  };
}

class AveluneFrameSample {
  const AveluneFrameSample({
    this.fps,
    this.latencyMs,
    this.p95Ms,
    this.buildMs,
    this.rasterMs,
    this.frameCount = 0,
    this.intervals = const AveluneFrameDistribution(),
    this.build = const AveluneFrameDistribution(),
    this.raster = const AveluneFrameDistribution(),
    this.latency = const AveluneFrameDistribution(),
    this.budget30 = const AveluneFrameBudget._(framesPerSecond: 30),
    this.budget60 = const AveluneFrameBudget._(framesPerSecond: 60),
  });
  final double? fps;
  final double? latencyMs;
  final double? p95Ms;
  final double? buildMs;
  final double? rasterMs;
  final int frameCount;
  final AveluneFrameDistribution intervals, build, raster, latency;
  final AveluneFrameBudget budget30, budget60;

  Map<String, Object?> toJson() => {
    'cadenceSource': 'flutterVsyncStart',
    'frameCount': frameCount,
    'fps': fps,
    'window': {
      'retentionMs': 2000,
      'sampleLimit': 512,
      'intervalSelection': 'endTimestamp',
      'observedIntervalSpanMs': intervals.meanMs == null
          ? null
          : intervals.meanMs! * intervals.count,
    },
    'intervals': intervals.toJson(),
    'build': build.toJson(),
    'raster': raster.toJson(),
    'latency': latency.toJson(),
    'budget30': budget30.toJson(),
    'budget60': budget60.toJson(),
    'presentation': null,
    'gpu': null,
  };
}

class AveluneFrameWindow {
  final _frames = <FrameTiming>[];
  final _intervals = <({int end, int micros})>[];
  Duration? _lastReport;
  int? _lastStart;
  int get sampleCount => _frames.length;

  void record(List<FrameTiming> frames, Duration now) {
    for (final frame in frames) {
      final start = frame.timestampInMicroseconds(FramePhase.vsyncStart);
      final previous = _lastStart;
      if (previous != null && start <= previous) continue;
      if (previous != null) {
        _intervals.add((end: start, micros: start - previous));
      }
      _lastStart = start;
      _frames.add(frame);
      _lastReport = now;
      final oldest = start - const Duration(seconds: 2).inMicroseconds;
      while (_frames.length > 512 ||
          _frames.first.timestampInMicroseconds(FramePhase.vsyncStart) <
              oldest) {
        _frames.removeAt(0);
      }
      while (_intervals.isNotEmpty &&
          (_intervals.length > 512 || _intervals.first.end < oldest)) {
        _intervals.removeAt(0);
      }
    }
  }

  void clear() {
    _frames.clear();
    _intervals.clear();
    _lastStart = null;
    _lastReport = null;
  }

  AveluneFrameSample read(Duration now) {
    if (_lastReport == null) return const AveluneFrameSample();
    if (now - _lastReport! > const Duration(seconds: 2)) {
      return const AveluneFrameSample(fps: 0);
    }
    final intervals = _intervals.map((value) => value.micros).toList();
    final cadence = AveluneFrameDistribution.fromMicroseconds(intervals);
    final build = AveluneFrameDistribution.fromMicroseconds([
      for (final frame in _frames) frame.buildDuration.inMicroseconds,
    ]);
    final raster = AveluneFrameDistribution.fromMicroseconds([
      for (final frame in _frames) frame.rasterDuration.inMicroseconds,
    ]);
    final latency = AveluneFrameDistribution.fromMicroseconds([
      for (final frame in _frames) frame.totalSpan.inMicroseconds,
    ]);
    return AveluneFrameSample(
      fps: cadence.meanMs == null ? null : 1000 / cadence.meanMs!,
      latencyMs: latency.meanMs,
      p95Ms: latency.p95Ms,
      buildMs: build.meanMs,
      rasterMs: raster.meanMs,
      frameCount: _frames.length,
      intervals: cadence,
      build: build,
      raster: raster,
      latency: latency,
      budget30: AveluneFrameBudget.fromIntervals(
        intervals,
        framesPerSecond: 30,
      ),
      budget60: AveluneFrameBudget.fromIntervals(
        intervals,
        framesPerSecond: 60,
      ),
    );
  }
}

class AveluneProcessSample {
  const AveluneProcessSample({
    this.cpuSeconds,
    this.uptimeSeconds,
    this.memoryBytes,
    this.memoryKind,
    this.thermalState,
    this.lowPowerMode,
  });
  final double? cpuSeconds;
  final double? uptimeSeconds;
  final double? memoryBytes;
  final String? memoryKind;
  final String? thermalState;
  final bool? lowPowerMode;

  factory AveluneProcessSample.fromPayload(Object? payload) {
    if (payload is! Map) return const AveluneProcessSample();
    double? number(String key) {
      final value = payload[key];
      return value is num && value.isFinite && value >= 0
          ? value.toDouble()
          : null;
    }

    return AveluneProcessSample(
      cpuSeconds: number('cpuSeconds'),
      uptimeSeconds: number('uptimeSeconds'),
      memoryBytes: number('memoryBytes'),
      memoryKind: payload['memoryKind'] is String
          ? payload['memoryKind'] as String
          : null,
      thermalState: payload['thermalState'] is String
          ? payload['thermalState'] as String
          : null,
      lowPowerMode: payload['lowPowerMode'] is bool
          ? payload['lowPowerMode'] as bool
          : null,
    );
  }

  double? get memoryMiB =>
      memoryBytes == null ? null : memoryBytes! / (1024 * 1024);

  Map<String, Object?> toJson() => {
    'cpuSeconds': cpuSeconds,
    'uptimeSeconds': uptimeSeconds,
    'memoryBytes': memoryBytes,
    'memoryKind': memoryKind,
    'thermalState': thermalState,
    'lowPowerMode': lowPowerMode,
  };

  double? cpuPercentSince(AveluneProcessSample? previous) {
    final beforeCpu = previous?.cpuSeconds;
    final beforeTime = previous?.uptimeSeconds;
    if (beforeCpu == null ||
        beforeTime == null ||
        cpuSeconds == null ||
        uptimeSeconds == null) {
      return null;
    }
    final elapsed = uptimeSeconds! - beforeTime;
    final cpu = cpuSeconds! - beforeCpu;
    if (elapsed <= 0 || cpu < 0) return null;
    return math.max(0, cpu / elapsed * 100);
  }
}

class AveluneDiagnosticSnapshot {
  const AveluneDiagnosticSnapshot({
    this.frames = const AveluneFrameSample(),
    this.process = const AveluneProcessSample(),
    this.cpuPercent,
  });
  final AveluneFrameSample frames;
  final AveluneProcessSample process;
  final double? cpuPercent;

  Map<String, Object?> toJson() => {
    'schemaVersion': 1,
    'frames': frames.toJson(),
    'process': process.toJson(),
    'cpuPercent': cpuPercent,
  };
}

class AveluneRuntimeDiagnostics extends ChangeNotifier
    with WidgetsBindingObserver {
  AveluneRuntimeDiagnostics({MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel('com.avelune.runtime/diagnostics');
  final MethodChannel _channel;
  final _clock = Stopwatch();
  final _frames = AveluneFrameWindow();
  Timer? _timer;
  AveluneProcessSample? _previous;
  var _attached = false;
  var _enabled = false;
  var _playing = false;
  var _foreground = true;
  var _polling = false;
  var _epoch = 0;
  AveluneDiagnosticSnapshot _snapshot = const AveluneDiagnosticSnapshot();

  bool get visible => _timer != null;
  AveluneDiagnosticSnapshot get snapshot => _snapshot;

  void attach() {
    if (_attached) return;
    _attached = true;
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'snapshot') {
        return {
          ..._snapshot.toJson(),
          'frames': _frames.read(_clock.elapsed).toJson(),
          'collection': {
            'generation': _epoch,
            'enabled': _enabled,
            'active': visible,
            'playing': _playing,
            'foreground': _foreground,
            'elapsedMs': _clock.elapsedMilliseconds,
          },
        };
      }
      if (call.method != 'setEnabled') throw MissingPluginException();
      final args = call.arguments;
      if (args is! Map || args['enabled'] is! bool) {
        throw PlatformException(
          code: 'invalidArguments',
          message: 'setEnabled requires enabled.',
        );
      }
      setEnabled(args['enabled'] as bool);
    });
  }

  void setPlaying(bool playing) {
    _playing = playing;
    _sync();
  }

  void setEnabled(bool enabled) {
    _enabled = enabled;
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  void _record(List<FrameTiming> frames) =>
      _frames.record(frames, _clock.elapsed);

  void _sync() {
    final active = _attached && _enabled && _playing && _foreground;
    if (active == visible) return;
    _epoch++;
    _previous = null;
    _polling = false;
    _frames.clear();
    _snapshot = const AveluneDiagnosticSnapshot();
    if (active) {
      _clock
        ..reset()
        ..start();
      WidgetsBinding.instance.addTimingsCallback(_record);
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => unawaited(_sample()),
      );
      unawaited(_sample());
    } else {
      _timer?.cancel();
      _timer = null;
      _clock.stop();
      WidgetsBinding.instance.removeTimingsCallback(_record);
    }
    notifyListeners();
  }

  Future<void> _sample() async {
    if (!visible || _polling) return;
    _polling = true;
    final epoch = _epoch;
    var process = const AveluneProcessSample();
    try {
      process = AveluneProcessSample.fromPayload(
        await _channel
            .invokeMethod<Object?>('processSample')
            .timeout(const Duration(seconds: 2)),
      );
    } on Exception {
      process = const AveluneProcessSample();
    }
    if (epoch != _epoch || !_attached || !visible) return;
    _snapshot = AveluneDiagnosticSnapshot(
      frames: _frames.read(_clock.elapsed),
      process: process,
      cpuPercent: process.cpuPercentSince(_previous),
    );
    _previous = process;
    _polling = false;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_attached) {
      _epoch++;
      if (visible) WidgetsBinding.instance.removeTimingsCallback(_record);
      _timer?.cancel();
      _timer = null;
      _clock.stop();
      _attached = false;
      WidgetsBinding.instance.removeObserver(this);
      _channel.setMethodCallHandler(null);
    }
    super.dispose();
  }
}

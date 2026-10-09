import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class AveluneFrameSample {
  const AveluneFrameSample({
    this.fps,
    this.latencyMs,
    this.p95Ms,
    this.buildMs,
    this.rasterMs,
  });
  final double? fps;
  final double? latencyMs;
  final double? p95Ms;
  final double? buildMs;
  final double? rasterMs;
}

class AveluneFrameWindow {
  final _frames = <FrameTiming>[];
  Duration? _lastReport;
  int get sampleCount => _frames.length;

  void record(List<FrameTiming> frames, Duration now) {
    for (final frame in frames) {
      final start = frame.timestampInMicroseconds(FramePhase.vsyncStart);
      if (_frames.isNotEmpty &&
          start <=
              _frames.last.timestampInMicroseconds(FramePhase.vsyncStart)) {
        continue;
      }
      _frames.add(frame);
      _lastReport = now;
      final oldest = start - const Duration(seconds: 2).inMicroseconds;
      while (_frames.length > 512 ||
          _frames.first.timestampInMicroseconds(FramePhase.vsyncStart) <
              oldest) {
        _frames.removeAt(0);
      }
    }
  }

  void clear() {
    _frames.clear();
    _lastReport = null;
  }

  AveluneFrameSample read(Duration now) {
    if (_lastReport == null) return const AveluneFrameSample();
    if (now - _lastReport! > const Duration(seconds: 2)) {
      return const AveluneFrameSample(fps: 0);
    }
    final latency =
        _frames.map((frame) => frame.totalSpan.inMicroseconds / 1000).toList()
          ..sort();
    final span =
        _frames.last.timestampInMicroseconds(FramePhase.vsyncStart) -
        _frames.first.timestampInMicroseconds(FramePhase.vsyncStart);
    return AveluneFrameSample(
      fps: span > 0 ? (_frames.length - 1) * 1000000 / span : null,
      latencyMs: latency.reduce((a, b) => a + b) / latency.length,
      p95Ms: latency[(latency.length * .95).ceil() - 1],
      buildMs:
          _frames.fold<double>(
            0,
            (sum, frame) => sum + frame.buildDuration.inMicroseconds / 1000,
          ) /
          _frames.length,
      rasterMs:
          _frames.fold<double>(
            0,
            (sum, frame) => sum + frame.rasterDuration.inMicroseconds / 1000,
          ) /
          _frames.length,
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
      memoryKind:
          payload['memoryKind'] is String
              ? payload['memoryKind'] as String
              : null,
      thermalState:
          payload['thermalState'] is String
              ? payload['thermalState'] as String
              : null,
      lowPowerMode:
          payload['lowPowerMode'] is bool
              ? payload['lowPowerMode'] as bool
              : null,
    );
  }

  double? get memoryMiB =>
      memoryBytes == null ? null : memoryBytes! / (1024 * 1024);

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
